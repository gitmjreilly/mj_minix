-- This is a memory mapped uart with fifo.
-- It uses the uart from the picoblaze 6,
-- but has FSM's to control pulses needed by 
-- the uarts so they will work properly as 
-- memory mapped devices with a static ram
-- interface.
--
-- Address Use
--		x0 read data from UART
--		x1 write data to UART
--		xE read fifo has data (1 = data is present)
--		xF write fifo is full (1 = full)
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
Library UNISIM;
use UNISIM.vcomponents.all;
use IEEE.NUMERIC_STD.ALL;


entity pb_uart_lacombe is 
	generic (
		data_width : natural := 16;
		addr_width : natural := 4
	);
	port (
		clk : in std_logic; -- Assume 100Mhz, NOT the CPU clock
		reset : in std_logic;
		n_cs : in std_logic;
		n_oe : in std_logic;
		n_wr : in std_logic;
		addr_bus : in std_logic_vector((addr_width - 1) downto 0);
		data_bus : inout std_logic_vector((data_width - 1) downto 0);
		en_16x_baud : in std_logic;
		serial_in : in std_logic;
		serial_out : out std_logic
	);
end pb_uart_lacombe;

architecture structural of pb_uart_lacombe is


    COMPONENT rx_fsm
		PORT(
			 reset : IN  std_logic;
			 clk : IN  std_logic;
			 rd_in_progress : IN  std_logic;
			 load_reg : OUT  std_logic;
			 do_fifo : OUT  std_logic
		);
    END COMPONENT;
    

	component tx_fsm 
		Port ( 
			reset : in STD_LOGIC;
			clk : in  STD_LOGIC;
			wr_in_progress: in  STD_LOGIC;
			wr_strobe: in  STD_LOGIC
		) ;
	end component;

	

	component uart_tx6 is 
		Port (
			data_in : in std_logic_vector(7 downto 0);
			en_16_x_baud : in std_logic;
			serial_out : out std_logic;
			buffer_write : in std_logic;
			buffer_data_present : out std_logic;
			buffer_half_full : out std_logic;
			buffer_full : out std_logic;
			buffer_reset : in std_logic;
			clk : in std_logic
		);
	end component;

	
	component uart_rx6 is
		Port (           
			serial_in : in std_logic;
			en_16_x_baud : in std_logic;
			data_out : out std_logic_vector(7 downto 0);
			buffer_read : in std_logic;
			buffer_data_present : out std_logic;
			buffer_half_full : out std_logic;
			buffer_full : out std_logic;
			buffer_reset : in std_logic;
			clk : in std_logic
		);
	end component;

  	
	
	
	
    COMPONENT jam_fifo
		PORT(
			 reset : IN  std_logic;
			 clk : IN  std_logic;
			 rd : IN  std_logic;
			 wr : IN  std_logic;
			 w_data : IN  std_logic_vector(7 downto 0);
			 empty : OUT  std_logic;
			 full : OUT  std_logic;
			 r_data : OUT  std_logic_vector(7 downto 0)
		);
    END COMPONENT;
    
	
	signal uart_rx_rd_in_progress : std_logic;
	signal load_reg : std_logic;
	signal rx_empty : std_logic;
	signal rx_full : std_logic;
	
	signal fifo_full : std_logic;
	signal tx_empty : std_logic;
	
	signal output_reg : std_logic_vector(15 downto 0);
	signal r_data : std_logic_vector(7 downto 0);
	
	signal do_fifo : std_logic;
	signal log_reg : std_logic;
	signal wr_strobe : std_logic;
	
	signal write_is_active : std_logic;
	signal read_is_active : std_logic;

	signal tx_buffer_data_present : std_logic;
	signal tx_buffer_half_full : std_logic;
	signal tx_buffer_full : std_logic;

	signal	rx_buffer_data_present : std_logic;
	signal	rx_buffer_half_full : std_logic;
	signal	rx_buffer_full : std_logic;

	
	
begin
	-- When a CPU read from the uart read data port,
	-- this fsm loads an external reg (with load_reg)
	-- and advances the fifo with do_fifo
	u_rx_fsm: rx_fsm PORT MAP (
		reset => reset,
		clk => clk,
		rd_in_progress => uart_rx_rd_in_progress,
		load_reg => load_reg,
		do_fifo => do_fifo
	);



	u_tx_fsm:  tx_fsm port map (
		reset => reset,
		clk => clk,
		wr_in_progress => write_is_active,
		wr_strobe => wr_strobe
	) ;


	

	u_uart_tx6 : uart_tx6 port map (
		data_in => data_bus(7 downto 0), -- ok
		en_16_x_baud => en_16x_baud, -- ok
		serial_out => serial_out, -- ok
		buffer_write => wr_strobe, -- ok (From tx_fsm)
		buffer_data_present => tx_buffer_data_present, -- ok (ignored for now)
		buffer_half_full => tx_buffer_half_full, -- ok (ignored for now)
		buffer_full => tx_buffer_full, -- ok (used by status reg at addr xF
		buffer_reset => reset,
		clk => clk
	);

	
	
	u_uart_rx6 : uart_rx6 port map (
		serial_in => serial_in, -- ok
		en_16_x_baud => en_16x_baud, -- ok
		data_out => r_data(7 downto 0), -- ok (will be loaded to reg by rx fsm)
		buffer_read => do_fifo, --ok cause fifo advance with rx fsm
		buffer_data_present => rx_buffer_data_present,
		buffer_half_full => rx_buffer_half_full,
		buffer_full => rx_buffer_full,
		buffer_reset => reset,
		clk => clk
	);

 	
 	
	
	
	-- u_jam_fifo : jam_fifo PORT MAP (
		-- reset => reset,
		-- clk => clk,
		-- rd => do_fifo, -- strobed by u_rx_fsm
		-- wr => wr_strobe,
		-- w_data => data_bus(7 downto 0),
		-- empty => rx_empty,
		-- full => fifo_full,
		-- r_data => r_data(7 downto 0)
	-- );

	u_output_reg : process(load_reg)
	begin
		if rising_edge(load_reg) then
			output_reg <= x"00" & r_data;
		end if;
	end process;

	
	u_write_is_active : process(n_cs, n_wr, addr_bus)
	begin
		if (n_cs = '0' AND n_wr = '0' AND addr_bus = x"1") then
			write_is_active <= '1';
		else
			write_is_active <= '0';
		end if;
	end process;

	
	u_read_is_active : process(n_cs, n_oe)
	begin
		if (n_cs = '0' AND n_oe = '0') then
			read_is_active <= '1';
		else
			read_is_active <= '0';
		end if;
	end process;
	uart_rx_rd_in_progress <= '1' when
		(read_is_active = '1' AND addr_bus = x"0") else '0';
	
	u_read_proc : process(read_is_active)
	begin
		if (read_is_active = '1') then

			if addr_bus = x"0" then 
				data_bus <= output_reg;
			elsif addr_bus = x"A" then
				data_bus <= x"AAAA";
			elsif addr_bus = x"B" then
				data_bus <= x"BBBB";
			elsif addr_bus = x"E" then
				data_bus <= "000000000000000" & rx_buffer_data_present;
			elsif addr_bus = x"F" then
				data_bus <= "000000000000000" & tx_buffer_full;
			else
				data_bus <= x"ABCD";
			end if;
		else
			data_bus <= (others => 'Z');
		end if;
	end process;
	
	
end structural;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;




entity pb_mj_uart is port (
	reset : in std_logic;
	-- This should be the 100Mhz clock on the Nexys 3
	clk : in std_logic;
	n_wr : in std_logic;
	n_rd : in std_logic;
	n_cs : in std_logic;
	data_bus : inout std_logic_vector(15 downto 0);
	addr_bus : in std_logic_vector(3 downto 0);
	-- serial_in : in std_logic;
	serial_out : out std_logic
);
end pb_mj_uart;


architecture structural of pb_mj_uart is



component uart_tx6 is Port (
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
  Port (           serial_in : in std_logic;
                en_16_x_baud : in std_logic;
                    data_out : out std_logic_vector(7 downto 0);
                 buffer_read : in std_logic;
         buffer_data_present : out std_logic;
            buffer_half_full : out std_logic;
                 buffer_full : out std_logic;
                buffer_reset : in std_logic;
                         clk : in std_logic);
  end component;
  
  	



	
	---------------------------------------------------------------------
	component pulse_gen is
    Port ( clk : in  STD_LOGIC;
           input : in  STD_LOGIC;
           output : out  STD_LOGIC);
	end component;
	---------------------------------------------------------------------

	
	-- The uart (connected to the disk controller)
	-- requires a short pulse to load data into its fifo
	signal write_pulse : std_logic;
	signal en_16_x_baud : std_logic;
	signal baud_count : integer range 0 to 53 := 0; 

	signal uart_tx0 : std_logic;
	signal uart_rx0 : std_logic;
	signal	buffer_data_present : std_logic;
	signal	buffer_half_full : std_logic;
	signal	buffer_full : std_logic;
	signal	buffer_reset : std_logic;

	signal data_in : std_logic_vector(7 downto 0);
	signal buffer_write : std_logic;
	
	-- Parallel output from uart receiver
	signal serial_data_out : std_logic_vector(7 downto 0);
	
	signal status_reg : std_logic_vector(15 downto 0);
	
begin
--
  -----------------------------------------------------------------------------------------
  -- RS232 (UART) baud rate 
  -----------------------------------------------------------------------------------------
  --
  -- To set serial communication baud rate to 115,200 then en_16_x_baud must pulse 
  -- High at 1,843,200Hz which is every 54.28 cycles at 100MHz. In this implementation 
  -- a pulse is generated every 54 cycles resulting is a baud rate of 115,741 baud which
  -- is only 0.5% high and well within limits.
  --

  baud_rate: process(clk)
  begin
    if clk'event and clk = '1' then
      if baud_count = 53 then                    -- counts 54 states including zero
        baud_count <= 0;
        en_16_x_baud <= '1';                     -- single cycle enable pulse
       else
        baud_count <= baud_count + 1;
        en_16_x_baud <= '0';
      end if;
    end if;
  end process baud_rate;
	

	
	-- u_wiznet_int_pulse : pulse_gen port map (
	   -- clk => clk_counter(5), -- clock should be half system clock
		-- input => n_external_input_port_4,
		-- output => wiznet_int_pulse);
	
	
	-- We are generating a clock pulse based on the underlying full speed clock
	-- used by the uart.  We do this because the uart expects one clock-width pulse
	-- to know when to load data.
	u_disk_ctlr_pulse : pulse_gen port map (
		clk => clk,
--		input => (NOT (n_wr)),
		input => (NOT (n_wr)),
		output => write_pulse
	);


	data_in <= data_bus(7 downto 0);
	buffer_write <= '1' when ((write_pulse = '1') AND (n_cs = '0') AND (addr_bus = "0000")) else '0' ;
	test_uart : uart_tx6 port map (
		data_in => data_in, -- OK
		en_16_x_baud => en_16_x_baud, -- OK
		serial_out => serial_out, -- OK
		-- This works !! buffer_write => clk_counter(22),
		-- buffer_write => ((NOT n_wr_bus) AND (NOT cs_bus(disk_ctlr_uart_cs))),
		-- buffer_write => (write_pulse) AND (NOT n_cs), -- write_pulse  OK  n_cs OK
		buffer_write => buffer_write,
		buffer_data_present => buffer_data_present,
		buffer_half_full => buffer_half_full,
		buffer_full => buffer_full,
		buffer_reset => reset,
		clk => clk
	);
		

		

	-- uart_rx : uart_rx6 port map (
  -- Port (           
		-- serial_in =>  serial_in, -- OK
		-- en_16_x_baud => en_16_x_baud, -- OK
		-- data_out => uart_rx_data_out, -- Feeds an internal reg on RE(clk)
                 -- buffer_read : in std_logic;
         -- buffer_data_present : out std_logic;
            -- buffer_half_full : out std_logic;
                 -- buffer_full : out std_logic;
                -- buffer_reset : in std_logic;
                         -- clk : in std_logic);
	-- );


	-- From pb_uart_demo
  -- rx: uart_rx6 
  -- port map (            serial_in => uart_rx,
                     -- en_16_x_baud => en_16_x_baud,
                         -- data_out => uart_rx_data_out,
                      -- buffer_read => read_from_uart_rx,
              -- buffer_data_present => uart_rx_data_present,
                 -- buffer_half_full => uart_rx_half_full,
                      -- buffer_full => uart_rx_full,
                     -- buffer_reset => uart_rx_reset,              
                              -- clk => clk);


	

  

	-- u_status_reg : process(clk)
	-- begin
		-- if rising_edge(clk) then
			-- status_reg(0) <= uart_tx_data_present;
			-- status_reg(1) <= uart_tx_half_full;
			-- status_reg(2) <= uart_tx_full; 
			-- status_reg(3) <= uart_rx_data_present;
			-- status_reg(4) <= uart_rx_half_full;
			-- status_reg(5) <= uart_rx_full;
		-- end if;	
	-- end process u_status_reg;
	
	-- u_rx_data_reg : process(clk)
	-- begin
		-- if rising_edge(clk) then
			-- rx_data_reg <= uart_rx_data_out;
		-- end if;	
	-- end process u_rx_data_reg;
	
  
  -- input_ports: process(clk)
  -- begin
    -- if clk'event and clk = '1' then

      -- Generate 'buffer_read' pulse following read from port address 01

      -- if (read_strobe = '1') and (port_id(1 downto 0) = "01") then
        -- read_from_uart_rx <= '1';
       -- else
        -- read_from_uart_rx <= '0';
      -- end if;
 
    -- end if;
  -- end process input_ports;


	-- buffer_write <= '1' when ((write_pulse = '1') AND (n_cs = '0') AND (addr_bus = "0000")) else '0' ;


	-- cpu_read <= '1' when ((write_pulse = '1') AND (n_cs = '0') AND (addr_bus = "0000")) else '0' ;
	-- data_bus <= 
		-- X"00" & rx_data_reg when (cpu_read = '1') AND (addr_bus = X"8") else
		-- status_reg when (cpu_read = '1') AND (addr_bus = X"9") else
		-- (others => X"ZZZZ");
		
		
	
end structural;	
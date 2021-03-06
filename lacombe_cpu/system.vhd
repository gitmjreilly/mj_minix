library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity system is port (
	reset : in std_logic;
	clk : in std_logic;
	clk_hi_ind : out std_logic;
	clk_low_ind : out std_logic;
	n_wr : out std_logic;
	n_rd : out std_logic;
	n_ind : out std_logic;
	z_ind : out std_logic;
	rd_ind : out std_logic;
	wr_ind : out std_logic;
	fetch_ind : out std_logic;
	data_bus : inout std_logic_vector(15 downto 0);
	addr_bus : out std_logic_vector(25 downto 0);
	SevenSegAnodes : out std_logic_vector(3 downto 0);
	SevenSegSegments : out std_logic_vector(7 downto 0);
	address_switches : in std_logic_vector(7 downto 0);
	
	console_uart_tx : out std_logic;
	console_uart_rx : in std_logic;
	N_UB : out std_logic;
	N_LB : out std_logic;
	external_ram_cs : out std_logic;
	-- These signals need to be set on Nexys3
	cellular_ram_clk : out std_logic;
	cellular_ram_adv : out std_logic;
	cellular_ram_cre : out std_logic;
	--
	parallel_pcm_cs : out std_logic;
	parallel_pcm_rst : out std_logic;
	-- End of signals for Nexys 3
	INT_SW : in std_logic;

	disk_uart_tx : out std_logic;
	disk_uart_rx : in std_logic;
	
	ptc_uart_tx : out std_logic;
	ptc_uart_rx : in std_logic
	
);
end system;



architecture structural of system is
	-- constant RAM_CS            : std_logic_vector(15 downto 0)  := "1111111111111110";
	-- constant ROM_CS            : std_logic_vector(15 downto 0)  := "1111111111111101";
	-- constant CONSOLE_UART_CS   : std_logic_vector(15 downto 0)  := "1111111111111011";
	-- constant COUNTER_0_CS      : std_logic_vector(15 downto 0)  := "1111111111110111";
	-- constant DISK_UART_CS      : std_logic_vector(15 downto 0)  := "1111111111101111"; 
	-- constant INT_CONTROLLER_CS : std_logic_vector(15 downto 0)  := "1111111111011111";
	-- constant BLANK_20_CS       : std_logic_vector(15 downto 0)  := "1111111110111111"; 
	-- constant PTC_UART_CS       : std_logic_vector(15 downto 0)  := "1111111101111111";
	-- constant BLANK_40_CS       : std_logic_vector(15 downto 0)  := "1111111011111111"; 
	-- constant BLANK_50_CS       : std_logic_vector(15 downto 0)  := "1111110111111111";
	-- constant BLANK_70_CS       : std_logic_vector(15 downto 0)  := "1111101111111111"; 
	-- constant BLANK_80_CS       : std_logic_vector(15 downto 0)  := "1111011111111111"; 
	-- constant NO_CS             : std_logic_vector(15 downto 0)  := "1111111111111111";
	
	constant RAM_CS            : integer  := 0;
	constant ROM_CS            : integer  := 1;
	constant CONSOLE_UART_CS   : integer  := 2;
	constant COUNTER_0_CS      : integer  := 3;
	constant DISK_UART_CS      : integer  := 4;
	constant INT_CONTROLLER_CS : integer  := 5;
	constant BLANK_20_CS       : integer  := 6;
	constant PTC_UART_CS       : integer  := 7;
	constant BLANK_40_CS       : integer  := 8;
	constant BLANK_50_CS       : integer  := 9;
	constant BLANK_70_CS       : integer  := 10;
	constant BLANK_80_CS       : integer  := 11;
	constant NO_CS             : integer  := 12;
	

	---------------------------------------------------------------------
	signal my_clock : std_logic; -- derived clock to be deprecated
	signal four_digits : std_logic_vector(15 downto 0);
	-- signal clk_counter : std_logic_vector(23 downto 0); -- OK Driven by clk

	signal cs_bus : std_logic_vector(15 downto 0);

	signal local_addr_bus : std_logic_vector(19 downto 0);
	signal multiple_int_sources : std_logic_vector(15 downto 0);

	signal reset_n : std_logic;
	signal txd_bus : std_logic;
	signal rxd_bus : std_logic;
	signal n_wr_bus : std_logic;
	signal n_rd_bus : std_logic;

	signal INT_SW_OUT : std_logic;
	signal RX_FULL : std_logic;
	signal tx_busy_n : std_logic;
	signal disk_uart_rx_fifo_is_half_full : std_logic;
	signal ptc_uart_rx_fifo_is_quarter_full : std_logic;
	signal cpu_int : std_logic;
	signal counter_is_zero : std_logic;
	signal	cpu_start  : std_logic;
	signal	cpu_finish : std_logic;
	
	---------------------------------------------------------------------

	
	
begin
	reset_n <= NOT reset;
	console_uart_tx <= txd_bus;
	rxd_bus <= console_uart_rx;

	n_wr <= n_wr_bus;
	n_rd <= n_rd_bus;

	parallel_pcm_cs  <= '1';
	parallel_pcm_rst  <= '0';
	cellular_ram_clk <= '0';
	cellular_ram_adv <= '0';
	cellular_ram_cre <= '0';

	---------------------------------------------------------------------
	-- clk_divider : entity work.ClockDivider 
		-- port map (
			-- reset => reset,
			-- clkin => clk,
			-- slowout => clk_counter -- clk_counter is derived from clk OK
		-- );
	-- ---------------------------------------------------------------------

	---------------------------------------------------------------------
	INT_SW_1 : entity work.switch_debounce 
		port map (
			-- clock => clk_counter(20), -- another switch debounce clock - OK
			clock => my_clock, -- junk entry to get build to work after switching to new clock
			sw => INT_SW,
			y => INT_SW_OUT
		);
	---------------------------------------------------------------------


	
	
	-- my_clock is the fundamental clock of the system.
	-- As of June 13, 2015, ISE claims the clock speed is limited to about 
	-- 75Mhz. Since the target is Spartan 6 Nexys 3 board, with 100Mhz clock,
	-- we use the clock divided by 2.
	-- my_clock <= clk_counter(0);

jam_clock : entity work.jam_half_clock
  port map
   (-- Clock in ports
    CLK_IN1 => clk,
    -- Clock out ports
    CLK_OUT1 => my_clock,
    -- Status and control signals
    RESET  => RESET);	
	
	
	-- clk_hi_ind <= 	my_clock;
	-- clk_low_ind <= NOT my_clock;
	clk_hi_ind <= 	'1';
	clk_low_ind <=  '0';

	-- 
	-- Hardwire UB & LB for RAM access
	--
	n_ub <= '0';
	n_lb <= '0';

	---------------------------------------------------------------------
	-- Notice the timing generator which generates cpu_start and cpu_finish
	-- pulses uses my_clock as the fundamental clock for the system.
	the_cpu_timing_generator  : entity work.cpu_timing_generator 
		port map( 
		clk => my_clock,
		reset => reset,
		cpu_start => cpu_start,
		cpu_finish => cpu_finish
	);
	---------------------------------------------------------------------
	
	
	---------------------------------------------------------------------
	the_cpu : entity work.cpu1 
		port map (
			reset => reset,
			my_clock => my_clock, 
			cpu_start => cpu_start,
			cpu_finish => cpu_finish,
			n_indicator => n_ind,
			z_indicator => z_ind,
			rd_indicator => rd_ind,
			wr_indicator => wr_ind,
			fetch_indicator => fetch_ind,
			four_digits => four_digits,
			address_switches => address_switches(4 downto 0),
			Mem_Addr_bus => local_addr_bus,
			Mem_Data_bus => data_bus,
			N_WR => n_wr_bus,
			N_RD => n_rd_bus,
			INT => cpu_int
		);	
	---------------------------------------------------------------------


   addr_bus <= "000000" & local_addr_bus(19 downto 0);


	---------------------------------------------------------------------
	--
	-- This is the ganged (4) Seven Segment Driver.
	-- It takes four bcd digits output from the cpu
	-- and produces the appropriate signals to drive
	-- the 4 seven segment LED display on the Digilent spartan 3 board.
	--
	DigitDriver : entity work.SevenSegDriver 	
		port map (	
			four_digits (15 downto 12),			-- High Digit
			four_digits (11 downto 8),
			four_digits (7 downto 4),
			four_digits (3 downto 0),
			-- clk_counter(15), -- This is OK as - is for digit driver
			my_clock, -- This is probably wrong - used to get build to work after switch to DCM
			SevenSegSegments, 
			SevenSegAnodes
		);
	---------------------------------------------------------------------


	---------------------------------------------------------------------
	-- This component provides the chip selects for 
	-- devices on the address and data buses.
	--
	glue_chip : entity work.CS_Glue 
		port map (
			addr => local_addr_bus(19 downto 0),
			CS => cs_bus
		);
	---------------------------------------------------------------------


	external_ram_cs <= cs_bus(RAM_CS);
 
	---------------------------------------------------------------------
	the_rom : entity work.rom  -- no sync clock issues - This is combinatorial
		port map (
			addr => local_addr_bus(15 downto 0),
			data => data_bus,
			cs => cs_bus(ROM_CS)
		);
	---------------------------------------------------------------------


	---------------------------------------------------------------------
	counter_0: entity work.mem_based_counter 
		port map (
			clock => my_clock,  -- counter clock MAY be OK - Confirm!!!
			reset => reset,
			n_rd => n_rd_bus,
			n_cs => cs_bus(COUNTER_0_CS),
			x_edge => counter_is_zero,
			counter_out => data_bus
		);
	---------------------------------------------------------------------


   ---
	--- Set up interrupt sources.  Those not connected to a device are
	--- tied to 0
	---
	multiple_int_sources(0) <= rx_full;
	multiple_int_sources(1) <= counter_is_zero;
	multiple_int_sources(2) <= NOT tx_busy_n;
	multiple_int_sources(3) <= int_sw_out;
	multiple_int_sources(4) <= disk_uart_rx_fifo_is_half_full;
	multiple_int_sources(5) <= ptc_uart_rx_fifo_is_quarter_full;
	  
	multiple_int_sources(15 downto 6) <= (others => disk_uart_rx_fifo_is_half_full);
   


	
	-- ---------------------------------------------------------------------
	-- int_controller_1 :  entity work.mem_based_int_controller 
		-- port map (
			-- -- clock => my_clock, -- TODO fix clock for interrupt controller
			-- clock => cpu_start, -- TODO fix clock for interrupt controller
			-- reset => reset,
			-- address => local_addr_bus(1 downto 0),
			-- data_bus_0 => data_bus(0),
			-- data_bus_1 => data_bus(1),
			-- data_bus_2 => data_bus(2),
			-- data_bus_3 => data_bus(3),
			-- data_bus_4 => data_bus(4),
			-- data_bus_5 => data_bus(5),
			-- data_bus_6 => data_bus(6),
			-- data_bus_7 => data_bus(7),
			-- data_bus_8 => data_bus(8),
			-- data_bus_9 => data_bus(9),
			-- data_bus_10 => data_bus(10),
			-- data_bus_11 => data_bus(11),
			-- data_bus_12 => data_bus(12),
			-- data_bus_13 => data_bus(13),
			-- data_bus_14 => data_bus(14),
			-- data_bus_15 => data_bus(15),
			-- int_out => cpu_int,
			-- n_cs => cs_bus(INT_CONTROLLER_CS),
			-- n_rd => n_rd_bus,
			-- n_wr => n_wr_bus,
			-- int_in => multiple_int_sources
		-- );
	-- ---------------------------------------------------------------------


	int_controller : entity work.mem_based_int_controller 
		port map ( 
			clock => my_clock, 
			reset => reset,
			cpu_finish => cpu_finish,
			addr_bus => local_addr_bus(3 downto 0),
			data_bus => data_bus,
			int_occurred => cpu_int,
			n_cs => cs_bus(INT_CONTROLLER_CS),
			n_wr => n_wr_bus,
			n_rd => n_rd_bus,
			raw_interrupt_word => multiple_int_sources
		);
	
	
	
	-- ---------------------------------------------------------------------
	-- -- Test output port - no actual use.
	-- u_output_port_0 : process (my_clock, reset, data_bus)
	-- begin
		-- if (reset = '1') then
			-- output_port_0 <= '0';
		-- elsif (rising_edge(my_clock)) then
			-- if (cpu_finish = '1' and n_wr_bus = '0' and cs_bus(OUTPUT_PORT_0_CS) = '0')  then
				-- output_port_0 <= data_bus(0);
			-- end if;
		-- end if;
	-- end process;
	-- ---------------------------------------------------------------------
	
	
	-- ---------------------------------------------------------------------
	-- -- The logic below works for a simple, unbuffered input, no clock required.
	-- -- Test input port - no actual use
	-- input_port_0: data_bus <=
		-- "0000000000000" & address_switches(7 downto 5)  when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"0000" else
		-- "ZZZZZZZZZZZZZZZZ";
	-- ---------------------------------------------------------------------

	-- ---------------------------------------------------------------------
	-- mem_mapped_peripheral : entity work.mem_mapped_fsm
		-- port map (
			-- clk => my_clock,
			-- reset => reset,
			-- cpu_start => cpu_start,
			-- cpu_finish => cpu_finish,
			-- n_cs => cs_bus(SPI_0_CS),
			-- n_rd => n_rd_bus,
			-- n_wr => n_wr_bus,
			-- data_bus => data_bus,
			-- addr_bus => local_addr_bus(3 downto 0)
		-- );
	-- ---------------------------------------------------------------------



	console_uart: entity work.uart_w_fifo
		port map ( 
			clk  => my_clock,
			rx => RXD_BUS,
			tx => TXD_BUS,
			reset => reset,
			cpu_finish => cpu_finish,
			n_cs => cs_bus(CONSOLE_UART_CS),
			n_rd => n_rd_bus,
			n_wr => n_wr_bus,
			data_bus => data_bus,
			addr_bus => local_addr_bus(3 downto 0)
		);


	disk_uart: entity work.uart_w_fifo
		port map ( 
			clk  => my_clock,
			rx => disk_uart_rx,
			tx => disk_uart_tx,
			reset => reset,
			cpu_finish => cpu_finish,
			n_cs => cs_bus(DISK_UART_CS),
			n_rd => n_rd_bus,
			n_wr => n_wr_bus,
			data_bus => data_bus,
			addr_bus => local_addr_bus(3 downto 0),
			rx_fifo_is_half_full => disk_uart_rx_fifo_is_half_full
		);
	
	ptc_uart: entity work.uart_w_fifo
		port map ( 
			clk  => my_clock,
			rx => ptc_uart_rx,
			tx => ptc_uart_tx,
			reset => reset,
			cpu_finish => cpu_finish,
			n_cs => cs_bus(PTC_UART_CS),
			n_rd => n_rd_bus,
			n_wr => n_wr_bus,
			data_bus => data_bus,
			addr_bus => local_addr_bus(3 downto 0),
			rx_fifo_is_quarter_full => ptc_uart_rx_fifo_is_quarter_full
		);
	


	
	
end structural;

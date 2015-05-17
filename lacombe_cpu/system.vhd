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
	address_switches : in std_logic_vector(4 downto 0);
	clock_sw : in std_logic;
	uart_tx : out std_logic;
	uart_rx : in std_logic;
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


	-- 16 single bit inputs
	external_input_port_0 : in std_logic;
	-- external_input_port_1 : in std_logic;
	external_input_port_2 : in std_logic;

   -- Formerly used by Wiznet
--	external_input_port_3 : in std_logic;
	external_input_port_4 : in std_logic;
	external_input_port_5 : in std_logic;
	external_input_port_6 : in std_logic;
	external_input_port_7 : in std_logic;
	external_input_port_8 : in std_logic;
	external_input_port_9 : in std_logic;
	external_input_port_A : in std_logic;
	external_input_port_B : in std_logic;
	external_input_port_C : in std_logic;
	external_input_port_D : in std_logic;
	external_input_port_E : in std_logic;
	external_input_port_F : in std_logic;
	
   -- 16 single bit outputs	
	-- output_port_0 : out std_logic;
	-- output_port_1 : out std_logic;
	output_port_2 : out std_logic;
	output_port_3 : out std_logic;
   -- Formerly used by wiznet code
	output_port_4 : out std_logic;
--	output_port_5 : out std_logic;
--	output_port_6 : out std_logic;
	output_port_7 : out std_logic;
	output_port_8 : out std_logic;
	output_port_9 : out std_logic;
	output_port_A : out std_logic;
	output_port_B : out std_logic;
	output_port_C : out std_logic;
	output_port_D : out std_logic;
	output_port_E : out std_logic;
	output_port_F : out std_logic;
	
   usbwiz_mosi : out std_logic;
   usbwiz_miso : in std_logic;
   usbwiz_sclk : out std_logic;
   
   wiznet_mosi : out std_logic;
   wiznet_miso : in std_logic;
   wiznet_sclk : out std_logic;
   
	clock_selector_switch : in std_logic;

	rx0_in : in std_logic;
	tx0_out : out std_logic;

	rx1_in : in std_logic;
	tx1_out : out std_logic
	
);
end system;



architecture structural of system is
	constant RAM_CS                       : integer := 0;
	constant ROM_CS                       : integer := 1;
	constant UART_0_CS                    : integer := 2;
	constant COUNTER_0_CS                 : integer := 3;
	constant DISK_CTLR_CS                 : integer := 4;
	constant INTERRUPT_CONTROLLER_CS      : integer := 5;
	constant SPI_2_CS                     : integer := 6;
	constant OUTPUT_PORT_0_CS             : integer := 7;
	constant DISK_CTLR_UART_CS            : integer := 8;
	constant INPUT_PORT_0_CS              : integer := 9;
	constant SPI_0_CS                     : integer := 10;
	constant SPI_1_CS                     : integer := 11;

	
	---------------------------------------------------------------------
	component CS_Glue is port (
		addr : in std_logic_vector(19 downto 0);
		CS : out std_logic_vector (15 downto 0));
	end component;
	---------------------------------------------------------------------

	---------------------------------------------------------------------
	component rom is port (
		addr : in std_logic_vector(15 downto 0);
		data : out std_logic_vector(15 downto 0);
		cs : in std_logic);
	end component;
	---------------------------------------------------------------------


	---------------------------------------------------------------------
	component mmu_uart_top is port (
		Clk     : in std_logic;         -- main clock
		Reset_n : in std_logic;         -- main reset
		TXD     : out std_logic;        -- RS232 TX data
		RXD     : in std_logic;         -- RS232 RX data
		ck_div  : in std_logic_vector(15 downto 0);
		-- clock divider value
		-- used to get the baud rate
		-- baud_rate = F(clk) / (ck_div * 3)
		CE_N    : in std_logic;         -- chip enable
		WR_N    : in std_logic;         -- write enable
		RD_N    : in std_logic;         -- read enable
		A0      : in std_logic;         -- 0 - Rx/TX data reg; 1 - status reg
		Data   : inout std_logic_vector(15 downto 0);
		-- interrupt signals- same signals as the status register bits
		RX_full     : out std_logic;
		TX_busy_n   : out std_logic);
	end component;
	---------------------------------------------------------------------



	---------------------------------------------------------------------
	component mem_based_counter is port(
		clock : in  STD_LOGIC;
		reset : in  STD_LOGIC;
		n_rd : in std_logic;
		n_cs : in std_logic;
		x_edge : out  STD_LOGIC;
		x_delayed_out : out  STD_LOGIC;
		x_synced_out : out  STD_LOGIC;
		fast_counter_out : out std_logic_vector(20 downto 0);
		counter_is_zero_out : out std_logic;
		counter_out : out std_logic_vector(15 downto 0));
	end component;
	---------------------------------------------------------------------


	---------------------------------------------------------------------
	component switch_debounce is port ( 
		clock : in std_logic;
		sw : in std_logic;
		y : out std_logic);
	end component;
	---------------------------------------------------------------------

	---------------------------------------------------------------------
	component ClockDivider is port (
		clkin : in std_logic;
		reset : in std_logic;
		slowout : out std_logic_vector(23 downto 0));
	end component;
	---------------------------------------------------------------------


	---------------------------------------------------------------------
	component mem_based_int_controller is port (
		clock : in  STD_LOGIC;
		reset : in  STD_LOGIC;
		address : in  STD_LOGIC_VECTOR (1 downto 0);
		data_bus_0 : inout  STD_LOGIC;
		data_bus_1 : inout  STD_LOGIC;
		data_bus_2 : inout  STD_LOGIC;
		data_bus_3 : inout  STD_LOGIC;
		data_bus_4 : inout  STD_LOGIC;
		data_bus_5 : inout  STD_LOGIC;
		data_bus_6 : inout  STD_LOGIC;
		data_bus_7 : inout  STD_LOGIC;
		data_bus_8 : inout  STD_LOGIC;
		data_bus_9 : inout  STD_LOGIC;
		data_bus_10 : inout  STD_LOGIC;
		data_bus_11 : inout  STD_LOGIC;
		data_bus_12 : inout  STD_LOGIC;
		data_bus_13 : inout  STD_LOGIC;
		data_bus_14 : inout  STD_LOGIC;
		data_bus_15 : inout  STD_LOGIC;
		int_out : out  STD_LOGIC;
		n_cs : in  STD_LOGIC;
		n_wr : in  STD_LOGIC;
		n_rd : in  STD_LOGIC;
		int_in : in  STD_LOGIC_vector(15 downto 0));
	end component;
	---------------------------------------------------------------------

	---------------------------------------------------------------------
   component output_port_16_bits is port ( 
		clock : in std_logic;
		reset : in std_logic;
		n_rd : in  STD_LOGIC;
		n_wr : in  STD_LOGIC;
		n_cs : in  STD_LOGIC;
		address : in std_logic_vector(3 downto 0);
		out_0 : out std_logic;
		out_1 : out std_logic;
		out_2 : out std_logic;
		out_3 : out std_logic;
		out_4 : out std_logic;
		out_5 : out std_logic;
		out_6 : out std_logic;
		out_7 : out std_logic;
		out_8 : out std_logic;
		out_9 : out std_logic;
		out_A : out std_logic;
		out_B : out std_logic;
		out_C : out std_logic;
		out_D : out std_logic;
		out_E : out std_logic;
		out_F : out std_logic;
		data_bus : inout  STD_LOGIC_VECTOR(15 downto 0));
   end component;
	---------------------------------------------------------------------



	---------------------------------------------------------------------
	component output_port_8_words is port (
		clock : in std_logic;
		reset : in std_logic;
		n_rd : in  STD_LOGIC;
		n_wr : in  STD_LOGIC;
		n_cs : in  STD_LOGIC;
		address : in std_logic_vector(2 downto 0);
		int_out : out  STD_LOGIC;
		toggle_status_out : out std_logic;
		out_0 : out std_logic_vector(15 downto 0);
		out_1 : out std_logic_vector(15 downto 0);
		out_2 : out std_logic_vector(15 downto 0);
		out_3 : out std_logic_vector(15 downto 0);
		out_4 : out std_logic_vector(15 downto 0);
		out_5 : out std_logic_vector(15 downto 0);
		out_6 : out std_logic_vector(15 downto 0);
		out_7 : out std_logic_vector(15 downto 0);
		data_bus : inout  STD_LOGIC_VECTOR(15 downto 0));
	end component;
	---------------------------------------------------------------------

	



	component pb_disk_ctlr is 
		generic (
			data_width : natural := 16;
			addr_width : natural := 4
		);
		Port ( 
			clk : in std_logic;
			reset : in std_logic;
			
			uart0_en_16x : in std_logic;
			uart1_en_16x : in std_logic;
			
			rx0_in : in std_logic;
			tx0_out : out std_logic;
			
			rx1_in : in std_logic;
			tx1_out : out std_logic;
			
			-- These signals are for parallel interface to dp ram
			addr_bus : in  STD_LOGIC_VECTOR ((addr_width - 1) downto 0);
			data_bus : inout  STD_LOGIC_VECTOR ((data_width - 1) downto 0);
			n_wr : in  STD_LOGIC;
			n_rd : in  STD_LOGIC;
			n_cs : in  STD_LOGIC
		);	
	end component;

		
		
	
	---------------------------------------------------------------------
	component pulse_gen is
    Port ( clk : in  STD_LOGIC;
           input : in  STD_LOGIC;
           output : out  STD_LOGIC);
	end component;
	---------------------------------------------------------------------

	
		

	
	
	---------------------------------------------------------------------
	component spi_mem_mapped is
    port (
     -- Clock is 100Mhz on Nexys 3 Board
      -- which is divided down to get fsm clock
      clock : in  STD_LOGIC;
      reset : in STD_LOGIC;
      n_cs : in std_logic;
      n_oe : in std_logic;
      n_we : in std_logic;
      address_bus : in std_logic_vector(1 downto 0);
      data_bus : inout std_logic_vector(15 downto 0);
      real_sclock : out STD_LOGIC;
      mosi : out STD_LOGIC;
      miso : in STD_LOGIC);
   end component;
	---------------------------------------------------------------------

	---------------------------------------------------------------------
	component wiznet_spi_mem_mapped is
    port (
     -- Clock is 100Mhz on Nexys 3 Board
      -- which is divided down to get fsm clock
      clock : in  STD_LOGIC;
      reset : in STD_LOGIC;
      n_cs : in std_logic;
      n_oe : in std_logic;
      n_we : in std_logic;
      address_bus : in std_logic_vector(1 downto 0);
      data_bus : inout std_logic_vector(15 downto 0);
      real_sclock : out STD_LOGIC;
      mosi : out STD_LOGIC;
      miso : in STD_LOGIC);
   end component;
	---------------------------------------------------------------------

	

	---------------------------------------------------------------------
	component pb_uart_lacombe is 
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
	end component;
	---------------------------------------------------------------------
	
	
	---------------------------------------------------------------------
	signal my_clock : std_logic;
	signal p5_clock : std_logic;
	signal four_digits : std_logic_vector(15 downto 0);
	signal sw_clock_out : std_logic;
	signal clk_counter : std_logic_vector(23 downto 0);
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
	signal cpu_int : std_logic;
	signal counter_is_zero : std_logic;
	
	signal wiznet_int_pulse : std_logic;
	signal n_external_input_port_4 : std_logic;

	signal en_16x_baud : std_logic;
	signal baud_count : integer range 0 to 500 := 0; 
	
	
	---------------------------------------------------------------------

---------------------------------------------------------------------
begin
	reset_n <= NOT reset;
	uart_tx <= txd_bus;
	rxd_bus <= uart_rx;

	n_wr <= n_wr_bus;
	n_rd <= n_rd_bus;

	parallel_pcm_cs  <= '1';
	parallel_pcm_rst  <= '0';
	cellular_ram_clk <= '0';
	cellular_ram_adv <= '0';
	cellular_ram_cre <= '0';

	---------------------------------------------------------------------
	clk_divider : ClockDivider port map (
		reset => reset,
		clkin => clk,
		slowout => clk_counter
	);
	---------------------------------------------------------------------


	---------------------------------------------------------------------
	u_switch_clock : switch_debounce port map (
		clock => clk_counter(20),
		sw => clock_sw,
		y => sw_clock_out);
	---------------------------------------------------------------------


	---------------------------------------------------------------------
	INT_SW_1 : switch_debounce port map (
		clock => clk_counter(20),
		sw => INT_SW,
		y => INT_SW_OUT);
	---------------------------------------------------------------------

-- Divide 50Mhz Clock by 2 on Spartan 3 starter ; Divide 100Mhz by 8 on Nexys3
--	my_clock <= sw_clock_out when clock_selector_switch = '1' else clk_counter(0);
--	my_clock <= sw_clock_out when clock_selector_switch = '1' else clk_counter(1);
--	my_clock <= sw_clock_out when clock_selector_switch = '1' else clk_counter(10);
	my_clock <= clk_counter(2);
	p5_clock <= clk_counter(3);

	clk_hi_ind <= 	my_clock;
	clk_low_ind <= NOT my_clock;

	-- 
	-- Hardwire UB & LB for RAM access
	--
	n_ub <= '0';
	n_lb <= '0';

	
	
	---------------------------------------------------------------------
	the_cpu : entity work.cpu1 
		port map (
			reset => reset,
			clkin => my_clock,
			n_indicator => n_ind,
			z_indicator => z_ind,
			rd_indicator => rd_ind,
			wr_indicator => wr_ind,
			fetch_indicator => fetch_ind,
			four_digits => four_digits,
			address_switches => address_switches,
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
			clk_counter(15), 
			SevenSegSegments, 
			SevenSegAnodes
		);
	---------------------------------------------------------------------


	---------------------------------------------------------------------
	-- This component provides the chip selects for 
	-- devices on the address and data buses.
	--
	glue_chip : CS_Glue port map (
		addr => local_addr_bus(19 downto 0),
		CS => cs_bus
	);
	---------------------------------------------------------------------


	external_ram_cs <= cs_bus(RAM_CS);
 
	---------------------------------------------------------------------
	the_rom : rom port map (
		addr => local_addr_bus(15 downto 0),
		data => data_bus,
		cs => cs_bus(ROM_CS));
	---------------------------------------------------------------------


	---------------------------------------------------------------------
	counter_0: mem_based_counter port map (
		clock => my_clock,
		reset => reset,
		n_rd => n_rd_bus,
		n_cs => cs_bus(COUNTER_0_CS),
		x_edge => counter_is_zero,
		counter_out => data_bus
	);
	---------------------------------------------------------------------

	---------------------------------------------------------------------
	u_uart :  mmu_uart_top port map (
		Clk => clk_counter(1),						-- Fundamental clock 0->Spartan 1->Nexys
		Reset_n => reset_n,					-- neg assertion reset
		TXD => TXD_BUS,
		RXD => RXD_BUS,
		ck_div => "0000000001001000", -- 72 for 115k ; 18	 (for 460 Kbps)
--		ck_div => "0000001101100000", -- 72 * 12 = 864 for 9600
		CE_N => cs_bus(UART_0_CS),
		WR_N => n_wr_bus,
		RD_N => n_rd_bus,
		A0  => local_addr_bus(0),
		Data  => data_bus,
		--        d_out_8   : out std_logic_vector(7 downto 0); NOT CONNECTED
		-- interrupt signals- same signals as the status register bits
		--        RX_full     : out std_logic;
		--		TX_busy_n => tx_busy_n
		RX_full => RX_FULL,
		tx_busy_n => tx_busy_n
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
	
	
	-- For USB Wiz BUSY, generate an interrupt when it is NOT busy
	multiple_int_sources(4) <= NOT external_input_port_0; -- USB Wiz BUSY; 
	-- For USB Wiz Ready, generate an interrupt when data IS ready
	multiple_int_sources(5) <= external_input_port_2; -- USB Wiz Data is READY; 

   -- The generic wiznet interrupt line (active low)
   n_external_input_port_4 <= NOT external_input_port_4;
	u_wiznet_int_pulse : pulse_gen port map (
	   clk => clk_counter(5), -- clock should be half system clock
		input => n_external_input_port_4,
		output => wiznet_int_pulse);
   multiple_int_sources(6) <= wiznet_int_pulse;
   	
	multiple_int_sources(15 downto 7) <= "000000000";
   
	---------------------------------------------------------------------
   --- Memory mapped SPI Port for usbwiz
   u_spi_port_0 : spi_mem_mapped port map (
      
      clock => my_clock,
      reset => reset,
      n_cs  => cs_bus(SPI_0_CS),
      n_oe  => n_rd_bus,
      n_we  => n_wr_bus,
      address_bus => local_addr_bus(1 downto 0),
      data_bus => data_bus,
      real_sclock => usbwiz_sclk,
      mosi => usbwiz_mosi,
      miso => usbwiz_miso
   );
	---------------------------------------------------------------------
   

	---------------------------------------------------------------------
   --- Memory mapped SPI Port for wiznet tcp/ip chip
   u_spi_port_1 : wiznet_spi_mem_mapped port map (
      
      clock => my_clock,
      reset => reset,
      n_cs  => cs_bus(SPI_1_CS),
      n_oe  => n_rd_bus,
      n_we  => n_wr_bus,
      address_bus => local_addr_bus(1 downto 0),
      data_bus => data_bus,
      real_sclock => wiznet_sclk,
      mosi => wiznet_mosi,
      miso => wiznet_miso
   );
	---------------------------------------------------------------------
   
	

	u_pb_disk_ctlr:  pb_disk_ctlr port map (
		clk => clk,
		reset => reset,
		
		uart0_en_16x => en_16x_baud, -- ok 
		uart1_en_16x => en_16x_baud, -- ok
		
		rx0_in => rx0_in, -- ok, from entity
		tx0_out => tx0_out, -- ok, from entity
		
		rx1_in => rx1_in, -- ok
		tx1_out => tx1_out, -- ok
		
		-- These signals are for parallel interface to dp ram
		addr_bus => local_addr_bus(3 downto 0),
		data_bus => data_bus,
		n_wr => n_wr_bus,
		n_rd => n_rd_bus,
		n_cs => cs_bus(DISK_CTLR_CS)
	);	

		
		

	baud_rate: process(clk)
		begin
			if clk'event and clk = '1' then
				if baud_count = 53 then                    -- counts 54 states including zero
					baud_count <= 0;
					en_16x_baud <= '1';                     -- single cycle enable pulse
				else
					baud_count <= baud_count + 1;
					en_16x_baud <= '0';
				end if;
			end if;
		end process baud_rate;
	
	
	-- u_pb_uart_lacombe_1 : pb_uart_lacombe port map (
			-- clk => clk,
			-- reset => reset,
			-- n_cs => cs_bus(disk_ctlr_uart_cs),
			-- n_oe => n_rd_bus,
			-- n_wr => n_wr_bus,
			-- addr_bus => local_addr_bus(3 downto 0),
			-- data_bus => data_bus,
			-- en_16x_baud => en_16x_baud,
			-- serial_in => test_serial_in,
			-- serial_out => test_serial_out
		-- );
	
			
	
		
	
	
	---------------------------------------------------------------------
	int_controller_1 :  mem_based_int_controller port map (
		clock => my_clock,
		reset => reset,
		address => local_addr_bus(1 downto 0),
		data_bus_0 => data_bus(0),
		data_bus_1 => data_bus(1),
		data_bus_2 => data_bus(2),
		data_bus_3 => data_bus(3),
		data_bus_4 => data_bus(4),
		data_bus_5 => data_bus(5),
		data_bus_6 => data_bus(6),
		data_bus_7 => data_bus(7),
		data_bus_8 => data_bus(8),
		data_bus_9 => data_bus(9),
		data_bus_10 => data_bus(10),
		data_bus_11 => data_bus(11),
		data_bus_12 => data_bus(12),
		data_bus_13 => data_bus(13),
		data_bus_14 => data_bus(14),
		data_bus_15 => data_bus(15),
		int_out => cpu_int,
		n_cs => cs_bus(INTERRUPT_CONTROLLER_CS),
		n_rd => n_rd_bus,
		n_wr => n_wr_bus,
		int_in => multiple_int_sources);
	---------------------------------------------------------------------


	---------------------------------------------------------------------
	u_output_port :  output_port_16_bits port map (	
		clock => my_clock,
		reset => reset,
		n_rd => n_rd_bus,
		n_wr => n_wr_bus,
		n_cs => cs_bus(OUTPUT_PORT_0_CS),
		address => local_addr_bus(3 downto 0),
--		out_0 => output_port_0,
--		out_1 => output_port_1,
		out_2 => output_port_2,
		out_3 => output_port_3,
		out_4 => output_port_4,
--		out_5 => output_port_5,
--		out_6 => output_port_6,
		out_7 => output_port_7,
		out_8 => output_port_8,
		out_9 => output_port_9,
		out_A => output_port_A,
		out_B => output_port_B,
		out_C => output_port_C,
		out_D => output_port_D,
		out_E => output_port_E,
		out_F => output_port_F,
		data_bus => data_bus);
	---------------------------------------------------------------------


	---------------------------------------------------------------------
   -- bit 0 is the USB Wiz READY bit
	--input_port_0 : data_bus <= external_input_port_0 when
	--	(n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') else
	--	"ZZZZZZZZZZZZZZZZ";
	---------------------------------------------------------------------

   input_port_0: data_bus <=
	   "000000000000000" & external_input_port_0 when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"0000" else
--	   "000000000000000" & external_input_port_1 when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"0001" else
	   "000000000000000" & external_input_port_2 when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"0002" else
--	   "000000000000000" & external_input_port_3 when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"0003" else
	   "000000000000000" & external_input_port_4 when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"0004" else
	   "000000000000000" & external_input_port_5 when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"0005" else
	   "000000000000000" & external_input_port_6 when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"0006" else
	   "000000000000000" & external_input_port_7 when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"0007" else
	   "000000000000000" & external_input_port_8 when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"0008" else
	   "000000000000000" & external_input_port_9 when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"0009" else
	   "000000000000000" & external_input_port_A when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"000A" else
	   "000000000000000" & external_input_port_B when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"000B" else
	   "000000000000000" & external_input_port_C when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"000C" else
	   "000000000000000" & external_input_port_D when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"000D" else
	   "000000000000000" & external_input_port_E when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"000E" else
	   "000000000000000" & external_input_port_F when (n_rd_bus = '0' AND cs_bus(INPUT_PORT_0_CS) = '0') AND local_addr_bus(3 downto 0) = x"000F" else
		"ZZZZZZZZZZZZZZZZ";
		

end structural;
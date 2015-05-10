--
-- This is a disk ctlr meant for use by one of the Jamet CPU's
-- It has a parallel SRAM style interface for memory map use
-- It has a serial channel to receive commands from the CPU
-- It has a second serial channel to store data on an external system
--
-- It is implemented with a picoblaze for spartan 6
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
Library UNISIM;
use UNISIM.vcomponents.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity pb_disk_ctlr is 
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
		addr_bus : in  STD_LOGIC_VECTOR ( (addr_width - 1) downto 0);
		data_bus : inout  STD_LOGIC_VECTOR ((data_width - 1) downto 0);
		n_wr : in  STD_LOGIC;
		n_rd : in  STD_LOGIC;
		n_cs : in  STD_LOGIC
	);	
end pb_disk_ctlr;




architecture Behavioral of pb_disk_ctlr is

	constant TX0_DATA_PORT_NUM : std_logic_vector(3 downto 0)      := X"0";
	constant RX0_DATA_PORT_NUM : std_logic_vector(3 downto 0)      := X"1";
	constant UART0_RESET_PORT_NUM : std_logic_vector(3 downto 0)   := X"2";
	constant UART0_STATUS_PORT_NUM : std_logic_vector(3 downto 0)  := X"3";

	constant TX1_DATA_PORT_NUM : std_logic_vector(3 downto 0)      := X"4";
	constant RX1_DATA_PORT_NUM : std_logic_vector(3 downto 0)      := X"5";
	constant UART1_RESET_PORT_NUM : std_logic_vector(3 downto 0)   := X"6";
	constant UART1_STATUS_PORT_NUM : std_logic_vector(3 downto 0)  := X"7";

	constant ADDR_LOW_PORT_NUM : std_logic_vector(3 downto 0)       := X"8";
	constant ADDR_HIGH_PORT_NUM : std_logic_vector(3 downto 0)      := X"9";
	constant ENABLE_PORT_NUM : std_logic_vector(3 downto 0)         := X"A";
	constant WRITE_ENABLE_PORT_NUM : std_logic_vector(3 downto 0)   := X"B";
	constant DPRAM_INPUT_REG_PORT_NUM : std_logic_vector(3 downto 0) := X"C";
	constant DPRAM_OUTPUT_PORT_NUM : std_logic_vector(3 downto 0) := X"D";

	
	-- Addresses used by host cpu NOT the internal picoblaze
	constant DATA_REGISTER_ADDRESS : std_logic_vector(3 downto 0) := X"0";
	constant RESET_REGISTER_ADDRESS : std_logic_vector(3 downto 0) := X"1";
	constant OUT_DATA_REGISTER_ADDRESS : std_logic_vector(3 downto 0) := X"2";

	
	component kcpsm6 
		generic(                 
			hwbuild : std_logic_vector(7 downto 0) := X"00";
			interrupt_vector : std_logic_vector(11 downto 0) := X"3FF";
			scratch_pad_memory_size : integer := 64
		);
		port (                   
			address : out std_logic_vector(11 downto 0);
			instruction : in std_logic_vector(17 downto 0);
			bram_enable : out std_logic;
			in_port : in std_logic_vector(7 downto 0);
			out_port : out std_logic_vector(7 downto 0);
			port_id : out std_logic_vector(7 downto 0);
			write_strobe : out std_logic;
			k_write_strobe : out std_logic;
			read_strobe : out std_logic;
			interrupt : in std_logic;
			interrupt_ack : out std_logic;
			sleep : in std_logic;
			reset : in std_logic;
			clk : in std_logic
		);
	end component;

	component my_program                             
		generic(             
			C_FAMILY : string := "S6"; 
			C_RAM_SIZE_KWORDS : integer := 1;
			C_JTAG_LOADER_ENABLE : integer := 0
		);
		Port (      
			address : in std_logic_vector(11 downto 0);
			instruction : out std_logic_vector(17 downto 0);
			enable : in std_logic;
			rdl : out std_logic;                    
			clk : in std_logic
		);
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

  

--
-- Signals for connection of KCPSM6 and Program Memory.
--
signal         address : std_logic_vector(11 downto 0);
signal     instruction : std_logic_vector(17 downto 0);
signal     bram_enable : std_logic;
signal         in_port : std_logic_vector(7 downto 0);
signal        out_port : std_logic_vector(7 downto 0);
signal         port_id : std_logic_vector(7 downto 0);
signal    write_strobe : std_logic;
signal  k_write_strobe : std_logic;
signal     read_strobe : std_logic;
signal       interrupt : std_logic;
signal   interrupt_ack : std_logic;
signal    kcpsm6_sleep : std_logic;
signal    kcpsm6_reset : std_logic;

--
-- Some additional signals are required if your system also needs to reset KCPSM6. 
--

signal       cpu_reset : std_logic;
signal             rdl : std_logic;

--
-- When interrupt is to be used then the recommended circuit included below requires 
-- the following signal to represent the request made from your system.
--

signal     int_request : std_logic;





	signal tx0_write_strobe : std_logic;
	signal tx0_buffer_reset : std_logic;
	signal rx0_buffer_reset : std_logic;
	signal tx0_buffer_data_present : std_logic;
	signal tx0_buffer_half_full : std_logic;
	signal tx0_buffer_full : std_logic;
	signal rx0_data_out : std_logic_vector(7 downto 0);
	signal rx0_buffer_data_present : std_logic;
	signal rx0_buffer_full : std_logic;
	signal rx0_buffer_half_full : std_logic;
	signal rx0_read_strobe : std_logic;
	signal uart0_status : std_logic_vector(7 downto 0);
	
	signal tx1_write_strobe : std_logic;
	signal tx1_buffer_reset : std_logic;
	signal rx1_buffer_reset : std_logic;
	signal tx1_buffer_data_present : std_logic;
	signal tx1_buffer_half_full : std_logic;
	signal tx1_buffer_full : std_logic;
	signal rx1_data_out : std_logic_vector(7 downto 0);
	signal rx1_buffer_data_present : std_logic;
	signal rx1_buffer_full : std_logic;
	signal rx1_buffer_half_full : std_logic;
	signal rx1_read_strobe : std_logic;
	signal uart1_status : std_logic_vector(7 downto 0);
	
	signal junk : std_logic;

	-- Output registers for dpram control
	signal addr_low_reg : std_logic_vector(7 downto 0);
	signal addr_high_reg : std_logic_vector(7 downto 0);
	signal enable_reg : std_logic_vector(7 downto 0);
	signal write_enable_reg : std_logic_vector(7 downto 0);


	-- Control signals for dpram port A ( used by PicoBlaze in this disk ctlr)
	signal DOA : std_logic_vector(31 downto 0);
	signal DIA : std_logic_vector(31 downto 0);
	signal ADDRA : std_logic_vector(13 downto 0);
	signal ENA : std_logic;
	signal WEA : std_logic_vector(3 downto 0);
	
	-- Control signals for dpram port B (Used by Host CPU)
	signal DOB : std_logic_vector(31 downto 0);
	signal DIB : std_logic_vector(31 downto 0);
	signal ADDRB : std_logic_vector(13 downto 0);
	signal ENB : std_logic;
	signal WEB : std_logic_vector(3 downto 0);
	signal port_a_input_reg : std_logic_vector(7 downto 0);
	signal port_a_output_reg : std_logic_vector(7 downto 0);
	signal output_enable : std_logic;
		

	-- 11 bit register used internally to address dual port ram by host cpu
	-- Host cpu does not know this register exists.  Reads and writes cause 
	-- auto inc based on FSM below
	signal internal_address_reg : std_logic_vector(10 downto 0);

	-- This register is used to asynchronously reset the internal_address_reg
	signal reset_reg : std_logic_vector(15 downto 0);
	
	-- This register is used to hold the value read from dpram
	-- This reg's output will be put on data bus for the host cpu to read
	signal outbound_data_reg : std_logic_vector(15 downto 0);
	

		
	-- Rising edge signal used to increment the internal (to this module) address register
	signal inc_addr : std_logic;
	-- Rising edge signal used to load the internal (to this module) reset register
	signal load_reset : std_logic;
	
	-- rising edge signal used to load internal data_out reg which host CPU will read
	-- ie.  Out from this component; in to the host cpu
	signal load_data_out : std_logic;
	
	
	
	-- combinatorial signal indicating a write to the internal data register 
	-- (or did we forego(sic) the internal reg and use the dpram directly?
	signal write_to_data_in_progress : std_logic;
	-- combinatorial signal indicating a write to the internal reset register
	signal write_to_reset_in_progress : std_logic;
	
	-- combinatorial signal indicating a read from the internal data register
	signal read_from_data_in_progress : std_logic;
	
	
	type state_type is (
		ST_0,
		-- States when host is writing to data register
		WTD_1,
		WTD_2,
		WTD_3,
		-- States when host is writing to reset register
		WTR_1,
		WTR_2,
		-- States when host is reading outbound data register
		RFD_1,
		RFD_2
		);
	signal current_state : state_type;
	signal next_state : state_type; 
	
	
	
	
begin
	kcpsm6_sleep <= '0';
	interrupt <= interrupt_ack;

	u_processor: kcpsm6
		generic map (                 
			hwbuild => X"00", 
			interrupt_vector => X"3FF",
			scratch_pad_memory_size => 64
		)
		port map(      
			address => address,
			instruction => instruction,
			bram_enable => bram_enable,
			port_id => port_id,
			write_strobe => write_strobe,
			k_write_strobe => k_write_strobe,
			out_port => out_port,
			read_strobe => read_strobe,
			in_port => in_port,
			interrupt => interrupt,
			interrupt_ack => interrupt_ack,
			sleep => kcpsm6_sleep,
			reset => kcpsm6_reset, -- NC?  Other examples show no connection, but OK func
			clk => clk
		);

	program_rom: my_program                    --Name to match your PSM file
		generic map(             
			C_FAMILY => "S6",   --Family 'S6', 'V6' or '7S'
			C_RAM_SIZE_KWORDS => 1,      --Program size '1', '2' or '4'
			C_JTAG_LOADER_ENABLE => 1
		)      --Include JTAG Loader when set to '1' 
		port map (      
			address => address,      
			instruction => instruction,
			enable => bram_enable,
			rdl => kcpsm6_reset,
			clk => clk
		);

		
	tx0_write_strobe  <= '1' when (write_strobe = '1' OR k_write_strobe = '1') and 
		(port_id(3 downto 0) = TX0_DATA_PORT_NUM) else '0';                     
		
	tx1_write_strobe  <= '1' when (write_strobe = '1' OR k_write_strobe = '1') and 
		(port_id(3 downto 0) = TX1_DATA_PORT_NUM) else '0';                     



		
	u_output_ports : process(clk)
	begin
		
		if rising_edge(clk) then
			
			if write_strobe = '1' or k_write_strobe = '1' then
				case port_id(3 downto 0) is
					when UART0_RESET_PORT_NUM => 
						tx0_buffer_reset <= out_port(0);
						rx0_buffer_reset <= out_port(1);
					when UART1_RESET_PORT_NUM => 
						tx1_buffer_reset <= out_port(0);
						rx1_buffer_reset <= out_port(1);
						
					-- Output registers used to drive dpram	
					when ADDR_LOW_PORT_NUM =>
						addr_low_reg <= out_port;
					when ADDR_HIGH_PORT_NUM =>
						addr_high_reg <= out_port;
					when ENABLE_PORT_NUM =>
						enable_reg <= out_port;
					when WRITE_ENABLE_PORT_NUM =>
						write_enable_reg <= out_port;
						
					-- port_a_input_reg is an output of the embedded picoblazer
					when DPRAM_INPUT_REG_PORT_NUM =>
						port_a_input_reg <= out_port;

					when others => 
						junk <= '1';
				end case;
			end if;
		end if;
	end process u_output_ports;
		
	u_tx0 : uart_tx6 port map (              
		data_in => out_port, -- from processor, ok
		en_16_x_baud => uart0_en_16x, -- from entity, ok
		serial_out => tx0_out, -- from entity, ok
		buffer_write => tx0_write_strobe, -- set by output ports, ok
		buffer_data_present => tx0_buffer_data_present, -- defined and used in status word,ok
		buffer_half_full => tx0_buffer_half_full,-- defined and used in status word,ok
		buffer_full => tx0_buffer_full,-- defined and used in status word,ok
		buffer_reset => tx0_buffer_reset,    -- driven by output port,ok          
		clk => clk -- from entity, ok
	);

	u_rx0 : uart_rx6 port map (            
		serial_in => rx0_in, -- from entity ok
		en_16_x_baud => uart0_en_16x, -- from entity, ok
		data_out => rx0_data_out, --8 bit parallel data fed to processor input port
		buffer_read => rx0_read_strobe, -- reads from data port, strobe this signal to advance fifo, ok
		buffer_data_present => rx0_buffer_data_present, -- defined & used in status word, ok
		buffer_half_full => rx0_buffer_half_full,-- defined & used in status word, ok
		buffer_full => rx0_buffer_full, -- defined & used in status word, ok
		buffer_reset => rx0_buffer_reset,  -- defined and used in output_port, ok           
		clk => clk
	);


		
	u_tx1 : uart_tx6 port map (              
		data_in => out_port, -- from processor, ok 
		en_16_x_baud => uart1_en_16x, -- from entity, ok
		serial_out => tx1_out, -- from entity, ok
		buffer_write => tx1_write_strobe, -- from output ports, ok
		buffer_data_present => tx1_buffer_data_present,  -- part of status word, ok
		buffer_half_full => tx1_buffer_half_full, -- part of status word, ok
		buffer_full => tx1_buffer_full, -- part of status word, ok
		buffer_reset => tx1_buffer_reset,  -- driven by output port, ok            
		clk => clk
	);

	u_rx1 : uart_rx6 port map (            
		serial_in => rx1_in, -- from entity, ok
		en_16_x_baud => uart1_en_16x, -- from entity ok
		data_out => rx1_data_out, -- paraallel data out, fed to input_port on processor, ok
		buffer_read => rx1_read_strobe, -- reads from data port, strobe this signal, ok
		buffer_data_present => rx1_buffer_data_present, -- part of status workd, ok
		buffer_half_full => rx1_buffer_half_full, -- part of status workd, ok
		buffer_full => rx1_buffer_full, -- part of status workd, ok
		buffer_reset => rx1_buffer_reset,  -- driven by output_port, ok            
		clk => clk
	);

	-- Status bits for uart0 -- ok
	uart0_status <= "00" &
		rx0_buffer_full &
		rx0_buffer_half_full &
		rx0_buffer_data_present &
		tx0_buffer_full &
		tx0_buffer_half_full &
		tx0_buffer_data_present;
		
	-- Status bits for uart1 -- ok
	uart1_status <= "00" &
		rx1_buffer_full &
		rx1_buffer_half_full &
		rx1_buffer_data_present &
		tx1_buffer_full &
		tx1_buffer_half_full &
		tx1_buffer_data_present;
	
	u_input_ports: process(clk)
	begin
		if rising_edge(clk) then
			case port_id(3 downto 0) is
				when UART0_STATUS_PORT_NUM =>  
					in_port <= uart0_status;
				when UART1_STATUS_PORT_NUM =>  
					in_port <= uart1_status;
				when RX0_DATA_PORT_NUM =>
					in_port <= rx0_data_out;
				when RX1_DATA_PORT_NUM =>
					in_port <= rx1_data_out;

					
					-- -- port_a_input_reg is an output of the embedded picoblazer
					-- when DPRAM_INPUT_REG_PORT_NUM =>
						-- port_a_input_reg <= out_port;
					
				when DPRAM_OUTPUT_PORT_NUM =>
					in_port <= DOA(7 downto 0);
				when others =>
					in_port <= "XXXXXXXX";
			end case;

			
			if (read_strobe = '1') and (port_id(3 downto 0) = RX0_DATA_PORT_NUM) then
				rx0_read_strobe <= '1';
			else
				rx0_read_strobe <= '0';
			end if;

			
			if (read_strobe = '1') and (port_id(3 downto 0) = RX1_DATA_PORT_NUM) then
				rx1_read_strobe <= '1';
			else
				rx1_read_strobe <= '0';
			end if;

		end if;
	end process u_input_ports;


	--
	-- Dual Port Ram
	-- Port A is used by the Picoblaze
	-- Port B will be the parallel interface used by the Jamet CPU
	--


	-- 14-bit;  port A address
	-- Notice 3 LSB's are 0 because word size is 8 bits.
	ADDRA <=  addr_high_reg(2 downto 0) & addr_low_reg(7 downto 0) & "000";   
	ENA <= enable_reg(0);

	-- port_a_input_reg is an output of the embedded picoblazer
	DIA <= X"000000" & port_a_input_reg;
	WEA <= write_enable_reg(3 downto 0);  
	
		   
	
	
	
		
			
	ADDRB <=  internal_address_reg & "000";   -- 14-bit B port address
	-- ADDRB <=  "00000000001000";   -- 14-bit B port address
	
	-- ENB now controlled by FSM
	ENB <= (NOT n_cs);
	DIB <= X"0000" & data_bus;

	-- WEB now controlled by FSM 
	-- WEB <= "1111" when n_wr = '0' else "0000";
	output_enable <= (NOT n_rd) and (NOT n_cs);
	-- data_bus <= DOB(15 downto 0)  when (output_enable = '1') else "ZZZZZZZZZZZZZZZZ";
	-- data_bus <= "00000" & internal_address_reg  when (output_enable = '1') else "ZZZZZZZZZZZZZZZZ";
	
	data_bus <= outbound_data_reg  when (output_enable = '1') else "ZZZZZZZZZZZZZZZZ";
	-- data_bus <= DOB(15 downto 0)  when (output_enable = '1') else "ZZZZZZZZZZZZZZZZ";

	
	-- process to set/reset write_to_data_in_progress
	process (n_wr, addr_bus)
	begin	
		if (n_wr = '0' and  n_cs = '0' and addr_bus = DATA_REGISTER_ADDRESS) then
			write_to_data_in_progress <= '1' ;
		else
			write_to_data_in_progress <= '0' ;
		end if;	
	end process;

	-- process to set/reset write_to_data_in_progress
	process (n_wr, n_cs, addr_bus)
	begin	
		if (n_wr = '0' and n_cs = '0' and addr_bus = RESET_REGISTER_ADDRESS) then
			write_to_reset_in_progress <= '1' ;
		else
			write_to_reset_in_progress <= '0' ;
		end if;	
	end process;

	-- process to set/reset read_from_data_in_progress
	process (n_rd, n_cs, addr_bus)
	begin	
		if (n_rd = '0' and n_cs = '0' and addr_bus = OUT_DATA_REGISTER_ADDRESS) then
			read_from_data_in_progress <= '1' ;
		else
			read_from_data_in_progress <= '0' ;
		end if;	
	end process;

	
	
	-- FSM will be used when reading and writing so (among other things)
	-- auto increment function can be implemented.
	SYNC_PROC: process (clk, reset)
	begin
		if (reset = '1') then
			current_state <= ST_0;
		elsif (rising_edge(clk)) then
			current_state <= next_state;
		end if;
	end process;

		
	
	
	process (
		current_state, 
		write_to_data_in_progress,
		write_to_reset_in_progress,
		read_from_data_in_progress)
		
	begin
		next_state <= current_state;
	
		case current_state is
			when ST_0 =>
				if write_to_data_in_progress = '1' then
					next_state <= WTD_1;
				elsif write_to_reset_in_progress = '1' then
					next_state <= WTR_1;
				elsif read_from_data_in_progress = '1' then
					next_state <= RFD_1;					
				end if;
			---------------------------------------------------------
			-- Cases when writing to data (WTD)
			when WTD_1 =>
				next_state <= WTD_2;
			when WTD_2 =>
				next_state <= WTD_3;
			when WTD_3 =>
				if write_to_data_in_progress = '0' then
					next_state <= ST_0;
				end if;
			---------------------------------------------------------
				

			---------------------------------------------------------
			-- Cases when writing to reset (WTR)
			when WTR_1 =>
				next_state <= WTR_2;
			when WTR_2 =>
				if write_to_reset_in_progress = '0' then
					next_state <= ST_0;
				end if;
			---------------------------------------------------------

			
			---------------------------------------------------------
			-- Cases when host is reading outbound data register (RFD)
			when RFD_1 =>
				next_state <= RFD_2;
			when RFD_2 =>
				if read_from_data_in_progress = '0' then
					next_state <= ST_0;
				end if;
			---------------------------------------------------------
				
				
		end case;	
	end process;
	

	-- Moore Outputs (based on FSM current_state only...)
	moore_outputs : process(current_state)
	begin
		WEB <= "0000"; -- defined, OK
		-- ENB <= '0'; -- defined, OK
		inc_addr <= '0'; -- defined, OK 
		load_reset <= '0'; -- defined, OK
		load_data_out <= '0';
		
		case current_state is
			---------------------------------------------------------
			-- Cases when writing to data "WTD"
			when WTD_1 =>
				WEB <= "1111";
			when WTD_2 =>
				WEB <= "1111";
				-- ENB <= '1';
			when WTD_3 =>
				inc_addr <= '1'; -- defined
			---------------------------------------------------------

			
			---------------------------------------------------------
			-- Cases when writing to reset "WTR"
			when WTR_1 =>
				load_reset <= '1';
			---------------------------------------------------------

			---------------------------------------------------------
			-- Cases when reading from outbound data register "RFD"
			when RFD_1 =>
				-- ENB <= '1';
			when RFD_2 =>
				-- ENB <= '1';
				load_data_out <= '1';
				inc_addr <= '1';
			---------------------------------------------------------

			
			---------------------------------------------------------
			-- Added when others b/c ISE complained...
			when others => 
				WEB <= "0000"; -- defined, OK
			---------------------------------------------------------
		end case;
	end process;
	
	process (load_reset) -- load_reset set/reset in FSM
	begin
		if rising_edge(load_reset) then
			reset_reg <= data_bus;
		end if;	
	end process;
	
	
	process (load_data_out) -- load_reset set/reset in FSM
	begin
		if rising_edge(load_data_out) then
			outbound_data_reg <= DOB(15 downto 0);
			-- outbound_data_reg <= X"7845";
		end if;	
	end process;
	
	
	-- Internal address register
	process (reset_reg, inc_addr)
	begin
		if (reset_reg(0) = '1') then
			internal_address_reg <= (others => '0');
		elsif rising_edge(inc_addr) then
			internal_address_reg <= internal_address_reg + 1;
		end if;
	end process;
		
	--
   RAMB16BWER_inst : RAMB16BWER
   generic map (
		-- DATA_WIDTH_A/DATA_WIDTH_B: 0, 1, 2, 4, 9, 18, or 36
	  
		DATA_WIDTH_A => 9,
		DATA_WIDTH_B => 9,
		-- DOA_REG/DOB_REG: Optional output register (0 or 1)
		DOA_REG => 0,
		DOB_REG => 0,
		-- EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
		EN_RSTRAM_A => FALSE,
		EN_RSTRAM_B => FALSE,
		-- INITP_00 to INITP_07: Initial memory contents.
		INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
		-- INIT_00 to INIT_3F: Initial memory contents.
		-- Each row corresponds to 32 bytes (64 hex digits)
		-- There are 64 rows 
		-- 64 rows x 32 bytes = 2KB
		-- Notice the first few bytes have been initialized. - jamet
		-- This is for testing purposes only
		INIT_00 => X"0000000000000000000000000000000000666768696A6B6C6D6E6F7071727374",
		INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
		INIT_3F => X"7153000000000000000000000000000000000000000000000000000000000000",
		-- INIT_A/INIT_B: Initial values on output port
		INIT_A => X"00000000B",
		INIT_B => X"000000C0E",
		-- INIT_FILE: Optional file used to specify initial RAM contents
		INIT_FILE => "NONE",
		-- RSTTYPE: "SYNC" or "ASYNC" 
		RSTTYPE => "SYNC",
		-- RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR" 
		RST_PRIORITY_A => "CE",
		RST_PRIORITY_B => "CE",
		-- SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE" 
		SIM_COLLISION_CHECK => "ALL",
		-- SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
		--SIM_DEVICE => "SPARTAN3ADSP",
		SIM_DEVICE => "SPARTAN6",
		-- SRVAL_A/SRVAL_B: Set/Reset value for RAM output
		SRVAL_A => X"000000000",
		SRVAL_B => X"000000000",
		-- WRITE_MODE_A/WRITE_MODE_B: "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE" 
		WRITE_MODE_A => "WRITE_FIRST",
		WRITE_MODE_B => "WRITE_FIRST" 
	)
   port map (
		-- Port A Data out; It is 32 bits no matter the configured width
		DOA => DOA,       -- 32-bit output: A port data output
		-- Ignoring the parity output on port A
		--DOPA => DOPA, 
		-- Input to dpram is from an output reg driven by embedded picoblaze
		DIA => DIA ,     -- 32-bit input: A port data input
		-- We don't use the parity input.
		DIPA => "0000",     -- 4-bit input: A port parity input

		-- ADDRA is driven by embedded picoblaze
		ADDRA => ADDRA,   
		CLKA => clk,
		ENA => ENA,      
		REGCEA => '0', -- REGCEA, -- 1-bit input: A port register clock enable input
		-- Reset when RST is high?
		RSTA => '0',     -- 1-bit input: A port register set/reset input
		WEA => WEA,       -- 4-bit input: Port A byte-wide write enable input

		--
		-- Port B connections; parallel connection to host

		--	Port B to be treated as SRAM by external system
		-- Port B Address/Control Signals: 14-bit (each) input: Port B address and control signals
		DOB => DOB,       -- 32-bit output: B port data output
		--DOPB => DOPB,     -- 4-bit output: B port parity output
		ADDRB => ADDRB,   -- 14-bit input: B port address input
		CLKB => clk,     -- 1-bit input: B port clock input
		-- ENB => ENB,       -- 1-bit input: B port enable input
		ENB => ENB,       -- 1-bit input: B port enable input
		REGCEB => '0', -- 1-bit input: B port register clock enable input
		RSTB => '0',     -- 1-bit input: B port register set/reset input
		WEB => WEB,       -- 4-bit input: Port B byte-wide write enable input
		--      -- Port B Data: 32-bit (each) input: Port B data
		DIB => DIB,       -- 32-bit input: B port data input
		DIPB => "0000"      -- 4-bit input: B port parity input
   );


end Behavioral;

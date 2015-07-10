---------------------------------------------------------------------
--  uart based on pong chu and Xilinx Coregen Ram
---------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity uart_w_fifo is
	generic (
		DBIT : integer := 8;
		SB_TICK : integer := 16
		-- For simulation only
		-- SB_TICK : integer := 2
	);
    port ( 
		clk : in  STD_LOGIC; -- TODO For now, we assume 50MHz
		rx : in STD_LOGIC;
		reset : in STD_LOGIC;
		cpu_finish : in  STD_LOGIC;
		n_cs : in STD_LOGIC;
		n_rd : in STD_LOGIC;
		n_wr : in STD_LOGIC;
		data_bus : inout STD_LOGIC_VECTOR(15 downto 0);
		addr_bus : in STD_LOGIC_VECTOR(3 downto 0)
	);
end uart_w_fifo;




architecture behavioral of uart_w_fifo is

	-- uart RX fifo write states
	-- These are the states the fifo fsm can be in.
	type w_state_type is (w_state_idle, w_state_0);

	type read_state_type is (read_state_idle, read_state_0);


	signal read_state_reg, read_state_next : read_state_type;
	signal w_state_reg, w_state_next : w_state_type;


	-- type state_type is (state_idle, state_0);
	type state_type is (state_idle, state_start_bit, state_data, state_stop_bit);
	signal state_reg, state_next : state_type;
	
	signal s_reg, s_next : unsigned(3 downto 0);
	signal n_reg, n_next : unsigned(2 downto 0);
	signal b_reg, b_next : std_logic_vector(7 downto 0);
	-- rx_received_byte contains the received byte.
	signal rx_received_byte : std_logic_vector(7 downto 0);

	signal s_tick : std_logic;


	signal is_write_in_progress  : std_logic;
	signal is_rx_fifo_read_in_progress  : std_logic;
	
	signal val_reg, val_next : std_logic_vector(15 downto 0);
	signal rx_done_tick : std_logic;
	
	signal buf_reg, buf_next : std_logic_vector(7 downto 0); 
	signal flag_reg, flag_next : std_logic; 
	signal clr_flag, clr_next : std_logic; 
	
	signal buffer_out : std_logic_vector(15 downto 0); 
	signal flag_out : std_logic;
	
	
	signal num_bytes_in_rx_fifo_next, num_bytes_in_rx_fifo_reg : std_logic_vector(9 downto 0);
	signal rx_fifo_in_addr_next, rx_fifo_in_addr : std_logic_vector(9 downto 0);
	signal rx_fifo_out_addr_next, rx_fifo_out_addr : std_logic_vector(9 downto 0);
	signal wea_reg, wea_next, wea : std_logic_vector(0 downto 0);
	
	signal rx_fifo_data_out : std_logic_vector(7 downto 0);
	

	COMPONENT blk_mem_gen_v7_3
		PORT (
			clka : IN STD_LOGIC;
			wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			clkb : IN STD_LOGIC;
			addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	END COMPONENT;
	
	
begin
	data_bus <= (others => 'Z');

	
	-----------------------------------------------------------------
	-- These 2 signals indicate either a memory read or write is in 
	-- progress by the host.
	-- They are asserted during the entire microcode cycle.
	-- They are NOT edge based.
	-- Please note all reads and writes are from the host's perspective
	is_rx_fifo_read_in_progress  <= '1' when ((n_cs = '0') and (n_rd = '0')) else '0';
	is_write_in_progress <= '1' when ((n_cs = '0') and (n_wr = '0')) else '0';
	-----------------------------------------------------------------

	
	
	-----------------------------------------------------------------
	ticker: entity work.mod_m 
		generic map(
			N => 5, -- num bits
			-- 50 * 10^6 / (16 * 19200)
			-- M => 163  -- MOD M (Should lead to 19200 bps w/50MHz clock)
			M => 27  -- MOD M (27 Should lead to 115200 bps w/50MHz clock)
			-- M => 2 -- for simulation only
		)
		port map(
			clk => clk, 
			reset => reset,
			max_tick => s_tick
		);
	-----------------------------------------------------------------
	
 
	-----------------------------------------------------------------
	-----------------------------------------------------------------
	-- Synchronous process associated with serial rx input
	-- All that happens here is the state change
	-- AND assignment of any internal storage
	process(
		clk, reset, 
		state_next,
		s_next, n_next, b_next
	)
	begin
		if reset = '1' then
			state_reg <= state_idle;

			s_reg <= (others => '0');
			n_reg <= (others => '0');
			b_reg <= (others => '0');
						
		elsif (rising_edge(clk)) then
			state_reg <= state_next;
			
			s_reg <= s_next;
			n_reg <= n_next;
			b_reg <= b_next;
			
		end if;	
	end process;
	-----------------------------------------------------------------

	
	-----------------------------------------------------------------
	-- Combinational State selection
	-- This process receives async char from serial port and 
	-- stores result in b_reg
	process (
		state_reg, 
		rx,
		s_reg,
		n_reg,
		b_reg,
		s_tick
	)
	begin
		state_next <= state_reg;
		s_next <= s_reg;
		n_next <= n_reg;
		b_next <= b_reg;
		rx_done_tick <= '0';
		

		case state_reg is 
			when state_idle =>
				if (rx = '0') then
					state_next <= state_start_bit;
					s_next <= (others => '0');
				end if;
				

			when state_start_bit =>
				-- We entered this state because we saw beginning
				-- of start bit; now we synchronize to the middle (s_reg = 7)
				if (s_tick = '1') then
					if (s_reg = 7) then
						state_next <= state_data;
						s_next <= (others => '0');
						n_next <= (others => '0');
					else
						s_next <= s_reg + 1;
					end if;
				end if;

			when state_data =>
				if (s_tick = '1') then
					if  (s_reg = (SB_TICK - 1)) then
						s_next <= (others => '0');
						b_next <= rx & b_reg(7 downto 1);
						if (n_reg = (DBIT - 1)) then
							state_next <= state_stop_bit;
						else
							n_next <= n_reg + 1;
						end if;
					else
						s_next <= s_reg + 1;
					end if;
				end if;
				
			when state_stop_bit =>
				if (s_tick = '1') then
					if (s_reg = (SB_TICK - 1)) then 
						state_next <= state_idle;
						rx_done_tick <= '1';
					else
						s_next <= s_reg + 1;
					end if;
				end if;
		end case;
	end process;
	
	-- rx_received_byte is the continuously updated val from b_reg
	-- the serially received byte.
	-- rx_received_byte is the value to be captured by the one word buffer below.
	rx_received_byte <= b_reg;
	-----------------------------------------------------------------
	-----------------------------------------------------------------
	



	
	-----------------------------------------------------------------
	-----------------------------------------------------------------
	-- This is the FIFO for use with the uart receiver
	-- It makes use of a 1K * 8 coregen ram : blk_mem_gen_v7_3
	-- It uses an FSM for memory reads and writes
	-----------------------------------------------------------------
	-----------------------------------------------------------------

	-- 1K, 16 bit word ram generated by coregen
	wea <= wea_reg;
	
	u_1k_block : blk_mem_gen_v7_3
		PORT MAP (
			clka => clk, -- clk from entity
			wea => wea,
			addra => rx_fifo_in_addr,
			dina => rx_received_byte,
			clkb => clk,
			addrb => rx_fifo_out_addr,
			doutb => rx_fifo_data_out
		);




	-----------------------------------------------------------------
	-- Host Read/Write FSM Synchronous process 
	-- All that happens here is the state change
	-- AND assignment of any internal storage
	--
	-- The RAM is written on port A with an auto incrementing address
	-- Writes are triggered by the uart rx sub system
	-- The RAM is read on port B and its output drives the databus
	process(
		clk, reset, 
		w_state_next, 
		wea_next,
		val_next
	)
	begin
		if reset = '1' then
			w_state_reg <= w_state_idle;
			read_state_reg <= read_state_idle;
			wea_reg <= "0";
			rx_fifo_in_addr <= (others => '0');
			num_bytes_in_rx_fifo_reg <= (others => '0');
			rx_fifo_out_addr <= (others => '0');
			val_reg <= (others => '0');
			
		elsif (rising_edge(clk)) then
			val_reg <= val_next;
			w_state_reg <= w_state_next;
			read_state_reg <= read_state_next;
			wea_reg <= wea_next;
			rx_fifo_in_addr <= rx_fifo_in_addr_next;
			rx_fifo_out_addr <= rx_fifo_out_addr_next;
			num_bytes_in_rx_fifo_reg <= num_bytes_in_rx_fifo_next;
		end if;	
	end process;
	-----------------------------------------------------------------


	
	-----------------------------------------------------------------
	-- FSM State Selector for RX FIFO writes
	-- An RX FIFO write is triggered by the uart rcvr rx_done_tick
	-- This FSM loads the byte from the uart rx and updates the ram address
	process (
		w_state_reg, 
		is_write_in_progress, 
		rx_done_tick,
		rx_fifo_in_addr,
		num_bytes_in_rx_fifo_reg
	)
	begin
		w_state_next <= w_state_reg;
		wea_next <= "0";
		rx_fifo_in_addr_next <= rx_fifo_in_addr;
		
		case w_state_reg is 
			-- A memory cycle can't begin until cpu_finish is asserted
			-- so we wait for it in the idle state.
			when w_state_idle =>
				if (rx_done_tick = '1') then
					wea_next <= "1";
					w_state_next <= w_state_0;
				end if;
				
			-- We know a memory cycle may be in progress;
			-- Is it addressed to us?
			when w_state_0 =>
				w_state_next <= w_state_idle;
				if (rx_fifo_in_addr = 1023) then
					rx_fifo_in_addr_next <= (others => '0');
				else
					rx_fifo_in_addr_next <= rx_fifo_in_addr + 1;
				end if;
				num_bytes_in_rx_fifo_next <= num_bytes_in_rx_fifo_reg + 1;
				
		end case;
	end process;
	-----------------------------------------------------------------


	
	
	-----------------------------------------------------------------
	-- Combinational State selection
	-- for HOST memory read FSM
	-- This process handles read requests (of the RX FIFO) from a host
	process (
		read_state_reg, 
		val_reg,
		is_rx_fifo_read_in_progress,
		rx_fifo_data_out,
		rx_fifo_out_addr,
		cpu_finish
	)
	begin
		read_state_next <= read_state_reg;
		val_next <= val_reg;
		rx_fifo_out_addr_next <= rx_fifo_out_addr;
		
		case read_state_reg is 
			-- A memory cycle can't begin until cpu_finish is asserted
			-- so we wait for it in the idle state.
			when read_state_idle =>

				if (cpu_finish = '1') then
					read_state_next <= read_state_0;
				end if;
				
			-- We know a memory cycle may be in progress;
			-- Is it addressed to us?
			when read_state_0 =>
				if (is_rx_fifo_read_in_progress = '1') then
					read_state_next <= read_state_idle;
					val_next <= X"00" & rx_fifo_data_out;
					if (rx_fifo_out_addr = 1023) then
						rx_fifo_out_addr_next <= (others => '0');
					else
						rx_fifo_out_addr_next <= rx_fifo_out_addr + 1;
					end if;
				else
				 	read_state_next <= read_state_idle;
				end if;
				
				
		end case;
	end process;
	-----------------------------------------------------------------

	

	-----------------------------------------------------------------
	-- If a HOST read is in progress (determined combinatorially),
	-- we drive the data bus with the register containing the 
	-- the requested value val_reg.  val_reg was populated
	-- by the FSM above.
	process (is_rx_fifo_read_in_progress, val_reg)
	begin
		if (is_rx_fifo_read_in_progress = '1') then
			data_bus <= val_reg;
		else
			data_bus <= (others => 'Z');
		end if;	
	end process;
	-----------------------------------------------------------------
	
end behavioral;

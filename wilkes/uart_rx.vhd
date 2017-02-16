---------------------------------------------------------------------
--  uart based on pong chu receiver
---------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
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
end uart_rx;


architecture behavioral of uart_rx is

	-- type state_type is (state_idle, state_0);
	type state_type is (state_idle, state_start_bit, state_data, state_stop_bit);
	signal state_reg, state_next : state_type;
	
	signal s_reg, s_next : unsigned(3 downto 0);
	signal n_reg, n_next : unsigned(2 downto 0);
	signal b_reg, b_next : std_logic_vector(7 downto 0);
	-- dout contains the received byte.
	signal dout : std_logic_vector(7 downto 0);

	signal s_tick : std_logic;


	type read_state_type is (read_state_idle, read_state_0);
	signal read_state_next, read_state_reg : read_state_type;

	signal is_write_in_progress  : std_logic;
	signal is_read_in_progress  : std_logic;
	
	signal val_reg, val_next : std_logic_vector(15 downto 0);
	signal rx_done_tick : std_logic;
	
	signal buf_reg, buf_next : std_logic_vector(7 downto 0); 
	signal flag_reg, flag_next : std_logic; 
	signal clr_flag, clr_next : std_logic; 
	
	signal buffer_out : std_logic_vector(15 downto 0); 
	signal flag_out : std_logic;
	
	
begin
	data_bus <= (others => 'Z');

	-----------------------------------------------------------------
	-- This signals indicate either a  write is in 
	-- progress by the host.
	-- It is asserted during the entire microcode cycle.
	-- It is NOT edge based.
	-- Please note all reads and writes are from the host's perspective
	-- is_write_in_progress <= '1' when ((n_cs = '0') and (n_wr = '0')) else '0';
	is_read_in_progress  <= '1' when ((n_cs = '0') and (n_rd = '0')) else '0';
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
	
	-- dout is the continuously updated val from b_reg
	-- the serially received byte.
	-- dout is the value to be captured by the one word buffer below.
	dout <= b_reg;
	-----------------------------------------------------------------
	-----------------------------------------------------------------
	




	-----------------------------------------------------------------
	-----------------------------------------------------------------
	-- One byte buffer buffer and flag indicating buffer is full
	-- buffer input comes from the uart rx fsm : dout
	process (clk, reset)
	begin
		if (reset = '1') then
			buf_reg <= (others => '0');
			flag_reg <= '0';
		elsif (rising_edge(clk)) then
			buf_reg <= buf_next;
			flag_reg <= flag_next;
		end if;
	end process;
	
	process (buf_reg, flag_reg, rx_done_tick, clr_flag, dout)
	begin
		buf_next <= buf_reg;
		flag_next <= flag_reg;
		if (rx_done_tick = '1') then
			buf_next <= dout;
			flag_next <= '1';
		elsif (clr_flag = '1') then
			flag_next <= '0';
		end if;
	end process;
	
	buffer_out <= X"00" & buf_reg;
	flag_out <= flag_reg;
	-----------------------------------------------------------------
	-----------------------------------------------------------------

 
	-----------------------------------------------------------------
	-- Synchronous process for 
	-- FSM handling host read requests
	-- All that happens here is the state change
	-- AND assignment of any internal storage
	process(
		clk, reset, 
		read_state_next, 
		val_next
	)
	begin
		if reset = '1' then
			read_state_reg <= read_state_idle;			
		elsif (rising_edge(clk)) then
			read_state_reg <= read_state_next;
			val_reg <= val_next;
			clr_flag <= clr_next;
		end if;	
	end process;
	-----------------------------------------------------------------

	
	-----------------------------------------------------------------
	-- Combinational State selection
	-- This process handles read requests from a host
	process (
		read_state_reg, 
		val_reg,
		is_read_in_progress, 
		addr_bus, cpu_finish,
		buffer_out, flag_out
	)
	begin
		read_state_next <= read_state_reg;
		val_next <= val_reg;
		clr_next <= '0';

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
				if (is_read_in_progress = '1') then
					read_state_next <= read_state_idle;
					if (addr_bus = X"0") then
						val_next <= buffer_out;
						clr_next <= '1';
					elsif (addr_bus = X"1") then
						val_next <= X"000" & "000" & flag_out;
					end if;
				end if;
		end case;
	end process;
	-----------------------------------------------------------------


	-----------------------------------------------------------------
	-- If a read is in progress (determined combinatorially),
	-- we drive the data bus with the register containing the 
	-- the requested value val_reg.  val_reg was populated
	-- by the state machine above.
	process (is_read_in_progress, val_reg)
	begin
		if (is_read_in_progress = '1') then
			data_bus <= val_reg;
		else
			data_bus <= (others => 'Z');
		end if;	
	end process;
	-----------------------------------------------------------------
	
	
end behavioral;

---------------------------------------------------------------------
--  uart based on pong chu transmitter
---------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx_test is
	generic (
		DBIT : integer := 8;
		SB_TICK : integer := 16
		-- For simulation only
		-- SB_TICK : integer := 2
	);
    port ( 
		clk : in  STD_LOGIC; -- TODO For now, we assume 50MHz
		reset : in STD_LOGIC;
		cpu_start : in  STD_LOGIC;
		cpu_finish : in  STD_LOGIC;
		n_cs : in STD_LOGIC;
		n_rd : in STD_LOGIC;
		n_wr : in STD_LOGIC;
		data_bus : inout STD_LOGIC_VECTOR(15 downto 0);
		addr_bus : in STD_LOGIC_VECTOR(3 downto 0);
		tx : out std_logic
	);
end uart_tx_test;


architecture behavioral of uart_tx_test is

	-- type state_type is (state_idle, state_0);
	type state_type is (state_idle, state_0, state_start_bit, state_data, state_stop_bit);
	signal state_reg, state_next : state_type;
	
	signal s_reg, s_next : unsigned(3 downto 0);
	signal n_reg, n_next : unsigned(2 downto 0);
	signal b_reg, b_next : std_logic_vector(7 downto 0);
	signal tx_reg, tx_next : std_logic;

	signal s_tick : std_logic;
	
	signal is_write_in_progress : std_logic;
	signal is_read_in_progress  : std_logic;
	
	signal is_transmitter_busy  : std_logic;
	
	signal val_reg : std_logic_vector(15 downto 0);
	
	
begin
	data_bus <= (others => 'Z');

	-----------------------------------------------------------------
	-- This signals indicate either a  write is in 
	-- progress by the host.
	-- It is asserted during the entire microcode cycle.
	-- It is NOT edge based.
	-- Please note all reads and writes are from the host's perspective
	is_write_in_progress <= '1' when ((n_cs = '0') and (n_wr = '0')) else '0';
	is_read_in_progress  <= '1' when ((n_cs = '0') and (n_rd = '0')) else '0';
	-----------------------------------------------------------------

 
	-----------------------------------------------------------------
	-- Synchronous process 
	-- All that happens here is the state change
	-- AND assignment of any internal storage
	process(
		clk, reset, 
		state_next,
		s_next, n_next, b_next, tx_next
	)
	begin
		if reset = '1' then
			state_reg <= state_idle;

			s_reg <= (others => '0');
			n_reg <= (others => '0');
			b_reg <= (others => '0');
			
			tx_reg <= '1';
			
		elsif (rising_edge(clk)) then
			state_reg <= state_next;
			
			s_reg <= s_next;
			n_reg <= n_next;
			b_reg <= b_next;
			
			tx_reg <= tx_next;
			
		end if;	
	end process;
	-----------------------------------------------------------------

	
	-----------------------------------------------------------------
	ticker: entity work.mod_m 
		generic map(
			N => 10, -- num bits
			-- 50 * 10^6 / (16 * 19200)
			-- M => 163  -- MOD M (Should lead to 19200 bps w/50MHz clock)
			M => 27  -- MOD M (Should lead to 115200 bps w/50MHz clock)
			-- M => 2 -- for simulation only
		)
		port map(
			clk => clk, 
			reset => reset,
			max_tick => s_tick
		);
	-----------------------------------------------------------------
	
	
	-----------------------------------------------------------------
	-- Combinational State selection
	-- This process handles read requests from a host
	process (
		state_reg, 
		s_reg,
		n_reg,
		b_reg,
		s_tick,
		tx_reg,
		is_write_in_progress, 
		cpu_finish, 
		data_bus
	)
	begin
		state_next <= state_reg;
		s_next <= s_reg;
		n_next <= n_reg;
		b_next <= b_reg;
		tx_next <= tx_reg;
		
		is_transmitter_busy <= '0';
		-- tx_done_tick <= '0';

		case state_reg is 
			-- A memory cycle can't begin until cpu_finish is asserted
			-- so we wait for it in the idle state.
			when state_idle =>
				tx_next <= '1';
				if (cpu_finish = '1') then
					state_next <= state_0;
				end if;
				
			-- We know a memory cycle may be in progress;
			-- Is it addressed to us?
			when state_0 =>
				-- tx_next <= '1';
				if (is_write_in_progress = '1') then
					state_next <= state_start_bit;
					b_next <= data_bus(7 downto 0);
					s_next <= (others => '0');
				else
				 	state_next <= state_idle;
				end if;

			when state_start_bit =>
				is_transmitter_busy <= '1';
				-- Drive the start bit and 
				-- hold it for 16 cycles
				tx_next <= '0'; 
				if (s_tick = '1') then
					if (s_reg = (SB_TICK - 1)) then
						state_next <= state_data;
						s_next <= (others => '0');
						n_next <= (others => '0');
					else
						s_next <= s_reg + 1;
					end if;
				end if;

			when state_data =>
				is_transmitter_busy <= '1';
				tx_next <= b_reg(0);
				if (s_tick = '1') then
					if  (s_reg = (SB_TICK - 1)) then
						s_next <= (others => '0');
						b_next <= '0' & b_reg(7 downto 1);
						if (n_reg = 7) then
							state_next <= state_stop_bit;
						else
							n_next <= n_reg + 1;
						end if;
					else
						s_next <= s_reg + 1;
					end if;
				end if;
				
			when state_stop_bit =>
				is_transmitter_busy <= '1';
				tx_next <= '1';
				if (s_tick = '1') then
					if (s_reg = (SB_TICK - 1)) then 
						state_next <= state_idle;
						-- tx_done_tick <= '1';
					else
						s_next <= s_reg + 1;
					end if;
				end if;
		end case;
	end process;
	
	tx <= tx_reg;
	
	val_reg <= X"000" & "000" & is_transmitter_busy;
	
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






----------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cpu_timing_generator is
    Port ( 
		clk : in  STD_LOGIC;
		reset : in STD_LOGIC;
		cpu_start : out  STD_LOGIC;
		cpu_finish : out  STD_LOGIC;
		pause : in  STD_LOGIC
	);
end cpu_timing_generator;

architecture Behavioral of cpu_timing_generator is

	constant N : unsigned := "00011";

	type state_type is (state_idle, state_0, state_1, state_2);
	signal state_reg, state_next : state_type;
	
	signal L : std_logic;
	signal H : std_logic;
	
	signal count_0, count_0_next : unsigned(4 downto 0);
	signal count_2, count_2_next : unsigned(4 downto 0);

begin

	-----------------------------------------------------------------
	process(clk, reset)
	begin
		if reset = '1' then
			state_reg <= state_idle;
			-- L <= '1';
			-- H <= '0';
		elsif (rising_edge(clk)) then
			state_reg <= state_next;
			count_0 <= count_0_next;
			count_2 <= count_2_next;
		end if;	
	end process;
	-----------------------------------------------------------------


	-----------------------------------------------------------------
	-- Combinational State selection and state based output (i.e. Moore output)

	-- Leads to state 0 being N -1  cycles long; state 1 being 1 cycle long
	-- state 2 being N cycles long
	-- For a TOTAL of 2N cycles.
	
	process (state_reg, count_0, count_0_next, count_2, count_2_next)

	-- This process statement is NG; count (nexts) have to be included
	-- process (state_reg, count_0, count_2)
	begin
		state_next <= state_reg;
		
		case state_reg is 
			when state_idle =>
				state_next <= state_0;
				L <= '1';
				H <= '0';
				count_0_next <= N - 1;
			when state_0 =>
				count_0_next <= count_0 - 1;
				if (count_0_next = 0) then
					state_next <= state_1;
				end if;
				L <= '0';
				H <= '0';
			when state_1 =>
				state_next <= state_2;
				L <= '0';
				H <= '1';
				count_2_next <= N;
			when state_2 =>
				count_2_next <= count_2 - 1;
				if (count_2_next = 0) then
					state_next <= state_0;
					count_0_next <= N - 1;
				end if;
				L <= '1';
				H <= '0'; 
		end case;
	end process;
	-----------------------------------------------------------------


	cpu_start <= L;
	cpu_finish <= H;

end Behavioral;


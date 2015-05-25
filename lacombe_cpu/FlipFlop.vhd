--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity FlipFlop is
    Port ( 
		clk : in std_logic;
		input : in std_logic;
		output : out std_logic;
		load : in std_logic
	);
end FlipFlop;

architecture Behavioral of FlipFlop is

begin

process (clk, load)
begin
	if (rising_edge(clk)) then
		if (load = '1') then
			output <= input;
		end if;
	end if;
end process;
 
end Behavioral;

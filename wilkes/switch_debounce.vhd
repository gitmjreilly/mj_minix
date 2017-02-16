library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--
-- The clock input should be in the 20Hz range
--
entity switch_debounce is Port ( 
	clock : in std_logic;
	sw : in std_logic;
	y : out std_logic);
end switch_debounce;

architecture Behavioral of switch_debounce is

begin
	process (clock) 
	begin
		if rising_edge(clock) then
				y <= sw;
		end if;
	end process;
end Behavioral;

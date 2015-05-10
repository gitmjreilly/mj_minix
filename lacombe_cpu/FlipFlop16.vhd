--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity FlipFlop16 is
    Port ( input : in std_logic_vector(15 downto 0);
           output : out std_logic_vector(15 downto 0);
			  latch : in std_logic;
           clock : in std_logic);
end FlipFlop16;

architecture Behavioral of FlipFlop16 is

begin

process (clock)
begin
   if clock'event and clock = '1' then 
		if (latch = '1') then
			output <= input;
		end if;
   end if;
end process;
 
end Behavioral;

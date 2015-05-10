--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity FlipFlop is
    Port ( input : in std_logic;
           output : out std_logic;
           clock : in std_logic);
end FlipFlop;

architecture Behavioral of FlipFlop is

begin

process (clock)
begin
   if clock'event and clock = '1' then  
      output <= input;
   end if;
end process;
 
end Behavioral;

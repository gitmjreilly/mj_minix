--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity ClockDivider is
	Port ( 
		clkin : in std_logic;
		reset : in std_logic;
		slowout : out std_logic_vector(23 downto 0));
end ClockDivider;

architecture Behavioral of ClockDivider is

signal InternalState : std_logic_vector(23 downto 0);

begin
process (clkin, reset) 
begin
	if (reset = '1') then
		InternalState <= (others => '0');
   elsif  clkin ='1' and clkin'event then
      InternalState <= InternalState + 1;
   end if;
end process;
 
slowout <= InternalState;
end Behavioral;

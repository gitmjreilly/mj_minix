library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity buf16 is
    Port ( input : in std_logic_vector(15 downto 0);
           output : out std_logic_vector(15 downto 0);
           oe : in std_logic);
end buf16;

architecture Behavioral of buf16 is

begin
	output <= input when (oe = '1') else "ZZZZZZZZZZZZZZZZ";
end Behavioral;

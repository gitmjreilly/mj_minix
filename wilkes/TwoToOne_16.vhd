library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TwoToOne_16 is
    Port ( in1 : in std_logic_vector(15 downto 0);
           in2 : in std_logic_vector(15 downto 0);
           out1 : out std_logic_vector(15 downto 0);
           loadp1 : in std_logic;
           loadp2 : in std_logic);
end TwoToOne_16;

architecture Behavioral of TwoToOne_16 is

signal input_selector : std_logic_vector(1 downto 0);

begin
	input_selector(0) <= loadp1;
	input_selector(1) <= loadp2;
	with input_selector select
		out1 <=
			in1 when "01",
			in2 when "10",
			"ZZZZZZZZZZZZZZZZ" when others;

end Behavioral;

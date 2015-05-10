--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity SevenSegDriver is
    Port ( Digit3 : in std_logic_vector(3 downto 0);
           Digit2 : in std_logic_vector(3 downto 0);
           Digit1 : in std_logic_vector(3 downto 0);
           Digit0 : in std_logic_vector(3 downto 0);
           clkin : in std_logic;
			  Segments : out std_logic_vector(7 downto 0);
			  Anodes : out std_logic_vector(3 downto 0));
end SevenSegDriver;

architecture Behavioral of SevenSegDriver is

signal InternalState : std_logic_vector(1 downto 0);
signal ReceivedVal : std_logic_vector(3 downto 0);

begin

	-- Create a simple 4 bit counter to drive the anodes
	process (clkin) 
	begin
		if  clkin ='1' and clkin'event then
			InternalState <= InternalState + 1;
		end if;
	end process;
 
	-- Drive ONE anode based on counter value
	process (InternalState, Digit0, Digit1, Digit2, Digit3, ReceivedVal) 
	variable InternalSegs : std_logic_vector(7 downto 0);

	begin
		if (InternalState = "00") then
			Anodes <= "1110";
--         Anodes <= "1111";
			ReceivedVal <= Digit0;
		elsif (InternalState = "01") then
			Anodes <= "1101";
--         Anodes <= "1111";
			ReceivedVal <= Digit1;
		elsif (InternalState = "10") then
			Anodes <= "1011";
--         Anodes <= "1111";
			ReceivedVal <= Digit2;
		elsif (InternalState = "11") then
			Anodes <= "0111";
--         Anodes <= "1111";
			ReceivedVal <= Digit3;
		else
--         Anodes <= (others => '1');
         Anodes <= "1111";
			ReceivedVal <= (others => '1');
		end if;

		if (ReceivedVal = "0000") then
			Segments <= "00000011";
		elsif (ReceivedVal = "0001") then
			Segments <= "10011111";
		elsif (ReceivedVal = "0010") then
			Segments <= "00100101";
		elsif (ReceivedVal = "0011") then
			Segments <= "00001101";
		elsif (ReceivedVal = "0100") then
			Segments <= "10011001";
		elsif (ReceivedVal = "0101") then
			Segments <= "01001001";
		elsif (ReceivedVal = "0110") then
			Segments <= "01000001";
		elsif (ReceivedVal = "0111") then
			Segments <= "00011111";
		elsif (ReceivedVal = "1000") then
			Segments <= "00000001";
		elsif (ReceivedVal = "1001") then
			Segments <= "00001001";
		elsif (ReceivedVal = "1010") then
			Segments <= "00010001";
		elsif (ReceivedVal = "1011") then
			Segments <= "11000001";
		elsif (ReceivedVal = "1100") then
			Segments <= "01100011";
		elsif (ReceivedVal = "1101") then
			Segments <= "10000101";
		elsif (ReceivedVal = "1110") then
			Segments <= "01100001";
		elsif (ReceivedVal = "1111") then
			Segments <= "01110001";
		else
         Segments <= (others => '1');
		end if;

	end process;


end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pulse_gen is
    Port ( clk : in  STD_LOGIC;
           input : in  STD_LOGIC;
           output : out  STD_LOGIC);
end pulse_gen;



architecture Behavioral of pulse_gen is
signal d1 : std_logic;
signal d2 : std_logic;

begin

u_d1: process (clk)
begin
   if clk'event and clk = '1' then  
      d1 <= input;
   end if;
end process;
 
u_d2: process (clk)
begin
   if clk'event and clk = '1' then  
      d2 <= d1;
   end if;
end process;
 
pulse: output <= (d1 AND (NOT d2));

end Behavioral;


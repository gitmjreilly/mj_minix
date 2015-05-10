
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity pb_port_8 is
    Port ( in_8 : in  STD_LOGIC_VECTOR (7 downto 0);
           out_8 : out  STD_LOGIC_VECTOR (7 downto 0);
			  clk : in STD_LOGIC;
			  cs  : in STD_LOGIC;
           write_strobe : in  STD_LOGIC);
end pb_port_8;



architecture Behavioral of pb_port_8 is

begin
  process(clk)
  begin
  if clk'event and clk = '1' then

      -- 'write_strobe' is used to qualify all writes to general output ports.
      if (write_strobe = '1') AND (cs = '0') then
	      out_8 <= in_8;
	   end if;
  end if;
  end process;

end Behavioral;


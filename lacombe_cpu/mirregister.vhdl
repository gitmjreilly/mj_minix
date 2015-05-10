library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity MIRRegister is
    Port ( in1           : in  std_logic_vector((40) downto 0);
           out1          : out std_logic_vector((40) downto 0);
			  latch         : in  std_logic;
			  reset			: in std_logic );
end MIRRegister;

architecture behave of MIRRegister is

signal InternalState : std_logic_vector(40 downto 0);

begin
	out1 <= InternalState;

	process (latch, reset)
	begin	
		if reset = '1' then
         InternalState <= (others => '0');
      elsif	latch'event and latch='0' then  
				InternalState <= in1;
     	end if;
	end process;
end behave;


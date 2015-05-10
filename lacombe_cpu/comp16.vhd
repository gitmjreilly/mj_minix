library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity CompoundRegister is

    Port ( clk           : in std_logic;
           reset         : in std_logic;
           in1           : in  std_logic_vector((15) downto 0);
           out1          : out std_logic_vector((15) downto 0);
           out2          : out std_logic_vector((15) downto 0);
           output_enable : in  std_logic;
			  latch         : in  std_logic );
end CompoundRegister;

--
-- This Simple Reg is a register because of the implied need 
-- to hold Q's state.
--
architecture behave of CompoundRegister is
signal InternalState : std_logic_vector((15) downto 0);

begin

	out1 <= InternalState when (output_enable = '1') else  "ZZZZZZZZZZZZZZZZ";
	out2 <= InternalState;

	process (clk, reset)
	begin	
	   if reset = '1' then 
         InternalState <= (others => '0');
      elsif	clk'event and clk='1' then  
			if (latch = '1') then
				InternalState <= in1;
			end if;
     	end if;
	end process;

	
end behave;


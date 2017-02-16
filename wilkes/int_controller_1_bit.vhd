library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity int_controller_1_bit is
    Port ( int_in : in  STD_LOGIC;
		clock : in std_logic;
		reset : in std_logic;
           n_rd : in  STD_LOGIC;
           n_wr : in  STD_LOGIC;
           n_cs : in  STD_LOGIC;
			  address : in std_logic_vector(1 downto 0);
           int_out : out  STD_LOGIC;
			  data_bus : inout  STD_LOGIC);
end int_controller_1_bit;

architecture Behavioral of int_controller_1_bit is

constant INTERRUPT_STATUS_ADDRESS : std_logic_vector(1 downto 0) := "00";
constant MASK_ADDRESS : std_logic_vector(1 downto 0)   := "01";
constant CLEAR_ADDRESS : std_logic_vector(1 downto 0)  := "10";


signal clear_status : std_logic;
signal mask_status : std_logic;
signal and_out : std_logic;
signal status_reset : std_logic;
signal interrupt_status_reg_in : std_logic;
-- Added attribute line below to remove XST warning 1710
-- about FF trimming.  Apparently it is a bug in xst.
-- Dont' actually know what "attribute" does...
attribute KEEP : string;
signal interrupt_status : std_logic;
attribute KEEP of interrupt_status : signal is "TRUE";


begin

u_and : and_out <= int_in and mask_status;

u_interrupt_status_reg : process (clock, status_reset, reset, interrupt_status_reg_in)
begin
	if ((status_reset OR reset) = '1') then
		interrupt_status <= '0';
	elsif (falling_edge(clock) and interrupt_status_reg_in = '1') then
		interrupt_status <= '1';
	end if;
end process;

u_clear_reg : process (clock, reset, data_bus)
begin
	if (reset = '1') then
		clear_status <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = CLEAR_ADDRESS)) then
			clear_status <= data_bus;
		end if;
	end if;
end process;

u_mask_reg : process (clock, reset, data_bus)
begin
	if (reset = '1') then
		mask_status <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = MASK_ADDRESS)) then
			mask_status <= data_bus;
		end if;
	end if;
end process;

status_reset <= clear_status;
int_out <= interrupt_status;
interrupt_status_reg_in <= and_out;

data_bus <= mask_status when (( n_cs = '0') and (n_rd = '0') and (address = MASK_ADDRESS)) else 'Z';
data_bus <= clear_status when (( n_cs = '0') and (n_rd = '0') and (address = CLEAR_ADDRESS)) else 'Z';
data_bus <= interrupt_status when (( n_cs = '0') and (n_rd = '0') and (address = INTERRUPT_STATUS_ADDRESS)) 	else 'Z';

end Behavioral;


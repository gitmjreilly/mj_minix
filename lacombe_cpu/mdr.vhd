library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mdr is
    Port (	clock : in std_logic;
	 			p1 : inout std_logic_vector(15 downto 0);
	 			p2 : in std_logic_vector(15 downto 0);
				loadp1 : in std_logic;
				loadp2 : in std_logic;
				outp1 : in std_logic;
				outp3 : in std_logic;
				p3 : out std_logic_vector(15 downto 0);
				p4 : out std_logic_vector(15 downto 0)
				);
           
end mdr;

architecture structural of mdr is

component FlipFlop16 is
    Port ( input : in std_logic_vector(15 downto 0);
           output : out std_logic_vector(15 downto 0);
			  latch : in std_logic;
           clock : in std_logic);
end component;

component buf16 is
    Port ( input : in std_logic_vector(15 downto 0);
           output : out std_logic_vector(15 downto 0);
           oe : in std_logic);
end component;

signal ff_out : std_logic_vector(15 downto 0);
signal mux_out : std_logic_vector(15 downto 0);
signal input_selector : std_logic_vector(1 downto 0);
signal ff_load : std_logic;

begin

	-- Input to the the entity can come from p1 or p2
	-- depending on the settings of the load_pX pins.
	--
	input_selector(0) <= loadp1;
	input_selector(1) <= loadp2;
	with input_selector select
		mux_out <=
			p1 when "01",
			p2 when "10",
			p1 when others;

	ff_load <= loadp1 OR loadp2;

	ff : FlipFlop16 port map(input=>mux_out, latch=>ff_load, clock=>clock, output=>ff_out);
	buff_p1 : buf16 port map  (input=>ff_out, output=>p1, oe=>outp1);
	buff_p3 : buf16 port map  (input=>ff_out, output=>p3, oe=>outp3);

	p4 <= ff_out;

end structural;
				 
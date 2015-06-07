library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mdr is
    Port (	clock : in std_logic;
	 			mem_data_bus : inout std_logic_vector(15 downto 0);
	 			c_bus : in std_logic_vector(15 downto 0);
				load_mem_data_bus : in std_logic;
				load_c_bus : in std_logic;
				out_mem_data_bus : in std_logic;
				out_b_bus : in std_logic;
				b_bus : out std_logic_vector(15 downto 0);
				always_out : out std_logic_vector(15 downto 0)
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

signal stored_word : std_logic_vector(15 downto 0);
signal mux_out : std_logic_vector(15 downto 0);
signal input_selector : std_logic_vector(1 downto 0);

-- signal indicating storage should be loaded
signal ff_load : std_logic;

begin

	-- Input to the the entity can come from mem_data_bus or c_bus
	-- depending on the settings of the load_XX pins.
	--
	input_selector(0) <= load_mem_data_bus;
	input_selector(1) <= load_c_bus;
	with input_selector select
		mux_out <=
			mem_data_bus when "01",
			c_bus when "10",
			mem_data_bus when others;

	ff_load <= load_mem_data_bus OR load_c_bus;

	ff : FlipFlop16 port map(input=>mux_out, latch=>ff_load, clock=>clock, output=>stored_word);
	buff_mem_data_bus : buf16 port map  (input=>stored_word, output=>mem_data_bus, oe=>out_mem_data_bus);
	buff_b_bus : buf16 port map  (input=>stored_word, output=>b_bus, oe=>out_b_bus);

	always_out <= stored_word;

end structural;
				 

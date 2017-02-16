library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity output_port_8_words is port ( 
	clock : in std_logic;
	reset : in std_logic;
	n_rd : in  STD_LOGIC;
	n_wr : in  STD_LOGIC;
	n_cs : in  STD_LOGIC;
	address : in std_logic_vector(2 downto 0);
	int_out : out  STD_LOGIC;
	toggle_status_out : out std_logic;
	out_0 : out std_logic_vector(15 downto 0);
	out_1 : out std_logic_vector(15 downto 0);
	out_2 : out std_logic_vector(15 downto 0);
	out_3 : out std_logic_vector(15 downto 0);
	out_4 : out std_logic_vector(15 downto 0);
	out_5 : out std_logic_vector(15 downto 0);
	out_6 : out std_logic_vector(15 downto 0);
	out_7 : out std_logic_vector(15 downto 0);
	data_bus : inout  STD_LOGIC_VECTOR(15 downto 0));
end output_port_8_words;

architecture Behavioral of output_port_8_words is

signal out_port_0 : std_logic_vector(15 downto 0);
signal out_port_1 : std_logic_vector(15 downto 0);
signal out_port_2 : std_logic_vector(15 downto 0);
signal out_port_3 : std_logic_vector(15 downto 0);
signal out_port_4 : std_logic_vector(15 downto 0);
signal out_port_5 : std_logic_vector(15 downto 0);
signal out_port_6 : std_logic_vector(15 downto 0);
signal out_port_7 : std_logic_vector(15 downto 0);


begin

u_out_port_0 : process (clock, reset)
begin
	if (reset = '1') then
		out_port_0 <= (others => '0');
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "000")) then
			out_port_0 <= data_bus;
		end if;
	end if;
end process;

u_out_port_1: process (clock, reset)
begin
	if (reset = '1') then
		out_port_1 <= (others => '0');
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "001")) then
			out_port_1 <= data_bus;
		end if;
	end if;
end process;

u_out_port_2: process (clock, reset)
begin
	if (reset = '1') then
		out_port_2 <= (others => '0');
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "010")) then
			out_port_2 <= data_bus;
		end if;
	end if;
end process;

u_out_port_3: process (clock, reset)
begin
	if (reset = '1') then
		out_port_3 <= (others => '0');
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "011")) then
			out_port_3 <= data_bus;
		end if;
	end if;
end process;


u_out_port_4: process (clock, reset)
begin
	if (reset = '1') then
		out_port_4 <= (others => '0');
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "100")) then
			out_port_4 <= data_bus;
		end if;
	end if;
end process;

--data_bus <= out_port_0 when (( n_cs = '0') and (n_rd = '0') and (address = "000")) else (others => 'Z');
--data_bus <= out_port_1 when (( n_cs = '0') and (n_rd = '0') and (address = "001")) else (others => 'Z');
--data_bus <= out_port_2 when (( n_cs = '0') and (n_rd = '0') and (address = "010")) else (others => 'Z');
--data_bus <= out_port_3 when (( n_cs = '0') and (n_rd = '0') and (address = "011")) else (others => 'Z');
--data_bus <= out_port_4 when (( n_cs = '0') and (n_rd = '0') and (address = "100")) else (others => 'Z');
--data_bus <= out_port_5 when (( n_cs = '0') and (n_rd = '0') and (address = "101")) else (others => 'Z');
--data_bus <= out_port_6 when (( n_cs = '0') and (n_rd = '0') and (address = "110")) else (others => 'Z');
--data_bus <= out_port_7 when (( n_cs = '0') and (n_rd = '0') and (address = "111")) else (others => 'Z');

out_0 <= out_port_0;
out_1 <= out_port_1;
out_2 <= out_port_2;
out_3 <= out_port_3;
out_4 <= out_port_4;
out_5 <= out_port_5;
out_6 <= out_port_6;
out_7 <= out_port_7;

end Behavioral;


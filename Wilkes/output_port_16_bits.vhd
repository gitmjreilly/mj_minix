library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity output_port_16_bits is port ( 
	clock : in std_logic;
	reset : in std_logic;
	n_rd : in  STD_LOGIC;
	n_wr : in  STD_LOGIC;
	n_cs : in  STD_LOGIC;
	address : in std_logic_vector(3 downto 0);
	out_0 : out std_logic;
	out_1 : out std_logic;
	out_2 : out std_logic;
	out_3 : out std_logic;
	out_4 : out std_logic;
	out_5 : out std_logic;
	out_6 : out std_logic;
	out_7 : out std_logic;
	out_8 : out std_logic;
   out_9 : out std_logic;
	out_A : out std_logic;
	out_B : out std_logic;
	out_C : out std_logic;
	out_D : out std_logic;
	out_E : out std_logic;
	out_F : out std_logic;
	data_bus : inout  STD_LOGIC_VECTOR(15 downto 0));
end output_port_16_bits;

architecture Behavioral of output_port_16_bits is

signal out_port_0 : std_logic;
signal out_port_1 : std_logic;
signal out_port_2 : std_logic;
signal out_port_3 : std_logic;
signal out_port_4 : std_logic;
signal out_port_5 : std_logic;
signal out_port_6 : std_logic;
signal out_port_7 : std_logic;
signal out_port_8 : std_logic;
signal out_port_9 : std_logic;
signal out_port_A : std_logic;
signal out_port_B : std_logic;
signal out_port_C : std_logic;
signal out_port_D : std_logic;
signal out_port_E : std_logic;
signal out_port_F : std_logic;


begin

u_out_port_0 : process (clock, reset)
begin
	if (reset = '1') then
		out_port_0 <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "0000")) then
			out_port_0 <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_1: process (clock, reset)
begin
	if (reset = '1') then
		out_port_1 <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "0001")) then
			out_port_1 <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_2: process (clock, reset)
begin
	if (reset = '1') then
		out_port_2 <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "0010")) then
			out_port_2 <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_3: process (clock, reset)
begin
	if (reset = '1') then
		out_port_3 <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "0011")) then
			out_port_3 <= data_bus(0);
		end if;
	end if;
end process;


u_out_port_4: process (clock, reset)
begin
	if (reset = '1') then
		out_port_4 <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "0100")) then
			out_port_4 <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_5: process (clock, reset, data_bus)
begin
	if (reset = '1') then
		out_port_5 <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "0101")) then
         -- Notice output is bit 7 (This is MOSI)
			out_port_5 <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_6: process (clock, reset)
begin
	if (reset = '1') then
		out_port_6 <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "0110")) then
			out_port_6 <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_7: process (clock, reset)
begin
	if (reset = '1') then
		out_port_7 <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "0111")) then
			out_port_7 <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_8: process (clock, reset)
begin
	if (reset = '1') then
		out_port_8 <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "1000")) then
			out_port_8 <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_9: process (clock, reset)
begin
	if (reset = '1') then
		out_port_9 <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "1001")) then
			out_port_9 <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_A: process (clock, reset)
begin
	if (reset = '1') then
		out_port_A <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "1010")) then
			out_port_A <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_B: process (clock, reset)
begin
	if (reset = '1') then
		out_port_B <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "1011")) then
			out_port_B <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_C: process (clock, reset)
begin
	if (reset = '1') then
		out_port_C <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "1100")) then
			out_port_C <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_D: process (clock, reset)
begin
	if (reset = '1') then
		out_port_D <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "1101")) then
			out_port_D <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_E: process (clock, reset)
begin
	if (reset = '1') then
		out_port_E <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "1110")) then
			out_port_E <= data_bus(0);
		end if;
	end if;
end process;

u_out_port_F: process (clock, reset)
begin
	if (reset = '1') then
		out_port_F <= '0';
	elsif (falling_edge(clock)) then
		if ( (n_cs = '0') and (n_wr = '0') and (address = "1111")) then
			out_port_F <= data_bus(0);
		end if;
	end if;
end process;

--data_bus <= out_port_0 when (( n_cs = '0') and (n_rd = '0') and (address = "0000")) else (others => 'Z');
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
out_8 <= out_port_8;
out_9 <= out_port_9;
out_A <= out_port_A;
out_B <= out_port_B;
out_C <= out_port_C;
out_D <= out_port_D;
out_E <= out_port_E;
out_F <= out_port_F;

end Behavioral;


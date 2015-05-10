--
-- This is the multi input interrupt controller.
-- It is meant to be memory mapped.
-- It supports 3 registers:
--		Address 00 - INTERRUPT_STATUS - readonly
--		Address 01 - INTERRUPT_MASK - read/write
--		Address 10 - INTERRUPT_CLEAR - read/write
--		Address 11 - UNUSED
--
-- Please note the data_bus had to be specified one bit at a time.
-- For reason(s) unknown, passing in the 16 bit data bus did not work.
-- i.e. reading from regs did not work (Writing might not have worked either)
-- I am guessing it is related to the fact the port is "inout".
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mem_based_int_controller is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           address : in  STD_LOGIC_VECTOR (1 downto 0);
           data_bus_0 : inout  STD_LOGIC;
           data_bus_1 : inout  STD_LOGIC;
           data_bus_2 : inout  STD_LOGIC;
           data_bus_3 : inout  STD_LOGIC;
           data_bus_4 : inout  STD_LOGIC;
           data_bus_5 : inout  STD_LOGIC;
           data_bus_6 : inout  STD_LOGIC;
           data_bus_7 : inout  STD_LOGIC;
           data_bus_8 : inout  STD_LOGIC;
           data_bus_9 : inout  STD_LOGIC;
           data_bus_10 : inout  STD_LOGIC;
           data_bus_11 : inout  STD_LOGIC;
           data_bus_12 : inout  STD_LOGIC;
           data_bus_13 : inout  STD_LOGIC;
           data_bus_14 : inout  STD_LOGIC;
           data_bus_15 : inout  STD_LOGIC;
           int_out : out  STD_LOGIC;
           n_cs : in  STD_LOGIC;
           n_wr : in  STD_LOGIC;
           n_rd : in  STD_LOGIC;
           int_in : in  STD_LOGIC_vector(15 downto 0));
end mem_based_int_controller;

architecture Behavioral of mem_based_int_controller is

signal int_out_0 : std_logic;
signal int_out_1 : std_logic;
signal int_out_2 : std_logic;
signal int_out_3 : std_logic;
signal int_out_4 : std_logic;
signal int_out_5 : std_logic;
signal int_out_6 : std_logic;
signal int_out_7 : std_logic;
signal int_out_8 : std_logic;
signal int_out_9 : std_logic;
signal int_out_10 : std_logic;
signal int_out_11 : std_logic;
signal int_out_12 : std_logic;
signal int_out_13 : std_logic;
signal int_out_14 : std_logic;
signal int_out_15 : std_logic;

	component int_controller_1_bit is
    Port ( int_in : in  STD_LOGIC;
		clock : in std_logic;
		reset : in std_logic;
           n_rd : in  STD_LOGIC;
           n_wr : in  STD_LOGIC;
           n_cs : in  STD_LOGIC;
			  address : in std_logic_vector(1 downto 0);
           int_out : out  STD_LOGIC;
			  data_bus : inout  STD_LOGIC);
	end component;


begin

	int_controller_0 : int_controller_1_bit port map (
		int_in => int_in(0),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_0,
		data_bus => data_bus_0);

	int_controller_1 : int_controller_1_bit port map (
		int_in => int_in(1),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_1,
		data_bus => data_bus_1);

	int_controller_2 : int_controller_1_bit port map (
		int_in => int_in(2),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_2,
		data_bus => data_bus_2);

	int_controller_3 : int_controller_1_bit port map (
		int_in => int_in(3),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_3,
		data_bus => data_bus_3);

	int_controller_4 : int_controller_1_bit port map (
		int_in => int_in(4),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_4,
		data_bus => data_bus_4);

	int_controller_5 : int_controller_1_bit port map (
		int_in => int_in(5),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_5,
		data_bus => data_bus_5);

	int_controller_6 : int_controller_1_bit port map (
		int_in => int_in(6),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_6,
		data_bus => data_bus_6);

	int_controller_7 : int_controller_1_bit port map (
		int_in => int_in(7),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_7,
		data_bus => data_bus_7);

	int_controller_8 : int_controller_1_bit port map (
		int_in => int_in(8),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_8,
		data_bus => data_bus_8);

	int_controller_9 : int_controller_1_bit port map (
		int_in => int_in(9),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_9,
		data_bus => data_bus_9);

	int_controller_10 : int_controller_1_bit port map (
		int_in => int_in(10),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_10,
		data_bus => data_bus_10);

	int_controller_11 : int_controller_1_bit port map (
		int_in => int_in(11),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_11,
		data_bus => data_bus_11);

	int_controller_12 : int_controller_1_bit port map (
		int_in => int_in(12),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_12,
		data_bus => data_bus_12);

	int_controller_13 : int_controller_1_bit port map (
		int_in => int_in(13),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_13,
		data_bus => data_bus_13);

	int_controller_14 : int_controller_1_bit port map (
		int_in => int_in(14),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_14,
		data_bus => data_bus_14);

	int_controller_15 : int_controller_1_bit port map (
		int_in => int_in(15),
		address => address,
		clock => clock,
		reset => reset,
      n_rd => n_rd,
      n_wr => n_wr,
      n_cs => n_cs,
      int_out => int_out_15,
		data_bus => data_bus_15);


	int_out <=
		int_out_0 OR
		int_out_1 OR
		int_out_2 OR
		int_out_3 OR
		int_out_4 OR
		int_out_5 OR
		int_out_6 OR
		int_out_7 OR
		int_out_8 OR
		int_out_9 OR
		int_out_10 OR
		int_out_11 OR
		int_out_12 OR
		int_out_13 OR
		int_out_14 OR
		int_out_15;


end Behavioral;


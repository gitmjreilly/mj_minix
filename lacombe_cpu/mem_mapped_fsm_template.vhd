---------------------------------------------------------------------
-- Template for creating a mem mapped peripheral
-- Using an fsm
-- 
---------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mem_mapped_fsm is
    Port ( 
		clk : in  STD_LOGIC;
		reset : in STD_LOGIC;
		cpu_start : in  STD_LOGIC;
		cpu_finish : in  STD_LOGIC;
		n_cs : in STD_LOGIC;
		n_rd : in STD_LOGIC;
		n_wr : in STD_LOGIC;
		data_bus : inout STD_LOGIC_VECTOR(15 downto 0);
		addr_bus : in STD_LOGIC_VECTOR(3 downto 0)
	);
end mem_mapped_fsm;


architecture behavioral of mem_mapped_fsm is

	type state_type is (state_idle, state_0);
	signal r_state_reg, r_state_next : state_type;
	signal w_state_reg, w_state_next : state_type;
	
	signal val_reg, val_next : std_logic_vector(15 downto 0);

	signal reg_0, reg_0_next : std_logic_vector(15 downto 0);
	signal reg_1, reg_3_next : std_logic_vector(15 downto 0);
	signal reg_2, reg_2_next : std_logic_vector(15 downto 0);
	signal reg_3, reg_1_next : std_logic_vector(15 downto 0);
	
	signal is_read_in_progress  : std_logic; 
	signal is_write_in_progress : std_logic;
	
	
begin
	-----------------------------------------------------------------
	-- These 2 signals indicate either a read or write is in 
	-- progress by the host.
	-- They are asserted during the entire microcode cycle.
	-- They are NOT edge based.
	-- Please note all reads and writes are from the host's perspective
	is_read_in_progress  <= '1' when ((n_cs = '0') and (n_rd = '0')) else '0';
	is_write_in_progress <= '1' when ((n_cs = '0') and (n_wr = '0')) else '0';
	-----------------------------------------------------------------

 
	-----------------------------------------------------------------
	-- Synchronous process 
	-- All that happens here is the state change
	-- AND assignment of any internal storage
	process(clk, reset, r_state_next, w_state_next, val_next, reg_0_next, reg_2_next, reg_2_next, reg_3_next )
	begin
		if reset = '1' then
			r_state_reg <= state_idle;
			w_state_reg <= state_idle;
			
			reg_0 <= X"1800";
			reg_1 <= X"1801";
			reg_2 <= X"1802";
			reg_3 <= X"1803";
			
			-- L <= '1';
			-- H <= '0';
		elsif (rising_edge(clk)) then
			r_state_reg <= r_state_next;
			w_state_reg <= w_state_next;
			
			val_reg <= val_next;
			
			reg_0 <= reg_0_next;
			reg_1 <= reg_1_next;
			reg_2 <= reg_2_next;
			reg_3 <= reg_3_next;
		end if;	
	end process;
	-----------------------------------------------------------------

	
	-----------------------------------------------------------------
	-- Combinational State selection and state based output (i.e. Moore output)
	-- This process handles read requests from a host

	-- Leads to state 0 being N -1  cycles long; state 1 being 1 cycle long
	-- state 2 being N cycles long
	-- For a TOTAL of 2N cycles.
	
	process (
		r_state_next, 
		r_state_reg, 
		val_reg,
		is_read_in_progress, addr_bus, cpu_finish, val_next, reg_0, reg_1, reg_2, reg_3)

	-- This process statement is NG; count (nexts) have to be included
	-- process (r_state_reg, count_0, count_2)
	begin
		r_state_next <= r_state_reg;
		val_next <= val_reg;

		case r_state_reg is 
			-- A memory cycle can't begin until cpu_finish is asserted
			-- so we wait for it in the idle state.
			when state_idle =>

				if (cpu_finish = '1') then
					r_state_next <= state_0;
				end if;
				
			-- We know a memory cycle may be in progress;
			-- Is it addressed to us?
			when state_0 =>
				if (is_read_in_progress = '1') then
					r_state_next <= state_idle;
					case addr_bus is
						when X"0" => val_next <= reg_0;
						when X"1" => val_next <= reg_1;
						when X"2" => val_next <= reg_2;
						when X"3" => val_next <= reg_3;
						when others  => val_next <= X"B0FF";
					end case;
				else
					r_state_next <= state_idle;
				end if;
				
				
		end case;
	end process;
	-----------------------------------------------------------------


	
	-- -----------------------------------------------------------------
	process (w_state_next, w_state_reg, is_write_in_progress, 
		addr_bus, cpu_finish, data_bus,
		reg_0, reg_1, reg_2, reg_3)


	begin
		w_state_next <= w_state_reg;
		reg_0_next <= reg_0;
		reg_1_next <= reg_1;
		reg_2_next <= reg_2;
		reg_3_next <= reg_3;

		case w_state_reg is 
			-- A memory cycle can't begin until cpu_finish is asserted
			-- so we wait for it in the idle state.
			when state_idle =>

				if (cpu_finish = '1') then
					w_state_next <= state_0;
				end if;
				
			-- We know a memory cycle may be in progress;
			-- Is it addressed to us?
			when state_0 =>
				if (is_write_in_progress = '1') then
					w_state_next <= state_idle;
					case addr_bus is
						when X"0" => reg_0_next <= data_bus;
						when X"1" => reg_1_next <= data_bus; 
						when X"2" => reg_2_next <= X"2022";
						when X"3" => reg_3_next <= X"330F";
						when others  => reg_0_next <= reg_0;
					end case;
				else
					w_state_next <= state_idle;
				end if;
				
			when others =>
				w_state_next <= w_state_reg;
				
		end case;
	end process;
	-----------------------------------------------------------------


	
	-----------------------------------------------------------------
	process (is_read_in_progress, val_reg)
	begin
		if (is_read_in_progress = '1') then
			data_bus <= val_reg;
		else
			data_bus <= (others => 'Z');
		end if;	
	end process;
	-----------------------------------------------------------------
	
end Behavioral;


---------------------------------------------------------------------
--  uart based on pong chu and Xilinx Coregen Ram
---------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity block_ram_demo is
    port ( 
		clk : in  STD_LOGIC; -- TODO For now, we assume 50MHz
		reset : in STD_LOGIC;
		cpu_finish : in  STD_LOGIC;
		n_cs : in STD_LOGIC;
		n_rd : in STD_LOGIC;
		n_wr : in STD_LOGIC;
		data_bus : inout STD_LOGIC_VECTOR(15 downto 0);
		fake_data_bus : out std_logic_vector(15 downto 0);
		addr_bus : in STD_LOGIC_VECTOR(10 downto 0)
	);
end block_ram_demo;




architecture behavioral of block_ram_demo is


	type write_state_type is (write_state_idle, write_state_0, write_state_1, write_state_2);

	type read_state_type is (read_state_idle, read_state_0, read_state_1);


	signal read_state_reg, read_state_next : read_state_type;
	signal write_state_reg, write_state_next : write_state_type;
	signal wea_reg, wea_next, wea : std_logic_vector(0 downto 0);

	signal is_host_write_in_progress  : std_logic;
	signal is_host_read_in_progress  : std_logic;
	
	signal val_reg, val_next : std_logic_vector(15 downto 0);
	signal douta: std_logic_vector(15 downto 0);
	
	COMPONENT mj_ram_2k
		PORT (
			clka : IN STD_LOGIC;
			wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
			dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT;

	
begin
	
	-----------------------------------------------------------------
	-- These 2 signals indicate either a memory read or write is in 
	-- progress by the host.
	-- They are asserted during the entire microcode cycle.
	-- They are NOT edge based.
	-- Please note all reads and writes are from the host's perspective
	is_host_read_in_progress  <= '1' when ((n_cs = '0') and (n_rd = '0')) else '0';
	is_host_write_in_progress <= '1' when ((n_cs = '0') and (n_wr = '0')) else '0';
	-----------------------------------------------------------------


	u_2k_block : mj_ram_2k
		PORT MAP (
			clka => clk,
			wea => wea_reg,
			addra => addr_bus,
			dina => data_bus,
			douta => douta
	);
	

	-----------------------------------------------------------------
	-- Synchronous process 
	-- All that happens here is the state change
	-- AND assignment of the val read from black ram
	process(
		clk, reset, 
		read_state_next, write_state_next, 
		val_next
	)
	begin
		if reset = '1' then
			read_state_reg <= read_state_idle;
			write_state_reg <= write_state_idle;
			
		elsif (rising_edge(clk)) then
			read_state_reg <= read_state_next;
			write_state_reg <= write_state_next;
			
			wea_reg <= wea_next;
			val_reg <= val_next;
			-- val_reg <= x"1717";
			
		end if;	
	end process;
	-----------------------------------------------------------------
	
	
	
	-----------------------------------------------------------------
	-- Combinational State selection
	-- This process handles read requests from a host
	process (
		read_state_reg, 
		val_reg,
		is_host_read_in_progress, 
		addr_bus, cpu_finish
	)
	begin
		read_state_next <= read_state_reg;
		val_next <= val_reg;

		case read_state_reg is 
			-- A memory cycle can't begin until cpu_finish is asserted
			-- so we wait for it in the idle state.
			when read_state_idle =>

				if (cpu_finish = '1') then
					read_state_next <= read_state_0;
				end if;
				
				
				
			-- We know a memory cycle may be in progress;
			-- Is it addressed to us?
			-- Please note, we're assuming the block ram has
			-- placed correct output on dout_a already.
			when read_state_0 =>
				read_state_next <= read_state_1;
			
			when read_state_1 =>
				read_state_next <= read_state_idle;
				if (is_host_read_in_progress = '1') then
					val_next <= douta;
					read_state_next <= read_state_idle;
				end if;
				

			when others =>
				read_state_next <= read_state_idle;
				
		end case;
	end process;
	-----------------------------------------------------------------

	
	
	---------------------------------------------------------------
	-- This is the state selection process of the 
	-- FSM activated by a host write 
	--
	process (
		write_state_reg, 
		is_host_write_in_progress, 
		cpu_finish
	)
	begin
		write_state_next <= write_state_reg;
		wea_next <= "0";
		
		case write_state_reg is 
			-- A memory cycle can't begin until cpu_finish is asserted
			-- so we wait for it in the idle state.
			when write_state_idle =>

				if (cpu_finish = '1') then
					write_state_next <= write_state_0;
				end if;
								
			-- We know a memory cycle may be in progress;
			-- Is it addressed to us?
			when write_state_0 =>
				if (is_host_write_in_progress = '1') then
					write_state_next <= write_state_1;
					wea_next <= "1";
				else
					write_state_next <= write_state_idle;
				end if;
		
			when write_state_1 =>
				write_state_next <= write_state_2;

						
			when write_state_2 =>
				write_state_next <= write_state_idle;
						
				
		end case;
	end process;
	-----------------------------------------------------------------

	
	
	-----------------------------------------------------------------
	-- If a HOST read is in progress (determined combinatorially),
	-- we drive the data bus with the register containing the 
	-- the requested value val_reg.  val_reg was populated
	-- by the FSM above.
	
	fake_data_bus <= data_bus;

	process (is_host_read_in_progress, val_reg)
	begin
		if (is_host_read_in_progress = '1') then
			data_bus <= val_reg;
		else
			data_bus <= (others => 'Z');
		end if;	
	end process;
	-----------------------------------------------------------------
	
	
	
end behavioral;

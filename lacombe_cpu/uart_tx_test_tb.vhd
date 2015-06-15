--------------------------------------------------------------------------------

-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY uart_tx_test_tb IS
END uart_tx_test_tb;
 
ARCHITECTURE behavior OF uart_tx_test_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT uart_tx_test
	generic (
		DBIT : integer := 8;
		SB_TICK : integer := 2
	);
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         cpu_start : IN  std_logic;
         cpu_finish : IN  std_logic;
         n_cs : IN  std_logic;
         n_rd : IN  std_logic;
         n_wr : IN  std_logic;
         data_bus : INOUT  std_logic_vector(15 downto 0);
         addr_bus : IN  std_logic_vector(3 downto 0);
		 tx : out std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal cpu_start : std_logic := '0';
   signal cpu_finish : std_logic := '0';
   signal n_cs : std_logic := '0';
   signal n_rd : std_logic := '0';
   signal n_wr : std_logic := '0';
   signal addr_bus : std_logic_vector(3 downto 0) := (others => '0');
   signal tx : std_logic;

	--BiDirs
   signal data_bus : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ps;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: uart_tx_test 
		generic map (
			dbit => 8,
			sb_tick => 2
		)
		PORT MAP (
          clk => clk,
          reset => reset,
          cpu_start => cpu_start,
          cpu_finish => cpu_finish,
          n_cs => n_cs,
          n_rd => n_rd,
          n_wr => n_wr,
          data_bus => data_bus,
          addr_bus => addr_bus,
		  tx => tx
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin

		reset <= '1';
		wait for clk_period * 5;
		reset <= '0';

		n_cs <= '1';
		n_wr <= '1';
		wait for clk_period * 3;

   
		wait until rising_edge(clk);
		cpu_finish <= '1';
		wait until rising_edge(clk);
		cpu_finish <= '0';

		n_cs <= '0';
		n_wr <= '0';
		addr_bus <= X"1";
		data_bus <= X"0009";

		wait for 5 * clk_period;
		n_cs <= '1';
		n_wr <= '1';
		wait until rising_edge(clk);
		cpu_finish <= '1';
		wait until rising_edge(clk);
		cpu_finish <= '0';
	


		wait for 100 * clk_period;
		assert false
		report "Simulation is done."
		severity failure;   
	
		
		
   end process;

END;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY cpu_timing_generator_test IS
END cpu_timing_generator_test;
 
ARCHITECTURE behavior OF cpu_timing_generator_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT cpu_timing_generator
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         cpu_start : OUT  std_logic;
         cpu_finish : OUT  std_logic;
         pause : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal pause : std_logic := '0';

 	--Outputs
   signal cpu_start : std_logic;
   signal cpu_finish : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ps;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: cpu_timing_generator PORT MAP (
          clk => clk,
          reset => reset,
          cpu_start => cpu_start,
          cpu_finish => cpu_finish,
          pause => pause
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
		-- hold reset state...
		reset <= '1';
		wait for 10 * clk_period;	
		reset <= '0';

		wait for clk_period*10;

		-- insert stimulus here 

		wait for 40 * clk_period;
		assert false
			report "Simulation is done."
			severity failure;
	end process;

END;

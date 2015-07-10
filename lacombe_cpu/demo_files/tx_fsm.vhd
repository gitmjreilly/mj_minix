library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity tx_fsm is
    Port ( 
		reset : in STD_LOGIC;
		clk : in  STD_LOGIC;
		wr_in_progress: in  STD_LOGIC;
		wr_strobe: out  STD_LOGIC) ;
end tx_fsm;


architecture Behavioral of tx_fsm is

	type state_type is (st0, st1, st2); 
	signal current_state : state_type;
	signal next_state : state_type; 
	

	
begin

	SYNC_PROC: process (clk)
	begin
		if (reset = '1') then
			current_state <= st0;
		elsif (rising_edge(clk)) then
			current_state <= next_state;
		end if;
	end process;

	
	NEXT_STATE_DECODE: process (current_state, wr_in_progress)
	begin
		-- Default is to stay in current current_state
		next_state <= current_state;

		case (current_state) is
			when st0 =>
				if wr_in_progress = '1' then
					next_state <= st1;
				end if;
			when st1 =>
				next_state <= st2;
			when st2 =>
				if wr_in_progress = '0' then
					next_state <= st0;
				end if;
		end case;      
	end process;

	
	-- Moore Outputs (based on FSM current_state only...
	moore_outputs : process(current_state)
	begin
		wr_strobe <= '0';
		if (current_state = st1) then
			wr_strobe <= '1';
		end if;	
	end process;

end Behavioral;




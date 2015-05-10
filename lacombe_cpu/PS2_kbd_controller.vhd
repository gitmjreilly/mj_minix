library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity PS2_kbd_controller is
   Port ( 
	   reset : in STD_LOGIC;
      clock : in  STD_LOGIC;
		
		n_rd : in STD_LOGIC;
		n_cs : in std_logic;

      kbd_clock_actual : in  STD_LOGIC;
		kbd_data_actual : in STD_LOGIC;

		bidir_data : inout STD_LOGIC_VECTOR(15 downto 0)
   );
end PS2_kbd_controller;


architecture Behavioral of PS2_kbd_controller is

type state_type is (
   idle, 
   saw_start, 
   received_bit_0, 
   received_bit_1, 
   received_bit_2,
   received_bit_3,
   received_bit_4,
   received_bit_5,
   received_bit_6,
   received_bit_7,
   received_parity,
   received_stop); 

signal sw_clock_debounced : std_logic;  
signal debounce_clock : std_logic;
signal state, next_state : state_type; 
signal result : std_logic_vector(3 downto 0);
signal four_digits : std_logic_vector(15 downto 0);
signal bit_0 : std_logic;
signal bit_1 : std_logic;
signal bit_2 : std_logic;
signal bit_3 : std_logic;
signal bit_4 : std_logic;
signal bit_5 : std_logic;
signal bit_6 : std_logic;
signal bit_7 : std_logic;

signal kbd_clock_sync : std_logic;
signal kbd_clock_delayed : std_logic;
signal kbd_clock_raw : std_logic;      -- kbd clock, either from kbd OR sw
signal kbd_data_raw : std_logic;       -- kbd data,  either from kbd OR sw

signal data_valid_raw : std_logic;
signal data_valid_sync : std_logic;
signal data_valid_delayed : std_logic;
signal data_valid_r_edge : std_logic;

signal full_flag : std_logic;

signal received_byte : std_logic_vector(7 downto 0);

signal clear : std_logic;


begin
   --
	-- Select one of 2 clock choices and one of 2 data choices
	-- The switched clock needs to be debounced.
	-- The switched data does NOT need to be debounced because
	-- this circuit only captures data when the clock goes low.
	--
	kbd_clock_raw <= kbd_clock_actual ;
	kbd_data_raw  <= kbd_data_actual  ;

  
   ------------------------------------------------------------------
   kbd_clock_synchronizer : process(clock, reset)
	begin
	   if (reset = '1') then
		   kbd_clock_sync <= '1';
			kbd_clock_delayed <= '1';
	   elsif rising_edge(clock) then
		   kbd_clock_sync <= kbd_clock_raw;
			kbd_clock_delayed <= kbd_clock_sync;
		end if;
	end process;
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   data_valid_synchronizer : process(clock, reset)
	begin
	   if (reset = '1') then
		   data_valid_sync <= '0';
			data_valid_delayed <= '0';
	   elsif rising_edge(clock) then
		   data_valid_sync <= data_valid_raw;
			data_valid_delayed <= data_valid_sync;
		end if;
	end process;
   ------------------------------------------------------------------

   ------------------------------------------------------------------		
   SYNC_PROC: process (kbd_clock_sync, reset)
   begin
	   if (reset = '1') then
		   state <= idle;
		elsif (falling_edge(kbd_clock_sync)) then
         state <= next_state;
      end if;
   end process;
   ------------------------------------------------------------------		
 
   ------------------------------------------------------------------		
   --
   --
   NEXT_STATE_DECODE: process (state)
   begin
      --declare default state for next_state to avoid latches
      next_state <= state;  --default is to stay in current state

      case (state) is
         when idle => next_state <= saw_start;
         when saw_start =>      next_state <= received_bit_0;
         when received_bit_0 => next_state <= received_bit_1;
         when received_bit_1 => next_state <= received_bit_2;
         when received_bit_2 => next_state <= received_bit_3;
         when received_bit_3 => next_state <= received_bit_4;
         when received_bit_4 => next_state <= received_bit_5;
         when received_bit_5 => next_state <= received_bit_6;
         when received_bit_6 => next_state <= received_bit_7;
         when received_bit_7 => next_state <= received_parity;
         when received_parity =>next_state <= received_stop;
         when received_stop =>  next_state <= saw_start;
         when others =>         next_state <= idle;
      end case;      
   end process;
   ------------------------------------------------------------------		


   ------------------------------------------------------------------		
	--
   OUTPUT_DECODE: process (kbd_clock_delayed, state, reset)
   begin
	   if reset = '1' then
		   data_valid_raw <= '0';
		elsif (falling_edge(kbd_clock_delayed)) then
		   if (state = saw_start) then
			   data_valid_raw <= '0';
   			bit_0 <= '0';
	   		bit_1 <= '0';
		   	bit_2 <= '0';
			   bit_3 <= '0';
   			bit_4 <= '0';
	   		bit_5 <= '0';
		   	bit_6 <= '0';
			   bit_7 <= '0';
				
		   elsif (state = received_bit_0) then bit_0 <= kbd_data_raw;
			elsif (state = received_bit_1) then bit_1 <= kbd_data_raw;
			elsif (state = received_bit_2) then	bit_2 <= kbd_data_raw;
			elsif (state = received_bit_3) then	bit_3 <= kbd_data_raw;
			elsif (state = received_bit_4) then	bit_4 <= kbd_data_raw;
			elsif (state = received_bit_5) then	bit_5 <= kbd_data_raw;
			elsif (state = received_bit_6) then	bit_6 <= kbd_data_raw;
			elsif (state = received_bit_7) then	bit_7 <= kbd_data_raw;
			elsif (state = received_parity) then
			   data_valid_raw <= '1';
			end if;
			
		end if;
   end process;
   ------------------------------------------------------------------		
 
   clear <= ((NOT n_rd) AND (NOT n_cs));   	
		
   ------------------------------------------------------------------		
   -- Full Flag Handling
	--
	process (clock, reset)
	begin
	   if (reset = '1') then
		   full_flag <= '0';
		elsif (rising_edge(clock)) then
		   if (clear = '1') then
			   full_flag <= '0';
			elsif (data_valid_r_edge = '1') then
			   full_flag <= '1';
			end if;
		end if;
	end process;

   data_valid_r_edge <= data_valid_sync and (not data_valid_delayed);
   ------------------------------------------------------------------		


	received_byte <= bit_7 & bit_6 & bit_5 & bit_4 &
	   bit_3 & bit_2 & bit_1 & bit_0;
		
   ------------------------------------------------------------------		
   bidir_data <= "0000000" & full_flag & received_byte when
	   ((n_rd = '0') and (n_cs = '0')) else "ZZZZZZZZZZZZZZZZ";
   ------------------------------------------------------------------		
		
		
end Behavioral;


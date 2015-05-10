library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---------------------------------------------------------------------
entity spi_mem_mapped is
Port (
      -- Clock is 100Mhz on Nexys 3 Board
      -- which is divided down to get fsm clock
      clock : in  STD_LOGIC;
      reset : in STD_LOGIC;
      n_cs : in std_logic;
      n_oe : in std_logic;
      n_we : in std_logic;
      address_bus : in std_logic_vector(1 downto 0);
      data_bus : inout std_logic_vector(15 downto 0);
      real_sclock : out STD_LOGIC;
      mosi : out STD_LOGIC;
      miso : in STD_LOGIC
   );
end spi_mem_mapped;
---------------------------------------------------------------------


---------------------------------------------------------------------
architecture Behavioral of spi_mem_mapped is
   type state_type is (st_idle, st1, st2, st3, st4, st5, 
	                    st6, st7, st8, st9, st10, st11,
							  st12, st13, st14, st15, st16, st17); 
	
   signal cur_state, next_state : state_type; 
	
	-- This signal indicates we are are shifting
	signal is_mosi_shift_state : std_logic;
   signal is_data_load_state : std_logic;
   signal is_miso_shift_state : std_logic;	

   signal mosi_shift_reg : std_logic_vector(7 downto 0);
	signal data_high : std_logic;
	
   -- signals used to fsm physical switch input
   -- Added attribute line below to remove XST warning 2677
   -- about FF trimming.  Apparently it is a bug in xst.
   -- Dont' actually know what "attribute" does...
   attribute KEEP : string;
   signal clock_counter : std_logic_vector(11 downto 0);
   attribute KEEP of clock_counter : signal is "TRUE";
	signal fsm_clock : std_logic;

   -- Start indicator for the spi fsm
   signal start_fsm : std_logic;
	
	signal write_id : std_logic;
	signal old_write_id : std_logic;
	
	--- Memory location seen by outside
   signal write_is_active : std_logic;
   signal read_is_active : std_logic;

   signal is_busy : std_logic;

   -- 0 is for spi writes
   -- 1 is for spi reads
   -- 2 is for busy 
   -- 3 for the future
	signal read_reg_0 : std_logic_vector (15 downto 0);
	signal read_reg_1 : std_logic_vector (15 downto 0);
	signal read_reg_2 : std_logic_vector (15 downto 0);
	signal read_reg_3 : std_logic_vector (15 downto 0);

   signal out_sclock : std_logic;
   
begin 

   real_sclock <= NOT(out_sclock);

   ------------------------------------------------------------------
   -- A Counter used to divide input clock
   -- to create a counter
   fsm_clock_proc : process (clock, reset)
	begin
	   if (reset = '1') then
		   clock_counter <= X"000";
		elsif (rising_edge(clock)) then
		   clock_counter <= clock_counter + 1;
		end if;
	end process;
   ------------------------------------------------------------------
	
   --
   -- 2 => 12.5Mhz / 8
   -- 0 => 12.5Mhz / 2 - NG
	fsm_clock <= clock_counter(1);


   ------------------------------------------------------------------
   -- Combinatorial proc indicating if CPU has triggered a write
   write_is_active_proc : process(n_cs, n_we)
   begin
	   if (n_cs = '0' AND n_we = '0') then
		   write_is_active <= '1';
		 else
		   write_is_active <= '0';
	   end if;
   end process write_is_active_proc;
   ------------------------------------------------------------------


   ------------------------------------------------------------------
   -- Combinatorial proc indicating if CPU has triggered a read
   read_is_active_proc : process(n_cs, n_oe)
   begin
      if (n_cs = '0' AND n_oe = '0') then
         read_is_active <= '1';
      else
         read_is_active <= '0';
     end if;
   end process read_is_active_proc;
   ------------------------------------------------------------------


   ------------------------------------------------------------------
   -- All this process does is select the next state
	-- based on either re(clock) or an asynch reset
   sync_proc: process (fsm_clock, reset)
   begin
      if (reset = '1') then
         cur_state <= st_idle;
      elsif (rising_edge(fsm_clock)) then
         cur_state <= next_state;
      end if;
   end process;
   ------------------------------------------------------------------
 
 
















   ------------------------------------------------------------------
   -- This is a combinatorial process.  It selects the next state based on the 
	-- current state.
   next_state_proc : process(cur_state, start_fsm)
	begin
	   case cur_state is
		   when st_idle => 
			   if start_fsm = '1' then
				   next_state <= st1;
				else
				   next_state <= st_idle;
			   end if;
			
		   when st1 => next_state <= st2;
		   when st2 => next_state <= st3;
		   when st3 => next_state <= st4;
		   when st4 => next_state <= st5;
		   when st5 => next_state <= st6;
		   when st6 => next_state <= st7;
		   when st7 => next_state <= st8;
		   when st8 => next_state <= st9;
		   when st9 => next_state <= st10;
		   when st10 => next_state <= st11;
		   when st11 => next_state <= st12;
		   when st12 => next_state <= st13;
		   when st13 => next_state <= st14;
		   when st14 => next_state <= st15;
		   when st15 => next_state <= st16;
		   when st16 => next_state <= st17;
		   when st17 => next_state <= st_idle;
			when others => next_state <= st_idle;
      end case;
   end process next_state_proc;
   ------------------------------------------------------------------
	
		
























	

   ------------------------------------------------------------------
	-- Define outputs based on current state
	output_proc : process(cur_state, data_high)
	begin
	   case cur_state is
		   when st_idle => 
				mosi <= data_high;
			   out_sclock <= '0';
				is_miso_shift_state <= '0';
				is_mosi_shift_state <= '0';
            is_data_load_state <= '0';
				is_busy <= '0';
		   when st1 => 
				mosi <= data_high;
			   out_sclock <= '0';
				-- Don't shift yet
            is_data_load_state <= '1';
				is_miso_shift_state <= '0';
				is_mosi_shift_state <= '0';
				is_busy <= '1';
		   when st2 => 
				mosi <= data_high;
			   out_sclock <= '1';
            is_data_load_state <= '0';
				is_miso_shift_state <= '1';
				is_mosi_shift_state <= '0';
				is_busy <= '1';
		   when st3 => 
				mosi <= data_high;
			   out_sclock <= '0';
            is_data_load_state <= '0';
				is_miso_shift_state <= '0';
				is_mosi_shift_state <= '1';
				is_busy <= '1';
		   when st4 => 
				mosi <= data_high;
			   out_sclock <= '1';
            is_data_load_state <= '0';
				is_miso_shift_state <= '1';
				is_mosi_shift_state <= '0';
				is_busy <= '1';
		   when st5 => 
				mosi <= data_high;
			   out_sclock <= '0';
            is_data_load_state <= '0';
				is_miso_shift_state <= '0';
				is_mosi_shift_state <= '1';
				is_busy <= '1';
		   when st6 => 
				mosi <= data_high;
			   out_sclock <= '1';
            is_data_load_state <= '0';
				is_miso_shift_state <= '1';
				is_mosi_shift_state <= '0';
				is_busy <= '1';
		   when st7 => 
				mosi <= data_high;
			   out_sclock <= '0';
            is_data_load_state <= '0';
				is_miso_shift_state <= '0';
				is_mosi_shift_state <= '1';
				is_busy <= '1';
		   when st8 => 
				mosi <= data_high;
			   out_sclock <= '1';
            is_data_load_state <= '0';
				is_miso_shift_state <= '1';
				is_mosi_shift_state <= '0';
				is_busy <= '1';
		   when st9 => 
				mosi <= data_high;
			   out_sclock <= '0';
            is_data_load_state <= '0';
				is_miso_shift_state <= '0';
				is_mosi_shift_state <= '1';
				is_busy <= '1';
		   when st10 => 
				mosi <= data_high;
			   out_sclock <= '1';
            is_data_load_state <= '0';
				is_miso_shift_state <= '1';
				is_mosi_shift_state <= '0';
				is_busy <= '1';
		   when st11 => 
				mosi <= data_high;
			   out_sclock <= '0';
            is_data_load_state <= '0';
				is_miso_shift_state <= '0';
				is_mosi_shift_state <= '1';
				is_busy <= '1';
		   when st12 => 
				mosi <= data_high;
			   out_sclock <= '1';
            is_data_load_state <= '0';
				is_miso_shift_state <= '1';
				is_mosi_shift_state <= '0';
				is_busy <= '1';
		   when st13 => 
				mosi <= data_high;
			   out_sclock <= '0';
            is_data_load_state <= '0';
				is_miso_shift_state <= '0';
				is_mosi_shift_state <= '1';
				is_busy <= '1';
		   when st14 => 
				mosi <= data_high;
			   out_sclock <= '1';
            is_data_load_state <= '0';
				is_miso_shift_state <= '1';
				is_mosi_shift_state <= '0';
				is_busy <= '1';
		   when st15 => 
				mosi <= data_high;
			   out_sclock <= '0';
				is_miso_shift_state <= '0';
				is_mosi_shift_state <= '1';
				is_busy <= '1';
		   when st16 => 
				mosi <= data_high;
			   out_sclock <= '1';
            is_data_load_state <= '0';
				is_miso_shift_state <= '1';
				is_mosi_shift_state <= '0';
				is_busy <= '1';
		   when st17 => 
				mosi <= data_high;
			   out_sclock <= '0';
            is_data_load_state <= '0';
				is_miso_shift_state <= '0';
				is_mosi_shift_state <= '0';
				is_busy <= '1';
		   when others => 
				mosi <= '0';
			   out_sclock <= '0';
            is_data_load_state <= '0';
				is_miso_shift_state <= '0';
				is_mosi_shift_state <= '0';
				is_busy <= '0';
      end case;
	end process output_proc;
   ------------------------------------------------------------------

   ------------------------------------------------------------------
	miso_shift_reg_proc : process(fsm_clock, reset, is_miso_shift_state)
	begin
	   if (reset = '1') then
		   read_reg_1 <= X"0000";
	   elsif (falling_edge(fsm_clock)) then
         if (is_miso_shift_state = '1') then 
		      read_reg_1 <= read_reg_1(14 downto 0) & miso;
         end if;
      end if;
   end process miso_shift_reg_proc;
   ------------------------------------------------------------------

   ------------------------------------------------------------------
	mosi_shift_reg_proc : process(fsm_clock, reset, is_mosi_shift_state)
	begin
	   if (falling_edge(fsm_clock)) then
         if (is_mosi_shift_state = '1') then 
		      mosi_shift_reg <= mosi_shift_reg(6 downto 0) & '0';
         elsif (is_data_load_state = '1') then
            mosi_shift_reg <= read_reg_0(7 downto 0);
         end if;
      end if;
   end process mosi_shift_reg_proc;
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- write_id used to tell fsm if the cpu has initiated a new write
	u_write_id : process(reset, write_is_active)
	begin
	   if (reset = '1') then
		   write_id <= '0';
	   elsif (rising_edge(write_is_active)) then 
		   write_id <= NOT (write_id);
      end if;
   end process u_write_id;
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- Have the fsm note the latest write_id it has acted on
	old_write_id_proc : process(fsm_clock, reset, cur_state)
	begin
	   if (reset = '1') then
		   old_write_id <= '0';
	   elsif (falling_edge(fsm_clock) AND (cur_state = st1)) then 
		   old_write_id <= write_id;
      end if;
   end process old_write_id_proc;
   ------------------------------------------------------------------
	
   ------------------------------------------------------------------
   -- process sets start_fsm to trigger the fsm to leave the idle
   -- state
	u_start_fsm: process(write_id, old_write_id)
	begin
	   if (write_id /= old_write_id) then
		   start_fsm <= '1';
		else
		   start_fsm <= '0';
		end if;
	end process u_start_fsm;
   ------------------------------------------------------------------

	
   ------------------------------------------------------------------
   -- data_high is used to drive actual MOSI signal
   data_high <= mosi_shift_reg(7);
   ------------------------------------------------------------------
	
  
   ------------------------------------------------------------------
   -- Process for reading reg's 0 -> 3
   -- 0 is for spi writes
   -- 1 is for spi reads
   -- 2 is for busy 
   -- 3 for the future
   read_reg_proc : process(read_reg_0, read_reg_1, read_reg_2, read_reg_3, read_is_active, address_bus, is_busy)
   begin
      if (read_is_active = '1') then
         if (address_bus = "00") then
            data_bus <= read_reg_0;
         elsif (address_bus = "01") then
            data_bus <= read_reg_1;
         elsif (address_bus = "10") then
            data_bus <= X"00" & "0000001" & is_busy;
         else
            data_bus <= read_reg_3;
         end if;
      else data_bus <= "ZZZZZZZZZZZZZZZZ";
      end if;
   end process read_reg_proc;
   ------------------------------------------------------------------


   ------------------------------------------------------------------
   -- Process for reading reg's 0 -> 3
   -- 0 is for spi writes
   -- 1 is for spi reads
   -- 2 is for busy 
   -- 3 for the future
   --
   -- Can't write to read_reg_1 because it is populated by
   -- shifts from the miso shift process
   write_reg_proc : process(reset, write_is_active, address_bus, data_bus)
   begin
      if (reset = '1') then
          read_reg_0 <= X"1900";
          read_reg_2 <= X"1902";
          read_reg_3 <= X"1903";
      elsif ((write_is_active = '1')) then
         if (address_bus = "00") then
           read_reg_0 <= data_bus;
         elsif (address_bus = "10") then
           read_reg_2 <= data_bus;
         else
           read_reg_3 <= data_bus;
         end if; 
      end if;
   end process write_reg_proc;
   ------------------------------------------------------------------

   
end Behavioral;

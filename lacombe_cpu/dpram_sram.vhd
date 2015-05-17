library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity dpram_sram is
    Port ( addr_bus : in  STD_LOGIC_VECTOR (9 downto 0);
           data_bus : inout  STD_LOGIC_VECTOR (15 downto 0);
           n_wr : in  STD_LOGIC;
           n_rd : in  STD_LOGIC;
           n_cs : in  STD_LOGIC;
           delayed_clock : in  STD_LOGIC);
end dpram_sram;

architecture Behavioral of dpram_sram is

signal DATA_OUT : STD_LOGIC_VECTOR(15 downto 0);
signal PADDED_ADDR : STD_LOGIC_VECTOR(9 downto 0);
signal OUTPUT_ENABLE : STD_LOGIC;
signal DOPB : STD_LOGIC_VECTOR(1 downto 0);

begin
  -- RAMB16_S18: Virtex-II/II-Pro, Spartan-3/3E 1k x 16 + 2 Parity bits Single-Port RAM
   -- Xilinx HDL Language Template, version 9.1i

--   RAMB16_S18_inst : RAMB16_S18
--   generic map (
--      INIT => X"00000", --  Value of output RAM registers at startup
--      SRVAL => X"FFFFF", --  Ouput value upon SSR assertion
--      WRITE_MODE => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
--      -- The following INIT_xx declarations specify the intial contents of the RAM
--      -- Address 0 to 255
--      INIT_00 => X"0000000000000000000000000000000000000000000000000000000000FB00FA",
--      INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
--      -- Address 256 to 511
--      INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
--      -- Address 512 to 767
--      INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
--      -- Address 768 to 1023
--      INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
--      -- The next set of INITP_xx are for the parity bits
--      -- Address 0 to 255
--      INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      -- Address 256 to 511
--      INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      -- Address 512 to 767
--      INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      -- Address 768 to 1023
--      INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")
--   port map (
--      DO => DATA_OUT,      -- 16-bit Data Output
----      DOP => DOP,    -- 2-bit parity Output
--      ADDR => PADDED_ADDR,  -- 10-bit Address Input
--      CLK => (NOT DELAYED_CLOCK),    -- Clock
--      DI => DATA_BUS,      -- 16-bit Data Input
--      DIP => "00",    -- 2-bit parity Input
--
--      EN => (NOT N_CS),      -- RAM Enable Input
--      SSR => '0',    -- Synchronous Set/Reset Input
--
--      WE => (NOT N_WR)       -- Write Enable Input
--   );
--

  RAMB16_S1_S18_inst : RAMB16_S1_S18
   generic map (
      INIT_A => "0", --  Value of output RAM registers on Port A at startup
      INIT_B => X"00000", --  Value of output RAM registers on Port B at startup
      SRVAL_A => "0", --  Port A ouput value upon SSR assertion
      SRVAL_B => X"00000", --  Port B ouput value upon SSR assertion
      WRITE_MODE_A => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      WRITE_MODE_B => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      SIM_COLLISION_CHECK => "ALL", -- "NONE", "WARNING", "GENERATE_X_ONLY", "ALL" 
      -- The following INIT_xx declarations specify the initial contents of the RAM
      -- Port A Address 0 to 4095, Port B Address 0 to 255
      INIT_00 => X"0000000000000000000000000000000000000000000000000000000000FB00FA",
      INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Port A Address 4096 to 8191, Port B Address 256 to 511
      INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Port A Address 8192 to 12287, Port B Address 512 to 767
      INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Port A Address 12288 to 16383, Port B Address 768 to 1023
      INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- The next set of INITP_xx are for the parity bits
      -- Port B Address 0 to 255
      INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Port B Address 256 to 511
      INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Port B Address 512 to 767
      INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Port B Address 768 to 1023 
      INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")
   port map (
--      DOA => DOA,       -- Port A 1-bit Data Output
      DOB => DATA_OUT,       -- Port B 16-bit Data Output
      DOPB => DOPB,     -- Port B 2-bit Parity Output
      ADDRA => "00000000000000",   -- Port A 14-bit Address Input
      ADDRB => PADDED_ADDR,   -- Port B 10-bit Address Input
      CLKA => '0',     -- Port A Clock
      CLKB => (NOT DELAYED_CLOCK),     -- Port B Clock
      DIA => "0",       -- Port A 1-bit Data Input
      DIB => DATA_BUS,       -- Port B 16-bit Data Input
      DIPB => "00",     -- Port-B 2-bit parity Input
      ENA => '0',       -- Port A RAM Enable Input
      ENB => (NOT N_CS),       -- PortB RAM Enable Input
      SSRA => '0',     -- Port A Synchronous Set/Reset Input
      SSRB => '0',     -- Port B Synchronous Set/Reset Input
      WEA => '0',       -- Port A Write Enable Input
      WEB => (NOT N_WR)        -- Port B Write Enable Input
   );


--   port map (
--      DO => DATA_OUT,      -- 16-bit Data Output
----      DOP => DOP,    -- 2-bit parity Output
--      ADDR => PADDED_ADDR,  -- 10-bit Address Input
--      CLK => (NOT DELAYED_CLOCK),    -- Clock
--      DI => DATA_BUS,      -- 16-bit Data Input
--      DIP => "00",    -- 2-bit parity Input
--
--      EN => (NOT N_CS),      -- RAM Enable Input
--      SSR => '0',    -- Synchronous Set/Reset Input
--
--      WE => (NOT N_WR)       -- Write Enable Input
--   );
--

   -- End of RAMB16_S1_S18_inst instantiation


							

   -- End  of RAMB16_S18_inst instantiation

	PADDED_ADDR <= "00000000" & ADDR_BUS(1 downto 0);

	output_enable <= (n_wr) and (NOT n_cs);
	
	data_bus <= DATA_OUT when (output_enable = '1') else "ZZZZZZZZZZZZZZZZ";



end Behavioral;

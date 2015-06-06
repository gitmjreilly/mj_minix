library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CS_Glue is
    Port (
	 	addr : in std_logic_vector(19 downto 0);
	 	CS : out std_logic_vector (15 downto 0)
	);
end CS_Glue;

architecture Behavioral of CS_Glue is
	constant RAM_CS : std_logic_vector(15 downto 0)            := "1111111111111110";
	constant ROM_CS : std_logic_vector(15 downto 0)            := "1111111111111101";
	constant UART_CS : std_logic_vector(15 downto 0)           := "1111111111111011";
	constant COUNTER1_CS : std_logic_vector(15 downto 0)       := "1111111111110111";
	constant DISK_CTLR_CS : std_logic_vector(15 downto 0)      := "1111111111101111";
	constant INT_CONTROLLER_CS : std_logic_vector(15 downto 0) := "1111111111011111";
	constant BLANK_CS : std_logic_vector(15 downto 0)          := "1111111110111111"; -- available
	constant OUTPUT_BUFFER_CS  : std_logic_vector(15 downto 0) := "1111111101111111";
	constant DISK_CTLR_UART_CS : std_logic_vector(15 downto 0) := "1111111011111111";
	constant INPUT_PORT_0_CS : std_logic_vector(15 downto 0)   := "1111110111111111";
	constant SPI_0_CS : std_logic_vector(15 downto 0)          := "1111101111111111"; -- available
	constant SPI_1_CS : std_logic_vector(15 downto 0)          := "1111011111111111"; -- available
	constant NO_CS : std_logic_vector(15 downto 0)             := "1111111111111111";

   signal local_addr : std_logic_vector(15 downto 0);

begin
	local_addr <= addr(15 downto 0);

	-- Conditional assignment forces priority
	CS <= 
		ROM_CS            when (local_addr >= x"0000" AND local_addr <= x"03FF") else 
		DISK_CTLR_CS      when (local_addr >= x"E000" and local_addr <= x"E7FF") else		
		UART_CS           when (local_addr >= x"F000" AND local_addr <= x"F00F") else
		INT_CONTROLLER_CS when (local_addr >= x"F010" AND local_addr <= x"F01F") else
		BLANK_CS          when (local_addr >= x"F020" AND local_addr <= x"F02F") else
		OUTPUT_BUFFER_CS  when (local_addr >= x"F030" AND local_addr <= x"F03F") else
		DISK_CTLR_UART_CS when (local_addr >= x"F040" AND local_addr <= x"F04F") else
		INPUT_PORT_0_CS   when (local_addr >= x"F050" AND local_addr <= x"F05F") else
		COUNTER1_CS       when (local_addr >= x"F060" AND local_addr <= x"F06F") else 
		-- SPI_0_CS          when (local_addr >= x"F070" AND local_addr <= x"F07F") else 
		-- SPI_1_CS          when (local_addr >= x"F080" AND local_addr <= x"F08F") else 
		RAM_CS;
		
end Behavioral;

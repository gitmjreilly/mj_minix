library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
entity ControlStore is
    Port ( input : in std_logic_vector(8 downto 0);
           output : out std_logic_vector(40 downto 0));
end ControlStore;


architecture Behavioral of ControlStore is

begin
output <= 
"00000100000001000010011110000010000000000" when (input = "000000000") else
    --   0 	setalu MINUS_1; setshifter SLL8; load_sp
        -- [ALU] [15] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [257] 
        -- [OriginalLine] [	setalu MINUS_1; setshifter SLL8; load_sp] 
        -- [SHIFTER] [1] 

"00000100000000000000000000000000000000000" when (input = "000000001") else
    --   1 	goto Main
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	goto Main] 

"00000100000101000000000000000000100000111" when (input = "000000010") else
    --   2 	ena_ptos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [261] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr] 

"00000000000011000000000000000000000000000" when (input = "000000011") else
    --   3 	goto HALT
        -- [NEXT_ADDRESS] [3] 
        -- [OriginalLine] [	goto HALT] 

"00000100001001000000000000000000000000000" when (input = "000000100") else
    --   4 	micronop
        -- [NEXT_ADDRESS] [265] 
        -- [OriginalLine] [	micronop] 

"00000100001011000000100000000010010100100" when (input = "000000101") else
    --   5 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [267] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000100001111000000000000000000010100111" when (input = "000000110") else
    --   6 	ena_ptos; setalu A; load_mar; read
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [271] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mar; read] 
        -- [READ] [1] 

"00000100010100000000100000000010010100100" when (input = "000000111") else
    --   7 	ena_psp; setalu DECA; load_mar; load_sp; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [276] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_mar; load_sp; read] 
        -- [READ] [1] 

"00000100010110000000100000000010010100100" when (input = "000001000") else
    --   8 	ena_sp; setalu DECA; load_mar; load_sp; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [278] 
        -- [OriginalLine] [	ena_sp; setalu DECA; load_mar; load_sp; read] 
        -- [READ] [1] 

"00000100011010000000000000000000010100111" when (input = "000001001") else
    --   9 	ena_ptos; setalu A; load_mar; read
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [282] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mar; read] 
        -- [READ] [1] 

"00000100011100000000000000000000100000110" when (input = "000001010") else
    --  10 	ena_rtos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [6] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [284] 
        -- [OriginalLine] [	ena_rtos; setalu A; load_mdr] 

"00000100100001000000100000000100010100101" when (input = "000001011") else
    --  11 	ena_rsp; setalu DECA; load_rsp; load_mar; read
        -- [ALU] [16] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [289] 
        -- [OriginalLine] [	ena_rsp; setalu DECA; load_rsp; load_mar; read] 
        -- [READ] [1] 

"00000011111110001000000000000000000000111" when (input = "000001100") else
    --  12 	ena_ptos; setalu A; jmpz dowhile_true_1 dowhile_false_1
        -- [ALU] [0] 
        -- [B] [7] 
        -- [JMPZ] [1] 
        -- [NEXT_ADDRESS] [254] 
        -- [OriginalLine] [	ena_ptos; setalu A; jmpz dowhile_true_1 dowhile_false_1] 

"00000100100111000000000000000000100000110" when (input = "000001101") else
    --  13 	ena_rtos; setalu A;load_mdr
        -- [ALU] [0] 
        -- [B] [6] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [295] 
        -- [OriginalLine] [	ena_rtos; setalu A;load_mdr] 

"00000100101101000000000000000000100000111" when (input = "000001110") else
    --  14 	ena_ptos; setalu A;load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [301] 
        -- [OriginalLine] [	ena_ptos; setalu A;load_mdr] 

"00000100000000000110000000010000000000111" when (input = "000001111") else
    --  15 	ena_ptos; setalu A; setshifter SLL1; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_ptos; setalu A; setshifter SLL1; load_ptos; goto Main] 
        -- [SHIFTER] [3] 

"00000100110011000000000000000000100000111" when (input = "000010000") else
    --  16 	ena_ptos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [307] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr] 

"00000100110110000000100000000010010100100" when (input = "000010001") else
    --  17 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [310] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000100111000000000000000000000100000111" when (input = "000010010") else
    --  18 	ena_ptos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [312] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr] 

"00000100111011000000000000000000100000111" when (input = "000010011") else
    --  19 	ena_ptos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [315] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr] 

"00000100111101000000000000000000100000111" when (input = "000010100") else
    --  20 	ena_ptos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [317] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr] 

"00000101000000000000100000000000010100100" when (input = "000010101") else
    --  21 	ena_psp; setalu DECA; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [320] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_mar; read] 
        -- [READ] [1] 

"00000101000011000000000000000000100000111" when (input = "000010110") else
    --  22 	ena_ptos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [323] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr] 

"00000100000000000000000000000010000000111" when (input = "000010111") else
    --  23 	ena_ptos; setalu A; load_psp; goto Main
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_psp; goto Main] 

"00000101001001000000100000000010010100100" when (input = "000011000") else
    --  24 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [329] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000101001011000000100000000010010100100" when (input = "000011001") else
    --  25 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [331] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000011111101010000000000000000000000111" when (input = "000011010") else
    --  26 	ena_ptos; setalu A; jmpn NEG_TRUE_1 NEG_FALSE_1
        -- [ALU] [0] 
        -- [B] [7] 
        -- [JMPN] [1] 
        -- [NEXT_ADDRESS] [253] 
        -- [OriginalLine] [	ena_ptos; setalu A; jmpn NEG_TRUE_1 NEG_FALSE_1] 

"00000101001101000000100000000010010100100" when (input = "000011011") else
    --  27 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [333] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000101001111000000100000000010010100100" when (input = "000011100") else
    --  28 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [335] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000101010001000000100000000010010100100" when (input = "000011101") else
    --  29 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [337] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000101010011000000100000000010010100100" when (input = "000011110") else
    --  30 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [339] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000101010101000000100000000010010100100" when (input = "000011111") else
    --  31 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [341] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000101010111000000100000000010010100100" when (input = "000100000") else
    --  32 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [343] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000101011010000000000001000000010000101" when (input = "000100001") else
    --  33 	ena_rsp; setalu A; load_mar; load_h
        -- [ALU] [0] 
        -- [B] [5] 
        -- [LOAD_H] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [346] 
        -- [OriginalLine] [	ena_rsp; setalu A; load_mar; load_h] 

"00000101101111000000100000000100010100101" when (input = "000100010") else
    --  34 	ena_rsp; setalu DECA; load_rsp; load_mar; read
        -- [ALU] [16] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [367] 
        -- [OriginalLine] [	ena_rsp; setalu DECA; load_rsp; load_mar; read] 
        -- [READ] [1] 

"00000100000000000000011100100000000000000" when (input = "000100011") else
    --  35 	setalu ONE; load_intctl_low; goto Main
        -- [ALU] [14] 
        -- [LOAD_OPC] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu ONE; load_intctl_low; goto Main] 

"00000100000000000100000000010000000000111" when (input = "000100100") else
    --  36 	ena_ptos; setalu A; setshifter SRA1; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_ptos; setalu A; setshifter SRA1; load_ptos; goto Main] 
        -- [SHIFTER] [2] 

"00000100000000000000011010100000000000000" when (input = "000100101") else
    --  37 	setalu ZERO; load_intctl_low; goto Main
        -- [ALU] [13] 
        -- [LOAD_OPC] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu ZERO; load_intctl_low; goto Main] 

"00000100000000000000101000010000000000111" when (input = "000100110") else
    --  38 	ena_ptos; setalu SRL_A; load_ptos; goto Main
        -- [ALU] [20] 
        -- [B] [7] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_ptos; setalu SRL_A; load_ptos; goto Main] 

"00000110000111000000100000000010010100100" when (input = "000100111") else
    --  39 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [391] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000110001001000000100000000010010100100" when (input = "000101000") else
    --  40 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [393] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000110001011000000000000000000100000111" when (input = "000101001") else
    --  41 	ena_ptos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [395] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr] 

"00000110001110000000000000000000100000111" when (input = "000101010") else
    --  42 	ena_ptos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [398] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr] 

"00000110010001000000000000000000100000111" when (input = "000101011") else
    --  43 	ena_ptos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [401] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr] 

"10000110010100000000000000000000010100111" when (input = "000101100") else
    --  44 	ena_ptos; setalu A; load_mar; read; use_es
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [404] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mar; read; use_es] 
        -- [READ] [1] 
        -- [USE_ES] [1] 

"00000110010110000000100000000010010100100" when (input = "000101101") else
    --  45 	ena_sp; setalu DECA; load_mar; load_sp; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [406] 
        -- [OriginalLine] [	ena_sp; setalu DECA; load_mar; load_sp; read] 
        -- [READ] [1] 

"00000110011010000000000001000000010000101" when (input = "000101110") else
    --  46 	ena_rsp; setalu A; load_mar; load_h
        -- [ALU] [0] 
        -- [B] [5] 
        -- [LOAD_H] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [410] 
        -- [OriginalLine] [	ena_rsp; setalu A; load_mar; load_h] 

"01000110110001000000011010000000000000000" when (input = "000101111") else
    --  47 	setalu ZERO; load_ds
        -- [ALU] [13] 
        -- [LOAD_DS] [1] 
        -- [NEXT_ADDRESS] [433] 
        -- [OriginalLine] [	setalu ZERO; load_ds] 

"00000110110010000000000000000000100000111" when (input = "000110000") else
    --  48 	ena_ptos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [434] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr] 

"00000110110101000000100000000010010100100" when (input = "000110001") else
    --  49 	ena_psp; setalu DECA; load_mar; load_sp; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [437] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_mar; load_sp; read] 
        -- [READ] [1] 

"00000110110111000000100000000010010100100" when (input = "000110010") else
    --  50 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [439] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000110111001000000000000000000100000111" when (input = "000110011") else
    --  51 	ena_ptos; setalu A; load_mdr
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [441] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr] 

"00000110111110000000100000000010010100100" when (input = "000110100") else
    --  52 	ena_psp; setalu DECA; load_mar; load_psp; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [446] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_mar; load_psp; read] 
        -- [READ] [1] 

"00000000000000000000000000000000000000000" when (input = "000110101") else
    --  53 

"00000000000000000000000000000000000000000" when (input = "000110110") else
    --  54 

"00000000000000000000000000000000000000000" when (input = "000110111") else
    --  55 

"00000000000000000000000000000000000000000" when (input = "000111000") else
    --  56 

"00000000000000000000000000000000000000000" when (input = "000111001") else
    --  57 

"00000000000000000000000000000000000000000" when (input = "000111010") else
    --  58 

"00000000000000000000000000000000000000000" when (input = "000111011") else
    --  59 

"00000000000000000000000000000000000000000" when (input = "000111100") else
    --  60 

"00000000000000000000000000000000000000000" when (input = "000111101") else
    --  61 

"00000000000000000000000000000000000000000" when (input = "000111110") else
    --  62 

"00000000000000000000000000000000000000000" when (input = "000111111") else
    --  63 

"00000000000000000000000000000000000000000" when (input = "001000000") else
    --  64 

"00000000000000000000000000000000000000000" when (input = "001000001") else
    --  65 

"00000000000000000000000000000000000000000" when (input = "001000010") else
    --  66 

"00000000000000000000000000000000000000000" when (input = "001000011") else
    --  67 

"00000000000000000000000000000000000000000" when (input = "001000100") else
    --  68 

"00000000000000000000000000000000000000000" when (input = "001000101") else
    --  69 

"00000000000000000000000000000000000000000" when (input = "001000110") else
    --  70 

"00000000000000000000000000000000000000000" when (input = "001000111") else
    --  71 

"00000000000000000000000000000000000000000" when (input = "001001000") else
    --  72 

"00000000000000000000000000000000000000000" when (input = "001001001") else
    --  73 

"00000000000000000000000000000000000000000" when (input = "001001010") else
    --  74 

"00000000000000000000000000000000000000000" when (input = "001001011") else
    --  75 

"00000000000000000000000000000000000000000" when (input = "001001100") else
    --  76 

"00000000000000000000000000000000000000000" when (input = "001001101") else
    --  77 

"00000000000000000000000000000000000000000" when (input = "001001110") else
    --  78 

"00000000000000000000000000000000000000000" when (input = "001001111") else
    --  79 

"00000000000000000000000000000000000000000" when (input = "001010000") else
    --  80 

"00000000000000000000000000000000000000000" when (input = "001010001") else
    --  81 

"00000000000000000000000000000000000000000" when (input = "001010010") else
    --  82 

"00000000000000000000000000000000000000000" when (input = "001010011") else
    --  83 

"00000000000000000000000000000000000000000" when (input = "001010100") else
    --  84 

"00000000000000000000000000000000000000000" when (input = "001010101") else
    --  85 

"00000000000000000000000000000000000000000" when (input = "001010110") else
    --  86 

"00000000000000000000000000000000000000000" when (input = "001010111") else
    --  87 

"00000000000000000000000000000000000000000" when (input = "001011000") else
    --  88 

"00000000000000000000000000000000000000000" when (input = "001011001") else
    --  89 

"00000000000000000000000000000000000000000" when (input = "001011010") else
    --  90 

"00000000000000000000000000000000000000000" when (input = "001011011") else
    --  91 

"00000000000000000000000000000000000000000" when (input = "001011100") else
    --  92 

"00000000000000000000000000000000000000000" when (input = "001011101") else
    --  93 

"00000000000000000000000000000000000000000" when (input = "001011110") else
    --  94 

"00000000000000000000000000000000000000000" when (input = "001011111") else
    --  95 

"00000000000000000000000000000000000000000" when (input = "001100000") else
    --  96 

"00000000000000000000000000000000000000000" when (input = "001100001") else
    --  97 

"00000000000000000000000000000000000000000" when (input = "001100010") else
    --  98 

"00000000000000000000000000000000000000000" when (input = "001100011") else
    --  99 

"00000000000000000000000000000000000000000" when (input = "001100100") else
    -- 100 

"00000000000000000000000000000000000000000" when (input = "001100101") else
    -- 101 

"00000000000000000000000000000000000000000" when (input = "001100110") else
    -- 102 

"00000000000000000000000000000000000000000" when (input = "001100111") else
    -- 103 

"00000000000000000000000000000000000000000" when (input = "001101000") else
    -- 104 

"00000000000000000000000000000000000000000" when (input = "001101001") else
    -- 105 

"00000000000000000000000000000000000000000" when (input = "001101010") else
    -- 106 

"00000000000000000000000000000000000000000" when (input = "001101011") else
    -- 107 

"00000000000000000000000000000000000000000" when (input = "001101100") else
    -- 108 

"00000000000000000000000000000000000000000" when (input = "001101101") else
    -- 109 

"00000000000000000000000000000000000000000" when (input = "001101110") else
    -- 110 

"00000000000000000000000000000000000000000" when (input = "001101111") else
    -- 111 

"00000000000000000000000000000000000000000" when (input = "001110000") else
    -- 112 

"00000000000000000000000000000000000000000" when (input = "001110001") else
    -- 113 

"00000000000000000000000000000000000000000" when (input = "001110010") else
    -- 114 

"00000000000000000000000000000000000000000" when (input = "001110011") else
    -- 115 

"00000000000000000000000000000000000000000" when (input = "001110100") else
    -- 116 

"00000000000000000000000000000000000000000" when (input = "001110101") else
    -- 117 

"00000000000000000000000000000000000000000" when (input = "001110110") else
    -- 118 

"00000000000000000000000000000000000000000" when (input = "001110111") else
    -- 119 

"00000000000000000000000000000000000000000" when (input = "001111000") else
    -- 120 

"00000000000000000000000000000000000000000" when (input = "001111001") else
    -- 121 

"00000000000000000000000000000000000000000" when (input = "001111010") else
    -- 122 

"00000000000000000000000000000000000000000" when (input = "001111011") else
    -- 123 

"00000000000000000000000000000000000000000" when (input = "001111100") else
    -- 124 

"00000000000000000000000000000000000000000" when (input = "001111101") else
    -- 125 

"00000000000000000000000000000000000000000" when (input = "001111110") else
    -- 126 

"00000000000000000000000000000000000000000" when (input = "001111111") else
    -- 127 

"00000000000000000000000000000000000000000" when (input = "010000000") else
    -- 128 

"00000000000000000000000000000000000000000" when (input = "010000001") else
    -- 129 

"00000000000000000000000000000000000000000" when (input = "010000010") else
    -- 130 

"00000000000000000000000000000000000000000" when (input = "010000011") else
    -- 131 

"00000000000000000000000000000000000000000" when (input = "010000100") else
    -- 132 

"00000000000000000000000000000000000000000" when (input = "010000101") else
    -- 133 

"00000000000000000000000000000000000000000" when (input = "010000110") else
    -- 134 

"00000000000000000000000000000000000000000" when (input = "010000111") else
    -- 135 

"00000000000000000000000000000000000000000" when (input = "010001000") else
    -- 136 

"00000000000000000000000000000000000000000" when (input = "010001001") else
    -- 137 

"00000000000000000000000000000000000000000" when (input = "010001010") else
    -- 138 

"00000000000000000000000000000000000000000" when (input = "010001011") else
    -- 139 

"00000000000000000000000000000000000000000" when (input = "010001100") else
    -- 140 

"00000000000000000000000000000000000000000" when (input = "010001101") else
    -- 141 

"00000000000000000000000000000000000000000" when (input = "010001110") else
    -- 142 

"00000000000000000000000000000000000000000" when (input = "010001111") else
    -- 143 

"00000000000000000000000000000000000000000" when (input = "010010000") else
    -- 144 

"00000000000000000000000000000000000000000" when (input = "010010001") else
    -- 145 

"00000000000000000000000000000000000000000" when (input = "010010010") else
    -- 146 

"00000000000000000000000000000000000000000" when (input = "010010011") else
    -- 147 

"00000000000000000000000000000000000000000" when (input = "010010100") else
    -- 148 

"00000000000000000000000000000000000000000" when (input = "010010101") else
    -- 149 

"00000000000000000000000000000000000000000" when (input = "010010110") else
    -- 150 

"00000000000000000000000000000000000000000" when (input = "010010111") else
    -- 151 

"00000000000000000000000000000000000000000" when (input = "010011000") else
    -- 152 

"00000000000000000000000000000000000000000" when (input = "010011001") else
    -- 153 

"00000000000000000000000000000000000000000" when (input = "010011010") else
    -- 154 

"00000000000000000000000000000000000000000" when (input = "010011011") else
    -- 155 

"00000000000000000000000000000000000000000" when (input = "010011100") else
    -- 156 

"00000000000000000000000000000000000000000" when (input = "010011101") else
    -- 157 

"00000000000000000000000000000000000000000" when (input = "010011110") else
    -- 158 

"00000000000000000000000000000000000000000" when (input = "010011111") else
    -- 159 

"00000000000000000000000000000000000000000" when (input = "010100000") else
    -- 160 

"00000000000000000000000000000000000000000" when (input = "010100001") else
    -- 161 

"00000000000000000000000000000000000000000" when (input = "010100010") else
    -- 162 

"00000000000000000000000000000000000000000" when (input = "010100011") else
    -- 163 

"00000000000000000000000000000000000000000" when (input = "010100100") else
    -- 164 

"00000000000000000000000000000000000000000" when (input = "010100101") else
    -- 165 

"00000000000000000000000000000000000000000" when (input = "010100110") else
    -- 166 

"00000000000000000000000000000000000000000" when (input = "010100111") else
    -- 167 

"00000000000000000000000000000000000000000" when (input = "010101000") else
    -- 168 

"00000000000000000000000000000000000000000" when (input = "010101001") else
    -- 169 

"00000000000000000000000000000000000000000" when (input = "010101010") else
    -- 170 

"00000000000000000000000000000000000000000" when (input = "010101011") else
    -- 171 

"00000000000000000000000000000000000000000" when (input = "010101100") else
    -- 172 

"00000000000000000000000000000000000000000" when (input = "010101101") else
    -- 173 

"00000000000000000000000000000000000000000" when (input = "010101110") else
    -- 174 

"00000000000000000000000000000000000000000" when (input = "010101111") else
    -- 175 

"00000000000000000000000000000000000000000" when (input = "010110000") else
    -- 176 

"00000000000000000000000000000000000000000" when (input = "010110001") else
    -- 177 

"00000000000000000000000000000000000000000" when (input = "010110010") else
    -- 178 

"00000000000000000000000000000000000000000" when (input = "010110011") else
    -- 179 

"00000000000000000000000000000000000000000" when (input = "010110100") else
    -- 180 

"00000000000000000000000000000000000000000" when (input = "010110101") else
    -- 181 

"00000000000000000000000000000000000000000" when (input = "010110110") else
    -- 182 

"00000000000000000000000000000000000000000" when (input = "010110111") else
    -- 183 

"00000000000000000000000000000000000000000" when (input = "010111000") else
    -- 184 

"00000000000000000000000000000000000000000" when (input = "010111001") else
    -- 185 

"00000000000000000000000000000000000000000" when (input = "010111010") else
    -- 186 

"00000000000000000000000000000000000000000" when (input = "010111011") else
    -- 187 

"00000000000000000000000000000000000000000" when (input = "010111100") else
    -- 188 

"00000000000000000000000000000000000000000" when (input = "010111101") else
    -- 189 

"00000000000000000000000000000000000000000" when (input = "010111110") else
    -- 190 

"00000000000000000000000000000000000000000" when (input = "010111111") else
    -- 191 

"00000000000000000000000000000000000000000" when (input = "011000000") else
    -- 192 

"00000000000000000000000000000000000000000" when (input = "011000001") else
    -- 193 

"00000000000000000000000000000000000000000" when (input = "011000010") else
    -- 194 

"00000000000000000000000000000000000000000" when (input = "011000011") else
    -- 195 

"00000000000000000000000000000000000000000" when (input = "011000100") else
    -- 196 

"00000000000000000000000000000000000000000" when (input = "011000101") else
    -- 197 

"00000000000000000000000000000000000000000" when (input = "011000110") else
    -- 198 

"00000000000000000000000000000000000000000" when (input = "011000111") else
    -- 199 

"00000000000000000000000000000000000000000" when (input = "011001000") else
    -- 200 

"00000000000000000000000000000000000000000" when (input = "011001001") else
    -- 201 

"00000000000000000000000000000000000000000" when (input = "011001010") else
    -- 202 

"00000000000000000000000000000000000000000" when (input = "011001011") else
    -- 203 

"00000000000000000000000000000000000000000" when (input = "011001100") else
    -- 204 

"00000000000000000000000000000000000000000" when (input = "011001101") else
    -- 205 

"00000000000000000000000000000000000000000" when (input = "011001110") else
    -- 206 

"00000000000000000000000000000000000000000" when (input = "011001111") else
    -- 207 

"00000000000000000000000000000000000000000" when (input = "011010000") else
    -- 208 

"00000000000000000000000000000000000000000" when (input = "011010001") else
    -- 209 

"00000000000000000000000000000000000000000" when (input = "011010010") else
    -- 210 

"00000000000000000000000000000000000000000" when (input = "011010011") else
    -- 211 

"00000000000000000000000000000000000000000" when (input = "011010100") else
    -- 212 

"00000000000000000000000000000000000000000" when (input = "011010101") else
    -- 213 

"00000000000000000000000000000000000000000" when (input = "011010110") else
    -- 214 

"00000000000000000000000000000000000000000" when (input = "011010111") else
    -- 215 

"00000000000000000000000000000000000000000" when (input = "011011000") else
    -- 216 

"00000000000000000000000000000000000000000" when (input = "011011001") else
    -- 217 

"00000000000000000000000000000000000000000" when (input = "011011010") else
    -- 218 

"00000000000000000000000000000000000000000" when (input = "011011011") else
    -- 219 

"00000000000000000000000000000000000000000" when (input = "011011100") else
    -- 220 

"00000000000000000000000000000000000000000" when (input = "011011101") else
    -- 221 

"00000000000000000000000000000000000000000" when (input = "011011110") else
    -- 222 

"00000000000000000000000000000000000000000" when (input = "011011111") else
    -- 223 

"00000000000000000000000000000000000000000" when (input = "011100000") else
    -- 224 

"00000000000000000000000000000000000000000" when (input = "011100001") else
    -- 225 

"00000000000000000000000000000000000000000" when (input = "011100010") else
    -- 226 

"00000000000000000000000000000000000000000" when (input = "011100011") else
    -- 227 

"00000000000000000000000000000000000000000" when (input = "011100100") else
    -- 228 

"00000000000000000000000000000000000000000" when (input = "011100101") else
    -- 229 

"00000000000000000000000000000000000000000" when (input = "011100110") else
    -- 230 

"00000000000000000000000000000000000000000" when (input = "011100111") else
    -- 231 

"00000000000000000000000000000000000000000" when (input = "011101000") else
    -- 232 

"00000000000000000000000000000000000000000" when (input = "011101001") else
    -- 233 

"00000000000000000000000000000000000000000" when (input = "011101010") else
    -- 234 

"00000000000000000000000000000000000000000" when (input = "011101011") else
    -- 235 

"00000000000000000000000000000000000000000" when (input = "011101100") else
    -- 236 

"00000000000000000000000000000000000000000" when (input = "011101101") else
    -- 237 

"00000000000000000000000000000000000000000" when (input = "011101110") else
    -- 238 

"00000000000000000000000000000000000000000" when (input = "011101111") else
    -- 239 

"00000000000000000000000000000000000000000" when (input = "011110000") else
    -- 240 

"00000000000000000000000000000000000000000" when (input = "011110001") else
    -- 241 

"00000000000000000000000000000000000000000" when (input = "011110010") else
    -- 242 

"00000000000000000000000000000000000000000" when (input = "011110011") else
    -- 243 

"00000000000000000000000000000000000000000" when (input = "011110100") else
    -- 244 

"00000000000000000000000000000000000000000" when (input = "011110101") else
    -- 245 

"00000000000000000000000000000000000000000" when (input = "011110110") else
    -- 246 

"00000000000000000000000000000000000000000" when (input = "011110111") else
    -- 247 

"00000000000000000000000000000000000000000" when (input = "011111000") else
    -- 248 

"00000000000000000000000000000000000000000" when (input = "011111001") else
    -- 249 

"00000000000000000000000000000000000000000" when (input = "011111010") else
    -- 250 

"00000100000000000000011010010000000000000" when (input = "011111011") else
    -- 251 	setalu ZERO; load_ptos; goto Main
        -- [ALU] [13] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu ZERO; load_ptos; goto Main] 

"00000100000000000000011010010000000000000" when (input = "011111100") else
    -- 252 	setalu ZERO; load_ptos; goto Main
        -- [ALU] [13] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu ZERO; load_ptos; goto Main] 

"00000100000000000000011010010000000000000" when (input = "011111101") else
    -- 253 	setalu ZERO; load_ptos; goto Main
        -- [ALU] [13] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu ZERO; load_ptos; goto Main] 

"00000100100101000000100000000010010100100" when (input = "011111110") else
    -- 254 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [293] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000100000000000000011010010000000000000" when (input = "011111111") else
    -- 255 	setalu ZERO; load_ptos; goto Main
        -- [ALU] [13] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu ZERO; load_ptos; goto Main] 

"00000000000000100000001100000001000010001" when (input = "100000000") else
    -- 256 	ena_pc; setalu INCA; load_pc; fetch; gotombr
        -- [ALU] [6] 
        -- [B] [1] 
        -- [FETCH] [1] 
        -- [JMPC] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [0] 
        -- [OriginalLine] [	ena_pc; setalu INCA; load_pc; fetch; gotombr] 

"00000100000010000000011110000100000000000" when (input = "100000001") else
    -- 257 	setalu MINUS_1; load_rsp
        -- [ALU] [15] 
        -- [LOAD_LV] [1] 
        -- [NEXT_ADDRESS] [258] 
        -- [OriginalLine] [	setalu MINUS_1; load_rsp] 

"00000100000011000010100000000100000000101" when (input = "100000010") else
    -- 258 	ena_rsp; setalu DECA; setshifter SLL8; load_rsp
        -- [ALU] [16] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [NEXT_ADDRESS] [259] 
        -- [OriginalLine] [	ena_rsp; setalu DECA; setshifter SLL8; load_rsp] 
        -- [SHIFTER] [1] 

"00000100000100000000011010000001000010000" when (input = "100000011") else
    -- 259 	setalu ZERO; load_pc; fetch;
        -- [ALU] [13] 
        -- [FETCH] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [260] 
        -- [OriginalLine] [	setalu ZERO; load_pc; fetch;] 

"00000100000000000000000000000000000000000" when (input = "100000100") else
    -- 260 	goto Main
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	goto Main] 

"00000100000110000000000000000000011000100" when (input = "100000101") else
    -- 261 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [262] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000100000111000000000000010000000000010" when (input = "100000110") else
    -- 262 	ena_mbr; setalu A; load_ptos
        -- [ALU] [0] 
        -- [B] [2] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [263] 
        -- [OriginalLine] [	ena_mbr; setalu A; load_ptos] 

"00000100001000000000001100000001000010001" when (input = "100000111") else
    -- 263 	ena_pc; setalu INCA; load_pc; fetch
        -- [ALU] [6] 
        -- [B] [1] 
        -- [FETCH] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [264] 
        -- [OriginalLine] [	ena_pc; setalu INCA; load_pc; fetch] 

"00000100000000000000001100000010000000100" when (input = "100001000") else
    -- 264 	ena_psp; setalu INCA; load_psp; goto Main
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp; goto Main] 

"00000100001010000000000000000001000010010" when (input = "100001001") else
    -- 265 	ena_mbr; setalu A; load_pc; fetch 
        -- [ALU] [0] 
        -- [B] [2] 
        -- [FETCH] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [266] 
        -- [OriginalLine] [	ena_mbr; setalu A; load_pc; fetch ] 

"00000100000000000000000000000000000000000" when (input = "100001010") else
    -- 266 	goto Main
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	goto Main] 

"00000100001100000000000001000000000000111" when (input = "100001011") else
    -- 267 	ena_ptos; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [268] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_h] 

"00000100001101000000000000000000000000000" when (input = "100001100") else
    -- 268 	micronop
        -- [NEXT_ADDRESS] [269] 
        -- [OriginalLine] [	micronop] 

"00000100001110000000000000000000000000000" when (input = "100001101") else
    -- 269 	micronop
        -- [NEXT_ADDRESS] [270] 
        -- [OriginalLine] [	micronop] 

"00000011111111010000100100000000000001001" when (input = "100001110") else
    -- 270 	ena_mdr; setalu A_MINUS_B; jmpn LESS_TRUE_1 LESS_FALSE_1
        -- [ALU] [18] 
        -- [B] [9] 
        -- [JMPN] [1] 
        -- [NEXT_ADDRESS] [255] 
        -- [OriginalLine] [	ena_mdr; setalu A_MINUS_B; jmpn LESS_TRUE_1 LESS_FALSE_1] 

"00000100010000000000000000000000000000000" when (input = "100001111") else
    -- 271 	micronop
        -- [NEXT_ADDRESS] [272] 
        -- [OriginalLine] [	micronop] 

"00000100010001000000001100000000101001001" when (input = "100010000") else
    -- 272 	ena_mdr; setalu INCA; load_mdr; write
        -- [ALU] [6] 
        -- [B] [9] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [273] 
        -- [OriginalLine] [	ena_mdr; setalu INCA; load_mdr; write] 
        -- [WRITE] [1] 

"00000100010010000000100000000010010100100" when (input = "100010001") else
    -- 273 	ena_psp; setalu DECA; load_mar; load_psp; read 
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [274] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_mar; load_psp; read ] 
        -- [READ] [1] 

"00000100010011000000000000000000000000000" when (input = "100010010") else
    -- 274 	micronop
        -- [NEXT_ADDRESS] [275] 
        -- [OriginalLine] [	micronop] 

"00000100000000000000000000010000000001001" when (input = "100010011") else
    -- 275 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"00000100010101000000000000000000000000000" when (input = "100010100") else
    -- 276 	micronop
        -- [NEXT_ADDRESS] [277] 
        -- [OriginalLine] [	micronop] 

"00000100000000000000000000010000000001001" when (input = "100010101") else
    -- 277 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"00000100010111000000000000000000011000111" when (input = "100010110") else
    -- 278 	ena_tos; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [279] 
        -- [OriginalLine] [	ena_tos; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000100011000000000100000000010010100100" when (input = "100010111") else
    -- 279 	ena_psp; setalu DECA; load_mar; load_psp; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [280] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_mar; load_psp; read] 
        -- [READ] [1] 

"00000100011001000000000000000000000000000" when (input = "100011000") else
    -- 280 	micronop
        -- [NEXT_ADDRESS] [281] 
        -- [OriginalLine] [	micronop] 

"00000100000000000000000000010000000001001" when (input = "100011001") else
    -- 281 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"00000100011011000000000000000000000000000" when (input = "100011010") else
    -- 282 	micronop
        -- [NEXT_ADDRESS] [283] 
        -- [OriginalLine] [	micronop] 

"00000100000000000000000000010000000001001" when (input = "100011011") else
    -- 283 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"00000100011101000000000000000000011000101" when (input = "100011100") else
    -- 284 	ena_rsp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [5] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [285] 
        -- [OriginalLine] [	ena_rsp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000100011110000000001100000100000000101" when (input = "100011101") else
    -- 285 	ena_rsp; setalu INCA; load_rsp
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [NEXT_ADDRESS] [286] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp] 

"00000100011111000000001100001000000000001" when (input = "100011110") else
    -- 286 	ena_pc; setalu INCA; load_rtos
        -- [ALU] [6] 
        -- [B] [1] 
        -- [LOAD_CPP] [1] 
        -- [NEXT_ADDRESS] [287] 
        -- [OriginalLine] [	ena_pc; setalu INCA; load_rtos] 

"00000100100000000000000000000001000010010" when (input = "100011111") else
    -- 287 	ena_mbr; setalu A; load_pc; fetch
        -- [ALU] [0] 
        -- [B] [2] 
        -- [FETCH] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [288] 
        -- [OriginalLine] [	ena_mbr; setalu A; load_pc; fetch] 

"00000100000000000000000000000000000000000" when (input = "100100000") else
    -- 288 	goto Main
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	goto Main] 

"00000100100010000000000000000001000010110" when (input = "100100001") else
    -- 289 	ena_rtos; setalu A; load_pc; fetch
        -- [ALU] [0] 
        -- [B] [6] 
        -- [FETCH] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [290] 
        -- [OriginalLine] [	ena_rtos; setalu A; load_pc; fetch] 

"00000100000000000000000000001000000001001" when (input = "100100010") else
    -- 290 	ena_mdr; setalu A; load_rtos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_CPP] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_rtos; goto Main] 

"00000100100100000000000000000001000010010" when (input = "100100011") else
    -- 291 	ena_mbr; setalu A; load_pc; fetch
        -- [ALU] [0] 
        -- [B] [2] 
        -- [FETCH] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [292] 
        -- [OriginalLine] [	ena_mbr; setalu A; load_pc; fetch] 

"00000100000000000000000000010000000001001" when (input = "100100100") else
    -- 292 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"00000100100110000000001100000001000010001" when (input = "100100101") else
    -- 293 	ena_pc; setalu INCA; load_pc; fetch
        -- [ALU] [6] 
        -- [B] [1] 
        -- [FETCH] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [294] 
        -- [OriginalLine] [	ena_pc; setalu INCA; load_pc; fetch] 

"00000100000000000000000000010000000001001" when (input = "100100110") else
    -- 294 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"00000100101000000000000000000000011000101" when (input = "100100111") else
    -- 295 	ena_rsp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [5] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [296] 
        -- [OriginalLine] [	ena_rsp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000100101001000000001100000100000000101" when (input = "100101000") else
    -- 296 	ena_rsp; setalu INCA; load_rsp
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [NEXT_ADDRESS] [297] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp] 

"00000100101010000000000000001000000000111" when (input = "100101001") else
    -- 297 	ena_ptos; setalu A; load_rtos
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_CPP] [1] 
        -- [NEXT_ADDRESS] [298] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_rtos] 

"00000100101011000000100000000010010100100" when (input = "100101010") else
    -- 298 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [299] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000100101100000000000000000000000000000" when (input = "100101011") else
    -- 299 	micronop
        -- [NEXT_ADDRESS] [300] 
        -- [OriginalLine] [	micronop] 

"00000100000000000000000000010000000001001" when (input = "100101100") else
    -- 300 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"00000100101110000000000000000000011000100" when (input = "100101101") else
    -- 301 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [302] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000100101111000000001100000010000000100" when (input = "100101110") else
    -- 302 	ena_psp; setalu INCA; load_psp
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [303] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp] 

"00000100110000000000000000010000000000110" when (input = "100101111") else
    -- 303 	ena_rtos; setalu A; load_ptos
        -- [ALU] [0] 
        -- [B] [6] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [304] 
        -- [OriginalLine] [	ena_rtos; setalu A; load_ptos] 

"00000100110001000000100000000100010100101" when (input = "100110000") else
    -- 304 	ena_rsp; setalu DECA; load_rsp; load_mar; read
        -- [ALU] [16] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [305] 
        -- [OriginalLine] [	ena_rsp; setalu DECA; load_rsp; load_mar; read] 
        -- [READ] [1] 

"00000100110010000000000000000000000000000" when (input = "100110001") else
    -- 305 	micronop
        -- [NEXT_ADDRESS] [306] 
        -- [OriginalLine] [	micronop] 

"00000100000000000000000000001000000001001" when (input = "100110010") else
    -- 306 	ena_mdr; setalu A; load_rtos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_CPP] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_rtos; goto Main] 

"00000100110100000000000000000000011000100" when (input = "100110011") else
    -- 307 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [308] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000100110101000000000000010000000000101" when (input = "100110100") else
    -- 308 	ena_rsp; setalu A; load_ptos
        -- [ALU] [0] 
        -- [B] [5] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [309] 
        -- [OriginalLine] [	ena_rsp; setalu A; load_ptos] 

"00000100000000000000001100000010000000100" when (input = "100110101") else
    -- 309 	ena_psp; setalu INCA; load_psp; goto Main
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp; goto Main] 

"00000100110111000000000000000100000000111" when (input = "100110110") else
    -- 310 	ena_ptos; setalu A; load_rsp
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_LV] [1] 
        -- [NEXT_ADDRESS] [311] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_rsp] 

"00000100000000000000000000010000000001001" when (input = "100110111") else
    -- 311 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"00000100111001000000000000000000011000100" when (input = "100111000") else
    -- 312 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [313] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000100111010000000001100000010000000100" when (input = "100111001") else
    -- 313 	ena_psp; setalu INCA; load_psp
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [314] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp] 

"00000100000000000000000000010000000000110" when (input = "100111010") else
    -- 314 	ena_rtos; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [6] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_rtos; setalu A; load_ptos; goto Main] 

"00000100111100000000000000000000011000100" when (input = "100111011") else
    -- 315 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [316] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000100000000000000001100000010000000100" when (input = "100111100") else
    -- 316 	ena_psp; setalu INCA; load_psp; goto Main
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp; goto Main] 

"00000100111110000000000000000000011000100" when (input = "100111101") else
    -- 317 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [318] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000100111111000000000000010000000000100" when (input = "100111110") else
    -- 318 	ena_psp; setalu A; load_ptos
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [319] 
        -- [OriginalLine] [	ena_psp; setalu A; load_ptos] 

"00000100000000000000001100000010000000100" when (input = "100111111") else
    -- 319 	ena_psp; setalu INCA; load_psp; goto Main
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp; goto Main] 

"00000101000001000000000001000000000000111" when (input = "101000000") else
    -- 320 	ena_ptos; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [321] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_h] 

"00000101000010000000000000010000000001001" when (input = "101000001") else
    -- 321 	ena_mdr; setalu A; load_ptos;
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [322] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos;] 

"00000100000000000000000010000000101000000" when (input = "101000010") else
    -- 322 	setalu B; load_mdr; write; goto Main
        -- [ALU] [1] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu B; load_mdr; write; goto Main] 
        -- [WRITE] [1] 

"00000101000100000000000000000000011000100" when (input = "101000011") else
    -- 323 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [324] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000101000101000000100000000000010100100" when (input = "101000100") else
    -- 324 	ena_psp; setalu DECA; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [325] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_mar; read] 
        -- [READ] [1] 

"00000101000110000000001100000010000000100" when (input = "101000101") else
    -- 325 	ena_psp; setalu INCA; load_psp
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [326] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp] 

"00000101000111000000000000010000000001001" when (input = "101000110") else
    -- 326 	ena_mdr; setalu A; load_ptos
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [327] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos] 

"00000101001000000000000000000000000000000" when (input = "101000111") else
    -- 327 	micronop
        -- [NEXT_ADDRESS] [328] 
        -- [OriginalLine] [	micronop] 

"00000100000000000000000000000000000000000" when (input = "101001000") else
    -- 328 	goto Main
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	goto Main] 

"00000101001010000000000001000000000000111" when (input = "101001001") else
    -- 329 	ena_ptos; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [330] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_h] 

"00000100000000000000001000010000000001001" when (input = "101001010") else
    -- 330 	ena_mdr; setalu ADD; load_ptos; goto Main
        -- [ALU] [4] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu ADD; load_ptos; goto Main] 

"00000101001100000000000001000000000000111" when (input = "101001011") else
    -- 331 	ena_ptos; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [332] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_h] 

"00000100000000000000100100010000000001001" when (input = "101001100") else
    -- 332 	ena_mdr; setalu A_MINUS_B; load_ptos; goto Main
        -- [ALU] [18] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A_MINUS_B; load_ptos; goto Main] 

"00000101001110000000000001000000000000111" when (input = "101001101") else
    -- 333 	ena_ptos; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [334] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_h] 

"00000100000000000000010110010000000001001" when (input = "101001110") else
    -- 334 	ena_mdr; setalu A_AND_B; load_ptos; goto Main
        -- [ALU] [11] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A_AND_B; load_ptos; goto Main] 

"00000101010000000000000001000000000000111" when (input = "101001111") else
    -- 335 	ena_ptos; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [336] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_h] 

"00000100000000000000011000010000000001001" when (input = "101010000") else
    -- 336 	ena_mdr; setalu A_OR_B; load_ptos; goto Main
        -- [ALU] [12] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A_OR_B; load_ptos; goto Main] 

"00000101010010000000000001000000000000111" when (input = "101010001") else
    -- 337 	ena_ptos; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [338] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_h] 

"00000100000000000000100010010000000001001" when (input = "101010010") else
    -- 338 	ena_mdr; setalu A_XOR_B; load_ptos; goto Main
        -- [ALU] [17] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A_XOR_B; load_ptos; goto Main] 

"00000101010100000000000001000000000000111" when (input = "101010011") else
    -- 339 	ena_ptos; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [340] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_h] 

"00000100000000000000100110010000000001001" when (input = "101010100") else
    -- 340 	ena_mdr; setalu A_MUL_B; load_ptos; goto Main
        -- [ALU] [19] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A_MUL_B; load_ptos; goto Main] 

"00000101010110000000000001000000000000111" when (input = "101010101") else
    -- 341 	ena_ptos; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [342] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_h] 

"00000011111100001000010000000000000001001" when (input = "101010110") else
    -- 342 	ena_mdr; setalu B_MINUS_A; jmpz EQUAL_TRUE_1 EQUAL_FALSE_1
        -- [ALU] [8] 
        -- [B] [9] 
        -- [JMPZ] [1] 
        -- [NEXT_ADDRESS] [252] 
        -- [OriginalLine] [	ena_mdr; setalu B_MINUS_A; jmpz EQUAL_TRUE_1 EQUAL_FALSE_1] 

"00000101011000000000000001000000000000111" when (input = "101010111") else
    -- 343 	ena_ptos; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [344] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_h] 

"00000101011001000000001100000010000000100" when (input = "101011000") else
    -- 344 	ena_psp; setalu INCA; load_psp;
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [345] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp;] 

"00001011111011000000001000000000101001001" when (input = "101011001") else
    -- 345 	ena_mdr; setalu ADD; load_mdr; write; jmpy UM_PLUS_TRUE_1 UM_PLUS_FALSE_1
        -- [ALU] [4] 
        -- [B] [9] 
        -- [JMPY] [1] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [251] 
        -- [OriginalLine] [	ena_mdr; setalu ADD; load_mdr; write; jmpy UM_PLUS_TRUE_1 UM_PLUS_FALSE_1] 
        -- [WRITE] [1] 

"00000101011011000000000000000000101001011" when (input = "101011010") else
    -- 346 	ena_ds; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [11] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [347] 
        -- [OriginalLine] [	ena_ds; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000101011100000000001100000100010000101" when (input = "101011011") else
    -- 347 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [348] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000101011101000000000000000000101001000" when (input = "101011100") else
    -- 348 	ena_cs; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [8] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [349] 
        -- [OriginalLine] [	ena_cs; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000101011110000000001100000100010000101" when (input = "101011101") else
    -- 349 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [350] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000101011111000000000000000000101000011" when (input = "101011110") else
    -- 350 	ena_es; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [3] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [351] 
        -- [OriginalLine] [	ena_es; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000101100000000000001100000100010000101" when (input = "101011111") else
    -- 351 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [352] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000101100001000000000000000000101000100" when (input = "101100000") else
    -- 352 	ena_psp; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [353] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000101100010000000001100000100010000101" when (input = "101100001") else
    -- 353 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [354] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000101100011000000000000000000101000111" when (input = "101100010") else
    -- 354 	ena_ptos; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [355] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000101100100000000001100000100010000101" when (input = "101100011") else
    -- 355 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [356] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000101100101000000100000000000101000001" when (input = "101100100") else
    -- 356 	ena_pc; setalu DECA; load_mdr; write
        -- [ALU] [16] 
        -- [B] [1] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [357] 
        -- [OriginalLine] [	ena_pc; setalu DECA; load_mdr; write] 
        -- [WRITE] [1] 

"00000101100110000000001100000100010000101" when (input = "101100101") else
    -- 357 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [358] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000101100111000000000000000000101001010" when (input = "101100110") else
    -- 358 	ena_intctl; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [10] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [359] 
        -- [OriginalLine] [	ena_intctl; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000101101000000000001100000100010000101" when (input = "101100111") else
    -- 359 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [360] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000101101001000000000010000000101000000" when (input = "101101000") else
    -- 360 	setalu B; load_mdr; write
        -- [ALU] [1] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [361] 
        -- [OriginalLine] [	setalu B; load_mdr; write] 
        -- [WRITE] [1] 

"00000101101010000000001100000100000000101" when (input = "101101001") else
    -- 361 	ena_rsp; setalu INCA; load_rsp
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [NEXT_ADDRESS] [362] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp] 

"00110101101011000000011010000000000000000" when (input = "101101010") else
    -- 362 	setalu ZERO; load_cs; load_es
        -- [ALU] [13] 
        -- [LOAD_CS] [1] 
        -- [LOAD_ES] [1] 
        -- [NEXT_ADDRESS] [363] 
        -- [OriginalLine] [	setalu ZERO; load_cs; load_es] 

"00000101101100000000011110000001000000000" when (input = "101101011") else
    -- 363 	setalu MINUS_1; load_pc
        -- [ALU] [15] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [364] 
        -- [OriginalLine] [	setalu MINUS_1; load_pc] 

"00000101101101000000100000000001000000001" when (input = "101101100") else
    -- 364 	ena_pc; setalu DECA; load_pc
        -- [ALU] [16] 
        -- [B] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [365] 
        -- [OriginalLine] [	ena_pc; setalu DECA; load_pc] 

"00000101101110000010100000000001000010001" when (input = "101101101") else
    -- 365 	ena_pc; setalu DECA; setshifter SLL8; load_pc; fetch
        -- [ALU] [16] 
        -- [B] [1] 
        -- [FETCH] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [366] 
        -- [OriginalLine] [	ena_pc; setalu DECA; setshifter SLL8; load_pc; fetch] 
        -- [SHIFTER] [1] 

"00000100000000000000011010100000000000000" when (input = "101101110") else
    -- 366 	setalu ZERO; load_intctl_low; goto Main
        -- [ALU] [13] 
        -- [LOAD_OPC] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu ZERO; load_intctl_low; goto Main] 

"00000101110000000000000000000000000000000" when (input = "101101111") else
    -- 367 	micronop;
        -- [NEXT_ADDRESS] [368] 
        -- [OriginalLine] [	micronop;] 

"00000101110001000000000001000000000001001" when (input = "101110000") else
    -- 368 	ena_mdr; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [369] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_h] 

"00000101110010000000100000000100010100101" when (input = "101110001") else
    -- 369 	ena_rsp; setalu DECA; load_rsp; load_mar; read
        -- [ALU] [16] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [370] 
        -- [OriginalLine] [	ena_rsp; setalu DECA; load_rsp; load_mar; read] 
        -- [READ] [1] 

"00000101110011000000000000000000000000000" when (input = "101110010") else
    -- 370 	micronop;
        -- [NEXT_ADDRESS] [371] 
        -- [OriginalLine] [	micronop;] 

"00000101110100000000000000100000000001001" when (input = "101110011") else
    -- 371 	ena_mdr; setalu A; load_intctl_low
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_OPC] [1] 
        -- [NEXT_ADDRESS] [372] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_intctl_low] 

"00000101110101000000100000000100010100101" when (input = "101110100") else
    -- 372 	ena_rsp; setalu DECA; load_rsp; load_mar; read
        -- [ALU] [16] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [373] 
        -- [OriginalLine] [	ena_rsp; setalu DECA; load_rsp; load_mar; read] 
        -- [READ] [1] 

"00000101110110000000000000000000000000000" when (input = "101110101") else
    -- 373 	micronop;
        -- [NEXT_ADDRESS] [374] 
        -- [OriginalLine] [	micronop;] 

"00000101110111000000000000000001000001001" when (input = "101110110") else
    -- 374 	ena_mdr; setalu A; load_pc
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [375] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_pc] 

"00000101111000000000100000000100010100101" when (input = "101110111") else
    -- 375 	ena_rsp; setalu DECA; load_rsp; load_mar; read
        -- [ALU] [16] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [376] 
        -- [OriginalLine] [	ena_rsp; setalu DECA; load_rsp; load_mar; read] 
        -- [READ] [1] 

"00000101111001000000000000000000000000000" when (input = "101111000") else
    -- 376 	micronop;
        -- [NEXT_ADDRESS] [377] 
        -- [OriginalLine] [	micronop;] 

"00000101111010000000000000010000000001001" when (input = "101111001") else
    -- 377 	ena_mdr; setalu A; load_ptos
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [378] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos] 

"00000101111011000000100000000100010100101" when (input = "101111010") else
    -- 378 	ena_rsp; setalu DECA; load_rsp; load_mar; read
        -- [ALU] [16] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [379] 
        -- [OriginalLine] [	ena_rsp; setalu DECA; load_rsp; load_mar; read] 
        -- [READ] [1] 

"00000101111100000000000000000000000000000" when (input = "101111011") else
    -- 379 	micronop;
        -- [NEXT_ADDRESS] [380] 
        -- [OriginalLine] [	micronop;] 

"00000101111101000000000000000010000001001" when (input = "101111100") else
    -- 380 	ena_mdr; setalu A; load_psp
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [381] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_psp] 

"00000101111110000000100000000100010100101" when (input = "101111101") else
    -- 381 	ena_rsp; setalu DECA; load_rsp; load_mar; read
        -- [ALU] [16] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [382] 
        -- [OriginalLine] [	ena_rsp; setalu DECA; load_rsp; load_mar; read] 
        -- [READ] [1] 

"00000101111111000000000000000000000000000" when (input = "101111110") else
    -- 382 	micronop;
        -- [NEXT_ADDRESS] [383] 
        -- [OriginalLine] [	micronop;] 

"00010110000000000000000000000000000001001" when (input = "101111111") else
    -- 383 	ena_mdr; setalu A; load_es
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_ES] [1] 
        -- [NEXT_ADDRESS] [384] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_es] 

"00000110000001000000100000000100010100101" when (input = "110000000") else
    -- 384 	ena_rsp; setalu DECA; load_rsp; load_mar; read
        -- [ALU] [16] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [385] 
        -- [OriginalLine] [	ena_rsp; setalu DECA; load_rsp; load_mar; read] 
        -- [READ] [1] 

"00000110000010000000000000000000000000000" when (input = "110000001") else
    -- 385 	micronop;
        -- [NEXT_ADDRESS] [386] 
        -- [OriginalLine] [	micronop;] 

"00100110000011000000000000000000000001001" when (input = "110000010") else
    -- 386 	ena_mdr; setalu A; load_cs
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_CS] [1] 
        -- [NEXT_ADDRESS] [387] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_cs] 

"00000110000100000000100000000100010100101" when (input = "110000011") else
    -- 387 	ena_rsp; setalu DECA; load_rsp; load_mar; read
        -- [ALU] [16] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [388] 
        -- [OriginalLine] [	ena_rsp; setalu DECA; load_rsp; load_mar; read] 
        -- [READ] [1] 

"00000110000101000000000000000000000000000" when (input = "110000100") else
    -- 388 	micronop;
        -- [NEXT_ADDRESS] [389] 
        -- [OriginalLine] [	micronop;] 

"01000110000110000000000000000000000011001" when (input = "110000101") else
    -- 389 	ena_mdr; setalu A; load_ds; fetch
        -- [ALU] [0] 
        -- [B] [9] 
        -- [FETCH] [1] 
        -- [LOAD_DS] [1] 
        -- [NEXT_ADDRESS] [390] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ds; fetch] 

"00000100000000000000000010000100000000000" when (input = "110000110") else
    -- 390 	setalu B; load_rsp; goto Main
        -- [ALU] [1] 
        -- [LOAD_LV] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu B; load_rsp; goto Main] 

"00010110001000000000000000000000000000111" when (input = "110000111") else
    -- 391 	ena_ptos; setalu A; load_es
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_ES] [1] 
        -- [NEXT_ADDRESS] [392] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_es] 

"00000100000000000000000000010000000001001" when (input = "110001000") else
    -- 392 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"01000110001010000000000000000000000000111" when (input = "110001001") else
    -- 393 	ena_ptos; setalu A; load_ds
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_DS] [1] 
        -- [NEXT_ADDRESS] [394] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_ds] 

"00000100000000000000000000010000000001001" when (input = "110001010") else
    -- 394 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"00000110001100000000000000000000011000100" when (input = "110001011") else
    -- 395 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [396] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000110001101000000001100000010000000100" when (input = "110001100") else
    -- 396 	ena_psp; setalu INCA; load_psp
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [397] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp] 

"00000100000000000000000000010000000000011" when (input = "110001101") else
    -- 397 	ena_es; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [3] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_es; setalu A; load_ptos; goto Main] 

"00000110001111000000000000000000011000100" when (input = "110001110") else
    -- 398 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [399] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000110010000000000001100000010000000100" when (input = "110001111") else
    -- 399 	ena_psp; setalu INCA; load_psp
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [400] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp] 

"00000100000000000000000000010000000001011" when (input = "110010000") else
    -- 400 	ena_ds; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [11] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_ds; setalu A; load_ptos; goto Main] 

"00000110010010000000000000000000011000100" when (input = "110010001") else
    -- 401 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [402] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000110010011000000001100000010000000100" when (input = "110010010") else
    -- 402 	ena_psp; setalu INCA; load_psp
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [403] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp] 

"00000100000000000000000000010000000001000" when (input = "110010011") else
    -- 403 	ena_cs; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [8] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_cs; setalu A; load_ptos; goto Main] 

"00000110010101000000000000000000000000000" when (input = "110010100") else
    -- 404 	micronop
        -- [NEXT_ADDRESS] [405] 
        -- [OriginalLine] [	micronop] 

"00000100000000000000000000010000000001001" when (input = "110010101") else
    -- 405 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"10000110010111000000000000000000011000111" when (input = "110010110") else
    -- 406 	ena_tos; setalu A; load_mar; write; use_es
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [407] 
        -- [OriginalLine] [	ena_tos; setalu A; load_mar; write; use_es] 
        -- [USE_ES] [1] 
        -- [WRITE] [1] 

"00000110011000000000100000000010010100100" when (input = "110010111") else
    -- 407 	ena_psp; setalu DECA; load_mar; load_psp; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [408] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_mar; load_psp; read] 
        -- [READ] [1] 

"00000110011001000000000000000000000000000" when (input = "110011000") else
    -- 408 	micronop
        -- [NEXT_ADDRESS] [409] 
        -- [OriginalLine] [	micronop] 

"00000100000000000000000000010000000001001" when (input = "110011001") else
    -- 409 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"00000110011011000000000000000000101001011" when (input = "110011010") else
    -- 410 	ena_ds; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [11] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [411] 
        -- [OriginalLine] [	ena_ds; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000110011100000000001100000100010000101" when (input = "110011011") else
    -- 411 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [412] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000110011101000000000000000000101001000" when (input = "110011100") else
    -- 412 	ena_cs; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [8] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [413] 
        -- [OriginalLine] [	ena_cs; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000110011110000000001100000100010000101" when (input = "110011101") else
    -- 413 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [414] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000110011111000000000000000000101000011" when (input = "110011110") else
    -- 414 	ena_es; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [3] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [415] 
        -- [OriginalLine] [	ena_es; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000110100000000000001100000100010000101" when (input = "110011111") else
    -- 415 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [416] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000110100001000000000000000000101000100" when (input = "110100000") else
    -- 416 	ena_psp; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [417] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000110100010000000001100000100010000101" when (input = "110100001") else
    -- 417 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [418] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000110100011000000000000000000101000111" when (input = "110100010") else
    -- 418 	ena_ptos; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [419] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000110100100000000001100000100010000101" when (input = "110100011") else
    -- 419 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [420] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000110100101000000000000000000101000001" when (input = "110100100") else
    -- 420 	ena_pc; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [1] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [421] 
        -- [OriginalLine] [	ena_pc; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000110100110000000001100000100010000101" when (input = "110100101") else
    -- 421 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [422] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000110100111000000000000000000101001010" when (input = "110100110") else
    -- 422 	ena_intctl; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [10] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [423] 
        -- [OriginalLine] [	ena_intctl; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000110101000000000001100000100010000101" when (input = "110100111") else
    -- 423 	ena_rsp; setalu INCA; load_rsp; load_mar
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [424] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp; load_mar] 

"00000110101001000000000010000000101000000" when (input = "110101000") else
    -- 424 	setalu B; load_mdr; write
        -- [ALU] [1] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [425] 
        -- [OriginalLine] [	setalu B; load_mdr; write] 
        -- [WRITE] [1] 

"00000110101010000000001100000100000000101" when (input = "110101001") else
    -- 425 	ena_rsp; setalu INCA; load_rsp
        -- [ALU] [6] 
        -- [B] [5] 
        -- [LOAD_LV] [1] 
        -- [NEXT_ADDRESS] [426] 
        -- [OriginalLine] [	ena_rsp; setalu INCA; load_rsp] 

"00110110101011000000011010000000000000000" when (input = "110101010") else
    -- 426 	setalu ZERO; load_cs; load_es
        -- [ALU] [13] 
        -- [LOAD_CS] [1] 
        -- [LOAD_ES] [1] 
        -- [NEXT_ADDRESS] [427] 
        -- [OriginalLine] [	setalu ZERO; load_cs; load_es] 

"00000110101100000000011110000001000000000" when (input = "110101011") else
    -- 427 	setalu MINUS_1; load_pc
        -- [ALU] [15] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [428] 
        -- [OriginalLine] [	setalu MINUS_1; load_pc] 

"00000110101101000000100000000001000000001" when (input = "110101100") else
    -- 428 	ena_pc; setalu DECA; load_pc
        -- [ALU] [16] 
        -- [B] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [429] 
        -- [OriginalLine] [	ena_pc; setalu DECA; load_pc] 

"00000110101110000010100000000001000000001" when (input = "110101101") else
    -- 429 	ena_pc; setalu DECA; setshifter SLL8; load_pc
        -- [ALU] [16] 
        -- [B] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [430] 
        -- [OriginalLine] [	ena_pc; setalu DECA; setshifter SLL8; load_pc] 
        -- [SHIFTER] [1] 

"00000110101111000000001100000001000000001" when (input = "110101110") else
    -- 430 	ena_pc; setalu INCA; load_pc
        -- [ALU] [6] 
        -- [B] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [431] 
        -- [OriginalLine] [	ena_pc; setalu INCA; load_pc] 

"00000110110000000000001100000001000010001" when (input = "110101111") else
    -- 431 	ena_pc; setalu INCA; load_pc; fetch
        -- [ALU] [6] 
        -- [B] [1] 
        -- [FETCH] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [432] 
        -- [OriginalLine] [	ena_pc; setalu INCA; load_pc; fetch] 

"00000100000000000000011010100000000000000" when (input = "110110000") else
    -- 432 	setalu ZERO; load_intctl_low; goto Main
        -- [ALU] [13] 
        -- [LOAD_OPC] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu ZERO; load_intctl_low; goto Main] 

"00000100000000000000000000000010000000111" when (input = "110110001") else
    -- 433 	ena_ptos; setalu A; load_psp; goto Main
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_psp; goto Main] 

"00000110110011000000000000000000011000100" when (input = "110110010") else
    -- 434 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [435] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000110110100000000000000010000000001010" when (input = "110110011") else
    -- 435 	ena_intctl; setalu A; load_ptos
        -- [ALU] [0] 
        -- [B] [10] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [436] 
        -- [OriginalLine] [	ena_intctl; setalu A; load_ptos] 

"00000100000000000000001100000010000000100" when (input = "110110100") else
    -- 436 	ena_psp; setalu INCA; load_psp; goto Main
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp; goto Main] 

"00000110110110000000000000100000000000111" when (input = "110110101") else
    -- 437 	ena_ptos; setalu A; load_intctl_low
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_OPC] [1] 
        -- [NEXT_ADDRESS] [438] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_intctl_low] 

"00000100000000000000000000010000000001001" when (input = "110110110") else
    -- 438 	ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu A; load_ptos; goto Main] 

"00000110111000000000000001000000000000111" when (input = "110110111") else
    -- 439 	ena_ptos; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [440] 
        -- [OriginalLine] [	ena_ptos; setalu A; load_h] 

"00000100000000000000101010010000000001001" when (input = "110111000") else
    -- 440 	ena_mdr; setalu S_LESS; load_ptos; goto Main
        -- [ALU] [21] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_mdr; setalu S_LESS; load_ptos; goto Main] 

"00000110111010000000000000000000011000100" when (input = "110111001") else
    -- 441 	ena_psp; setalu A; load_mar; write
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [442] 
        -- [OriginalLine] [	ena_psp; setalu A; load_mar; write] 
        -- [WRITE] [1] 

"00000110111011000000000001000000000000010" when (input = "110111010") else
    -- 442 	ena_mbr; setalu A; load_h
        -- [ALU] [0] 
        -- [B] [2] 
        -- [LOAD_H] [1] 
        -- [NEXT_ADDRESS] [443] 
        -- [OriginalLine] [	ena_mbr; setalu A; load_h] 

"00000110111100000000001000010000000000110" when (input = "110111011") else
    -- 443 	ena_rtos; setalu ADD; load_ptos 
        -- [ALU] [4] 
        -- [B] [6] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [444] 
        -- [OriginalLine] [	ena_rtos; setalu ADD; load_ptos ] 

"00000110111101000000001100000001000010001" when (input = "110111100") else
    -- 444 	ena_pc; setalu INCA; load_pc; fetch
        -- [ALU] [6] 
        -- [B] [1] 
        -- [FETCH] [1] 
        -- [LOAD_PC] [1] 
        -- [NEXT_ADDRESS] [445] 
        -- [OriginalLine] [	ena_pc; setalu INCA; load_pc; fetch] 

"00000100000000000000001100000010000000100" when (input = "110111101") else
    -- 445 	ena_psp; setalu INCA; load_psp; goto Main
        -- [ALU] [6] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	ena_psp; setalu INCA; load_psp; goto Main] 

"00000110111111000000100000000010000000100" when (input = "110111110") else
    -- 446 	ena_psp; setalu DECA; load_psp
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [447] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp] 

"00000111000000000000000000000000010001001" when (input = "110111111") else
    -- 447     ena_mdr; setalu A; load_mar
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [448] 
        -- [OriginalLine] [    ena_mdr; setalu A; load_mar] 

"00000111000001000000000000000000101000111" when (input = "111000000") else
    -- 448     ena_ptos; setalu A; load_mdr; write
        -- [ALU] [0] 
        -- [B] [7] 
        -- [LOAD_MDR] [1] 
        -- [NEXT_ADDRESS] [449] 
        -- [OriginalLine] [    ena_ptos; setalu A; load_mdr; write] 
        -- [WRITE] [1] 

"00000111000010000000000000000000010100100" when (input = "111000001") else
    -- 449     ena_psp; setalu A; load_mar; read
        -- [ALU] [0] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [NEXT_ADDRESS] [450] 
        -- [OriginalLine] [    ena_psp; setalu A; load_mar; read] 
        -- [READ] [1] 

"00000111000011000000000000000000000000000" when (input = "111000010") else
    -- 450     micronop
        -- [NEXT_ADDRESS] [451] 
        -- [OriginalLine] [    micronop] 

"00000100000000000000000000010000000001001" when (input = "111000011") else
    -- 451     ena_mdr; setalu A; load_ptos; goto Main
        -- [ALU] [0] 
        -- [B] [9] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [    ena_mdr; setalu A; load_ptos; goto Main] 

"00000000000000000000000000000000000000000" when (input = "111000100") else
    -- 452 

"00000000000000000000000000000000000000000" when (input = "111000101") else
    -- 453 

"00000000000000000000000000000000000000000" when (input = "111000110") else
    -- 454 

"00000000000000000000000000000000000000000" when (input = "111000111") else
    -- 455 

"00000000000000000000000000000000000000000" when (input = "111001000") else
    -- 456 

"00000000000000000000000000000000000000000" when (input = "111001001") else
    -- 457 

"00000000000000000000000000000000000000000" when (input = "111001010") else
    -- 458 

"00000000000000000000000000000000000000000" when (input = "111001011") else
    -- 459 

"00000000000000000000000000000000000000000" when (input = "111001100") else
    -- 460 

"00000000000000000000000000000000000000000" when (input = "111001101") else
    -- 461 

"00000000000000000000000000000000000000000" when (input = "111001110") else
    -- 462 

"00000000000000000000000000000000000000000" when (input = "111001111") else
    -- 463 

"00000000000000000000000000000000000000000" when (input = "111010000") else
    -- 464 

"00000000000000000000000000000000000000000" when (input = "111010001") else
    -- 465 

"00000000000000000000000000000000000000000" when (input = "111010010") else
    -- 466 

"00000000000000000000000000000000000000000" when (input = "111010011") else
    -- 467 

"00000000000000000000000000000000000000000" when (input = "111010100") else
    -- 468 

"00000000000000000000000000000000000000000" when (input = "111010101") else
    -- 469 

"00000000000000000000000000000000000000000" when (input = "111010110") else
    -- 470 

"00000000000000000000000000000000000000000" when (input = "111010111") else
    -- 471 

"00000000000000000000000000000000000000000" when (input = "111011000") else
    -- 472 

"00000000000000000000000000000000000000000" when (input = "111011001") else
    -- 473 

"00000000000000000000000000000000000000000" when (input = "111011010") else
    -- 474 

"00000000000000000000000000000000000000000" when (input = "111011011") else
    -- 475 

"00000000000000000000000000000000000000000" when (input = "111011100") else
    -- 476 

"00000000000000000000000000000000000000000" when (input = "111011101") else
    -- 477 

"00000000000000000000000000000000000000000" when (input = "111011110") else
    -- 478 

"00000000000000000000000000000000000000000" when (input = "111011111") else
    -- 479 

"00000000000000000000000000000000000000000" when (input = "111100000") else
    -- 480 

"00000000000000000000000000000000000000000" when (input = "111100001") else
    -- 481 

"00000000000000000000000000000000000000000" when (input = "111100010") else
    -- 482 

"00000000000000000000000000000000000000000" when (input = "111100011") else
    -- 483 

"00000000000000000000000000000000000000000" when (input = "111100100") else
    -- 484 

"00000000000000000000000000000000000000000" when (input = "111100101") else
    -- 485 

"00000000000000000000000000000000000000000" when (input = "111100110") else
    -- 486 

"00000000000000000000000000000000000000000" when (input = "111100111") else
    -- 487 

"00000000000000000000000000000000000000000" when (input = "111101000") else
    -- 488 

"00000000000000000000000000000000000000000" when (input = "111101001") else
    -- 489 

"00000000000000000000000000000000000000000" when (input = "111101010") else
    -- 490 

"00000000000000000000000000000000000000000" when (input = "111101011") else
    -- 491 

"00000000000000000000000000000000000000000" when (input = "111101100") else
    -- 492 

"00000000000000000000000000000000000000000" when (input = "111101101") else
    -- 493 

"00000000000000000000000000000000000000000" when (input = "111101110") else
    -- 494 

"00000000000000000000000000000000000000000" when (input = "111101111") else
    -- 495 

"00000000000000000000000000000000000000000" when (input = "111110000") else
    -- 496 

"00000000000000000000000000000000000000000" when (input = "111110001") else
    -- 497 

"00000000000000000000000000000000000000000" when (input = "111110010") else
    -- 498 

"00000000000000000000000000000000000000000" when (input = "111110011") else
    -- 499 

"00000000000000000000000000000000000000000" when (input = "111110100") else
    -- 500 

"00000000000000000000000000000000000000000" when (input = "111110101") else
    -- 501 

"00000000000000000000000000000000000000000" when (input = "111110110") else
    -- 502 

"00000000000000000000000000000000000000000" when (input = "111110111") else
    -- 503 

"00000000000000000000000000000000000000000" when (input = "111111000") else
    -- 504 

"00000000000000000000000000000000000000000" when (input = "111111001") else
    -- 505 

"00000000000000000000000000000000000000000" when (input = "111111010") else
    -- 506 

"00000100000000000000011100010000000000000" when (input = "111111011") else
    -- 507 	setalu ONE; load_ptos; goto Main
        -- [ALU] [14] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu ONE; load_ptos; goto Main] 

"00000100000000000000011110010000000000000" when (input = "111111100") else
    -- 508 	setalu MINUS_1; load_ptos; goto Main
        -- [ALU] [15] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu MINUS_1; load_ptos; goto Main] 

"00000100000000000000011110010000000000000" when (input = "111111101") else
    -- 509 	setalu MINUS_1; load_ptos; goto Main
        -- [ALU] [15] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu MINUS_1; load_ptos; goto Main] 

"00000100100011000000100000000010010100100" when (input = "111111110") else
    -- 510 	ena_psp; setalu DECA; load_psp; load_mar; read
        -- [ALU] [16] 
        -- [B] [4] 
        -- [LOAD_MAR] [1] 
        -- [LOAD_SP] [1] 
        -- [NEXT_ADDRESS] [291] 
        -- [OriginalLine] [	ena_psp; setalu DECA; load_psp; load_mar; read] 
        -- [READ] [1] 

"00000100000000000000011110010000000000000" when (input = "111111111") else
    -- 511 	setalu MINUS_1; load_ptos;	goto Main
        -- [ALU] [15] 
        -- [LOAD_TOS] [1] 
        -- [NEXT_ADDRESS] [256] 
        -- [OriginalLine] [	setalu MINUS_1; load_ptos;	goto Main] 

"00000000000000000000000000000000000000000";

end Behavioral;
-- ==== Symbol Table ====
  -- [AND] [27]
  -- [BRANCH] [4]
  -- [CS_FETCH] [43]
  -- [DI] [37]
  -- [DOWHILE] [12]
  -- [DO_LIT] [2]
  -- [DROP] [7]
  -- [DS_FETCH] [42]
  -- [DUP] [19]
  -- [EI] [35]
  -- [EQUAL] [31]
  -- [EQUAL_FALSE_1] [252]
  -- [EQUAL_TRUE_1] [508]
  -- [ES_FETCH] [41]
  -- [FETCH] [9]
  -- [FROM_R] [14]
  -- [HALT] [3]
  -- [JSR] [10]
  -- [JSRINT] [33]
  -- [K_SP_STORE] [47]
  -- [LESS] [5]
  -- [LESS_FALSE_1] [255]
  -- [LESS_TRUE_1] [511]
  -- [LONG_FETCH] [44]
  -- [LONG_STORE] [45]
  -- [L_VAR] [51]
  -- [MUL] [30]
  -- [Main] [256]
  -- [NEG] [26]
  -- [NEG_FALSE_1] [253]
  -- [NEG_TRUE_1] [509]
  -- [NOP] [1]
  -- [OR] [28]
  -- [OVER] [22]
  -- [PLUS] [24]
  -- [PLUSPLUS] [6]
  -- [POPF] [49]
  -- [PUSHF] [48]
  -- [RESET] [0]
  -- [RET] [11]
  -- [RETI] [34]
  -- [RP_FETCH] [16]
  -- [RP_STORE] [17]
  -- [R_FETCH] [18]
  -- [SLL] [15]
  -- [SP_FETCH] [20]
  -- [SP_STORE] [23]
  -- [SRA] [36]
  -- [SRL] [38]
  -- [STORE] [8]
  -- [STORE2] [52]
  -- [SUB] [25]
  -- [SWAP] [21]
  -- [SYSCALL] [46]
  -- [S_LESS] [50]
  -- [TO_DS] [40]
  -- [TO_ES] [39]
  -- [TO_R] [13]
  -- [UM_PLUS] [32]
  -- [UM_PLUS_FALSE_1] [251]
  -- [UM_PLUS_TRUE_1] [507]
  -- [XOR] [29]
  -- [dowhile_false_1] [254]
  -- [dowhile_true_1] [510]

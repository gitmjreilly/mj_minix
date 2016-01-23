-- Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2015.3 (lin64) Build 1368829 Mon Sep 28 20:06:39 MDT 2015
-- Date        : Fri Jan 22 19:23:08 2016
-- Host        : mint-2015 running 64-bit Linux Mint 17 Qiana
-- Command     : write_vhdl -force -mode synth_stub
--               /home/mj/git-src/repo/ellsworth_cpu/ellsworth_cpu.srcs/sources_1/ip/clk_100_50/clk_100_50_stub.vhdl
-- Design      : clk_100_50
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a35ticsg324-1L
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_100_50 is
  Port ( 
    clk_in : in STD_LOGIC;
    clk_out : out STD_LOGIC;
    reset : in STD_LOGIC
  );

end clk_100_50;

architecture stub of clk_100_50 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_in,clk_out,reset";
begin
end;

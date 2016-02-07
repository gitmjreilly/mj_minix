// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.3 (lin64) Build 1368829 Mon Sep 28 20:06:39 MDT 2015
// Date        : Sat Feb  6 19:07:02 2016
// Host        : mint-2015 running 64-bit Linux Mint 17 Qiana
// Command     : write_verilog -force -mode synth_stub
//               /home/mj/git-src/repo/ellsworth_cpu/ellsworth_cpu.srcs/sources_1/ip/clk_100_50/clk_100_50_stub.v
// Design      : clk_100_50
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35ticsg324-1L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_100_50(clk_in, clk_out, reset)
/* synthesis syn_black_box black_box_pad_pin="clk_in,clk_out,reset" */;
  input clk_in;
  output clk_out;
  input reset;
endmodule

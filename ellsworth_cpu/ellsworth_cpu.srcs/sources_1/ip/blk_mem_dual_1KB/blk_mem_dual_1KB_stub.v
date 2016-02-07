// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.3 (lin64) Build 1368829 Mon Sep 28 20:06:39 MDT 2015
// Date        : Mon Jan 25 19:51:19 2016
// Host        : mint-2015 running 64-bit Linux Mint 17 Qiana
// Command     : write_verilog -force -mode synth_stub
//               /home/mj/git-src/repo/ellsworth_cpu/ellsworth_cpu.srcs/sources_1/ip/blk_mem_dual_1KB/blk_mem_dual_1KB_stub.v
// Design      : blk_mem_dual_1KB
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35ticsg324-1L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_3_0,Vivado 2015.3" *)
module blk_mem_dual_1KB(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[9:0],dina[7:0],clkb,addrb[9:0],doutb[7:0]" */;
  input clka;
  input [0:0]wea;
  input [9:0]addra;
  input [7:0]dina;
  input clkb;
  input [9:0]addrb;
  output [7:0]doutb;
endmodule

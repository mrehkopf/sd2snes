////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2013 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: P.20131013
//  \   \         Application: netgen
//  /   /         Filename: cx4_mul.v
// /___/   /\     Timestamp: Wed Feb 11 10:00:14 2015
// \   \  /  \ 
//  \___\/\___\
//             
// Command	: -w -sim -ofmt verilog "D:/peter/Workspaces/Xilinx ISE/sd2snes-develop/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.ngc" "D:/peter/Workspaces/Xilinx ISE/sd2snes-develop/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.v" 
// Device	: 3s400pq208-4
// Input file	: D:/peter/Workspaces/Xilinx ISE/sd2snes-develop/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.ngc
// Output file	: D:/peter/Workspaces/Xilinx ISE/sd2snes-develop/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.v
// # of Modules	: 1
// Design Name	: cx4_mul
// Xilinx        : C:\Xilinx\14.7\ISE_DS\ISE\
//             
// Purpose:    
//     This verilog netlist is a verification model and uses simulation 
//     primitives which may not represent the true implementation of the 
//     device, however the netlist is functionally correct and should not 
//     be modified. This file cannot be synthesized and should only be used 
//     with supported simulation tools.
//             
// Reference:  
//     Command Line Tools User Guide, Chapter 23 and Synthesis and Simulation Design Guide, Chapter 6
//             
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/1 ps

module cx4_mul (
  clk, p, a, b
)/* synthesis syn_black_box syn_noprune=1 */;
  input clk;
  output [47 : 0] p;
  input [23 : 0] a;
  input [23 : 0] b;
  
  // synthesis translate_off
  
  wire \blk00000001/sig00000195 ;
  wire \blk00000001/sig00000194 ;
  wire \blk00000001/sig00000193 ;
  wire \blk00000001/sig00000192 ;
  wire \blk00000001/sig00000191 ;
  wire \blk00000001/sig00000190 ;
  wire \blk00000001/sig0000018f ;
  wire \blk00000001/sig0000018e ;
  wire \blk00000001/sig0000018d ;
  wire \blk00000001/sig0000018c ;
  wire \blk00000001/sig0000018b ;
  wire \blk00000001/sig0000018a ;
  wire \blk00000001/sig00000189 ;
  wire \blk00000001/sig00000188 ;
  wire \blk00000001/sig00000187 ;
  wire \blk00000001/sig00000186 ;
  wire \blk00000001/sig00000185 ;
  wire \blk00000001/sig00000184 ;
  wire \blk00000001/sig00000183 ;
  wire \blk00000001/sig00000182 ;
  wire \blk00000001/sig00000181 ;
  wire \blk00000001/sig00000180 ;
  wire \blk00000001/sig0000017f ;
  wire \blk00000001/sig0000017e ;
  wire \blk00000001/sig0000017d ;
  wire \blk00000001/sig0000017c ;
  wire \blk00000001/sig0000017b ;
  wire \blk00000001/sig0000017a ;
  wire \blk00000001/sig00000179 ;
  wire \blk00000001/sig00000178 ;
  wire \blk00000001/sig00000177 ;
  wire \blk00000001/sig00000176 ;
  wire \blk00000001/sig00000175 ;
  wire \blk00000001/sig00000174 ;
  wire \blk00000001/sig00000173 ;
  wire \blk00000001/sig00000172 ;
  wire \blk00000001/sig00000171 ;
  wire \blk00000001/sig00000170 ;
  wire \blk00000001/sig0000016f ;
  wire \blk00000001/sig0000016e ;
  wire \blk00000001/sig0000016d ;
  wire \blk00000001/sig0000016c ;
  wire \blk00000001/sig0000016b ;
  wire \blk00000001/sig0000016a ;
  wire \blk00000001/sig00000169 ;
  wire \blk00000001/sig00000168 ;
  wire \blk00000001/sig00000167 ;
  wire \blk00000001/sig00000166 ;
  wire \blk00000001/sig00000165 ;
  wire \blk00000001/sig00000164 ;
  wire \blk00000001/sig00000163 ;
  wire \blk00000001/sig00000162 ;
  wire \blk00000001/sig00000161 ;
  wire \blk00000001/sig00000160 ;
  wire \blk00000001/sig0000015f ;
  wire \blk00000001/sig0000015e ;
  wire \blk00000001/sig0000015d ;
  wire \blk00000001/sig0000015c ;
  wire \blk00000001/sig0000015b ;
  wire \blk00000001/sig0000015a ;
  wire \blk00000001/sig00000159 ;
  wire \blk00000001/sig00000158 ;
  wire \blk00000001/sig00000157 ;
  wire \blk00000001/sig00000156 ;
  wire \blk00000001/sig00000155 ;
  wire \blk00000001/sig00000154 ;
  wire \blk00000001/sig00000153 ;
  wire \blk00000001/sig00000152 ;
  wire \blk00000001/sig00000151 ;
  wire \blk00000001/sig00000150 ;
  wire \blk00000001/sig0000014f ;
  wire \blk00000001/sig0000014e ;
  wire \blk00000001/sig0000014d ;
  wire \blk00000001/sig0000014c ;
  wire \blk00000001/sig0000014b ;
  wire \blk00000001/sig0000014a ;
  wire \blk00000001/sig00000149 ;
  wire \blk00000001/sig00000148 ;
  wire \blk00000001/sig00000147 ;
  wire \blk00000001/sig00000146 ;
  wire \blk00000001/sig00000145 ;
  wire \blk00000001/sig00000144 ;
  wire \blk00000001/sig00000143 ;
  wire \blk00000001/sig00000142 ;
  wire \blk00000001/sig00000141 ;
  wire \blk00000001/sig00000140 ;
  wire \blk00000001/sig0000013f ;
  wire \blk00000001/sig0000013e ;
  wire \blk00000001/sig0000013d ;
  wire \blk00000001/sig0000013c ;
  wire \blk00000001/sig0000013b ;
  wire \blk00000001/sig0000013a ;
  wire \blk00000001/sig00000139 ;
  wire \blk00000001/sig00000138 ;
  wire \blk00000001/sig00000137 ;
  wire \blk00000001/sig00000136 ;
  wire \blk00000001/sig00000135 ;
  wire \blk00000001/sig00000134 ;
  wire \blk00000001/sig00000133 ;
  wire \blk00000001/sig00000132 ;
  wire \blk00000001/sig00000131 ;
  wire \blk00000001/sig00000130 ;
  wire \blk00000001/sig0000012f ;
  wire \blk00000001/sig0000012e ;
  wire \blk00000001/sig0000012d ;
  wire \blk00000001/sig0000012c ;
  wire \blk00000001/sig0000012b ;
  wire \blk00000001/sig0000012a ;
  wire \blk00000001/sig00000129 ;
  wire \blk00000001/sig00000128 ;
  wire \blk00000001/sig00000127 ;
  wire \blk00000001/sig00000126 ;
  wire \blk00000001/sig00000125 ;
  wire \blk00000001/sig00000124 ;
  wire \blk00000001/sig00000123 ;
  wire \blk00000001/sig00000122 ;
  wire \blk00000001/sig00000121 ;
  wire \blk00000001/sig00000120 ;
  wire \blk00000001/sig0000011f ;
  wire \blk00000001/sig0000011e ;
  wire \blk00000001/sig0000011d ;
  wire \blk00000001/sig0000011c ;
  wire \blk00000001/sig0000011b ;
  wire \blk00000001/sig0000011a ;
  wire \blk00000001/sig00000119 ;
  wire \blk00000001/sig00000118 ;
  wire \blk00000001/sig00000117 ;
  wire \blk00000001/sig00000116 ;
  wire \blk00000001/sig00000115 ;
  wire \blk00000001/sig00000114 ;
  wire \blk00000001/sig00000113 ;
  wire \blk00000001/sig00000112 ;
  wire \blk00000001/sig00000111 ;
  wire \blk00000001/sig00000110 ;
  wire \blk00000001/sig0000010f ;
  wire \blk00000001/sig0000010e ;
  wire \blk00000001/sig0000010d ;
  wire \blk00000001/sig0000010c ;
  wire \blk00000001/sig0000010b ;
  wire \blk00000001/sig0000010a ;
  wire \blk00000001/sig00000109 ;
  wire \blk00000001/sig00000108 ;
  wire \blk00000001/sig00000107 ;
  wire \blk00000001/sig00000106 ;
  wire \blk00000001/sig00000105 ;
  wire \blk00000001/sig00000104 ;
  wire \blk00000001/sig00000103 ;
  wire \blk00000001/sig00000102 ;
  wire \blk00000001/sig00000101 ;
  wire \blk00000001/sig00000100 ;
  wire \blk00000001/sig000000ff ;
  wire \blk00000001/sig000000fe ;
  wire \blk00000001/sig000000fd ;
  wire \blk00000001/sig000000fc ;
  wire \blk00000001/sig000000fb ;
  wire \blk00000001/sig000000fa ;
  wire \blk00000001/sig000000f9 ;
  wire \blk00000001/sig000000f8 ;
  wire \blk00000001/sig000000f7 ;
  wire \blk00000001/sig000000f6 ;
  wire \blk00000001/sig000000f5 ;
  wire \blk00000001/sig000000f4 ;
  wire \blk00000001/sig000000f3 ;
  wire \blk00000001/sig000000f2 ;
  wire \blk00000001/sig000000f1 ;
  wire \blk00000001/sig000000f0 ;
  wire \blk00000001/sig000000ef ;
  wire \blk00000001/sig000000ee ;
  wire \blk00000001/sig000000ed ;
  wire \blk00000001/sig000000ec ;
  wire \blk00000001/sig000000eb ;
  wire \blk00000001/sig000000ea ;
  wire \blk00000001/sig000000e9 ;
  wire \blk00000001/sig000000e8 ;
  wire \blk00000001/sig000000e7 ;
  wire \blk00000001/sig000000e6 ;
  wire \blk00000001/sig000000e5 ;
  wire \blk00000001/sig000000e4 ;
  wire \blk00000001/sig000000e3 ;
  wire \blk00000001/sig000000e2 ;
  wire \blk00000001/sig000000e1 ;
  wire \blk00000001/sig000000e0 ;
  wire \blk00000001/sig000000df ;
  wire \blk00000001/sig000000de ;
  wire \blk00000001/sig000000dd ;
  wire \blk00000001/sig000000dc ;
  wire \blk00000001/sig000000db ;
  wire \blk00000001/sig000000da ;
  wire \blk00000001/sig000000d9 ;
  wire \blk00000001/sig000000d8 ;
  wire \blk00000001/sig000000d7 ;
  wire \blk00000001/sig000000d6 ;
  wire \blk00000001/sig000000d5 ;
  wire \blk00000001/sig000000d4 ;
  wire \blk00000001/sig000000d3 ;
  wire \blk00000001/sig000000d2 ;
  wire \blk00000001/sig000000d1 ;
  wire \blk00000001/sig000000d0 ;
  wire \blk00000001/sig000000cf ;
  wire \blk00000001/sig000000ce ;
  wire \blk00000001/sig000000cd ;
  wire \blk00000001/sig000000cc ;
  wire \blk00000001/sig000000cb ;
  wire \blk00000001/sig000000ca ;
  wire \blk00000001/sig000000c9 ;
  wire \blk00000001/sig000000c8 ;
  wire \blk00000001/sig000000c7 ;
  wire \blk00000001/sig000000c6 ;
  wire \blk00000001/sig000000c5 ;
  wire \blk00000001/sig000000c4 ;
  wire \blk00000001/sig000000c3 ;
  wire \blk00000001/sig000000c2 ;
  wire \blk00000001/sig000000c1 ;
  wire \blk00000001/sig000000c0 ;
  wire \blk00000001/sig000000bf ;
  wire \blk00000001/sig000000be ;
  wire \blk00000001/sig000000bd ;
  wire \blk00000001/sig000000bc ;
  wire \blk00000001/sig000000bb ;
  wire \blk00000001/sig000000ba ;
  wire \blk00000001/sig000000b9 ;
  wire \blk00000001/sig000000b8 ;
  wire \blk00000001/sig000000b7 ;
  wire \blk00000001/sig000000b6 ;
  wire \blk00000001/sig000000b5 ;
  wire \blk00000001/sig000000b4 ;
  wire \blk00000001/sig000000b3 ;
  wire \blk00000001/sig000000b2 ;
  wire \blk00000001/sig000000b1 ;
  wire \blk00000001/sig000000b0 ;
  wire \blk00000001/sig000000af ;
  wire \blk00000001/sig000000ae ;
  wire \blk00000001/sig000000ad ;
  wire \blk00000001/sig000000ac ;
  wire \blk00000001/sig000000ab ;
  wire \blk00000001/sig000000aa ;
  wire \blk00000001/sig000000a9 ;
  wire \blk00000001/sig000000a8 ;
  wire \blk00000001/sig000000a7 ;
  wire \blk00000001/sig000000a6 ;
  wire \blk00000001/sig000000a5 ;
  wire \blk00000001/sig000000a4 ;
  wire \blk00000001/sig000000a3 ;
  wire \blk00000001/sig000000a2 ;
  wire \blk00000001/sig000000a1 ;
  wire \blk00000001/sig000000a0 ;
  wire \blk00000001/sig0000009f ;
  wire \blk00000001/sig0000009e ;
  wire \blk00000001/sig0000009d ;
  wire \blk00000001/sig0000009c ;
  wire \blk00000001/sig0000009b ;
  wire \blk00000001/sig0000009a ;
  wire \blk00000001/sig00000099 ;
  wire \blk00000001/sig00000098 ;
  wire \blk00000001/sig00000097 ;
  wire \blk00000001/sig00000096 ;
  wire \blk00000001/sig00000095 ;
  wire \blk00000001/sig00000094 ;
  wire \blk00000001/sig00000093 ;
  wire \blk00000001/sig00000092 ;
  wire \blk00000001/sig00000091 ;
  wire \blk00000001/sig00000090 ;
  wire \blk00000001/sig0000008f ;
  wire \blk00000001/sig0000008e ;
  wire \blk00000001/sig0000008d ;
  wire \blk00000001/sig0000008c ;
  wire \blk00000001/sig0000008b ;
  wire \blk00000001/sig0000008a ;
  wire \blk00000001/sig00000089 ;
  wire \blk00000001/sig00000088 ;
  wire \blk00000001/sig00000087 ;
  wire \blk00000001/sig00000086 ;
  wire \blk00000001/sig00000085 ;
  wire \blk00000001/sig00000084 ;
  wire \blk00000001/sig00000083 ;
  wire \blk00000001/sig00000082 ;
  wire \blk00000001/sig00000081 ;
  wire \blk00000001/sig00000080 ;
  wire \blk00000001/sig0000007f ;
  wire \blk00000001/sig0000007e ;
  wire \blk00000001/sig0000007d ;
  wire \blk00000001/sig0000007c ;
  wire \blk00000001/sig0000007b ;
  wire \blk00000001/sig0000007a ;
  wire \blk00000001/sig00000079 ;
  wire \blk00000001/sig00000078 ;
  wire \blk00000001/sig00000077 ;
  wire \blk00000001/sig00000076 ;
  wire \blk00000001/sig00000075 ;
  wire \blk00000001/sig00000074 ;
  wire \blk00000001/sig00000073 ;
  wire \blk00000001/sig00000072 ;
  wire \blk00000001/sig00000071 ;
  wire \blk00000001/sig00000070 ;
  wire \blk00000001/sig0000006f ;
  wire \blk00000001/sig0000006e ;
  wire \blk00000001/sig0000006d ;
  wire \blk00000001/sig0000006c ;
  wire \blk00000001/sig0000006b ;
  wire \blk00000001/sig0000006a ;
  wire \blk00000001/sig00000069 ;
  wire \blk00000001/sig00000068 ;
  wire \blk00000001/sig00000067 ;
  wire \blk00000001/sig00000066 ;
  wire \blk00000001/sig00000065 ;
  wire \blk00000001/sig00000064 ;
  wire \blk00000001/sig00000063 ;
  wire \blk00000001/sig00000062 ;
  wire \blk00000001/sig00000061 ;
  wire \blk00000001/sig00000060 ;
  wire \blk00000001/sig0000005f ;
  wire \blk00000001/sig0000005e ;
  wire \blk00000001/sig0000005d ;
  wire \blk00000001/sig0000005c ;
  wire \blk00000001/sig0000005b ;
  wire \blk00000001/sig0000005a ;
  wire \blk00000001/sig00000059 ;
  wire \blk00000001/sig00000058 ;
  wire \blk00000001/sig00000057 ;
  wire \blk00000001/sig00000056 ;
  wire \blk00000001/sig00000055 ;
  wire \blk00000001/sig00000054 ;
  wire \blk00000001/sig00000053 ;
  wire \blk00000001/sig00000052 ;
  wire \blk00000001/sig00000051 ;
  wire \blk00000001/sig00000050 ;
  wire \blk00000001/sig0000004f ;
  wire \blk00000001/sig0000004e ;
  wire \blk00000001/sig0000004d ;
  wire \blk00000001/sig0000004c ;
  wire \blk00000001/sig0000004b ;
  wire \blk00000001/sig0000004a ;
  wire \blk00000001/sig00000049 ;
  wire \blk00000001/sig00000048 ;
  wire \blk00000001/sig00000047 ;
  wire \blk00000001/sig00000046 ;
  wire \blk00000001/sig00000045 ;
  wire \blk00000001/sig00000044 ;
  wire \blk00000001/sig00000043 ;
  wire \blk00000001/sig00000042 ;
  wire \blk00000001/sig00000041 ;
  wire \blk00000001/sig00000040 ;
  wire \blk00000001/sig0000003f ;
  wire \blk00000001/sig0000003e ;
  wire \blk00000001/sig0000003d ;
  wire \blk00000001/sig0000003c ;
  wire \blk00000001/sig0000003b ;
  wire \blk00000001/sig0000003a ;
  wire \blk00000001/sig00000039 ;
  wire \blk00000001/sig00000038 ;
  wire \blk00000001/sig00000037 ;
  wire \blk00000001/sig00000036 ;
  wire \blk00000001/sig00000035 ;
  wire \blk00000001/sig00000034 ;
  wire \blk00000001/sig00000033 ;
  wire \blk00000001/sig00000032 ;
  wire \NLW_blk00000001/blk00000007_P<35>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<35>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<34>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<33>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<32>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<31>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<30>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<29>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<28>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<27>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<26>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<25>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000006_P<24>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<35>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<34>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<33>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<32>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<31>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<30>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<29>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<28>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<27>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<26>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<25>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000005_P<24>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<35>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<34>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<33>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<32>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<31>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<30>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<29>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<28>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<27>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<26>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<25>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<24>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<23>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<22>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<21>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<20>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<19>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<18>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<17>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<16>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<15>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000004_P<14>_UNCONNECTED ;
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000138  (
    .C(clk),
    .D(\blk00000001/sig000000bf ),
    .Q(p[0])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000137  (
    .C(clk),
    .D(\blk00000001/sig000000ca ),
    .Q(p[1])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000136  (
    .C(clk),
    .D(\blk00000001/sig000000d5 ),
    .Q(p[2])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000135  (
    .C(clk),
    .D(\blk00000001/sig000000db ),
    .Q(p[3])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000134  (
    .C(clk),
    .D(\blk00000001/sig000000dc ),
    .Q(p[4])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000133  (
    .C(clk),
    .D(\blk00000001/sig000000dd ),
    .Q(p[5])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000132  (
    .C(clk),
    .D(\blk00000001/sig000000de ),
    .Q(p[6])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000131  (
    .C(clk),
    .D(\blk00000001/sig000000df ),
    .Q(p[7])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000130  (
    .C(clk),
    .D(\blk00000001/sig000000e0 ),
    .Q(p[8])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012f  (
    .C(clk),
    .D(\blk00000001/sig000000e1 ),
    .Q(p[9])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012e  (
    .C(clk),
    .D(\blk00000001/sig000000c0 ),
    .Q(p[10])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012d  (
    .C(clk),
    .D(\blk00000001/sig000000c1 ),
    .Q(p[11])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012c  (
    .C(clk),
    .D(\blk00000001/sig000000c2 ),
    .Q(p[12])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012b  (
    .C(clk),
    .D(\blk00000001/sig000000c3 ),
    .Q(p[13])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012a  (
    .C(clk),
    .D(\blk00000001/sig000000c4 ),
    .Q(p[14])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000129  (
    .C(clk),
    .D(\blk00000001/sig000000c5 ),
    .Q(p[15])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000128  (
    .C(clk),
    .D(\blk00000001/sig000000c6 ),
    .Q(p[16])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000127  (
    .C(clk),
    .D(\blk00000001/sig000000c7 ),
    .Q(\blk00000001/sig00000120 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000126  (
    .C(clk),
    .D(\blk00000001/sig000000c8 ),
    .Q(\blk00000001/sig00000121 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000125  (
    .C(clk),
    .D(\blk00000001/sig000000c9 ),
    .Q(\blk00000001/sig00000122 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000124  (
    .C(clk),
    .D(\blk00000001/sig000000cb ),
    .Q(\blk00000001/sig00000123 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000123  (
    .C(clk),
    .D(\blk00000001/sig000000cc ),
    .Q(\blk00000001/sig00000124 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000122  (
    .C(clk),
    .D(\blk00000001/sig000000cd ),
    .Q(\blk00000001/sig00000125 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000121  (
    .C(clk),
    .D(\blk00000001/sig000000ce ),
    .Q(\blk00000001/sig00000126 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000120  (
    .C(clk),
    .D(\blk00000001/sig000000cf ),
    .Q(\blk00000001/sig00000127 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011f  (
    .C(clk),
    .D(\blk00000001/sig000000d0 ),
    .Q(\blk00000001/sig00000128 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011e  (
    .C(clk),
    .D(\blk00000001/sig000000d1 ),
    .Q(\blk00000001/sig00000129 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011d  (
    .C(clk),
    .D(\blk00000001/sig000000d2 ),
    .Q(\blk00000001/sig0000012a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011c  (
    .C(clk),
    .D(\blk00000001/sig000000d3 ),
    .Q(\blk00000001/sig0000012b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011b  (
    .C(clk),
    .D(\blk00000001/sig000000d4 ),
    .Q(\blk00000001/sig0000012c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011a  (
    .C(clk),
    .D(\blk00000001/sig000000d6 ),
    .Q(\blk00000001/sig0000012d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000119  (
    .C(clk),
    .D(\blk00000001/sig000000d7 ),
    .Q(\blk00000001/sig0000012e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000118  (
    .C(clk),
    .D(\blk00000001/sig000000d8 ),
    .Q(\blk00000001/sig0000012f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000117  (
    .C(clk),
    .D(\blk00000001/sig000000d9 ),
    .Q(\blk00000001/sig00000130 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000116  (
    .C(clk),
    .D(\blk00000001/sig000000da ),
    .Q(\blk00000001/sig00000131 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000115  (
    .C(clk),
    .D(\blk00000001/sig00000112 ),
    .Q(\blk00000001/sig00000162 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000114  (
    .C(clk),
    .D(\blk00000001/sig00000117 ),
    .Q(\blk00000001/sig00000163 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000113  (
    .C(clk),
    .D(\blk00000001/sig00000118 ),
    .Q(\blk00000001/sig00000168 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000112  (
    .C(clk),
    .D(\blk00000001/sig00000119 ),
    .Q(\blk00000001/sig00000169 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000111  (
    .C(clk),
    .D(\blk00000001/sig0000011a ),
    .Q(\blk00000001/sig0000016a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000110  (
    .C(clk),
    .D(\blk00000001/sig0000011b ),
    .Q(\blk00000001/sig0000016b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010f  (
    .C(clk),
    .D(\blk00000001/sig0000011c ),
    .Q(\blk00000001/sig0000016c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010e  (
    .C(clk),
    .D(\blk00000001/sig0000011d ),
    .Q(\blk00000001/sig0000016d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010d  (
    .C(clk),
    .D(\blk00000001/sig0000011e ),
    .Q(\blk00000001/sig0000016e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010c  (
    .C(clk),
    .D(\blk00000001/sig0000011f ),
    .Q(\blk00000001/sig0000016f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010b  (
    .C(clk),
    .D(\blk00000001/sig00000113 ),
    .Q(\blk00000001/sig00000164 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010a  (
    .C(clk),
    .D(\blk00000001/sig00000114 ),
    .Q(\blk00000001/sig00000165 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000109  (
    .C(clk),
    .D(\blk00000001/sig00000115 ),
    .Q(\blk00000001/sig00000166 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000108  (
    .C(clk),
    .D(\blk00000001/sig00000116 ),
    .Q(\blk00000001/sig00000167 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000107  (
    .C(clk),
    .D(\blk00000001/sig000000e2 ),
    .Q(\blk00000001/sig00000132 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000106  (
    .C(clk),
    .D(\blk00000001/sig000000ed ),
    .Q(\blk00000001/sig00000133 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000105  (
    .C(clk),
    .D(\blk00000001/sig000000f2 ),
    .Q(\blk00000001/sig0000013e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000104  (
    .C(clk),
    .D(\blk00000001/sig000000f3 ),
    .Q(\blk00000001/sig00000143 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000103  (
    .C(clk),
    .D(\blk00000001/sig000000f4 ),
    .Q(\blk00000001/sig00000144 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000102  (
    .C(clk),
    .D(\blk00000001/sig000000f5 ),
    .Q(\blk00000001/sig00000145 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000101  (
    .C(clk),
    .D(\blk00000001/sig000000f6 ),
    .Q(\blk00000001/sig00000146 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000100  (
    .C(clk),
    .D(\blk00000001/sig000000f7 ),
    .Q(\blk00000001/sig00000147 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ff  (
    .C(clk),
    .D(\blk00000001/sig000000f8 ),
    .Q(\blk00000001/sig00000148 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fe  (
    .C(clk),
    .D(\blk00000001/sig000000f9 ),
    .Q(\blk00000001/sig00000149 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fd  (
    .C(clk),
    .D(\blk00000001/sig000000e3 ),
    .Q(\blk00000001/sig00000134 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fc  (
    .C(clk),
    .D(\blk00000001/sig000000e4 ),
    .Q(\blk00000001/sig00000135 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fb  (
    .C(clk),
    .D(\blk00000001/sig000000e5 ),
    .Q(\blk00000001/sig00000136 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fa  (
    .C(clk),
    .D(\blk00000001/sig000000e6 ),
    .Q(\blk00000001/sig00000137 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f9  (
    .C(clk),
    .D(\blk00000001/sig000000e7 ),
    .Q(\blk00000001/sig00000138 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f8  (
    .C(clk),
    .D(\blk00000001/sig000000e8 ),
    .Q(\blk00000001/sig00000139 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f7  (
    .C(clk),
    .D(\blk00000001/sig000000e9 ),
    .Q(\blk00000001/sig0000013a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f6  (
    .C(clk),
    .D(\blk00000001/sig000000ea ),
    .Q(\blk00000001/sig0000013b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f5  (
    .C(clk),
    .D(\blk00000001/sig000000eb ),
    .Q(\blk00000001/sig0000013c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f4  (
    .C(clk),
    .D(\blk00000001/sig000000ec ),
    .Q(\blk00000001/sig0000013d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f3  (
    .C(clk),
    .D(\blk00000001/sig000000ee ),
    .Q(\blk00000001/sig0000013f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f2  (
    .C(clk),
    .D(\blk00000001/sig000000ef ),
    .Q(\blk00000001/sig00000140 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f1  (
    .C(clk),
    .D(\blk00000001/sig000000f0 ),
    .Q(\blk00000001/sig00000141 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f0  (
    .C(clk),
    .D(\blk00000001/sig000000f1 ),
    .Q(\blk00000001/sig00000142 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ef  (
    .C(clk),
    .D(\blk00000001/sig000000fa ),
    .Q(\blk00000001/sig0000014a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ee  (
    .C(clk),
    .D(\blk00000001/sig00000105 ),
    .Q(\blk00000001/sig0000014b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ed  (
    .C(clk),
    .D(\blk00000001/sig0000010a ),
    .Q(\blk00000001/sig00000156 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ec  (
    .C(clk),
    .D(\blk00000001/sig0000010b ),
    .Q(\blk00000001/sig0000015b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000eb  (
    .C(clk),
    .D(\blk00000001/sig0000010c ),
    .Q(\blk00000001/sig0000015c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ea  (
    .C(clk),
    .D(\blk00000001/sig0000010d ),
    .Q(\blk00000001/sig0000015d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e9  (
    .C(clk),
    .D(\blk00000001/sig0000010e ),
    .Q(\blk00000001/sig0000015e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e8  (
    .C(clk),
    .D(\blk00000001/sig0000010f ),
    .Q(\blk00000001/sig0000015f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e7  (
    .C(clk),
    .D(\blk00000001/sig00000110 ),
    .Q(\blk00000001/sig00000160 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e6  (
    .C(clk),
    .D(\blk00000001/sig00000111 ),
    .Q(\blk00000001/sig00000161 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e5  (
    .C(clk),
    .D(\blk00000001/sig000000fb ),
    .Q(\blk00000001/sig0000014c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e4  (
    .C(clk),
    .D(\blk00000001/sig000000fc ),
    .Q(\blk00000001/sig0000014d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e3  (
    .C(clk),
    .D(\blk00000001/sig000000fd ),
    .Q(\blk00000001/sig0000014e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e2  (
    .C(clk),
    .D(\blk00000001/sig000000fe ),
    .Q(\blk00000001/sig0000014f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e1  (
    .C(clk),
    .D(\blk00000001/sig000000ff ),
    .Q(\blk00000001/sig00000150 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e0  (
    .C(clk),
    .D(\blk00000001/sig00000100 ),
    .Q(\blk00000001/sig00000151 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000df  (
    .C(clk),
    .D(\blk00000001/sig00000101 ),
    .Q(\blk00000001/sig00000152 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000de  (
    .C(clk),
    .D(\blk00000001/sig00000102 ),
    .Q(\blk00000001/sig00000153 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000dd  (
    .C(clk),
    .D(\blk00000001/sig00000103 ),
    .Q(\blk00000001/sig00000154 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000dc  (
    .C(clk),
    .D(\blk00000001/sig00000104 ),
    .Q(\blk00000001/sig00000155 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000db  (
    .C(clk),
    .D(\blk00000001/sig00000106 ),
    .Q(\blk00000001/sig00000157 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000da  (
    .C(clk),
    .D(\blk00000001/sig00000107 ),
    .Q(\blk00000001/sig00000158 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000d9  (
    .C(clk),
    .D(\blk00000001/sig00000108 ),
    .Q(\blk00000001/sig00000159 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000d8  (
    .C(clk),
    .D(\blk00000001/sig00000109 ),
    .Q(\blk00000001/sig0000015a )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000d7  (
    .I0(\blk00000001/sig00000153 ),
    .I1(\blk00000001/sig00000162 ),
    .O(\blk00000001/sig00000070 )
  );
  MUXCY   \blk00000001/blk000000d6  (
    .CI(\blk00000001/sig00000032 ),
    .DI(\blk00000001/sig00000153 ),
    .S(\blk00000001/sig00000070 ),
    .O(\blk00000001/sig00000063 )
  );
  XORCY   \blk00000001/blk000000d5  (
    .CI(\blk00000001/sig00000032 ),
    .LI(\blk00000001/sig00000070 ),
    .O(\blk00000001/sig00000188 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000d4  (
    .I0(\blk00000001/sig00000154 ),
    .I1(\blk00000001/sig00000163 ),
    .O(\blk00000001/sig00000075 )
  );
  MUXCY   \blk00000001/blk000000d3  (
    .CI(\blk00000001/sig00000063 ),
    .DI(\blk00000001/sig00000154 ),
    .S(\blk00000001/sig00000075 ),
    .O(\blk00000001/sig00000067 )
  );
  XORCY   \blk00000001/blk000000d2  (
    .CI(\blk00000001/sig00000063 ),
    .LI(\blk00000001/sig00000075 ),
    .O(\blk00000001/sig0000018d )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000d1  (
    .I0(\blk00000001/sig00000155 ),
    .I1(\blk00000001/sig00000168 ),
    .O(\blk00000001/sig00000076 )
  );
  MUXCY   \blk00000001/blk000000d0  (
    .CI(\blk00000001/sig00000067 ),
    .DI(\blk00000001/sig00000155 ),
    .S(\blk00000001/sig00000076 ),
    .O(\blk00000001/sig00000068 )
  );
  XORCY   \blk00000001/blk000000cf  (
    .CI(\blk00000001/sig00000067 ),
    .LI(\blk00000001/sig00000076 ),
    .O(\blk00000001/sig0000018e )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ce  (
    .I0(\blk00000001/sig00000157 ),
    .I1(\blk00000001/sig00000169 ),
    .O(\blk00000001/sig00000077 )
  );
  MUXCY   \blk00000001/blk000000cd  (
    .CI(\blk00000001/sig00000068 ),
    .DI(\blk00000001/sig00000157 ),
    .S(\blk00000001/sig00000077 ),
    .O(\blk00000001/sig00000069 )
  );
  XORCY   \blk00000001/blk000000cc  (
    .CI(\blk00000001/sig00000068 ),
    .LI(\blk00000001/sig00000077 ),
    .O(\blk00000001/sig0000018f )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000cb  (
    .I0(\blk00000001/sig00000158 ),
    .I1(\blk00000001/sig0000016a ),
    .O(\blk00000001/sig00000078 )
  );
  MUXCY   \blk00000001/blk000000ca  (
    .CI(\blk00000001/sig00000069 ),
    .DI(\blk00000001/sig00000158 ),
    .S(\blk00000001/sig00000078 ),
    .O(\blk00000001/sig0000006a )
  );
  XORCY   \blk00000001/blk000000c9  (
    .CI(\blk00000001/sig00000069 ),
    .LI(\blk00000001/sig00000078 ),
    .O(\blk00000001/sig00000190 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c8  (
    .I0(\blk00000001/sig00000159 ),
    .I1(\blk00000001/sig0000016b ),
    .O(\blk00000001/sig00000079 )
  );
  MUXCY   \blk00000001/blk000000c7  (
    .CI(\blk00000001/sig0000006a ),
    .DI(\blk00000001/sig00000159 ),
    .S(\blk00000001/sig00000079 ),
    .O(\blk00000001/sig0000006b )
  );
  XORCY   \blk00000001/blk000000c6  (
    .CI(\blk00000001/sig0000006a ),
    .LI(\blk00000001/sig00000079 ),
    .O(\blk00000001/sig00000191 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c5  (
    .I0(\blk00000001/sig0000015a ),
    .I1(\blk00000001/sig0000016c ),
    .O(\blk00000001/sig0000007a )
  );
  MUXCY   \blk00000001/blk000000c4  (
    .CI(\blk00000001/sig0000006b ),
    .DI(\blk00000001/sig0000015a ),
    .S(\blk00000001/sig0000007a ),
    .O(\blk00000001/sig0000006c )
  );
  XORCY   \blk00000001/blk000000c3  (
    .CI(\blk00000001/sig0000006b ),
    .LI(\blk00000001/sig0000007a ),
    .O(\blk00000001/sig00000192 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c2  (
    .I0(\blk00000001/sig0000015a ),
    .I1(\blk00000001/sig0000016d ),
    .O(\blk00000001/sig0000007b )
  );
  MUXCY   \blk00000001/blk000000c1  (
    .CI(\blk00000001/sig0000006c ),
    .DI(\blk00000001/sig0000015a ),
    .S(\blk00000001/sig0000007b ),
    .O(\blk00000001/sig0000006d )
  );
  XORCY   \blk00000001/blk000000c0  (
    .CI(\blk00000001/sig0000006c ),
    .LI(\blk00000001/sig0000007b ),
    .O(\blk00000001/sig00000193 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000bf  (
    .I0(\blk00000001/sig0000015a ),
    .I1(\blk00000001/sig0000016e ),
    .O(\blk00000001/sig0000007c )
  );
  MUXCY   \blk00000001/blk000000be  (
    .CI(\blk00000001/sig0000006d ),
    .DI(\blk00000001/sig0000015a ),
    .S(\blk00000001/sig0000007c ),
    .O(\blk00000001/sig0000006e )
  );
  XORCY   \blk00000001/blk000000bd  (
    .CI(\blk00000001/sig0000006d ),
    .LI(\blk00000001/sig0000007c ),
    .O(\blk00000001/sig00000194 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000bc  (
    .I0(\blk00000001/sig0000015a ),
    .I1(\blk00000001/sig0000016f ),
    .O(\blk00000001/sig0000007d )
  );
  MUXCY   \blk00000001/blk000000bb  (
    .CI(\blk00000001/sig0000006e ),
    .DI(\blk00000001/sig0000015a ),
    .S(\blk00000001/sig0000007d ),
    .O(\blk00000001/sig0000006f )
  );
  XORCY   \blk00000001/blk000000ba  (
    .CI(\blk00000001/sig0000006e ),
    .LI(\blk00000001/sig0000007d ),
    .O(\blk00000001/sig00000195 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b9  (
    .I0(\blk00000001/sig0000015a ),
    .I1(\blk00000001/sig00000164 ),
    .O(\blk00000001/sig00000071 )
  );
  MUXCY   \blk00000001/blk000000b8  (
    .CI(\blk00000001/sig0000006f ),
    .DI(\blk00000001/sig0000015a ),
    .S(\blk00000001/sig00000071 ),
    .O(\blk00000001/sig00000064 )
  );
  XORCY   \blk00000001/blk000000b7  (
    .CI(\blk00000001/sig0000006f ),
    .LI(\blk00000001/sig00000071 ),
    .O(\blk00000001/sig00000189 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b6  (
    .I0(\blk00000001/sig0000015a ),
    .I1(\blk00000001/sig00000165 ),
    .O(\blk00000001/sig00000072 )
  );
  MUXCY   \blk00000001/blk000000b5  (
    .CI(\blk00000001/sig00000064 ),
    .DI(\blk00000001/sig0000015a ),
    .S(\blk00000001/sig00000072 ),
    .O(\blk00000001/sig00000065 )
  );
  XORCY   \blk00000001/blk000000b4  (
    .CI(\blk00000001/sig00000064 ),
    .LI(\blk00000001/sig00000072 ),
    .O(\blk00000001/sig0000018a )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b3  (
    .I0(\blk00000001/sig0000015a ),
    .I1(\blk00000001/sig00000166 ),
    .O(\blk00000001/sig00000073 )
  );
  MUXCY   \blk00000001/blk000000b2  (
    .CI(\blk00000001/sig00000065 ),
    .DI(\blk00000001/sig0000015a ),
    .S(\blk00000001/sig00000073 ),
    .O(\blk00000001/sig00000066 )
  );
  XORCY   \blk00000001/blk000000b1  (
    .CI(\blk00000001/sig00000065 ),
    .LI(\blk00000001/sig00000073 ),
    .O(\blk00000001/sig0000018b )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b0  (
    .I0(\blk00000001/sig0000015a ),
    .I1(\blk00000001/sig00000167 ),
    .O(\blk00000001/sig00000074 )
  );
  XORCY   \blk00000001/blk000000af  (
    .CI(\blk00000001/sig00000066 ),
    .LI(\blk00000001/sig00000074 ),
    .O(\blk00000001/sig0000018c )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ae  (
    .I0(\blk00000001/sig00000120 ),
    .I1(\blk00000001/sig00000132 ),
    .O(\blk00000001/sig0000004b )
  );
  MUXCY   \blk00000001/blk000000ad  (
    .CI(\blk00000001/sig00000032 ),
    .DI(\blk00000001/sig00000120 ),
    .S(\blk00000001/sig0000004b ),
    .O(\blk00000001/sig00000034 )
  );
  XORCY   \blk00000001/blk000000ac  (
    .CI(\blk00000001/sig00000032 ),
    .LI(\blk00000001/sig0000004b ),
    .O(\blk00000001/sig00000170 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ab  (
    .I0(\blk00000001/sig00000121 ),
    .I1(\blk00000001/sig00000133 ),
    .O(\blk00000001/sig00000056 )
  );
  MUXCY   \blk00000001/blk000000aa  (
    .CI(\blk00000001/sig00000034 ),
    .DI(\blk00000001/sig00000121 ),
    .S(\blk00000001/sig00000056 ),
    .O(\blk00000001/sig0000003f )
  );
  XORCY   \blk00000001/blk000000a9  (
    .CI(\blk00000001/sig00000034 ),
    .LI(\blk00000001/sig00000056 ),
    .O(\blk00000001/sig0000017b )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a8  (
    .I0(\blk00000001/sig00000122 ),
    .I1(\blk00000001/sig0000013e ),
    .O(\blk00000001/sig0000005b )
  );
  MUXCY   \blk00000001/blk000000a7  (
    .CI(\blk00000001/sig0000003f ),
    .DI(\blk00000001/sig00000122 ),
    .S(\blk00000001/sig0000005b ),
    .O(\blk00000001/sig00000043 )
  );
  XORCY   \blk00000001/blk000000a6  (
    .CI(\blk00000001/sig0000003f ),
    .LI(\blk00000001/sig0000005b ),
    .O(\blk00000001/sig00000180 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a5  (
    .I0(\blk00000001/sig00000123 ),
    .I1(\blk00000001/sig00000143 ),
    .O(\blk00000001/sig0000005c )
  );
  MUXCY   \blk00000001/blk000000a4  (
    .CI(\blk00000001/sig00000043 ),
    .DI(\blk00000001/sig00000123 ),
    .S(\blk00000001/sig0000005c ),
    .O(\blk00000001/sig00000044 )
  );
  XORCY   \blk00000001/blk000000a3  (
    .CI(\blk00000001/sig00000043 ),
    .LI(\blk00000001/sig0000005c ),
    .O(\blk00000001/sig00000181 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a2  (
    .I0(\blk00000001/sig00000124 ),
    .I1(\blk00000001/sig00000144 ),
    .O(\blk00000001/sig0000005d )
  );
  MUXCY   \blk00000001/blk000000a1  (
    .CI(\blk00000001/sig00000044 ),
    .DI(\blk00000001/sig00000124 ),
    .S(\blk00000001/sig0000005d ),
    .O(\blk00000001/sig00000045 )
  );
  XORCY   \blk00000001/blk000000a0  (
    .CI(\blk00000001/sig00000044 ),
    .LI(\blk00000001/sig0000005d ),
    .O(\blk00000001/sig00000182 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009f  (
    .I0(\blk00000001/sig00000125 ),
    .I1(\blk00000001/sig00000145 ),
    .O(\blk00000001/sig0000005e )
  );
  MUXCY   \blk00000001/blk0000009e  (
    .CI(\blk00000001/sig00000045 ),
    .DI(\blk00000001/sig00000125 ),
    .S(\blk00000001/sig0000005e ),
    .O(\blk00000001/sig00000046 )
  );
  XORCY   \blk00000001/blk0000009d  (
    .CI(\blk00000001/sig00000045 ),
    .LI(\blk00000001/sig0000005e ),
    .O(\blk00000001/sig00000183 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009c  (
    .I0(\blk00000001/sig00000126 ),
    .I1(\blk00000001/sig00000146 ),
    .O(\blk00000001/sig0000005f )
  );
  MUXCY   \blk00000001/blk0000009b  (
    .CI(\blk00000001/sig00000046 ),
    .DI(\blk00000001/sig00000126 ),
    .S(\blk00000001/sig0000005f ),
    .O(\blk00000001/sig00000047 )
  );
  XORCY   \blk00000001/blk0000009a  (
    .CI(\blk00000001/sig00000046 ),
    .LI(\blk00000001/sig0000005f ),
    .O(\blk00000001/sig00000184 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000099  (
    .I0(\blk00000001/sig00000127 ),
    .I1(\blk00000001/sig00000147 ),
    .O(\blk00000001/sig00000060 )
  );
  MUXCY   \blk00000001/blk00000098  (
    .CI(\blk00000001/sig00000047 ),
    .DI(\blk00000001/sig00000127 ),
    .S(\blk00000001/sig00000060 ),
    .O(\blk00000001/sig00000048 )
  );
  XORCY   \blk00000001/blk00000097  (
    .CI(\blk00000001/sig00000047 ),
    .LI(\blk00000001/sig00000060 ),
    .O(\blk00000001/sig00000185 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000096  (
    .I0(\blk00000001/sig00000128 ),
    .I1(\blk00000001/sig00000148 ),
    .O(\blk00000001/sig00000061 )
  );
  MUXCY   \blk00000001/blk00000095  (
    .CI(\blk00000001/sig00000048 ),
    .DI(\blk00000001/sig00000128 ),
    .S(\blk00000001/sig00000061 ),
    .O(\blk00000001/sig00000049 )
  );
  XORCY   \blk00000001/blk00000094  (
    .CI(\blk00000001/sig00000048 ),
    .LI(\blk00000001/sig00000061 ),
    .O(\blk00000001/sig00000186 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000093  (
    .I0(\blk00000001/sig00000129 ),
    .I1(\blk00000001/sig00000149 ),
    .O(\blk00000001/sig00000062 )
  );
  MUXCY   \blk00000001/blk00000092  (
    .CI(\blk00000001/sig00000049 ),
    .DI(\blk00000001/sig00000129 ),
    .S(\blk00000001/sig00000062 ),
    .O(\blk00000001/sig0000004a )
  );
  XORCY   \blk00000001/blk00000091  (
    .CI(\blk00000001/sig00000049 ),
    .LI(\blk00000001/sig00000062 ),
    .O(\blk00000001/sig00000187 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000090  (
    .I0(\blk00000001/sig0000012a ),
    .I1(\blk00000001/sig00000134 ),
    .O(\blk00000001/sig0000004c )
  );
  MUXCY   \blk00000001/blk0000008f  (
    .CI(\blk00000001/sig0000004a ),
    .DI(\blk00000001/sig0000012a ),
    .S(\blk00000001/sig0000004c ),
    .O(\blk00000001/sig00000035 )
  );
  XORCY   \blk00000001/blk0000008e  (
    .CI(\blk00000001/sig0000004a ),
    .LI(\blk00000001/sig0000004c ),
    .O(\blk00000001/sig00000171 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000008d  (
    .I0(\blk00000001/sig0000012b ),
    .I1(\blk00000001/sig00000135 ),
    .O(\blk00000001/sig0000004d )
  );
  MUXCY   \blk00000001/blk0000008c  (
    .CI(\blk00000001/sig00000035 ),
    .DI(\blk00000001/sig0000012b ),
    .S(\blk00000001/sig0000004d ),
    .O(\blk00000001/sig00000036 )
  );
  XORCY   \blk00000001/blk0000008b  (
    .CI(\blk00000001/sig00000035 ),
    .LI(\blk00000001/sig0000004d ),
    .O(\blk00000001/sig00000172 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000008a  (
    .I0(\blk00000001/sig0000012c ),
    .I1(\blk00000001/sig00000136 ),
    .O(\blk00000001/sig0000004e )
  );
  MUXCY   \blk00000001/blk00000089  (
    .CI(\blk00000001/sig00000036 ),
    .DI(\blk00000001/sig0000012c ),
    .S(\blk00000001/sig0000004e ),
    .O(\blk00000001/sig00000037 )
  );
  XORCY   \blk00000001/blk00000088  (
    .CI(\blk00000001/sig00000036 ),
    .LI(\blk00000001/sig0000004e ),
    .O(\blk00000001/sig00000173 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000087  (
    .I0(\blk00000001/sig0000012d ),
    .I1(\blk00000001/sig00000137 ),
    .O(\blk00000001/sig0000004f )
  );
  MUXCY   \blk00000001/blk00000086  (
    .CI(\blk00000001/sig00000037 ),
    .DI(\blk00000001/sig0000012d ),
    .S(\blk00000001/sig0000004f ),
    .O(\blk00000001/sig00000038 )
  );
  XORCY   \blk00000001/blk00000085  (
    .CI(\blk00000001/sig00000037 ),
    .LI(\blk00000001/sig0000004f ),
    .O(\blk00000001/sig00000174 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000084  (
    .I0(\blk00000001/sig0000012e ),
    .I1(\blk00000001/sig00000138 ),
    .O(\blk00000001/sig00000050 )
  );
  MUXCY   \blk00000001/blk00000083  (
    .CI(\blk00000001/sig00000038 ),
    .DI(\blk00000001/sig0000012e ),
    .S(\blk00000001/sig00000050 ),
    .O(\blk00000001/sig00000039 )
  );
  XORCY   \blk00000001/blk00000082  (
    .CI(\blk00000001/sig00000038 ),
    .LI(\blk00000001/sig00000050 ),
    .O(\blk00000001/sig00000175 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000081  (
    .I0(\blk00000001/sig0000012f ),
    .I1(\blk00000001/sig00000139 ),
    .O(\blk00000001/sig00000051 )
  );
  MUXCY   \blk00000001/blk00000080  (
    .CI(\blk00000001/sig00000039 ),
    .DI(\blk00000001/sig0000012f ),
    .S(\blk00000001/sig00000051 ),
    .O(\blk00000001/sig0000003a )
  );
  XORCY   \blk00000001/blk0000007f  (
    .CI(\blk00000001/sig00000039 ),
    .LI(\blk00000001/sig00000051 ),
    .O(\blk00000001/sig00000176 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000007e  (
    .I0(\blk00000001/sig00000130 ),
    .I1(\blk00000001/sig0000013a ),
    .O(\blk00000001/sig00000052 )
  );
  MUXCY   \blk00000001/blk0000007d  (
    .CI(\blk00000001/sig0000003a ),
    .DI(\blk00000001/sig00000130 ),
    .S(\blk00000001/sig00000052 ),
    .O(\blk00000001/sig0000003b )
  );
  XORCY   \blk00000001/blk0000007c  (
    .CI(\blk00000001/sig0000003a ),
    .LI(\blk00000001/sig00000052 ),
    .O(\blk00000001/sig00000177 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000007b  (
    .I0(\blk00000001/sig00000131 ),
    .I1(\blk00000001/sig0000013b ),
    .O(\blk00000001/sig00000053 )
  );
  MUXCY   \blk00000001/blk0000007a  (
    .CI(\blk00000001/sig0000003b ),
    .DI(\blk00000001/sig00000131 ),
    .S(\blk00000001/sig00000053 ),
    .O(\blk00000001/sig0000003c )
  );
  XORCY   \blk00000001/blk00000079  (
    .CI(\blk00000001/sig0000003b ),
    .LI(\blk00000001/sig00000053 ),
    .O(\blk00000001/sig00000178 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000078  (
    .I0(\blk00000001/sig00000131 ),
    .I1(\blk00000001/sig0000013c ),
    .O(\blk00000001/sig00000054 )
  );
  MUXCY   \blk00000001/blk00000077  (
    .CI(\blk00000001/sig0000003c ),
    .DI(\blk00000001/sig00000131 ),
    .S(\blk00000001/sig00000054 ),
    .O(\blk00000001/sig0000003d )
  );
  XORCY   \blk00000001/blk00000076  (
    .CI(\blk00000001/sig0000003c ),
    .LI(\blk00000001/sig00000054 ),
    .O(\blk00000001/sig00000179 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000075  (
    .I0(\blk00000001/sig00000131 ),
    .I1(\blk00000001/sig0000013d ),
    .O(\blk00000001/sig00000055 )
  );
  MUXCY   \blk00000001/blk00000074  (
    .CI(\blk00000001/sig0000003d ),
    .DI(\blk00000001/sig00000131 ),
    .S(\blk00000001/sig00000055 ),
    .O(\blk00000001/sig0000003e )
  );
  XORCY   \blk00000001/blk00000073  (
    .CI(\blk00000001/sig0000003d ),
    .LI(\blk00000001/sig00000055 ),
    .O(\blk00000001/sig0000017a )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000072  (
    .I0(\blk00000001/sig00000131 ),
    .I1(\blk00000001/sig0000013f ),
    .O(\blk00000001/sig00000057 )
  );
  MUXCY   \blk00000001/blk00000071  (
    .CI(\blk00000001/sig0000003e ),
    .DI(\blk00000001/sig00000131 ),
    .S(\blk00000001/sig00000057 ),
    .O(\blk00000001/sig00000040 )
  );
  XORCY   \blk00000001/blk00000070  (
    .CI(\blk00000001/sig0000003e ),
    .LI(\blk00000001/sig00000057 ),
    .O(\blk00000001/sig0000017c )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000006f  (
    .I0(\blk00000001/sig00000131 ),
    .I1(\blk00000001/sig00000140 ),
    .O(\blk00000001/sig00000058 )
  );
  MUXCY   \blk00000001/blk0000006e  (
    .CI(\blk00000001/sig00000040 ),
    .DI(\blk00000001/sig00000131 ),
    .S(\blk00000001/sig00000058 ),
    .O(\blk00000001/sig00000041 )
  );
  XORCY   \blk00000001/blk0000006d  (
    .CI(\blk00000001/sig00000040 ),
    .LI(\blk00000001/sig00000058 ),
    .O(\blk00000001/sig0000017d )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000006c  (
    .I0(\blk00000001/sig00000131 ),
    .I1(\blk00000001/sig00000141 ),
    .O(\blk00000001/sig00000059 )
  );
  MUXCY   \blk00000001/blk0000006b  (
    .CI(\blk00000001/sig00000041 ),
    .DI(\blk00000001/sig00000131 ),
    .S(\blk00000001/sig00000059 ),
    .O(\blk00000001/sig00000042 )
  );
  XORCY   \blk00000001/blk0000006a  (
    .CI(\blk00000001/sig00000041 ),
    .LI(\blk00000001/sig00000059 ),
    .O(\blk00000001/sig0000017e )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000069  (
    .I0(\blk00000001/sig00000131 ),
    .I1(\blk00000001/sig00000142 ),
    .O(\blk00000001/sig0000005a )
  );
  XORCY   \blk00000001/blk00000068  (
    .CI(\blk00000001/sig00000042 ),
    .LI(\blk00000001/sig0000005a ),
    .O(\blk00000001/sig0000017f )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000067  (
    .I0(\blk00000001/sig00000170 ),
    .I1(\blk00000001/sig0000014a ),
    .O(\blk00000001/sig0000009e )
  );
  MUXCY   \blk00000001/blk00000066  (
    .CI(\blk00000001/sig00000032 ),
    .DI(\blk00000001/sig00000170 ),
    .S(\blk00000001/sig0000009e ),
    .O(\blk00000001/sig0000007e )
  );
  XORCY   \blk00000001/blk00000065  (
    .CI(\blk00000001/sig00000032 ),
    .LI(\blk00000001/sig0000009e ),
    .O(p[17])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000064  (
    .I0(\blk00000001/sig0000017b ),
    .I1(\blk00000001/sig0000014b ),
    .O(\blk00000001/sig000000a9 )
  );
  MUXCY   \blk00000001/blk00000063  (
    .CI(\blk00000001/sig0000007e ),
    .DI(\blk00000001/sig0000017b ),
    .S(\blk00000001/sig000000a9 ),
    .O(\blk00000001/sig00000089 )
  );
  XORCY   \blk00000001/blk00000062  (
    .CI(\blk00000001/sig0000007e ),
    .LI(\blk00000001/sig000000a9 ),
    .O(p[18])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000061  (
    .I0(\blk00000001/sig00000180 ),
    .I1(\blk00000001/sig00000156 ),
    .O(\blk00000001/sig000000b4 )
  );
  MUXCY   \blk00000001/blk00000060  (
    .CI(\blk00000001/sig00000089 ),
    .DI(\blk00000001/sig00000180 ),
    .S(\blk00000001/sig000000b4 ),
    .O(\blk00000001/sig00000094 )
  );
  XORCY   \blk00000001/blk0000005f  (
    .CI(\blk00000001/sig00000089 ),
    .LI(\blk00000001/sig000000b4 ),
    .O(p[19])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000005e  (
    .I0(\blk00000001/sig00000181 ),
    .I1(\blk00000001/sig0000015b ),
    .O(\blk00000001/sig000000b8 )
  );
  MUXCY   \blk00000001/blk0000005d  (
    .CI(\blk00000001/sig00000094 ),
    .DI(\blk00000001/sig00000181 ),
    .S(\blk00000001/sig000000b8 ),
    .O(\blk00000001/sig00000097 )
  );
  XORCY   \blk00000001/blk0000005c  (
    .CI(\blk00000001/sig00000094 ),
    .LI(\blk00000001/sig000000b8 ),
    .O(p[20])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000005b  (
    .I0(\blk00000001/sig00000182 ),
    .I1(\blk00000001/sig0000015c ),
    .O(\blk00000001/sig000000b9 )
  );
  MUXCY   \blk00000001/blk0000005a  (
    .CI(\blk00000001/sig00000097 ),
    .DI(\blk00000001/sig00000182 ),
    .S(\blk00000001/sig000000b9 ),
    .O(\blk00000001/sig00000098 )
  );
  XORCY   \blk00000001/blk00000059  (
    .CI(\blk00000001/sig00000097 ),
    .LI(\blk00000001/sig000000b9 ),
    .O(p[21])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000058  (
    .I0(\blk00000001/sig00000183 ),
    .I1(\blk00000001/sig0000015d ),
    .O(\blk00000001/sig000000ba )
  );
  MUXCY   \blk00000001/blk00000057  (
    .CI(\blk00000001/sig00000098 ),
    .DI(\blk00000001/sig00000183 ),
    .S(\blk00000001/sig000000ba ),
    .O(\blk00000001/sig00000099 )
  );
  XORCY   \blk00000001/blk00000056  (
    .CI(\blk00000001/sig00000098 ),
    .LI(\blk00000001/sig000000ba ),
    .O(p[22])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000055  (
    .I0(\blk00000001/sig00000184 ),
    .I1(\blk00000001/sig0000015e ),
    .O(\blk00000001/sig000000bb )
  );
  MUXCY   \blk00000001/blk00000054  (
    .CI(\blk00000001/sig00000099 ),
    .DI(\blk00000001/sig00000184 ),
    .S(\blk00000001/sig000000bb ),
    .O(\blk00000001/sig0000009a )
  );
  XORCY   \blk00000001/blk00000053  (
    .CI(\blk00000001/sig00000099 ),
    .LI(\blk00000001/sig000000bb ),
    .O(p[23])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000052  (
    .I0(\blk00000001/sig00000185 ),
    .I1(\blk00000001/sig0000015f ),
    .O(\blk00000001/sig000000bc )
  );
  MUXCY   \blk00000001/blk00000051  (
    .CI(\blk00000001/sig0000009a ),
    .DI(\blk00000001/sig00000185 ),
    .S(\blk00000001/sig000000bc ),
    .O(\blk00000001/sig0000009b )
  );
  XORCY   \blk00000001/blk00000050  (
    .CI(\blk00000001/sig0000009a ),
    .LI(\blk00000001/sig000000bc ),
    .O(p[24])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000004f  (
    .I0(\blk00000001/sig00000186 ),
    .I1(\blk00000001/sig00000160 ),
    .O(\blk00000001/sig000000bd )
  );
  MUXCY   \blk00000001/blk0000004e  (
    .CI(\blk00000001/sig0000009b ),
    .DI(\blk00000001/sig00000186 ),
    .S(\blk00000001/sig000000bd ),
    .O(\blk00000001/sig0000009c )
  );
  XORCY   \blk00000001/blk0000004d  (
    .CI(\blk00000001/sig0000009b ),
    .LI(\blk00000001/sig000000bd ),
    .O(p[25])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000004c  (
    .I0(\blk00000001/sig00000187 ),
    .I1(\blk00000001/sig00000161 ),
    .O(\blk00000001/sig000000be )
  );
  MUXCY   \blk00000001/blk0000004b  (
    .CI(\blk00000001/sig0000009c ),
    .DI(\blk00000001/sig00000187 ),
    .S(\blk00000001/sig000000be ),
    .O(\blk00000001/sig0000009d )
  );
  XORCY   \blk00000001/blk0000004a  (
    .CI(\blk00000001/sig0000009c ),
    .LI(\blk00000001/sig000000be ),
    .O(p[26])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000049  (
    .I0(\blk00000001/sig00000171 ),
    .I1(\blk00000001/sig0000014c ),
    .O(\blk00000001/sig0000009f )
  );
  MUXCY   \blk00000001/blk00000048  (
    .CI(\blk00000001/sig0000009d ),
    .DI(\blk00000001/sig00000171 ),
    .S(\blk00000001/sig0000009f ),
    .O(\blk00000001/sig0000007f )
  );
  XORCY   \blk00000001/blk00000047  (
    .CI(\blk00000001/sig0000009d ),
    .LI(\blk00000001/sig0000009f ),
    .O(p[27])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000046  (
    .I0(\blk00000001/sig00000172 ),
    .I1(\blk00000001/sig0000014d ),
    .O(\blk00000001/sig000000a0 )
  );
  MUXCY   \blk00000001/blk00000045  (
    .CI(\blk00000001/sig0000007f ),
    .DI(\blk00000001/sig00000172 ),
    .S(\blk00000001/sig000000a0 ),
    .O(\blk00000001/sig00000080 )
  );
  XORCY   \blk00000001/blk00000044  (
    .CI(\blk00000001/sig0000007f ),
    .LI(\blk00000001/sig000000a0 ),
    .O(p[28])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000043  (
    .I0(\blk00000001/sig00000173 ),
    .I1(\blk00000001/sig0000014e ),
    .O(\blk00000001/sig000000a1 )
  );
  MUXCY   \blk00000001/blk00000042  (
    .CI(\blk00000001/sig00000080 ),
    .DI(\blk00000001/sig00000173 ),
    .S(\blk00000001/sig000000a1 ),
    .O(\blk00000001/sig00000081 )
  );
  XORCY   \blk00000001/blk00000041  (
    .CI(\blk00000001/sig00000080 ),
    .LI(\blk00000001/sig000000a1 ),
    .O(p[29])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000040  (
    .I0(\blk00000001/sig00000174 ),
    .I1(\blk00000001/sig0000014f ),
    .O(\blk00000001/sig000000a2 )
  );
  MUXCY   \blk00000001/blk0000003f  (
    .CI(\blk00000001/sig00000081 ),
    .DI(\blk00000001/sig00000174 ),
    .S(\blk00000001/sig000000a2 ),
    .O(\blk00000001/sig00000082 )
  );
  XORCY   \blk00000001/blk0000003e  (
    .CI(\blk00000001/sig00000081 ),
    .LI(\blk00000001/sig000000a2 ),
    .O(p[30])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000003d  (
    .I0(\blk00000001/sig00000175 ),
    .I1(\blk00000001/sig00000150 ),
    .O(\blk00000001/sig000000a3 )
  );
  MUXCY   \blk00000001/blk0000003c  (
    .CI(\blk00000001/sig00000082 ),
    .DI(\blk00000001/sig00000175 ),
    .S(\blk00000001/sig000000a3 ),
    .O(\blk00000001/sig00000083 )
  );
  XORCY   \blk00000001/blk0000003b  (
    .CI(\blk00000001/sig00000082 ),
    .LI(\blk00000001/sig000000a3 ),
    .O(p[31])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000003a  (
    .I0(\blk00000001/sig00000176 ),
    .I1(\blk00000001/sig00000151 ),
    .O(\blk00000001/sig000000a4 )
  );
  MUXCY   \blk00000001/blk00000039  (
    .CI(\blk00000001/sig00000083 ),
    .DI(\blk00000001/sig00000176 ),
    .S(\blk00000001/sig000000a4 ),
    .O(\blk00000001/sig00000084 )
  );
  XORCY   \blk00000001/blk00000038  (
    .CI(\blk00000001/sig00000083 ),
    .LI(\blk00000001/sig000000a4 ),
    .O(p[32])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000037  (
    .I0(\blk00000001/sig00000177 ),
    .I1(\blk00000001/sig00000152 ),
    .O(\blk00000001/sig000000a5 )
  );
  MUXCY   \blk00000001/blk00000036  (
    .CI(\blk00000001/sig00000084 ),
    .DI(\blk00000001/sig00000177 ),
    .S(\blk00000001/sig000000a5 ),
    .O(\blk00000001/sig00000085 )
  );
  XORCY   \blk00000001/blk00000035  (
    .CI(\blk00000001/sig00000084 ),
    .LI(\blk00000001/sig000000a5 ),
    .O(p[33])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000034  (
    .I0(\blk00000001/sig00000178 ),
    .I1(\blk00000001/sig00000188 ),
    .O(\blk00000001/sig000000a6 )
  );
  MUXCY   \blk00000001/blk00000033  (
    .CI(\blk00000001/sig00000085 ),
    .DI(\blk00000001/sig00000178 ),
    .S(\blk00000001/sig000000a6 ),
    .O(\blk00000001/sig00000086 )
  );
  XORCY   \blk00000001/blk00000032  (
    .CI(\blk00000001/sig00000085 ),
    .LI(\blk00000001/sig000000a6 ),
    .O(p[34])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000031  (
    .I0(\blk00000001/sig00000179 ),
    .I1(\blk00000001/sig0000018d ),
    .O(\blk00000001/sig000000a7 )
  );
  MUXCY   \blk00000001/blk00000030  (
    .CI(\blk00000001/sig00000086 ),
    .DI(\blk00000001/sig00000179 ),
    .S(\blk00000001/sig000000a7 ),
    .O(\blk00000001/sig00000087 )
  );
  XORCY   \blk00000001/blk0000002f  (
    .CI(\blk00000001/sig00000086 ),
    .LI(\blk00000001/sig000000a7 ),
    .O(p[35])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000002e  (
    .I0(\blk00000001/sig0000017a ),
    .I1(\blk00000001/sig0000018e ),
    .O(\blk00000001/sig000000a8 )
  );
  MUXCY   \blk00000001/blk0000002d  (
    .CI(\blk00000001/sig00000087 ),
    .DI(\blk00000001/sig0000017a ),
    .S(\blk00000001/sig000000a8 ),
    .O(\blk00000001/sig00000088 )
  );
  XORCY   \blk00000001/blk0000002c  (
    .CI(\blk00000001/sig00000087 ),
    .LI(\blk00000001/sig000000a8 ),
    .O(p[36])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000002b  (
    .I0(\blk00000001/sig0000017c ),
    .I1(\blk00000001/sig0000018f ),
    .O(\blk00000001/sig000000aa )
  );
  MUXCY   \blk00000001/blk0000002a  (
    .CI(\blk00000001/sig00000088 ),
    .DI(\blk00000001/sig0000017c ),
    .S(\blk00000001/sig000000aa ),
    .O(\blk00000001/sig0000008a )
  );
  XORCY   \blk00000001/blk00000029  (
    .CI(\blk00000001/sig00000088 ),
    .LI(\blk00000001/sig000000aa ),
    .O(p[37])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000028  (
    .I0(\blk00000001/sig0000017d ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig000000ab )
  );
  MUXCY   \blk00000001/blk00000027  (
    .CI(\blk00000001/sig0000008a ),
    .DI(\blk00000001/sig0000017d ),
    .S(\blk00000001/sig000000ab ),
    .O(\blk00000001/sig0000008b )
  );
  XORCY   \blk00000001/blk00000026  (
    .CI(\blk00000001/sig0000008a ),
    .LI(\blk00000001/sig000000ab ),
    .O(p[38])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000025  (
    .I0(\blk00000001/sig0000017e ),
    .I1(\blk00000001/sig00000191 ),
    .O(\blk00000001/sig000000ac )
  );
  MUXCY   \blk00000001/blk00000024  (
    .CI(\blk00000001/sig0000008b ),
    .DI(\blk00000001/sig0000017e ),
    .S(\blk00000001/sig000000ac ),
    .O(\blk00000001/sig0000008c )
  );
  XORCY   \blk00000001/blk00000023  (
    .CI(\blk00000001/sig0000008b ),
    .LI(\blk00000001/sig000000ac ),
    .O(p[39])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000022  (
    .I0(\blk00000001/sig0000017f ),
    .I1(\blk00000001/sig00000192 ),
    .O(\blk00000001/sig000000ad )
  );
  MUXCY   \blk00000001/blk00000021  (
    .CI(\blk00000001/sig0000008c ),
    .DI(\blk00000001/sig0000017f ),
    .S(\blk00000001/sig000000ad ),
    .O(\blk00000001/sig0000008d )
  );
  XORCY   \blk00000001/blk00000020  (
    .CI(\blk00000001/sig0000008c ),
    .LI(\blk00000001/sig000000ad ),
    .O(p[40])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000001f  (
    .I0(\blk00000001/sig0000017f ),
    .I1(\blk00000001/sig00000193 ),
    .O(\blk00000001/sig000000ae )
  );
  MUXCY   \blk00000001/blk0000001e  (
    .CI(\blk00000001/sig0000008d ),
    .DI(\blk00000001/sig0000017f ),
    .S(\blk00000001/sig000000ae ),
    .O(\blk00000001/sig0000008e )
  );
  XORCY   \blk00000001/blk0000001d  (
    .CI(\blk00000001/sig0000008d ),
    .LI(\blk00000001/sig000000ae ),
    .O(p[41])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000001c  (
    .I0(\blk00000001/sig0000017f ),
    .I1(\blk00000001/sig00000194 ),
    .O(\blk00000001/sig000000af )
  );
  MUXCY   \blk00000001/blk0000001b  (
    .CI(\blk00000001/sig0000008e ),
    .DI(\blk00000001/sig0000017f ),
    .S(\blk00000001/sig000000af ),
    .O(\blk00000001/sig0000008f )
  );
  XORCY   \blk00000001/blk0000001a  (
    .CI(\blk00000001/sig0000008e ),
    .LI(\blk00000001/sig000000af ),
    .O(p[42])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000019  (
    .I0(\blk00000001/sig0000017f ),
    .I1(\blk00000001/sig00000195 ),
    .O(\blk00000001/sig000000b0 )
  );
  MUXCY   \blk00000001/blk00000018  (
    .CI(\blk00000001/sig0000008f ),
    .DI(\blk00000001/sig0000017f ),
    .S(\blk00000001/sig000000b0 ),
    .O(\blk00000001/sig00000090 )
  );
  XORCY   \blk00000001/blk00000017  (
    .CI(\blk00000001/sig0000008f ),
    .LI(\blk00000001/sig000000b0 ),
    .O(p[43])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000016  (
    .I0(\blk00000001/sig0000017f ),
    .I1(\blk00000001/sig00000189 ),
    .O(\blk00000001/sig000000b1 )
  );
  MUXCY   \blk00000001/blk00000015  (
    .CI(\blk00000001/sig00000090 ),
    .DI(\blk00000001/sig0000017f ),
    .S(\blk00000001/sig000000b1 ),
    .O(\blk00000001/sig00000091 )
  );
  XORCY   \blk00000001/blk00000014  (
    .CI(\blk00000001/sig00000090 ),
    .LI(\blk00000001/sig000000b1 ),
    .O(p[44])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000013  (
    .I0(\blk00000001/sig0000017f ),
    .I1(\blk00000001/sig0000018a ),
    .O(\blk00000001/sig000000b2 )
  );
  MUXCY   \blk00000001/blk00000012  (
    .CI(\blk00000001/sig00000091 ),
    .DI(\blk00000001/sig0000017f ),
    .S(\blk00000001/sig000000b2 ),
    .O(\blk00000001/sig00000092 )
  );
  XORCY   \blk00000001/blk00000011  (
    .CI(\blk00000001/sig00000091 ),
    .LI(\blk00000001/sig000000b2 ),
    .O(p[45])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000010  (
    .I0(\blk00000001/sig0000017f ),
    .I1(\blk00000001/sig0000018b ),
    .O(\blk00000001/sig000000b3 )
  );
  MUXCY   \blk00000001/blk0000000f  (
    .CI(\blk00000001/sig00000092 ),
    .DI(\blk00000001/sig0000017f ),
    .S(\blk00000001/sig000000b3 ),
    .O(\blk00000001/sig00000093 )
  );
  XORCY   \blk00000001/blk0000000e  (
    .CI(\blk00000001/sig00000092 ),
    .LI(\blk00000001/sig000000b3 ),
    .O(p[46])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000000d  (
    .I0(\blk00000001/sig0000017f ),
    .I1(\blk00000001/sig0000018c ),
    .O(\blk00000001/sig000000b5 )
  );
  MUXCY   \blk00000001/blk0000000c  (
    .CI(\blk00000001/sig00000093 ),
    .DI(\blk00000001/sig0000017f ),
    .S(\blk00000001/sig000000b5 ),
    .O(\blk00000001/sig00000095 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000000b  (
    .I0(\blk00000001/sig0000017f ),
    .I1(\blk00000001/sig0000018c ),
    .O(\blk00000001/sig000000b6 )
  );
  MUXCY   \blk00000001/blk0000000a  (
    .CI(\blk00000001/sig00000095 ),
    .DI(\blk00000001/sig0000017f ),
    .S(\blk00000001/sig000000b6 ),
    .O(\blk00000001/sig00000096 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000009  (
    .I0(\blk00000001/sig0000017f ),
    .I1(\blk00000001/sig0000018c ),
    .O(\blk00000001/sig000000b7 )
  );
  XORCY   \blk00000001/blk00000008  (
    .CI(\blk00000001/sig00000096 ),
    .LI(\blk00000001/sig000000b7 ),
    .O(p[47])
  );
  MULT18X18S   \blk00000001/blk00000007  (
    .C(clk),
    .CE(\blk00000001/sig00000033 ),
    .R(\blk00000001/sig00000032 ),
    .A({\blk00000001/sig00000032 , a[16], a[15], a[14], a[13], a[12], a[11], a[10], a[9], a[8], a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0]}),
    .B({\blk00000001/sig00000032 , b[16], b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4], b[3], b[2], b[1], b[0]}),
    .P({\NLW_blk00000001/blk00000007_P<35>_UNCONNECTED , \blk00000001/sig000000da , \blk00000001/sig000000d9 , \blk00000001/sig000000d8 , 
\blk00000001/sig000000d7 , \blk00000001/sig000000d6 , \blk00000001/sig000000d4 , \blk00000001/sig000000d3 , \blk00000001/sig000000d2 , 
\blk00000001/sig000000d1 , \blk00000001/sig000000d0 , \blk00000001/sig000000cf , \blk00000001/sig000000ce , \blk00000001/sig000000cd , 
\blk00000001/sig000000cc , \blk00000001/sig000000cb , \blk00000001/sig000000c9 , \blk00000001/sig000000c8 , \blk00000001/sig000000c7 , 
\blk00000001/sig000000c6 , \blk00000001/sig000000c5 , \blk00000001/sig000000c4 , \blk00000001/sig000000c3 , \blk00000001/sig000000c2 , 
\blk00000001/sig000000c1 , \blk00000001/sig000000c0 , \blk00000001/sig000000e1 , \blk00000001/sig000000e0 , \blk00000001/sig000000df , 
\blk00000001/sig000000de , \blk00000001/sig000000dd , \blk00000001/sig000000dc , \blk00000001/sig000000db , \blk00000001/sig000000d5 , 
\blk00000001/sig000000ca , \blk00000001/sig000000bf })
  );
  MULT18X18S   \blk00000001/blk00000006  (
    .C(clk),
    .CE(\blk00000001/sig00000033 ),
    .R(\blk00000001/sig00000032 ),
    .A({\blk00000001/sig00000032 , a[16], a[15], a[14], a[13], a[12], a[11], a[10], a[9], a[8], a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0]}),
    .B({b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[22], b[21], b[20], b[19], b[18], b[17]}),
    .P({\NLW_blk00000001/blk00000006_P<35>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<34>_UNCONNECTED , 
\NLW_blk00000001/blk00000006_P<33>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<32>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<31>_UNCONNECTED , 
\NLW_blk00000001/blk00000006_P<30>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<29>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<28>_UNCONNECTED , 
\NLW_blk00000001/blk00000006_P<27>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<26>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<25>_UNCONNECTED , 
\NLW_blk00000001/blk00000006_P<24>_UNCONNECTED , \blk00000001/sig000000f1 , \blk00000001/sig000000f0 , \blk00000001/sig000000ef , 
\blk00000001/sig000000ee , \blk00000001/sig000000ec , \blk00000001/sig000000eb , \blk00000001/sig000000ea , \blk00000001/sig000000e9 , 
\blk00000001/sig000000e8 , \blk00000001/sig000000e7 , \blk00000001/sig000000e6 , \blk00000001/sig000000e5 , \blk00000001/sig000000e4 , 
\blk00000001/sig000000e3 , \blk00000001/sig000000f9 , \blk00000001/sig000000f8 , \blk00000001/sig000000f7 , \blk00000001/sig000000f6 , 
\blk00000001/sig000000f5 , \blk00000001/sig000000f4 , \blk00000001/sig000000f3 , \blk00000001/sig000000f2 , \blk00000001/sig000000ed , 
\blk00000001/sig000000e2 })
  );
  MULT18X18S   \blk00000001/blk00000005  (
    .C(clk),
    .CE(\blk00000001/sig00000033 ),
    .R(\blk00000001/sig00000032 ),
    .A({a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[22], a[21], a[20], a[19], a[18], a[17]}),
    .B({\blk00000001/sig00000032 , b[16], b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4], b[3], b[2], b[1], b[0]}),
    .P({\NLW_blk00000001/blk00000005_P<35>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<34>_UNCONNECTED , 
\NLW_blk00000001/blk00000005_P<33>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<32>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<31>_UNCONNECTED , 
\NLW_blk00000001/blk00000005_P<30>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<29>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<28>_UNCONNECTED , 
\NLW_blk00000001/blk00000005_P<27>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<26>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<25>_UNCONNECTED , 
\NLW_blk00000001/blk00000005_P<24>_UNCONNECTED , \blk00000001/sig00000109 , \blk00000001/sig00000108 , \blk00000001/sig00000107 , 
\blk00000001/sig00000106 , \blk00000001/sig00000104 , \blk00000001/sig00000103 , \blk00000001/sig00000102 , \blk00000001/sig00000101 , 
\blk00000001/sig00000100 , \blk00000001/sig000000ff , \blk00000001/sig000000fe , \blk00000001/sig000000fd , \blk00000001/sig000000fc , 
\blk00000001/sig000000fb , \blk00000001/sig00000111 , \blk00000001/sig00000110 , \blk00000001/sig0000010f , \blk00000001/sig0000010e , 
\blk00000001/sig0000010d , \blk00000001/sig0000010c , \blk00000001/sig0000010b , \blk00000001/sig0000010a , \blk00000001/sig00000105 , 
\blk00000001/sig000000fa })
  );
  MULT18X18S   \blk00000001/blk00000004  (
    .C(clk),
    .CE(\blk00000001/sig00000033 ),
    .R(\blk00000001/sig00000032 ),
    .A({a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[22], a[21], a[20], a[19], a[18], a[17]}),
    .B({b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[22], b[21], b[20], b[19], b[18], b[17]}),
    .P({\NLW_blk00000001/blk00000004_P<35>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<34>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<33>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<32>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<31>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<30>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<29>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<28>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<27>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<26>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<25>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<24>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<23>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<22>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<21>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<20>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<19>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<18>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<17>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<16>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<15>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<14>_UNCONNECTED , \blk00000001/sig00000116 , \blk00000001/sig00000115 
, \blk00000001/sig00000114 , \blk00000001/sig00000113 , \blk00000001/sig0000011f , \blk00000001/sig0000011e , \blk00000001/sig0000011d , 
\blk00000001/sig0000011c , \blk00000001/sig0000011b , \blk00000001/sig0000011a , \blk00000001/sig00000119 , \blk00000001/sig00000118 , 
\blk00000001/sig00000117 , \blk00000001/sig00000112 })
  );
  VCC   \blk00000001/blk00000003  (
    .P(\blk00000001/sig00000033 )
  );
  GND   \blk00000001/blk00000002  (
    .G(\blk00000001/sig00000032 )
  );

// synthesis translate_on

endmodule

// synthesis translate_off

`ifndef GLBL
`define GLBL

`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;

    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (weak1, weak0) GSR = GSR_int;
    assign (weak1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule

`endif

// synthesis translate_on

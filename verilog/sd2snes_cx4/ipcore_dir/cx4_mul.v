////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2013 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: P.20131013
//  \   \         Application: netgen
//  /   /         Filename: cx4_mul.v
// /___/   /\     Timestamp: Mon Sep 15 23:40:29 2014
// \   \  /  \ 
//  \___\/\___\
//             
// Command	: -w -sim -ofmt verilog /home/ikari/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.ngc /home/ikari/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.v 
// Device	: 3s400pq208-4
// Input file	: /home/ikari/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.ngc
// Output file	: /home/ikari/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.v
// # of Modules	: 1
// Design Name	: cx4_mul
// Xilinx        : /home/ikari/Xilinx/14.7/ISE_DS/ISE/
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
  
  wire \blk00000001/sig000001c5 ;
  wire \blk00000001/sig000001c4 ;
  wire \blk00000001/sig000001c3 ;
  wire \blk00000001/sig000001c2 ;
  wire \blk00000001/sig000001c1 ;
  wire \blk00000001/sig000001c0 ;
  wire \blk00000001/sig000001bf ;
  wire \blk00000001/sig000001be ;
  wire \blk00000001/sig000001bd ;
  wire \blk00000001/sig000001bc ;
  wire \blk00000001/sig000001bb ;
  wire \blk00000001/sig000001ba ;
  wire \blk00000001/sig000001b9 ;
  wire \blk00000001/sig000001b8 ;
  wire \blk00000001/sig000001b7 ;
  wire \blk00000001/sig000001b6 ;
  wire \blk00000001/sig000001b5 ;
  wire \blk00000001/sig000001b4 ;
  wire \blk00000001/sig000001b3 ;
  wire \blk00000001/sig000001b2 ;
  wire \blk00000001/sig000001b1 ;
  wire \blk00000001/sig000001b0 ;
  wire \blk00000001/sig000001af ;
  wire \blk00000001/sig000001ae ;
  wire \blk00000001/sig000001ad ;
  wire \blk00000001/sig000001ac ;
  wire \blk00000001/sig000001ab ;
  wire \blk00000001/sig000001aa ;
  wire \blk00000001/sig000001a9 ;
  wire \blk00000001/sig000001a8 ;
  wire \blk00000001/sig000001a7 ;
  wire \blk00000001/sig000001a6 ;
  wire \blk00000001/sig000001a5 ;
  wire \blk00000001/sig000001a4 ;
  wire \blk00000001/sig000001a3 ;
  wire \blk00000001/sig000001a2 ;
  wire \blk00000001/sig000001a1 ;
  wire \blk00000001/sig000001a0 ;
  wire \blk00000001/sig0000019f ;
  wire \blk00000001/sig0000019e ;
  wire \blk00000001/sig0000019d ;
  wire \blk00000001/sig0000019c ;
  wire \blk00000001/sig0000019b ;
  wire \blk00000001/sig0000019a ;
  wire \blk00000001/sig00000199 ;
  wire \blk00000001/sig00000198 ;
  wire \blk00000001/sig00000197 ;
  wire \blk00000001/sig00000196 ;
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
  \blk00000001/blk00000168  (
    .C(clk),
    .D(\blk00000001/sig00000032 ),
    .Q(p[0])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000167  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000d0 ),
    .Q(\blk00000001/sig00000032 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000166  (
    .C(clk),
    .D(\blk00000001/sig00000033 ),
    .Q(p[1])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000165  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000db ),
    .Q(\blk00000001/sig00000033 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000164  (
    .C(clk),
    .D(\blk00000001/sig0000003b ),
    .Q(p[2])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000163  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000e6 ),
    .Q(\blk00000001/sig0000003b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000162  (
    .C(clk),
    .D(\blk00000001/sig0000003c ),
    .Q(p[3])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000161  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000ec ),
    .Q(\blk00000001/sig0000003c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000160  (
    .C(clk),
    .D(\blk00000001/sig0000003d ),
    .Q(p[4])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000015f  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000ed ),
    .Q(\blk00000001/sig0000003d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000015e  (
    .C(clk),
    .D(\blk00000001/sig0000003e ),
    .Q(p[5])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000015d  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000ee ),
    .Q(\blk00000001/sig0000003e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000015c  (
    .C(clk),
    .D(\blk00000001/sig0000003f ),
    .Q(p[6])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000015b  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000ef ),
    .Q(\blk00000001/sig0000003f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000015a  (
    .C(clk),
    .D(\blk00000001/sig00000040 ),
    .Q(p[7])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000159  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000f0 ),
    .Q(\blk00000001/sig00000040 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000158  (
    .C(clk),
    .D(\blk00000001/sig00000041 ),
    .Q(p[8])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000157  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000f1 ),
    .Q(\blk00000001/sig00000041 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000156  (
    .C(clk),
    .D(\blk00000001/sig00000042 ),
    .Q(p[9])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000155  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000f2 ),
    .Q(\blk00000001/sig00000042 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000154  (
    .C(clk),
    .D(\blk00000001/sig00000034 ),
    .Q(p[10])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000153  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000d1 ),
    .Q(\blk00000001/sig00000034 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000152  (
    .C(clk),
    .D(\blk00000001/sig00000035 ),
    .Q(p[11])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000151  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000d2 ),
    .Q(\blk00000001/sig00000035 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000150  (
    .C(clk),
    .D(\blk00000001/sig00000036 ),
    .Q(p[12])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000014f  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000d3 ),
    .Q(\blk00000001/sig00000036 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000014e  (
    .C(clk),
    .D(\blk00000001/sig00000037 ),
    .Q(p[13])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000014d  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000d4 ),
    .Q(\blk00000001/sig00000037 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000014c  (
    .C(clk),
    .D(\blk00000001/sig00000039 ),
    .Q(p[15])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000014b  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000d6 ),
    .Q(\blk00000001/sig00000039 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000014a  (
    .C(clk),
    .D(\blk00000001/sig0000003a ),
    .Q(p[16])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000149  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000d7 ),
    .Q(\blk00000001/sig0000003a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000148  (
    .C(clk),
    .D(\blk00000001/sig00000038 ),
    .Q(p[14])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000147  (
    .A0(\blk00000001/sig00000043 ),
    .A1(\blk00000001/sig00000043 ),
    .A2(\blk00000001/sig00000043 ),
    .A3(\blk00000001/sig00000043 ),
    .CLK(clk),
    .D(\blk00000001/sig000000d5 ),
    .Q(\blk00000001/sig00000038 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000146  (
    .C(clk),
    .D(\blk00000001/sig000000d8 ),
    .Q(\blk00000001/sig00000131 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000145  (
    .C(clk),
    .D(\blk00000001/sig000000d9 ),
    .Q(\blk00000001/sig00000132 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000144  (
    .C(clk),
    .D(\blk00000001/sig000000da ),
    .Q(\blk00000001/sig00000133 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000143  (
    .C(clk),
    .D(\blk00000001/sig000000dc ),
    .Q(\blk00000001/sig00000134 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000142  (
    .C(clk),
    .D(\blk00000001/sig000000dd ),
    .Q(\blk00000001/sig00000135 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000141  (
    .C(clk),
    .D(\blk00000001/sig000000de ),
    .Q(\blk00000001/sig00000136 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000140  (
    .C(clk),
    .D(\blk00000001/sig000000df ),
    .Q(\blk00000001/sig00000137 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013f  (
    .C(clk),
    .D(\blk00000001/sig000000e0 ),
    .Q(\blk00000001/sig00000138 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013e  (
    .C(clk),
    .D(\blk00000001/sig000000e1 ),
    .Q(\blk00000001/sig00000139 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013d  (
    .C(clk),
    .D(\blk00000001/sig000000e2 ),
    .Q(\blk00000001/sig0000013a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013c  (
    .C(clk),
    .D(\blk00000001/sig000000e3 ),
    .Q(\blk00000001/sig0000013b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013b  (
    .C(clk),
    .D(\blk00000001/sig000000e4 ),
    .Q(\blk00000001/sig0000013c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013a  (
    .C(clk),
    .D(\blk00000001/sig000000e5 ),
    .Q(\blk00000001/sig0000013d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000139  (
    .C(clk),
    .D(\blk00000001/sig000000e7 ),
    .Q(\blk00000001/sig0000013e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000138  (
    .C(clk),
    .D(\blk00000001/sig000000e8 ),
    .Q(\blk00000001/sig0000013f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000137  (
    .C(clk),
    .D(\blk00000001/sig000000e9 ),
    .Q(\blk00000001/sig00000140 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000136  (
    .C(clk),
    .D(\blk00000001/sig000000ea ),
    .Q(\blk00000001/sig00000141 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000135  (
    .C(clk),
    .D(\blk00000001/sig000000eb ),
    .Q(\blk00000001/sig00000142 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000134  (
    .C(clk),
    .D(\blk00000001/sig000000f3 ),
    .Q(\blk00000001/sig00000143 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000133  (
    .C(clk),
    .D(\blk00000001/sig000000fe ),
    .Q(\blk00000001/sig00000144 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000132  (
    .C(clk),
    .D(\blk00000001/sig00000103 ),
    .Q(\blk00000001/sig0000014f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000131  (
    .C(clk),
    .D(\blk00000001/sig00000104 ),
    .Q(\blk00000001/sig00000154 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000130  (
    .C(clk),
    .D(\blk00000001/sig00000105 ),
    .Q(\blk00000001/sig00000155 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012f  (
    .C(clk),
    .D(\blk00000001/sig00000106 ),
    .Q(\blk00000001/sig00000156 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012e  (
    .C(clk),
    .D(\blk00000001/sig00000107 ),
    .Q(\blk00000001/sig00000157 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012d  (
    .C(clk),
    .D(\blk00000001/sig00000108 ),
    .Q(\blk00000001/sig00000158 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012c  (
    .C(clk),
    .D(\blk00000001/sig00000109 ),
    .Q(\blk00000001/sig00000159 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012b  (
    .C(clk),
    .D(\blk00000001/sig0000010a ),
    .Q(\blk00000001/sig0000015a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012a  (
    .C(clk),
    .D(\blk00000001/sig000000f4 ),
    .Q(\blk00000001/sig00000145 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000129  (
    .C(clk),
    .D(\blk00000001/sig000000f5 ),
    .Q(\blk00000001/sig00000146 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000128  (
    .C(clk),
    .D(\blk00000001/sig000000f6 ),
    .Q(\blk00000001/sig00000147 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000127  (
    .C(clk),
    .D(\blk00000001/sig000000f7 ),
    .Q(\blk00000001/sig00000148 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000126  (
    .C(clk),
    .D(\blk00000001/sig000000f8 ),
    .Q(\blk00000001/sig00000149 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000125  (
    .C(clk),
    .D(\blk00000001/sig000000f9 ),
    .Q(\blk00000001/sig0000014a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000124  (
    .C(clk),
    .D(\blk00000001/sig000000fa ),
    .Q(\blk00000001/sig0000014b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000123  (
    .C(clk),
    .D(\blk00000001/sig000000fb ),
    .Q(\blk00000001/sig0000014c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000122  (
    .C(clk),
    .D(\blk00000001/sig000000fc ),
    .Q(\blk00000001/sig0000014d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000121  (
    .C(clk),
    .D(\blk00000001/sig000000fd ),
    .Q(\blk00000001/sig0000014e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000120  (
    .C(clk),
    .D(\blk00000001/sig000000ff ),
    .Q(\blk00000001/sig00000150 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011f  (
    .C(clk),
    .D(\blk00000001/sig00000100 ),
    .Q(\blk00000001/sig00000151 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011e  (
    .C(clk),
    .D(\blk00000001/sig00000101 ),
    .Q(\blk00000001/sig00000152 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011d  (
    .C(clk),
    .D(\blk00000001/sig00000102 ),
    .Q(\blk00000001/sig00000153 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011c  (
    .C(clk),
    .D(\blk00000001/sig0000010b ),
    .Q(\blk00000001/sig0000015b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011b  (
    .C(clk),
    .D(\blk00000001/sig00000116 ),
    .Q(\blk00000001/sig0000015c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011a  (
    .C(clk),
    .D(\blk00000001/sig0000011b ),
    .Q(\blk00000001/sig00000167 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000119  (
    .C(clk),
    .D(\blk00000001/sig0000011c ),
    .Q(\blk00000001/sig0000016c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000118  (
    .C(clk),
    .D(\blk00000001/sig0000011d ),
    .Q(\blk00000001/sig0000016d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000117  (
    .C(clk),
    .D(\blk00000001/sig0000011e ),
    .Q(\blk00000001/sig0000016e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000116  (
    .C(clk),
    .D(\blk00000001/sig0000011f ),
    .Q(\blk00000001/sig0000016f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000115  (
    .C(clk),
    .D(\blk00000001/sig00000120 ),
    .Q(\blk00000001/sig00000170 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000114  (
    .C(clk),
    .D(\blk00000001/sig00000121 ),
    .Q(\blk00000001/sig00000171 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000113  (
    .C(clk),
    .D(\blk00000001/sig00000122 ),
    .Q(\blk00000001/sig00000172 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000112  (
    .C(clk),
    .D(\blk00000001/sig0000010c ),
    .Q(\blk00000001/sig0000015d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000111  (
    .C(clk),
    .D(\blk00000001/sig0000010d ),
    .Q(\blk00000001/sig0000015e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000110  (
    .C(clk),
    .D(\blk00000001/sig0000010e ),
    .Q(\blk00000001/sig0000015f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010f  (
    .C(clk),
    .D(\blk00000001/sig0000010f ),
    .Q(\blk00000001/sig00000160 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010e  (
    .C(clk),
    .D(\blk00000001/sig00000110 ),
    .Q(\blk00000001/sig00000161 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010d  (
    .C(clk),
    .D(\blk00000001/sig00000111 ),
    .Q(\blk00000001/sig00000162 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010c  (
    .C(clk),
    .D(\blk00000001/sig00000112 ),
    .Q(\blk00000001/sig00000163 )
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
    .D(\blk00000001/sig00000117 ),
    .Q(\blk00000001/sig00000168 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000107  (
    .C(clk),
    .D(\blk00000001/sig00000118 ),
    .Q(\blk00000001/sig00000169 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000106  (
    .C(clk),
    .D(\blk00000001/sig00000119 ),
    .Q(\blk00000001/sig0000016a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000105  (
    .C(clk),
    .D(\blk00000001/sig0000011a ),
    .Q(\blk00000001/sig0000016b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000104  (
    .C(clk),
    .D(\blk00000001/sig00000123 ),
    .Q(\blk00000001/sig00000173 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000103  (
    .C(clk),
    .D(\blk00000001/sig00000128 ),
    .Q(\blk00000001/sig00000174 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000102  (
    .C(clk),
    .D(\blk00000001/sig00000129 ),
    .Q(\blk00000001/sig00000179 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000101  (
    .C(clk),
    .D(\blk00000001/sig0000012a ),
    .Q(\blk00000001/sig0000017a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000100  (
    .C(clk),
    .D(\blk00000001/sig0000012b ),
    .Q(\blk00000001/sig0000017b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ff  (
    .C(clk),
    .D(\blk00000001/sig0000012c ),
    .Q(\blk00000001/sig0000017c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fe  (
    .C(clk),
    .D(\blk00000001/sig0000012d ),
    .Q(\blk00000001/sig0000017d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fd  (
    .C(clk),
    .D(\blk00000001/sig0000012e ),
    .Q(\blk00000001/sig0000017e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fc  (
    .C(clk),
    .D(\blk00000001/sig0000012f ),
    .Q(\blk00000001/sig0000017f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fb  (
    .C(clk),
    .D(\blk00000001/sig00000130 ),
    .Q(\blk00000001/sig00000180 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fa  (
    .C(clk),
    .D(\blk00000001/sig00000124 ),
    .Q(\blk00000001/sig00000175 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f9  (
    .C(clk),
    .D(\blk00000001/sig00000125 ),
    .Q(\blk00000001/sig00000176 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f8  (
    .C(clk),
    .D(\blk00000001/sig00000126 ),
    .Q(\blk00000001/sig00000177 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f7  (
    .C(clk),
    .D(\blk00000001/sig00000127 ),
    .Q(\blk00000001/sig00000178 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f6  (
    .C(clk),
    .D(\blk00000001/sig000001a7 ),
    .Q(p[17])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f5  (
    .C(clk),
    .D(\blk00000001/sig000001b2 ),
    .Q(p[18])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f4  (
    .C(clk),
    .D(\blk00000001/sig000001bd ),
    .Q(p[19])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f3  (
    .C(clk),
    .D(\blk00000001/sig000001be ),
    .Q(p[20])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f2  (
    .C(clk),
    .D(\blk00000001/sig000001bf ),
    .Q(p[21])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f1  (
    .C(clk),
    .D(\blk00000001/sig000001c1 ),
    .Q(p[22])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f0  (
    .C(clk),
    .D(\blk00000001/sig000001c2 ),
    .Q(p[23])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ef  (
    .C(clk),
    .D(\blk00000001/sig000001c3 ),
    .Q(p[24])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ee  (
    .C(clk),
    .D(\blk00000001/sig000001c4 ),
    .Q(p[25])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ed  (
    .C(clk),
    .D(\blk00000001/sig000001c5 ),
    .Q(p[26])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ec  (
    .C(clk),
    .D(\blk00000001/sig000001a8 ),
    .Q(p[27])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000eb  (
    .C(clk),
    .D(\blk00000001/sig000001a9 ),
    .Q(p[28])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ea  (
    .C(clk),
    .D(\blk00000001/sig000001aa ),
    .Q(p[29])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e9  (
    .C(clk),
    .D(\blk00000001/sig000001ab ),
    .Q(p[30])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e8  (
    .C(clk),
    .D(\blk00000001/sig000001ac ),
    .Q(p[31])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e7  (
    .C(clk),
    .D(\blk00000001/sig000001ad ),
    .Q(p[32])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e6  (
    .C(clk),
    .D(\blk00000001/sig000001ae ),
    .Q(p[33])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e5  (
    .C(clk),
    .D(\blk00000001/sig000001af ),
    .Q(p[34])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e4  (
    .C(clk),
    .D(\blk00000001/sig000001b0 ),
    .Q(p[35])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e3  (
    .C(clk),
    .D(\blk00000001/sig000001b1 ),
    .Q(p[36])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e2  (
    .C(clk),
    .D(\blk00000001/sig000001b3 ),
    .Q(p[37])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e1  (
    .C(clk),
    .D(\blk00000001/sig000001b4 ),
    .Q(p[38])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000e0  (
    .C(clk),
    .D(\blk00000001/sig000001b5 ),
    .Q(p[39])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000df  (
    .C(clk),
    .D(\blk00000001/sig000001b6 ),
    .Q(p[40])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000de  (
    .C(clk),
    .D(\blk00000001/sig000001b7 ),
    .Q(p[41])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000dd  (
    .C(clk),
    .D(\blk00000001/sig000001b8 ),
    .Q(p[42])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000dc  (
    .C(clk),
    .D(\blk00000001/sig000001b9 ),
    .Q(p[43])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000db  (
    .C(clk),
    .D(\blk00000001/sig000001ba ),
    .Q(p[44])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000da  (
    .C(clk),
    .D(\blk00000001/sig000001bb ),
    .Q(p[45])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000d9  (
    .C(clk),
    .D(\blk00000001/sig000001bc ),
    .Q(p[46])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000d8  (
    .C(clk),
    .D(\blk00000001/sig000001c0 ),
    .Q(p[47])
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000d7  (
    .I0(\blk00000001/sig00000164 ),
    .I1(\blk00000001/sig00000173 ),
    .O(\blk00000001/sig00000081 )
  );
  MUXCY   \blk00000001/blk000000d6  (
    .CI(\blk00000001/sig00000043 ),
    .DI(\blk00000001/sig00000164 ),
    .S(\blk00000001/sig00000081 ),
    .O(\blk00000001/sig00000074 )
  );
  XORCY   \blk00000001/blk000000d5  (
    .CI(\blk00000001/sig00000043 ),
    .LI(\blk00000001/sig00000081 ),
    .O(\blk00000001/sig00000199 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000d4  (
    .I0(\blk00000001/sig00000165 ),
    .I1(\blk00000001/sig00000174 ),
    .O(\blk00000001/sig00000086 )
  );
  MUXCY   \blk00000001/blk000000d3  (
    .CI(\blk00000001/sig00000074 ),
    .DI(\blk00000001/sig00000165 ),
    .S(\blk00000001/sig00000086 ),
    .O(\blk00000001/sig00000078 )
  );
  XORCY   \blk00000001/blk000000d2  (
    .CI(\blk00000001/sig00000074 ),
    .LI(\blk00000001/sig00000086 ),
    .O(\blk00000001/sig0000019e )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000d1  (
    .I0(\blk00000001/sig00000166 ),
    .I1(\blk00000001/sig00000179 ),
    .O(\blk00000001/sig00000087 )
  );
  MUXCY   \blk00000001/blk000000d0  (
    .CI(\blk00000001/sig00000078 ),
    .DI(\blk00000001/sig00000166 ),
    .S(\blk00000001/sig00000087 ),
    .O(\blk00000001/sig00000079 )
  );
  XORCY   \blk00000001/blk000000cf  (
    .CI(\blk00000001/sig00000078 ),
    .LI(\blk00000001/sig00000087 ),
    .O(\blk00000001/sig0000019f )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ce  (
    .I0(\blk00000001/sig00000168 ),
    .I1(\blk00000001/sig0000017a ),
    .O(\blk00000001/sig00000088 )
  );
  MUXCY   \blk00000001/blk000000cd  (
    .CI(\blk00000001/sig00000079 ),
    .DI(\blk00000001/sig00000168 ),
    .S(\blk00000001/sig00000088 ),
    .O(\blk00000001/sig0000007a )
  );
  XORCY   \blk00000001/blk000000cc  (
    .CI(\blk00000001/sig00000079 ),
    .LI(\blk00000001/sig00000088 ),
    .O(\blk00000001/sig000001a0 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000cb  (
    .I0(\blk00000001/sig00000169 ),
    .I1(\blk00000001/sig0000017b ),
    .O(\blk00000001/sig00000089 )
  );
  MUXCY   \blk00000001/blk000000ca  (
    .CI(\blk00000001/sig0000007a ),
    .DI(\blk00000001/sig00000169 ),
    .S(\blk00000001/sig00000089 ),
    .O(\blk00000001/sig0000007b )
  );
  XORCY   \blk00000001/blk000000c9  (
    .CI(\blk00000001/sig0000007a ),
    .LI(\blk00000001/sig00000089 ),
    .O(\blk00000001/sig000001a1 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c8  (
    .I0(\blk00000001/sig0000016a ),
    .I1(\blk00000001/sig0000017c ),
    .O(\blk00000001/sig0000008a )
  );
  MUXCY   \blk00000001/blk000000c7  (
    .CI(\blk00000001/sig0000007b ),
    .DI(\blk00000001/sig0000016a ),
    .S(\blk00000001/sig0000008a ),
    .O(\blk00000001/sig0000007c )
  );
  XORCY   \blk00000001/blk000000c6  (
    .CI(\blk00000001/sig0000007b ),
    .LI(\blk00000001/sig0000008a ),
    .O(\blk00000001/sig000001a2 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c5  (
    .I0(\blk00000001/sig0000017d ),
    .I1(\blk00000001/sig0000016b ),
    .O(\blk00000001/sig0000008b )
  );
  MUXCY   \blk00000001/blk000000c4  (
    .CI(\blk00000001/sig0000007c ),
    .DI(\blk00000001/sig0000016b ),
    .S(\blk00000001/sig0000008b ),
    .O(\blk00000001/sig0000007d )
  );
  XORCY   \blk00000001/blk000000c3  (
    .CI(\blk00000001/sig0000007c ),
    .LI(\blk00000001/sig0000008b ),
    .O(\blk00000001/sig000001a3 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c2  (
    .I0(\blk00000001/sig0000017e ),
    .I1(\blk00000001/sig0000016b ),
    .O(\blk00000001/sig0000008c )
  );
  MUXCY   \blk00000001/blk000000c1  (
    .CI(\blk00000001/sig0000007d ),
    .DI(\blk00000001/sig0000016b ),
    .S(\blk00000001/sig0000008c ),
    .O(\blk00000001/sig0000007e )
  );
  XORCY   \blk00000001/blk000000c0  (
    .CI(\blk00000001/sig0000007d ),
    .LI(\blk00000001/sig0000008c ),
    .O(\blk00000001/sig000001a4 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000bf  (
    .I0(\blk00000001/sig0000017f ),
    .I1(\blk00000001/sig0000016b ),
    .O(\blk00000001/sig0000008d )
  );
  MUXCY   \blk00000001/blk000000be  (
    .CI(\blk00000001/sig0000007e ),
    .DI(\blk00000001/sig0000016b ),
    .S(\blk00000001/sig0000008d ),
    .O(\blk00000001/sig0000007f )
  );
  XORCY   \blk00000001/blk000000bd  (
    .CI(\blk00000001/sig0000007e ),
    .LI(\blk00000001/sig0000008d ),
    .O(\blk00000001/sig000001a5 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000bc  (
    .I0(\blk00000001/sig00000180 ),
    .I1(\blk00000001/sig0000016b ),
    .O(\blk00000001/sig0000008e )
  );
  MUXCY   \blk00000001/blk000000bb  (
    .CI(\blk00000001/sig0000007f ),
    .DI(\blk00000001/sig0000016b ),
    .S(\blk00000001/sig0000008e ),
    .O(\blk00000001/sig00000080 )
  );
  XORCY   \blk00000001/blk000000ba  (
    .CI(\blk00000001/sig0000007f ),
    .LI(\blk00000001/sig0000008e ),
    .O(\blk00000001/sig000001a6 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b9  (
    .I0(\blk00000001/sig00000175 ),
    .I1(\blk00000001/sig0000016b ),
    .O(\blk00000001/sig00000082 )
  );
  MUXCY   \blk00000001/blk000000b8  (
    .CI(\blk00000001/sig00000080 ),
    .DI(\blk00000001/sig0000016b ),
    .S(\blk00000001/sig00000082 ),
    .O(\blk00000001/sig00000075 )
  );
  XORCY   \blk00000001/blk000000b7  (
    .CI(\blk00000001/sig00000080 ),
    .LI(\blk00000001/sig00000082 ),
    .O(\blk00000001/sig0000019a )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b6  (
    .I0(\blk00000001/sig00000176 ),
    .I1(\blk00000001/sig0000016b ),
    .O(\blk00000001/sig00000083 )
  );
  MUXCY   \blk00000001/blk000000b5  (
    .CI(\blk00000001/sig00000075 ),
    .DI(\blk00000001/sig0000016b ),
    .S(\blk00000001/sig00000083 ),
    .O(\blk00000001/sig00000076 )
  );
  XORCY   \blk00000001/blk000000b4  (
    .CI(\blk00000001/sig00000075 ),
    .LI(\blk00000001/sig00000083 ),
    .O(\blk00000001/sig0000019b )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b3  (
    .I0(\blk00000001/sig00000177 ),
    .I1(\blk00000001/sig0000016b ),
    .O(\blk00000001/sig00000084 )
  );
  MUXCY   \blk00000001/blk000000b2  (
    .CI(\blk00000001/sig00000076 ),
    .DI(\blk00000001/sig0000016b ),
    .S(\blk00000001/sig00000084 ),
    .O(\blk00000001/sig00000077 )
  );
  XORCY   \blk00000001/blk000000b1  (
    .CI(\blk00000001/sig00000076 ),
    .LI(\blk00000001/sig00000084 ),
    .O(\blk00000001/sig0000019c )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b0  (
    .I0(\blk00000001/sig0000016b ),
    .I1(\blk00000001/sig00000178 ),
    .O(\blk00000001/sig00000085 )
  );
  XORCY   \blk00000001/blk000000af  (
    .CI(\blk00000001/sig00000077 ),
    .LI(\blk00000001/sig00000085 ),
    .O(\blk00000001/sig0000019d )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ae  (
    .I0(\blk00000001/sig00000131 ),
    .I1(\blk00000001/sig00000143 ),
    .O(\blk00000001/sig0000005c )
  );
  MUXCY   \blk00000001/blk000000ad  (
    .CI(\blk00000001/sig00000043 ),
    .DI(\blk00000001/sig00000131 ),
    .S(\blk00000001/sig0000005c ),
    .O(\blk00000001/sig00000045 )
  );
  XORCY   \blk00000001/blk000000ac  (
    .CI(\blk00000001/sig00000043 ),
    .LI(\blk00000001/sig0000005c ),
    .O(\blk00000001/sig00000181 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ab  (
    .I0(\blk00000001/sig00000132 ),
    .I1(\blk00000001/sig00000144 ),
    .O(\blk00000001/sig00000067 )
  );
  MUXCY   \blk00000001/blk000000aa  (
    .CI(\blk00000001/sig00000045 ),
    .DI(\blk00000001/sig00000132 ),
    .S(\blk00000001/sig00000067 ),
    .O(\blk00000001/sig00000050 )
  );
  XORCY   \blk00000001/blk000000a9  (
    .CI(\blk00000001/sig00000045 ),
    .LI(\blk00000001/sig00000067 ),
    .O(\blk00000001/sig0000018c )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a8  (
    .I0(\blk00000001/sig00000133 ),
    .I1(\blk00000001/sig0000014f ),
    .O(\blk00000001/sig0000006c )
  );
  MUXCY   \blk00000001/blk000000a7  (
    .CI(\blk00000001/sig00000050 ),
    .DI(\blk00000001/sig00000133 ),
    .S(\blk00000001/sig0000006c ),
    .O(\blk00000001/sig00000054 )
  );
  XORCY   \blk00000001/blk000000a6  (
    .CI(\blk00000001/sig00000050 ),
    .LI(\blk00000001/sig0000006c ),
    .O(\blk00000001/sig00000191 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a5  (
    .I0(\blk00000001/sig00000134 ),
    .I1(\blk00000001/sig00000154 ),
    .O(\blk00000001/sig0000006d )
  );
  MUXCY   \blk00000001/blk000000a4  (
    .CI(\blk00000001/sig00000054 ),
    .DI(\blk00000001/sig00000134 ),
    .S(\blk00000001/sig0000006d ),
    .O(\blk00000001/sig00000055 )
  );
  XORCY   \blk00000001/blk000000a3  (
    .CI(\blk00000001/sig00000054 ),
    .LI(\blk00000001/sig0000006d ),
    .O(\blk00000001/sig00000192 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a2  (
    .I0(\blk00000001/sig00000135 ),
    .I1(\blk00000001/sig00000155 ),
    .O(\blk00000001/sig0000006e )
  );
  MUXCY   \blk00000001/blk000000a1  (
    .CI(\blk00000001/sig00000055 ),
    .DI(\blk00000001/sig00000135 ),
    .S(\blk00000001/sig0000006e ),
    .O(\blk00000001/sig00000056 )
  );
  XORCY   \blk00000001/blk000000a0  (
    .CI(\blk00000001/sig00000055 ),
    .LI(\blk00000001/sig0000006e ),
    .O(\blk00000001/sig00000193 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009f  (
    .I0(\blk00000001/sig00000136 ),
    .I1(\blk00000001/sig00000156 ),
    .O(\blk00000001/sig0000006f )
  );
  MUXCY   \blk00000001/blk0000009e  (
    .CI(\blk00000001/sig00000056 ),
    .DI(\blk00000001/sig00000136 ),
    .S(\blk00000001/sig0000006f ),
    .O(\blk00000001/sig00000057 )
  );
  XORCY   \blk00000001/blk0000009d  (
    .CI(\blk00000001/sig00000056 ),
    .LI(\blk00000001/sig0000006f ),
    .O(\blk00000001/sig00000194 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009c  (
    .I0(\blk00000001/sig00000137 ),
    .I1(\blk00000001/sig00000157 ),
    .O(\blk00000001/sig00000070 )
  );
  MUXCY   \blk00000001/blk0000009b  (
    .CI(\blk00000001/sig00000057 ),
    .DI(\blk00000001/sig00000137 ),
    .S(\blk00000001/sig00000070 ),
    .O(\blk00000001/sig00000058 )
  );
  XORCY   \blk00000001/blk0000009a  (
    .CI(\blk00000001/sig00000057 ),
    .LI(\blk00000001/sig00000070 ),
    .O(\blk00000001/sig00000195 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000099  (
    .I0(\blk00000001/sig00000138 ),
    .I1(\blk00000001/sig00000158 ),
    .O(\blk00000001/sig00000071 )
  );
  MUXCY   \blk00000001/blk00000098  (
    .CI(\blk00000001/sig00000058 ),
    .DI(\blk00000001/sig00000138 ),
    .S(\blk00000001/sig00000071 ),
    .O(\blk00000001/sig00000059 )
  );
  XORCY   \blk00000001/blk00000097  (
    .CI(\blk00000001/sig00000058 ),
    .LI(\blk00000001/sig00000071 ),
    .O(\blk00000001/sig00000196 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000096  (
    .I0(\blk00000001/sig00000139 ),
    .I1(\blk00000001/sig00000159 ),
    .O(\blk00000001/sig00000072 )
  );
  MUXCY   \blk00000001/blk00000095  (
    .CI(\blk00000001/sig00000059 ),
    .DI(\blk00000001/sig00000139 ),
    .S(\blk00000001/sig00000072 ),
    .O(\blk00000001/sig0000005a )
  );
  XORCY   \blk00000001/blk00000094  (
    .CI(\blk00000001/sig00000059 ),
    .LI(\blk00000001/sig00000072 ),
    .O(\blk00000001/sig00000197 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000093  (
    .I0(\blk00000001/sig0000013a ),
    .I1(\blk00000001/sig0000015a ),
    .O(\blk00000001/sig00000073 )
  );
  MUXCY   \blk00000001/blk00000092  (
    .CI(\blk00000001/sig0000005a ),
    .DI(\blk00000001/sig0000013a ),
    .S(\blk00000001/sig00000073 ),
    .O(\blk00000001/sig0000005b )
  );
  XORCY   \blk00000001/blk00000091  (
    .CI(\blk00000001/sig0000005a ),
    .LI(\blk00000001/sig00000073 ),
    .O(\blk00000001/sig00000198 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000090  (
    .I0(\blk00000001/sig0000013b ),
    .I1(\blk00000001/sig00000145 ),
    .O(\blk00000001/sig0000005d )
  );
  MUXCY   \blk00000001/blk0000008f  (
    .CI(\blk00000001/sig0000005b ),
    .DI(\blk00000001/sig0000013b ),
    .S(\blk00000001/sig0000005d ),
    .O(\blk00000001/sig00000046 )
  );
  XORCY   \blk00000001/blk0000008e  (
    .CI(\blk00000001/sig0000005b ),
    .LI(\blk00000001/sig0000005d ),
    .O(\blk00000001/sig00000182 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000008d  (
    .I0(\blk00000001/sig0000013c ),
    .I1(\blk00000001/sig00000146 ),
    .O(\blk00000001/sig0000005e )
  );
  MUXCY   \blk00000001/blk0000008c  (
    .CI(\blk00000001/sig00000046 ),
    .DI(\blk00000001/sig0000013c ),
    .S(\blk00000001/sig0000005e ),
    .O(\blk00000001/sig00000047 )
  );
  XORCY   \blk00000001/blk0000008b  (
    .CI(\blk00000001/sig00000046 ),
    .LI(\blk00000001/sig0000005e ),
    .O(\blk00000001/sig00000183 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000008a  (
    .I0(\blk00000001/sig0000013d ),
    .I1(\blk00000001/sig00000147 ),
    .O(\blk00000001/sig0000005f )
  );
  MUXCY   \blk00000001/blk00000089  (
    .CI(\blk00000001/sig00000047 ),
    .DI(\blk00000001/sig0000013d ),
    .S(\blk00000001/sig0000005f ),
    .O(\blk00000001/sig00000048 )
  );
  XORCY   \blk00000001/blk00000088  (
    .CI(\blk00000001/sig00000047 ),
    .LI(\blk00000001/sig0000005f ),
    .O(\blk00000001/sig00000184 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000087  (
    .I0(\blk00000001/sig0000013e ),
    .I1(\blk00000001/sig00000148 ),
    .O(\blk00000001/sig00000060 )
  );
  MUXCY   \blk00000001/blk00000086  (
    .CI(\blk00000001/sig00000048 ),
    .DI(\blk00000001/sig0000013e ),
    .S(\blk00000001/sig00000060 ),
    .O(\blk00000001/sig00000049 )
  );
  XORCY   \blk00000001/blk00000085  (
    .CI(\blk00000001/sig00000048 ),
    .LI(\blk00000001/sig00000060 ),
    .O(\blk00000001/sig00000185 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000084  (
    .I0(\blk00000001/sig0000013f ),
    .I1(\blk00000001/sig00000149 ),
    .O(\blk00000001/sig00000061 )
  );
  MUXCY   \blk00000001/blk00000083  (
    .CI(\blk00000001/sig00000049 ),
    .DI(\blk00000001/sig0000013f ),
    .S(\blk00000001/sig00000061 ),
    .O(\blk00000001/sig0000004a )
  );
  XORCY   \blk00000001/blk00000082  (
    .CI(\blk00000001/sig00000049 ),
    .LI(\blk00000001/sig00000061 ),
    .O(\blk00000001/sig00000186 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000081  (
    .I0(\blk00000001/sig00000140 ),
    .I1(\blk00000001/sig0000014a ),
    .O(\blk00000001/sig00000062 )
  );
  MUXCY   \blk00000001/blk00000080  (
    .CI(\blk00000001/sig0000004a ),
    .DI(\blk00000001/sig00000140 ),
    .S(\blk00000001/sig00000062 ),
    .O(\blk00000001/sig0000004b )
  );
  XORCY   \blk00000001/blk0000007f  (
    .CI(\blk00000001/sig0000004a ),
    .LI(\blk00000001/sig00000062 ),
    .O(\blk00000001/sig00000187 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000007e  (
    .I0(\blk00000001/sig00000141 ),
    .I1(\blk00000001/sig0000014b ),
    .O(\blk00000001/sig00000063 )
  );
  MUXCY   \blk00000001/blk0000007d  (
    .CI(\blk00000001/sig0000004b ),
    .DI(\blk00000001/sig00000141 ),
    .S(\blk00000001/sig00000063 ),
    .O(\blk00000001/sig0000004c )
  );
  XORCY   \blk00000001/blk0000007c  (
    .CI(\blk00000001/sig0000004b ),
    .LI(\blk00000001/sig00000063 ),
    .O(\blk00000001/sig00000188 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000007b  (
    .I0(\blk00000001/sig0000014c ),
    .I1(\blk00000001/sig00000142 ),
    .O(\blk00000001/sig00000064 )
  );
  MUXCY   \blk00000001/blk0000007a  (
    .CI(\blk00000001/sig0000004c ),
    .DI(\blk00000001/sig00000142 ),
    .S(\blk00000001/sig00000064 ),
    .O(\blk00000001/sig0000004d )
  );
  XORCY   \blk00000001/blk00000079  (
    .CI(\blk00000001/sig0000004c ),
    .LI(\blk00000001/sig00000064 ),
    .O(\blk00000001/sig00000189 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000078  (
    .I0(\blk00000001/sig0000014d ),
    .I1(\blk00000001/sig00000142 ),
    .O(\blk00000001/sig00000065 )
  );
  MUXCY   \blk00000001/blk00000077  (
    .CI(\blk00000001/sig0000004d ),
    .DI(\blk00000001/sig00000142 ),
    .S(\blk00000001/sig00000065 ),
    .O(\blk00000001/sig0000004e )
  );
  XORCY   \blk00000001/blk00000076  (
    .CI(\blk00000001/sig0000004d ),
    .LI(\blk00000001/sig00000065 ),
    .O(\blk00000001/sig0000018a )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000075  (
    .I0(\blk00000001/sig0000014e ),
    .I1(\blk00000001/sig00000142 ),
    .O(\blk00000001/sig00000066 )
  );
  MUXCY   \blk00000001/blk00000074  (
    .CI(\blk00000001/sig0000004e ),
    .DI(\blk00000001/sig00000142 ),
    .S(\blk00000001/sig00000066 ),
    .O(\blk00000001/sig0000004f )
  );
  XORCY   \blk00000001/blk00000073  (
    .CI(\blk00000001/sig0000004e ),
    .LI(\blk00000001/sig00000066 ),
    .O(\blk00000001/sig0000018b )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000072  (
    .I0(\blk00000001/sig00000150 ),
    .I1(\blk00000001/sig00000142 ),
    .O(\blk00000001/sig00000068 )
  );
  MUXCY   \blk00000001/blk00000071  (
    .CI(\blk00000001/sig0000004f ),
    .DI(\blk00000001/sig00000142 ),
    .S(\blk00000001/sig00000068 ),
    .O(\blk00000001/sig00000051 )
  );
  XORCY   \blk00000001/blk00000070  (
    .CI(\blk00000001/sig0000004f ),
    .LI(\blk00000001/sig00000068 ),
    .O(\blk00000001/sig0000018d )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000006f  (
    .I0(\blk00000001/sig00000151 ),
    .I1(\blk00000001/sig00000142 ),
    .O(\blk00000001/sig00000069 )
  );
  MUXCY   \blk00000001/blk0000006e  (
    .CI(\blk00000001/sig00000051 ),
    .DI(\blk00000001/sig00000142 ),
    .S(\blk00000001/sig00000069 ),
    .O(\blk00000001/sig00000052 )
  );
  XORCY   \blk00000001/blk0000006d  (
    .CI(\blk00000001/sig00000051 ),
    .LI(\blk00000001/sig00000069 ),
    .O(\blk00000001/sig0000018e )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000006c  (
    .I0(\blk00000001/sig00000152 ),
    .I1(\blk00000001/sig00000142 ),
    .O(\blk00000001/sig0000006a )
  );
  MUXCY   \blk00000001/blk0000006b  (
    .CI(\blk00000001/sig00000052 ),
    .DI(\blk00000001/sig00000142 ),
    .S(\blk00000001/sig0000006a ),
    .O(\blk00000001/sig00000053 )
  );
  XORCY   \blk00000001/blk0000006a  (
    .CI(\blk00000001/sig00000052 ),
    .LI(\blk00000001/sig0000006a ),
    .O(\blk00000001/sig0000018f )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000069  (
    .I0(\blk00000001/sig00000142 ),
    .I1(\blk00000001/sig00000153 ),
    .O(\blk00000001/sig0000006b )
  );
  XORCY   \blk00000001/blk00000068  (
    .CI(\blk00000001/sig00000053 ),
    .LI(\blk00000001/sig0000006b ),
    .O(\blk00000001/sig00000190 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000067  (
    .I0(\blk00000001/sig0000015b ),
    .I1(\blk00000001/sig00000181 ),
    .O(\blk00000001/sig000000af )
  );
  MUXCY   \blk00000001/blk00000066  (
    .CI(\blk00000001/sig00000043 ),
    .DI(\blk00000001/sig00000181 ),
    .S(\blk00000001/sig000000af ),
    .O(\blk00000001/sig0000008f )
  );
  XORCY   \blk00000001/blk00000065  (
    .CI(\blk00000001/sig00000043 ),
    .LI(\blk00000001/sig000000af ),
    .O(\blk00000001/sig000001a7 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000064  (
    .I0(\blk00000001/sig0000015c ),
    .I1(\blk00000001/sig0000018c ),
    .O(\blk00000001/sig000000ba )
  );
  MUXCY   \blk00000001/blk00000063  (
    .CI(\blk00000001/sig0000008f ),
    .DI(\blk00000001/sig0000018c ),
    .S(\blk00000001/sig000000ba ),
    .O(\blk00000001/sig0000009a )
  );
  XORCY   \blk00000001/blk00000062  (
    .CI(\blk00000001/sig0000008f ),
    .LI(\blk00000001/sig000000ba ),
    .O(\blk00000001/sig000001b2 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000061  (
    .I0(\blk00000001/sig00000167 ),
    .I1(\blk00000001/sig00000191 ),
    .O(\blk00000001/sig000000c5 )
  );
  MUXCY   \blk00000001/blk00000060  (
    .CI(\blk00000001/sig0000009a ),
    .DI(\blk00000001/sig00000191 ),
    .S(\blk00000001/sig000000c5 ),
    .O(\blk00000001/sig000000a5 )
  );
  XORCY   \blk00000001/blk0000005f  (
    .CI(\blk00000001/sig0000009a ),
    .LI(\blk00000001/sig000000c5 ),
    .O(\blk00000001/sig000001bd )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000005e  (
    .I0(\blk00000001/sig0000016c ),
    .I1(\blk00000001/sig00000192 ),
    .O(\blk00000001/sig000000c9 )
  );
  MUXCY   \blk00000001/blk0000005d  (
    .CI(\blk00000001/sig000000a5 ),
    .DI(\blk00000001/sig00000192 ),
    .S(\blk00000001/sig000000c9 ),
    .O(\blk00000001/sig000000a8 )
  );
  XORCY   \blk00000001/blk0000005c  (
    .CI(\blk00000001/sig000000a5 ),
    .LI(\blk00000001/sig000000c9 ),
    .O(\blk00000001/sig000001be )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000005b  (
    .I0(\blk00000001/sig0000016d ),
    .I1(\blk00000001/sig00000193 ),
    .O(\blk00000001/sig000000ca )
  );
  MUXCY   \blk00000001/blk0000005a  (
    .CI(\blk00000001/sig000000a8 ),
    .DI(\blk00000001/sig00000193 ),
    .S(\blk00000001/sig000000ca ),
    .O(\blk00000001/sig000000a9 )
  );
  XORCY   \blk00000001/blk00000059  (
    .CI(\blk00000001/sig000000a8 ),
    .LI(\blk00000001/sig000000ca ),
    .O(\blk00000001/sig000001bf )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000058  (
    .I0(\blk00000001/sig0000016e ),
    .I1(\blk00000001/sig00000194 ),
    .O(\blk00000001/sig000000cb )
  );
  MUXCY   \blk00000001/blk00000057  (
    .CI(\blk00000001/sig000000a9 ),
    .DI(\blk00000001/sig00000194 ),
    .S(\blk00000001/sig000000cb ),
    .O(\blk00000001/sig000000aa )
  );
  XORCY   \blk00000001/blk00000056  (
    .CI(\blk00000001/sig000000a9 ),
    .LI(\blk00000001/sig000000cb ),
    .O(\blk00000001/sig000001c1 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000055  (
    .I0(\blk00000001/sig0000016f ),
    .I1(\blk00000001/sig00000195 ),
    .O(\blk00000001/sig000000cc )
  );
  MUXCY   \blk00000001/blk00000054  (
    .CI(\blk00000001/sig000000aa ),
    .DI(\blk00000001/sig00000195 ),
    .S(\blk00000001/sig000000cc ),
    .O(\blk00000001/sig000000ab )
  );
  XORCY   \blk00000001/blk00000053  (
    .CI(\blk00000001/sig000000aa ),
    .LI(\blk00000001/sig000000cc ),
    .O(\blk00000001/sig000001c2 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000052  (
    .I0(\blk00000001/sig00000170 ),
    .I1(\blk00000001/sig00000196 ),
    .O(\blk00000001/sig000000cd )
  );
  MUXCY   \blk00000001/blk00000051  (
    .CI(\blk00000001/sig000000ab ),
    .DI(\blk00000001/sig00000196 ),
    .S(\blk00000001/sig000000cd ),
    .O(\blk00000001/sig000000ac )
  );
  XORCY   \blk00000001/blk00000050  (
    .CI(\blk00000001/sig000000ab ),
    .LI(\blk00000001/sig000000cd ),
    .O(\blk00000001/sig000001c3 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000004f  (
    .I0(\blk00000001/sig00000171 ),
    .I1(\blk00000001/sig00000197 ),
    .O(\blk00000001/sig000000ce )
  );
  MUXCY   \blk00000001/blk0000004e  (
    .CI(\blk00000001/sig000000ac ),
    .DI(\blk00000001/sig00000197 ),
    .S(\blk00000001/sig000000ce ),
    .O(\blk00000001/sig000000ad )
  );
  XORCY   \blk00000001/blk0000004d  (
    .CI(\blk00000001/sig000000ac ),
    .LI(\blk00000001/sig000000ce ),
    .O(\blk00000001/sig000001c4 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000004c  (
    .I0(\blk00000001/sig00000172 ),
    .I1(\blk00000001/sig00000198 ),
    .O(\blk00000001/sig000000cf )
  );
  MUXCY   \blk00000001/blk0000004b  (
    .CI(\blk00000001/sig000000ad ),
    .DI(\blk00000001/sig00000198 ),
    .S(\blk00000001/sig000000cf ),
    .O(\blk00000001/sig000000ae )
  );
  XORCY   \blk00000001/blk0000004a  (
    .CI(\blk00000001/sig000000ad ),
    .LI(\blk00000001/sig000000cf ),
    .O(\blk00000001/sig000001c5 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000049  (
    .I0(\blk00000001/sig0000015d ),
    .I1(\blk00000001/sig00000182 ),
    .O(\blk00000001/sig000000b0 )
  );
  MUXCY   \blk00000001/blk00000048  (
    .CI(\blk00000001/sig000000ae ),
    .DI(\blk00000001/sig00000182 ),
    .S(\blk00000001/sig000000b0 ),
    .O(\blk00000001/sig00000090 )
  );
  XORCY   \blk00000001/blk00000047  (
    .CI(\blk00000001/sig000000ae ),
    .LI(\blk00000001/sig000000b0 ),
    .O(\blk00000001/sig000001a8 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000046  (
    .I0(\blk00000001/sig0000015e ),
    .I1(\blk00000001/sig00000183 ),
    .O(\blk00000001/sig000000b1 )
  );
  MUXCY   \blk00000001/blk00000045  (
    .CI(\blk00000001/sig00000090 ),
    .DI(\blk00000001/sig00000183 ),
    .S(\blk00000001/sig000000b1 ),
    .O(\blk00000001/sig00000091 )
  );
  XORCY   \blk00000001/blk00000044  (
    .CI(\blk00000001/sig00000090 ),
    .LI(\blk00000001/sig000000b1 ),
    .O(\blk00000001/sig000001a9 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000043  (
    .I0(\blk00000001/sig0000015f ),
    .I1(\blk00000001/sig00000184 ),
    .O(\blk00000001/sig000000b2 )
  );
  MUXCY   \blk00000001/blk00000042  (
    .CI(\blk00000001/sig00000091 ),
    .DI(\blk00000001/sig00000184 ),
    .S(\blk00000001/sig000000b2 ),
    .O(\blk00000001/sig00000092 )
  );
  XORCY   \blk00000001/blk00000041  (
    .CI(\blk00000001/sig00000091 ),
    .LI(\blk00000001/sig000000b2 ),
    .O(\blk00000001/sig000001aa )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000040  (
    .I0(\blk00000001/sig00000160 ),
    .I1(\blk00000001/sig00000185 ),
    .O(\blk00000001/sig000000b3 )
  );
  MUXCY   \blk00000001/blk0000003f  (
    .CI(\blk00000001/sig00000092 ),
    .DI(\blk00000001/sig00000185 ),
    .S(\blk00000001/sig000000b3 ),
    .O(\blk00000001/sig00000093 )
  );
  XORCY   \blk00000001/blk0000003e  (
    .CI(\blk00000001/sig00000092 ),
    .LI(\blk00000001/sig000000b3 ),
    .O(\blk00000001/sig000001ab )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000003d  (
    .I0(\blk00000001/sig00000161 ),
    .I1(\blk00000001/sig00000186 ),
    .O(\blk00000001/sig000000b4 )
  );
  MUXCY   \blk00000001/blk0000003c  (
    .CI(\blk00000001/sig00000093 ),
    .DI(\blk00000001/sig00000186 ),
    .S(\blk00000001/sig000000b4 ),
    .O(\blk00000001/sig00000094 )
  );
  XORCY   \blk00000001/blk0000003b  (
    .CI(\blk00000001/sig00000093 ),
    .LI(\blk00000001/sig000000b4 ),
    .O(\blk00000001/sig000001ac )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000003a  (
    .I0(\blk00000001/sig00000162 ),
    .I1(\blk00000001/sig00000187 ),
    .O(\blk00000001/sig000000b5 )
  );
  MUXCY   \blk00000001/blk00000039  (
    .CI(\blk00000001/sig00000094 ),
    .DI(\blk00000001/sig00000187 ),
    .S(\blk00000001/sig000000b5 ),
    .O(\blk00000001/sig00000095 )
  );
  XORCY   \blk00000001/blk00000038  (
    .CI(\blk00000001/sig00000094 ),
    .LI(\blk00000001/sig000000b5 ),
    .O(\blk00000001/sig000001ad )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000037  (
    .I0(\blk00000001/sig00000163 ),
    .I1(\blk00000001/sig00000188 ),
    .O(\blk00000001/sig000000b6 )
  );
  MUXCY   \blk00000001/blk00000036  (
    .CI(\blk00000001/sig00000095 ),
    .DI(\blk00000001/sig00000188 ),
    .S(\blk00000001/sig000000b6 ),
    .O(\blk00000001/sig00000096 )
  );
  XORCY   \blk00000001/blk00000035  (
    .CI(\blk00000001/sig00000095 ),
    .LI(\blk00000001/sig000000b6 ),
    .O(\blk00000001/sig000001ae )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000034  (
    .I0(\blk00000001/sig00000199 ),
    .I1(\blk00000001/sig00000189 ),
    .O(\blk00000001/sig000000b7 )
  );
  MUXCY   \blk00000001/blk00000033  (
    .CI(\blk00000001/sig00000096 ),
    .DI(\blk00000001/sig00000189 ),
    .S(\blk00000001/sig000000b7 ),
    .O(\blk00000001/sig00000097 )
  );
  XORCY   \blk00000001/blk00000032  (
    .CI(\blk00000001/sig00000096 ),
    .LI(\blk00000001/sig000000b7 ),
    .O(\blk00000001/sig000001af )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000031  (
    .I0(\blk00000001/sig0000019e ),
    .I1(\blk00000001/sig0000018a ),
    .O(\blk00000001/sig000000b8 )
  );
  MUXCY   \blk00000001/blk00000030  (
    .CI(\blk00000001/sig00000097 ),
    .DI(\blk00000001/sig0000018a ),
    .S(\blk00000001/sig000000b8 ),
    .O(\blk00000001/sig00000098 )
  );
  XORCY   \blk00000001/blk0000002f  (
    .CI(\blk00000001/sig00000097 ),
    .LI(\blk00000001/sig000000b8 ),
    .O(\blk00000001/sig000001b0 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000002e  (
    .I0(\blk00000001/sig0000019f ),
    .I1(\blk00000001/sig0000018b ),
    .O(\blk00000001/sig000000b9 )
  );
  MUXCY   \blk00000001/blk0000002d  (
    .CI(\blk00000001/sig00000098 ),
    .DI(\blk00000001/sig0000018b ),
    .S(\blk00000001/sig000000b9 ),
    .O(\blk00000001/sig00000099 )
  );
  XORCY   \blk00000001/blk0000002c  (
    .CI(\blk00000001/sig00000098 ),
    .LI(\blk00000001/sig000000b9 ),
    .O(\blk00000001/sig000001b1 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000002b  (
    .I0(\blk00000001/sig000001a0 ),
    .I1(\blk00000001/sig0000018d ),
    .O(\blk00000001/sig000000bb )
  );
  MUXCY   \blk00000001/blk0000002a  (
    .CI(\blk00000001/sig00000099 ),
    .DI(\blk00000001/sig0000018d ),
    .S(\blk00000001/sig000000bb ),
    .O(\blk00000001/sig0000009b )
  );
  XORCY   \blk00000001/blk00000029  (
    .CI(\blk00000001/sig00000099 ),
    .LI(\blk00000001/sig000000bb ),
    .O(\blk00000001/sig000001b3 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000028  (
    .I0(\blk00000001/sig000001a1 ),
    .I1(\blk00000001/sig0000018e ),
    .O(\blk00000001/sig000000bc )
  );
  MUXCY   \blk00000001/blk00000027  (
    .CI(\blk00000001/sig0000009b ),
    .DI(\blk00000001/sig0000018e ),
    .S(\blk00000001/sig000000bc ),
    .O(\blk00000001/sig0000009c )
  );
  XORCY   \blk00000001/blk00000026  (
    .CI(\blk00000001/sig0000009b ),
    .LI(\blk00000001/sig000000bc ),
    .O(\blk00000001/sig000001b4 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000025  (
    .I0(\blk00000001/sig000001a2 ),
    .I1(\blk00000001/sig0000018f ),
    .O(\blk00000001/sig000000bd )
  );
  MUXCY   \blk00000001/blk00000024  (
    .CI(\blk00000001/sig0000009c ),
    .DI(\blk00000001/sig0000018f ),
    .S(\blk00000001/sig000000bd ),
    .O(\blk00000001/sig0000009d )
  );
  XORCY   \blk00000001/blk00000023  (
    .CI(\blk00000001/sig0000009c ),
    .LI(\blk00000001/sig000000bd ),
    .O(\blk00000001/sig000001b5 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000022  (
    .I0(\blk00000001/sig000001a3 ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig000000be )
  );
  MUXCY   \blk00000001/blk00000021  (
    .CI(\blk00000001/sig0000009d ),
    .DI(\blk00000001/sig00000190 ),
    .S(\blk00000001/sig000000be ),
    .O(\blk00000001/sig0000009e )
  );
  XORCY   \blk00000001/blk00000020  (
    .CI(\blk00000001/sig0000009d ),
    .LI(\blk00000001/sig000000be ),
    .O(\blk00000001/sig000001b6 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000001f  (
    .I0(\blk00000001/sig000001a4 ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig000000bf )
  );
  MUXCY   \blk00000001/blk0000001e  (
    .CI(\blk00000001/sig0000009e ),
    .DI(\blk00000001/sig00000190 ),
    .S(\blk00000001/sig000000bf ),
    .O(\blk00000001/sig0000009f )
  );
  XORCY   \blk00000001/blk0000001d  (
    .CI(\blk00000001/sig0000009e ),
    .LI(\blk00000001/sig000000bf ),
    .O(\blk00000001/sig000001b7 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000001c  (
    .I0(\blk00000001/sig000001a5 ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig000000c0 )
  );
  MUXCY   \blk00000001/blk0000001b  (
    .CI(\blk00000001/sig0000009f ),
    .DI(\blk00000001/sig00000190 ),
    .S(\blk00000001/sig000000c0 ),
    .O(\blk00000001/sig000000a0 )
  );
  XORCY   \blk00000001/blk0000001a  (
    .CI(\blk00000001/sig0000009f ),
    .LI(\blk00000001/sig000000c0 ),
    .O(\blk00000001/sig000001b8 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000019  (
    .I0(\blk00000001/sig000001a6 ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig000000c1 )
  );
  MUXCY   \blk00000001/blk00000018  (
    .CI(\blk00000001/sig000000a0 ),
    .DI(\blk00000001/sig00000190 ),
    .S(\blk00000001/sig000000c1 ),
    .O(\blk00000001/sig000000a1 )
  );
  XORCY   \blk00000001/blk00000017  (
    .CI(\blk00000001/sig000000a0 ),
    .LI(\blk00000001/sig000000c1 ),
    .O(\blk00000001/sig000001b9 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000016  (
    .I0(\blk00000001/sig0000019a ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig000000c2 )
  );
  MUXCY   \blk00000001/blk00000015  (
    .CI(\blk00000001/sig000000a1 ),
    .DI(\blk00000001/sig00000190 ),
    .S(\blk00000001/sig000000c2 ),
    .O(\blk00000001/sig000000a2 )
  );
  XORCY   \blk00000001/blk00000014  (
    .CI(\blk00000001/sig000000a1 ),
    .LI(\blk00000001/sig000000c2 ),
    .O(\blk00000001/sig000001ba )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000013  (
    .I0(\blk00000001/sig0000019b ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig000000c3 )
  );
  MUXCY   \blk00000001/blk00000012  (
    .CI(\blk00000001/sig000000a2 ),
    .DI(\blk00000001/sig00000190 ),
    .S(\blk00000001/sig000000c3 ),
    .O(\blk00000001/sig000000a3 )
  );
  XORCY   \blk00000001/blk00000011  (
    .CI(\blk00000001/sig000000a2 ),
    .LI(\blk00000001/sig000000c3 ),
    .O(\blk00000001/sig000001bb )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000010  (
    .I0(\blk00000001/sig0000019c ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig000000c4 )
  );
  MUXCY   \blk00000001/blk0000000f  (
    .CI(\blk00000001/sig000000a3 ),
    .DI(\blk00000001/sig00000190 ),
    .S(\blk00000001/sig000000c4 ),
    .O(\blk00000001/sig000000a4 )
  );
  XORCY   \blk00000001/blk0000000e  (
    .CI(\blk00000001/sig000000a3 ),
    .LI(\blk00000001/sig000000c4 ),
    .O(\blk00000001/sig000001bc )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000000d  (
    .I0(\blk00000001/sig0000019d ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig000000c6 )
  );
  MUXCY   \blk00000001/blk0000000c  (
    .CI(\blk00000001/sig000000a4 ),
    .DI(\blk00000001/sig00000190 ),
    .S(\blk00000001/sig000000c6 ),
    .O(\blk00000001/sig000000a6 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000000b  (
    .I0(\blk00000001/sig0000019d ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig000000c7 )
  );
  MUXCY   \blk00000001/blk0000000a  (
    .CI(\blk00000001/sig000000a6 ),
    .DI(\blk00000001/sig00000190 ),
    .S(\blk00000001/sig000000c7 ),
    .O(\blk00000001/sig000000a7 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000009  (
    .I0(\blk00000001/sig0000019d ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig000000c8 )
  );
  XORCY   \blk00000001/blk00000008  (
    .CI(\blk00000001/sig000000a7 ),
    .LI(\blk00000001/sig000000c8 ),
    .O(\blk00000001/sig000001c0 )
  );
  MULT18X18S   \blk00000001/blk00000007  (
    .C(clk),
    .CE(\blk00000001/sig00000044 ),
    .R(\blk00000001/sig00000043 ),
    .A({\blk00000001/sig00000043 , a[16], a[15], a[14], a[13], a[12], a[11], a[10], a[9], a[8], a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0]}),
    .B({\blk00000001/sig00000043 , b[16], b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4], b[3], b[2], b[1], b[0]}),
    .P({\NLW_blk00000001/blk00000007_P<35>_UNCONNECTED , \blk00000001/sig000000eb , \blk00000001/sig000000ea , \blk00000001/sig000000e9 , 
\blk00000001/sig000000e8 , \blk00000001/sig000000e7 , \blk00000001/sig000000e5 , \blk00000001/sig000000e4 , \blk00000001/sig000000e3 , 
\blk00000001/sig000000e2 , \blk00000001/sig000000e1 , \blk00000001/sig000000e0 , \blk00000001/sig000000df , \blk00000001/sig000000de , 
\blk00000001/sig000000dd , \blk00000001/sig000000dc , \blk00000001/sig000000da , \blk00000001/sig000000d9 , \blk00000001/sig000000d8 , 
\blk00000001/sig000000d7 , \blk00000001/sig000000d6 , \blk00000001/sig000000d5 , \blk00000001/sig000000d4 , \blk00000001/sig000000d3 , 
\blk00000001/sig000000d2 , \blk00000001/sig000000d1 , \blk00000001/sig000000f2 , \blk00000001/sig000000f1 , \blk00000001/sig000000f0 , 
\blk00000001/sig000000ef , \blk00000001/sig000000ee , \blk00000001/sig000000ed , \blk00000001/sig000000ec , \blk00000001/sig000000e6 , 
\blk00000001/sig000000db , \blk00000001/sig000000d0 })
  );
  MULT18X18S   \blk00000001/blk00000006  (
    .C(clk),
    .CE(\blk00000001/sig00000044 ),
    .R(\blk00000001/sig00000043 ),
    .A({\blk00000001/sig00000043 , a[16], a[15], a[14], a[13], a[12], a[11], a[10], a[9], a[8], a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0]}),
    .B({b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[22], b[21], b[20], b[19], b[18], b[17]}),
    .P({\NLW_blk00000001/blk00000006_P<35>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<34>_UNCONNECTED , 
\NLW_blk00000001/blk00000006_P<33>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<32>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<31>_UNCONNECTED , 
\NLW_blk00000001/blk00000006_P<30>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<29>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<28>_UNCONNECTED , 
\NLW_blk00000001/blk00000006_P<27>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<26>_UNCONNECTED , \NLW_blk00000001/blk00000006_P<25>_UNCONNECTED , 
\NLW_blk00000001/blk00000006_P<24>_UNCONNECTED , \blk00000001/sig00000102 , \blk00000001/sig00000101 , \blk00000001/sig00000100 , 
\blk00000001/sig000000ff , \blk00000001/sig000000fd , \blk00000001/sig000000fc , \blk00000001/sig000000fb , \blk00000001/sig000000fa , 
\blk00000001/sig000000f9 , \blk00000001/sig000000f8 , \blk00000001/sig000000f7 , \blk00000001/sig000000f6 , \blk00000001/sig000000f5 , 
\blk00000001/sig000000f4 , \blk00000001/sig0000010a , \blk00000001/sig00000109 , \blk00000001/sig00000108 , \blk00000001/sig00000107 , 
\blk00000001/sig00000106 , \blk00000001/sig00000105 , \blk00000001/sig00000104 , \blk00000001/sig00000103 , \blk00000001/sig000000fe , 
\blk00000001/sig000000f3 })
  );
  MULT18X18S   \blk00000001/blk00000005  (
    .C(clk),
    .CE(\blk00000001/sig00000044 ),
    .R(\blk00000001/sig00000043 ),
    .A({a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[22], a[21], a[20], a[19], a[18], a[17]}),
    .B({\blk00000001/sig00000043 , b[16], b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4], b[3], b[2], b[1], b[0]}),
    .P({\NLW_blk00000001/blk00000005_P<35>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<34>_UNCONNECTED , 
\NLW_blk00000001/blk00000005_P<33>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<32>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<31>_UNCONNECTED , 
\NLW_blk00000001/blk00000005_P<30>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<29>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<28>_UNCONNECTED , 
\NLW_blk00000001/blk00000005_P<27>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<26>_UNCONNECTED , \NLW_blk00000001/blk00000005_P<25>_UNCONNECTED , 
\NLW_blk00000001/blk00000005_P<24>_UNCONNECTED , \blk00000001/sig0000011a , \blk00000001/sig00000119 , \blk00000001/sig00000118 , 
\blk00000001/sig00000117 , \blk00000001/sig00000115 , \blk00000001/sig00000114 , \blk00000001/sig00000113 , \blk00000001/sig00000112 , 
\blk00000001/sig00000111 , \blk00000001/sig00000110 , \blk00000001/sig0000010f , \blk00000001/sig0000010e , \blk00000001/sig0000010d , 
\blk00000001/sig0000010c , \blk00000001/sig00000122 , \blk00000001/sig00000121 , \blk00000001/sig00000120 , \blk00000001/sig0000011f , 
\blk00000001/sig0000011e , \blk00000001/sig0000011d , \blk00000001/sig0000011c , \blk00000001/sig0000011b , \blk00000001/sig00000116 , 
\blk00000001/sig0000010b })
  );
  MULT18X18S   \blk00000001/blk00000004  (
    .C(clk),
    .CE(\blk00000001/sig00000044 ),
    .R(\blk00000001/sig00000043 ),
    .A({a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[22], a[21], a[20], a[19], a[18], a[17]}),
    .B({b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[22], b[21], b[20], b[19], b[18], b[17]}),
    .P({\NLW_blk00000001/blk00000004_P<35>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<34>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<33>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<32>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<31>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<30>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<29>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<28>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<27>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<26>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<25>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<24>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<23>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<22>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<21>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<20>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<19>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<18>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<17>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<16>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<15>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<14>_UNCONNECTED , \blk00000001/sig00000127 , \blk00000001/sig00000126 
, \blk00000001/sig00000125 , \blk00000001/sig00000124 , \blk00000001/sig00000130 , \blk00000001/sig0000012f , \blk00000001/sig0000012e , 
\blk00000001/sig0000012d , \blk00000001/sig0000012c , \blk00000001/sig0000012b , \blk00000001/sig0000012a , \blk00000001/sig00000129 , 
\blk00000001/sig00000128 , \blk00000001/sig00000123 })
  );
  VCC   \blk00000001/blk00000003  (
    .P(\blk00000001/sig00000044 )
  );
  GND   \blk00000001/blk00000002  (
    .G(\blk00000001/sig00000043 )
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

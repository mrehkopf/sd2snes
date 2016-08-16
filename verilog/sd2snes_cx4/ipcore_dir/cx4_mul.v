////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2013 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: P.20131013
//  \   \         Application: netgen
//  /   /         Filename: cx4_mul.v
// /___/   /\     Timestamp: Mon Jul 25 22:26:18 2016
// \   \  /  \ 
//  \___\/\___\
//             
// Command	: -w -sim -ofmt verilog D:/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.ngc D:/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.v 
// Device	: 3s400pq208-4
// Input file	: D:/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.ngc
// Output file	: D:/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.v
// # of Modules	: 1
// Design Name	: cx4_mul
// Xilinx        : E:\Xilinx\14.7\ISE_DS\ISE\
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
  
  wire \blk00000001/sig0000021b ;
  wire \blk00000001/sig0000021a ;
  wire \blk00000001/sig00000219 ;
  wire \blk00000001/sig00000218 ;
  wire \blk00000001/sig00000217 ;
  wire \blk00000001/sig00000216 ;
  wire \blk00000001/sig00000215 ;
  wire \blk00000001/sig00000214 ;
  wire \blk00000001/sig00000213 ;
  wire \blk00000001/sig00000212 ;
  wire \blk00000001/sig00000211 ;
  wire \blk00000001/sig00000210 ;
  wire \blk00000001/sig0000020f ;
  wire \blk00000001/sig0000020e ;
  wire \blk00000001/sig0000020d ;
  wire \blk00000001/sig0000020c ;
  wire \blk00000001/sig0000020b ;
  wire \blk00000001/sig0000020a ;
  wire \blk00000001/sig00000209 ;
  wire \blk00000001/sig00000208 ;
  wire \blk00000001/sig00000207 ;
  wire \blk00000001/sig00000206 ;
  wire \blk00000001/sig00000205 ;
  wire \blk00000001/sig00000204 ;
  wire \blk00000001/sig00000203 ;
  wire \blk00000001/sig00000202 ;
  wire \blk00000001/sig00000201 ;
  wire \blk00000001/sig00000200 ;
  wire \blk00000001/sig000001ff ;
  wire \blk00000001/sig000001fe ;
  wire \blk00000001/sig000001fd ;
  wire \blk00000001/sig000001fc ;
  wire \blk00000001/sig000001fb ;
  wire \blk00000001/sig000001fa ;
  wire \blk00000001/sig000001f9 ;
  wire \blk00000001/sig000001f8 ;
  wire \blk00000001/sig000001f7 ;
  wire \blk00000001/sig000001f6 ;
  wire \blk00000001/sig000001f5 ;
  wire \blk00000001/sig000001f4 ;
  wire \blk00000001/sig000001f3 ;
  wire \blk00000001/sig000001f2 ;
  wire \blk00000001/sig000001f1 ;
  wire \blk00000001/sig000001f0 ;
  wire \blk00000001/sig000001ef ;
  wire \blk00000001/sig000001ee ;
  wire \blk00000001/sig000001ed ;
  wire \blk00000001/sig000001ec ;
  wire \blk00000001/sig000001eb ;
  wire \blk00000001/sig000001ea ;
  wire \blk00000001/sig000001e9 ;
  wire \blk00000001/sig000001e8 ;
  wire \blk00000001/sig000001e7 ;
  wire \blk00000001/sig000001e6 ;
  wire \blk00000001/sig000001e5 ;
  wire \blk00000001/sig000001e4 ;
  wire \blk00000001/sig000001e3 ;
  wire \blk00000001/sig000001e2 ;
  wire \blk00000001/sig000001e1 ;
  wire \blk00000001/sig000001e0 ;
  wire \blk00000001/sig000001df ;
  wire \blk00000001/sig000001de ;
  wire \blk00000001/sig000001dd ;
  wire \blk00000001/sig000001dc ;
  wire \blk00000001/sig000001db ;
  wire \blk00000001/sig000001da ;
  wire \blk00000001/sig000001d9 ;
  wire \blk00000001/sig000001d8 ;
  wire \blk00000001/sig000001d7 ;
  wire \blk00000001/sig000001d6 ;
  wire \blk00000001/sig000001d5 ;
  wire \blk00000001/sig000001d4 ;
  wire \blk00000001/sig000001d3 ;
  wire \blk00000001/sig000001d2 ;
  wire \blk00000001/sig000001d1 ;
  wire \blk00000001/sig000001d0 ;
  wire \blk00000001/sig000001cf ;
  wire \blk00000001/sig000001ce ;
  wire \blk00000001/sig000001cd ;
  wire \blk00000001/sig000001cc ;
  wire \blk00000001/sig000001cb ;
  wire \blk00000001/sig000001ca ;
  wire \blk00000001/sig000001c9 ;
  wire \blk00000001/sig000001c8 ;
  wire \blk00000001/sig000001c7 ;
  wire \blk00000001/sig000001c6 ;
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
  wire \NLW_blk00000001/blk0000001e_P<35>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<35>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<34>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<33>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<32>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<31>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<30>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<29>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<28>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<27>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<26>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<25>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001d_P<24>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<35>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<34>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<33>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<32>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<31>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<30>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<29>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<28>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<27>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<26>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<25>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001c_P<24>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<35>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<34>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<33>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<32>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<31>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<30>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<29>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<28>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<27>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<26>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<25>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<24>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<23>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<22>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<21>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<20>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<19>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<18>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<17>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<16>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<15>_UNCONNECTED ;
  wire \NLW_blk00000001/blk0000001b_P<14>_UNCONNECTED ;
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001be  (
    .C(clk),
    .D(\blk00000001/sig000000d8 ),
    .Q(\blk00000001/sig000000e9 )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001bd  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000135 ),
    .Q(\blk00000001/sig000000d8 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001bc  (
    .C(clk),
    .D(\blk00000001/sig000000d9 ),
    .Q(\blk00000001/sig000000ea )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001bb  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000140 ),
    .Q(\blk00000001/sig000000d9 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001ba  (
    .C(clk),
    .D(\blk00000001/sig000000e2 ),
    .Q(\blk00000001/sig000000f3 )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001b9  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000146 ),
    .Q(\blk00000001/sig000000e2 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001b8  (
    .C(clk),
    .D(\blk00000001/sig000000e3 ),
    .Q(\blk00000001/sig000000f4 )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001b7  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000147 ),
    .Q(\blk00000001/sig000000e3 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001b6  (
    .C(clk),
    .D(\blk00000001/sig000000e1 ),
    .Q(\blk00000001/sig000000f2 )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001b5  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000145 ),
    .Q(\blk00000001/sig000000e1 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001b4  (
    .C(clk),
    .D(\blk00000001/sig000000e4 ),
    .Q(\blk00000001/sig000000f5 )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001b3  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000148 ),
    .Q(\blk00000001/sig000000e4 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001b2  (
    .C(clk),
    .D(\blk00000001/sig000000e5 ),
    .Q(\blk00000001/sig000000f6 )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001b1  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000149 ),
    .Q(\blk00000001/sig000000e5 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001b0  (
    .C(clk),
    .D(\blk00000001/sig000000e7 ),
    .Q(\blk00000001/sig000000f8 )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001af  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig0000014b ),
    .Q(\blk00000001/sig000000e7 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001ae  (
    .C(clk),
    .D(\blk00000001/sig000000e8 ),
    .Q(\blk00000001/sig000000f9 )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001ad  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig0000014c ),
    .Q(\blk00000001/sig000000e8 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001ac  (
    .C(clk),
    .D(\blk00000001/sig000000e6 ),
    .Q(\blk00000001/sig000000f7 )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001ab  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig0000014a ),
    .Q(\blk00000001/sig000000e6 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001aa  (
    .C(clk),
    .D(\blk00000001/sig000000da ),
    .Q(\blk00000001/sig000000eb )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001a9  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000136 ),
    .Q(\blk00000001/sig000000da )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001a8  (
    .C(clk),
    .D(\blk00000001/sig000000db ),
    .Q(\blk00000001/sig000000ec )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001a7  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000137 ),
    .Q(\blk00000001/sig000000db )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001a6  (
    .C(clk),
    .D(\blk00000001/sig000000dd ),
    .Q(\blk00000001/sig000000ee )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001a5  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000139 ),
    .Q(\blk00000001/sig000000dd )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001a4  (
    .C(clk),
    .D(\blk00000001/sig000000de ),
    .Q(\blk00000001/sig000000ef )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001a3  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig0000013a ),
    .Q(\blk00000001/sig000000de )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001a2  (
    .C(clk),
    .D(\blk00000001/sig000000dc ),
    .Q(\blk00000001/sig000000ed )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk000001a1  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000138 ),
    .Q(\blk00000001/sig000000dc )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000001a0  (
    .C(clk),
    .D(\blk00000001/sig000000e0 ),
    .Q(\blk00000001/sig000000f1 )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000019f  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig0000013c ),
    .Q(\blk00000001/sig000000e0 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000019e  (
    .C(clk),
    .D(\blk00000001/sig00000043 ),
    .Q(p[24])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000019d  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000202 ),
    .Q(\blk00000001/sig00000043 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000019c  (
    .C(clk),
    .D(\blk00000001/sig000000df ),
    .Q(\blk00000001/sig000000f0 )
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000019b  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig0000013b ),
    .Q(\blk00000001/sig000000df )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000019a  (
    .C(clk),
    .D(\blk00000001/sig00000041 ),
    .Q(p[22])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000199  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000200 ),
    .Q(\blk00000001/sig00000041 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000198  (
    .C(clk),
    .D(\blk00000001/sig00000040 ),
    .Q(p[21])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000197  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig000001fe ),
    .Q(\blk00000001/sig00000040 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000196  (
    .C(clk),
    .D(\blk00000001/sig00000042 ),
    .Q(p[23])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000195  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000201 ),
    .Q(\blk00000001/sig00000042 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000194  (
    .C(clk),
    .D(\blk00000001/sig0000003f ),
    .Q(p[20])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000193  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig000001fd ),
    .Q(\blk00000001/sig0000003f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000192  (
    .C(clk),
    .D(\blk00000001/sig0000003d ),
    .Q(p[19])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000191  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig000001fc ),
    .Q(\blk00000001/sig0000003d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000190  (
    .C(clk),
    .D(\blk00000001/sig0000003b ),
    .Q(p[17])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000018f  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig000001e6 ),
    .Q(\blk00000001/sig0000003b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000018e  (
    .C(clk),
    .D(\blk00000001/sig0000003a ),
    .Q(p[16])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000018d  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000101 ),
    .Q(\blk00000001/sig0000003a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000018c  (
    .C(clk),
    .D(\blk00000001/sig0000003c ),
    .Q(p[18])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000018b  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004b ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig000001f1 ),
    .Q(\blk00000001/sig0000003c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000018a  (
    .C(clk),
    .D(\blk00000001/sig00000039 ),
    .Q(p[15])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000189  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000100 ),
    .Q(\blk00000001/sig00000039 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000188  (
    .C(clk),
    .D(\blk00000001/sig00000038 ),
    .Q(p[14])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000187  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig000000ff ),
    .Q(\blk00000001/sig00000038 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000186  (
    .C(clk),
    .D(\blk00000001/sig00000036 ),
    .Q(p[12])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000185  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig000000fd ),
    .Q(\blk00000001/sig00000036 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000184  (
    .C(clk),
    .D(\blk00000001/sig00000035 ),
    .Q(p[11])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000183  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig000000fc ),
    .Q(\blk00000001/sig00000035 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000182  (
    .C(clk),
    .D(\blk00000001/sig00000037 ),
    .Q(p[13])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000181  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig000000fe ),
    .Q(\blk00000001/sig00000037 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000180  (
    .C(clk),
    .D(\blk00000001/sig00000034 ),
    .Q(p[10])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000017f  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig000000fb ),
    .Q(\blk00000001/sig00000034 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000017e  (
    .C(clk),
    .D(\blk00000001/sig0000004a ),
    .Q(p[9])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000017d  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig0000011c ),
    .Q(\blk00000001/sig0000004a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000017c  (
    .C(clk),
    .D(\blk00000001/sig00000048 ),
    .Q(p[7])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000017b  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig0000011a ),
    .Q(\blk00000001/sig00000048 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000017a  (
    .C(clk),
    .D(\blk00000001/sig00000047 ),
    .Q(p[6])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000179  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000119 ),
    .Q(\blk00000001/sig00000047 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000178  (
    .C(clk),
    .D(\blk00000001/sig00000049 ),
    .Q(p[8])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000177  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig0000011b ),
    .Q(\blk00000001/sig00000049 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000176  (
    .C(clk),
    .D(\blk00000001/sig00000045 ),
    .Q(p[4])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000175  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000117 ),
    .Q(\blk00000001/sig00000045 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000174  (
    .C(clk),
    .D(\blk00000001/sig00000044 ),
    .Q(p[3])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000173  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000116 ),
    .Q(\blk00000001/sig00000044 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000172  (
    .C(clk),
    .D(\blk00000001/sig00000046 ),
    .Q(p[5])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk00000171  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000118 ),
    .Q(\blk00000001/sig00000046 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000170  (
    .C(clk),
    .D(\blk00000001/sig00000033 ),
    .Q(p[1])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000016f  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000105 ),
    .Q(\blk00000001/sig00000033 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000016e  (
    .C(clk),
    .D(\blk00000001/sig00000032 ),
    .Q(p[0])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000016d  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig000000fa ),
    .Q(\blk00000001/sig00000032 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000016c  (
    .C(clk),
    .D(\blk00000001/sig0000003e ),
    .Q(p[2])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  \blk00000001/blk0000016b  (
    .A0(\blk00000001/sig0000004b ),
    .A1(\blk00000001/sig0000004c ),
    .A2(\blk00000001/sig0000004b ),
    .A3(\blk00000001/sig0000004b ),
    .CLK(clk),
    .D(\blk00000001/sig00000110 ),
    .Q(\blk00000001/sig0000003e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000016a  (
    .C(clk),
    .D(\blk00000001/sig00000102 ),
    .Q(\blk00000001/sig0000015b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000169  (
    .C(clk),
    .D(\blk00000001/sig00000103 ),
    .Q(\blk00000001/sig0000015c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000168  (
    .C(clk),
    .D(\blk00000001/sig00000104 ),
    .Q(\blk00000001/sig0000015d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000167  (
    .C(clk),
    .D(\blk00000001/sig00000106 ),
    .Q(\blk00000001/sig0000015e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000166  (
    .C(clk),
    .D(\blk00000001/sig00000107 ),
    .Q(\blk00000001/sig0000015f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000165  (
    .C(clk),
    .D(\blk00000001/sig00000108 ),
    .Q(\blk00000001/sig00000160 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000164  (
    .C(clk),
    .D(\blk00000001/sig00000109 ),
    .Q(\blk00000001/sig00000161 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000163  (
    .C(clk),
    .D(\blk00000001/sig0000010a ),
    .Q(\blk00000001/sig00000162 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000162  (
    .C(clk),
    .D(\blk00000001/sig0000010b ),
    .Q(\blk00000001/sig00000163 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000161  (
    .C(clk),
    .D(\blk00000001/sig0000010c ),
    .Q(\blk00000001/sig00000164 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000160  (
    .C(clk),
    .D(\blk00000001/sig0000010d ),
    .Q(\blk00000001/sig00000165 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000015f  (
    .C(clk),
    .D(\blk00000001/sig0000010e ),
    .Q(\blk00000001/sig00000166 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000015e  (
    .C(clk),
    .D(\blk00000001/sig0000010f ),
    .Q(\blk00000001/sig00000167 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000015d  (
    .C(clk),
    .D(\blk00000001/sig00000111 ),
    .Q(\blk00000001/sig00000168 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000015c  (
    .C(clk),
    .D(\blk00000001/sig00000112 ),
    .Q(\blk00000001/sig00000169 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000015b  (
    .C(clk),
    .D(\blk00000001/sig00000113 ),
    .Q(\blk00000001/sig0000016a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000015a  (
    .C(clk),
    .D(\blk00000001/sig00000114 ),
    .Q(\blk00000001/sig0000016b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000159  (
    .C(clk),
    .D(\blk00000001/sig00000115 ),
    .Q(\blk00000001/sig0000016c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000158  (
    .C(clk),
    .D(\blk00000001/sig0000011d ),
    .Q(\blk00000001/sig0000016d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000157  (
    .C(clk),
    .D(\blk00000001/sig00000128 ),
    .Q(\blk00000001/sig0000016e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000156  (
    .C(clk),
    .D(\blk00000001/sig0000012d ),
    .Q(\blk00000001/sig00000179 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000155  (
    .C(clk),
    .D(\blk00000001/sig0000012e ),
    .Q(\blk00000001/sig0000017e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000154  (
    .C(clk),
    .D(\blk00000001/sig0000012f ),
    .Q(\blk00000001/sig0000017f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000153  (
    .C(clk),
    .D(\blk00000001/sig00000130 ),
    .Q(\blk00000001/sig00000180 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000152  (
    .C(clk),
    .D(\blk00000001/sig00000131 ),
    .Q(\blk00000001/sig00000181 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000151  (
    .C(clk),
    .D(\blk00000001/sig00000132 ),
    .Q(\blk00000001/sig00000182 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000150  (
    .C(clk),
    .D(\blk00000001/sig00000133 ),
    .Q(\blk00000001/sig00000183 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000014f  (
    .C(clk),
    .D(\blk00000001/sig00000134 ),
    .Q(\blk00000001/sig00000184 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000014e  (
    .C(clk),
    .D(\blk00000001/sig0000011e ),
    .Q(\blk00000001/sig0000016f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000014d  (
    .C(clk),
    .D(\blk00000001/sig0000011f ),
    .Q(\blk00000001/sig00000170 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000014c  (
    .C(clk),
    .D(\blk00000001/sig00000120 ),
    .Q(\blk00000001/sig00000171 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000014b  (
    .C(clk),
    .D(\blk00000001/sig00000121 ),
    .Q(\blk00000001/sig00000172 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000014a  (
    .C(clk),
    .D(\blk00000001/sig00000122 ),
    .Q(\blk00000001/sig00000173 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000149  (
    .C(clk),
    .D(\blk00000001/sig00000123 ),
    .Q(\blk00000001/sig00000174 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000148  (
    .C(clk),
    .D(\blk00000001/sig00000124 ),
    .Q(\blk00000001/sig00000175 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000147  (
    .C(clk),
    .D(\blk00000001/sig00000125 ),
    .Q(\blk00000001/sig00000176 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000146  (
    .C(clk),
    .D(\blk00000001/sig00000126 ),
    .Q(\blk00000001/sig00000177 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000145  (
    .C(clk),
    .D(\blk00000001/sig00000127 ),
    .Q(\blk00000001/sig00000178 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000144  (
    .C(clk),
    .D(\blk00000001/sig00000129 ),
    .Q(\blk00000001/sig0000017a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000143  (
    .C(clk),
    .D(\blk00000001/sig0000012a ),
    .Q(\blk00000001/sig0000017b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000142  (
    .C(clk),
    .D(\blk00000001/sig0000012b ),
    .Q(\blk00000001/sig0000017c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000141  (
    .C(clk),
    .D(\blk00000001/sig0000012c ),
    .Q(\blk00000001/sig0000017d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000140  (
    .C(clk),
    .D(\blk00000001/sig0000013d ),
    .Q(\blk00000001/sig00000185 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013f  (
    .C(clk),
    .D(\blk00000001/sig0000013e ),
    .Q(\blk00000001/sig00000186 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013e  (
    .C(clk),
    .D(\blk00000001/sig0000013f ),
    .Q(\blk00000001/sig00000187 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013d  (
    .C(clk),
    .D(\blk00000001/sig00000141 ),
    .Q(\blk00000001/sig00000188 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013c  (
    .C(clk),
    .D(\blk00000001/sig00000142 ),
    .Q(\blk00000001/sig00000189 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013b  (
    .C(clk),
    .D(\blk00000001/sig00000143 ),
    .Q(\blk00000001/sig0000018a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000013a  (
    .C(clk),
    .D(\blk00000001/sig00000144 ),
    .Q(\blk00000001/sig0000018b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000139  (
    .C(clk),
    .D(\blk00000001/sig0000014d ),
    .Q(\blk00000001/sig0000018c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000138  (
    .C(clk),
    .D(\blk00000001/sig00000152 ),
    .Q(\blk00000001/sig0000018d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000137  (
    .C(clk),
    .D(\blk00000001/sig00000153 ),
    .Q(\blk00000001/sig00000192 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000136  (
    .C(clk),
    .D(\blk00000001/sig00000154 ),
    .Q(\blk00000001/sig00000193 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000135  (
    .C(clk),
    .D(\blk00000001/sig00000155 ),
    .Q(\blk00000001/sig00000194 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000134  (
    .C(clk),
    .D(\blk00000001/sig00000156 ),
    .Q(\blk00000001/sig00000195 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000133  (
    .C(clk),
    .D(\blk00000001/sig00000157 ),
    .Q(\blk00000001/sig00000196 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000132  (
    .C(clk),
    .D(\blk00000001/sig00000158 ),
    .Q(\blk00000001/sig00000197 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000131  (
    .C(clk),
    .D(\blk00000001/sig00000159 ),
    .Q(\blk00000001/sig00000198 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000130  (
    .C(clk),
    .D(\blk00000001/sig0000015a ),
    .Q(\blk00000001/sig00000199 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012f  (
    .C(clk),
    .D(\blk00000001/sig0000014e ),
    .Q(\blk00000001/sig0000018e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012e  (
    .C(clk),
    .D(\blk00000001/sig0000014f ),
    .Q(\blk00000001/sig0000018f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012d  (
    .C(clk),
    .D(\blk00000001/sig00000150 ),
    .Q(\blk00000001/sig00000190 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012c  (
    .C(clk),
    .D(\blk00000001/sig00000151 ),
    .Q(\blk00000001/sig00000191 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012b  (
    .C(clk),
    .D(\blk00000001/sig000001ca ),
    .Q(\blk00000001/sig000001d8 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000012a  (
    .C(clk),
    .D(\blk00000001/sig000001cf ),
    .Q(\blk00000001/sig000001d9 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000129  (
    .C(clk),
    .D(\blk00000001/sig000001d0 ),
    .Q(\blk00000001/sig000001de )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000128  (
    .C(clk),
    .D(\blk00000001/sig000001d1 ),
    .Q(\blk00000001/sig000001df )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000127  (
    .C(clk),
    .D(\blk00000001/sig000001d2 ),
    .Q(\blk00000001/sig000001e0 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000126  (
    .C(clk),
    .D(\blk00000001/sig000001d3 ),
    .Q(\blk00000001/sig000001e1 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000125  (
    .C(clk),
    .D(\blk00000001/sig000001d4 ),
    .Q(\blk00000001/sig000001e2 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000124  (
    .C(clk),
    .D(\blk00000001/sig000001d5 ),
    .Q(\blk00000001/sig000001e3 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000123  (
    .C(clk),
    .D(\blk00000001/sig000001d6 ),
    .Q(\blk00000001/sig000001e4 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000122  (
    .C(clk),
    .D(\blk00000001/sig000001d7 ),
    .Q(\blk00000001/sig000001e5 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000121  (
    .C(clk),
    .D(\blk00000001/sig000001cb ),
    .Q(\blk00000001/sig000001da )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000120  (
    .C(clk),
    .D(\blk00000001/sig000001cc ),
    .Q(\blk00000001/sig000001db )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011f  (
    .C(clk),
    .D(\blk00000001/sig000001cd ),
    .Q(\blk00000001/sig000001dc )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011e  (
    .C(clk),
    .D(\blk00000001/sig000001ce ),
    .Q(\blk00000001/sig000001dd )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011d  (
    .C(clk),
    .D(\blk00000001/sig0000019a ),
    .Q(\blk00000001/sig000001b2 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011c  (
    .C(clk),
    .D(\blk00000001/sig000001a5 ),
    .Q(\blk00000001/sig000001b3 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011b  (
    .C(clk),
    .D(\blk00000001/sig000001aa ),
    .Q(\blk00000001/sig000001be )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000011a  (
    .C(clk),
    .D(\blk00000001/sig000001ab ),
    .Q(\blk00000001/sig000001c3 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000119  (
    .C(clk),
    .D(\blk00000001/sig000001ac ),
    .Q(\blk00000001/sig000001c4 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000118  (
    .C(clk),
    .D(\blk00000001/sig000001ad ),
    .Q(\blk00000001/sig000001c5 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000117  (
    .C(clk),
    .D(\blk00000001/sig000001ae ),
    .Q(\blk00000001/sig000001c6 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000116  (
    .C(clk),
    .D(\blk00000001/sig000001af ),
    .Q(\blk00000001/sig000001c7 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000115  (
    .C(clk),
    .D(\blk00000001/sig000001b0 ),
    .Q(\blk00000001/sig000001c8 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000114  (
    .C(clk),
    .D(\blk00000001/sig000001b1 ),
    .Q(\blk00000001/sig000001c9 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000113  (
    .C(clk),
    .D(\blk00000001/sig0000019b ),
    .Q(\blk00000001/sig000001b4 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000112  (
    .C(clk),
    .D(\blk00000001/sig0000019c ),
    .Q(\blk00000001/sig000001b5 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000111  (
    .C(clk),
    .D(\blk00000001/sig0000019d ),
    .Q(\blk00000001/sig000001b6 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000110  (
    .C(clk),
    .D(\blk00000001/sig0000019e ),
    .Q(\blk00000001/sig000001b7 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010f  (
    .C(clk),
    .D(\blk00000001/sig0000019f ),
    .Q(\blk00000001/sig000001b8 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010e  (
    .C(clk),
    .D(\blk00000001/sig000001a0 ),
    .Q(\blk00000001/sig000001b9 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010d  (
    .C(clk),
    .D(\blk00000001/sig000001a1 ),
    .Q(\blk00000001/sig000001ba )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010c  (
    .C(clk),
    .D(\blk00000001/sig000001a2 ),
    .Q(\blk00000001/sig000001bb )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010b  (
    .C(clk),
    .D(\blk00000001/sig000001a3 ),
    .Q(\blk00000001/sig000001bc )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000010a  (
    .C(clk),
    .D(\blk00000001/sig000001a4 ),
    .Q(\blk00000001/sig000001bd )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000109  (
    .C(clk),
    .D(\blk00000001/sig000001a6 ),
    .Q(\blk00000001/sig000001bf )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000108  (
    .C(clk),
    .D(\blk00000001/sig000001a7 ),
    .Q(\blk00000001/sig000001c0 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000107  (
    .C(clk),
    .D(\blk00000001/sig000001a8 ),
    .Q(\blk00000001/sig000001c1 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000106  (
    .C(clk),
    .D(\blk00000001/sig000001a9 ),
    .Q(\blk00000001/sig000001c2 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000105  (
    .C(clk),
    .D(\blk00000001/sig00000203 ),
    .Q(\blk00000001/sig0000021a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000104  (
    .C(clk),
    .D(\blk00000001/sig00000204 ),
    .Q(\blk00000001/sig0000021b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000103  (
    .C(clk),
    .D(\blk00000001/sig000001e7 ),
    .Q(\blk00000001/sig00000205 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000102  (
    .C(clk),
    .D(\blk00000001/sig000001e8 ),
    .Q(\blk00000001/sig00000206 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000101  (
    .C(clk),
    .D(\blk00000001/sig000001e9 ),
    .Q(\blk00000001/sig00000207 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000100  (
    .C(clk),
    .D(\blk00000001/sig000001ea ),
    .Q(\blk00000001/sig00000208 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ff  (
    .C(clk),
    .D(\blk00000001/sig000001eb ),
    .Q(\blk00000001/sig00000209 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fe  (
    .C(clk),
    .D(\blk00000001/sig000001ec ),
    .Q(\blk00000001/sig0000020a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fd  (
    .C(clk),
    .D(\blk00000001/sig000001ed ),
    .Q(\blk00000001/sig0000020b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fc  (
    .C(clk),
    .D(\blk00000001/sig000001ee ),
    .Q(\blk00000001/sig0000020c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fb  (
    .C(clk),
    .D(\blk00000001/sig000001ef ),
    .Q(\blk00000001/sig0000020d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000fa  (
    .C(clk),
    .D(\blk00000001/sig000001f0 ),
    .Q(\blk00000001/sig0000020e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f9  (
    .C(clk),
    .D(\blk00000001/sig000001f2 ),
    .Q(\blk00000001/sig0000020f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f8  (
    .C(clk),
    .D(\blk00000001/sig000001f3 ),
    .Q(\blk00000001/sig00000210 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f7  (
    .C(clk),
    .D(\blk00000001/sig000001f4 ),
    .Q(\blk00000001/sig00000211 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f6  (
    .C(clk),
    .D(\blk00000001/sig000001f5 ),
    .Q(\blk00000001/sig00000212 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f5  (
    .C(clk),
    .D(\blk00000001/sig000001f6 ),
    .Q(\blk00000001/sig00000213 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f4  (
    .C(clk),
    .D(\blk00000001/sig000001f7 ),
    .Q(\blk00000001/sig00000214 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f3  (
    .C(clk),
    .D(\blk00000001/sig000001f8 ),
    .Q(\blk00000001/sig00000215 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f2  (
    .C(clk),
    .D(\blk00000001/sig000001f9 ),
    .Q(\blk00000001/sig00000216 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f1  (
    .C(clk),
    .D(\blk00000001/sig000001fa ),
    .Q(\blk00000001/sig00000217 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000f0  (
    .C(clk),
    .D(\blk00000001/sig000001fb ),
    .Q(\blk00000001/sig00000218 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk000000ef  (
    .C(clk),
    .D(\blk00000001/sig000001ff ),
    .Q(\blk00000001/sig00000219 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ee  (
    .I0(\blk00000001/sig00000185 ),
    .I1(\blk00000001/sig0000018c ),
    .O(\blk00000001/sig00000089 )
  );
  MUXCY   \blk00000001/blk000000ed  (
    .CI(\blk00000001/sig0000004b ),
    .DI(\blk00000001/sig00000185 ),
    .S(\blk00000001/sig00000089 ),
    .O(\blk00000001/sig0000007c )
  );
  XORCY   \blk00000001/blk000000ec  (
    .CI(\blk00000001/sig0000004b ),
    .LI(\blk00000001/sig00000089 ),
    .O(\blk00000001/sig000001ca )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000eb  (
    .I0(\blk00000001/sig00000186 ),
    .I1(\blk00000001/sig0000018d ),
    .O(\blk00000001/sig0000008e )
  );
  MUXCY   \blk00000001/blk000000ea  (
    .CI(\blk00000001/sig0000007c ),
    .DI(\blk00000001/sig00000186 ),
    .S(\blk00000001/sig0000008e ),
    .O(\blk00000001/sig00000080 )
  );
  XORCY   \blk00000001/blk000000e9  (
    .CI(\blk00000001/sig0000007c ),
    .LI(\blk00000001/sig0000008e ),
    .O(\blk00000001/sig000001cf )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000e8  (
    .I0(\blk00000001/sig00000187 ),
    .I1(\blk00000001/sig00000192 ),
    .O(\blk00000001/sig0000008f )
  );
  MUXCY   \blk00000001/blk000000e7  (
    .CI(\blk00000001/sig00000080 ),
    .DI(\blk00000001/sig00000187 ),
    .S(\blk00000001/sig0000008f ),
    .O(\blk00000001/sig00000081 )
  );
  XORCY   \blk00000001/blk000000e6  (
    .CI(\blk00000001/sig00000080 ),
    .LI(\blk00000001/sig0000008f ),
    .O(\blk00000001/sig000001d0 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000e5  (
    .I0(\blk00000001/sig00000188 ),
    .I1(\blk00000001/sig00000193 ),
    .O(\blk00000001/sig00000090 )
  );
  MUXCY   \blk00000001/blk000000e4  (
    .CI(\blk00000001/sig00000081 ),
    .DI(\blk00000001/sig00000188 ),
    .S(\blk00000001/sig00000090 ),
    .O(\blk00000001/sig00000082 )
  );
  XORCY   \blk00000001/blk000000e3  (
    .CI(\blk00000001/sig00000081 ),
    .LI(\blk00000001/sig00000090 ),
    .O(\blk00000001/sig000001d1 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000e2  (
    .I0(\blk00000001/sig00000189 ),
    .I1(\blk00000001/sig00000194 ),
    .O(\blk00000001/sig00000091 )
  );
  MUXCY   \blk00000001/blk000000e1  (
    .CI(\blk00000001/sig00000082 ),
    .DI(\blk00000001/sig00000189 ),
    .S(\blk00000001/sig00000091 ),
    .O(\blk00000001/sig00000083 )
  );
  XORCY   \blk00000001/blk000000e0  (
    .CI(\blk00000001/sig00000082 ),
    .LI(\blk00000001/sig00000091 ),
    .O(\blk00000001/sig000001d2 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000df  (
    .I0(\blk00000001/sig0000018a ),
    .I1(\blk00000001/sig00000195 ),
    .O(\blk00000001/sig00000092 )
  );
  MUXCY   \blk00000001/blk000000de  (
    .CI(\blk00000001/sig00000083 ),
    .DI(\blk00000001/sig0000018a ),
    .S(\blk00000001/sig00000092 ),
    .O(\blk00000001/sig00000084 )
  );
  XORCY   \blk00000001/blk000000dd  (
    .CI(\blk00000001/sig00000083 ),
    .LI(\blk00000001/sig00000092 ),
    .O(\blk00000001/sig000001d3 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000dc  (
    .I0(\blk00000001/sig0000018b ),
    .I1(\blk00000001/sig00000196 ),
    .O(\blk00000001/sig00000093 )
  );
  MUXCY   \blk00000001/blk000000db  (
    .CI(\blk00000001/sig00000084 ),
    .DI(\blk00000001/sig0000018b ),
    .S(\blk00000001/sig00000093 ),
    .O(\blk00000001/sig00000085 )
  );
  XORCY   \blk00000001/blk000000da  (
    .CI(\blk00000001/sig00000084 ),
    .LI(\blk00000001/sig00000093 ),
    .O(\blk00000001/sig000001d4 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000d9  (
    .I0(\blk00000001/sig0000018b ),
    .I1(\blk00000001/sig00000197 ),
    .O(\blk00000001/sig00000094 )
  );
  MUXCY   \blk00000001/blk000000d8  (
    .CI(\blk00000001/sig00000085 ),
    .DI(\blk00000001/sig0000018b ),
    .S(\blk00000001/sig00000094 ),
    .O(\blk00000001/sig00000086 )
  );
  XORCY   \blk00000001/blk000000d7  (
    .CI(\blk00000001/sig00000085 ),
    .LI(\blk00000001/sig00000094 ),
    .O(\blk00000001/sig000001d5 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000d6  (
    .I0(\blk00000001/sig0000018b ),
    .I1(\blk00000001/sig00000198 ),
    .O(\blk00000001/sig00000095 )
  );
  MUXCY   \blk00000001/blk000000d5  (
    .CI(\blk00000001/sig00000086 ),
    .DI(\blk00000001/sig0000018b ),
    .S(\blk00000001/sig00000095 ),
    .O(\blk00000001/sig00000087 )
  );
  XORCY   \blk00000001/blk000000d4  (
    .CI(\blk00000001/sig00000086 ),
    .LI(\blk00000001/sig00000095 ),
    .O(\blk00000001/sig000001d6 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000d3  (
    .I0(\blk00000001/sig0000018b ),
    .I1(\blk00000001/sig00000199 ),
    .O(\blk00000001/sig00000096 )
  );
  MUXCY   \blk00000001/blk000000d2  (
    .CI(\blk00000001/sig00000087 ),
    .DI(\blk00000001/sig0000018b ),
    .S(\blk00000001/sig00000096 ),
    .O(\blk00000001/sig00000088 )
  );
  XORCY   \blk00000001/blk000000d1  (
    .CI(\blk00000001/sig00000087 ),
    .LI(\blk00000001/sig00000096 ),
    .O(\blk00000001/sig000001d7 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000d0  (
    .I0(\blk00000001/sig0000018b ),
    .I1(\blk00000001/sig0000018e ),
    .O(\blk00000001/sig0000008a )
  );
  MUXCY   \blk00000001/blk000000cf  (
    .CI(\blk00000001/sig00000088 ),
    .DI(\blk00000001/sig0000018b ),
    .S(\blk00000001/sig0000008a ),
    .O(\blk00000001/sig0000007d )
  );
  XORCY   \blk00000001/blk000000ce  (
    .CI(\blk00000001/sig00000088 ),
    .LI(\blk00000001/sig0000008a ),
    .O(\blk00000001/sig000001cb )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000cd  (
    .I0(\blk00000001/sig0000018b ),
    .I1(\blk00000001/sig0000018f ),
    .O(\blk00000001/sig0000008b )
  );
  MUXCY   \blk00000001/blk000000cc  (
    .CI(\blk00000001/sig0000007d ),
    .DI(\blk00000001/sig0000018b ),
    .S(\blk00000001/sig0000008b ),
    .O(\blk00000001/sig0000007e )
  );
  XORCY   \blk00000001/blk000000cb  (
    .CI(\blk00000001/sig0000007d ),
    .LI(\blk00000001/sig0000008b ),
    .O(\blk00000001/sig000001cc )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ca  (
    .I0(\blk00000001/sig0000018b ),
    .I1(\blk00000001/sig00000190 ),
    .O(\blk00000001/sig0000008c )
  );
  MUXCY   \blk00000001/blk000000c9  (
    .CI(\blk00000001/sig0000007e ),
    .DI(\blk00000001/sig0000018b ),
    .S(\blk00000001/sig0000008c ),
    .O(\blk00000001/sig0000007f )
  );
  XORCY   \blk00000001/blk000000c8  (
    .CI(\blk00000001/sig0000007e ),
    .LI(\blk00000001/sig0000008c ),
    .O(\blk00000001/sig000001cd )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c7  (
    .I0(\blk00000001/sig0000018b ),
    .I1(\blk00000001/sig00000191 ),
    .O(\blk00000001/sig0000008d )
  );
  XORCY   \blk00000001/blk000000c6  (
    .CI(\blk00000001/sig0000007f ),
    .LI(\blk00000001/sig0000008d ),
    .O(\blk00000001/sig000001ce )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c5  (
    .I0(\blk00000001/sig0000015b ),
    .I1(\blk00000001/sig0000016d ),
    .O(\blk00000001/sig00000064 )
  );
  MUXCY   \blk00000001/blk000000c4  (
    .CI(\blk00000001/sig0000004b ),
    .DI(\blk00000001/sig0000015b ),
    .S(\blk00000001/sig00000064 ),
    .O(\blk00000001/sig0000004d )
  );
  XORCY   \blk00000001/blk000000c3  (
    .CI(\blk00000001/sig0000004b ),
    .LI(\blk00000001/sig00000064 ),
    .O(\blk00000001/sig0000019a )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c2  (
    .I0(\blk00000001/sig0000015c ),
    .I1(\blk00000001/sig0000016e ),
    .O(\blk00000001/sig0000006f )
  );
  MUXCY   \blk00000001/blk000000c1  (
    .CI(\blk00000001/sig0000004d ),
    .DI(\blk00000001/sig0000015c ),
    .S(\blk00000001/sig0000006f ),
    .O(\blk00000001/sig00000058 )
  );
  XORCY   \blk00000001/blk000000c0  (
    .CI(\blk00000001/sig0000004d ),
    .LI(\blk00000001/sig0000006f ),
    .O(\blk00000001/sig000001a5 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000bf  (
    .I0(\blk00000001/sig0000015d ),
    .I1(\blk00000001/sig00000179 ),
    .O(\blk00000001/sig00000074 )
  );
  MUXCY   \blk00000001/blk000000be  (
    .CI(\blk00000001/sig00000058 ),
    .DI(\blk00000001/sig0000015d ),
    .S(\blk00000001/sig00000074 ),
    .O(\blk00000001/sig0000005c )
  );
  XORCY   \blk00000001/blk000000bd  (
    .CI(\blk00000001/sig00000058 ),
    .LI(\blk00000001/sig00000074 ),
    .O(\blk00000001/sig000001aa )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000bc  (
    .I0(\blk00000001/sig0000015e ),
    .I1(\blk00000001/sig0000017e ),
    .O(\blk00000001/sig00000075 )
  );
  MUXCY   \blk00000001/blk000000bb  (
    .CI(\blk00000001/sig0000005c ),
    .DI(\blk00000001/sig0000015e ),
    .S(\blk00000001/sig00000075 ),
    .O(\blk00000001/sig0000005d )
  );
  XORCY   \blk00000001/blk000000ba  (
    .CI(\blk00000001/sig0000005c ),
    .LI(\blk00000001/sig00000075 ),
    .O(\blk00000001/sig000001ab )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b9  (
    .I0(\blk00000001/sig0000015f ),
    .I1(\blk00000001/sig0000017f ),
    .O(\blk00000001/sig00000076 )
  );
  MUXCY   \blk00000001/blk000000b8  (
    .CI(\blk00000001/sig0000005d ),
    .DI(\blk00000001/sig0000015f ),
    .S(\blk00000001/sig00000076 ),
    .O(\blk00000001/sig0000005e )
  );
  XORCY   \blk00000001/blk000000b7  (
    .CI(\blk00000001/sig0000005d ),
    .LI(\blk00000001/sig00000076 ),
    .O(\blk00000001/sig000001ac )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b6  (
    .I0(\blk00000001/sig00000160 ),
    .I1(\blk00000001/sig00000180 ),
    .O(\blk00000001/sig00000077 )
  );
  MUXCY   \blk00000001/blk000000b5  (
    .CI(\blk00000001/sig0000005e ),
    .DI(\blk00000001/sig00000160 ),
    .S(\blk00000001/sig00000077 ),
    .O(\blk00000001/sig0000005f )
  );
  XORCY   \blk00000001/blk000000b4  (
    .CI(\blk00000001/sig0000005e ),
    .LI(\blk00000001/sig00000077 ),
    .O(\blk00000001/sig000001ad )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b3  (
    .I0(\blk00000001/sig00000161 ),
    .I1(\blk00000001/sig00000181 ),
    .O(\blk00000001/sig00000078 )
  );
  MUXCY   \blk00000001/blk000000b2  (
    .CI(\blk00000001/sig0000005f ),
    .DI(\blk00000001/sig00000161 ),
    .S(\blk00000001/sig00000078 ),
    .O(\blk00000001/sig00000060 )
  );
  XORCY   \blk00000001/blk000000b1  (
    .CI(\blk00000001/sig0000005f ),
    .LI(\blk00000001/sig00000078 ),
    .O(\blk00000001/sig000001ae )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b0  (
    .I0(\blk00000001/sig00000162 ),
    .I1(\blk00000001/sig00000182 ),
    .O(\blk00000001/sig00000079 )
  );
  MUXCY   \blk00000001/blk000000af  (
    .CI(\blk00000001/sig00000060 ),
    .DI(\blk00000001/sig00000162 ),
    .S(\blk00000001/sig00000079 ),
    .O(\blk00000001/sig00000061 )
  );
  XORCY   \blk00000001/blk000000ae  (
    .CI(\blk00000001/sig00000060 ),
    .LI(\blk00000001/sig00000079 ),
    .O(\blk00000001/sig000001af )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ad  (
    .I0(\blk00000001/sig00000163 ),
    .I1(\blk00000001/sig00000183 ),
    .O(\blk00000001/sig0000007a )
  );
  MUXCY   \blk00000001/blk000000ac  (
    .CI(\blk00000001/sig00000061 ),
    .DI(\blk00000001/sig00000163 ),
    .S(\blk00000001/sig0000007a ),
    .O(\blk00000001/sig00000062 )
  );
  XORCY   \blk00000001/blk000000ab  (
    .CI(\blk00000001/sig00000061 ),
    .LI(\blk00000001/sig0000007a ),
    .O(\blk00000001/sig000001b0 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000aa  (
    .I0(\blk00000001/sig00000164 ),
    .I1(\blk00000001/sig00000184 ),
    .O(\blk00000001/sig0000007b )
  );
  MUXCY   \blk00000001/blk000000a9  (
    .CI(\blk00000001/sig00000062 ),
    .DI(\blk00000001/sig00000164 ),
    .S(\blk00000001/sig0000007b ),
    .O(\blk00000001/sig00000063 )
  );
  XORCY   \blk00000001/blk000000a8  (
    .CI(\blk00000001/sig00000062 ),
    .LI(\blk00000001/sig0000007b ),
    .O(\blk00000001/sig000001b1 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a7  (
    .I0(\blk00000001/sig00000165 ),
    .I1(\blk00000001/sig0000016f ),
    .O(\blk00000001/sig00000065 )
  );
  MUXCY   \blk00000001/blk000000a6  (
    .CI(\blk00000001/sig00000063 ),
    .DI(\blk00000001/sig00000165 ),
    .S(\blk00000001/sig00000065 ),
    .O(\blk00000001/sig0000004e )
  );
  XORCY   \blk00000001/blk000000a5  (
    .CI(\blk00000001/sig00000063 ),
    .LI(\blk00000001/sig00000065 ),
    .O(\blk00000001/sig0000019b )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a4  (
    .I0(\blk00000001/sig00000166 ),
    .I1(\blk00000001/sig00000170 ),
    .O(\blk00000001/sig00000066 )
  );
  MUXCY   \blk00000001/blk000000a3  (
    .CI(\blk00000001/sig0000004e ),
    .DI(\blk00000001/sig00000166 ),
    .S(\blk00000001/sig00000066 ),
    .O(\blk00000001/sig0000004f )
  );
  XORCY   \blk00000001/blk000000a2  (
    .CI(\blk00000001/sig0000004e ),
    .LI(\blk00000001/sig00000066 ),
    .O(\blk00000001/sig0000019c )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a1  (
    .I0(\blk00000001/sig00000167 ),
    .I1(\blk00000001/sig00000171 ),
    .O(\blk00000001/sig00000067 )
  );
  MUXCY   \blk00000001/blk000000a0  (
    .CI(\blk00000001/sig0000004f ),
    .DI(\blk00000001/sig00000167 ),
    .S(\blk00000001/sig00000067 ),
    .O(\blk00000001/sig00000050 )
  );
  XORCY   \blk00000001/blk0000009f  (
    .CI(\blk00000001/sig0000004f ),
    .LI(\blk00000001/sig00000067 ),
    .O(\blk00000001/sig0000019d )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009e  (
    .I0(\blk00000001/sig00000168 ),
    .I1(\blk00000001/sig00000172 ),
    .O(\blk00000001/sig00000068 )
  );
  MUXCY   \blk00000001/blk0000009d  (
    .CI(\blk00000001/sig00000050 ),
    .DI(\blk00000001/sig00000168 ),
    .S(\blk00000001/sig00000068 ),
    .O(\blk00000001/sig00000051 )
  );
  XORCY   \blk00000001/blk0000009c  (
    .CI(\blk00000001/sig00000050 ),
    .LI(\blk00000001/sig00000068 ),
    .O(\blk00000001/sig0000019e )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009b  (
    .I0(\blk00000001/sig00000169 ),
    .I1(\blk00000001/sig00000173 ),
    .O(\blk00000001/sig00000069 )
  );
  MUXCY   \blk00000001/blk0000009a  (
    .CI(\blk00000001/sig00000051 ),
    .DI(\blk00000001/sig00000169 ),
    .S(\blk00000001/sig00000069 ),
    .O(\blk00000001/sig00000052 )
  );
  XORCY   \blk00000001/blk00000099  (
    .CI(\blk00000001/sig00000051 ),
    .LI(\blk00000001/sig00000069 ),
    .O(\blk00000001/sig0000019f )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000098  (
    .I0(\blk00000001/sig0000016a ),
    .I1(\blk00000001/sig00000174 ),
    .O(\blk00000001/sig0000006a )
  );
  MUXCY   \blk00000001/blk00000097  (
    .CI(\blk00000001/sig00000052 ),
    .DI(\blk00000001/sig0000016a ),
    .S(\blk00000001/sig0000006a ),
    .O(\blk00000001/sig00000053 )
  );
  XORCY   \blk00000001/blk00000096  (
    .CI(\blk00000001/sig00000052 ),
    .LI(\blk00000001/sig0000006a ),
    .O(\blk00000001/sig000001a0 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000095  (
    .I0(\blk00000001/sig0000016b ),
    .I1(\blk00000001/sig00000175 ),
    .O(\blk00000001/sig0000006b )
  );
  MUXCY   \blk00000001/blk00000094  (
    .CI(\blk00000001/sig00000053 ),
    .DI(\blk00000001/sig0000016b ),
    .S(\blk00000001/sig0000006b ),
    .O(\blk00000001/sig00000054 )
  );
  XORCY   \blk00000001/blk00000093  (
    .CI(\blk00000001/sig00000053 ),
    .LI(\blk00000001/sig0000006b ),
    .O(\blk00000001/sig000001a1 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000092  (
    .I0(\blk00000001/sig0000016c ),
    .I1(\blk00000001/sig00000176 ),
    .O(\blk00000001/sig0000006c )
  );
  MUXCY   \blk00000001/blk00000091  (
    .CI(\blk00000001/sig00000054 ),
    .DI(\blk00000001/sig0000016c ),
    .S(\blk00000001/sig0000006c ),
    .O(\blk00000001/sig00000055 )
  );
  XORCY   \blk00000001/blk00000090  (
    .CI(\blk00000001/sig00000054 ),
    .LI(\blk00000001/sig0000006c ),
    .O(\blk00000001/sig000001a2 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000008f  (
    .I0(\blk00000001/sig0000016c ),
    .I1(\blk00000001/sig00000177 ),
    .O(\blk00000001/sig0000006d )
  );
  MUXCY   \blk00000001/blk0000008e  (
    .CI(\blk00000001/sig00000055 ),
    .DI(\blk00000001/sig0000016c ),
    .S(\blk00000001/sig0000006d ),
    .O(\blk00000001/sig00000056 )
  );
  XORCY   \blk00000001/blk0000008d  (
    .CI(\blk00000001/sig00000055 ),
    .LI(\blk00000001/sig0000006d ),
    .O(\blk00000001/sig000001a3 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000008c  (
    .I0(\blk00000001/sig0000016c ),
    .I1(\blk00000001/sig00000178 ),
    .O(\blk00000001/sig0000006e )
  );
  MUXCY   \blk00000001/blk0000008b  (
    .CI(\blk00000001/sig00000056 ),
    .DI(\blk00000001/sig0000016c ),
    .S(\blk00000001/sig0000006e ),
    .O(\blk00000001/sig00000057 )
  );
  XORCY   \blk00000001/blk0000008a  (
    .CI(\blk00000001/sig00000056 ),
    .LI(\blk00000001/sig0000006e ),
    .O(\blk00000001/sig000001a4 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000089  (
    .I0(\blk00000001/sig0000016c ),
    .I1(\blk00000001/sig0000017a ),
    .O(\blk00000001/sig00000070 )
  );
  MUXCY   \blk00000001/blk00000088  (
    .CI(\blk00000001/sig00000057 ),
    .DI(\blk00000001/sig0000016c ),
    .S(\blk00000001/sig00000070 ),
    .O(\blk00000001/sig00000059 )
  );
  XORCY   \blk00000001/blk00000087  (
    .CI(\blk00000001/sig00000057 ),
    .LI(\blk00000001/sig00000070 ),
    .O(\blk00000001/sig000001a6 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000086  (
    .I0(\blk00000001/sig0000016c ),
    .I1(\blk00000001/sig0000017b ),
    .O(\blk00000001/sig00000071 )
  );
  MUXCY   \blk00000001/blk00000085  (
    .CI(\blk00000001/sig00000059 ),
    .DI(\blk00000001/sig0000016c ),
    .S(\blk00000001/sig00000071 ),
    .O(\blk00000001/sig0000005a )
  );
  XORCY   \blk00000001/blk00000084  (
    .CI(\blk00000001/sig00000059 ),
    .LI(\blk00000001/sig00000071 ),
    .O(\blk00000001/sig000001a7 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000083  (
    .I0(\blk00000001/sig0000016c ),
    .I1(\blk00000001/sig0000017c ),
    .O(\blk00000001/sig00000072 )
  );
  MUXCY   \blk00000001/blk00000082  (
    .CI(\blk00000001/sig0000005a ),
    .DI(\blk00000001/sig0000016c ),
    .S(\blk00000001/sig00000072 ),
    .O(\blk00000001/sig0000005b )
  );
  XORCY   \blk00000001/blk00000081  (
    .CI(\blk00000001/sig0000005a ),
    .LI(\blk00000001/sig00000072 ),
    .O(\blk00000001/sig000001a8 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000080  (
    .I0(\blk00000001/sig0000016c ),
    .I1(\blk00000001/sig0000017d ),
    .O(\blk00000001/sig00000073 )
  );
  XORCY   \blk00000001/blk0000007f  (
    .CI(\blk00000001/sig0000005b ),
    .LI(\blk00000001/sig00000073 ),
    .O(\blk00000001/sig000001a9 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000007e  (
    .I0(\blk00000001/sig000001b2 ),
    .I1(\blk00000001/sig000000e9 ),
    .O(\blk00000001/sig000000b7 )
  );
  MUXCY   \blk00000001/blk0000007d  (
    .CI(\blk00000001/sig0000004b ),
    .DI(\blk00000001/sig000001b2 ),
    .S(\blk00000001/sig000000b7 ),
    .O(\blk00000001/sig00000097 )
  );
  XORCY   \blk00000001/blk0000007c  (
    .CI(\blk00000001/sig0000004b ),
    .LI(\blk00000001/sig000000b7 ),
    .O(\blk00000001/sig000001e6 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000007b  (
    .I0(\blk00000001/sig000001b3 ),
    .I1(\blk00000001/sig000000ea ),
    .O(\blk00000001/sig000000c2 )
  );
  MUXCY   \blk00000001/blk0000007a  (
    .CI(\blk00000001/sig00000097 ),
    .DI(\blk00000001/sig000001b3 ),
    .S(\blk00000001/sig000000c2 ),
    .O(\blk00000001/sig000000a2 )
  );
  XORCY   \blk00000001/blk00000079  (
    .CI(\blk00000001/sig00000097 ),
    .LI(\blk00000001/sig000000c2 ),
    .O(\blk00000001/sig000001f1 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000078  (
    .I0(\blk00000001/sig000001be ),
    .I1(\blk00000001/sig000000f2 ),
    .O(\blk00000001/sig000000cd )
  );
  MUXCY   \blk00000001/blk00000077  (
    .CI(\blk00000001/sig000000a2 ),
    .DI(\blk00000001/sig000001be ),
    .S(\blk00000001/sig000000cd ),
    .O(\blk00000001/sig000000ad )
  );
  XORCY   \blk00000001/blk00000076  (
    .CI(\blk00000001/sig000000a2 ),
    .LI(\blk00000001/sig000000cd ),
    .O(\blk00000001/sig000001fc )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000075  (
    .I0(\blk00000001/sig000001c3 ),
    .I1(\blk00000001/sig000000f3 ),
    .O(\blk00000001/sig000000d1 )
  );
  MUXCY   \blk00000001/blk00000074  (
    .CI(\blk00000001/sig000000ad ),
    .DI(\blk00000001/sig000001c3 ),
    .S(\blk00000001/sig000000d1 ),
    .O(\blk00000001/sig000000b0 )
  );
  XORCY   \blk00000001/blk00000073  (
    .CI(\blk00000001/sig000000ad ),
    .LI(\blk00000001/sig000000d1 ),
    .O(\blk00000001/sig000001fd )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000072  (
    .I0(\blk00000001/sig000001c4 ),
    .I1(\blk00000001/sig000000f4 ),
    .O(\blk00000001/sig000000d2 )
  );
  MUXCY   \blk00000001/blk00000071  (
    .CI(\blk00000001/sig000000b0 ),
    .DI(\blk00000001/sig000001c4 ),
    .S(\blk00000001/sig000000d2 ),
    .O(\blk00000001/sig000000b1 )
  );
  XORCY   \blk00000001/blk00000070  (
    .CI(\blk00000001/sig000000b0 ),
    .LI(\blk00000001/sig000000d2 ),
    .O(\blk00000001/sig000001fe )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000006f  (
    .I0(\blk00000001/sig000001c5 ),
    .I1(\blk00000001/sig000000f5 ),
    .O(\blk00000001/sig000000d3 )
  );
  MUXCY   \blk00000001/blk0000006e  (
    .CI(\blk00000001/sig000000b1 ),
    .DI(\blk00000001/sig000001c5 ),
    .S(\blk00000001/sig000000d3 ),
    .O(\blk00000001/sig000000b2 )
  );
  XORCY   \blk00000001/blk0000006d  (
    .CI(\blk00000001/sig000000b1 ),
    .LI(\blk00000001/sig000000d3 ),
    .O(\blk00000001/sig00000200 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000006c  (
    .I0(\blk00000001/sig000001c6 ),
    .I1(\blk00000001/sig000000f6 ),
    .O(\blk00000001/sig000000d4 )
  );
  MUXCY   \blk00000001/blk0000006b  (
    .CI(\blk00000001/sig000000b2 ),
    .DI(\blk00000001/sig000001c6 ),
    .S(\blk00000001/sig000000d4 ),
    .O(\blk00000001/sig000000b3 )
  );
  XORCY   \blk00000001/blk0000006a  (
    .CI(\blk00000001/sig000000b2 ),
    .LI(\blk00000001/sig000000d4 ),
    .O(\blk00000001/sig00000201 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000069  (
    .I0(\blk00000001/sig000001c7 ),
    .I1(\blk00000001/sig000000f7 ),
    .O(\blk00000001/sig000000d5 )
  );
  MUXCY   \blk00000001/blk00000068  (
    .CI(\blk00000001/sig000000b3 ),
    .DI(\blk00000001/sig000001c7 ),
    .S(\blk00000001/sig000000d5 ),
    .O(\blk00000001/sig000000b4 )
  );
  XORCY   \blk00000001/blk00000067  (
    .CI(\blk00000001/sig000000b3 ),
    .LI(\blk00000001/sig000000d5 ),
    .O(\blk00000001/sig00000202 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000066  (
    .I0(\blk00000001/sig000001c8 ),
    .I1(\blk00000001/sig000000f8 ),
    .O(\blk00000001/sig000000d6 )
  );
  MUXCY   \blk00000001/blk00000065  (
    .CI(\blk00000001/sig000000b4 ),
    .DI(\blk00000001/sig000001c8 ),
    .S(\blk00000001/sig000000d6 ),
    .O(\blk00000001/sig000000b5 )
  );
  XORCY   \blk00000001/blk00000064  (
    .CI(\blk00000001/sig000000b4 ),
    .LI(\blk00000001/sig000000d6 ),
    .O(\blk00000001/sig00000203 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000063  (
    .I0(\blk00000001/sig000001c9 ),
    .I1(\blk00000001/sig000000f9 ),
    .O(\blk00000001/sig000000d7 )
  );
  MUXCY   \blk00000001/blk00000062  (
    .CI(\blk00000001/sig000000b5 ),
    .DI(\blk00000001/sig000001c9 ),
    .S(\blk00000001/sig000000d7 ),
    .O(\blk00000001/sig000000b6 )
  );
  XORCY   \blk00000001/blk00000061  (
    .CI(\blk00000001/sig000000b5 ),
    .LI(\blk00000001/sig000000d7 ),
    .O(\blk00000001/sig00000204 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000060  (
    .I0(\blk00000001/sig000001b4 ),
    .I1(\blk00000001/sig000000eb ),
    .O(\blk00000001/sig000000b8 )
  );
  MUXCY   \blk00000001/blk0000005f  (
    .CI(\blk00000001/sig000000b6 ),
    .DI(\blk00000001/sig000001b4 ),
    .S(\blk00000001/sig000000b8 ),
    .O(\blk00000001/sig00000098 )
  );
  XORCY   \blk00000001/blk0000005e  (
    .CI(\blk00000001/sig000000b6 ),
    .LI(\blk00000001/sig000000b8 ),
    .O(\blk00000001/sig000001e7 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000005d  (
    .I0(\blk00000001/sig000001b5 ),
    .I1(\blk00000001/sig000000ec ),
    .O(\blk00000001/sig000000b9 )
  );
  MUXCY   \blk00000001/blk0000005c  (
    .CI(\blk00000001/sig00000098 ),
    .DI(\blk00000001/sig000001b5 ),
    .S(\blk00000001/sig000000b9 ),
    .O(\blk00000001/sig00000099 )
  );
  XORCY   \blk00000001/blk0000005b  (
    .CI(\blk00000001/sig00000098 ),
    .LI(\blk00000001/sig000000b9 ),
    .O(\blk00000001/sig000001e8 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000005a  (
    .I0(\blk00000001/sig000001b6 ),
    .I1(\blk00000001/sig000000ed ),
    .O(\blk00000001/sig000000ba )
  );
  MUXCY   \blk00000001/blk00000059  (
    .CI(\blk00000001/sig00000099 ),
    .DI(\blk00000001/sig000001b6 ),
    .S(\blk00000001/sig000000ba ),
    .O(\blk00000001/sig0000009a )
  );
  XORCY   \blk00000001/blk00000058  (
    .CI(\blk00000001/sig00000099 ),
    .LI(\blk00000001/sig000000ba ),
    .O(\blk00000001/sig000001e9 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000057  (
    .I0(\blk00000001/sig000001b7 ),
    .I1(\blk00000001/sig000000ee ),
    .O(\blk00000001/sig000000bb )
  );
  MUXCY   \blk00000001/blk00000056  (
    .CI(\blk00000001/sig0000009a ),
    .DI(\blk00000001/sig000001b7 ),
    .S(\blk00000001/sig000000bb ),
    .O(\blk00000001/sig0000009b )
  );
  XORCY   \blk00000001/blk00000055  (
    .CI(\blk00000001/sig0000009a ),
    .LI(\blk00000001/sig000000bb ),
    .O(\blk00000001/sig000001ea )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000054  (
    .I0(\blk00000001/sig000001b8 ),
    .I1(\blk00000001/sig000000ef ),
    .O(\blk00000001/sig000000bc )
  );
  MUXCY   \blk00000001/blk00000053  (
    .CI(\blk00000001/sig0000009b ),
    .DI(\blk00000001/sig000001b8 ),
    .S(\blk00000001/sig000000bc ),
    .O(\blk00000001/sig0000009c )
  );
  XORCY   \blk00000001/blk00000052  (
    .CI(\blk00000001/sig0000009b ),
    .LI(\blk00000001/sig000000bc ),
    .O(\blk00000001/sig000001eb )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000051  (
    .I0(\blk00000001/sig000001b9 ),
    .I1(\blk00000001/sig000000f0 ),
    .O(\blk00000001/sig000000bd )
  );
  MUXCY   \blk00000001/blk00000050  (
    .CI(\blk00000001/sig0000009c ),
    .DI(\blk00000001/sig000001b9 ),
    .S(\blk00000001/sig000000bd ),
    .O(\blk00000001/sig0000009d )
  );
  XORCY   \blk00000001/blk0000004f  (
    .CI(\blk00000001/sig0000009c ),
    .LI(\blk00000001/sig000000bd ),
    .O(\blk00000001/sig000001ec )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000004e  (
    .I0(\blk00000001/sig000001ba ),
    .I1(\blk00000001/sig000000f1 ),
    .O(\blk00000001/sig000000be )
  );
  MUXCY   \blk00000001/blk0000004d  (
    .CI(\blk00000001/sig0000009d ),
    .DI(\blk00000001/sig000001ba ),
    .S(\blk00000001/sig000000be ),
    .O(\blk00000001/sig0000009e )
  );
  XORCY   \blk00000001/blk0000004c  (
    .CI(\blk00000001/sig0000009d ),
    .LI(\blk00000001/sig000000be ),
    .O(\blk00000001/sig000001ed )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000004b  (
    .I0(\blk00000001/sig000001bb ),
    .I1(\blk00000001/sig000001d8 ),
    .O(\blk00000001/sig000000bf )
  );
  MUXCY   \blk00000001/blk0000004a  (
    .CI(\blk00000001/sig0000009e ),
    .DI(\blk00000001/sig000001bb ),
    .S(\blk00000001/sig000000bf ),
    .O(\blk00000001/sig0000009f )
  );
  XORCY   \blk00000001/blk00000049  (
    .CI(\blk00000001/sig0000009e ),
    .LI(\blk00000001/sig000000bf ),
    .O(\blk00000001/sig000001ee )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000048  (
    .I0(\blk00000001/sig000001bc ),
    .I1(\blk00000001/sig000001d9 ),
    .O(\blk00000001/sig000000c0 )
  );
  MUXCY   \blk00000001/blk00000047  (
    .CI(\blk00000001/sig0000009f ),
    .DI(\blk00000001/sig000001bc ),
    .S(\blk00000001/sig000000c0 ),
    .O(\blk00000001/sig000000a0 )
  );
  XORCY   \blk00000001/blk00000046  (
    .CI(\blk00000001/sig0000009f ),
    .LI(\blk00000001/sig000000c0 ),
    .O(\blk00000001/sig000001ef )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000045  (
    .I0(\blk00000001/sig000001bd ),
    .I1(\blk00000001/sig000001de ),
    .O(\blk00000001/sig000000c1 )
  );
  MUXCY   \blk00000001/blk00000044  (
    .CI(\blk00000001/sig000000a0 ),
    .DI(\blk00000001/sig000001bd ),
    .S(\blk00000001/sig000000c1 ),
    .O(\blk00000001/sig000000a1 )
  );
  XORCY   \blk00000001/blk00000043  (
    .CI(\blk00000001/sig000000a0 ),
    .LI(\blk00000001/sig000000c1 ),
    .O(\blk00000001/sig000001f0 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000042  (
    .I0(\blk00000001/sig000001bf ),
    .I1(\blk00000001/sig000001df ),
    .O(\blk00000001/sig000000c3 )
  );
  MUXCY   \blk00000001/blk00000041  (
    .CI(\blk00000001/sig000000a1 ),
    .DI(\blk00000001/sig000001bf ),
    .S(\blk00000001/sig000000c3 ),
    .O(\blk00000001/sig000000a3 )
  );
  XORCY   \blk00000001/blk00000040  (
    .CI(\blk00000001/sig000000a1 ),
    .LI(\blk00000001/sig000000c3 ),
    .O(\blk00000001/sig000001f2 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000003f  (
    .I0(\blk00000001/sig000001c0 ),
    .I1(\blk00000001/sig000001e0 ),
    .O(\blk00000001/sig000000c4 )
  );
  MUXCY   \blk00000001/blk0000003e  (
    .CI(\blk00000001/sig000000a3 ),
    .DI(\blk00000001/sig000001c0 ),
    .S(\blk00000001/sig000000c4 ),
    .O(\blk00000001/sig000000a4 )
  );
  XORCY   \blk00000001/blk0000003d  (
    .CI(\blk00000001/sig000000a3 ),
    .LI(\blk00000001/sig000000c4 ),
    .O(\blk00000001/sig000001f3 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000003c  (
    .I0(\blk00000001/sig000001c1 ),
    .I1(\blk00000001/sig000001e1 ),
    .O(\blk00000001/sig000000c5 )
  );
  MUXCY   \blk00000001/blk0000003b  (
    .CI(\blk00000001/sig000000a4 ),
    .DI(\blk00000001/sig000001c1 ),
    .S(\blk00000001/sig000000c5 ),
    .O(\blk00000001/sig000000a5 )
  );
  XORCY   \blk00000001/blk0000003a  (
    .CI(\blk00000001/sig000000a4 ),
    .LI(\blk00000001/sig000000c5 ),
    .O(\blk00000001/sig000001f4 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000039  (
    .I0(\blk00000001/sig000001e2 ),
    .I1(\blk00000001/sig000001c2 ),
    .O(\blk00000001/sig000000c6 )
  );
  MUXCY   \blk00000001/blk00000038  (
    .CI(\blk00000001/sig000000a5 ),
    .DI(\blk00000001/sig000001c2 ),
    .S(\blk00000001/sig000000c6 ),
    .O(\blk00000001/sig000000a6 )
  );
  XORCY   \blk00000001/blk00000037  (
    .CI(\blk00000001/sig000000a5 ),
    .LI(\blk00000001/sig000000c6 ),
    .O(\blk00000001/sig000001f5 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000036  (
    .I0(\blk00000001/sig000001c2 ),
    .I1(\blk00000001/sig000001e3 ),
    .O(\blk00000001/sig000000c7 )
  );
  MUXCY   \blk00000001/blk00000035  (
    .CI(\blk00000001/sig000000a6 ),
    .DI(\blk00000001/sig000001c2 ),
    .S(\blk00000001/sig000000c7 ),
    .O(\blk00000001/sig000000a7 )
  );
  XORCY   \blk00000001/blk00000034  (
    .CI(\blk00000001/sig000000a6 ),
    .LI(\blk00000001/sig000000c7 ),
    .O(\blk00000001/sig000001f6 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000033  (
    .I0(\blk00000001/sig000001c2 ),
    .I1(\blk00000001/sig000001e4 ),
    .O(\blk00000001/sig000000c8 )
  );
  MUXCY   \blk00000001/blk00000032  (
    .CI(\blk00000001/sig000000a7 ),
    .DI(\blk00000001/sig000001c2 ),
    .S(\blk00000001/sig000000c8 ),
    .O(\blk00000001/sig000000a8 )
  );
  XORCY   \blk00000001/blk00000031  (
    .CI(\blk00000001/sig000000a7 ),
    .LI(\blk00000001/sig000000c8 ),
    .O(\blk00000001/sig000001f7 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000030  (
    .I0(\blk00000001/sig000001c2 ),
    .I1(\blk00000001/sig000001e5 ),
    .O(\blk00000001/sig000000c9 )
  );
  MUXCY   \blk00000001/blk0000002f  (
    .CI(\blk00000001/sig000000a8 ),
    .DI(\blk00000001/sig000001c2 ),
    .S(\blk00000001/sig000000c9 ),
    .O(\blk00000001/sig000000a9 )
  );
  XORCY   \blk00000001/blk0000002e  (
    .CI(\blk00000001/sig000000a8 ),
    .LI(\blk00000001/sig000000c9 ),
    .O(\blk00000001/sig000001f8 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000002d  (
    .I0(\blk00000001/sig000001c2 ),
    .I1(\blk00000001/sig000001da ),
    .O(\blk00000001/sig000000ca )
  );
  MUXCY   \blk00000001/blk0000002c  (
    .CI(\blk00000001/sig000000a9 ),
    .DI(\blk00000001/sig000001c2 ),
    .S(\blk00000001/sig000000ca ),
    .O(\blk00000001/sig000000aa )
  );
  XORCY   \blk00000001/blk0000002b  (
    .CI(\blk00000001/sig000000a9 ),
    .LI(\blk00000001/sig000000ca ),
    .O(\blk00000001/sig000001f9 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000002a  (
    .I0(\blk00000001/sig000001c2 ),
    .I1(\blk00000001/sig000001db ),
    .O(\blk00000001/sig000000cb )
  );
  MUXCY   \blk00000001/blk00000029  (
    .CI(\blk00000001/sig000000aa ),
    .DI(\blk00000001/sig000001c2 ),
    .S(\blk00000001/sig000000cb ),
    .O(\blk00000001/sig000000ab )
  );
  XORCY   \blk00000001/blk00000028  (
    .CI(\blk00000001/sig000000aa ),
    .LI(\blk00000001/sig000000cb ),
    .O(\blk00000001/sig000001fa )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000027  (
    .I0(\blk00000001/sig000001c2 ),
    .I1(\blk00000001/sig000001dc ),
    .O(\blk00000001/sig000000cc )
  );
  MUXCY   \blk00000001/blk00000026  (
    .CI(\blk00000001/sig000000ab ),
    .DI(\blk00000001/sig000001c2 ),
    .S(\blk00000001/sig000000cc ),
    .O(\blk00000001/sig000000ac )
  );
  XORCY   \blk00000001/blk00000025  (
    .CI(\blk00000001/sig000000ab ),
    .LI(\blk00000001/sig000000cc ),
    .O(\blk00000001/sig000001fb )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000024  (
    .I0(\blk00000001/sig000001c2 ),
    .I1(\blk00000001/sig000001dd ),
    .O(\blk00000001/sig000000ce )
  );
  MUXCY   \blk00000001/blk00000023  (
    .CI(\blk00000001/sig000000ac ),
    .DI(\blk00000001/sig000001c2 ),
    .S(\blk00000001/sig000000ce ),
    .O(\blk00000001/sig000000ae )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000022  (
    .I0(\blk00000001/sig000001c2 ),
    .I1(\blk00000001/sig000001dd ),
    .O(\blk00000001/sig000000cf )
  );
  MUXCY   \blk00000001/blk00000021  (
    .CI(\blk00000001/sig000000ae ),
    .DI(\blk00000001/sig000001c2 ),
    .S(\blk00000001/sig000000cf ),
    .O(\blk00000001/sig000000af )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000020  (
    .I0(\blk00000001/sig000001c2 ),
    .I1(\blk00000001/sig000001dd ),
    .O(\blk00000001/sig000000d0 )
  );
  XORCY   \blk00000001/blk0000001f  (
    .CI(\blk00000001/sig000000af ),
    .LI(\blk00000001/sig000000d0 ),
    .O(\blk00000001/sig000001ff )
  );
  MULT18X18S   \blk00000001/blk0000001e  (
    .C(clk),
    .CE(\blk00000001/sig0000004c ),
    .R(\blk00000001/sig0000004b ),
    .A({\blk00000001/sig0000004b , a[16], a[15], a[14], a[13], a[12], a[11], a[10], a[9], a[8], a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0]}),
    .B({\blk00000001/sig0000004b , b[16], b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4], b[3], b[2], b[1], b[0]}),
    .P({\NLW_blk00000001/blk0000001e_P<35>_UNCONNECTED , \blk00000001/sig00000115 , \blk00000001/sig00000114 , \blk00000001/sig00000113 , 
\blk00000001/sig00000112 , \blk00000001/sig00000111 , \blk00000001/sig0000010f , \blk00000001/sig0000010e , \blk00000001/sig0000010d , 
\blk00000001/sig0000010c , \blk00000001/sig0000010b , \blk00000001/sig0000010a , \blk00000001/sig00000109 , \blk00000001/sig00000108 , 
\blk00000001/sig00000107 , \blk00000001/sig00000106 , \blk00000001/sig00000104 , \blk00000001/sig00000103 , \blk00000001/sig00000102 , 
\blk00000001/sig00000101 , \blk00000001/sig00000100 , \blk00000001/sig000000ff , \blk00000001/sig000000fe , \blk00000001/sig000000fd , 
\blk00000001/sig000000fc , \blk00000001/sig000000fb , \blk00000001/sig0000011c , \blk00000001/sig0000011b , \blk00000001/sig0000011a , 
\blk00000001/sig00000119 , \blk00000001/sig00000118 , \blk00000001/sig00000117 , \blk00000001/sig00000116 , \blk00000001/sig00000110 , 
\blk00000001/sig00000105 , \blk00000001/sig000000fa })
  );
  MULT18X18S   \blk00000001/blk0000001d  (
    .C(clk),
    .CE(\blk00000001/sig0000004c ),
    .R(\blk00000001/sig0000004b ),
    .A({\blk00000001/sig0000004b , a[16], a[15], a[14], a[13], a[12], a[11], a[10], a[9], a[8], a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0]}),
    .B({b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[22], b[21], b[20], b[19], b[18], b[17]}),
    .P({\NLW_blk00000001/blk0000001d_P<35>_UNCONNECTED , \NLW_blk00000001/blk0000001d_P<34>_UNCONNECTED , 
\NLW_blk00000001/blk0000001d_P<33>_UNCONNECTED , \NLW_blk00000001/blk0000001d_P<32>_UNCONNECTED , \NLW_blk00000001/blk0000001d_P<31>_UNCONNECTED , 
\NLW_blk00000001/blk0000001d_P<30>_UNCONNECTED , \NLW_blk00000001/blk0000001d_P<29>_UNCONNECTED , \NLW_blk00000001/blk0000001d_P<28>_UNCONNECTED , 
\NLW_blk00000001/blk0000001d_P<27>_UNCONNECTED , \NLW_blk00000001/blk0000001d_P<26>_UNCONNECTED , \NLW_blk00000001/blk0000001d_P<25>_UNCONNECTED , 
\NLW_blk00000001/blk0000001d_P<24>_UNCONNECTED , \blk00000001/sig0000012c , \blk00000001/sig0000012b , \blk00000001/sig0000012a , 
\blk00000001/sig00000129 , \blk00000001/sig00000127 , \blk00000001/sig00000126 , \blk00000001/sig00000125 , \blk00000001/sig00000124 , 
\blk00000001/sig00000123 , \blk00000001/sig00000122 , \blk00000001/sig00000121 , \blk00000001/sig00000120 , \blk00000001/sig0000011f , 
\blk00000001/sig0000011e , \blk00000001/sig00000134 , \blk00000001/sig00000133 , \blk00000001/sig00000132 , \blk00000001/sig00000131 , 
\blk00000001/sig00000130 , \blk00000001/sig0000012f , \blk00000001/sig0000012e , \blk00000001/sig0000012d , \blk00000001/sig00000128 , 
\blk00000001/sig0000011d })
  );
  MULT18X18S   \blk00000001/blk0000001c  (
    .C(clk),
    .CE(\blk00000001/sig0000004c ),
    .R(\blk00000001/sig0000004b ),
    .A({a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[22], a[21], a[20], a[19], a[18], a[17]}),
    .B({\blk00000001/sig0000004b , b[16], b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4], b[3], b[2], b[1], b[0]}),
    .P({\NLW_blk00000001/blk0000001c_P<35>_UNCONNECTED , \NLW_blk00000001/blk0000001c_P<34>_UNCONNECTED , 
\NLW_blk00000001/blk0000001c_P<33>_UNCONNECTED , \NLW_blk00000001/blk0000001c_P<32>_UNCONNECTED , \NLW_blk00000001/blk0000001c_P<31>_UNCONNECTED , 
\NLW_blk00000001/blk0000001c_P<30>_UNCONNECTED , \NLW_blk00000001/blk0000001c_P<29>_UNCONNECTED , \NLW_blk00000001/blk0000001c_P<28>_UNCONNECTED , 
\NLW_blk00000001/blk0000001c_P<27>_UNCONNECTED , \NLW_blk00000001/blk0000001c_P<26>_UNCONNECTED , \NLW_blk00000001/blk0000001c_P<25>_UNCONNECTED , 
\NLW_blk00000001/blk0000001c_P<24>_UNCONNECTED , \blk00000001/sig00000144 , \blk00000001/sig00000143 , \blk00000001/sig00000142 , 
\blk00000001/sig00000141 , \blk00000001/sig0000013f , \blk00000001/sig0000013e , \blk00000001/sig0000013d , \blk00000001/sig0000013c , 
\blk00000001/sig0000013b , \blk00000001/sig0000013a , \blk00000001/sig00000139 , \blk00000001/sig00000138 , \blk00000001/sig00000137 , 
\blk00000001/sig00000136 , \blk00000001/sig0000014c , \blk00000001/sig0000014b , \blk00000001/sig0000014a , \blk00000001/sig00000149 , 
\blk00000001/sig00000148 , \blk00000001/sig00000147 , \blk00000001/sig00000146 , \blk00000001/sig00000145 , \blk00000001/sig00000140 , 
\blk00000001/sig00000135 })
  );
  MULT18X18S   \blk00000001/blk0000001b  (
    .C(clk),
    .CE(\blk00000001/sig0000004c ),
    .R(\blk00000001/sig0000004b ),
    .A({a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[22], a[21], a[20], a[19], a[18], a[17]}),
    .B({b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[22], b[21], b[20], b[19], b[18], b[17]}),
    .P({\NLW_blk00000001/blk0000001b_P<35>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<34>_UNCONNECTED , 
\NLW_blk00000001/blk0000001b_P<33>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<32>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<31>_UNCONNECTED , 
\NLW_blk00000001/blk0000001b_P<30>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<29>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<28>_UNCONNECTED , 
\NLW_blk00000001/blk0000001b_P<27>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<26>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<25>_UNCONNECTED , 
\NLW_blk00000001/blk0000001b_P<24>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<23>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<22>_UNCONNECTED , 
\NLW_blk00000001/blk0000001b_P<21>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<20>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<19>_UNCONNECTED , 
\NLW_blk00000001/blk0000001b_P<18>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<17>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<16>_UNCONNECTED , 
\NLW_blk00000001/blk0000001b_P<15>_UNCONNECTED , \NLW_blk00000001/blk0000001b_P<14>_UNCONNECTED , \blk00000001/sig00000151 , \blk00000001/sig00000150 
, \blk00000001/sig0000014f , \blk00000001/sig0000014e , \blk00000001/sig0000015a , \blk00000001/sig00000159 , \blk00000001/sig00000158 , 
\blk00000001/sig00000157 , \blk00000001/sig00000156 , \blk00000001/sig00000155 , \blk00000001/sig00000154 , \blk00000001/sig00000153 , 
\blk00000001/sig00000152 , \blk00000001/sig0000014d })
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000001a  (
    .C(clk),
    .D(\blk00000001/sig00000219 ),
    .Q(p[47])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000019  (
    .C(clk),
    .D(\blk00000001/sig00000218 ),
    .Q(p[46])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000018  (
    .C(clk),
    .D(\blk00000001/sig00000217 ),
    .Q(p[45])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000017  (
    .C(clk),
    .D(\blk00000001/sig00000216 ),
    .Q(p[44])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000016  (
    .C(clk),
    .D(\blk00000001/sig00000215 ),
    .Q(p[43])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000015  (
    .C(clk),
    .D(\blk00000001/sig00000214 ),
    .Q(p[42])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000014  (
    .C(clk),
    .D(\blk00000001/sig00000213 ),
    .Q(p[41])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000013  (
    .C(clk),
    .D(\blk00000001/sig00000212 ),
    .Q(p[40])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000012  (
    .C(clk),
    .D(\blk00000001/sig00000211 ),
    .Q(p[39])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000011  (
    .C(clk),
    .D(\blk00000001/sig00000210 ),
    .Q(p[38])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000010  (
    .C(clk),
    .D(\blk00000001/sig0000020f ),
    .Q(p[37])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000f  (
    .C(clk),
    .D(\blk00000001/sig0000020e ),
    .Q(p[36])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000e  (
    .C(clk),
    .D(\blk00000001/sig0000020d ),
    .Q(p[35])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000d  (
    .C(clk),
    .D(\blk00000001/sig0000020c ),
    .Q(p[34])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000c  (
    .C(clk),
    .D(\blk00000001/sig0000020b ),
    .Q(p[33])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000b  (
    .C(clk),
    .D(\blk00000001/sig0000020a ),
    .Q(p[32])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000a  (
    .C(clk),
    .D(\blk00000001/sig00000209 ),
    .Q(p[31])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000009  (
    .C(clk),
    .D(\blk00000001/sig00000208 ),
    .Q(p[30])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000008  (
    .C(clk),
    .D(\blk00000001/sig00000207 ),
    .Q(p[29])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000007  (
    .C(clk),
    .D(\blk00000001/sig00000206 ),
    .Q(p[28])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000006  (
    .C(clk),
    .D(\blk00000001/sig00000205 ),
    .Q(p[27])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000005  (
    .C(clk),
    .D(\blk00000001/sig0000021b ),
    .Q(p[26])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000004  (
    .C(clk),
    .D(\blk00000001/sig0000021a ),
    .Q(p[25])
  );
  VCC   \blk00000001/blk00000003  (
    .P(\blk00000001/sig0000004c )
  );
  GND   \blk00000001/blk00000002  (
    .G(\blk00000001/sig0000004b )
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

////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2011 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: O.61xd
//  \   \         Application: netgen
//  /   /         Filename: cx4_mul.v
// /___/   /\     Timestamp: Tue Oct 25 00:04:23 2011
// \   \  /  \ 
//  \___\/\___\
//             
// Command	: -w -sim -ofmt verilog /home/ikari/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.ngc /home/ikari/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.v 
// Device	: 3s400pq208-4
// Input file	: /home/ikari/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.ngc
// Output file	: /home/ikari/prj/sd2snes/verilog/sd2snes_cx4/ipcore_dir/tmp/_cg/cx4_mul.v
// # of Modules	: 1
// Design Name	: cx4_mul
// Xilinx        : /mnt/store/bin/Xilinx/13.2/ISE_DS/ISE/
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
  
  wire sig00000001;
  wire sig00000002;
  wire sig00000003;
  wire sig00000004;
  wire sig00000005;
  wire sig00000006;
  wire sig00000007;
  wire sig00000008;
  wire sig00000009;
  wire sig0000000a;
  wire sig0000000b;
  wire sig0000000c;
  wire sig0000000d;
  wire sig0000000e;
  wire sig0000000f;
  wire sig00000010;
  wire sig00000011;
  wire sig00000012;
  wire sig00000013;
  wire sig00000014;
  wire sig00000015;
  wire sig00000016;
  wire sig00000017;
  wire sig00000018;
  wire sig00000019;
  wire sig0000001a;
  wire sig0000001b;
  wire sig0000001c;
  wire sig0000001d;
  wire sig0000001e;
  wire sig0000001f;
  wire sig00000020;
  wire sig00000021;
  wire sig00000022;
  wire sig00000023;
  wire sig00000024;
  wire sig00000025;
  wire sig00000026;
  wire sig00000027;
  wire sig00000028;
  wire sig00000029;
  wire sig0000002a;
  wire sig0000002b;
  wire sig0000002c;
  wire sig0000002d;
  wire sig0000002e;
  wire sig0000002f;
  wire sig00000030;
  wire sig00000031;
  wire sig00000032;
  wire sig00000033;
  wire sig00000034;
  wire sig00000035;
  wire sig00000036;
  wire sig00000037;
  wire sig00000038;
  wire sig00000039;
  wire sig0000003a;
  wire sig0000003b;
  wire sig0000003c;
  wire sig0000003d;
  wire sig0000003e;
  wire sig0000003f;
  wire sig00000040;
  wire sig00000041;
  wire sig00000042;
  wire sig00000043;
  wire sig00000044;
  wire sig00000045;
  wire sig00000046;
  wire sig00000047;
  wire sig00000048;
  wire sig00000049;
  wire sig0000004a;
  wire sig0000004b;
  wire sig0000004c;
  wire sig0000004d;
  wire sig0000004e;
  wire sig0000004f;
  wire sig00000050;
  wire sig00000051;
  wire sig00000052;
  wire sig00000053;
  wire sig00000054;
  wire sig00000055;
  wire sig00000056;
  wire sig00000057;
  wire sig00000058;
  wire sig00000059;
  wire sig0000005a;
  wire sig0000005b;
  wire sig0000005c;
  wire sig0000005d;
  wire sig0000005e;
  wire sig0000005f;
  wire sig00000060;
  wire sig00000061;
  wire sig00000062;
  wire sig00000063;
  wire sig00000064;
  wire sig00000065;
  wire sig00000066;
  wire sig00000067;
  wire sig00000068;
  wire sig00000069;
  wire sig0000006a;
  wire sig0000006b;
  wire sig0000006c;
  wire sig0000006d;
  wire sig0000006e;
  wire sig0000006f;
  wire sig00000070;
  wire sig00000071;
  wire sig00000072;
  wire sig00000073;
  wire sig00000074;
  wire sig00000075;
  wire sig00000076;
  wire sig00000077;
  wire sig00000078;
  wire sig00000079;
  wire sig0000007a;
  wire sig0000007b;
  wire sig0000007c;
  wire sig0000007d;
  wire sig0000007e;
  wire sig0000007f;
  wire sig00000080;
  wire sig00000081;
  wire sig00000082;
  wire sig00000083;
  wire sig00000084;
  wire sig00000085;
  wire sig00000086;
  wire sig00000087;
  wire sig00000088;
  wire sig00000089;
  wire sig0000008a;
  wire sig0000008b;
  wire sig0000008c;
  wire sig0000008d;
  wire sig0000008e;
  wire sig0000008f;
  wire sig00000090;
  wire sig00000091;
  wire sig00000092;
  wire sig00000093;
  wire sig00000094;
  wire sig00000095;
  wire sig00000096;
  wire sig00000097;
  wire sig00000098;
  wire sig00000099;
  wire sig0000009a;
  wire sig0000009b;
  wire sig0000009c;
  wire sig0000009d;
  wire sig0000009e;
  wire sig0000009f;
  wire sig000000a0;
  wire sig000000a1;
  wire sig000000a2;
  wire sig000000a3;
  wire sig000000a4;
  wire sig000000a5;
  wire sig000000a6;
  wire sig000000a7;
  wire sig000000a8;
  wire sig000000a9;
  wire sig000000aa;
  wire sig000000ab;
  wire sig000000ac;
  wire sig000000ad;
  wire sig000000ae;
  wire sig000000af;
  wire sig000000b0;
  wire sig000000b1;
  wire sig000000b2;
  wire sig000000b3;
  wire sig000000b4;
  wire sig000000b5;
  wire sig000000b6;
  wire sig000000b7;
  wire sig000000b8;
  wire sig000000b9;
  wire sig000000ba;
  wire sig000000bb;
  wire sig000000bc;
  wire sig000000bd;
  wire sig000000be;
  wire sig000000bf;
  wire sig000000c0;
  wire sig000000c1;
  wire sig000000c2;
  wire sig000000c3;
  wire sig000000c4;
  wire sig000000c5;
  wire sig000000c6;
  wire sig000000c7;
  wire sig000000c8;
  wire sig000000c9;
  wire sig000000ca;
  wire sig000000cb;
  wire sig000000cc;
  wire sig000000cd;
  wire sig000000ce;
  wire sig000000cf;
  wire sig000000d0;
  wire sig000000d1;
  wire sig000000d2;
  wire sig000000d3;
  wire sig000000d4;
  wire sig000000d5;
  wire sig000000d6;
  wire sig000000d7;
  wire sig000000d8;
  wire sig000000d9;
  wire sig000000da;
  wire sig000000db;
  wire sig000000dc;
  wire sig000000dd;
  wire sig000000de;
  wire sig000000df;
  wire sig000000e0;
  wire sig000000e1;
  wire sig000000e2;
  wire sig000000e3;
  wire sig000000e4;
  wire sig000000e5;
  wire sig000000e6;
  wire sig000000e7;
  wire sig000000e8;
  wire sig000000e9;
  wire sig000000ea;
  wire sig000000eb;
  wire sig000000ec;
  wire sig000000ed;
  wire sig000000ee;
  wire sig000000ef;
  wire sig000000f0;
  wire sig000000f1;
  wire sig000000f2;
  wire sig000000f3;
  wire sig000000f4;
  wire sig000000f5;
  wire sig000000f6;
  wire sig000000f7;
  wire sig000000f8;
  wire sig000000f9;
  wire sig000000fa;
  wire sig000000fb;
  wire sig000000fc;
  wire sig000000fd;
  wire sig000000fe;
  wire sig000000ff;
  wire sig00000100;
  wire sig00000101;
  wire sig00000102;
  wire sig00000103;
  wire sig00000104;
  wire sig00000105;
  wire sig00000106;
  wire sig00000107;
  wire sig00000108;
  wire sig00000109;
  wire sig0000010a;
  wire sig0000010b;
  wire sig0000010c;
  wire sig0000010d;
  wire sig0000010e;
  wire sig0000010f;
  wire sig00000110;
  wire sig00000111;
  wire sig00000112;
  wire sig00000113;
  wire sig00000114;
  wire sig00000115;
  wire sig00000116;
  wire sig00000117;
  wire sig00000118;
  wire sig00000119;
  wire sig0000011a;
  wire sig0000011b;
  wire sig0000011c;
  wire sig0000011d;
  wire sig0000011e;
  wire sig0000011f;
  wire sig00000120;
  wire sig00000121;
  wire sig00000122;
  wire sig00000123;
  wire sig00000124;
  wire sig00000125;
  wire sig00000126;
  wire sig00000127;
  wire sig00000128;
  wire sig00000129;
  wire sig0000012a;
  wire sig0000012b;
  wire sig0000012c;
  wire sig0000012d;
  wire sig0000012e;
  wire sig0000012f;
  wire sig00000130;
  wire sig00000131;
  wire sig00000132;
  wire sig00000133;
  wire sig00000134;
  wire sig00000135;
  wire sig00000136;
  wire sig00000137;
  wire sig00000138;
  wire sig00000139;
  wire sig0000013a;
  wire sig0000013b;
  wire sig0000013c;
  wire sig0000013d;
  wire sig0000013e;
  wire sig0000013f;
  wire sig00000140;
  wire sig00000141;
  wire sig00000142;
  wire sig00000143;
  wire sig00000144;
  wire sig00000145;
  wire sig00000146;
  wire sig00000147;
  wire sig00000148;
  wire sig00000149;
  wire sig0000014a;
  wire sig0000014b;
  wire sig0000014c;
  wire sig0000014d;
  wire sig0000014e;
  wire sig0000014f;
  wire sig00000150;
  wire sig00000151;
  wire sig00000152;
  wire sig00000153;
  wire sig00000154;
  wire sig00000155;
  wire sig00000156;
  wire sig00000157;
  wire sig00000158;
  wire sig00000159;
  wire sig0000015a;
  wire sig0000015b;
  wire sig0000015c;
  wire sig0000015d;
  wire sig0000015e;
  wire sig0000015f;
  wire sig00000160;
  wire sig00000161;
  wire sig00000162;
  wire sig00000163;
  wire sig00000164;
  wire sig00000165;
  wire sig00000166;
  wire sig00000167;
  wire sig00000168;
  wire sig00000169;
  wire sig0000016a;
  wire sig0000016b;
  wire sig0000016c;
  wire sig0000016d;
  wire sig0000016e;
  wire sig0000016f;
  wire sig00000170;
  wire sig00000171;
  wire sig00000172;
  wire sig00000173;
  wire sig00000174;
  wire sig00000175;
  wire sig00000176;
  wire sig00000177;
  wire sig00000178;
  wire sig00000179;
  wire sig0000017a;
  wire sig0000017b;
  wire sig0000017c;
  wire sig0000017d;
  wire sig0000017e;
  wire sig0000017f;
  wire sig00000180;
  wire sig00000181;
  wire sig00000182;
  wire sig00000183;
  wire sig00000184;
  wire sig00000185;
  wire sig00000186;
  wire sig00000187;
  wire sig00000188;
  wire sig00000189;
  wire sig0000018a;
  wire sig0000018b;
  wire sig0000018c;
  wire sig0000018d;
  wire sig0000018e;
  wire sig0000018f;
  wire sig00000190;
  wire sig00000191;
  wire sig00000192;
  wire sig00000193;
  wire sig00000194;
  wire \NLW_blk00000003_P<35>_UNCONNECTED ;
  wire \NLW_blk00000003_P<34>_UNCONNECTED ;
  wire \NLW_blk00000003_P<33>_UNCONNECTED ;
  wire \NLW_blk00000003_P<32>_UNCONNECTED ;
  wire \NLW_blk00000003_P<31>_UNCONNECTED ;
  wire \NLW_blk00000003_P<30>_UNCONNECTED ;
  wire \NLW_blk00000003_P<29>_UNCONNECTED ;
  wire \NLW_blk00000003_P<28>_UNCONNECTED ;
  wire \NLW_blk00000003_P<27>_UNCONNECTED ;
  wire \NLW_blk00000003_P<26>_UNCONNECTED ;
  wire \NLW_blk00000003_P<25>_UNCONNECTED ;
  wire \NLW_blk00000003_P<24>_UNCONNECTED ;
  wire \NLW_blk00000003_P<23>_UNCONNECTED ;
  wire \NLW_blk00000003_P<22>_UNCONNECTED ;
  wire \NLW_blk00000003_P<21>_UNCONNECTED ;
  wire \NLW_blk00000003_P<20>_UNCONNECTED ;
  wire \NLW_blk00000003_P<19>_UNCONNECTED ;
  wire \NLW_blk00000003_P<18>_UNCONNECTED ;
  wire \NLW_blk00000003_P<17>_UNCONNECTED ;
  wire \NLW_blk00000003_P<16>_UNCONNECTED ;
  wire \NLW_blk00000003_P<15>_UNCONNECTED ;
  wire \NLW_blk00000003_P<14>_UNCONNECTED ;
  wire \NLW_blk00000004_P<35>_UNCONNECTED ;
  wire \NLW_blk00000004_P<34>_UNCONNECTED ;
  wire \NLW_blk00000004_P<33>_UNCONNECTED ;
  wire \NLW_blk00000004_P<32>_UNCONNECTED ;
  wire \NLW_blk00000004_P<31>_UNCONNECTED ;
  wire \NLW_blk00000004_P<30>_UNCONNECTED ;
  wire \NLW_blk00000004_P<29>_UNCONNECTED ;
  wire \NLW_blk00000004_P<28>_UNCONNECTED ;
  wire \NLW_blk00000004_P<27>_UNCONNECTED ;
  wire \NLW_blk00000004_P<26>_UNCONNECTED ;
  wire \NLW_blk00000004_P<25>_UNCONNECTED ;
  wire \NLW_blk00000004_P<24>_UNCONNECTED ;
  wire \NLW_blk00000005_P<35>_UNCONNECTED ;
  wire \NLW_blk00000005_P<34>_UNCONNECTED ;
  wire \NLW_blk00000005_P<33>_UNCONNECTED ;
  wire \NLW_blk00000005_P<32>_UNCONNECTED ;
  wire \NLW_blk00000005_P<31>_UNCONNECTED ;
  wire \NLW_blk00000005_P<30>_UNCONNECTED ;
  wire \NLW_blk00000005_P<29>_UNCONNECTED ;
  wire \NLW_blk00000005_P<28>_UNCONNECTED ;
  wire \NLW_blk00000005_P<27>_UNCONNECTED ;
  wire \NLW_blk00000005_P<26>_UNCONNECTED ;
  wire \NLW_blk00000005_P<25>_UNCONNECTED ;
  wire \NLW_blk00000005_P<24>_UNCONNECTED ;
  wire \NLW_blk00000006_P<35>_UNCONNECTED ;
  GND   blk00000001 (
    .G(sig00000012)
  );
  VCC   blk00000002 (
    .P(sig00000013)
  );
  MULT18X18S   blk00000003 (
    .C(clk),
    .CE(sig00000013),
    .R(sig00000012),
    .A({a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[22], a[21], a[20], a[19], a[18], a[17]}),
    .B({b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[22], b[21], b[20], b[19], b[18], b[17]}),
    .P({\NLW_blk00000003_P<35>_UNCONNECTED , \NLW_blk00000003_P<34>_UNCONNECTED , \NLW_blk00000003_P<33>_UNCONNECTED , 
\NLW_blk00000003_P<32>_UNCONNECTED , \NLW_blk00000003_P<31>_UNCONNECTED , \NLW_blk00000003_P<30>_UNCONNECTED , \NLW_blk00000003_P<29>_UNCONNECTED , 
\NLW_blk00000003_P<28>_UNCONNECTED , \NLW_blk00000003_P<27>_UNCONNECTED , \NLW_blk00000003_P<26>_UNCONNECTED , \NLW_blk00000003_P<25>_UNCONNECTED , 
\NLW_blk00000003_P<24>_UNCONNECTED , \NLW_blk00000003_P<23>_UNCONNECTED , \NLW_blk00000003_P<22>_UNCONNECTED , \NLW_blk00000003_P<21>_UNCONNECTED , 
\NLW_blk00000003_P<20>_UNCONNECTED , \NLW_blk00000003_P<19>_UNCONNECTED , \NLW_blk00000003_P<18>_UNCONNECTED , \NLW_blk00000003_P<17>_UNCONNECTED , 
\NLW_blk00000003_P<16>_UNCONNECTED , \NLW_blk00000003_P<15>_UNCONNECTED , \NLW_blk00000003_P<14>_UNCONNECTED , sig000000f6, sig000000f5, sig000000f4, 
sig000000f3, sig000000ff, sig000000fe, sig000000fd, sig000000fc, sig000000fb, sig000000fa, sig000000f9, sig000000f8, sig000000f7, sig000000f2})
  );
  MULT18X18S   blk00000004 (
    .C(clk),
    .CE(sig00000013),
    .R(sig00000012),
    .A({a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[23], a[22], a[21], a[20], a[19], a[18], a[17]}),
    .B({sig00000012, b[16], b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4], b[3], b[2], b[1], b[0]}),
    .P({\NLW_blk00000004_P<35>_UNCONNECTED , \NLW_blk00000004_P<34>_UNCONNECTED , \NLW_blk00000004_P<33>_UNCONNECTED , 
\NLW_blk00000004_P<32>_UNCONNECTED , \NLW_blk00000004_P<31>_UNCONNECTED , \NLW_blk00000004_P<30>_UNCONNECTED , \NLW_blk00000004_P<29>_UNCONNECTED , 
\NLW_blk00000004_P<28>_UNCONNECTED , \NLW_blk00000004_P<27>_UNCONNECTED , \NLW_blk00000004_P<26>_UNCONNECTED , \NLW_blk00000004_P<25>_UNCONNECTED , 
\NLW_blk00000004_P<24>_UNCONNECTED , sig000000e9, sig000000e8, sig000000e7, sig000000e6, sig000000e4, sig000000e3, sig000000e2, sig000000e1, 
sig000000e0, sig000000df, sig000000de, sig000000dd, sig000000dc, sig000000db, sig000000f1, sig000000f0, sig000000ef, sig000000ee, sig000000ed, 
sig000000ec, sig000000eb, sig000000ea, sig000000e5, sig000000da})
  );
  MULT18X18S   blk00000005 (
    .C(clk),
    .CE(sig00000013),
    .R(sig00000012),
    .A({sig00000012, a[16], a[15], a[14], a[13], a[12], a[11], a[10], a[9], a[8], a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0]}),
    .B({b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[23], b[22], b[21], b[20], b[19], b[18], b[17]}),
    .P({\NLW_blk00000005_P<35>_UNCONNECTED , \NLW_blk00000005_P<34>_UNCONNECTED , \NLW_blk00000005_P<33>_UNCONNECTED , 
\NLW_blk00000005_P<32>_UNCONNECTED , \NLW_blk00000005_P<31>_UNCONNECTED , \NLW_blk00000005_P<30>_UNCONNECTED , \NLW_blk00000005_P<29>_UNCONNECTED , 
\NLW_blk00000005_P<28>_UNCONNECTED , \NLW_blk00000005_P<27>_UNCONNECTED , \NLW_blk00000005_P<26>_UNCONNECTED , \NLW_blk00000005_P<25>_UNCONNECTED , 
\NLW_blk00000005_P<24>_UNCONNECTED , sig000000d1, sig000000d0, sig000000cf, sig000000ce, sig000000cc, sig000000cb, sig000000ca, sig000000c9, 
sig000000c8, sig000000c7, sig000000c6, sig000000c5, sig000000c4, sig000000c3, sig000000d9, sig000000d8, sig000000d7, sig000000d6, sig000000d5, 
sig000000d4, sig000000d3, sig000000d2, sig000000cd, sig000000c2})
  );
  MULT18X18S   blk00000006 (
    .C(clk),
    .CE(sig00000013),
    .R(sig00000012),
    .A({sig00000012, a[16], a[15], a[14], a[13], a[12], a[11], a[10], a[9], a[8], a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0]}),
    .B({sig00000012, b[16], b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4], b[3], b[2], b[1], b[0]}),
    .P({\NLW_blk00000006_P<35>_UNCONNECTED , sig000000ba, sig000000b9, sig000000b8, sig000000b7, sig000000b6, sig000000b4, sig000000b3, sig000000b2, 
sig000000b1, sig000000b0, sig000000af, sig000000ae, sig000000ad, sig000000ac, sig000000ab, sig000000a9, sig000000a8, sig000000a7, sig000000a6, 
sig000000a5, sig000000a4, sig000000a3, sig000000a2, sig000000a1, sig000000a0, sig000000c1, sig000000c0, sig000000bf, sig000000be, sig000000bd, 
sig000000bc, sig000000bb, sig000000b5, sig000000aa, sig0000009f})
  );
  XORCY   blk00000007 (
    .CI(sig00000076),
    .LI(sig00000097),
    .O(sig0000018f)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000008 (
    .I0(sig0000016c),
    .I1(sig0000015f),
    .O(sig00000097)
  );
  MUXCY   blk00000009 (
    .CI(sig00000075),
    .DI(sig0000015f),
    .S(sig00000096),
    .O(sig00000076)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000000a (
    .I0(sig0000016c),
    .I1(sig0000015f),
    .O(sig00000096)
  );
  MUXCY   blk0000000b (
    .CI(sig00000073),
    .DI(sig0000015f),
    .S(sig00000095),
    .O(sig00000075)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000000c (
    .I0(sig0000016c),
    .I1(sig0000015f),
    .O(sig00000095)
  );
  XORCY   blk0000000d (
    .CI(sig00000072),
    .LI(sig00000093),
    .O(sig0000018b)
  );
  MUXCY   blk0000000e (
    .CI(sig00000072),
    .DI(sig0000015f),
    .S(sig00000093),
    .O(sig00000073)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000000f (
    .I0(sig0000016b),
    .I1(sig0000015f),
    .O(sig00000093)
  );
  XORCY   blk00000010 (
    .CI(sig00000071),
    .LI(sig00000092),
    .O(sig0000018a)
  );
  MUXCY   blk00000011 (
    .CI(sig00000071),
    .DI(sig0000015f),
    .S(sig00000092),
    .O(sig00000072)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000012 (
    .I0(sig0000016a),
    .I1(sig0000015f),
    .O(sig00000092)
  );
  XORCY   blk00000013 (
    .CI(sig00000070),
    .LI(sig00000091),
    .O(sig00000189)
  );
  MUXCY   blk00000014 (
    .CI(sig00000070),
    .DI(sig0000015f),
    .S(sig00000091),
    .O(sig00000071)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000015 (
    .I0(sig00000169),
    .I1(sig0000015f),
    .O(sig00000091)
  );
  XORCY   blk00000016 (
    .CI(sig0000006f),
    .LI(sig00000090),
    .O(sig00000188)
  );
  MUXCY   blk00000017 (
    .CI(sig0000006f),
    .DI(sig0000015f),
    .S(sig00000090),
    .O(sig00000070)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000018 (
    .I0(sig00000175),
    .I1(sig0000015f),
    .O(sig00000090)
  );
  XORCY   blk00000019 (
    .CI(sig0000006e),
    .LI(sig0000008f),
    .O(sig00000187)
  );
  MUXCY   blk0000001a (
    .CI(sig0000006e),
    .DI(sig0000015f),
    .S(sig0000008f),
    .O(sig0000006f)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000001b (
    .I0(sig00000174),
    .I1(sig0000015f),
    .O(sig0000008f)
  );
  XORCY   blk0000001c (
    .CI(sig0000006d),
    .LI(sig0000008e),
    .O(sig00000186)
  );
  MUXCY   blk0000001d (
    .CI(sig0000006d),
    .DI(sig0000015f),
    .S(sig0000008e),
    .O(sig0000006e)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000001e (
    .I0(sig00000173),
    .I1(sig0000015f),
    .O(sig0000008e)
  );
  XORCY   blk0000001f (
    .CI(sig0000006c),
    .LI(sig0000008d),
    .O(sig00000185)
  );
  MUXCY   blk00000020 (
    .CI(sig0000006c),
    .DI(sig0000015f),
    .S(sig0000008d),
    .O(sig0000006d)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000021 (
    .I0(sig00000172),
    .I1(sig0000015f),
    .O(sig0000008d)
  );
  XORCY   blk00000022 (
    .CI(sig0000006b),
    .LI(sig0000008c),
    .O(sig00000184)
  );
  MUXCY   blk00000023 (
    .CI(sig0000006b),
    .DI(sig0000015e),
    .S(sig0000008c),
    .O(sig0000006c)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000024 (
    .I0(sig00000171),
    .I1(sig0000015e),
    .O(sig0000008c)
  );
  XORCY   blk00000025 (
    .CI(sig0000006a),
    .LI(sig0000008b),
    .O(sig00000183)
  );
  MUXCY   blk00000026 (
    .CI(sig0000006a),
    .DI(sig0000015d),
    .S(sig0000008b),
    .O(sig0000006b)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000027 (
    .I0(sig00000170),
    .I1(sig0000015d),
    .O(sig0000008b)
  );
  XORCY   blk00000028 (
    .CI(sig00000068),
    .LI(sig0000008a),
    .O(sig00000182)
  );
  MUXCY   blk00000029 (
    .CI(sig00000068),
    .DI(sig0000015c),
    .S(sig0000008a),
    .O(sig0000006a)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000002a (
    .I0(sig0000016f),
    .I1(sig0000015c),
    .O(sig0000008a)
  );
  XORCY   blk0000002b (
    .CI(sig00000067),
    .LI(sig00000088),
    .O(sig00000180)
  );
  MUXCY   blk0000002c (
    .CI(sig00000067),
    .DI(sig0000015a),
    .S(sig00000088),
    .O(sig00000068)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000002d (
    .I0(sig0000016e),
    .I1(sig0000015a),
    .O(sig00000088)
  );
  XORCY   blk0000002e (
    .CI(sig00000066),
    .LI(sig00000087),
    .O(sig0000017f)
  );
  MUXCY   blk0000002f (
    .CI(sig00000066),
    .DI(sig00000159),
    .S(sig00000087),
    .O(sig00000067)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000030 (
    .I0(sig0000016d),
    .I1(sig00000159),
    .O(sig00000087)
  );
  XORCY   blk00000031 (
    .CI(sig00000065),
    .LI(sig00000086),
    .O(sig0000017e)
  );
  MUXCY   blk00000032 (
    .CI(sig00000065),
    .DI(sig00000158),
    .S(sig00000086),
    .O(sig00000066)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000033 (
    .I0(sig00000168),
    .I1(sig00000158),
    .O(sig00000086)
  );
  XORCY   blk00000034 (
    .CI(sig00000064),
    .LI(sig00000085),
    .O(sig0000017d)
  );
  MUXCY   blk00000035 (
    .CI(sig00000064),
    .DI(sig00000157),
    .S(sig00000085),
    .O(sig00000065)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000036 (
    .I0(sig00000132),
    .I1(sig00000157),
    .O(sig00000085)
  );
  XORCY   blk00000037 (
    .CI(sig00000063),
    .LI(sig00000084),
    .O(sig0000017c)
  );
  MUXCY   blk00000038 (
    .CI(sig00000063),
    .DI(sig00000156),
    .S(sig00000084),
    .O(sig00000064)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000039 (
    .I0(sig00000131),
    .I1(sig00000156),
    .O(sig00000084)
  );
  XORCY   blk0000003a (
    .CI(sig00000062),
    .LI(sig00000083),
    .O(sig0000017b)
  );
  MUXCY   blk0000003b (
    .CI(sig00000062),
    .DI(sig00000155),
    .S(sig00000083),
    .O(sig00000063)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000003c (
    .I0(sig00000130),
    .I1(sig00000155),
    .O(sig00000083)
  );
  XORCY   blk0000003d (
    .CI(sig00000061),
    .LI(sig00000082),
    .O(sig0000017a)
  );
  MUXCY   blk0000003e (
    .CI(sig00000061),
    .DI(sig00000154),
    .S(sig00000082),
    .O(sig00000062)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000003f (
    .I0(sig0000012f),
    .I1(sig00000154),
    .O(sig00000082)
  );
  XORCY   blk00000040 (
    .CI(sig00000060),
    .LI(sig00000081),
    .O(sig00000179)
  );
  MUXCY   blk00000041 (
    .CI(sig00000060),
    .DI(sig00000153),
    .S(sig00000081),
    .O(sig00000061)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000042 (
    .I0(sig0000012e),
    .I1(sig00000153),
    .O(sig00000081)
  );
  XORCY   blk00000043 (
    .CI(sig0000005f),
    .LI(sig00000080),
    .O(sig00000178)
  );
  MUXCY   blk00000044 (
    .CI(sig0000005f),
    .DI(sig00000152),
    .S(sig00000080),
    .O(sig00000060)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000045 (
    .I0(sig0000012d),
    .I1(sig00000152),
    .O(sig00000080)
  );
  XORCY   blk00000046 (
    .CI(sig0000007d),
    .LI(sig0000007f),
    .O(sig00000177)
  );
  MUXCY   blk00000047 (
    .CI(sig0000007d),
    .DI(sig00000151),
    .S(sig0000007f),
    .O(sig0000005f)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000048 (
    .I0(sig0000012c),
    .I1(sig00000151),
    .O(sig0000007f)
  );
  XORCY   blk00000049 (
    .CI(sig0000007c),
    .LI(sig0000009e),
    .O(sig00000194)
  );
  MUXCY   blk0000004a (
    .CI(sig0000007c),
    .DI(sig00000167),
    .S(sig0000009e),
    .O(sig0000007d)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000004b (
    .I0(sig00000141),
    .I1(sig00000167),
    .O(sig0000009e)
  );
  XORCY   blk0000004c (
    .CI(sig0000007b),
    .LI(sig0000009d),
    .O(sig00000193)
  );
  MUXCY   blk0000004d (
    .CI(sig0000007b),
    .DI(sig00000166),
    .S(sig0000009d),
    .O(sig0000007c)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000004e (
    .I0(sig00000140),
    .I1(sig00000166),
    .O(sig0000009d)
  );
  XORCY   blk0000004f (
    .CI(sig0000007a),
    .LI(sig0000009c),
    .O(sig00000192)
  );
  MUXCY   blk00000050 (
    .CI(sig0000007a),
    .DI(sig00000165),
    .S(sig0000009c),
    .O(sig0000007b)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000051 (
    .I0(sig0000013f),
    .I1(sig00000165),
    .O(sig0000009c)
  );
  XORCY   blk00000052 (
    .CI(sig00000079),
    .LI(sig0000009b),
    .O(sig00000191)
  );
  MUXCY   blk00000053 (
    .CI(sig00000079),
    .DI(sig00000164),
    .S(sig0000009b),
    .O(sig0000007a)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000054 (
    .I0(sig0000013e),
    .I1(sig00000164),
    .O(sig0000009b)
  );
  XORCY   blk00000055 (
    .CI(sig00000078),
    .LI(sig0000009a),
    .O(sig00000190)
  );
  MUXCY   blk00000056 (
    .CI(sig00000078),
    .DI(sig00000163),
    .S(sig0000009a),
    .O(sig00000079)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000057 (
    .I0(sig0000013d),
    .I1(sig00000163),
    .O(sig0000009a)
  );
  XORCY   blk00000058 (
    .CI(sig00000077),
    .LI(sig00000099),
    .O(sig0000018e)
  );
  MUXCY   blk00000059 (
    .CI(sig00000077),
    .DI(sig00000162),
    .S(sig00000099),
    .O(sig00000078)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000005a (
    .I0(sig0000013c),
    .I1(sig00000162),
    .O(sig00000099)
  );
  XORCY   blk0000005b (
    .CI(sig00000074),
    .LI(sig00000098),
    .O(sig0000018d)
  );
  MUXCY   blk0000005c (
    .CI(sig00000074),
    .DI(sig00000161),
    .S(sig00000098),
    .O(sig00000077)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000005d (
    .I0(sig0000013b),
    .I1(sig00000161),
    .O(sig00000098)
  );
  XORCY   blk0000005e (
    .CI(sig00000069),
    .LI(sig00000094),
    .O(sig0000018c)
  );
  MUXCY   blk0000005f (
    .CI(sig00000069),
    .DI(sig00000160),
    .S(sig00000094),
    .O(sig00000074)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000060 (
    .I0(sig00000136),
    .I1(sig00000160),
    .O(sig00000094)
  );
  XORCY   blk00000061 (
    .CI(sig0000005e),
    .LI(sig00000089),
    .O(sig00000181)
  );
  MUXCY   blk00000062 (
    .CI(sig0000005e),
    .DI(sig0000015b),
    .S(sig00000089),
    .O(sig00000069)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000063 (
    .I0(sig0000012b),
    .I1(sig0000015b),
    .O(sig00000089)
  );
  XORCY   blk00000064 (
    .CI(sig00000012),
    .LI(sig0000007e),
    .O(sig00000176)
  );
  MUXCY   blk00000065 (
    .CI(sig00000012),
    .DI(sig00000150),
    .S(sig0000007e),
    .O(sig0000005e)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000066 (
    .I0(sig0000012a),
    .I1(sig00000150),
    .O(sig0000007e)
  );
  XORCY   blk00000067 (
    .CI(sig00000022),
    .LI(sig0000003a),
    .O(sig0000015f)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000068 (
    .I0(sig00000111),
    .I1(sig00000122),
    .O(sig0000003a)
  );
  XORCY   blk00000069 (
    .CI(sig00000021),
    .LI(sig00000039),
    .O(sig0000015e)
  );
  MUXCY   blk0000006a (
    .CI(sig00000021),
    .DI(sig00000111),
    .S(sig00000039),
    .O(sig00000022)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000006b (
    .I0(sig00000121),
    .I1(sig00000111),
    .O(sig00000039)
  );
  XORCY   blk0000006c (
    .CI(sig00000020),
    .LI(sig00000038),
    .O(sig0000015d)
  );
  MUXCY   blk0000006d (
    .CI(sig00000020),
    .DI(sig00000111),
    .S(sig00000038),
    .O(sig00000021)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000006e (
    .I0(sig00000120),
    .I1(sig00000111),
    .O(sig00000038)
  );
  XORCY   blk0000006f (
    .CI(sig0000001e),
    .LI(sig00000037),
    .O(sig0000015c)
  );
  MUXCY   blk00000070 (
    .CI(sig0000001e),
    .DI(sig00000111),
    .S(sig00000037),
    .O(sig00000020)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000071 (
    .I0(sig0000011f),
    .I1(sig00000111),
    .O(sig00000037)
  );
  XORCY   blk00000072 (
    .CI(sig0000001d),
    .LI(sig00000035),
    .O(sig0000015a)
  );
  MUXCY   blk00000073 (
    .CI(sig0000001d),
    .DI(sig00000111),
    .S(sig00000035),
    .O(sig0000001e)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000074 (
    .I0(sig0000011d),
    .I1(sig00000111),
    .O(sig00000035)
  );
  XORCY   blk00000075 (
    .CI(sig0000001c),
    .LI(sig00000034),
    .O(sig00000159)
  );
  MUXCY   blk00000076 (
    .CI(sig0000001c),
    .DI(sig00000111),
    .S(sig00000034),
    .O(sig0000001d)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000077 (
    .I0(sig0000011c),
    .I1(sig00000111),
    .O(sig00000034)
  );
  XORCY   blk00000078 (
    .CI(sig0000001b),
    .LI(sig00000033),
    .O(sig00000158)
  );
  MUXCY   blk00000079 (
    .CI(sig0000001b),
    .DI(sig00000111),
    .S(sig00000033),
    .O(sig0000001c)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000007a (
    .I0(sig0000011b),
    .I1(sig00000111),
    .O(sig00000033)
  );
  XORCY   blk0000007b (
    .CI(sig0000001a),
    .LI(sig00000032),
    .O(sig00000157)
  );
  MUXCY   blk0000007c (
    .CI(sig0000001a),
    .DI(sig00000110),
    .S(sig00000032),
    .O(sig0000001b)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000007d (
    .I0(sig00000110),
    .I1(sig0000011a),
    .O(sig00000032)
  );
  XORCY   blk0000007e (
    .CI(sig00000019),
    .LI(sig00000031),
    .O(sig00000156)
  );
  MUXCY   blk0000007f (
    .CI(sig00000019),
    .DI(sig0000010f),
    .S(sig00000031),
    .O(sig0000001a)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000080 (
    .I0(sig0000010f),
    .I1(sig00000119),
    .O(sig00000031)
  );
  XORCY   blk00000081 (
    .CI(sig00000018),
    .LI(sig00000030),
    .O(sig00000155)
  );
  MUXCY   blk00000082 (
    .CI(sig00000018),
    .DI(sig0000010e),
    .S(sig00000030),
    .O(sig00000019)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000083 (
    .I0(sig0000010e),
    .I1(sig00000118),
    .O(sig00000030)
  );
  XORCY   blk00000084 (
    .CI(sig00000017),
    .LI(sig0000002f),
    .O(sig00000154)
  );
  MUXCY   blk00000085 (
    .CI(sig00000017),
    .DI(sig0000010d),
    .S(sig0000002f),
    .O(sig00000018)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000086 (
    .I0(sig0000010d),
    .I1(sig00000117),
    .O(sig0000002f)
  );
  XORCY   blk00000087 (
    .CI(sig00000016),
    .LI(sig0000002e),
    .O(sig00000153)
  );
  MUXCY   blk00000088 (
    .CI(sig00000016),
    .DI(sig0000010c),
    .S(sig0000002e),
    .O(sig00000017)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000089 (
    .I0(sig0000010c),
    .I1(sig00000116),
    .O(sig0000002e)
  );
  XORCY   blk0000008a (
    .CI(sig00000015),
    .LI(sig0000002d),
    .O(sig00000152)
  );
  MUXCY   blk0000008b (
    .CI(sig00000015),
    .DI(sig0000010b),
    .S(sig0000002d),
    .O(sig00000016)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000008c (
    .I0(sig0000010b),
    .I1(sig00000115),
    .O(sig0000002d)
  );
  XORCY   blk0000008d (
    .CI(sig0000002a),
    .LI(sig0000002c),
    .O(sig00000151)
  );
  MUXCY   blk0000008e (
    .CI(sig0000002a),
    .DI(sig0000010a),
    .S(sig0000002c),
    .O(sig00000015)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000008f (
    .I0(sig0000010a),
    .I1(sig00000114),
    .O(sig0000002c)
  );
  XORCY   blk00000090 (
    .CI(sig00000029),
    .LI(sig00000042),
    .O(sig00000167)
  );
  MUXCY   blk00000091 (
    .CI(sig00000029),
    .DI(sig00000109),
    .S(sig00000042),
    .O(sig0000002a)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000092 (
    .I0(sig00000109),
    .I1(sig00000129),
    .O(sig00000042)
  );
  XORCY   blk00000093 (
    .CI(sig00000028),
    .LI(sig00000041),
    .O(sig00000166)
  );
  MUXCY   blk00000094 (
    .CI(sig00000028),
    .DI(sig00000108),
    .S(sig00000041),
    .O(sig00000029)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000095 (
    .I0(sig00000108),
    .I1(sig00000128),
    .O(sig00000041)
  );
  XORCY   blk00000096 (
    .CI(sig00000027),
    .LI(sig00000040),
    .O(sig00000165)
  );
  MUXCY   blk00000097 (
    .CI(sig00000027),
    .DI(sig00000107),
    .S(sig00000040),
    .O(sig00000028)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000098 (
    .I0(sig00000107),
    .I1(sig00000127),
    .O(sig00000040)
  );
  XORCY   blk00000099 (
    .CI(sig00000026),
    .LI(sig0000003f),
    .O(sig00000164)
  );
  MUXCY   blk0000009a (
    .CI(sig00000026),
    .DI(sig00000106),
    .S(sig0000003f),
    .O(sig00000027)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000009b (
    .I0(sig00000106),
    .I1(sig00000126),
    .O(sig0000003f)
  );
  XORCY   blk0000009c (
    .CI(sig00000025),
    .LI(sig0000003e),
    .O(sig00000163)
  );
  MUXCY   blk0000009d (
    .CI(sig00000025),
    .DI(sig00000105),
    .S(sig0000003e),
    .O(sig00000026)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000009e (
    .I0(sig00000105),
    .I1(sig00000125),
    .O(sig0000003e)
  );
  XORCY   blk0000009f (
    .CI(sig00000024),
    .LI(sig0000003d),
    .O(sig00000162)
  );
  MUXCY   blk000000a0 (
    .CI(sig00000024),
    .DI(sig00000104),
    .S(sig0000003d),
    .O(sig00000025)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000a1 (
    .I0(sig00000104),
    .I1(sig00000124),
    .O(sig0000003d)
  );
  XORCY   blk000000a2 (
    .CI(sig00000023),
    .LI(sig0000003c),
    .O(sig00000161)
  );
  MUXCY   blk000000a3 (
    .CI(sig00000023),
    .DI(sig00000103),
    .S(sig0000003c),
    .O(sig00000024)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000a4 (
    .I0(sig00000103),
    .I1(sig00000123),
    .O(sig0000003c)
  );
  XORCY   blk000000a5 (
    .CI(sig0000001f),
    .LI(sig0000003b),
    .O(sig00000160)
  );
  MUXCY   blk000000a6 (
    .CI(sig0000001f),
    .DI(sig00000102),
    .S(sig0000003b),
    .O(sig00000023)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000a7 (
    .I0(sig00000102),
    .I1(sig0000011e),
    .O(sig0000003b)
  );
  XORCY   blk000000a8 (
    .CI(sig00000014),
    .LI(sig00000036),
    .O(sig0000015b)
  );
  MUXCY   blk000000a9 (
    .CI(sig00000014),
    .DI(sig00000101),
    .S(sig00000036),
    .O(sig0000001f)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000aa (
    .I0(sig00000101),
    .I1(sig00000113),
    .O(sig00000036)
  );
  XORCY   blk000000ab (
    .CI(sig00000012),
    .LI(sig0000002b),
    .O(sig00000150)
  );
  MUXCY   blk000000ac (
    .CI(sig00000012),
    .DI(sig00000100),
    .S(sig0000002b),
    .O(sig00000014)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000ad (
    .I0(sig00000100),
    .I1(sig00000112),
    .O(sig0000002b)
  );
  XORCY   blk000000ae (
    .CI(sig00000046),
    .LI(sig00000054),
    .O(sig0000016c)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000af (
    .I0(sig0000013a),
    .I1(sig00000147),
    .O(sig00000054)
  );
  XORCY   blk000000b0 (
    .CI(sig00000045),
    .LI(sig00000053),
    .O(sig0000016b)
  );
  MUXCY   blk000000b1 (
    .CI(sig00000045),
    .DI(sig0000013a),
    .S(sig00000053),
    .O(sig00000046)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000b2 (
    .I0(sig00000146),
    .I1(sig0000013a),
    .O(sig00000053)
  );
  XORCY   blk000000b3 (
    .CI(sig00000044),
    .LI(sig00000052),
    .O(sig0000016a)
  );
  MUXCY   blk000000b4 (
    .CI(sig00000044),
    .DI(sig0000013a),
    .S(sig00000052),
    .O(sig00000045)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000b5 (
    .I0(sig00000145),
    .I1(sig0000013a),
    .O(sig00000052)
  );
  XORCY   blk000000b6 (
    .CI(sig0000004f),
    .LI(sig00000051),
    .O(sig00000169)
  );
  MUXCY   blk000000b7 (
    .CI(sig0000004f),
    .DI(sig0000013a),
    .S(sig00000051),
    .O(sig00000044)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000b8 (
    .I0(sig00000144),
    .I1(sig0000013a),
    .O(sig00000051)
  );
  XORCY   blk000000b9 (
    .CI(sig0000004e),
    .LI(sig0000005d),
    .O(sig00000175)
  );
  MUXCY   blk000000ba (
    .CI(sig0000004e),
    .DI(sig0000013a),
    .S(sig0000005d),
    .O(sig0000004f)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000bb (
    .I0(sig0000014f),
    .I1(sig0000013a),
    .O(sig0000005d)
  );
  XORCY   blk000000bc (
    .CI(sig0000004d),
    .LI(sig0000005c),
    .O(sig00000174)
  );
  MUXCY   blk000000bd (
    .CI(sig0000004d),
    .DI(sig0000013a),
    .S(sig0000005c),
    .O(sig0000004e)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000be (
    .I0(sig0000014e),
    .I1(sig0000013a),
    .O(sig0000005c)
  );
  XORCY   blk000000bf (
    .CI(sig0000004c),
    .LI(sig0000005b),
    .O(sig00000173)
  );
  MUXCY   blk000000c0 (
    .CI(sig0000004c),
    .DI(sig0000013a),
    .S(sig0000005b),
    .O(sig0000004d)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000c1 (
    .I0(sig0000014d),
    .I1(sig0000013a),
    .O(sig0000005b)
  );
  XORCY   blk000000c2 (
    .CI(sig0000004b),
    .LI(sig0000005a),
    .O(sig00000172)
  );
  MUXCY   blk000000c3 (
    .CI(sig0000004b),
    .DI(sig0000013a),
    .S(sig0000005a),
    .O(sig0000004c)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000c4 (
    .I0(sig0000014c),
    .I1(sig0000013a),
    .O(sig0000005a)
  );
  XORCY   blk000000c5 (
    .CI(sig0000004a),
    .LI(sig00000059),
    .O(sig00000171)
  );
  MUXCY   blk000000c6 (
    .CI(sig0000004a),
    .DI(sig00000139),
    .S(sig00000059),
    .O(sig0000004b)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000c7 (
    .I0(sig00000139),
    .I1(sig0000014b),
    .O(sig00000059)
  );
  XORCY   blk000000c8 (
    .CI(sig00000049),
    .LI(sig00000058),
    .O(sig00000170)
  );
  MUXCY   blk000000c9 (
    .CI(sig00000049),
    .DI(sig00000138),
    .S(sig00000058),
    .O(sig0000004a)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000ca (
    .I0(sig00000138),
    .I1(sig0000014a),
    .O(sig00000058)
  );
  XORCY   blk000000cb (
    .CI(sig00000048),
    .LI(sig00000057),
    .O(sig0000016f)
  );
  MUXCY   blk000000cc (
    .CI(sig00000048),
    .DI(sig00000137),
    .S(sig00000057),
    .O(sig00000049)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000cd (
    .I0(sig00000137),
    .I1(sig00000149),
    .O(sig00000057)
  );
  XORCY   blk000000ce (
    .CI(sig00000047),
    .LI(sig00000056),
    .O(sig0000016e)
  );
  MUXCY   blk000000cf (
    .CI(sig00000047),
    .DI(sig00000135),
    .S(sig00000056),
    .O(sig00000048)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000d0 (
    .I0(sig00000135),
    .I1(sig00000148),
    .O(sig00000056)
  );
  XORCY   blk000000d1 (
    .CI(sig00000043),
    .LI(sig00000055),
    .O(sig0000016d)
  );
  MUXCY   blk000000d2 (
    .CI(sig00000043),
    .DI(sig00000134),
    .S(sig00000055),
    .O(sig00000047)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000d3 (
    .I0(sig00000134),
    .I1(sig00000143),
    .O(sig00000055)
  );
  XORCY   blk000000d4 (
    .CI(sig00000012),
    .LI(sig00000050),
    .O(sig00000168)
  );
  MUXCY   blk000000d5 (
    .CI(sig00000012),
    .DI(sig00000133),
    .S(sig00000050),
    .O(sig00000043)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk000000d6 (
    .I0(sig00000133),
    .I1(sig00000142),
    .O(sig00000050)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000d7 (
    .C(clk),
    .D(sig0000018f),
    .Q(p[47])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000d8 (
    .C(clk),
    .D(sig0000018b),
    .Q(p[46])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000d9 (
    .C(clk),
    .D(sig0000018a),
    .Q(p[45])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000da (
    .C(clk),
    .D(sig00000189),
    .Q(p[44])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000db (
    .C(clk),
    .D(sig00000188),
    .Q(p[43])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000dc (
    .C(clk),
    .D(sig00000187),
    .Q(p[42])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000dd (
    .C(clk),
    .D(sig00000186),
    .Q(p[41])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000de (
    .C(clk),
    .D(sig00000185),
    .Q(p[40])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000df (
    .C(clk),
    .D(sig00000184),
    .Q(p[39])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000e0 (
    .C(clk),
    .D(sig00000183),
    .Q(p[38])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000e1 (
    .C(clk),
    .D(sig00000182),
    .Q(p[37])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000e2 (
    .C(clk),
    .D(sig00000180),
    .Q(p[36])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000e3 (
    .C(clk),
    .D(sig0000017f),
    .Q(p[35])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000e4 (
    .C(clk),
    .D(sig0000017e),
    .Q(p[34])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000e5 (
    .C(clk),
    .D(sig0000017d),
    .Q(p[33])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000e6 (
    .C(clk),
    .D(sig0000017c),
    .Q(p[32])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000e7 (
    .C(clk),
    .D(sig0000017b),
    .Q(p[31])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000e8 (
    .C(clk),
    .D(sig0000017a),
    .Q(p[30])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000e9 (
    .C(clk),
    .D(sig00000179),
    .Q(p[29])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000ea (
    .C(clk),
    .D(sig00000178),
    .Q(p[28])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000eb (
    .C(clk),
    .D(sig00000177),
    .Q(p[27])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000ec (
    .C(clk),
    .D(sig00000194),
    .Q(p[26])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000ed (
    .C(clk),
    .D(sig00000193),
    .Q(p[25])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000ee (
    .C(clk),
    .D(sig00000192),
    .Q(p[24])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000ef (
    .C(clk),
    .D(sig00000191),
    .Q(p[23])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000f0 (
    .C(clk),
    .D(sig00000190),
    .Q(p[22])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000f1 (
    .C(clk),
    .D(sig0000018e),
    .Q(p[21])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000f2 (
    .C(clk),
    .D(sig0000018d),
    .Q(p[20])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000f3 (
    .C(clk),
    .D(sig0000018c),
    .Q(p[19])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000f4 (
    .C(clk),
    .D(sig00000181),
    .Q(p[18])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000f5 (
    .C(clk),
    .D(sig00000176),
    .Q(p[17])
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000f6 (
    .C(clk),
    .D(sig000000f6),
    .Q(sig00000147)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000f7 (
    .C(clk),
    .D(sig000000f5),
    .Q(sig00000146)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000f8 (
    .C(clk),
    .D(sig000000f4),
    .Q(sig00000145)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000f9 (
    .C(clk),
    .D(sig000000f3),
    .Q(sig00000144)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000fa (
    .C(clk),
    .D(sig000000ff),
    .Q(sig0000014f)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000fb (
    .C(clk),
    .D(sig000000fe),
    .Q(sig0000014e)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000fc (
    .C(clk),
    .D(sig000000fd),
    .Q(sig0000014d)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000fd (
    .C(clk),
    .D(sig000000fc),
    .Q(sig0000014c)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000fe (
    .C(clk),
    .D(sig000000fb),
    .Q(sig0000014b)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk000000ff (
    .C(clk),
    .D(sig000000fa),
    .Q(sig0000014a)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000100 (
    .C(clk),
    .D(sig000000f9),
    .Q(sig00000149)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000101 (
    .C(clk),
    .D(sig000000f8),
    .Q(sig00000148)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000102 (
    .C(clk),
    .D(sig000000f7),
    .Q(sig00000143)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000103 (
    .C(clk),
    .D(sig000000f2),
    .Q(sig00000142)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000104 (
    .C(clk),
    .D(sig000000e9),
    .Q(sig0000013a)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000105 (
    .C(clk),
    .D(sig000000e8),
    .Q(sig00000139)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000106 (
    .C(clk),
    .D(sig000000e7),
    .Q(sig00000138)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000107 (
    .C(clk),
    .D(sig000000e6),
    .Q(sig00000137)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000108 (
    .C(clk),
    .D(sig000000e4),
    .Q(sig00000135)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000109 (
    .C(clk),
    .D(sig000000e3),
    .Q(sig00000134)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000010a (
    .C(clk),
    .D(sig000000e2),
    .Q(sig00000133)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000010b (
    .C(clk),
    .D(sig000000e1),
    .Q(sig00000132)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000010c (
    .C(clk),
    .D(sig000000e0),
    .Q(sig00000131)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000010d (
    .C(clk),
    .D(sig000000df),
    .Q(sig00000130)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000010e (
    .C(clk),
    .D(sig000000de),
    .Q(sig0000012f)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000010f (
    .C(clk),
    .D(sig000000dd),
    .Q(sig0000012e)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000110 (
    .C(clk),
    .D(sig000000dc),
    .Q(sig0000012d)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000111 (
    .C(clk),
    .D(sig000000db),
    .Q(sig0000012c)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000112 (
    .C(clk),
    .D(sig000000f1),
    .Q(sig00000141)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000113 (
    .C(clk),
    .D(sig000000f0),
    .Q(sig00000140)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000114 (
    .C(clk),
    .D(sig000000ef),
    .Q(sig0000013f)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000115 (
    .C(clk),
    .D(sig000000ee),
    .Q(sig0000013e)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000116 (
    .C(clk),
    .D(sig000000ed),
    .Q(sig0000013d)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000117 (
    .C(clk),
    .D(sig000000ec),
    .Q(sig0000013c)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000118 (
    .C(clk),
    .D(sig000000eb),
    .Q(sig0000013b)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000119 (
    .C(clk),
    .D(sig000000ea),
    .Q(sig00000136)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000011a (
    .C(clk),
    .D(sig000000e5),
    .Q(sig0000012b)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000011b (
    .C(clk),
    .D(sig000000da),
    .Q(sig0000012a)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000011c (
    .C(clk),
    .D(sig000000d1),
    .Q(sig00000122)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000011d (
    .C(clk),
    .D(sig000000d0),
    .Q(sig00000121)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000011e (
    .C(clk),
    .D(sig000000cf),
    .Q(sig00000120)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000011f (
    .C(clk),
    .D(sig000000ce),
    .Q(sig0000011f)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000120 (
    .C(clk),
    .D(sig000000cc),
    .Q(sig0000011d)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000121 (
    .C(clk),
    .D(sig000000cb),
    .Q(sig0000011c)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000122 (
    .C(clk),
    .D(sig000000ca),
    .Q(sig0000011b)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000123 (
    .C(clk),
    .D(sig000000c9),
    .Q(sig0000011a)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000124 (
    .C(clk),
    .D(sig000000c8),
    .Q(sig00000119)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000125 (
    .C(clk),
    .D(sig000000c7),
    .Q(sig00000118)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000126 (
    .C(clk),
    .D(sig000000c6),
    .Q(sig00000117)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000127 (
    .C(clk),
    .D(sig000000c5),
    .Q(sig00000116)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000128 (
    .C(clk),
    .D(sig000000c4),
    .Q(sig00000115)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000129 (
    .C(clk),
    .D(sig000000c3),
    .Q(sig00000114)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000012a (
    .C(clk),
    .D(sig000000d9),
    .Q(sig00000129)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000012b (
    .C(clk),
    .D(sig000000d8),
    .Q(sig00000128)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000012c (
    .C(clk),
    .D(sig000000d7),
    .Q(sig00000127)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000012d (
    .C(clk),
    .D(sig000000d6),
    .Q(sig00000126)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000012e (
    .C(clk),
    .D(sig000000d5),
    .Q(sig00000125)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000012f (
    .C(clk),
    .D(sig000000d4),
    .Q(sig00000124)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000130 (
    .C(clk),
    .D(sig000000d3),
    .Q(sig00000123)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000131 (
    .C(clk),
    .D(sig000000d2),
    .Q(sig0000011e)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000132 (
    .C(clk),
    .D(sig000000cd),
    .Q(sig00000113)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000133 (
    .C(clk),
    .D(sig000000c2),
    .Q(sig00000112)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000134 (
    .C(clk),
    .D(sig000000ba),
    .Q(sig00000111)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000135 (
    .C(clk),
    .D(sig000000b9),
    .Q(sig00000110)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000136 (
    .C(clk),
    .D(sig000000b8),
    .Q(sig0000010f)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000137 (
    .C(clk),
    .D(sig000000b7),
    .Q(sig0000010e)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000138 (
    .C(clk),
    .D(sig000000b6),
    .Q(sig0000010d)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000139 (
    .C(clk),
    .D(sig000000b4),
    .Q(sig0000010c)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000013a (
    .C(clk),
    .D(sig000000b3),
    .Q(sig0000010b)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000013b (
    .C(clk),
    .D(sig000000b2),
    .Q(sig0000010a)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000013c (
    .C(clk),
    .D(sig000000b1),
    .Q(sig00000109)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000013d (
    .C(clk),
    .D(sig000000b0),
    .Q(sig00000108)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000013e (
    .C(clk),
    .D(sig000000af),
    .Q(sig00000107)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000013f (
    .C(clk),
    .D(sig000000ae),
    .Q(sig00000106)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000140 (
    .C(clk),
    .D(sig000000ad),
    .Q(sig00000105)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000141 (
    .C(clk),
    .D(sig000000ac),
    .Q(sig00000104)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000142 (
    .C(clk),
    .D(sig000000ab),
    .Q(sig00000103)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000143 (
    .C(clk),
    .D(sig000000a9),
    .Q(sig00000102)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000144 (
    .C(clk),
    .D(sig000000a8),
    .Q(sig00000101)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000145 (
    .C(clk),
    .D(sig000000a7),
    .Q(sig00000100)
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk00000146 (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000a4),
    .Q(sig00000007)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000147 (
    .C(clk),
    .D(sig00000007),
    .Q(p[14])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk00000148 (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000a6),
    .Q(sig00000009)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000149 (
    .C(clk),
    .D(sig00000009),
    .Q(p[16])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk0000014a (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000a5),
    .Q(sig00000008)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000014b (
    .C(clk),
    .D(sig00000008),
    .Q(p[15])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk0000014c (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000a3),
    .Q(sig00000006)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000014d (
    .C(clk),
    .D(sig00000006),
    .Q(p[13])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk0000014e (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000a2),
    .Q(sig00000005)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000014f (
    .C(clk),
    .D(sig00000005),
    .Q(p[12])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk00000150 (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000a1),
    .Q(sig00000004)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000151 (
    .C(clk),
    .D(sig00000004),
    .Q(p[11])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk00000152 (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000a0),
    .Q(sig00000003)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000153 (
    .C(clk),
    .D(sig00000003),
    .Q(p[10])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk00000154 (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000c1),
    .Q(sig00000011)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000155 (
    .C(clk),
    .D(sig00000011),
    .Q(p[9])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk00000156 (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000c0),
    .Q(sig00000010)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000157 (
    .C(clk),
    .D(sig00000010),
    .Q(p[8])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk00000158 (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000bf),
    .Q(sig0000000f)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000159 (
    .C(clk),
    .D(sig0000000f),
    .Q(p[7])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk0000015a (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000be),
    .Q(sig0000000e)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000015b (
    .C(clk),
    .D(sig0000000e),
    .Q(p[6])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk0000015c (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000bd),
    .Q(sig0000000d)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000015d (
    .C(clk),
    .D(sig0000000d),
    .Q(p[5])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk0000015e (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000bc),
    .Q(sig0000000c)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk0000015f (
    .C(clk),
    .D(sig0000000c),
    .Q(p[4])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk00000160 (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000bb),
    .Q(sig0000000b)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000161 (
    .C(clk),
    .D(sig0000000b),
    .Q(p[3])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk00000162 (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000b5),
    .Q(sig0000000a)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000163 (
    .C(clk),
    .D(sig0000000a),
    .Q(p[2])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk00000164 (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig000000aa),
    .Q(sig00000002)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000165 (
    .C(clk),
    .D(sig00000002),
    .Q(p[1])
  );
  SRL16 #(
    .INIT ( 16'h0000 ))
  blk00000166 (
    .A0(sig00000012),
    .A1(sig00000012),
    .A2(sig00000012),
    .A3(sig00000012),
    .CLK(clk),
    .D(sig0000009f),
    .Q(sig00000001)
  );
  FD #(
    .INIT ( 1'b0 ))
  blk00000167 (
    .C(clk),
    .D(sig00000001),
    .Q(p[0])
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

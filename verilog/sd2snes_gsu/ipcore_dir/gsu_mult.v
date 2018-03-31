////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2013 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: P.20131013
//  \   \         Application: netgen
//  /   /         Filename: gsu_mult.v
// /___/   /\     Timestamp: Sat Mar 31 14:00:26 2018
// \   \  /  \ 
//  \___\/\___\
//             
// Command	: -w -sim -ofmt verilog C:/Users/O/dev/sd2snes-gsu/verilog/sd2snes_gsu/ipcore_dir/tmp/_cg/gsu_mult.ngc C:/Users/O/dev/sd2snes-gsu/verilog/sd2snes_gsu/ipcore_dir/tmp/_cg/gsu_mult.v 
// Device	: 3s400pq208-4
// Input file	: C:/Users/O/dev/sd2snes-gsu/verilog/sd2snes_gsu/ipcore_dir/tmp/_cg/gsu_mult.ngc
// Output file	: C:/Users/O/dev/sd2snes-gsu/verilog/sd2snes_gsu/ipcore_dir/tmp/_cg/gsu_mult.v
// # of Modules	: 1
// Design Name	: gsu_mult
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

module gsu_mult (
  clk, p, a, b
)/* synthesis syn_black_box syn_noprune=1 */;
  input clk;
  output [15 : 0] p;
  input [7 : 0] a;
  input [7 : 0] b;
  
  // synthesis translate_off
  
  wire \blk00000001/sig00000023 ;
  wire \blk00000001/sig00000022 ;
  wire \blk00000001/sig00000021 ;
  wire \blk00000001/sig00000020 ;
  wire \blk00000001/sig0000001f ;
  wire \blk00000001/sig0000001e ;
  wire \blk00000001/sig0000001d ;
  wire \blk00000001/sig0000001c ;
  wire \blk00000001/sig0000001b ;
  wire \blk00000001/sig0000001a ;
  wire \blk00000001/sig00000019 ;
  wire \blk00000001/sig00000018 ;
  wire \blk00000001/sig00000017 ;
  wire \blk00000001/sig00000016 ;
  wire \blk00000001/sig00000015 ;
  wire \blk00000001/sig00000014 ;
  wire \blk00000001/sig00000013 ;
  wire \blk00000001/sig00000012 ;
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
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000014  (
    .C(clk),
    .D(\blk00000001/sig00000014 ),
    .Q(p[0])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000013  (
    .C(clk),
    .D(\blk00000001/sig0000001a ),
    .Q(p[1])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000012  (
    .C(clk),
    .D(\blk00000001/sig0000001b ),
    .Q(p[2])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000011  (
    .C(clk),
    .D(\blk00000001/sig0000001d ),
    .Q(p[3])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000010  (
    .C(clk),
    .D(\blk00000001/sig0000001e ),
    .Q(p[4])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000f  (
    .C(clk),
    .D(\blk00000001/sig0000001f ),
    .Q(p[5])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000e  (
    .C(clk),
    .D(\blk00000001/sig00000020 ),
    .Q(p[6])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000d  (
    .C(clk),
    .D(\blk00000001/sig00000021 ),
    .Q(p[7])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000c  (
    .C(clk),
    .D(\blk00000001/sig00000022 ),
    .Q(p[8])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000b  (
    .C(clk),
    .D(\blk00000001/sig00000023 ),
    .Q(p[9])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000000a  (
    .C(clk),
    .D(\blk00000001/sig00000015 ),
    .Q(p[10])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000009  (
    .C(clk),
    .D(\blk00000001/sig00000016 ),
    .Q(p[11])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000008  (
    .C(clk),
    .D(\blk00000001/sig00000017 ),
    .Q(p[12])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000007  (
    .C(clk),
    .D(\blk00000001/sig00000018 ),
    .Q(p[13])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000006  (
    .C(clk),
    .D(\blk00000001/sig00000019 ),
    .Q(p[14])
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000005  (
    .C(clk),
    .D(\blk00000001/sig0000001c ),
    .Q(p[15])
  );
  MULT18X18S   \blk00000001/blk00000004  (
    .C(clk),
    .CE(\blk00000001/sig00000013 ),
    .R(\blk00000001/sig00000012 ),
    .A({a[7], a[7], a[7], a[7], a[7], a[7], a[7], a[7], a[7], a[7], a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0]}),
    .B({b[7], b[7], b[7], b[7], b[7], b[7], b[7], b[7], b[7], b[7], b[7], b[6], b[5], b[4], b[3], b[2], b[1], b[0]}),
    .P({\blk00000001/sig0000001c , \NLW_blk00000001/blk00000004_P<34>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<33>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<32>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<31>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<30>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<29>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<28>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<27>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<26>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<25>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<24>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<23>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<22>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<21>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<20>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<19>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<18>_UNCONNECTED , 
\NLW_blk00000001/blk00000004_P<17>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<16>_UNCONNECTED , \NLW_blk00000001/blk00000004_P<15>_UNCONNECTED , 
\blk00000001/sig00000019 , \blk00000001/sig00000018 , \blk00000001/sig00000017 , \blk00000001/sig00000016 , \blk00000001/sig00000015 , 
\blk00000001/sig00000023 , \blk00000001/sig00000022 , \blk00000001/sig00000021 , \blk00000001/sig00000020 , \blk00000001/sig0000001f , 
\blk00000001/sig0000001e , \blk00000001/sig0000001d , \blk00000001/sig0000001b , \blk00000001/sig0000001a , \blk00000001/sig00000014 })
  );
  VCC   \blk00000001/blk00000003  (
    .P(\blk00000001/sig00000013 )
  );
  GND   \blk00000001/blk00000002  (
    .G(\blk00000001/sig00000012 )
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

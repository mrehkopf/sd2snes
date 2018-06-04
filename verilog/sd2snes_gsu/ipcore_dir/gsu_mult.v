////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2013 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: P.20131013
//  \   \         Application: netgen
//  /   /         Filename: gsu_mult.v
// /___/   /\     Timestamp: Sun Apr 22 08:48:28 2018
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
p, a, b
)/* synthesis syn_black_box syn_noprune=1 */;
  output [15 : 0] p;
  input [7 : 0] a;
  input [7 : 0] b;
  
  // synthesis translate_off
  
  wire \NLW_blk00000001/blk00000002_P<34>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<33>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<32>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<31>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<30>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<29>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<28>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<27>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<26>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<25>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<24>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<23>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<22>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<21>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<20>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<19>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<18>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<17>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<16>_UNCONNECTED ;
  wire \NLW_blk00000001/blk00000002_P<15>_UNCONNECTED ;
  MULT18X18   \blk00000001/blk00000002  (
    .A({a[7], a[7], a[7], a[7], a[7], a[7], a[7], a[7], a[7], a[7], a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0]}),
    .B({b[7], b[7], b[7], b[7], b[7], b[7], b[7], b[7], b[7], b[7], b[7], b[6], b[5], b[4], b[3], b[2], b[1], b[0]}),
    .P({p[15], \NLW_blk00000001/blk00000002_P<34>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<33>_UNCONNECTED , 
\NLW_blk00000001/blk00000002_P<32>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<31>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<30>_UNCONNECTED , 
\NLW_blk00000001/blk00000002_P<29>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<28>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<27>_UNCONNECTED , 
\NLW_blk00000001/blk00000002_P<26>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<25>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<24>_UNCONNECTED , 
\NLW_blk00000001/blk00000002_P<23>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<22>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<21>_UNCONNECTED , 
\NLW_blk00000001/blk00000002_P<20>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<19>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<18>_UNCONNECTED , 
\NLW_blk00000001/blk00000002_P<17>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<16>_UNCONNECTED , \NLW_blk00000001/blk00000002_P<15>_UNCONNECTED , 
p[14], p[13], p[12], p[11], p[10], p[9], p[8], p[7], p[6], p[5], p[4], p[3], p[2], p[1], p[0]})
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

`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:   09:28:48 05/31/2011
// Design Name:   upd77c25
// Module Name:   /home/ikari/prj/sd2snes/verilog/sd2snes/updtest.tf
// Project Name:  sd2snes
// Target Device:
// Tool versions:
// Description:
//
// Verilog Test Fixture created by ISE for module: upd77c25
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

module updtest;

  // Inputs
  reg [7:0] DI;
  reg A0;
  reg nCS;
  reg nRD;
  reg nWR;
  reg RST;
  reg CLK;
  reg PGM_WR;
  reg [23:0] PGM_DI;
  reg [10:0] PGM_WR_ADDR;
  reg DAT_WR;
  reg [15:0] DAT_DI;
  reg [9:0] DAT_WR_ADDR;

  // debug
  wire [15:0] SR;
  wire [15:0] DR;
  wire [10:0] PC;
  wire [15:0] A;
  wire [15:0] B;
  wire [5:0] FL_A;
  wire [5:0] FL_B;

  // Outputs
  wire [7:0] DO;

   // variables
  integer i;

  // Instantiate the Unit Under Test (UUT)
  upd77c25 uut (
    .DI(DI),
    .DO(DO),
    .A0(A0),
    .nCS(nCS),
    .nRD(nRD),
    .nWR(nWR),
    .DP_nCS(1'b1),
    .RST(RST),
    .CLK(CLK),
    .PGM_WR(PGM_WR),
    .PGM_DI(PGM_DI),
    .PGM_WR_ADDR(PGM_WR_ADDR),
    .DAT_WR(DAT_WR),
    .DAT_DI(DAT_DI),
    .DAT_WR_ADDR(DAT_WR_ADDR),
    .SR(SR),
    .DR(DR),
    .PC(PC),
    .A(A),
    .B(B),
    .FL_A(FL_A),
    .FL_B(FL_B)
  );

  initial begin
    // Initialize Inputs
    DI = 0;
    A0 = 0;
    nCS = 0;
    nRD = 1;
    nWR = 1;
    RST = 1;
    CLK = 0;
    PGM_WR = 0;
    PGM_DI = 0;
    PGM_WR_ADDR = 0;
    DAT_WR = 0;
    DAT_DI = 0;
    DAT_WR_ADDR = 0;

    // Wait 100 ns for global reset to finish
    #1000;

    // Add stimulus here
    nRD = 0;

    #100 nRD = 1;
    for (i=0; i < 1; i = i + 1) begin
      #200 nRD = 0;
      #200 nRD = 1;
    end
    #1000 DI = 8'h02;
         nWR = 0;
    #200 nWR = 1;
    #3000 DI = 8'hc2;
    for (i=0; i < 6; i = i + 1) begin
      #400 nWR = 0;
      #400 nWR = 1;
      #400 nWR = 0;
      #400 nWR = 1;
    end
    #15000;
    #200 nWR = 0;
    #200 nWR = 1;
    #200 nWR = 0;
    #200 nWR = 1;
    #50000;
    for (i=0; i < 10; i = i + 1) begin
      #200 nRD = 0;
      #200 nRD = 1;
    end
    #200 DI = 8'h06;
         nWR = 0;
    #200 nWR = 1;
    #200 DI = 8'h7f;
    for (i=0; i < 3; i = i + 1) begin
      #400 nWR = 0;
      #400 nWR = 1;
      #400 nWR = 0;
      #400 nWR = 1;
    end
    #15000;
    for (i=0; i < 10; i = i + 1) begin
      #200 nRD = 0;
      #200 nRD = 1;
    end

  end

  always #6 CLK = ~CLK;
endmodule


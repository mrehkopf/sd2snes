`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:11:58 05/13/2009
// Design Name:   main
// Module Name:   /home/ikari/prj/sd2snes/verilog/sd2snes/tf_main.v
// Project Name:  sd2snes
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: main
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tf_main;

	// Inputs
	reg CLK;
	reg [2:0] MAPPER;
	reg [23:0] SNES_ADDR;
	reg SNES_READ;
	reg SNES_WRITE;
	reg SNES_CS;
	reg AVR_ENA;

	// Outputs
	wire [20:0] SRAM_ADDR;
	wire [3:0] ROM_SEL;
	wire SRAM_OE;
	wire SRAM_WE;
   wire SNES_DATABUS_OE;
   wire SNES_DATABUS_DIR;
   wire MODE;
   
	// Bidirs
	wire [7:0] SNES_DATA;
	wire [7:0] SRAM_DATA;
	wire [7:0] AVR_DATA;

   reg [7:0] SRAM_DATA_BUF;
   reg [7:0] SNES_DATA_BUF;
   
   		SCK = 0;
		MOSI = 0;
		SSEL = 1;
		input_data = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
      SSEL = 0;
      MOSI=1;
      #100 SCK=1;
      #100 SCK=0;
      MOSI=0;
      #100 SCK=1;
      #100 SCK=0;
      MOSI=0;
      #100 SCK=1;
      #100 SCK=0;
      MOSI=1;
      #100 SCK=1;
      #100 SCK=0;
      MOSI=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #200;
         #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #200;
         #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SCK=1;
      #100 SCK=0;
      #100 SSEL=1;
      
      
	end
   always begin
      #19 clk = ~clk;
   end
   
// Instantiate the Unit Under Test (UUT)
	main uut (
		.CLKIN(CLK), 
		.MAPPER(MAPPER), 
		.SNES_ADDR(SNES_ADDR), 
		.SNES_READ(SNES_READ), 
		.SNES_WRITE(SNES_WRITE), 
		.SNES_CS(SNES_CS), 
		.SNES_DATA(SNES_DATA), 
		.SRAM_DATA(SRAM_DATA), 
		.SRAM_ADDR(SRAM_ADDR), 
		.ROM_SEL(ROM_SEL), 
		.SRAM_OE(SRAM_OE), 
		.SRAM_WE(SRAM_WE), 
		.AVR_ENA(AVR_ENA), 
      .SNES_DATABUS_OE(SNES_DATABUS_OE),
      .SNES_DATABUS_DIR(SNES_DATABUS_DIR),
      .MODE(MODE)
	);
   
   assign SRAM_DATA = SRAM_DATA_BUF;
	initial begin
		// Initialize Inputs
		CLK = 1;
		MAPPER = 0;
		SNES_ADDR = 24'h223456;
		SNES_READ = 1;
		SNES_WRITE = 1;
		SNES_CS = 0;
		AVR_ENA = 1;
      SRAM_DATA_BUF = 8'hff;
		// Wait for global reset to finish
		#276;
      SNES_ADDR <= 24'h123456;
      SNES_READ <= 0;
      #176;
      SNES_READ <= 1;
      #100;      
      SNES_WRITE <= 0;
      #176;
      SNES_WRITE <= 1;
      #100;
      SNES_READ <= 0;
      #276;
//      AVR_READ <= 1;
		// Add stimulus here
	end

   always
      #23 CLK <= ~CLK;
//   always begin
//   end
      
endmodule


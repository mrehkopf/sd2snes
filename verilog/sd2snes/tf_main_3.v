`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   04:03:25 12/21/2009
// Design Name:   main
// Module Name:   /home/ikari/prj/sd2snes/verilog/sd2snes/tf_main_3.v
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

module tf_main_3;

	// Inputs
	reg CLKIN;
	reg [23:0] SNES_ADDR;
	reg SNES_READ;
	reg SNES_WRITE;
	reg SNES_CS;
	reg SNES_CPU_CLK;
	reg SNES_REFRESH;
	reg SPI_MOSI;
	reg SPI_SS;
	reg AVR_ENA;

	// Outputs
	wire SNES_DATABUS_OE;
	wire SNES_DATABUS_DIR;
	wire IRQ_DIR;
	wire [19:0] SRAM_ADDR;
	wire [3:0] SRAM_CE2;
	wire SRAM_OE;
	wire SRAM_WE;
	wire SRAM_BHE;
	wire SRAM_BLE;

	// Bidirs
	wire [7:0] SNES_DATA;
	wire SNES_IRQ;
	wire [15:0] SRAM_DATA;
	wire SPI_MISO;
	wire SPI_SCK;
	wire SPI_DMA_CTRL;
   
   reg SPI_DMA_CTRLdir;
   reg SPI_DMA_CTRLr;

   reg SPI_MISOdir;
   reg SPI_MISOr;
	// Instantiate the Unit Under Test (UUT)
	main uut (
		.CLKIN(CLKIN), 
		.SNES_ADDR(SNES_ADDR), 
		.SNES_READ(SNES_READ), 
		.SNES_WRITE(SNES_WRITE), 
		.SNES_CS(SNES_CS), 
		.SNES_DATA(SNES_DATA), 
		.SNES_CPU_CLK(SNES_CPU_CLK), 
		.SNES_REFRESH(SNES_REFRESH), 
		.SNES_IRQ(SNES_IRQ), 
		.SNES_DATABUS_OE(SNES_DATABUS_OE), 
		.SNES_DATABUS_DIR(SNES_DATABUS_DIR), 
		.IRQ_DIR(IRQ_DIR), 
		.SRAM_DATA(SRAM_DATA), 
		.SRAM_ADDR(SRAM_ADDR), 
		.SRAM_CE2(SRAM_CE2), 
		.SRAM_OE(SRAM_OE), 
		.SRAM_WE(SRAM_WE), 
		.SRAM_BHE(SRAM_BHE), 
		.SRAM_BLE(SRAM_BLE), 
		.SPI_MOSI(SPI_MOSI), 
		.SPI_MISO(SPI_MISO), 
		.SPI_SS(SPI_SS), 
		.SPI_SCK(SPI_SCK), 
		.AVR_ENA(AVR_ENA), 
		.SPI_DMA_CTRL(SPI_DMA_CTRL)
	);

	initial begin
		// Initialize Inputs
		CLKIN = 0;
		SNES_ADDR = 0;
		SNES_READ = 0;
		SNES_WRITE = 0;
		SNES_CS = 0;
		SNES_CPU_CLK = 0;
		SNES_REFRESH = 0;
		SPI_MOSI = 0;
		SPI_SS = 0;
		AVR_ENA = 0;
      SPI_DMA_CTRLr = 1;
      SPI_DMA_CTRLdir = 0;
      SPI_MISOr = 0;
      SPI_MISOdir = 0;
		// Wait 100 ns for global reset to finish
		#100;
      #600; // dcm?
		// Add stimulus here
      SPI_DMA_CTRLr = 1;
      SPI_DMA_CTRLdir = 1;
      #100 SPI_DMA_CTRLr = 0;
      #100 SPI_DMA_CTRLr = 1'bZ;
      SPI_DMA_CTRLdir = 0;
      SPI_MISOdir = 1;
      #260 SPI_MISOr = 1;
      #80 SPI_MISOr = 0;
      #80 SPI_MISOr = 0;
      #80 SPI_MISOr = 1;
      #80 SPI_MISOr = 0;
      #80 SPI_MISOr = 1;
      #80 SPI_MISOr = 0;
      #80 SPI_MISOr = 1;
	end
   
   assign SPI_DMA_CTRL = SPI_DMA_CTRLdir ? SPI_DMA_CTRLr : 1'bZ;
   assign SPI_MISO = SPI_MISOdir ? SPI_MISOr : 1'bZ;
   always #35 CLKIN = ~CLKIN;
endmodule


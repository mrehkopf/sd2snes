`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   00:20:33 07/14/2009
// Design Name:   main
// Module Name:   /home/ikari/prj/sd2snes/verilog/sd2snes/main_tf2.v
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

module main_tf2;

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
	reg SPI_SCK;
	reg AVR_ENA;

	// Outputs
	wire SNES_DATABUS_OE;
	wire SNES_DATABUS_DIR;
	wire [19:0] SRAM_ADDR;
	wire [3:0] ROM_SEL;
	wire SRAM_OE;
	wire SRAM_WE;
	wire SPI_MISO;
	wire MODE;
   wire SRAM_BHE;
   wire SRAM_BLE;
   
	// Bidirs
	wire [7:0] SNES_DATA;
	wire SNES_IRQ;
	wire [15:0] SRAM_DATA;

   reg [15:0] SRAM_DATA_BUF;
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
      .IRQ_DIR(IRQ_DIR),
		.SNES_DATABUS_OE(SNES_DATABUS_OE), 
		.SNES_DATABUS_DIR(SNES_DATABUS_DIR), 
		.SRAM_DATA(SRAM_DATA), 
		.SRAM_ADDR(SRAM_ADDR), 
		.SRAM_CE2(ROM_SEL), 
		.SRAM_OE(SRAM_OE), 
		.SRAM_WE(SRAM_WE), 
		.SPI_MOSI(SPI_MOSI), 
		.SPI_MISO(SPI_MISO), 
		.SPI_SS(SPI_SS), 
		.SPI_SCK(SPI_SCK), 
		.AVR_ENA(AVR_ENA), 
      .SRAM_BHE(SRAM_BHE),
      .SRAM_BLE(SRAM_BLE)
	);

	initial begin
		// Initialize Inputs
		CLKIN = 0;
		SNES_ADDR = 0;
		SNES_READ = 1;
		SNES_WRITE = 1;
		SNES_CS = 0;
		SNES_CPU_CLK = 0;
		SNES_REFRESH = 0;
		SPI_MOSI = 0;
		SPI_SS = 1;
		SPI_SCK = 0;
		AVR_ENA = 0;

		// Wait 100 ns for global reset to finish
		#100;
      // Wait for DCM to stabilize
      #5000;
		// Add stimulus here
		// Add stimulus here
      SPI_SS = 0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      #200;

      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      #200;

      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      #100 SPI_SS=1;
      #200;
      SPI_SS=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      #200;
      SPI_SS=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      #200;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      #200;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      #200;
      #100 SPI_SS=1;
      #200;
      SPI_SS=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      #200;
      SPI_SS=1;
      #200;
      
      /*
       * READ TEST
       */
       AVR_ENA=1;
      SPI_SS=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      #100;
      #100;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      #200;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      #200;
      SPI_SS=1;
      #300;
      SPI_SS=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      #200;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      #200;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      #200;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      #200;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;      
      #200;
      SPI_SS=1;
      AVR_ENA=1;
      #280;
  		// Initialize Inputs
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
      SPI_SS = 0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      #200;

      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      #200;

      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=0;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      SPI_MOSI=1;
      #100 SPI_SCK=1;
      #100 SPI_SCK=0;
      #100 SPI_SS=1;
      #200;


	end
   always begin
      #23 CLKIN = ~CLKIN;
   end
   always begin
      #150 SNES_READ = ~SNES_READ;
   end
   
endmodule


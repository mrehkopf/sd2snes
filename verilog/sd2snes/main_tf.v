`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:   14:40:38 05/31/2011
// Design Name:   main
// Module Name:   /home/ikari/prj/sd2snes/verilog/sd2snes/main_tf.v
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

module main_tf;

  // Inputs
  reg CLKIN;
  reg [23:0] SNES_ADDR;
  reg SNES_READ;
  reg SNES_WRITE;
  reg SNES_CS;
  reg SNES_CPU_CLK;
  reg SNES_REFRESH;
  reg SNES_SYSCLK;
  reg SPI_MOSI;
  reg SPI_SS;
  reg MCU_OVR;
  reg [3:0] SD_DAT;

  // Outputs
  wire SNES_DATABUS_OE;
  wire SNES_DATABUS_DIR;
  wire IRQ_DIR;
  wire [22:0] ROM_ADDR;
  wire ROM_CE;
  wire ROM_OE;
  wire ROM_WE;
  wire ROM_BHE;
  wire ROM_BLE;
  wire [18:0] RAM_ADDR;
  wire RAM_CE;
  wire RAM_OE;
  wire RAM_WE;
  wire DAC_MCLK;
  wire DAC_LRCK;
  wire DAC_SDOUT;

  // Bidirs
  wire [7:0] SNES_DATA;
  wire SNES_IRQ;
  wire [15:0] ROM_DATA;
  wire [7:0] RAM_DATA;
  wire SPI_MISO;
  wire SPI_SCK;
  wire SD_CMD;
  wire SD_CLK;

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
    .SNES_SYSCLK(SNES_SYSCLK),
    .ROM_DATA(ROM_DATA),
    .ROM_ADDR(ROM_ADDR),
    .ROM_CE(ROM_CE),
    .ROM_OE(ROM_OE),
    .ROM_WE(ROM_WE),
    .ROM_BHE(ROM_BHE),
    .ROM_BLE(ROM_BLE),
    .RAM_DATA(RAM_DATA),
    .RAM_ADDR(RAM_ADDR),
    .RAM_CE(RAM_CE),
    .RAM_OE(RAM_OE),
    .RAM_WE(RAM_WE),
    .SPI_MOSI(SPI_MOSI),
    .SPI_MISO(SPI_MISO),
    .SPI_SS(SPI_SS),
    .SPI_SCK(SPI_SCK),
    .MCU_OVR(MCU_OVR),
    .DAC_MCLK(DAC_MCLK),
    .DAC_LRCK(DAC_LRCK),
    .DAC_SDOUT(DAC_SDOUT),
    .SD_DAT(SD_DAT),
    .SD_CMD(SD_CMD),
    .SD_CLK(SD_CLK)
  );

  integer i;

  reg [7:0] SNES_DATA_OUT;
  reg [7:0] SNES_DATA_IN;

  assign SNES_DATA = (!SNES_READ) ? 8'bZ : SNES_DATA_IN;
  initial begin
    // Initialize Inputs
    CLKIN = 0;
    SNES_ADDR = 0;
    SNES_READ = 1;
    SNES_WRITE = 1;
    SNES_CS = 0;
    SNES_CPU_CLK = 0;
    SNES_REFRESH = 0;
    SNES_SYSCLK = 0;
    SPI_MOSI = 0;
    SPI_SS = 0;
    MCU_OVR = 1;
    SD_DAT = 0;

    // Wait 100 ns for global reset to finish
    #500;
     // Add stimulus here
         SNES_ADDR = 24'h208000;
         SNES_DATA_IN = 8'h1f;
         SNES_WRITE = 0;
    #100 SNES_WRITE = 1;
    #100;
    for (i = 0; i < 4096; i = i + 1) begin
      #140 SNES_READ = 0;
           SNES_CPU_CLK = 1;
      #140 SNES_READ = 1;
           SNES_CPU_CLK = 0;

    end


  end
   always #24 CLKIN = ~CLKIN;

endmodule


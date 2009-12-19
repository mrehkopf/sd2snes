`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:03:06 05/13/2009 
// Design Name: 
// Module Name:    data 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module data(
      input CLK,
      input SNES_READ,
      input SNES_WRITE,
      input AVR_READ,
      input AVR_WRITE,
      inout [7:0] SNES_DATA,
      inout [15:0] SRAM_DATA,
      input [7:0] AVR_IN_DATA,
      output [7:0] AVR_OUT_DATA,
      input MODE,
      input SNES_DATA_TO_MEM,
      input AVR_DATA_TO_MEM,
      input SRAM_DATA_TO_SNES_MEM,
      input SRAM_DATA_TO_AVR_MEM,
      input AVR_ENA,
      input SRAM_ADDR0
    );

reg [7:0] SNES_IN_MEM;
reg [7:0] SNES_OUT_MEM;
reg [7:0] AVR_IN_MEM;
reg [7:0] AVR_OUT_MEM;

wire [7:0] FROM_SRAM_BYTE;

assign SNES_DATA = SNES_READ ? 8'bZ : SNES_OUT_MEM;                   

assign FROM_SRAM_BYTE = (SRAM_ADDR0 ? SRAM_DATA[7:0] : SRAM_DATA[15:8]);

assign AVR_OUT_DATA = !AVR_ENA ? (FROM_SRAM_BYTE)
                  : (AVR_OUT_MEM);

assign SRAM_DATA[7:0] = SRAM_ADDR0 ? (!AVR_ENA ? (!AVR_WRITE ? AVR_IN_DATA : 8'bZ)
                                                : (MODE ? (!AVR_WRITE ? AVR_IN_MEM : 8'bZ)                   
                                                        : (!SNES_WRITE ? SNES_IN_MEM : 8'bZ)))
                                    :  8'bZ;
assign SRAM_DATA[15:8] = SRAM_ADDR0 ? 8'bZ : (!AVR_ENA ? (!AVR_WRITE ? AVR_IN_DATA : 8'bZ)
                                                : (MODE ? (!AVR_WRITE ? AVR_IN_MEM : 8'bZ)                   
                                                        : (!SNES_WRITE ? SNES_IN_MEM : 8'bZ)));
                                                        
always @(posedge CLK) begin
   if(SNES_DATA_TO_MEM)
      SNES_IN_MEM <= SNES_DATA;
   if(AVR_DATA_TO_MEM)
      AVR_IN_MEM <= AVR_IN_DATA;
   if(SRAM_DATA_TO_SNES_MEM)
      SNES_OUT_MEM <= FROM_SRAM_BYTE;
   if(SRAM_DATA_TO_AVR_MEM)
      AVR_OUT_MEM <= FROM_SRAM_BYTE;
end

endmodule

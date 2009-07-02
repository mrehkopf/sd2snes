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
      inout [7:0] SRAM_DATA,
      inout [7:0] AVR_DATA,
      input MODE,
      input SNES_DATA_TO_MEM,
      input AVR_DATA_TO_MEM,
      input SRAM_DATA_TO_SNES_MEM,
      input SRAM_DATA_TO_AVR_MEM,
      input AVR_ENA,
      input AVR_NEXTADDR_PREV,
      input AVR_NEXTADDR_CURR
    );

reg [7:0] SNES_IN_MEM;
reg [7:0] SNES_OUT_MEM;
reg [7:0] AVR_IN_MEM;
reg [7:0] AVR_OUT_MEM;

assign SNES_DATA = SNES_READ ? 8'bZ : SNES_OUT_MEM;                   

assign AVR_DATA = !AVR_ENA ? (!AVR_READ ? SRAM_DATA : 8'bZ)
                  : (AVR_READ ? 8'bZ : AVR_OUT_MEM);

assign SRAM_DATA = !AVR_ENA ? (!AVR_WRITE ? AVR_DATA : 8'bZ)//  /**/ : 8'bZ;
                   : MODE ? (!AVR_WRITE ? AVR_IN_MEM : 8'bZ)                   
                          : (!SNES_WRITE ? SNES_IN_MEM : 8'bZ);

always @(posedge CLK) begin
   if(SNES_DATA_TO_MEM)
      SNES_IN_MEM <= SNES_DATA;
   if(AVR_DATA_TO_MEM)
      AVR_IN_MEM <= AVR_DATA;
   if(SRAM_DATA_TO_SNES_MEM)
      SNES_OUT_MEM <= SRAM_DATA;
   if(SRAM_DATA_TO_AVR_MEM)
      AVR_OUT_MEM <= SRAM_DATA;
end


/*
always @(posedge SNES_DATA_TO_MEM) begin
   SNES_IN_MEM <= SNES_DATA;
end

always @(posedge AVR_DATA_TO_MEM) begin
   AVR_IN_MEM <= AVR_DATA;
end

always @(posedge SRAM_DATA_TO_SNES_MEM) begin
   SNES_OUT_MEM <= SRAM_DATA;
end

always @(posedge SRAM_DATA_TO_AVR_MEM) begin
   AVR_OUT_MEM <= SRAM_DATA;
end
*/
endmodule

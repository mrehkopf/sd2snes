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
      input MCU_READ,
      input MCU_WRITE,
      inout [7:0] SNES_DATA,
      inout [15:0] ROM_DATA,
      input [7:0] MCU_IN_DATA,
      output [7:0] MCU_OUT_DATA,
      input MODE,
      input SNES_DATA_TO_MEM,
      input MCU_DATA_TO_MEM,
      input ROM_DATA_TO_SNES_MEM,
      input ROM_DATA_TO_MCU_MEM,
      input MCU_OVR,
      input ROM_ADDR0,
		output [7:0] MSU_DATA_IN,
		input [7:0] MSU_DATA_OUT,
		output [7:0] BSX_DATA_IN,
		input [7:0] BSX_DATA_OUT,
		output [7:0] SRTC_DATA_IN,
		input [7:0] SRTC_DATA_OUT,
		input msu_enable,
		input bsx_data_ovr,
		input srtc_enable
    );

reg [7:0] SNES_IN_MEM;
reg [7:0] SNES_OUT_MEM;
reg [7:0] MCU_IN_MEM;
reg [7:0] MCU_OUT_MEM;

wire [7:0] FROM_ROM_BYTE;

assign MSU_DATA_IN = SNES_DATA;
assign BSX_DATA_IN = SNES_DATA;
assign SRTC_DATA_IN = SNES_DATA;

assign SNES_DATA = SNES_READ ? 8'bZ : (!MCU_OVR ? 8'h00 : (msu_enable ? MSU_DATA_OUT : 
                                                           bsx_data_ovr ? BSX_DATA_OUT : 
																			  srtc_enable ? SRTC_DATA_OUT : SNES_OUT_MEM));

assign FROM_ROM_BYTE = (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8]);

assign MCU_OUT_DATA = !MCU_OVR ? (FROM_ROM_BYTE)
                  : (MCU_OUT_MEM);

assign ROM_DATA[7:0] = ROM_ADDR0 ? (!MCU_OVR ? (!MCU_WRITE ? MCU_IN_DATA : 8'bZ)
                                                : (MODE ? (!MCU_WRITE ? MCU_IN_MEM : 8'bZ)                   
                                                        : (!SNES_WRITE ? SNES_IN_MEM : 8'bZ)))
                                    :  8'bZ;
assign ROM_DATA[15:8] = ROM_ADDR0 ? 8'bZ : (!MCU_OVR ? (!MCU_WRITE ? MCU_IN_DATA : 8'bZ)
                                                : (MODE ? (!MCU_WRITE ? MCU_IN_MEM : 8'bZ)                   
                                                        : (!SNES_WRITE ? SNES_IN_MEM : 8'bZ)));
                                                        
always @(posedge CLK) begin
   if(SNES_DATA_TO_MEM)
      SNES_IN_MEM <= SNES_DATA;
   if(MCU_DATA_TO_MEM)
      MCU_IN_MEM <= MCU_IN_DATA;
   if(ROM_DATA_TO_SNES_MEM)
      SNES_OUT_MEM <= FROM_ROM_BYTE;
   if(ROM_DATA_TO_MCU_MEM)
      MCU_OUT_MEM <= FROM_ROM_BYTE;
end

endmodule

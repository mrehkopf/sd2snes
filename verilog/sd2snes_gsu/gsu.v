`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    06:32:24 02/24/2018 
// Design Name: 
// Module Name:    gsu 
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
module gsu(
  input         RST,
  input         CLK,
  
  // MMIO interface
  input         ENABLE,
  input         SNES_RD_start,
  input         SNES_WR_end,
  input  [23:0] SNES_ADDR,
  input  [7:0]  GSU_DATA_IN,
  output [7:0]  GSU_DATA_OUT,
  
  // State debug read interface
  input  [9:0]  PGM_ADDR, // [9:0]
  output [7:0]  PGM_DATA, // [7:0]
  
  output DBG
);

//-------------------------------------------------------------------
// STATE
//-------------------------------------------------------------------
reg [15:0] REG_r   [15:0];

// Special Registers
reg [15:0] SFR_r;   // 3030-3031
reg [7:0]  BRAMR_r; // 3033
reg [7:0]  PBR_r;   // 3034
reg [7:0]  ROMBR_r; // 3036
reg [7:0]  CFGR_r;  // 3037
reg [7:0]  SCBR_r;  // 3038
reg [7:0]  CLSR_r;  // 3039
reg [7:0]  SCMR_r;  // 303A
reg [7:0]  VCR_r;   // 303B
reg [7:0]  RAMBR_r; // 303C
// unmapped
reg [7:0]  COLR_r;
reg [7:0]  POR_r;
reg [7:0]  SREG_r;
reg [7:0]  DREG_r;
reg [7:0]  ROMRDBUF_r;
reg [7:0]  RAMWRBUF_r;
reg [15:0] RAMADDR_r;

// FIXME: Pixel Buffer

// Cache
// interface
wire       cache_wren;
wire [9:0] cache_wraddr;
wire [7:0] cache_wrdata;
wire [9:0] cache_rdaddr;
wire [7:0] cache_rddata;

assign cache_wren = 0;

gsu_cache cache (
  .clka(CLK), // input clka
  .wea(cache_wren), // input [0 : 0] wea
  .addra(cache_wraddr), // input [9 : 0] addra
  .dina(cache_wrdata), // input [7 : 0] dina
  .clkb(CLK), // input clkb
  .addrb(cache_rdaddr), // input [9 : 0] addrb
  .doutb(cache_rddata) // output [7 : 0] doutb
);

// Debug State

//-------------------------------------------------------------------
// MMIO
//-------------------------------------------------------------------

//-------------------------------------------------------------------
// EXECUTION PIPELINE
//-------------------------------------------------------------------

//-------------------------------------------------------------------
// MISC OUTPUTS
//-------------------------------------------------------------------
assign DBG = 0;
assign GSU_DATA_OUT = 0;

endmodule

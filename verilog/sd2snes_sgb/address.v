`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// Company: Rehkopf
// Engineer: Rehkopf
//
// Create Date:    01:13:46 05/09/2009
// Design Name:
// Module Name:    address
// Project Name:
// Target Devices:
// Tool versions:
// Description: Address logic w/ SaveRAM masking
//
// Dependencies:
//
// Revision:
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`define SGB_HOOK

module address(
  input CLK,
  input [15:0] featurebits, // peripheral enable/disable
  //input [2:0] MAPPER,       // MCU detected mapper
  input [23:0] SNES_ADDR,   // requested address from SNES
  input [7:0] SNES_PA,      // peripheral address from SNES
  input SNES_ROMSEL,        // ROMSEL from SNES
  output [23:0] ROM_ADDR,   // Address to request from SRAM0
  output ROM_HIT,           // enable SRAM0
  output IS_SAVERAM,        // address/CS mapped as SRAM?
  output IS_ROM,            // address mapped as ROM?
  output IS_WRITABLE,       // address somehow mapped as writable area?
  //input [23:0] SAVERAM_MASK,
  //input [23:0] ROM_MASK,
  output msu_enable,
  //output srtc_enable,
  output sgb_enable,
  output r213f_enable,
  output r2100_hit,
  output snescmd_enable,

  output button_enable,
  output button_addr
);

/* feature bits. see src/fpga_spi.c for mapping */
parameter [2:0]
  FEAT_DSPX = 0,
  FEAT_ST0010 = 1,
  FEAT_SRTC = 2,
  FEAT_MSU1 = 3,
  FEAT_213F = 4,
  FEAT_2100 = 6
;

wire [23:0] SRAM_SNES_ADDR;

/* currently supported mappers:
   Index     Mapper
   -         LoROM
*/

assign IS_ROM = ~SNES_ROMSEL;

// Original SGB SNES code does not enable SaveRAM.  If a SD2SNES feature is added to support this
// the firmware will need a way to back it up.  Also SNES access to PSRAM will create bus
// contention with the GB.  A better solution is to have the GB code use its SaveRAM.
assign IS_SAVERAM = 0;

// LoROM: A23 = r03/r04  A22 = r06  A21 = r05  A20 = 0    A19 = d/c
assign IS_WRITABLE = IS_SAVERAM;

// Only a LOROM image of up to 512KB is supported.  MAPPER, ROMMASK, and RAMMASK have been repurposed for GB.
assign SRAM_SNES_ADDR = {5'h00, SNES_ADDR[19:16], SNES_ADDR[14:0]};

assign ROM_ADDR = SRAM_SNES_ADDR;

assign ROM_HIT = IS_ROM | IS_WRITABLE;

assign msu_enable = featurebits[FEAT_MSU1] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff8) == 16'h2000));
assign sgb_enable = !SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hf808) == 16'h6000 || (SNES_ADDR[15:0] & 16'hf80F) == 16'h600F || (SNES_ADDR[15:0] & 16'hf000) == 16'h7000); // 6000/2/8-F -67FF, 7000-7FFF -> 6000/2/8-F, 7000-700F, 7800 unique

assign r213f_enable = featurebits[FEAT_213F] & (SNES_PA == 8'h3f);
assign r2100_hit = (SNES_PA == 8'h00);

assign snescmd_enable = ({SNES_ADDR[22], SNES_ADDR[15:9]} == 8'b0_0010101);

// Simplified button snooping for SGB hook code.  See cheats.v for more details.
// $010F11 <- $4218
// $010F12 <- $4219
assign button_enable = {SNES_ADDR[23:2],2'b00} == {24'h010F10} && SNES_ADDR[1] != SNES_ADDR[0];
assign button_addr   = ~SNES_ADDR[0];

endmodule

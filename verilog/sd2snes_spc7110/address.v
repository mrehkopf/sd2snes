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
module address(
  input [15:0] featurebits, // peripheral enable/disable
  input [23:0] SNES_ADDR,   // requested address from SNES
  input [7:0] SNES_PA,      // peripheral address from SNES
  input SNES_ROMSEL,        // ROMSEL from SNES
  output [23:0] ROM_ADDR,   // Address to request from SRAM0
  output ROM_HIT,           // enable SRAM0
  output IS_SAVERAM,        // address/CS mapped as SRAM?
  output IS_ROM,            // address mapped as ROM?
  output IS_WRITABLE,       // address somehow mapped as writable area?
  input [23:0] SAVERAM_MASK,
  input [23:0] ROM_MASK,
  /* cartridge mapping from spc7110_map: the four $4830-$4834 selected 1 MB
     windows over program ROM / data ROM, and the $6000-$7FFF SRAM gate */
  input SPC7110_ROM_HIT,
  input [23:0] SPC7110_PSRAM_ADDR,
  input SPC7110_IS_SRAM,
  output msu_enable,
  output r213f_enable,
  output r2100_hit,
  output snescmd_enable,
  output nmicmd_enable,
  output return_vector_enable,
  output branch1_enable,
  output branch2_enable,
  output branch3_enable
);
// SPC7110 behaviour referenced here follows the ares implementation (ISC);
// the full ISC notice is carried in spc7110_map.v / spc7110_dcu.v.

/* feature bits. see src/fpga_spi.c for mapping */
parameter [2:0]
  FEAT_MSU1 = 3,
  FEAT_213F = 4
;

wire [23:0] SRAM_SNES_ADDR;

/*
  SPC7110 memory mapper.

  The cartridge mapping itself -- program ROM window, the four $4830-$4834
  selected data ROM windows and the $6000-$7FFF SRAM gate -- is decoded by
  spc7110_map.v, which sees the register file directly.  This file only turns
  its verdict into the final PSRAM address: the mapped ROM offset comes in ready
  to use, and the save RAM offset is built here because the SPC7110 packs it
  differently from the stock LoROM mirroring.
*/

// active high to select ROM in banks 00-3f,80-bf:8000-ffff and 40-7d,c0-ff:0000-ffff
// (decoded by SNES).  This one stays the plain ROMSEL decode: it drives the data
// bus level shifter, not the PSRAM address.
assign IS_ROM = ~SNES_ROMSEL;

/* Save RAM mapping: $00-3f,80-bf:6000-7fff, enabled by $4830 bit 7 (which is
   already part of SPC7110_IS_SRAM).  The reference folds the address as
   ((bank & 0x7f) << 13) | (addr & 0x1fff), i.e. every enabled bank contributes
   its own 8 KB page instead of the four-banks-per-page mirroring of a LoROM
   cartridge.  The window can only be reached with address bit 22 clear, so the
   seven bank bits are exactly SNES_ADDR[22:16]. */
wire [19:0] SPC7110_SRAM_OFFSET = {SNES_ADDR[22:16], SNES_ADDR[12:0]};

assign IS_SAVERAM = SPC7110_IS_SRAM;

// '1' to signal access to cartrigde writable range (Backup RAM or BS-X RAM)
assign IS_WRITABLE = IS_SAVERAM;

assign SRAM_SNES_ADDR = IS_SAVERAM ? 24'hE00000 + ({4'h0, SPC7110_SRAM_OFFSET} & SAVERAM_MASK)
                      : SPC7110_PSRAM_ADDR;

assign ROM_ADDR = SRAM_SNES_ADDR;

// '1' when accesing PSRAM for ROM, Backup RAM, BS-X RAM
assign ROM_HIT = SPC7110_ROM_HIT | IS_WRITABLE;

// '1' when accessing to MSU register map $2000:$2007
assign msu_enable = featurebits[FEAT_MSU1] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff8) == 16'h2000));

assign r213f_enable = featurebits[FEAT_213F] & (SNES_PA == 8'h3f);
assign r2100_hit = (SNES_PA == 8'h00);

assign snescmd_enable = ({SNES_ADDR[22], SNES_ADDR[15:9]} == 8'b0_0010101);
assign nmicmd_enable = (SNES_ADDR == 24'h002BF2);
assign return_vector_enable = (SNES_ADDR == 24'h002A6C);
assign branch1_enable = (SNES_ADDR == 24'h002A1F);
assign branch2_enable = (SNES_ADDR == 24'h002A59);
assign branch3_enable = (SNES_ADDR == 24'h002A5E);
endmodule

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

/* feature bits. see src/fpga_spi.c for mapping */
parameter [2:0]
  FEAT_MSU1 = 3,
  FEAT_213F = 4
;

wire [23:0] SRAM_SNES_ADDR;

/*
  S-DD1 memory mapper.
  NOTE: Part of the ROM mapping/bankswitching is carried out in SDD1.vhd!
  SaveRAM mapping is still defined here.
*/

// active high to select ROM in banks 00-3f,80-bf:8000-ffff and 40-7d,c0-ff:0000-ffff
// (decoded by SNES)
assign IS_ROM = ~SNES_ROMSEL;

/* Save RAM mapping: up to 1Mbit;
   Address ranges: 70-73:0000-7fff,
                   00-3f:6000-7fff,
                   80-bf:6000-7fff.

   Mirrored like this:
    ( x = 0,1,2,3,8,9,a,b )
    70:0000  -  x0:6000
    70:1fff  -  x0:7fff
    70:2000  -  x1:6000
    70:3fff  -  x1:7fff
            ...
    70:7fff  -  x3:7fff
    71:0000  -  x4:6000
    71:7fff  -  x4:7fff
            ...
    73:0000  -  xc:6000
            ...
    73:7fff  -  xf:7fff
*/

wire IS_SAVERAM_BIGBANKS   = ((SNES_ADDR[23:18] == 6'b011100) && (SNES_ADDR[15] == 1'b0));
wire IS_SAVERAM_SMALLBANKS = ((SNES_ADDR[22] == 1'b0) && (SNES_ADDR[15:13] == 3'b011));

wire  [1:0] SAVERAM_BANK_BIG     = SNES_ADDR[17:16];
wire  [3:0] SAVERAM_BANK_SMALL   = SNES_ADDR[19:16];
wire [14:0] SAVERAM_OFFSET_BIG   = SNES_ADDR[14:0];
wire [12:0] SAVERAM_OFFSET_SMALL = SNES_ADDR[12:0];

assign IS_SAVERAM = IS_SAVERAM_BIGBANKS | IS_SAVERAM_SMALLBANKS;

// '1' to signal access to cartrigde writable range (Backup RAM or BS-X RAM)
assign IS_WRITABLE = IS_SAVERAM;

assign SRAM_SNES_ADDR = IS_SAVERAM_BIGBANKS ? 24'hE00000 + ({SAVERAM_BANK_BIG, SAVERAM_OFFSET_BIG} & SAVERAM_MASK)
                      : IS_SAVERAM_SMALLBANKS ? 24'hE00000 + ({SAVERAM_BANK_SMALL, SAVERAM_OFFSET_SMALL} & SAVERAM_MASK)
                      : ({1'b0, !SNES_ADDR[23], SNES_ADDR[21:0]} & ROM_MASK);

assign ROM_ADDR = SRAM_SNES_ADDR;

// '1' when accesing PSRAM for ROM, Backup RAM, BS-X RAM
assign ROM_HIT = IS_ROM | IS_WRITABLE;

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

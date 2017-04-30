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
  input CLK,
  input [7:0] featurebits,
  input [2:0] MAPPER,       // MCU detected mapper
  input [23:0] SNES_ADDR,   // requested address from SNES
  input [7:0] SNES_PA,      // peripheral address from SNES
  output [23:0] ROM_ADDR,   // Address to request from SRAM0
  output ROM_HIT,           // want to access RAM0
  output IS_SAVERAM,        // address/CS mapped as SRAM?
  output IS_ROM,            // address mapped as ROM?
  output IS_WRITABLE,       // address somehow mapped as writable area?
  input [23:0] SAVERAM_MASK,
  input [23:0] ROM_MASK,
  output msu_enable,
  output cx4_enable,
  output cx4_vect_enable,
  output r213f_enable,
  output snescmd_enable,
  output nmicmd_enable,
  output return_vector_enable,
  output branch1_enable,
  output branch2_enable
);

parameter [2:0]
  FEAT_MSU1 = 3,
  FEAT_213F = 4
;

wire [23:0] SRAM_SNES_ADDR;

/* Cx4 mapper:
   - LoROM (extended to 00-7d, 80-ff)
   - MMIO @ 6000-7fff
   - SRAM @ 70-77:0000-7fff
 */

assign IS_ROM = ((!SNES_ADDR[22] & SNES_ADDR[15])
                 |(SNES_ADDR[22]));

assign IS_SAVERAM = |SAVERAM_MASK & (~SNES_ADDR[23] & &SNES_ADDR[22:20] & ~SNES_ADDR[19] & ~SNES_ADDR[15]);

assign SRAM_SNES_ADDR = IS_SAVERAM
                        ? (24'hE00000 | ({SNES_ADDR[19:16], SNES_ADDR[14:0]}
                         & SAVERAM_MASK))
                        : ({2'b00, SNES_ADDR[22:16], SNES_ADDR[14:0]}
                         & ROM_MASK);

assign ROM_ADDR = SRAM_SNES_ADDR;

assign IS_WRITABLE = IS_SAVERAM;

assign ROM_HIT = IS_ROM | IS_WRITABLE;

wire msu_enable_w = featurebits[FEAT_MSU1] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff8) == 16'h2000));
assign msu_enable = msu_enable_w;

wire cx4_enable_w = (!SNES_ADDR[22] && (SNES_ADDR[15:13] == 3'b011));
assign cx4_enable = cx4_enable_w;

assign cx4_vect_enable = &SNES_ADDR[15:5];

assign r213f_enable = featurebits[FEAT_213F] & (SNES_PA == 9'h3f);

assign snescmd_enable = ({SNES_ADDR[22], SNES_ADDR[15:9]} == 8'b0_0010101);
assign nmicmd_enable = (SNES_ADDR == 24'h002BF2);
assign return_vector_enable = (SNES_ADDR == 24'h002A5A);
assign branch1_enable = (SNES_ADDR == 24'h002A13);
assign branch2_enable = (SNES_ADDR == 24'h002A4D);
endmodule

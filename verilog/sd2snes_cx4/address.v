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
  input [15:0] featurebits,
  input [2:0] MAPPER,       // MCU detected mapper
  input [23:0] SNES_ADDR,   // requested address from SNES
  input [7:0] SNES_PA,      // peripheral address from SNES
  input SNES_ROMSEL,        // ROMSEL from SNES
  output [23:0] ROM_ADDR,   // Address to request from SRAM0
  output ROM_HIT,           // want to access RAM0
  output IS_SAVERAM,        // address/CS mapped as SRAM?
  output IS_ROM,            // address mapped as ROM?
  output IS_WRITABLE,       // address somehow mapped as writable area?
  output IS_PATCH,          // hook identity window active ($C0-FF while unlocked)
  input [23:0] SAVERAM_MASK,
  input [23:0] ROM_MASK,
  input  snescmd_unlock,    // snescmd region unlocked (gates the hook window)
  output msu_enable,
  output cx4_enable,
  output cx4_vect_enable,
  output cx4_ss_enable,     // savestate scan window ($E8:00xx while unlocked; mk2 AND mk3)
  output r213f_enable,
  output r2100_hit,
  output snescmd_enable,
  output nmicmd_enable,
  output return_vector_enable,
  output branch1_enable,
  output branch2_enable,
  output branch3_enable
);

parameter [2:0]
  FEAT_MSU1 = 3,
  FEAT_213F = 4,
  FEAT_2100 = 6
;

wire [23:0] SRAM_SNES_ADDR;

/* Cx4 mapper:
   - LoROM (extended to 00-7d, 80-ff)
   - MMIO @ 6000-7fff
   - SRAM @ 70-77:0000-7fff
 */

assign IS_ROM = ~SNES_ROMSEL;

assign IS_SAVERAM = |SAVERAM_MASK & (~SNES_ADDR[23] & &SNES_ADDR[22:20] & ~SNES_ADDR[19] & ~SNES_ADDR[15]);

// Hook identity window (as in sd2snes_base): while the hook holds the snescmd
// region unlocked, banks $C0-$FF are identity-mapped so the savestate handler runs
// from menu PSRAM with its scratch in $F2-$FF.  0 outside the hook window.
assign IS_PATCH = snescmd_unlock & &SNES_ADDR[23:22];

assign SRAM_SNES_ADDR = IS_PATCH
                        // hook window: identity-map $C0-$FF (handler code + scratch)
                        ? SNES_ADDR
                        : IS_SAVERAM
                        ? (24'hE00000 | ({SNES_ADDR[19:16], SNES_ADDR[14:0]}
                         & SAVERAM_MASK))
                        : ({2'b00, SNES_ADDR[22:16], SNES_ADDR[14:0]}
                         & ROM_MASK);

assign ROM_ADDR = SRAM_SNES_ADDR;

assign IS_WRITABLE = IS_SAVERAM | IS_PATCH;

assign ROM_HIT = IS_ROM | IS_WRITABLE;

wire msu_enable_w = featurebits[FEAT_MSU1] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff8) == 16'h2000));
assign msu_enable = msu_enable_w;

wire cx4_enable_w = (!SNES_ADDR[22] && (SNES_ADDR[15:13] == 3'b011));
assign cx4_enable = cx4_enable_w;

assign cx4_vect_enable = &SNES_ADDR[15:5];

// Savestate scan window: $E8:0000-$00FF while unlocked (inside IS_PATCH; the main.v
// data mux gives the window priority over the PSRAM serve, mirroring the GSU core's
// gsu_ss_enable).  Collides with nothing: cx4_enable needs ~SNES_ADDR[22] and $E8 has
// bit22=1; cx4_vect_enable needs &SNES_ADDR[15:5] and the window has SNES_ADDR[15:8]==0;
// IS_SAVERAM is $70-$77.  Inside cx4.v the window offset is therefore ADDR[7:0].
assign cx4_ss_enable = snescmd_unlock & (SNES_ADDR[23:16] == 8'hE8) & ~|SNES_ADDR[15:8];

assign r213f_enable = featurebits[FEAT_213F] & (SNES_PA == 8'h3f);
assign r2100_hit = (SNES_PA == 8'h00);

assign snescmd_enable = ({SNES_ADDR[22], SNES_ADDR[15:9]} == 8'b0_0010101);
assign nmicmd_enable = (SNES_ADDR == 24'h002BF2);
assign return_vector_enable = (SNES_ADDR == 24'h002A6C);
assign branch1_enable = (SNES_ADDR == 24'h002A1F);
assign branch2_enable = (SNES_ADDR == 24'h002A59);
assign branch3_enable = (SNES_ADDR == 24'h002A5E);
endmodule

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
  input [15:0] featurebits, // peripheral enable/disable
  input [2:0] MAPPER,       // MCU detected mapper
  input [23:0] SNES_ADDR,   // requested address from SNES
  input [7:0] SNES_PA,      // peripheral address from SNES
  input SNES_ROMSEL,        // ROMSEL from SNES
  output [23:0] ROM_ADDR,   // Address to request from SRAM0
  output ROM_HIT,           // enable SRAM0
  output IS_SAVERAM,        // address/CS mapped as SRAM?
  output IS_ROM,            // address mapped as ROM?
  output IS_WRITABLE,       // address somehow mapped as writable area?
  output IS_PATCH,          // hook identity window active ($C0-FF while unlocked)
  output gsu_ss_enable,     // savestate scan window ($E8:00xx while unlocked; active on mk2 AND mk3)
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
  output branch3_enable,
  output gsu_enable,
  input  snescmd_unlock     // snescmd region unlocked (gates the hook window)
);

parameter [2:0]
  //FEAT_DSPX = 0,
  //FEAT_ST0010 = 1,
  //FEAT_SRTC = 2,
  FEAT_MSU1 = 3,
  FEAT_213F = 4,
  FEAT_2100 = 6
;

wire [23:0] SRAM_SNES_ADDR;

assign IS_ROM = ~SNES_ROMSEL;

// In-game hook identity window: while the snescmd region is unlocked, map all of
// $C0-$FF 1:1 to PSRAM (handler code at $C0xxxx, scratch/shadows in $F2-$FF).
assign IS_PATCH = snescmd_unlock & &SNES_ADDR[23:22];

// Savestate scan window: $E8:0000-00FF while unlocked (inside IS_PATCH; the
// main.v data mux gives the window priority over the PSRAM serve, mirroring
// the SA-1 core's sa1_ss_enable).
// MEASUREMENT: scan window active on mk2 too (fit probe for full savestate)
assign gsu_ss_enable = snescmd_unlock & (SNES_ADDR[23:16] == 8'hE8) & ~|SNES_ADDR[15:8];

// ~IS_PATCH: the GSU map places SAVERAM at 60-7D/E0-FF -- banks $E0-$FF overlap the
// hook window, and without the gate the handler's PSRAM scratch reads/writes would
// hit the GSU cart RAM instead (the identity window must win while unlocked).
assign IS_SAVERAM = ~IS_PATCH & SAVERAM_MASK[0]
                    & ( // 60-7D/E0-FF:0000-FFFF
                        ( &SNES_ADDR[22:21]
                        & ~SNES_ROMSEL
                        )
                        // 00-3F/80-BF:6000-7FFF
                      | ( ~SNES_ADDR[22]
                        & ~SNES_ADDR[15]
                        & &SNES_ADDR[14:13]
                        )
                      );

assign IS_WRITABLE = IS_SAVERAM | IS_PATCH;

// GSU has a weird hybrid of Lo and Hi ROM formats.
// TODO: add programmable address map
assign SRAM_SNES_ADDR = IS_PATCH
                        // hook window: identity-map $C0-$FF (handler code + scratch)
                        ? SNES_ADDR
                        : (IS_SAVERAM
                         // 60-7D/E0-FF:0000-FFFF or 00-3F/80-BF:6000-7FFF (first 8K mirror)
                         ? (24'hE00000 + ((SNES_ADDR[22] ? SNES_ADDR[16:0] : SNES_ADDR[12:0]) & SAVERAM_MASK))
                         // 40-5F/C0-DF:0000-FFFF or 00-3F/80-BF:8000-FFFF
                         : ((SNES_ADDR[22] ? {2'b00, SNES_ADDR[21:0]} : {2'b00, SNES_ADDR[22:16], SNES_ADDR[14:0]}) & ROM_MASK)
                         );

assign ROM_ADDR = SRAM_SNES_ADDR;

assign ROM_HIT = IS_ROM | IS_WRITABLE;

assign msu_enable = featurebits[FEAT_MSU1] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff8) == 16'h2000));
assign r213f_enable = featurebits[FEAT_213F] & (SNES_PA == 8'h3f);
assign r2100_hit = (SNES_PA == 8'h00);
assign snescmd_enable = ({SNES_ADDR[22], SNES_ADDR[15:9]} == 8'b0_0010101);
assign nmicmd_enable = (SNES_ADDR == 24'h002BF2);
assign return_vector_enable = (SNES_ADDR == 24'h002A6C);
assign branch1_enable = (SNES_ADDR == 24'h002A1F);
assign branch2_enable = (SNES_ADDR == 24'h002A59);
assign branch3_enable = (SNES_ADDR == 24'h002A5E);
// 00-3F/80-BF:3000-32FF gsu registers.  TODO: some emulators go to $34FF???
assign gsu_enable = (!SNES_ADDR[22] && ({SNES_ADDR[15:10],2'h0} == 8'h30)) && (SNES_ADDR[9:8] != 2'h3);

endmodule

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
  output gsu_enable
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


assign IS_ROM = ( (~SNES_ADDR[22] & SNES_ADDR[15])
                | (SNES_ADDR[22]  & ~SNES_ROMSEL))
                ;

assign IS_SAVERAM = SAVERAM_MASK[0]
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

assign IS_WRITABLE = IS_SAVERAM;

// GSU has a weird hybrid of Lo and Hi ROM formats.
assign SRAM_SNES_ADDR = (IS_SAVERAM
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
assign return_vector_enable = (SNES_ADDR == 24'h002A5A);
assign branch1_enable = (SNES_ADDR == 24'h002A13);
assign branch2_enable = (SNES_ADDR == 24'h002A4D);
// 00-3F/80-BF:3000-32FF gsu registers.  TODO: some emulators go to $34FF???
assign gsu_enable = (!SNES_ADDR[22] && ({SNES_ADDR[15:10],2'h0} == 8'h30)) && (SNES_ADDR[9:8] != 2'h3);

endmodule

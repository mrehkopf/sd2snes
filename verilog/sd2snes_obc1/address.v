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
  input [7:0] featurebits,  // peripheral enable/disable
  input [2:0] MAPPER,       // MCU detected mapper
  input [23:0] SNES_ADDR,   // requested address from SNES
  input [7:0] SNES_PA,      // peripheral address from SNES
  output [23:0] ROM_ADDR,   // Address to request from SRAM0
  output ROM_HIT,           // enable SRAM0
  output IS_SAVERAM,        // address/CS mapped as SRAM?
  output IS_ROM,            // address mapped as ROM?
  output IS_WRITABLE,       // address somehow mapped as writable area?
  input [23:0] SAVERAM_MASK,
  input [23:0] ROM_MASK,
  output msu_enable,
  output r213f_enable,
  output snescmd_enable,
  output obc1_enable
);

parameter [2:0]
  FEAT_MSU1 = 3,
  FEAT_213F = 4
;

wire [23:0] SRAM_SNES_ADDR;

/* currently supported mappers:
   Index     Mapper
      000      HiROM
      001      LoROM
      010      ExHiROM (48-64Mbit)
*/

/* HiROM:   SRAM @ Bank 0x30-0x3f, 0xb0-0xbf
            Offset 6000-7fff */

assign IS_ROM = ((!SNES_ADDR[22] & SNES_ADDR[15])
                 |(SNES_ADDR[22]));

assign IS_SAVERAM = SAVERAM_MASK[0]
                    &(((MAPPER == 3'b000
                     || MAPPER == 3'b010)
                      ? (!SNES_ADDR[22]
                         & SNES_ADDR[21]
                         & &SNES_ADDR[14:13]
                         & !SNES_ADDR[15]
                        )
/*  LoROM:   SRAM @ Bank 0x70-0x7d, 0xf0-0xfd
 *  Offset 0000-7fff for ROM >= 32 MBit, otherwise 0000-ffff */
                      :(MAPPER == 3'b001)
                      ? (&SNES_ADDR[22:20]
                         & (SNES_ADDR[19:16] < 4'b1110)
                         & (~SNES_ADDR[15] | ~ROM_MASK[21])
                        )
                      : 1'b0));

assign IS_WRITABLE = IS_SAVERAM;

assign SRAM_SNES_ADDR = ((MAPPER == 3'b000)
                          ?(IS_SAVERAM
                            ? 24'hE00000 + ({SNES_ADDR[20:16], SNES_ADDR[12:0]}
                                            & SAVERAM_MASK)
                            : ({1'b0, SNES_ADDR[22:0]} & ROM_MASK))

                        :(MAPPER == 3'b001)
                          ?(IS_SAVERAM
                            ? 24'hE00000 + ({SNES_ADDR[20:16], SNES_ADDR[14:0]}
                                            & SAVERAM_MASK)
                            : ({2'b00, SNES_ADDR[22:16], SNES_ADDR[14:0]}
                               & ROM_MASK))

                        :(MAPPER == 3'b010)
                          ?(IS_SAVERAM
                            ? 24'hE00000 + ({SNES_ADDR[20:16], SNES_ADDR[12:0]}
                                            & SAVERAM_MASK)
                            : ({1'b0, !SNES_ADDR[23], SNES_ADDR[21:0]}
                               & ROM_MASK))
                        : 24'b0);

assign ROM_ADDR = SRAM_SNES_ADDR;

assign ROM_SEL = 1'b0;

assign ROM_HIT = IS_ROM | IS_WRITABLE;

assign msu_enable = featurebits[FEAT_MSU1] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff8) == 16'h2000));
assign r213f_enable = featurebits[FEAT_213F] & (SNES_PA == 8'h3f);
assign obc1_enable = (~SNES_ADDR[22]) & (SNES_ADDR[15:11] == 5'b01111);
assign snescmd_enable = ({SNES_ADDR[22], SNES_ADDR[15:9]} == 8'b0_0010101);

endmodule

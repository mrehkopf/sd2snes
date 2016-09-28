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
  input [23:0] SNES_ADDR,   // requested address from SNES
  output [23:0] ROM_ADDR,   // Address to request from SRAM0
  output ROM_HIT,           // enable SRAM0
  output IS_SAVERAM,        // address/CS mapped as SRAM?
  output IS_ROM,            // address mapped as ROM?
  input [23:0] SAVERAM_MASK,
  input [23:0] ROM_MASK
);

wire [23:0] SRAM_SNES_ADDR;

/* static mapper:
      menu (ROM in upper SRAM)
*/

/* HiROM:   SRAM @ Bank 0x30-0x3f, 0xb0-0xbf
            Offset 6000-7fff */

assign IS_ROM = ((!SNES_ADDR[22] & SNES_ADDR[15])
                 |(SNES_ADDR[22]));

assign IS_SAVERAM = (!SNES_ADDR[22]
                     & &SNES_ADDR[21:20]
                     & &SNES_ADDR[14:13]
                     & !SNES_ADDR[15]
                    );

assign SRAM_SNES_ADDR = (IS_SAVERAM
                             ? 24'hFF0000 + ((SNES_ADDR[14:0] - 15'h6000)
                                             & SAVERAM_MASK)
                             : (({1'b0, SNES_ADDR[22:0]} & ROM_MASK)
                                + 24'hC00000)
                        );

assign ROM_ADDR = SRAM_SNES_ADDR;

assign ROM_HIT = IS_ROM | IS_SAVERAM;

endmodule

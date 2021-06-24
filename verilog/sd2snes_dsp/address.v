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
  input  map_unlock,
  output msu_enable,
  output dma_enable,
  output dspx_enable,
  output dspx_dp_enable,
  output dspx_a0,
  output r213f_enable,
  output r2100_hit,
  output snescmd_enable,
  output nmicmd_enable,
  output return_vector_enable,
  output branch1_enable,
  output branch2_enable,
  output exe_enable,
  input [8:0] bs_page_offset,
  input [9:0] bs_page,
  input bs_page_enable
);

/* feature bits. see src/fpga_spi.c for mapping */
parameter [3:0]
  FEAT_DSPX = 0,
  FEAT_ST0010 = 1,
  FEAT_MSU1 = 3,
  FEAT_213F = 4,
  FEAT_SNESUNLOCK = 5,
  FEAT_2100 = 6,
  FEAT_DMA1 = 11
;
reg [7:0] MAPPER_DEC;
integer i;
always @(posedge CLK) begin
  for (i = 0; i < 8; i = i + 1) MAPPER_DEC[i] <= (MAPPER == i);
end

wire [23:0] SRAM_SNES_ADDR;

/* currently supported mappers:
   Index     Mapper
      000      HiROM
      001      LoROM
      010      ExHiROM (48-64Mbit)
      011      BS-X
      110      brainfuck interleaved 96MBit Star Ocean =)
      111      menu (ROM in upper SRAM)
*/

/* HiROM:   SRAM @ Bank 0x30-0x3f, 0xb0-0xbf
            Offset 6000-7fff */

assign IS_ROM = ((!SNES_ADDR[22] & SNES_ADDR[15])
                 |(SNES_ADDR[22]));

assign IS_SAVERAM = (~map_unlock & SAVERAM_MASK[0])
                    &(featurebits[FEAT_ST0010]
                      ?((SNES_ADDR[22:19] == 4'b1101)
                        & &(~SNES_ADDR[15:12])
                        & SNES_ADDR[11])
                      :((MAPPER_DEC[3'b000]
                        || MAPPER_DEC[3'b010]
                        || MAPPER_DEC[3'b110])
                      ? (!SNES_ADDR[22]
                         & SNES_ADDR[21]
                         & &SNES_ADDR[14:13]
                         & !SNES_ADDR[15]
                        )
/*  LoROM:   SRAM @ Bank 0x70-0x7d, 0xf0-0xff
 *  Offset 0000-7fff for ROM >= 32 MBit, otherwise 0000-ffff */
                      :(MAPPER_DEC[3'b001])
                      ? (&SNES_ADDR[22:20]
                         & (~SNES_ROMSEL)
                         & (~SNES_ADDR[15] | ~ROM_MASK[21])
                        )
/*  Menu mapper: 8Mbit "SRAM" @ Bank 0xf0-0xff (entire banks!) */
                      :(MAPPER_DEC[3'b111])
                      ? (&SNES_ADDR[23:20])
                      : 1'b0));

// give the patch free reign over $F0-$FF banks
assign IS_PATCH = map_unlock & (&SNES_ADDR[23:20]);

assign IS_WRITABLE = IS_SAVERAM
                     |IS_PATCH; // allow writing of the patch region

assign SRAM_SNES_ADDR = IS_PATCH
                        ? SNES_ADDR
                        : ((MAPPER_DEC[3'b000])
                          ?(IS_SAVERAM
                            ? 24'hE00000 + ({SNES_ADDR[20:16], SNES_ADDR[12:0]}
                                            & SAVERAM_MASK)
                            : ({1'b0, SNES_ADDR[22:0]} & ROM_MASK))

                          :(MAPPER_DEC[3'b001])
                          ?(IS_SAVERAM
                            ? 24'hE00000 + ({SNES_ADDR[20:16], SNES_ADDR[14:0]}
                                            & SAVERAM_MASK)
                            : ({1'b0, ~SNES_ADDR[23], SNES_ADDR[22:16], SNES_ADDR[14:0]}
                               & ROM_MASK))

                          :(MAPPER_DEC[3'b010])
                          ?(IS_SAVERAM
                            ? 24'hE00000 + ({SNES_ADDR[20:16], SNES_ADDR[12:0]}
                                            & SAVERAM_MASK)
                            : ({1'b0, !SNES_ADDR[23], SNES_ADDR[21:0]}
                               & ROM_MASK))
                           :(MAPPER_DEC[3'b110])
                           ?(IS_SAVERAM
                             ? 24'hE00000 + ((SNES_ADDR[14:0] - 15'h6000)
                                             & SAVERAM_MASK)
                             :(SNES_ADDR[15]
                               ?({1'b0, SNES_ADDR[23:16], SNES_ADDR[14:0]})
                               :({2'b10,
                                  SNES_ADDR[23],
                                  SNES_ADDR[21:16],
                                  SNES_ADDR[14:0]}
                                )
                              )
                            )
                           :(MAPPER_DEC[3'b111])
                           ?(IS_SAVERAM
                             ? SNES_ADDR
                             : (({1'b0, SNES_ADDR[22:0]} & ROM_MASK)
                                + 24'hC00000)
                            )
                           : 24'b0);

assign ROM_ADDR = SRAM_SNES_ADDR;

assign ROM_HIT = IS_ROM | IS_WRITABLE | bs_page_enable;

assign msu_enable = featurebits[FEAT_MSU1] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff8) == 16'h2000));
assign dma_enable = (featurebits[FEAT_DMA1] | map_unlock) & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff0) == 16'h2020));
assign exe_enable =                           (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hffff) == 16'h2C00));

// DSP1 LoROM: DR=30-3f:8000-bfff; SR=30-3f:c000-ffff
//          or DR=60-6f:0000-3fff; SR=60-6f:4000-7fff
// DSP1 HiROM: DR=00-0f:6000-6fff; SR=00-0f:7000-7fff
assign dspx_enable =
  featurebits[FEAT_DSPX]
  ?((MAPPER_DEC[3'b001])
    ?(ROM_MASK[20]
      ?(SNES_ADDR[22] & SNES_ADDR[21] & ~SNES_ADDR[20] & ~SNES_ADDR[15])
      :(~SNES_ADDR[22] & SNES_ADDR[21] & SNES_ADDR[20] & SNES_ADDR[15])
     )
    :(MAPPER_DEC[3'b000])
      ?(~SNES_ADDR[22] & ~SNES_ADDR[21] & ~SNES_ADDR[20] & ~SNES_ADDR[15]
        & &SNES_ADDR[14:13])
    :1'b0)
  :featurebits[FEAT_ST0010]
  ?(SNES_ADDR[22] & SNES_ADDR[21] & ~SNES_ADDR[20] & &(~SNES_ADDR[19:16]) & ~SNES_ADDR[15])
  :1'b0;

assign dspx_dp_enable = featurebits[FEAT_ST0010]
                      &(SNES_ADDR[22:19] == 4'b1101
                     && SNES_ADDR[15:11] == 5'b00000);

assign dspx_a0 = featurebits[FEAT_DSPX]
                 ?((MAPPER_DEC[3'b001]) ? SNES_ADDR[14]
                   :(MAPPER_DEC[3'b000]) ? SNES_ADDR[12]
                   :1'b1)
                 : featurebits[FEAT_ST0010]
                 ? SNES_ADDR[0]
                 : 1'b1;

assign r213f_enable = featurebits[FEAT_213F] & (SNES_PA == 8'h3f);
assign r2100_hit = (SNES_PA == 8'h00);

// snescmd covers $2A00-$2FFF.  This overlaps with at least one hardware cheat device address range.
assign snescmd_enable = ({SNES_ADDR[22], SNES_ADDR[15:11]} == 6'b0_00101) && (SNES_ADDR[10:9] != 2'b00);
assign nmicmd_enable = (SNES_ADDR == 24'h002BF2);
assign return_vector_enable = (SNES_ADDR == 24'h002A5A);
assign branch1_enable = (SNES_ADDR == 24'h002A13);
assign branch2_enable = (SNES_ADDR == 24'h002A4D);
endmodule

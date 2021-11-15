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
  input [23:0] SNES_ADDR_early,   // requested address from SNES
  input SNES_WRITE_early,
  input [7:0] SNES_PA,      // peripheral address from SNES
  input SNES_ROMSEL,        // ROMSEL from SNES
  output [23:0] ROM_ADDR,   // Address to request from SRAM0
  output ROM_HIT,           // enable SRAM0
  output IS_SAVERAM,        // address/CS mapped as SRAM?
  output IS_ROM,            // address mapped as ROM?
  output IS_WRITABLE,       // address somehow mapped as writable area?
  output IS_PATCH,          // linear address map (C0-FF, Ex/Fx)
  input [7:0] SAVERAM_BASE,
  input [23:0] SAVERAM_MASK,
  input [23:0] ROM_MASK,
  input  map_unlock,
  input  map_Ex_rd_unlock,
  input  map_Ex_wr_unlock,
  input  map_Fx_rd_unlock,
  input  map_Fx_wr_unlock,
  input  snescmd_unlock,
  output msu_enable,
  output dma_enable,
  output srtc_enable,
  output use_bsx,
  output bsx_tristate,
  input [14:0] bsx_regs,
  output r213f_enable,
  output r2100_hit,
  output snescmd_enable,
  output nmicmd_enable,
  output return_vector_enable,
  output branch1_enable,
  output branch2_enable,
  output branch3_enable,
  output exe_enable,
  output map_enable,
  input [8:0] bs_page_offset,
  input [9:0] bs_page,
  input bs_page_enable
);

/* feature bits. see src/fpga_spi.c for mapping */
parameter [3:0]
  FEAT_SRTC = 2,
  FEAT_MSU1 = 3,
  FEAT_213F = 4,
  FEAT_SNESUNLOCK = 5,
  FEAT_2100 = 6,
  FEAT_DMA1 = 11
;

integer i;
reg [7:0] MAPPER_DEC; always @(posedge CLK) for (i = 0; i < 8; i = i + 1) MAPPER_DEC[i] <= (MAPPER == i);
reg [23:0] SNES_ADDR; always @(posedge CLK) SNES_ADDR <= SNES_ADDR_early;

wire [23:0] SRAM_SNES_ADDR;
wire [23:0] SAVERAM_ADDR = {4'hE,1'b0,SAVERAM_BASE,11'h0};

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

assign IS_ROM = ~SNES_ROMSEL;

// Calculate pre IS_SAVERAM to relax timing.  Uses
// early SNES_ADDR from main.
assign IS_SAVERAM_pre = (~map_unlock & SAVERAM_MASK[0])
                    &((MAPPER_DEC[3'b000]
                        || MAPPER_DEC[3'b010]
                        || MAPPER_DEC[3'b110])
                      ? (!SNES_ADDR_early[22]
                         & SNES_ADDR_early[21]
                         & &SNES_ADDR_early[14:13]
                         & !SNES_ADDR_early[15]
                        )
/*  LoROM:   SRAM @ Bank 0x70-0x7d, 0xf0-0xff
 *  Offset 0000-7fff for ROM >= 32 MBit, otherwise 0000-ffff */
                      :(MAPPER_DEC[3'b001])
                      ? (&SNES_ADDR_early[22:20]
                         & (~SNES_ROMSEL)
                         & (~SNES_ADDR_early[15] | ~ROM_MASK[21])
                        )
/*  BS-X: SRAM @ Bank 0x10-0x17 Offset 5000-5fff */
                      :(MAPPER_DEC[3'b011])
                      ? ((SNES_ADDR_early[23:19] == 5'b00010)
                         & (SNES_ADDR_early[15:12] == 4'b0101)
                        )
/*  Menu mapper: 8Mbit "SRAM" @ Bank 0xf0-0xff (entire banks!) */
                      :(MAPPER_DEC[3'b111])
                      ? (&SNES_ADDR_early[23:20])
                      : 1'b0);

reg IS_SAVERAM_r; always @(posedge CLK) IS_SAVERAM_r <= IS_SAVERAM_pre;
assign IS_SAVERAM = IS_SAVERAM_r;

// give the patch free reign over $F0-$FF banks
// map_unlock: F0-FF
// map_Ex: E0-EF
// map_Fx: F0-FF
// snescmd_unlock: C0-FF
assign IS_PATCH = ( (map_unlock 
                     | (map_Fx_rd_unlock & SNES_WRITE_early)
                     | (map_Fx_wr_unlock & ~SNES_WRITE_early)
                    ) & (&SNES_ADDR[23:20])
                  )
                | ( ((map_Ex_rd_unlock & SNES_WRITE_early)
                    |(map_Ex_wr_unlock & ~SNES_WRITE_early)
                    ) & ({SNES_ADDR[23:20]} == 4'hE)
                  )
                | (snescmd_unlock & &SNES_ADDR[23:22]); // full access to C0-FF

/* BS-X has 4 MBits of extra RAM that can be mapped to various places */
// LoROM: A23 = r03/r04  A22 = r06  A21 = r05  A20 = 0    A19 = d/c
// HiROM: A23 = r03/r04  A22 = d/c  A21 = r06  A20 = r05  A19 = 0

wire [2:0] BSX_PSRAM_BANK = {bsx_regs[6], bsx_regs[5], 1'b0};
wire [2:0] SNES_PSRAM_BANK = bsx_regs[2] ? SNES_ADDR[21:19] : SNES_ADDR[22:20];
wire BSX_PSRAM_LOHI = (bsx_regs[3] & ~SNES_ADDR[23]) | (bsx_regs[4] & SNES_ADDR[23]);
reg BSX_IS_PSRAMr;
wire BSX_IS_PSRAM = BSX_IS_PSRAMr;
always @(posedge CLK) begin
  BSX_IS_PSRAMr <= BSX_PSRAM_LOHI
                     & (( IS_ROM & (SNES_PSRAM_BANK == BSX_PSRAM_BANK)
                         &(SNES_ADDR[15] | bsx_regs[2])
                         &(~(SNES_ADDR[19] & bsx_regs[2])))
                       | (bsx_regs[2]
                          ? (SNES_ADDR[22:21] == 2'b01 & SNES_ADDR[15:13] == 3'b011)
                          : (~SNES_ROMSEL & &SNES_ADDR[22:20] & ~SNES_ADDR[15]))
                       );
end

wire BSX_IS_CARTROM = ((bsx_regs[7] & (SNES_ADDR[23:22] == 2'b00))
                      |(bsx_regs[8] & (SNES_ADDR[23:22] == 2'b10)))
                      & SNES_ADDR[15];

wire BSX_HOLE_LOHI = (bsx_regs[9] & ~SNES_ADDR[23]) | (bsx_regs[10] & SNES_ADDR[23]);

wire BSX_IS_HOLE = BSX_HOLE_LOHI
                   & (bsx_regs[2] ? (SNES_ADDR[21:20] == {bsx_regs[11], 1'b0})
                                  : (SNES_ADDR[22:21] == {bsx_regs[11], 1'b0}));

assign bsx_tristate = (MAPPER_DEC[3'b011]) & ~BSX_IS_CARTROM & ~BSX_IS_PSRAM & BSX_IS_HOLE;

assign IS_WRITABLE = IS_SAVERAM
                     |IS_PATCH // allow writing of the patch region
                     |((MAPPER_DEC[3'b011]) & BSX_IS_PSRAM);

wire [23:0] BSX_ADDR = bsx_regs[2] ? {1'b0, SNES_ADDR[22:0]}
                                   : {2'b00, SNES_ADDR[22:16], SNES_ADDR[14:0]};


assign SRAM_SNES_ADDR = IS_PATCH
                        ? SNES_ADDR
                        : ((MAPPER_DEC[3'b000])
                          ?(IS_SAVERAM
                            ? SAVERAM_ADDR + ({SNES_ADDR[20:16], SNES_ADDR[12:0]}
                                            & SAVERAM_MASK)
                            : ({1'b0, SNES_ADDR[22:0]} & ROM_MASK))

                          :(MAPPER_DEC[3'b001])
                          ?(IS_SAVERAM
                            ? SAVERAM_ADDR + ({SNES_ADDR[20:16], SNES_ADDR[14:0]}
                                            & SAVERAM_MASK)
                            : ({1'b0, ~SNES_ADDR[23], SNES_ADDR[22:16], SNES_ADDR[14:0]}
                               & ROM_MASK))

                          :(MAPPER_DEC[3'b010])
                          ?(IS_SAVERAM
                            ? SAVERAM_ADDR + ({SNES_ADDR[20:16], SNES_ADDR[12:0]}
                                            & SAVERAM_MASK)
                            : ({1'b0, !SNES_ADDR[23], SNES_ADDR[21:0]}
                               & ROM_MASK))
                          :(MAPPER_DEC[3'b011])
                          ?(  IS_SAVERAM
                              ? SAVERAM_ADDR + {SNES_ADDR[18:16], SNES_ADDR[11:0]}
                              : BSX_IS_CARTROM
                              ? (24'h800000 + ({SNES_ADDR[22:16], SNES_ADDR[14:0]} & 24'h0fffff))
                              : BSX_IS_PSRAM
                              ? (24'h400000 + (BSX_ADDR & 24'h07FFFF))
                              : bs_page_enable
                              ? (24'h900000 + {bs_page,bs_page_offset})
                              : (BSX_ADDR & 24'h0fffff)
                           )
                           :(MAPPER_DEC[3'b110])
                           ?(IS_SAVERAM
                             ? SAVERAM_ADDR + ((SNES_ADDR[14:0] - 15'h6000)
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
assign dma_enable = (featurebits[FEAT_DMA1] | map_unlock | snescmd_unlock) & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff0) == 16'h2020));
assign use_bsx = (MAPPER_DEC[3'b011]);
assign srtc_enable = featurebits[FEAT_SRTC] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfffe) == 16'h2800));
assign exe_enable =                           (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hffff) == 16'h2C00));
assign map_enable =                           (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hffff) == 16'h2BB2));

assign r213f_enable = featurebits[FEAT_213F] & (SNES_PA == 8'h3f);
assign r2100_hit = (SNES_PA == 8'h00);

// snescmd covers $2A00-$2FFF.  This overlaps with at least one hardware cheat device address range.
assign snescmd_enable = ({SNES_ADDR[22], SNES_ADDR[15:11]} == 6'b0_00101) && (SNES_ADDR[10:9] != 2'b00);
assign nmicmd_enable = (SNES_ADDR == 24'h002BF2);
assign return_vector_enable = (SNES_ADDR == 24'h002A6C);
assign branch1_enable = (SNES_ADDR == 24'h002A1F);
assign branch2_enable = (SNES_ADDR == 24'h002A59);
assign branch3_enable = (SNES_ADDR == 24'h002A5E);
endmodule

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
  output srtc_enable,
  output use_bsx,
  output bsx_tristate,
  input [14:0] bsx_regs,
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
  input [8:0] bs_page_offset,
  input [9:0] bs_page,
  input bs_page_enable
);

/* feature bits. see src/fpga_spi.c for mapping */
parameter [2:0]
  FEAT_DSPX = 0,
  FEAT_ST0010 = 1,
  FEAT_SRTC = 2,
  FEAT_MSU1 = 3,
  FEAT_213F = 4,
  FEAT_2100 = 6
;

wire [23:0] SRAM_SNES_ADDR;

/* currently supported mappers:
   Index     Mapper
      000      HiROM
      001      LoROM
      010      ExHiROM (48-64Mbit)
      011      BS-X
      100      ExLoROM (StarOCean and SFA2)
      110      brainfuck interleaved 96MBit Star Ocean =)
      111      menu (ROM in upper SRAM)
*/


// active high to select ROM when
            // bank is in range ($00-$3F) or ($80-$BF) and accessing upper half of bank ($8000-$FFFF) (LoROM)
assign IS_ROM = 	((!SNES_ADDR[22] & SNES_ADDR[15])
            // bank is in range ($C0-$FF) or ($40-$7D).  Avoid WRAM $7E-$7F with /ROMSEL signal
            |(SNES_ADDR[22] & ~SNES_ROMSEL));

// select backup RAM when
              // ST0010 chip is present, SRAM is mapped to
assign IS_SAVERAM = SAVERAM_MASK[0]&(featurebits[FEAT_ST0010]?((SNES_ADDR[22:19] == 4'b1101) & &(~SNES_ADDR[15:12]) & SNES_ADDR[11])
              // for HiROM, ExtHIROM or interleaved StarOcean -> $3X:[$6000-$7FFF] or $BX:[$6000-$7FFF]
              :((MAPPER == 3'b000 || MAPPER == 3'b010 || MAPPER == 3'b110) ? (!SNES_ADDR[22] & SNES_ADDR[21] & &SNES_ADDR[14:13] & !SNES_ADDR[15])
              // for ExtLoROM -> $7X:[$6000-$7FFF]
              :(MAPPER == 3'b100) ? ((SNES_ADDR[23:19] == 5'b01110) && (SNES_ADDR[15:13] == 3'b011))
              // LoROM:   SRAM @ Bank 0x70-0x7d, 0xf0-0xff
              // Offset 0000-7fff for ROM >= 32 MBit, otherwise 0000-ffff
              :(MAPPER == 3'b001)? (&SNES_ADDR[22:20] & (~SNES_ROMSEL) & (~SNES_ADDR[15] | ~ROM_MASK[21]))
              // BS-X: SRAM @ Bank 0x10-0x17 Offset 5000-5fff
              :(MAPPER == 3'b011) ? ((SNES_ADDR[23:19] == 5'b00010) & (SNES_ADDR[15:12] == 4'b0101) )
              // Menu mapper: 8Mbit "SRAM" @ Bank 0xf0-0xff (entire banks!)
              :(MAPPER == 3'b111) ? (&SNES_ADDR[23:20])
              : 1'b0));


/* BS-X has 4 MBits of extra RAM that can be mapped to various places */
// LoROM: A23 = r03/r04  A22 = r06  A21 = r05  A20 = 0    A19 = d/c
// HiROM: A23 = r03/r04  A22 = d/c  A21 = r06  A20 = r05  A19 = 0
wire [2:0] BSX_PSRAM_BANK = {bsx_regs[6], bsx_regs[5], 1'b0};
wire [2:0] SNES_PSRAM_BANK = bsx_regs[2] ? SNES_ADDR[21:19] : SNES_ADDR[22:20];
wire BSX_PSRAM_LOHI = (bsx_regs[3] & ~SNES_ADDR[23]) | (bsx_regs[4] & SNES_ADDR[23]);
wire BSX_IS_PSRAM = BSX_PSRAM_LOHI
                     & (( IS_ROM & (SNES_PSRAM_BANK == BSX_PSRAM_BANK)
                         &(SNES_ADDR[15] | bsx_regs[2])
                         &(~(SNES_ADDR[19] & bsx_regs[2])))
                       | (bsx_regs[2]
                          ? (SNES_ADDR[22:21] == 2'b01 & SNES_ADDR[15:13] == 3'b011)
                          : (~SNES_ROMSEL & &SNES_ADDR[22:20] & ~SNES_ADDR[15]))
                       );

wire BSX_IS_CARTROM = ((bsx_regs[7] & (SNES_ADDR[23:22] == 2'b00))
                      |(bsx_regs[8] & (SNES_ADDR[23:22] == 2'b10)))
                      & SNES_ADDR[15];

wire BSX_HOLE_LOHI = (bsx_regs[9] & ~SNES_ADDR[23]) | (bsx_regs[10] & SNES_ADDR[23]);

wire BSX_IS_HOLE = BSX_HOLE_LOHI
                   & (bsx_regs[2] ? (SNES_ADDR[21:20] == {bsx_regs[11], 1'b0})
                                  : (SNES_ADDR[22:21] == {bsx_regs[11], 1'b0}));

assign bsx_tristate = (MAPPER == 3'b011) & ~BSX_IS_CARTROM & ~BSX_IS_PSRAM & BSX_IS_HOLE;

wire [23:0] BSX_ADDR = bsx_regs[2] ? {1'b0, SNES_ADDR[22:0]}
                                   : {2'b00, SNES_ADDR[22:16], SNES_ADDR[14:0]};

// '1' to signal access to cartrigde writable range (Backup RAM or BS-X RAM)
assign IS_WRITABLE = IS_SAVERAM | ((MAPPER == 3'b011) & BSX_IS_PSRAM);

/* BSX regs:
 Index  Function
    1   0=map flash to ROM area; 1=map PRAM to ROM area
    2   1=HiROM; 0=LoROM
    3   1=Mirror PRAM @60-6f:0000-ffff
    5   1=DO NOT mirror PRAM @40-4f:0000-ffff
    6   1=DO NOT mirror PRAM @50-5f:0000-ffff
    7   1=map BSX cartridge ROM @00-1f:8000-ffff
    8   1=map BSX cartridge ROM @80-9f:8000-ffff
*/
                // HiROM
assign SRAM_SNES_ADDR = ((MAPPER == 3'b000) ? (IS_SAVERAM	? 24'hE00000 + ({SNES_ADDR[20:16], SNES_ADDR[12:0]} & SAVERAM_MASK)
                                        : ({1'b0, SNES_ADDR[22:0]} & ROM_MASK))
                // LoROM
                :(MAPPER == 3'b001) ? (IS_SAVERAM 	? 24'hE00000 + ({SNES_ADDR[20:16], SNES_ADDR[14:0]} & SAVERAM_MASK)
                                        : ({1'b0, ~SNES_ADDR[23], SNES_ADDR[22:16], SNES_ADDR[14:0]} & ROM_MASK))
                // ExtHiROM
                :(MAPPER == 3'b010) ? (IS_SAVERAM 	? 24'hE00000 + ({7'b0000000, SNES_ADDR[19:16], SNES_ADDR[12:0]} & SAVERAM_MASK)
                                        : ({1'b0, !SNES_ADDR[23], SNES_ADDR[21:0]} & ROM_MASK))
                // ExtLoROM
                :(MAPPER == 3'b100) ? (IS_SAVERAM 	? 24'hE00000 + ({7'b0000000, SNES_ADDR[19:16], SNES_ADDR[12:0]} & SAVERAM_MASK)
                                        : ({1'b0, !SNES_ADDR[23], SNES_ADDR[21:0]} & ROM_MASK))
                // BS-X
                :(MAPPER == 3'b011) ? (IS_SAVERAM	? 24'hE00000 + {SNES_ADDR[18:16], SNES_ADDR[11:0]}
                                        : BSX_IS_CARTROM ? (24'h800000 + ({SNES_ADDR[22:16], SNES_ADDR[14:0]} & 24'h0fffff))
                                        : BSX_IS_PSRAM ? (24'h400000 + (BSX_ADDR & 24'h07FFFF))
                                        : bs_page_enable ? (24'h900000 + {bs_page,bs_page_offset})
                                        : (BSX_ADDR & 24'h0fffff))
                // interleaved StarOcean
                :(MAPPER == 3'b110) ? (IS_SAVERAM	? 24'hE00000 + ((SNES_ADDR[14:0] - 15'h6000) & SAVERAM_MASK)
                                        :(SNES_ADDR[15] ? ({1'b0, SNES_ADDR[23:16], SNES_ADDR[14:0]})
                                        :({2'b10, SNES_ADDR[23], SNES_ADDR[21:16], SNES_ADDR[14:0]}) ) )
                // menu
                :(MAPPER == 3'b111) ? (IS_SAVERAM	? SNES_ADDR
                                        : (({1'b0, SNES_ADDR[22:0]} & ROM_MASK) + 24'hC00000) )
                : 24'b0);

assign ROM_ADDR = SRAM_SNES_ADDR;

// '1' when accesing PSRAM for ROM, Backup RAM, BS-X RAM
assign ROM_HIT = IS_ROM | IS_WRITABLE | bs_page_enable;

// '1' when accessing to MSU register map $2000:$2007
assign msu_enable = featurebits[FEAT_MSU1] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff8) == 16'h2000));

// MAGNO -> disabled for S-DD1 core
//assign use_bsx = (MAPPER == 3'b011);
assign use_bsx = 1'b0;

// MAGNO -> disabled for S-DD1 core
//assign srtc_enable = featurebits[FEAT_SRTC] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfffe) == 16'h2800));
assign srtc_enable = 1'b0;


// DSP1 LoROM: DR=30-3f:8000-bfff; SR=30-3f:c000-ffff
//          or DR=60-6f:0000-3fff; SR=60-6f:4000-7fff
// DSP1 HiROM: DR=00-0f:6000-6fff; SR=00-0f:7000-7fff
// MAGNO -> disabled for S-DD1 core
/*assign dspx_enable =
  featurebits[FEAT_DSPX]
  ?((MAPPER == 3'b001)
    ?(ROM_MASK[20]
      ?(SNES_ADDR[22] & SNES_ADDR[21] & ~SNES_ADDR[20] & ~SNES_ADDR[15])
      :(~SNES_ADDR[22] & SNES_ADDR[21] & SNES_ADDR[20] & SNES_ADDR[15])
     )
    :(MAPPER == 3'b000)
      ?(~SNES_ADDR[22] & ~SNES_ADDR[21] & ~SNES_ADDR[20] & ~SNES_ADDR[15]
        & &SNES_ADDR[14:13])
    :1'b0)
  :featurebits[FEAT_ST0010]
  ?(SNES_ADDR[22] & SNES_ADDR[21] & ~SNES_ADDR[20] & &(~SNES_ADDR[19:16]) & ~SNES_ADDR[15])
  :1'b0;
*/
assign dspx_enable = 1'b0;

// MAGNO -> disabled for S-DD1 core
/*
assign dspx_dp_enable = featurebits[FEAT_ST0010]
                      &(SNES_ADDR[22:19] == 4'b1101
                     && SNES_ADDR[15:11] == 5'b00000);
*/
assign dspx_dp_enable = 1'b0;

assign dspx_a0 = featurebits[FEAT_DSPX]
                 ?((MAPPER == 3'b001) ? SNES_ADDR[14]
                   :(MAPPER == 3'b000) ? SNES_ADDR[12]
                   :1'b1)
                 : featurebits[FEAT_ST0010]
                 ? SNES_ADDR[0]
                 : 1'b1;

assign r213f_enable = featurebits[FEAT_213F] & (SNES_PA == 8'h3f);
assign r2100_hit = (SNES_PA == 8'h00);

assign snescmd_enable = ({SNES_ADDR[22], SNES_ADDR[15:9]} == 8'b0_0010101);
assign nmicmd_enable = (SNES_ADDR == 24'h002BF2);
assign return_vector_enable = (SNES_ADDR == 24'h002A5A);
assign branch1_enable = (SNES_ADDR == 24'h002A13);
assign branch2_enable = (SNES_ADDR == 24'h002A4D);
endmodule

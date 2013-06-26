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
  output ROM_SEL,           // enable SRAM0 (active low)
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
  output snescmd_rd_enable,
  output snescmd_wr_enable,
  input [8:0] bs_page_offset,
  input [9:0] bs_page,
  input bs_page_enable
);

parameter [2:0]
  FEAT_DSPX = 0,
  FEAT_ST0010 = 1,
  FEAT_SRTC = 2,
  FEAT_MSU1 = 3,
  FEAT_213F = 4
;

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

assign IS_SAVERAM = SAVERAM_MASK[0]
                    &(featurebits[FEAT_ST0010]
                      ?((SNES_ADDR[22:19] == 4'b1101)
                        & &(~SNES_ADDR[15:12])
                        & SNES_ADDR[11])
                      :((MAPPER == 3'b000
                        || MAPPER == 3'b010
                        || MAPPER == 3'b110
                        || MAPPER == 3'b111)
                      ? (!SNES_ADDR[22]
                         & SNES_ADDR[21]
                         & &SNES_ADDR[14:13]
                         & !SNES_ADDR[15]
                        )
/*  LoROM:   SRAM @ Bank 0x70-0x7d, 0xf0-0xfd Offset 0000-7fff
             TODO: 0000-ffff for small ROMs? */
                      :(MAPPER == 3'b001)
                      ? (&SNES_ADDR[22:20]
                         & (SNES_ADDR[19:16] < 4'b1110)
                         & !SNES_ADDR[15]
                        )
/*  BS-X: SRAM @ Bank 0x10-0x17 Offset 5000-5fff */
                      :(MAPPER == 3'b011)
                      ? ((SNES_ADDR[23:19] == 5'b00010)
                         & (SNES_ADDR[15:12] == 4'b0101)
                        )
                      : 1'b0));


/* BS-X has 4 MBits of extra RAM that can be mapped to various places */
wire [2:0] BSX_PSRAM_BANK = {bsx_regs[2], bsx_regs[6], bsx_regs[5]};
wire [23:0] BSX_CHKADDR = bsx_regs[2] ? SNES_ADDR : {SNES_ADDR[23], 1'b0, SNES_ADDR[22:16], SNES_ADDR[14:0]};
wire BSX_PSRAM_LOHI = (bsx_regs[3] & ~SNES_ADDR[23]) | (bsx_regs[4] & SNES_ADDR[23]);
wire BSX_IS_PSRAM = BSX_PSRAM_LOHI
                     & (( (BSX_CHKADDR[22:20] == BSX_PSRAM_BANK)
                         &(SNES_ADDR[15] | bsx_regs[2])
                         &(~(SNES_ADDR[19] & bsx_regs[2])))
                       | (bsx_regs[2]
                          ? (SNES_ADDR[22:21] == 2'b01 & SNES_ADDR[15:13] == 3'b011)
                          : (&SNES_ADDR[22:20] & ~SNES_ADDR[15]))
                       );

wire BSX_IS_CARTROM = ((bsx_regs[7] & (SNES_ADDR[23:22] == 2'b00))
                      |(bsx_regs[8] & (SNES_ADDR[23:22] == 2'b10)))
							 & SNES_ADDR[15];

wire BSX_HOLE_LOHI = (bsx_regs[9] & ~SNES_ADDR[23]) | (bsx_regs[10] & SNES_ADDR[23]);

wire BSX_IS_HOLE = BSX_HOLE_LOHI
                   & (bsx_regs[2] ? (SNES_ADDR[21:20] == {bsx_regs[11], 1'b0})
                                  : (SNES_ADDR[22:21] == {bsx_regs[11], 1'b0}));

assign bsx_tristate = (MAPPER == 3'b011) & ~BSX_IS_CARTROM & ~BSX_IS_PSRAM & BSX_IS_HOLE;

assign IS_WRITABLE = IS_SAVERAM
                     |((MAPPER == 3'b011)
                       ? BSX_IS_PSRAM
                       : 1'b0);

wire [23:0] BSX_ADDR = bsx_regs[2] ? {1'b0, SNES_ADDR[22:0]}
                                   : {2'b00, SNES_ADDR[22:16], SNES_ADDR[14:0]};

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
                          :(MAPPER == 3'b011)
                          ?(  IS_SAVERAM
                              ? 24'hE00000 + {SNES_ADDR[18:16], SNES_ADDR[11:0]}
                              : BSX_IS_CARTROM
                              ? (24'h800000 + ({SNES_ADDR[22:16], SNES_ADDR[14:0]} & 24'h0fffff))
                              : BSX_IS_PSRAM
                              ? (24'h400000 + (BSX_ADDR & 24'h07FFFF))
                              : bs_page_enable
                              ? (24'h900000 + {bs_page,bs_page_offset})
                              : (BSX_ADDR & 24'h0fffff)
                           )
                           :(MAPPER == 3'b110)
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
                           :(MAPPER == 3'b111)
                           ?(IS_SAVERAM
                             ? 24'hFF0000 + ((SNES_ADDR[14:0] - 15'h6000)
                                             & SAVERAM_MASK)
                             : (({1'b0, SNES_ADDR[22:0]} & ROM_MASK)
                                + 24'hC00000)
                            )
                           : 24'b0);

assign ROM_ADDR = SRAM_SNES_ADDR;

assign ROM_SEL = 1'b0;

assign msu_enable_w = featurebits[FEAT_MSU1] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff8) == 16'h2000));
//reg [5:0] msu_enable_r;
//initial msu_enable_r = 6'b000000;
//always @(posedge CLK) msu_enable_r <= {msu_enable_r[4:0], msu_enable_w};
assign msu_enable = msu_enable_w /*&msu_enable_r[5:2]*/;

assign use_bsx = (MAPPER == 3'b011);

assign srtc_enable_w = (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfffe) == 16'h2800));
//reg [5:0] srtc_enable_r;
//initial srtc_enable_r = 6'b000000;
//always @(posedge CLK) srtc_enable_r <= {srtc_enable_r[4:0], srtc_enable_w};
assign srtc_enable = srtc_enable_w /*&srtc_enable_r[3:0]*/ & featurebits[FEAT_SRTC];


// DSP1 LoROM: DR=30-3f:8000-bfff; SR=30-3f:c000-ffff
//          or DR=60-6f:0000-3fff; SR=60-6f:4000-7fff
// DSP1 HiROM: DR=00-0f:6000-6fff; SR=00-0f:7000-7fff
wire dspx_enable_w =
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

wire dspx_dp_enable_w = featurebits[FEAT_ST0010]
                         &(SNES_ADDR[22:19] == 4'b1101
                          && SNES_ADDR[15:11] == 5'b00000);

assign dspx_a0 = featurebits[FEAT_DSPX]
                 ?((MAPPER == 3'b001) ? SNES_ADDR[14]
                   :(MAPPER == 3'b000) ? SNES_ADDR[12]
                   :1'b1)
                 :featurebits[FEAT_ST0010]
                 ?SNES_ADDR[0]
                 :1'b1;

assign dspx_dp_enable = dspx_dp_enable_w;

//reg [5:0] dspx_enable_r;
//initial dspx_enable_r = 6'b000000;
//always @(posedge CLK) dspx_enable_r <= {dspx_enable_r[4:0], dspx_enable_w};
assign dspx_enable = dspx_enable_w /*&dspx_enable_r[5:1]*/;

wire r213f_enable_w = (SNES_PA == 8'h3f);
//reg [5:0] r213f_enable_r;
//initial r213f_enable_r = 6'b000000;
//always @(posedge CLK) r213f_enable_r <= {r213f_enable_r[4:0], r213f_enable_w};
assign r213f_enable = r213f_enable_w /*&r213f_enable_r[5:2]*/ & featurebits[FEAT_213F];

wire snescmd_rd_enable_w = (SNES_PA[7:4] == 4'b1111);
//reg [5:0] snescmd_rd_enable_r;
//initial snescmd_rd_enable_r = 6'b000000;
//always @(posedge CLK) snescmd_rd_enable_r <= {snescmd_rd_enable_r[4:0], snescmd_rd_enable_w};
assign snescmd_rd_enable = snescmd_rd_enable_w /*&snescmd_rd_enable_r[5:1]*/;

assign snescmd_wr_enable_w = (SNES_ADDR[23:4] == 20'hccccc);
//reg [5:0] snescmd_wr_enable_r;
//initial snescmd_wr_enable_r = 6'b000000;
//always @(posedge CLK) snescmd_wr_enable_r <= {snescmd_wr_enable_r[4:0], snescmd_wr_enable_w};
assign snescmd_wr_enable = snescmd_wr_enable_w /*&snescmd_wr_enable_r[5:1]*/;

endmodule

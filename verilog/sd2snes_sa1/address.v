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
  input [15:0] featurebits,  // peripheral enable/disable
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
  input [4:0] sa1_bmaps_sbm,
  input  sa1_dma_cc1_en,
  input [11:0] sa1_xxb,
  input [3:0] sa1_xxb_en,
//  output srtc_enable,
  output r213f_enable,
  output r2100_hit,
  output snescmd_enable,
  output nmicmd_enable,
  output return_vector_enable,
  output branch1_enable,
  output branch2_enable,
  output branch3_enable,
  output sa1_enable,
  // BS Memory Pack flash slot (writable): write strobe + data in; write-enable
  // and read-override (vendor "M P"/status) out.
  input SNES_WR_end,
  input [7:0] SNES_DATA_IN,
  output IS_FLASHWR,
  output BS_FLASH_OVR,
  output [7:0] BS_FLASH_DOUT,
  // Flash block-erase request to the MCU (seq increments per erase; blk 0xF = all)
  output [1:0] bs_erase_seq,
  output [3:0] bs_erase_blk
);

parameter [2:0]
  //FEAT_DSPX = 0,
  //FEAT_ST0010 = 1,
  //FEAT_SRTC = 2,
  FEAT_MSU1 = 3,
  FEAT_213F = 4,
  FEAT_2100 = 6
 ;
// BS Memory Pack slot bit (>2:0, declared separately).  Mirrors sd2snes_base.
localparam FEAT_BSSLOT = 14;

// Static Inputs
reg [23:0] ROM_MASK_r     = 0;
reg [23:0] SAVERAM_MASK_r = 0;
reg        iram_battery_r = 0;

always @(posedge CLK) begin
  ROM_MASK_r     <= ROM_MASK;
  SAVERAM_MASK_r <= SAVERAM_MASK;
  iram_battery_r <= ~SAVERAM_MASK_r[1] & SAVERAM_MASK_r[0];
end

wire [23:0] SRAM_SNES_ADDR;

wire [2:0] xxb[3:0];
assign {xxb[3], xxb[2], xxb[1], xxb[0]} = sa1_xxb;
wire [3:0] xxb_en = sa1_xxb_en;

assign IS_ROM = ~SNES_ROMSEL;

assign IS_SAVERAM = SAVERAM_MASK_r[0]
                    & ( // 40-4F:0000-FFFF
                        ( ~SNES_ADDR[23]
                        &  SNES_ADDR[22]
                        & ~SNES_ADDR[21]
                        & ~SNES_ADDR[20]
                        & ~sa1_dma_cc1_en
                        )
                        // 00-3F/80-BF:6000-7FFF
                      | ( ~SNES_ADDR[22]
                        & ~SNES_ADDR[15]
                        & &SNES_ADDR[14:13]
                        )
                      | ( iram_battery_r
                        & ~SNES_ADDR[22]
                        & ~SNES_ADDR[15]
                        & ~SNES_ADDR[14]
                        &  SNES_ADDR[13]
                        &  SNES_ADDR[12]
                        & ~SNES_ADDR[11]
                        )
                      );

assign IS_WRITABLE = IS_SAVERAM;

// ROM address before the BS-pack redirect / ROM_MASK.  SA-1 SuperMMC: $C0-$FF use
// xxb[bank]; $00-3F/$80-BF use the default {A23,A21} block unless xxb_en selects one.
// Bits [22:20] = resolved MMC block (0..7), bits [19:0] = offset within the 1MB block.
wire [23:0] ROM_ADDR_pre = (SNES_ADDR[22]
                            ? {1'b0, xxb[SNES_ADDR[21:20]], SNES_ADDR[19:0]}
                            : {1'b0, (xxb_en[{SNES_ADDR[23],SNES_ADDR[21]}] ? xxb[{SNES_ADDR[23],SNES_ADDR[21]}] : {1'b0,SNES_ADDR[23],SNES_ADDR[21]}), SNES_ADDR[20:16], SNES_ADDR[14:0]});

// BS Memory Pack slot: when a pack is present (FEAT_BSSLOT) and the game points an MMC
// bank register at block >= 4 (e.g. SD Gundam G Next: $2223=$84 after padding the cart
// to 4MB, then reading the pack appended at the end), redirect those reads to the pack
// staged at PSRAM 0x900000 (1MB, mirrored across blocks 4-7).  ROM_ADDR_pre[22] = high
// bit of the 3-bit MMC block = "block >= 4".
wire BS_PACK_HIT = featurebits[FEAT_BSSLOT] & ROM_ADDR_pre[22];

`ifndef MK2
// --- BS Memory Pack flash command FSM (writable slot) ----------------------
// Like sd2snes_base/bsx.v, but keyed on the resolved pack offset so it follows
// the SuperMMC.  Command port = pack offset 0.  Idle for ROM packs (G Next).
// Gated out on mk2: SA-1 packs are read-only (read via SuperMMC, never flash
// commands), so this whole FSM is dead there -- drop it to fit the Spartan-3.
reg bs_flash_ovr_r = 1'b0;     // 1 = vendor/status override active (not read-array)
reg bs_flash_status_r = 1'b0;  // 1 = status mode ($80); 0 = vendor mode ("M P")
reg bs_flash_we_r = 1'b0;      // armed: the next pack write is the program data byte
reg [7:0] bs_flash_cmd0 = 8'h00;

// block erase = $20/$A7 then $D0 at the block address: seq counter the MCU compares,
// busy timer so the game waits per block.
reg [1:0] bs_erase_seq_r = 0;
reg [3:0] bs_erase_blk_r = 0;
reg bs_erase_setup_r = 0, bs_erase_all_setup_r = 0;
reg [24:0] bs_erase_busy_cnt = 0;
wire bs_erase_busy = (bs_erase_busy_cnt != 0);
assign bs_erase_seq = bs_erase_seq_r;
assign bs_erase_blk = bs_erase_blk_r;
wire [3:0] bs_erase_blk_of = ROM_ADDR_pre[19:16]; // 64KB block within the 1MB pack

wire bs_cmd_port = BS_PACK_HIT & (ROM_ADDR_pre[19:0] == 20'h00000); // pack offset 0
wire [15:0] bs_flash_addr = ROM_ADDR_pre[15:0];

always @(posedge CLK) begin
  if(bs_erase_busy_cnt != 0) bs_erase_busy_cnt <= bs_erase_busy_cnt - 1'b1;  // WSM busy timer
  if(SNES_WR_end & BS_PACK_HIT) begin
    if(bs_flash_we_r) begin
      bs_flash_we_r <= 1'b0;         // this write is the program byte, not a command
    end else begin
      // program/erase are issued at the target/block address (tracked regardless of
      // address); program only arms the write byte.  Mode commands stay at the command port.
      case(SNES_DATA_IN)
        8'h10, 8'h40: begin bs_flash_we_r <= 1'b1; bs_erase_setup_r <= 1'b0; bs_erase_all_setup_r <= 1'b0; end
        8'h20: begin bs_erase_setup_r <= 1'b1; bs_erase_all_setup_r <= 1'b0; end
        8'ha7: begin bs_erase_all_setup_r <= 1'b1; bs_erase_setup_r <= 1'b0; end
        8'hd0: begin
          // block = the $D0 (confirm) address, not $20 (setup): $20 at the command port,
          // $D0 at the block address.
          if(bs_erase_setup_r) begin
            bs_erase_seq_r <= bs_erase_seq_r + 1'b1; bs_erase_blk_r <= bs_erase_blk_of;
            bs_erase_busy_cnt <= {25{1'b1}}; bs_flash_ovr_r <= 1'b1; bs_flash_status_r <= 1'b1;
          end else if(bs_erase_all_setup_r) begin
            bs_erase_seq_r <= bs_erase_seq_r + 1'b1; bs_erase_blk_r <= 4'hf;
            bs_erase_busy_cnt <= {25{1'b1}}; bs_flash_ovr_r <= 1'b1; bs_flash_status_r <= 1'b1;
          end
          bs_erase_setup_r <= 1'b0; bs_erase_all_setup_r <= 1'b0;
        end
        default: begin bs_erase_setup_r <= 1'b0; bs_erase_all_setup_r <= 1'b0; end
      endcase
      if(bs_cmd_port) begin
        bs_flash_cmd0 <= SNES_DATA_IN;
        if(bs_flash_cmd0 == 8'h72 && SNES_DATA_IN == 8'h75) begin
          bs_flash_ovr_r <= 1'b1; bs_flash_status_r <= 1'b0;          // vendor/page read
        end else if(SNES_DATA_IN == 8'hff) begin
          bs_flash_ovr_r <= 1'b0;                                     // read array
        end else if(SNES_DATA_IN[7:1] == 7'b0111000                  // $70/$71 read status
                    || (bs_flash_cmd0 == 8'h38 && SNES_DATA_IN == 8'hd0)) begin
          bs_flash_ovr_r <= 1'b1; bs_flash_status_r <= 1'b1;
        end
      end
    end
  end
end

// program data-phase: enable the PSRAM write for the pack (consumed by main.v ROM_WE).
// The command byte itself never reaches the array: bs_flash_we_r is still 0 while the
// $10/$40 is written, and only flips on its trailing SNES_WR_end.
assign IS_FLASHWR = BS_PACK_HIT & bs_flash_we_r;

// read override: synth "M P" + chip info (vendor) or $80 (ready) in command modes.
assign BS_FLASH_OVR = BS_PACK_HIT & bs_flash_ovr_r;
reg [7:0] bs_flash_dout_r;
always @(*) begin
  casex(bs_flash_addr)
    16'b1111111100000xxx:           // $FF00-$FF07: "4D 00 50 00 00 00 1A 00"
      case(bs_flash_addr[2:0])
        3'h0:    bs_flash_dout_r = bs_flash_status_r ? (bs_erase_busy ? 8'h00 : 8'h80) : 8'h4d; // 'M'
        3'h2:    bs_flash_dout_r = bs_flash_status_r ? (bs_erase_busy ? 8'h00 : 8'h80) : 8'h50; // 'P'
        3'h6:    bs_flash_dout_r = bs_flash_status_r ? (bs_erase_busy ? 8'h00 : 8'h80) : 8'h1a; // type1/1MB
        default: bs_flash_dout_r = bs_flash_status_r ? (bs_erase_busy ? 8'h00 : 8'h80) : 8'h00;
      endcase
    16'b1111111100001xxx,
    16'b11111111000100xx:           // $FF08-$FF13
      bs_flash_dout_r = bs_flash_status_r ? (bs_erase_busy ? 8'h00 : 8'h80) : 8'h00;
    default:
      bs_flash_dout_r = (bs_erase_busy ? 8'h00 : 8'h80);  // CSR busy/ready
  endcase
end
assign BS_FLASH_DOUT = bs_flash_dout_r;
`else
// mk2: flash FSM gated out -- tie the outputs off (pack still reads via SuperMMC below).
assign IS_FLASHWR   = 1'b0;
assign BS_FLASH_OVR = 1'b0;
assign BS_FLASH_DOUT = 8'h00;
assign bs_erase_seq = 2'b00;
assign bs_erase_blk = 4'h0;
`endif

// TODO: add programmable address map
assign SRAM_SNES_ADDR = (IS_SAVERAM
                         // 40-4F:0000-FFFF or 00-3F/80-BF:6000-7FFF (first 8K mirror).  Mask handles mirroring.  60 is sa1-only
                         ? (24'hE00000 + (iram_battery_r ? SNES_ADDR[10:0] : ((SNES_ADDR[22] ? SNES_ADDR[19:0] : {sa1_bmaps_sbm,SNES_ADDR[12:0]}) & SAVERAM_MASK_r)))
                         // BS pack: MMC block >= 4 -> pack at PSRAM 0x900000 (no ROM_MASK)
                         : BS_PACK_HIT
                         ? (24'h900000 + {4'h0, ROM_ADDR_pre[19:0]})
                         // C0-FF:0000-FFFF or 00-3F/80-BF:8000-FFFF
                         : (ROM_ADDR_pre & ROM_MASK_r)
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
endmodule

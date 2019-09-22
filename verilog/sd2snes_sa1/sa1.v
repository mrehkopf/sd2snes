`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    06:32:24 04/24/2018
// Design Name:
// Module Name:    sa1
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module sa1(
  input         RST,
  input         CLK,

  input  [23:0] SAVERAM_MASK,
  input  [23:0] ROM_MASK,

  // MMIO interface
  //input         ENABLE,
  input         SNES_READ,
  input         SNES_WRITE,
  input         SNES_RD_start,
  input         SNES_RD_end,
  input         SNES_WR_start,
  input         SNES_WR_end,
  input         SNES_cycle_end,
  input  [23:0] SNES_ADDR,
  input  [7:0]  DATA_IN,
  output        DATA_ENABLE,
  output [7:0]  DATA_OUT,

  // ROM interface
  input         ROM_BUS_RDY,
  output        ROM_BUS_RRQ,
  output        ROM_BUS_WRQ,
  output        ROM_BUS_WORD,
  output [23:0] ROM_BUS_ADDR,
  input  [15:0] ROM_BUS_RDDATA,
  output [15:0] ROM_BUS_WRDATA,

  output        ROM_HIT,

  // RAM interface
  input         RAM_BUS_RDY,
  output        RAM_BUS_RRQ,
  output        RAM_BUS_WRQ,
  output        RAM_BUS_WORD,
  output [23:0] RAM_BUS_ADDR,
  input  [7:0]  RAM_BUS_RDDATA,
  output [7:0]  RAM_BUS_WRDATA,

  output        RAM_HIT,

  // address map
  output [4:0]  BMAPS_SBM,
  output [15:0] SNV,
  output [15:0] SIV,
  output        SCNT_NVSW,
  output        SCNT_IVSW,
  output        DMA_CC1_EN,
  output [11:0] XXB_OUT,
  output [3:0]  XXB_EN_OUT,

  output        IRQ,

  input         SPEED,

  // State debug read interface
  input  [11:0] PGM_ADDR, // [11:0]
  output [7:0]  PGM_DATA, // [7:0]

  // config interface
  input  [7:0]  reg_group_in,
  input  [7:0]  reg_index_in,
  input  [7:0]  reg_value_in,
  input  [7:0]  reg_invmask_in,
  input         reg_we_in,
  input  [7:0]  reg_read_in,
  output [7:0]  config_data_out,
  // config interface

  output        DBG
);

//-------------------------------------------------------------------
// NOTES
//-------------------------------------------------------------------
// This is a cycle-approximate implementation of the sa1 chip.  The sa1
// is a 65c816 core running at ~10.74 MHz.  It can serve as an off-load
// engine/accelerator or a peer to the host snes cpu.
//
// There are base 65c816 as well as custom features available to the sa1
// with varying levels of implementation.  Several features have been left
// out in order to make development easier and fit basic functionality on
// the fpga.
//
// [x] full native 65c816 instruction set. (not fully debugged)
// [x] host and slave mmio support for reset and other basic functionality
// [x] host and slave access to bram (cart ram) and iram.
// [_] 65c816 emulation mode.  (known holes in emulation execution)
// [x] dma/normal
// [x] dma/cc
// [x] host interrupts
// [x] host interrupt vectors
// [x] sa1 interrupts
// [_] counters
// [x] bcd mode/math (overflow likely not set correctly)
// [x] rom address mapping
// [x] ram address mapping
// [x] multiply/divide
// [x] mac support for multiply
// [_] full mdr support
// [x] variable length data/fixed
// [x] variable length data/auto

//-------------------------------------------------------------------
// DEFINES
//-------------------------------------------------------------------

//`define DEBUG
`define DEBUG_IRAM
`define DEBUG_MMIO
//`define DEBUG_EXT
//`define DEBUG_MMC
//`define DEBUG_EXE
//`define DEBUG_DMA

`define DMA_ENABLE
`define DMA_NORMAL_ENABLE
`define DMA_TYPE1_ENABLE
`define DMA_TYPE2_ENABLE
`define VBD_ENABLE
`define BCD_ENABLE

`define EXE_FAST_FETCH
`define EXE_FAST_MOVE

// temporaries
integer i;
wire pipeline_advance;

function integer clog2;
  input integer value;
  begin
    value = value-1;
    for (clog2=0; value>0; clog2=clog2+1)
      value = value>>1;
  end
endfunction

`define BCD_CARRY(c,s) (c | (s[3] & (s[2] | s[1])))
function [2:0] bcd_adder;
  input       carry;
  input [3:0] sum;

  begin
    bcd_adder = {`BCD_CARRY(carry,sum),`BCD_CARRY(carry,sum),1'b0};
  end
endfunction

//-------------------------------------------------------------------
// INPUTS
//-------------------------------------------------------------------
reg [7:0]  data_in_r;
reg [23:0] addr_in_r;
//reg        enable_r;
reg [11:0]  pgm_addr_r;

reg [23:0]  SAVERAM_MASK_r; initial SAVERAM_MASK_r = 0;
reg [23:0]  ROM_MASK_r; initial ROM_MASK_r = 0;
// TODO: battery backed iram support doesn't fit.  For now, only let the snes access it.
reg         iram_battery_r; initial iram_battery_r = 0;

always @(posedge CLK) begin
  data_in_r  <= DATA_IN;
  addr_in_r  <= SNES_ADDR;
  //enable_r   <= ENABLE;
  pgm_addr_r <= PGM_ADDR;

  SAVERAM_MASK_r <= SAVERAM_MASK;
  ROM_MASK_r     <= ROM_MASK;
  // battery backed iram is encoded as a mask of 1 by the firmware.
  iram_battery_r <= ~SAVERAM_MASK_r[1] & SAVERAM_MASK_r[0];
end

//-------------------------------------------------------------------
// ADDRESS MAP
//-------------------------------------------------------------------
wire       sw46;
wire [6:0] cbm;
wire       bbf;
reg  [2:0] xxb[3:0];
wire [3:0] xxb_en;

// address map tests
`define IS_ROM(a)  ((&a[23:22]) | (~a[22] & a[15]))                                              // 00-3F/80-BF:8000-FFFF, C0-FF:0000-FFFF
//`define IS_SA1_IRAM(a) (~iram_battery_r & ~a[22] & ~a[15] & ~a[14] & ~^a[13:12] & ~a[11])                          // 00-3F/80-BF:0/3000-0/37FF
`define IS_SA1_IRAM(a) (~a[22] & ~a[15] & ~a[14] & ~^a[13:12] & ~a[11])                          // 00-3F/80-BF:0/3000-0/37FF
`define IS_CPU_IRAM(a) (~iram_battery_r & ~a[22] & ~a[15] & ~a[14] & &a[13:12] & ~a[11])                           // 00-3F/80-BF:3000-37FF
//`define IS_SA1_BRAM(a) ((iram_battery_r & `IS_SA1_IRAM(a)) | (~sw46 & ~a[22] & ~a[15] & &a[14:13]) | (~a[23] & a[22] & ~a[21] & ~a[20])) // 00-3F/80-BF:6000-7FFF, 40-4F:0000-FFFF
`define IS_SA1_BRAM(a) ((~sw46 & ~a[22] & ~a[15] & &a[14:13]) | (~a[23] & a[22] & ~a[21] & ~a[20])) // 00-3F/80-BF:6000-7FFF, 40-4F:0000-FFFF
// NOTE: the following is only used for cc1 DMA
`define IS_CPU_BRAM(a) ((~a[22] & ~a[15] & &a[14:13]) | (~a[23] & a[22] & ~a[21] & ~a[20]))      // 00-3F/80-BF:6000-7FFF, 40-4F:0000-FFFF
`define IS_MMIO(a) (~a[22] & ~a[15] & ~a[14] & a[13] & ~a[12] & ~a[11] & ~a[10] & a[9])          // 00-3F/80-BF:2200-23FF
`define IS_SA1_PRAM(a) ((sw46 & ~a[22] & ~a[15] & &a[14:13]) | (~a[23] & a[22] & a[21] & ~a[20])) // 00-3F/80-BF:6000-7FFF, 60-6F:0000-FFFF

`define MAP_ROM(a)  ((a[22] ? {1'b0, xxb[a[21:20]], a[19:0]} : {1'b0, xxb_en[{a[23],a[21]}] ? xxb[{a[23],a[21]}] : {1'b0,a[23],a[21]}, a[20:16], a[14:0]}) & ROM_MASK_r)
`define MAP_IRAM(a) (a[10:0])
`define MAP_MMIO(a) (a[8:0])
//`define MAP_BRAM(a) (iram_battery_r ? `MAP_IRAM(a) : ((a[22] ? a[19:0] : {cbm[4:0],a[12:0]}) & SAVERAM_MASK_r))
`define MAP_BRAM(a) ((a[22] ? a[19:0] : {cbm[4:0],a[12:0]}) & SAVERAM_MASK_r)
`define MAP_PRAM(a) ((a[22] ? (bbf ? a[19:2] : a[19:1]) : (bbf ? {cbm[6:0],a[12:2]} : {cbm[6:0],a[12:1]})) & SAVERAM_MASK_r)

//-------------------------------------------------------------------
// PARAMETERS
//-------------------------------------------------------------------

parameter
  // write
  ADDR_CCNT  = 9'h000,
  ADDR_SIE   = 9'h001,
  ADDR_SIC   = 9'h002,
  ADDR_CRV   = 9'h003, // $2
  //
  ADDR_CNV   = 9'h005, // $2
  //
  ADDR_CIV   = 9'h007, // $2
  //
  ADDR_SCNT  = 9'h009,
  ADDR_CIE   = 9'h00A,
  ADDR_CIC   = 9'h00B,
  ADDR_SNV   = 9'h00C, // $2
  //
  ADDR_SIV   = 9'h00E, // $2
  //

  ADDR_TMC   = 9'h010,
  ADDR_CTR   = 9'h011,
  ADDR_HCNT  = 9'h012, // $2
  //
  ADDR_VCNT  = 9'h014, // $2
  //
  ADDR_CXB   = 9'h020,
  ADDR_DXB   = 9'h021,
  ADDR_EXB   = 9'h022,
  ADDR_FXB   = 9'h023,
  ADDR_BMAPS = 9'h024,
  ADDR_BMAP  = 9'h025,
  ADDR_SWBE  = 9'h026,
  ADDR_CWBE  = 9'h027,
  ADDR_BWPA  = 9'h028,
  ADDR_SIWP  = 9'h029,
  ADDR_CIWP  = 9'h02A,
  //
  ADDR_DCNT  = 9'h030,
  ADDR_CDMA  = 9'h031,
  ADDR_DSA   = 9'h032, // $3
  //
  //
  ADDR_DDA   = 9'h035, // $3
  //
  //
  ADDR_DTC   = 9'h038,
  //
  ADDR_BBF   = 9'h03F,
  ADDR_BRF   = 9'h040, // $10
  ADDR_BRF0  = 9'h040,
  ADDR_BRF1  = 9'h041,
  ADDR_BRF2  = 9'h042,
  ADDR_BRF3  = 9'h043,
  ADDR_BRF4  = 9'h044,
  ADDR_BRF5  = 9'h045,
  ADDR_BRF6  = 9'h046,
  ADDR_BRF7  = 9'h047,
  ADDR_BRF8  = 9'h048,
  ADDR_BRF9  = 9'h049,
  ADDR_BRFA  = 9'h04A,
  ADDR_BRFB  = 9'h04B,
  ADDR_BRFC  = 9'h04C,
  ADDR_BRFD  = 9'h04D,
  ADDR_BRFE  = 9'h04E,
  ADDR_BRFF  = 9'h04F,

  ADDR_MCNT  = 9'h050,
  ADDR_MA    = 9'h051, // $2
  //
  ADDR_MB    = 9'h053, // $2
  //
  ADDR_VBD   = 9'h058,
  ADDR_VDA   = 9'h059  // $3
  ;

parameter
  ADDR_SFR   = 9'h100,
  ADDR_CFR   = 9'h101,
  ADDR_HCR   = 9'h102, // $2
  ADDR_VCR   = 9'h104, // $2
  ADDR_MR    = 9'h106, // $5
  ADDR_OF    = 9'h10B,
  ADDR_VDP   = 9'h10C, // $2
  ADDR_VC    = 9'h10E
  ;

//-------------------------------------------------------------------
// CONFIG
//-------------------------------------------------------------------

// C0 Control
// 0 - Go (1)
// 1 - MatchFullInst

// C1 StepControl
// [7:0] StepCount

// C2 BreakpointControl
// 0 - BreakOnInstRdByteWatch
// 1 - BreakOnDataRdByteWatch
// 2 - BreakOnDataWrByteWatch
// 3 - BreakOnInstRdAddrWatch
// 4 - BreakOnDataRdAddrWatch
// 5 - BreakOnDataWrAddrWatch
// 6 - BreakOnStop
// 7 - BreakOnError

// C3 ???

// C4 DataWatch
// [7:0] DataWatch

// C5-C7 AddrWatch (little endian)
// [23:0] AddrWatch

// breakpoint state
`ifdef DEBUG
reg         brk_inst_rd_byte; initial brk_inst_rd_byte = 0;
reg         brk_data_rd_byte; initial brk_data_rd_byte = 0;
reg         brk_data_wr_byte; initial brk_data_wr_byte = 0;
reg         brk_inst_rd_addr; initial brk_inst_rd_addr = 0;
reg         brk_data_rd_addr; initial brk_data_rd_addr = 0;
reg         brk_data_wr_addr; initial brk_data_wr_addr = 0;
reg         brk_data;         initial brk_data = 0;
reg         brk_stop;         initial brk_stop = 0;
reg         brk_error;        initial brk_error = 0;

parameter CONFIG_REGISTERS = 8;
reg [7:0] config_r[CONFIG_REGISTERS-1:0]; initial for (i = 0; i < CONFIG_REGISTERS; i = i + 1) config_r[i] = 8'h00;

always @(posedge CLK) begin
  if (RST) begin
    //for (i = 0; i < CONFIG_REGISTERS; i = i + 1) config_r[i] <= 8'h00;
  end
  else if (reg_we_in && (reg_group_in == 8'h03)) begin
    if (reg_index_in < CONFIG_REGISTERS) config_r[reg_index_in] <= (config_r[reg_index_in] & reg_invmask_in) | (reg_value_in & ~reg_invmask_in);
  end
  else begin
    config_r[0][0] <= config_r[0][0] & ~|(config_r[2] & {brk_error,brk_stop,brk_data_wr_addr,brk_data_rd_addr,brk_inst_rd_addr,brk_data_wr_byte,brk_data_rd_byte,brk_inst_rd_byte});
  end
end

assign config_data_out = config_r[reg_read_in];

assign      CONFIG_CONTROL_ENABLED       = config_r[0][0];
assign      CONFIG_CONTROL_MATCHPARTINST = config_r[0][1];

wire [7:0]  CONFIG_STEP_COUNT   = config_r[1];
wire [7:0]  CONFIG_DATA_WATCH   = config_r[4];
wire [23:0] CONFIG_ADDR_WATCH   = {config_r[7],config_r[6],config_r[5]};
`else
wire [7:0] CONFIG_STEP_COUNT = 0;
assign CONFIG_CONTROL_ENABLED = 1;
assign CONFIG_CONTROL_MATCHPARTINST = 0;
`endif

//-------------------------------------------------------------------
// FLOPS
//-------------------------------------------------------------------
reg [23:0] debug_inst_addr_r;
reg [23:0] debug_inst_addr_prev_r;

reg [2:0]  sa1_cycle_r; initial sa1_cycle_r = 0;
reg        sa1_clock_en; initial sa1_clock_en = 0;

// step counter for pipelines
reg [7:0] stepcnt_r; initial stepcnt_r = 0;
reg       step_r; initial step_r = 0;

wire      sa1_clock_en_pre = sa1_cycle_r == 6;

always @(posedge CLK) begin
  if (RST) begin
    sa1_cycle_r <= 0;
    sa1_clock_en <= 0;
  end
  else begin
    sa1_cycle_r  <= sa1_cycle_r + 1;
    sa1_clock_en <= sa1_clock_en_pre;
  end
end

reg [31:0] sa1_cycle_cnt_r; initial sa1_cycle_cnt_r = 0;

//-------------------------------------------------------------------
// STATE
//-------------------------------------------------------------------
// register state
reg [7:0]   PBR_r;  initial PBR_r  = 0;
reg [15:0]  PC_r;   initial PC_r   = 0;
reg [15:0]  A_r;    initial A_r    = 0;
reg [15:0]  X_r;    initial X_r    = 0;
reg [15:0]  Y_r;    initial Y_r    = 0;
reg [15:0]  S_r;    initial S_r    = 16'h01FF;
reg [15:0]  D_r;    initial D_r    = 0;
reg [7:0]   DBR_r;   initial DBR_r   = 0;
reg [7:0]   P_r;    initial P_r    = 8'h34;
reg         E_r;    initial E_r    = 1;
reg         WAI_r;  initial WAI_r  = 0;

// write-only MMIO
reg [7:0]   CCNT_r; initial CCNT_r = 8'h20;
reg [7:0]   SIE_r;  initial SIE_r  = 0;
reg [7:0]   SIC_r;  initial SIC_r  = 0;
reg [15:0]  CRV_r;  initial CRV_r  = 0;
reg [15:0]  CNV_r;  initial CNV_r  = 0;
reg [15:0]  CIV_r;  initial CIV_r  = 0;
reg [7:0]   SCNT_r; initial SCNT_r = 0;
reg [7:0]   CIE_r;  initial CIE_r  = 0;
reg [7:0]   CIC_r;  initial CIC_r  = 0;
reg [15:0]  SNV_r;  initial SNV_r  = 0;
reg [15:0]  SIV_r;  initial SIV_r  = 0;
reg [7:0]   TMC_r;  initial TMC_r  = 0;
reg [7:0]   CTR_r;  initial CTR_r  = 0;
reg [15:0]  HCNT_r; initial HCNT_r = 0;
reg [15:0]  VCNT_r; initial VCNT_r = 0;
reg [7:0]   CXB_r;  initial CXB_r  = 0;
reg [7:0]   DXB_r;  initial DXB_r  = 1;
reg [7:0]   EXB_r;  initial EXB_r  = 2;
reg [7:0]   FXB_r;  initial FXB_r  = 3;
reg [7:0]   BMAPS_r;initial BMAPS_r= 0;
reg [7:0]   BMAP_r; initial BMAP_r = 0;
reg [7:0]   SWBE_r; initial SWBE_r = 0;
reg [7:0]   CWBE_r; initial CWBE_r = 0;
reg [7:0]   BWPA_r; initial BWPA_r = 8'hFF;
reg [7:0]   SIWP_r; initial SIWP_r = 0;
reg [7:0]   CIWP_r; initial CIWP_r = 0;
reg [7:0]   DCNT_r; initial DCNT_r = 0;
reg [7:0]   CDMA_r; initial CDMA_r = 0;
reg [23:0]  DSA_r;  initial DSA_r  = 0;
reg [23:0]  DDA_r;  initial DDA_r  = 0;
reg [15:0]  DTC_r;  initial DTC_r  = 0;
reg [7:0]   BBF_r;  initial BBF_r  = 0;
reg [7:0]   BRF_r[15:0]; initial for (i = 0; i < 16; i = i + 1) BRF_r[i] = 0;
reg [7:0]   MCNT_r; initial MCNT_r = 0;
reg [15:0]  MA_r;   initial MA_r   = 0;
reg [15:0]  MB_r;   initial MB_r   = 0;
reg [7:0]   VBD_r;  initial VBD_r  = 0;
reg [23:0]  VDA_r;  initial VDA_r  = 0;

// read-only through MMIO
reg [7:0]   SFR_r;  initial SFR_r  = 0;
reg [7:0]   CFR_r;  initial CFR_r  = 0;
reg [15:0]  HCR_r;  initial HCR_r  = 0;
reg [15:0]  VCR_r;  initial VCR_r  = 0;
reg [39:0]  MR_r;   initial MR_r   = 0;
reg [7:0]   OF_r;   initial OF_r   = 0;
reg [15:0]  VDP_r;  initial VDP_r  = 0;
reg [7:0]   VC_r;   initial VC_r   = 0;

// internal state
reg [15:0]  hcounter_r; initial hcounter_r = 0;
reg [15:0]  vcounter_r; initial vcounter_r = 0;

// Important parameters
`define P_C           0
`define P_Z           1
`define P_I           2
`define P_D           3
`define P_X           4
`define P_M           5
`define P_V           6
`define P_N           7
`define P_B           4

`define CCNT_SMEG     3:0
`define CCNT_SA1_NMI  4
`define CCNT_SA1_RESB 5
`define CCNT_SA1_RDYB 6
`define CCNT_SA1_IRQ  7

`define SIE_DMA_IRQEN 5
`define SIE_CPU_IRQEN 7

`define SIC_DMA_IRQCL 5
`define SIC_CPU_IRQCL 7

`define SCNT_CMEG     3:0
`define SCNT_NVSW     4
`define SCNT_IVSW     6
`define SCNT_CPU_IRQ  7

`define CIE_SA1_NMIEN 4
`define CIE_DMA_IRQEN 5
`define CIE_TMR_IRQEN 6
`define CIE_SA1_IRQEN 7

`define CIC_SA1_NMICL 4
`define CIC_DMA_IRQCL 5
`define CIC_TMR_IRQCL 6
`define CIC_SA1_IRQCL 7

`define TMC_HEN       0
`define TMC_VEN       1
`define TMC_HVSELB    7

`define CXB_CB        2:0
`define CXB_CBMODE    7

`define DXB_DB        2:0
`define DXB_DBMODE    7

`define EXB_EB        2:0
`define EXB_EBMODE    7

`define FXB_FB        2:0
`define FXB_FBMODE    7

`define BMAPS_SBM     4:0

`define BMAP_CBM      6:0
`define BMAP_SW46     7

`define SWBE_SWEN     7

`define CWBE_CWEN     7

`define BWPA_BWP      3:0

`define DCNT_SD       1:0
`define DCNT_DD       2
`define DCNT_CDSEL    4
`define DCNT_CDEN     5
`define DCNT_DPRIO    6
`define DCNT_DMAEN    7

`define CDMA_DMACB    1:0
`define CDMA_DMASIZE  4:2
`define CDMA_CHDEND   7

`define BBF_BBF       7

`define MCNT_MD       0
`define MCNT_ACM      1

`define VBD_VB        3:0
`define VBD_HL        7

`define SFR_DMA_IRQFL 5
`define SFR_CPU_IRQFL 7

`define CFR_SA1_NMIFL 4
`define CFR_DMA_IRQFL 5
`define CFR_TMR_IRQFL 6
`define CFR_SA1_IRQFL 7

`define DCNT_SRC      1:0

assign sw46 = BMAP_r[`BMAP_SW46];
assign cbm  = BMAP_r[`BMAP_CBM];
assign bbf  = BBF_r[`BBF_BBF];

always @(*) begin
  xxb[0] = CXB_r[`CXB_CB];
  xxb[1] = DXB_r[`DXB_DB];
  xxb[2] = EXB_r[`EXB_EB];
  xxb[3] = FXB_r[`FXB_FB];
end
assign xxb_en = {FXB_r[`FXB_FBMODE], EXB_r[`EXB_EBMODE], DXB_r[`DXB_DBMODE], CXB_r[`CXB_CBMODE]};

//-------------------------------------------------------------------
// PIPELINE IO
//-------------------------------------------------------------------
// mmc interface
reg        exe_mmc_rd_r; initial exe_mmc_rd_r = 0;
reg        exe_mmc_wr_r; initial exe_mmc_wr_r = 0;
reg        exe_mmc_dpe_r; initial exe_mmc_dpe_r = 0;
reg [1:0]  exe_mmc_byte_total_r; initial exe_mmc_byte_total_r = 0;
reg        exe_mmc_long_r; initial exe_mmc_long_r = 0;
reg [31:0] exe_mmc_data_r;

reg        dma_mmc_rd_rom_r;  initial dma_mmc_rd_rom_r  = 0;
reg        dma_mmc_rd_bram_r; initial dma_mmc_rd_bram_r = 0;
reg        dma_mmc_wr_bram_r; initial dma_mmc_wr_bram_r = 0;
reg        dma_mmc_rd_iram_r; initial dma_mmc_rd_iram_r = 0;
reg        dma_mmc_wr_iram_r; initial dma_mmc_wr_iram_r = 0;

reg [23:0] dma_mmc_rd_addr_r;
reg [23:0] dma_mmc_wr_addr_r;
reg [7:0]  dma_mmc_data_r;

reg        vbd_mmc_rd_r; initial vbd_mmc_rd_r = 0;
reg [23:0] vbd_mmc_addr_r;

//-------------------------------------------------------------------
// REGISTER/MMIO ACCESS
//-------------------------------------------------------------------
reg        snes_data_enable_r; initial snes_data_enable_r = 0;
reg [7:0]  data_out_r;
reg [7:0]  snes_data_out_r; initial snes_data_out_r = 0;

reg [10:0] snes_iram_addr_r;

reg        snes_writebuf_val_r; initial snes_writebuf_val_r = 0;
reg        snes_writebuf_iram_r; initial snes_writebuf_iram_r = 0;
reg [10:0] snes_writebuf_addr_r;
reg [7:0]  snes_writebuf_data_r;
reg [7:0]  snes_writebuf_iram_data_r;

reg        snes_mmio_active_r; initial snes_mmio_active_r = 0;
reg        snes_iram_active_r; initial snes_iram_active_r = 0;

reg        snes_readbuf_val_r; initial snes_readbuf_val_r = 0;
reg        snes_readbuf_iram_r; initial snes_readbuf_iram_r = 0;
reg [8:0]  snes_readbuf_mmio_addr_r;
reg        snes_mmio_done_r; initial snes_mmio_done_r = 0;

wire [7:0] snes_iram_out;
reg  [7:0] snes_iram_data_r;

reg [1:0]  snes_mmio_delay_r; initial snes_mmio_delay_r = 0;

reg        sa1_readbuf_val_r; initial sa1_readbuf_val_r = 0;

wire [8:0] sa1_mmio_addr;
wire [7:0] sa1_mmio_data;
wire       sa1_mmio_write;
wire       sa1_mmio_read;
reg  [1:0] sa1_mmio_read_r; initial sa1_mmio_read_r = 0;

wire       dma_mmc_cc1_en;
wire [6:0] dma_mmc_cc1_mask;

always @(posedge CLK) begin
  // iram sees the address early so data is available.
  // TODO: can this be single bit now?
// XXX  if (~SNES_READ) snes_data_out_r <= snes_iram_active_r ? snes_iram_out : data_out_r;
// XXX  if (snes_iram_active_r) snes_data_out_r <= snes_iram_out;
// XXX  if (~snes_mmio_delay_r[1] & ~snes_mmio_done_r) snes_data_out_r <= snes_readbuf_iram_r ? snes_iram_data_r : data_out_r;
  if (~snes_mmio_delay_r[1] & ~snes_mmio_done_r) snes_data_out_r <= snes_readbuf_iram_r ? snes_iram_out : data_out_r;

  if (RST) begin
    snes_data_enable_r <= 0;
    data_out_r <= 0;

    snes_writebuf_val_r <= 0;
    snes_writebuf_iram_r <= 0;
    snes_readbuf_val_r <= 0;
    snes_readbuf_iram_r <= 0;

    snes_mmio_active_r <= 0;
    snes_iram_active_r <= 0;

    snes_mmio_delay_r <= 0;
    snes_mmio_done_r <= 0;

    sa1_readbuf_val_r <= 0;
    sa1_mmio_read_r <= 0;

    // initialize registers on cart reset
    CCNT_r <= 8'h20;
    SIE_r  <= 0;
    SIC_r  <= 0;
    CRV_r  <= 0;
    CNV_r  <= 0;
    CIV_r  <= 0;
    SCNT_r <= 0;
    CIE_r  <= 0;
    CIC_r  <= 0;
    SNV_r  <= 0;
    SIV_r  <= 0;
    TMC_r  <= 0;
    CTR_r  <= 0;
    //HCNT_r <= 0;
    //VCNT_r <= 0;
    CXB_r  <= 0;
    DXB_r  <= 1;
    EXB_r  <= 2;
    FXB_r  <= 3;
    BMAPS_r<= 0;
    BMAP_r <= 0;
    SWBE_r <= 0;
    CWBE_r <= 0;
    BWPA_r <= 8'hFF;
    SIWP_r <= 0;
    CIWP_r <= 0;
    DCNT_r <= 0;
    CDMA_r <= 0;
    DSA_r  <= 0;
    //DDA_r  <= 0;
    DTC_r  <= 0;
    BBF_r  <= 0;
    //for (i = 0; i < 16; i = i + 1) BRF_r[i] <= 0;
    MCNT_r <= 0;
    MA_r   <= 0;
    MB_r   <= 0;
    VBD_r  <= 0;
    //VDA_r  <= 0;

    // DMA bit handled by DMA state machine
    {SFR_r[7:6],SFR_r[4:0]} <= 0;
    {CFR_r[7:6],CFR_r[4:0]} <= 0;
    HCR_r  <= 0;
    VCR_r  <= 0;
    //MR_r   <= 0;
    //OF_r   <= 0;
    //VDP_r  <= 0;
    //VC_r   <= 0;
  end
  else begin
    sa1_mmio_read_r <= {sa1_mmio_read_r[0], sa1_mmio_read};
    snes_mmio_delay_r[1:0] <= {snes_mmio_delay_r[0],snes_readbuf_val_r|snes_readbuf_iram_r};

    snes_mmio_active_r <= `IS_MMIO(addr_in_r);
    snes_iram_active_r <= `IS_CPU_IRAM(addr_in_r) | (`IS_CPU_BRAM(addr_in_r) & dma_mmc_cc1_en);

    // Register Read
    if (~SNES_READ & snes_mmio_active_r & ~snes_mmio_done_r) begin
      snes_readbuf_val_r  <= 1;
      snes_readbuf_mmio_addr_r <= addr_in_r[8:0];
      snes_mmio_done_r <= snes_mmio_delay_r[0];

      sa1_readbuf_val_r   <= 0;
    end
    else begin
      snes_readbuf_val_r <= 0;
      sa1_readbuf_val_r  <= sa1_mmio_read;

      if (SNES_READ) snes_mmio_done_r <= 0;

      snes_readbuf_mmio_addr_r <= sa1_mmio_addr;
    end

    // "0" SNES_READ_IN
    // 1   SNES_READ[0]
    // 2   SNES_READ[1] -> ~SNES_READ
    // 3   snes_readbuf_iram_r/addr
    // 4   iram performs read
    // 5   iram_out
    // 6   snes_data_out_r
    if (~SNES_READ & snes_iram_active_r) begin
      snes_readbuf_iram_r <= 1;
    end
    else begin
      snes_readbuf_iram_r <= 0;
    end

    // set both data and oe enable here
    snes_data_enable_r <= (snes_iram_active_r & ~SNES_READ) | ((snes_iram_active_r | snes_mmio_active_r) & ~SNES_WRITE) | snes_mmio_delay_r[1] | snes_mmio_done_r;
// XXX    snes_data_enable_r <= ((snes_iram_active | snes_mmio_active_r) & (~SNES_WRITE | ~SNES_READ));
// XXX    snes_data_enable_r <= ((snes_iram_active_r | snes_mmio_active_r) & ~SNES_WRITE) | snes_mmio_delay_r[1] | snes_mmio_done_r;
    // get address as early as possible so the read data is available when SNES_READ asserts
    snes_iram_addr_r <= (`IS_CPU_BRAM(addr_in_r) & dma_mmc_cc1_en) ? {DDA_r[10:7],(DDA_r[6:0] & ~dma_mmc_cc1_mask) | (addr_in_r[6:0] & dma_mmc_cc1_mask)} : addr_in_r[10:0];

    if (snes_readbuf_val_r | sa1_readbuf_val_r) begin
      case (snes_readbuf_mmio_addr_r[8:0])
        ADDR_SFR  : data_out_r <= {SFR_r[`SFR_CPU_IRQFL], SCNT_r[`SCNT_IVSW],    SFR_r[`SFR_DMA_IRQFL], SCNT_r[`SCNT_NVSW],    SCNT_r[`SCNT_CMEG]};
        ADDR_CFR  : data_out_r <= {CFR_r[`CFR_SA1_IRQFL], CFR_r[`CFR_TMR_IRQFL], CFR_r[`CFR_DMA_IRQFL], CFR_r[`CFR_SA1_NMIFL], CCNT_r[`CCNT_SMEG]};
        //ADDR_HCR  : if (~data_enable_r) begin data_out_r <= hcounter_r[9:2]; HCR_r <= {2'h0,hcounter_r[15:2]}; VCR_r <= vcounter_r; end
        //ADDR_HCR+1: data_out_r <= HCR_r[15:8];
        //ADDR_VCR  : data_out_r <= VCR_r[7:0];
        //ADDR_VCR+1: data_out_r <= VCR_r[15:8];
        ADDR_MR   : data_out_r <= MR_r[7:0];
        ADDR_MR+1 : data_out_r <= MR_r[15:8];
        ADDR_MR+2 : data_out_r <= MR_r[23:16];
        ADDR_MR+3 : data_out_r <= MR_r[31:24];
        ADDR_MR+4 : data_out_r <= MR_r[39:32];
        ADDR_OF   : data_out_r <= OF_r;
        ADDR_VDP  : data_out_r <= VDP_r[7:0];
        ADDR_VDP+1: data_out_r <= VDP_r[15:8];
        ADDR_VC   : data_out_r <= VC_r;
      endcase
    end

    if (snes_readbuf_iram_r) begin
      snes_iram_data_r <= snes_iram_out;
    end

    // Register Write Buffer.
    if (SNES_WR_end & snes_mmio_active_r) begin
      snes_writebuf_val_r  <= 1;
      snes_writebuf_addr_r <= {2'h0,addr_in_r[8:0]};
      snes_writebuf_data_r <= data_in_r;
    end
    else begin
      snes_writebuf_val_r       <= sa1_mmio_write;

      snes_writebuf_addr_r      <= {2'h0,sa1_mmio_addr};
      snes_writebuf_data_r      <= sa1_mmio_data;
    end

    if (SNES_WR_end & `IS_CPU_IRAM(addr_in_r)) begin
      snes_writebuf_iram_r <= 1;
      snes_writebuf_iram_data_r <= data_in_r;
    end
    else begin
      snes_writebuf_iram_r <= 0;
    end

    // TODO: can we move the interrupt controller logic outside of the MMIO operations to reduce code size and complexity?
    if (snes_writebuf_val_r) begin
      case (snes_writebuf_addr_r[8:0])
        ADDR_CCNT  : begin  // 8'h00,
          CCNT_r <= snes_writebuf_data_r;

          if (snes_writebuf_data_r[`CCNT_SA1_IRQ]) begin
            CFR_r[`CFR_SA1_IRQFL] <= 1;
            if (CIE_r[`CIE_SA1_IRQEN]) CIC_r[`CIC_SA1_IRQCL] <= 0;
          end

          if (snes_writebuf_data_r[`CCNT_SA1_NMI]) begin
            CFR_r[`CFR_SA1_NMIFL] <= 1;
            if (CIE_r[`CIE_SA1_NMIEN]) CIC_r[`CIC_SA1_NMICL] <= 0;
          end
        end
        ADDR_SIE   : begin  // 8'h01,
          {SIE_r[`SIE_CPU_IRQEN],SIE_r[`SIE_DMA_IRQEN]} <= {snes_writebuf_data_r[`SIE_CPU_IRQEN],snes_writebuf_data_r[`SIE_DMA_IRQEN]};

          if (~SIE_r[`SIE_CPU_IRQEN] & snes_writebuf_data_r[`SIE_CPU_IRQEN] & SFR_r[`SFR_CPU_IRQFL]) begin
            SIC_r[`SIC_CPU_IRQCL] <= 0;
          end

          if (~SIE_r[`SIE_DMA_IRQEN] & snes_writebuf_data_r[`SIE_DMA_IRQEN] & SFR_r[`SFR_DMA_IRQFL]) begin
            SIC_r[`SIC_DMA_IRQCL] <= 0;
          end
        end
        ADDR_SIC   : begin  // 8'h02,
          {SIC_r[`SIC_CPU_IRQCL],SIC_r[`SIC_DMA_IRQCL]} <= {snes_writebuf_data_r[`SIC_CPU_IRQCL],snes_writebuf_data_r[`SIC_DMA_IRQCL]};

          //if (snes_writebuf_data_r[`SIC_DMA_IRQCL]) SFR_r[`SFR_DMA_IRQFL] <= 0;
          if (snes_writebuf_data_r[`SIC_CPU_IRQCL]) SFR_r[`SFR_CPU_IRQFL] <= 0;
        end
        ADDR_CRV   : CRV_r[7:0]  <= snes_writebuf_data_r;  // 8'h03, // $2
        ADDR_CRV+1 : CRV_r[15:8] <= snes_writebuf_data_r;  // 8'h03, // $2
        ADDR_CNV   : CNV_r[7:0]  <= snes_writebuf_data_r;  // 8'h05, // $2
        ADDR_CNV+1 : CNV_r[15:8] <= snes_writebuf_data_r;  // 8'h05, // $2
        ADDR_CIV   : CIV_r[7:0]  <= snes_writebuf_data_r;  // 8'h07, // $2
        ADDR_CIV+1 : CIV_r[15:8] <= snes_writebuf_data_r;  // 8'h07, // $2
        ADDR_SCNT  : begin  // 8'h09,
          {SCNT_r[7:6],SCNT_r[4:0]} <= {snes_writebuf_data_r[7:6],snes_writebuf_data_r[4:0]};

          if (snes_writebuf_data_r[`SCNT_CPU_IRQ]) begin
            SFR_r[`SFR_CPU_IRQFL] <= 1;
            if (SIE_r[`SIE_CPU_IRQEN]) begin
              SIC_r[`SIC_CPU_IRQCL] <= 0;
            end
          end
        end
        ADDR_CIE   : begin  // 8'h0A,
          CIE_r[7:4] <= snes_writebuf_data_r[7:4];

          if (~CIE_r[`CIE_SA1_IRQEN] & snes_writebuf_data_r[`CIE_SA1_IRQEN] & CFR_r[`CFR_SA1_IRQFL]) CIC_r[`CIC_SA1_IRQCL] <= 0;
          if (~CIE_r[`CIE_TMR_IRQEN] & snes_writebuf_data_r[`CIE_TMR_IRQEN] & CFR_r[`CFR_TMR_IRQFL]) CIC_r[`CIC_TMR_IRQCL] <= 0;
          if (~CIE_r[`CIE_DMA_IRQEN] & snes_writebuf_data_r[`CIE_DMA_IRQEN] & CFR_r[`CFR_DMA_IRQFL]) CIC_r[`CIC_DMA_IRQCL] <= 0;
          if (~CIE_r[`CIE_SA1_NMIEN] & snes_writebuf_data_r[`CIE_SA1_NMIEN] & CFR_r[`CFR_SA1_NMIFL]) CIC_r[`CIC_SA1_NMICL] <= 0;
        end
        ADDR_CIC   : begin  // 8'h0B,
          CIC_r[7:4] <= snes_writebuf_data_r[7:4];

          if (snes_writebuf_data_r[`CIC_SA1_IRQCL]) CFR_r[`CFR_SA1_IRQFL] <= 0;
          if (snes_writebuf_data_r[`CIC_TMR_IRQCL]) CFR_r[`CFR_TMR_IRQFL] <= 0;
          //if (snes_writebuf_data_r[`CIC_DMA_IRQCL]) CFR_r[`CFR_DMA_IRQFL] <= 0;
          if (snes_writebuf_data_r[`CIC_SA1_NMICL]) CFR_r[`CFR_SA1_NMIFL] <= 0;
        end
        ADDR_SNV   : SNV_r[7:0]          <= snes_writebuf_data_r;  // 8'h0C, // $2
        ADDR_SNV+1 : SNV_r[15:8]         <= snes_writebuf_data_r;  // 8'h0C, // $2
        ADDR_SIV   : SIV_r[7:0]          <= snes_writebuf_data_r;  // 8'h0E, // $2
        ADDR_SIV+1 : SIV_r[15:8]         <= snes_writebuf_data_r;  // 8'h0E, // $2
        ADDR_TMC   : {TMC_r[`TMC_HVSELB],TMC_r[`TMC_VEN],TMC_r[`TMC_HEN]} <= {snes_writebuf_data_r[`TMC_HVSELB],snes_writebuf_data_r[`TMC_VEN],snes_writebuf_data_r[`TMC_HEN]};  // 8'h10,
        //ADDR_CTR   : // TODO: reset counters.  Probably needs to be moved outside of this code  // 8'h11,
        //ADDR_HCNT  : HCNT_r[7:0]         <= snes_writebuf_data_r;  // 8'h12, // $2
        //ADDR_HCNT+1: HCNT_r[15:8]        <= snes_writebuf_data_r;  // 8'h12, // $2
        //ADDR_VCNT  : VCNT_r[7:0]         <= snes_writebuf_data_r;  // 8'h14, // $2
        //ADDR_VCNT+1: VCNT_r[15:8]        <= snes_writebuf_data_r;  // 8'h14, // $2
        ADDR_CXB   : {CXB_r[`CXB_CBMODE],CXB_r[`CXB_CB]} <= {snes_writebuf_data_r[`CXB_CBMODE],snes_writebuf_data_r[`CXB_CB]};  // 8'h20,
        ADDR_DXB   : {DXB_r[`DXB_DBMODE],DXB_r[`DXB_DB]} <= {snes_writebuf_data_r[`DXB_DBMODE],snes_writebuf_data_r[`DXB_DB]};  // 8'h21,
        ADDR_EXB   : {EXB_r[`EXB_EBMODE],EXB_r[`EXB_EB]} <= {snes_writebuf_data_r[`EXB_EBMODE],snes_writebuf_data_r[`EXB_EB]};  // 8'h22,
        ADDR_FXB   : {FXB_r[`FXB_FBMODE],FXB_r[`FXB_FB]} <= {snes_writebuf_data_r[`FXB_FBMODE],snes_writebuf_data_r[`FXB_FB]};  // 8'h23,
        ADDR_BMAPS : BMAPS_r[`BMAPS_SBM] <= snes_writebuf_data_r[`BMAPS_SBM];  // 8'h24,
        ADDR_BMAP  : BMAP_r              <= snes_writebuf_data_r;  // 8'h25,
        ADDR_SWBE  : SWBE_r[`SWBE_SWEN]  <= snes_writebuf_data_r[`SWBE_SWEN];  // 8'h26,
        ADDR_CWBE  : CWBE_r[`CWBE_CWEN]  <= snes_writebuf_data_r[`CWBE_CWEN];  // 8'h27,
        ADDR_BWPA  : BWPA_r[`BWPA_BWP]   <= snes_writebuf_data_r[`BWPA_BWP];  // 8'h28,
        ADDR_SIWP  : SIWP_r              <= snes_writebuf_data_r;  // 8'h29,
        ADDR_CIWP  : CIWP_r              <= snes_writebuf_data_r;  // 8'h2A,
        ADDR_DCNT  : {DCNT_r[7:4],DCNT_r[2:0]} <= {snes_writebuf_data_r[7:4],snes_writebuf_data_r[2:0]};  // 8'h30,
        ADDR_CDMA  : {CDMA_r[`CDMA_CHDEND],CDMA_r[`CDMA_DMASIZE],CDMA_r[`CDMA_DMACB]} <= {snes_writebuf_data_r[`CDMA_CHDEND],snes_writebuf_data_r[`CDMA_DMASIZE],snes_writebuf_data_r[`CDMA_DMACB]};  // 8'h31,
        ADDR_DSA   : DSA_r[7:0]          <= snes_writebuf_data_r;  // 8'h32, // $3
        ADDR_DSA+1 : DSA_r[15:8]         <= snes_writebuf_data_r;  // 8'h32, // $3
        ADDR_DSA+2 : DSA_r[23:16]        <= snes_writebuf_data_r;  // 8'h32, // $3
        ADDR_DDA   : DDA_r[7:0]          <= snes_writebuf_data_r;  // 8'h35, // $3
        ADDR_DDA+1 : DDA_r[15:8]         <= snes_writebuf_data_r;  // 8'h35, // $3
        ADDR_DDA+2 : DDA_r[23:16]        <= snes_writebuf_data_r;  // 8'h35, // $3
        ADDR_DTC   : DTC_r[7:0]          <= snes_writebuf_data_r;  // 8'h38, // $2
        ADDR_DTC+1 : DTC_r[15:8]         <= snes_writebuf_data_r;  // 8'h38, // $2
        ADDR_BBF   : BBF_r[`BBF_BBF]     <= snes_writebuf_data_r[`BBF_BBF];  // 8'h3F,
        ADDR_BRF+0 : BRF_r[0][7:0]       <= snes_writebuf_data_r;  // 8'h40,
        ADDR_BRF+1 : BRF_r[1][7:0]       <= snes_writebuf_data_r;  // 8'h41,
        ADDR_BRF+2 : BRF_r[2][7:0]       <= snes_writebuf_data_r;  // 8'h42,
        ADDR_BRF+3 : BRF_r[3][7:0]       <= snes_writebuf_data_r;  // 8'h43,
        ADDR_BRF+4 : BRF_r[4][7:0]       <= snes_writebuf_data_r;  // 8'h44,
        ADDR_BRF+5 : BRF_r[5][7:0]       <= snes_writebuf_data_r;  // 8'h45,
        ADDR_BRF+6 : BRF_r[6][7:0]       <= snes_writebuf_data_r;  // 8'h46,
        ADDR_BRF+7 : BRF_r[7][7:0]       <= snes_writebuf_data_r;  // 8'h47,
        ADDR_BRF+8 : BRF_r[8][7:0]       <= snes_writebuf_data_r;  // 8'h48,
        ADDR_BRF+9 : BRF_r[9][7:0]       <= snes_writebuf_data_r;  // 8'h49,
        ADDR_BRF+10: BRF_r[10][7:0]      <= snes_writebuf_data_r;  // 8'h4A,
        ADDR_BRF+11: BRF_r[11][7:0]      <= snes_writebuf_data_r;  // 8'h4B,
        ADDR_BRF+12: BRF_r[12][7:0]      <= snes_writebuf_data_r;  // 8'h4C,
        ADDR_BRF+13: BRF_r[13][7:0]      <= snes_writebuf_data_r;  // 8'h4D,
        ADDR_BRF+14: BRF_r[14][7:0]      <= snes_writebuf_data_r;  // 8'h4E,
        ADDR_BRF+15: BRF_r[15][7:0]      <= snes_writebuf_data_r;  // 8'h4F,
        ADDR_MCNT  : {MCNT_r[`MCNT_ACM],MCNT_r[`MCNT_MD]} <= {snes_writebuf_data_r[`MCNT_ACM],snes_writebuf_data_r[`MCNT_MD]}; // 8'h50,
        ADDR_MA    : MA_r[7:0]           <= snes_writebuf_data_r;  // 8'h51, // $2
        ADDR_MA+1  : MA_r[15:8]          <= snes_writebuf_data_r;  // 8'h51, // $2
        ADDR_MB    : MB_r[7:0]           <= snes_writebuf_data_r;  // 8'h53, // $2
        ADDR_MB+1  : begin // 8'h53, // $2
          if (~MCNT_r[`MCNT_ACM] & MCNT_r[`MCNT_MD]) MA_r <= 0;
          MB_r <= 0;
        end
        ADDR_VBD   : {VBD_r[`VBD_HL],VBD_r[`VBD_VB]} <= {snes_writebuf_data_r[`VBD_HL],snes_writebuf_data_r[`VBD_VB]}; // 8'h58,
        default: begin end
      endcase
    end
  end
end

//-------------------------------------------------------------------
// Math
//-------------------------------------------------------------------
wire [31:0] mult_out;
wire [15:0] divq_out;
wire [15:0] divr_out;
wire        div_by_zero;

reg  [1:0]  math_md_r; initial math_md_r = 0;
reg  [15:0] math_ma_r; initial math_ma_r = 0;
reg  [15:0] math_mb_r; initial math_mb_r = 0;

reg         math_val_r;  initial math_val_r = 0;
reg         math_acm_r;  initial math_acm_r = 0;
reg         math_init_r; initial math_init_r = 0;

`ifdef MK2
sa1_mult mult(
  .clk(CLK),
  .a(math_ma_r),
  .b(math_mb_r),
  .p(mult_out)
);

sa1_div div(
  .clk(CLK),
  .dividend(math_ma_r),
  .divisor(math_mb_r),
  .quotient(divq_out),
  .fractional(divr_out)
);
`endif
`ifdef MK3
sa1_mult mult(
  .clock(CLK),
  .dataa(math_ma_r),
  .datab(math_mb_r),
  .result(mult_out)
);

sa1_div div(
  .clock(CLK),
  .numer(math_ma_r),
  .denom(math_mb_r),
  .quotient(divq_out),
  .remain(divr_out)
);
`endif

reg  [40:0] math_result;

always @(posedge CLK) begin
  if (RST) begin
    math_val_r <= 0;
    math_acm_r <= 0;
    math_init_r <= 0;

    math_md_r <= 0;
    math_ma_r <= 0;
    math_mb_r <= 0;

    MR_r      <= 0;
    OF_r      <= 0;
  end
  else begin
    if (snes_writebuf_val_r) begin
      if (snes_writebuf_addr_r[8:0] == ADDR_MB+1) begin
        if (~math_val_r) begin
          // flop all inputs
          math_md_r <= MCNT_r[1:0];
          math_ma_r <= MA_r;
          math_mb_r <= {snes_writebuf_data_r,MB_r[7:0]};

          math_val_r <= 1;
        end
      end
      else if (snes_writebuf_addr_r[8:0] == ADDR_MCNT) begin
        math_init_r <= snes_writebuf_data_r[`MCNT_ACM];
      end

      // clear in case we get another write
      math_acm_r <= 0;
    end
    else begin
      if (math_val_r) math_acm_r <= 1;
      else            math_acm_r <= 0;

      math_val_r <= 0;
      math_init_r <= 0;
    end

    if      (math_init_r) begin
      MR_r <= 0;
    end
    // if we switch to ACM we need to avoid other math immediately
    else if (MCNT_r[`MCNT_ACM]) begin
      if (math_acm_r) begin
        math_result[40:0] = {1'b0,MR_r} + {9'h00,mult_out};
        MR_r <= math_result[39:0];
        // set overflow
        OF_r <= math_result[40];
      end
    end
    // otherwise continue performing operation based on flopped MCNT
    else if (math_md_r[`MCNT_MD]) begin
      MR_r[39:32] <= 0;
      MR_r[31:0] <= |math_mb_r ? {divr_out,divq_out} : 0;
    end
    else begin
      MR_r[39:32] <= 0;
      MR_r[31:0] <= mult_out;
    end
  end
end

//-------------------------------------------------------------------
// COMMON EXE STATE
//-------------------------------------------------------------------
`define GRP_PRI     0
`define GRP_RMW     1
`define GRP_CBR     2
`define GRP_JMP     3
`define GRP_PHS     4
`define GRP_PLL     5
`define GRP_CMP     6
`define GRP_STS     7
`define GRP_MOV     8
`define GRP_TXR     9
`define GRP_SPC     10
`define GRP_SMP     11
`define GRP_STK     12
`define GRP_XCH     13
`define GRP_TST     14

`define ADD_O16     0
`define ADD_DPR     1
`define ADD_PCR     2
`define ADD_SPL     3
`define ADD_SMI     4
`define ADD_SPR     5

`define BNK_PBR     0
`define BNK_DBR     1
`define BNK_ZRO     2
`define BNK_O24     3

`define MOD_X16     0
`define MOD_Y16     1
`define MOD_YPT     2
`define MOD_INV     3

`define ADD_STK     31:31
`define ADD_LNG     30:30
`define ADD_IND     29:29
`define ADD_IMM     28:28
`define ADD_MOD     27:26
`define ADD_ADD     25:23
`define ADD_BNK     22:21
`define DEC_GROUP   20:17
`define DEC_SIZE    16:15
`define DEC_LATENCY 14:11
`define DEC_PRC     10:9
`define DEC_SRC      8:6
`define DEC_DST      5:3
`define DEC_LOAD     2:2
`define DEC_STORE    1:1
`define DEC_CONTROL  0:0

`define PRC_B        0
`define PRC_M        1
`define PRC_X        2
`define PRC_W        3

`define REG_Z        0
`define REG_A        1
`define REG_X        2
`define REG_Y        3
`define REG_S        4
`define REG_D        5
`define REG_B        6
`define REG_P        7

`define SZE_1        0
`define SZE_2        1
`define SZE_3        2
`define SZE_4        3

parameter
  ST_EXE_IDLE        = 8'b00000001,
  ST_EXE_FETCH       = 8'b00000010,
  ST_EXE_FETCH_END   = 8'b00000100,
  ST_EXE_ADDRESS     = 8'b00001000,
  ST_EXE_ADDRESS_END = 8'b00010000,
  ST_EXE_EXECUTE     = 8'b00100000,
  ST_EXE_EXECUTE_END = 8'b01000000,
  ST_EXE_WAIT        = 8'b10000000,
  ST_EXE_ALL         = 8'b11111111;

reg [7:0]  EXE_STATE; initial EXE_STATE = ST_EXE_IDLE;
reg [23:0] exe_fetch_addr_r; initial exe_fetch_addr_r = 0;
reg [31:0] exe_decode_r; initial exe_decode_r = 0;

wire       exe_dec_add_stk  = exe_decode_r[`ADD_STK];
wire       exe_dec_add_imm  = exe_decode_r[`ADD_IMM];
wire [1:0] exe_dec_add_bank = exe_decode_r[`ADD_BNK];
wire [2:0] exe_dec_add_base = exe_decode_r[`ADD_ADD];
wire [1:0] exe_dec_add_mod  = exe_decode_r[`ADD_MOD];
wire       exe_dec_add_indirect = exe_decode_r[`ADD_IND];
wire       exe_dec_add_long = exe_decode_r[`ADD_LNG];
wire [3:0] exe_dec_grp      = exe_decode_r[`DEC_GROUP];
//wire [6:0] exe_dec_inst  = exe_decode_r[`DEC_OPCODE];
wire [1:0] exe_dec_size  = exe_decode_r[`DEC_SIZE];
wire [3:0] exe_dec_lat   = exe_decode_r[`DEC_LATENCY];
wire [1:0] exe_dec_prc   = exe_decode_r[`DEC_PRC];
wire [2:0] exe_dec_src   = exe_decode_r[`DEC_SRC];
wire [2:0] exe_dec_dst   = exe_decode_r[`DEC_DST];
wire       exe_dec_load  = exe_decode_r[`DEC_LOAD];
wire       exe_dec_store = exe_decode_r[`DEC_STORE];
wire       exe_dec_ctl   = exe_decode_r[`DEC_CONTROL];

wire       exe_wai;
wire       exe_mmc_int;

wire       exe_fetch_byte_val;
wire       exe_fetch_move;
wire [7:0] exe_fetch_byte;
wire [7:0] exe_fetch_data;

//-------------------------------------------------------------------
// COMMON PIPELINE
//-------------------------------------------------------------------
reg [3:0] exe_waitcnt_r; initial exe_waitcnt_r = 0;
reg [3:0] e2c_waitcnt_r; initial e2c_waitcnt_r = 0;

always @(posedge CLK) begin
  if (RST) begin
    exe_waitcnt_r <= 0;

    step_r <= 0;
  end
  else begin
    if (sa1_clock_en & |exe_waitcnt_r) exe_waitcnt_r <= exe_waitcnt_r + e2c_waitcnt_r - 1;
    else                               exe_waitcnt_r <= exe_waitcnt_r + e2c_waitcnt_r;

    // ok to advance to next instruction byte
    step_r <= CONFIG_CONTROL_ENABLED || (stepcnt_r != CONFIG_STEP_COUNT);

    if (pipeline_advance) stepcnt_r <= CONFIG_STEP_COUNT;
  end
end

//-------------------------------------------------------------------
// IRAM
//-------------------------------------------------------------------
wire         iram_wren;
wire [10:0]  iram_addr;
wire [7:0]   iram_din;
wire [7:0]   iram_dout;

// TDP macro simplifies abritration between the snes and sa1.  Also use
// spare cycles for debug reads.
wire         snes_iram_wren = snes_writebuf_iram_r;
`ifdef DEBUG
wire [10:0]  snes_iram_addr = snes_iram_active_r ? snes_iram_addr_r : pgm_addr_r[10:0];
`else
wire [10:0]  snes_iram_addr = snes_iram_addr_r;
`endif
wire [7:0]   snes_iram_din  = snes_writebuf_iram_data_r;
wire [7:0]   snes_iram_dout;

`ifdef MK2
sa1_iram iram (
  .clka(CLK), // input clka
  .wea(iram_wren), // input [0 : 0] wea
  .addra(iram_addr), // input [10 : 0] addra
  .dina(iram_din), // input [7 : 0] dina
  .douta(iram_dout), // output [7 : 0] douta

  .clkb(CLK), // input clkb
  .web(snes_iram_wren), // input [0 : 0] web
  .addrb(snes_iram_addr), // input [10 : 0] addrb
  .dinb(snes_iram_din), // input [7 : 0] dinb
  .doutb(snes_iram_dout) // output [7 : 0] doutb
);
`endif
`ifdef MK3
sa1_iram iram (
  .clock(CLK), // input clka
  .wren_a(iram_wren), // input [0 : 0] wea
  .address_a(iram_addr), // input [10 : 0] addra
  .data_a(iram_din), // input [7 : 0] dina
  .q_a(iram_dout), // output [7 : 0] douta

  .wren_b(snes_iram_wren), // input [0 : 0] web
  .address_b(snes_iram_addr), // input [10 : 0] addrb
  .data_b(snes_iram_din), // input [7 : 0] dinb
  .q_b(snes_iram_dout) // output [7 : 0] doutb
);
`endif

assign snes_iram_out = snes_iram_dout;

//-------------------------------------------------------------------
// MMC PIPELINE
//-------------------------------------------------------------------
// Unified memory access.  All requests are serialized and allowed
// to access as fast as the associated pipeline supports.  This covers
// the following:
//  sources: sa1, dma, vdp (TBD may be moved to main.v)
//  targets: rom, bram, iram, mmio
//
// The unified state machine supports: single MDR, consolidated address map logic,
// priority scheduling.
//
// It's not clear whether there is a store buffer in the sa1 to overlap post store commit with
// instruction fetch (likely to rom) and other operations.
// To simplify the design don't support a store buffer unless we need the performance.
// The MDR and priority gets more complicated if we need to do parallel accesses to the different
// targets.  NOTE: The ready check blocks all operations.  The pipe is strictly in-order.

wire [31:0] exe_mmc_rddata;
wire [31:0] dma_mmc_rddata;

reg [7:0]  MDR_r;  initial MDR_r  = 0;

// rom
reg rom_bus_rrq_r; initial rom_bus_rrq_r = 0;
reg [23:0] rom_bus_addr_r;
reg        rom_bus_word_r;

// bram
reg ram_bus_rrq_r; initial ram_bus_rrq_r = 0;
reg ram_bus_wrq_r; initial ram_bus_wrq_r = 0;
reg [19:0] ram_bus_addr_r;
reg [7:0]  ram_bus_data_r;

// iram
reg        mmc_iram_state_r;

// mmio
// -

wire [23:0] exe_mmc_addr;

wire        mmc_dma_end;
wire        mmc_exe_end;
reg rom_bus_wrq_r; initial rom_bus_wrq_r = 0;
reg [15:0] rom_bus_data_r;

parameter
  ST_MMC_IDLE      = 8'b00000001,
  ST_MMC_ROM       = 8'b00000010,
  ST_MMC_IRAM      = 8'b00000100,
  ST_MMC_MMIO      = 8'b00001000,
  ST_MMC_INV       = 8'b00010000,
  ST_MMC_EXE_END   = 8'b00100000,
  ST_MMC_DMA_END   = 8'b01000000,
  ST_MMC_VBD_END   = 8'b10000000,
  ST_MMC_ALL       = 8'b11111111;

reg [7:0]  MMC_STATE; initial MMC_STATE = ST_MMC_IDLE;
reg [7:0]  mmc_state_end_r;

reg [23:0] mmc_addr_r;
reg [31:0] mmc_data_r; initial mmc_data_r = 0;
reg [31:0] mmc_wrdata_r; initial mmc_wrdata_r = 0;
reg        mmc_wr_r; initial mmc_wr_r = 0;
reg        mmc_dpe_r; initial mmc_dpe_r = 0;
reg [1:0]  mmc_byte_r; initial mmc_byte_r = 0;
reg [1:0]  mmc_byte_total_r; initial mmc_byte_total_r = 0;
reg        mmc_long_r; initial mmc_long_r = 0;
reg        mmc_rom_misaligned; initial mmc_rom_misaligned = 0;

always @(posedge CLK) begin
  if (RST) begin
    MMC_STATE <= ST_MMC_IDLE;
    MDR_r <= 0;
    mmc_long_r <= 0;

    rom_bus_rrq_r <= 0;
    rom_bus_wrq_r <= 0; // unused but good to init
  end
  else begin
    case (MMC_STATE)
      ST_MMC_IDLE: begin
        // priority
        // - vdp
        // - dma (high pri)
        // - exe
        // - dma (low pri)
        mmc_byte_r <= 0;

`ifdef VBD_ENABLE
        if (vbd_mmc_rd_r) begin
          mmc_byte_total_r   <= 3;
          mmc_dpe_r          <= 0;
          mmc_wr_r           <= 0;
          mmc_long_r         <= 0;

          rom_bus_rrq_r      <= 1;
          rom_bus_addr_r     <= `MAP_ROM(vbd_mmc_addr_r);
          rom_bus_word_r     <= 1;

          // TODO: ok to force aligned access?
          mmc_rom_misaligned <= 0;

          MMC_STATE          <= ST_MMC_ROM;

          mmc_state_end_r    <= ST_MMC_VBD_END;
        end
        else
`endif
        if (dma_mmc_rd_rom_r | dma_mmc_rd_iram_r | dma_mmc_wr_iram_r) begin
          mmc_byte_total_r<= 0;
          mmc_dpe_r       <= 0;
          mmc_wr_r        <= dma_mmc_wr_iram_r;
          mmc_long_r      <= 0;
          mmc_wrdata_r[7:0] <= dma_mmc_data_r;

          // NOTE: could move this decode to DMA
          if      (dma_mmc_rd_rom_r/* & ROM_BUS_RDY*/) begin
            rom_bus_rrq_r  <= 1;
            rom_bus_addr_r <= `MAP_ROM(dma_mmc_rd_addr_r);
            rom_bus_word_r <= 1;
            //mmc_addr_r     <= `MAP_ROM(dma_mmc_addr_r);
            mmc_rom_misaligned <= dma_mmc_rd_addr_r[0];

            MMC_STATE      <= ST_MMC_ROM;
          end
          else if (dma_mmc_rd_iram_r | dma_mmc_wr_iram_r) begin
            mmc_iram_state_r <= 0;
            mmc_addr_r     <= `MAP_IRAM(dma_mmc_rd_iram_r ? dma_mmc_rd_addr_r : dma_mmc_wr_addr_r);
            MMC_STATE      <= ST_MMC_IRAM;
          end
          else begin
            MMC_STATE <= ST_MMC_INV;
          end

          mmc_state_end_r <= ST_MMC_DMA_END;
        end
//        // save a cycle in fetch if we are going to rom.
//        else if (EXE_STATE[clog2(ST_EXE_FETCH)] & ~exe_mmc_int & ~exe_fetch_byte_val & ~exe_fetch_move) begin
//          mmc_byte_total_r <= exe_mmc_byte_total_r;
//          mmc_dpe_r <= exe_mmc_dpe_r;
//          mmc_wr_r <= 0;
//          mmc_long_r <= exe_mmc_long_r;
//
//          if (`IS_ROM(exe_fetch_addr_r)/* & ROM_BUS_RDY*/) begin
//            rom_bus_rrq_r <= 1;
//            rom_bus_addr_r <= `MAP_ROM(exe_fetch_addr_r);
//            rom_bus_word_r <= 1;
//            mmc_rom_misaligned <= exe_fetch_addr_r[0];
//
//            MMC_STATE <= ST_MMC_ROM;
//          end
//
//          mmc_state_end_r <= ST_MMC_EXE_END;
//        end
        else if (exe_mmc_rd_r | exe_mmc_wr_r) begin
          mmc_byte_total_r <= exe_mmc_byte_total_r;
          mmc_dpe_r <= exe_mmc_dpe_r;
          mmc_wr_r <= exe_mmc_wr_r;
          mmc_long_r <= exe_mmc_long_r;
          mmc_wrdata_r <= exe_mmc_data_r;

          if (`IS_ROM(exe_mmc_addr)/* & ROM_BUS_RDY*/) begin
            rom_bus_rrq_r  <= ~exe_mmc_wr_r;
            rom_bus_addr_r <= `MAP_ROM(exe_mmc_addr);
            rom_bus_word_r <= 1;
            //mmc_addr_r     <= `MAP_ROM(exe_mmc_addr);
            mmc_rom_misaligned <= exe_mmc_addr[0];

            MMC_STATE <= exe_mmc_wr_r ? ST_MMC_INV : ST_MMC_ROM;
          end
          else if (`IS_SA1_IRAM(exe_mmc_addr)) begin
            // avoid sa1 write to snes read conflict late in the cycle - NOTE: if we do an address compare we won't properly handle collisions on multi-byte operations.
            // TODO: move this to the IRAM cycle, but need to be careful of write enable, state machine, etc state.  The current fix may still miss multibyte operations.
            mmc_iram_state_r <= 0;
            mmc_addr_r    <= `MAP_IRAM(exe_mmc_addr);

            MMC_STATE <= ST_MMC_IRAM;
          end
          else if (`IS_MMIO(exe_mmc_addr)) begin
            mmc_addr_r    <= `MAP_MMIO(exe_mmc_addr);
            MMC_STATE <= ST_MMC_MMIO;
          end
          else if (~`IS_SA1_BRAM(exe_mmc_addr) & ~`IS_SA1_PRAM(exe_mmc_addr)) begin
            MMC_STATE <= ST_MMC_INV;
          end

          mmc_state_end_r <= ST_MMC_EXE_END;
        end
      end
      ST_MMC_ROM: begin
        rom_bus_rrq_r <= 0;

        if (~rom_bus_rrq_r & ROM_BUS_RDY) begin
          mmc_byte_r <= mmc_byte_r + (mmc_rom_misaligned ? 1 : 2);

          // only the first request may be misaligned
          mmc_rom_misaligned <= 0;

          case (mmc_byte_r)
            0: mmc_data_r[15: 0] <= ROM_BUS_RDDATA[15:0];
            1: mmc_data_r[23: 8] <= ROM_BUS_RDDATA[15:0];
            2: mmc_data_r[31:16] <= ROM_BUS_RDDATA[15:0];
            3: mmc_data_r[31:24] <= ROM_BUS_RDDATA[7:0];
          endcase

          // TODO: doesn't work if we want 4 bytes back and misaligned
          // TODO: fetch already handles misaligned.  don't need both.
          if ((mmc_rom_misaligned & mmc_byte_total_r[0]) | (~|mmc_byte_r & mmc_byte_total_r[1])) begin
            rom_bus_rrq_r <= 1;

            if      (mmc_dpe_r)  rom_bus_addr_r[7:0]  <= {rom_bus_addr_r[7:1]  + 1, 1'b0};
            //else if (mmc_long_r) rom_bus_addr_r[23:0] <= {rom_bus_addr_r[23:1] + 1, 1'b0};
            //else                 rom_bus_addr_r[15:0] <= {rom_bus_addr_r[15:1] + 1, 1'b0};
            else                 rom_bus_addr_r[23:0] <= {rom_bus_addr_r[23:1] + 1, 1'b0};
          end
          else begin
            MMC_STATE <= mmc_state_end_r;
          end
        end
      end
      ST_MMC_IRAM: begin
        mmc_iram_state_r <= ~mmc_iram_state_r;

        // writes are pipelined single cycle
        if (mmc_wr_r | mmc_iram_state_r) begin
          mmc_byte_r <= mmc_byte_r + 1;

          case (mmc_byte_r)
            0: mmc_data_r[ 7: 0] <= iram_dout[7:0];
            1: mmc_data_r[15: 8] <= iram_dout[7:0];
            2: mmc_data_r[23:16] <= iram_dout[7:0];
            3: mmc_data_r[31:24] <= iram_dout[7:0];
          endcase

          mmc_wrdata_r <= {mmc_wrdata_r[7:0],mmc_wrdata_r[31:24],mmc_wrdata_r[23:16],mmc_wrdata_r[15:8]};

          if (mmc_byte_r != mmc_byte_total_r) begin
            if (mmc_dpe_r) mmc_addr_r[7:0]  <= mmc_addr_r[7:0] + 1;
            else           mmc_addr_r[10:0] <= mmc_addr_r[10:0] + 1;
          end
          else begin
            MMC_STATE <= mmc_state_end_r;
          end
        end
      end
      ST_MMC_MMIO: begin
        if ((mmc_wr_r & sa1_mmio_write) | (~mmc_wr_r & sa1_mmio_read_r[1])) begin
          mmc_byte_r <= mmc_byte_r + 1;

          case (mmc_byte_r)
            0: mmc_data_r[ 7: 0] <= data_out_r[7:0];
            1: mmc_data_r[15: 8] <= data_out_r[7:0];
            2: mmc_data_r[23:16] <= data_out_r[7:0];
            3: mmc_data_r[31:23] <= data_out_r[7:0];
          endcase

          mmc_wrdata_r <= {mmc_wrdata_r[7:0],mmc_wrdata_r[31:24],mmc_wrdata_r[23:16],mmc_wrdata_r[15:8]};

          if (mmc_byte_r != mmc_byte_total_r) begin
            mmc_addr_r[7:0] <= mmc_addr_r[7:0] + 1;
          end
          else begin
            MMC_STATE <= mmc_state_end_r;
          end
        end
      end
      ST_MMC_INV: begin
        mmc_data_r <= {MDR_r,MDR_r,MDR_r,MDR_r};
        MMC_STATE <= mmc_state_end_r;
      end
   `ifdef VBD_ENABLE
      ST_MMC_VBD_END,
   `endif
      ST_MMC_EXE_END,
      ST_MMC_DMA_END: begin
        MMC_STATE <= ST_MMC_IDLE;
      end
    endcase
  end
end

// bram/pram
// - exe
// - dma
parameter
  ST_MMC_RAM_IDLE = 1'b0,
  ST_MMC_RAM_WAIT = 1'b1;

reg        MMC_RAM_STATE; initial MMC_RAM_STATE = ST_MMC_RAM_IDLE;
reg        mmc_ram_exe_end_r; initial mmc_ram_exe_end_r = 0;
reg        mmc_ram_dma_end_r; initial mmc_ram_dma_end_r = 0;

reg [1:0]  mmc_ram_byte_r;
reg [1:0]  mmc_ram_byte_total_r;
reg        mmc_ram_dpe_r;
reg        mmc_ram_wr_r;
reg        mmc_ram_long_r;
reg [31:0] mmc_ram_rddata_r;
reg [31:0] mmc_ram_wrdata_r;
reg        mmc_ram_pram_r;
reg [1:0]  mmc_ram_pram_index_r; initial mmc_ram_pram_index_r = 0;

reg        mmc_ram_dma_r;
reg        mmc_ram_exe_r;

always @(posedge CLK) begin
  if (RST) begin
    mmc_ram_exe_end_r <= 0;
    mmc_ram_dma_end_r <= 0;

    ram_bus_rrq_r     <= 0;
    ram_bus_wrq_r     <= 0;

    MMC_RAM_STATE <= ST_MMC_RAM_IDLE;
  end
  else begin
    case (MMC_RAM_STATE)
      ST_MMC_RAM_IDLE: begin
        mmc_ram_exe_end_r <= 0;
        mmc_ram_dma_end_r <= 0;
        mmc_ram_byte_r    <= 0;
        mmc_ram_dma_r     <= 0;
        mmc_ram_exe_r     <= 0;

        // bus must be available here
        if      ((dma_mmc_wr_bram_r | dma_mmc_rd_bram_r) & ~mmc_ram_dma_end_r) begin
          ram_bus_rrq_r  <= ~dma_mmc_wr_bram_r;
          ram_bus_wrq_r  <=  dma_mmc_wr_bram_r;
          ram_bus_addr_r <= `MAP_BRAM(dma_mmc_wr_bram_r ? dma_mmc_wr_addr_r : dma_mmc_rd_addr_r);
          ram_bus_data_r <= dma_mmc_data_r[7:0];

          mmc_ram_pram_r       <= 0;

          mmc_ram_byte_total_r  <= 0;
          mmc_ram_dpe_r         <= 0;
          mmc_ram_wr_r          <= dma_mmc_wr_bram_r;
          mmc_ram_long_r        <= 0;
          mmc_ram_wrdata_r[7:0] <= dma_mmc_data_r;

          mmc_ram_dma_r        <= 1;

          MMC_RAM_STATE <= ST_MMC_RAM_WAIT;
        end
        else if ((exe_mmc_wr_r | exe_mmc_rd_r) & ~mmc_ram_exe_end_r) begin
          mmc_ram_byte_total_r <= exe_mmc_byte_total_r;
          mmc_ram_dpe_r        <= exe_mmc_dpe_r;
          mmc_ram_wr_r         <= exe_mmc_wr_r;
          mmc_ram_long_r       <= exe_mmc_long_r;
          mmc_ram_wrdata_r     <= exe_mmc_data_r;

          if (`IS_SA1_BRAM(exe_mmc_addr)/* & RAM_BUS_RDY*/) begin
            ram_bus_rrq_r  <= ~exe_mmc_wr_r;
            ram_bus_wrq_r  <=  exe_mmc_wr_r;
            ram_bus_addr_r <= `MAP_BRAM(exe_mmc_addr);
            ram_bus_data_r <= exe_mmc_data_r[7:0];

            mmc_ram_pram_r <= 0;

            MMC_RAM_STATE  <= ST_MMC_RAM_WAIT;
          end
          else if (`IS_SA1_PRAM(exe_mmc_addr)/* & RAM_BUS_RDY*/) begin
            // PRAM is always RMW if we are writing
            ram_bus_rrq_r  <= 1;
            ram_bus_addr_r <= `MAP_PRAM(exe_mmc_addr);
            ram_bus_data_r <= exe_mmc_data_r[7:0];

            mmc_ram_byte_total_r <= 0; // force 1 byte to avoid complexity of word write and interleaving data
            mmc_ram_pram_r       <= 1;
            mmc_ram_pram_index_r <= exe_mmc_addr[1:0];

            MMC_RAM_STATE <= ST_MMC_RAM_WAIT;
          end

          mmc_ram_exe_r        <= 1;
        end
      end
      ST_MMC_RAM_WAIT: begin
        ram_bus_rrq_r <= 0;
        ram_bus_wrq_r <= 0;

        if (~ram_bus_rrq_r & ~ram_bus_wrq_r & RAM_BUS_RDY) begin
          if (~mmc_ram_pram_r) begin
            // don't increment byte location or shift write data if pram
            mmc_ram_byte_r <= mmc_ram_byte_r + 1;
            mmc_ram_wrdata_r <= {mmc_ram_wrdata_r[7:0],mmc_ram_wrdata_r[31:24],mmc_ram_wrdata_r[23:16],mmc_ram_wrdata_r[15:8]};
          end

          if (mmc_ram_pram_r) begin
            // read data
            case (mmc_ram_pram_index_r)
              0: mmc_ram_rddata_r[7:0] <= bbf ? {6'h00,RAM_BUS_RDDATA[1:0]} : {4'h0,RAM_BUS_RDDATA[3:0]};
              1: mmc_ram_rddata_r[7:0] <= bbf ? {6'h00,RAM_BUS_RDDATA[3:2]} : {4'h0,RAM_BUS_RDDATA[7:4]};
              2: mmc_ram_rddata_r[7:0] <= bbf ? {6'h00,RAM_BUS_RDDATA[5:4]} : {4'h0,RAM_BUS_RDDATA[3:0]};
              3: mmc_ram_rddata_r[7:0] <= bbf ? {6'h00,RAM_BUS_RDDATA[7:6]} : {4'h0,RAM_BUS_RDDATA[7:4]};
            endcase
          end
          else begin
            case (mmc_ram_byte_r)
              0: mmc_ram_rddata_r[7 : 0] <= RAM_BUS_RDDATA[7:0];
              1: mmc_ram_rddata_r[15: 8] <= RAM_BUS_RDDATA[7:0];
              2: mmc_ram_rddata_r[23:16] <= RAM_BUS_RDDATA[7:0];
              3: mmc_ram_rddata_r[31:24] <= RAM_BUS_RDDATA[7:0];
            endcase
          end

          if (mmc_ram_pram_r & mmc_ram_wr_r) begin
            // perform rmw
            ram_bus_wrq_r <= 1;

            mmc_ram_pram_r <= 0;

            // TODO: assumes only one byte (value) is merged
            case (mmc_ram_pram_index_r)
              0: ram_bus_data_r[7:0] <= bbf ? {RAM_BUS_RDDATA[7:2],mmc_ram_wrdata_r[1:0]                    } : {RAM_BUS_RDDATA[7:4],mmc_ram_wrdata_r[3:0]};
              1: ram_bus_data_r[7:0] <= bbf ? {RAM_BUS_RDDATA[7:4],mmc_ram_wrdata_r[1:0],RAM_BUS_RDDATA[1:0]} : {mmc_ram_wrdata_r[3:0],RAM_BUS_RDDATA[3:0]};
              2: ram_bus_data_r[7:0] <= bbf ? {RAM_BUS_RDDATA[7:6],mmc_ram_wrdata_r[1:0],RAM_BUS_RDDATA[3:0]} : {RAM_BUS_RDDATA[7:4],mmc_ram_wrdata_r[3:0]};
              3: ram_bus_data_r[7:0] <= bbf ? {mmc_ram_wrdata_r[1:0],RAM_BUS_RDDATA[5:0]                    } : {mmc_ram_wrdata_r[3:0],RAM_BUS_RDDATA[3:0]};
            endcase
          end
          else if (mmc_ram_byte_r != mmc_ram_byte_total_r) begin
            // stay in the same state and make a new request
            ram_bus_rrq_r  <= ~mmc_ram_wr_r;
            ram_bus_wrq_r  <=  mmc_ram_wr_r;

            if      (mmc_ram_dpe_r)  ram_bus_addr_r[7:0]  <= ram_bus_addr_r[7:0]  + 1;
            //else if (mmc_long_r) ram_bus_addr_r[23:0] <= ram_bus_addr_r[23:0] + 1;
            //else                 ram_bus_addr_r[15:0] <= ram_bus_addr_r[15:0] + 1;
            else                     ram_bus_addr_r[19:0] <= ram_bus_addr_r[19:0] + 1;

            ram_bus_data_r <= mmc_ram_wrdata_r[15:8];
          end
          else begin
            {mmc_ram_dma_end_r,mmc_ram_exe_end_r} <= {mmc_ram_dma_r,mmc_ram_exe_r};

            MMC_RAM_STATE <= ST_MMC_RAM_IDLE;
          end
        end
      end
    endcase
  end
end

assign ROM_BUS_RRQ = rom_bus_rrq_r;
assign ROM_BUS_WRQ = 1'b0;
assign ROM_BUS_WORD = rom_bus_word_r;
assign ROM_BUS_ADDR = rom_bus_addr_r;
assign ROM_BUS_WRDATA = rom_bus_data_r;

assign RAM_BUS_RRQ = ram_bus_rrq_r;
assign RAM_BUS_WRQ = ram_bus_wrq_r;
assign RAM_BUS_WORD = 1'b0;
assign RAM_BUS_ADDR = {4'h0,ram_bus_addr_r};
assign RAM_BUS_WRDATA = ram_bus_data_r;

assign iram_wren = MMC_STATE[clog2(ST_MMC_IRAM)] & mmc_wr_r;
assign iram_addr = mmc_addr_r[10:0];
assign iram_din  = mmc_wrdata_r[7:0];

assign sa1_mmio_addr  = mmc_addr_r[8:0];
assign sa1_mmio_data  = mmc_wrdata_r[7:0];
assign sa1_mmio_write = ~(SNES_WR_end & snes_mmio_active_r) & MMC_STATE[clog2(ST_MMC_MMIO)] & mmc_wr_r;
assign sa1_mmio_read  = ~|sa1_mmio_read_r & ~(~SNES_READ & snes_mmio_active_r & ~snes_mmio_done_r) & MMC_STATE[clog2(ST_MMC_MMIO)] & ~mmc_wr_r;

assign exe_mmc_rddata = mmc_ram_exe_end_r ? mmc_ram_rddata_r : mmc_data_r;
assign dma_mmc_rddata = mmc_ram_dma_end_r ? mmc_ram_rddata_r : mmc_data_r;

assign mmc_exe_end    = MMC_STATE[clog2(ST_MMC_EXE_END)] | mmc_ram_exe_end_r;
assign mmc_dma_end    = MMC_STATE[clog2(ST_MMC_DMA_END)] | mmc_ram_dma_end_r;

//-------------------------------------------------------------------
// DMA Pipeline
//-------------------------------------------------------------------
// The DMA controller supports 2 general modes of operation: normal
// and character conversion (CC).  CC can be broken down into type1
// (fully automatic) and type2 (semi-automatic).  In an attempt to
// get this to fit in the fpga, as much code as re-used as possible.
// The main differences between the 2 modes are addressing/dataswizzle
// and triggers.
//
// normal - no character conversion.  can trigger interrupt.  dtc holds count.  triggered by dda write.
// type1  - bram->iram character conversion.  pixel to planar.  8x8 character.  triggered by dda write and snes reads.
// type2  - brf->iram character conversion.  pixel to planar. 8 pixels in lower or upper brf.  triggered by brf writes.

parameter
  ST_DMA_IDLE        = 8'b00000001,
  ST_DMA_NORMAL_READ = 8'b00000010,
  ST_DMA_TYPE1_READ  = 8'b00000100,
  ST_DMA_TYPE2_READ  = 8'b00001000,
  ST_DMA_READ_END    = 8'b00010000,
  ST_DMA_TYPE1_WRITE = 8'b00100000,
  ST_DMA_WRITE       = 8'b01000000,
  ST_DMA_WRITE_END   = 8'b10000000,
  ST_DMA_ALL         = 8'b11111111;

reg [7:0]  DMA_STATE; initial DMA_STATE = ST_DMA_IDLE;
reg        dma_cc1_en_r; initial dma_cc1_en_r = 0;
reg        dma_normal_pri_active_r; initial dma_normal_pri_active_r = 0;
reg        dma_cc1_active_r; initial dma_cc1_active_r = 0;
reg [6:0]  dma_cc1_imask_r;

`ifdef DMA_ENABLE
reg [7:0]  dma_next_readstate_r; initial dma_next_readstate_r = 0;
reg [7:0]  dma_next_writestate_r; initial dma_next_writestate_r = 0;

reg [23:0] dma_write_addr_r; initial dma_write_addr_r = 0;
reg [7:0]  dma_data_r; initial dma_data_r = 0;

reg [7:0]  dma_cc1_data_r[7:0];
reg        dma_cc1_int_r;
reg [5:0]  dma_cc1_mask_r;
reg [3:0]  dma_cc1_bpp_r; // both bits per pixel and bytes per 8x8 character row
reg [8:0]  dma_cc1_bpl_r; // bytes per line
reg [4:0]  dma_cc1_size_mask_r; // characters per line
reg [4:0]  dma_cc1_char_num_r; initial dma_cc1_char_num_r = 0;
reg [23:0] dma_cc1_addr_char_base_r;
reg [23:0] dma_cc1_addr_row_base_r;
reg [23:0] dma_cc1_addr_rd_r; // current read address
reg [10:0] dma_cc1_addr_wr_r; // current write address

reg [3:0]  dma_cc2_line_r; initial dma_cc2_line_r = 0;

reg        dma_normal_int_r; initial dma_normal_int_r = 0;
reg        dma_normal_prefetch_val_r; initial dma_normal_prefetch_val_r = 0;
reg        dma_normal_prefetch_found_r; initial dma_normal_prefetch_found_r = 0;
reg [7:0]  dma_normal_prefetch_dat_r; initial dma_normal_prefetch_dat_r = 0;
reg [1:0]  dma_normal_state_r; initial dma_normal_state_r = 0;

reg        dma_trigger_normal_r; initial dma_trigger_normal_r = 0;
reg        dma_start_type1_r; initial dma_start_type1_r = 0;
reg        dma_trigger_type1_r; initial dma_trigger_type1_r = 0;
reg        dma_trigger_type2_r; initial dma_trigger_type2_r = 0;

reg [2:0]  dma_line_r; initial dma_line_r = 0;
reg [2:0]  dma_byte_r; initial dma_byte_r = 0;
reg [2:0]  dma_comp_r; initial dma_comp_r = 0;

reg [7:0]  dma_cdma_r; initial dma_cdma_r = 0;
reg [7:0]  dma_dcnt_r; initial dma_dcnt_r = 0;
reg [15:0] dma_dtc_r; initial dma_dtc_r = 0;
reg [23:0] dma_dsa_r; initial dma_dsa_r = 0;
reg [23:0] dma_dda_r; initial dma_dda_r = 0;

always @(posedge CLK) begin
  if (RST) begin
    DMA_STATE             <= ST_DMA_IDLE;
    dma_next_readstate_r  <= ST_DMA_IDLE;
    dma_next_writestate_r <= ST_DMA_IDLE;

    dma_mmc_rd_rom_r   <= 0;
    dma_mmc_rd_bram_r   <= 0;
    dma_mmc_wr_bram_r   <= 0;
    dma_mmc_rd_iram_r   <= 0;
    dma_mmc_wr_iram_r   <= 0;

    dma_trigger_normal_r <= 0;
    dma_start_type1_r    <= 0;
    dma_trigger_type1_r  <= 0;
    dma_trigger_type2_r  <= 0;

    dma_line_r              <= 0;
    dma_cc1_char_num_r      <= 0;
    dma_cc1_int_r           <= 0;
    dma_cc1_en_r            <= 0;
    dma_cc1_active_r        <= 0;
    dma_normal_pri_active_r <= 0;

    dma_cc2_line_r <= 0;

    dma_normal_int_r          <= 0;
    dma_normal_prefetch_val_r <= 0;
    dma_normal_state_r        <= 0;

    SFR_r[`SFR_DMA_IRQFL] <= 0;
    CFR_r[`CFR_DMA_IRQFL] <= 0;
  end
  else begin
    // watch for triggers
    dma_trigger_normal_r <= (   dma_dcnt_r[`DCNT_DMAEN]
                            && ~dma_dcnt_r[`DCNT_CDEN]
                            && (  (~dma_dcnt_r[1] && ~dma_dcnt_r[`DCNT_DD]) // iram
                               || (~dma_dcnt_r[0] &&  dma_dcnt_r[`DCNT_DD]) // bram
                               )
                            && (  (snes_writebuf_val_r && snes_writebuf_addr_r[8:0] == (ADDR_DDA+1) && ~dma_dcnt_r[`DCNT_DD]) // iram
                               || (snes_writebuf_val_r && snes_writebuf_addr_r[8:0] == (ADDR_DDA+2) &&  dma_dcnt_r[`DCNT_DD]) // bram
                               )
                            );
    dma_start_type1_r    <= (   dma_dcnt_r[`DCNT_DMAEN]
                            &&  dma_dcnt_r[`DCNT_CDEN]
                            &&  dma_dcnt_r[`DCNT_CDSEL]
                            && (  (snes_writebuf_val_r && snes_writebuf_addr_r[8:0] == (ADDR_DDA+1))
                               )
                            );
    dma_trigger_type1_r  <= (   dma_cc1_en_r
                            &&  `IS_CPU_BRAM(addr_in_r)
                            //&&  (addr_in_r[23:20] == 4'h4)
                            &&  SNES_RD_start
                            &&  ((addr_in_r[5:0] & dma_cc1_mask_r) == 0)
                            );
`ifdef DMA_TYPE2_ENABLE
    dma_trigger_type2_r  <= (   dma_dcnt_r[`DCNT_DMAEN]
                            &&  dma_dcnt_r[`DCNT_CDEN]
                            && ~dma_dcnt_r[`DCNT_CDSEL]
                            && (  (snes_writebuf_val_r && snes_writebuf_addr_r[8:0] == ADDR_BRF7)
                               || (snes_writebuf_val_r && snes_writebuf_addr_r[8:0] == ADDR_BRFF)
                               )
                            );
`else
    dma_trigger_type2_r  <= 0;
`endif

    dma_comp_r     <= {~|dma_cdma_r[1:0],~dma_cdma_r[1],1'b1};
    dma_cc1_bpp_r  <= {~|dma_cdma_r[1:0],dma_cdma_r[0],dma_cdma_r[1],1'b0};

    case (dma_cdma_r[`CDMA_DMASIZE] + {dma_cdma_r[1]^~dma_cdma_r[0],dma_cdma_r[0]})
      0: dma_cc1_bpl_r <= 9'b000000010;
      1: dma_cc1_bpl_r <= 9'b000000100;
      2: dma_cc1_bpl_r <= 9'b000001000;
      3: dma_cc1_bpl_r <= 9'b000010000;
      4: dma_cc1_bpl_r <= 9'b000100000;
      5: dma_cc1_bpl_r <= 9'b001000000;
      6: dma_cc1_bpl_r <= 9'b010000000;
      7: dma_cc1_bpl_r <= 9'b100000000;
    endcase

    case (dma_cdma_r[`CDMA_DMASIZE])
      0: dma_cc1_size_mask_r <= 1-1;
      1: dma_cc1_size_mask_r <= 2-1;
      2: dma_cc1_size_mask_r <= 4-1;
      3: dma_cc1_size_mask_r <= 8-1;
      4: dma_cc1_size_mask_r <= 16-1;
      5: dma_cc1_size_mask_r <= 32-1;
    endcase

    // source is naturally aligned to full width (charSize * dmaSize).  That makes addressing easier.
    dma_cc1_mask_r      <= {dma_comp_r,3'b111};
    dma_cc1_imask_r     <= {dma_comp_r,4'b1111};

    // CC1 to SCPU (snes) interrupt
    if      (DMA_STATE[clog2(ST_DMA_IDLE)] & dma_cc1_int_r)                                                        SFR_r[`SFR_DMA_IRQFL] <= 1;
    else if (snes_writebuf_val_r && snes_writebuf_addr_r[8:0] == ADDR_SIC && snes_writebuf_data_r[`SIC_DMA_IRQCL]) SFR_r[`SFR_DMA_IRQFL] <= 0;

    // normal to CCPU (sa1) interrupt
    if      (DMA_STATE[clog2(ST_DMA_IDLE)] & dma_normal_int_r)                                                       CFR_r[`CFR_DMA_IRQFL] <= 1;
    else if (snes_writebuf_val_r && snes_writebuf_addr_r[8:0] == ADDR_CIC  &&  snes_writebuf_data_r[`CIC_DMA_IRQCL]) CFR_r[`CFR_DMA_IRQFL] <= 0;

    if      (dma_start_type1_r)                                                                                   dma_cc1_en_r <= 1;
    else if (snes_writebuf_val_r && snes_writebuf_addr_r[8:0] == ADDR_CDMA && snes_writebuf_data_r[`CDMA_CHDEND]) dma_cc1_en_r <= 0;

    if      (dma_trigger_type1_r)                                                                                 dma_cc1_active_r <= 1;
    else if (snes_writebuf_val_r && snes_writebuf_addr_r[8:0] == ADDR_CDMA && snes_writebuf_data_r[`CDMA_CHDEND]) dma_cc1_active_r <= 0;

    // TODO: temporarily make DMA high priority to avoid races.
    if      ((dma_trigger_normal_r/* & dma_dcnt_r[`DCNT_DPRIO]*/) | dma_trigger_type2_r)                              dma_normal_pri_active_r <= 1;
    else if (DMA_STATE[clog2(ST_DMA_IDLE)])                                                                       dma_normal_pri_active_r <= 0;

    case (DMA_STATE)
      ST_DMA_IDLE: begin
        // clear line number
        if (~dma_dcnt_r[`DCNT_DMAEN]) dma_cc2_line_r <= 0;

        dma_cdma_r <= CDMA_r;
        dma_dcnt_r <= DCNT_r;
        dma_dtc_r <= DTC_r;
        dma_dsa_r <= DSA_r;
        dma_dda_r <= DDA_r;

        dma_byte_r <= 0;

        // will be 1 when we transition to idle after the first character.
        dma_cc1_int_r <= dma_start_type1_r;

        dma_normal_int_r          <= 0;
        dma_normal_prefetch_val_r <= 0;

        if      (dma_trigger_normal_r) begin
          dma_normal_state_r <= 1;

          DMA_STATE <= ST_DMA_NORMAL_READ;
        end
        else if (dma_start_type1_r) begin
          // when we are only one character wide then bpp == bpl
          dma_cc1_addr_char_base_r <= |dma_cc1_size_mask_r ? (DSA_r + dma_cc1_bpp_r) : (DSA_r + {dma_cc1_bpl_r,3'b000});
          dma_cc1_addr_row_base_r  <= DSA_r;

          dma_cc1_addr_rd_r   <= DSA_r;
          dma_cc1_addr_wr_r   <= DDA_r[10:0];

          dma_cc1_char_num_r  <= {4'b0000,dma_cc1_size_mask_r[0]};
          dma_line_r          <= 0;

          DMA_STATE <= ST_DMA_TYPE1_READ;
        end
        else if (dma_trigger_type1_r) begin
          // either we are in the same row and increment the base by the width of a character in bytes or take the current address
          // which has incremented beyond the start of the next character by bpl-2*bpp
          dma_cc1_addr_char_base_r <= (dma_cc1_char_num_r == dma_cc1_size_mask_r) ? (dma_cc1_addr_row_base_r + {dma_cc1_bpl_r,3'b000}) : (dma_cc1_addr_char_base_r + dma_cc1_bpp_r);
          dma_cc1_addr_row_base_r  <= |dma_cc1_char_num_r ? dma_cc1_addr_row_base_r : dma_cc1_addr_char_base_r;

          dma_cc1_addr_rd_r        <= dma_cc1_addr_char_base_r;
          // toggle double buffer
          dma_cc1_addr_wr_r[6:4] <= dma_cc1_addr_wr_r[6:4] ^ dma_cc1_bpp_r[3:1];

          dma_cc1_char_num_r  <= (dma_cc1_char_num_r + 1) & dma_cc1_size_mask_r;

          DMA_STATE <= ST_DMA_TYPE1_READ;
        end
        else if (dma_trigger_type2_r) begin
          DMA_STATE <= ST_DMA_TYPE2_READ;
        end
      end

`ifdef DMA_NORMAL_ENABLE
      // normal
      // read/write state
      ST_DMA_NORMAL_READ: begin
        dma_mmc_rd_rom_r  <= dma_normal_state_r[0] & ~|dma_dcnt_r[1:0] & ~dma_normal_prefetch_val_r;
        dma_mmc_rd_bram_r <= dma_normal_state_r[0] & dma_dcnt_r[0];
        dma_mmc_rd_iram_r <= dma_normal_state_r[0] & dma_dcnt_r[1];
        dma_mmc_wr_bram_r <= dma_normal_state_r[1] & dma_dcnt_r[`DCNT_DD];
        dma_mmc_wr_iram_r <= dma_normal_state_r[1] & ~dma_dcnt_r[`DCNT_DD];

        // adjust count on writes
        if (dma_normal_state_r[0]) dma_dsa_r <= dma_dsa_r + 1;
        if (dma_normal_state_r[1]) dma_dda_r <= dma_dda_r + 1;
        if (dma_normal_state_r[1]) dma_dtc_r <= dma_dtc_r - 1;

        dma_mmc_rd_addr_r <= {(dma_dsa_r[23:11] & {13{~dma_dcnt_r[1]}}),      dma_dsa_r[10:0]};
        dma_mmc_wr_addr_r <= {(dma_dda_r[23:11] & {13{dma_dcnt_r[`DCNT_DD]}}),dma_dda_r[10:0]};

        dma_mmc_data_r[7:0] <= dma_data_r[7:0];
        dma_normal_prefetch_found_r <= 0;

        DMA_STATE <= ST_DMA_WRITE;
      end
      // new wait state
      ST_DMA_WRITE: begin
        // need to watch for both read and write ending and grab data from appropriate place

        // FIXME: remove the hack that uses mmc_wr_r
        if      (dma_mmc_rd_bram_r & mmc_ram_dma_end_r)        dma_data_r[7:0] <= mmc_ram_rddata_r[7:0];
        else if (MMC_STATE[clog2(ST_MMC_DMA_END)] & ~mmc_wr_r) dma_data_r[7:0] <= mmc_data_r[7:0];
        else if (dma_normal_prefetch_val_r)                    dma_data_r[7:0] <= dma_normal_prefetch_dat_r[7:0];

        // store the next prefetch byte if it's to rom
        if (dma_mmc_rd_rom_r & ~dma_normal_prefetch_val_r & ~dma_mmc_rd_addr_r[0] & MMC_STATE[clog2(ST_MMC_DMA_END)]) dma_normal_prefetch_found_r <= 1;
        if (MMC_STATE[clog2(ST_MMC_DMA_END)])                                                                         dma_normal_prefetch_dat_r <= mmc_data_r[15:8];

        // need to disambiguate between reads and writes for rom/iram
        if (MMC_STATE[clog2(ST_MMC_DMA_END)])             dma_mmc_rd_rom_r <= 0;
        if (MMC_STATE[clog2(ST_MMC_DMA_END)] & ~mmc_wr_r) dma_mmc_rd_iram_r <= 0;
        if (MMC_STATE[clog2(ST_MMC_DMA_END)] & mmc_wr_r)  dma_mmc_wr_iram_r <= 0;
        if (mmc_ram_dma_end_r)                            dma_mmc_rd_bram_r <= 0;
        if (mmc_ram_dma_end_r)                            dma_mmc_wr_bram_r <= 0;

        dma_normal_state_r <= {1'b1, |dma_dtc_r[15:1]};

        // look for all conditions done
        if (~(dma_mmc_rd_rom_r | dma_mmc_rd_bram_r | dma_mmc_wr_bram_r | dma_mmc_rd_iram_r | dma_mmc_wr_iram_r)) begin
          if (~|dma_dtc_r) dma_normal_int_r <= 1;

          dma_normal_prefetch_val_r <= dma_normal_prefetch_found_r;
          dma_normal_prefetch_found_r <= 0;

          if (~|dma_dtc_r) DMA_STATE <= ST_DMA_IDLE;
          else             DMA_STATE <= ST_DMA_NORMAL_READ;
        end
      end
`endif

`ifdef DMA_TYPE1_ENABLE
      // type1
      ST_DMA_TYPE1_READ: begin
        // only perform memory read for valid byte
        //dma_cc1_rd_r <= ~|(dma_byte_r[1:0] & {dma_cdma_r[1],|dma_cdma_r[1:0]});
        //dma_mmc_rd_r <= ~|(dma_byte_r[1:0] & {dma_cdma_r[1],|dma_cdma_r[1:0]}); // & ~dma_cc1_upper_r;
        //{dma_mmc_rom_r,dma_mmc_iram_r,dma_mmc_bram_r} <= {1'b0,1'b0,1'b1};
        dma_mmc_rd_bram_r <= ~|(dma_byte_r[1:0] & {dma_cdma_r[1],|dma_cdma_r[1:0]});

        // address is for row and also include the byte of interest.
        dma_mmc_rd_addr_r <= dma_cc1_addr_rd_r | (dma_cdma_r[1] ? {2'b00,dma_byte_r[2]} : dma_cdma_r[0] ? {1'b0,dma_byte_r[2:1]} : dma_byte_r[2:0]);

        dma_byte_r <= dma_byte_r + 1;

        // test for transition to write state
        dma_next_readstate_r <= &dma_byte_r ? ST_DMA_TYPE1_WRITE : ST_DMA_TYPE1_READ;

        DMA_STATE <= ST_DMA_READ_END;
      end
      ST_DMA_TYPE1_WRITE: begin
        dma_mmc_wr_iram_r <= ~|(dma_byte_r & ~dma_comp_r);
        //{dma_mmc_rom_r,dma_mmc_iram_r,dma_mmc_bram_r} <= {1'b0,1'b1,1'b0};

        // calculate address
        dma_mmc_wr_addr_r <= {13'h0000,dma_cc1_addr_wr_r} | {dma_byte_r[2:1],dma_line_r[2:0],dma_byte_r[0]};

        dma_mmc_data_r <= {dma_cc1_data_r[0][dma_byte_r],
                           dma_cc1_data_r[1][dma_byte_r],
                           dma_cc1_data_r[2][dma_byte_r],
                           dma_cc1_data_r[3][dma_byte_r],
                           dma_cc1_data_r[4][dma_byte_r],
                           dma_cc1_data_r[5][dma_byte_r],
                           dma_cc1_data_r[6][dma_byte_r],
                           dma_cc1_data_r[7][dma_byte_r]
                          };

        dma_byte_r <= dma_byte_r + 1;

        // advance to the next byte
        if (&dma_byte_r) begin
          dma_line_r[2:0]   <= dma_line_r[2:0] + 1;
          dma_cc1_addr_rd_r <= dma_cc1_addr_rd_r + dma_cc1_bpl_r;
        end

        dma_next_writestate_r <= &dma_byte_r ? (&dma_line_r[2:0] ? ST_DMA_IDLE : ST_DMA_TYPE1_READ) : ST_DMA_TYPE1_WRITE;

        DMA_STATE <= ST_DMA_WRITE_END;
      end
`endif
`ifdef DMA_TYPE2_ENABLE
      // type2
      ST_DMA_TYPE2_READ: begin
        dma_mmc_wr_iram_r <= ~|(dma_byte_r & ~dma_comp_r);
        //{dma_mmc_rom_r,dma_mmc_iram_r,dma_mmc_bram_r} <= {1'b0,1'b1,1'b0};

        // compose BRF to iram write
        dma_mmc_wr_addr_r <= {13'h0000,
                              DDA_r[10:7],
                              (|dma_cdma_r[`CDMA_DMACB] ? DDA_r[6]                                              : dma_cc2_line_r[3]),
                              (dma_cdma_r[1]            ? DDA_r[5]          : dma_cdma_r[0] ? dma_cc2_line_r[3] : dma_byte_r[2]    ),
                              (dma_cdma_r[1]            ? dma_cc2_line_r[3] :                 dma_byte_r[1]                        ),
                              dma_cc2_line_r[2:0],
                              dma_byte_r[0]
                             };

        dma_mmc_data_r <= {dma_cc2_line_r[0] ? BRF_r[8][dma_byte_r]  : BRF_r[0][dma_byte_r],
                           dma_cc2_line_r[0] ? BRF_r[9][dma_byte_r]  : BRF_r[1][dma_byte_r],
                           dma_cc2_line_r[0] ? BRF_r[10][dma_byte_r] : BRF_r[2][dma_byte_r],
                           dma_cc2_line_r[0] ? BRF_r[11][dma_byte_r] : BRF_r[3][dma_byte_r],
                           dma_cc2_line_r[0] ? BRF_r[12][dma_byte_r] : BRF_r[4][dma_byte_r],
                           dma_cc2_line_r[0] ? BRF_r[13][dma_byte_r] : BRF_r[5][dma_byte_r],
                           dma_cc2_line_r[0] ? BRF_r[14][dma_byte_r] : BRF_r[6][dma_byte_r],
                           dma_cc2_line_r[0] ? BRF_r[15][dma_byte_r] : BRF_r[7][dma_byte_r]
                          };

        dma_byte_r <= dma_byte_r + 1;

        if (&dma_byte_r) dma_cc2_line_r <= dma_cc2_line_r + 1;
        dma_next_writestate_r <= &dma_byte_r ? ST_DMA_IDLE : ST_DMA_TYPE2_READ;

        DMA_STATE <= ST_DMA_WRITE_END;
      end
`endif

      ST_DMA_READ_END: begin
        if (~dma_mmc_rd_bram_r) begin
          //dma_normal_prefetch_val_r <= 0;
          //dma_data_r <= dma_normal_prefetch_dat_r[7:0];

          DMA_STATE <= dma_next_readstate_r;
          //if (dma_cc1_rd_r) dma_cc1_upper_r <= 0;
        end
        else if (mmc_dma_end) begin
          //dma_normal_prefetch_val_r <= ~dma_mmc_addr_r[0] & dma_mmc_rom_r;
          dma_mmc_rd_bram_r <= 0;
          dma_data_r <= dma_mmc_rddata[7:0];

          DMA_STATE <= dma_next_readstate_r;
        end

        //dma_normal_prefetch_dat_r <= dma_mmc_rddata[15:8];

        if (~dma_mmc_rd_bram_r | mmc_dma_end) begin
          dma_cc1_data_r[7] <=   dma_mmc_rd_bram_r  ? dma_mmc_rddata[7:0]
                               : dma_cdma_r[0]      ? {dma_cc1_data_r[7][3:0],dma_cc1_data_r[7][7:4]}
                               :                      {dma_cc1_data_r[7][1:0],dma_cc1_data_r[7][7:6],dma_cc1_data_r[7][5:4],dma_cc1_data_r[7][3:2]}
                               ;
          // shift older data
          for (i = 0; i < 7; i = i + 1) dma_cc1_data_r[i] <= dma_cc1_data_r[i+1];
        end
      end
      ST_DMA_WRITE_END: begin
        if (~dma_mmc_wr_iram_r) begin
          DMA_STATE <= dma_next_writestate_r;
        end
        else if (mmc_dma_end) begin
          dma_mmc_wr_iram_r <= 0;

          DMA_STATE <= dma_next_writestate_r;
        end
      end
    endcase
  end
end
`endif

assign dma_mmc_cc1_en   = dma_cc1_en_r;
assign dma_mmc_cc1_mask = dma_cc1_imask_r;

//-------------------------------------------------------------------
// VBD Pipeline
//-------------------------------------------------------------------
// The variable bit data pipeline provides a programmable shifted/masked
// interface to rom data.  It triggers on MMIO reads and writes.
//
// There are two modes of operation:
// fixed - write address, loop (data read, control write)
// auto  - write address, write control, [not currently supported]
parameter
  ST_VBD_IDLE        = 8'b00000001,
  ST_VBD_READ        = 8'b00000010,
  ST_VBD_READ_END    = 8'b00000100,
  ST_VBD_SHIFT       = 8'b00001000,
  ST_VBD_ALL         = 8'b11111111;

reg [7:0]  VBD_STATE; initial VBD_STATE = ST_VBD_IDLE;

reg [23:0] VBA_r; initial VBA_r = 0;
reg [4:0]  vbd_temp;
reg [3:0]  vbd_vbit_r; initial vbd_vbit_r = 0;
reg        vbd_trigger_r; initial vbd_trigger_r = 0;
reg        vbd_update_r; initial vbd_update_r = 0;
reg [31:0] vbd_data_r;

reg        vbd_active_r; initial vbd_active_r = 0;

`ifdef VBD_ENABLE
always @(posedge CLK) begin
  if (RST) begin
    vbd_mmc_rd_r  <= 0;
    VDA_r         <= 0;
    VDP_r         <= 0;
    vbd_vbit_r    <= 0;
    vbd_trigger_r <= 0;
    vbd_update_r  <= 0;
    vbd_active_r  <= 0;

    VBD_STATE <= ST_VBD_IDLE;
  end
  else begin
    // watch for triggers
    // HL=0 trigger on VBA+2 and every VBD write.  HL=1 trigger on VDP+1 data read and every VBD write.
    vbd_trigger_r <= (VBD_r[`VBD_HL] && sa1_mmio_read_r[1] && snes_readbuf_mmio_addr_r[8:0] == ADDR_VDP+1) || (snes_writebuf_val_r && ((~VBD_r[`VBD_HL] && snes_writebuf_addr_r[8:0] == ADDR_VDA+2) || snes_writebuf_addr_r[8:0] == ADDR_VBD));
    // HL=0 update on VBD write.  needs to sync'ed with trigger to get new register value.  this is done by adding the extra READ stage.  HL=1 update on data written to VDP
    vbd_update_r <= (snes_writebuf_val_r && snes_writebuf_addr_r[8:0] == ADDR_VBD && ~snes_writebuf_data_r[`VBD_HL]) || (VBD_STATE[clog2(ST_VBD_SHIFT)] && VBD_r[`VBD_HL]);

    case (VBD_STATE)
      ST_VBD_IDLE: begin
        if (vbd_update_r) begin
          vbd_temp = {1'b0,vbd_vbit_r} + {~|VBD_r[`VBD_VB],VBD_r[`VBD_VB]};

          vbd_vbit_r <= vbd_temp[3:0];
          VDA_r <= VDA_r[23:0] + {vbd_temp[4],1'b0};
        end
        else if (snes_writebuf_val_r) begin
          if      (snes_writebuf_addr_r[8:0] == ADDR_VDA+0) VDA_r[7 : 0] <= snes_writebuf_data_r;
          else if (snes_writebuf_addr_r[8:0] == ADDR_VDA+1) VDA_r[15: 8] <= snes_writebuf_data_r;
          else if (snes_writebuf_addr_r[8:0] == ADDR_VDA+2) begin VDA_r[23:16] <= snes_writebuf_data_r; vbd_vbit_r <= 0; end
        end

        if (vbd_trigger_r) begin
          vbd_active_r <= 1;

          VBD_STATE <= ST_VBD_READ;
        end
      end
      ST_VBD_READ: begin
        vbd_mmc_rd_r   <= 1;
        vbd_mmc_addr_r <= VDA_r;

        VBD_STATE <= ST_VBD_READ_END;
      end
      ST_VBD_READ_END: begin
        if (MMC_STATE[clog2(ST_MMC_VBD_END)]) begin
          vbd_mmc_rd_r <= 0;

          // TODO: use wire to support new mmc
          vbd_data_r[31:0] <= mmc_data_r[31:0];

          VBD_STATE <= ST_VBD_SHIFT;
        end
      end
      ST_VBD_SHIFT: begin
        VDP_r[15:0] <= vbd_data_r[31:0] >> vbd_vbit_r;

        vbd_active_r <= 0;

        VBD_STATE <= ST_VBD_IDLE;
      end
    endcase
  end
end
`endif

//-------------------------------------------------------------------
// DECODER
//-------------------------------------------------------------------

reg [15:0] REG[7:0];
reg [15:0] REGS[7:0];

always @(*) begin
  REG[`REG_Z] = 16'h0000;
  REG[`REG_A] = A_r;
  REG[`REG_X] = X_r;
  REG[`REG_Y] = Y_r;
  REG[`REG_S] = S_r;
  REG[`REG_D] = D_r;
  REG[`REG_B] = {8'h00,DBR_r};
  REG[`REG_P] = {8'h00,P_r};
end

always @(*) begin
  REGS[`REG_Z] = 16'h0000;
  REGS[`REG_A] = A_r;
  REGS[`REG_X] = X_r;
  REGS[`REG_Y] = Y_r;
  REGS[`REG_S] = {8'h00,PBR_r};
  REGS[`REG_D] = D_r;
  REGS[`REG_B] = {8'h00,DBR_r};
  REGS[`REG_P] = {8'h00,P_r};
end

// need to take from the input so we get a clock
//wire [7:0]  dec_addr = MMC_STATE[clog2(ST_MMC_ROM)] ? ROM_BUS_RDDATA[7:0] : mmc_data_r[7:0];
wire [7:0]  dec_addr = exe_mmc_int ? 8'h00 : exe_fetch_byte_val ? exe_fetch_byte[7:0] : mmc_exe_end ? exe_mmc_rddata[7:0] : exe_fetch_data[7:0];
wire [31:0] dec_data;

`ifdef MK2
dec_table dec (
  .clka(CLK),       // input clka
  .addra(dec_addr), // input [7 : 0] addra
  .douta(dec_data)  // output [31 : 0] douta
);
`endif
`ifdef MK3
dec_table dec (
  .clock(CLK),        // input clock
  .address(dec_addr), // input [7 : 0] address
  .q(dec_data)        // output [31 : 0] q
);
`endif

//-------------------------------------------------------------------
// Interrupt Controller
//-------------------------------------------------------------------
// The interrupt controller handles sa1 irq and nmi interrupts.
// Interrupts can be observed at cycle boundaries and can't be
// interrupted with the exception of a nmi interrupting a irq.

reg        int_pending_r; initial int_pending_r = 0;
reg        int_nmi_r; initial int_nmi_r = 0;
reg [15:0] int_vector_r; initial int_vector_r = 0;
reg        int_rti_r; initial int_rti_r = 0;

wire       int_wai;

// lots of races to handle:
// - RTI needs to clear nmi interrupt
// - WAI write from execute and clear from interrupt edge (while in WAI state).  Should have common support in mmc for interrupt active.
// - Set/Clear interrupt flag in register state.
always @(posedge CLK) begin
  int_rti_r <= exe_dec_grp == `GRP_SPC && exe_dec_add_stk && !exe_dec_store;

  if (RST) begin
    int_pending_r <= 0;
    int_nmi_r     <= 0;

    WAI_r         <= 0;
  end
  else begin
    // WAI_r can only be set in EXE_WAIT for WAI
    if (EXE_STATE[clog2(ST_EXE_WAIT)] & pipeline_advance) begin
      // check current pending.  taking an interrupt will block nmi and avoid duplicate irq.
      // pending is only set during the interrupt (break opcode) execution
      if (int_pending_r) begin
        int_pending_r <= 0;
      end
      else if (int_rti_r) begin
        // clear current nmi on rti.  this is either already zero or must be a nmi so unconditionally clear
        int_nmi_r <= 0;
      end
      // check NMI
      else if (~int_nmi_r) begin
        if (CIE_r[`CIE_SA1_NMIEN] & CFR_r[`CFR_SA1_NMIFL]) begin
          int_pending_r <= 1;
          int_nmi_r     <= 1;
          int_vector_r  <= CNV_r;
        end
        // check IRQ
        else if (~P_r[`P_I]) begin
          // TODO: timer
          // register based interrupts
          if ((CIE_r[`CIE_SA1_IRQEN] & CFR_r[`CFR_SA1_IRQFL]) | (CIE_r[`CIE_DMA_IRQEN] & CFR_r[`CFR_DMA_IRQFL])) begin
            int_pending_r <= 1;
            int_vector_r  <= CIV_r;
          end
        end
      end
    end

    // WAI set/clear
    if (WAI_r & (CFR_r[`CFR_SA1_IRQFL] | CFR_r[`CFR_DMA_IRQFL] | CFR_r[`CFR_SA1_NMIFL])) begin
      WAI_r <= 0;
    end
    else if (exe_wai) begin
      WAI_r <= 1;
    end
  end
end

assign exe_wai     = EXE_STATE[clog2(ST_EXE_EXECUTE)] & int_wai;
assign exe_mmc_int = int_pending_r;

//-------------------------------------------------------------------
// BCD
//-------------------------------------------------------------------
`ifdef BCD_ENABLE
reg [15:0] bcd_a_r;
reg [15:0] bcd_b_r;
reg [15:0] bcd_o_r;
reg [3:0]  bcd_c_r;

reg [1:0]  bcd_cnt_r; initial bcd_cnt_r = 3;
reg        bcd_state_r; initial bcd_state_r = 0;
reg        bcd_done_r; initial bcd_done_r = 0;

// exe inputs
reg        exe_bcd_val_r; initial exe_bcd_val_r = 0;
reg [15:0] exe_bcd_a_r; initial exe_bcd_a_r = 0;
reg [15:0] exe_bcd_b_r; initial exe_bcd_b_r = 0;
reg        exe_bcd_c_r; initial exe_bcd_c_r = 0;

wire [4:0] bcd_result;

always @(posedge CLK) begin
  if (RST) begin
    bcd_state_r <= 0;
    bcd_done_r  <= 0;
    bcd_cnt_r   <= 3;
  end
  else begin
    if (~bcd_state_r) begin
      bcd_done_r <= 0;

      if (exe_bcd_val_r) begin
        bcd_a_r    <= exe_bcd_a_r;
        bcd_b_r    <= exe_bcd_b_r;
        bcd_c_r[3] <= exe_bcd_c_r;

        bcd_state_r <= 1;
      end
    end
    else begin
      bcd_a_r <= {bcd_a_r[3:0],bcd_a_r[15:4]};
      bcd_b_r <= {bcd_b_r[3:0],bcd_b_r[15:4]};

      bcd_o_r[11:0] <= bcd_o_r[15:4];
      bcd_c_r[2:0]  <= bcd_c_r[3:1];

      {bcd_c_r[3],bcd_o_r[15:12]} <= bcd_result[4:0] + bcd_adder(bcd_result[4],bcd_result[3:0]);

      bcd_cnt_r   <= bcd_cnt_r - 1;
      bcd_done_r  <= ~|bcd_cnt_r;
      bcd_state_r <= |bcd_cnt_r;
    end
  end
end

assign bcd_result = bcd_a_r[3:0] + bcd_b_r[3:0] + bcd_c_r[3];
`endif

//-------------------------------------------------------------------
// EXECUTION PIPELINE
//-------------------------------------------------------------------

reg [31:0] exe_data_r;
reg [15:0] exe_fetch_data_r;
reg [23:0] exe_addr_r; initial exe_addr_r = 0;
reg [23:0] exe_mmc_addr_r; initial exe_mmc_addr_r = 0;

reg [1:0]  exe_opsize_r; initial exe_opsize_r = 0;
reg [7:0]  exe_opcode_r; initial exe_opcode_r = 0;
reg [23:0] exe_operand_r; initial exe_operand_r = 0;
reg [1:0]  exe_fetch_size_r; initial exe_fetch_size_r = 0;

reg [15:0] exe_src_r; initial exe_src_r = 16'h0BAD;
reg [15:0] exe_dst_r; initial exe_dst_r = 16'h0BAD;

reg        exe_control_r; initial exe_control_r = 0;
reg        exe_load_r; initial exe_load_r = 0;
reg        exe_store_r; initial exe_store_r = 0;
reg        exe_data_word_r; initial exe_data_word_r = 0;
reg [15:0] exe_nextpc_r; initial exe_nextpc_r = 0;
reg [15:0] exe_nextpc_addr_r; initial exe_nextpc_addr_r = 0;
reg [15:0] exe_add_post_r; initial exe_add_post_r = 0;
reg        exe_dst_p_r; initial exe_dst_p_r = 0;
reg [23:0] exe_target_r; initial exe_target_r = 0;
reg [15:0] exe_mod_r; initial exe_mod_r = 0;

reg [15:0] exe_a_r; initial exe_a_r = 0;
reg [15:0] exe_x_r; initial exe_x_r = 0;
reg [15:0] exe_y_r; initial exe_y_r = 0;
reg [15:0] exe_s_r; initial exe_s_r = 16'h01FF;
reg [15:0] exe_d_r; initial exe_d_r = 0;
reg [7:0]  exe_dbr_r; initial exe_dbr_r = 0;
reg [7:0]  exe_pbr_r; initial exe_pbr_r = 0;
reg [7:0]  exe_p_r; initial exe_p_r = 0;
reg        exe_e_r; initial exe_e_r = 1;

reg        exe_active_r; initial exe_active_r = 0;

reg        exe_mmc_state_exe_end_r; initial exe_mmc_state_exe_end_r = 0;

reg        exe_prefetch_val_r; initial exe_prefetch_val_r = 0;
reg [7:0]  exe_prefetch_r; initial exe_prefetch_r = 0;

reg        exe_move_val_r; initial exe_move_val_r = 0;

wire       exe_dpe       = ~|D_r[7:0] & E_r;
wire       exe_data_word = |({~P_r[`P_X],~P_r[`P_M]}&dec_data[`DEC_PRC]) | &dec_data[`DEC_PRC];
wire       exe_dec_imm16 = (|({~P_r[`P_X],~P_r[`P_M]}&dec_data[`DEC_PRC]) & dec_data[`ADD_IMM]);

// temporary
reg [16:0] exe_result;
reg [16:0] add_result;

always @(posedge CLK) begin

`ifdef BCD_ENABLE
  // drive BCD inputs
  exe_bcd_a_r <= exe_src_r[15:0];
  // invert for SBC
  exe_bcd_b_r <= exe_opcode_r[7] ? ~exe_data_r[15:0] : exe_data_r[15:0];
  exe_bcd_c_r <= P_r[`P_C];
`endif

  if (RST) begin
    EXE_STATE <= ST_EXE_IDLE;

    PBR_r         <= 0;
    PC_r          <= 0;
    A_r           <= 0;
    X_r           <= 0;
    Y_r           <= 0;
    S_r[15:8]     <= 1;
    D_r           <= 0;
    DBR_r         <= 0;
    P_r           <= 8'h34;
    E_r           <= 1;

    //exe_fetch_addr_r <= 0;
    //exe_addr_r       <= 0;
    //exe_mmc_addr_r   <= 0;

    exe_opsize_r  <= 0;
    exe_fetch_size_r <= 0;
    exe_opcode_r  <= 0;
    exe_operand_r <= 0;
    exe_decode_r  <= 0;

    //exe_src_r     <= 16'h0BAD;
    //exe_dst_r     <= 16'h0BAD;

    exe_control_r <= 0;
    exe_pbr_r     <= 0;
    exe_nextpc_r  <= 0;
    exe_nextpc_addr_r <= 0;
    exe_add_post_r <= 0;

    exe_mmc_rd_r  <= 0;
    exe_mmc_wr_r  <= 0;
    //exe_mmc_data_r<= 0;
    exe_mmc_long_r<= 0;
    exe_mmc_byte_total_r <= 0;

    exe_mmc_state_exe_end_r <= 0;

    exe_active_r <= 0;

    exe_prefetch_val_r <= 0;
    exe_move_val_r <= 0;

`ifdef BCD_ENABLE
    exe_bcd_val_r <= 0;
`endif

    e2c_waitcnt_r <= 0;
  end
  else begin
    case (EXE_STATE)
      ST_EXE_IDLE: begin
        if (~CCNT_r[`CCNT_SA1_RESB] & sa1_clock_en) begin
          {PBR_r,PC_r} <= {8'h00,CRV_r};
          exe_fetch_addr_r <= {8'h00,CRV_r};
          exe_fetch_size_r <= 0;
          exe_mmc_byte_total_r <= 1;
          exe_data_word_r <= 0;
          exe_mmc_long_r <= 0;
          exe_mmc_dpe_r <= 0;

          exe_opsize_r <= 0;

          exe_active_r <= 1;

          EXE_STATE <= ST_EXE_FETCH;
        end

        exe_prefetch_val_r <= 0;
        exe_move_val_r <= 0;
        e2c_waitcnt_r  <= 0;
      end

      // FETCH
      ST_EXE_FETCH: begin
        exe_mmc_rd_r   <= ~(int_pending_r | exe_prefetch_val_r | exe_move_val_r);
        // only tell the mmc about 1 byte if its to rom.  It still returns 2 which we will use if aligned.
        // TODO: why is this slower?
        //exe_mmc_byte_total_r <= `IS_ROM(exe_fetch_addr_r) ? 0 : 1;
        exe_mmc_byte_total_r <= 1;
        exe_mmc_state_exe_end_r <= 0;

        e2c_waitcnt_r  <= 0;
        exe_move_val_r <= 0;

        // fast move skips fetch
        if (exe_move_val_r & ~int_pending_r) begin
          // reset some state that was modified
          exe_opsize_r  <= `SZE_3;

          exe_control_r <= exe_decode_r[`DEC_CONTROL];
          exe_load_r    <= exe_decode_r[`DEC_LOAD];
          exe_store_r   <= exe_decode_r[`DEC_STORE];

          EXE_STATE <= ST_EXE_ADDRESS;
        end
        else begin
          EXE_STATE <= ST_EXE_FETCH_END;
        end
      end
      ST_EXE_FETCH_END: begin
        // always stop the read at END
        if (mmc_exe_end) begin
          exe_mmc_rd_r <= 0;
          exe_fetch_data_r <= exe_mmc_rddata[15:0];
        end

        // TODO: fill in other data sources
        exe_mmc_state_exe_end_r <= mmc_exe_end | int_pending_r | exe_prefetch_val_r;

        // The decode rom takes an additional clock.
        if (exe_mmc_state_exe_end_r) begin
          //exe_fetch_data_r <= int_pending_r ? 8'h00 : exe_prefetch_val_r ? exe_prefetch_r : exe_fetch_data_r;

          if (~|exe_opsize_r) begin
            exe_opcode_r       <= exe_mmc_int ? 8'h00 : exe_prefetch_val_r ? exe_prefetch_r : exe_fetch_data_r[7:0];
            // word size only affects immediate for fetch
            exe_opsize_r       <= dec_data[`DEC_SIZE] ^ {2{exe_dec_imm16}};
            exe_control_r      <= dec_data[`DEC_CONTROL];
            exe_load_r         <= dec_data[`DEC_LOAD];
            exe_store_r        <= dec_data[`DEC_STORE];
            exe_decode_r       <= dec_data;
            exe_data_word_r    <= exe_data_word;

            exe_nextpc_addr_r  <= PC_r + dec_data[`DEC_SIZE] + (exe_dec_imm16 ? 2 : 1);

            // FIXME: fix latencies once perf problems are resolved
            e2c_waitcnt_r <= 0;
            //e2c_waitcnt_r <= dec_data[`DEC_LATENCY];

            // `define ADD_MOD     27:26
            exe_mod_r <= dec_data[27] ? 16'h0000 : dec_data[26] ? Y_r[15:0] : X_r[15:0];

            // record the current PC and previous PC
            debug_inst_addr_r <= {PBR_r,PC_r};
            debug_inst_addr_prev_r <= debug_inst_addr_r;
          end

          exe_a_r            <= A_r;
          exe_x_r            <= X_r;
          exe_y_r            <= Y_r;
          exe_s_r            <= S_r;
          exe_d_r            <= D_r;
          exe_dbr_r          <= DBR_r;
          exe_pbr_r          <= PBR_r;
          exe_p_r            <= P_r;
          exe_e_r            <= E_r;

`ifdef EXE_FAST_FETCH
          // next state, address, and prefetch logic.
          if (~|exe_opsize_r) begin
            // initial decode
            // `define DEC_SIZE    16:15
            exe_operand_r[7:0] <= exe_fetch_data_r[15:8];

            if (dec_data[16] | exe_dec_imm16 | (exe_fetch_addr_r[0] & dec_data[15])) begin
              // 3,4 bytes or 2 misaligned bytes

              // fetch the remainder of the instruction
              exe_fetch_addr_r[15:0] <= {exe_fetch_addr_r[15:1] + 1,1'b0};
              // this represents the next total byte size we are going to get (e.g., 3 or 4)
              exe_fetch_size_r        <= {1'b0,~exe_fetch_addr_r[0]};

              exe_prefetch_val_r     <= 0;

              EXE_STATE <= ST_EXE_FETCH;
            end
            else begin
              // 1 byte or 2 aligned bytes

              // prefetch is valid if aligned 1 byte
              exe_prefetch_val_r <= ~exe_fetch_addr_r[0] && (dec_data[`DEC_SIZE] == `SZE_1);
              exe_prefetch_r     <= exe_fetch_data_r[15:8];

              EXE_STATE <= ST_EXE_ADDRESS;
            end
          end
          else begin
            // remaining bytes
            // we get here for 2 misaligned 3 aligned (2 valid) or misaligned (1 valid) bytes.

            case (exe_fetch_size_r)
              // have 1 byte
              `SZE_1: exe_operand_r[15:0]  <= exe_fetch_data_r[15:0];
              // have 2 bytes
              `SZE_2: exe_operand_r[23:8]  <= exe_fetch_data_r[15:0];
              // have 3 bytes
              `SZE_3: exe_operand_r[23:16] <= exe_fetch_data_r[7:0];
              // have 4 bytes.  not possible
              `SZE_4: exe_operand_r[23:0]  <= 24'hBADBAD;
            endcase

            // the only case where this matters is 3->5 bytes
            exe_fetch_size_r[1] <= ~exe_fetch_size_r[1];

            if (&exe_opsize_r && (exe_fetch_size_r == `SZE_1)) begin
              // 1->3 (need 4)
              // continue with aligned fetch.  must already be aligned
              exe_fetch_addr_r[15:0] <= {exe_fetch_addr_r[15:1] + 1,1'b0};

              exe_prefetch_val_r <= 0;

              EXE_STATE <= ST_EXE_FETCH;
            end
            else begin
              // fetch is complete.  1->2, 1->3, 2->3, 2->4, 3->4

              // check if prefetch available (overfetch)
              exe_prefetch_val_r <= exe_fetch_size_r[0] ^ exe_opsize_r[0];
              exe_prefetch_r     <= exe_fetch_data_r[15:8];

              EXE_STATE <= ST_EXE_ADDRESS;
            end
          end
`else
          // handle 1 byte at a time
          exe_fetch_size_r <= exe_fetch_size_r + 1;
          exe_fetch_addr_r <= exe_fetch_addr_r + 1;

          case (exe_fetch_size_r)
            `SZE_1: begin end
            `SZE_2: exe_operand_r[7 : 0] <= exe_prefetch_val_r ? exe_prefetch_r : exe_fetch_data_r[7:0];
            `SZE_3: exe_operand_r[15: 8] <= exe_prefetch_val_r ? exe_prefetch_r : exe_fetch_data_r[7:0];
            `SZE_4: exe_operand_r[23:16] <= exe_prefetch_val_r ? exe_prefetch_r : exe_fetch_data_r[7:0];
          endcase

          // TODO: the memory controller actually returns 2 sequential bytes independent of source, but we still want to force alignment.
          exe_prefetch_val_r <= ~exe_prefetch_val_r & (~exe_fetch_addr_r[0] | ~`IS_ROM(exe_fetch_addr_r));
          exe_prefetch_r     <= exe_fetch_data_r[15:8];

          EXE_STATE <= ~|exe_opsize_r ? (~|dec_data[`DEC_SIZE] ? ST_EXE_ADDRESS : ST_EXE_FETCH) : (exe_fetch_size_r == exe_opsize_r ? ST_EXE_ADDRESS : ST_EXE_FETCH);
`endif

        end
      end

      // ADDRESSING MODE
      ST_EXE_ADDRESS: begin
        e2c_waitcnt_r <= 0;

        exe_mmc_rd_r         <= exe_dec_add_indirect;
        exe_mmc_long_r       <= exe_dec_add_long;
        exe_mmc_byte_total_r <= {exe_dec_add_long,~exe_dec_add_long};
        exe_mmc_dpe_r        <= 0;

        exe_dst_r <= REG[exe_dec_dst];
        exe_src_r <= REG[exe_dec_src];

        add_result = {1'b0,exe_operand_r[15:0]} + {1'b0,exe_mod_r};

        case (exe_dec_add_bank)
          `BNK_PBR: exe_addr_r[23:16] <= PBR_r;
          `BNK_DBR: exe_addr_r[23:16] <= DBR_r + add_result[16]; // this covers the 3 types: Absolute, AbsoluteIndexedX, AbsoluteIndexedY.  Always in the form operand[15:0] + 0/X/Y
          `BNK_ZRO: exe_addr_r[23:16] <= 8'h00;
          `BNK_O24: exe_addr_r[23:16] <= exe_operand_r[23:16] + (exe_dec_add_mod == `MOD_X16 ? add_result[16] : 0); // need to carry address into upper bits for AbsoluteLongIndexedX
        endcase

        case (exe_dec_add_base)
          `ADD_O16: exe_addr_r[15:0] <= add_result[15:0]; //exe_operand_r[15:0]                                            + exe_mod_r;
          `ADD_DPR: exe_addr_r[15:0] <= D_r + {8'h00,exe_operand_r[7:0]}                               + exe_mod_r;
          `ADD_PCR: exe_addr_r[15:0] <= exe_nextpc_addr_r + {(exe_dec_add_long ? exe_operand_r[15:8] : {8{exe_operand_r[7]}}),exe_operand_r[7:0]} + exe_mod_r;
          `ADD_SPL: exe_addr_r[15:0] <= S_r + 1                                                        + exe_mod_r;
          `ADD_SMI: exe_addr_r[15:0] <= S_r - exe_data_word_r                                          + exe_mod_r;
          `ADD_SPR: exe_addr_r[15:0] <= S_r + {8'h00,exe_operand_r[7:0]}                               + exe_mod_r;
        endcase

        // initialize the operand data as the immediate field.
        exe_data_r[15:0] <= exe_dec_add_imm ? exe_operand_r[15:0] : REGS[exe_dec_src];

        exe_add_post_r <= (exe_dec_add_mod == `MOD_YPT ? Y_r[15:0] : 0);
        exe_dst_p_r <= exe_dec_dst == `REG_P;

        exe_nextpc_r <= exe_nextpc_addr_r;

        EXE_STATE <= exe_dec_add_indirect ? ST_EXE_ADDRESS_END : ST_EXE_EXECUTE;
      end
      ST_EXE_ADDRESS_END: begin
        if (mmc_exe_end) begin
          exe_mmc_rd_r <= 0;
          // [3:2] catches the two JMP/JSR indirects which use PBR.  All other indirects are long (full 24b address) or use DBR.
          add_result = {1'b0,exe_mmc_rddata[15:0]} + {1'b0,exe_add_post_r};

          exe_addr_r[23:16] <= exe_dec_add_long ? (exe_mmc_rddata[23:16] + add_result[16]) : (&exe_opcode_r[3:2]) ? PBR_r : DBR_r;
          exe_addr_r[15:0]  <= add_result[15:0];

          EXE_STATE <= ST_EXE_EXECUTE;
        end
      end

      // EXECUTE
      ST_EXE_EXECUTE: begin
        e2c_waitcnt_r <= 0;

        // generic handler for load/store
        if (exe_load_r | exe_store_r) begin
          exe_mmc_rd_r   <=  exe_load_r;
          exe_mmc_wr_r   <= ~exe_load_r;
          exe_mmc_addr_r <= exe_addr_r;
          exe_mmc_byte_total_r <= exe_data_word_r;
          EXE_STATE <= ST_EXE_EXECUTE_END;
        end
        else begin
          EXE_STATE <= ST_EXE_WAIT;
        end

        // save target address since it will be overwritten by JSL/JSR
        exe_target_r <= exe_addr_r;

        case (exe_dec_grp)
          `GRP_PRI: begin
            // TODO: deal with D bit
            exe_result[16] = 0;
            case (exe_opcode_r[7:5])
              0: exe_result[15:0] = exe_src_r | exe_data_r; // ORA
              1: exe_result[15:0] = exe_src_r & exe_data_r; // AND
              2: exe_result[15:0] = exe_src_r ^ exe_data_r; // EOR
              3: begin
`ifdef BCD_ENABLE
                if (P_r[`P_D]) begin
                  if (~exe_load_r) begin
                    exe_bcd_val_r <= |bcd_cnt_r & ~bcd_done_r;

                    if (~bcd_done_r) begin
                      // wait on bcd state machine if not done
                      exe_mmc_wr_r <= 0;
                      EXE_STATE <= ST_EXE_EXECUTE;
                    end
                  end

                  // NOTE: this won't set the overflow flag properly
                  exe_result[16:0] = exe_data_word_r ? {bcd_c_r[3],bcd_o_r[15:0]} : {8'h00,bcd_c_r[1],bcd_o_r[7:0]};
                end
                else
`endif
                  exe_result[16:0] = exe_data_word_r ? {1'b0,exe_src_r[15:0]} + {1'b0,exe_data_r[15:0]} + P_r[`P_C] : {9'h000,exe_src_r[7:0]} + {9'h000,exe_data_r[7:0]} + P_r[`P_C]; // ADC
              end
              //4: // STA
              5: exe_result[15:0] = exe_data_r; // LDA
              //6: // CMP
              //7: exe_result[16:0] = exe_data_word_r ? {1'b0,exe_src_r[15:0]} + ~{1'b0,exe_data_r[15:0]} + P_r[`P_C] : {9'h000,exe_src_r[7:0]} + ~{9'h000,exe_data_r[7:0]} + P_r[`P_C];// SBC
              7: exe_result[16:0] = exe_data_word_r ? {1'b0,exe_src_r[15:0]} + {1'b0,~exe_data_r[15:0]} + P_r[`P_C] : {9'h000,exe_src_r[7:0]} + {9'h000,~exe_data_r[7:0]} + P_r[`P_C];// SBC
              //default: exe_result[15:0] = 0;
            endcase

            exe_a_r <= {exe_data_word_r ? exe_result[15:8] : exe_src_r[15:8], exe_result[7:0]};
            exe_p_r[`P_N] <= exe_data_word_r ? exe_result[15]     : exe_result[7];
            exe_p_r[`P_Z] <= exe_data_word_r ? ~|exe_result[15:0] : ~|exe_result[7:0];

            if (&exe_opcode_r[6:5]) begin
              // input data gets inverted for SBC
              exe_p_r[`P_V] <= exe_data_word_r ? (~(exe_src_r[15] ^ exe_opcode_r[7] ^ exe_data_r[15]) & (exe_src_r[15] ^ exe_result[15])) : (~(exe_src_r[7] ^ exe_opcode_r[7] ^ exe_data_r[7]) & (exe_src_r[7] ^ exe_result[7]));
              exe_p_r[`P_C] <= exe_data_word_r ? exe_result[16] : exe_result[8];
            end
          end
          `GRP_RMW: begin
            exe_result[16] = 0;
            case (exe_opcode_r[7:5])
              0: exe_result[16:0] = {exe_data_r[15:0],1'b0}; // ASL
              1: exe_result[16:0] = {exe_data_r[15:0],P_r[`P_C]}; // ROL
              2: exe_result[16:0] = exe_data_word_r ? {exe_data_r[0],1'b0,exe_data_r[15:1]}         : {8'h00,exe_data_r[0],1'b0,exe_data_r[7:1]}; // LSR
              3: exe_result[16:0] = exe_data_word_r ? {exe_data_r[0],P_r[`P_C],exe_data_r[15:1]}    : {8'h00,exe_data_r[0],P_r[`P_C],exe_data_r[7:1]}; // ROR
              //4: // STX,STY
              //5: // -
              6: exe_result[15:0] = exe_data_word_r ? (exe_data_r[15:0]-1) : (exe_data_r[7:0]-1); // DEC
              7: exe_result[15:0] = exe_data_word_r ? (exe_data_r[15:0]+1) : (exe_data_r[7:0]+1); // INC
              default: exe_result[15:0] = 0;
            endcase

            if (~exe_store_r) begin
              exe_a_r <= {exe_data_word_r ? exe_result[15:8] : exe_src_r[15:8], exe_result[7:0]};
            end

            // data for store
            exe_mmc_data_r[15:0] <= exe_result[15:0];

            exe_p_r[`P_N] <= exe_data_word_r ? exe_result[15]     : exe_result[7];
            exe_p_r[`P_Z] <= exe_data_word_r ? ~|exe_result[15:0] : ~|exe_result[7:0];
            if (~exe_opcode_r[7]) begin
              exe_p_r[`P_C] <= exe_data_word_r ? exe_result[16] : exe_result[8];
            end
          end
          `GRP_CBR: begin
            exe_control_r <= exe_dec_src[2] ? ~P_r[{{2{exe_dec_src[1]}},exe_dec_src[0]}] : P_r[{{2{exe_dec_src[1]}},exe_dec_src[0]}];
          end
          `GRP_JMP: begin
            if (exe_dec_add_stk) begin
              // stack
              if (exe_store_r) begin
                // JSR,JSL
                exe_mmc_addr_r <= {8'h00,(S_r - {exe_dec_add_long,~exe_dec_add_long})};
                exe_mmc_data_r[23:16] <= PBR_r;
                exe_mmc_data_r[15:0] <= exe_nextpc_r - 1;
                exe_mmc_byte_total_r <= {exe_dec_add_long,~exe_dec_add_long};
                exe_s_r <= S_r - {1'b1,exe_dec_add_long};
              end
              else begin
                // RTS,RTL
                exe_mmc_byte_total_r <= {exe_dec_add_long,~exe_dec_add_long};
                exe_s_r <= S_r + {1'b1,exe_dec_add_long};
                exe_target_r[23:16] <= exe_dec_add_long ? exe_data_r[23:16] : PBR_r;
                exe_target_r[15:0] <= exe_data_r[15:0] + 1;
              end
            end
          end
          `GRP_PHS: begin
            exe_mmc_data_r[15:0] <= exe_data_r[15:0];

            if (exe_dec_add_stk) exe_s_r <= S_r - (exe_data_word_r ? 2 : 1);

            EXE_STATE <= ST_EXE_EXECUTE_END;
          end
          `GRP_PLL: begin
            case (exe_dec_dst)
              //`REG_Z: if (P_r[`P_M]) exe_a_r[7:0] <= 0;               else exe_a_r[15:0] <= 0;
              `REG_A: if (exe_data_word_r) exe_a_r[15:0] <= exe_data_r[15:0]; else exe_a_r[7:0] <= exe_data_r[7:0];
              `REG_X: if (exe_data_word_r) exe_x_r[15:0] <= exe_data_r[15:0]; else exe_x_r[7:0] <= exe_data_r[7:0];
              `REG_Y: if (exe_data_word_r) exe_y_r[15:0] <= exe_data_r[15:0]; else exe_y_r[7:0] <= exe_data_r[7:0];
              `REG_S: exe_s_r <= exe_data_r[15:0];
              `REG_D: exe_d_r <= exe_data_r[15:0];
              `REG_B: exe_dbr_r <= exe_data_r[7:0];
              `REG_P: exe_p_r <= {exe_data_r[7:6],exe_data_r[5:4]|{2{E_r}},exe_data_r[3:0]};
              default: begin end
            endcase

            if (~exe_dst_p_r) begin
              exe_p_r[`P_N] <= exe_data_word_r ? exe_data_r[15]      : exe_data_r[7];
              exe_p_r[`P_Z] <= exe_data_word_r ? ~|exe_data_r[15:0] : ~|exe_data_r[7:0];
            end
            else if (exe_data_r[`P_X] | E_r) begin
              exe_x_r[15:8] <= 0;
              exe_y_r[15:8] <= 0;
            end

            if (exe_dec_add_stk) exe_s_r <= S_r + (exe_data_word_r ? 2 : 1);
          end
          `GRP_CMP: begin
            if (~exe_opcode_r[6]) begin
              // BIT
              exe_result = exe_dst_r & exe_data_r;

              // BIT with immediate operand doesn't set N or V
              if (~exe_dec_add_imm) begin
                exe_p_r[`P_V] <= exe_data_word_r ? exe_data_r[14]      : exe_data_r[6];
                exe_p_r[`P_N] <= exe_data_word_r ? exe_data_r[15]      : exe_data_r[7];
              end

              exe_p_r[`P_Z] <= exe_data_word_r ? ~|exe_result[15:0] : ~|exe_result[7:0];
            end
            else begin
              // CMP, CPX, CPY
              if (exe_data_word_r) exe_result[16:0] = {1'b0,exe_dst_r[15:0]} - {1'b0,exe_data_r[15:0]};
              else                 exe_result[8:0]  = {1'b0,exe_dst_r[7:0]}  - {1'b0,exe_data_r[7:0]};

              exe_p_r[`P_N] <= exe_data_word_r ? exe_result[15]     : exe_result[7];
              exe_p_r[`P_Z] <= exe_data_word_r ? ~|exe_result[15:0] : ~|exe_result[7:0];
              exe_p_r[`P_C] <= exe_data_word_r ? ~exe_result[16]    : ~exe_result[8];
            end
          end
          `GRP_STS: begin
            if (exe_opcode_r[1]) begin
              if (exe_opcode_r[5]) begin
                // SEP
                exe_p_r <= exe_p_r | exe_operand_r[7:0];

                if (P_r[`P_X] | exe_operand_r[`P_X]) begin
                  exe_x_r[15:8] <= 0;
                  exe_y_r[15:8] <= 0;
                end
              end
              else begin
                // REP
                exe_p_r <= exe_p_r & {~exe_operand_r[7:6],(~exe_operand_r[5:4])|{2{E_r}},~exe_operand_r[3:0]};
              end
            end
            else begin
              case (exe_opcode_r[7:6])
                0: exe_p_r[`P_C] <= exe_opcode_r[5];
                1: exe_p_r[`P_I] <= exe_opcode_r[5];
                2: exe_p_r[`P_V] <= 0; // SEV does not exist and won't match with STS
                3: exe_p_r[`P_D] <= exe_opcode_r[5];
              endcase
            end
          end
          `GRP_MOV: begin
            // TODO: apply correct latency
            exe_dbr_r <= exe_operand_r[7:0];

            if (exe_load_r) begin
              exe_mmc_addr_r <= {exe_operand_r[15:8], exe_src_r[15:0]};
            end
            else begin
              exe_mmc_addr_r <= {exe_operand_r[7:0],  exe_dst_r[15:0]};
            end

            // TODO: change this to use exe_data_word_r
            if (P_r[`P_X]) begin
              exe_x_r[7:0] <= exe_src_r[7:0] + (exe_opcode_r[4] ? 1 : -1);
              exe_y_r[7:0] <= exe_dst_r[7:0] + (exe_opcode_r[4] ? 1 : -1);
            end
            else begin
              exe_x_r[15:0] <= exe_src_r[15:0] + (exe_opcode_r[4] ? 1 : -1);
              exe_y_r[15:0] <= exe_dst_r[15:0] + (exe_opcode_r[4] ? 1 : -1);
            end
            exe_a_r             <= A_r - 1;
            exe_control_r       <= |A_r;
            exe_target_r        <= {PBR_r,PC_r};

            exe_mmc_data_r[7:0] <= exe_data_r[7:0];

`ifdef EXE_FAST_MOVE
            // someone could have the mov perform self modifying code on itself and break this.  could qualify it as rom address to fix that.
            exe_move_val_r      <= |A_r & `IS_ROM(exe_fetch_addr_r); // assume that if last byte was in rom the whole thing was in rom
`endif

            // END takes care of exit
            EXE_STATE <= ST_EXE_EXECUTE_END;
          end
          `GRP_TXR: begin
            exe_result[15:0] = {exe_data_word_r ? exe_src_r[15:8] : exe_dst_r[15:8], exe_src_r[7:0]};

            // register output
            case (exe_dec_dst)
              `REG_A: exe_a_r[15:0] <= exe_result[15:0];
              `REG_X: exe_x_r[15:0] <= exe_result[15:0];
              `REG_Y: exe_y_r[15:0] <= exe_result[15:0];
              `REG_S: exe_s_r[15:0] <= {E_r ? 8'h01 : exe_result[15:8],exe_result[7:0]};
              `REG_D: exe_d_r[15:0] <= exe_result[15:0];
            endcase

            // condition codes
            if (exe_dec_dst != `REG_S) begin
              exe_p_r[`P_N] <= exe_data_word_r ? exe_result[15]     : exe_result[7];
              exe_p_r[`P_Z] <= exe_data_word_r ? ~|exe_result[15:0] : ~|exe_result[7:0];
            end
          end
          `GRP_SMP: begin
            if (~exe_data_word_r) begin
              exe_result[7:0] = ((exe_opcode_r[4] & ~exe_opcode_r[5]) | (~exe_opcode_r[4] & (exe_opcode_r[6] ^ exe_opcode_r[1]))) ? exe_src_r[7:0] + 1 : exe_src_r[7:0] - 1;

              // register output
              if      (exe_opcode_r[4])                   exe_a_r[7:0]  <= exe_result[7:0];
              else if (exe_opcode_r[5] ^ exe_opcode_r[1]) exe_x_r[7:0]  <= exe_result[7:0];
              else                                        exe_y_r[7:0]  <= exe_result[7:0];

              // condition codes
              exe_p_r[`P_N] <= exe_result[7];
              exe_p_r[`P_Z] <= ~|exe_result[7:0];
            end
            else begin
              exe_result[15:0] = ((exe_opcode_r[4] & ~exe_opcode_r[5]) | (~exe_opcode_r[4] & (exe_opcode_r[6] ^ exe_opcode_r[1]))) ? exe_src_r[15:0] + 1 :  (exe_src_r[15:0] - 1);

              // register output
              if      (exe_opcode_r[4])                   exe_a_r[15:0] <= exe_result[15:0];
              else if (exe_opcode_r[5] ^ exe_opcode_r[1]) exe_x_r[15:0] <= exe_result[15:0];
              else                                        exe_y_r[15:0] <= exe_result[15:0];

              // condition codes
              exe_p_r[`P_N] <= exe_result[15];
              exe_p_r[`P_Z] <= ~|exe_result[15:0];
            end
          end
          `GRP_SPC: begin
            // BRK, COP, STP, WAI, RTI

            if (exe_opcode_r[7]^exe_opcode_r[6]) begin
              // RTI
              exe_target_r <= {(E_r ? exe_pbr_r : exe_data_r[31:24]),exe_data_r[23:8]};
              exe_p_r      <= exe_data_r[7:0];
              exe_s_r <= S_r + {~E_r,E_r,E_r};

              exe_mmc_byte_total_r <= {1'b1,~E_r};

              if (exe_data_r[`P_X]) begin
                exe_x_r[15:8] <= 0;
                exe_y_r[15:8] <= 0;
              end
            end
            else if (exe_opcode_r[6]) begin
              // STP,WAI
              exe_active_r <= ~exe_opcode_r[4];
            end
            else begin
              // COP/BRK
              if (exe_load_r) begin
                // interrupt will read BRK vector from memory
                exe_mmc_addr_r <= {16'h00FF,3'h7,E_r,E_r,1'b1,~exe_opcode_r[1],1'b0};
              end
              else begin
                if (~int_pending_r) exe_target_r <= {8'h00,exe_data_r[15:0]};
                else                exe_target_r <= {8'h00,int_vector_r};
                exe_s_r <= S_r - {~E_r,E_r,E_r};
                exe_p_r[`P_I] <= 1;
                exe_p_r[`P_D] <= 0;

                exe_mmc_addr_r <= {8'h00,S_r - {1'b1,~E_r}};
                exe_mmc_data_r <= {PBR_r,(int_pending_r ? PC_r[15:0] : exe_nextpc_r[15:0]),P_r};
                exe_mmc_byte_total_r <= {1'b1,~E_r};
              end
            end
          end
          `GRP_STK: begin
            // PEA, PER, PEI
            // non-indirect will store data at stack address
            // indirect will first load, return here, and update data to be stored

            // need to update the address for PEI.  The others already have the correct address.
            if (~exe_load_r) exe_mmc_addr_r <= {8'h00,S_r-1};
            exe_mmc_data_r[15:0] <= exe_opcode_r[1] ? (exe_nextpc_r[15:0] + exe_operand_r[15:0]) : exe_opcode_r[5] ? exe_operand_r[15:0] : exe_data_r[15:0];

            exe_s_r <= S_r - 2;
          end
          `GRP_XCH: begin
            if (exe_opcode_r[4]) begin
              exe_p_r[`P_C] <= E_r;
              exe_e_r       <= P_r[`P_C];

              if (P_r[`P_C]) begin
                exe_p_r[`P_M] <= 1;
                exe_p_r[`P_X] <= 1;
                exe_x_r[15:8] <= 0;
                exe_y_r[15:8] <= 0;
              end
            end
            else begin
              exe_result[15:0] = {exe_src_r[7:0],exe_src_r[15:8]};

              // register output
              exe_a_r[15:0] <= exe_result[15:0];
              // condition codes
              exe_p_r[`P_N] <= exe_result[7];
              exe_p_r[`P_Z] <= ~|exe_result[7:0];
            end
          end
          `GRP_TST: begin
            case (exe_opcode_r[4])
              0: exe_result = exe_data_r[15:0] | exe_src_r[15:0];
              1: exe_result = exe_data_r[15:0] & ~exe_src_r[15:0];
            endcase

            exe_mmc_data_r[15:0] <= exe_result[15:0];
            // TSB/TRB are unique in that the Z flag is only set based on the logical and of the memory location and A
            exe_p_r[`P_Z] <= exe_data_word_r ? ~|(exe_data_r[15:0] & exe_src_r[15:0]) : ~|(exe_data_r[7:0] & exe_src_r[7:0]);
          end
        endcase

      end
      ST_EXE_EXECUTE_END: begin
        e2c_waitcnt_r <= 0;

        if (mmc_exe_end) begin
          exe_mmc_rd_r <= 0;
          exe_mmc_wr_r <= 0;
          exe_load_r <= 0;
          if (exe_load_r) exe_data_r <= exe_mmc_rddata;

          // return to EXECUTE if there are still work to do
          EXE_STATE <= exe_load_r ? ST_EXE_EXECUTE : ST_EXE_WAIT;
        end
      end
      ST_EXE_WAIT: begin
        e2c_waitcnt_r <= 0;

        if (pipeline_advance) begin
          {PBR_r,PC_r}     <= exe_control_r ? exe_target_r : {exe_pbr_r,exe_nextpc_r};
          exe_fetch_addr_r <= exe_control_r ? exe_target_r : {exe_pbr_r,exe_nextpc_r};
          exe_fetch_size_r <= 0;
          exe_mmc_byte_total_r <= 1;

          // will be assigned properly on fast move
          exe_opsize_r  <= 0;

          // TODO: resetting the following is really only useful debug.
          exe_mmc_long_r <= 0;
          exe_mmc_dpe_r <= 0;
          if (~exe_move_val_r) begin
            exe_opcode_r  <= 0;
            exe_operand_r <= 0;
          end

          // invalidate the prefetch on a taken control instruction
          if (exe_control_r) exe_prefetch_val_r <= 0;

          // write register state
          A_r           <= exe_a_r;
          X_r           <= exe_x_r;
          Y_r           <= exe_y_r;
          S_r           <= exe_s_r;
          D_r           <= exe_d_r;
          DBR_r         <= exe_dbr_r;
          P_r           <= exe_p_r;
          E_r           <= exe_e_r;

          // reset internal PCs to help with debugging
          exe_nextpc_r   <= 0;

          EXE_STATE <= (exe_active_r & ~CCNT_r[`CCNT_SA1_RESB]) ? ST_EXE_FETCH : ST_EXE_IDLE;
        end
      end
    endcase
  end
end

assign     int_wai = (exe_opcode_r == 8'hCB);
assign     exe_mmc_addr = EXE_STATE[clog2(ST_EXE_FETCH_END)] ? exe_fetch_addr_r : EXE_STATE[clog2(ST_EXE_ADDRESS_END)] ? exe_addr_r : exe_mmc_addr_r;
assign     exe_fetch_byte_val = exe_prefetch_val_r;
assign     exe_fetch_move     = exe_move_val_r;
assign     exe_fetch_byte     = exe_prefetch_r;
assign     exe_fetch_data     = exe_fetch_data_r[7:0];

`ifdef DEBUG
// breakpoints
reg      brk_inst_rd_rom_m1;
reg      brk_inst_rd_ram_m1;
reg      brk_data_rd_rom_m1;
reg      brk_data_rd_ram_m1;
reg      brk_data_wr_ram_m1;

reg [23:0] brk_addr_r;

always @(posedge CLK) begin
  if (RST) begin
    brk_inst_rd_rom_m1 <= 0;
    brk_inst_rd_ram_m1 <= 0;
    brk_data_rd_rom_m1 <= 0;
    brk_data_rd_ram_m1 <= 0;
    brk_data_wr_ram_m1 <= 0;

    brk_inst_rd_byte <= 0;
    brk_data_rd_byte <= 0;
    brk_data_wr_byte <= 0;

    brk_inst_rd_addr <= 0;
    brk_data_rd_addr <= 0;
    brk_data_wr_addr <= 0;
    brk_stop         <= 0;
    brk_error        <= 0;

    brk_addr_r       <= 0;
  end
  else begin
    //brk_inst_rd_rom_m1 <= (|(ROM_STATE & ST_ROM_FETCH_RD)) && !rom_bus_rrq_r && ROM_BUS_RDY;
    //brk_inst_rd_ram_m1 <= (|(RAM_STATE & ST_RAM_FETCH_RD)) && !ram_bus_rrq_r && RAM_BUS_RDY;
    //brk_data_rd_rom_m1 <= (|(ROM_STATE & ST_ROM_DATA_RD)) && !rom_bus_rrq_r && ROM_BUS_RDY;
    //brk_data_rd_ram_m1 <= (|(RAM_STATE & ST_RAM_DATA_RD)) && !ram_bus_rrq_r && RAM_BUS_RDY;
    //brk_data_wr_ram_m1 <= (|(RAM_STATE & ST_RAM_DATA_WR)) && !ram_bus_wrq_r && RAM_BUS_RDY;

    //brk_inst_rd_byte <= pipeline_advance ? 0 : brk_inst_rd_rom_m1 ? (rom_bus_data_r == CONFIG_DATA_WATCH) : brk_inst_rd_ram_m1 ? (ram_bus_data_r == CONFIG_DATA_WATCH) : brk_inst_rd_byte;
    //brk_data_rd_byte <= pipeline_advance ? 0 : brk_data_rd_rom_m1 ? (rom_bus_data_r == CONFIG_DATA_WATCH) : brk_data_rd_ram_m1 ? (ram_bus_data_r == CONFIG_DATA_WATCH) : brk_data_rd_byte;
    //brk_data_wr_byte <= pipeline_advance ? 0                                                              : brk_data_wr_ram_m1 ? (RAMWRBUF_r     == CONFIG_DATA_WATCH) : brk_data_wr_byte;

    brk_inst_rd_addr <= (debug_inst_addr_r == brk_addr_r);
    brk_data_rd_addr <= EXE_STATE[clog2(ST_EXE_EXECUTE_END)] && (exe_mmc_addr_r == brk_addr_r) && exe_mmc_rd_r && (!config_r[2][0] ||     mmc_data_r[7:0] == CONFIG_DATA_WATCH);
    brk_data_wr_addr <= EXE_STATE[clog2(ST_EXE_EXECUTE_END)] && (exe_mmc_addr_r == brk_addr_r) && exe_mmc_wr_r && (!config_r[2][0] || exe_mmc_data_r[7:0] == CONFIG_DATA_WATCH);
    brk_stop         <= EXE_STATE[clog2(ST_EXE_EXECUTE)] && (exe_opcode_r == 8'hDB || exe_opcode_r == 8'hCB || int_pending_r);
    brk_error        <= EXE_STATE[clog2(ST_EXE_EXECUTE)] && (exe_opcode_r == 8'h00);

    brk_addr_r <= CONFIG_ADDR_WATCH[23:0];
  end
end
`endif

// performance counter
reg cycle_wait_r;
reg dma_active_r;

always @(posedge CLK) begin
  dma_active_r <= dma_cc1_active_r | dma_normal_pri_active_r | vbd_active_r;

`ifdef DEBUG
  if (sa1_clock_en & ~|exe_waitcnt_r & EXE_STATE[clog2(ST_EXE_WAIT)] & ~step_r) cycle_wait_r <= 1;
  else if (pipeline_advance) cycle_wait_r <= 0;

  if (RST) begin
    sa1_cycle_cnt_r <= 0;
  end
  else if ((~EXE_STATE[clog2(ST_EXE_WAIT)] | ~cycle_wait_r) & ~EXE_STATE[clog2(ST_EXE_IDLE)]) begin
    sa1_cycle_cnt_r <= sa1_cycle_cnt_r + 1;
  end
`endif
end

assign pipeline_advance = sa1_clock_en & ~|exe_waitcnt_r & EXE_STATE[clog2(ST_EXE_WAIT)] & step_r & ~dma_active_r & ~WAI_r;

//-------------------------------------------------------------------
// DEBUG OUTPUT
//-------------------------------------------------------------------
`ifdef DEBUG
wire [7:0] dbg_reg_dout;

dbg_state state (
  .clka(CLK), // input clka
  //.wea(~addr_in_r[7] & SNES_WR_end & `IS_MMIO(addr_in_r)), // input [0 : 0] wea
  //.addra(addr_in_r[6:0]), // input [6 : 0] addra
  //.dina(data_in_r), // input [7 : 0] dina
  .wea(~|snes_writebuf_addr_r[8:7] & snes_writebuf_val_r), // input [0 : 0] wea
  .addra(snes_writebuf_addr_r[6:0]), // input [6 : 0] addra
  .dina(snes_writebuf_data_r), // input [7 : 0] dina

  .clkb(CLK), // input clkb
  .addrb(pgm_addr_r[6:0]), // input [6 : 0] addrb
  .doutb(dbg_reg_dout) // output [7 : 0] doutb
);

reg [7:0]  pgmpre_out[3:0];
reg [7:0]  pgmdata_out; //initial pgmdata_out_r = 0;

always @(posedge CLK) begin
  if      (~pgm_addr_r[11])                              pgmdata_out <= pgmpre_out[pgm_addr_r[9:8]];
`ifdef DEBUG_IRAM
  else if (~snes_writebuf_iram_r & ~snes_readbuf_iram_r) pgmdata_out <= snes_iram_dout;
`endif

  if (~pgm_addr_r[11]) begin
    case (pgm_addr_r[9:8])
      2'h0: case (pgm_addr_r[7:0])
        // 00-7F MMIO
        ADDR_CCNT  ,
        ADDR_SIE   ,
        ADDR_SIC   ,
        ADDR_CRV   ,
        ADDR_CRV+1 ,
        ADDR_CNV   ,
        ADDR_CNV+1 ,
        ADDR_CIV   ,
        ADDR_CIV+1 ,
        ADDR_SCNT  ,
        ADDR_CIE   ,
        ADDR_CIC   ,
        ADDR_SNV   ,
        ADDR_SNV+1 ,
        ADDR_SIV   ,
        ADDR_SIV+1 ,

`ifdef DEBUG_MMIO
        ADDR_TMC   ,
        ADDR_CTR   ,
        ADDR_HCNT  ,
        ADDR_HCNT+1,
        ADDR_VCNT  ,
        ADDR_VCNT+1,
        ADDR_CXB   ,
        ADDR_DXB   ,
        ADDR_EXB   ,
        ADDR_FXB   ,
        ADDR_BMAPS ,
        ADDR_BMAP  ,
        ADDR_SWBE  ,
        ADDR_CWBE  ,
        ADDR_BWPA  ,
        ADDR_SIWP  ,
        ADDR_CIWP  ,
        ADDR_DCNT  ,
        ADDR_CDMA  ,
        ADDR_DSA   ,
        ADDR_DSA+1 ,
        ADDR_DSA+2 ,
        ADDR_DDA   ,
        ADDR_DDA+1 ,
        ADDR_DDA+2 ,
        ADDR_DTC   ,
        ADDR_BBF   ,
        ADDR_BRF0  ,
        ADDR_BRF1  ,
        ADDR_BRF2  ,
        ADDR_BRF3  ,
        ADDR_BRF4  ,
        ADDR_BRF5  ,
        ADDR_BRF6  ,
        ADDR_BRF7  ,
        ADDR_BRF8  ,
        ADDR_BRF9  ,
        ADDR_BRFA  ,
        ADDR_BRFB  ,
        ADDR_BRFC  ,
        ADDR_BRFD  ,
        ADDR_BRFE  ,
        ADDR_BRFF  ,
        ADDR_MCNT  ,
        ADDR_MA    ,
        ADDR_MA+1  ,
        ADDR_MB    ,
        ADDR_MB+1  ,
        ADDR_VBD   ,
        ADDR_VDA   ,
        ADDR_VDA+1 ,
        ADDR_VDA+2 : pgmpre_out[0] <= dbg_reg_dout;

        8'h60+ADDR_SFR   : pgmpre_out[0] <= SFR_r;
        8'h60+ADDR_CFR   : pgmpre_out[0] <= CFR_r;
`endif

`ifdef DEBUG_EXT
        8'h60+ADDR_HCR   : pgmpre_out[0] <= HCR_r[7:0]; // $2
        8'h60+ADDR_HCR+1 : pgmpre_out[0] <= HCR_r[15:8]; // $2
        8'h60+ADDR_VCR   : pgmpre_out[0] <= VCR_r[7:0]; // $2
        8'h60+ADDR_VCR+1 : pgmpre_out[0] <= VCR_r[15:8]; // $2
        8'h60+ADDR_MR    : pgmpre_out[0] <= MR_r[7:0]; // $5
        8'h60+ADDR_MR+1  : pgmpre_out[0] <= MR_r[15:8]; // $5
        8'h60+ADDR_MR+2  : pgmpre_out[0] <= MR_r[23:16]; // $5
        8'h60+ADDR_MR+3  : pgmpre_out[0] <= MR_r[31:24]; // $5
        8'h60+ADDR_MR+4  : pgmpre_out[0] <= MR_r[39:32]; // $5
        8'h60+ADDR_OF    : pgmpre_out[0] <= OF_r;
        8'h60+ADDR_VDP   : pgmpre_out[0] <= VDP_r[7:0]; // $2
        8'h60+ADDR_VDP+1 : pgmpre_out[0] <= VDP_r[15:8]; // $2
        8'h60+ADDR_VC    : pgmpre_out[0] <= VC_r;
`endif

        // 80-9F ARCH STATE
        8'h80      : pgmpre_out[0] <= A_r[7:0];
        8'h81      : pgmpre_out[0] <= A_r[15:8];
        8'h82      : pgmpre_out[0] <= X_r[7:0];
        8'h83      : pgmpre_out[0] <= X_r[15:8];
        8'h84      : pgmpre_out[0] <= Y_r[7:0];
        8'h85      : pgmpre_out[0] <= Y_r[15:8];
        8'h86      : pgmpre_out[0] <= S_r[7:0];
        8'h87      : pgmpre_out[0] <= S_r[15:8];
        8'h88      : pgmpre_out[0] <= D_r[7:0];
        8'h89      : pgmpre_out[0] <= D_r[15:8];
        8'h8A      : pgmpre_out[0] <= PC_r[7:0];
        8'h8B      : pgmpre_out[0] <= PC_r[15:8];
        8'h8C      : pgmpre_out[0] <= PBR_r;
        8'h8D      : pgmpre_out[0] <= DBR_r;
        8'h8E      : pgmpre_out[0] <= P_r;
        8'h8F      : pgmpre_out[0] <= E_r;
        8'h90      : pgmpre_out[0] <= MDR_r;
        8'h91      : pgmpre_out[0] <= WAI_r;

`ifdef DEBUG_MMC
        // A0-BF MMC
        8'hA0           : pgmpre_out[0] <= MMC_STATE;
        8'hA1           : pgmpre_out[0] <= mmc_addr_r[7:0];
        8'hA2           : pgmpre_out[0] <= mmc_addr_r[15:8];
        8'hA3           : pgmpre_out[0] <= mmc_addr_r[23:16];
        8'hA4           : pgmpre_out[0] <= mmc_data_r[7:0];
        8'hA5           : pgmpre_out[0] <= mmc_data_r[15:8];
        8'hA6           : pgmpre_out[0] <= mmc_data_r[23:16];
        8'hA7           : pgmpre_out[0] <= mmc_data_r[31:24];
        8'hA8           : pgmpre_out[0] <= mmc_wr_r;
        8'hA9           : pgmpre_out[0] <= mmc_byte_r;
        8'hAA           : pgmpre_out[0] <= mmc_byte_total_r;
        8'hAB           : pgmpre_out[0] <= mmc_long_r;
        8'hAC           : pgmpre_out[0] <= mmc_dpe_r;
        8'hAD           : pgmpre_out[0] <= mmc_state_end_r;

//        8'hB0           : pgmpre_out[0] <= exe_mmc_rd_r;
//        8'hB1           : pgmpre_out[0] <= exe_mmc_addr_r[7:0];
//        8'hB2           : pgmpre_out[0] <= exe_mmc_addr_r[15:8];
//        8'hB3           : pgmpre_out[0] <= exe_mmc_addr_r[23:16];
//        8'hB4           : pgmpre_out[0] <= exe_mmc_data_r[7:0];
//        8'hB5           : pgmpre_out[0] <= exe_mmc_data_r[15:8];
//        8'hB6           : pgmpre_out[0] <= exe_mmc_data_r[23:16];
//        8'hB7           : pgmpre_out[0] <= exe_mmc_data_r[31:24];
//        8'hB8           : pgmpre_out[0] <= exe_mmc_wr_r;
//        8'hB9           : pgmpre_out[0] <= exe_mmc_long_r;
//        8'hBA           : pgmpre_out[0] <= exe_mmc_byte_total_r;
`else
`ifdef DEBUG_DMA
        8'hA0           : pgmpre_out[0] <= DMA_STATE;
`ifdef DMA_ENABLE
        8'hA1           : pgmpre_out[0] <= dma_next_readstate_r;
        8'hA2           : pgmpre_out[0] <= dma_next_writestate_r;
        8'hA3           : pgmpre_out[0] <= dma_cc1_bpp_r;
        8'hA4           : pgmpre_out[0] <= dma_cc1_bpl_r[8:1]; // 0 always 0
        8'hA5           : pgmpre_out[0] <= dma_cc1_size_mask_r;
        8'hA6           : pgmpre_out[0] <= dma_cc1_char_num_r;
        8'hA7           : pgmpre_out[0] <= dma_cc1_mask_r;
        8'hA8           : pgmpre_out[0] <= dma_cc1_imask_r;
        8'hA9           : pgmpre_out[0] <= dma_cc1_en_r;
        8'hAA           : pgmpre_out[0] <= dbg_dma_cc1_start_r;
        8'hAB           : pgmpre_out[0] <= dbg_dma_cc1_trigger_r;
        8'hAC           : pgmpre_out[0] <= dbg_dma_cc1_write_r[7:0];
        8'hAD           : pgmpre_out[0] <= dbg_dma_cc1_write_r[15:8];
        8'hAE           : pgmpre_out[0] <= dbg_dma_cc1_nonzero_write_r[7:0];
        8'hAF           : pgmpre_out[0] <= dbg_dma_cc1_nonzero_write_r[15:8];

        8'hB0           : pgmpre_out[0] <= dma_cc1_addr_rd_r[7:0];
        8'hB1           : pgmpre_out[0] <= dma_cc1_addr_rd_r[15:8];
        8'hB2           : pgmpre_out[0] <= dma_cc1_addr_rd_r[23:16];
        8'hB3           : pgmpre_out[0] <= dma_cc1_addr_wr_r[7:0];
        8'hB4           : pgmpre_out[0] <= dma_cc1_addr_wr_r[10:8];
        8'hB5           : pgmpre_out[0] <= dma_line_r;
        8'hB6           : pgmpre_out[0] <= dma_byte_r;
        8'hB7           : pgmpre_out[0] <= dma_comp_r;
`endif
`endif
`endif

        // C0-DF EXECUTE
        8'hC0           : pgmpre_out[0] <= EXE_STATE;
        8'hC1           : pgmpre_out[0] <= exe_opsize_r;
        8'hC2           : pgmpre_out[0] <= exe_opcode_r;
        8'hC3           : pgmpre_out[0] <= exe_operand_r[7:0];
        8'hC4           : pgmpre_out[0] <= exe_operand_r[15:8];
        8'hC5           : pgmpre_out[0] <= exe_operand_r[23:16];
        8'hC6           : pgmpre_out[0] <= exe_addr_r[7:0];
        8'hC7           : pgmpre_out[0] <= exe_addr_r[15:8];
        8'hC8           : pgmpre_out[0] <= exe_addr_r[23:16];
        8'hC9           : pgmpre_out[0] <= exe_data_r[7:0];
        8'hCA           : pgmpre_out[0] <= exe_data_r[15:8];
`ifdef DEBUG_EXE
        8'hCB           : pgmpre_out[0] <= exe_control_r;
        8'hCC           : pgmpre_out[0] <= exe_nextpc_r[7:0];
        8'hCD           : pgmpre_out[0] <= exe_nextpc_r[15:8];
        8'hCE           : pgmpre_out[0] <= exe_src_r[7:0];
        8'hCF           : pgmpre_out[0] <= exe_src_r[15:8];

        //8'hD0           : pgmpre_out[0] <= exe_dec_inst;
        8'hD0           : pgmpre_out[0] <= exe_dec_grp;
        8'hD1           : pgmpre_out[0] <= exe_dec_size;
        8'hD2           : pgmpre_out[0] <= exe_dec_lat;
        8'hD3           : pgmpre_out[0] <= exe_dec_prc;
        8'hD4           : pgmpre_out[0] <= exe_dec_src;
        8'hD5           : pgmpre_out[0] <= exe_dec_dst;
        8'hD6           : pgmpre_out[0] <= exe_dec_ctl;
        8'hD7           : pgmpre_out[0] <= exe_dec_add_bank;
        8'hD8           : pgmpre_out[0] <= exe_dec_add_base;
        8'hD9           : pgmpre_out[0] <= exe_dec_add_mod;
        8'hDA           : pgmpre_out[0] <= exe_dec_add_imm;
        8'hDB           : pgmpre_out[0] <= exe_dec_add_indirect;
        8'hDC           : pgmpre_out[0] <= exe_dec_add_long;
        //8'hDD           : pgmpre_out[0] <= exe_dec_add_stk;
`endif
        8'hDD           : pgmpre_out[0] <= exe_target_r[7:0];
        8'hDE           : pgmpre_out[0] <= exe_target_r[15:8];
        8'hDF           : pgmpre_out[0] <= exe_target_r[23:16];

        //8'hC5           : pgmpre_out[0] <= exe_opindex_r;

        // E0-EF ???
        8'hE0           : pgmpre_out[0] <= debug_inst_addr_prev_r[ 7: 0];
        8'hE1           : pgmpre_out[0] <= debug_inst_addr_prev_r[15: 8];
        8'hE2           : pgmpre_out[0] <= debug_inst_addr_prev_r[23:16];

        8'hF0           : pgmpre_out[0] <= config_r[0];
        8'hF1           : pgmpre_out[0] <= config_r[1];
        8'hF2           : pgmpre_out[0] <= config_r[2];
        8'hF3           : pgmpre_out[0] <= config_r[3];
        8'hF4           : pgmpre_out[0] <= config_r[4];
        8'hF5           : pgmpre_out[0] <= config_r[5];
        8'hF6           : pgmpre_out[0] <= config_r[6];
        8'hF7           : pgmpre_out[0] <= config_r[7];

        8'hF8           : pgmpre_out[0] <= stepcnt_r;
        8'hF9           : pgmpre_out[0] <= sa1_clock_en;

`ifdef DEBUG_EXT
        // big endian to make debugging easier
        8'hFA           : pgmpre_out[0] <= sa1_cycle_cnt_r[31:24];
        8'hFB           : pgmpre_out[0] <= sa1_cycle_cnt_r[23:16];
        8'hFC           : pgmpre_out[0] <= sa1_cycle_cnt_r[15: 8];
        8'hFD           : pgmpre_out[0] <= sa1_cycle_cnt_r[ 7: 0];
`endif

        default         : pgmpre_out[0] <= 8'hFF;
      endcase
      default         : pgmpre_out[pgm_addr_r[9:8]] <= 8'hFF;
    endcase
  end
end
`endif

//-------------------------------------------------------------------
// MISC OUTPUTS
//-------------------------------------------------------------------
assign DBG         = 0;
`ifdef DEBUG
assign PGM_DATA    = pgmdata_out;
`else
assign PGM_DATA    = 0;
`endif

assign DATA_ENABLE = snes_data_enable_r;
assign DATA_OUT    = snes_data_out_r;

reg cpu_irq_r; initial cpu_irq_r = 0;
always @(posedge CLK) cpu_irq_r <= (SIE_r[`SIE_DMA_IRQEN] & SFR_r[`SFR_DMA_IRQFL]) | (SIE_r[`SIE_CPU_IRQEN] & SFR_r[`SFR_CPU_IRQFL]);

assign IRQ         = cpu_irq_r;

assign BMAPS_SBM   = BMAPS_r[`BMAPS_SBM];
assign SNV         = SNV_r;
assign SIV         = SIV_r;
assign SCNT_NVSW   = SCNT_r[`SCNT_NVSW];
assign SCNT_IVSW   = SCNT_r[`SCNT_IVSW];
assign DMA_CC1_EN  = dma_cc1_en_r;
assign XXB_OUT     = {xxb[3], xxb[2], xxb[1], xxb[0]};
assign XXB_EN_OUT  = xxb_en;

endmodule

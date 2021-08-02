`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name:
// Module Name:
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
`include "config.vh"

module sgb_cpu(
  input         RST,
  input         CPU_RST,
  input         CLK,
  input         CLK_CPU_EDGE,

  // SYS out
  input         SYS_RDY,
  output        SYS_REQ,
  output        SYS_WR,
  output [15:0] SYS_ADDR,
  input  [7:0]  SYS_RDDATA,
  output [7:0]  SYS_WRDATA,

  output        BOOTROM_ACTIVE,
  output        FREE_SLOT,

  // PPU out
  output        PPU_DOT_EDGE,
  output        PPU_PIXEL_VALID,
  output [1:0]  PPU_PIXEL,
  output        PPU_VSYNC_EDGE,
  output        PPU_HSYNC_EDGE,

  // APU out
  output [19:0] APU_DAT,

  // P1
  output [1:0]  P1O,
  input  [3:0]  P1I,

  // Halt
  input         HLT_REQ,
  output        HLT_RSP,
  input         IDL_ICD,

  // Features
  input  [15:0]  FEAT,

  // State
  output        REG_REQ,
  output [7:0]  REG_ADDR,
  output [7:0]  REG_REQ_DATA,
  input  [7:0]  MBC_REG_DATA,

  // DBG
  input         MCU_RRQ,
  input         MCU_WRQ,
  input  [18:0] MCU_ADDR,
  input  [7:0]  MCU_DATA_IN,
  output        MCU_RSP,
  output [7:0]  MCU_DATA_OUT,

  output [11:0] DBG_ADDR,
  input  [7:0]  DBG_ICD2_DATA_IN,
  input  [7:0]  DBG_MBC_DATA_IN,
  input  [7:0]  DBG_CHEAT_DATA_IN,
  input  [7:0]  DBG_MAIN_DATA_IN,

  input  [8*8-1:0] DBG_CONFIG,
  output        DBG_BRK
);

integer i;

//-------------------------------------------------------------------
// DESCRIPTION
//-------------------------------------------------------------------

// This is the SGB2-CPU chip which consists of the following logic:
//
// CPU - Central Processing Unit
//   IFD - Instruction Fetch and Decode
//   EXE - Register Read, EXEcute/Memory, and Writeback
//   ICT - Interrupt ConTroller
// PPU - Pixel Processing Unit
// APU - Audio Processing Unit
// MCT - Memory ConTroller for internal (VRAM, OAM, HRAM, REG) and external state (WRAM and CART)
// DMA - DMA engine for copying data to the OAM
// SER - SERial state machine
//
// DBG - DeBuG state available for breakpoint/watchpoint

//-------------------------------------------------------------------
// MISC
//-------------------------------------------------------------------

`define APU

`define OPR_I       4'd0
`define OPR_PC      4'd1
`define OPR_S8      4'd2
`define OPR_U16     4'd3
`define OPR_BC      4'd4
`define OPR_DE      4'd5
`define OPR_SP      4'd6
`define OPR_AF      4'd7
`define OPR_B       4'd8
`define OPR_C       4'd9
`define OPR_D       4'd10
`define OPR_E       4'd11
`define OPR_H       4'd12
`define OPR_L       4'd13
`define OPR_HL      4'd14
`define OPR_A       4'd15

`define GRP_SPC     4'd0
`define GRP_MOV     4'd1
`define GRP_INC     4'd2
`define GRP_DEC     4'd3
`define GRP_ALU     4'd4
`define GRP_BIT     4'd5
`define GRP_JMP     4'd6
`define GRP____     4'd7
`define GRP_MST     4'd8
`define GRP_MLD     4'd9
`define GRP_MIC     4'd10
`define GRP_MDC     4'd11
`define GRP_MLU     4'd12
`define GRP_MBT     4'd13
`define GRP_CLL     4'd14
`define GRP_RET     4'd15

`define DEC_SZE     15:14
`define DEC_LAT     13:12
`define DEC_DST     11:8
`define DEC_SRC     7:4
`define DEC_GRP     3:0

// Forwarded signals
//
// IFD outputs
//
wire        IFD_EXE_valid;
wire [23:0] IFD_EXE_op;
wire [15:0] IFD_EXE_decode;
wire [15:0] IFD_EXE_pc_start;
wire [15:0] IFD_EXE_pc_end;
wire [15:0] IFD_EXE_pc_next;
wire        IFD_EXE_cb;
wire        IFD_EXE_new;
wire        IFD_EXE_int;
wire        IFD_MCT_req_val;
wire [15:0] IFD_MCT_req_addr_d1;
wire [7:0]  IFD_REG_ic;
//
// EXE outputs
//
wire        EXE_MCT_req_val;
wire [15:0] EXE_MCT_req_addr_d1;
wire        EXE_MCT_req_wr;
wire [7:0]  EXE_MCT_req_data_d1;

wire        EXE_IFD_redirect;
wire [15:0] EXE_IFD_target;
wire        EXE_IFD_ready;
wire        EXE_IFD_ime;

wire        EXE_DMA_halt;
wire        EXE_REG_ime;
//
// REG outputs
//
wire [7:0]  REG_data;
wire        REG_MCT_rsp_val;
wire        REG_DBG_rsp_val;
wire        REG_DMA_start;
wire        REG_req_val;
wire        REG_req_dbg;
wire [7:0]  REG_address;
wire [7:0]  REG_req_data;
//
// MCT outputs
//
wire [7:0]  MCT_data;
wire        MCT_IFD_rsp_val;
wire        MCT_EXE_rsp_val;

wire        MCT_VRAM_wren;
wire [12:0] MCT_VRAM_address;
wire [7:0]  MCT_VRAM_data;

wire        MCT_OAM_wren;
wire [7:0]  MCT_OAM_address;
wire [7:0]  MCT_OAM_data;

wire        MCT_HRAM_wren;
wire [6:0]  MCT_HRAM_address;
wire [7:0]  MCT_HRAM_data;

wire        MCT_REG_req_val;
wire        MCT_REG_wren;
wire [7:0]  MCT_REG_address;
wire [7:0]  MCT_REG_data;
//
// MCT input data
//
wire [7:0]  VRAM_data;
wire [7:0]  OAM_data;
wire [7:0]  HRAM_data;
//
// PPU outputs
//
wire        PPU_VRAM_active;
wire [12:0] PPU_VRAM_address;
wire        PPU_OAM_active;
wire [7:0]  PPU_OAM_address;
wire        PPU_REG_vblank;
wire        PPU_REG_lcd_stat;
wire        PPU_vblank;
//
// DMA outputs
//
wire        DMA_SYS_active;
wire        DMA_VRAM_active;
wire        DMA_active;

wire        DMA_req_val;
wire [15:0] DMA_address;

wire        DMA_OAM_req_val;
wire [7:0]  DMA_OAM_address;
wire [7:0]  DMA_OAM_req_data;
//
// APU outputs
//
wire [3:0]  APU_REG_enable;

wire        SER_REG_done;

wire        DBG_EXE_step;

wire        DBG_REG_req_val;
wire        DBG_REG_wren;
wire [7:0]  DBG_REG_address;
wire [7:0]  DBG_REG_data;
wire        DBG_advance;

wire        HLT_REQ_sync;
wire        HLT_IFD_rsp;
wire        HLT_EXE_rsp;
wire        HLT_DMA_rsp;
wire        HLT_SER_rsp;

assign      HLT_RSP = HLT_REQ_sync & HLT_IFD_rsp & HLT_EXE_rsp & HLT_DMA_rsp & HLT_SER_rsp;

//-------------------------------------------------------------------
// Clocks
//-------------------------------------------------------------------

// Generate a BUS clock edge from the incoming CPU clock edge.  The
// BUS clock is always /4.
reg  [1:0]  clk_bus_ctr_r; always @(posedge CLK) clk_bus_ctr_r <= RST ? 0 : clk_bus_ctr_r + (CLK_CPU_EDGE ? 1 : 0);
wire        CLK_BUS_EDGE = CLK_CPU_EDGE & &clk_bus_ctr_r;

// Synchronize reset to bus edge.  Want a full bus clock prior to first edge assertion and the system bus to be ready
reg         cpu_ireset_r; always @(posedge CLK) cpu_ireset_r <= RST | CPU_RST | (cpu_ireset_r & (~CLK_BUS_EDGE | ~SYS_RDY));

// Assume GB only needs PSRAM on the first of the 4 CPU clocks.  Each CPU clock is a minimum of 16 CLK2
// and PSRAM should only need ~8 of those clocks to perform the access.  It's possible that the GB timing
// will spill into the first free slot, but that will just remove that slot for MCU use.

// The delay needs to match the mct request pipe to the system:
// -1 - CLK_BUS_EDGE
//  0 - MCT request             dma_req_r SYS/REQ
//  1 - MCT decode              ReqPendr
//  2 - MCT mct_req_r/SYS_REQ
//  3 - ReqPendr
reg  [5:0]  cpu_free_slot_r;
always @(posedge CLK) begin
  // MCU needs more bandwidth so now we only block the last empty CPU clock cycle shifted by a value greater than the MCT delay
  cpu_free_slot_r <= {cpu_free_slot_r[4:0],(~&clk_bus_ctr_r)};
end

assign FREE_SLOT = cpu_free_slot_r[5];

reg  [1:0]  ppu_vblank_sync_r;
reg         hlt_req_sync_r;

always @(posedge CLK) begin
  if (CLK_BUS_EDGE) ppu_vblank_sync_r <= {ppu_vblank_sync_r[0],PPU_vblank};
  hlt_req_sync_r <= cpu_ireset_r ? 0 : (CLK_BUS_EDGE && ppu_vblank_sync_r == 2'b01) ? HLT_REQ : hlt_req_sync_r;
end

assign HLT_REQ_sync = hlt_req_sync_r;

//-------------------------------------------------------------------
// REG/MMIO
//-------------------------------------------------------------------

`define P1_I              3:0
`define P1_O              5:4

`define TAC_FREQ_DIV      1:0
`define TAC_ENABLE        2:2

`define LCDC_BG_EN        0:0
`define LCDC_SP_EN        1:1
`define LCDC_SP_SIZE      2:2
`define LCDC_BG_MAP_SEL   3:3
`define LCDC_BG_TILE_SEL  4:4
`define LCDC_WD_EN        5:5
`define LCDC_WD_MAP_SEL   6:6
`define LCDC_DS_EN        7:7

`define STAT_MODE         1:0
`define STAT_ACTIVE       1:1
`define STAT_LYC_MATCH    2:2
`define STAT_INT_H_EN     3:3 // mode 0
`define STAT_INT_V_EN     4:4 // mode 1
`define STAT_INT_O_EN     5:5 // mode 2
`define STAT_INT_M_EN     6:6

`define PAL0              1:0
`define PAL1              3:2
`define PAL2              5:4
`define PAL3              7:6

`define BOOT_ROM_DI       0:0

`define IE_VBLANK         0:0
`define IE_LCD_STAT       1:1
`define IE_TIMER          2:2
`define IE_SERIAL         3:3
`define IE_JOYPAD         4:4

// square1
`define NR10_SWEEP_SHIFT  2:0
`define NR10_SWEEP_NEG    3:3
`define NR10_SWEEP_TIME   6:4
`define NR11_LENGTH       5:0
`define NR11_DUTY         7:6
`define NR12_ENV_PERIOD   2:0
`define NR12_ENV_DIR      3:3
`define NR12_ENV_VOLUME   7:4
`define NR13_FREQ_LSB     7:0
`define NR14_FREQ_MSB     2:0
`define NR14_FREQ_STOP    6:6
`define NR14_FREQ_ENABLE  7:7

// square2
`define NR21_LENGTH       5:0
`define NR21_DUTY         7:6
`define NR22_ENV_PERIOD   2:0
`define NR22_ENV_DIR      3:3
`define NR22_ENV_VOLUME   7:4
`define NR23_FREQ_LSB     7:0
`define NR24_FREQ_MSB     2:0
`define NR24_FREQ_STOP    6:6
`define NR24_FREQ_ENABLE  7:7

// wave
`define NR30_WAVE_ENABLE  7:7
`define NR31_LENGTH       7:0
`define NR32_LEVEL        6:5
`define NR33_FREQ_LSB     7:0
`define NR34_FREQ_MSB     2:0
`define NR34_FREQ_STOP    6:6
`define NR34_FREQ_ENABLE  7:7

// noise
`define NR41_LENGTH       5:0
`define NR42_ENV_PERIOD   2:0
`define NR42_ENV_DIR      3:3
`define NR42_ENV_VOLUME   7:4
`define NR43_LFSR_DIV     2:0
`define NR43_LFSR_WIDTH   3:3
`define NR43_LFSR_SHIFT   7:4
`define NR44_FREQ_STOP    6:6
`define NR44_FREQ_ENABLE  7:7

// control
`define NR50_MASTER_LEFT_VOLUME   2:0
`define NR50_MASTER_LEFT_ENABLE   3:3
`define NR50_MASTER_RIGHT_VOLUME  6:4
`define NR50_MASTER_RIGHT_ENABLE  7:7
`define NR51_SELECT_LEFT_CH0      0:0
`define NR51_SELECT_LEFT_CH1      1:1
`define NR51_SELECT_LEFT_CH2      2:2
`define NR51_SELECT_LEFT_CH3      3:3
`define NR51_SELECT_RIGHT_CH0     4:4
`define NR51_SELECT_RIGHT_CH1     5:5
`define NR51_SELECT_RIGHT_CH2     6:6
`define NR51_SELECT_RIGHT_CH3     7:7
`define NR52_CONTROL_CH0_ACTIVE   0:0
`define NR52_CONTROL_CH1_ACTIVE   1:1
`define NR52_CONTROL_CH2_ACTIVE   2:2
`define NR52_CONTROL_CH3_ACTIVE   3:3
`define NR52_CONTROL_ENABLE       7:7

reg [15:0]  PC_r;
reg [7:0]   A_r;
reg [7:0]   F_r;
reg [7:0]   B_r;
reg [7:0]   C_r;
reg [7:0]   D_r;
reg [7:0]   E_r;
reg [7:0]   H_r;
reg [7:0]   L_r;
reg [15:0]  SP_r;

`define AF_r {A_r,F_r}
`define BC_r {B_r,C_r}
`define DE_r {D_r,E_r}
`define HL_r {H_r,L_r}

`define FLAG_Z 7
`define FLAG_N 6
`define FLAG_H 5
`define FLAG_C 4

reg [7:0]   REG_P1_r;   // FF00
reg [7:0]   REG_SB_r;   // FF01
reg [7:0]   REG_SC_r;   // FF02

reg [15:0]  REG_DIV_r;  // FF04 top 8b
reg [7:0]   REG_TIMA_r; // FF05
reg [7:0]   REG_TMA_r;  // FF06
reg [7:0]   REG_TAC_r;  // FF07

reg [7:0]   REG_IF_r;   // FF0F

// APU
reg [7:0]   REG_NR10_r; // FF10
reg [7:0]   REG_NR11_r; // FF11
reg [7:0]   REG_NR12_r; // FF12
reg [7:0]   REG_NR13_r; // FF13
reg [7:0]   REG_NR14_r; // FF14

reg [7:0]   REG_NR21_r; // FF16
reg [7:0]   REG_NR22_r; // FF17
reg [7:0]   REG_NR23_r; // FF18
reg [7:0]   REG_NR24_r; // FF19

reg [7:0]   REG_NR30_r; // FF1A
reg [7:0]   REG_NR31_r; // FF1B
reg [7:0]   REG_NR32_r; // FF1C
reg [7:0]   REG_NR33_r; // FF1D
reg [7:0]   REG_NR34_r; // FF1E

reg [7:0]   REG_NR41_r; // FF20
reg [7:0]   REG_NR42_r; // FF21
reg [7:0]   REG_NR43_r; // FF22
reg [7:0]   REG_NR44_r; // FF23

reg [7:0]   REG_NR50_r; // FF24
reg [7:0]   REG_NR51_r; // FF25
reg [7:0]   REG_NR52_r; // FF26

reg [7:0]   REG_WAV_r[15:0]; // FF30-FF3F

// PPU
reg [7:0]   REG_LCDC_r; // FF40
reg [7:0]   REG_STAT_r; // FF41
reg [7:0]   REG_SCY_r;  // FF42
reg [7:0]   REG_SCX_r;  // FF43
reg [7:0]   REG_LY_r;   // FF44
reg [7:0]   REG_LYC_r;  // FF45
reg [7:0]   REG_DMA_r;  // FF46
reg [7:0]   REG_BGP_r;  // FF47
reg [7:0]   REG_OBP0_r; // FF48
reg [7:0]   REG_OBP1_r; // FF49
reg [7:0]   REG_WY_r;   // FF4A
reg [7:0]   REG_WX_r;   // FF4B

// MISC
reg [0:0]   REG_BOOT_r; // FF50
reg [7:0]   REG_IE_r;   // FFFF

parameter
  ST_REG_IDLE     = 3'b001,
  ST_REG_REQ      = 3'b010,
  ST_REG_END      = 3'b100;

reg         reg_req_r;
reg [2:0]   reg_state_r;
reg [7:0]   reg_addr_r;
reg         reg_src_r;
reg         reg_wr_r;
reg [7:0]   reg_wr_data_r;
reg [7:0]   reg_mdr_r;

reg         tmr_apu_step_r;
reg         tmr_ovf_1024_r;
reg         tmr_ovf_16_r;
reg         tmr_ovf_64_r;
reg         tmr_ovf_256_r;
reg         tmr_ovf_tima_r;
reg         tmr_cpu_edge_d1_r;

reg         reg_dma_start_r;
reg         reg_int_write_r;
reg  [7:0]  reg_int_write_data_r;

assign BOOTROM_ACTIVE = ~REG_BOOT_r[`BOOT_ROM_DI];
assign P1O = REG_P1_r[5:4];

assign REG_MCT_rsp_val = |(reg_state_r & ST_REG_END) & ~reg_src_r;
assign REG_DBG_rsp_val = |(reg_state_r & ST_REG_END) &  reg_src_r;
assign REG_data = reg_mdr_r;

assign REG_DMA_start = reg_dma_start_r;

assign REG_req_val  = |(reg_state_r & ST_REG_REQ) & reg_wr_r;
`ifdef SGB_SAVE_STATES
assign REG_req_dbg  = |(reg_state_r & ST_REG_REQ) & reg_wr_r &  reg_src_r;
`else
assign REG_req_dbg  = 0;
`endif
assign REG_address  = reg_addr_r;
assign REG_req_data = reg_wr_data_r;

assign REG_REQ      = REG_req_dbg;
assign REG_ADDR     = REG_address;
assign REG_REQ_DATA = REG_req_data;

always @(posedge CLK) begin
  if (cpu_ireset_r) begin
    reg_state_r <= ST_REG_IDLE;
    reg_req_r   <= 0;

    tmr_cpu_edge_d1_r <= 0;
    tmr_ovf_tima_r <= 0;

    reg_dma_start_r <= 0;
    reg_int_write_r <= 0;

    REG_P1_r[5:4] <= 2'b11;   // FF00
    //REG_SB_r;   // FF01
    //REG_SC_r;   // FF02

    REG_DIV_r     <= 16'h0000;  // FF04
    REG_TIMA_r    <= 8'h00; // FF05
    REG_TMA_r     <= 8'h00; // FF06
    REG_TAC_r     <= 8'h00; // FF07

    REG_IF_r      <= 8'h00;   // FF0F

    // Audio registers written by APU

    REG_LCDC_r    <= 8'h00; // FF40
    REG_STAT_r[7:3] <= 0;
    REG_SCY_r     <= 8'h00; // FF42
    REG_SCX_r     <= 8'h00; // FF43
    //REG_LY_r // FF44
    REG_LYC_r     <= 8'h00; // FF45
    //REG_DMA_r // FF46
    REG_BGP_r     <= 8'hFC; // FF47
    REG_OBP0_r    <= 8'hFF; // FF48
    REG_OBP1_r    <= 8'hFF; // FF49
    REG_WY_r      <= 8'h00; // FF4A
    REG_WX_r      <= 8'h00; // FF4B

    REG_BOOT_r    <= 8'h00; // FF50

    REG_IE_r      <= 8'h00; // FFFF
  end
  else begin

    // timers
    if (CLK_CPU_EDGE & DBG_advance) begin
      {tmr_ovf_16_r,  REG_DIV_r[3:0]  } <= REG_DIV_r[3:0]   + 1;
      {tmr_ovf_64_r,  REG_DIV_r[5:4]  } <= REG_DIV_r[5:4]   + tmr_ovf_16_r;
      {tmr_ovf_256_r, REG_DIV_r[7:6]  } <= REG_DIV_r[7:6]   + tmr_ovf_64_r;
      {tmr_ovf_1024_r,REG_DIV_r[9:8]  } <= REG_DIV_r[9:8]   + tmr_ovf_256_r;
      {tmr_apu_step_r,REG_DIV_r[12:10]} <= REG_DIV_r[12:10] + tmr_ovf_1024_r;
      {               REG_DIV_r[15:13]} <= REG_DIV_r[15:13] + tmr_apu_step_r;
    end

    tmr_cpu_edge_d1_r <= CLK_CPU_EDGE;

    // there are at least 16 base clocks in a CPU clock so update the timer state using a base clock delay
    if (REG_TAC_r[`TAC_ENABLE]) begin
      if (tmr_cpu_edge_d1_r) begin
        if (REG_TAC_r[`TAC_FREQ_DIV] == 0 ? tmr_ovf_1024_r : REG_TAC_r[`TAC_FREQ_DIV] == 1 ? tmr_ovf_16_r : REG_TAC_r[`TAC_FREQ_DIV] == 2 ? tmr_ovf_64_r : tmr_ovf_256_r) begin
          {tmr_ovf_tima_r,REG_TIMA_r} <= REG_TIMA_r + 1;
        end
      end
      else if (CLK_CPU_EDGE) begin
        tmr_ovf_tima_r <= 0;

        // load TMA into TIMA one CPU clock after the overflow
        if (tmr_ovf_tima_r) REG_TIMA_r <= REG_TMA_r;
      end
    end
    else begin
      tmr_ovf_tima_r <= 0;
    end

    // interrupt flags
    if (CLK_CPU_EDGE) begin
      // once we have halted instruction fetch then time has stopped and we need to avoid recording new interrupts
      if (~HLT_IFD_rsp) begin
        REG_IF_r[`IE_VBLANK]   <= (REG_IF_r[`IE_VBLANK]   | PPU_REG_vblank               | (reg_int_write_r & reg_int_write_data_r[`IE_VBLANK])  ) & ~(IFD_REG_ic[`IE_VBLANK]   | (reg_int_write_r & ~reg_int_write_data_r[`IE_VBLANK])  );
        REG_IF_r[`IE_LCD_STAT] <= (REG_IF_r[`IE_LCD_STAT] | PPU_REG_lcd_stat             | (reg_int_write_r & reg_int_write_data_r[`IE_LCD_STAT])) & ~(IFD_REG_ic[`IE_LCD_STAT] | (reg_int_write_r & ~reg_int_write_data_r[`IE_LCD_STAT]));
        REG_IF_r[`IE_TIMER]    <= (REG_IF_r[`IE_TIMER]    | tmr_ovf_tima_r               | (reg_int_write_r & reg_int_write_data_r[`IE_TIMER])   ) & ~(IFD_REG_ic[`IE_TIMER]    | (reg_int_write_r & ~reg_int_write_data_r[`IE_TIMER])   );
        REG_IF_r[`IE_SERIAL]   <= (REG_IF_r[`IE_SERIAL]   | SER_REG_done                 | (reg_int_write_r & reg_int_write_data_r[`IE_SERIAL])  ) & ~(IFD_REG_ic[`IE_SERIAL]   | (reg_int_write_r & ~reg_int_write_data_r[`IE_SERIAL])  );
        REG_IF_r[`IE_JOYPAD]   <= (REG_IF_r[`IE_JOYPAD]   | |(REG_P1_r[3:0] & ~P1I[3:0]) | (reg_int_write_r & reg_int_write_data_r[`IE_JOYPAD])  ) & ~(IFD_REG_ic[`IE_JOYPAD]   | (reg_int_write_r & ~reg_int_write_data_r[`IE_JOYPAD])  );
      end
    end

    if (CLK_CPU_EDGE) REG_P1_r[3:0] <= P1I[3:0];

    if (CLK_BUS_EDGE) reg_dma_start_r <= 0;
    if (CLK_CPU_EDGE) reg_int_write_r <= 0;

    case (reg_state_r)
      ST_REG_IDLE: begin
        if      (MCT_REG_req_val) begin
          reg_src_r     <= 0;
          reg_addr_r    <= MCT_REG_address;
          reg_wr_r      <= MCT_REG_wren;
          reg_wr_data_r <= MCT_REG_data;

          reg_state_r <= ST_REG_REQ;
        end
        else if (DBG_REG_req_val) begin
          reg_src_r     <= 1;
          reg_addr_r    <= DBG_REG_address;
          reg_wr_r      <= DBG_REG_wren;
          reg_wr_data_r <= DBG_REG_data;

          reg_state_r <= ST_REG_REQ;
        end
      end
      ST_REG_REQ: begin
        case (reg_addr_r)
          8'h00: begin reg_mdr_r[7:0] <= {2'b11, REG_P1_r[5:0]}; if (reg_wr_r) REG_P1_r[5:4]   <= reg_wr_data_r[5:4];   end
          8'h01: reg_mdr_r[7:0] <= REG_SB_r;
          8'h02: reg_mdr_r[7:0] <= {REG_SC_r[7],6'h3F,REG_SC_r[0]};

          8'h04: begin reg_mdr_r[7:0] <= REG_DIV_r[15:8];         if (reg_wr_r) REG_DIV_r[15:0] <= 0;               end
          8'h05: begin reg_mdr_r[7:0] <= REG_TIMA_r;              if (reg_wr_r) REG_TIMA_r[7:0] <= reg_wr_data_r[7:0];  end
          8'h06: begin reg_mdr_r[7:0] <= REG_TMA_r;               if (reg_wr_r) REG_TMA_r[7:0]  <= reg_wr_data_r[7:0];  end
          8'h07: begin reg_mdr_r[7:0] <= {5'h1F,REG_TAC_r[2:0]};  if (reg_wr_r) REG_TAC_r[2:0]  <= reg_wr_data_r[2:0];  end

          8'h0F: begin reg_mdr_r[7:0] <= REG_IF_r;                if (reg_wr_r) begin reg_int_write_data_r <= reg_wr_data_r[7:0]; reg_int_write_r <= 1; end end

          // APU registers read here for MMIO accesses and written in APU
          8'h10: reg_mdr_r[7:0] <= {1'h1,REG_NR10_r[6:0]};
          8'h11: reg_mdr_r[7:0] <= {REG_NR11_r[7:6],6'h3F};
          8'h12: reg_mdr_r[7:0] <= REG_NR12_r[7:0];
          8'h13: reg_mdr_r[7:0] <= 8'hFF;
          8'h14: reg_mdr_r[7:0] <= {1'h1,REG_NR14_r[6],6'h3F};

          8'h16: reg_mdr_r[7:0] <= {REG_NR21_r[7:6],6'h3F};
          8'h17: reg_mdr_r[7:0] <= REG_NR22_r[7:0];
          8'h18: reg_mdr_r[7:0] <= 8'hFF;
          8'h19: reg_mdr_r[7:0] <= {1'h1,REG_NR24_r[6],6'h3F};

          8'h1A: reg_mdr_r[7:0] <= {REG_NR30_r[7:7],7'h7F};
          8'h1B: reg_mdr_r[7:0] <= 8'hFF;
          8'h1C: reg_mdr_r[7:0] <= {1'h1,REG_NR32_r[6:5],5'h1F};
          8'h1D: reg_mdr_r[7:0] <= 8'hFF;
          8'h1E: reg_mdr_r[7:0] <= {1'h1,REG_NR34_r[6],6'h3F};

          8'h20: reg_mdr_r[7:0] <= 8'hFF;
          8'h21: reg_mdr_r[7:0] <= REG_NR42_r;
          8'h22: reg_mdr_r[7:0] <= REG_NR43_r;
          8'h23: reg_mdr_r[7:0] <= {1'h1,REG_NR44_r[6],6'hFF};

          8'h24: reg_mdr_r[7:0] <= REG_NR50_r;
          8'h25: reg_mdr_r[7:0] <= REG_NR51_r;
          8'h26: reg_mdr_r[7:0] <= {REG_NR52_r[7:7],3'h7,({4{REG_NR52_r[7]}} & {APU_REG_enable})};

          8'h30: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h31: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h32: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h33: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h34: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h35: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h36: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h37: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h38: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h39: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h3A: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h3B: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h3C: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h3D: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h3E: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];
          8'h3F: reg_mdr_r[7:0] <= (APU_REG_enable[2] & ~reg_src_r) ? 8'hFF : REG_WAV_r[reg_addr_r[3:0]][7:0];

          8'h40: begin reg_mdr_r[7:0] <= REG_LCDC_r;                    if (reg_wr_r) REG_LCDC_r[7:0] <= reg_wr_data_r[7:0]; end
          8'h41: begin reg_mdr_r[7:0] <= {1'b1,REG_STAT_r[6:0]};        if (reg_wr_r) REG_STAT_r[7:3] <= reg_wr_data_r[7:3]; end
          8'h42: begin reg_mdr_r[7:0] <= REG_SCY_r;                     if (reg_wr_r) REG_SCY_r[7:0]  <= reg_wr_data_r[7:0]; end
          8'h43: begin reg_mdr_r[7:0] <= REG_SCX_r;                     if (reg_wr_r) REG_SCX_r[7:0]  <= reg_wr_data_r[7:0]; end
          8'h44: reg_mdr_r[7:0] <= REG_LY_r;
          8'h45: begin reg_mdr_r[7:0] <= REG_LYC_r;                     if (reg_wr_r) REG_LYC_r[7:0]  <= reg_wr_data_r[7:0]; end
          8'h46: begin reg_mdr_r[7:0] <= REG_DMA_r;                     if (reg_wr_r) begin REG_DMA_r[7:0]  <= reg_wr_data_r[7:0]; reg_dma_start_r <= ~HLT_RSP; end end // don't trigger DMA on HLT
          8'h47: begin reg_mdr_r[7:0] <= REG_BGP_r;                     if (reg_wr_r) REG_BGP_r[7:0]  <= reg_wr_data_r[7:0]; end
          8'h48: begin reg_mdr_r[7:0] <= REG_OBP0_r;                    if (reg_wr_r) REG_OBP0_r[7:0] <= reg_wr_data_r[7:0]; end
          8'h49: begin reg_mdr_r[7:0] <= REG_OBP1_r;                    if (reg_wr_r) REG_OBP1_r[7:0] <= reg_wr_data_r[7:0]; end
          8'h4A: begin reg_mdr_r[7:0] <= REG_WY_r;                      if (reg_wr_r) REG_WY_r[7:0]   <= reg_wr_data_r[7:0]; end
          8'h4B: begin reg_mdr_r[7:0] <= REG_WX_r;                      if (reg_wr_r) REG_WX_r[7:0]   <= reg_wr_data_r[7:0]; end

          8'h50: begin reg_mdr_r[7:0] <= {7'h7F,REG_BOOT_r[`BOOT_ROM_DI]}; if (reg_wr_r) REG_BOOT_r[`BOOT_ROM_DI] <= 1'b1; end

`ifdef SGB_SAVE_STATES
          // special case debug source reads to read out arch state that isn't normally memory mapped

          // ARCH state
          8'h60: if (reg_src_r) reg_mdr_r <= A_r;
          8'h61: if (reg_src_r) reg_mdr_r <= F_r[7:0];
          8'h62: if (reg_src_r) reg_mdr_r <= B_r;
          8'h63: if (reg_src_r) reg_mdr_r <= C_r;
          8'h64: if (reg_src_r) reg_mdr_r <= D_r;
          8'h65: if (reg_src_r) reg_mdr_r <= E_r;
          8'h66: if (reg_src_r) reg_mdr_r <= H_r;
          8'h67: if (reg_src_r) reg_mdr_r <= L_r;
          8'h68: if (reg_src_r) reg_mdr_r <= SP_r[7:0];
          8'h69: if (reg_src_r) reg_mdr_r <= SP_r[15:8];
          8'h6A: if (reg_src_r) reg_mdr_r <= PC_r[7:0];
          8'h6B: if (reg_src_r) reg_mdr_r <= PC_r[15:8];
          8'h6C: if (reg_src_r) reg_mdr_r <= EXE_REG_ime;

          // MBC
          8'h70: if (reg_src_r) reg_mdr_r <= MBC_REG_DATA;
          8'h71: if (reg_src_r) reg_mdr_r <= MBC_REG_DATA;
          8'h72: if (reg_src_r) reg_mdr_r <= MBC_REG_DATA;
          8'h73: if (reg_src_r) reg_mdr_r <= MBC_REG_DATA;
          8'h74: if (reg_src_r) reg_mdr_r <= MBC_REG_DATA;
          8'h75: if (reg_src_r) reg_mdr_r <= MBC_REG_DATA;
          8'h76: if (reg_src_r) reg_mdr_r <= MBC_REG_DATA;
          8'h77: if (reg_src_r) reg_mdr_r <= MBC_REG_DATA;
`endif

          8'hFF: begin reg_mdr_r[7:0] <= {3'h0,REG_IE_r[4:0]};          if (reg_wr_r) REG_IE_r[4:0]   <= reg_wr_data_r[4:0]; end
          default: reg_mdr_r <= 8'hFF;
        endcase

        reg_state_r <= ST_REG_END;
      end
      ST_REG_END: begin
        reg_state_r <= ST_REG_IDLE;
      end
    endcase
  end
end

//-------------------------------------------------------------------
// IFD
//-------------------------------------------------------------------

// IFD performs Instruction Fetch and Decode operations in one or more
// bus cycles.  The number of bytes fetched is based on the decoded
// operation in a prior cycle.

// Local
reg [7:0]   ifd_op_r;
reg [1:0]   ifd_size_r;
reg [7:0]   ifd_data_r;
reg [15:0]  ifd_decode_r;
reg         ifd_req_r;
reg         ifd_complete_r;
reg         ifd_cb_r;
reg         ifd_int_r;
reg [2:0]   ifd_int_tgt_r;
reg [7:0]   ifd_int_ic_r;

// Outputs
reg         ifd_exe_valid_r;
reg [23:0]  ifd_exe_op_r;
reg [15:0]  ifd_exe_decode_r;
reg [15:0]  ifd_exe_pc_start_r;
reg [15:0]  ifd_exe_pc_end_r;
reg [15:0]  ifd_exe_pc_next_r;
reg         ifd_exe_cb_r;
reg         ifd_exe_new_r;
reg         ifd_exe_int_r;
reg [7:0]   ifd_reg_ic_r;

// decoder
wire [7:0]  dec_addr = ifd_op_r;
wire [15:0] dec_data;

// PC with bypass
wire [15:0] ifd_pc = EXE_IFD_redirect ? EXE_IFD_target : PC_r;

`ifdef MK2
dec_table dec (
  .clka(CLK),       // input clka
  .addra(dec_addr), // input [7 : 0] addra
  .douta(dec_data)  // output [15 : 0] douta
);
`endif
`ifdef MK3
dec_table dec (
  .clock(CLK),        // input clock
  .address(dec_addr), // input [7 : 0] address
  .q(dec_data)        // output [15 : 0] q
);
`endif

assign IFD_MCT_req_val = ifd_req_r;
assign IFD_MCT_req_addr_d1 = ifd_pc;

assign IFD_EXE_valid = ifd_exe_valid_r;
assign IFD_EXE_decode = ifd_exe_decode_r;
assign IFD_EXE_op = ifd_exe_op_r;

assign IFD_EXE_pc_start = ifd_exe_pc_start_r;
assign IFD_EXE_pc_end = ifd_exe_pc_end_r;
assign IFD_EXE_pc_next = ifd_exe_pc_next_r;

assign IFD_EXE_cb = ifd_exe_cb_r;
assign IFD_EXE_new = ifd_exe_new_r;
assign IFD_EXE_int = ifd_exe_int_r;

assign IFD_REG_ic = ifd_reg_ic_r;

// idle when:
// - at instruction boundary
// - not taking an interrupt
// - no in-progress ICD transfers
assign HLT_IFD_rsp = HLT_REQ_sync & ~|ifd_size_r & ~ifd_int_r & IDL_ICD;

always @(posedge CLK) begin
  if (cpu_ireset_r) begin
    PC_r <= 0;

    ifd_exe_valid_r <= 0;
    ifd_size_r <= 0;
    ifd_req_r <= 1; // generate the initial request out of reset
    ifd_exe_new_r <= 0;

    ifd_int_ic_r <= 0;
  end
  else begin
    ifd_exe_new_r <= 0;

    if (CLK_CPU_EDGE) ifd_reg_ic_r <= 0;

    if (CLK_BUS_EDGE & EXE_IFD_ready) begin
      if (~HLT_IFD_rsp) begin
        PC_r <= ifd_pc + 1;

        // Flop pipeline registers
        ifd_exe_valid_r <= ifd_complete_r;
        ifd_exe_new_r   <= ifd_complete_r;
        ifd_exe_int_r   <= ifd_complete_r & ifd_int_r;

        // Adjust current instrucion size
        ifd_size_r      <= ifd_complete_r ? 0 : ifd_size_r + 1;

        if (ifd_complete_r & ifd_int_r) ifd_reg_ic_r <= ifd_int_ic_r;
      end
      else begin
        // force bypassed PC to be accounted for in state
        PC_r <= ifd_pc;

        ifd_exe_valid_r <= 0;
        ifd_exe_new_r <= 0;
        ifd_exe_int_r <= 0;
      end
    end

    ifd_req_r <= CLK_BUS_EDGE;
  end

  if (CLK_BUS_EDGE & EXE_IFD_ready) begin
    case (ifd_size_r)
      0: ifd_exe_op_r[7:0]   <= ifd_int_r ? {2'h3,ifd_int_tgt_r,3'h7} : ifd_data_r;
      1: ifd_exe_op_r[15:8]  <=                                         ifd_data_r;
      2: ifd_exe_op_r[23:16] <=                                         ifd_data_r;
    endcase

    ifd_exe_decode_r <= ifd_decode_r;

    if (ifd_size_r == 0) ifd_exe_pc_start_r <= ifd_pc;
    ifd_exe_pc_end_r  <= ifd_pc;
    ifd_exe_pc_next_r <= ifd_pc + (ifd_int_r ? 0 : 1);
    ifd_exe_cb_r      <= ifd_cb_r;
  end

  if (MCT_IFD_rsp_val) begin
    ifd_data_r <= MCT_data;
    if (ifd_size_r == 0) ifd_op_r <= MCT_data;
  end

  // Interrupts
  // this doesn't have to be the first base cycle since the instruction is contructed from constants and register state
  ifd_int_r <= EXE_IFD_ime & |(REG_IE_r & REG_IF_r) & ~|ifd_size_r;
  ifd_int_tgt_r <= (  (REG_IE_r[`IE_VBLANK]   & REG_IF_r[`IE_VBLANK]  ) ? 3'h0
                   :  (REG_IE_r[`IE_LCD_STAT] & REG_IF_r[`IE_LCD_STAT]) ? 3'h1
                   :  (REG_IE_r[`IE_TIMER]    & REG_IF_r[`IE_TIMER])    ? 3'h2
                   :  (REG_IE_r[`IE_SERIAL]   & REG_IF_r[`IE_SERIAL])   ? 3'h3
                   :  (REG_IE_r[`IE_JOYPAD]   & REG_IF_r[`IE_JOYPAD])   ? 3'h4
                   :                                                      3'h7
                   );

  if      (REG_IE_r[`IE_VBLANK]   & REG_IF_r[`IE_VBLANK]  ) ifd_int_ic_r <= 8'b00000001;
  else if (REG_IE_r[`IE_LCD_STAT] & REG_IF_r[`IE_LCD_STAT]) ifd_int_ic_r <= 8'b00000010;
  else if (REG_IE_r[`IE_TIMER]    & REG_IF_r[`IE_TIMER]   ) ifd_int_ic_r <= 8'b00000100;
  else if (REG_IE_r[`IE_SERIAL]   & REG_IF_r[`IE_SERIAL]  ) ifd_int_ic_r <= 8'b00001000;
  else if (REG_IE_r[`IE_JOYPAD]   & REG_IF_r[`IE_JOYPAD]  ) ifd_int_ic_r <= 8'b00010000;
  else                                                      ifd_int_ic_r <= 8'b00000000;

  ifd_complete_r <= (ifd_decode_r[`DEC_SZE] == ifd_size_r);

  ifd_cb_r <= ifd_op_r == 8'hCB;

  // SZE2, LAT2, DST4, SRC4, GRP4
  ifd_decode_r <= ( ifd_int_r ? {2'h0,2'h0,`OPR_SP,`OPR_PC,`GRP_CLL}
                  : ifd_cb_r  ? {2'h1,{(ifd_data_r[2:0] == 3'h6 ? 1'b1 : 1'b0),1'b0},{1'b1,ifd_data_r[2:0]},{1'b1,ifd_data_r[2:0]},({{(ifd_data_r[2:0] == 3'h6 ? 1'b1 : 1'b0),3'h0} | `GRP_BIT})}
                  :             dec_data
                  );

  // debug/state writes
  if (REG_req_dbg) begin
    case (REG_address)
      8'h6A: PC_r[7:0]  <= REG_req_data;
      8'h6B: PC_r[15:8] <= REG_req_data;
    endcase
  end
end

//-------------------------------------------------------------------
// EXE
//-------------------------------------------------------------------

// EXE implements the execution component of the CPU.
//
// Overall instruction latency is defined as the following:
//
// OP         [operand fetch-1 + execution/memory time + writeback]
//
// For example:
// LD R,R     [0 + 0 + 1 = 1]
// LD R,n     [1 + 0 + 1 = 2]
// LD (HL),n  [1 + 1 + 1 = 3]
// RET CC     [0 + 1 + 1 = 2] // not taken
// RET CC     [0 + 4 + 1 = 5] // taken
//
// IFD handles operand fetch.  EXE is responsible for performing any
// data bus operations and writing back to register state.  Since
// the next opcode bus fetch is pipelined wrt Writeback,
// WB cannot peform any bus operations.
//
// This multi-cycle operation is composed of 4 distinct stages which can
// cover 1-5 cycles of latency in addition to the 1-2 cycles of operand fetch
// in IFD.
//
// Sequencing:
//  0*  3   2   1   0   // stage numbers
//                  WB  // LD R,R  LD R,n
//              LD  WB
//              ST  WB
//          LD  LD  WB
//          ST  ST  WB
//          LD  ST  WB
//  CC                  // JR CC not taken
//  CC      LD  LD  WB
//  CC      ST  ST  WB
//  CC  --  LD  LD  WB  // RET CC taken
//
// 0/0* - WB/CC is always stage 0*/0. They are effectively the same stage.
//        0* indicates that certain condition code instructions will evaluate and
//        possibly extend the execution time 1-4 additional clocks.
// 2/1  - Up to 2 memory data bus operation will be performed in the format of
//        LD, ST, LD-LD, ST-ST, or LD-ST.  These always occur in stage 2 and 1.
// 3    - This serves as an optional delay stage.  No arch state is modified.

// Local
reg         exe_advance_r;
reg         exe_ready_r;
reg         exe_complete_r;

reg [2:0]   exe_ctr_r;
reg [2:0]   exe_lat_add_r;

reg [15:0]  exe_src_r;
reg [15:0]  exe_dst_r;
reg [7:0]   exe_cc_r;
reg [7:0]   exe_src_alu_r;

reg [15:0]  exe_res_r;
reg [7:0]   exe_res_cc_r;
reg [7:0]   exe_res_los_r;
reg [7:0]   exe_res_cp_r;
// address arithmetic
reg         exe_res_hl_mod_r;
reg [15:0]  exe_res_hl_r;
reg         exe_res_sp_mod_r;
reg [15:0]  exe_res_sp_r;
// alu
reg         exe_res_c15_r;
reg         exe_res_c11_r;
reg         exe_res_c7_r;
reg         exe_res_c3_r;

reg         exe_res_int_enable_r;
reg         exe_res_int_disable_r;

reg         exe_res_halt_r;
reg         exe_res_stop_r;

reg         exe_mem_req_r;
reg [15:0]  exe_mem_data_r;
reg [15:0]  exe_mem_addr_mod_r;

reg         exe_ime_r;

wire        exe_loadopstore = (IFD_EXE_decode[`DEC_GRP] == `GRP_MBT || IFD_EXE_decode[`DEC_GRP] == `GRP_MIC || IFD_EXE_decode[`DEC_GRP] == `GRP_MDC);
// use condition codes directly since the flopped version causes problems with evaluating redirect
wire        exe_redirect_taken = ~(IFD_EXE_op[3] ^ (IFD_EXE_op[4] ? F_r[`FLAG_C] : F_r[`FLAG_Z]));
wire        exe_stall = (exe_res_halt_r & ~|(REG_IE_r[4:0] & REG_IF_r[4:0])) | (exe_res_stop_r & &REG_P1_r[3:0]);

// latency/stage computation
// latency adder state is set after cycle 0 to avoid treating the delay as a non-CC/WB cycle.  Also, it is forced clear
// on the first base clock of a new op to make sure we do not make an access.
wire [2:0]  exe_lat   = IFD_EXE_decode[`DEC_LAT] + (IFD_EXE_new ? 0 : exe_lat_add_r);
wire [2:0]  exe_stage = exe_lat - exe_ctr_r; // must be correct on first cycle for memory op

// Outputs
reg         exe_ifd_redirect_r;
reg [15:0]  exe_ifd_redirect_target_r;

reg [15:0]  exe_pc_prev_r;
reg [15:0]  exe_pc_prev_redirect_r;
reg [15:0]  exe_target_prev_redirect_r;

assign      EXE_IFD_redirect = IFD_EXE_valid & exe_ifd_redirect_r;
assign      EXE_IFD_target   = exe_ifd_redirect_target_r;
assign      EXE_IFD_ready    = exe_ready_r;
assign      EXE_IFD_ime      = (exe_ime_r | (exe_res_int_enable_r & ~IFD_EXE_op[5])) & ~IFD_EXE_int & ~exe_res_int_disable_r; // RETI and disables need bypass.  EI is delayed a clock.

assign      EXE_MCT_req_val     = IFD_EXE_valid & exe_mem_req_r & ^exe_stage[1:0];
assign      EXE_MCT_req_addr_d1 = ( EXE_MCT_req_wr ? {((IFD_EXE_decode[`DEC_DST] == `OPR_S8 || IFD_EXE_decode[`DEC_DST] == `OPR_C) ? 8'hFF : exe_dst_r[15:8]),exe_dst_r[7:0]}
                                              : {((IFD_EXE_decode[`DEC_SRC] == `OPR_S8 || IFD_EXE_decode[`DEC_SRC] == `OPR_C) ? 8'hFF : exe_src_r[15:8]),exe_src_r[7:0]})
                                  + exe_mem_addr_mod_r;
assign      EXE_MCT_req_wr = (  IFD_EXE_decode[`DEC_GRP] == `GRP_MST
                             || IFD_EXE_decode[`DEC_GRP] == `GRP_CLL
                             // load-op-store operations need ST on second stage
                             || (exe_stage[0] & exe_loadopstore)
                             );
// always write MSB followed by LSB.  LOS ops need the result of math
assign      EXE_MCT_req_data_d1 = exe_loadopstore ? exe_res_los_r[7:0] : (exe_stage[1] ? exe_src_r[15:8] : exe_src_r[7:0]);

assign      EXE_DMA_halt = exe_res_halt_r;

assign      EXE_REG_ime = exe_ime_r;

assign      HLT_EXE_rsp = HLT_REQ_sync & ~IFD_EXE_valid;

reg         dbg_advance_r;
assign      DBG_advance = dbg_advance_r;

always @(posedge CLK) begin
  if (cpu_ireset_r) begin
    exe_ctr_r <= 0;

    exe_ime_r <= 0;

    dbg_advance_r <= 1;
  end
  else begin
    if (CLK_BUS_EDGE & exe_advance_r) begin
      exe_ctr_r <= exe_complete_r ? 0 : exe_ctr_r + 1;

      if (exe_complete_r) begin
        case (IFD_EXE_decode[`DEC_DST])
          //`OPR_I  : exe_src_r <= 0;
          // this is for RET.  could also make its target SP
          `OPR_PC : begin if (exe_res_sp_mod_r) SP_r <= exe_res_sp_r;                                                                end
          //`OPR_S8 : exe_dst_r[15:0] <= {8{IFD_EXE_op[15]},IFD_EXE_op[15:8]};
          //`OPR_U16: exe_dst_r[15:0] <= IFD_EXE_op[23:8];
          `OPR_BC : begin `BC_r <= exe_res_r;                                   SP_r <= exe_res_sp_r; F_r[7:4] <= exe_res_cc_r[7:4]; end
          `OPR_DE : begin `DE_r <= exe_res_r;                                   SP_r <= exe_res_sp_r; F_r[7:4] <= exe_res_cc_r[7:4]; end
          `OPR_SP : begin SP_r  <= exe_res_sp_mod_r ? exe_res_sp_r : exe_res_r;                       F_r[7:4] <= exe_res_cc_r[7:4]; end
          `OPR_AF : begin A_r   <= exe_res_r[15:8];                             SP_r <= exe_res_sp_r; F_r[7:4] <= exe_res_r[7:4];    end
          `OPR_B  : begin B_r   <= exe_res_r[7:0];                                                    F_r[7:4] <= exe_res_cc_r[7:4]; end
          `OPR_C  : begin C_r   <= exe_res_r[7:0];                                                    F_r[7:4] <= exe_res_cc_r[7:4]; end
          `OPR_D  : begin D_r   <= exe_res_r[7:0];                                                    F_r[7:4] <= exe_res_cc_r[7:4]; end
          `OPR_E  : begin E_r   <= exe_res_r[7:0];                                                    F_r[7:4] <= exe_res_cc_r[7:4]; end
          `OPR_H  : begin H_r   <= exe_res_r[7:0];                                                    F_r[7:4] <= exe_res_cc_r[7:4]; end
          `OPR_L  : begin L_r   <= exe_res_r[7:0];                                                    F_r[7:4] <= exe_res_cc_r[7:4]; end
          `OPR_HL : begin `HL_r <= exe_res_hl_mod_r ? exe_res_hl_r : exe_res_r; SP_r <= exe_res_sp_r; F_r[7:4] <= exe_res_cc_r[7:4]; end
          `OPR_A  : begin A_r   <= exe_res_r[7:0]; if (exe_res_hl_mod_r) `HL_r <= exe_res_hl_r;       F_r[7:4] <= exe_res_cc_r[7:4]; end
        endcase

        // delay 1 inst because fetch will see this in the following cycle
        exe_ime_r <= (exe_ime_r | exe_res_int_enable_r) & ~exe_res_int_disable_r & ~IFD_EXE_int;
        exe_pc_prev_r <= IFD_EXE_pc_start;
        if (exe_ifd_redirect_r) exe_pc_prev_redirect_r <= IFD_EXE_pc_start;
        if (exe_ifd_redirect_r) exe_target_prev_redirect_r <= exe_ifd_redirect_target_r;
      end
    end

    if (CLK_BUS_EDGE) dbg_advance_r <= ~IFD_EXE_valid | ~exe_complete_r | DBG_EXE_step;
  end

  // alu/bit/los input
  exe_src_alu_r[7:0] <= IFD_EXE_decode[3] ? exe_mem_data_r[7:0] : exe_src_r[7:0];

  // default to no redirect and no extended latency
  exe_ifd_redirect_r <= 0;
  exe_lat_add_r      <= 0;

  // default no mod to SP
  exe_res_sp_mod_r <= 0;
  exe_res_sp_r     <= SP_r;

  exe_res_int_enable_r  <= 0;
  exe_res_int_disable_r <= 0;

  exe_res_r    <= exe_dst_r;
  exe_res_cc_r <= exe_cc_r;

  exe_res_halt_r <= 0;
  exe_res_stop_r <= 0;

  // result computation
  case (IFD_EXE_decode[`DEC_GRP])
    `GRP_SPC: begin
      // NOP (0x00), STOP (0x10), HALT (0x76), EI (0xFB), DI (0xF3)

      exe_res_halt_r <= ~IFD_EXE_op[7] & IFD_EXE_op[4] &  IFD_EXE_op[2];
      exe_res_stop_r <= ~IFD_EXE_op[7] & IFD_EXE_op[4] & ~IFD_EXE_op[2];

      exe_res_int_enable_r  <= IFD_EXE_op[7] &  IFD_EXE_op[3];
      exe_res_int_disable_r <= IFD_EXE_op[7] & ~IFD_EXE_op[3];
    end
    `GRP_MOV: begin
      exe_res_r <= exe_src_r;
      exe_res_cc_r <= exe_cc_r;

      // LD HL,SP requires an extra clock
      if (&IFD_EXE_op[7:6]) exe_lat_add_r <= 1;
    end
    `GRP_MIC,`GRP_INC,`GRP_DEC,`GRP_MDC: begin
      {exe_res_c3_r,exe_res_los_r[3:0]}   <= exe_src_alu_r[3:0] + {{3{IFD_EXE_decode[0]}},1'b1};
      {exe_res_c7_r,exe_res_los_r[7:4]}   <= exe_src_alu_r[7:4] + {4{IFD_EXE_decode[0]}} + exe_res_c3_r;
      exe_res_r[7:0]                      <= IFD_EXE_decode[3] ? exe_dst_r[7:0] : exe_res_los_r[7:0];
      if (~IFD_EXE_op[2]) exe_res_r[15:8] <= exe_src_r[15:8] + {8{IFD_EXE_decode[0]}} + exe_res_c7_r;
      exe_res_cc_r                        <= ~IFD_EXE_op[2] ? exe_cc_r : {~|exe_res_los_r,IFD_EXE_decode[0],IFD_EXE_decode[0]^exe_res_c3_r,exe_cc_r[`FLAG_C],exe_cc_r[3:0]};

      // 16b operations require an extra clock
      exe_lat_add_r <= IFD_EXE_op[1] ? 1 : 0;
    end
    `GRP_ALU,`GRP_MLU: begin
      if (~IFD_EXE_op[7] | (IFD_EXE_op[6] & ~IFD_EXE_op[2])) begin
        if      (IFD_EXE_op[3:0] == 4'h9) begin
          // ADD HL,BC
          // ADD HL,DE
          // ADD HL,HL
          // ADD HL,SP
          {exe_res_c11_r,exe_res_r[11:0]}  <= exe_dst_r[11:0] + exe_src_r[11:0];
          {exe_res_c15_r,exe_res_r[15:12]} <= exe_dst_r[15:12] + exe_src_r[15:12] + exe_res_c11_r;
          exe_res_cc_r                     <= {exe_cc_r[`FLAG_Z],1'b0,exe_res_c11_r,exe_res_c15_r,exe_cc_r[3:0]};

          exe_lat_add_r <= 1;
        end
        else if (IFD_EXE_op[3:0] == 4'h7) begin
          if (~IFD_EXE_op[4]) begin
            // DAA
            if (exe_cc_r[`FLAG_N]) begin
              exe_res_r[7:0] <= exe_src_r[7:0] - {(exe_cc_r[`FLAG_C] ? 4'h6 : 4'h0), (exe_cc_r[`FLAG_H] ? 4'h6 : 4'h0)};
              exe_res_c7_r <= 0;
            end
            else begin
              {exe_res_c3_r,exe_res_r[3:0]} <= exe_src_r[3:0] + ((exe_cc_r[`FLAG_H] | (exe_src_r[3] & | exe_src_r[2:1])) ? 4'h6 : 4'h0);
              {exe_res_c7_r,exe_res_r[7:4]} <= exe_src_r[7:4] + ((exe_cc_r[`FLAG_C] | (exe_src_r[7:0] > 8'h99)) ? 4'h6 : 4'h0) + exe_res_c3_r;
            end

            exe_res_cc_r <= {~|exe_res_r[7:0],exe_cc_r[`FLAG_N],1'b0,(exe_res_c7_r | exe_cc_r[`FLAG_C]),exe_cc_r[3:0]};
          end
          else begin
            // SCF
            exe_res_r    <= exe_dst_r;
            exe_res_cc_r <= {exe_cc_r[`FLAG_Z],1'b0,1'b0,1'b1,exe_cc_r[3:0]};
          end
        end
        else if (IFD_EXE_op[3:0] == 4'hF) begin
          if (~IFD_EXE_op[4]) begin
            // CPL
            exe_res_r    <= ~exe_src_r;
            exe_res_cc_r <= {exe_cc_r[`FLAG_Z],1'b1,1'b1,exe_cc_r[4:0]};
          end
          else begin
            // CCF
            exe_res_r    <= exe_dst_r;
            exe_res_cc_r <= {exe_cc_r[`FLAG_Z],1'b0,1'b0,~exe_cc_r[`FLAG_C],exe_cc_r[3:0]};
          end
        end
        else if (IFD_EXE_op[3:0] == 4'h8) begin
          if (~IFD_EXE_op[4]) begin
            // ADD SP,e
            {exe_res_c3_r,exe_res_r[3:0]} <= exe_dst_r[3:0] + exe_src_r[3:0];
            {exe_res_c7_r,exe_res_r[7:4]} <= exe_dst_r[7:4] + exe_src_r[7:4] + exe_res_c3_r;
            exe_res_r[15:8]               <= exe_dst_r[15:8] + exe_src_r[15:8] + exe_res_c7_r;
            exe_res_cc_r                  <= {1'b0,1'b0,exe_res_c3_r,exe_res_c7_r,exe_cc_r[3:0]};

            // hack to avoid memory access.  stage is always 0 on first cycle
            exe_lat_add_r <= |exe_ctr_r ? 2 : 1;
          end
          else begin
            // LD HL,SP+e
            {exe_res_c3_r,exe_res_r[3:0]} <= SP_r[3:0] + exe_src_r[3:0];
            {exe_res_c7_r,exe_res_r[7:4]} <= SP_r[7:4] + exe_src_r[7:4] + exe_res_c3_r;
            exe_res_r[15:8]               <= SP_r[15:8] + exe_src_r[15:8] + exe_res_c7_r;
            exe_res_cc_r                  <= {1'b0,1'b0,exe_res_c3_r,exe_res_c7_r,exe_cc_r[3:0]};

            exe_lat_add_r <= 1;
          end
        end
      end
      else begin
        // ALU
        case (IFD_EXE_op[5:3])
          3'h0,3'h1,3'h2,3'h3: begin // ADD,ADC,SUB,SBC
            {exe_res_c3_r,exe_res_r[3:0]} <= exe_dst_r[3:0] + ({4{IFD_EXE_op[4]}} ^ exe_src_alu_r[3:0]) + ((IFD_EXE_op[3] & exe_cc_r[4]) ^ (IFD_EXE_op[4]));
            {exe_res_c7_r,exe_res_r[7:4]} <= exe_dst_r[7:4] + ({4{IFD_EXE_op[4]}} ^ exe_src_alu_r[7:4]) + exe_res_c3_r;
            exe_res_cc_r              <= {~|exe_res_r[7:0],IFD_EXE_op[4],IFD_EXE_op[4]^exe_res_c3_r,IFD_EXE_op[4]^exe_res_c7_r,exe_cc_r[3:0]};
          end
          3'h4: begin // AND
            exe_res_r[7:0] <= exe_dst_r[7:0] & exe_src_alu_r[7:0];
            exe_res_cc_r   <= {~|exe_res_r[7:0],1'b0,1'b1,1'b0,exe_cc_r[3:0]};
          end
          3'h5: begin // XOR
            exe_res_r[7:0] <= exe_dst_r[7:0] ^ exe_src_alu_r[7:0];
            exe_res_cc_r   <= {~|exe_res_r[7:0],1'b0,1'b0,1'b0,exe_cc_r[3:0]};
          end
          3'h6: begin // OR
            exe_res_r[7:0] <= exe_dst_r[7:0] | exe_src_alu_r[7:0];
            exe_res_cc_r   <= {~|exe_res_r[7:0],1'b0,1'b0,1'b0,exe_cc_r[3:0]};
          end
          3'h7: begin // CP
            {exe_res_c3_r,exe_res_cp_r[3:0]} <= exe_dst_r[3:0] + ({4{1'b1}} ^ exe_src_alu_r[3:0]) + 1'b1;
            {exe_res_c7_r,exe_res_cp_r[7:4]} <= exe_dst_r[7:4] + ({4{1'b1}} ^ exe_src_alu_r[7:4]) + exe_res_c3_r;
            exe_res_cc_r                 <= {~|exe_res_cp_r[7:0],1'b1,~exe_res_c3_r,~exe_res_c7_r,exe_cc_r[3:0]};
          end
        endcase
      end
    end
    `GRP_BIT,`GRP_MBT: begin
      if (~IFD_EXE_cb) begin
        exe_res_r[7:0] <= IFD_EXE_op[3] ? {(IFD_EXE_op[4] ? exe_cc_r[`FLAG_C] : exe_src_r[0]),exe_src_r[7:1]} : {exe_src_r[6:0],(IFD_EXE_op[4] ? exe_cc_r[`FLAG_C] : exe_src_r[7])};
        exe_res_cc_r[7:0] <= {1'b0,1'b0,1'b0,(IFD_EXE_op[3] ? exe_src_r[0] : exe_src_r[7]),exe_cc_r[3:0]};
      end
      else begin
        // CB bit operations
        case (IFD_EXE_op[15:12])
          4'h0,4'h1,4'h2: begin
            // RLC,RRC
            // RL,RR
            // SLA,SRA
            exe_res_los_r[7:0] <= IFD_EXE_op[11] ? {(IFD_EXE_op[12] ? exe_cc_r[`FLAG_C] : (IFD_EXE_op[13] ? exe_src_alu_r[7] : exe_src_alu_r[0])),exe_src_alu_r[7:1]} : {exe_src_alu_r[6:0],(IFD_EXE_op[12] ? exe_cc_r[`FLAG_C] : (~IFD_EXE_op[13] & exe_src_alu_r[7]))};
            if (~IFD_EXE_decode[3]) exe_res_r[7:0] <= exe_res_los_r[7:0];
            exe_res_cc_r       <= {~|exe_res_los_r[7:0],1'b0,1'b0,(IFD_EXE_op[11] ? exe_src_alu_r[0] : exe_src_alu_r[7]),exe_cc_r[3:0]};
          end
          4'h3:begin
            // SWAP,SRL
            exe_res_los_r[7:0] <= IFD_EXE_op[11] ? {1'b0,exe_src_alu_r[7:1]} : {exe_src_alu_r[3:0],exe_src_alu_r[7:4]};
            if (~IFD_EXE_decode[3]) exe_res_r[7:0] <= exe_res_los_r[7:0];
            exe_res_cc_r       <= {~|exe_res_los_r[7:0],1'b0,1'b0,(IFD_EXE_op[11] & exe_src_alu_r[0]),exe_cc_r[3:0]};
          end
          4'h4,4'h5,4'h6,4'h7:begin
            // BIT
            exe_res_los_r[7:0] <= exe_src_alu_r[7:0];
            exe_res_cc_r       <= {~exe_res_los_r[IFD_EXE_op[13:11]],1'b0,1'b1,exe_cc_r[`FLAG_C],exe_cc_r[3:0]};

            // hack to avoid memory access.  skips stage 1 (ST)
            // NOTE: the previous version of this was holding lat_add from the prior op (2 cycle op, lat_add=1) during the first stage which caused us to not perform the LD
            // 1) lat_add to be 0 while the stage is 0
            // 2) lat_add to be 7 going into subsequent stages (keyed on BUS_EDGE)
            if (IFD_EXE_decode[3]) exe_lat_add_r <= (~exe_stage[1] | CLK_BUS_EDGE) ? 3'h7 : 0;

          end
          4'h8,4'h9,4'hA,4'hB:begin
            // RES
            exe_res_los_r[7:0] <= exe_src_alu_r[7:0] & ~(8'h1 << IFD_EXE_op[13:11]);
            if (~IFD_EXE_decode[3]) exe_res_r[15:0] <= {8'h00,exe_res_los_r[7:0]};
            exe_res_cc_r       <= exe_cc_r;
          end
          4'hC,4'hD,4'hE,4'hF:begin
            // SET
            exe_res_los_r[7:0] <= exe_src_alu_r[7:0] | (8'h1 << IFD_EXE_op[13:11]);
            if (~IFD_EXE_decode[3]) exe_res_r[15:0] <= {8'h00,exe_res_los_r[7:0]};
            exe_res_cc_r       <= exe_cc_r;
          end
        endcase
      end
    end
    `GRP_JMP: begin
      // branch control flow
      // redirect and the associated PC must be available 1 base clock after the start of the bus cycle for IFD to send
      // the correct address to MCT!  This is important for JMP HL.
      // It's ok to cause a redirect even if this isn't the final stage as long as we don't advance EXE.
      exe_ifd_redirect_r        <= (IFD_EXE_op[0] | (~IFD_EXE_op[7] & ~IFD_EXE_op[5])) | exe_redirect_taken;
      exe_ifd_redirect_target_r <= IFD_EXE_op[7] ? (IFD_EXE_op[5] ? `HL_r : exe_src_r) : (IFD_EXE_pc_next + exe_src_r);

      // JMP HL needs to be special cased since HL looks like it can be bypassed.
      exe_lat_add_r <= (exe_ifd_redirect_r & ~(IFD_EXE_op[7] & IFD_EXE_op[5])) ? 1 : 0;
    end
    `GRP_RET: begin
      // RET
      exe_ifd_redirect_r        <= IFD_EXE_op[0] | exe_redirect_taken;
      exe_ifd_redirect_target_r <= exe_mem_data_r;

      exe_lat_add_r <= exe_ifd_redirect_r ? (IFD_EXE_op[0] ? 3 : 4) : 1;

      exe_res_sp_mod_r <= exe_ifd_redirect_r;
      exe_res_sp_r     <= SP_r + 2;

      // RETI enables interrupts
      exe_res_int_enable_r <= IFD_EXE_op[4] & IFD_EXE_op[0];
    end
    `GRP_MST: begin
      if (IFD_EXE_decode[`DEC_DST] == `OPR_SP) begin
        exe_res_sp_mod_r <= 1;
        exe_res_sp_r     <= SP_r - 2;
      end
    end
    `GRP_MLD: begin
      exe_res_r <= exe_mem_data_r;
      exe_res_cc_r <= exe_cc_r;

      if (IFD_EXE_decode[`DEC_SRC] == `OPR_SP) exe_res_sp_r <= SP_r + 2;
    end
    `GRP_CLL: begin
      // CALL + RST
      exe_ifd_redirect_r        <= IFD_EXE_op[0] | exe_redirect_taken;
      exe_ifd_redirect_target_r <= IFD_EXE_op[1] ? {1'h0,IFD_EXE_int, IFD_EXE_op[5:3], 3'h0} : IFD_EXE_op[23:8];

      exe_lat_add_r <= exe_ifd_redirect_r ? (IFD_EXE_int ? 4 : 3) : 0;

      exe_res_sp_mod_r <= exe_ifd_redirect_r;
      exe_res_sp_r     <= SP_r - 2;
    end
    `GRP____: begin
    end
  endcase

  exe_res_hl_mod_r <= IFD_EXE_op[7:0] == 8'h22 || IFD_EXE_op[7:0] == 8'h2A || IFD_EXE_op[7:0] == 8'h32 || IFD_EXE_op[7:0] == 8'h3A;
  exe_res_hl_r     <= IFD_EXE_op[4] ? `HL_r - 1 : `HL_r + 1;

  // memory operations
  exe_mem_req_r <= ~cpu_ireset_r & CLK_BUS_EDGE;

  // force MSB -> LSB order for all memory operations to simplify 8/16b sequencing.
  // LD             (+1)  +0
  // ST             (+1)  +0
  // PUSH/CALL/RST  -1    -2
  // POP/RET        +1    +0
  // LD-OP-ST       +0    +0
  exe_mem_addr_mod_r <= ((exe_stage[1] & ~exe_loadopstore) ? 1 : 0) + ((IFD_EXE_decode[`DEC_DST] == `OPR_SP) ? -2 : 0);
  if (MCT_EXE_rsp_val & ~EXE_MCT_req_wr) if (exe_stage[1] & ~exe_loadopstore) exe_mem_data_r[15:8] <= MCT_data; else exe_mem_data_r[7:0] <= MCT_data;

  // op completion and pipe advance
  exe_complete_r <= IFD_EXE_valid & ~|exe_stage;
  exe_advance_r  <= IFD_EXE_valid & (~exe_complete_r | DBG_EXE_step & ~exe_stall);
  exe_ready_r    <= ~IFD_EXE_valid | (exe_complete_r & ~exe_stall & DBG_EXE_step);

  // operand read
  case (IFD_EXE_decode[`DEC_SRC])
    //`OPR_I  : exe_src_r <= 0;
    `OPR_PC : exe_src_r[15:0] <= IFD_EXE_pc_next;
    `OPR_S8 : exe_src_r[15:0] <= {{8{IFD_EXE_op[15]}},IFD_EXE_op[15:8]};
    `OPR_U16: exe_src_r[15:0] <= IFD_EXE_op[23:8];
    `OPR_BC : exe_src_r[15:0] <= `BC_r;
    `OPR_DE : exe_src_r[15:0] <= `DE_r;
    `OPR_SP : exe_src_r[15:0] <= SP_r;
    `OPR_AF : exe_src_r[15:0] <= `AF_r;
    `OPR_B  : exe_src_r[15:0] <= {8'h0,B_r};
    `OPR_C  : exe_src_r[15:0] <= {8'h0,C_r};
    `OPR_D  : exe_src_r[15:0] <= {8'h0,D_r};
    `OPR_E  : exe_src_r[15:0] <= {8'h0,E_r};
    `OPR_H  : exe_src_r[15:0] <= {8'h0,H_r};
    `OPR_L  : exe_src_r[15:0] <= {8'h0,L_r};
    `OPR_HL : exe_src_r[15:0] <= `HL_r;
    `OPR_A  : exe_src_r[15:0] <= {8'h0,A_r};
  endcase

  // operand read
  case (IFD_EXE_decode[`DEC_DST])
    //`OPR_I  : exe_src_r <= 0;
    `OPR_PC : exe_dst_r[15:0] <= IFD_EXE_pc_next;
    `OPR_S8 : exe_dst_r[15:0] <= {{8{IFD_EXE_op[15]}},IFD_EXE_op[15:8]};
    `OPR_U16: exe_dst_r[15:0] <= IFD_EXE_op[23:8];
    `OPR_BC : exe_dst_r[15:0] <= `BC_r;
    `OPR_DE : exe_dst_r[15:0] <= `DE_r;
    `OPR_SP : exe_dst_r[15:0] <= SP_r;
    `OPR_AF : exe_dst_r[15:0] <= `AF_r;
    `OPR_B  : exe_dst_r[15:0] <= {8'h0,B_r};
    `OPR_C  : exe_dst_r[15:0] <= {8'h0,C_r};
    `OPR_D  : exe_dst_r[15:0] <= {8'h0,D_r};
    `OPR_E  : exe_dst_r[15:0] <= {8'h0,E_r};
    `OPR_H  : exe_dst_r[15:0] <= {8'h0,H_r};
    `OPR_L  : exe_dst_r[15:0] <= {8'h0,L_r};
    `OPR_HL : exe_dst_r[15:0] <= `HL_r;
    `OPR_A  : exe_dst_r[15:0] <= {8'h0,A_r};
  endcase

  // condition code read
  exe_cc_r <= F_r;

  // debug writes
  if (REG_req_dbg) begin
    case (REG_address)
      8'h60: if (reg_src_r) A_r <= REG_req_data;
      8'h61: if (reg_src_r) F_r[7:4] <= REG_req_data[7:4];
      8'h62: if (reg_src_r) B_r <= REG_req_data;
      8'h63: if (reg_src_r) C_r <= REG_req_data;
      8'h64: if (reg_src_r) D_r <= REG_req_data;
      8'h65: if (reg_src_r) E_r <= REG_req_data;
      8'h66: if (reg_src_r) H_r <= REG_req_data;
      8'h67: if (reg_src_r) L_r <= REG_req_data;
      8'h68: if (reg_src_r) SP_r[7:0] <= REG_req_data;
      8'h69: if (reg_src_r) SP_r[15:8] <= REG_req_data;
      //8'h6A:
      //8'h6B:
      8'h6C: if (reg_src_r) exe_ime_r <= REG_req_data[0];
    endcase
  end
end

//-------------------------------------------------------------------
// DMA
//-------------------------------------------------------------------

parameter
  ST_DMA_IDLE      = 4'b0001,
  ST_DMA_READ      = 4'b0010,
  ST_DMA_READ_WAIT = 4'b0100,
  ST_DMA_WRITE     = 4'b1000;

reg  [3:0]  dma_state_r;
reg  [7:0]  dma_addr_r;
reg         dma_req_r;
reg         dma_src_r;
reg  [7:0]  dma_data_r;

assign      DMA_SYS_active  = ~|(dma_state_r & ST_DMA_IDLE) & ~dma_src_r;
assign      DMA_VRAM_active = ~|(dma_state_r & ST_DMA_IDLE) &  dma_src_r;
assign      DMA_active      = DMA_SYS_active | DMA_VRAM_active;

assign      DMA_req_val = |(dma_state_r & ST_DMA_READ_WAIT) & dma_req_r;
assign      DMA_address = {REG_DMA_r,dma_addr_r};

assign      DMA_OAM_req_val  = |(dma_state_r & ST_DMA_WRITE);
assign      DMA_OAM_address  = dma_addr_r;
assign      DMA_OAM_req_data = dma_data_r;

assign      HLT_DMA_rsp = HLT_REQ_sync & ~DMA_active;

always @(posedge CLK) begin
  if (cpu_ireset_r) begin
    dma_state_r <= ST_DMA_IDLE;
    dma_req_r <= 0;
  end
  else begin
    dma_src_r <= (REG_DMA_r[7:5] == 3'b100) ? 1 : 0;

    case (dma_state_r)
      ST_DMA_IDLE: begin
        dma_addr_r <= 0;

        // sync start of DMA request to BUS edge
        if (REG_DMA_start & CLK_BUS_EDGE) dma_state_r <= ST_DMA_READ;
      end
      ST_DMA_READ: begin
        if (CLK_BUS_EDGE & ~EXE_DMA_halt) begin
          // sync to one read/write pair per cycle
          dma_req_r <= 1;

          dma_state_r <= ST_DMA_READ_WAIT;
        end
      end
      ST_DMA_READ_WAIT: begin
        dma_req_r <= 0;
        dma_data_r <= dma_src_r ? VRAM_data : SYS_RDDATA;

        // address available 1 cycle early and we have the VRAM bus so not necessary to wait an extra clock
        if (~dma_req_r & (dma_src_r | SYS_RDY)) dma_state_r <= ST_DMA_WRITE;
      end
      ST_DMA_WRITE: begin
        dma_addr_r <= dma_addr_r + 1;

        dma_state_r <= (dma_addr_r[7] & dma_addr_r[4] & &dma_addr_r[3:0]) ? ST_DMA_IDLE : ST_DMA_READ;
      end
    endcase
  end
end

//-------------------------------------------------------------------
// PPU
//-------------------------------------------------------------------

wire        vram_wren    = DMA_VRAM_active ? 0                 : PPU_VRAM_active ? 0                : MCT_VRAM_wren;
wire [12:0] vram_address = DMA_VRAM_active ? DMA_address[12:0] : PPU_VRAM_active ? PPU_VRAM_address : MCT_VRAM_address;
wire [7:0]  vram_rddata;
wire [7:0]  vram_wrdata  = MCT_VRAM_data;

wire        dbg_vram_wren;
wire [12:0] dbg_vram_address;
wire [7:0]  dbg_vram_rddata;
wire [7:0]  dbg_vram_wrdata;

`ifdef MK2
vram vram (
  .clka(CLK), // input clka
  .wea(vram_wren), // input [0 : 0] wea
  .addra(vram_address), // input [12 : 0] addra
  .dina(vram_wrdata), // input [7 : 0] dina
  .douta(vram_rddata), // output [7 : 0] douta
  .clkb(CLK), // input clkb
  .web(dbg_vram_wren), // input [0 : 0] web
  .addrb(dbg_vram_address), // input [12 : 0] addrb
  .dinb(dbg_vram_wrdata), // input [7 : 0] dinb
  .doutb(dbg_vram_rddata) // output [7 : 0] doutb
);
`endif
`ifdef MK3
vram vram (
  .clock(CLK), // input clka
  .wren_a(vram_wren), // input [0 : 0] wea
  .address_a(vram_address), // input [12 : 0] addra
  .data_a(vram_wrdata), // input [7 : 0] dina
  .q_a(vram_rddata), // output [7 : 0] douta
  .wren_b(dbg_vram_wren), // input [0 : 0] web
  .address_b(dbg_vram_address), // input [12 : 0] addrb
  .data_b(dbg_vram_wrdata), // input [7 : 0] dinb
  .q_b(dbg_vram_rddata) // output [7 : 0] doutb
);
`endif

wire        oam_wren    = DMA_active ? DMA_OAM_req_val  : PPU_OAM_active ? 0               : MCT_OAM_wren;
wire [7:0]  oam_address = DMA_active ? DMA_OAM_address  : PPU_OAM_active ? PPU_OAM_address : MCT_OAM_address;
wire [7:0]  oam_rddata;
wire [7:0]  oam_wrdata  = DMA_active ? DMA_OAM_req_data : MCT_OAM_data;

wire        dbg_oam_wren;
wire [7:0]  dbg_oam_address;
wire [7:0]  dbg_oam_rddata;
wire [7:0]  dbg_oam_wrdata;

`ifdef MK2
oam oam (
  .clka(CLK), // input clka
  .wea(oam_wren), // input [0 : 0] wea
  .addra(oam_address), // input [7 : 0] addra
  .dina(oam_wrdata), // input [7 : 0] dina
  .douta(oam_rddata), // output [7 : 0] douta
  .clkb(CLK), // input clkb
  .web(dbg_oam_wren), // input [0 : 0] web
  .addrb(dbg_oam_address), // input [7 : 0] addrb
  .dinb(dbg_oam_wrdata), // input [7 : 0] dinb
  .doutb(dbg_oam_rddata) // output [7 : 0] doutb
);
`endif
`ifdef MK3
oam oam (
  .clock(CLK), // input clka
  .wren_a(oam_wren), // input [0 : 0] wea
  .address_a(oam_address), // input [7 : 0] addra
  .data_a(oam_wrdata), // input [7 : 0] dina
  .q_a(oam_rddata), // output [7 : 0] douta
  .wren_b(dbg_oam_wren), // input [0 : 0] web
  .address_b(dbg_oam_address), // input [7 : 0] addrb
  .data_b(dbg_oam_wrdata), // input [7 : 0] dinb
  .q_b(dbg_oam_rddata) // output [7 : 0] doutb
);
`endif

`define MODE_H      0 // HBLANK
`define MODE_V      1 // VBLANK
`define MODE_O      2 // OAM READ
`define MODE_D      3 // DISPLAY WRITE

`define OBJ_FIFO_PIXEL  1:0
`define OBJ_FIFO_PRI    2:2
`define OBJ_FIFO_PAL    3:3

parameter
  ST_PPU_OFF     = 13'b0000000000001,
  ST_PPU_FRM_NEW = 13'b0000000000010,
  ST_PPU_OAM_NEW = 13'b0000000000100,
  ST_PPU_OAM_POS = 13'b0000000001000,
  ST_PPU_PIX_NEW = 13'b0000000010000,
  ST_PPU_PIX_MAP = 13'b0000000100000,
  ST_PPU_PIX_DT0 = 13'b0000001000000,
  ST_PPU_PIX_DT1 = 13'b0000010000000,
  ST_PPU_PIX_OB0 = 13'b0000100000000,
  ST_PPU_PIX_OB1 = 13'b0001000000000,
  ST_PPU_PIX_OB2 = 13'b0010000000000,
  ST_PPU_HBL     = 13'b0100000000000,
  ST_PPU_VBL     = 13'b1000000000000;

reg  [12:0] ppu_state_r;

reg  [8:0]  ppu_dot_ctr_r;
reg  [5:0]  ppu_tile_ctr_r;   // 32 tiles with 8 pixels in a 256 pixel source tile data.  extra bit covers negative values
reg  [7:0]  ppu_pix_ctr_r;
reg  [7:0]  ppu_scanline_r;

wire        ppu_vram_active = |(ppu_state_r & (ST_PPU_PIX_NEW | ST_PPU_PIX_MAP | ST_PPU_PIX_DT0 | ST_PPU_PIX_DT1 | ST_PPU_PIX_OB0 | ST_PPU_PIX_OB1 | ST_PPU_PIX_OB2));
wire        ppu_oam_active  = ~|(ppu_state_r & (ST_PPU_OFF | ST_PPU_HBL | ST_PPU_VBL));
assign      PPU_vblank      = |(ppu_state_r & ST_PPU_VBL);

reg         ppu_first_frame_r;

reg  [7:0]  ppu_oam_address_r;
reg  [7:0]  ppu_oam_rddata_r;
reg  [7:0]  ppu_oam_data_r;
reg  [12:0] ppu_vram_address_r;
reg  [7:0]  ppu_vram_data_r;

// OAM lookup table
`ifdef SGB_SPR_INCREASE
`define NUM_OAM_LUT 16
reg  [5:0]  ppu_oam_lut_cnt_r;
wire        ppu_feat_spr_increase = FEAT[`SGB_FEAT_SPR_INCREASE];
wire        ppu_oam_lut_full = ppu_feat_spr_increase ? ppu_oam_lut_cnt_r[4] : (ppu_oam_lut_cnt_r[3] & ppu_oam_lut_cnt_r[1]);
`else
`define NUM_OAM_LUT 10
reg  [3:0]  ppu_oam_lut_cnt_r;
wire        ppu_oam_lut_full = ppu_oam_lut_cnt_r[3] & ppu_oam_lut_cnt_r[1];
`endif
reg  [3:0]  ppu_oam_lut_ypos_r[`NUM_OAM_LUT-1:0];
reg  [7:0]  ppu_oam_lut_xpos_r[`NUM_OAM_LUT-1:0];
reg  [5:0]  ppu_oam_lut_index_r[`NUM_OAM_LUT-1:0];
wire        ppu_oam_end      = ppu_oam_address_r[7] & &ppu_oam_address_r[4:2]; // 159 + 1 = 160 bytes (40 entries of 4 bytes each)

// window
reg  [7:0]  ppu_pix_win_line_r;
reg  [4:0]  ppu_pix_win_tile_r;
wire [8:0]  ppu_pix_wx_m7      = {1'b0,REG_WX_r} - 7;
wire        ppu_pix_win_active = REG_LCDC_r[`LCDC_WD_EN] && ppu_scanline_r >= REG_WY_r && $signed(ppu_tile_ctr_r[5:0]) >= $signed(ppu_pix_wx_m7[8:3]);
reg         ppu_pix_win_active_r;

wire [7:0]  ppu_pix_row      = ppu_scanline_r + REG_SCY_r;
wire [4:0]  ppu_pix_col      = ppu_tile_ctr_r[4:0] + REG_SCX_r[7:3] + (|REG_SCX_r[2:0] ? 1 : 0);
wire [7:0]  ppu_pix_win_row  = ppu_pix_win_line_r;
wire [4:0]  ppu_pix_win_col  = ppu_pix_win_tile_r[4:0];

wire [1:0]  ppu_tile_ctr_next = ppu_tile_ctr_r[1:0] + 1;
wire        ppu_tile_dummy = ppu_tile_ctr_r[4] & ppu_tile_ctr_r[3];

wire        ppu_pix_end = ppu_pix_ctr_r[7] & ppu_pix_ctr_r[5];
wire        ppu_dot_edge = CLK_CPU_EDGE;
wire        ppu_dot_end  = &ppu_dot_ctr_r[8:6] & &ppu_dot_ctr_r[2:0];             // 455+1 = 456 dots
wire        ppu_vis_end  = ppu_scanline_r[7] & &ppu_scanline_r[3:0];                          // 143+1 = 144 lines
wire        ppu_disp_end = ppu_scanline_r[7] & ppu_scanline_r[4] & ppu_scanline_r[3] & ppu_scanline_r[0]; // 153+1 = 154 lines
wire        ppu_tile_end = ~ppu_tile_dummy & ppu_tile_ctr_r[4] & &ppu_tile_ctr_r[1:0];      // 159+1 = 160 pixels, 19+1 = 20 tiles

wire        ppu_fifo_data = ~ppu_tile_dummy && ppu_pix_ctr_r[5:3] != ppu_tile_ctr_r[2:0] && ~ppu_pix_end;

wire [2:0]  ppu_bgw_fifo_index_start = (ppu_pix_win_active_r ? REG_WX_r[2:0] : ~REG_SCX_r[2:0]) + 1;
reg  [1:0]  ppu_bgw_fifo_r[31:0]; // 4 [tiles] * 8 [pixels/tile] * 2 [bpp]
reg  [7:0]  ppu_pix_bgw_data_r;

reg  [3:0]  ppu_obj_fifo_r[31:0]; // 4 [tiles] * 8 [pixels/tile] * 1+1+2[bpp,pri,pal]
reg  [7:0]  ppu_obj_fifo_transparent_r;
reg  [7:0]  ppu_pix_obj_data_r;

wire        ppu_hsync    = ppu_dot_edge & ppu_dot_end;
wire        ppu_vsync    = ppu_dot_edge & ppu_dot_end & ppu_disp_end;

reg         ppu_pix_phase_r;
reg         ppu_vblank_pulse_r;
reg         ppu_vblank_seen_r;
reg         ppu_stat_active_r;
reg  [7:0]  ppu_stat_match_r;
reg         ppu_dot_start_r;
reg         ppu_stat_write_r;

// OAM LUT lookup operation
reg         ppu_oam_lut_found;
reg  [3:0]  ppu_oam_lut_match;
always @(ppu_oam_lut_xpos_r[0],ppu_oam_lut_xpos_r[1],ppu_oam_lut_xpos_r[2],ppu_oam_lut_xpos_r[3],ppu_oam_lut_xpos_r[4],
         ppu_oam_lut_xpos_r[5],ppu_oam_lut_xpos_r[6],ppu_oam_lut_xpos_r[7],ppu_oam_lut_xpos_r[8],ppu_oam_lut_xpos_r[9],
         ppu_tile_ctr_r) begin
  ppu_oam_lut_match = 4'hF;
  ppu_oam_lut_found = 0;
  for (i = 0; i < `NUM_OAM_LUT; i = i + 1) begin
    if (ppu_oam_lut_xpos_r[i][7:3] == ppu_tile_ctr_r[4:0] && ~ppu_oam_lut_found) begin
      ppu_oam_lut_match = i[3:0];
      ppu_oam_lut_found = 1;
    end
  end
end

reg         ppu_pix_oam_lut_found_r;
reg  [3:0]  ppu_pix_oam_lut_match_r;
reg  [7:0]  ppu_pix_oam_tile_num_r;
reg  [7:0]  ppu_pix_oam_flag_r;
reg  [7:0]  ppu_oam_obj_xpos_r;
wire [3:0]  ppu_pix_obj_row = (ppu_scanline_r[3:0] - ppu_oam_lut_ypos_r[ppu_pix_oam_lut_match_r][3:0]) ^ {4{ppu_pix_oam_flag_r[6]}};

reg         ppu_bgw_fifo_wr_req_r;
reg  [4:0]  ppu_bgw_fifo_wr_req_index_r;
reg  [1:0]  ppu_bgw_fifo_wr_req_data_r[7:0];
reg         ppu_bgw_fifo_wr_active_r;
reg  [4:0]  ppu_bgw_fifo_wr_index_r;
reg  [2:0]  ppu_bgw_fifo_wr_cnt_r;
reg  [1:0]  ppu_bgw_fifo_wr_data_r;

reg         ppu_obj_fifo_wr_req_r;
reg  [4:0]  ppu_obj_fifo_wr_req_index_r;
reg  [3:0]  ppu_obj_fifo_wr_req_data_r[7:0];
reg         ppu_obj_fifo_wr_active_r;
reg  [4:0]  ppu_obj_fifo_wr_index_r;
reg  [2:0]  ppu_obj_fifo_wr_cnt_r;
reg  [3:0]  ppu_obj_fifo_wr_data_r;
reg         ppu_obj_fifo_wr_req_clear_r;

assign      VRAM_data = vram_rddata;
assign      OAM_data  = oam_rddata;

assign      PPU_VRAM_active  = ppu_vram_active;
assign      PPU_VRAM_address = ppu_vram_address_r;
assign      PPU_OAM_active   = ppu_oam_active;
assign      PPU_OAM_address  = ppu_oam_address_r;
assign      PPU_REG_vblank   = ppu_vblank_pulse_r;
assign      PPU_REG_lcd_stat = ~ppu_stat_active_r & |ppu_stat_match_r;

assign      PPU_MCT_vram_active = ppu_vram_active;
assign      PPU_MCT_oam_active  = ppu_oam_active;

wire  [1:0] ppu_bgw_index = ppu_bgw_fifo_r[ppu_pix_ctr_r[4:0]][1:0];
wire  [1:0] ppu_obj_index = ppu_obj_fifo_r[ppu_pix_ctr_r[4:0]][1:0];
reg         ppu_obj_pal;
reg         ppu_obj_pri;

// Xilinx compiler can silently fail if we don't expand out the obj fifo reads in a case statement.
always @(ppu_pix_ctr_r,
         ppu_obj_fifo_r[0 ][3:2],ppu_obj_fifo_r[1 ][3:2],ppu_obj_fifo_r[2 ][3:2],ppu_obj_fifo_r[3 ][3:2],ppu_obj_fifo_r[4 ][3:2],ppu_obj_fifo_r[5 ][3:2],ppu_obj_fifo_r[6 ][3:2],ppu_obj_fifo_r[7 ][3:2],
         ppu_obj_fifo_r[8 ][3:2],ppu_obj_fifo_r[9 ][3:2],ppu_obj_fifo_r[10][3:2],ppu_obj_fifo_r[11][3:2],ppu_obj_fifo_r[12][3:2],ppu_obj_fifo_r[13][3:2],ppu_obj_fifo_r[14][3:2],ppu_obj_fifo_r[15][3:2],
         ppu_obj_fifo_r[16][3:2],ppu_obj_fifo_r[17][3:2],ppu_obj_fifo_r[18][3:2],ppu_obj_fifo_r[19][3:2],ppu_obj_fifo_r[20][3:2],ppu_obj_fifo_r[21][3:2],ppu_obj_fifo_r[22][3:2],ppu_obj_fifo_r[23][3:2],
         ppu_obj_fifo_r[24][3:2],ppu_obj_fifo_r[25][3:2],ppu_obj_fifo_r[26][3:2],ppu_obj_fifo_r[27][3:2],ppu_obj_fifo_r[28][3:2],ppu_obj_fifo_r[29][3:2],ppu_obj_fifo_r[30][3:2],ppu_obj_fifo_r[31][3:2]
         ) begin
  case (ppu_pix_ctr_r[4:0])
    0:  {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[0 ][3:2];
    1:  {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[1 ][3:2];
    2:  {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[2 ][3:2];
    3:  {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[3 ][3:2];
    4:  {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[4 ][3:2];
    5:  {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[5 ][3:2];
    6:  {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[6 ][3:2];
    7:  {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[7 ][3:2];
    8:  {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[8 ][3:2];
    9:  {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[9 ][3:2];
    10: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[10][3:2];
    11: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[11][3:2];
    12: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[12][3:2];
    13: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[13][3:2];
    14: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[14][3:2];
    15: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[15][3:2];
    16: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[16][3:2];
    17: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[17][3:2];
    18: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[18][3:2];
    19: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[19][3:2];
    20: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[20][3:2];
    21: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[21][3:2];
    22: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[22][3:2];
    23: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[23][3:2];
    24: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[24][3:2];
    25: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[25][3:2];
    26: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[26][3:2];
    27: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[27][3:2];
    28: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[28][3:2];
    29: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[29][3:2];
    30: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[30][3:2];
    31: {ppu_obj_pri,ppu_obj_pal} = ppu_obj_fifo_r[31][3:2];
  endcase
end

// merge background and object indices and derive pixel values
assign      PPU_PIXEL = HLT_REQ_sync ? 2'b00
                      : (~|ppu_obj_index | (|ppu_bgw_index & ppu_obj_pri)) ? ( (ppu_bgw_index == 0) ? REG_BGP_r[1:0]
                                                                             : (ppu_bgw_index == 1) ? REG_BGP_r[3:2]
                                                                             : (ppu_bgw_index == 2) ? REG_BGP_r[5:4]
                                                                             :                        REG_BGP_r[7:6]
                                                                             )
                                                                           : ( (ppu_obj_index == 0) ? (ppu_obj_pal ? REG_OBP1_r[1:0] : REG_OBP0_r[1:0])
                                                                             : (ppu_obj_index == 1) ? (ppu_obj_pal ? REG_OBP1_r[3:2] : REG_OBP0_r[3:2])
                                                                             : (ppu_obj_index == 2) ? (ppu_obj_pal ? REG_OBP1_r[5:4] : REG_OBP0_r[5:4])
                                                                             :                        (ppu_obj_pal ? REG_OBP1_r[7:6] : REG_OBP0_r[7:6])
                                                                           );

assign      PPU_DOT_EDGE    = ppu_dot_edge;
assign      PPU_HSYNC_EDGE  = ppu_hsync;
assign      PPU_VSYNC_EDGE  = ppu_vsync;
assign      PPU_PIXEL_VALID = ppu_fifo_data;

reg         dbg_state_valid_r;
reg  [7:0]  dbg_reg_ly_r;
reg  [8:0]  dbg_dot_ctr_r;
reg  [8:0]  dbg_dot_ctr_next_r;
reg         dbg_oam_active_r;
reg         dbg_vram_active_r;
reg         dbg_dma_active_r;
reg  [7:0]  dbg_ppu_stat_match_r;
reg  [8:0]  dbg_ppu_stat_dot_ctr_r;

always @(posedge CLK) begin
  if (cpu_ireset_r) begin
    REG_STAT_r[`STAT_MODE]      <= `MODE_H;
    REG_STAT_r[`STAT_LYC_MATCH] <= 0;
    REG_LY_r                    <= 0;

    ppu_scanline_r <= 0;

    ppu_tile_ctr_r <= 0;
    ppu_pix_ctr_r  <= 0;

    ppu_dot_ctr_r <= 0;

    ppu_state_r <= ST_PPU_OFF;

    ppu_vblank_pulse_r <= 0;
    ppu_stat_active_r <= 0;
    ppu_stat_match_r <= 0;

    ppu_bgw_fifo_wr_req_r <= 0;
    ppu_bgw_fifo_wr_active_r <= 0;
    ppu_obj_fifo_wr_req_r <= 0;
    ppu_obj_fifo_wr_active_r <= 0;

    ppu_stat_write_r <= 0;

    dbg_dot_ctr_next_r <= 0;
    dbg_dot_ctr_r      <= 0;
  end
  else begin
    // The active scanline pixel output is composed of 3 distinct phases:
    // - OAM test and buffer (~80 dot clocks)
    // - pixel output        (166-180 dot clocks)
    // - h-blank             (remaining dot clocks in 456 scanline)
    //
    // A VRAM access takes 2 dot clocks and an OAM access takes 1 dot clock.
    //
    // The phases of the display rendering are:
    // 0 - hblank/display disable
    // 1 - vblank
    // 2 - OAM testing
    // 3 - display
    //
    // Sequencing:
    // - [OFF->VBL] The display is enabled by the sofware during the vblank region.  This is the initial condition.
    //
    // - [VBL->OAM] OAM testing is performed to find up to 10 matching valid sprites in the scanline
    //   - Tests are performed on ypos and need to account for 8x8 vs 8x16 size.
    //   - There are 40 sprites to test and OAM is assumed to take 1 dot clock to read.  This is separated into a
    //     ypos read clock followed by a test/xpos read clock.
    //   - A lookup table is kept with xpos and a pointer to the associated OAM entry.
    // - [OAM->PIX] PIX reads the BG or window MAP, 2 bytes of 8 pixels, and then tests OAM matches on the current row.
    // - [PIX->HBL] HBL is when we are in hblank
    // - [HBL->OAM] From HBL we can transition back to OAM if the new line is visible
    // - [HBL->VBL] From HBL we can transition to VBL (vblank) if the visible lines are complete

    // debug
    if (CLK_BUS_EDGE) begin
      if      (exe_advance_r) begin
        dbg_state_valid_r <= 0;
      end
      else if (~dbg_state_valid_r) begin
        dbg_state_valid_r <= 1;

        dbg_reg_ly_r       <= REG_LY_r;
        {dbg_dot_ctr_r,dbg_dot_ctr_next_r} <= {dbg_dot_ctr_next_r,ppu_dot_ctr_r};
        dbg_oam_active_r   <= PPU_OAM_active;
        dbg_vram_active_r  <= PPU_VRAM_active;
        dbg_dma_active_r   <= DMA_active;
      end
    end

    if      (REG_req_val && REG_address == 8'h41) ppu_stat_write_r <= 1;
    else if (ppu_dot_edge)                        ppu_stat_write_r <= 0;

    // flop match
    ppu_pix_oam_lut_match_r <= ppu_oam_lut_match;
    ppu_pix_oam_lut_found_r <= ppu_oam_lut_found & ~(ppu_first_frame_r|~REG_LCDC_r[`LCDC_SP_EN] | DMA_active);

    ppu_oam_rddata_r <= oam_rddata;

    // Xilinx compiler (MK2) can silently fail if we don't expand out the pixel fifo writes in a case statement.  Same goes for the packet buffer in ICD and others.
    // This results in a lot of code verbosity, but it works.
    ppu_bgw_fifo_wr_req_r <= 0;
    if (ppu_bgw_fifo_wr_req_r) begin
      ppu_bgw_fifo_wr_active_r <= 1;
      ppu_bgw_fifo_wr_index_r <= ppu_bgw_fifo_wr_req_index_r;
      ppu_bgw_fifo_wr_cnt_r <= 1;

      ppu_bgw_fifo_wr_data_r <= ppu_bgw_fifo_wr_req_data_r[0];
    end
    else if (ppu_bgw_fifo_wr_active_r) begin
      case (ppu_bgw_fifo_wr_index_r[4:0])
        0:  ppu_bgw_fifo_r[0 ] <= ppu_bgw_fifo_wr_data_r;
        1:  ppu_bgw_fifo_r[1 ] <= ppu_bgw_fifo_wr_data_r;
        2:  ppu_bgw_fifo_r[2 ] <= ppu_bgw_fifo_wr_data_r;
        3:  ppu_bgw_fifo_r[3 ] <= ppu_bgw_fifo_wr_data_r;
        4:  ppu_bgw_fifo_r[4 ] <= ppu_bgw_fifo_wr_data_r;
        5:  ppu_bgw_fifo_r[5 ] <= ppu_bgw_fifo_wr_data_r;
        6:  ppu_bgw_fifo_r[6 ] <= ppu_bgw_fifo_wr_data_r;
        7:  ppu_bgw_fifo_r[7 ] <= ppu_bgw_fifo_wr_data_r;
        8:  ppu_bgw_fifo_r[8 ] <= ppu_bgw_fifo_wr_data_r;
        9:  ppu_bgw_fifo_r[9 ] <= ppu_bgw_fifo_wr_data_r;
        10: ppu_bgw_fifo_r[10] <= ppu_bgw_fifo_wr_data_r;
        11: ppu_bgw_fifo_r[11] <= ppu_bgw_fifo_wr_data_r;
        12: ppu_bgw_fifo_r[12] <= ppu_bgw_fifo_wr_data_r;
        13: ppu_bgw_fifo_r[13] <= ppu_bgw_fifo_wr_data_r;
        14: ppu_bgw_fifo_r[14] <= ppu_bgw_fifo_wr_data_r;
        15: ppu_bgw_fifo_r[15] <= ppu_bgw_fifo_wr_data_r;
        16: ppu_bgw_fifo_r[16] <= ppu_bgw_fifo_wr_data_r;
        17: ppu_bgw_fifo_r[17] <= ppu_bgw_fifo_wr_data_r;
        18: ppu_bgw_fifo_r[18] <= ppu_bgw_fifo_wr_data_r;
        19: ppu_bgw_fifo_r[19] <= ppu_bgw_fifo_wr_data_r;
        20: ppu_bgw_fifo_r[20] <= ppu_bgw_fifo_wr_data_r;
        21: ppu_bgw_fifo_r[21] <= ppu_bgw_fifo_wr_data_r;
        22: ppu_bgw_fifo_r[22] <= ppu_bgw_fifo_wr_data_r;
        23: ppu_bgw_fifo_r[23] <= ppu_bgw_fifo_wr_data_r;
        24: ppu_bgw_fifo_r[24] <= ppu_bgw_fifo_wr_data_r;
        25: ppu_bgw_fifo_r[25] <= ppu_bgw_fifo_wr_data_r;
        26: ppu_bgw_fifo_r[26] <= ppu_bgw_fifo_wr_data_r;
        27: ppu_bgw_fifo_r[27] <= ppu_bgw_fifo_wr_data_r;
        28: ppu_bgw_fifo_r[28] <= ppu_bgw_fifo_wr_data_r;
        29: ppu_bgw_fifo_r[29] <= ppu_bgw_fifo_wr_data_r;
        30: ppu_bgw_fifo_r[30] <= ppu_bgw_fifo_wr_data_r;
        31: ppu_bgw_fifo_r[31] <= ppu_bgw_fifo_wr_data_r;
      endcase
      ppu_bgw_fifo_wr_index_r <= ppu_bgw_fifo_wr_index_r + 1;

      case (ppu_bgw_fifo_wr_cnt_r[2:0])
        0:  ppu_bgw_fifo_wr_data_r <= ppu_bgw_fifo_wr_req_data_r[0];
        1:  ppu_bgw_fifo_wr_data_r <= ppu_bgw_fifo_wr_req_data_r[1];
        2:  ppu_bgw_fifo_wr_data_r <= ppu_bgw_fifo_wr_req_data_r[2];
        3:  ppu_bgw_fifo_wr_data_r <= ppu_bgw_fifo_wr_req_data_r[3];
        4:  ppu_bgw_fifo_wr_data_r <= ppu_bgw_fifo_wr_req_data_r[4];
        5:  ppu_bgw_fifo_wr_data_r <= ppu_bgw_fifo_wr_req_data_r[5];
        6:  ppu_bgw_fifo_wr_data_r <= ppu_bgw_fifo_wr_req_data_r[6];
        7:  ppu_bgw_fifo_wr_data_r <= ppu_bgw_fifo_wr_req_data_r[7];
      endcase
      ppu_bgw_fifo_wr_cnt_r <= ppu_bgw_fifo_wr_cnt_r + 1;

      ppu_bgw_fifo_wr_active_r <= |ppu_bgw_fifo_wr_cnt_r;
    end

    ppu_obj_fifo_wr_req_r <= 0;
    if (ppu_obj_fifo_wr_req_r) begin
      ppu_obj_fifo_wr_active_r <= 1;
      ppu_obj_fifo_wr_index_r <= ppu_obj_fifo_wr_req_index_r;
      ppu_obj_fifo_wr_cnt_r <= 1;

      ppu_obj_fifo_wr_data_r <= ppu_obj_fifo_wr_req_data_r[0];
    end
    else if (ppu_obj_fifo_wr_active_r) begin
      case (ppu_obj_fifo_wr_index_r[4:0])
        0:  if (ppu_obj_fifo_r[0 ][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[0 ][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        1:  if (ppu_obj_fifo_r[1 ][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[1 ][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        2:  if (ppu_obj_fifo_r[2 ][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[2 ][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        3:  if (ppu_obj_fifo_r[3 ][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[3 ][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        4:  if (ppu_obj_fifo_r[4 ][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[4 ][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        5:  if (ppu_obj_fifo_r[5 ][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[5 ][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        6:  if (ppu_obj_fifo_r[6 ][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[6 ][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        7:  if (ppu_obj_fifo_r[7 ][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[7 ][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        8:  if (ppu_obj_fifo_r[8 ][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[8 ][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        9:  if (ppu_obj_fifo_r[9 ][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[9 ][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        10: if (ppu_obj_fifo_r[10][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[10][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        11: if (ppu_obj_fifo_r[11][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[11][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        12: if (ppu_obj_fifo_r[12][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[12][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        13: if (ppu_obj_fifo_r[13][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[13][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        14: if (ppu_obj_fifo_r[14][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[14][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        15: if (ppu_obj_fifo_r[15][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[15][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        16: if (ppu_obj_fifo_r[16][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[16][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        17: if (ppu_obj_fifo_r[17][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[17][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        18: if (ppu_obj_fifo_r[18][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[18][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        19: if (ppu_obj_fifo_r[19][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[19][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        20: if (ppu_obj_fifo_r[20][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[20][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        21: if (ppu_obj_fifo_r[21][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[21][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        22: if (ppu_obj_fifo_r[22][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[22][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        23: if (ppu_obj_fifo_r[23][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[23][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        24: if (ppu_obj_fifo_r[24][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[24][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        25: if (ppu_obj_fifo_r[25][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[25][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        26: if (ppu_obj_fifo_r[26][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[26][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        27: if (ppu_obj_fifo_r[27][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[27][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        28: if (ppu_obj_fifo_r[28][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[28][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        29: if (ppu_obj_fifo_r[29][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[29][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        30: if (ppu_obj_fifo_r[30][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[30][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
        31: if (ppu_obj_fifo_r[31][1:0] == 0 || ppu_obj_fifo_wr_req_clear_r) ppu_obj_fifo_r[31][3:0] <= ppu_obj_fifo_wr_data_r[3:0];
      endcase
      ppu_obj_fifo_wr_index_r <= ppu_obj_fifo_wr_index_r + 1;

      case (ppu_obj_fifo_wr_cnt_r[2:0])
        0:  ppu_obj_fifo_wr_data_r <= ppu_obj_fifo_wr_req_data_r[0];
        1:  ppu_obj_fifo_wr_data_r <= ppu_obj_fifo_wr_req_data_r[1];
        2:  ppu_obj_fifo_wr_data_r <= ppu_obj_fifo_wr_req_data_r[2];
        3:  ppu_obj_fifo_wr_data_r <= ppu_obj_fifo_wr_req_data_r[3];
        4:  ppu_obj_fifo_wr_data_r <= ppu_obj_fifo_wr_req_data_r[4];
        5:  ppu_obj_fifo_wr_data_r <= ppu_obj_fifo_wr_req_data_r[5];
        6:  ppu_obj_fifo_wr_data_r <= ppu_obj_fifo_wr_req_data_r[6];
        7:  ppu_obj_fifo_wr_data_r <= ppu_obj_fifo_wr_req_data_r[7];
      endcase
      ppu_obj_fifo_wr_cnt_r <= ppu_obj_fifo_wr_cnt_r + 1;

      ppu_obj_fifo_wr_active_r <= |ppu_obj_fifo_wr_cnt_r;
    end

    // scanline/state rendering datapath
    if (ppu_dot_edge & DBG_advance) begin
      ppu_pix_phase_r <= 0;

      // read pointer advance
      if (ppu_fifo_data) ppu_pix_ctr_r <= ppu_pix_ctr_r + 1;

      ppu_vblank_pulse_r <= 0;
      ppu_stat_active_r <= |ppu_stat_match_r;
      if (~ppu_stat_active_r & |ppu_stat_match_r) begin
        dbg_ppu_stat_match_r <= ppu_stat_match_r;
        dbg_ppu_stat_dot_ctr_r <= ppu_dot_ctr_r;
      end

      ppu_oam_data_r <= ppu_oam_rddata_r;

      case (ppu_state_r)
        ST_PPU_OFF     : begin
          // clear display state
          REG_STAT_r[`STAT_MODE] <= `MODE_H;

          REG_LY_r         <= 0;
          ppu_scanline_r   <= 0;

          ppu_tile_ctr_r <= 0;
          ppu_pix_ctr_r  <= 0;

          ppu_first_frame_r <= 1;

          ppu_vblank_seen_r <= 0;

          ppu_stat_match_r <= 0;

          if (REG_LCDC_r[`LCDC_DS_EN]) ppu_state_r <= ST_PPU_FRM_NEW;
        end
        ST_PPU_FRM_NEW : begin
          // next frame
          ppu_pix_win_line_r <= 8'hFF;

          // TODO: should we flop WY here for current frame?

          REG_STAT_r[`STAT_MODE] <= `MODE_H;

          ppu_state_r <= ST_PPU_OAM_NEW;
        end
        ST_PPU_OAM_NEW : begin
          // start of new line

          // setup initial address
          ppu_oam_address_r <= 0;

          // use -16 (instead of -8) in order to put the xpos before the dummy tile for empty entries
          for (i = 0; i < `NUM_OAM_LUT; i = i + 1) ppu_oam_lut_xpos_r[i] <= 0-16;

          // initialize all entries to be invalid
          ppu_oam_lut_cnt_r <= 0;

          REG_STAT_r[`STAT_MODE] <= `MODE_O;

          // WARNING: this needs to only be one dot cycle to avoid multiple interrupts.  Or we need to guard the interrupt with the same condition.
          ppu_state_r <= ST_PPU_OAM_POS;
        end
        ST_PPU_OAM_POS : begin
          // read in xpos if ypos is on this line
          if (~ppu_oam_lut_full & ppu_pix_phase_r & ~DMA_active) begin
            if (ppu_oam_data_r <= (ppu_scanline_r + 16) && (ppu_scanline_r + 16) < (ppu_oam_data_r + (REG_LCDC_r[`LCDC_SP_SIZE] ? 16 : 8))) begin
              ppu_oam_lut_ypos_r[ppu_oam_lut_cnt_r]  <= ppu_oam_data_r[3:0];
              ppu_oam_lut_xpos_r[ppu_oam_lut_cnt_r]  <= ppu_oam_rddata_r - (|ppu_oam_rddata_r ? 8 : 16);
              ppu_oam_lut_index_r[ppu_oam_lut_cnt_r] <= ppu_oam_address_r[7:2];

              ppu_oam_lut_cnt_r <= ppu_oam_lut_cnt_r + 1;
            end
          end

          // calculate new address
          ppu_oam_address_r <= ppu_oam_address_r + (ppu_pix_phase_r ? 3 : 1);

          if (ppu_oam_end & ppu_pix_phase_r) begin
            ppu_state_r <= ST_PPU_PIX_NEW;
          end

          ppu_pix_phase_r <= ~ppu_pix_phase_r;
        end
        ST_PPU_PIX_NEW : begin
          // new visible scanline

          // reset counter/pointer state
          // Start at tile -1 to handle scrolling and window offsets
          ppu_tile_ctr_r <= 6'h3F;  // partial fifo write pointer
          ppu_pix_ctr_r <= 0;       // fifo read pointer

          ppu_pix_win_active_r <= 0;

          REG_STAT_r[`STAT_MODE] <= `MODE_D;

          ppu_state_r <= ST_PPU_PIX_MAP;
        end
        ST_PPU_PIX_MAP : begin
          // generate map address
          ppu_vram_address_r <= ppu_pix_win_active_r ? {1'b1,1'b1,REG_LCDC_r[`LCDC_WD_MAP_SEL],ppu_pix_win_row[7:3],ppu_pix_win_col[4:0]} : {1'b1,1'b1,REG_LCDC_r[`LCDC_BG_MAP_SEL],ppu_pix_row[7:3],ppu_pix_col[4:0]};
          ppu_vram_data_r <= vram_rddata;

          if (ppu_pix_phase_r) ppu_state_r <= ST_PPU_PIX_DT0;

          ppu_pix_phase_r <= ~ppu_pix_phase_r;
        end
        ST_PPU_PIX_DT0 : begin
          // all BG tiles are consecutive 16B and naturally aligned
          ppu_vram_address_r <= {(~REG_LCDC_r[`LCDC_BG_TILE_SEL] & ~ppu_vram_data_r[7]),ppu_vram_data_r[7:0],(ppu_pix_win_active_r ? ppu_pix_win_row[2:0] : ppu_pix_row[2:0]),1'b0};

          ppu_pix_bgw_data_r <= vram_rddata;

          if (ppu_pix_phase_r) ppu_state_r <= ST_PPU_PIX_DT1;

          ppu_pix_phase_r <= ~ppu_pix_phase_r;
        end
        ST_PPU_PIX_DT1 : begin
          ppu_oam_address_r <= {ppu_oam_lut_index_r[ppu_pix_oam_lut_match_r],2'b10};
          ppu_vram_address_r <= {ppu_vram_address_r[12:1],1'b1};

          if (ppu_pix_phase_r) begin
            ppu_bgw_fifo_wr_req_r <= 1;

            // write bgw fifo with current pixel data
            ppu_bgw_fifo_wr_req_index_r <= {ppu_tile_ctr_r[1:0],ppu_bgw_fifo_index_start[2:0]};
            for (i = 0; i < 8; i = i + 1) ppu_bgw_fifo_wr_req_data_r[i][0] <= (ppu_first_frame_r|~REG_LCDC_r[`LCDC_BG_EN]) ? 1'b0 : ppu_pix_bgw_data_r[7-i];
            for (i = 0; i < 8; i = i + 1) ppu_bgw_fifo_wr_req_data_r[i][1] <= (ppu_first_frame_r|~REG_LCDC_r[`LCDC_BG_EN]) ? 1'b0 : vram_rddata[7-i];

            // clear object fifo for next set of sprite tiles
            ppu_obj_fifo_wr_req_r <= 1;
            ppu_obj_fifo_wr_req_clear_r <= 1;
            ppu_obj_fifo_wr_req_index_r <= {ppu_tile_ctr_next[1:0],3'h0};
            for (i = 0; i < 8; i = i + 1) ppu_obj_fifo_wr_req_data_r[i][3:0] <= 0;
          end

          if (ppu_pix_phase_r) begin
            // determine if there is a transition to window.  If so, render the new active mode on top of the old by repeating the BGW tile fetch
            ppu_pix_win_active_r <= ppu_pix_win_active;
            if (ppu_pix_win_active_r ^ ppu_pix_win_active) ppu_pix_win_line_r <= ppu_pix_win_line_r + 1;
            if (ppu_pix_win_active_r ^ ppu_pix_win_active) ppu_pix_win_tile_r <= 0;

            ppu_state_r <= (ppu_pix_win_active_r ^ ppu_pix_win_active) ? ST_PPU_PIX_MAP : ST_PPU_PIX_OB0;
          end

          ppu_pix_phase_r <= ~ppu_pix_phase_r;
        end
        ST_PPU_PIX_OB0 : begin
          ppu_oam_obj_xpos_r <= ppu_oam_lut_xpos_r[ppu_pix_oam_lut_match_r];

          ppu_oam_address_r <= {ppu_oam_address_r[7:1],1'b1};

          if (~ppu_pix_phase_r) ppu_pix_oam_tile_num_r <= ppu_oam_rddata_r; else ppu_pix_oam_flag_r <= ppu_oam_rddata_r;

          if (ppu_pix_phase_r) begin
            if (~ppu_pix_oam_lut_found_r) ppu_tile_ctr_r <= ppu_tile_ctr_r + 1;
            if (~ppu_pix_oam_lut_found_r) ppu_pix_win_tile_r <= ppu_pix_win_tile_r + 1;

            ppu_state_r <= ppu_pix_oam_lut_found_r ? ST_PPU_PIX_OB1 : (ppu_tile_end ? ST_PPU_HBL : ST_PPU_PIX_MAP);
          end

          ppu_pix_phase_r <= ~ppu_pix_phase_r;
        end
        ST_PPU_PIX_OB1 : begin
          ppu_vram_address_r <= {1'b0,ppu_pix_oam_tile_num_r[7:1],(REG_LCDC_r[`LCDC_SP_SIZE] ? ppu_pix_obj_row[3] : ppu_pix_oam_tile_num_r[0]),ppu_pix_obj_row[2:0],1'b0};

          // read second half of tile
          ppu_pix_obj_data_r <= vram_rddata;

          if (ppu_pix_phase_r) begin
            ppu_state_r <= ST_PPU_PIX_OB2;
          end

          ppu_pix_phase_r <= ~ppu_pix_phase_r;
        end
        ST_PPU_PIX_OB2 : begin
          ppu_vram_address_r <= {ppu_vram_address_r[12:1],1'b1};

          // clear match for second phase
          if (~ppu_pix_phase_r) ppu_oam_lut_xpos_r[ppu_pix_oam_lut_match_r] <= 0-16;

          if (ppu_pix_phase_r) begin
            // get address of next match
            ppu_oam_address_r <= {ppu_oam_lut_index_r[ppu_pix_oam_lut_match_r],2'b10};

            ppu_obj_fifo_wr_req_r <= 1;
            ppu_obj_fifo_wr_req_clear_r <= 0;
            ppu_obj_fifo_wr_req_index_r <= ppu_oam_obj_xpos_r[4:0];
            for (i = 0; i < 8; i = i + 1) ppu_obj_fifo_wr_req_data_r[i][0] <= ppu_pix_oam_flag_r[5] ? ppu_pix_obj_data_r[i] : ppu_pix_obj_data_r[7-i];
            for (i = 0; i < 8; i = i + 1) ppu_obj_fifo_wr_req_data_r[i][1] <= ppu_pix_oam_flag_r[5] ? vram_rddata[i]        : vram_rddata[7-i];
            for (i = 0; i < 8; i = i + 1) ppu_obj_fifo_wr_req_data_r[i][2] <= ppu_pix_oam_flag_r[4];
            for (i = 0; i < 8; i = i + 1) ppu_obj_fifo_wr_req_data_r[i][3] <= ppu_pix_oam_flag_r[7];

            ppu_state_r <= ST_PPU_PIX_OB0;
          end

          ppu_pix_phase_r <= ~ppu_pix_phase_r;
        end
        ST_PPU_HBL     : begin
          if (~ppu_fifo_data) begin
            ppu_tile_ctr_r <= 0;
            ppu_pix_ctr_r  <= 0;

            // TODO: late timer interrupt causes us to miss MODE_D during stat interrupt in PBF.  Check if dot clock count is larger than some amount
            // Need to look at potential problems:
            // PBD wanted it pushed another bus clock (260->264).
            // 1) timer interrupt starting at the very last cycle is not supposed to happen
            // 2) draw mode needs to be extended by a few clocks
            // 3) interrupts are supposed to be faster.  e.g. is taking interrupt actually 4 bus clocks like RST (should solve the problem)
            if (ppu_dot_ctr_r >= 264) REG_STAT_r[`STAT_MODE] <= `MODE_H; // H-Blank mode starts when the fifos have been consumed
          end

          ppu_vblank_seen_r <= 0;

          if (ppu_dot_end) begin
            ppu_state_r <= ppu_vis_end ? ST_PPU_VBL : ST_PPU_OAM_NEW;
          end
        end
        ST_PPU_VBL     : begin
          REG_STAT_r[`STAT_MODE] <= `MODE_V;

          if (~ppu_vblank_seen_r & ppu_dot_ctr_r[0]) begin
            // assert on dot clock 2
            ppu_vblank_pulse_r <= 1;

            ppu_vblank_seen_r <= 1;
          end

          ppu_first_frame_r <= 0;

          if (ppu_dot_end) begin
            if (ppu_disp_end) ppu_state_r <= ST_PPU_FRM_NEW;
          end
        end
      endcase

      if (~|(ppu_state_r & ST_PPU_OFF)) begin
        // It's possible for a write to happen on the last dot cycle which will cause us to miss a 1->0->1 transition.
        //
        // dot clk
        // 0 - LY_r
        // 1 - match
        // 2 - ppu_stat_active_r[0]
        // 3 - IF/earliest interrupt point
        // 3+?    - Wait for current instruction to finish. 4 * (0-6)
        // 3+?+20 - +20 = 5 * 4 dot clocks to take interrupt

        // P-M breaks if the transition to 0 on line 153 happens too early.
        // BMF expects REG_LY_r to transition from 153->0 early in the line.
        if (ppu_dot_end) ppu_scanline_r <= ppu_disp_end ? 0 : ppu_scanline_r + 1;
        if (ppu_dot_end) REG_LY_r <= ppu_disp_end ? 0 : REG_LY_r + 1; else if (&ppu_dot_ctr_r[3:2] & ppu_disp_end) REG_LY_r <= 0;

        // TODO: is the match clear necessary?  Seems like the use case for it originally was actually a STAT write spurious interrupt.
        // Definitely can't clear on the last line or it causes problems with double interrupts for LYC==0.
        REG_STAT_r[`STAT_LYC_MATCH] <= (REG_LY_r == REG_LYC_r && ~(ppu_dot_end & ~ppu_disp_end)) ? 1 : 0;

        // PBF limits IRQs by transitioning between enabled modes on the same cycle (M->O)
        // RR expects stat write to trigger spurious interrupt during V-Blank to make menu->game not lock.  144 V-Blank Int -> 147-148 Spurious STAT (V-Blank) Int -> 153 STAT (LY==LYC==0) Int -> 0 STAT (H-Blank) Int
        ppu_stat_match_r[`STAT_INT_H_EN] <= (REG_STAT_r[`STAT_INT_H_EN] | ppu_stat_write_r) & |(ppu_state_r & ST_PPU_HBL);
        ppu_stat_match_r[`STAT_INT_V_EN] <= (REG_STAT_r[`STAT_INT_V_EN] | ppu_stat_write_r) & |(ppu_state_r & ST_PPU_VBL);
        ppu_stat_match_r[`STAT_INT_O_EN] <= (REG_STAT_r[`STAT_INT_O_EN] | ppu_stat_write_r) & ((|ppu_scanline_r ? |(ppu_state_r & ST_PPU_OAM_NEW) : |(ppu_state_r & ST_PPU_FRM_NEW)) | (|(ppu_state_r & ST_PPU_VBL) & ~ppu_vblank_seen_r & ppu_dot_ctr_r[0]));  // pulse
        ppu_stat_match_r[`STAT_INT_M_EN] <= (REG_STAT_r[`STAT_INT_M_EN] | ppu_stat_write_r) & REG_STAT_r[`STAT_LYC_MATCH];
      end

      // 1->0 display disable happens imediately.  it's only possible to go from 0->1 during vblank
      if (~REG_LCDC_r[`LCDC_DS_EN]) ppu_state_r <= ST_PPU_OFF;
      ppu_dot_ctr_r <= (ppu_dot_end | |(ppu_state_r & ST_PPU_OFF)) ? 0 : ppu_dot_ctr_r + 1;
    end
  end
end

//-------------------------------------------------------------------
// APU
//-------------------------------------------------------------------

`ifdef APU
reg  [2:0]  apu_frame_step_r;

// square1
reg         apu_square1_enable_r;
reg  [12:0] apu_square1_timer_r;
reg  [5:0]  apu_square1_length_r;
reg         apu_square1_env_enable_r;
reg  [2:0]  apu_square1_env_timer_r;
reg  [3:0]  apu_square1_volume_r;
reg  [2:0]  apu_square1_pos_r;

reg  [7:0]  apu_square1_duty_r;

reg         apu_square1_sweep_enable_r;
reg  [3:0]  apu_square1_sweep_timer_r;
reg  [10:0] apu_square1_sweep_freq_r;
wire [15:0] apu_square1_sweep_freq_next = REG_NR10_r[`NR10_SWEEP_NEG] ? ({5'h00,apu_square1_sweep_freq_r} - ({5'h00,apu_square1_sweep_freq_r} >> REG_NR10_r[`NR10_SWEEP_SHIFT])) : ({5'h00,apu_square1_sweep_freq_r} + ({5'h00,apu_square1_sweep_freq_r} >> REG_NR10_r[`NR10_SWEEP_SHIFT]));

wire [12:0] apu_square1_period = {REG_NR14_r[`NR14_FREQ_MSB],REG_NR13_r[`NR13_FREQ_LSB],2'b00};
wire signed [4:0] apu_square1_output = (apu_square1_enable_r & apu_square1_duty_r[apu_square1_pos_r]) ? {apu_square1_volume_r,1'b0} : 5'h00;

// square2
reg         apu_square2_enable_r;
reg  [12:0] apu_square2_timer_r;
reg  [5:0]  apu_square2_length_r;
reg         apu_square2_env_enable_r;
reg  [2:0]  apu_square2_env_timer_r;
reg  [3:0]  apu_square2_volume_r;
reg  [2:0]  apu_square2_pos_r;

reg  [7:0]  apu_square2_duty_r;

wire [12:0] apu_square2_period = {REG_NR24_r[`NR24_FREQ_MSB],REG_NR23_r[`NR23_FREQ_LSB],2'b00};
wire [4:0] apu_square2_output = (apu_square2_enable_r & apu_square2_duty_r[apu_square2_pos_r]) ? {apu_square2_volume_r,1'b0} : 5'h00;

// wave
reg         apu_wave_enable_r;
reg  [11:0] apu_wave_timer_r;
reg  [7:0]  apu_wave_length_r;
reg  [4:0]  apu_wave_pos_r;
reg         apu_wave_sample_update_r;
reg  [3:0]  apu_wave_sample_r;

reg  [3:0]  apu_wave_data_r;
//reg  [4:0]  apu_wave_data_shifted_r;
reg  [3:0]  apu_wave_data_shifted_r;
wire [11:0] apu_wave_period = {REG_NR34_r[`NR34_FREQ_MSB],REG_NR33_r[`NR33_FREQ_LSB],1'b0};
wire [4:0] apu_wave_output = (apu_wave_enable_r & |REG_NR32_r[`NR32_LEVEL]) ? {apu_wave_data_shifted_r,1'b0} : 5'h00;

// noise
reg         apu_noise_enable_r;
reg  [21:0] apu_noise_timer_r;
reg  [5:0]  apu_noise_length_r;
reg  [2:0]  apu_noise_env_timer_r;
reg  [3:0]  apu_noise_volume_r;
reg  [14:0] apu_noise_lfsr_r;

wire [21:0] apu_noise_period = {15'h0000,REG_NR43_r[`NR43_LFSR_DIV],~|REG_NR43_r[`NR43_LFSR_DIV],3'h0} << REG_NR43_r[`NR43_LFSR_SHIFT];
wire [4:0] apu_noise_output = (apu_noise_enable_r & apu_noise_lfsr_r[0]) ? {apu_noise_volume_r,1'b0} : 5'h00;

wire [6:0]  apu_data[1:0];
reg  [6:0] apu_data_r[1:0];
reg  [9:0] apu_data_volume_r[1:0];

assign apu_data[0][6:0] = ( ((apu_square1_output[4:0] & {5{REG_NR51_r[`NR51_SELECT_LEFT_CH0]  & REG_NR52_r[`NR52_CONTROL_ENABLE]}}))
                          + ((apu_square2_output[4:0] & {5{REG_NR51_r[`NR51_SELECT_LEFT_CH1]  & REG_NR52_r[`NR52_CONTROL_ENABLE]}}))
                          + ((apu_wave_output[4:0]    & {5{REG_NR51_r[`NR51_SELECT_LEFT_CH2]  & REG_NR52_r[`NR52_CONTROL_ENABLE]}}))
                          + ((apu_noise_output[4:0]   & {5{REG_NR51_r[`NR51_SELECT_LEFT_CH3]  & REG_NR52_r[`NR52_CONTROL_ENABLE]}}))
                          );
assign apu_data[1][6:0] = ( ((apu_square1_output[4:0] & {5{REG_NR51_r[`NR51_SELECT_RIGHT_CH0] & REG_NR52_r[`NR52_CONTROL_ENABLE]}}))
                          + ((apu_square2_output[4:0] & {5{REG_NR51_r[`NR51_SELECT_RIGHT_CH1] & REG_NR52_r[`NR52_CONTROL_ENABLE]}}))
                          + ((apu_wave_output[4:0]    & {5{REG_NR51_r[`NR51_SELECT_RIGHT_CH2] & REG_NR52_r[`NR52_CONTROL_ENABLE]}}))
                          + ((apu_noise_output[4:0]   & {5{REG_NR51_r[`NR51_SELECT_RIGHT_CH3] & REG_NR52_r[`NR52_CONTROL_ENABLE]}}))
                          );

assign APU_REG_enable = {apu_noise_enable_r, apu_wave_enable_r, apu_square2_enable_r, apu_square1_enable_r};

reg         apu_cpu_edge_d1_r;
reg         apu_reg_update_r;
reg  [7:0]  apu_reg_update_address_r;
reg         apu_reg_update_nr12_dir_r;
reg         apu_reg_update_nr22_dir_r;
reg         apu_reg_update_nr14_enable_r;
reg         apu_reg_update_nr24_enable_r;

// convert to signed
assign APU_DAT = {~apu_data_volume_r[1][9],apu_data_volume_r[1][8:0],~apu_data_volume_r[0][9],apu_data_volume_r[0][8:0]};

always @(posedge CLK) begin
  // Flop audio state since it is a critical path on MK2
  for (i = 0; i < 2; i = i + 1) apu_data_r[i] <= apu_data[i];

  apu_data_volume_r[0][9:0] <= apu_data_r[0][6:0] * ({7'h00,REG_NR50_r[`NR50_MASTER_LEFT_VOLUME]}  + 1);
  apu_data_volume_r[1][9:0] <= apu_data_r[1][6:0] * ({7'h00,REG_NR50_r[`NR50_MASTER_RIGHT_VOLUME]} + 1);

  apu_wave_data_shifted_r[3:0] <= apu_wave_sample_r[3:0] >> (REG_NR32_r[`NR32_LEVEL] - 1);

  case (REG_NR11_r[`NR11_DUTY])
    0: apu_square1_duty_r <= 8'b00000001;
    1: apu_square1_duty_r <= 8'b10000001;
    2: apu_square1_duty_r <= 8'b10000111;
    3: apu_square1_duty_r <= 8'b01111110;
  endcase

  case (REG_NR21_r[`NR21_DUTY])
    0: apu_square2_duty_r <= 8'b00000001;
    1: apu_square2_duty_r <= 8'b10000001;
    2: apu_square2_duty_r <= 8'b10000111;
    3: apu_square2_duty_r <= 8'b01111110;
  endcase

  apu_wave_sample_update_r <= 0;
  if (apu_wave_sample_update_r) apu_wave_sample_r <= apu_wave_pos_r[0] ? REG_WAV_r[apu_wave_pos_r[4:1]][3:0] : REG_WAV_r[apu_wave_pos_r[4:1]][7:4];

  if (cpu_ireset_r | ~REG_NR52_r[`NR52_CONTROL_ENABLE]) begin
    REG_NR10_r    <= 8'h00; // FF10
    if (cpu_ireset_r) REG_NR11_r[`NR11_LENGTH] <= 0; // FF11
    REG_NR11_r[`NR11_DUTY] <= 0;
    REG_NR12_r    <= 8'h00; // FF12
    REG_NR13_r    <= 8'h00; // FF13
    REG_NR14_r    <= 5'h00; // FF14

    if (cpu_ireset_r) REG_NR21_r[`NR21_LENGTH] <= 0; // FF16
    REG_NR21_r[`NR21_DUTY] <= 0;
    REG_NR22_r    <= 8'h00; // FF17
    REG_NR23_r    <= 8'h00; // FF18
    REG_NR24_r    <= 8'h00; // FF19

    REG_NR30_r    <= 8'h00; // FF1A
    REG_NR31_r    <= 8'h00; // FF1B
    REG_NR32_r    <= 8'h00; // FF1C
    REG_NR33_r    <= 8'h00; // FF1D
    REG_NR34_r    <= 8'h00; // FF1E

    if (cpu_ireset_r) REG_NR41_r[`NR41_LENGTH] <= 0; // FF16
    REG_NR42_r    <= 8'h00; // FF21
    REG_NR43_r    <= 8'h00; // FF22
    REG_NR44_r    <= 8'h00; // FF23

    REG_NR50_r    <= 8'h00; // FF24
    REG_NR51_r    <= 8'h00; // FF25
    REG_NR52_r    <= 8'h00; // FF26

    // RT1 uses uninitialized WAV RAM data.  One possible set of SGB2 values used.
    if (cpu_ireset_r) begin
      REG_WAV_r[0]  <= 8'h08;//8'hAC;
      REG_WAV_r[1]  <= 8'hF7;//8'hDD;
      REG_WAV_r[2]  <= 8'h04;//8'hDA;
      REG_WAV_r[3]  <= 8'hDF;//8'h48;
      REG_WAV_r[4]  <= 8'h08;//8'h36;
      REG_WAV_r[5]  <= 8'h66;//8'h02;
      REG_WAV_r[6]  <= 8'h00;//8'hCF;
      REG_WAV_r[7]  <= 8'h7F;//8'h16;
      REG_WAV_r[8]  <= 8'h00;//8'h2C;
      REG_WAV_r[9]  <= 8'h57;//8'h04;
      REG_WAV_r[10] <= 8'h02;//8'hE5;
      REG_WAV_r[11] <= 8'hFF;//8'h2C;
      REG_WAV_r[12] <= 8'h08;//8'hAC;
      REG_WAV_r[13] <= 8'hFF;//8'hDD;
      REG_WAV_r[14] <= 8'h00;//8'hDA;
      REG_WAV_r[15] <= 8'h9F;//8'h48;
    end

    apu_frame_step_r <= 0;

    apu_square1_enable_r       <= 0;
    apu_square1_timer_r        <= 0;
    apu_square1_env_enable_r   <= 0;
    apu_square1_env_timer_r    <= 0;
    apu_square1_volume_r       <= 0;
    apu_square1_pos_r          <= 0;
    apu_square1_sweep_enable_r <= 0;
    apu_square1_sweep_timer_r  <= 0;
    apu_square1_sweep_freq_r   <= 0;

    apu_square2_enable_r     <= 0;
    apu_square2_timer_r      <= 0;
    apu_square2_env_enable_r <= 0;
    apu_square2_env_timer_r  <= 0;
    apu_square2_volume_r     <= 0;
    apu_square2_pos_r        <= 0;

    apu_wave_enable_r <= 0;
    apu_wave_timer_r  <= 0;
    apu_wave_pos_r    <= 0;

    apu_noise_enable_r     <= 0;
    apu_noise_timer_r      <= 0;
    apu_noise_env_timer_r  <= 0;
    apu_noise_volume_r     <= 0;
    apu_noise_lfsr_r       <= 0;

    apu_cpu_edge_d1_r <= 0;
    apu_reg_update_r  <= 0;

    // handle APU enable
    if (REG_req_val) begin
      case(REG_address)
        8'h11: REG_NR11_r[`NR11_LENGTH] <= REG_req_data[`NR11_LENGTH];
        8'h16: REG_NR21_r[`NR21_LENGTH] <= REG_req_data[`NR21_LENGTH];
        8'h20: REG_NR41_r[`NR41_LENGTH] <= REG_req_data[`NR41_LENGTH];
        8'h26: {REG_NR52_r[7:7],REG_NR52_r[3:0]} <= {REG_req_data[7:7],REG_req_data[3:0]};
      endcase
    end
  end
  else begin
    apu_cpu_edge_d1_r <= CLK_CPU_EDGE;

    if (apu_reg_update_r & apu_cpu_edge_d1_r) begin
      case (apu_reg_update_address_r)
        // square1
        8'h11:  apu_square1_length_r <= REG_NR11_r[`NR11_LENGTH];    // NR11
        8'h12: begin // NR12
          // volume side effect (inversion).  see register writes for additional side effects.
          if (apu_reg_update_nr12_dir_r ^ REG_NR12_r[`NR12_ENV_DIR]) apu_square1_volume_r <= ~apu_square1_volume_r + 1;

          if (apu_reg_update_nr14_enable_r) apu_square1_pos_r <= apu_square1_pos_r + 1;

          if (apu_square1_enable_r) apu_square1_enable_r <= |REG_NR12_r[7:3];
        end
        8'h13: begin // NR13
          if (apu_reg_update_nr14_enable_r) apu_square1_pos_r <= apu_square1_pos_r + 1;
        end
        8'h14: begin // NR14
          if (apu_reg_update_nr14_enable_r) apu_square1_pos_r <= apu_square1_pos_r + 1;

          if (REG_NR14_r[`NR14_FREQ_ENABLE]) begin
            apu_square1_enable_r     <= (|REG_NR12_r[`NR12_ENV_VOLUME] | REG_NR12_r[`NR12_ENV_DIR]) & ~HLT_RSP;
            apu_square1_timer_r      <= apu_square1_period;
            apu_square1_length_r     <= &apu_square1_length_r ? 0 : apu_square1_length_r;
            apu_square1_env_enable_r <= 1;
            apu_square1_env_timer_r  <= REG_NR12_r[`NR12_ENV_PERIOD];
            apu_square1_volume_r     <= REG_NR12_r[`NR12_ENV_VOLUME];

            apu_square1_sweep_enable_r <= |REG_NR10_r[`NR10_SWEEP_TIME] | |REG_NR10_r[`NR10_SWEEP_SHIFT];
            apu_square1_sweep_timer_r  <= {~|REG_NR10_r[`NR10_SWEEP_TIME],REG_NR10_r[`NR10_SWEEP_TIME]};
            apu_square1_sweep_freq_r   <= {REG_NR14_r[`NR14_FREQ_MSB],REG_NR13_r[`NR13_FREQ_LSB]};
          end
        end

        // square2
        8'h16:  apu_square2_length_r <= REG_NR21_r[`NR21_LENGTH];    // NR21
        8'h17: begin // NR22
          // volume side effect (inversion).  see register writes for additional side effects.
          if (apu_reg_update_nr22_dir_r ^ REG_NR22_r[`NR22_ENV_DIR]) apu_square2_volume_r <= ~apu_square2_volume_r + 1;

          if (apu_reg_update_nr24_enable_r) apu_square2_pos_r <= apu_square2_pos_r + 1;

          if (apu_square2_enable_r) apu_square2_enable_r <= |REG_NR22_r[7:3];
        end
        8'h18: begin // NR23
          if (apu_reg_update_nr24_enable_r) apu_square2_pos_r <= apu_square2_pos_r + 1;
        end
        8'h19: begin // NR24
          if (apu_reg_update_nr24_enable_r) apu_square2_pos_r <= apu_square2_pos_r + 1;

          if (REG_NR24_r[`NR24_FREQ_ENABLE]) begin
            apu_square2_enable_r     <= (|REG_NR22_r[`NR22_ENV_VOLUME] | REG_NR22_r[`NR22_ENV_DIR]) & ~HLT_RSP;
            apu_square2_timer_r      <= apu_square2_period;
            apu_square2_length_r     <= &apu_square2_length_r ? 0 : apu_square2_length_r;
            apu_square2_env_enable_r <= 1;
            apu_square2_env_timer_r  <= REG_NR22_r[`NR22_ENV_PERIOD];
            apu_square2_volume_r     <= REG_NR22_r[`NR22_ENV_VOLUME];
          end
        end

        // wave
        8'h1A:  if (apu_wave_enable_r) apu_wave_enable_r <= REG_NR30_r[`NR30_WAVE_ENABLE]; // NR30
        8'h1B:  apu_wave_length_r <= REG_NR31_r[`NR31_LENGTH];    // NR31
        8'h1E:  begin                                                         // NR34
          if (REG_NR34_r[`NR34_FREQ_ENABLE]) begin
            apu_wave_enable_r     <= REG_NR30_r[`NR30_WAVE_ENABLE] & ~HLT_RSP;
            apu_wave_timer_r      <= apu_wave_period;
            apu_wave_length_r     <= &apu_wave_length_r ? 0 : apu_wave_length_r;
            apu_wave_pos_r        <= 0;
          end
        end

        // noise
        8'h20:  apu_noise_length_r <= REG_NR41_r[`NR41_LENGTH];    // NR41
        8'h21:  if (apu_noise_enable_r) apu_noise_enable_r <= (REG_NR42_r[`NR42_ENV_DIR] | |REG_NR42_r[`NR42_ENV_VOLUME]);// NR42
        8'h23:  begin                                                         // NR44
          if (REG_NR44_r[`NR44_FREQ_ENABLE]) begin
            apu_noise_enable_r     <= (REG_NR42_r[`NR42_ENV_DIR] | |REG_NR42_r[`NR42_ENV_VOLUME]) & ~HLT_RSP;
            apu_noise_timer_r      <= apu_noise_period;
            apu_noise_lfsr_r       <= 15'h7FFF;
            apu_noise_length_r     <= &apu_noise_length_r ? 0 : apu_noise_length_r;
            apu_noise_env_timer_r  <= REG_NR42_r[`NR42_ENV_PERIOD];
            apu_noise_volume_r     <= REG_NR42_r[`NR42_ENV_VOLUME];
          end

        end
      endcase
    end
    else if (CLK_CPU_EDGE) begin
      if (tmr_apu_step_r) apu_frame_step_r <= apu_frame_step_r + 1;

      ////////////
      // square1
      ////////////
      if (tmr_apu_step_r) begin
        // period
        if (~apu_frame_step_r[0]) begin
          if (REG_NR14_r[`NR14_FREQ_STOP]) begin
            if (&apu_square1_length_r) apu_square1_enable_r <= 0; else apu_square1_length_r <= apu_square1_length_r + 1;
          end
        end

        // envelope
        if (&apu_frame_step_r) begin
          if (apu_square1_env_enable_r & |REG_NR12_r[`NR12_ENV_PERIOD]) begin
            apu_square1_env_timer_r <= apu_square1_env_timer_r - 1;

            if (apu_square1_env_timer_r == 1) begin
              if      ( REG_NR12_r[`NR12_ENV_DIR] & ~&apu_square1_volume_r) apu_square1_volume_r <= apu_square1_volume_r + 1;
              else if (~REG_NR12_r[`NR12_ENV_DIR] &  |apu_square1_volume_r) apu_square1_volume_r <= apu_square1_volume_r - 1;
              else                                                          apu_square1_env_enable_r <= 0;

              apu_square1_env_timer_r <= REG_NR12_r[`NR12_ENV_PERIOD];
            end
          end
        end

        // sweep
        if (apu_frame_step_r[1:0] == 2'b10) begin
          if (apu_square1_sweep_enable_r) begin
            if (|REG_NR10_r[`NR10_SWEEP_TIME]) begin
              if (|apu_square1_sweep_timer_r) begin
                apu_square1_sweep_timer_r <= apu_square1_sweep_timer_r - 1;

                if (apu_square1_sweep_timer_r == 1) begin
                  if (~|REG_NR10_r[`NR10_SWEEP_SHIFT]) apu_square1_enable_r <= 0;
                  if (~|REG_NR10_r[`NR10_SWEEP_SHIFT]) apu_square1_sweep_enable_r <= 0;
                  apu_square1_sweep_timer_r  <= {~|REG_NR10_r[`NR10_SWEEP_TIME],REG_NR10_r[`NR10_SWEEP_TIME]};

                  // need to update both reg and shadow here because period uses reg.  period needs to use reg because the program may update that manually.
                  // the shadow is used to compute the next frequency for shutting down the output for sweep
                  // TODO: determine if looking one frequency shift in the future is enough.
                  if (|REG_NR10_r[`NR10_SWEEP_SHIFT]) {REG_NR14_r[`NR14_FREQ_MSB],REG_NR13_r[`NR13_FREQ_LSB]} <= apu_square1_sweep_freq_next[10:0];
                  if (|REG_NR10_r[`NR10_SWEEP_SHIFT]) apu_square1_sweep_freq_r[10:0] <= apu_square1_sweep_freq_next[10:0];
                end
              end
            end
          end
        end
      end

      // duty cycle
      apu_square1_timer_r <= apu_square1_timer_r + 1;
      if (&apu_square1_timer_r) begin
        apu_square1_pos_r <= apu_square1_pos_r + 1;
        apu_square1_timer_r <= apu_square1_period;
      end

      // check sweep overflow
      if (apu_square1_sweep_enable_r & |REG_NR10_r[`NR10_SWEEP_SHIFT] & |apu_square1_sweep_freq_next[15:11]) begin
        apu_square1_enable_r <= 0;
        apu_square1_sweep_enable_r <= 0;
      end

      ////////////
      // square2
      ////////////
      if (tmr_apu_step_r) begin
        // period
        if (~apu_frame_step_r[0]) begin
          if (REG_NR24_r[`NR24_FREQ_STOP]) begin
            if (&apu_square2_length_r) apu_square2_enable_r <= 0; else apu_square2_length_r <= apu_square2_length_r + 1;
          end
        end

        // envelope
        if (&apu_frame_step_r) begin
          if (apu_square2_env_enable_r & |REG_NR22_r[`NR22_ENV_PERIOD]) begin
            apu_square2_env_timer_r <= apu_square2_env_timer_r - 1;
            if (apu_square2_env_timer_r == 1) begin
              if      ( REG_NR22_r[`NR22_ENV_DIR] & ~&apu_square2_volume_r) apu_square2_volume_r <= apu_square2_volume_r + 1;
              else if (~REG_NR22_r[`NR22_ENV_DIR] &  |apu_square2_volume_r) apu_square2_volume_r <= apu_square2_volume_r - 1;
              else                                                          apu_square2_env_enable_r <= 0;

              apu_square2_env_timer_r <= REG_NR22_r[`NR22_ENV_PERIOD];
            end
          end
        end
      end

      // duty cycle
      apu_square2_timer_r <= apu_square2_timer_r + 1;
      if (&apu_square2_timer_r) begin
        apu_square2_pos_r <= apu_square2_pos_r + 1;
        apu_square2_timer_r <= apu_square2_period;
      end

      ////////////
      // wave
      ////////////
      if (tmr_apu_step_r) begin
        // period
        if (~apu_frame_step_r[0]) begin
          if (REG_NR34_r[`NR34_FREQ_STOP]) begin
            if (&apu_wave_length_r) apu_wave_enable_r <= 0; else apu_wave_length_r <= apu_wave_length_r + 1;
          end
        end
      end

      apu_wave_timer_r <= apu_wave_timer_r + 1;
      if (&apu_wave_timer_r) begin
        apu_wave_pos_r   <= apu_wave_pos_r + 1;
        apu_wave_timer_r <= apu_wave_period;

        apu_wave_sample_update_r <= 1;
      end

      ////////////
      // noise
      ////////////
      if (tmr_apu_step_r) begin
        // period
        if (~apu_frame_step_r[0]) begin
          if (REG_NR44_r[`NR44_FREQ_STOP]) begin
            if (&apu_noise_length_r) apu_noise_enable_r <= 0; else apu_noise_length_r <= apu_noise_length_r + 1;
          end
        end

        // envelope
        if (&apu_frame_step_r) begin
          if (|apu_noise_env_timer_r) begin
            apu_noise_env_timer_r <= apu_noise_env_timer_r - 1;
            if (apu_noise_env_timer_r == 1) begin
              if      ( REG_NR42_r[`NR42_ENV_DIR] & ~&apu_noise_volume_r) apu_noise_volume_r <= apu_noise_volume_r + 1;
              else if (~REG_NR42_r[`NR42_ENV_DIR] &  |apu_noise_volume_r) apu_noise_volume_r <= apu_noise_volume_r - 1;

              apu_noise_env_timer_r <= REG_NR42_r[`NR42_ENV_PERIOD];
            end
          end
        end
      end

      // lfsr
      if (REG_NR43_r[`NR43_LFSR_SHIFT] < 4'hE) begin
        apu_noise_timer_r <= apu_noise_timer_r - 1;
        if (~|apu_noise_timer_r) begin
          apu_noise_timer_r <= apu_noise_period;

          apu_noise_lfsr_r <= {^apu_noise_lfsr_r[1:0],apu_noise_lfsr_r[14:8],(REG_NR43_r[`NR43_LFSR_WIDTH] ? ^apu_noise_lfsr_r[1:0] : apu_noise_lfsr_r[7]),apu_noise_lfsr_r[6:1]};
        end
      end
    end

    //--------------
    // APU REGISTERS
    //--------------

    // sync to one after CPU clock edge
    if (apu_cpu_edge_d1_r) apu_reg_update_r <= 0;

    if (REG_req_val) begin
      apu_reg_update_r <= 1;
      apu_reg_update_address_r <= REG_address;
      apu_reg_update_nr12_dir_r <= REG_NR12_r[`NR12_ENV_DIR];
      apu_reg_update_nr22_dir_r <= REG_NR22_r[`NR22_ENV_DIR];
      apu_reg_update_nr14_enable_r <= REG_NR14_r[`NR14_FREQ_ENABLE];
      apu_reg_update_nr24_enable_r <= REG_NR24_r[`NR24_FREQ_ENABLE];

      case (REG_address)
        8'h10: REG_NR10_r[7:0] <= REG_req_data[7:0];
        8'h11: REG_NR11_r[7:0] <= REG_req_data[7:0];
        8'h12: begin
          REG_NR12_r[7:0] <= REG_req_data[7:0];

          // volume side effects
          // P-M uses the first one to wrap the volume from F->0
          // CVL and probably many others use the second as predecrement of volume
          if      (REG_req_data[`NR12_ENV_DIR] & ~|REG_NR12_r[`NR12_ENV_PERIOD])                                                            apu_square1_volume_r <= apu_square1_volume_r + 1;
          else if (~REG_req_data[`NR12_ENV_DIR] & |REG_req_data[`NR12_ENV_PERIOD] & ~|REG_NR12_r[`NR12_ENV_PERIOD] & |apu_square1_volume_r) apu_square1_volume_r <= apu_square1_volume_r - 1;
        end
        8'h13: REG_NR13_r[7:0] <= REG_req_data[7:0];
        8'h14: REG_NR14_r[7:0] <= REG_req_data[7:0];

        8'h16: REG_NR21_r[7:0] <= REG_req_data[7:0];
        8'h17: begin
          REG_NR22_r[7:0] <= REG_req_data[7:0];

          // volume side effects
          // P-M uses the first one to wrap the volume from F->0
          // CVL and probably many others use the second as predecrement of volume
          if      (REG_req_data[`NR22_ENV_DIR] & ~|REG_NR22_r[`NR22_ENV_PERIOD])                                                            apu_square2_volume_r <= apu_square2_volume_r + 1;
          else if (~REG_req_data[`NR22_ENV_DIR] & |REG_req_data[`NR22_ENV_PERIOD] & ~|REG_NR22_r[`NR22_ENV_PERIOD] & |apu_square2_volume_r) apu_square2_volume_r <= apu_square2_volume_r - 1;
        end
        8'h18: REG_NR23_r[7:0] <= REG_req_data[7:0];
        8'h19: REG_NR24_r[7:0] <= REG_req_data[7:0];

        8'h1A: REG_NR30_r[7:0] <= REG_req_data[7:0];
        8'h1B: REG_NR31_r[7:0] <= REG_req_data[7:0];
        8'h1C: REG_NR32_r[7:0] <= REG_req_data[7:0];
        8'h1D: REG_NR33_r[7:0] <= REG_req_data[7:0];
        8'h1E: REG_NR34_r[7:0] <= REG_req_data[7:0];

        8'h20: REG_NR41_r[7:0] <= REG_req_data[7:0];
        8'h21: REG_NR42_r[7:0] <= REG_req_data[7:0];
        8'h22: REG_NR43_r[7:0] <= REG_req_data[7:0];
        8'h23: REG_NR44_r[7:0] <= REG_req_data[7:0];

        8'h24: REG_NR50_r[7:0] <= REG_req_data[7:0];
        8'h25: REG_NR51_r[7:0] <= REG_req_data[7:0];
        8'h26: {REG_NR52_r[7:7],REG_NR52_r[3:0]} <= {REG_req_data[7:7],REG_req_data[3:0]};

        8'h30, 8'h31, 8'h32, 8'h33, 8'h34, 8'h35, 8'h36, 8'h37,
        8'h38, 8'h39, 8'h3A, 8'h3B, 8'h3C, 8'h3D, 8'h3E, 8'h3F: if (~apu_wave_enable_r | REG_req_dbg) REG_WAV_r[REG_address[3:0]] <= REG_req_data;

      endcase
    end
  end
end
`endif

//-------------------------------------------------------------------
// MCT
//-------------------------------------------------------------------

// MCT is the memory controller that allows the CPU pipeline stages
// to access all memory-mapped architectural state including:
//
// ROM (both cart and boot)
// SaveRAM
// WRAM
// VRAM
// OAM
// HRAM
// REG (IO registers)
//
// The first 3 are stored in the SD2SNES's 16MB PSRAM.  The others
// are mapped to BRAM or registers because they need: higher bandwidth,
// concurrency (with other state), or partial byte support.
//
// In general, the GB's bandwidth requirements are very modest, but using
// BRAM simplifies having to balance the various sources.

//
// hram
//
wire        hram_wren    = MCT_HRAM_wren;
wire [6:0]  hram_address = MCT_HRAM_address;
wire [7:0]  hram_rddata;
wire [7:0]  hram_wrdata  = MCT_HRAM_data;

wire        dbg_hram_wren;
wire [6:0]  dbg_hram_address;
wire [7:0]  dbg_hram_rddata;
wire [7:0]  dbg_hram_wrdata;

`ifdef MK2
hram hram (
  .clka(CLK), // input clka
  .wea(hram_wren), // input [0 : 0] wea
  .addra(hram_address), // input [6 : 0] addra
  .dina(hram_wrdata), // input [7 : 0] dina
  .douta(hram_rddata), // output [7 : 0] douta
  .clkb(CLK), // input clkb
  .web(dbg_hram_wren), // input [0 : 0] web
  .addrb(dbg_hram_address), // input [6 : 0] addrb
  .dinb(dbg_hram_wrdata), // input [7 : 0] dinb
  .doutb(dbg_hram_rddata) // output [7 : 0] doutb
);
`endif
`ifdef MK3
hram hram (
  .clock(CLK), // input clka
  .wren_a(hram_wren), // input [0 : 0] wea
  .address_a(hram_address), // input [6 : 0] addra
  .data_a(hram_wrdata), // input [7 : 0] dina
  .q_a(hram_rddata), // output [7 : 0] douta
  .wren_b(dbg_hram_wren), // input [0 : 0] web
  .address_b(dbg_hram_address), // input [6 : 0] addrb
  .data_b(dbg_hram_wrdata), // input [7 : 0] dinb
  .q_b(dbg_hram_rddata) // output [7 : 0] doutb
);
`endif

// Sources: IFD, EXE
// Targets: EXT (ROM, SaveRAM, WRAM), VRAM, OAM, IO/HRAM

`define MCT_TGT_VRAM(a) (a[15:13] == 3'b100)  // 8000-9FFF
`define MCT_TGT_HIGH(a) (&a[15:9])            // FE00-FE9F,FF00-FF7F,FF80-FFFE,FFFF

parameter
  ST_MCT_IDLE     = 8'b00000001,
  ST_MCT_DEC      = 8'b00000010,
  ST_MCT_VRAM     = 8'b00000100,
  ST_MCT_OAM      = 8'b00001000,
  ST_MCT_REG      = 8'b00010000,
  ST_MCT_HRAM     = 8'b00100000,
  ST_MCT_EXT      = 8'b01000000,
  ST_MCT_END      = 8'b10000000;

reg  [1:0]  mct_req_r;
reg  [7:0]  mct_state_r;
reg  [15:0] mct_addr_r;
reg         mct_src_r;
reg         mct_wr_r;
reg  [7:0]  mct_mdr_r;

wire [15:0] mct_addr_d1 = mct_src_r ? EXE_MCT_req_addr_d1 : IFD_MCT_req_addr_d1;

assign HRAM_data = hram_rddata;

assign MCT_VRAM_wren = mct_wr_r & |(mct_state_r & ST_MCT_VRAM) & mct_req_r[0];
assign MCT_VRAM_address = mct_addr_r[12:0];
assign MCT_VRAM_data = mct_mdr_r;

assign MCT_OAM_wren = mct_wr_r & |(mct_state_r & ST_MCT_OAM) & mct_req_r[0];
assign MCT_OAM_address = mct_addr_r[7:0];
assign MCT_OAM_data = mct_mdr_r;

assign MCT_HRAM_wren = mct_wr_r & |(mct_state_r & ST_MCT_HRAM) & mct_req_r[0];
assign MCT_HRAM_address = mct_addr_r[6:0];
assign MCT_HRAM_data = mct_mdr_r;

assign MCT_REG_wren = mct_wr_r & |(mct_state_r & ST_MCT_REG) & mct_req_r[0];
assign MCT_REG_address = mct_addr_r[7:0];
assign MCT_REG_data = mct_mdr_r;

assign SYS_REQ    = DMA_SYS_active ? DMA_req_val : (|(mct_state_r & ST_MCT_EXT) & mct_req_r[0]);
assign SYS_WR     = DMA_SYS_active ? 0           : mct_wr_r & mct_req_r[0];
assign SYS_ADDR   = DMA_SYS_active ? DMA_address : mct_addr_r;
assign SYS_WRDATA = mct_mdr_r;

assign MCT_IFD_rsp_val = |(mct_state_r & ST_MCT_END) & ~mct_src_r;
assign MCT_EXE_rsp_val = |(mct_state_r & ST_MCT_END) &  mct_src_r;
assign MCT_data = mct_mdr_r;

assign MCT_REG_req_val = |(mct_state_r & ST_MCT_REG);

reg  [15:0] mct_oam_error_r;
reg  [15:0] mct_vram_error_r;

always @(posedge CLK) begin
  if (cpu_ireset_r) begin
    mct_state_r <= ST_MCT_IDLE;
    mct_req_r   <= 0;

    mct_oam_error_r <= 0;
    mct_vram_error_r <= 0;
  end
  else begin
    case (mct_state_r)
      ST_MCT_IDLE: begin
        if      (EXE_MCT_req_val) begin
          mct_src_r   <= 1;
          mct_wr_r    <= EXE_MCT_req_wr;

          mct_state_r <= ST_MCT_DEC;
        end
        else if (IFD_MCT_req_val) begin
          mct_src_r   <= 0;
          mct_wr_r    <= 0;

          mct_state_r <= ST_MCT_DEC;
        end
      end
      ST_MCT_DEC: begin
        // data and address arrives one cycle late to simplify EXE register read -> AGEN
        mct_addr_r <= mct_addr_d1;
        if (mct_wr_r) mct_mdr_r <= EXE_MCT_req_data_d1;

        if      (`MCT_TGT_VRAM(mct_addr_d1)) begin
          mct_state_r <= ST_MCT_VRAM;
        end
        else if (`MCT_TGT_HIGH(mct_addr_d1)) begin
          mct_state_r <= mct_addr_d1[8] ? ((~mct_addr_d1[7] | &mct_addr_d1[6:0]) ? ST_MCT_REG : ST_MCT_HRAM) : ST_MCT_OAM;
        end
        else begin
          mct_state_r <= ST_MCT_EXT;
        end
      end
      ST_MCT_VRAM: begin
        // SH writes 0 and checks for nonzero to see if the write failed.  Returning FF here allows correct detection of the fail
        if (~mct_wr_r) mct_mdr_r <= PPU_MCT_vram_active ? 8'hFF : VRAM_data;

        // avoid false errors by only looking at EXE src
        if (~|mct_req_r & PPU_MCT_vram_active & mct_src_r) mct_vram_error_r <= mct_vram_error_r + 1;
        if (~|mct_req_r) mct_state_r <= ST_MCT_END;
      end
      ST_MCT_OAM: begin
        if (~mct_wr_r) mct_mdr_r <= PPU_MCT_oam_active ? 8'hFF : OAM_data;

        // avoid false errors by only looking at EXE src
        if (~|mct_req_r & PPU_MCT_oam_active & mct_src_r) mct_oam_error_r <= mct_oam_error_r + 1;
        if (~|mct_req_r) mct_state_r <= ST_MCT_END;
      end
      ST_MCT_REG: begin
        if (~mct_wr_r) mct_mdr_r <= REG_data;

        if (~|mct_req_r & REG_MCT_rsp_val) mct_state_r <= ST_MCT_END;
      end
      ST_MCT_HRAM: begin
        if (~mct_wr_r) mct_mdr_r <= HRAM_data;

        if (~|mct_req_r) mct_state_r <= ST_MCT_END;
      end
      ST_MCT_EXT: begin
        // the main logic has a one entry buffer to always sink these requests
        if (~mct_wr_r) mct_mdr_r <= SYS_RDDATA;

        if (~|mct_req_r & SYS_RDY) mct_state_r <= ST_MCT_END;
      end
      ST_MCT_END: begin
        mct_state_r <= ST_MCT_IDLE;
      end
    endcase

    mct_req_r <= {mct_req_r[0],|(mct_state_r & ST_MCT_DEC)};
  end
end

//-------------------------------------------------------------------
// SERIAL
//-------------------------------------------------------------------

// Basic functionality to allow multiplayer games to pass.  missing external clock/data.

`ifdef SGB_SERIAL
reg         ser_active_d1_r;
reg         ser_clk_d1_r;
reg  [9:0]  ser_ctr_r;
reg  [2:0]  ser_pos_r;
reg         ser_done_r;

assign      SER_REG_done = ser_done_r;

assign HLT_SER_rsp = HLT_REQ_sync & (~REG_SC_r[7] | ~REG_SC_r[0]);

always @(posedge CLK) begin
  if (cpu_ireset_r) begin
    REG_SB_r <= 0;
    REG_SC_r <= 8'h7F;

    ser_active_d1_r <= 0;
    ser_done_r      <= 0;
  end
  else begin
    if (CLK_CPU_EDGE) begin
      ser_active_d1_r <= REG_SC_r[7];
      ser_done_r      <= 0;

      if (REG_SC_r[7]) begin
        if (~ser_active_d1_r) begin
          ser_ctr_r <= 0;
          ser_clk_d1_r <= 0;
          ser_pos_r <= 0;
        end
        else begin
          ser_ctr_r <= REG_SC_r[0] ? ser_ctr_r + 1 : ser_ctr_r;
          ser_clk_d1_r <= ser_ctr_r[9];

          if (ser_clk_d1_r ^ ser_ctr_r[9]) begin
            REG_SB_r[~ser_pos_r] <= 1'b1;
            ser_pos_r <= ser_pos_r + 1;

            if (&ser_pos_r) begin
              REG_SC_r[7] <= 0;
              ser_done_r <= 1;
            end
          end
        end
      end
    end

    if (REG_req_val) begin
      case (REG_address)
        8'h01: REG_SB_r[7:0] <= REG_req_data[7:0];
        8'h02: begin
         REG_SC_r[7:0] <= REG_req_data[7:0];
         // support MCU/DBG triggering interrupt on 1->0 transition.  it's possible, but highly unlikely save states could trigger this and we
         // may not want that.  that would happen only on the few games that use this and require saving and then loading a state in
         // external clock mode when the state machine is active.  BMQ doesn't want to assert interrupt on CPU write of SC.
         if (reg_src_r & ~HLT_RSP) ser_done_r <= REG_SC_r[7] & ~REG_req_data[7];
        end
      endcase
    end
  end
end
`endif

//-------------------------------------------------------------------
// DBG
//-------------------------------------------------------------------

// DBG contains all the state we want to read out from the SGB via
// the MCU.  It mirrors the MCT pipe because the general operation is
// the same.  If fitting this logic becomes problematic it can either
// be removed entirely or integrated into the MCU pipe (with some
// concurrency limitations).

parameter
  ST_DBG_IDLE     = 8'b00000001,
  ST_DBG_DEC      = 8'b00000010,
  ST_DBG_VRAM     = 8'b00000100,
  ST_DBG_OAM      = 8'b00001000,
  ST_DBG_REG      = 8'b00010000,
  ST_DBG_HRAM     = 8'b00100000,
  ST_DBG_MISC     = 8'b01000000, // MISC state we want to export at 810000-87FFFF
  ST_DBG_END      = 8'b10000000;

reg  [1:0]  dbg_req_r;
reg  [7:0]  dbg_state_r;
reg  [15:0] dbg_addr_r;
reg         dbg_wr_r;
reg  [7:0]  dbg_mdr_r;

reg  [7:0]  dbg_misc_data_r = 0;

// return bogus data under reset to avoid having to keep parts of the CPU awake
assign MCU_RSP = |(dbg_state_r & ST_DBG_END) | cpu_ireset_r;
assign MCU_DATA_OUT = dbg_mdr_r;

assign dbg_vram_wren = dbg_wr_r & |(dbg_state_r & ST_DBG_VRAM);
assign dbg_vram_address = dbg_addr_r[12:0];
assign dbg_vram_wrdata = dbg_mdr_r;

assign dbg_oam_wren = dbg_wr_r & |(dbg_state_r & ST_DBG_OAM);
assign dbg_oam_address = dbg_addr_r[7:0];
assign dbg_oam_wrdata = dbg_mdr_r;

assign dbg_hram_wren = dbg_wr_r & |(dbg_state_r & ST_DBG_HRAM);
assign dbg_hram_address = dbg_addr_r[6:0];
assign dbg_hram_wrdata = dbg_mdr_r;

assign DBG_REG_req_val = |(dbg_state_r & ST_DBG_REG);

assign DBG_REG_wren = dbg_wr_r & |(dbg_state_r & ST_DBG_REG);
assign DBG_REG_address = dbg_addr_r[7:0];
assign DBG_REG_data = dbg_mdr_r;

assign DBG_ADDR = dbg_addr_r[11:0];

`ifdef SGB_DEBUG
wire [7:0] config_r[7:0];
`endif

always @(posedge CLK) begin
  if (cpu_ireset_r) begin
    dbg_state_r <= ST_DBG_IDLE;
    dbg_req_r   <= 0;
    dbg_wr_r    <= 0;
  end
  else begin
    case (dbg_state_r)
      ST_DBG_IDLE: begin
        if (MCU_RRQ | MCU_WRQ) begin
          dbg_addr_r  <= MCU_ADDR;
          dbg_wr_r    <= MCU_WRQ;
          if (MCU_WRQ) dbg_mdr_r <= MCU_DATA_IN;

          dbg_state_r <= ST_DBG_DEC;
        end
      end
      ST_DBG_DEC: begin
        if      (`MCT_TGT_VRAM(dbg_addr_r)) begin
          dbg_state_r <= ST_DBG_VRAM;
        end
        else if (`MCT_TGT_HIGH(dbg_addr_r)) begin
          dbg_state_r <= dbg_addr_r[8] ? ((~dbg_addr_r[7] | &dbg_addr_r[6:0]) ? ST_DBG_REG : ST_DBG_HRAM) : ST_DBG_OAM;
        end
        else begin
          dbg_state_r <= ST_DBG_MISC;
        end
      end
      ST_DBG_VRAM: begin
        if (~dbg_wr_r) dbg_mdr_r <= dbg_vram_rddata;

        dbg_state_r <= ST_DBG_END;
      end
      ST_DBG_OAM: begin
        if (~dbg_wr_r) dbg_mdr_r <= dbg_oam_rddata;

        dbg_state_r <= ST_DBG_END;
      end
      ST_DBG_REG: begin
        if (~dbg_wr_r) dbg_mdr_r <= REG_data;

        if (~dbg_req_r[0] & REG_DBG_rsp_val) dbg_state_r <= ST_DBG_END;
      end
      ST_DBG_HRAM: begin
        if (~dbg_wr_r) dbg_mdr_r <= dbg_hram_rddata;

        dbg_state_r <= ST_DBG_END;
      end
      ST_DBG_MISC: begin
        if (~dbg_wr_r) dbg_mdr_r <= dbg_misc_data_r;

        // DEC   - addr
        // MISC0 - dbg_req_r[0], dbg_row_rddata
        // MISC1 - dbg_req_r[1], data_in
        // MISC2 - dbg_misc_data_r
        if (~|dbg_req_r) dbg_state_r <= ST_DBG_END;
      end
      ST_DBG_END: begin
        dbg_state_r <= ST_DBG_IDLE;
      end
    endcase

    dbg_req_r <= {dbg_req_r[0],|(dbg_state_r & ST_DBG_DEC)};
  end

`ifdef SGB_DEBUG
  case (dbg_addr_r[11:8])
    // ARCH
    4'h0: case(dbg_addr_r[7:0])
            8'h00:    dbg_misc_data_r <= ifd_pc[7:0];
            8'h01:    dbg_misc_data_r <= ifd_pc[15:8];
            8'h02:    dbg_misc_data_r <= F_r;
            8'h03:    dbg_misc_data_r <= A_r;
            8'h04:    dbg_misc_data_r <= C_r;
            8'h05:    dbg_misc_data_r <= B_r;
            8'h06:    dbg_misc_data_r <= E_r;
            8'h07:    dbg_misc_data_r <= D_r;
            8'h08:    dbg_misc_data_r <= L_r;
            8'h09:    dbg_misc_data_r <= H_r;
            8'h0A:    dbg_misc_data_r <= SP_r[7:0];
            8'h0B:    dbg_misc_data_r <= SP_r[15:8];

            default:  dbg_misc_data_r <= 0;
          endcase
    // ARCH/MMIO
    4'h1: casez(dbg_addr_r[7:0])
            8'h00:    dbg_misc_data_r <= REG_P1_r;
            8'h01:    dbg_misc_data_r <= REG_SB_r;
            8'h02:    dbg_misc_data_r <= REG_SC_r;

            8'h04:    dbg_misc_data_r <= REG_DIV_r;
            8'h05:    dbg_misc_data_r <= REG_TIMA_r;
            8'h06:    dbg_misc_data_r <= REG_TMA_r;
            8'h07:    dbg_misc_data_r <= REG_TAC_r;

            8'h0F:    dbg_misc_data_r <= REG_IF_r;

            8'h10:    dbg_misc_data_r <= REG_NR10_r;
            8'h11:    dbg_misc_data_r <= REG_NR11_r;
            8'h12:    dbg_misc_data_r <= REG_NR12_r;
            8'h13:    dbg_misc_data_r <= REG_NR13_r;
            8'h14:    dbg_misc_data_r <= REG_NR14_r;

            8'h16:    dbg_misc_data_r <= REG_NR21_r;
            8'h17:    dbg_misc_data_r <= REG_NR22_r;
            8'h18:    dbg_misc_data_r <= REG_NR23_r;
            8'h19:    dbg_misc_data_r <= REG_NR24_r;

            8'h1A:    dbg_misc_data_r <= REG_NR30_r;
            8'h1B:    dbg_misc_data_r <= REG_NR31_r;
            8'h1C:    dbg_misc_data_r <= REG_NR32_r;
            8'h1D:    dbg_misc_data_r <= REG_NR33_r;
            8'h1E:    dbg_misc_data_r <= REG_NR34_r;

            8'h20:    dbg_misc_data_r <= REG_NR41_r;
            8'h21:    dbg_misc_data_r <= REG_NR42_r;
            8'h22:    dbg_misc_data_r <= REG_NR43_r;
            8'h23:    dbg_misc_data_r <= REG_NR44_r;

            8'h24:    dbg_misc_data_r <= REG_NR50_r;
            8'h25:    dbg_misc_data_r <= REG_NR51_r;
            8'h26:    dbg_misc_data_r <= REG_NR52_r;

            8'h3?:    dbg_misc_data_r <= REG_WAV_r[dbg_addr_r[3:0]];

            8'h40:    dbg_misc_data_r <= REG_LCDC_r;
            8'h41:    dbg_misc_data_r <= REG_STAT_r;
            8'h42:    dbg_misc_data_r <= REG_SCY_r;
            8'h43:    dbg_misc_data_r <= REG_SCX_r;
            8'h44:    dbg_misc_data_r <= REG_LY_r;
            8'h45:    dbg_misc_data_r <= REG_LYC_r;
            8'h46:    dbg_misc_data_r <= REG_DMA_r;
            8'h47:    dbg_misc_data_r <= REG_BGP_r;
            8'h48:    dbg_misc_data_r <= REG_OBP0_r;
            8'h49:    dbg_misc_data_r <= REG_OBP1_r;
            8'h4A:    dbg_misc_data_r <= REG_WY_r;
            8'h4B:    dbg_misc_data_r <= REG_WX_r;

            8'h50:    dbg_misc_data_r <= REG_BOOT_r;

            8'hFF:    dbg_misc_data_r <= REG_IE_r;

            default:  dbg_misc_data_r <= 0;
          endcase
    // IFD
    4'h2: case(dbg_addr_r[7:0])
            8'h00:    dbg_misc_data_r <= ifd_op_r;
            8'h01:    dbg_misc_data_r <= ifd_size_r;
            8'h02:    dbg_misc_data_r <= ifd_data_r;
            8'h03:    dbg_misc_data_r <= ifd_decode_r[7:0];
            8'h04:    dbg_misc_data_r <= ifd_decode_r[15:8];
            8'h05:    dbg_misc_data_r <= MCT_IFD_rsp_val;
            8'h06:    dbg_misc_data_r <= ifd_size_r;
            8'h07:    dbg_misc_data_r <= ifd_decode_r[`DEC_SZE];
            8'h08:    dbg_misc_data_r <= ifd_pc[7:0];
            8'h09:    dbg_misc_data_r <= ifd_pc[15:8];
            8'h0A:    dbg_misc_data_r <= PC_r[7:0];
            8'h0B:    dbg_misc_data_r <= PC_r[15:8];
            8'h0C:    dbg_misc_data_r <= ifd_complete_r;

            default:  dbg_misc_data_r <= 0;
          endcase
    // EXE
    4'h3: case(dbg_addr_r[7:0])
            8'h00:    dbg_misc_data_r <= IFD_EXE_valid;
            8'h01:    dbg_misc_data_r <= IFD_EXE_op[7:0];
            8'h02:    dbg_misc_data_r <= IFD_EXE_op[15:8];
            8'h03:    dbg_misc_data_r <= IFD_EXE_op[23:16];
            8'h04:    dbg_misc_data_r <= exe_ime_r;

            8'h10:    dbg_misc_data_r <= IFD_EXE_decode[`DEC_GRP];
            8'h11:    dbg_misc_data_r <= IFD_EXE_decode[`DEC_LAT];
            8'h12:    dbg_misc_data_r <= IFD_EXE_decode[`DEC_DST];
            8'h13:    dbg_misc_data_r <= IFD_EXE_decode[`DEC_SRC];
            8'h14:    dbg_misc_data_r <= IFD_EXE_decode[`DEC_SZE];
            8'h15:    dbg_misc_data_r <= IFD_EXE_cb;

            8'h20:    dbg_misc_data_r <= exe_ctr_r;
            8'h21:    dbg_misc_data_r <= 0;
            8'h22:    dbg_misc_data_r <= exe_stage;
            8'h23:    dbg_misc_data_r <= exe_advance_r;
            8'h24:    dbg_misc_data_r <= exe_ready_r;
            8'h25:    dbg_misc_data_r <= exe_complete_r;
            8'h26:    dbg_misc_data_r <= exe_lat_add_r;
            8'h27:    dbg_misc_data_r <= exe_lat;

            8'h30:    dbg_misc_data_r <= IFD_EXE_pc_start[7:0];
            8'h31:    dbg_misc_data_r <= IFD_EXE_pc_start[15:8];
            8'h32:    dbg_misc_data_r <= IFD_EXE_pc_end[7:0];
            8'h33:    dbg_misc_data_r <= IFD_EXE_pc_end[15:8];
            8'h34:    dbg_misc_data_r <= IFD_EXE_pc_next[7:0];
            8'h35:    dbg_misc_data_r <= IFD_EXE_pc_next[15:8];

            8'h40:    dbg_misc_data_r <= exe_res_r[7:0];
            8'h41:    dbg_misc_data_r <= exe_res_r[15:8];
            8'h42:    dbg_misc_data_r <= exe_src_r[7:0];
            8'h43:    dbg_misc_data_r <= exe_src_r[15:8];
            8'h44:    dbg_misc_data_r <= exe_dst_r[7:0];
            8'h45:    dbg_misc_data_r <= exe_dst_r[15:8];
            8'h46:    dbg_misc_data_r <= exe_res_cc_r[7:0];
            8'h47:    dbg_misc_data_r <= exe_cc_r[7:0];
            8'h48:    dbg_misc_data_r <= EXE_MCT_req_addr_d1[7:0];
            8'h49:    dbg_misc_data_r <= EXE_MCT_req_addr_d1[15:8];
            8'h4A:    dbg_misc_data_r <= exe_mem_data_r[7:0];
            8'h4B:    dbg_misc_data_r <= exe_mem_data_r[15:8];
            8'h4C:    dbg_misc_data_r <= exe_res_los_r;
            8'h4D:    dbg_misc_data_r <= exe_src_alu_r;

            8'h50:    dbg_misc_data_r <= EXE_IFD_redirect;
            8'h51:    dbg_misc_data_r <= EXE_IFD_target[7:0];
            8'h52:    dbg_misc_data_r <= EXE_IFD_target[15:8];
            8'h53:    dbg_misc_data_r <= exe_pc_prev_r[7:0];
            8'h54:    dbg_misc_data_r <= exe_pc_prev_r[15:8];
            8'h55:    dbg_misc_data_r <= exe_pc_prev_redirect_r[7:0];
            8'h56:    dbg_misc_data_r <= exe_pc_prev_redirect_r[15:8];
            8'h57:    dbg_misc_data_r <= exe_target_prev_redirect_r[7:0];
            8'h58:    dbg_misc_data_r <= exe_target_prev_redirect_r[15:8];

            //8'h60:    dbg_misc_data_r <= tmp_div_r[3:0];
            //8'h61:    dbg_misc_data_r <= tmp_latency_r;
            //8'h62:    dbg_misc_data_r <= tmp_latency2_r;
            //8'h63:    dbg_misc_data_r <= tmp_latency3_r;

            8'h70:    dbg_misc_data_r <= IFD_EXE_int;

            default:  dbg_misc_data_r <= 0;
          endcase
`ifndef MK2
    // MCT,REG
    4'h4: casez(dbg_addr_r[7:0])
            8'h00:    dbg_misc_data_r <= mct_state_r;
            8'h01:    dbg_misc_data_r <= mct_req_r;
            8'h02:    dbg_misc_data_r <= mct_addr_r[7:0];
            8'h03:    dbg_misc_data_r <= mct_addr_r[15:8];
            8'h04:    dbg_misc_data_r <= mct_src_r;
            8'h05:    dbg_misc_data_r <= mct_wr_r;
            8'h06:    dbg_misc_data_r <= mct_mdr_r;

            8'h10:    dbg_misc_data_r <= reg_state_r;
            8'h11:    dbg_misc_data_r <= reg_req_r;
            8'h12:    dbg_misc_data_r <= reg_addr_r[6:0];
            //8'h13:    dbg_misc_data_r <= 0;
            8'h14:    dbg_misc_data_r <= reg_src_r;
            8'h15:    dbg_misc_data_r <= reg_wr_r;
            8'h16:    dbg_misc_data_r <= reg_mdr_r;

            8'h20:    dbg_misc_data_r <= mct_vram_error_r[7:0];
            8'h21:    dbg_misc_data_r <= mct_vram_error_r[15:8];
            8'h22:    dbg_misc_data_r <= mct_oam_error_r[7:0];
            8'h23:    dbg_misc_data_r <= mct_oam_error_r[15:8];

            8'hC0:    dbg_misc_data_r <= HLT_REQ_sync;
            8'hC1:    dbg_misc_data_r <= HLT_RSP;
            8'hC2:    dbg_misc_data_r <= HLT_IFD_rsp;
            8'hC3:    dbg_misc_data_r <= HLT_EXE_rsp;
            8'hC4:    dbg_misc_data_r <= HLT_DMA_rsp;
            8'hC5:    dbg_misc_data_r <= HLT_SER_rsp;
            8'hC6:    dbg_misc_data_r <= ~|ifd_size_r;
            8'hC7:    dbg_misc_data_r <= ~ifd_int_r;
            8'hC8:    dbg_misc_data_r <= EXE_IFD_ime;
            8'hC9:    dbg_misc_data_r <= IDL_ICD;

            8'hD?:    dbg_misc_data_r <= DBG_MAIN_DATA_IN;
            8'hE?:    dbg_misc_data_r <= DBG_CHEAT_DATA_IN;
            8'hF?:    dbg_misc_data_r <= DBG_MBC_DATA_IN;

            default:  dbg_misc_data_r <= 0;
          endcase
    // PPU
    4'h5: casez(dbg_addr_r[7:0])
            8'h00:    dbg_misc_data_r <= PPU_HSYNC_EDGE;
            8'h01:    dbg_misc_data_r <= PPU_VSYNC_EDGE;
            8'h02:    dbg_misc_data_r <= PPU_PIXEL_VALID;
            8'h03:    dbg_misc_data_r <= PPU_PIXEL;
            8'h04:    dbg_misc_data_r <= PPU_DOT_EDGE;

            8'h10:    dbg_misc_data_r <= ppu_state_r[7:0];
            8'h11:    dbg_misc_data_r <= ppu_state_r[12:8];
            8'h12:    dbg_misc_data_r <= ppu_dot_ctr_r[7:0];
            8'h13:    dbg_misc_data_r <= ppu_dot_ctr_r[8];

            8'h20:    dbg_misc_data_r <= ppu_tile_ctr_r[1:0];
            //8'h21:    dbg_misc_data_r <= 0;
            8'h22:    dbg_misc_data_r <= ppu_tile_ctr_r;
            8'h23:    dbg_misc_data_r <= ppu_pix_ctr_r;
            //8'h24:    dbg_misc_data_r <= 0;
            8'h25:    dbg_misc_data_r <= ppu_first_frame_r;

            8'h30:    dbg_misc_data_r <= dbg_reg_ly_r[7:0];
            8'h31:    dbg_misc_data_r <= dbg_dot_ctr_r[7:0];
            8'h32:    dbg_misc_data_r <= dbg_dot_ctr_r[8:8];
            8'h33:    dbg_misc_data_r <= dbg_oam_active_r;
            8'h34:    dbg_misc_data_r <= dbg_vram_active_r;
            8'h35:    dbg_misc_data_r <= dbg_dma_active_r;

            8'h40:    dbg_misc_data_r <= ppu_stat_active_r;
            8'h41:    dbg_misc_data_r <= ppu_stat_match_r;
            8'h42:    dbg_misc_data_r <= dbg_ppu_stat_match_r;
            8'h43:    dbg_misc_data_r <= dbg_ppu_stat_dot_ctr_r[7:0];
            8'h44:    dbg_misc_data_r <= dbg_ppu_stat_dot_ctr_r[8:8];
            //8'h45:    dbg_misc_data_r <= dbg_timer_ly_r;
            //8'h46:    dbg_misc_data_r <= dbg_timer_dot_ctr_r[7:0];
            //8'h47:    dbg_misc_data_r <= dbg_timer_dot_ctr_r[8:8];

            8'hA0:    dbg_misc_data_r <= apu_square1_enable_r;
            8'hA1:    dbg_misc_data_r <= apu_square1_timer_r[7:0];
            8'hA2:    dbg_misc_data_r <= apu_square1_timer_r[12:8];
            8'hA3:    dbg_misc_data_r <= apu_square1_length_r;
            8'hA4:    dbg_misc_data_r <= apu_square1_env_timer_r;
            8'hA5:    dbg_misc_data_r <= apu_square1_volume_r;
            8'hA6:    dbg_misc_data_r <= apu_square1_pos_r;
            8'hA7:    dbg_misc_data_r <= apu_square1_sweep_enable_r;
            8'hA8:    dbg_misc_data_r <= apu_square1_sweep_freq_r[7:0];
            8'hA9:    dbg_misc_data_r <= apu_square1_sweep_freq_r[10:8];
            8'hAA:    dbg_misc_data_r <= apu_square1_period[7:0];
            8'hAB:    dbg_misc_data_r <= apu_square1_period[12:8];
            //8'hAC:    dbg_misc_data_r <= apu_square1_duty;
            8'hAF:    dbg_misc_data_r <= apu_square1_output[4:0];

            8'hB0:    dbg_misc_data_r <= apu_square2_enable_r;
            8'hB1:    dbg_misc_data_r <= apu_square2_timer_r[7:0];
            8'hB2:    dbg_misc_data_r <= apu_square2_timer_r[12:8];
            8'hB3:    dbg_misc_data_r <= apu_square2_length_r;
            8'hB4:    dbg_misc_data_r <= apu_square2_env_timer_r;
            8'hB5:    dbg_misc_data_r <= apu_square2_volume_r;
            8'hB6:    dbg_misc_data_r <= apu_square2_pos_r;
            //8'hB7:    dbg_misc_data_r <= apu_square2_sweep_enable_r;
            //8'hB8:    dbg_misc_data_r <= apu_square2_sweep_freq_r[7:0];
            //8'hB9:    dbg_misc_data_r <= apu_square2_sweep_freq_r[15:8];
            8'hBA:    dbg_misc_data_r <= apu_square2_period[7:0];
            8'hBB:    dbg_misc_data_r <= apu_square2_period[12:8];
            //8'hBC:    dbg_misc_data_r <= apu_square2_duty;
            8'hBF:    dbg_misc_data_r <= apu_square2_output[4:0];

            8'hC0:    dbg_misc_data_r <= apu_wave_enable_r;
            8'hC1:    dbg_misc_data_r <= apu_wave_length_r[7:0];
            //8'hC2:    dbg_misc_data_r <= 0;
            8'hC3:    dbg_misc_data_r <= apu_wave_pos_r;
            8'hC4:    dbg_misc_data_r <= apu_wave_timer_r[7:0];
            8'hC5:    dbg_misc_data_r <= apu_wave_timer_r[11:8];
            //8'hC6:    dbg_misc_data_r <= apu_wave_timer_r[23:16];
            //8'hC7:    dbg_misc_data_r <= apu_wave_timer_r[31:24];
            8'hC8:    dbg_misc_data_r <= apu_wave_period[7:0];
            8'hC9:    dbg_misc_data_r <= apu_wave_period[11:8];
            8'hCF:    dbg_misc_data_r <= apu_wave_output[4:0];

            8'hD0:    dbg_misc_data_r <= apu_noise_enable_r;
            8'hD1:    dbg_misc_data_r <= apu_noise_length_r;
            8'hD2:    dbg_misc_data_r <= apu_noise_env_timer_r;
            8'hD3:    dbg_misc_data_r <= apu_noise_volume_r;
            8'hD4:    dbg_misc_data_r <= apu_noise_timer_r[7:0];
            8'hD5:    dbg_misc_data_r <= apu_noise_timer_r[15:8];
            8'hD6:    dbg_misc_data_r <= apu_noise_timer_r[21:16];
            //8'hD7:    dbg_misc_data_r <= apu_noise_timer_r[31:24];
            8'hD8:    dbg_misc_data_r <= apu_noise_period[7:0];
            8'hD9:    dbg_misc_data_r <= apu_noise_period[15:8];
            8'hDA:    dbg_misc_data_r <= apu_noise_period[21:16];
            //8'hDB:    dbg_misc_data_r <= apu_noise_period[31:24];
            8'hDC:    dbg_misc_data_r <= apu_noise_lfsr_r[7:0];
            8'hDD:    dbg_misc_data_r <= apu_noise_lfsr_r[14:8];
            8'hDF:    dbg_misc_data_r <= apu_noise_output[4:0];

            8'hE0:    dbg_misc_data_r <= APU_DAT[7:0];
            8'hE1:    dbg_misc_data_r <= APU_DAT[9:8];
            8'hE2:    dbg_misc_data_r <= APU_DAT[17:10];
            8'hE3:    dbg_misc_data_r <= APU_DAT[19:18];

            default:  dbg_misc_data_r <= 0;
          endcase
`endif

    // ICD2
    4'h6: dbg_misc_data_r <= DBG_ICD2_DATA_IN;

    // CONFIG
    4'h7: case(dbg_addr_r[7:0])
            8'h00:    dbg_misc_data_r <= config_r[0];
            8'h01:    dbg_misc_data_r <= config_r[1];
            8'h02:    dbg_misc_data_r <= config_r[2];
            8'h03:    dbg_misc_data_r <= config_r[3];
            8'h04:    dbg_misc_data_r <= config_r[4];
            8'h05:    dbg_misc_data_r <= config_r[5];
            8'h06:    dbg_misc_data_r <= config_r[6];
            8'h07:    dbg_misc_data_r <= config_r[7];

            default:  dbg_misc_data_r <= 0;
          endcase

    default: dbg_misc_data_r <= 0;
  endcase
`endif

end

reg         step_r;
assign      DBG_EXE_step = step_r;

`ifdef SGB_DEBUG
assign {config_r[7],config_r[6],config_r[5],config_r[4],config_r[3],config_r[2],config_r[1],config_r[0]} = DBG_CONFIG;

assign      dbg_brk_enabled          = config_r[0][0];
assign      dbg_brk_matchpartialinst = config_r[0][1];
//
wire [7:0]  dbg_brk_stepcnt      = config_r[1];
wire [7:0]  dbg_brk_data_watch   = config_r[4];
wire [15:0] dbg_brk_addr_watch   = {config_r[6],config_r[5]};

// breakpoints
reg         dbg_brk_inst_rd_byte = 0;
reg         dbg_brk_data_rd_byte = 0;
reg         dbg_brk_data_wr_byte = 0;
reg         dbg_brk_inst_rd_addr = 0;
reg         dbg_brk_data_rd_addr = 0;
reg         dbg_brk_data_wr_addr = 0;
reg         dbg_brk_data         = 0;
reg         dbg_brk_stop         = 0;
reg         dbg_brk_error        = 0;

reg [15:0]  dbg_brk_addr_r;
reg [7:0]   dbg_brk_data_r;

reg [7:0]   stepcnt_r = 0;
always @(posedge CLK) begin
  step_r <= ~dbg_brk_enabled | (stepcnt_r != dbg_brk_stepcnt);
  if (CLK_BUS_EDGE & exe_advance_r) stepcnt_r <= dbg_brk_stepcnt;
end

assign DBG_BRK = |(config_r[2] & {dbg_brk_error,dbg_brk_stop,dbg_brk_data_wr_addr,dbg_brk_data_rd_addr,dbg_brk_inst_rd_addr,dbg_brk_data_wr_byte,dbg_brk_data_rd_byte,dbg_brk_inst_rd_byte});// | RST;

reg dbg_mem_req_val_d1_r;
reg dbg_mem_req_wr_d1_r;

reg  [15:0] dbg_mct_vram_error_r;
reg  [15:0] dbg_mct_oam_error_r;

always @(posedge CLK) begin
  if (RST) begin
    dbg_brk_inst_rd_byte <= 0;
    dbg_brk_data_rd_byte <= 0;
    dbg_brk_data_wr_byte <= 0;

    dbg_brk_inst_rd_addr <= 0;
    dbg_brk_data_rd_addr <= 0;
    dbg_brk_data_wr_addr <= 0;
    dbg_brk_stop         <= 0;
    dbg_brk_error        <= 0;

    dbg_brk_addr_r       <= 0;
  end
  else begin
    dbg_brk_inst_rd_addr <= IFD_EXE_valid && (IFD_EXE_pc_start == dbg_brk_addr_r);
    dbg_brk_data_rd_addr <= (exe_advance_r && exe_complete_r) ? 0 : (IFD_EXE_valid && dbg_mem_req_val_d1_r && ~dbg_mem_req_wr_d1_r && EXE_MCT_req_addr_d1 == dbg_brk_addr_r); //&& (!config_r[2][0] ||     mmc_data_r[7:0] == dbg_brk_data_r);
    dbg_brk_data_wr_addr <= (exe_advance_r && exe_complete_r) ? 0 : (IFD_EXE_valid && dbg_mem_req_val_d1_r &&  dbg_mem_req_wr_d1_r && EXE_MCT_req_addr_d1 == dbg_brk_addr_r && (!config_r[2][0] || EXE_MCT_req_data_d1 == dbg_brk_data_r));
    dbg_brk_stop         <= IFD_EXE_valid & IFD_EXE_int;
    dbg_brk_error        <= (  0
                            || (mct_vram_error_r != dbg_mct_vram_error_r)
                            || (mct_oam_error_r != dbg_mct_oam_error_r)
                            );

    dbg_brk_addr_r <= dbg_brk_addr_watch;
    dbg_brk_data_r <= dbg_brk_data_watch;

    dbg_mem_req_val_d1_r <= EXE_MCT_req_val;
    dbg_mem_req_wr_d1_r <= EXE_MCT_req_wr;

    dbg_mct_vram_error_r <= mct_vram_error_r;
    dbg_mct_oam_error_r <= mct_oam_error_r;
  end
end

`else
always @(posedge CLK) step_r <= 1;

assign DBG_BRK = 0;
`endif

endmodule

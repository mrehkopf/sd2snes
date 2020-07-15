`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// Company: Rehkopf
// Engineer: Rehkopf
//
// Create Date:    01:13:46 05/09/2009
// Design Name:
// Module Name:    main
// Project Name:
// Target Devices:
// Tool versions:
// Description: Master Control FSM
//
// Dependencies: address
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`include "config.vh"

module main(
`ifdef MK2
  /* Bus 1: PSRAM, 128Mbit, 16bit, 70ns */
  output [22:0] ROM_ADDR,
  output ROM_CE,
  input MCU_OVR,
  /* debug */
  output p113_out,
`endif
`ifdef MK3
  input SNES_CIC_CLK,
  /* Bus 1: 2x PSRAM, 64Mbit, 16bit, 70ns */
  output [21:0] ROM_ADDR,
  output ROM_1CE,
  output ROM_2CE,
  output ROM_ZZ,
  /* debug */
  output PM6_out,
  output PN6_out,
  input  PT5_in,
`endif

  /* input clock */
  input CLKIN,

  /* SNES signals */
  input [23:0] SNES_ADDR_IN,
  input SNES_READ_IN,
  input SNES_WRITE_IN,
  input SNES_ROMSEL_IN,
  inout [7:0] SNES_DATA,
  input SNES_CPU_CLK_IN,
  input SNES_REFRESH,
  output SNES_IRQ,
  output SNES_DATABUS_OE,
  output SNES_DATABUS_DIR,
  input SNES_SYSCLK,

  input [7:0] SNES_PA_IN,
  input SNES_PARD_IN,
  input SNES_PAWR_IN,

  /* SRAM signals */
  inout [15:0] ROM_DATA,
  output ROM_OE,
  output ROM_WE,
  output ROM_BHE,
  output ROM_BLE,

  /* Bus 2: SRAM, 4Mbit, 8bit, 45ns */
  inout [7:0] RAM_DATA,
  output [18:0] RAM_ADDR,
  output RAM_OE,
  output RAM_WE,

  /* MCU signals */
  input SPI_MOSI,
  inout SPI_MISO,
  input SPI_SS,
  input SPI_SCK,

  output MCU_RDY,

  output DAC_MCLK,
  output DAC_LRCK,
  output DAC_SDOUT,

  /* SD signals */
  input [3:0] SD_DAT,
  inout SD_CMD,
  inout SD_CLK
);

wire CLK2;

wire MCU_ROM;
wire MCU_RAM;
wire MCU_RRQ;
wire MCU_WRQ;
wire [7:0] MCU_DOUT;

wire [7:0] spi_cmd_data;
wire [7:0] spi_param_data;
wire [7:0] spi_input_data;
wire [31:0] spi_byte_cnt;
wire [2:0] spi_bit_cnt;
wire [23:0] MCU_ADDR;
wire [3:0] MAPPER;
wire [23:0] SAVERAM_MASK;
wire [23:0] ROM_MASK;
wire [7:0] SD_DMA_SRAM_DATA;
wire [1:0] SD_DMA_TGT;
wire [10:0] SD_DMA_PARTIAL_START;
wire [10:0] SD_DMA_PARTIAL_END;

wire [10:0] dac_addr;
wire [2:0] dac_vol_select_out;
wire [8:0] dac_ptr_addr;
//wire [7:0] dac_volume;
wire [7:0] msu_volumerq_out;
wire [7:0] msu_status_out;
wire [31:0] msu_addressrq_out;
wire [15:0] msu_trackrq_out;
wire [13:0] msu_write_addr;
wire [13:0] msu_ptr_addr;
wire [7:0] MSU_SNES_DATA_IN;
wire [7:0] MSU_SNES_DATA_OUT;
wire [5:0] msu_status_reset_bits;
wire [5:0] msu_status_set_bits;

wire [7:0] SGB_SNES_DATA_IN;
wire [7:0] SGB_SNES_DATA_OUT;
wire [19:0] SGB_APU_DAT;
wire [55:0] SGB_RTC_DAT;
wire [55:0] MCU_RTC_DAT;
wire        MCU_RTC_WE;
wire        MCU_RTC_RD;

wire       SGB_ROM_RRQ;
wire       SGB_ROM_WRQ;
wire       sgb_enable;

wire [15:0] featurebits;
wire feat_cmd_unlock = featurebits[5];

wire [23:0] MAPPED_SNES_ADDR;
wire ROM_ADDR0;

wire [13:0] DBG_msu_address;
wire DBG_msu_reg_oe_rising;
wire DBG_msu_reg_oe_falling;
wire DBG_msu_reg_we_rising;
wire [2:0] SD_DMA_DBG_clkcnt;
wire [10:0] SD_DMA_DBG_cyclecnt;

wire [15:0] dsp_feat;

wire [8:0] snescmd_addr_mcu;
wire [7:0] snescmd_data_out_mcu;
wire [7:0] snescmd_data_in_mcu;

// config
wire [7:0] reg_group;
wire [7:0] reg_index;
wire [7:0] reg_value;
wire [7:0] reg_invmask;
wire       reg_we;
wire [7:0] reg_read;
// unit level configuration output
wire [7:0] sgb_config_data;

reg [7:0] SNES_PARDr = 8'b11111111;
reg [7:0] SNES_PAWRr = 8'b11111111;
reg [7:0] SNES_READr = 8'b11111111;
reg [7:0] SNES_WRITEr = 8'b11111111;
reg [7:0] SNES_CPU_CLKr = 8'b00000000;
reg [7:0] SNES_ROMSELr = 8'b11111111;
reg [23:0] SNES_ADDRr [6:0];
reg [7:0] SNES_PAr [6:0];
reg [7:0] SNES_DATAr [4:0];

reg SNES_DEADr = 1;
reg SNES_reset_strobe = 0;

reg free_strobe = 0;
reg ram_free_strobe = 0;

wire [23:0] SNES_ADDR = (SNES_ADDRr[6] & SNES_ADDRr[5]);
wire [7:0] SNES_PA = (SNES_PAr[6] & SNES_PAr[5]);
wire [7:0] SNES_DATA_IN = (SNES_DATAr[3] & SNES_DATAr[2]);

wire SNES_PARD_start = (SNES_PARDr[6:1] == 6'b111110);
// Sample PAWR data earlier on CPU accesses, later on DMA accesses...
wire SNES_PAWR_start = (SNES_PAWRr[7:1] == (({SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h02100) ? 7'b1110000 : 7'b1000000));
wire SNES_PAWR_end = (SNES_PAWRr[6:1] == 6'b000001);
wire SNES_RD_start = (SNES_READr[6:1] == 6'b111110);
wire SNES_RD_end = (SNES_READr[6:1] == 6'b000001);
wire SNES_WR_end = (SNES_WRITEr[6:1] == 6'b000001);
wire SNES_cycle_start = (SNES_CPU_CLKr[6:1] == 6'b000001);
wire SNES_cycle_end = (SNES_CPU_CLKr[6:1] == 6'b111110);
wire SNES_WRITE = SNES_WRITEr[2] & SNES_WRITEr[1];
wire SNES_READ = SNES_READr[2] & SNES_READr[1];
wire SNES_CPU_CLK = SNES_CPU_CLKr[2] & SNES_CPU_CLKr[1];
wire SNES_PARD = SNES_PARDr[2] & SNES_PARDr[1];
wire SNES_PAWR = SNES_PAWRr[2] & SNES_PAWRr[1];

wire SNES_ROMSEL = (SNES_ROMSELr[5] & SNES_ROMSELr[4]);

reg [7:0] BUS_DATA;

always @(posedge CLK2) begin
  if(~SNES_READ) BUS_DATA <= SNES_DATA;
  else if(~SNES_WRITE) BUS_DATA <= SNES_DATA_IN;
end

wire SGB_FREE_SLOT;
wire free_slot = SGB_FREE_SLOT;
wire ram_free_slot;

wire ROM_HIT;
wire IS_ROM;
assign DCM_RST=0;
wire IS_SAVERAM;

always @(posedge CLK2) begin
  SNES_PARDr  <= {SNES_PARDr[6:0], SNES_PARD_IN};
  SNES_PAWRr  <= {SNES_PAWRr[6:0], SNES_PAWR_IN};
  SNES_READr  <= {SNES_READr[6:0], SNES_READ_IN};
  SNES_WRITEr <= {SNES_WRITEr[6:0], SNES_WRITE_IN};
  SNES_CPU_CLKr <= {SNES_CPU_CLKr[6:0], SNES_CPU_CLK_IN};
  SNES_ROMSELr <= {SNES_ROMSELr[6:0], SNES_ROMSEL_IN};
  SNES_ADDRr[6] <= SNES_ADDRr[5];
  SNES_ADDRr[5] <= SNES_ADDRr[4];
  SNES_ADDRr[4] <= SNES_ADDRr[3];
  SNES_ADDRr[3] <= SNES_ADDRr[2];
  SNES_ADDRr[2] <= SNES_ADDRr[1];
  SNES_ADDRr[1] <= SNES_ADDRr[0];
  SNES_ADDRr[0] <= SNES_ADDR_IN;
  SNES_PAr[6] <= SNES_PAr[5];
  SNES_PAr[5] <= SNES_PAr[4];
  SNES_PAr[4] <= SNES_PAr[3];
  SNES_PAr[3] <= SNES_PAr[2];
  SNES_PAr[2] <= SNES_PAr[1];
  SNES_PAr[1] <= SNES_PAr[0];
  SNES_PAr[0] <= SNES_PA_IN;
  SNES_DATAr[4] <= SNES_DATAr[3];
  SNES_DATAr[3] <= SNES_DATAr[2];
  SNES_DATAr[2] <= SNES_DATAr[1];
  SNES_DATAr[1] <= SNES_DATAr[0];
  SNES_DATAr[0] <= SNES_DATA;
end

parameter ST_IDLE            = 9'b000000001;
parameter ST_MCU_RD_ADDR     = 9'b000000010;
parameter ST_MCU_RD_END      = 9'b000000100;
parameter ST_MCU_WR_ADDR     = 9'b000001000;
parameter ST_MCU_WR_END      = 9'b000010000;
parameter ST_SGB_ROM_RD_ADDR = 9'b000100000;
parameter ST_SGB_ROM_RD_END  = 9'b001000000;
parameter ST_SGB_ROM_WR_ADDR = 9'b010000000;
parameter ST_SGB_ROM_WR_END  = 9'b100000000;

parameter SNES_DEAD_TIMEOUT = 17'd84000; // 1ms

parameter ROM_CYCLE_LEN = 4'd7;

reg [8:0] STATE;
initial STATE = ST_IDLE;

assign MSU_SNES_DATA_IN = BUS_DATA;
assign SGB_SNES_DATA_IN = BUS_DATA;

sd_dma snes_sd_dma(
  .CLK(CLK2),
  .SD_DAT(SD_DAT),
  .SD_CLK(SD_CLK),
  .SD_DMA_EN(SD_DMA_EN),
  .SD_DMA_STATUS(SD_DMA_STATUS),
  .SD_DMA_SRAM_WE(SD_DMA_SRAM_WE),
  .SD_DMA_SRAM_DATA(SD_DMA_SRAM_DATA),
  .SD_DMA_NEXTADDR(SD_DMA_NEXTADDR),
  .SD_DMA_PARTIAL(SD_DMA_PARTIAL),
  .SD_DMA_PARTIAL_START(SD_DMA_PARTIAL_START),
  .SD_DMA_PARTIAL_END(SD_DMA_PARTIAL_END),
  .SD_DMA_START_MID_BLOCK(SD_DMA_START_MID_BLOCK),
  .SD_DMA_END_MID_BLOCK(SD_DMA_END_MID_BLOCK),
  .DBG_cyclecnt(SD_DMA_DBG_cyclecnt),
  .DBG_clkcnt(SD_DMA_DBG_clkcnt)
);

wire SD_DMA_TO_ROM = (SD_DMA_STATUS && (SD_DMA_TGT == 2'b00)) && MCU_ROM;
wire SD_DMA_TO_RAM = (SD_DMA_STATUS && (SD_DMA_TGT == 2'b00)) && MCU_RAM;

dac snes_dac(
  .clkin(CLK2),
  .sysclk(SNES_SYSCLK),
  .mclk_out(DAC_MCLK),
  .lrck_out(DAC_LRCK),
  .sdout(DAC_SDOUT),
  .we(SD_DMA_TGT==2'b01 ? SD_DMA_SRAM_WE : 1'b1),
  .pgm_address(dac_addr),
  .pgm_data(SD_DMA_SRAM_DATA),
  .DAC_STATUS(DAC_STATUS),
  .volume(msu_volumerq_out),
  .sgb_apu_dat(SGB_APU_DAT),
  .sgb_apu_clk_edge(SGB_APU_CLK_EDGE),
  .vol_latch(msu_volume_latch_out),
  .vol_select(dac_vol_select_out),
  .palmode(dac_palmode_out),
  .play(dac_play),
  .reset(dac_reset),
  .dac_address_ext(dac_ptr_addr)
);

msu snes_msu (
  .clkin(CLK2),
  .enable(msu_enable),
  .pgm_address(msu_write_addr),
  .pgm_data(SD_DMA_SRAM_DATA),
  .pgm_we(SD_DMA_TGT==2'b10 ? SD_DMA_SRAM_WE : 1'b1),
  .reg_addr(SNES_ADDR[2:0]),
  .reg_data_in(MSU_SNES_DATA_IN),
  .reg_data_out(MSU_SNES_DATA_OUT),
  .reg_oe_falling(SNES_RD_start),
  .reg_oe_rising(SNES_RD_end),
  .reg_we_rising(SNES_WR_end),
  .status_out(msu_status_out),
  .volume_out(msu_volumerq_out),
  .volume_latch_out(msu_volume_latch_out),
  .addr_out(msu_addressrq_out),
  .track_out(msu_trackrq_out),
  .status_reset_bits(msu_status_reset_bits),
  .status_set_bits(msu_status_set_bits),
  .status_reset_we(msu_status_reset_we),
  .msu_address_ext(msu_ptr_addr),
  .msu_address_ext_write(msu_addr_reset),
  .DBG_msu_reg_oe_rising(DBG_msu_reg_oe_rising),
  .DBG_msu_reg_oe_falling(DBG_msu_reg_oe_falling),
  .DBG_msu_reg_we_rising(DBG_msu_reg_we_rising),
  .DBG_msu_address(DBG_msu_address),
  .DBG_msu_address_ext_write_rising(DBG_msu_address_ext_write_rising)
);

spi snes_spi(
  .clk(CLK2),
  .MOSI(SPI_MOSI),
  .MISO(SPI_MISO),
  .SSEL(SPI_SS),
  .SCK(SPI_SCK),
  .cmd_ready(spi_cmd_ready),
  .param_ready(spi_param_ready),
  .cmd_data(spi_cmd_data),
  .param_data(spi_param_data),
  .endmessage(spi_endmessage),
  .startmessage(spi_startmessage),
  .input_data(spi_input_data),
  .byte_cnt(spi_byte_cnt),
  .bit_cnt(spi_bit_cnt)
);

// RAM contains the SNES ROM and is memory mapped to 880000-8FFFFF
assign MCU_RAM = MCU_ADDR[23:19] == {4'h8,1'b1};
`ifdef SGB_MCU_ACCESS
// 800000-8FFFFF is owned by RAM and SGB except for WRAM at 80C000-80DFFF.  Any MCU accesses to mirrored SRAM needs to instead access Exxxxx directly and not 80A000.
assign MCU_ROM = (MCU_ADDR[23:20] != 4'h8 || {MCU_ADDR[19:13],1'b0} == 8'h0C || MCU_ADDR[23:8] == 16'h8000);
`else
assign MCU_ROM = ~MCU_RAM;
`endif

reg  [7:0]  SGB_ROM_DINr;
wire [23:0] SGB_ROM_ADDR;
wire        SGB_ROM_WORD;
wire [7:0]  SGB_ROM_DATA;

wire        SGB_MCU_RSP;
wire [7:0]  SGB_MCU_DIN;

// MCU accesses to SGB state
reg         RQ_SGB_MCU_RDYr = 1;
reg         MCU_SGB_RD_PENDr = 0;
reg         MCU_SGB_WR_PENDr = 0;
reg [18:0]  SGB_ADDRr;

always @(posedge CLK2) begin
  if(MCU_RRQ & ~(MCU_ROM | MCU_RAM)) begin
    MCU_SGB_RD_PENDr <= 1'b1;
    RQ_SGB_MCU_RDYr <= 1'b0;
    SGB_ADDRr <= MCU_ADDR[18:0];
  end else if(MCU_WRQ & ~(MCU_ROM | MCU_RAM)) begin
    MCU_SGB_WR_PENDr <= 1'b1;
    RQ_SGB_MCU_RDYr <= 1'b0;
    SGB_ADDRr <= MCU_ADDR[18:0];
  end else if(SGB_MCU_RSP) begin
    MCU_SGB_RD_PENDr <= 1'b0;
    MCU_SGB_WR_PENDr <= 1'b0;
    RQ_SGB_MCU_RDYr <= 1'b1;
  end
end

//-------------------------------------------------------------------
// SGB
//-------------------------------------------------------------------

// CTX saves and restores architectural visible (and other state).
// When enabled, the SaveRAM portion of the PSRAM is used
// capture up to 64KB of additional state covering one saved image.

parameter
  ST_CTX_IDLE     = 4'b0001,
  ST_CTX_HALT     = 4'b0010,
  ST_CTX_READ     = 4'b0100,
  ST_CTX_WRITE    = 4'b1000;

reg  [3:0]  ctx_state_r = ST_CTX_IDLE;
reg         ctx_mode_r;
reg         ctx_req_r;
reg  [15:0] ctx_addr_r;
reg  [7:0]  ctx_data_r;

wire        button_ctx_valid;
wire        button_ctx_mode;

wire        SGB_reset;

wire        ctx_active = |(ctx_state_r & (ST_CTX_READ | ST_CTX_WRITE));
wire        ctx_rrq    = ctx_req_r & |(ctx_state_r & ST_CTX_READ);
wire        ctx_wrq    = ctx_req_r & |(ctx_state_r & ST_CTX_WRITE);
// Use the lower 32KB (normally ROM) for SaveRAM.  State is located in second 64KB of PSRAM's SaveRAM region.
wire [23:0] ctx_addr   = (|(ctx_state_r & ST_CTX_READ) ^ ctx_mode_r) ? {(ctx_addr_r[15] ? 8'h80 : 8'hE0),ctx_addr_r} : {8'hE1,ctx_addr_r};

wire        mcu_rdy_int;
wire        mcu_rrq_int;
wire        mcu_wrq_int;
wire [23:0] mcu_addr_int;
wire [7:0]  mcu_dout_int;

wire        HLT_REQ = ~|(ctx_state_r & ST_CTX_IDLE);
wire        HLT_RSP;

wire [11:0] DBG_ADDR;
wire [7:0]  DBG_CHEAT_DATA_OUT;

wire [7:0]  CTX_DINr;

// MCU mux
assign      MCU_RDY  = ctx_active ? 0          : mcu_rdy_int;
assign      MCU_RRQ  = ctx_active ? ctx_rrq    : mcu_rrq_int;
assign      MCU_WRQ  = ctx_active ? ctx_wrq    : mcu_wrq_int;
assign      MCU_ADDR = ctx_active ? ctx_addr   : mcu_addr_int;
assign      MCU_DOUT = ctx_active ? ctx_data_r : mcu_dout_int;

`ifdef SGB_SAVE_STATES
always @(posedge CLK2) begin
  if (SNES_reset_strobe | SGB_reset) begin
    ctx_state_r <= ST_CTX_IDLE;
    ctx_addr_r <= 0;
  end
  else begin
    ctx_req_r <= 0;
    case (ctx_state_r)
      ST_CTX_IDLE: begin
        ctx_mode_r <= button_ctx_mode;
        if (button_ctx_valid & ~HLT_RSP) ctx_state_r <= ST_CTX_HALT;
      end
      ST_CTX_HALT: begin
        if (HLT_RSP & ~(mcu_rrq_int| mcu_wrq_int) & mcu_rdy_int) begin
          ctx_req_r   <= 1;
          ctx_state_r <= ST_CTX_READ;
        end
      end
      ST_CTX_READ: begin
        ctx_data_r <= CTX_DINr;
        if (~ctx_req_r & mcu_rdy_int) begin
          ctx_req_r   <= 1;
          ctx_state_r <= ST_CTX_WRITE;
        end
      end
      ST_CTX_WRITE: begin
        if (~ctx_req_r & mcu_rdy_int) begin
          ctx_req_r   <= 1;
          ctx_addr_r  <= ctx_addr_r + 1;
          // TODO: decide if making save states a little faster is worth the extra logic (and bugs?)
          //ctx_addr_r  <= ( (~ctx_addr_r[15] && ctx_addr_r[14:0] == SAVERAM_MASK[14:0]) ? 16'h8000
          //               : (ctx_addr_r == 16'h9FFF)                                    ? 16'hC000
          //               :                                                               ctx_addr_r + 1
          //               );
          ctx_state_r <= &ctx_addr_r ? ST_CTX_IDLE : ST_CTX_READ;
        end
      end
    endcase
  end
end
`endif

reg  [7:0]  dbg_data_r;

always @(posedge CLK2) begin
  casez(DBG_ADDR[3:0])
    4'h0:    dbg_data_r <= ctx_state_r;
    4'h1:    dbg_data_r <= ctx_mode_r;
    4'h2:    dbg_data_r <= ctx_req_r;
    4'h3:    dbg_data_r <= ctx_data_r;
    4'h4:    dbg_data_r <= ctx_addr_r[7:0];
    4'h5:    dbg_data_r <= ctx_addr_r[15:8];
    4'h6:    dbg_data_r <= HLT_REQ;
    4'h7:    dbg_data_r <= HLT_RSP;

    default:  dbg_data_r <= 0;
  endcase
end

sgb snes_sgb (
  .RST(SNES_reset_strobe),
  .CPU_RST(SGB_reset),
  .CLK(CLK2),
  
  // MMIO interface
  .SNES_RD_start(SNES_RD_start),
  .SNES_WR_end(SNES_WR_end),
  .SNES_ADDR(SNES_ADDR),
  .DATA_IN(SGB_SNES_DATA_IN),
  .DATA_OUT(SGB_SNES_DATA_OUT),
  
  // ROM interface
  .ROM_BUS_RDY(SGB_ROM_RDY),
  .ROM_BUS_RRQ(SGB_ROM_RRQ),
  .ROM_BUS_WRQ(SGB_ROM_WRQ),
  .ROM_BUS_WORD(SGB_ROM_WORD),
  .ROM_BUS_ADDR(SGB_ROM_ADDR),
  .ROM_BUS_WRDATA(SGB_ROM_DATA),
  .ROM_BUS_RDDATA(SGB_ROM_DINr),
  .ROM_FREE_SLOT(SGB_FREE_SLOT),

  // Audio interface
  .APU_DAT(SGB_APU_DAT),
  .APU_CLK_EDGE(SGB_APU_CLK_EDGE),
  
  // RTC interface
  .RTC_DAT(SGB_RTC_DAT),
  .RTC_DAT_IN(MCU_RTC_DAT),
  .RTC_DAT_WE(MCU_RTC_WE),
  .RTC_DAT_RD(MCU_RTC_RD),
  
  // MBC interface
  .MAPPER(MAPPER),
  .SAVERAM_MASK(SAVERAM_MASK),
  .ROM_MASK(ROM_MASK),
  
  // Halt interface
  .HLT_REQ(HLT_REQ),
  .HLT_RSP(HLT_RSP),
  
  // State debug read interface
  .MCU_RRQ(MCU_SGB_RD_PENDr),
  .MCU_WRQ(MCU_SGB_WR_PENDr),
  .MCU_ADDR(SGB_ADDRr[18:0]),
  .MCU_DATA_IN(MCU_DOUT),
  .MCU_RSP(SGB_MCU_RSP),
  .MCU_DATA_OUT(SGB_MCU_DIN),

  // config
  .reg_group_in(reg_group),
  .reg_index_in(reg_index),
  .reg_value_in(reg_value),
  .reg_invmask_in(reg_invmask),
  .reg_we_in(reg_we),
  .reg_read_in(reg_read),
  .config_data_out(sgb_config_data),
  
  .DBG_ADDR(DBG_ADDR),
  .DBG_CHEAT_DATA_IN(DBG_CHEAT_DATA_OUT),
  .DBG_MAIN_DATA_IN(dbg_data_r),
  .DBG(DBG_SGB)
);

reg [7:0] MCU_DINr;
assign CTX_DINr = MCU_DINr;
reg [7:0] MCU_ROM_DINr;
reg [7:0] MCU_RAM_DINr;
wire [31:0] cheat_pgm_data;
wire [7:0] cheat_data_out;
wire [2:0] cheat_pgm_idx;

mcu_cmd snes_mcu_cmd(
  .clk(CLK2),
  .snes_sysclk(SNES_SYSCLK),
  .cmd_ready(spi_cmd_ready),
  .param_ready(spi_param_ready),
  .cmd_data(spi_cmd_data),
  .param_data(spi_param_data),
  .mcu_mapper(MAPPER),
  .mcu_write(MCU_WRITE),
  .mcu_data_in(MCU_DINr),
  .mcu_data_out(mcu_dout_int),
  .spi_byte_cnt(spi_byte_cnt),
  .spi_bit_cnt(spi_bit_cnt),
  .spi_data_out(spi_input_data),
  .addr_out(mcu_addr_int),
  .saveram_mask_out(SAVERAM_MASK),
  .rom_mask_out(ROM_MASK),
  .SD_DMA_EN(SD_DMA_EN),
  .SD_DMA_STATUS(SD_DMA_STATUS),
  .SD_DMA_NEXTADDR(SD_DMA_NEXTADDR),
  .SD_DMA_SRAM_DATA(SD_DMA_SRAM_DATA),
  .SD_DMA_SRAM_WE(SD_DMA_SRAM_WE),
  .SD_DMA_TGT(SD_DMA_TGT),
  .SD_DMA_PARTIAL(SD_DMA_PARTIAL),
  .SD_DMA_PARTIAL_START(SD_DMA_PARTIAL_START),
  .SD_DMA_PARTIAL_END(SD_DMA_PARTIAL_END),
  .SD_DMA_START_MID_BLOCK(SD_DMA_START_MID_BLOCK),
  .SD_DMA_END_MID_BLOCK(SD_DMA_END_MID_BLOCK),
  .dac_addr_out(dac_addr),
  .DAC_STATUS(DAC_STATUS),
  .dac_play_out(dac_play),
  .dac_reset_out(dac_reset),
  .dac_vol_select_out(dac_vol_select_out),
  .dac_palmode_out(dac_palmode_out),
  .dac_ptr_out(dac_ptr_addr),
  .msu_addr_out(msu_write_addr),
  .MSU_STATUS(msu_status_out),
  .msu_status_reset_out(msu_status_reset_bits),
  .msu_status_set_out(msu_status_set_bits),
  .msu_status_reset_we(msu_status_reset_we),
  .msu_volumerq(msu_volumerq_out),
  .msu_addressrq(msu_addressrq_out),
  .msu_trackrq(msu_trackrq_out),
  .msu_ptr_out(msu_ptr_addr),
  .msu_reset_out(msu_addr_reset),
  .rtc_data_in(SGB_RTC_DAT),
  .rtc_data_out(MCU_RTC_DAT),
  .rtc_pgm_we(MCU_RTC_WE),
  .rtc_pgm_rd(MCU_RTC_RD),
  // config
  .reg_group_out(reg_group),
  .reg_index_out(reg_index),
  .reg_value_out(reg_value),
  .reg_invmask_out(reg_invmask),
  .reg_we_out(reg_we),
  .reg_read_out(reg_read),
  // vv config data in vv
  .sgb_config_data_in(sgb_config_data),
  // ^^ config data in ^^
  .featurebits_out(featurebits),
  .mcu_rrq(mcu_rrq_int),
  .mcu_wrq(mcu_wrq_int),
  .mcu_rq_rdy(MCU_RDY),
  .region_out(mcu_region),
  .snescmd_addr_out(snescmd_addr_mcu),
  .snescmd_we_out(snescmd_we_mcu),
  .snescmd_data_out(snescmd_data_out_mcu),
  .snescmd_data_in(snescmd_data_in_mcu),
  .cheat_pgm_idx_out(cheat_pgm_idx),
  .cheat_pgm_data_out(cheat_pgm_data),
  .cheat_pgm_we_out(cheat_pgm_we),
  .dsp_feat_out(dsp_feat)
);

wire button_enable;
wire button_addr;

address snes_addr(
  .CLK(CLK2),
  //.MAPPER(MAPPER),
  .featurebits(featurebits),
  .SNES_ADDR(SNES_ADDR), // requested address from SNES
  .SNES_PA(SNES_PA),
  .SNES_ROMSEL(SNES_ROMSEL),
  .ROM_ADDR(MAPPED_SNES_ADDR),   // Address to request from SRAM (active low)
  .ROM_HIT(ROM_HIT),     // want to access RAM0
  .IS_SAVERAM(IS_SAVERAM),
  .IS_ROM(IS_ROM),
  .IS_WRITABLE(IS_WRITABLE),
  //.SAVERAM_MASK(SAVERAM_MASK),
  //.ROM_MASK(ROM_MASK),
  //MSU-1
  .msu_enable(msu_enable),
  .sgb_enable(sgb_enable),
  .r213f_enable(r213f_enable),
  .r2100_hit(r2100_hit),
  .snescmd_enable(snescmd_enable),
  .button_enable(button_enable),
  .button_addr(button_addr)
);

reg pad_latch = 0;
reg [4:0] pad_cnt = 0;

reg snes_ajr = 0;

wire        snescmd_we_cheat;
wire [8:0]  snescmd_addr_cheat;
wire [7:0]  snescmd_data_cheat;

cheat snes_cheat(
  .clk(CLK2),
  .SNES_ADDR(SNES_ADDR),
  .SNES_PA(SNES_PA),
  .SNES_DATA(SNES_DATA),
  .SNES_reset_strobe(SNES_reset_strobe),
  .SNES_wr_strobe(SNES_WR_end),
  .SNES_rd_strobe(SNES_RD_start),
  .snescmd_enable(snescmd_enable),
  .button_enable(button_enable),
  .button_addr(button_addr),
  .snescmd_rdy(ram_free_slot),
  .snescmd_we_cheat(snescmd_we_cheat),
  .snescmd_addr_cheat(snescmd_addr_cheat),
  .snescmd_data_cheat(snescmd_data_cheat),
  .button_ctx_valid(button_ctx_valid),
  .button_ctx_mode(button_ctx_mode),
  .DBG_ADDR(DBG_ADDR),
  .DBG_DATA_OUT(DBG_CHEAT_DATA_OUT),

  .pad_latch(pad_latch),
  .snes_ajr(snes_ajr),
  .SNES_cycle_start(SNES_cycle_start),
  .pgm_idx(cheat_pgm_idx),
  .pgm_we(cheat_pgm_we),
  .pgm_in(cheat_pgm_data),
  .data_out(cheat_data_out),
  .cheat_hit(cheat_hit),
  .snescmd_unlock(snescmd_unlock)
);

wire [7:0] snescmd_dout;

reg [7:0] r213fr;
reg r213f_forceread;
reg [2:0] r213f_delay;
reg [1:0] r213f_state;
initial r213fr = 8'h55;
initial r213f_forceread = 0;
initial r213f_state = 2'b01;
initial r213f_delay = 3'b000;

reg [7:0] r2100r = 0;
reg r2100_forcewrite = 0;
reg r2100_forcewrite_pre = 0;
wire [3:0] r2100_limit = featurebits[10:7];
wire [3:0] r2100_limited = (SNES_DATA[3:0] > r2100_limit) ? r2100_limit : SNES_DATA[3:0];
wire r2100_patch = featurebits[6];
wire r2100_enable = r2100_hit & (r2100_patch | ~(&r2100_limit));

wire snoop_4200_enable = {SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h04200;
wire r4016_enable = {SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h04016;

always @(posedge CLK2) begin
  r2100_forcewrite <= r2100_forcewrite_pre;
end

always @(posedge CLK2) begin
  if(SNES_WR_end & snoop_4200_enable) begin
    snes_ajr <= SNES_DATA[0];
  end
end

always @(posedge CLK2) begin
  if(SNES_WR_end & r4016_enable) begin
    pad_latch <= 1'b1;
    pad_cnt <= 5'h0;
  end
  if(SNES_RD_start & r4016_enable) begin
    pad_cnt <= pad_cnt + 1;
    if(&pad_cnt[3:0]) begin
      pad_latch <= 1'b0;
    end
  end
end

reg nmi_match; initial nmi_match = 0;
reg irq_match; initial irq_match = 0;

always @(posedge CLK2) nmi_match <= {SNES_ADDR[23:1],1'b0} == 24'h00FFEA;
always @(posedge CLK2) irq_match <= {SNES_ADDR[23:1],1'b0} == 24'h00FFEE;

assign SNES_DATA = (r213f_enable & ~SNES_PARD & ~r213f_forceread) ? r213fr
                   :(r2100_enable & ~SNES_PAWR & r2100_forcewrite) ? r2100r
                   :((~SNES_READ ^ (r213f_forceread & r213f_enable & ~SNES_PARD))
                                & ~(r2100_enable & ~SNES_PAWR & ~r2100_forcewrite & ~IS_ROM & ~IS_WRITABLE & ~sgb_enable))
                                ? ( msu_enable ? MSU_SNES_DATA_OUT
                                  : sgb_enable ? SGB_SNES_DATA_OUT  // SGB MMIO read
                                  : (cheat_hit & ~feat_cmd_unlock) ? cheat_data_out
                                  : ((snescmd_unlock | feat_cmd_unlock) & snescmd_enable) ? snescmd_dout
                                  : RAM_DATA // the RAM module holds up to a 512KB SNES ROM
                                  ) : 8'bZ;

reg [3:0] ST_MEM_DELAYr;

// MCU
reg MCU_RD_PENDr = 0;
reg MCU_WR_PENDr = 0;
reg [23:0] ROM_ADDRr;

reg RQ_MCU_RDYr;
initial RQ_MCU_RDYr = 1'b1;

wire MCU_WE_HIT = |(STATE & ST_MCU_WR_ADDR);
wire MCU_WR_HIT = |(STATE & (ST_MCU_WR_ADDR | ST_MCU_WR_END));
wire MCU_RD_HIT = |(STATE & (ST_MCU_RD_ADDR | ST_MCU_RD_END));
wire MCU_HIT = MCU_WR_HIT | MCU_RD_HIT;

// SGB ROM
reg SGB_ROM_RD_PENDr; initial SGB_ROM_RD_PENDr = 0;
reg SGB_ROM_WR_PENDr; initial SGB_ROM_WR_PENDr = 0;
reg [23:0] SGB_ROM_ADDRr;
reg [7:0]  SGB_ROM_DATAr;
reg        SGB_ROM_WORDr;

reg RQ_SGB_ROM_RDYr; initial RQ_SGB_ROM_RDYr = 1;
assign SGB_ROM_RDY = RQ_SGB_ROM_RDYr;

wire SGB_WE_HIT     = |(STATE & ST_SGB_ROM_WR_ADDR);
wire SGB_ROM_RD_HIT = |(STATE & (ST_SGB_ROM_RD_ADDR | ST_SGB_ROM_RD_END));
wire SGB_ROM_WR_HIT = |(STATE & (ST_SGB_ROM_WR_ADDR | ST_SGB_ROM_WR_END));
wire SGB_ROM_HIT    = SGB_ROM_RD_HIT | SGB_ROM_WR_HIT;

`ifdef MK2
my_dcm snes_dcm(
  .CLKIN(CLKIN),
  .CLKFX(CLK2),
  .LOCKED(DCM_LOCKED),
  .RST(DCM_RST)
);

assign ROM_ADDR  = (SD_DMA_TO_ROM) ? MCU_ADDR[23:1] : MCU_HIT ? ROM_ADDRr[23:1] : /*SGB_ROM_HIT ?*/ SGB_ROM_ADDRr[23:1];
assign ROM_ADDR0 = (SD_DMA_TO_ROM) ? MCU_ADDR[0]    : MCU_HIT ? ROM_ADDRr[0]    : /*SGB_ROM_HIT ?*/ SGB_ROM_ADDRr[0];

assign ROM_CE = 1'b0;

assign p113_out = 1'b0;

snescmd_buf snescmd (
  .clka(CLK2), // input clka
  .wea(snescmd_we_cheat | (SNES_WR_end & ((snescmd_unlock | feat_cmd_unlock) & snescmd_enable))), // input [0 : 0] wea
  .addra(snescmd_we_cheat ? snescmd_addr_cheat : SNES_ADDR[8:0]), // input [8 : 0] addra
  .dina(snescmd_we_cheat ? snescmd_data_cheat : SNES_DATA), // input [7 : 0] dina
  .douta(snescmd_dout), // output [7 : 0] douta
  .clkb(CLK2), // input clkb
  .web(snescmd_we_mcu), // input [0 : 0] web
  .addrb(snescmd_addr_mcu), // input [8 : 0] addrb
  .dinb(snescmd_data_out_mcu), // input [7 : 0] dinb
  .doutb(snescmd_data_in_mcu) // output [7 : 0] doutb
);
`endif

`ifdef MK3
pll snes_pll(
  .inclk0(CLKIN),
  .c0(CLK2),
  .locked(DCM_LOCKED),
  .areset(DCM_RST)
);

wire ROM_ADDR22;
assign ROM_ADDR22 = (SD_DMA_TO_ROM) ? MCU_ADDR[1]    : MCU_HIT ? ROM_ADDRr[1]    : SGB_ROM_ADDRr[1];
assign ROM_ADDR   = (SD_DMA_TO_ROM) ? MCU_ADDR[23:2] : MCU_HIT ? ROM_ADDRr[23:2] : SGB_ROM_ADDRr[23:2];
assign ROM_ADDR0  = (SD_DMA_TO_ROM) ? MCU_ADDR[0]    : MCU_HIT ? ROM_ADDRr[0]    : SGB_ROM_ADDRr[0];

assign ROM_ZZ = 1'b1;
assign ROM_1CE = ROM_ADDR22;
assign ROM_2CE = ~ROM_ADDR22;

snescmd_buf snescmd (
  .clock(CLK2), // input clka
  .wren_a(snescmd_we_cheat | (SNES_WR_end & ((snescmd_unlock | feat_cmd_unlock) & snescmd_enable))), // input [0 : 0] wea
  .address_a(snescmd_we_cheat ? snescmd_addr_cheat : SNES_ADDR[8:0]), // input [8 : 0] addra
  .data_a(snescmd_we_cheat ? snescmd_data_cheat : SNES_DATA), // input [7 : 0] dina
  .q_a(snescmd_dout), // output [7 : 0] douta
  .wren_b(snescmd_we_mcu), // input [0 : 0] web
  .address_b(snescmd_addr_mcu), // input [8 : 0] addrb
  .data_b(snescmd_data_out_mcu), // input [7 : 0] dinb
  .q_b(snescmd_data_in_mcu) // output [7 : 0] doutb
);
`endif

// OE always active. Overridden by WE when needed.
assign ROM_OE = 1'b0;

reg[17:0] SNES_DEAD_CNTr;
initial SNES_DEAD_CNTr = 0;

always @(posedge CLK2) begin
  if(MCU_RRQ & MCU_ROM) begin
    MCU_RD_PENDr <= 1'b1;
    RQ_MCU_RDYr <= 1'b0;
    ROM_ADDRr <= MCU_ADDR;
  end else if(MCU_WRQ & MCU_ROM) begin
    MCU_WR_PENDr <= 1'b1;
    RQ_MCU_RDYr <= 1'b0;
    ROM_ADDRr <= MCU_ADDR;
  end else if(STATE & (ST_MCU_RD_END | ST_MCU_WR_END)) begin
    MCU_RD_PENDr <= 1'b0;
    MCU_WR_PENDr <= 1'b0;
    RQ_MCU_RDYr <= 1'b1;
  end
end

always @(posedge CLK2) begin
  if(SGB_ROM_RRQ) begin
    SGB_ROM_RD_PENDr <= 1'b1;
    RQ_SGB_ROM_RDYr <= 1'b0;
    SGB_ROM_ADDRr <= SGB_ROM_ADDR;
    SGB_ROM_WORDr <= SGB_ROM_WORD;
  end else if(SGB_ROM_WRQ) begin
    SGB_ROM_WR_PENDr <= 1'b1;
    RQ_SGB_ROM_RDYr <= 1'b0;
    SGB_ROM_ADDRr <= SGB_ROM_ADDR;
    SGB_ROM_WORDr <= SGB_ROM_WORD;
    SGB_ROM_DATAr <= SGB_ROM_DATA;
  end else if(|(STATE & (ST_SGB_ROM_RD_ADDR)) & ~|ST_MEM_DELAYr) begin
    // enable rdy/response 1 cycle earlier
    RQ_SGB_ROM_RDYr <= 1'b1;
  end else if(STATE & (ST_SGB_ROM_RD_END | ST_SGB_ROM_WR_END)) begin
    SGB_ROM_RD_PENDr <= 1'b0;
    SGB_ROM_WR_PENDr <= 1'b0;
    RQ_SGB_ROM_RDYr <= 1'b1;
  end
end

always @(posedge CLK2) begin
  if(~SNES_CPU_CLKr[1]) SNES_DEAD_CNTr <= SNES_DEAD_CNTr + 1;
  else SNES_DEAD_CNTr <= 17'h0;
end

always @(posedge CLK2) begin
  SNES_reset_strobe <= 1'b0;
  if(SNES_CPU_CLKr[1]) begin
    SNES_DEADr <= 1'b0;
    if(SNES_DEADr) SNES_reset_strobe <= 1'b1;
  end
  else if(SNES_DEAD_CNTr > SNES_DEAD_TIMEOUT) SNES_DEADr <= 1'b1;
end

always @(posedge CLK2) begin
  if(SNES_DEADr & SNES_CPU_CLKr[1]) STATE <= ST_IDLE; // interrupt+restart an ongoing MCU access when the SNES comes alive
  else
  case(STATE)
    ST_IDLE: begin
      STATE <= ST_IDLE;
      
      if (SGB_ROM_RD_PENDr) begin
        STATE <= ST_SGB_ROM_RD_ADDR;
        ST_MEM_DELAYr <= ROM_CYCLE_LEN;
      end
      else if (SGB_ROM_WR_PENDr) begin
        STATE <= ST_SGB_ROM_WR_ADDR;
        ST_MEM_DELAYr <= ROM_CYCLE_LEN;
      end
      else if (free_slot | SNES_DEADr) begin
        if(MCU_RD_PENDr) begin
          STATE <= ST_MCU_RD_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end else if(MCU_WR_PENDr) begin
          STATE <= ST_MCU_WR_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
      end
    end
    ST_MCU_RD_ADDR: begin
      STATE <= ST_MCU_RD_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_MCU_RD_END;
      MCU_ROM_DINr <= (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8]);
    end
    ST_MCU_WR_ADDR: begin
      STATE <= ST_MCU_WR_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_MCU_WR_END;
    end
    ST_SGB_ROM_RD_ADDR: begin
      STATE <= ST_SGB_ROM_RD_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_SGB_ROM_RD_END;
      SGB_ROM_DINr <= (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8]);
    end
    ST_SGB_ROM_WR_ADDR: begin
      STATE <= ST_SGB_ROM_WR_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_SGB_ROM_WR_END;
    end
    ST_MCU_RD_END, ST_MCU_WR_END, ST_SGB_ROM_RD_END, ST_SGB_ROM_WR_END: begin
      STATE <= ST_IDLE;
    end
  endcase
end

always @(posedge CLK2) begin
  if(SNES_cycle_end) r213f_forceread <= 1'b1;
  else if(SNES_PARD_start & r213f_enable) begin
    r213f_delay <= 3'b001;
    r213f_state <= 2'b10;
  end else if(r213f_state == 2'b10) begin
    r213f_delay <= r213f_delay - 1;
    if(r213f_delay == 3'b000) begin
      r213f_forceread <= 1'b0;
      r213f_state <= 2'b01;
      r213fr <= {SNES_DATA[7:5], mcu_region, SNES_DATA[3:0]};
    end
  end
end

/*********************************
 * R2100 patching (experimental) *
 *********************************/
reg [3:0] r2100_bright = 0;
reg [3:0] r2100_bright_orig = 0;

always @(posedge CLK2) begin
  if(SNES_cycle_end) r2100_forcewrite_pre <= 1'b0;
  else if(SNES_PAWR_start & r2100_hit) begin
    if(r2100_patch & SNES_DATA[7]) begin
    // keep previous brightness during forced blanking so there is no DAC step
      r2100_forcewrite_pre <= 1'b1;
      r2100r <= {SNES_DATA[7], 3'b010, r2100_bright}; // 0xAx
    end else if (r2100_patch && SNES_DATA == 8'h00 && r2100r[7]) begin
    // extend forced blanking when game goes from blanking to brightness 0 (Star Fox top of screen)
      r2100_forcewrite_pre <= 1'b1;
      r2100r <= {1'b1, 3'b111, r2100_bright}; // 0xFx
    end else if (r2100_patch && SNES_DATA[3:0] < 4'h8 && r2100_bright_orig > 4'hd) begin
    // substitute big brightness changes with brightness 0 (so it is visible on 1CHIP)
      r2100_forcewrite_pre <= 1'b1;
      r2100r <= {SNES_DATA[7], 3'b011, 4'h0}; // 0x3x / 0xBx(!)
    end else if (r2100_patch | ~(&r2100_limit)) begin
    // save brightness, limit brightness
      r2100_bright <= r2100_limited;
      r2100_bright_orig <= SNES_DATA[3:0];
      if (~(&r2100_limit) && SNES_DATA[3:0] > r2100_limit) begin
        r2100_forcewrite_pre <= 1'b1;
        r2100r <= {SNES_DATA[7], 3'b100, r2100_limited}; // 0x4x / 0xCx
      end
    end
  end
end

reg MCU_WRITE_1;
always @(posedge CLK2) MCU_WRITE_1<= MCU_WRITE;

// odd addresses xxx1
assign ROM_DATA[7:0] = ROM_ADDR0
                       ?(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                       : SGB_ROM_WR_HIT ? SGB_ROM_DATAr
                                       : MCU_WR_HIT ? MCU_DOUT : 8'bZ
                        )
                       :8'bZ;

// even addresses xxx0
assign ROM_DATA[15:8] = ROM_ADDR0
                        ? 8'bZ
                        :(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                        : SGB_ROM_WR_HIT ? SGB_ROM_DATAr
                                        : MCU_WR_HIT ? MCU_DOUT
                                        : 8'bZ
                         );

assign ROM_WE = SD_DMA_TO_ROM
                ?MCU_WRITE
                : SGB_WE_HIT ? 1'b0
                : MCU_WE_HIT ? 1'b0
                : 1'b1;

assign ROM_BHE =  ROM_ADDR0 && !(!SD_DMA_TO_ROM && SGB_ROM_HIT && SGB_ROM_WORDr);
assign ROM_BLE = !ROM_ADDR0 && !(!SD_DMA_TO_ROM && SGB_ROM_HIT && SGB_ROM_WORDr);

//--------------
// RAM Pipeline
//--------------
parameter ST_RAM_IDLE            = 5'b00001;
parameter ST_RAM_MCU_RD_ADDR     = 5'b00010;
parameter ST_RAM_MCU_RD_END      = 5'b00100;
parameter ST_RAM_MCU_WR_ADDR     = 5'b01000;
parameter ST_RAM_MCU_WR_END      = 5'b10000;

parameter RAM_CYCLE_LEN = 4'd5;

reg [4:0] RAM_STATE; initial RAM_STATE = ST_RAM_IDLE;
reg [3:0] ST_RAM_DELAYr;

assign ram_free_slot = SNES_cycle_end | ram_free_strobe;

// Provide full bandwidth if snes is not accessing the bus.
always @(posedge CLK2) begin
  ram_free_strobe <= 1'b0;
  if (SNES_cycle_start) ram_free_strobe <= ~ROM_HIT;
end

// MCU state machine
reg MCU_RAM_RD_PENDr = 0;
reg MCU_RAM_WR_PENDr = 0;
reg [18:0] RAM_ADDRr;

reg RQ_RAM_MCU_RDYr;
initial RQ_RAM_MCU_RDYr = 1'b1;

wire MCU_RAM_WE_HIT = |(RAM_STATE & ST_RAM_MCU_WR_ADDR);
wire MCU_RAM_WR_HIT = |(RAM_STATE & (ST_RAM_MCU_WR_ADDR | ST_RAM_MCU_WR_END));
wire MCU_RAM_RD_HIT = |(RAM_STATE & (ST_RAM_MCU_RD_ADDR | ST_RAM_MCU_RD_END));
wire MCU_RAM_HIT = MCU_RAM_WR_HIT | MCU_RAM_RD_HIT;

always @(posedge CLK2) begin
  if(MCU_RRQ & MCU_RAM) begin
    MCU_RAM_RD_PENDr <= 1'b1;
    RQ_RAM_MCU_RDYr <= 1'b0;
    RAM_ADDRr <= MCU_ADDR;
  end else if(MCU_WRQ & MCU_RAM) begin
    MCU_RAM_WR_PENDr <= 1'b1;
    RQ_RAM_MCU_RDYr <= 1'b0;
    RAM_ADDRr <= MCU_ADDR;
  end else if(RAM_STATE & (ST_RAM_MCU_RD_END | ST_RAM_MCU_WR_END)) begin
    MCU_RAM_RD_PENDr <= 1'b0;
    MCU_RAM_WR_PENDr <= 1'b0;
    RQ_RAM_MCU_RDYr <= 1'b1;
  end
end

// RAM state machine
always @(posedge CLK2) begin
  if(SNES_DEADr & SNES_CPU_CLKr[1]) RAM_STATE <= ST_RAM_IDLE; // interrupt+restart an ongoing MCU access when the SNES comes alive
  else
  case(RAM_STATE)
    ST_RAM_IDLE: begin
      if(ram_free_slot | SNES_DEADr) begin
        if(MCU_RAM_RD_PENDr) begin
          RAM_STATE <= ST_RAM_MCU_RD_ADDR;
          ST_RAM_DELAYr <= RAM_CYCLE_LEN;
        end
        else if(MCU_RAM_WR_PENDr) begin
          RAM_STATE <= ST_RAM_MCU_WR_ADDR;
          ST_RAM_DELAYr <= RAM_CYCLE_LEN;
        end
      end
    end
    ST_RAM_MCU_RD_ADDR: begin
      ST_RAM_DELAYr <= ST_RAM_DELAYr - 1;
      if(ST_RAM_DELAYr == 0) RAM_STATE <= ST_RAM_MCU_RD_END;
      MCU_RAM_DINr <= RAM_DATA;
    end
    ST_RAM_MCU_WR_ADDR: begin
      ST_RAM_DELAYr <= ST_RAM_DELAYr - 1;
      if(ST_RAM_DELAYr == 0) RAM_STATE <= ST_RAM_MCU_WR_END;
    end
    ST_RAM_MCU_RD_END, ST_RAM_MCU_WR_END: begin
      RAM_STATE <= ST_RAM_IDLE;
    end
  endcase
end

assign RAM_ADDR = (SD_DMA_TO_RAM) ? MCU_ADDR[18:0] : MCU_RAM_HIT ? RAM_ADDRr[18:0] : MAPPED_SNES_ADDR[18:0];

assign RAM_DATA[7:0] = (SD_DMA_TO_RAM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                      : (ROM_HIT & ~SNES_WRITE) ? SNES_DATA
                                      : MCU_RAM_WR_HIT ? MCU_DOUT
                                      : 8'bZ
                       );

// NOTE: IS_SAVERAM should never assert
assign RAM_WE = (SD_DMA_TO_RAM ? MCU_WRITE 
                               : (ROM_HIT & IS_SAVERAM & SNES_CPU_CLK) ? SNES_WRITE
                               : MCU_RAM_WE_HIT ? 1'b0
                               : 1'b1
                );

assign RAM_OE = 1'b0;

always @(posedge CLK2) begin
  // flop data based on source
  if (STATE & ST_MCU_RD_END) begin
    MCU_DINr <= MCU_ROM_DINr;
  end
  else if (RAM_STATE & ST_RAM_MCU_RD_END) begin
    MCU_DINr <= MCU_RAM_DINr;
  end
  else if (MCU_SGB_RD_PENDr & SGB_MCU_RSP) begin
    MCU_DINr <= SGB_MCU_DIN;
  end
end

assign mcu_rdy_int = RQ_MCU_RDYr & RQ_RAM_MCU_RDYr & RQ_SGB_MCU_RDYr;

//--------------

assign SNES_DATABUS_OE = msu_enable & ~(SNES_READ & SNES_WRITE) ? 1'b0 :
                         // cover open bus to write-only registers (6000/6002 and 7XXX are the exceptions)
                         sgb_enable & (~SNES_WRITE | (SNES_ADDR[12] | ~|{SNES_ADDR[3:2],SNES_ADDR[0]})) ? 1'b0 :
                         snescmd_enable & ~(SNES_READ & SNES_WRITE) ? ~(snescmd_unlock | feat_cmd_unlock) :
                         (r213f_enable & ~SNES_PARD) ? 1'b0 :
                         (r2100_enable & ~SNES_PAWR) ? 1'b0 :
                         snoop_4200_enable & ~SNES_WRITE ? 1'b0 :
                         button_enable & ~SNES_WRITE ? 1'b0 :
                         ( (IS_ROM & SNES_ROMSEL)
                         | (!IS_ROM & !IS_SAVERAM & !IS_WRITABLE)
                         | (SNES_READ & SNES_WRITE)
                         );

/* data bus direction: 0 = SNES -> FPGA; 1 = FPGA -> SNES
 * data bus is always SNES -> FPGA to avoid fighting except when:
 *  a) the SNES wants to read
 *  b) we want to force a value on the bus
 */
assign SNES_DATABUS_DIR = (~SNES_READ | (~SNES_PARD & (r213f_enable)))
                           ? (1'b1 ^ (r213f_forceread & r213f_enable & ~SNES_PARD)
                                   ^ (r2100_enable & ~SNES_PAWR & ~r2100_forcewrite & ~IS_ROM & ~IS_WRITABLE & ~sgb_enable))
                           : ((~SNES_PAWR & r2100_enable) ? r2100_forcewrite
                             : 1'b0);

assign SNES_IRQ = 1'b0;

endmodule

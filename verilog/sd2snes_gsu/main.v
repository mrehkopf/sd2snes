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
module main(
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
  /* Bus 1: PSRAM, 128Mbit, 16bit, 70ns */
  inout [15:0] ROM_DATA,
  output [22:0] ROM_ADDR,
  output ROM_CE,
  output ROM_OE,
  output ROM_WE,
  output ROM_BHE,
  output ROM_BLE,

  /* Bus 2: SRAM, 4Mbit, 8bit, 45ns */
  inout [7:0] RAM_DATA,
  output [18:0] RAM_ADDR,
  //output RAM_CE,
  output RAM_OE,
  output RAM_WE,

  /* MCU signals */
  input SPI_MOSI,
  inout SPI_MISO,
  input SPI_SS,
  inout SPI_SCK,
  input MCU_OVR,
  output MCU_RDY,

  output DAC_MCLK,
  output DAC_LRCK,
  output DAC_SDOUT,

  /* SD signals */
  input [3:0] SD_DAT,
  inout SD_CMD,
  inout SD_CLK,

  /* debug */
  output p113_out
);

wire CLK2;

wire dspx_dp_enable;

wire [7:0] spi_cmd_data;
wire [7:0] spi_param_data;
wire [7:0] spi_input_data;
wire [31:0] spi_byte_cnt;
wire [2:0] spi_bit_cnt;
wire [23:0] MCU_ADDR;
wire [2:0] MAPPER;
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

wire [9:0] GSU_PGM_ADDR;
wire [7:0] GSU_PGM_DATA;

wire [7:0] GSU_SNES_DATA_IN;
wire [7:0] GSU_SNES_DATA_OUT;

//wire [14:0] bsx_regs;
//wire [7:0] BSX_SNES_DATA_IN;
//wire [7:0] BSX_SNES_DATA_OUT;
//wire [7:0] bsx_regs_reset_bits;
//wire [7:0] bsx_regs_set_bits;
//
//wire [59:0] rtc_data;
//wire [55:0] rtc_data_in;
//wire [59:0] srtc_rtc_data_out;
//wire [3:0] SRTC_SNES_DATA_IN;
//wire [7:0] SRTC_SNES_DATA_OUT;
//
//wire [7:0] DSPX_SNES_DATA_IN;
//wire [7:0] DSPX_SNES_DATA_OUT;
//
//wire [23:0] dspx_pgm_data;
//wire [10:0] dspx_pgm_addr;
//wire dspx_pgm_we;
//
//wire [15:0] dspx_dat_data;
//wire [10:0] dspx_dat_addr;
//wire dspx_dat_we;

wire [7:0] featurebits;

wire [23:0] MAPPED_SNES_ADDR;
wire ROM_ADDR0;

//wire [9:0] bs_page;
//wire [8:0] bs_page_offset;
//wire bs_page_enable;
//
//wire [4:0] DBG_srtc_state;
//wire DBG_srtc_we_rising;
//wire [3:0] DBG_srtc_ptr;
//wire [5:0] DBG_srtc_we_sreg;
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
wire [7:0] gsu_config_data;

reg [7:0] SNES_PARDr;
reg [7:0] SNES_READr;
reg [7:0] SNES_WRITEr;
reg [7:0] SNES_CPU_CLKr;
reg [7:0] SNES_ROMSELr;
reg [23:0] SNES_ADDRr [6:0];
reg [7:0] SNES_PAr [6:0];
reg [7:0] SNES_DATAr [4:0];

reg SNES_DEADr = 1;
reg SNES_reset_strobe = 0;

reg free_strobe = 0;
reg ram_free_strobe = 0;

wire SNES_PARD_start = ((SNES_PARDr[6:1] | SNES_PARDr[7:2]) == 6'b111110);
wire SNES_RD_start = ((SNES_READr[6:1] | SNES_READr[7:2]) == 6'b111100);
//wire SNES_RD_end = ((SNES_READr[6:1] & SNES_READr[7:2]) == 6'b000001);
//wire SNES_WR_end = ((SNES_WRITEr[6:1] & SNES_WRITEr[7:2]) == 6'b000001);
reg SNES_RD_end; always @(posedge CLK2) SNES_RD_end <= ((SNES_READr[5:0] & SNES_READr[6:1]) == 6'b000001);
reg SNES_WR_end; always @(posedge CLK2) SNES_WR_end <= ((SNES_WRITEr[5:0] & SNES_WRITEr[6:1]) == 6'b000001);
wire SNES_cycle_start = ((SNES_CPU_CLKr[7:2] & SNES_CPU_CLKr[6:1]) == 6'b000011);
wire SNES_cycle_end = ((SNES_CPU_CLKr[7:2] | SNES_CPU_CLKr[6:1]) == 6'b111000);
wire SNES_WRITE = SNES_WRITEr[2] & SNES_WRITEr[1];
wire SNES_READ = SNES_READr[2] & SNES_READr[1];
wire SNES_CPU_CLK = SNES_CPU_CLKr[2] & SNES_CPU_CLKr[1];
wire SNES_PARD = SNES_PARDr[2] & SNES_PARDr[1];

wire SNES_ROMSEL = (SNES_ROMSELr[5] & SNES_ROMSELr[4]);
wire [23:0] SNES_ADDR = (SNES_ADDRr[6] & SNES_ADDRr[5]);
wire [7:0] SNES_PA = (SNES_PAr[6] & SNES_PAr[5]);
wire [7:0] SNES_DATA_IN = (SNES_DATAr[3] & SNES_DATAr[2]);

reg [7:0] BUS_DATA;

always @(posedge CLK2) begin
  if(~SNES_READ) BUS_DATA <= SNES_DATA;
  else if(~SNES_WRITE) BUS_DATA <= SNES_DATA_IN;
end

wire free_slot = SNES_cycle_end | free_strobe;

wire ROM_HIT;

assign DCM_RST=0;

// gsu state
wire GSU_GO;
wire GSU_RON;
wire GSU_RAN;
wire IS_SAVERAM;

reg GSU_RONr;    initial GSU_RONr = 0;
reg GSU_RANr;    initial GSU_RANr = 0;

always @(posedge CLK2) begin
  // synchronize to the SNES cycle to avoid reading partial interrupt vector
  //if (SNES_WR_end | SNES_RD_end) begin
  if (SNES_cycle_end) begin
    GSU_RONr    <= GSU_RON & GSU_GO;
    GSU_RANr    <= GSU_RAN & GSU_GO;
  end
end

// Provide full bandwidth if snes is not accessing the bus.
always @(posedge CLK2) begin
  if(GSU_RONr) free_strobe <= 1;
  else if (SNES_cycle_start) free_strobe <= ~ROM_HIT | IS_SAVERAM;
  else free_strobe <= 1'b0;
end

always @(posedge CLK2) begin
  SNES_PARDr <= {SNES_PARDr[6:0], SNES_PARD_IN};
  SNES_READr <= {SNES_READr[6:0], SNES_READ_IN};
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

parameter ST_IDLE            = 11'b00000000001;
parameter ST_MCU_RD_ADDR     = 11'b00000000010;
parameter ST_MCU_RD_END      = 11'b00000000100;
parameter ST_MCU_WR_ADDR     = 11'b00000001000;
parameter ST_MCU_WR_END      = 11'b00000010000;
parameter ST_GSU_ROM_RD_ADDR = 11'b00000100000;
parameter ST_GSU_ROM_RD_END  = 11'b00001000000;
parameter ST_GSU_RAM_RD_ADDR = 11'b00010000000;
parameter ST_GSU_RAM_RD_END  = 11'b00100000000;
parameter ST_GSU_RAM_WR_ADDR = 11'b01000000000;
parameter ST_GSU_RAM_WR_END  = 11'b10000000000;

parameter SNES_DEAD_TIMEOUT = 17'd96000; // 1ms  // FIXME: this and some other constant times should be adjusted for new clock rate.

parameter ROM_CYCLE_LEN = 4'd7; // Increased from 6 due to tight timing on some sd2snes.  Two pics from boards with errors had a Micron chip with 0LA41/PW510.  Same build lot.

reg [10:0] STATE;
initial STATE = ST_IDLE;

//assign DSPX_SNES_DATA_IN = BUS_DATA;
//assign SRTC_SNES_DATA_IN = BUS_DATA[3:0];
assign MSU_SNES_DATA_IN = BUS_DATA;
assign GSU_SNES_DATA_IN = BUS_DATA;
//assign BSX_SNES_DATA_IN = BUS_DATA;

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

wire SD_DMA_TO_ROM = (SD_DMA_STATUS && (SD_DMA_TGT == 2'b00));

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
  .vol_latch(msu_volume_latch_out),
  .vol_select(dac_vol_select_out),
  .palmode(dac_palmode_out),
  .play(dac_play),
  .reset(dac_reset),
  .dac_address_ext(dac_ptr_addr)
);

//srtc snes_srtc (
//  .clkin(CLK2),
//  .addr_in(SNES_ADDR[0]),
//  .data_in(SRTC_SNES_DATA_IN),
//  .data_out(SRTC_SNES_DATA_OUT),
//  .rtc_data_in(rtc_data),
//  .enable(srtc_enable),
//  .rtc_data_out(srtc_rtc_data_out),
//  .reg_oe_falling(SNES_RD_start),
//  .reg_oe_rising(SNES_RD_end),
//  .reg_we_rising(SNES_WR_end),
//  .rtc_we(srtc_rtc_we),
//  .reset(srtc_reset),
//  .srtc_state(DBG_srtc_state),
//  .srtc_reg_we_rising(DBG_srtc_we_rising),
//  .srtc_rtc_ptr(DBG_srtc_ptr),
//  .srtc_we_sreg(DBG_srtc_we_sreg)
//);
//
//rtc snes_rtc (
//  .clkin(CLKIN),
//  .rtc_data(rtc_data),
//  .rtc_data_in(rtc_data_in),
//  .pgm_we(rtc_pgm_we),
//  .rtc_data_in1(srtc_rtc_data_out),
//  .we1(srtc_rtc_we)
//);

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

//bsx snes_bsx(
//  .clkin(CLK2),
//  .use_bsx(use_bsx),
//  .pgm_we(bsx_regs_reset_we),
//  .snes_addr(SNES_ADDR),
//  .reg_data_in(BSX_SNES_DATA_IN),
//  .reg_data_out(BSX_SNES_DATA_OUT),
//  .reg_oe_falling(SNES_RD_start),
//  .reg_oe_rising(SNES_RD_end),
//  .reg_we_rising(SNES_WR_end),
//  .regs_out(bsx_regs),
//  .reg_reset_bits(bsx_regs_reset_bits),
//  .reg_set_bits(bsx_regs_set_bits),
//  .data_ovr(bsx_data_ovr),
//  .flash_writable(IS_FLASHWR),
//  .rtc_data(rtc_data[59:0]),
//  .bs_page_out(bs_page), // support only page 0000-03ff
//  .bs_page_enable(bs_page_enable),
//  .bs_page_offset(bs_page_offset)
//
//);

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

// GSU ROM access
reg  [15:0] GSU_ROM_DINr;
wire [23:0] GSU_ROM_ADDR;
wire        GSU_ROM_WORD;

reg  [7:0]  GSU_RAM_DINr;
wire [18:0] GSU_RAM_ADDR;
wire [7:0]  GSU_RAM_DOUT;
wire        GSU_RAM_WORD;

// GSU (superfx)
gsu snes_gsu (
  .RST(SNES_reset_strobe),
  .CLK(CLK2),
  
  .SAVERAM_MASK(SAVERAM_MASK),
  .ROM_MASK(ROM_MASK),
  
  // MMIO interface
  .ENABLE(gsu_enable),
  .SNES_RD_start(SNES_RD_start),
  .SNES_WR_start(SNES_WR_start),
  .SNES_WR_end(SNES_WR_end),
  .SNES_ADDR(SNES_ADDR[9:0]),
  .DATA_IN(GSU_SNES_DATA_IN),
  .DATA_ENABLE(gsu_data_enable),
  .DATA_OUT(GSU_SNES_DATA_OUT),
  
  // ROM interface
  .ROM_BUS_RDY(GSU_ROM_RDY),
  .ROM_BUS_RRQ(GSU_ROM_RRQ),
  .ROM_BUS_WORD(GSU_ROM_WORD),
  .ROM_BUS_ADDR(GSU_ROM_ADDR),
  .ROM_BUS_RDDATA(GSU_ROM_DINr),

  // RAM interface
  .RAM_BUS_RDY(GSU_RAM_RDY),
  .RAM_BUS_RRQ(GSU_RAM_RRQ),
  .RAM_BUS_WRQ(GSU_RAM_WRQ),
  .RAM_BUS_WORD(GSU_RAM_WORD),
  .RAM_BUS_ADDR(GSU_RAM_ADDR),
  .RAM_BUS_RDDATA(GSU_RAM_DINr),
  .RAM_BUS_WRDATA(GSU_RAM_DOUT),
  
  // ACTIVE interface
  //.ACTIVE(GSU_ACTIVE),
  .IRQ(GSU_IRQ),
  .RON(GSU_RON),
  .RAN(GSU_RAN),
  .GO(GSU_GO),
  
  .SPEED(dsp_feat[0]),
  
  // State debug read interface
  .PGM_ADDR(GSU_PGM_ADDR), // [9:0]
  .PGM_DATA(GSU_PGM_DATA), // [7:0]

  // config
  .reg_group_in(reg_group),
  .reg_index_in(reg_index),
  .reg_value_in(reg_value),
  .reg_invmask_in(reg_invmask),
  .reg_we_in(reg_we),
  .reg_read_in(reg_read),
  .config_data_out(gsu_config_data),

  .DBG(DBG_GSU)
);

//
//upd77c25 snes_dspx (
//  .DI(DSPX_SNES_DATA_IN),
//  .DO(DSPX_SNES_DATA_OUT),
//  .A0(DSPX_A0),
//  .enable(dspx_enable),
//  .reg_oe_falling(SNES_RD_start),
//  .reg_oe_rising(SNES_RD_end),
//  .reg_we_rising(SNES_WR_end),
//  .RST(~dspx_reset),
//  .CLK(CLK2),
//  .PGM_WR(dspx_pgm_we),
//  .PGM_DI(dspx_pgm_data),
//  .PGM_WR_ADDR(dspx_pgm_addr),
//  .DAT_WR(dspx_dat_we),
//  .DAT_DI(dspx_dat_data),
//  .DAT_WR_ADDR(dspx_dat_addr),
//  .DP_enable(dspx_dp_enable),
//  .DP_ADDR(SNES_ADDR[10:0]),
//  .dsp_feat(dsp_feat)
//);

reg [7:0] MCU_DINr;
reg [7:0] MCU_ROM_DINr;
reg [7:0] MCU_RAM_DINr;
wire [7:0] MCU_DOUT;
wire [31:0] cheat_pgm_data;
wire [7:0] cheat_data_out;
wire [2:0] cheat_pgm_idx;

wire feat_cmd_unlock = featurebits[5];

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
  .mcu_data_out(MCU_DOUT),
  .spi_byte_cnt(spi_byte_cnt),
  .spi_bit_cnt(spi_bit_cnt),
  .spi_data_out(spi_input_data),
  .addr_out(MCU_ADDR),
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
  .gsu_addr_out(GSU_PGM_ADDR),
  .gsu_data(GSU_PGM_DATA),
//  .bsx_regs_set_out(bsx_regs_set_bits),
//  .bsx_regs_reset_out(bsx_regs_reset_bits),
//  .bsx_regs_reset_we(bsx_regs_reset_we),
//  .rtc_data_out(rtc_data_in),
//  .rtc_pgm_we(rtc_pgm_we),
//  .srtc_reset(srtc_reset),
//  .dspx_pgm_data_out(dspx_pgm_data),
//  .dspx_pgm_addr_out(dspx_pgm_addr),
//  .dspx_pgm_we_out(dspx_pgm_we),
//  .dspx_dat_data_out(dspx_dat_data),
//  .dspx_dat_addr_out(dspx_dat_addr),
//  .dspx_dat_we_out(dspx_dat_we),
//  .dspx_reset_out(dspx_reset),
  // config
  .reg_group_out(reg_group),
  .reg_index_out(reg_index),
  .reg_value_out(reg_value),
  .reg_invmask_out(reg_invmask),
  .reg_we_out(reg_we),
  .reg_read_out(reg_read),
  // vv config data in vv
  .gsu_config_data_in(gsu_config_data),
  // ^^ config data in ^^
  .featurebits_out(featurebits),
  .mcu_rrq(MCU_RRQ),
  .mcu_wrq(MCU_WRQ),
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

wire [7:0] DCM_STATUS;
// dcm1: dfs 4x
my_dcm snes_dcm(
  .CLKIN(CLKIN),
  .CLKFX(CLK2),
  .LOCKED(DCM_LOCKED),
  .RST(DCM_RST),
  .STATUS(DCM_STATUS)
);

address snes_addr(
  .CLK(CLK2),
  .MAPPER(MAPPER),
  .featurebits(featurebits),
  .SNES_ADDR(SNES_ADDR), // requested address from SNES
  .SNES_PA(SNES_PA),
  .SNES_ROMSEL(SNES_ROMSEL),
  .ROM_ADDR(MAPPED_SNES_ADDR),   // Address to request from SRAM (active low)
  .ROM_HIT(ROM_HIT),     // want to access RAM0
  .IS_SAVERAM(IS_SAVERAM),
  .IS_ROM(IS_ROM),
  .IS_WRITABLE(IS_WRITABLE),
  .SAVERAM_MASK(SAVERAM_MASK),
  .ROM_MASK(ROM_MASK),
  //MSU-1
  .msu_enable(msu_enable),
//  //BS-X
//  .use_bsx(use_bsx),
//  .bsx_regs(bsx_regs),
//  .bs_page_offset(bs_page_offset),
//  .bs_page(bs_page),
//  .bs_page_enable(bs_page_enable),
//  .bsx_tristate(bsx_tristate),
//  //SRTC
//  .srtc_enable(srtc_enable),
//  //uPD77C25
//  .dspx_enable(dspx_enable),
//  .dspx_dp_enable(dspx_dp_enable),
//  .dspx_a0(DSPX_A0),
  //GSU
  .gsu_enable(gsu_enable),
  .r213f_enable(r213f_enable),
  .snescmd_enable(snescmd_enable),
  .nmicmd_enable(nmicmd_enable),
  .return_vector_enable(return_vector_enable),
  .branch1_enable(branch1_enable),
  .branch2_enable(branch2_enable)
);

reg pad_latch = 0;
reg [4:0] pad_cnt = 0;

reg snes_ajr = 0;

cheat snes_cheat(
  .clk(CLK2),
  .SNES_ADDR(SNES_ADDR),
  .SNES_PA(SNES_PA),
  .SNES_DATA(SNES_DATA),
  .SNES_reset_strobe(SNES_reset_strobe),
  .SNES_wr_strobe(SNES_WR_end),
  .SNES_rd_strobe(SNES_RD_start),
  .snescmd_enable(snescmd_enable),
  .nmicmd_enable(nmicmd_enable),
  .return_vector_enable(return_vector_enable),
  .branch1_enable(branch1_enable),
  .branch2_enable(branch2_enable),
  .pad_latch(pad_latch),
  .snes_ajr(snes_ajr),
  .SNES_cycle_start(SNES_cycle_start),
  .pgm_idx(cheat_pgm_idx),
  .pgm_we(cheat_pgm_we),
  .pgm_in(cheat_pgm_data),
  .gsu_vec_enable(ROM_HIT & ~IS_SAVERAM & GSU_RONr),
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

wire snoop_4200_enable = {SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h04200;
wire r4016_enable = {SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h04016;

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

assign SNES_DATA = (r213f_enable & ~SNES_PARD & ~r213f_forceread) ? r213fr
                   :(~SNES_READ ^ (r213f_forceread & r213f_enable & ~SNES_PARD))
                                ? ( msu_enable ? MSU_SNES_DATA_OUT
                                  : gsu_data_enable ? GSU_SNES_DATA_OUT  // GSU MMIO read
                                  : (cheat_hit & ~feat_cmd_unlock) ? cheat_data_out
                                  : ((snescmd_unlock | feat_cmd_unlock) & snescmd_enable) ? snescmd_dout
                                  : (ROM_HIT & IS_SAVERAM) ? RAM_DATA
                                  : (ROM_HIT & ~IS_SAVERAM & GSU_RONr) ? (SNES_ADDR[0] ? 8'h01 : {4'h0, (SNES_ADDR[3] & SNES_ADDR[1]), (SNES_ADDR[2] & ~^{SNES_ADDR[3],SNES_ADDR[1]}), 1'b0, SNES_ADDR[0]}) // used for interrupt vectors
                                  : (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8])
                                  ) : 8'bZ;

reg [3:0] ST_MEM_DELAYr;

// MCU
reg MCU_RD_PENDr = 0;
reg MCU_WR_PENDr = 0;
reg [23:0] ROM_ADDRr;

reg RQ_MCU_RDYr;
initial RQ_MCU_RDYr = 1'b1;

wire MCU_WR_HIT = |(STATE & ST_MCU_WR_ADDR);
wire MCU_RD_HIT = |(STATE & ST_MCU_RD_ADDR);
wire MCU_HIT = MCU_WR_HIT | MCU_RD_HIT;

// GSU ROM
reg GSU_ROM_RD_PENDr; initial GSU_ROM_RD_PENDr = 0;
reg GSU_ROM_WR_PENDr; initial GSU_ROM_WR_PENDr = 0;
reg [23:0] GSU_ROM_ADDRr;
reg [15:0] GSU_ROM_DATAr;
reg        GSU_ROM_WORDr;

reg RQ_GSU_ROM_RDYr; initial RQ_GSU_ROM_RDYr = 1;
assign GSU_ROM_RDY = RQ_GSU_ROM_RDYr;

wire GSU_ROM_HIT = |(STATE & ST_GSU_ROM_RD_ADDR);

assign ROM_ADDR  = (SD_DMA_TO_ROM) ? MCU_ADDR[23:1] : GSU_ROM_HIT ? GSU_ROM_ADDRr[23:1] /*: GSU_RAM_HIT ? GSU_RAM_ADDRr[23:1]*/ : MCU_HIT ? ROM_ADDRr[23:1] : MAPPED_SNES_ADDR[23:1];
assign ROM_ADDR0 = (SD_DMA_TO_ROM) ? MCU_ADDR[0]    : GSU_ROM_HIT ? GSU_ROM_ADDRr[0]    /*: GSU_RAM_HIT ? GSU_RAM_ADDRr[0]   */ : MCU_HIT ? ROM_ADDRr[0]    : MAPPED_SNES_ADDR[0];

reg[17:0] SNES_DEAD_CNTr;
initial SNES_DEAD_CNTr = 0;

reg ROM_ADDR0_r;
always @(posedge CLK2) ROM_ADDR0_r <= ROM_ADDR0;

always @(posedge CLK2) begin
  if(MCU_RRQ && MCU_ADDR[23:19] != 5'b11100) begin
    MCU_RD_PENDr <= 1'b1;
    RQ_MCU_RDYr <= 1'b0;
    ROM_ADDRr <= MCU_ADDR;
  end else if(MCU_WRQ && MCU_ADDR[23:19] != 5'b11100) begin
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
//  if (SNES_reset_strobe) begin
//    GSU_ROM_RD_PENDr <= 1'b0;
//    RQ_GSU_ROM_RDYr <= 1'b1;  
//  end
//  else
  if(GSU_ROM_RRQ) begin
    GSU_ROM_RD_PENDr <= 1'b1;
    RQ_GSU_ROM_RDYr <= 1'b0;
    GSU_ROM_ADDRr <= GSU_ROM_ADDR;
    GSU_ROM_WORDr <= GSU_ROM_WORD;
  end else if(STATE & ST_GSU_ROM_RD_END) begin
    GSU_ROM_RD_PENDr <= 1'b0;
    RQ_GSU_ROM_RDYr <= 1'b1;
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
      
      if(free_slot | SNES_DEADr) begin
        if (GSU_ROM_RD_PENDr) begin
          STATE <= ST_GSU_ROM_RD_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
//        else if (GSU_RAM_RD_PENDr) begin
//          STATE <= ST_GSU_RAM_RD_ADDR;
//          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
//        end
//        else if (GSU_RAM_WR_PENDr) begin
//          STATE <= ST_GSU_RAM_WR_ADDR;
//          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
//        end
        else if(MCU_RD_PENDr) begin
          STATE <= ST_MCU_RD_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
        else if(MCU_WR_PENDr) begin
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
    ST_GSU_ROM_RD_ADDR: begin
      STATE <= ST_GSU_ROM_RD_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_GSU_ROM_RD_END;
      GSU_ROM_DINr <= (ROM_ADDR0_r ? ROM_DATA[15:0] : {ROM_DATA[7:0],ROM_DATA[15:8]});
    end
//    ST_GSU_RAM_RD_ADDR: begin
//      STATE <= ST_GSU_RAM_RD_ADDR;
//      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
//      if(ST_MEM_DELAYr == 0) STATE <= ST_GSU_RAM_RD_END;
//      GSU_RAM_DINr <= (ROM_ADDR0_r ? ROM_DATA[15:0] : {ROM_DATA[7:0],ROM_DATA[15:8]});
//    end
//    ST_GSU_RAM_WR_ADDR: begin
//      STATE <= ST_GSU_RAM_WR_ADDR;
//      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
//      if(ST_MEM_DELAYr == 0) STATE <= ST_GSU_RAM_WR_END;
//    end
    ST_MCU_RD_END, ST_MCU_WR_END, ST_GSU_ROM_RD_END, ST_GSU_RAM_RD_END, ST_GSU_RAM_WR_END: begin
      STATE <= ST_IDLE;
    end
  endcase
end

always @(posedge CLK2) begin
  if(SNES_cycle_end) r213f_forceread <= 1'b1;
  else if(SNES_PARD_start & r213f_enable) begin
//    r213f_delay <= 3'b000;
//    r213f_state <= 2'b10;
//  end else if(r213f_state == 2'b10) begin
//    r213f_delay <= r213f_delay - 1;
//    if(r213f_delay == 3'b000) begin
      r213f_forceread <= 1'b0;
      r213f_state <= 2'b01;
      r213fr <= {SNES_DATA[7:5], mcu_region, SNES_DATA[3:0]};
//    end
  end
end

reg MCU_WRITE_1;
always @(posedge CLK2) MCU_WRITE_1<= MCU_WRITE;

// odd addresses xxx1
assign ROM_DATA[7:0] = (ROM_ADDR0)// || (!SD_DMA_TO_ROM && GSU_RAM_WR_HIT && GSU_RAM_WORDr))
                       ?(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                       //: GSU_RAM_WR_HIT ? (ROM_ADDR0 ? GSU_RAM_DATAr[7:0] : GSU_RAM_DATAr[15:8])
                                       : (ROM_HIT & ~IS_SAVERAM & ~SNES_WRITE & ~GSU_RONr) ? SNES_DATA
                                       : MCU_WR_HIT ? MCU_DOUT : 8'bZ
                        )
                       :8'bZ;

// even addresses xxx0
assign ROM_DATA[15:8] = (ROM_ADDR0)// && !(!SD_DMA_TO_ROM && GSU_RAM_WR_HIT && GSU_RAM_WORDr))
                        ? 8'bZ
                        :(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                        //: GSU_RAM_WR_HIT ? (ROM_ADDR0 ? GSU_RAM_DATAr[15:8] : GSU_RAM_DATAr[7:0])
                                        : (ROM_HIT & ~IS_SAVERAM & ~SNES_WRITE & ~GSU_RONr) ? SNES_DATA
                                        : MCU_WR_HIT ? MCU_DOUT
                                        : 8'bZ
                         );

assign ROM_WE = SD_DMA_TO_ROM
                ?MCU_WRITE
                //: GSU_RAM_WR_HIT ? 1'b0
                : (ROM_HIT & IS_WRITABLE & ~IS_SAVERAM & SNES_CPU_CLK & ~GSU_RONr) ? SNES_WRITE
                : MCU_WR_HIT ? 1'b0
                : 1'b1;

// OE always active. Overridden by WE when needed.
assign ROM_OE = 1'b0;

assign ROM_CE = 1'b0;

// force word enable for GSU
assign ROM_BHE =  ROM_ADDR0 && !(!SD_DMA_TO_ROM && GSU_ROM_HIT && GSU_ROM_WORDr);// && !(!SD_DMA_TO_ROM && GSU_RAM_HIT && GSU_RAM_WORDr);
assign ROM_BLE = !ROM_ADDR0 && !(!SD_DMA_TO_ROM && GSU_ROM_HIT && GSU_ROM_WORDr);// && !(!SD_DMA_TO_ROM && GSU_RAM_HIT && GSU_RAM_WORDr);

//--------------
// RAM Pipeline
//--------------
parameter ST_RAM_IDLE            = 9'b000000001;
parameter ST_RAM_MCU_RD_ADDR     = 9'b000000010;
parameter ST_RAM_MCU_RD_END      = 9'b000000100;
parameter ST_RAM_MCU_WR_ADDR     = 9'b000001000;
parameter ST_RAM_MCU_WR_END      = 9'b000010000;
parameter ST_RAM_GSU_RD_ADDR     = 9'b000100000;
parameter ST_RAM_GSU_RD_END      = 9'b001000000;
parameter ST_RAM_GSU_WR_ADDR     = 9'b010000000;
parameter ST_RAM_GSU_WR_END      = 9'b100000000;

parameter RAM_CYCLE_LEN = 4'd5;

reg [8:0] RAM_STATE; initial RAM_STATE = ST_RAM_IDLE;
reg [3:0] ST_RAM_DELAYr;

wire ram_free_slot = SNES_cycle_end | ram_free_strobe;

// Provide full bandwidth if snes is not accessing the bus.
always @(posedge CLK2) begin
  if(GSU_RANr) ram_free_strobe <= 1;
  else if (SNES_cycle_start) ram_free_strobe <= ~ROM_HIT | ~IS_SAVERAM;
  else ram_free_strobe <= 1'b0;
end

// MCU state machine
reg MCU_RAM_RD_PENDr = 0;
reg MCU_RAM_WR_PENDr = 0;
reg [18:0] RAM_ADDRr;

reg RQ_RAM_MCU_RDYr;
initial RQ_RAM_MCU_RDYr = 1'b1;

wire MCU_RAM_WR_HIT = |(RAM_STATE & ST_RAM_MCU_WR_ADDR);
wire MCU_RAM_RD_HIT = |(RAM_STATE & ST_RAM_MCU_RD_ADDR);
wire MCU_RAM_HIT = MCU_RAM_WR_HIT | MCU_RAM_RD_HIT;

always @(posedge CLK2) begin
  if(MCU_RRQ && MCU_ADDR[23:19] == 5'b11100) begin
    MCU_RAM_RD_PENDr <= 1'b1;
    RQ_RAM_MCU_RDYr <= 1'b0;
    RAM_ADDRr <= MCU_ADDR;
  end else if(MCU_WRQ && MCU_ADDR[23:19] == 5'b11100) begin
    MCU_RAM_WR_PENDr <= 1'b1;
    RQ_RAM_MCU_RDYr <= 1'b0;
    RAM_ADDRr <= MCU_ADDR;
  end else if(RAM_STATE & (ST_RAM_MCU_RD_END | ST_RAM_MCU_WR_END)) begin
    MCU_RAM_RD_PENDr <= 1'b0;
    MCU_RAM_WR_PENDr <= 1'b0;
    RQ_RAM_MCU_RDYr <= 1'b1;
  end
end

// GSU RAM
reg GSU_RAM_RD_PENDr; initial GSU_RAM_RD_PENDr = 0;
reg GSU_RAM_WR_PENDr; initial GSU_RAM_WR_PENDr = 0;
reg [18:0] GSU_RAM_ADDRr;
reg [7:0]  GSU_RAM_DATAr;
reg        GSU_RAM_WORDr;

reg RQ_GSU_RAM_RDYr; initial RQ_GSU_RAM_RDYr = 1;
assign GSU_RAM_RDY = RQ_GSU_RAM_RDYr;

wire GSU_RAM_WR_HIT = |(RAM_STATE & ST_RAM_GSU_WR_ADDR);
wire GSU_RAM_RD_HIT = |(RAM_STATE & ST_RAM_GSU_RD_ADDR);
wire GSU_RAM_HIT    = GSU_RAM_WR_HIT | GSU_RAM_RD_HIT;

always @(posedge CLK2) begin
  if(GSU_RAM_RRQ) begin
    GSU_RAM_RD_PENDr <= 1'b1;
    RQ_GSU_RAM_RDYr <= 1'b0;
    GSU_RAM_ADDRr <= GSU_RAM_ADDR;
    GSU_RAM_WORDr <= GSU_RAM_WORD;
  end else if(GSU_RAM_WRQ) begin
    GSU_RAM_WR_PENDr <= 1'b1;
    RQ_GSU_RAM_RDYr <= 1'b0;
    GSU_RAM_ADDRr <= GSU_RAM_ADDR;
    GSU_RAM_WORDr <= GSU_RAM_WORD;
    GSU_RAM_DATAr <= GSU_RAM_DOUT;
  end else if(RAM_STATE & (ST_RAM_GSU_RD_END | ST_RAM_GSU_WR_END)) begin
    GSU_RAM_RD_PENDr <= 1'b0;
    GSU_RAM_WR_PENDr <= 1'b0;
    RQ_GSU_RAM_RDYr <= 1'b1;
  end
end

// RAM state machine
always @(posedge CLK2) begin
  if(SNES_DEADr & SNES_CPU_CLKr[1]) RAM_STATE <= ST_RAM_IDLE; // interrupt+restart an ongoing MCU access when the SNES comes alive
  else
  case(RAM_STATE)
    ST_RAM_IDLE: begin      
      if(ram_free_slot | SNES_DEADr) begin
        if (GSU_RAM_RD_PENDr) begin
          RAM_STATE <= ST_RAM_GSU_RD_ADDR;
          ST_RAM_DELAYr <= RAM_CYCLE_LEN;
        end
        else if (GSU_RAM_WR_PENDr) begin
          RAM_STATE <= ST_RAM_GSU_WR_ADDR;
          ST_RAM_DELAYr <= RAM_CYCLE_LEN;
        end
        else if(MCU_RAM_RD_PENDr) begin
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
    ST_RAM_GSU_RD_ADDR: begin
      ST_RAM_DELAYr <= ST_RAM_DELAYr - 1;
      if(ST_RAM_DELAYr == 0) RAM_STATE <= ST_RAM_GSU_RD_END;
      GSU_RAM_DINr <= RAM_DATA;
    end
    ST_RAM_GSU_WR_ADDR: begin
      ST_RAM_DELAYr <= ST_RAM_DELAYr - 1;
      if(ST_RAM_DELAYr == 0) RAM_STATE <= ST_RAM_GSU_WR_END;
    end
    ST_RAM_MCU_RD_END, ST_RAM_MCU_WR_END, ST_RAM_GSU_RD_END, ST_RAM_GSU_WR_END: begin
      RAM_STATE <= ST_RAM_IDLE;
    end
  endcase
end

assign RAM_ADDR = GSU_RAM_HIT ? GSU_RAM_ADDRr[18:0] : MCU_RAM_HIT ? RAM_ADDRr[18:0] : MAPPED_SNES_ADDR[18:0];

assign RAM_DATA[7:0] = ( GSU_RAM_WR_HIT ? GSU_RAM_DATAr[7:0]
                       : (ROM_HIT & IS_SAVERAM & ~SNES_WRITE & ~GSU_RANr) ? SNES_DATA
                       : MCU_RAM_WR_HIT ? MCU_DOUT
                       : 8'bZ
                       );

assign RAM_WE = ( GSU_RAM_WR_HIT ? 1'b0
                : (ROM_HIT & IS_SAVERAM & SNES_CPU_CLK & ~GSU_RANr) ? SNES_WRITE
                : MCU_RAM_WR_HIT ? 1'b0
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
end

assign MCU_RDY = RQ_MCU_RDYr & RQ_RAM_MCU_RDYr;

//--------------

assign SNES_DATABUS_OE = msu_enable ? 1'b0 :
                         gsu_enable ? 1'b0 :
                         snescmd_enable ? (~(snescmd_unlock | feat_cmd_unlock) | (SNES_READ & SNES_WRITE)) :
                         r213f_enable & !SNES_PARD ? 1'b0 :
                         snoop_4200_enable ? SNES_WRITE :
                         ( (IS_ROM & SNES_ROMSEL)
                         | (!IS_ROM & !IS_SAVERAM & !IS_WRITABLE)
                         | (SNES_READ & SNES_WRITE)
                         );

assign SNES_DATABUS_DIR = (~SNES_READ | (~SNES_PARD & (r213f_enable)))
                           ? 1'b1 ^ (r213f_forceread & r213f_enable & ~SNES_PARD)
                           : 1'b0;

assign SNES_IRQ = GSU_IRQ;

assign p113_out = 1'b0;

snescmd_buf snescmd (
  .clka(CLK2), // input clka
  .wea(SNES_WR_end & ((snescmd_unlock | feat_cmd_unlock) & snescmd_enable)), // input [0 : 0] wea
  .addra(SNES_ADDR[8:0]), // input [8 : 0] addra
  .dina(SNES_DATA), // input [7 : 0] dina
  .douta(snescmd_dout), // output [7 : 0] douta
  .clkb(CLK2), // input clkb
  .web(snescmd_we_mcu), // input [0 : 0] web
  .addrb(snescmd_addr_mcu), // input [8 : 0] addrb
  .dinb(snescmd_data_out_mcu), // input [7 : 0] dinb
  .doutb(snescmd_data_in_mcu) // output [7 : 0] doutb
);

/*
wire [35:0] CONTROL0;

chipscope_icon icon (
    .CONTROL0(CONTROL0) // INOUT BUS [35:0]
);

chipscope_ila ila (
    .CONTROL(CONTROL0), // INOUT BUS [35:0]
    .CLK(CLK2), // IN
    .TRIG0(SNES_ADDR), // IN BUS [23:0]
    .TRIG1(SNES_DATA), // IN BUS [7:0]
    .TRIG2({SNES_READ, SNES_WRITE, SNES_CPU_CLK, SNES_cycle_start, SNES_cycle_end, SNES_DEADr, MCU_RRQ, MCU_WRQ, MCU_RDY, ROM_WEr, ROM_WE, ROM_DOUT_ENr, ROM_SA, DBG_mcu_nextaddr, SNES_DATABUS_DIR, SNES_DATABUS_OE}),   // IN BUS [15:0]
    .TRIG3({bsx_data_ovr, r213f_forceread, r213f_enable, SNES_PARD, spi_cmd_ready, spi_param_ready, spi_input_data, SD_DAT}), // IN BUS [17:0]
    .TRIG4(ROM_ADDRr), // IN BUS [23:0]
    .TRIG5(ROM_DATA), // IN BUS [15:0]
    .TRIG6(MCU_DINr), // IN BUS [7:0]
   .TRIG7(spi_byte_cnt[3:0])
);

/*
ila_srtc ila (
    .CONTROL(CONTROL0), // INOUT BUS [35:0]
    .CLK(CLK2), // IN
    .TRIG0(SD_DMA_DBG_cyclecnt), // IN BUS [23:0]
    .TRIG1(SD_DMA_SRAM_DATA), // IN BUS [7:0]
    .TRIG2({SPI_SCK, SPI_MOSI, SPI_MISO, spi_cmd_ready, SD_DMA_SRAM_WE, SD_DMA_EN, SD_CLK, SD_DAT, SD_DMA_NEXTADDR, SD_DMA_STATUS, 3'b000}),   // IN BUS [15:0]
    .TRIG3({spi_cmd_data, spi_param_data}), // IN BUS [17:0]
    .TRIG4(ROM_ADDRr), // IN BUS [23:0]
    .TRIG5(ROM_DATA), // IN BUS [15:0]
    .TRIG6(MCU_DINr), // IN BUS [7:0]
   .TRIG7(ST_MEM_DELAYr)
);
*/

endmodule

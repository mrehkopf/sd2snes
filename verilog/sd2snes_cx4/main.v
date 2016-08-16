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
  input SNES_CS,
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
  output RAM_CE,
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

wire [7:0] CX4_SNES_DATA_IN;
wire [7:0] CX4_SNES_DATA_OUT;

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

wire [23:0] MAPPED_SNES_ADDR;
wire ROM_ADDR0;

wire [23:0] cx4_datrom_data;
wire [9:0] cx4_datrom_addr;
wire cx4_datrom_we;

wire [8:0] snescmd_addr_mcu;
wire [7:0] snescmd_data_out_mcu;
wire [7:0] snescmd_data_in_mcu;

reg [7:0] SNES_PARDr;
reg [7:0] SNES_READr;
reg [7:0] SNES_WRITEr;
reg [7:0] SNES_CPU_CLKr;
reg [23:0] SNES_ADDRr [5:0];
reg [7:0] SNES_PAr [5:0];
reg [7:0] SNES_DATAr [4:0];

reg[17:0] SNES_DEAD_CNTr = 18'h00000;

reg SNES_DEADr = 1;
reg SNES_reset_strobe = 0;

reg free_strobe = 0;

wire SNES_PARD_start = ((SNES_PARDr[6:1] & SNES_PARDr[7:2]) == 6'b111110);
wire SNES_RD_start = ((SNES_READr[6:1] & SNES_READr[7:2]) == 6'b111110);
wire SNES_RD_end = ((SNES_READr[6:1] & SNES_READr[7:2]) == 6'b000001);
wire SNES_WR_end = ((SNES_WRITEr[6:1] & SNES_WRITEr[7:2]) == 6'b000001);
wire SNES_cycle_start = ((SNES_CPU_CLKr[4:1] & SNES_CPU_CLKr[5:2]) == 4'b0001);
wire SNES_cycle_end = ((SNES_CPU_CLKr[4:1] & SNES_CPU_CLKr[5:2]) == 4'b1110);
wire SNES_WRITE = SNES_WRITEr[2] & SNES_WRITEr[1];
wire SNES_READ = SNES_READr[2] & SNES_READr[1];
wire SNES_CPU_CLK = SNES_CPU_CLKr[2] & SNES_CPU_CLKr[1];
wire SNES_PARD = SNES_PARDr[2] & SNES_PARDr[1];

wire [23:0] SNES_ADDR = (SNES_ADDRr[5] & SNES_ADDRr[4]);
wire [7:0] SNES_PA = (SNES_PAr[5] & SNES_PAr[4]);
wire [7:0] SNES_DATA_IN = (SNES_DATAr[3] & SNES_DATAr[2]);

wire free_slot = SNES_cycle_end | free_strobe;

reg [7:0] BUS_DATA;

always @(posedge CLK2) begin
  if(~SNES_READ) BUS_DATA <= SNES_DATA;
  else if(~SNES_WRITE) BUS_DATA <= SNES_DATA_IN;
end

wire ROM_HIT;

assign DCM_RST=0;

always @(posedge CLK2) begin
  free_strobe <= 1'b0;
  if(SNES_cycle_start) free_strobe <= ~ROM_HIT;
end

always @(posedge CLK2) begin
  SNES_PARDr <= {SNES_PARDr[6:0], SNES_PARD_IN};
  SNES_READr <= {SNES_READr[6:0], SNES_READ_IN};
  SNES_WRITEr <= {SNES_WRITEr[6:0], SNES_WRITE_IN};
  SNES_CPU_CLKr <= {SNES_CPU_CLKr[6:0], SNES_CPU_CLK_IN};
  SNES_ADDRr[5] <= SNES_ADDRr[4];
  SNES_ADDRr[4] <= SNES_ADDRr[3];
  SNES_ADDRr[3] <= SNES_ADDRr[2];
  SNES_ADDRr[2] <= SNES_ADDRr[1];
  SNES_ADDRr[1] <= SNES_ADDRr[0];
  SNES_ADDRr[0] <= SNES_ADDR_IN;
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

parameter ST_IDLE         = 7'b0000001;
parameter ST_MCU_RD_ADDR  = 7'b0000010;
parameter ST_MCU_RD_END   = 7'b0000100;
parameter ST_MCU_WR_ADDR  = 7'b0001000;
parameter ST_MCU_WR_END   = 7'b0010000;
parameter ST_CX4_RD_ADDR  = 7'b0100000;
parameter ST_CX4_RD_END   = 7'b1000000;

parameter ROM_CYCLE_LEN = 4'd6;

parameter SNES_DEAD_TIMEOUT = 17'd80000; // 1ms

reg [6:0] STATE;
initial STATE = ST_IDLE;

assign MSU_SNES_DATA_IN = BUS_DATA;
assign CX4_SNES_DATA_IN = BUS_DATA;

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
  .SD_DMA_END_MID_BLOCK(SD_DMA_END_MID_BLOCK)
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
  .reset(dac_reset)
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
  .msu_address_ext_write(msu_addr_reset)
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

reg [7:0] MCU_DINr;
wire [7:0] MCU_DOUT;
wire [7:0] featurebits;
wire [31:0] cheat_pgm_data;
wire [7:0] cheat_data_out;
wire [2:0] cheat_pgm_idx;
wire [15:0] dsp_feat;

wire [7:0] snescmd_data_in_mcu_dbg;

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
//  .dac_volume_out(dac_volume),
//  .dac_volume_latch_out(dac_vol_latch),
  .dac_play_out(dac_play),
  .dac_reset_out(dac_reset),
  .dac_vol_select_out(dac_vol_select_out),
  .dac_palmode_out(dac_palmode_out),
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
  .mcu_rrq(MCU_RRQ),
  .mcu_wrq(MCU_WRQ),
  .mcu_rq_rdy(MCU_RDY),
  .featurebits_out(featurebits),
  .cx4_reset_out(cx4_reset),
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
  .SNES_ADDR(SNES_ADDR), // requested address from SNES
  .SNES_PA(SNES_PA),
  .ROM_ADDR(MAPPED_SNES_ADDR),   // Address to request from SRAM (active low)
  .ROM_HIT(ROM_HIT),
  .IS_SAVERAM(IS_SAVERAM),
  .IS_ROM(IS_ROM),
  .IS_WRITABLE(IS_WRITABLE),
  .SAVERAM_MASK(SAVERAM_MASK),
  .ROM_MASK(ROM_MASK),
  .featurebits(featurebits),
  //MSU-1
  .msu_enable(msu_enable),
  //CX4
  .cx4_enable(cx4_enable),
  .cx4_vect_enable(cx4_vect_enable),
  //region
  .r213f_enable(r213f_enable),
  //CMD Interface
  .snescmd_enable(snescmd_enable),
  .nmicmd_enable(nmicmd_enable),
  .return_vector_enable(return_vector_enable),
  .pad_latch_enable(pad_latch_enable)
);

assign DCM_RST=0;

//always @(posedge CLK2) begin
//  non_hit_cycle <= 1'b0;
//  if(SNES_cycle_start) non_hit_cycle <= ~ROM_HIT;
//end

reg [7:0] CX4_DINr;
wire [23:0] CX4_ADDR;
wire [2:0] cx4_busy;

cx4 snes_cx4 (
  .DI(CX4_SNES_DATA_IN),
  .DO(CX4_SNES_DATA_OUT),
  .ADDR(SNES_ADDR[12:0]),
  .CS(cx4_enable),
  .SNES_VECT_EN(cx4_vect_enable),
  .reg_we_rising(SNES_WR_end),
  .CLK(CLK2),
  .BUS_DI(CX4_DINr),
  .BUS_ADDR(CX4_ADDR),
  .BUS_RRQ(CX4_RRQ),
  .BUS_RDY(CX4_RDY),
  .cx4_active(cx4_active),
  .cx4_busy_out(cx4_busy),
  .speed(dsp_feat[0])
);

reg pad_latch = 0;
reg [4:0] pad_cnt = 0;

cheat snes_cheat(
  .clk(CLK2),
  .SNES_ADDR(SNES_ADDR),
  .SNES_PA(SNES_PA),
  .SNES_DATA(SNES_DATA),
  .SNES_reset_strobe(SNES_reset_strobe),
  .SNES_cycle_start(SNES_cycle_start),
  .SNES_wr_strobe(SNES_WR_end),
  .SNES_rd_strobe(SNES_RD_start),
  .snescmd_enable(snescmd_enable),
  .nmicmd_enable(nmicmd_enable),
  .return_vector_enable(return_vector_enable),
  .pad_latch_enable(pad_latch_enable),
  .pad_latch(pad_latch),
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

wire snoop_4200_enable = {SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h04200;
wire r4016_enable = {SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h04016;

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
                     ? (msu_enable ? MSU_SNES_DATA_OUT
                       :cx4_enable ? CX4_SNES_DATA_OUT
                       :(cx4_active & cx4_vect_enable) ? CX4_SNES_DATA_OUT
                       :(cheat_hit & ~feat_cmd_unlock) ? cheat_data_out
                       :(snescmd_unlock | feat_cmd_unlock) & snescmd_enable ? snescmd_dout
                       :(ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8])
                       ): 8'bZ;

reg [4:0] ST_MEM_DELAYr;
reg MCU_RD_PENDr = 0;
reg MCU_WR_PENDr = 0;
reg CX4_RD_PENDr = 0;
reg [23:0] ROM_ADDRr;
reg [23:0] CX4_ADDRr;

reg RQ_MCU_RDYr;
initial RQ_MCU_RDYr = 1'b1;
assign MCU_RDY = RQ_MCU_RDYr;

reg RQ_CX4_RDYr;
initial RQ_CX4_RDYr = 1'b1;
assign CX4_RDY = RQ_CX4_RDYr;

wire MCU_WR_HIT = |(STATE & ST_MCU_WR_ADDR);
wire MCU_RD_HIT = |(STATE & ST_MCU_RD_ADDR);
wire MCU_HIT = MCU_WR_HIT | MCU_RD_HIT;

wire CX4_HIT = |(STATE & ST_CX4_RD_ADDR);

assign ROM_ADDR  = (SD_DMA_TO_ROM) ? MCU_ADDR[23:1] : MCU_HIT ? ROM_ADDRr[23:1] : CX4_HIT ? CX4_ADDRr[23:1] : MAPPED_SNES_ADDR[23:1];
assign ROM_ADDR0 = (SD_DMA_TO_ROM) ? MCU_ADDR[0] : MCU_HIT ? ROM_ADDRr[0] : CX4_HIT ? CX4_ADDRr[0] : MAPPED_SNES_ADDR[0];

always @(posedge CLK2) begin
  if(cx4_active) begin
    if(CX4_RRQ) begin
      CX4_RD_PENDr <= 1'b1;
      RQ_CX4_RDYr <= 1'b0;
      CX4_ADDRr <= CX4_ADDR;
    end else if(STATE == ST_CX4_RD_END) begin
      CX4_RD_PENDr <= 1'b0;
      RQ_CX4_RDYr <= 1'b1;
    end
  end
end

always @(posedge CLK2) begin
  if(MCU_RRQ) begin
    MCU_RD_PENDr <= 1'b1;
    RQ_MCU_RDYr <= 1'b0;
    ROM_ADDRr <= MCU_ADDR;
  end else if(MCU_WRQ) begin
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
      if(cx4_active) begin
        if (CX4_RD_PENDr) begin
          STATE <= ST_CX4_RD_ADDR;
          ST_MEM_DELAYr <= 16;
        end
      end else if(free_slot | SNES_DEADr) begin
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
      MCU_DINr <= (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8]);
    end
    ST_MCU_WR_ADDR: begin
      STATE <= ST_MCU_WR_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_MCU_WR_END;
    end
    ST_MCU_RD_END, ST_MCU_WR_END: begin
      STATE <= ST_IDLE;
    end
    ST_CX4_RD_ADDR: begin
      STATE <= ST_CX4_RD_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_CX4_RD_END;
      CX4_DINr <= (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8]);
    end
    ST_CX4_RD_END: begin
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

assign ROM_DATA[7:0] = ROM_ADDR0
                       ?(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                        : (ROM_HIT & ~SNES_WRITE) ? SNES_DATA
                                        : MCU_WR_HIT ? MCU_DOUT : 8'bZ
                        )
                       :8'bZ;

assign ROM_DATA[15:8] = ROM_ADDR0 ? 8'bZ
                        :(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                        : (ROM_HIT & ~SNES_WRITE) ? SNES_DATA
                                        : MCU_WR_HIT ? MCU_DOUT
                                        : 8'bZ
                         );

assign ROM_WE = SD_DMA_TO_ROM
                ?MCU_WRITE
                : (ROM_HIT & IS_WRITABLE & SNES_CPU_CLK) ? SNES_WRITE
                : MCU_WR_HIT ? 1'b0
                : 1'b1;

// OE always active. Overridden by WE when needed.
assign ROM_OE = 1'b0;

assign ROM_CE = 1'b0;

assign ROM_BHE = ROM_ADDR0;
assign ROM_BLE = !ROM_ADDR0;

assign SNES_DATABUS_OE = msu_enable ? 1'b0 :
                         cx4_enable ? 1'b0 :
                         (cx4_active & cx4_vect_enable) ? 1'b0 :
                         r213f_enable & !SNES_PARD ? 1'b0 :
                         snoop_4200_enable ? SNES_WRITE :
                         snescmd_enable ? ((~(snescmd_unlock | feat_cmd_unlock) | SNES_READ) & SNES_WRITE) :
                         ((IS_ROM & SNES_CS)
                          |(!IS_ROM & !IS_SAVERAM & !IS_WRITABLE)
                          |(SNES_READ & SNES_WRITE)
                         );

assign SNES_DATABUS_DIR = (~SNES_READ | (~SNES_PARD & (r213f_enable)))
                           ? 1'b1 ^ (r213f_forceread & r213f_enable & ~SNES_PARD)
                           : 1'b0;

assign SNES_IRQ = 1'b0;

assign p113_out = 1'b0;

wire [8:0] snescmd_addra = snoop_4200_enable ? 9'h1fa : SNES_ADDR[8:0];

snescmd_buf snescmd (
  .clka(CLK2), // input clka
  .wea(SNES_WR_end & (((snescmd_unlock | feat_cmd_unlock) & snescmd_enable) | snoop_4200_enable)), // input [0 : 0] wea
  .addra(snescmd_addra), // input [8 : 0] addra
  .dina(snoop_4200_enable ? {SNES_DATA[0], 3'b000, SNES_DATA[7], 1'b0, SNES_DATA[5:4]} : SNES_DATA), // input [7 : 0] dina
  .douta(snescmd_dout), // output [7 : 0] douta
  .clkb(CLK2), // input clkb
  .web(snescmd_we_mcu), // input [0 : 0] web
  .addrb(snescmd_addr_mcu), // input [8 : 0] addrb
  .dinb(snescmd_data_out_mcu), // input [7 : 0] dinb
  .doutb(snescmd_data_in_mcu) // output [7 : 0] doutb
);

/*
wire [35:0] CONTROL0;

icon icon (
    .CONTROL0(CONTROL0) // INOUT BUS [35:0]
);

ila ila (
    .CONTROL(CONTROL0), // INOUT BUS [35:0]
    .CLK(CLK2), // IN
    .TRIG0(SNES_ADDR), // IN BUS [23:0]
    .TRIG1(SNES_DATA), // IN BUS [7:0]
    .TRIG2({SNES_READ, SNES_WRITE, SNES_CPU_CLK, SNES_cycle_start, SNES_cycle_end, SNES_DEADr, MCU_RRQ, MCU_WRQ, MCU_RDY, cx4_active, ROM_WE, ROM_DOUT_ENr, ROM_SA, CX4_RRQ, CX4_RDY, ROM_CA}), // IN BUS [15:0]
    .TRIG3(ROM_ADDRr), // IN BUS [23:0]
    .TRIG4(CX4_ADDRr), // IN BUS [23:0]
    .TRIG5(ROM_DATA), // IN BUS [15:0]
    .TRIG6(CX4_DINr), // IN BUS [7:0]
    .TRIG7(STATE) // IN BUS [21:0]
);*/
/*
ila ila (
    .CONTROL(CONTROL0), // INOUT BUS [35:0]
    .CLK(CLK2), // IN
    .TRIG0(SNES_ADDR), // IN BUS [23:0]
    .TRIG1(SNES_DATA), // IN BUS [7:0]
    .TRIG2({SNES_READ, SNES_WRITE, SNES_CPU_CLK, SNES_cycle_start, SNES_cycle_end, SNES_DEADr, MCU_RRQ, MCU_WRQ, MCU_RDY, ROM_WEr, ROM_WE, ROM_DOUT_ENr, ROM_SA, DBG_mcu_nextaddr, SNES_DATABUS_DIR, SNES_DATABUS_OE}),   // IN BUS [15:0]
    .TRIG3({bsx_data_ovr, SPI_SCK, SPI_MISO, SPI_MOSI, spi_cmd_ready, spi_param_ready, spi_input_data, SD_DAT}), // IN BUS [17:0]
    .TRIG4(ROM_ADDRr), // IN BUS [23:0]
    .TRIG5(ROM_DATA), // IN BUS [15:0]
    .TRIG6(MCU_DINr), // IN BUS [7:0]
   .TRIG7(spi_byte_cnt[3:0])
);
*/
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

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
  output RAM_OE,
  output RAM_WE,

  /* MCU signals */
  input SPI_MOSI,
  inout SPI_MISO,
  input SPI_SS,
  input SPI_SCK,
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

`define upper(i) (8*(i+1)-1)
`define lower(i) (8*(i+0)-0)

wire CLK2;

wire dspx_dp_enable;

wire [7:0] spi_cmd_data;
wire [7:0] spi_param_data;
wire [7:0] spi_input_data;
wire [31:0] spi_byte_cnt;
wire [2:0] spi_bit_cnt;
wire [23:0] MCU_ADDR;
wire [2:0] MAPPER;
wire [7:0] SAVERAM_BASE;
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
wire [7:0] DMA_SNES_DATA_IN;
wire [7:0] DMA_SNES_DATA_OUT;
wire [7:0] CTX_SNES_DATA_IN;

wire [14:0] bsx_regs;
wire [7:0] BSX_SNES_DATA_IN;
wire [7:0] BSX_SNES_DATA_OUT;
wire [7:0] bsx_regs_reset_bits;
wire [7:0] bsx_regs_set_bits;

wire [59:0] rtc_data;
wire [55:0] rtc_data_in;
wire [59:0] srtc_rtc_data_out;
wire [3:0] SRTC_SNES_DATA_IN;
wire [7:0] SRTC_SNES_DATA_OUT;

wire [7:0] DSPX_SNES_DATA_IN;
wire [7:0] DSPX_SNES_DATA_OUT;

wire [23:0] dspx_pgm_data;
wire [10:0] dspx_pgm_addr;
wire dspx_pgm_we;

wire [15:0] dspx_dat_data;
wire [10:0] dspx_dat_addr;
wire dspx_dat_we;

wire [15:0] featurebits;
wire feat_cmd_unlock = featurebits[5];
wire feat_bs_base_enable = featurebits[12];

wire r213f_enable;

wire [23:0] MAPPED_SNES_ADDR;
wire        ROM_ADDR0;
//reg [22:0] ROM_ADDR_PRE;
//reg        ROM_ADDR0_PRE;
//assign ROM_ADDR = ROM_ADDR_PRE;
//wire ROM_ADDR0 = ROM_ADDR0_PRE;

wire [9:0] bs_page;
wire [8:0] bs_page_offset;
wire bs_page_enable;

wire [4:0] DBG_srtc_state;
wire DBG_srtc_we_rising;
wire [3:0] DBG_srtc_ptr;
wire [5:0] DBG_srtc_we_sreg;
wire [13:0] DBG_msu_address;
wire DBG_msu_reg_oe_rising;
wire DBG_msu_reg_oe_falling;
wire DBG_msu_reg_we_rising;
wire [2:0] SD_DMA_DBG_clkcnt;
wire [10:0] SD_DMA_DBG_cyclecnt;

wire [9:0] snescmd_addr_mcu;
wire [7:0] snescmd_data_out_mcu;
wire [7:0] snescmd_data_in_mcu;

wire [7:0] reg_group;
wire [7:0] reg_index;
wire [7:0] reg_value;
wire [7:0] reg_invmask;
wire       reg_we;
wire [7:0] reg_read;
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
reg loop_enable = 0;
reg [7:0] loop_data = 8'h80; // BRA
// exe region
reg exe_present; initial exe_present = 0;
wire map_unlock;

reg map_Fx_rd_unlock_r; initial map_Fx_rd_unlock_r = 0;
reg map_Fx_wr_unlock_r; initial map_Fx_wr_unlock_r = 0;
reg map_Ex_rd_unlock_r; initial map_Ex_rd_unlock_r = 0;
reg map_Ex_wr_unlock_r; initial map_Ex_wr_unlock_r = 0;
reg map_snescmd_rd_unlock_r; initial map_snescmd_rd_unlock_r = 0;
reg map_snescmd_wr_unlock_r; initial map_snescmd_wr_unlock_r = 0;

reg SNES_SNOOPRD_DATA_OE;
reg SNES_SNOOPWR_DATA_OE;
reg SNES_SNOOPPAWR_DATA_OE;
reg SNES_SNOOPPARD_DATA_OE;

reg [3:0] SNES_SNOOPRD_count;
reg [3:0] SNES_SNOOPWR_count;
reg [3:0] SNES_SNOOPPAWR_count;
reg [3:0] SNES_SNOOPPARD_count;
reg [7:0] CTX_DINr;
reg       CTX_DIRr;

// early signals for snooping bus
wire SNES_PAWR_start_early = ((SNES_PAWRr[4:1] | SNES_PAWRr[5:2]) == 4'b1110);
wire SNES_RD_start_early = ((SNES_READr[6:1] | SNES_READr[7:2]) == 6'b111100);

wire [23:0] SNES_ADDR = (SNES_ADDRr[5] & SNES_ADDRr[4]);
wire [7:0] SNES_PA = (SNES_PAr[5] & SNES_PAr[4]);
wire [7:0] SNES_DATA_IN = (SNES_DATAr[3] & SNES_DATAr[2]);

reg  [23:0] SNES_ADDR_early; always @(posedge CLK2) SNES_ADDR_early <= (SNES_ADDRr[3] & SNES_ADDRr[2]);

wire SNES_PARD_start = (SNES_PARDr[6:1] == 6'b111110);
// Sample PAWR data earlier on CPU accesses, later on DMA accesses...
wire SNES_PAWR_start = (SNES_PAWRr[7:1] == (({SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h02100) ? 7'b1110000 : 7'b1000000));
wire SNES_PAWR_end = (SNES_PAWRr[6:1] == 6'b000001);
wire SNES_RD_start = (SNES_READr[6:1] == 6'b111110);
wire SNES_WR_start = (SNES_WRITEr[6:1] == 6'b111000);
wire SNES_RD_end = (SNES_READr[6:1] == 6'b000001);
wire SNES_WR_end = (SNES_WRITEr[6:1] == 6'b000001);
wire SNES_cycle_start = (SNES_CPU_CLKr[6:1] == 6'b000001);
wire SNES_cycle_end = (SNES_CPU_CLKr[6:1] == 6'b111110);
wire SNES_WRITE = SNES_WRITEr[2] & SNES_WRITEr[1];
wire SNES_READ = SNES_READr[2] & SNES_READr[1];
wire SNES_CPU_CLK = SNES_CPU_CLKr[2] & SNES_CPU_CLKr[1];
wire SNES_PARD = SNES_PARDr[2] & SNES_PARDr[1];
wire SNES_PAWR = SNES_PAWRr[2] & SNES_PAWRr[1];
wire SNES_ROMSEL_EARLY = (SNES_ROMSELr[2] & SNES_ROMSELr[1]);
wire SNES_WRITE_early = SNES_WRITEr[1] & SNES_WRITEr[0];

reg SNES_SNOOPPARD_end;
reg SNES_SNOOPPAWR_end;
reg SNES_SNOOPRD_end;
reg SNES_SNOOPWR_end;
always @(posedge CLK2) begin
  if (SNES_reset_strobe) begin
    SNES_SNOOPPARD_end <= 0;
    SNES_SNOOPPAWR_end <= 0;
    SNES_SNOOPRD_end <= 0;
    SNES_SNOOPWR_end <= 0;
  end
  else begin
    SNES_SNOOPPARD_end <= SNES_SNOOPPARD_count == 4;
    SNES_SNOOPPAWR_end <= SNES_SNOOPPAWR_count == 4;
    SNES_SNOOPRD_end <= SNES_SNOOPRD_count == 4;
    SNES_SNOOPWR_end <= SNES_SNOOPWR_count == 4;
  end
end
wire SNES_ROMSEL = (SNES_ROMSELr[5] & SNES_ROMSELr[4]);

//wire [23:0] SNES_ADDR = (SNES_ADDRr[6] & SNES_ADDRr[5]);
//wire [7:0] SNES_PA = (SNES_PAr[6] & SNES_PAr[5]);
//wire [7:0] SNES_DATA_IN = (SNES_DATAr[3] & SNES_DATAr[2]);
//wire [23:0] SNES_ADDR_EARLY = (SNES_ADDRr[5] & SNES_ADDRr[4]);

reg [7:0] BUS_DATA;

always @(posedge CLK2) begin
  if(~SNES_READ) BUS_DATA <= SNES_DATA;
  else if(~SNES_WRITE) BUS_DATA <= SNES_DATA_IN;
end

wire SD_DMA_TO_ROM;
wire free_slot = (SNES_cycle_end | free_strobe) & ~SD_DMA_TO_ROM;

wire ROM_HIT;

assign DCM_RST=0;

always @(posedge CLK2) begin
  free_strobe <= 1'b0;
  if(SNES_cycle_start) free_strobe <= (~ROM_HIT | loop_enable);
end

always @(posedge CLK2) begin
  SNES_PARDr <= {SNES_PARDr[6:0], SNES_PARD_IN};
  SNES_PAWRr <= {SNES_PAWRr[6:0], SNES_PAWR_IN};
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
  
  // count of write low
  if (SNES_reset_strobe | SNES_SNOOPPAWR_end) begin
    SNES_SNOOPPAWR_count <= 0;
    SNES_SNOOPPAWR_DATA_OE <= 0;
  end
  else if (SNES_PAWR_start_early) begin 
    SNES_SNOOPPAWR_count <= 1;
    SNES_SNOOPPAWR_DATA_OE <= 1;
  end
  else if (|SNES_SNOOPPAWR_count) begin
    SNES_SNOOPPAWR_count <= SNES_SNOOPPAWR_count + 1;
  end

  // count of write low
  if (SNES_reset_strobe | SNES_SNOOPPARD_end) begin
    SNES_SNOOPPARD_count <= 0;
    SNES_SNOOPPARD_DATA_OE <= 0;
  end
  // avoid triggering OE signals on 213f to avoid problem with region override
  else if (SNES_PARD_start & ~r213f_enable) begin 
    SNES_SNOOPPARD_count <= 1;
    SNES_SNOOPPARD_DATA_OE <= 1;
  end
  else if (|SNES_SNOOPPARD_count) begin
    SNES_SNOOPPARD_count <= SNES_SNOOPPARD_count + 1;
  end

  // count of write low
  if (SNES_reset_strobe | SNES_SNOOPWR_end) begin
    SNES_SNOOPWR_count <= 0;
    SNES_SNOOPWR_DATA_OE <= 0;
  end
  else if (SNES_WR_start) begin 
    SNES_SNOOPWR_count <= 1;
    SNES_SNOOPWR_DATA_OE <= 1;
  end
  else if (|SNES_SNOOPWR_count) begin
    SNES_SNOOPWR_count <= SNES_SNOOPWR_count + 1;
  end

  // count of write low
  if (SNES_reset_strobe | SNES_SNOOPRD_end) begin
    SNES_SNOOPRD_count <= 0;
    SNES_SNOOPRD_DATA_OE <= 0;
  end
  else if (SNES_RD_start_early) begin 
    SNES_SNOOPRD_count <= 1;
    SNES_SNOOPRD_DATA_OE <= 1;
  end
  else if (|SNES_SNOOPRD_count) begin
    SNES_SNOOPRD_count <= SNES_SNOOPRD_count + 1;
  end


end

parameter ST_IDLE        = 11'b00000000001;
parameter ST_MCU_RD_ADDR = 11'b00000000010;
parameter ST_MCU_RD_END  = 11'b00000000100;
parameter ST_MCU_WR_ADDR = 11'b00000001000;
parameter ST_MCU_WR_END  = 11'b00000010000;
parameter ST_CTX_WR_ADDR = 11'b00000100000;
parameter ST_CTX_WR_END  = 11'b00001000000;
parameter ST_DMA_RD_ADDR = 11'b00010000000;
parameter ST_DMA_RD_END  = 11'b00100000000;
parameter ST_DMA_WR_ADDR = 11'b01000000000;
parameter ST_DMA_WR_END  = 11'b10000000000;

parameter SNES_DEAD_TIMEOUT = 17'd96000; // 1ms

parameter ROM_CYCLE_LEN = 4'd7;

reg [10:0] STATE;
initial STATE = ST_IDLE;

assign DSPX_SNES_DATA_IN = BUS_DATA;
assign SRTC_SNES_DATA_IN = BUS_DATA[3:0];
assign MSU_SNES_DATA_IN = BUS_DATA;
assign DMA_SNES_DATA_IN = BUS_DATA;
assign BSX_SNES_DATA_IN = BUS_DATA;
assign CTX_SNES_DATA_IN = CTX_DIRr ? CTX_DINr : SNES_DATAr[0];

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

assign SD_DMA_TO_ROM = (SD_DMA_STATUS && (SD_DMA_TGT == 2'b00));

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

srtc snes_srtc (
  .clkin(CLK2),
  .addr_in(SNES_ADDR[0]),
  .data_in(SRTC_SNES_DATA_IN),
  .data_out(SRTC_SNES_DATA_OUT),
  .rtc_data_in(rtc_data),
  .enable(srtc_enable),
  .rtc_data_out(srtc_rtc_data_out),
  .reg_oe_falling(SNES_RD_start),
  .reg_oe_rising(SNES_RD_end),
  .reg_we_rising(SNES_WR_end),
  .rtc_we(srtc_rtc_we),
  .reset(srtc_reset),
  .srtc_state(DBG_srtc_state),
  .srtc_reg_we_rising(DBG_srtc_we_rising),
  .srtc_rtc_ptr(DBG_srtc_ptr),
  .srtc_we_sreg(DBG_srtc_we_sreg)
);

rtc snes_rtc (
  .clkin(CLKIN),
  .rtc_data(rtc_data),
  .rtc_data_in(rtc_data_in),
  .pgm_we(rtc_pgm_we),
  .rtc_data_in1(srtc_rtc_data_out),
  .we1(srtc_rtc_we)
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

wire [23:0] CTX_ADDR;
wire [15:0] CTX_DOUT;

ctx snes_ctx (
  .clkin(CLK2),
  .reset(SNES_reset_strobe),

  .SNES_ADDR(SNES_ADDR),
  .SNES_PA(SNES_PA),
  .SNES_RD_end_PRE(SNES_RD_end),
  .SNES_WR_end_PRE(SNES_SNOOPWR_end),
  .SNES_PARD_end_PRE(SNES_SNOOPPARD_end),
  .SNES_PAWR_end_PRE(SNES_SNOOPPAWR_end),
  .SNES_DATA_IN_PRE(CTX_SNES_DATA_IN), // needs to handle PA accesses, too

  //.OE_RD_ENABLE(ctx_rd_enable),
  .OE_WR_ENABLE(ctx_wr_enable),
  .OE_PAWR_ENABLE(ctx_pawr_enable),
  .OE_PARD_ENABLE(ctx_pard_enable),

  .BUS_WRQ(CTX_WRQ),
  .BUS_RDY(CTX_RDY),

  .snescmd_unlock(snescmd_unlock),

  .ROM_ADDR(CTX_ADDR),
  .ROM_DATA(CTX_DOUT),
  .ROM_WORD_ENABLE(CTX_WORD),
  
  .DBG(CTX_DBG)
);

wire [23:0] DMA_ADDR;
wire [15:0] DMA_DOUT;

reg [15:0] DMA_DINr;

dma snes_dma (
  .clkin(CLK2),
  .reset(SNES_reset_strobe),
  .enable(dma_enable),

  .reg_addr(SNES_ADDR[3:0]),
  .reg_data_in(DMA_SNES_DATA_IN),
  .reg_data_out(DMA_SNES_DATA_OUT),

  .reg_oe_falling(SNES_RD_start),
  .reg_we_rising(SNES_WR_end),
  
  .loop_enable(DMA_LOOP_ENABLE),
  
  .BUS_RDY(DMA_RDY),
  .BUS_RRQ(DMA_RRQ),
  .BUS_WRQ(DMA_WRQ),
  
  .ROM_ADDR(DMA_ADDR),
  .ROM_DATA_OUT(DMA_DOUT),
  .ROM_DATA_IN(DMA_DINr),
  .ROM_WORD_ENABLE(DMA_WORD)
);

bsx snes_bsx(
  .clkin(CLK2),
  .use_bsx(use_bsx),
  .pgm_we(bsx_regs_reset_we),
  .snes_addr_in(SNES_ADDR),
  .reg_data_in(BSX_SNES_DATA_IN),
  .reg_data_out(BSX_SNES_DATA_OUT),
  .reg_oe_falling(SNES_RD_start),
  .reg_oe_rising(SNES_RD_end),
  .reg_we_rising(SNES_WR_end),
  .regs_out(bsx_regs),
  .reg_reset_bits(bsx_regs_reset_bits),
  .reg_set_bits(bsx_regs_set_bits),
  .data_ovr(bsx_data_ovr),
  .flash_writable(IS_FLASHWR),
  .rtc_data_in(rtc_data[59:0]),
  .bs_page_out(bs_page), // support only page 0000-03ff
  .bs_page_enable(bs_page_enable),
  .bs_page_offset(bs_page_offset),
  .feat_bs_base_enable(feat_bs_base_enable)
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

wire [15:0] dsp_feat;
`ifndef DEBUG
upd77c25 snes_dspx (
  .DI(DSPX_SNES_DATA_IN),
  .DO(DSPX_SNES_DATA_OUT),
  .A0(DSPX_A0),
  .enable(dspx_enable),
  .reg_oe_falling(SNES_RD_start),
  .reg_oe_rising(SNES_RD_end),
  .reg_we_rising(SNES_WR_end),
  .RST(~dspx_reset),
  .CLK(CLK2),
  .PGM_WR(dspx_pgm_we),
  .PGM_DI(dspx_pgm_data),
  .PGM_WR_ADDR(dspx_pgm_addr),
  .DAT_WR(dspx_dat_we),
  .DAT_DI(dspx_dat_data),
  .DAT_WR_ADDR(dspx_dat_addr),
  .DP_enable(dspx_dp_enable),
  .DP_ADDR(SNES_ADDR[10:0]),
  .dsp_feat(dsp_feat)
);
`endif

reg [7:0] MCU_DINr;
wire [7:0] MCU_DOUT;
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
  .mcu_data_out(MCU_DOUT),
  .spi_byte_cnt(spi_byte_cnt),
  .spi_bit_cnt(spi_bit_cnt),
  .spi_data_out(spi_input_data),
  .addr_out(MCU_ADDR),
  .saveram_base_out(SAVERAM_BASE),
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
  .reg_group_out(reg_group),
  .reg_index_out(reg_index),
  .reg_value_out(reg_value),
  .reg_invmask_out(reg_invmask),
  .reg_we_out(reg_we),
  .reg_read_out(reg_read),
  //.trc_config_data_in(trc_config_data),
  .bsx_regs_set_out(bsx_regs_set_bits),
  .bsx_regs_reset_out(bsx_regs_reset_bits),
  .bsx_regs_reset_we(bsx_regs_reset_we),
  .rtc_data_out(rtc_data_in),
  .rtc_pgm_we(rtc_pgm_we),
  .srtc_reset(srtc_reset),
  .dspx_pgm_data_out(dspx_pgm_data),
  .dspx_pgm_addr_out(dspx_pgm_addr),
  .dspx_pgm_we_out(dspx_pgm_we),
  .dspx_dat_data_out(dspx_dat_data),
  .dspx_dat_addr_out(dspx_dat_addr),
  .dspx_dat_we_out(dspx_dat_we),
  .dspx_reset_out(dspx_reset),
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
  .SNES_ADDR_early(SNES_ADDR_early), // requested address from SNES
  .SNES_WRITE_early(SNES_WRITE_early),
  .SNES_PA(SNES_PA),
  .SNES_ROMSEL(SNES_ROMSEL),
  .ROM_ADDR(MAPPED_SNES_ADDR),   // Address to request from SRAM (active low)
  .ROM_HIT(ROM_HIT),     // want to access RAM0
  .IS_SAVERAM(IS_SAVERAM),
  .IS_ROM(IS_ROM),
  .IS_WRITABLE(IS_WRITABLE),
  .SAVERAM_BASE(SAVERAM_BASE),
  .SAVERAM_MASK(SAVERAM_MASK),
  .ROM_MASK(ROM_MASK),
  .map_unlock(map_unlock),
  .map_Ex_rd_unlock(map_Ex_rd_unlock_r),
  .map_Ex_wr_unlock(map_Ex_wr_unlock_r),
  .map_Fx_rd_unlock(map_Fx_rd_unlock_r),
  .map_Fx_wr_unlock(map_Fx_wr_unlock_r),
  //MSU-1
  .msu_enable(msu_enable),
  //DMA-1
  .dma_enable(dma_enable),
  //BS-X
  .use_bsx(use_bsx),
  .bsx_regs(bsx_regs),
  .bs_page_offset(bs_page_offset),
  .bs_page(bs_page),
  .bs_page_enable(bs_page_enable),
  .bsx_tristate(bsx_tristate),
  //SRTC
  .srtc_enable(srtc_enable),
  //uPD77C25
  .dspx_enable(dspx_enable),
  .dspx_dp_enable(dspx_dp_enable),
  .dspx_a0(DSPX_A0),
  .r213f_enable(r213f_enable),
  .r2100_hit(r2100_hit),
  .snescmd_enable(snescmd_enable),
  .nmicmd_enable(nmicmd_enable),
  .return_vector_enable(return_vector_enable),
  .branch1_enable(branch1_enable),
  .branch2_enable(branch2_enable),
  .exe_enable(exe_enable),
  .map_enable(map_enable)
);

// flop all snes_addr outputs

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
  .exe_present(exe_present),
  .pad_latch(pad_latch),
  .snes_ajr(snes_ajr),
  .SNES_cycle_start(SNES_cycle_start),
  .pgm_idx(cheat_pgm_idx),
  .pgm_we(cheat_pgm_we),
  .pgm_in(cheat_pgm_data),
  .feat_cmd_unlock_in(feat_cmd_unlock),
  .data_out(cheat_data_out),
  .cheat_hit(cheat_hit),
  .snescmd_unlock(snescmd_unlock),
  .map_unlock(map_unlock)
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

assign SNES_DATA = (r213f_enable & ~SNES_PARD & ~r213f_forceread) ? r213fr
                   :(r2100_enable & ~SNES_PAWR & r2100_forcewrite) ? r2100r
                   :(((~SNES_READ & ((~SNES_SNOOPPAWR_DATA_OE & ~SNES_SNOOPPARD_DATA_OE) | ~SNES_ROMSEL_EARLY)) ^ (r213f_forceread & r213f_enable & ~SNES_PARD))
                                & ~(r2100_enable & ~SNES_PAWR & ~r2100_forcewrite & ~IS_ROM & ~IS_WRITABLE)) // FIXME: will this work with snooping?
                                ? (srtc_enable ? SRTC_SNES_DATA_OUT
                                  :dspx_enable ? DSPX_SNES_DATA_OUT
                                  :dspx_dp_enable ? DSPX_SNES_DATA_OUT
                                  :msu_enable ? MSU_SNES_DATA_OUT
                                  :dma_enable ? DMA_SNES_DATA_OUT
                                  :bsx_data_ovr ? BSX_SNES_DATA_OUT
                                  :(cheat_hit & ~feat_cmd_unlock) ? cheat_data_out
                                  // put spinloop below cheat so we don't overwrite jmp target after NMI
                                  :loop_enable ? loop_data
                                  :((snescmd_unlock | feat_cmd_unlock | map_snescmd_rd_unlock_r) & snescmd_enable) ? snescmd_dout
                                  :(ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8])
                                  ) : 8'bZ;

reg [3:0] ST_MEM_DELAYr;
reg MCU_RD_PENDr = 0;
reg MCU_WR_PENDr = 0;
reg [23:0] ROM_ADDRr;

// CTX
reg CTX_WR_PENDr;
initial CTX_WR_PENDr = 0;
reg [23:0] CTX_ROM_ADDRr;
initial CTX_ROM_ADDRr = 24'h0;
reg [15:0] CTX_ROM_DATAr;
initial CTX_ROM_DATAr = 16'h0000;
reg CTX_ROM_WORDr;
initial CTX_ROM_WORDr = 1'b0;


// DMA
reg DMA_WR_PENDr;
initial DMA_WR_PENDr = 0;
reg DMA_RD_PENDr;
initial DMA_RD_PENDr = 0;
reg [23:0] DMA_ROM_ADDRr;
initial DMA_ROM_ADDRr = 24'h0;
reg [15:0] DMA_ROM_DATAr;
initial DMA_ROM_DATAr = 16'h0000;
reg DMA_ROM_WORDr;
initial DMA_ROM_WORDr = 1'b0;

reg RQ_MCU_RDYr;
initial RQ_MCU_RDYr = 1'b1;
assign MCU_RDY = RQ_MCU_RDYr;
// CTX
reg RQ_CTX_RDYr;
initial RQ_CTX_RDYr = 1'b1;
assign CTX_RDY = RQ_CTX_RDYr;
// DMA
reg RQ_DMA_RDYr;
initial RQ_DMA_RDYr = 1'b1;
assign DMA_RDY = RQ_DMA_RDYr;

wire MCU_WE_HIT = |(STATE & ST_MCU_WR_ADDR);
wire MCU_WR_HIT = |(STATE & (ST_MCU_WR_ADDR | ST_MCU_WR_END));
wire MCU_RD_HIT = |(STATE & (ST_MCU_RD_ADDR | ST_MCU_RD_END));
wire MCU_HIT = MCU_WR_HIT | MCU_RD_HIT;
// CTX
wire CTX_WE_HIT = |(STATE & ST_CTX_WR_ADDR);
wire CTX_WR_HIT = |(STATE & (ST_CTX_WR_ADDR | ST_CTX_WR_END));
wire CTX_HIT = CTX_WR_HIT;
// DMA
wire DMA_WE_HIT = |(STATE & ST_DMA_WR_ADDR);
wire DMA_WR_HIT = |(STATE & (ST_DMA_WR_ADDR | ST_DMA_WR_END));
wire DMA_RD_HIT = |(STATE & (ST_DMA_RD_ADDR | ST_DMA_RD_END));
wire DMA_HIT = DMA_WR_HIT | DMA_RD_HIT;

assign ROM_ADDR  = (SD_DMA_TO_ROM) ? MCU_ADDR[23:1] : CTX_HIT ? CTX_ROM_ADDRr[23:1] : DMA_HIT ? DMA_ROM_ADDRr[23:1] : MCU_HIT ? ROM_ADDRr[23:1] : MAPPED_SNES_ADDR[23:1];
assign ROM_ADDR0 = (SD_DMA_TO_ROM) ? MCU_ADDR[0] : CTX_HIT ? CTX_ROM_ADDRr[0] : DMA_HIT ? DMA_ROM_ADDRr[0] : MCU_HIT ? ROM_ADDRr[0] : MAPPED_SNES_ADDR[0];
//always @(posedge CLK2) ROM_ADDR_PRE <= (SD_DMA_TO_ROM) ? MCU_ADDR[23:1] : CTX_HIT ? CTX_ROM_ADDRr[23:1] : DMA_HIT ? DMA_ROM_ADDRr[23:1] : MCU_HIT ? ROM_ADDRr[23:1] : MAPPED_SNES_ADDR[23:1];
//always @(posedge CLK2) ROM_ADDR0_PRE <= (SD_DMA_TO_ROM) ? MCU_ADDR[0] : CTX_HIT ? CTX_ROM_ADDRr[0] : DMA_HIT ? DMA_ROM_ADDRr[0] : MCU_HIT ? ROM_ADDRr[0] : MAPPED_SNES_ADDR[0];

reg[17:0] SNES_DEAD_CNTr;
initial SNES_DEAD_CNTr = 0;

// context engine request
always @(posedge CLK2) begin
  if(CTX_WRQ) begin
    CTX_WR_PENDr <= 1'b1;
    RQ_CTX_RDYr <= 1'b0;
    CTX_ROM_ADDRr <= CTX_ADDR;
    CTX_ROM_DATAr <= CTX_DOUT;
    CTX_ROM_WORDr <= CTX_WORD;
  end 
  else if(STATE & ST_CTX_WR_END) begin
    CTX_WR_PENDr <= 1'b0;
    RQ_CTX_RDYr <= 1'b1;
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

// dma engine request
always @(posedge CLK2) begin
  if(DMA_RRQ) begin
    DMA_RD_PENDr <= 1'b1;
    RQ_DMA_RDYr <= 1'b0;
    DMA_ROM_ADDRr <= DMA_ADDR;
    DMA_ROM_WORDr <= DMA_WORD;
  end 
  else if(DMA_WRQ) begin
    DMA_WR_PENDr <= 1'b1;
    RQ_DMA_RDYr <= 1'b0;
    DMA_ROM_ADDRr <= DMA_ADDR;
    DMA_ROM_DATAr <= DMA_DOUT;
    DMA_ROM_WORDr <= DMA_WORD;
  end
  else if(STATE & (ST_DMA_RD_END | ST_DMA_WR_END)) begin
    DMA_RD_PENDr <= 1'b0;
    DMA_WR_PENDr <= 1'b0;
    RQ_DMA_RDYr <= 1'b1;
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
  CTX_DINr <= (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8]);
  CTX_DIRr <= SNES_DATABUS_DIR;
end

always @(posedge CLK2) begin
  if(SNES_DEADr & SNES_CPU_CLKr[1]) STATE <= ST_IDLE; // interrupt+restart an ongoing MCU access when the SNES comes alive
  else
  case(STATE)
    ST_IDLE: begin
      STATE <= ST_IDLE;
      if(free_slot | SNES_DEADr) begin
        if(CTX_WR_PENDr) begin
          STATE <= ST_CTX_WR_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
        else if(MCU_RD_PENDr) begin
          STATE <= ST_MCU_RD_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
        else if(MCU_WR_PENDr) begin
          STATE <= ST_MCU_WR_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
        else if(DMA_RD_PENDr) begin
          STATE <= ST_DMA_RD_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
        else if(DMA_WR_PENDr) begin
          STATE <= ST_DMA_WR_ADDR;
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
    ST_CTX_WR_ADDR: begin
      STATE <= ST_CTX_WR_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_CTX_WR_END;
    end
    ST_DMA_RD_ADDR: begin
      STATE <= ST_DMA_RD_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_DMA_RD_END;
      // FIXME: seems like the lower byte is the upper byte (BIG ENDIAN)?  Maybe a bug in the DMA addressing logic.
      DMA_DINr <= (ROM_ADDR0 ? ROM_DATA : {ROM_DATA[7:0],ROM_DATA[15:8]});
    end
    ST_DMA_WR_ADDR: begin
      STATE <= ST_DMA_WR_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_DMA_WR_END;
    end
    ST_MCU_RD_END, ST_MCU_WR_END, ST_CTX_WR_END, ST_DMA_RD_END, ST_DMA_WR_END: begin
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

assign ROM_DATA[7:0] = (ROM_ADDR0 || (!SD_DMA_TO_ROM && CTX_HIT && CTX_ROM_WORDr) || (!SD_DMA_TO_ROM && DMA_HIT && DMA_ROM_WORDr))
                       ?(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                       : CTX_WR_HIT ? CTX_ROM_DATAr[15:8]
                                       : DMA_WR_HIT ? DMA_ROM_DATAr[15:8]
                                       : (ROM_HIT & ~loop_enable & ~SNES_WRITE) ? SNES_DATA
                                       : MCU_WR_HIT ? MCU_DOUT : 8'bZ
                        )
                       :8'bZ;

assign ROM_DATA[15:8] = ROM_ADDR0 ? 8'bZ
                        :(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                        : CTX_WR_HIT ? CTX_ROM_DATAr[7:0]
                                        : DMA_WR_HIT ? DMA_ROM_DATAr[7:0]
                                        : (ROM_HIT & ~loop_enable & ~SNES_WRITE) ? SNES_DATA
                                        : MCU_WR_HIT ? MCU_DOUT
                                        : 8'bZ
                         );

assign ROM_WE = SD_DMA_TO_ROM
                ? MCU_WRITE
                : CTX_WE_HIT ? 1'b0
                : DMA_WE_HIT ? 1'b0
                : (ROM_HIT & ~loop_enable & (IS_WRITABLE | IS_FLASHWR) & SNES_CPU_CLK) ? SNES_WRITE
                : MCU_WE_HIT ? 1'b0
                : 1'b1;

// OE always active. Overridden by WE when needed.
assign ROM_OE = 1'b0;

assign ROM_CE = 1'b0;

assign ROM_BHE = ROM_ADDR0;
assign ROM_BLE = ~ROM_ADDR0 & ~(~SD_DMA_TO_ROM & CTX_HIT & CTX_ROM_WORDr) & ~(~SD_DMA_TO_ROM & DMA_HIT & DMA_ROM_WORDr);

reg ReadOrWrite_r; always @(posedge CLK2) ReadOrWrite_r <= ~(SNES_READr[1] & SNES_READr[0] & SNES_WRITEr[1] & SNES_WRITEr[0]);

assign SNES_DATABUS_OE = ((dspx_enable | dspx_dp_enable) & ReadOrWrite_r) ? 1'b0 :
                         (msu_enable & ReadOrWrite_r) ? 1'b0 :
                         (dma_enable & ReadOrWrite_r) ? 1'b0 :
                         (loop_enable & ~SNES_READ) ? 1'b0 :
                         (bsx_data_ovr & ReadOrWrite_r) ? 1'b0 :
                         (srtc_enable & ReadOrWrite_r) ? 1'b0 :
                         (snescmd_enable & ReadOrWrite_r) ? (~(snescmd_unlock | feat_cmd_unlock | map_snescmd_wr_unlock_r)) :
                         (bs_page_enable & SNES_READ) ? 1'b0 :
                         (r213f_enable & ~SNES_PARD) ? 1'b0 :
                         (r2100_enable & ~SNES_PAWR) ? 1'b0 :
                         (snoop_4200_enable & ~SNES_WRITE) ? 1'b0 :
                         (ctx_wr_enable & SNES_SNOOPWR_DATA_OE) ? 1'b0 :
                         (ctx_pawr_enable & SNES_SNOOPPAWR_DATA_OE)? 1'b0 :
                         (ctx_pard_enable & SNES_SNOOPPARD_DATA_OE)? 1'b0 :
                         ((IS_ROM & SNES_ROMSEL)
                          |(!IS_ROM & !IS_SAVERAM & !IS_WRITABLE & !IS_FLASHWR)
                          |(SNES_READ & SNES_WRITE)
                          | bsx_tristate
                         );

/* data bus direction: 0 = SNES -> FPGA; 1 = FPGA -> SNES
 * data bus is always SNES -> FPGA to avoid fighting except when:
 *  a) the SNES wants to read
 *  b) we want to force a value on the bus
 */
assign SNES_DATABUS_DIR = ((~SNES_READ & ((~SNES_SNOOPPAWR_DATA_OE & ~SNES_SNOOPPARD_DATA_OE) | ~SNES_ROMSEL_EARLY)) | (~SNES_PARD & (r213f_enable)))
                           ? (1'b1 ^ (r213f_forceread & r213f_enable & ~SNES_PARD)
                                   ^ (r2100_enable & ~SNES_PAWR & ~r2100_forcewrite & ~IS_ROM & ~IS_WRITABLE))
                           : ((~SNES_PAWR & r2100_enable) ? r2100_forcewrite
                           : 1'b0);

assign SNES_IRQ = 1'b0;

assign p113_out = 1'b0;

snescmd_buf snescmd (
  .clka(CLK2), // input clka
  .wea(SNES_WR_end & ((snescmd_unlock | feat_cmd_unlock | map_snescmd_wr_unlock_r) & snescmd_enable)), // input [0 : 0] wea
  .addra({~SNES_ADDR[9],SNES_ADDR[8:0]}), // input [9 : 0] addra
  .dina(SNES_DATA), // input [7 : 0] dina
  .douta(snescmd_dout), // output [7 : 0] douta
  .clkb(CLK2), // input clkb
  .web(snescmd_we_mcu), // input [0 : 0] web
  .addrb({~snescmd_addr_mcu[9],snescmd_addr_mcu[8:0]}), // input [9 : 0] addrb
  .dinb(snescmd_data_out_mcu), // input [7 : 0] dinb
  .doutb(snescmd_data_in_mcu) // output [7 : 0] doutb
);

reg snescmd_addr_exe_r; always @(posedge CLK2) snescmd_addr_exe_r <= {2'b11,snescmd_addr_mcu} == 12'hC00;
reg snescmd_addr_map_r; always @(posedge CLK2) snescmd_addr_map_r <= {2'b10,snescmd_addr_mcu} == 12'hBB2;

always @(posedge CLK2) begin 
  if      (SNES_WR_end & (snescmd_unlock | feat_cmd_unlock | map_snescmd_wr_unlock_r) & exe_enable) exe_present <= (SNES_DATA != 0) ? 1 : 0;
  // snescmd_addr_mcu is 10b.  $2C00 is inteleaved with $2A00 such that $2C00 comes first at 0
  else if (snescmd_we_mcu & snescmd_addr_exe_r)                                                     exe_present <= (snescmd_data_out_mcu != 0) ? 1 : 0;
  
  if      (SNES_WR_end & (snescmd_unlock | feat_cmd_unlock | map_snescmd_wr_unlock_r) & map_enable) {map_Fx_rd_unlock_r,map_Fx_wr_unlock_r,map_Ex_rd_unlock_r,map_Ex_wr_unlock_r,map_snescmd_rd_unlock_r,map_snescmd_wr_unlock_r} <= SNES_DATA;
  else if (snescmd_we_mcu & snescmd_addr_map_r)                                                     {map_Fx_rd_unlock_r,map_Fx_wr_unlock_r,map_Ex_rd_unlock_r,map_Ex_wr_unlock_r,map_snescmd_rd_unlock_r,map_snescmd_wr_unlock_r} <= snescmd_data_out_mcu;
end

// spin loop state machine
// This is used to put the SNES into a spin loop.  It replaces the current instruction fetch with a branch
// to itself.  Upon release it lets the SNES fetch.
// TODO: add this to a more general-purpose debug module
reg loop_state;
initial loop_state = 0;
parameter [`upper(2):0] loop_code = { 8'h80, 8'hFE }; // BRA $FE

always @(posedge CLK2) begin

  if (!loop_enable) begin
    loop_enable <= DMA_LOOP_ENABLE;
  end  
  else begin
    case (loop_state)
      0: begin
        if (SNES_RD_end) begin
          loop_state <= 1;
          loop_data <= loop_code[`upper(0):`lower(0)];
        end
      end
      1: begin
        if (SNES_RD_end) begin
          loop_state <= 0;
          loop_data <= loop_code[`upper(1):`lower(1)];
          loop_enable <= DMA_LOOP_ENABLE;
        end
      end
    endcase
  end
end

`ifdef DEBUG

wire [35:0] CONTROL;

wire [7:0] TRIG0w = {
  SNES_READ_IN,
  SNES_WRITE_IN,
  SNES_CPU_CLK_IN,
  SNES_READ,
  SNES_WRITE,
  SNES_CPU_CLK,
  SNES_DATABUS_OE,
  SNES_DATABUS_DIR
};

wire [31:0] TRIG1w = {
  SNES_ADDR_IN,
  SNES_DATA_IN
};

wire [40:0] TRIG2w = {
  SNES_ADDR,
  SNES_DATA,
  BUS_DATA
};

wire [3:0] TRIG3w = {
  SNES_cycle_start,
  SNES_RD_start,
  SNES_RD_end,
  SNES_WR_end
};

wire [25:0] TRIG4w = {
  ROM_WE,
  ROM_BHE,
  ROM_BLE,
  ROM_ADDR
};

reg [7:0] TRIG0;
reg [31:0] TRIG1;
reg [40:0] TRIG2;
reg [3:0] TRIG3;
reg [25:0] TRIG4;

always @(posedge CLK2) begin
	TRIG0 <= TRIG0w;
	TRIG1 <= TRIG1w;
	TRIG2 <= TRIG2w;
	TRIG3 <= TRIG3w;
	TRIG4 <= TRIG4w;
end

chipscope_icon snes_icon (
    .CONTROL0(CONTROL) // INOUT BUS [35:0]
);

chipscope_ila snes_ila (
    .CONTROL(CONTROL), // INOUT BUS [35:0]
    .CLK(CLK2), // IN
    .TRIG0(TRIG0), // IN BUS [7:0]
    .TRIG1(TRIG1), // IN BUS [31:0]
    .TRIG2(TRIG2), // IN BUS [39:0]
    .TRIG3(TRIG3), // IN BUS [3:0]
    .TRIG4(TRIG4) // IN BUS [25:0]
);
`endif

endmodule

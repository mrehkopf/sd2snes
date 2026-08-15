// `default_nettype none
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

// SA-1 savestate machinery gate; Mk.III only (see address.v).  Derived in each
// file that needs it: address.v, sa1.v, cheat.v, mcu_cmd.v.
`ifdef MK3
`define SA1_SS_ACTIVE
`elsif SA1_SS_MK2
`define SA1_SS_ACTIVE
`endif

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

wire [11:0] SA1_PGM_ADDR;
wire [7:0] SA1_PGM_DATA;

wire [7:0] SA1_SNES_DATA_IN;
wire [7:0] SA1_SNES_DATA_OUT;

wire [15:0] SA1_SNV;
wire [15:0] SA1_SIV;
wire [11:0] SA1_XXB;
wire [3:0]  SA1_XXB_EN;

wire [15:0] featurebits;
wire feat_cmd_unlock = featurebits[5];

wire [23:0] MAPPED_SNES_ADDR;
wire ROM_ADDR0;

// $2020-$202F copier reg window (address.v); declared before its consumers so XST
// does not build an implicit net.
wire dma_enable;

// Hook identity window, from address.v.
wire IS_PATCH;

// Savestate scan window (address.v); wins the SNES_DATA read mux.  0 on mk2.
wire sa1_ss_enable;
wire [7:0] SA1_SS_DATA_OUT;
wire [15:0] sa1_iram_pad;
// MCU-side halt request (mcu_cmd 0xfb).
wire sa1_ss_halt;

// Hook-side SA-1 pause, written through the $202C decode next to the copier.
reg snapshot_pause; initial snapshot_pause = 0;

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
wire [7:0] sa1_config_data;

reg [7:0] SNES_PARDr = 8'b11111111;
reg [7:0] SNES_PAWRr = 8'b11111111;
reg [7:0] SNES_READr = 8'b11111111;
reg [7:0] SNES_WRITEr = 8'b11111111;
reg [7:0] SNES_CPU_CLKr = 8'b00000000;
reg [7:0] SNES_ROMSELr = 8'b11111111;
reg [7:0] SNES_PULSEr = 8'b11111111;
reg [23:0] SNES_ADDRr [6:0];
reg [7:0] SNES_PAr [6:0];
reg [7:0] SNES_DATAr [4:0];

reg SNES_DEADr = 1;
reg SNES_reset_strobe = 0;

reg free_strobe = 0;
reg ram_free_strobe = 0;

wire [23:0] SNES_ADDR = SNES_ADDRr[0]; //(SNES_ADDRr[6] & SNES_ADDRr[5]);
//wire [23:0] SNES_ADDR_early = SNES_ADDRr[0];
wire [7:0] SNES_PA = SNES_PAr[0]; //(SNES_PAr[6] & SNES_PAr[5]);
wire [7:0] SNES_DATA_IN = (SNES_DATAr[3] & SNES_DATAr[2]);

wire SNES_PULSE_IN = SNES_READ_IN & SNES_WRITE_IN & ~SNES_CPU_CLK_IN;

wire SNES_PULSE_end = (SNES_PULSEr[6:1] == 6'b000001);
wire SNES_PARD_start = (SNES_PARDr[6:1] == 6'b111110);
wire SNES_PARD_end = (SNES_PARDr[6:1] == 6'b000001);
// Sample PAWR data earlier on CPU accesses, later on DMA accesses...
wire SNES_PAWR_start = (SNES_PAWRr[6:1] == (({SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h02100) ? 6'b111000 : 6'b100000));
wire SNES_PAWR_end = (SNES_PAWRr[6:1] == 6'b000001);
wire SNES_RD_start = (SNES_READr[6:1] == 6'b111110);
wire SNES_RD_end = (SNES_READr[6:1] == 6'b000001);
wire SNES_WR_start = (SNES_WRITEr[6:1] == 6'b111000);
wire SNES_WR_end = (SNES_WRITEr[6:1] == 6'b000001);
wire SNES_cycle_start = (SNES_CPU_CLKr[6:1] == 6'b000001);
wire SNES_cycle_end = (SNES_CPU_CLKr[6:1] == 6'b111110);
wire SNES_cycle_end_early = (SNES_CPU_CLKr[6:1] == 6'b111110);

wire SNES_WRITE = SNES_WRITEr[2] & SNES_WRITEr[1];
wire SNES_READ = SNES_READr[2] & SNES_READr[1];
wire SNES_READ_late = SNES_READr[5] & SNES_READr[4];
wire SNES_READ_narrow = SNES_READ | SNES_READ_late;
wire SNES_CPU_CLK = SNES_CPU_CLKr[2] & SNES_CPU_CLKr[1];
wire SNES_PARD = SNES_PARDr[2] & SNES_PARDr[1];
wire SNES_PAWR = SNES_PAWRr[2] & SNES_PAWRr[1];

wire SNES_ROMSEL = (SNES_ROMSELr[0]);

`ifdef SA1_SS_ACTIVE
// ---------------------------------------------------------------------------
// ctx bus-snoop plumbing, ported from sd2snes_base; Mk.III only.  The savestate
// handler reads the $21xx/$42xx register shadows out of the mirror (VRAM, CGRAM,
// OAM and WRAM it reads back from the hardware instead).
//
// The base samples the late, glitch-filtered SNES_ADDR/PA while this core runs off
// the early SNES_ADDRr[0], so the settled taps are rebuilt here: the 4-tick end
// strobes are calibrated against the late address.
wire [23:0] CTX_SNES_ADDR = (SNES_ADDRr[5] & SNES_ADDRr[4]);
wire [7:0]  CTX_SNES_PA   = (SNES_PAr[5] & SNES_PAr[4]);

// early snoop-arm strobe (control lines only, address/PA independent)
wire SNES_PAWR_start_early = ((SNES_PAWRr[4:1] | SNES_PAWRr[5:2]) == 4'b1110);

reg SNES_SNOOPWR_DATA_OE = 0;
reg SNES_SNOOPPAWR_DATA_OE = 0;
reg SNES_SNOOPPARD_DATA_OE = 0;
reg [3:0] SNES_SNOOPWR_count;
reg [3:0] SNES_SNOOPPAWR_count;
reg [3:0] SNES_SNOOPPARD_count;
reg SNES_SNOOPWR_end;
reg SNES_SNOOPPAWR_end;
reg SNES_SNOOPPARD_end;
reg [7:0] CTX_DINr;
reg       CTX_DIRr;
wire [15:0] ctx_pad1;          // JOY1 captured by ctx's CPUREG store-sniffing FSM
wire [7:0] CTX_SNES_DATA_IN = CTX_DIRr ? CTX_DINr : SNES_DATAr[0];

// 4-tick snoop end strobes, as in sd2snes_base.
always @(posedge CLK2) begin
  if (SNES_reset_strobe) begin
    SNES_SNOOPPARD_end <= 0;
    SNES_SNOOPPAWR_end <= 0;
    SNES_SNOOPWR_end <= 0;
  end
  else begin
    SNES_SNOOPPARD_end <= SNES_SNOOPPARD_count == 4;
    SNES_SNOOPPAWR_end <= SNES_SNOOPPAWR_count == 4;
    SNES_SNOOPWR_end <= SNES_SNOOPWR_count == 4;
  end
end

// snoop low-strobe counters + data-OE (level-shifter enable during capture)
always @(posedge CLK2) begin
  // PA write
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

  // PA read -- prioritize writes when there is a DMA from a PPU reg; avoid
  // r213f (region override) and the external B-bus (>=$2184, e.g. Satellaview)
  if (SNES_reset_strobe | SNES_SNOOPPARD_end | ~SNES_WRITE) begin
    SNES_SNOOPPARD_count <= 0;
    SNES_SNOOPPARD_DATA_OE <= 0;
  end
  else if (SNES_PARD_start & ~r213f_enable & (CTX_SNES_PA < 8'h84)) begin
    SNES_SNOOPPARD_count <= 1;
    SNES_SNOOPPARD_DATA_OE <= 1;
  end
  else if (|SNES_SNOOPPARD_count) begin
    SNES_SNOOPPARD_count <= SNES_SNOOPPARD_count + 1;
  end

  // main-bus write
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
end
`endif

reg [7:0] BUS_DATA;

always @(posedge CLK2) begin
  if(~SNES_READ) BUS_DATA <= SNES_DATA;
  else if(~SNES_WRITE) BUS_DATA <= SNES_DATA_IN;
end

wire ROM_HIT;
wire IS_ROM;
assign DCM_RST=0;
wire IS_SAVERAM;
// TODO does this free_slot style cause problems with SA1 performance?
wire SD_DMA_TO_ROM;
// wire free_slot = (SNES_PULSE_end | free_strobe) & ~SD_DMA_TO_ROM;
wire free_slot = SNES_cycle_end | ~IS_ROM;

//wire free_slot = (SNES_PULSEr[0] | ~IS_ROM) & ~SD_DMA_TO_ROM;

// TODO: Provide full bandwidth if snes is not accessing the bus.
always @(posedge CLK2) begin
  if (SNES_cycle_start) free_strobe <= ~ROM_HIT;
  else if (SNES_cycle_end) free_strobe <= 1'b0;
  else free_strobe <= 1'b0;
end

always @(posedge CLK2) begin
  SNES_PULSEr <= {SNES_PULSEr[6:0], SNES_PULSE_IN};
  SNES_PARDr  <= {SNES_PARDr[6:0], SNES_PARD_IN};
  SNES_PAWRr  <= {SNES_PAWRr[6:0], SNES_PAWR_IN};
  SNES_READr  <= {SNES_READr[6:0], SNES_READ_IN};
  SNES_WRITEr <= {SNES_WRITEr[6:0], SNES_WRITE_IN};
  SNES_ROMSELr <= {SNES_ROMSELr[6:0], SNES_ROMSEL_IN};
  SNES_CPU_CLKr <= {SNES_CPU_CLKr[6:0], SNES_CPU_CLK_IN};
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

// One-hot ROM-side arbiter state, widened 11 -> 13 bits for the two CTX write
// states; every original bit is in use, so they are appended, not shared.
parameter ST_IDLE            = 13'b0000000000001;
parameter ST_MCU_RD_ADDR     = 13'b0000000000010;
parameter ST_MCU_RD_END      = 13'b0000000000100;
parameter ST_MCU_WR_ADDR     = 13'b0000000001000;
parameter ST_MCU_WR_END      = 13'b0000000010000;
parameter ST_SA1_ROM_RD_ADDR = 13'b0000000100000;
parameter ST_SA1_ROM_RD_END  = 13'b0000001000000;
// The ST_SA1_RAM_* bits were dead here (SA-1 RAM uses the separate ST_RAM_* FSM),
// so they are reused for the copier.
parameter ST_DMA_RD_ADDR     = 13'b0000010000000;
parameter ST_DMA_RD_END      = 13'b0000100000000;
parameter ST_DMA_WR_ADDR     = 13'b0001000000000;
parameter ST_DMA_WR_END      = 13'b0010000000000;
// ctx (context/PPU-mirror) write port -- top priority; mk3 only.
parameter ST_CTX_WR_ADDR     = 13'b0100000000000;
parameter ST_CTX_WR_END      = 13'b1000000000000;

`ifdef MK2
parameter SNES_DEAD_TIMEOUT = 17'd85714; // 1ms
parameter ROM_CYCLE_LEN = 4'd7; // Increased from 6 due to tight timing on some sd2snes.  Two pics from boards with errors had a Micron chip with 0LA41/PW510.  Same build lot.
`endif
`ifdef MK3
// Cyclone IV PLL allows us to get a bit closer to original speed
parameter SNES_DEAD_TIMEOUT = 17'd85867; // 1ms
parameter ROM_CYCLE_LEN = 4'd6;
`endif

reg [12:0] STATE;
initial STATE = ST_IDLE;

assign MSU_SNES_DATA_IN = BUS_DATA;
assign SA1_SNES_DATA_IN = BUS_DATA;

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

// SA1 address mapping
wire [4:0]  SA1_BMAPS_SBM;

// SA1 ROM access
reg  [15:0] SA1_ROM_DINr;
wire [23:0] SA1_ROM_ADDR;
wire        SA1_ROM_WORD;
wire [15:0] SA1_ROM_DATA;

reg  [7:0]  SA1_RAM_DINr;
wire [23:0] SA1_RAM_ADDR;
wire [7:0]  SA1_RAM_DOUT;
wire        SA1_RAM_WORD;

// SA1
sa1 snes_sa1 (
  .RST(SNES_reset_strobe),
  .CLK(CLK2),
  
  .SAVERAM_MASK(SAVERAM_MASK),
  .ROM_MASK(ROM_MASK),
  
  // MMIO interface
  .SNES_READ(SNES_READ),
  .SNES_WRITE(SNES_WRITE),
  .SNES_RD_start(SNES_RD_start),
  .SNES_RD_end(SNES_RD_end),
  .SNES_WR_start(SNES_WR_start),
  .SNES_WR_end(SNES_WR_end),
  .SNES_cycle_end(SNES_cycle_end),
  .SNES_ADDR(SNES_ADDR),
  .DATA_IN(SA1_SNES_DATA_IN),
  .DATA_ENABLE(sa1_data_enable),
  .DATA_OUT(SA1_SNES_DATA_OUT),
  
  // ROM interface
  .ROM_BUS_RDY(SA1_ROM_RDY),
  .ROM_BUS_RRQ(SA1_ROM_RRQ),
  .ROM_BUS_WRQ(SA1_ROM_WRQ),
  .ROM_BUS_WORD(SA1_ROM_WORD),
  .ROM_BUS_ADDR(SA1_ROM_ADDR),
  .ROM_BUS_WRDATA(SA1_ROM_DATA),
  .ROM_BUS_RDDATA(SA1_ROM_DINr),

  // RAM interface
  .RAM_BUS_RDY(SA1_RAM_RDY),
  .RAM_BUS_RRQ(SA1_RAM_RRQ),
  .RAM_BUS_WRQ(SA1_RAM_WRQ),
  .RAM_BUS_WORD(SA1_RAM_WORD),
  .RAM_BUS_ADDR(SA1_RAM_ADDR),
  .RAM_BUS_RDDATA(SA1_RAM_DINr),
  .RAM_BUS_WRDATA(SA1_RAM_DOUT),

  .BMAPS_SBM(SA1_BMAPS_SBM),
  .SNV(SA1_SNV),
  .SIV(SA1_SIV),
  .SCNT_NVSW(SA1_SCNT_NVSW),
  .SCNT_IVSW(SA1_SCNT_IVSW),
  .DMA_CC1_EN(SA1_DMA_CC1_EN),
  .XXB_OUT(SA1_XXB),
  .XXB_EN_OUT(SA1_XXB_EN),

  // ACTIVE interface
  //.ACTIVE(SA1_ACTIVE),
  .IRQ(SA1_IRQ),
  
  .SPEED(dsp_feat[0]),
  // transparent FPGA-side halt for savestate snapshots (mk3; 0 on mk2)
  .snapshot_pause(snapshot_pause),

  // Savestate scan window (mk3; tied off on mk2)
  .ss_window_en(sa1_ss_enable),
  .ss_halt(sa1_ss_halt),
  .ss_dout(SA1_SS_DATA_OUT),
  .ss_iram_pad(sa1_iram_pad),

  // State debug read interface
  .PGM_ADDR(SA1_PGM_ADDR), // [11:0]
  .PGM_DATA(SA1_PGM_DATA), // [7:0]

  // config
  .reg_group_in(reg_group),
  .reg_index_in(reg_index),
  .reg_value_in(reg_value),
  .reg_invmask_in(reg_invmask),
  .reg_we_in(reg_we),
  .reg_read_in(reg_read),
  .config_data_out(sa1_config_data),

  .DBG(DBG_SA1)
);

`ifdef SA1_SS_ACTIVE
// --------------------------------------------------------------------------
// ctx (context / PPU-mirror) engine -- Mk.III only.  Instantiated exactly as in
// sd2snes_base, wired to the ported snoop signals + the settled SNES taps.
// Produces CTX write requests (CTX_WRQ/CTX_ADDR/CTX_DOUT/CTX_WORD) granted by
// the ROM arbiter, and the ctx_*_enable data-OE terms for the databus logic.
// --------------------------------------------------------------------------
wire [23:0] CTX_ADDR;
wire [15:0] CTX_DOUT;
wire        CTX_WORD;
wire        CTX_WRQ;
wire        CTX_RDY;
wire        CTX_DBG;
wire        ctx_wr_enable;
wire        ctx_pawr_enable;
wire        ctx_pard_enable;

ctx snes_ctx (
  .clkin(CLK2),
  .reset(SNES_reset_strobe),

  .SNES_ADDR(CTX_SNES_ADDR),
  .SNES_PA(CTX_SNES_PA),
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

  .DBG(CTX_DBG),
  .PAD1_OUT(ctx_pad1)
);
`endif

reg [7:0] MCU_DINr;
reg [7:0] MCU_ROM_DINr;
reg [7:0] MCU_RAM_DINr;
wire [7:0] MCU_DOUT;
wire [31:0] cheat_pgm_data;
wire [7:0] cheat_data_out;
wire [2:0] cheat_pgm_idx;

// ---- SNES-side copier ($2020-$202F) -------------------------------------------
// Ported from sd2snes_base: the savestate handler programs the copier over the
// bus (inside its hook window) to stage the WRAM/APU-RAM mirrors into the state
// buffer.  The copier requests PSRAM via BUS_RRQ/WRQ; the ROM-side STATE machine
// grants it cycles through the ST_DMA_* states (which reuse the dead SA1_RAM
// one-hot bits), exactly like the MCU/SA1 requesters.
`ifdef SA1_SS_ACTIVE
wire [7:0] DMA_SNES_DATA_IN;
wire [7:0] DMA_SNES_DATA_OUT;
assign DMA_SNES_DATA_IN = BUS_DATA;
`endif
wire [23:0] DMA_ADDR;
wire [15:0] DMA_DOUT;
wire        DMA_WORD;
reg  [15:0] DMA_DINr;
wire        DMA_RRQ;
wire        DMA_WRQ;
reg  DMA_RD_PENDr = 0;
reg  DMA_WR_PENDr = 0;
reg  [23:0] DMA_ROM_ADDRr;
reg  [15:0] DMA_ROM_DATAr;
reg         DMA_ROM_WORDr;
reg  RQ_DMA_RDYr = 1'b1;
wire DMA_RDY = RQ_DMA_RDYr;
wire DMA_WE_HIT = |(STATE & ST_DMA_WR_ADDR);
wire DMA_WR_HIT = |(STATE & (ST_DMA_WR_ADDR | ST_DMA_WR_END));
wire DMA_RD_HIT = |(STATE & (ST_DMA_RD_ADDR | ST_DMA_RD_END));
wire DMA_HIT    = DMA_WR_HIT | DMA_RD_HIT;

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
  .sa1_addr_out(SA1_PGM_ADDR),
  .sa1_data(SA1_PGM_DATA),
  // config
  .reg_group_out(reg_group),
  .reg_index_out(reg_index),
  .reg_value_out(reg_value),
  .reg_invmask_out(reg_invmask),
  .reg_we_out(reg_we),
  .reg_read_out(reg_read),
  // vv config data in vv
  .sa1_config_data_in(sa1_config_data),
  // ^^ config data in ^^
  .featurebits_out(featurebits),
  .mcu_rrq(MCU_RRQ),
  .mcu_wrq(MCU_WRQ),
  .mcu_rq_rdy(MCU_RDY),
  .region_out(mcu_region),
  .sa1_ss_halt_out(sa1_ss_halt),
  .snescmd_addr_out(snescmd_addr_mcu),
  .snescmd_we_out(snescmd_we_mcu),
  .snescmd_data_out(snescmd_data_out_mcu),
  .snescmd_data_in(snescmd_data_in_mcu),
  .cheat_pgm_idx_out(cheat_pgm_idx),
  .cheat_pgm_data_out(cheat_pgm_data),
  .cheat_pgm_we_out(cheat_pgm_we),
  .dsp_feat_out(dsp_feat)
);

`ifdef SA1_SS_ACTIVE
dma snes_dma (
  .clkin(CLK2),
  .reset(SNES_reset_strobe),
  // Driven by the live SNES bus when it writes/reads $2020-$202F (dma_enable) --
  // used by the in-game savestate snapshot.
  .enable(dma_enable),
  .reg_addr(SNES_ADDR[3:0]),
  .reg_data_in(DMA_SNES_DATA_IN),
  .reg_data_out(DMA_SNES_DATA_OUT),
  .reg_oe_falling(SNES_RD_start),
  .reg_we_rising(SNES_WR_end),
  .loop_enable(),
  .BUS_RDY(DMA_RDY),
  .BUS_RRQ(DMA_RRQ),
  .BUS_WRQ(DMA_WRQ),
  .ROM_ADDR(DMA_ADDR),
  .ROM_DATA_OUT(DMA_DOUT),
  .ROM_DATA_IN(DMA_DINr),
  .ROM_WORD_ENABLE(DMA_WORD)
);
`endif

// Hook-side SA-1 pause register.  $202C (SNES_ADDR[3:0]==C) sits in the same
// 16-address dma_enable window; bit0 of the write sets/clears a TRANSPARENT halt
// (CCNT_r untouched, so the SA-1 resumes exactly where it stopped), cleared on
// SNES reset so a reset can never leave it stuck paused.  The savestate handler
// does not use it -- it freezes the SA-1 at an instruction boundary through the
// $E8 window instead -- but it is the cheap way for a hook to stop the
// coprocessor for a moment.  dma_enable is 0 outside the savestate build, so the
// whole decode folds away there.
always @(posedge CLK2) begin
  if (SNES_reset_strobe)
    snapshot_pause <= 1'b0;
  else if (dma_enable & SNES_WR_end & (SNES_ADDR[3:0] == 4'hC))
    snapshot_pause <= SNES_DATA_IN[0];
end

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
  .IS_PATCH(IS_PATCH),
  .sa1_ss_enable(sa1_ss_enable),
  .SAVERAM_MASK(SAVERAM_MASK),
  .ROM_MASK(ROM_MASK),
  .snescmd_unlock(snescmd_unlock),
  //MSU-1
  .msu_enable(msu_enable),
  //DMA-1 / SNES-side $2020 copier (mk3 snapshot)
  .dma_enable(dma_enable),
  // sa1
  .sa1_bmaps_sbm(SA1_BMAPS_SBM),
  .sa1_dma_cc1_en(SA1_DMA_CC1_EN),
  .sa1_xxb(SA1_XXB),
  .sa1_xxb_en(SA1_XXB_EN),
  .r213f_enable(r213f_enable),
  .r2100_hit(r2100_hit),
  .snescmd_enable(snescmd_enable),
  .nmicmd_enable(nmicmd_enable),
  .return_vector_enable(return_vector_enable),
  .branch1_enable(branch1_enable),
  .branch2_enable(branch2_enable),
  .branch3_enable(branch3_enable)
);

reg pad_latch = 0;
reg [4:0] pad_cnt = 0;

reg snes_ajr = 0;

// ss_combo is declared HERE (before its use in the instance below) and assigned
// further down. XST (mk2) otherwise makes the port connection an implicit net and
// rejects the later declaration as an illegal redeclaration (Quartus tolerates it).
wire ss_combo;

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
  .branch3_enable(branch3_enable),
  .pad_latch(pad_latch),
  .snes_ajr(snes_ajr),
  .ss_combo(ss_combo),
  .SNES_cycle_start(SNES_cycle_start),
  .pgm_idx(cheat_pgm_idx),
  .pgm_we(cheat_pgm_we),
  .pgm_in(cheat_pgm_data),
  .data_out(cheat_data_out),
  .cheat_hit(cheat_hit),
  .snescmd_unlock(snescmd_unlock)
);

wire [7:0] snescmd_dout;

parameter ST_R213F_ARMED     = 4'b0001;
parameter ST_R213F_WAITBUS   = 4'b0010;
parameter ST_R213F_OVERRIDE  = 4'b0100;
parameter ST_R213F_HOLD      = 4'b1000;

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

// Savestate gesture detect, used by cheat.v to arm the IRQ hook only while the
// user is actually holding one (see the rate-limit/gesture-gate note there).
// Reads of $4218/$4219 pulse address+/RD on the cart bus but the DATA of a
// CPU-INTERNAL register read is not driven externally, so a plain read snoop
// captures garbage (verified in hardware).  ctx.v's CPUREG FSM solves this the
// proven way: it watches the instruction stream for the game's LDA $4218(/19) ->
// STA idiom and captures the value from the STORE (writes ARE bus-visible), with
// stale-value expiry, and exports it as PAD1_OUT.
//
// The gestures are the savestate DEFAULT inputs: Start+R (save), Start+L (load)
// and Select+d-pad (slot load).  Custom inputs from savestate_inputs.yml are not
// known to the FPGA, so those only trigger in NMI-driven scenes.
//
// Two pad sources, matched independently: the ctx $4218 store-sniff (scene
// dependent -- some Super Mario RPG areas never use the LDA/STA idiom) and the
// IRAM $3010 pad-forwarding snoop from sa1.v (which every SMRPG scene does).
`ifdef SA1_SS_ACTIVE
assign ss_combo = ((ctx_pad1 & 16'h1010) == 16'h1010)
                | ((ctx_pad1 & 16'h1020) == 16'h1020)
                | (ctx_pad1[13] & |ctx_pad1[11:8])
                | ((sa1_iram_pad & 16'h1010) == 16'h1010)
                | ((sa1_iram_pad & 16'h1020) == 16'h1020)
                | (sa1_iram_pad[13] & |sa1_iram_pad[11:8]);
`else
assign ss_combo = 1'b0;
`endif

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
                                & ~(r2100_enable & ~SNES_PAWR & ~r2100_forcewrite & ~IS_ROM & ~IS_WRITABLE & ~sa1_data_enable))
                                ? ( msu_enable ? MSU_SNES_DATA_OUT
`ifdef SA1_SS_ACTIVE
                                  // SA-1 savestate scan window ($E8:0000-07FF): must
                                  // win over the IS_PATCH/PSRAM fall-through and the
                                  // cheat arm below (address.v aliases $E8 under
                                  // unlock).  Registered byte from sa1.v.
                                  : sa1_ss_enable ? SA1_SS_DATA_OUT
`endif
`ifdef SA1_SS_ACTIVE
                                  : dma_enable ? DMA_SNES_DATA_OUT  // $2020 copier read-back
`endif
                                  : sa1_data_enable ? SA1_SNES_DATA_OUT  // SA1 MMIO read
                                  : (cheat_hit & ~feat_cmd_unlock) ? cheat_data_out
                                  : ((snescmd_unlock | feat_cmd_unlock) & snescmd_enable) ? snescmd_dout
                                  : (ROM_HIT & IS_SAVERAM) ? RAM_DATA
                                  : (SA1_SCNT_NVSW & nmi_match) ? (SNES_ADDR[0] ? SA1_SNV[15:8] : SA1_SNV[7:0])
                                  : (SA1_SCNT_IVSW & irq_match) ? (SNES_ADDR[0] ? SA1_SIV[15:8] : SA1_SIV[7:0])
                                  : (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8])
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

// SA1 ROM
reg SA1_ROM_RD_PENDr; initial SA1_ROM_RD_PENDr = 0;
reg SA1_ROM_WR_PENDr; initial SA1_ROM_WR_PENDr = 0;
reg [23:0] SA1_ROM_ADDRr;
reg [15:0] SA1_ROM_DATAr;
reg        SA1_ROM_WORDr;

reg RQ_SA1_ROM_RDYr; initial RQ_SA1_ROM_RDYr = 1;
assign SA1_ROM_RDY = RQ_SA1_ROM_RDYr;

wire SA1_ROM_RD_HIT = |(STATE & ST_SA1_ROM_RD_ADDR);
wire SA1_ROM_HIT    = SA1_ROM_RD_HIT;

// CTX (context/PPU-mirror) write port -- top-priority ROM requester (mk3).
// Declared unconditionally because the ROM muxes reference them; on mk2 CTX_HIT
// is constant 0 (STATE never enters ST_CTX_*) and the terms fold away.
reg [23:0] CTX_ROM_ADDRr; initial CTX_ROM_ADDRr = 24'h0;
reg [15:0] CTX_ROM_DATAr; initial CTX_ROM_DATAr = 16'h0000;
reg        CTX_ROM_WORDr; initial CTX_ROM_WORDr = 1'b0;
wire CTX_WE_HIT = |(STATE & ST_CTX_WR_ADDR);
wire CTX_WR_HIT = |(STATE & (ST_CTX_WR_ADDR | ST_CTX_WR_END));
wire CTX_HIT    = CTX_WR_HIT;
`ifdef SA1_SS_ACTIVE
reg CTX_WR_PENDr; initial CTX_WR_PENDr = 0;
reg RQ_CTX_RDYr;  initial RQ_CTX_RDYr = 1'b1;
assign CTX_RDY = RQ_CTX_RDYr;
`endif

`ifdef MK2
my_dcm snes_dcm(
  .CLKIN(CLKIN),
  .CLKFX(CLK2),
  .LOCKED(DCM_LOCKED),
  .RST(DCM_RST)
);

assign ROM_ADDR  = (SD_DMA_TO_ROM) ? MCU_ADDR[23:1] : CTX_HIT ? CTX_ROM_ADDRr[23:1] : SA1_ROM_HIT ? SA1_ROM_ADDRr[23:1] : DMA_HIT ? DMA_ROM_ADDRr[23:1] : MCU_HIT ? ROM_ADDRr[23:1] : MAPPED_SNES_ADDR[23:1];
assign ROM_ADDR0 = (SD_DMA_TO_ROM) ? MCU_ADDR[0]    : CTX_HIT ? CTX_ROM_ADDRr[0]    : SA1_ROM_HIT ? SA1_ROM_ADDRr[0]    : DMA_HIT ? DMA_ROM_ADDRr[0]    : MCU_HIT ? ROM_ADDRr[0]    : MAPPED_SNES_ADDR[0];

assign ROM_CE = 1'b0;

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
`endif

`ifdef MK3
pll snes_pll(
  .inclk0(CLKIN),
  .c0(CLK2),
  .locked(DCM_LOCKED),
  .areset(DCM_RST)
);

wire ROM_ADDR22;
assign ROM_ADDR22 = (SD_DMA_TO_ROM) ? MCU_ADDR[1]    : CTX_HIT ? CTX_ROM_ADDRr[1]    : SA1_ROM_HIT ? SA1_ROM_ADDRr[1]    : DMA_HIT ? DMA_ROM_ADDRr[1]    : MCU_HIT ? ROM_ADDRr[1]    : MAPPED_SNES_ADDR[1];
assign ROM_ADDR   = (SD_DMA_TO_ROM) ? MCU_ADDR[23:2] : CTX_HIT ? CTX_ROM_ADDRr[23:2] : SA1_ROM_HIT ? SA1_ROM_ADDRr[23:2] : DMA_HIT ? DMA_ROM_ADDRr[23:2] : MCU_HIT ? ROM_ADDRr[23:2] : MAPPED_SNES_ADDR[23:2];
assign ROM_ADDR0  = (SD_DMA_TO_ROM) ? MCU_ADDR[0]    : CTX_HIT ? CTX_ROM_ADDRr[0]    : SA1_ROM_HIT ? SA1_ROM_ADDRr[0]    : DMA_HIT ? DMA_ROM_ADDRr[0]    : MCU_HIT ? ROM_ADDRr[0]    : MAPPED_SNES_ADDR[0];

assign ROM_ZZ = 1'b1;
assign ROM_1CE = ROM_ADDR22;
assign ROM_2CE = ~ROM_ADDR22;

snescmd_buf snescmd (
  .clock(CLK2), // input clka
  .wren_a(SNES_WR_end & ((snescmd_unlock | feat_cmd_unlock) & snescmd_enable)), // input [0 : 0] wea
  .address_a(SNES_ADDR[8:0]), // input [8 : 0] addra
  .data_a(SNES_DATA), // input [7 : 0] dina
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

reg ROM_ADDR0_r;
always @(posedge CLK2) ROM_ADDR0_r <= ROM_ADDR0;

// MCU r/w request
always @(posedge CLK2) begin
  // MCU E0-E8 (Save RAM) goes to RAM1 instead
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

// SA1 r/w request
always @(posedge CLK2) begin
  if(SA1_ROM_RRQ) begin
    SA1_ROM_RD_PENDr <= 1'b1;
    RQ_SA1_ROM_RDYr <= 1'b0;
    SA1_ROM_ADDRr <= SA1_ROM_ADDR;
    SA1_ROM_WORDr <= SA1_ROM_WORD;
  end else if(SA1_ROM_WRQ) begin
    SA1_ROM_WR_PENDr <= 1'b1;
    RQ_SA1_ROM_RDYr <= 1'b0;
    SA1_ROM_ADDRr <= SA1_ROM_ADDR;
    SA1_ROM_WORDr <= SA1_ROM_WORD;
    SA1_ROM_DATAr <= SA1_ROM_DATA;
  end else if(|(STATE & (ST_SA1_ROM_RD_ADDR)) & ~|ST_MEM_DELAYr) begin
    // enable rdy/response 1 cycle earlier
    RQ_SA1_ROM_RDYr <= 1'b1;
  end else if(STATE & (ST_SA1_ROM_RD_END)) begin
    SA1_ROM_RD_PENDr <= 1'b0;
    SA1_ROM_WR_PENDr <= 1'b0;
    RQ_SA1_ROM_RDYr <= 1'b1;
  end
end

`ifdef SA1_SS_ACTIVE
// Copier r/w request -- latch the requested PSRAM access
always @(posedge CLK2) begin
  if(DMA_RRQ) begin
    DMA_RD_PENDr  <= 1'b1;
    RQ_DMA_RDYr   <= 1'b0;
    DMA_ROM_ADDRr <= DMA_ADDR;
    DMA_ROM_WORDr <= DMA_WORD;
  end else if(DMA_WRQ) begin
    DMA_WR_PENDr  <= 1'b1;
    RQ_DMA_RDYr   <= 1'b0;
    DMA_ROM_ADDRr <= DMA_ADDR;
    DMA_ROM_DATAr <= DMA_DOUT;
    DMA_ROM_WORDr <= DMA_WORD;
  end else if(STATE & (ST_DMA_RD_END | ST_DMA_WR_END)) begin
    DMA_RD_PENDr <= 1'b0;
    DMA_WR_PENDr <= 1'b0;
    RQ_DMA_RDYr  <= 1'b1;
  end
end

// ctx (context/PPU-mirror) write request -- latch the requested PSRAM write.
always @(posedge CLK2) begin
  if(CTX_WRQ) begin
    CTX_WR_PENDr  <= 1'b1;
    RQ_CTX_RDYr   <= 1'b0;
    CTX_ROM_ADDRr <= CTX_ADDR;
    CTX_ROM_DATAr <= CTX_DOUT;
    CTX_ROM_WORDr <= CTX_WORD;
  end
  else if(STATE & ST_CTX_WR_END) begin
    CTX_WR_PENDr <= 1'b0;
    RQ_CTX_RDYr  <= 1'b1;
  end
end

// ctx read-back: the byte the FPGA is serving plus the bus direction.  This core
// serves reads from three sources (SA-1 IRAM/MMIO, BW-RAM and PSRAM), and a DMA
// out of IRAM or BW-RAM is snooped with the FPGA driving, so capturing ROM_DATA
// alone would leave holes in the mirror.  Mirror the SNES_DATA serve mux.
always @(posedge CLK2) begin
  CTX_DINr <= sa1_data_enable ? SA1_SNES_DATA_OUT
            : (ROM_HIT & IS_SAVERAM) ? RAM_DATA
            : (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8]);
  CTX_DIRr <= SNES_DATABUS_DIR;
end
`endif

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
`ifdef SA1_SS_ACTIVE
        // ctx write, top priority; the trailing `end else` chains into the SA1
        // `if` below on mk3 and vanishes on mk2.
        if (CTX_WR_PENDr) begin
          STATE <= ST_CTX_WR_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end else
`endif
        // early notify from SA1 to save a clock
        if (SA1_ROM_RD_PENDr | SA1_ROM_RRQ) begin
          STATE <= ST_SA1_ROM_RD_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
        // early notify from MCU to save a clock
        else if(MCU_RD_PENDr | (MCU_RRQ && MCU_ADDR[23:19] != 5'b11100)) begin
          STATE <= ST_MCU_RD_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end else if(MCU_WR_PENDr | (MCU_WRQ && MCU_ADDR[23:19] != 5'b11100)) begin
          STATE <= ST_MCU_WR_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
`ifdef SA1_SS_ACTIVE
        else if(DMA_RD_PENDr) begin
          STATE <= ST_DMA_RD_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end else if(DMA_WR_PENDr) begin
          STATE <= ST_DMA_WR_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
`endif
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
    ST_SA1_ROM_RD_ADDR: begin
      STATE <= ST_SA1_ROM_RD_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_SA1_ROM_RD_END;
      SA1_ROM_DINr <= (ROM_ADDR0_r ? ROM_DATA[15:0] : {ROM_DATA[7:0],ROM_DATA[15:8]});
    end
`ifdef SA1_SS_ACTIVE
    ST_DMA_RD_ADDR: begin
      STATE <= ST_DMA_RD_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_DMA_RD_END;
      DMA_DINr <= (ROM_ADDR0 ? ROM_DATA[15:0] : {ROM_DATA[7:0],ROM_DATA[15:8]});
    end
    ST_DMA_WR_ADDR: begin
      STATE <= ST_DMA_WR_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_DMA_WR_END;
    end
    ST_CTX_WR_ADDR: begin
      STATE <= ST_CTX_WR_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_CTX_WR_END;
    end
`endif
    ST_MCU_RD_END, ST_MCU_WR_END, ST_SA1_ROM_RD_END, ST_DMA_RD_END, ST_DMA_WR_END, ST_CTX_WR_END: begin
      STATE <= ST_IDLE;
    end
  endcase
end

/***********************
 * R213F read patching *
 ***********************/
always @(posedge CLK2) begin
  case(r213f_state)
    ST_R213F_HOLD: begin
      r213f_state <= ST_R213F_HOLD;
      if(SNES_PULSE_end) begin
        r213f_forceread <= 1'b1;
        r213f_state <= ST_R213F_ARMED;
      end
    end
    ST_R213F_ARMED: begin
      r213f_state <= ST_R213F_ARMED;
      if(SNES_PARD_start & r213f_enable) begin
        r213f_delay <= 3'b001;
        r213f_state <= ST_R213F_WAITBUS;
      end
    end
    ST_R213F_WAITBUS: begin
      r213f_state <= ST_R213F_WAITBUS;
      r213f_delay <= r213f_delay - 1;
      if(r213f_delay == 3'b000) begin
        r213f_state <= ST_R213F_OVERRIDE;
        r213fr <= {SNES_DATA[7:5], mcu_region, SNES_DATA[3:0]};
      end
    end
    ST_R213F_OVERRIDE: begin
      r213f_state <= ST_R213F_HOLD;
      r213f_forceread <= 1'b0;
    end
  endcase
end

/*********************************
 * R2100 patching (experimental) *
 *********************************/
reg [3:0] r2100_bright = 0;
reg [3:0] r2100_bright_orig = 0;

always @(posedge CLK2) begin
  if(SNES_PULSE_end) r2100_forcewrite_pre <= 1'b0;
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
assign ROM_DATA[7:0] = (ROM_ADDR0 || (!SD_DMA_TO_ROM && CTX_HIT && CTX_ROM_WORDr) || (!SD_DMA_TO_ROM && DMA_HIT && DMA_ROM_WORDr))
                       ?(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                       : CTX_WR_HIT ? CTX_ROM_DATAr[15:8]  // ctx snapshot write (mk3)
                                       : DMA_WR_HIT ? DMA_ROM_DATAr[15:8]
                                       // The handler writes its scratches through the ROM bus, so the
                                       // SNES->PSRAM drive is kept for IS_PATCH writes only; stray game
                                       // writes to ROM stay high-Z.
                                       : (IS_PATCH
                                         & ~SNES_WRITE) ? SNES_DATA
                                       : MCU_WR_HIT ? MCU_DOUT : 8'bZ
                        )
                       :8'bZ;

// even addresses xxx0
assign ROM_DATA[15:8] = ROM_ADDR0
                        ? 8'bZ
                        :(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                        : CTX_WR_HIT ? CTX_ROM_DATAr[7:0]  // ctx snapshot write (mk3)
                                        : DMA_WR_HIT ? DMA_ROM_DATAr[7:0]
                                        // See the IS_PATCH note on the odd-byte mux above.
                                        : (IS_PATCH
                                          & ~SNES_WRITE) ? SNES_DATA
                                        : MCU_WR_HIT ? MCU_DOUT
                                        : 8'bZ
                         );

assign ROM_WE = SD_DMA_TO_ROM
                ?MCU_WRITE
                : CTX_WE_HIT ? 1'b0                       // ctx snapshot write (mk3)
                : DMA_WE_HIT ? 1'b0                       // MCU-driven copier write
                : (ROM_HIT & IS_WRITABLE
                  & ~IS_SAVERAM
                  & SNES_CPU_CLK) ? SNES_WRITE
                : MCU_WE_HIT ? 1'b0
                : 1'b1;

// force word enable for SA1, the MCU-driven copier and ctx (word mode)
assign ROM_BHE =  ROM_ADDR0 && !(!SD_DMA_TO_ROM && CTX_HIT && CTX_ROM_WORDr) && !(!SD_DMA_TO_ROM && SA1_ROM_HIT && SA1_ROM_WORDr) && !(!SD_DMA_TO_ROM && DMA_HIT && DMA_ROM_WORDr);
assign ROM_BLE = !ROM_ADDR0 && !(!SD_DMA_TO_ROM && CTX_HIT && CTX_ROM_WORDr) && !(!SD_DMA_TO_ROM && SA1_ROM_HIT && SA1_ROM_WORDr) && !(!SD_DMA_TO_ROM && DMA_HIT && DMA_ROM_WORDr);

//--------------
// RAM Pipeline
//--------------
parameter ST_RAM_IDLE            = 9'b000000001;
parameter ST_RAM_MCU_RD_ADDR     = 9'b000000010;
parameter ST_RAM_MCU_RD_END      = 9'b000000100;
parameter ST_RAM_MCU_WR_ADDR     = 9'b000001000;
parameter ST_RAM_MCU_WR_END      = 9'b000010000;
parameter ST_RAM_SA1_RD_ADDR     = 9'b000100000;
parameter ST_RAM_SA1_RD_END      = 9'b001000000;
parameter ST_RAM_SA1_WR_ADDR     = 9'b010000000;
parameter ST_RAM_SA1_WR_END      = 9'b100000000;

parameter RAM_CYCLE_LEN = 4'd5;

reg [8:0] RAM_STATE; initial RAM_STATE = ST_RAM_IDLE;
reg [3:0] ST_RAM_DELAYr;

//wire ram_free_slot = SNES_cycle_end | ram_free_strobe;
wire ram_free_slot = SNES_cycle_end | ~IS_SAVERAM;

// Provide full bandwidth if snes is not accessing the bus.
always @(posedge CLK2) begin
  if (SNES_cycle_start) ram_free_strobe <= ~ROM_HIT | ~IS_SAVERAM;
  else if (SNES_cycle_end) ram_free_strobe <= 1'b0;
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

// MCU RAM1 r/w request
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

// SA1 RAM
reg SA1_RAM_RD_PENDr; initial SA1_RAM_RD_PENDr = 0;
reg SA1_RAM_WR_PENDr; initial SA1_RAM_WR_PENDr = 0;
// TODO: how much ram does sa1 support?  more than 512KB?
reg [18:0] SA1_RAM_ADDRr;
reg [7:0]  SA1_RAM_DATAr;
reg        SA1_RAM_WORDr;

reg RQ_SA1_RAM_RDYr; initial RQ_SA1_RAM_RDYr = 1;
assign SA1_RAM_RDY = RQ_SA1_RAM_RDYr;

wire SA1_RAM_WE_HIT = |(RAM_STATE & ST_RAM_SA1_WR_ADDR);
wire SA1_RAM_WR_HIT = |(RAM_STATE & (ST_RAM_SA1_WR_ADDR | ST_RAM_SA1_WR_END));
wire SA1_RAM_RD_HIT = |(RAM_STATE & (ST_RAM_SA1_RD_ADDR | ST_RAM_SA1_RD_END));
wire SA1_RAM_HIT    = SA1_RAM_WR_HIT | SA1_RAM_RD_HIT;

// SA1 RAM1 r/w request
always @(posedge CLK2) begin
  if(SA1_RAM_RRQ) begin
    SA1_RAM_RD_PENDr <= 1'b1;
    RQ_SA1_RAM_RDYr <= 1'b0;
    SA1_RAM_ADDRr <= SA1_RAM_ADDR;
    SA1_RAM_WORDr <= SA1_RAM_WORD;
  end else if(SA1_RAM_WRQ) begin
    SA1_RAM_WR_PENDr <= 1'b1;
    RQ_SA1_RAM_RDYr <= 1'b0;
    SA1_RAM_ADDRr <= SA1_RAM_ADDR;
    SA1_RAM_WORDr <= SA1_RAM_WORD;
    SA1_RAM_DATAr <= SA1_RAM_DOUT;
  end else if(RAM_STATE & (ST_RAM_SA1_RD_END | ST_RAM_SA1_WR_END)) begin
    SA1_RAM_RD_PENDr <= 1'b0;
    SA1_RAM_WR_PENDr <= 1'b0;
    RQ_SA1_RAM_RDYr <= 1'b1;
  end
end

// RAM state machine
always @(posedge CLK2) begin
  if(SNES_DEADr & SNES_CPU_CLKr[1]) RAM_STATE <= ST_RAM_IDLE; // interrupt+restart an ongoing MCU access when the SNES comes alive
  else
  case(RAM_STATE)
    ST_RAM_IDLE: begin
      if(ram_free_slot | SNES_DEADr) begin
        // early notify from SA1 to save a clock
        if (SA1_RAM_RD_PENDr | SA1_RAM_RRQ) begin
          RAM_STATE <= ST_RAM_SA1_RD_ADDR;
          ST_RAM_DELAYr <= RAM_CYCLE_LEN;
        end
        else if (SA1_RAM_WR_PENDr | SA1_RAM_WRQ) begin
          RAM_STATE <= ST_RAM_SA1_WR_ADDR;
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
    ST_RAM_SA1_RD_ADDR: begin
      ST_RAM_DELAYr <= ST_RAM_DELAYr - 1;
      if(ST_RAM_DELAYr == 0) RAM_STATE <= ST_RAM_SA1_RD_END;
      SA1_RAM_DINr <= RAM_DATA;
    end
    ST_RAM_SA1_WR_ADDR: begin
      ST_RAM_DELAYr <= ST_RAM_DELAYr - 1;
      if(ST_RAM_DELAYr == 0) RAM_STATE <= ST_RAM_SA1_WR_END;
    end
    ST_RAM_MCU_RD_END, ST_RAM_MCU_WR_END, ST_RAM_SA1_RD_END, ST_RAM_SA1_WR_END: begin
      RAM_STATE <= ST_RAM_IDLE;
    end
  endcase
end

assign RAM_ADDR = SA1_RAM_HIT ? SA1_RAM_ADDRr[18:0] : MCU_RAM_HIT ? RAM_ADDRr[18:0] : MAPPED_SNES_ADDR[18:0];

assign RAM_DATA[7:0] = ( SA1_RAM_WR_HIT ? SA1_RAM_DATAr[7:0]
                       : (ROM_HIT & IS_SAVERAM & ~SNES_WRITE) ? SNES_DATA
                       : MCU_RAM_WR_HIT ? MCU_DOUT
                       : 8'bZ
                       );

assign RAM_WE = ( SA1_RAM_WE_HIT ? 1'b0
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
end

assign MCU_RDY = RQ_MCU_RDYr & RQ_RAM_MCU_RDYr;

//--------------

assign SNES_DATABUS_OE = msu_enable & ~(SNES_READ_narrow & SNES_WRITE) ? 1'b0 :
`ifdef SA1_SS_ACTIVE
                         sa1_ss_enable ? 1'b0 : // savestate window read/write
`endif
                         sa1_data_enable ? 1'b0 : // accounts for read/write
                         snescmd_enable & ~(SNES_READ_narrow & SNES_WRITE) ? ~(snescmd_unlock | feat_cmd_unlock) :
                         (r213f_enable & ~SNES_PARD) ? 1'b0 :
                         (r2100_enable & ~SNES_PAWR) ? 1'b0 :
                         snoop_4200_enable & ~SNES_WRITE ? 1'b0 :
`ifdef SA1_SS_ACTIVE
                         // enable the level shifter for the $2020 copier
                         // (read-back) and while the ctx engine captures a snooped access.
                         dma_enable & ~(SNES_READ_narrow & SNES_WRITE) ? 1'b0 :
                         (ctx_wr_enable & SNES_SNOOPWR_DATA_OE) ? 1'b0 :
                         (ctx_pawr_enable & SNES_SNOOPPAWR_DATA_OE) ? 1'b0 :
                         (ctx_pard_enable & SNES_SNOOPPARD_DATA_OE) ? 1'b0 :
`endif
                         ( (IS_ROM & SNES_ROMSEL)
                         | (!IS_ROM & !IS_SAVERAM & !IS_WRITABLE)
                         | (SNES_READ_narrow & SNES_WRITE)
                         );

/* data bus direction: 0 = SNES -> FPGA; 1 = FPGA -> SNES
 * data bus is always SNES -> FPGA to avoid fighting except when:
 *  a) the SNES wants to read
 *  b) we want to force a value on the bus
 */
`ifdef SA1_SS_ACTIVE
// Keep the bus SNES -> FPGA while the ctx engine snoops a PA access, so the FPGA
// captures the byte instead of fighting the PPU/APU for it.  The served-source
// terms (ROM_HIT, sa1_data_enable) are what makes that safe: a concurrent A-bus
// read on DMA/HDMA must not flip the shifter to drive unless the FPGA is the one
// serving that source, or the DMA reads float.  The assign head is duplicated per
// platform so the mk2 output stays identical to the original.
assign SNES_DATABUS_DIR = ((~SNES_READ & ((~SNES_SNOOPPAWR_DATA_OE & ~SNES_SNOOPPARD_DATA_OE) | ROM_HIT | sa1_data_enable
                                          | sa1_ss_enable  // savestate window read -> drive FPGA->SNES; write falls through (DIR=0)
                                          )) | (~SNES_PARD & (r213f_enable)))
                           ? (1'b1 ^ (r213f_forceread & r213f_enable & ~SNES_PARD)
                                   ^ (r2100_enable & ~SNES_PAWR & ~r2100_forcewrite & ~IS_ROM & ~IS_WRITABLE & ~sa1_data_enable))
                           : ((~SNES_PAWR & r2100_enable) ? r2100_forcewrite
                             : 1'b0);
`else
assign SNES_DATABUS_DIR = (~SNES_READ | (~SNES_PARD & (r213f_enable)))
                           ? (1'b1 ^ (r213f_forceread & r213f_enable & ~SNES_PARD)
                                   ^ (r2100_enable & ~SNES_PAWR & ~r2100_forcewrite & ~IS_ROM & ~IS_WRITABLE & ~sa1_data_enable))
                           : ((~SNES_PAWR & r2100_enable) ? r2100_forcewrite
                             : 1'b0);
`endif

assign SNES_IRQ = SA1_IRQ;

endmodule

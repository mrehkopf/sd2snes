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
// SPC7110 behaviour referenced here follows the ares implementation (ISC);
// the full ISC notice is carried in spc7110_map.v / spc7110_dcu.v.

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

  /* Bus 2: SRAM, 4Mbit, 8bit, 45ns -> NOT USED; Backup RAM mapped to $E0:0000 in PSRAM */
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
/* SPC7110 data ROM window in PSRAM, programmed by the MCU (see mcu_cmd.v) */
wire [23:0] DROM_BASE;
wire [23:0] DROM_MASK;
wire [23:0] EXP_BASE;
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

wire [15:0] featurebits;
wire feat_cmd_unlock = featurebits[5];

wire [23:0] MAPPED_SNES_ADDR;
wire ROM_ADDR0;

wire [8:0] snescmd_addr_mcu;
wire [7:0] snescmd_data_out_mcu;
wire [7:0] snescmd_data_in_mcu;

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

// snes address bus delayed by 6 cycles, 4 respect SNES_READ and SNES_WRITE
wire [23:0] SNES_ADDR = (SNES_ADDRr[5] & SNES_ADDRr[4]);
wire [7:0] SNES_PA = (SNES_PAr[5] & SNES_PAr[4]);
wire [7:0] SNES_DATA_IN = (SNES_DATAr[3] & SNES_DATAr[2]);

wire SNES_PULSE_IN = SNES_READ_IN & SNES_WRITE_IN & ~SNES_CPU_CLK_IN;

wire SNES_PULSE_end = (SNES_PULSEr[6:1] == 6'b000011);
wire SNES_PARD_start = (SNES_PARDr[6:1] == 6'b111110);
wire SNES_PARD_end = (SNES_PARDr[6:1] == 6'b000001);
// Sample PAWR data earlier on CPU accesses, later on DMA accesses...
wire SNES_PAWR_start = (SNES_PAWRr[7:1] == (({SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h02100) ? 7'b1110000 : 7'b1000000));
wire SNES_PAWR_end = (SNES_PAWRr[6:1] == 6'b000001);
wire SNES_RD_start = (SNES_READr[6:1] == 6'b111110);
wire SNES_RD_end = (SNES_READr[6:1] == 6'b000001);
wire SNES_WR_end = (SNES_WRITEr[6:1] == 6'b000001);
wire SNES_cycle_start = (SNES_CPU_CLKr[6:1] == 6'b000001);
wire SNES_cycle_end = (SNES_CPU_CLKr[6:1] == 6'b111110);
// active low write signal from SNES delayed 2 cycles (96MHz clock)
wire SNES_WRITE = SNES_WRITEr[2] & SNES_WRITEr[1];
// active low read signal from SNES delayed 2 cycles (96MHz clock)
wire SNES_READ = SNES_READr[2] & SNES_READr[1];
wire SNES_READ_late = SNES_READr[5] & SNES_READr[4];
wire SNES_READ_narrow = SNES_READ | SNES_READ_late;
wire SNES_CPU_CLK = SNES_CPU_CLKr[2] & SNES_CPU_CLKr[1];
wire SNES_PARD = SNES_PARDr[2] & SNES_PARDr[1];
wire SNES_PAWR = SNES_PAWRr[2] & SNES_PAWRr[1];

// active low ROM-select signal from SNES delayed 5 cycles (96MHz clock)
wire SNES_ROMSEL = (SNES_ROMSELr[5] & SNES_ROMSELr[4]);

reg [7:0] BUS_DATA;

// if SNES CPU is reading, register data bus
// if SNES CPU is writing, register data bus delayed 4 cycles
always @(posedge CLK2) begin
  if(~SNES_READ) BUS_DATA <= SNES_DATA;
  else if(~SNES_WRITE) BUS_DATA <= SNES_DATA_IN;
end

wire SD_DMA_TO_ROM;
wire free_slot = (SNES_PULSE_end | free_strobe) & ~SD_DMA_TO_ROM;

wire ROM_HIT;

assign DCM_RST=0;

always @(posedge CLK2) begin
  free_strobe <= 1'b0;
  if(SNES_cycle_start) free_strobe <= ~ROM_HIT;
end

// register all interface signals from SNES with 96MHz clock
always @(posedge CLK2) begin
  SNES_PULSEr <= {SNES_PULSEr[6:0], SNES_PULSE_IN};
  SNES_PARDr <= {SNES_PARDr[6:0], SNES_PARD_IN};
  SNES_PAWRr <= {SNES_PAWRr[6:0], SNES_PAWR_IN};
  // 8-cycle pipeline for /SNES_RD
  SNES_READr <= {SNES_READr[6:0], SNES_READ_IN};
  // 8-cycle pipeline for /SNES_WR
  SNES_WRITEr <= {SNES_WRITEr[6:0], SNES_WRITE_IN};
  SNES_CPU_CLKr <= {SNES_CPU_CLKr[6:0], SNES_CPU_CLK_IN};
  SNES_ROMSELr <= {SNES_ROMSELr[6:0], SNES_ROMSEL_IN};
  // 7 cycles pipeline for full address bus (24 bits)
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

parameter ST_IDLE        = 5'b00001;
parameter ST_MCU_RD_ADDR = 5'b00010;
parameter ST_MCU_RD_END  = 5'b00100;
parameter ST_MCU_WR_ADDR = 5'b01000;
parameter ST_MCU_WR_END  = 5'b10000;

parameter SNES_DEAD_TIMEOUT = 17'd96000; // 1ms

parameter ROM_CYCLE_LEN = 4'd7;

/* Length of a data ROM fetch, in CLK2 cycles minus one (the counter is loaded
 * with this value and the byte is sampled on the edge that retires it, so the
 * address is held for DROM_CYCLE_LEN+1 cycles).
 *
 * It is LONGER than ROM_CYCLE_LEN on purpose, and the difference is the reason
 * this parameter exists at all.  The PSRAM is asynchronous, so the real budget
 * of an access is
 *
 *     hold >= (clock to ROM_ADDR pad) + (array access time) + (ROM_DATA setup)
 *
 * and NONE of those three terms is covered by a timing constraint: the external
 * bus carries no OFFSET IN/OUT in main.ucf (in any core of the fork), so a fit
 * that reports "all constraints met" has said nothing about it.  Measured on
 * the placed and routed mk2 design (trce data sheet report plus a FROM:TO
 * attribution per source), 96.04 MHz, xc3s400-4:
 *
 *   clock to ROM_ADDR pad, MCU source (ROM_ADDRr, a plain register): 10.0-11.2 ns
 *   clock to ROM_ADDR pad, fetch source (drom_addr):                 17.5-18.1 ns
 *   ROM_DATA pad to the capture flip-flop, setup:                    up to 8.2 ns
 *
 * The fetch is ~7 ns slower than the MCU read because its address reaches the
 * pins through the 24-bit adder that biases the linear data ROM offset by the
 * window base -- the MCU drives the pins straight out of a register.  With the
 * MCU's eight cycles (83.3 ns) that leaves 83.3 - 18.1 - 8.2 = 57.0 ns for the
 * array, BELOW what the 70 ns part guarantees and close enough to what it
 * actually does that some addresses read the previous word: a byte from a
 * neighbouring address, deterministic, and on screen a handful of corrupted
 * tiles in an otherwise correct image.  Ten cycles (104.1 ns) leave 77.8 ns,
 * which clears the datasheet number with margin.
 *
 * The same budget computed from the trce data sheet report's WORST clock-to-pad
 * of the whole fit (24.91 ns, which includes pads the fetch never drives) and
 * the worst ROM_DATA setup (6.54 ns) gives 51.9 ns at eight cycles and 72.7 ns
 * at ten -- a more conservative +2.7 ns margin.  Both attributions agree on the
 * decision (eight cycles is short of 70 ns, ten clears it); quote either, but
 * know which one you are quoting: per-path FROM:TO above, whole-fit worst here.
 *
 * Do not lower this back to ROM_CYCLE_LEN.  If the fetch ever has to get
 * shorter, take the adder out of the path from drom_addr to the pins first and
 * re-measure -- the number here is a hardware budget, not a preference.
 */
parameter DROM_CYCLE_LEN = 4'd9;

reg [4:0] STATE;
initial STATE = ST_IDLE;

assign MSU_SNES_DATA_IN = BUS_DATA;

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

wire [15:0] dsp_feat;

/*****************************************************************************
 * SPC7110 register block
 *
 * The chip answers at $4800-$484F in banks $00-$3F / $80-$BF (bank groups with
 * address bit 22 clear, hence the ~SNES_ADDR[22] term):
 *   $4800-$480F  decompression unit
 *   $4810-$481F  data port
 *   $4820-$482F  ALU (mul/div)
 *   $4830-$483F  bank/window mapping + SRAM enable
 *   $4840-$484F  RTC-4513 interface
 *
 * Plus the two whole-bank aliases of the reference, which is how a game aims a
 * DMA channel straight at the chip without going through the B bus: EVERY
 * address in bank $50 is $4800 and EVERY address in bank $58 is $4808 (the
 * offset inside the bank is ignored, so the DMA may walk it or hold it still).
 * The reference tests the bank exactly, so $D0/$D8 are NOT aliases.  Those two
 * banks carry address bit 22 and are claimed by nothing else in this core: the
 * cartridge windows of spc7110_map are $00-3f/$80-bf:8000-ffff and
 * $c0-ff:0000-ffff, its SRAM window needs bit 22 clear, and the hook identity
 * window needs bits 23:22 both set -- so the alias cannot punch a hole in any
 * of them.
 *
 * This block decodes the window and folds the alias into a register index; the
 * register file itself is spc7110_regs.v.
 *****************************************************************************/
reg spc7110_enable;
reg spc7110_reg_enable;
reg [7:0] spc7110_reg_addr;

wire spc7110_win_regs  = ~SNES_ADDR[22] & (SNES_ADDR[15:8] == 8'h48)
                       & ((SNES_ADDR[7:6] == 2'b00) | (SNES_ADDR[7:4] == 4'h4));
wire spc7110_win_4800  = (SNES_ADDR[23:16] == 8'h50);   // bank alias of $4800
wire spc7110_win_4808  = (SNES_ADDR[23:16] == 8'h58);   // bank alias of $4808

// '1' when accessing any SPC7110 register $4800-$484F, or one of the two bank
// aliases; spc7110_reg_addr is the register index the access resolves to.
always @(posedge CLK2)
begin
  if( SNES_DEADr == 1'b1 )
    begin
      spc7110_enable        <= 1'b0;
      spc7110_reg_enable    <= 1'b0;
      spc7110_reg_addr      <= 8'h00;
    end
  else if( MAPPER == 3'b101 )
    begin
      spc7110_enable        <= 1'b1;
      spc7110_reg_enable    <= spc7110_win_regs | spc7110_win_4800 | spc7110_win_4808;
      spc7110_reg_addr      <= spc7110_win_4800 ? 8'h00
                             : spc7110_win_4808 ? 8'h08
                             : SNES_ADDR[7:0];
    end
  else
    begin
      spc7110_enable        <= 1'b0;
      spc7110_reg_enable    <= 1'b0;
      spc7110_reg_addr      <= 8'h00;
    end
end

// Register read-back ($4800-$484F), combinational: a register read never waits
// for a data ROM fetch.
wire [7:0] spc7110_dout;

/* Cartridge address mapping produced by spc7110_map (inside spc7110_regs) and
 * consumed by address.v, which turns it into the final PSRAM address. */
wire        SPC7110_ROM_HIT;
wire [23:0] SPC7110_PSRAM_ADDR;
wire        SPC7110_IS_SRAM;

/* RTC-4513 (the cartridge with the real time clock).  Time keeping is the
 * shared rtc.v of the base core, written either by the MCU (SPI command $e5) or
 * by the game through $4840-$4842, exactly the way srtc.v drives it for the
 * S-RTC. */
wire [59:0] rtc_data;
wire [55:0] rtc_data_in;
wire        rtc_pgm_we;
wire [59:0] rtcif_rtc_data_wr;
wire        rtcif_rtc_we;
/* RTC-4513 battery backup: read by the MCU with SPI $e6, restored with $e7 */
`ifndef MK2
wire [59:0] rtc_bkp_time;
wire [1:0]  rtc_bkp_flags;
wire [59:0] rtc_bkp_time_in;
wire [1:0]  rtc_bkp_flags_in;
wire        rtc_bkp_we;
`endif

/*****************************************************************************
 * Data ROM (DROM) fetch path
 *
 * The data port and the decompressor read the compressed data ROM one byte at a
 * time through a req/ack handshake with arbitrary latency.  The fetch steals a
 * PSRAM slot from the SNES exactly the way the S-DD1 prefetch did: the SNES owns
 * the bus during its own read cycle, the second half of every cycle is free, and
 * a started access runs to completion (DROM_CYCLE_LEN+1 clocks at 96 MHz, see
 * the parameter for the hardware budget behind that number) before the address
 * may change.
 *
 *   drom_req   level, held by the requester until its ack
 *   drom_addr  LINEAR offset inside the data ROM (0-based), latched at arm time
 *   drom_ack   one clock, drom_data valid, one per requester
 *   drom_data  the fetched byte, registered
 *   drom_busy  '1' while the fetch owns the PSRAM bus; it also keeps the MCU
 *              off the bus below, the same role the S-DD1's "Idle" output had
 *
 * The state machine itself sits further down, next to the MCU request registers
 * it has to arbitrate against.
 *****************************************************************************/
wire        data_drom_req;
wire [23:0] data_drom_addr;
wire        dcu_drom_req;
wire [23:0] dcu_drom_addr;

// Fixed priority, data port above the decompressor: a $4810 read is synchronous
// to the SNES (the game may be running a DMA straight out of it) while the
// decompressor has a tile buffer and tolerates the wait.  Neither requester
// bursts -- one byte in flight each, by contract -- so a fixed priority is
// enough and costs nothing.
wire        drom_req      = data_drom_req | dcu_drom_req;
wire        drom_sel_dcu  = ~data_drom_req & dcu_drom_req;
wire [23:0] drom_sel_addr = data_drom_req ? data_drom_addr : dcu_drom_addr;

reg         drom_busy;
reg         drom_owner;    // owner of the running fetch: 0 = data port, 1 = DCU
reg  [23:0] drom_addr;
reg  [3:0]  drom_cnt;
reg         drom_ack;
reg  [7:0]  drom_data;

initial begin
  drom_busy  = 1'b0;
  drom_owner = 1'b0;
  drom_addr  = 24'h000000;
  drom_cnt   = 4'h0;
  drom_ack   = 1'b0;
  drom_data  = 8'h00;
end

wire data_drom_ack = drom_ack & ~drom_owner;
wire dcu_drom_ack  = drom_ack &  drom_owner;

// PSRAM address of the byte being fetched: linear offset wrapped inside the data
// ROM, then biased by its base.  Both come from the MCU (SPI commands $d7/$d8).
// NOTE the power-up defaults (base 0, mask $ffffff) provide no wrap at all: the
// firmware must program $d7/$d8 before the first fetch or reads walk from
// PSRAM 0 unbounded.
wire [23:0] drom_psram_addr = DROM_BASE + (drom_addr & DROM_MASK);

spc7110_regs snes_spc7110(
  .clkin(CLK2),
  .rst(SNES_DEADr),
  .reg_enable(spc7110_reg_enable),
  .reg_addr(spc7110_reg_addr),
  .reg_din(BUS_DATA),
  .wr_end(SNES_WR_end),
  .rd_end(SNES_RD_end),
  .reg_dout(spc7110_dout),
  .snes_addr(SNES_ADDR),
  .drom_base(DROM_BASE),
  .drom_mask(DROM_MASK),
  .exp_base(EXP_BASE),
  .map_rom_hit(SPC7110_ROM_HIT),
  .map_psram_addr(SPC7110_PSRAM_ADDR),
  .map_is_sram(SPC7110_IS_SRAM),
  .data_drom_req(data_drom_req),
  .data_drom_addr(data_drom_addr),
  .data_drom_ack(data_drom_ack),
  .dcu_drom_req(dcu_drom_req),
  .dcu_drom_addr(dcu_drom_addr),
  .dcu_drom_ack(dcu_drom_ack),
  .drom_data(drom_data),
  .rtc_data(rtc_data),
  .rtc_we(rtcif_rtc_we),
`ifndef MK2
  .rtc_data_wr(rtcif_rtc_data_wr),
  .bkp_time(rtc_bkp_time),
  .bkp_flags(rtc_bkp_flags),
  .bkp_we(rtc_bkp_we),
  .bkp_time_in(rtc_bkp_time_in),
  .bkp_flags_in(rtc_bkp_flags_in)
`else
  .rtc_data_wr(rtcif_rtc_data_wr)
`endif
);

// Time keeping.  Runs on CLKIN, not CLK2 -- same as the base core.  The
// crossing into rtc_data_r is a quasi-static CDC and is cut in main.sdc.
// On mk2 the DCM wrapper owns the IBUFG of the CLKIN pad, so every other
// consumer has to take the buffered copy (a pad may feed its input buffer and
// nothing else); mk3 has no such wrapper and uses the pin directly.
`ifdef MK2
wire clkin_rtc;
`else
wire clkin_rtc = CLKIN;
`endif
rtc snes_rtc (
  .clkin(clkin_rtc),
  .rtc_data(rtc_data),
  .rtc_data_in(rtc_data_in),
  .pgm_we(rtc_pgm_we),
  .rtc_data_in1(rtcif_rtc_data_wr),
  .we1(rtcif_rtc_we)
);

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
  .saveram_mask_out(SAVERAM_MASK),
  .rom_mask_out(ROM_MASK),
  .drom_base_out(DROM_BASE),
  .drom_mask_out(DROM_MASK),
  .exp_base_out(EXP_BASE),
  .rtc_data_out(rtc_data_in),
  .rtc_pgm_we(rtc_pgm_we),
`ifndef MK2
  .rtc_bkp_in(rtc_bkp_time),
  .rtc_bkp_flags_in(rtc_bkp_flags),
  .rtc_bkp_out(rtc_bkp_time_in),
  .rtc_bkp_flags_out(rtc_bkp_flags_in),
  .rtc_bkp_we(rtc_bkp_we),
`endif
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

address snes_addr(
  .featurebits(featurebits),
  .SNES_ADDR(SNES_ADDR), // requested address from SNES
  .SNES_PA(SNES_PA),
  .SNES_ROMSEL(SNES_ROMSEL),
  // Address to read/write from PSRAM
  .ROM_ADDR(MAPPED_SNES_ADDR),
  // '1' when SNES request to access ROM, Backup RAM or BS-X RAM (stored at PSRAM)
  .ROM_HIT(ROM_HIT),
  // '1' when SNES request to access backup RAM (stored linearly at PSRAM $E0:0000)
  .IS_SAVERAM(IS_SAVERAM),
  // '1' when SNES request to access ROM (stored linearly at PSRAM $00:0000)
  .IS_ROM(IS_ROM),
  // '1' when SNES request to access to PSRAM writable range (Backup RAM or BS-X RAM)
  .IS_WRITABLE(IS_WRITABLE),
  .SAVERAM_MASK(SAVERAM_MASK),
  .ROM_MASK(ROM_MASK),
  // cartridge mapping from spc7110_map: the four $4830-$4834 selected windows
  .SPC7110_ROM_HIT(SPC7110_ROM_HIT),
  .SPC7110_PSRAM_ADDR(SPC7110_PSRAM_ADDR),
  .SPC7110_IS_SRAM(SPC7110_IS_SRAM),
  //MSU-1
  .msu_enable(msu_enable),
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

// data from FPGA to SNES CPU when it is reading
assign SNES_DATA = (r213f_enable & ~SNES_PARD & ~r213f_forceread) ? r213fr
                   :(r2100_enable & ~SNES_PAWR & r2100_forcewrite) ? r2100r
                   :(~SNES_READ ^ (r213f_forceread & r213f_enable & ~SNES_PARD)) ?
              ( msu_enable ? MSU_SNES_DATA_OUT
              :(cheat_hit & ~feat_cmd_unlock) ? cheat_data_out
              :((snescmd_unlock | feat_cmd_unlock) & snescmd_enable) ? snescmd_dout
              // SPC7110 register read-back ($4800-$484F)
              :(spc7110_enable & spc7110_reg_enable) ? spc7110_dout
              :(ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8]))
             : 8'bZ;

reg [3:0] ST_MEM_DELAYr;
reg MCU_RD_PENDr = 0;
reg MCU_WR_PENDr = 0;
reg [23:0] ROM_ADDRr;

/* DROM fetch state machine (the path is declared with the register block above).
 *
 * Invariants, all inherited from the way the S-DD1 prefetch shared the bus:
 *  - arm ONLY in a free slot.  Taking the bus while the SNES is driving an
 *    access swaps the address under a read in flight.
 *  - once armed, hold the bus until the counter runs out even if the slot ends
 *    (the S-DD1 did the same with ROM_Access_Cnt /= 0); PSRAM is asynchronous
 *    and an address glitch mid-access corrupts the byte.
 *  - do NOT arm while the MCU has a request pending.  free_slot is a ONE clock
 *    pulse and the MCU gate below tests ~drom_busy, which is still 0 on the
 *    clock this machine arms, so both would take the same slot -- and the
 *    address mux gives the MCU priority, so this fetch would silently sample
 *    the MCU's address.  Deferring here matches the priority already in the mux.
 *  - drom_busy alone owns the address mux for the whole access.  Gating the mux
 *    with anything combinational over the SNES address, or with the mapper
 *    enable, would drop the fetch mid-access -- silently, whenever that term
 *    moved.
 *  - drom_ack is a REGISTERED one clock pulse and drom_data is already latched
 *    when it fires.  The requesters drop drom_req combinationally on their ack,
 *    so an ack derived combinationally from the request would close a loop.
 *  - SNES_DEADr drops everything: the MCU needs the whole bus to load a ROM.
 */
always @(posedge CLK2) begin
  if(SNES_DEADr) begin
    drom_busy <= 1'b0;
    drom_ack  <= 1'b0;
    drom_cnt  <= 4'h0;
  end else begin
    drom_ack <= 1'b0;
    if(~drom_busy) begin
      if(drom_req & free_slot & ~(MCU_RD_PENDr | MCU_WR_PENDr)) begin
        drom_busy  <= 1'b1;
        drom_owner <= drom_sel_dcu;
        drom_addr  <= drom_sel_addr;
        drom_cnt   <= DROM_CYCLE_LEN;
      end
    end else begin
      drom_cnt  <= drom_cnt - 1'b1;
      drom_data <= drom_psram_addr[0] ? ROM_DATA[7:0] : ROM_DATA[15:8];
      if(drom_cnt == 0) begin
        drom_busy <= 1'b0;
        drom_ack  <= 1'b1;
      end
    end
  end
end

reg RQ_MCU_RDYr;
initial RQ_MCU_RDYr = 1'b1;
assign MCU_RDY = RQ_MCU_RDYr;

wire MCU_WE_HIT = |(STATE & ST_MCU_WR_ADDR);
wire MCU_WR_HIT = |(STATE & (ST_MCU_WR_ADDR | ST_MCU_WR_END));
wire MCU_RD_HIT = |(STATE & (ST_MCU_RD_ADDR | ST_MCU_RD_END));
wire MCU_HIT = MCU_WR_HIT | MCU_RD_HIT;

// final address to PSRAM where ROM and SRAM is stored
`ifdef MK2
DCM_Scope snes_dcm(
  .CLKIN_IN(CLKIN),
  .CLKFX_OUT(CLK2),
  .CLKDV_OUT(CLK_SCOPE),
  .CLKIN_IBUFG_OUT(clkin_rtc),
  .CLK0_OUT(),
  .LOCKED_OUT(DCM_LOCKED),
  .RST_IN(DCM_RST)
);
assign ROM_ADDR  = (SD_DMA_TO_ROM) ? MCU_ADDR[23:1]
            : MCU_HIT ? ROM_ADDRr[23:1] // keep the MCU above the chip so it can use the free slot during normal SNES accesses
            : drom_busy ? drom_psram_addr[23:1]
            : MAPPED_SNES_ADDR[23:1];


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

assign ROM_ADDR22 = (SD_DMA_TO_ROM) ? MCU_ADDR[1]
            : MCU_HIT ? ROM_ADDRr[1] // keep the MCU above the chip so it can use the free slot during normal SNES accesses
            : drom_busy ? drom_psram_addr[1]
            : MAPPED_SNES_ADDR[1];

assign ROM_ADDR  = (SD_DMA_TO_ROM) ? MCU_ADDR[23:2]
            : MCU_HIT ? ROM_ADDRr[23:2] // keep the MCU above the chip so it can use the free slot during normal SNES accesses
            : drom_busy ? drom_psram_addr[23:2]
            : MAPPED_SNES_ADDR[23:2];

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

// lower address bit to select [7:0] (ROM_ADDR0 = '1') or [15:8] (ROM_ADDR0 = '0') byte in the 16-bit word read from PSRAM
assign ROM_ADDR0 = (SD_DMA_TO_ROM) ? MCU_ADDR[0]
            : MCU_HIT ? ROM_ADDRr[0] // keep the MCU above the chip so it can use the free slot during normal SNES accesses
            : drom_busy ? drom_psram_addr[0]
            : MAPPED_SNES_ADDR[0];

reg[17:0] SNES_DEAD_CNTr;
initial SNES_DEAD_CNTr = 0;

// MCU r/w request
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
  // make sure the MCU doesn't touch the PSRAM while a DROM fetch owns the bus
      if((free_slot & ~drom_busy) | SNES_DEADr) begin
        if(MCU_RD_PENDr) begin
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
    // extend forced blanking when game goes from blanking to brightness 0
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

// data to write to PSRAM (ROM file at boot, backup RAM when game running).
// The chip itself never writes to PSRAM, it only reads (data ROM fetches), so the
// bus is tri-stated during a DROM access.
assign ROM_DATA[7:0] = ROM_ADDR0 ?
                // if ROM_ADDR[0] = '1'
                (SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                  : MCU_WR_HIT ? MCU_DOUT
                  // DROM fetch in flight: read only, never drive
                  : drom_busy ? 8'bZ
                  // if writing to ROM or backup RAM (both stored in PSRAM)
                  : (ROM_HIT & ~SNES_WRITE) ? SNES_DATA
                  : 8'bZ )
                // if ROM_ADDR[0] = '0'
                :8'bZ;

assign ROM_DATA[15:8] = ROM_ADDR0 ? 8'bZ
                  // if ROM_ADDR[0] = '0'
                  : (SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                  : MCU_WR_HIT ? MCU_DOUT
                  // DROM fetch in flight: read only, never drive
                  : drom_busy ? 8'bZ
                  // if writing to ROM or backup RAM (both stored in PSRAM)
                  : (ROM_HIT & ~SNES_WRITE) ? SNES_DATA
                           : 8'bZ );


// write enable for PSRAM
assign ROM_WE = SD_DMA_TO_ROM ? MCU_WRITE
      : MCU_WE_HIT ? 1'b0
           : drom_busy ? 1'b1
           : (ROM_HIT & IS_WRITABLE & SNES_CPU_CLK) ? SNES_WRITE
           : 1'b1;

// byte selector for PSRAM output.  DROM fetches are one byte per transaction, so
// they use the same byte select as every other access.
// '0' when accessing high byte
assign ROM_BHE = ROM_ADDR0;
// '0' when accessing low byte
assign ROM_BLE = !ROM_ADDR0;

// active low signal to enable level converters' output; it enables output in both sides of the chip
assign SNES_DATABUS_OE = msu_enable & ~(SNES_READ_narrow & SNES_WRITE) ? 1'b0 :
                         snescmd_enable & ~(SNES_READ_narrow & SNES_WRITE) ? ~(snescmd_unlock | feat_cmd_unlock) :
                         spc7110_reg_enable ? 1'b0 :
                         (r213f_enable & ~SNES_PARD) ? 1'b0 :
                         (r2100_enable & ~SNES_PAWR) ? 1'b0 :
                         snoop_4200_enable ? SNES_WRITE :
                         ((IS_ROM & SNES_ROMSEL) | (!IS_ROM & !IS_SAVERAM & !IS_WRITABLE) | (SNES_READ_narrow & SNES_WRITE)
                         );

/* data bus direction: 0 = SNES -> FPGA; 1 = FPGA -> SNES
 * data bus is always SNES -> FPGA to avoid fighting except when:
 *  a) the SNES wants to read
 *  b) we want to force a value on the bus
 */
assign SNES_DATABUS_DIR = (~SNES_READ | (~SNES_PARD & (r213f_enable))) ?
              (1'b1 ^ (r213f_forceread & r213f_enable & ~SNES_PARD)
                  ^ (r2100_enable & ~SNES_PAWR & ~r2100_forcewrite & ~IS_ROM & ~IS_WRITABLE))
                           : ((~SNES_PAWR & r2100_enable) ? r2100_forcewrite
                           : 1'b0);

assign SNES_IRQ = 1'b0;

endmodule

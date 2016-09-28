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

  input [7:0] SNES_PA,
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

assign DAC_MCLK = 0;
assign DAC_LRCK = 0;
assign DAC_SDOUT = 0;

wire CLK2;

wire [7:0] spi_cmd_data;
wire [7:0] spi_param_data;
wire [7:0] spi_input_data;
wire [31:0] spi_byte_cnt;
wire [2:0] spi_bit_cnt;
wire [23:0] MCU_ADDR;
wire [23:0] SAVERAM_MASK;
wire [23:0] ROM_MASK;

wire [23:0] MAPPED_SNES_ADDR;
wire ROM_ADDR0;


assign DCM_RST=0;

reg [7:0] SNES_PARDr;
reg [7:0] SNES_READr;
reg [7:0] SNES_WRITEr;
reg [7:0] SNES_CPU_CLKr;
reg [7:0] SNES_ROMSELr;
reg [23:0] SNES_ADDRr [5:0];

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

wire SNES_ROMSEL = (SNES_ROMSELr[5] & SNES_ROMSELr[4]);
wire [23:0] SNES_ADDR = (SNES_ADDRr[5] & SNES_ADDRr[4]);

wire free_slot = SNES_cycle_end | free_strobe;

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
  SNES_ROMSELr <= {SNES_ROMSELr[6:0], SNES_ROMSEL_IN};
  SNES_ADDRr[5] <= SNES_ADDRr[4];
  SNES_ADDRr[4] <= SNES_ADDRr[3];
  SNES_ADDRr[3] <= SNES_ADDRr[2];
  SNES_ADDRr[2] <= SNES_ADDRr[1];
  SNES_ADDRr[1] <= SNES_ADDRr[0];
  SNES_ADDRr[0] <= SNES_ADDR_IN;
end


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
  .input_data(spi_input_data),
  .byte_cnt(spi_byte_cnt),
  .bit_cnt(spi_bit_cnt)
);

reg [7:0] MCU_DINr;
wire [7:0] MCU_DOUT;

mcu_cmd snes_mcu_cmd(
  .clk(CLK2),
  .cmd_ready(spi_cmd_ready),
  .param_ready(spi_param_ready),
  .cmd_data(spi_cmd_data),
  .param_data(spi_param_data),
  .mcu_data_in(MCU_DINr),
  .mcu_data_out(MCU_DOUT),
  .spi_byte_cnt(spi_byte_cnt),
  .spi_bit_cnt(spi_bit_cnt),
  .spi_data_out(spi_input_data),
  .addr_out(MCU_ADDR),
  .saveram_mask_out(SAVERAM_MASK),
  .rom_mask_out(ROM_MASK),
  .mcu_rrq(MCU_RRQ),
  .mcu_wrq(MCU_WRQ),
  .mcu_rq_rdy(MCU_RDY)
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
  .SNES_ADDR(SNES_ADDR), // requested address from SNES
  .ROM_ADDR(MAPPED_SNES_ADDR),   // Address to request from SRAM (active low)
  .ROM_HIT(ROM_HIT),
  .IS_SAVERAM(IS_SAVERAM),
  .IS_ROM(IS_ROM),
  .SAVERAM_MASK(SAVERAM_MASK),
  .ROM_MASK(ROM_MASK)
);

parameter ST_IDLE        = 5'b00001;
parameter ST_MCU_RD_ADDR = 5'b00010;
parameter ST_MCU_RD_END  = 5'b00100;
parameter ST_MCU_WR_ADDR = 5'b01000;
parameter ST_MCU_WR_END  = 5'b10000;

parameter SNES_DEAD_TIMEOUT = 17'd96000; // 1ms

parameter ROM_CYCLE_LEN = 4'd8; // ideally 70ns but close enough...

reg [4:0] STATE;
initial STATE = ST_IDLE;

assign SNES_DATA = ~SNES_READ ? (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8])
             : 8'bZ;

reg [3:0] ST_MEM_DELAYr;
reg MCU_RD_PENDr = 0;
reg MCU_WR_PENDr = 0;
reg [23:0] ROM_ADDRr;

reg RQ_MCU_RDYr;
initial RQ_MCU_RDYr = 1'b1;
assign MCU_RDY = RQ_MCU_RDYr;

wire MCU_WR_HIT = |(STATE & ST_MCU_WR_ADDR);
wire MCU_RD_HIT = |(STATE & ST_MCU_RD_ADDR);
wire MCU_HIT = MCU_WR_HIT | MCU_RD_HIT;

assign ROM_ADDR  = MCU_HIT ? ROM_ADDRr[23:1] : MAPPED_SNES_ADDR[23:1];
assign ROM_ADDR0 = MCU_HIT ? ROM_ADDRr[0] : MAPPED_SNES_ADDR[0];

reg ROM_WEr;
initial ROM_WEr = 1'b1;
reg ROM_DOUT_ENr;
initial ROM_DOUT_ENr = 1'b0;

reg[17:0] SNES_DEAD_CNTr;
initial SNES_DEAD_CNTr = 0;

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
  if(SNES_CPU_CLKr[1]) SNES_DEADr <= 1'b0;
  else if(SNES_DEAD_CNTr > SNES_DEAD_TIMEOUT) SNES_DEADr <= 1'b1;
end

always @(posedge CLK2) begin
  if(SNES_DEADr & SNES_CPU_CLKr[1]) STATE <= ST_IDLE; // interrupt+restart an ongoing MCU access when the SNES comes alive
  else
  case(STATE)
    ST_IDLE: begin
      STATE <= ST_IDLE;
      if(free_slot | SNES_DEADr) begin
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

assign ROM_DATA[7:0] = ROM_ADDR0
                       ?((ROM_HIT & ~SNES_WRITE) ? SNES_DATA
                        : MCU_WR_HIT ? MCU_DOUT : 8'bZ
                        )
                       :8'bZ;

assign ROM_DATA[15:8] = ROM_ADDR0 ? 8'bZ
                        :((ROM_HIT & ~SNES_WRITE) ? SNES_DATA
                         : MCU_WR_HIT ? MCU_DOUT
                         : 8'bZ
                         );

assign ROM_WE = (ROM_HIT & IS_SAVERAM & SNES_CPU_CLK) ? SNES_WRITE
                : MCU_WR_HIT ? 1'b0
                : 1'b1;

// OE always active. Overridden by WE when needed.
assign ROM_OE = 1'b0;

assign ROM_CE = 1'b0;

assign ROM_BHE = ROM_ADDR0;
assign ROM_BLE = ~ROM_ADDR0;

assign SNES_DATABUS_OE = ((IS_ROM & SNES_ROMSEL)
                          |(!IS_ROM & !IS_SAVERAM)
                          |(SNES_READr[0] & SNES_WRITEr[0])
                         );

assign SNES_DATABUS_DIR = (!SNES_READr[0])
                           ? 1'b1
                           : 1'b0;

assign SNES_IRQ = 1'b0;

assign p113_out = 1'b0;

/*
wire [35:0] CONTROL0;

icon icon (
    .CONTROL0(CONTROL0) // INOUT BUS [35:0]
);

ila_srtc ila (
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

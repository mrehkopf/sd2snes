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
  input SNES_READ,
  input SNES_WRITE,
  input SNES_CS,
  inout [7:0] SNES_DATA,
  input SNES_CPU_CLK,
  input SNES_REFRESH,
  output SNES_IRQ,
  output SNES_DATABUS_OE,
  output SNES_DATABUS_DIR,
  input SNES_SYSCLK,

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

reg [23:0] SNES_ADDR_r [2:0];
always @(posedge CLK2) begin
  SNES_ADDR_r[2] <= SNES_ADDR_r[1];
  SNES_ADDR_r[1] <= SNES_ADDR_r[0];
  SNES_ADDR_r[0] <= SNES_ADDR_IN;
end
wire [23:0] SNES_ADDR = SNES_ADDR_r[2] & SNES_ADDR_r[1];

wire [7:0] spi_cmd_data;
wire [7:0] spi_param_data;
wire [7:0] spi_input_data;
wire [31:0] spi_byte_cnt;
wire [2:0] spi_bit_cnt;
wire [23:0] MCU_ADDR;
wire [7:0] mcu_data_in;
wire [7:0] mcu_data_out;
wire [23:0] SAVERAM_MASK;
wire [23:0] ROM_MASK;

wire [23:0] MAPPED_SNES_ADDR;
wire ROM_ADDR0;

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
  .mcu_write(MCU_WRITE),
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

assign DCM_RST=0;

reg [7:0] SNES_PARDr;
reg [7:0] SNES_PAWRr;
reg [7:0] SNES_READr;
reg [7:0] SNES_WRITEr;
reg [7:0] SNES_CPU_CLKr;

wire SNES_FAKE_CLK = &SNES_CPU_CLKr[2:1];
//wire SNES_FAKE_CLK = ~(SNES_READ & SNES_WRITE);

reg SNES_DEADr;
initial SNES_DEADr = 0;

wire SNES_PARD_start = (SNES_PARDr[7:1] == 7'b1111110);
wire SNES_PAWR_start = (SNES_PAWRr[7:1] == 7'b0000001);
wire SNES_RD_start = (SNES_READr[7:1] == 7'b1111110);
wire SNES_WR_start = (SNES_WRITEr[7:1] == 7'b1111110);
wire SNES_WR_end = (SNES_WRITEr[7:1] == 7'b0000001);
wire SNES_cycle_start = ((SNES_CPU_CLKr[7:2] & SNES_CPU_CLKr[6:1]) == 6'b000001);
wire SNES_cycle_end = ((SNES_CPU_CLKr[7:2] & SNES_CPU_CLKr[6:1]) == 6'b111110);

always @(posedge CLK2) begin
  SNES_PARDr <= {SNES_PARDr[6:0], SNES_PARD};
end

always @(posedge CLK2) begin
  SNES_PAWRr <= {SNES_PAWRr[6:0], SNES_PAWR};
  SNES_READr <= {SNES_READr[6:0], SNES_READ};
  SNES_WRITEr <= {SNES_WRITEr[6:0], SNES_WRITE};
  SNES_CPU_CLKr <= {SNES_CPU_CLKr[6:0], SNES_CPU_CLK};
end

address snes_addr(
  .CLK(CLK2),
  .SNES_ADDR(SNES_ADDR), // requested address from SNES
  .SNES_CS(SNES_CS),     // "CART" pin from SNES (active low)
  .ROM_ADDR(MAPPED_SNES_ADDR),   // Address to request from SRAM (active low)
  .IS_SAVERAM(IS_SAVERAM),
  .IS_ROM(IS_ROM),
  .SAVERAM_MASK(SAVERAM_MASK),
  .ROM_MASK(ROM_MASK)
);

wire SNES_READ_CYCLEw;
wire SNES_WRITE_CYCLEw;
wire MCU_READ_CYCLEw;
wire MCU_WRITE_CYCLEw;

parameter MODE_SNES = 1'b0;
parameter MODE_MCU = 1'b1;

parameter ST_IDLE         = 18'b000000000000000001;
parameter ST_SNES_RD_ADDR = 18'b000000000000000010;
parameter ST_SNES_RD_WAIT = 18'b000000000000000100;
parameter ST_SNES_RD_END  = 18'b000000000000001000;
parameter ST_SNES_WR_ADDR = 18'b000000000000010000;
parameter ST_SNES_WR_WAIT1= 18'b000000000000100000;
parameter ST_SNES_WR_DATA = 18'b000000000001000000;
parameter ST_SNES_WR_WAIT2= 18'b000000000010000000;
parameter ST_SNES_WR_END  = 18'b000000000100000000;
parameter ST_MCU_RD_ADDR  = 18'b000000001000000000;
parameter ST_MCU_RD_WAIT  = 18'b000000010000000000;
parameter ST_MCU_RD_WAIT2 = 18'b000000100000000000;
parameter ST_MCU_RD_END   = 18'b000001000000000000;
parameter ST_MCU_WR_ADDR  = 18'b000010000000000000;
parameter ST_MCU_WR_WAIT  = 18'b000100000000000000;
parameter ST_MCU_WR_WAIT2 = 18'b001000000000000000;
parameter ST_MCU_WR_END   = 18'b010000000000000000;

parameter ROM_RD_WAIT = 4'h4;
parameter ROM_RD_WAIT_MCU = 4'h6;
parameter ROM_WR_WAIT1 = 4'h2;
parameter ROM_WR_WAIT2 = 4'h3;
parameter ROM_WR_WAIT_MCU = 4'h6;

reg [17:0] STATE;
initial STATE = ST_IDLE;

reg [1:0] CYCLE_RESET;
reg ROM_WE_MASK;
reg ROM_OE_MASK;

reg [7:0] SNES_DINr;
reg [7:0] ROM_DOUTr;

assign SNES_DATA = (!SNES_READ) ? SNES_DINr : 8'bZ;

reg [3:0] ST_MEM_DELAYr;
reg MCU_RD_PENDr;
reg MCU_WR_PENDr;
reg [23:0] ROM_ADDRr;
reg NEED_SNES_ADDRr;
always @(posedge CLK2) begin
  if(SNES_cycle_end) NEED_SNES_ADDRr <= 1'b1;
  else if(STATE & (ST_SNES_RD_END | ST_SNES_WR_END)) NEED_SNES_ADDRr <= 1'b0;
end

reg RQ_MCU_RDYr;
initial RQ_MCU_RDYr = 1'b1;
assign MCU_RDY = RQ_MCU_RDYr;

reg ROM_SAr;
initial ROM_SAr = 1'b1;
//wire ROM_SA = SNES_FAKE_CLK | ((STATE == ST_IDLE) ^ (~RQ_MCU_RDYr & SNES_cycle_end));
wire ROM_SA = ROM_SAr;

assign ROM_ADDR  = (ROM_SA) ? MAPPED_SNES_ADDR[23:1] : ROM_ADDRr[23:1];
assign ROM_ADDR0 = (ROM_SA) ? MAPPED_SNES_ADDR[0] : ROM_ADDRr[0];

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
  if(~SNES_CPU_CLK) SNES_DEAD_CNTr <= SNES_DEAD_CNTr + 1;
  else SNES_DEAD_CNTr <= 17'h0;
end

always @(posedge CLK2) begin
  if(SNES_DEAD_CNTr > SNES_DEAD_TIMEOUT) SNES_DEADr <= 1'b1;
  else if(SNES_CPU_CLK) SNES_DEADr <= 1'b0;
end

reg snes_wr_cycle;

always @(posedge CLK2) begin
  if(SNES_DEADr & SNES_CPU_CLK) STATE <= ST_IDLE; // interrupt+restart an ongoing MCU access when the SNES comes alive
  else
  case(STATE)
    ST_IDLE: begin
	   ROM_SAr <= 1'b1;
		ROM_DOUT_ENr <= 1'b0;
	   if(SNES_cycle_start & ~SNES_WRITE) begin
		  STATE <= ST_SNES_WR_ADDR;
		  if(IS_SAVERAM) begin
		    ROM_WEr <= 1'b0;
          ROM_DOUT_ENr <= 1'b1;
        end
		end else if(SNES_cycle_start) begin
//		  STATE <= ST_SNES_RD_ADDR;		  
        STATE <= ST_SNES_RD_END;
        SNES_DOUTr <= (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8]);
		end else if(SNES_DEADr & MCU_RD_PENDr) begin
		  STATE <= ST_MCU_RD_ADDR;
		end else if(SNES_DEADr & MCU_WR_PENDr) begin
		  STATE <= ST_MCU_WR_ADDR;
		end
	 end
	 ST_SNES_RD_ADDR: begin
	   ST_MEM_DELAYr <= ROM_RD_WAIT;
		STATE <= ST_SNES_RD_WAIT;
	 end
	 ST_SNES_RD_WAIT: begin
	   ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
//		if(ST_MEM_DELAYr == 0) begin
//		end
//		else STATE <= ST_SNES_RD_WAIT;
	 end
	 
	 ST_SNES_WR_ADDR: begin
	   ST_MEM_DELAYr <= ROM_WR_WAIT1;
	   STATE <= ST_SNES_WR_WAIT1;
	 end
	 ST_SNES_WR_WAIT1: begin
	   ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
		if(ST_MEM_DELAYr == 0) begin
		  ST_MEM_DELAYr <= ROM_WR_WAIT2;
        STATE <= ST_SNES_WR_WAIT2;
		  ROM_DOUTr <= SNES_DATA;
		end
		else STATE <= ST_SNES_WR_WAIT1;
	 end
	 ST_SNES_WR_WAIT2: begin
	   ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
		if(ST_MEM_DELAYr == 0) begin
        STATE <= ST_SNES_WR_END;
		  ROM_WEr <= 1'b1;
		end
		else STATE <= ST_SNES_WR_WAIT2;
    end
	 ST_SNES_RD_END, ST_SNES_WR_END: begin
	   ROM_DOUT_ENr <= 1'b0;		
      if(MCU_RD_PENDr) begin
        STATE <= ST_MCU_RD_ADDR;
      end else if(MCU_WR_PENDr) begin
        STATE <= ST_MCU_WR_ADDR;
      end else STATE <= ST_IDLE;
    end
    ST_MCU_RD_ADDR: begin
      ROM_SAr <= 1'b0;
		ST_MEM_DELAYr <= ROM_RD_WAIT_MCU;
		STATE <= ST_MCU_RD_WAIT;
	 end
	 ST_MCU_RD_WAIT: begin
	   ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
		if(ST_MEM_DELAYr == 0) begin
        STATE <= ST_MCU_RD_END;
		end
		else STATE <= ST_MCU_RD_WAIT;
	 end
	 ST_MCU_RD_END: begin
      MCU_DINr <= ROM_ADDRr[0] ? ROM_DATA[7:0] : ROM_DATA[15:8];
	   STATE <= ST_IDLE;
	 end
	 
	 ST_MCU_WR_ADDR: begin
      ROM_DOUTr <= MCU_DOUT;
      ROM_SAr <= 1'b0;
	   ST_MEM_DELAYr <= ROM_WR_WAIT_MCU;
		STATE <= ST_MCU_WR_WAIT;
		ROM_DOUT_ENr <= 1'b1;
		ROM_WEr <= 1'b0;
	 end
	 ST_MCU_WR_WAIT: begin
	   ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
		if(ST_MEM_DELAYr == 0) begin
		  ROM_WEr <= 1'b1;
		  STATE <= ST_MCU_WR_END;
		end
		else STATE <= ST_MCU_WR_WAIT;	 
	 end
	 ST_MCU_WR_END: begin
		ROM_DOUT_ENr <= 1'b0;
	   STATE <= ST_IDLE;
	 end
  endcase
end

reg ROM_WE_1;

always @(posedge CLK2) begin
  ROM_WE_1 <= ROM_WE;
end

assign ROM_DATA[7:0] = ROM_ADDR0
                       ?(ROM_DOUT_ENr ? ROM_DOUTr : 8'bZ)
                       :8'bZ;

assign ROM_DATA[15:8] = ROM_ADDR0 ? 8'bZ
                        :(ROM_DOUT_ENr ? ROM_DOUTr : 8'bZ);

assign ROM_WE = ROM_WEr;

// OE always active. Overridden by WE when needed.
assign ROM_OE = 1'b0;

assign ROM_CE = 1'b0;

assign ROM_BHE = /*(~SD_DMA_TO_ROM & ~ROM_WE & ~ROM_SA) ?*/ ROM_ADDR0 /*: 1'b0*/;
assign ROM_BLE = /*(~SD_DMA_TO_ROM & ~ROM_WE & ~ROM_SA) ?*/ !ROM_ADDR0 /*: 1'b0*/;

assign SNES_DATABUS_OE = ((IS_ROM & SNES_CS)
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
    .TRIG2({SNES_READ, SNES_WRITE, SNES_CPU_CLK, SNES_cycle_start, SNES_cycle_end, SNES_DEADr, MCU_RRQ, MCU_WRQ, MCU_RDY, ROM_WEr, ROM_WE, ROM_DOUT_ENr, ROM_SA, DBG_mcu_nextaddr, SNES_DATABUS_DIR, SNES_DATABUS_OE}),	 // IN BUS [15:0]
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
    .TRIG2({SPI_SCK, SPI_MOSI, SPI_MISO, spi_cmd_ready, SD_DMA_SRAM_WE, SD_DMA_EN, SD_CLK, SD_DAT, SD_DMA_NEXTADDR, SD_DMA_STATUS, 3'b000}),	 // IN BUS [15:0]
    .TRIG3({spi_cmd_data, spi_param_data}), // IN BUS [17:0]
    .TRIG4(ROM_ADDRr), // IN BUS [23:0]
    .TRIG5(ROM_DATA), // IN BUS [15:0]
    .TRIG6(MCU_DINr), // IN BUS [7:0]
	 .TRIG7(ST_MEM_DELAYr)
);
*/

endmodule

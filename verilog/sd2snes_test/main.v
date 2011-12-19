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
  input [23:0] SNES_ADDR,
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

  input [7:0] SNES_PA,
  input SNES_PARD,
  input SNES_PAWR,
  
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

wire [31:0] snes_sysclk_freq;
wire [31:0] snes_read_freq;
wire [31:0] snes_write_freq;
wire [31:0] snes_pard_freq;
wire [31:0] snes_pawr_freq;
wire [31:0] snes_refresh_freq;
wire [31:0] snes_cpuclk_freq;
wire [31:0] snes_romsel_freq;

clk_test snes_clk_test (
    .clk(CLK2),
    .sysclk(SNES_SYSCLK),
    .read(SNES_READ),
    .write(SNES_WRITE),
    .pard(SNES_PARD),
    .pawr(SNES_PAWR),
    .refresh(SNES_REFRESH),
    .cpuclk(SNES_CPU_CLK),
    .romsel(SNES_CS),
    .snes_sysclk_freq(snes_sysclk_freq),
    .snes_read_freq(snes_read_freq),
    .snes_write_freq(snes_write_freq),
    .snes_pard_freq(snes_pard_freq),
    .snes_pawr_freq(snes_pawr_freq),
    .snes_refresh_freq(snes_refresh_freq),
    .snes_cpuclk_freq(snes_cpuclk_freq),
    .snes_romsel_freq(snes_romsel_freq)
);

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

wire [23:0] ram0_addr;
wire [18:0] ram1_addr;
wire [7:0] PA_addr;
wire [12:0] bram_addr;
wire ROM_ADDR0;

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
  .SD_DMA_PARTIAL_END(SD_DMA_PARTIAL_END)
);

wire SD_DMA_TO_ROM = (SD_DMA_STATUS && (SD_DMA_TGT == 2'b00));

dac snes_dac(
  .clkin(CLK2),
  .sysclk(SNES_SYSCLK),
  .mclk(DAC_MCLK),
  .lrck(DAC_LRCK),
  .sdout(DAC_SDOUT),
  .we(SD_DMA_TGT==2'b01 ? SD_DMA_SRAM_WE : 1'b1),
  .pgm_address(dac_addr),
  .pgm_data(SD_DMA_SRAM_DATA),
  .DAC_STATUS(DAC_STATUS),
  .play(dac_play),
  .reset(dac_reset)
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

wire [7:0] mcu_bram_data_in;
wire [7:0] mcu_bram_data_out;
wire [12:0] mcu_bram_addr;

mcu_cmd snes_mcu_cmd(
  .clk(CLK2),
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
  .dac_addr_out(dac_addr),
  .DAC_STATUS(DAC_STATUS),
//  .dac_volume_out(dac_volume),
//  .dac_volume_latch_out(dac_vol_latch),
  .dac_play_out(dac_play),
  .dac_reset_out(dac_reset),
  .featurebits_out(featurebits),
  .mcu_rrq(MCU_RRQ),
  .mcu_wrq(MCU_WRQ),
  .mcu_rq_rdy(MCU_RDY),
  .ramsel_out(MCU_RAMSEL),
  .snes_sysclk_freq(snes_sysclk_freq),
  .snes_read_freq(snes_read_freq),
  .snes_write_freq(snes_write_freq),
  .snes_pard_freq(snes_pard_freq),
  .snes_pawr_freq(snes_pawr_freq),
  .snes_refresh_freq(snes_refresh_freq),
  .snes_cpuclk_freq(snes_cpuclk_freq),
  .snes_romsel_freq(snes_romsel_freq),
  .mcu_bram_addr(mcu_bram_addr),
  .mcu_bram_data_in(mcu_bram_data_in),
  .mcu_bram_data_out(mcu_bram_data_out),
  .mcu_bram_we(mcu_bram_we)
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

reg [5:0] SNES_READr;
reg [5:0] SNES_WRITEr;
reg [5:0] SNES_CPU_CLKr;

wire SNES_RD_start = (SNES_READr == 6'b111110);
wire SNES_WR_start = (SNES_WRITEr == 6'b111110);
wire SNES_WR_rising = (SNES_WRITEr == 6'b000001);
wire SNES_cycle_start = (SNES_CPU_CLKr[5:0] == 6'b000001);
wire SNES_cycle_end = (SNES_CPU_CLKr[5:0] == 6'b111110);

always @(posedge CLK2) begin
  SNES_READr <= {SNES_READr[4:0], SNES_READ};
  SNES_WRITEr <= {SNES_WRITEr[4:0], SNES_WRITE};
  SNES_CPU_CLKr <= {SNES_CPU_CLKr[4:0], SNES_CPU_CLK};
end

reg [7:0] ram0_bank;
initial ram0_bank = 8'h00;
reg ram0_linear;
initial ram0_linear = 1'b0;

address snes_addr(
  .CLK(CLK2),
  .SNES_ADDR(SNES_ADDR), // requested address from SNES
  .ram0_addr(ram0_addr),   // Address to request from SRAM (active low)
  .ram1_addr(ram1_addr),
  .PA_addr(PA_addr),
  .bram_addr(bram_addr),
  .ram0_enable(ram0_enable),
  .ram1_enable(ram1_enable),
  .PA_enable(PA_enable),
  .bram_enable(bram_enable),
  .ram0_bank(ram0_bank),
  .ram0_linear(ram0_linear),
  .irq_enable(irq_enable),
  .bank_enable(bank_enable),
  .linear_enable(linear_enable)
);

always @(posedge CLK2) begin
  if(SNES_WR_rising && bank_enable) ram0_bank <= SNES_DATA;
end

always @(posedge CLK2) begin
  if(SNES_WR_rising && linear_enable) ram0_linear <= SNES_DATA[0];
end

reg [7:0] irq_count_r;
initial irq_count_r = 8'b0;
reg SNES_IRQr;
initial SNES_IRQr = 0;

always @(posedge CLK2) begin
  if(SNES_WR_rising & irq_enable) SNES_IRQr <= 1'b1;
  else if(irq_count_r == 8'h00) SNES_IRQr <= 1'b0;
end

always @(posedge CLK2) begin
  if(SNES_WR_rising & irq_enable) irq_count_r <= 8'h01;
  else irq_count_r <= irq_count_r + 1;
end


wire [7:0] bram_data_out;
bram test_bram (
  .clka(CLK2), // input clka
  .wea(~SNES_WRITE & bram_enable), // input [0 : 0] wea
  .addra(bram_addr), // input [12 : 0] addra
  .dina(SNES_DATA), // input [7 : 0] dina
  .douta(bram_data_out), // output [7 : 0] douta
  .clkb(CLK2), // input clkb
  .web(mcu_bram_we), // input [0 : 0] web
  .addrb(mcu_bram_addr), // input [12 : 0] addrb
  .dinb(mcu_bram_data_out), // input [7 : 0] dinb
  .doutb(mcu_bram_data_in) // output [7 : 0] doutb
);
reg [1:0] SNES_PAWR_start_r;
always @(posedge CLK2) SNES_PAWR_start_r <= {SNES_PAWR_start_r[0], SNES_PAWR};
wire SNES_PAWR_start = (SNES_PAWR_start_r == 2'b01);
wire [7:0] PA_data_out;
PA test_PA (
  .clka(CLK2), // input clka
  .wea(SNES_PAWR_start), // input [0 : 0] wea
  .addra(SNES_PA), // input [7 : 0] addra
  .dina(SNES_DATA), // input [7 : 0] dina
  .clkb(CLK2), // input clkb
  .addrb(PA_addr), // input [7 : 0] addrb
  .doutb(PA_data_out) // output [7 : 0] doutb
);

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

reg [7:0] SNES_DINr;
reg [7:0] ROM_DOUTr;
reg [7:0] RAM_DOUTr;

assign SNES_DATA = (!SNES_READ) ? (ram0_enable ? SNES_DINr
                                  :ram1_enable ? SNES_DINr
                                  :bram_enable ? bram_data_out
                                  :PA_enable ? PA_data_out
                                  :SNES_DINr /*(ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8])*/) : 8'bZ;

reg [3:0] ST_MEM_DELAYr;
reg MCU_RD_PENDr;
reg MCU_WR_PENDr;
reg [23:0] ROM_ADDRr;
reg [18:0] RAM_ADDRr;
reg NEED_SNES_ADDRr;
always @(posedge CLK2) begin
  if(SNES_cycle_end) NEED_SNES_ADDRr <= 1'b1;
  else if(STATE & (ST_SNES_RD_END | ST_SNES_WR_END)) NEED_SNES_ADDRr <= 1'b0;
end

wire ASSERT_SNES_ADDR = SNES_CPU_CLK & NEED_SNES_ADDRr;

assign ROM_ADDR  = (SD_DMA_TO_ROM) ? MCU_ADDR[23:1] : (ASSERT_SNES_ADDR) ? ram0_addr[23:1] : ROM_ADDRr[23:1];
assign ROM_ADDR0 = (SD_DMA_TO_ROM) ? MCU_ADDR[0] : (ASSERT_SNES_ADDR) ? ram0_addr[0] : ROM_ADDRr[0];

assign RAM_ADDR = ASSERT_SNES_ADDR ? ram1_addr : RAM_ADDRr;

reg ROM_WEr;
initial ROM_WEr = 1'b1;

reg RAM_WEr;
initial RAM_WEr = 1'b1;

reg RQ_MCU_RDYr;
initial RQ_MCU_RDYr = 1'b1;
assign MCU_RDY = RQ_MCU_RDYr;

always @(posedge CLK2) begin
  if(MCU_RRQ) begin
    MCU_RD_PENDr <= 1'b1;
    RQ_MCU_RDYr <= 1'b0;
  end else if(MCU_WRQ) begin
    MCU_WR_PENDr <= 1'b1;
    RQ_MCU_RDYr <= 1'b0;
  end else if(STATE & (ST_MCU_RD_END | ST_MCU_WR_END)) begin
    MCU_RD_PENDr <= 1'b0;
    MCU_WR_PENDr <= 1'b0;
    RQ_MCU_RDYr <= 1'b1;
  end
end

reg snes_wr_cycle;
wire ram_enable = ram0_enable | ram1_enable;
always @(posedge CLK2) begin
  if(ram_enable & SNES_cycle_start & ~SNES_WR_start) begin
    STATE <= ST_SNES_RD_ADDR;
  end else if(ram_enable & SNES_WR_start) begin
    snes_wr_cycle <= 1'b1;
    STATE <= ST_SNES_WR_ADDR;
  end else begin
    case(STATE)
	    ST_IDLE: begin
        if(ram0_enable) ROM_ADDRr <= ram0_addr;
        if(ram1_enable) RAM_ADDRr <= ram1_addr;
        if(MCU_RD_PENDr) STATE <= ST_MCU_RD_ADDR;
        else if(MCU_WR_PENDr) STATE <= ST_MCU_WR_ADDR;
        else STATE <= ST_IDLE;
      end
      ST_SNES_RD_ADDR: begin
        STATE <= ST_SNES_RD_WAIT;
        ST_MEM_DELAYr <= ROM_RD_WAIT;
      end
      ST_SNES_RD_WAIT: begin
        ST_MEM_DELAYr <= ST_MEM_DELAYr - 4'h1;
        if(ST_MEM_DELAYr == 4'h0) STATE <= ST_SNES_RD_END;
        else STATE <= ST_SNES_RD_WAIT;
        if(ram0_enable) begin
          if(ROM_ADDR0) SNES_DINr <= ROM_DATA[7:0];
          else SNES_DINr <= ROM_DATA[15:8];
        end else if(ram1_enable) begin
          SNES_DINr <= RAM_DATA[7:0];
        end
      end
      ST_SNES_RD_END: begin
        STATE <= ST_IDLE;
        if(ram0_enable) begin
          if(ROM_ADDR0) SNES_DINr <= ROM_DATA[7:0];
          else SNES_DINr <= ROM_DATA[15:8];
        end else if(ram1_enable) begin
          SNES_DINr <= RAM_DATA[7:0];
        end
      end
      ST_SNES_WR_ADDR: begin
        if(ram0_enable) ROM_WEr <= 1'b0;
        if(ram1_enable) RAM_WEr <= 1'b0;
        STATE <= ST_SNES_WR_WAIT1;
        ST_MEM_DELAYr <= ROM_WR_WAIT1;
      end
      ST_SNES_WR_WAIT1: begin
        ST_MEM_DELAYr <= ST_MEM_DELAYr - 4'h1;
        if(ST_MEM_DELAYr == 4'h0) STATE <= ST_SNES_WR_DATA;
        else STATE <= ST_SNES_WR_WAIT1;
      end
      ST_SNES_WR_DATA: begin
        if(ram0_enable) ROM_DOUTr <= SNES_DATA;
        if(ram1_enable) RAM_DOUTr <= SNES_DATA;
        ST_MEM_DELAYr <= ROM_WR_WAIT2;
        STATE <= ST_SNES_WR_WAIT2;
      end
        ST_SNES_WR_WAIT2: begin
        ST_MEM_DELAYr <= ST_MEM_DELAYr - 4'h1;
        if(ST_MEM_DELAYr == 4'h0) STATE <= ST_SNES_WR_END;
        else STATE <= ST_SNES_WR_WAIT2;
      end
      ST_SNES_WR_END: begin
        STATE <= ST_IDLE;
        ROM_WEr <= 1'b1;
        RAM_WEr <= 1'b1;
        snes_wr_cycle <= 1'b0;
      end
      ST_MCU_RD_ADDR: begin
        if(MCU_RAMSEL == 1'b0) ROM_ADDRr <= MCU_ADDR;
        else RAM_ADDRr <= MCU_ADDR;
        STATE <= ST_MCU_RD_WAIT;
        ST_MEM_DELAYr <= ROM_RD_WAIT_MCU;
      end
      ST_MCU_RD_WAIT: begin
        ST_MEM_DELAYr <= ST_MEM_DELAYr - 4'h1;
        if(ST_MEM_DELAYr == 4'h0) begin
          STATE <= ST_MCU_RD_WAIT2;
          ST_MEM_DELAYr <= 4'h2;
        end
        else STATE <= ST_MCU_RD_WAIT;
        if(MCU_RAMSEL == 1'b0) begin
          if(ROM_ADDR0) MCU_DINr <= ROM_DATA[7:0];
          else MCU_DINr <= ROM_DATA[15:8];
        end else MCU_DINr <= RAM_DATA;
      end
      ST_MCU_RD_WAIT2: begin
        ST_MEM_DELAYr <= ST_MEM_DELAYr - 4'h1;
        if(ST_MEM_DELAYr == 4'h0) begin
          STATE <= ST_MCU_RD_END;
        end else STATE <= ST_MCU_RD_WAIT2;
      end
      ST_MCU_RD_END: begin
        STATE <= ST_IDLE;
      end
      ST_MCU_WR_ADDR: begin
        if(MCU_RAMSEL == 1'b0) ROM_ADDRr <= MCU_ADDR;
        else RAM_ADDRr <= MCU_ADDR;
        STATE <= ST_MCU_WR_WAIT;
        ST_MEM_DELAYr <= ROM_WR_WAIT_MCU;
        if(MCU_RAMSEL == 1'b0) ROM_DOUTr <= MCU_DOUT;
        else RAM_DOUTr <= MCU_DOUT;
        if(MCU_RAMSEL == 1'b0)
          ROM_WEr <= 1'b0;
        else if(MCU_RAMSEL == 1'b1)
          RAM_WEr <= 1'b0;
      end
      ST_MCU_WR_WAIT: begin
        ST_MEM_DELAYr <= ST_MEM_DELAYr - 4'h1;
        if(ST_MEM_DELAYr == 4'h0) begin
          ROM_WEr <= 1'b1;
          RAM_WEr <= 1'b1;
          STATE <= ST_MCU_WR_WAIT2;
          ST_MEM_DELAYr <= 4'h2;
        end
        else begin
          STATE <= ST_MCU_WR_WAIT;
        end
      end
      ST_MCU_WR_WAIT2: begin
        ST_MEM_DELAYr <= ST_MEM_DELAYr - 4'h1;
        if(ST_MEM_DELAYr == 4'h0) begin
          STATE <= ST_MCU_WR_END;
        end else STATE <= ST_MCU_WR_WAIT2;
      end
      ST_MCU_WR_END: begin
        STATE <= ST_IDLE;
      end
    endcase
  end
end

assign ROM_DATA[7:0] = ROM_ADDR0
                       ?(SD_DMA_TO_ROM ? (!MCU_WRITE ? MCU_DOUT : 8'bZ)
                                        : (!ROM_WE ? ROM_DOUTr : 8'bZ)
                        )
                       :8'bZ;

assign ROM_DATA[15:8] = ROM_ADDR0 ? 8'bZ
                        :(SD_DMA_TO_ROM ? (!MCU_WRITE ? MCU_DOUT : 8'bZ)
                                         : (!ROM_WE ? ROM_DOUTr : 8'bZ)
                         );

assign RAM_DATA = !RAM_WE ? RAM_DOUTr : 8'bZ;

assign ROM_WE = SD_DMA_TO_ROM
                ?MCU_WRITE
                :ROM_WEr | (ASSERT_SNES_ADDR & ~(snes_wr_cycle & ram0_enable));

assign RAM_WE = RAM_WEr | (ASSERT_SNES_ADDR & ~(snes_wr_cycle & ram1_enable));

assign RAM_OE = 1'b0;

// OE always active. Overridden by WE when needed.
assign ROM_OE = 1'b0;

assign ROM_CE = 1'b0;

assign ROM_BHE = !ROM_WE ? ROM_ADDR0 : 1'b0;
assign ROM_BLE = !ROM_WE ? !ROM_ADDR0 : 1'b0;

assign SNES_DATABUS_OE = PA_enable ? 1'b0
                         : bram_enable ? 1'b0
                         : (~SNES_PAWR & SNES_READ) ? 1'b0
                         : SNES_CS ? SNES_WRITE
                         :((SNES_CS)
                          |(!ram0_enable & !ram1_enable)
                          |(SNES_READ & SNES_WRITE)
                         );

assign SNES_DATABUS_DIR = ~SNES_READ ? 1'b1 : 1'b0;

assign IRQ_DIR = 1'b0;
assign SNES_IRQ = SNES_IRQr;

assign p113_out = 1'b0;

endmodule

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
    inout SNES_IRQ,
    output SNES_DATABUS_OE,
    output SNES_DATABUS_DIR,
    output IRQ_DIR,
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
	 
	 output DAC_MCLK,
	 output DAC_LRCK,
	 output DAC_SDOUT,
	 
	/* SD signals */
    input [3:0] SD_DAT,
	 inout SD_CMD,
	 inout SD_CLK
	 
   /* debug */
   //output DCM_IN_STOPPED,
   //output DCM_FX_STOPPED
   //input DCM_RST
    );
wire [7:0] spi_cmd_data;
wire [7:0] spi_param_data;
wire [7:0] spi_input_data;
wire [31:0] spi_byte_cnt;
wire [2:0] spi_bit_cnt;
wire [23:0] MCU_ADDR;
wire [7:0] mcu_data_in;
wire [7:0] mcu_data_out;
wire [7:0] MCU_IN_DATA;
wire [7:0] MCU_OUT_DATA;
wire [3:0] MAPPER;
wire [23:0] SAVERAM_MASK;
wire [23:0] ROM_MASK;
wire [7:0] SD_DMA_SRAM_DATA;
wire [1:0] SD_DMA_TGT;
wire [10:0] SD_DMA_PARTIAL_START;
wire [10:0] SD_DMA_PARTIAL_END;

wire [10:0] dac_addr;
//wire [7:0] dac_volume;
wire [7:0] msu_volumerq_out;
wire [6:0] msu_status_out;
wire [31:0] msu_addressrq_out;
wire [15:0] msu_trackrq_out;
wire [13:0] msu_write_addr;
wire [13:0] msu_ptr_addr;
wire [7:0] MSU_SNES_DATA_IN;
wire [7:0] MSU_SNES_DATA_OUT;
wire [5:0] msu_status_reset_bits;
wire [5:0] msu_status_set_bits;

wire [14:0] bsx_regs;
wire [14:0] bsx_regs_in;
wire [7:0] BSX_SNES_DATA_IN;
wire [7:0] BSX_SNES_DATA_OUT;
wire [7:0] bsx_regs_reset_bits;
wire [7:0] bsx_regs_set_bits;

wire [59:0] rtc_data;
wire [59:0] rtc_data_in;
wire [59:0] srtc_rtc_data_out;
wire [7:0] SRTC_SNES_DATA_IN;
wire [7:0] SRTC_SNES_DATA_OUT;

wire [7:0] DSPX_SNES_DATA_IN;
wire [7:0] DSPX_SNES_DATA_OUT;

wire [23:0] dspx_pgm_data;
wire [10:0] dspx_pgm_addr;
wire dspx_pgm_we;
   
wire [15:0] dspx_dat_data;
wire [9:0] dspx_dat_addr;
wire dspx_dat_we;

//wire SD_DMA_EN; //SPI_DMA_CTRL;

sd_dma snes_sd_dma(.CLK(CLK2),
                   .SD_DAT(SD_DAT),
						 .SD_CLK(SD_CLK),
						 .SD_DMA_EN(SD_DMA_EN),
						 .SD_DMA_STATUS(SD_DMA_STATUS),
						 .SD_DMA_SRAM_WE(SD_DMA_SRAM_WE),
						 .SD_DMA_SRAM_DATA(SD_DMA_SRAM_DATA),
						 .SD_DMA_NEXTADDR(SD_DMA_NEXTADDR),
						 .SD_DMA_TGT(SD_DMA_TGT),
						 .SD_DMA_PARTIAL(SD_DMA_PARTIAL),
						 .SD_DMA_PARTIAL_START(SD_DMA_PARTIAL_START),
						 .SD_DMA_PARTIAL_END(SD_DMA_PARTIAL_END)
);

dac snes_dac(.clkin(CLK2),
                       .sysclk(SNES_SYSCLK),
                       .mclk(DAC_MCLK),
							  .lrck(DAC_LRCK),
							  .sdout(DAC_SDOUT),
							  .we(SD_DMA_TGT==2'b01 ? SD_DMA_SRAM_WE : 1'b1),
							  .pgm_address(dac_addr),
	                    .pgm_data(SD_DMA_SRAM_DATA),
							  .DAC_STATUS(DAC_STATUS),
							  .volume(msu_volumerq_out),
							  .vol_latch(msu_volume_latch_out),
							  .play(dac_play),
							  .reset(dac_reset)
);

srtc snes_srtc (
    .clkin(CLK2),
    /*XXX*/.reg_addr(srtc_reg_addr), 
    .addr_in(SNES_ADDR[0]), 
    .data_in(SRTC_SNES_DATA_IN), 
    .data_out(SRTC_SNES_DATA_OUT), 
    .rtc_data_in(rtc_data),
    .reg_we(SNES_WRITE), 
    .reg_oe(SNES_READ),
	 .enable(srtc_enable),
	 .rtc_data_out(srtc_rtc_data_out),
	 .rtc_we(srtc_rtc_we),
	 .reset(srtc_reset)
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
    .reg_addr(SNES_ADDR),
    .reg_data_in(MSU_SNES_DATA_IN),
    .reg_data_out(MSU_SNES_DATA_OUT),
    .reg_oe(SNES_READ),
    .reg_we(SNES_WRITE),
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

bsx snes_bsx(.clkin(CLK2),
             .use_bsx(use_bsx),
				 .pgm_we(bsx_regs_reset_we),
				 .snes_addr(SNES_ADDR),
				 .reg_data_in(BSX_SNES_DATA_IN),
				 .reg_data_out(BSX_SNES_DATA_OUT),
				 .reg_oe(SNES_READ),
				 .reg_we(SNES_WRITE),
				 .regs_out(bsx_regs),
				 .reg_reset_bits(bsx_regs_reset_bits),
				 .reg_set_bits(bsx_regs_set_bits),
				 .data_ovr(bsx_data_ovr),
				 .flash_writable(IS_FLASHWR),
				 .rtc_data(rtc_data)
             );

spi snes_spi(.clk(CLK2),
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

upd77c25 snes_dspx (
    .DI(DSPX_SNES_DATA_IN), 
    .DO(DSPX_SNES_DATA_OUT), 
    .A0(DSPX_A0), 
    .nCS(~dspx_enable), 
    .nRD(SNES_READ), 
    .nWR(SNES_WRITE), 
    .RST(~dspx_reset), 
    .CLK(CLK2), 
    .PGM_WR(dspx_pgm_we),
    .PGM_DI(dspx_pgm_data), 
    .PGM_WR_ADDR(dspx_pgm_addr), 
    .DAT_WR(dspx_dat_we), 
    .DAT_DI(dspx_dat_data), 
    .DAT_WR_ADDR(dspx_dat_addr)
    );
    
mcu_cmd snes_mcu_cmd(
    .clk(CLK2),
	 .snes_sysclk(SNES_SYSCLK),
    .cmd_ready(spi_cmd_ready),
    .param_ready(spi_param_ready),
    .cmd_data(spi_cmd_data),
    .param_data(spi_param_data),
    .mcu_mapper(MAPPER),
    .mcu_sram_size(SRAM_SIZE),
    .mcu_read(MCU_READ),
    .mcu_write(MCU_WRITE),
    .mcu_data_in(MCU_OUT_DATA),
    .mcu_data_out(MCU_IN_DATA),
    .spi_byte_cnt(spi_byte_cnt),
    .spi_bit_cnt(spi_bit_cnt),
    .spi_data_out(spi_input_data),
    .addr_out(MCU_ADDR),
    .endmessage(spi_endmessage),
    .startmessage(spi_startmessage),
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
//	 .dac_volume_out(dac_volume),
//	 .dac_volume_latch_out(dac_vol_latch),
	 .dac_play_out(dac_play),
	 .dac_reset_out(dac_reset),
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
   .dspx_reset_out(dspx_reset)
);

// dcm1: dfs 4x
my_dcm snes_dcm(.CLKIN(CLKIN),
                  .CLKFX(CLK2),
                  .LOCKED(DCM_LOCKED),
                  .RST(DCM_RST),
                  .STATUS(DCM_STATUS)
                );
                
assign DCM_RST=0;

/*
dcm_srl16 snes_dcm_resetter(.CLK(CLKIN),
                              .Q(DCM_RST)
                           );
*/
//wire DCM_FX_STOPPED = DCM_STATUS[2];
//always @(posedge CLKIN) begin
//   if(DCM_FX_STOPPED)
//      DCM_RSTr <= 1'b1;
//   else
//      DCM_RSTr <= 1'b0;
//end

/*reg DO_DCM_RESET, DCM_RESETTING;
reg DCM_RSTr;
assign DCM_RST = DCM_RSTr;
reg [2:0] DCM_RESET_CNT;
initial DO_DCM_RESET = 1'b0;
initial DCM_RESETTING = 1'b0;

always @(posedge CLKIN) begin
   if(!DCM_LOCKED && !DCM_RESETTING) begin
      DCM_RSTr <= 1'b1;
      DO_DCM_RESET <= 1'b1;
      DCM_RESET_CNT <= 3'b0;
   end else if (DO_DCM_RESET) begin
      DCM_RSTr <= 1'b0;
      DCM_RESET_CNT <= DCM_RESET_CNT + 1;
   end
end

always @(posedge CLKIN) begin
   if (DO_DCM_RESET)
      DCM_RESETTING <= 1'b1;
   else if (DCM_RESET_CNT == 3'b110)
      DCM_RESETTING <= 1'b0;
end
*/
wire SNES_RW;
reg [1:0] SNES_READr;
reg [1:0] SNES_WRITEr;
reg [1:0] SNES_CSr;
reg [5:0] SNES_CPU_CLKr;
reg [5:0] SNES_RWr;
reg [23:0] SNES_ADDRr;
reg [23:0] SNES_ADDR_PREVr;
reg [3:0] SNES_ADDRCHGr;

wire SNES_READs = (SNES_READr == 2'b11);
wire SNES_WRITEs = (SNES_WRITEr == 2'b11);
wire SNES_CSs = (SNES_CSr == 2'b11);
wire SNES_CPU_CLKs = SNES_CPU_CLK; // (SNES_CPU_CLKr == 2'b11);
wire SNES_RW_start = (SNES_RWr == 6'b111110); // falling edge marks beginning of cycle
wire SNES_cycle_start = (SNES_CPU_CLKr == 6'b000011);
wire SNES_ADDRCHG = (SNES_ADDRr != SNES_ADDR_PREVr);
wire SNES_addr_start = (SNES_ADDRCHGr[0] == 1'b1);

assign SNES_RW = (SNES_READ & SNES_WRITE);

always @(posedge CLK2) begin
   SNES_READr <= {SNES_READr[0], SNES_READ};
   SNES_WRITEr <= {SNES_WRITEr[0], SNES_WRITE};
   SNES_CSr <= {SNES_CSr[0], SNES_CS};
   SNES_CPU_CLKr <= {SNES_CPU_CLKr[4:0], SNES_CPU_CLK};
   SNES_RWr <= {SNES_RWr[4:0], SNES_RW};
end

reg ADDR_WRITE;

//reg [23:0] SNES_ADDRr;
//wire [23:0] SNES_ADDRw = SNES_ADDR;

wire ROM_SEL;

address snes_addr(
    .CLK(CLK2),
    .MAPPER(MAPPER),
    .SNES_ADDR(SNES_ADDR),   // requested address from SNES
    .SNES_CS(SNES_CS),            // "CART" pin from SNES (active low)
    .ROM_ADDR(ROM_ADDR),  // Address to request from SRAM (active low)
    .ROM_SEL(ROM_SEL),     // which SRAM unit to access
    .MCU_OVR(MCU_OVR),            // enable MCU mode (active low)
	 .MODE(MODE),               // MCU(1) or SNES(0) ("bus phase")
    .IS_SAVERAM(IS_SAVERAM),
    .IS_ROM(IS_ROM),
	 .IS_WRITABLE(IS_WRITABLE),
    .MCU_ADDR(MCU_ADDR),
    .ROM_ADDR0(ROM_ADDR0),
    .SAVERAM_MASK(SAVERAM_MASK),
    .ROM_MASK(ROM_MASK),
	 //MSU-1
	 .use_msu(use_msu),
	 .msu_enable(msu_enable),
	 //BS-X
	 .use_bsx(use_bsx),
	 .bsx_regs(bsx_regs),
	 //SRTC
	 .srtc_enable(srtc_enable),
   //uPD77C25
   .dspx_enable(dspx_enable),
   .dspx_a0(DSPX_A0)
    );

wire SNES_READ_CYCLEw;
wire SNES_WRITE_CYCLEw;
wire MCU_READ_CYCLEw;
wire MCU_WRITE_CYCLEw;

data snes_data(.CLK(CLK2),
      .SNES_READ(SNES_READ),
      .SNES_WRITE(SNES_WRITE),
      .MCU_READ(MCU_READ),
      .MCU_WRITE(MCU_WRITE),
      .SNES_DATA(SNES_DATA),
      .ROM_DATA(ROM_DATA),
      .MODE(MODE),
      .SNES_DATA_TO_MEM(SNES_DATA_TO_MEM),
      .MCU_DATA_TO_MEM(MCU_DATA_TO_MEM),
      .ROM_DATA_TO_SNES_MEM(ROM_DATA_TO_SNES_MEM),
      .ROM_DATA_TO_MCU_MEM(ROM_DATA_TO_MCU_MEM),
      .MCU_OVR(MCU_OVR),
      .MCU_IN_DATA(MCU_IN_DATA),
      .MCU_OUT_DATA(MCU_OUT_DATA),
      .ROM_ADDR0(ROM_ADDR0),
		.MSU_DATA_IN(MSU_SNES_DATA_IN),
		.MSU_DATA_OUT(MSU_SNES_DATA_OUT),
		.BSX_DATA_IN(BSX_SNES_DATA_IN),
		.BSX_DATA_OUT(BSX_SNES_DATA_OUT),
		.SRTC_DATA_IN(SRTC_SNES_DATA_IN),
		.SRTC_DATA_OUT(SRTC_SNES_DATA_OUT),
    .DSPX_DATA_IN(DSPX_SNES_DATA_IN),
    .DSPX_DATA_OUT(DSPX_SNES_DATA_OUT),
		.msu_enable(msu_enable),
		.bsx_data_ovr(bsx_data_ovr),
		.srtc_enable(srtc_enable),
    .dspx_enable(dspx_enable)
      );
      
parameter MODE_SNES = 1'b0;
parameter MODE_MCU = 1'b1;

parameter STATE_0    = 14'b00000000000001;
parameter STATE_1    = 14'b00000000000010;
parameter STATE_2    = 14'b00000000000100;
parameter STATE_3    = 14'b00000000001000;
parameter STATE_4    = 14'b00000000010000;
parameter STATE_5    = 14'b00000000100000;
parameter STATE_6    = 14'b00000001000000;
parameter STATE_7    = 14'b00000010000000;
parameter STATE_8    = 14'b00000100000000;
parameter STATE_9    = 14'b00001000000000;
parameter STATE_10   = 14'b00010000000000;
parameter STATE_11   = 14'b00100000000000;
parameter STATE_12	= 14'b01000000000000;
parameter STATE_IDLE = 14'b10000000000000;

reg [13:0] STATE;
reg [3:0] STATEIDX;

reg [1:0] CYCLE_RESET;
reg ROM_WE_MASK;
reg ROM_OE_MASK;

reg [13:0] ROM_WE_ARRAY [3:0];
reg [13:0] ROM_OE_ARRAY [3:0];

reg [13:0] SNES_DATA_TO_MEM_ARRAY[1:0];
reg [13:0] MCU_DATA_TO_MEM_ARRAY[1:0];
reg [13:0] ROM_DATA_TO_SNES_MEM_ARRAY[1:0];
reg [13:0] ROM_DATA_TO_MCU_MEM_ARRAY[1:0];

reg [13:0] MODE_ARRAY;

reg SNES_READ_CYCLE;
reg SNES_WRITE_CYCLE;
reg MCU_READ_CYCLE;
reg MCU_WRITE_CYCLE;
reg MCU_SPI_WRITEONCE;
reg MCU_SPI_READONCE;
reg MCU_SPI_WRITE;
reg MCU_SPI_READ;
reg MCU_SPI_ADDR_INCREMENT;
reg [7:0] MCU_DATA_IN;
reg [3:0] MAPPER_BUF;

reg SNES_DATABUS_OE_BUF;
reg SNES_DATABUS_DIR_BUF;

assign MODE = !MCU_OVR ? MODE_MCU : MODE_ARRAY[STATEIDX];

initial begin
   CYCLE_RESET = 2'b0;
   
   STATE = STATE_IDLE;
   STATEIDX = 13;
   ROM_WE_MASK = 1'b1;
   ROM_OE_MASK = 1'b1;
   SNES_READ_CYCLE = 1'b1;
   SNES_WRITE_CYCLE = 1'b1;
   MCU_READ_CYCLE = 1'b1;
   MCU_WRITE_CYCLE = 1'b1;
   MODE_ARRAY = 14'b0_000000_1111111;
   
   ROM_WE_ARRAY[2'b00] = 14'b1_000000_0000000;
   ROM_WE_ARRAY[2'b01] = 14'b1_000000_1111111;
   ROM_WE_ARRAY[2'b10] = 14'b1_111111_0000000;
   ROM_WE_ARRAY[2'b11] = 14'b1_111111_1111111;

   ROM_OE_ARRAY[2'b00] = 14'b1_111111_1111111;
   ROM_OE_ARRAY[2'b01] = 14'b1_111111_0000000;
   ROM_OE_ARRAY[2'b10] = 14'b0_000000_1111111;
   ROM_OE_ARRAY[2'b11] = 14'b0_000000_0000000;
   
   SNES_DATA_TO_MEM_ARRAY[1'b0] = 14'b0_000100_0000000;  // SNES write
   /* 13'b0001000000000 */
   SNES_DATA_TO_MEM_ARRAY[1'b1] = 14'b0_000000_0000000;  // SNES read
   
   MCU_DATA_TO_MEM_ARRAY[1'b0] = 14'b1_111111_1111111;  // MCU write
//   MCU_DATA_TO_MEM_ARRAY[1'b0] = 13'b0000000001000;  // MCU write

   MCU_DATA_TO_MEM_ARRAY[1'b1] = 14'b0_000000_0000000;  // MCU read
   
   ROM_DATA_TO_SNES_MEM_ARRAY[1'b0] = 14'b0_000000_0000000;  // SNES write
   ROM_DATA_TO_SNES_MEM_ARRAY[1'b1] = 14'b0_000010_0000000;  // SNES read
   /* 13'b0000100000000; */
   
   ROM_DATA_TO_MCU_MEM_ARRAY[1'b0] = 14'b0_000000_0000000;  // MCU write
   ROM_DATA_TO_MCU_MEM_ARRAY[1'b1] = 14'b0_000000_0000001;  // MCU read
//   SRAM_DATA_TO_MCU_MEM_ARRAY[1'b1] = 13'b0000000000001;  // MCU read

end 

// falling edge of SNES /RD or /WR marks the beginning of a new cycle
// SNES READ or WRITE always starts @posedge CLK !!
// CPU cycle can be 6, 8 or 12 CLKIN cycles so we must satisfy
// the minimum of 6 SNES cycles to get everything done.
// we have 24 internal cycles to work with. (CLKIN * 4)

always @(posedge CLK2) begin
	CYCLE_RESET <= {CYCLE_RESET[0], SNES_cycle_start};
end

reg[7:0] STATECNT;
initial STATECNT = 0;

always @(posedge CLK2) begin
       MCU_READ_CYCLE <= MCU_READ;
       MCU_WRITE_CYCLE <= MCU_WRITE;
       if (SNES_cycle_start) begin
           SNES_READ_CYCLE <= SNES_READ;
           SNES_WRITE_CYCLE <= SNES_WRITE;
           STATE <= STATE_0;
           STATEIDX <= 12;
			  STATECNT <= 0;
       end else begin
           STATECNT <= STATECNT + 1;
           case (STATE)
              STATE_0: begin
                 SNES_WRITE_CYCLE <= SNES_WRITE;
                 STATE <= STATE_1; STATEIDX <= 11;
              end
              STATE_1: begin
                 STATE <= STATE_2; STATEIDX <= 10;
              end
              STATE_2: begin
                 STATE <= STATE_3; STATEIDX <= 9;
              end
              STATE_3: begin
                 STATE <= STATE_4; STATEIDX <= 8;
              end
              STATE_4: begin
                 STATE <= STATE_5; STATEIDX <= 7;
              end
              STATE_5: begin
                 STATE <= STATE_6; STATEIDX <= 6;
              end
              STATE_6: begin
                 STATE <= STATE_7; STATEIDX <= 5;
              end
              STATE_7: begin
                 STATE <= STATE_8; STATEIDX <= 4;
              end
              STATE_8: begin
                 STATE <= STATE_9; STATEIDX <= 3;
              end
              STATE_9: begin
                 STATE <= STATE_10; STATEIDX <= 2;
              end
              STATE_10: begin
                 STATE <= STATE_11; STATEIDX <= 1;
              end
              STATE_11: begin
                 STATE <= STATE_12; STATEIDX <= 0;
              end
				  STATE_12: begin
				     STATE <= STATE_IDLE; STATEIDX <= 13;
				  end
              STATE_IDLE: begin
                 STATE <= STATE_IDLE; STATEIDX <= 13;
              end
              default: begin
                 STATE <= STATE_IDLE; STATEIDX <= 13;
              end
           endcase
       end
end
/*
always @(posedge CLK2) begin

   case (STATE)   
      STATE_9: begin
         STATEIDX <= 9;
      end
      
      STATE_0: begin
         STATEIDX <= 8;
      end
      
      STATE_1: begin
         STATEIDX <= 7;
      end
      
      STATE_2: begin
         STATEIDX <= 6;
      end
      
      STATE_3: begin
         STATEIDX <= 5;
      end
      
      STATE_4: begin
         STATEIDX <= 4;
      end
      
      STATE_5: begin
         STATEIDX <= 3;
      end
      
      STATE_6: begin
         STATEIDX <= 2;
      end

      STATE_7: begin
         STATEIDX <= 1;
      end

      STATE_8: begin
         STATEIDX <= 0;
      end
      default:
         STATEIDX <= 9;
   endcase      
end
*/
// When in MCU mode, enable SRAM_WE according to MCU programming
// else enable SRAM_WE according to state&cycle
assign ROM_WE = !MCU_OVR ? MCU_WRITE
                          : ((!IS_FLASHWR & !IS_WRITABLE & !MODE) | ROM_WE_ARRAY[{SNES_WRITE_CYCLE, MCU_WRITE_CYCLE}][STATEIDX]);

// When in MCU mode, enable SRAM_OE whenever not writing
// else enable SRAM_OE according to state&cycle
assign ROM_OE = !MCU_OVR ? MCU_READ 
                          : ROM_OE_ARRAY[{SNES_WRITE_CYCLE, MCU_WRITE_CYCLE}][STATEIDX];

assign ROM_CE = 1'b0; // !MCU_OVR ? (MCU_READ & MCU_WRITE) : ROM_SEL;

assign ROM_BHE = !ROM_WE ? ROM_ADDR0 : 1'b0;
assign ROM_BLE = !ROM_WE ? !ROM_ADDR0 : 1'b0;

//assign SRAM_BHE = SRAM_ADDR0;
//assign SRAM_BLE = ~SRAM_ADDR0;

// dumb version
//assign SRAM_OE = !MCU_ENA ? MCU_READ : SNES_READs;
//assign SRAM_WE = !MCU_ENA ? MCU_WRITE : 1'b1;

//assign SNES_DATABUS_OE = (!IS_SAVERAM & SNES_CS) | (SNES_READ & SNES_WRITE);
assign SNES_DATABUS_OE = dspx_enable ? 1'b0 :
                         msu_enable ? (SNES_READ & SNES_WRITE) :
                         bsx_data_ovr ? (SNES_READ & SNES_WRITE) : 
								 srtc_enable ? (SNES_READ & SNES_WRITE) : ((IS_ROM & SNES_CS) | (!IS_ROM & !IS_SAVERAM & !IS_WRITABLE & !IS_FLASHWR) | (SNES_READ & SNES_WRITE));
assign SNES_DATABUS_DIR = !SNES_READ ? 1'b1 : 1'b0;

assign SNES_DATA_TO_MEM = SNES_DATA_TO_MEM_ARRAY[SNES_WRITE_CYCLE][STATEIDX];
assign MCU_DATA_TO_MEM = MCU_DATA_TO_MEM_ARRAY[MCU_WRITE_CYCLE][STATEIDX];

assign ROM_DATA_TO_SNES_MEM = ROM_DATA_TO_SNES_MEM_ARRAY[SNES_WRITE_CYCLE][STATEIDX];
assign ROM_DATA_TO_MCU_MEM = ROM_DATA_TO_MCU_MEM_ARRAY[MCU_WRITE_CYCLE][STATEIDX];

assign SNES_READ_CYCLEw = SNES_READ_CYCLE;
assign SNES_WRITE_CYCLEw = SNES_WRITE_CYCLE;
assign IRQ_DIR = 1'b0;
assign SNES_IRQ = 1'bZ;

endmodule

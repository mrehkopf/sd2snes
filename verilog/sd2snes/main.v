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

   /* SRAM signals */
    inout [15:0] SRAM_DATA,
    output [19:0] SRAM_ADDR,
    output [3:0] SRAM_CE2,
    output SRAM_OE,
    output SRAM_WE,
    output SRAM_BHE,
    output SRAM_BLE,

   /* AVR signals */
    input SPI_MOSI,
    output SPI_MISO,
    input SPI_SS,
    input SPI_SCK,
    input AVR_ENA
    
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
wire [23:0] AVR_ADDR;
wire [7:0] avr_data_in;
wire [7:0] avr_data_out;
wire [7:0] AVR_IN_DATA;
wire [7:0] AVR_OUT_DATA;
wire [3:0] MAPPER;
wire [23:0] SAVERAM_MASK;
wire [23:0] ROM_MASK;

spi snes_spi(.clk(CLK2),
             .MOSI(SPI_MOSI),
             .MISO(SPI_MISO),
             .SSEL(SPI_SS),
             .SCK(SPI_SCK),
             .LED(SPI_LSB),
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

avr_cmd snes_avr_cmd(
    .clk(CLK2),
    .cmd_ready(spi_cmd_ready),
    .param_ready(spi_param_ready),
    .cmd_data(spi_cmd_data),
    .param_data(spi_param_data),
    .avr_mapper(MAPPER),
    .avr_sram_size(SRAM_SIZE),
    .avr_read(AVR_READ),
    .avr_write(AVR_WRITE),
    .avr_data_in(AVR_OUT_DATA),
    .avr_data_out(AVR_IN_DATA),
    .spi_byte_cnt(spi_byte_cnt),
    .spi_bit_cnt(spi_bit_cnt),
    .spi_data_out(spi_input_data),
    .addr_out(AVR_ADDR),
    .endmessage(spi_endmessage),
    .startmessage(spi_startmessage),
    .saveram_mask_out(SAVERAM_MASK),
    .rom_mask_out(ROM_MASK)
);

wire [7:0] DCM_STATUS;
my_dcm snes_dcm(.CLKIN(CLKIN),
                  .CLKFX(CLK2),
                  .LOCKED(DCM_LOCKED),
                  .RST(DCM_RST),
                  .STATUS(DCM_STATUS),
                  .CLKFB(CLKFB),
                  .CLK0(CLK0)
                );
reg DCM_RSTr;
assign DCM_RST = DCM_RSTr;
assign CLKFB = CLK0;
wire DCM_FX_STOPPED = DCM_STATUS[2];
always @(posedge CLKIN) begin
   if(DCM_FX_STOPPED)
      DCM_RSTr <= 1'b1;
   else
      DCM_RSTr <= 1'b0;
end

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
wire SNES_cycle_start = (SNES_CPU_CLKr == 6'b000001);
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


address snes_addr(
    .CLK(CLK2),
    .MAPPER(MAPPER),
    .SNES_ADDR(SNES_ADDR),   // requested address from SNES
    .SNES_CS(SNES_CS),            // "CART" pin from SNES (active low)
    .SRAM_ADDR(SRAM_ADDR),  // Address to request from SRAM (active low)
    .ROM_SEL(SRAM_CE2),     // which SRAM unit to access
    .AVR_ENA(AVR_ENA),            // enable AVR mode (active low)
	 .MODE(MODE),               // AVR(1) or SNES(0) ("bus phase")
    .IS_SAVERAM(IS_SAVERAM),
    .IS_ROM(IS_ROM),
    .AVR_ADDR(AVR_ADDR),
    .SRAM_ADDR0(SRAM_ADDR0),
    .SAVERAM_MASK(SAVERAM_MASK),
    .ROM_MASK(ROM_MASK)
    );

wire SNES_READ_CYCLEw;
wire SNES_WRITE_CYCLEw;
wire AVR_READ_CYCLEw;
wire AVR_WRITE_CYCLEw;
    
data snes_data(.CLK(CLK2),
      .SNES_READ(SNES_READ),
      .SNES_WRITE(SNES_WRITE),
      .AVR_READ(AVR_READ),
      .AVR_WRITE(AVR_WRITE),
      .SNES_DATA(SNES_DATA),
      .SRAM_DATA(SRAM_DATA),
      .MODE(MODE),
      .SNES_DATA_TO_MEM(SNES_DATA_TO_MEM),
      .AVR_DATA_TO_MEM(AVR_DATA_TO_MEM),
      .SRAM_DATA_TO_SNES_MEM(SRAM_DATA_TO_SNES_MEM),
      .SRAM_DATA_TO_AVR_MEM(SRAM_DATA_TO_AVR_MEM),
      .AVR_ENA(AVR_ENA),
      .AVR_IN_DATA(AVR_IN_DATA),
      .AVR_OUT_DATA(AVR_OUT_DATA),
      .SRAM_ADDR0(SRAM_ADDR0)
      );
      
parameter MODE_SNES = 1'b0;
parameter MODE_AVR = 1'b1;

parameter STATE_0    = 13'b0000000000001;
parameter STATE_1    = 13'b0000000000010;
parameter STATE_2    = 13'b0000000000100;
parameter STATE_3    = 13'b0000000001000;
parameter STATE_4    = 13'b0000000010000;
parameter STATE_5    = 13'b0000000100000;
parameter STATE_6    = 13'b0000001000000;
parameter STATE_7    = 13'b0000010000000;
parameter STATE_8    = 13'b0000100000000;
parameter STATE_9    = 13'b0001000000000;
parameter STATE_10   = 13'b0010000000000;
parameter STATE_11   = 13'b0100000000000;
parameter STATE_IDLE = 13'b1000000000000;

reg [12:0] STATE;
reg [3:0] STATEIDX;

reg [1:0] CYCLE_RESET;
reg SRAM_WE_MASK;
reg SRAM_OE_MASK;

reg [12:0] SRAM_WE_ARRAY [3:0];
reg [12:0] SRAM_OE_ARRAY [3:0];

reg [12:0] SNES_DATA_TO_MEM_ARRAY[1:0];
reg [12:0] AVR_DATA_TO_MEM_ARRAY[1:0];
reg [12:0] SRAM_DATA_TO_SNES_MEM_ARRAY[1:0];
reg [12:0] SRAM_DATA_TO_AVR_MEM_ARRAY[1:0];

reg [12:0] MODE_ARRAY;

reg SNES_READ_CYCLE;
reg SNES_WRITE_CYCLE;
reg AVR_READ_CYCLE;
reg AVR_WRITE_CYCLE;
reg AVR_SPI_WRITEONCE;
reg AVR_SPI_READONCE;
reg AVR_SPI_WRITE;
reg AVR_SPI_READ;
reg AVR_SPI_ADDR_INCREMENT;
reg [7:0] AVR_DATA_IN;
reg [3:0] MAPPER_BUF;

reg SNES_DATABUS_OE_BUF;
reg SNES_DATABUS_DIR_BUF;

assign MODE = !AVR_ENA ? MODE_AVR : MODE_ARRAY[STATEIDX];

initial begin
   CYCLE_RESET = 2'b0;
   
   STATE = STATE_IDLE;
   STATEIDX = 12;
   SRAM_WE_MASK = 1'b1;
   SRAM_OE_MASK = 1'b1;
   SNES_READ_CYCLE = 1'b1;
   SNES_WRITE_CYCLE = 1'b1;
   AVR_READ_CYCLE = 1'b1;
   AVR_WRITE_CYCLE = 1'b1;
   MODE_ARRAY = 13'b0000000111111;
   
   SRAM_WE_ARRAY[2'b00] = 13'b1000000000000;
   SRAM_WE_ARRAY[2'b01] = 13'b1000000111111;
   SRAM_WE_ARRAY[2'b10] = 13'b1111111000000;
   SRAM_WE_ARRAY[2'b11] = 13'b1111111111111;

   SRAM_OE_ARRAY[2'b00] = 13'b1111111111111;
   SRAM_OE_ARRAY[2'b01] = 13'b1111111000000;
   SRAM_OE_ARRAY[2'b10] = 13'b0000000111111;
   SRAM_OE_ARRAY[2'b11] = 13'b0000000000000;
   
   SNES_DATA_TO_MEM_ARRAY[1'b0] = 13'b0001000000000;  // SNES write
   SNES_DATA_TO_MEM_ARRAY[1'b1] = 13'b0000000000000;  // SNES read
   
   AVR_DATA_TO_MEM_ARRAY[1'b0] = 13'b0000000010000;  // AVR write
   AVR_DATA_TO_MEM_ARRAY[1'b1] = 13'b0000000000000;  // AVR read
   
   SRAM_DATA_TO_SNES_MEM_ARRAY[1'b0] = 13'b0000000000000;  // SNES write
   SRAM_DATA_TO_SNES_MEM_ARRAY[1'b1] = 13'b0000100000000;  // SNES read
   
   SRAM_DATA_TO_AVR_MEM_ARRAY[1'b0] = 13'b0000000000000;  // AVR write
   SRAM_DATA_TO_AVR_MEM_ARRAY[1'b1] = 13'b0000000000001;  // AVR read
end 

// falling edge of SNES /RD or /WR marks the beginning of a new cycle
// SNES READ or WRITE always starts @posedge CLK !!
// CPU cycle can be 6, 8 or 12 CLKIN cycles so we must satisfy
// the minimum of 6 SNES cycles to get everything done.
// we have 24 internal cycles to work with. (CLKIN * 4)

always @(posedge CLK2) begin
	CYCLE_RESET <= {CYCLE_RESET[0], SNES_cycle_start};
end

always @(posedge CLK2) begin
       if (SNES_RW_start) begin
           SNES_READ_CYCLE <= SNES_READ;
           SNES_WRITE_CYCLE <= SNES_WRITE;
           AVR_READ_CYCLE <= AVR_READ;
           AVR_WRITE_CYCLE <= AVR_WRITE;
           STATE <= STATE_0;
           STATEIDX <= 11;
       end else begin
           case (STATE)
              STATE_0: begin
                 STATE <= STATE_1; STATEIDX <= 10;
              end
              STATE_1: begin
                 STATE <= STATE_2; STATEIDX <= 9;
              end
              STATE_2: begin
                 STATE <= STATE_3; STATEIDX <= 8;
              end
              STATE_3: begin
                 STATE <= STATE_4; STATEIDX <= 7;
              end
              STATE_4: begin
                 STATE <= STATE_5; STATEIDX <= 6;
              end
              STATE_5: begin
                 STATE <= STATE_6; STATEIDX <= 5;
              end
              STATE_6: begin
                 STATE <= STATE_7; STATEIDX <= 4;
              end
              STATE_7: begin
                 STATE <= STATE_8; STATEIDX <= 3;
              end
              STATE_8: begin
                 STATE <= STATE_9; STATEIDX <= 2;
              end
              STATE_9: begin
                 STATE <= STATE_10; STATEIDX <= 1;
              end
              STATE_10: begin
                 STATE <= STATE_11; STATEIDX <= 0;
              end
              STATE_11: begin
                 STATE <= STATE_IDLE; STATEIDX <= 12;
              end
              STATE_IDLE: begin
                 STATE <= STATE_IDLE; STATEIDX <= 12;
              end
              default: begin
                 STATE <= STATE_IDLE; STATEIDX <= 12;
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
// When in AVR mode, enable SRAM_WE according to AVR programming
// else enable SRAM_WE according to state&cycle
assign SRAM_WE = !AVR_ENA ? AVR_WRITE
                          : ((!IS_SAVERAM & !MODE) | SRAM_WE_ARRAY[{SNES_WRITE_CYCLE, AVR_WRITE_CYCLE}][STATEIDX]);

// When in AVR mode, enable SRAM_OE whenever not writing
// else enable SRAM_OE according to state&cycle
assign SRAM_OE = !AVR_ENA ? AVR_READ 
                          : SRAM_OE_ARRAY[{SNES_WRITE_CYCLE, AVR_WRITE_CYCLE}][STATEIDX];

assign SRAM_BHE = !SRAM_WE ? SRAM_ADDR0 : 1'b0;
assign SRAM_BLE = !SRAM_WE ? !SRAM_ADDR0 : 1'b0;

// dumb version
//assign SRAM_OE = !AVR_ENA ? AVR_READ : SNES_READs;
//assign SRAM_WE = !AVR_ENA ? AVR_WRITE : 1'b1;

//assign SNES_DATABUS_OE = (!IS_SAVERAM & SNES_CS) | (SNES_READ & SNES_WRITE);
assign SNES_DATABUS_OE = (IS_ROM & SNES_CS) | (!IS_ROM & !IS_SAVERAM) | (SNES_READ & SNES_WRITE);
assign SNES_DATABUS_DIR = !SNES_READ ? 1'b1 : 1'b0;

assign SNES_DATA_TO_MEM = SNES_DATA_TO_MEM_ARRAY[SNES_WRITE_CYCLE][STATEIDX];
assign AVR_DATA_TO_MEM = AVR_DATA_TO_MEM_ARRAY[AVR_WRITE_CYCLE][STATEIDX];

assign SRAM_DATA_TO_SNES_MEM = SRAM_DATA_TO_SNES_MEM_ARRAY[SNES_WRITE_CYCLE][STATEIDX];
assign SRAM_DATA_TO_AVR_MEM = SRAM_DATA_TO_AVR_MEM_ARRAY[AVR_WRITE_CYCLE][STATEIDX];

assign SNES_READ_CYCLEw = SNES_READ_CYCLE;
assign SNES_WRITE_CYCLEw = SNES_WRITE_CYCLE;
assign IRQ_DIR = 1'b0;
assign SNES_IRQ = 1'bZ;

endmodule

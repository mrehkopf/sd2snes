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

my_dcm snes_dcm(.CLKIN(CLKIN),
                  .CLK2X(CLK),
                  .CLKFB(CLKFB),
                  .CLKFX(CLK2),
                  .CLK0(CLK0)
                );

/*my_dcm snes_dcm2(.CLKIN(CLK),
                  .CLK2X(CLK2),
                  .CLKFB(CLKFB2),
                  .CLKFX(CLKFX2)
                );*/
assign CLKFB = CLK0;
//assign CLKFB2 = CLK2;

wire SNES_RW;
reg SNES_READs;
reg SNES_WRITEs;
reg SNES_CSs;

assign SNES_RW = (SNES_READs & SNES_WRITEs);

always @(posedge CLK2) begin
   SNES_READs <= SNES_READ;
   SNES_WRITEs <= SNES_WRITE;
   SNES_CSs <= SNES_CS;
end
reg ADDR_WRITE;


address snes_addr(
    .CLK(CLK2),
    .MAPPER(MAPPER),
    .SNES_ADDR(SNES_ADDR),   // requested address from SNES
    .SNES_CS(SNES_CSs),            // "CART" pin from SNES (active low)
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
    
data snes_data(.CLK(CLK2),
      .SNES_READ(SNES_READs),
      .SNES_WRITE(SNES_WRITEs),
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

parameter STATE_0 = 10'b0000000001;
parameter STATE_1 = 10'b0000000010;
parameter STATE_2 = 10'b0000000100;
parameter STATE_3 = 10'b0000001000;
parameter STATE_4 = 10'b0000010000;
parameter STATE_5 = 10'b0000100000;
parameter STATE_6 = 10'b0001000000;
parameter STATE_7 = 10'b0010000000;
parameter STATE_8 = 10'b0100000000;
parameter STATE_9 = 10'b1000000000;

reg [9:0] STATE;
reg [3:0] STATEIDX;

reg STATE_RESET, CYCLE_RESET, CYCLE_RESET_ACK;
reg SRAM_WE_MASK;
reg SRAM_OE_MASK;

reg [9:0] SRAM_WE_ARRAY [3:0];
reg [9:0] SRAM_OE_ARRAY [3:0];

reg [9:0] SNES_DATA_TO_MEM_ARRAY[1:0];
reg [9:0] AVR_DATA_TO_MEM_ARRAY[1:0];
reg [9:0] SRAM_DATA_TO_SNES_MEM_ARRAY[1:0];
reg [9:0] SRAM_DATA_TO_AVR_MEM_ARRAY[1:0];

reg [9:0] MODE_ARRAY;

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
   CYCLE_RESET = 0;
   CYCLE_RESET_ACK = 0;
   
   STATE = STATE_9;
   STATEIDX = 9;
   SRAM_WE_MASK = 1'b1;
   SRAM_OE_MASK = 1'b1;
   SNES_READ_CYCLE = 1'b1;
   SNES_WRITE_CYCLE = 1'b1;
   AVR_READ_CYCLE = 1'b1;
   AVR_WRITE_CYCLE = 1'b1;

   MODE_ARRAY = 10'b0000011111;
   
   SRAM_WE_ARRAY[2'b00] = 10'b1000010000;
   SRAM_WE_ARRAY[2'b01] = 10'b1000011111;
   SRAM_WE_ARRAY[2'b10] = 10'b1111110000;
   SRAM_WE_ARRAY[2'b11] = 10'b1111111111;

   SRAM_OE_ARRAY[2'b00] = 10'b1111111111;
   SRAM_OE_ARRAY[2'b01] = 10'b1111100000;
   SRAM_OE_ARRAY[2'b10] = 10'b0000011111;
   SRAM_OE_ARRAY[2'b11] = 10'b0000000000;
   
   SNES_DATA_TO_MEM_ARRAY[1'b0] = 10'b1000000000;
   SNES_DATA_TO_MEM_ARRAY[1'b1] = 10'b0000000000;
   
   AVR_DATA_TO_MEM_ARRAY[1'b0] = 10'b0000100000;
   AVR_DATA_TO_MEM_ARRAY[1'b1] = 10'b0000000000;
   
   SRAM_DATA_TO_SNES_MEM_ARRAY[1'b0] = 10'b0000000000;
   SRAM_DATA_TO_SNES_MEM_ARRAY[1'b1] = 10'b0000100000;
   
   SRAM_DATA_TO_AVR_MEM_ARRAY[1'b0] = 10'b0000000000;
   SRAM_DATA_TO_AVR_MEM_ARRAY[1'b1] = 10'b0000000001;  
end 

// falling edge of SNES /RD or /WR marks the beginning of a new cycle
// SNES READ or WRITE always starts @posedge CLK !!
// CPU cycle can be 6, 8 or 12 CLK cycles so we must satisfy
// the minimum of 6 cycles to get everything done.

always @(posedge CLK2) begin
   if (!SNES_RW /* || !AVR_ENA */) begin
      if (!CYCLE_RESET_ACK) 
         CYCLE_RESET <= 1;
      else
         CYCLE_RESET <= 0;
   end
end

always @(posedge CLK2) begin
       if (CYCLE_RESET && !CYCLE_RESET_ACK) begin
          CYCLE_RESET_ACK <= 1;
          STATE <= STATE_0;
       end else begin
           case (STATE)
              STATE_0:
                 STATE <= STATE_1;
              STATE_1:
                 STATE <= STATE_2;
              STATE_2:
                 STATE <= STATE_3;
              STATE_3:
                 STATE <= STATE_4;
              STATE_4:
                 STATE <= STATE_5;
              STATE_5:
                 STATE <= STATE_6;
              STATE_6:
                 STATE <= STATE_7;
              STATE_7:
                 STATE <= STATE_8;
              STATE_8:
                 STATE <= STATE_9;
              STATE_9: begin
                 if (SNES_RW /* || !AVR_ENA */) // check for end of SNES cycle to avoid looping
                     CYCLE_RESET_ACK <= 0;  // ready for new cycle
                 STATE <= STATE_9;
              end                 
              default:
                 STATE <= STATE_9;
           endcase
       end
end

always @(posedge CLK2) begin

   case (STATE)   
      STATE_9: begin
         SNES_READ_CYCLE <= SNES_READs;
         SNES_WRITE_CYCLE <= SNES_WRITEs;
         AVR_READ_CYCLE <= AVR_READ;
         AVR_WRITE_CYCLE <= AVR_WRITE;
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
   endcase      
end

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
assign SNES_DATABUS_OE = (IS_ROM & SNES_CSs) | (!IS_ROM & !IS_SAVERAM) | (SNES_READs & SNES_WRITEs);
assign SNES_DATABUS_DIR = !SNES_WRITEs ? 1'b0 : 1'b1;

assign SNES_DATA_TO_MEM = SNES_DATA_TO_MEM_ARRAY[SNES_WRITE_CYCLE][STATEIDX];
assign AVR_DATA_TO_MEM = AVR_DATA_TO_MEM_ARRAY[AVR_WRITE_CYCLE][STATEIDX];

assign SRAM_DATA_TO_SNES_MEM = SRAM_DATA_TO_SNES_MEM_ARRAY[SNES_WRITE_CYCLE][STATEIDX];
assign SRAM_DATA_TO_AVR_MEM = SRAM_DATA_TO_AVR_MEM_ARRAY[AVR_WRITE_CYCLE][STATEIDX];

assign IRQ_DIR = 1'b0;
assign SNES_IRQ = 1'bZ;

endmodule

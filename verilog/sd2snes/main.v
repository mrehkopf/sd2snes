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
    input CLKIN,
    input [2:0] MAPPER,
    input [23:0] SNES_ADDR,
    input SNES_READ,
    input SNES_WRITE,
    input SNES_CS,
    inout [7:0] SNES_DATA,
    inout [7:0] SRAM_DATA,
    inout [7:0] AVR_DATA,
    output [20:0] SRAM_ADDR,
    output [3:0] ROM_SEL,
    output SRAM_OE,
    output SRAM_WE,
    output SNES_DATABUS_OE,
    output SNES_DATABUS_DIR,
    input AVR_ADDR_RESET,
    input AVR_ADDR_EN,
    input AVR_READ,
    input AVR_WRITE,
    input AVR_NEXTADDR,
    input AVR_ENA,
    input [1:0] AVR_BANK,
    output MODE
    );

my_dcm snes_dcm(.CLKIN(CLKIN),
                  .CLK2X(CLK),
                  .CLKFB(CLKFB)
                );
                
assign CLKFB = CLK;
                
address snes_addr(
    .CLK(CLK),
    .MAPPER(MAPPER),
    .SNES_ADDR(SNES_ADDR),   // requested address from SNES
    .SNES_CS(SNES_CS),            // "CART" pin from SNES (active low)
    .SRAM_ADDR(SRAM_ADDR),  // Address to request from SRAM (active low)
    .ROM_SEL(ROM_SEL),     // which SRAM unit to access
    .AVR_ADDR_RESET(AVR_ADDR_RESET),     // reset AVR sequence (active low)
    .AVR_NEXTADDR(AVR_NEXTADDR),        // next byte request from AVR
    .AVR_ENA(AVR_ENA),            // enable AVR mode (active low)
    .AVR_ADDR_EN(AVR_ADDR_EN),  // enable AVR address counter (active low)
    .AVR_BANK(AVR_BANK),     // which bank does the AVR want
	 .MODE(MODE),               // AVR(1) or SNES(0) ("bus phase")
    .IS_SAVERAM(IS_SAVERAM),
    .IS_ROM(IS_ROM),
    .AVR_NEXTADDR_PREV(AVR_NEXTADDR_PREV),
    .AVR_NEXTADDR_CURR(AVR_NEXTADDR_CURR)
    );
    
data snes_data(.CLK(CLK),
      .SNES_READ(SNES_READ),
      .SNES_WRITE(SNES_WRITE),
      .AVR_READ(AVR_READ),
      .AVR_WRITE(AVR_WRITE),
      .SNES_DATA(SNES_DATA),
      .SRAM_DATA(SRAM_DATA),
      .AVR_DATA(AVR_DATA),
      .MODE(MODE),
      .SNES_DATA_TO_MEM(SNES_DATA_TO_MEM),
      .AVR_DATA_TO_MEM(AVR_DATA_TO_MEM),
      .SRAM_DATA_TO_SNES_MEM(SRAM_DATA_TO_SNES_MEM),
      .SRAM_DATA_TO_AVR_MEM(SRAM_DATA_TO_AVR_MEM),
      .AVR_ENA(AVR_ENA),
      .AVR_NEXTADDR_PREV(AVR_NEXTADDR_PREV),
      .AVR_NEXTADDR_CURR(AVR_NEXTADDR_CURR)
      );
      
parameter MODE_SNES = 1'b0;
parameter MODE_AVR = 1'b1;

parameter STATE_0 = 8'b00000001;
parameter STATE_1 = 8'b00000010;
parameter STATE_2 = 8'b00000100;
parameter STATE_3 = 8'b00001000;
parameter STATE_4 = 8'b00010000;
parameter STATE_5 = 8'b00100000;
parameter STATE_6 = 8'b01000000;
parameter STATE_7 = 8'b10000000;

reg [7:0] STATE;
reg [2:0] STATEIDX;

reg STATE_RESET, CYCLE_RESET, CYCLE_RESET_ACK;
reg SRAM_WE_MASK;
reg SRAM_OE_MASK;

reg [7:0] SRAM_WE_ARRAY [3:0];
reg [7:0] SRAM_OE_ARRAY [3:0];

reg [7:0] SNES_DATA_TO_MEM_ARRAY[1:0];
reg [7:0] AVR_DATA_TO_MEM_ARRAY[1:0];
reg [7:0] SRAM_DATA_TO_SNES_MEM_ARRAY[1:0];
reg [7:0] SRAM_DATA_TO_AVR_MEM_ARRAY[1:0];

reg [7:0] MODE_ARRAY;

reg SNES_READ_CYCLE;
reg SNES_WRITE_CYCLE;
reg AVR_READ_CYCLE;
reg AVR_WRITE_CYCLE;

reg SNES_DATABUS_OE_BUF;
reg SNES_DATABUS_DIR_BUF;

reg AVR_NEXTADDR_PREV_BUF;
reg AVR_NEXTADDR_CURR_BUF;

wire SNES_RW;

assign MODE = !AVR_ENA ? MODE_AVR : MODE_ARRAY[STATEIDX];

assign SNES_RW = (SNES_READ & SNES_WRITE);

initial begin
   CYCLE_RESET = 0;
   CYCLE_RESET_ACK = 0;
   
   STATE = STATE_7;
   STATEIDX = 7;
   SRAM_WE_MASK = 1'b1;
   SRAM_OE_MASK = 1'b1;
   SNES_READ_CYCLE = 1'b1;
   SNES_WRITE_CYCLE = 1'b1;
   AVR_READ_CYCLE = 1'b1;
   AVR_WRITE_CYCLE = 1'b1;

   MODE_ARRAY = 8'b00011111;
   
   SRAM_WE_ARRAY[2'b00] = 8'b10010011;
   SRAM_WE_ARRAY[2'b01] = 8'b10011111;
   SRAM_WE_ARRAY[2'b10] = 8'b11110011;
   SRAM_WE_ARRAY[2'b11] = 8'b11111111;

   SRAM_OE_ARRAY[2'b00] = 8'b11111111;
   SRAM_OE_ARRAY[2'b01] = 8'b11100000;
   SRAM_OE_ARRAY[2'b10] = 8'b00011111;
   SRAM_OE_ARRAY[2'b11] = 8'b00000000;
   
   SNES_DATA_TO_MEM_ARRAY[1'b0] = 8'b10000000;
   SNES_DATA_TO_MEM_ARRAY[1'b1] = 8'b00000000;
   
   AVR_DATA_TO_MEM_ARRAY[1'b0] = 8'b00010000;
   AVR_DATA_TO_MEM_ARRAY[1'b1] = 8'b00000000;
   
   SRAM_DATA_TO_SNES_MEM_ARRAY[1'b0] = 8'b00000000;
   SRAM_DATA_TO_SNES_MEM_ARRAY[1'b1] = 8'b00100000;
   
   SRAM_DATA_TO_AVR_MEM_ARRAY[1'b0] = 8'b00000000;
   SRAM_DATA_TO_AVR_MEM_ARRAY[1'b1] = 8'b00000010;  
   
   AVR_NEXTADDR_PREV_BUF = 0;
   AVR_NEXTADDR_CURR_BUF = 0;
end 

// falling edge of SNES /RD or /WR marks the beginning of a new cycle
// SNES READ or WRITE always starts @posedge CLK !!
// CPU cycle can be 6, 8 or 12 CLK cycles so we must satisfy
// the minimum of 6 cycles to get everything done.

always @(posedge CLK) begin
   if (!SNES_RW) begin
      if (!CYCLE_RESET_ACK) 
         CYCLE_RESET <= 1;
      else
         CYCLE_RESET <= 0;
   end
end

always @(posedge CLK) begin
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
              STATE_7: begin
                 if (SNES_RW) // check for end of SNES cycle to avoid looping
                     CYCLE_RESET_ACK <= 0;  // ready for new cycle
                 STATE <= STATE_7;
              end                 
              default:
                 STATE <= STATE_7;
           endcase
       end
end

always @(posedge CLK) begin
   case (STATE)
   
      STATE_7: begin
         SNES_READ_CYCLE <= SNES_READ;
         SNES_WRITE_CYCLE <= SNES_WRITE;
         AVR_READ_CYCLE <= AVR_READ;
         AVR_WRITE_CYCLE <= AVR_WRITE;
         STATEIDX <= 7;
      end
      STATE_0: begin
         STATEIDX <= 6;
      end
      
      STATE_1: begin
         STATEIDX <= 5;
      end
      
      STATE_2: begin
         STATEIDX <= 4;
      end
      
      STATE_3: begin
         STATEIDX <= 3;
      end
      
      STATE_4: begin
         STATEIDX <= 2;
      end
      
      STATE_5: begin
         STATEIDX <= 1;
      end
      
      STATE_6: begin
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

// dumb version
//assign SRAM_OE = !AVR_ENA ? AVR_READ : SNES_READ;
//assign SRAM_WE = !AVR_ENA ? AVR_WRITE : 1'b1;

always @(posedge CLK) begin
   SNES_DATABUS_OE_BUF <= SNES_CS | (SNES_READ & SNES_WRITE);
end

always @(posedge CLK) begin
   AVR_NEXTADDR_PREV_BUF <= AVR_NEXTADDR_CURR_BUF;
   AVR_NEXTADDR_CURR_BUF <= AVR_NEXTADDR;
end

assign AVR_NEXTADDR_PREV = AVR_NEXTADDR_PREV_BUF;
assign AVR_NEXTADDR_CURR = AVR_NEXTADDR_CURR_BUF;

//assign SNES_DATABUS_OE = (!IS_SAVERAM & SNES_CS) | (SNES_READ & SNES_WRITE);
assign SNES_DATABUS_OE = (IS_ROM & SNES_CS) | (!IS_ROM & !IS_SAVERAM) | (SNES_READ & SNES_WRITE);
assign SNES_DATABUS_DIR = !SNES_WRITE ? 1'b0 : 1'b1;

assign SNES_DATA_TO_MEM = SNES_DATA_TO_MEM_ARRAY[SNES_WRITE_CYCLE][STATEIDX];
assign AVR_DATA_TO_MEM = AVR_DATA_TO_MEM_ARRAY[AVR_WRITE_CYCLE][STATEIDX];

assign SRAM_DATA_TO_SNES_MEM = SRAM_DATA_TO_SNES_MEM_ARRAY[SNES_WRITE_CYCLE][STATEIDX];
assign SRAM_DATA_TO_AVR_MEM = SRAM_DATA_TO_AVR_MEM_ARRAY[AVR_WRITE_CYCLE][STATEIDX];

endmodule

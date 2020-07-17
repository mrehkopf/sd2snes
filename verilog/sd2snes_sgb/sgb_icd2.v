`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name:
// Module Name:    icd2
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`include "config.vh"

module sgb_icd2(
  input         RST,
  output        CPU_RST,
  input         CLK,
  output        CLK_CPU_EDGE,

  // MMIO interface
  input         SNES_RD_start,
  input         SNES_WR_end,
  input  [23:0] SNES_ADDR,
  input  [7:0]  DATA_IN,
  output [7:0]  DATA_OUT,

  input         BOOTROM_ACTIVE,
  
  // Pixel interface
  input         PPU_DOT_EDGE,
  input         PPU_PIXEL_VALID,
  input  [1:0]  PPU_PIXEL,
  input         PPU_VSYNC_EDGE,
  input         PPU_HSYNC_EDGE,  
  
  // Button/Serial interface
  input  [1:0]  P1I,
  output [3:0]  P1O,

  // Halt interface
  output        IDL,

  // Features
  input  [3:0]  FEAT,
  
  // Debug state
  input  [11:0] DBG_ADDR,
  output [7:0]  DBG_DATA_OUT
);

integer i;

//-------------------------------------------------------------------
// DESCRIPTION
//-------------------------------------------------------------------

// The ICD2 interfaces the SNES with the SGB via two points:
// SNES - cartridge bus
// SGB  - pixel output, button/serial
//
// The pixel interface takes the 2b PPU output and renders it back into a SNES
// 2bpp planar format before writing into 1 of 4 row (scanline) buffers.
// The 2b button interface serves as a way for the SGB to get the controller
// state from the SNES via ICD2 registers written over the SNES cart bus.
// The serial interface overloads the 2b button interface to transfer
// 16B packets to the SNES.  The SGB boot ROMs use this to transfer a
// portion of the GB header.  GB games may also be customized to generate these
// packets for SGB-enhanced content.

//-------------------------------------------------------------------
// Clocks
//-------------------------------------------------------------------

// GB Crystal - 20.97152 MHz
// GB Machine Frequency - 4.194304 MHz
// GB Bus Frequency - 1.048576 MHz

// To approximate the SGB2 frequency the SD2SNES implements a 84 MHz 
// base clock which may be further divided down.  With a skip
// clock every 737 base clocks the effective base frequency is:
//   84 MHz * 737 / 738 = 83.88618 MHz
// With /20 the frequency is roughly .00012% faster than the SGB2
// system clock.
//
// The CPU implementation is pipelined into a fetch and execute stage.
// Each stage is multiple base clocks some of which may be idle to
// pad out to the equivalent SGB2 clock.
//
// The clock logic generates clock edge signals in the base clock
// domain.
//
// The SGB supports a /4, /5 (default), /7, and /9 clock.  This is
// accounted for by adjusting the number of base clocks per CPU clock
// assertion.

reg  [9:0]  clk_skp_ctr_r; // in base domain
reg  [5:0]  clk_cpu_ctr_r; // in base domain
reg  [1:0]  clk_mult_r;

reg         clk_cpu_edge_r;

wire [1:0]  clk_mult;

// assert on every 737th clock (ctr == 736) of 84 MHz.
assign clk_skp_ast = clk_skp_ctr_r[9] & clk_skp_ctr_r[7] & clk_skp_ctr_r[6] & clk_skp_ctr_r[5];

// check for 15, 19, 27, and 35 based on divisor
assign clk_cpu_ast = ( ~clk_skp_ast
                     & ( (~clk_mult_r[1] & ~clk_mult_r[0] & &clk_cpu_ctr_r[3:0]                      ) // 16-1
                       | (~clk_mult_r[1] &  clk_mult_r[0] & &clk_cpu_ctr_r[4:4] & &clk_cpu_ctr_r[1:0]) // 20-1
                       | ( clk_mult_r[1] & ~clk_mult_r[0] & &clk_cpu_ctr_r[4:3] & &clk_cpu_ctr_r[1:0]) // 28-1
                       | ( clk_mult_r[1] &  clk_mult_r[0] & &clk_cpu_ctr_r[5:5] & &clk_cpu_ctr_r[1:0]) // 36-1
                       )
                     );

assign CLK_CPU_EDGE = clk_cpu_edge_r;

always @(posedge CLK) begin
  if (RST) begin
    clk_skp_ctr_r <= 0;
    clk_cpu_ctr_r <= 0;    
  end
  else begin  
    clk_skp_ctr_r <= clk_skp_ast ? 0 : clk_skp_ctr_r + 1;
    
    // The machine clock absorbs the skip clock since it's the primary that feeds all GB logic
    clk_cpu_ctr_r <= clk_skp_ast ? clk_cpu_ctr_r : (clk_cpu_ast ? 0 : (clk_cpu_ctr_r + 1));
    // arbitrary point assigned to define edge for cpu clock
    clk_cpu_edge_r <= clk_cpu_ast;
  end
end

// Generate a BUS clock edge from the incoming CPU clock edge.  The
// BUS clock is always /4.
reg  [1:0]  clk_bus_ctr_r; always @(posedge CLK) clk_bus_ctr_r <= RST ? 0 : clk_bus_ctr_r + (CLK_CPU_EDGE ? 1 : 0);
wire        CLK_BUS_EDGE = CLK_CPU_EDGE & &clk_bus_ctr_r;

// synchronize on bus edge
always @(posedge CLK) if (RST | CLK_BUS_EDGE) clk_mult_r <= clk_mult;

// Add a delay on cold reset since the SNES has to win the race to capture the buffer.  Do we need this for CPU reset, too?
reg  [15:0] rst_cnt_r;
always @(posedge CLK) if (RST) rst_cnt_r <= -1; else if (CLK_BUS_EDGE & |rst_cnt_r) rst_cnt_r <= rst_cnt_r - 1;

// Synchronize reset to bus edge.  Want a full bus clock prior to first edge assertion
reg         cpu_ireset_r; always @(posedge CLK) cpu_ireset_r <= RST | CPU_RST | (cpu_ireset_r & ~CLK_BUS_EDGE) | |rst_cnt_r;

//-------------------------------------------------------------------
// Row Buffers
//-------------------------------------------------------------------

`define ROW_CNT 4

wire        row_wren[`ROW_CNT-1:0];
wire [8:0]  row_address[`ROW_CNT-1:0];
wire [7:0]  row_rddata[`ROW_CNT-1:0];
wire [7:0]  row_wrdata[`ROW_CNT-1:0];

wire        dbg_row_wren[`ROW_CNT-1:0];
wire [8:0]  dbg_row_address[`ROW_CNT-1:0];
wire [7:0]  dbg_row_rddata[`ROW_CNT-1:0];
wire [7:0]  dbg_row_wrdata[`ROW_CNT-1:0];

`ifdef MK2
row_buf row0 (
  .clka(CLK), // input clka
  .wea(row_wren[0]), // input [0 : 0] wea
  .addra(row_address[0]), // input [8 : 0] addra
  .dina(row_wrdata[0]), // input [7 : 0] dina
  .douta(row_rddata[0]), // output [7 : 0] douta
  .clkb(CLK), // input clkb
  .web(dbg_row_wren[0]), // input [0 : 0] web
  .addrb(dbg_row_address[0]), // input [12 : 0] addrb
  .dinb(dbg_row_wrdata[0]), // input [7 : 0] dinb
  .doutb(dbg_row_rddata[0]) // output [7 : 0] doutb
);
row_buf row1 (
  .clka(CLK), // input clka
  .wea(row_wren[1]), // input [0 : 0] wea
  .addra(row_address[1]), // input [8 : 0] addra
  .dina(row_wrdata[1]), // input [7 : 0] dina
  .douta(row_rddata[1]), // output [7 : 0] douta
  .clkb(CLK), // input clkb
  .web(dbg_row_wren[1]), // input [0 : 0] web
  .addrb(dbg_row_address[1]), // input [12 : 0] addrb
  .dinb(dbg_row_wrdata[1]), // input [7 : 0] dinb
  .doutb(dbg_row_rddata[1]) // output [7 : 0] doutb
);
row_buf row2 (
  .clka(CLK), // input clka
  .wea(row_wren[2]), // input [0 : 0] wea
  .addra(row_address[2]), // input [8 : 0] addra
  .dina(row_wrdata[2]), // input [7 : 0] dina
  .douta(row_rddata[2]), // output [7 : 0] douta
  .clkb(CLK), // input clkb
  .web(dbg_row_wren[2]), // input [0 : 0] web
  .addrb(dbg_row_address[2]), // input [12 : 0] addrb
  .dinb(dbg_row_wrdata[2]), // input [7 : 0] dinb
  .doutb(dbg_row_rddata[2]) // output [7 : 0] doutb
);
row_buf row3 (
  .clka(CLK), // input clka
  .wea(row_wren[3]), // input [0 : 0] wea
  .addra(row_address[3]), // input [8 : 0] addra
  .dina(row_wrdata[3]), // input [7 : 0] dina
  .douta(row_rddata[3]), // output [7 : 0] douta
  .clkb(CLK), // input clkb
  .web(dbg_row_wren[3]), // input [0 : 0] web
  .addrb(dbg_row_address[3]), // input [12 : 0] addrb
  .dinb(dbg_row_wrdata[3]), // input [7 : 0] dinb
  .doutb(dbg_row_rddata[3]) // output [7 : 0] doutb
);
`endif
`ifdef MK3
row_buf row0 (
  .clock(CLK), // input clka
  .wren_a(row_wren[0]), // input [0 : 0] wea
  .address_a(row_address[0]), // input [8 : 0] addra
  .data_a(row_wrdata[0]), // input [7 : 0] dina
  .q_a(row_rddata[0]), // output [7 : 0] douta
  .wren_b(dbg_row_wren[0]), // input [0 : 0] web
  .address_b(dbg_row_address[0]), // input [12 : 0] addrb
  .data_b(dbg_row_wrdata[0]), // input [7 : 0] dinb
  .q_b(dbg_row_rddata[0]) // output [7 : 0] doutb
);

row_buf row1 (
  .clock(CLK), // input clka
  .wren_a(row_wren[1]), // input [0 : 0] wea
  .address_a(row_address[1]), // input [8 : 0] addra
  .data_a(row_wrdata[1]), // input [7 : 0] dina
  .q_a(row_rddata[1]), // output [7 : 0] douta
  .wren_b(dbg_row_wren[1]), // input [0 : 0] web
  .address_b(dbg_row_address[1]), // input [12 : 0] addrb
  .data_b(dbg_row_wrdata[1]), // input [7 : 0] dinb
  .q_b(dbg_row_rddata[1]) // output [7 : 0] doutb
);

row_buf row2 (
  .clock(CLK), // input clka
  .wren_a(row_wren[2]), // input [0 : 0] wea
  .address_a(row_address[2]), // input [8 : 0] addra
  .data_a(row_wrdata[2]), // input [7 : 0] dina
  .q_a(row_rddata[2]), // output [7 : 0] douta
  .wren_b(dbg_row_wren[2]), // input [0 : 0] web
  .address_b(dbg_row_address[2]), // input [12 : 0] addrb
  .data_b(dbg_row_wrdata[2]), // input [7 : 0] dinb
  .q_b(dbg_row_rddata[2]) // output [7 : 0] doutb
);

row_buf row3 (
  .clock(CLK), // input clka
  .wren_a(row_wren[3]), // input [0 : 0] wea
  .address_a(row_address[3]), // input [8 : 0] addra
  .data_a(row_wrdata[3]), // input [7 : 0] dina
  .q_a(row_rddata[3]), // output [7 : 0] douta
  .wren_b(dbg_row_wren[3]), // input [0 : 0] web
  .address_b(dbg_row_address[3]), // input [12 : 0] addrb
  .data_b(dbg_row_wrdata[3]), // input [7 : 0] dinb
  .q_b(dbg_row_rddata[3]) // output [7 : 0] doutb
);
`endif

//-------------------------------------------------------------------
// REG
//-------------------------------------------------------------------

`define PKT_CNT 16

`define LCDC_ROW_INDEX 1:0
`define LCDC_CHAR_ROW 7:3

reg  [7:0]  REG_LCDCHW_r;   // 6000 R
reg  [7:0]  REG_LCDCHR_r;   // 6001 W
reg  [7:0]  REG_PKTRDY_r;   // 6002 R
reg  [7:0]  REG_CTL_r;      // 6003 W
reg  [7:0]  REG_PAD_r[3:0]; // 6004-6007 W
reg  [7:0]  REG_VER_r;      // 600F R

reg  [7:0]  REG_PKT_r[`PKT_CNT-1:0];// 7000-700F R
reg  [7:0]  REG_CHDAT_r;    // 7800 R

reg  [7:0]  reg_mdr_r;
reg  [8:0]  reg_row_index_read_r;

reg         reg_pktrdy_clear_r;

assign DATA_OUT = reg_mdr_r;
assign CPU_RST  = ~REG_CTL_r[7];
assign clk_mult = REG_CTL_r[1:0];

always @(posedge CLK) begin
  if (cpu_ireset_r) begin
    REG_LCDCHR_r <= 0;      // 6001 W
    //REG_CTL_R <= 8'h01;
    for (i = 0; i < 4; i = i + 1) REG_PAD_r[i] <= 8'hFF;  // 6004-6007 W
    REG_VER_r    <= 8'h61;  // 600F R

    REG_CHDAT_r  <= 0;      // 7800-780F R

    reg_row_index_read_r <= 0;
    
    reg_pktrdy_clear_r <= 0;
  end
  else begin
    // It's important to flop the data early in the SNES read cycle so that concurrent
    // writes don't cause late changes on the bus which will lead to errors in the SNES.
    
    case (REG_CTL_r[5:4]) // 1(0),2(1),4(3) players enabled.  0 out if not enabled to avoid spurious presses
      0: begin REG_PAD_r[1] <= 8'hFF; REG_PAD_r[2] <= 8'hFF; REG_PAD_r[3] <= 8'hFF; end
      1: begin                        REG_PAD_r[2] <= 8'hFF; REG_PAD_r[3] <= 8'hFF; end
    endcase
    
    reg_pktrdy_clear_r <= 0;
    casez ({SNES_ADDR[22],SNES_ADDR[15:11],7'h00,SNES_ADDR[3:0]})
      {1'b0,16'h6000}: if (SNES_RD_start) reg_mdr_r         <= REG_LCDCHW_r; // R
      {1'b0,16'h6001}: begin
        if (SNES_WR_end) begin
          REG_LCDCHR_r[1:0]    <= DATA_IN[1:0]; // W
          reg_row_index_read_r <= 0;
        end
      end
      {1'b0,16'h6002}: if (SNES_RD_start) reg_mdr_r         <= REG_PKTRDY_r; // R
      //{1'b0,16'h6003}: if (SNES_WR_end)   {REG_CTL_r[7],REG_CTL_r[5:4],REG_CTL_r[1:0]} <= {DATA_IN[7],DATA_IN[5:4],DATA_IN[1:0]}; // W
      {1'b0,16'h6004}: if (SNES_WR_end)   REG_PAD_r[0]      <= DATA_IN;      // W
      {1'b0,16'h6005}: if (SNES_WR_end)   REG_PAD_r[1]      <= DATA_IN;      // W
      {1'b0,16'h6006}: if (SNES_WR_end)   REG_PAD_r[2]      <= DATA_IN;      // W
      {1'b0,16'h6007}: if (SNES_WR_end)   REG_PAD_r[3]      <= DATA_IN;      // W
      {1'b0,16'h600F}: if (SNES_RD_start) reg_mdr_r         <= REG_VER_r;    // R
      {1'b0,16'h700?}: begin
        if (SNES_RD_start) begin
          reg_mdr_r <= REG_PKT_r[SNES_ADDR[3:0]];
          // pulse PKTRDY clear
          if (SNES_ADDR[3:0] == 0) reg_pktrdy_clear_r <= 1;
        end
      end  
      {1'b0,16'h7800}: begin
        if (SNES_RD_start) begin
          reg_mdr_r            <= REG_CHDAT_r;  // R
          reg_row_index_read_r <= reg_row_index_read_r + 1;
        end
      end
    endcase
    
    REG_CHDAT_r <= row_rddata[REG_LCDCHR_r[`LCDC_ROW_INDEX]];
  end

  // COLD reset forces a complete reinit.  Otherwise this register is not affected by a WARM (CPU) reset.
  REG_CTL_r <= ( RST                                                                                       ? 8'h01
               : ({SNES_ADDR[22],SNES_ADDR[15:11],7'h00,SNES_ADDR[3:0]} == {1'b0,16'h6003} && SNES_WR_end) ? {DATA_IN[7],1'b0,DATA_IN[5:4],2'h0,DATA_IN[1:0]}
               :                                                                                             REG_CTL_r
               );
end

//-------------------------------------------------------------------
// PIXELS
//-------------------------------------------------------------------

reg  [8:0]  pix_row_index_r;
reg  [2:0]  pix_index_r;
reg  [7:0]  pix_data_r[1:0];

reg  [1:0]  pix_row_write_r;
reg  [8:0]  pix_row_index_write_r;

assign row_address[0] = (REG_LCDCHW_r[`LCDC_ROW_INDEX] == 0) ? {pix_row_index_write_r[8:1],pix_row_write_r[1]} : reg_row_index_read_r;
assign row_address[1] = (REG_LCDCHW_r[`LCDC_ROW_INDEX] == 1) ? {pix_row_index_write_r[8:1],pix_row_write_r[1]} : reg_row_index_read_r;
assign row_address[2] = (REG_LCDCHW_r[`LCDC_ROW_INDEX] == 2) ? {pix_row_index_write_r[8:1],pix_row_write_r[1]} : reg_row_index_read_r;
assign row_address[3] = (REG_LCDCHW_r[`LCDC_ROW_INDEX] == 3) ? {pix_row_index_write_r[8:1],pix_row_write_r[1]} : reg_row_index_read_r;

assign row_wrdata[0] = pix_data_r[pix_row_write_r[1]];
assign row_wrdata[1] = pix_data_r[pix_row_write_r[1]];
assign row_wrdata[2] = pix_data_r[pix_row_write_r[1]];
assign row_wrdata[3] = pix_data_r[pix_row_write_r[1]];

assign row_wren[0] = (REG_LCDCHW_r[`LCDC_ROW_INDEX] == 0) ? |pix_row_write_r : 0;
assign row_wren[1] = (REG_LCDCHW_r[`LCDC_ROW_INDEX] == 1) ? |pix_row_write_r : 0;
assign row_wren[2] = (REG_LCDCHW_r[`LCDC_ROW_INDEX] == 2) ? |pix_row_write_r : 0;
assign row_wren[3] = (REG_LCDCHW_r[`LCDC_ROW_INDEX] == 3) ? |pix_row_write_r : 0;

always @(posedge CLK) begin
  if (cpu_ireset_r) begin
    REG_LCDCHW_r <= 0;
    
    pix_row_index_r  <= 0;
    pix_index_r <= 0;
    
    pix_row_write_r <= 0;
  end
  else begin
    pix_row_write_r <= {pix_row_write_r[0],1'b0};
    
    if (PPU_DOT_EDGE) begin      
      if (PPU_PIXEL_VALID) begin
        pix_index_r <= pix_index_r + 1;

        // pack pixels into 2bpp planar format
        {pix_data_r[1][~pix_index_r[2:0]],pix_data_r[0][~pix_index_r[2:0]]} <= PPU_PIXEL;

        if (&pix_index_r) begin
          pix_row_index_r[8:4] <= pix_row_index_r[8:4] + 1;
          
          pix_row_write_r[0]    <= 1;
          pix_row_index_write_r <= pix_row_index_r;
        end        
      end
      else if (PPU_VSYNC_EDGE) begin
        pix_row_index_r[8:4] <= 0;
        pix_index_r          <= 0;
        
        REG_LCDCHW_r[`LCDC_CHAR_ROW] <= 0;
      end
      else if (PPU_HSYNC_EDGE) begin
        if (~REG_LCDCHW_r[7] | ~REG_LCDCHW_r[4]) begin
          pix_row_index_r[3:1] <= pix_row_index_r[3:1] + 1;
          pix_row_index_r[8:4] <= 0;
        
          if (pix_row_index_r[3:1] == 3'h7) begin
            REG_LCDCHW_r[`LCDC_ROW_INDEX] <= REG_LCDCHW_r[`LCDC_ROW_INDEX] + 1;
            REG_LCDCHW_r[`LCDC_CHAR_ROW]  <= REG_LCDCHW_r[`LCDC_CHAR_ROW] + 1;
          end
        end
      end
    end
  end
end

//-------------------------------------------------------------------
// BUTTON/SERIAL
//-------------------------------------------------------------------

parameter
  ST_BTN_IDLE     = 4'b0001,
  ST_BTN_RECV     = 4'b0010,
  ST_BTN_WAIT     = 4'b0100,
  ST_BTN_END      = 4'b1000;

reg  [3:0]  btn_state_r;
reg  [3:0]  btn_state_next_r;
reg  [1:0]  btn_prev_r;
reg  [1:0]  btn_curr_id_r;
reg  [6:0]  btn_bit_pos_r;
reg         btn_pktrdy_set_r;

// Output assignment is:
// IDLE P1I = 11 -> ~CurId (0=F,1=E,2=D,3=C)
// IDLE P1I = 01 -> ~Btn[7:0][CurID]  // buttons
// IDLE P1I = 10 -> ~Btn[15:8][CurID] // d-pad
// 
// IDLE P1I = 01 -> 10 or 11 -> Increment ID mod NumPad
assign P1O = ( (~^P1I       ) ? ~{2'h0,btn_curr_id_r}
             : (P1I == 2'b01) ? REG_PAD_r[btn_curr_id_r][7:4]
             : (P1I == 2'b10) ? REG_PAD_r[btn_curr_id_r][3:0]
             :                  4'h0 // should never get here
             );

assign IDL = |(btn_state_r & ST_BTN_IDLE);

always @(posedge CLK) begin
  if (cpu_ireset_r) begin
    REG_PKTRDY_r <= 0;
    for (i = 0; i < `PKT_CNT; i = i + 1) REG_PKT_r[i] <= 0;
    
    btn_state_r   <= ST_BTN_IDLE;
    btn_prev_r    <= 2'b00;
    btn_curr_id_r <= 0;
    
    btn_pktrdy_set_r <= 0;
  end
  else begin
    btn_pktrdy_set_r <= 0;

    if (CLK_CPU_EDGE) begin
      btn_prev_r <= P1I;

      if (P1I != btn_prev_r) begin
        if (~|P1I & (BOOTROM_ACTIVE | ~FEAT[`FEAT_ENH_OVERRIDE])) begin
          // *->00 from any state causes us to go to serial transfer mode
          // Is this true if we are already in serial transfer mode?  Convenient to assume so.
          btn_bit_pos_r <= 0;
          btn_state_next_r <= ST_BTN_RECV;
          
          btn_state_r <= ST_BTN_WAIT;
        end
        else begin
          case (btn_state_r)
            ST_BTN_IDLE: begin            
              if (~btn_prev_r[1] & P1I[1]) begin
                // 01->(10|11) transition increments id
                btn_curr_id_r <= (btn_curr_id_r + 1) & REG_CTL_r[5:4];
              end
            end
            ST_BTN_RECV: begin
              // 11 is considered a NOP
              
              if (^P1I) begin
                // Xilinx compiler silently fails to create logic if we use the following code:
                // REG_PKT_r[btn_bit_pos_r[6:3]][btn_bit_pos_r[2:0]] <= P1I[0];
                case (btn_bit_pos_r[6:3])
                  0:  REG_PKT_r[0 ][btn_bit_pos_r[2:0]] <= P1I[0];
                  1:  REG_PKT_r[1 ][btn_bit_pos_r[2:0]] <= P1I[0];
                  2:  REG_PKT_r[2 ][btn_bit_pos_r[2:0]] <= P1I[0];
                  3:  REG_PKT_r[3 ][btn_bit_pos_r[2:0]] <= P1I[0];
                  4:  REG_PKT_r[4 ][btn_bit_pos_r[2:0]] <= P1I[0];
                  5:  REG_PKT_r[5 ][btn_bit_pos_r[2:0]] <= P1I[0];
                  6:  REG_PKT_r[6 ][btn_bit_pos_r[2:0]] <= P1I[0];
                  7:  REG_PKT_r[7 ][btn_bit_pos_r[2:0]] <= P1I[0];
                  8:  REG_PKT_r[8 ][btn_bit_pos_r[2:0]] <= P1I[0];
                  9:  REG_PKT_r[9 ][btn_bit_pos_r[2:0]] <= P1I[0];
                  10: REG_PKT_r[10][btn_bit_pos_r[2:0]] <= P1I[0];
                  11: REG_PKT_r[11][btn_bit_pos_r[2:0]] <= P1I[0];
                  12: REG_PKT_r[12][btn_bit_pos_r[2:0]] <= P1I[0];
                  13: REG_PKT_r[13][btn_bit_pos_r[2:0]] <= P1I[0];
                  14: REG_PKT_r[14][btn_bit_pos_r[2:0]] <= P1I[0];
                  15: REG_PKT_r[15][btn_bit_pos_r[2:0]] <= P1I[0];
                endcase
              
                btn_bit_pos_r <= btn_bit_pos_r + 1;
  
                btn_state_next_r <= &btn_bit_pos_r ? ST_BTN_WAIT : ST_BTN_RECV;
                
                btn_state_r <= ST_BTN_WAIT;
              end
            end
            ST_BTN_WAIT: begin
              // 11 transition unless we are looping WAIT->WAIT->IDLE on 10 (TERM).
              if (P1I == {1'b1,~|(btn_state_next_r & ST_BTN_IDLE)}) begin
                // set packet ready if we are successfully transitioning to idle
                btn_pktrdy_set_r <= |(btn_state_next_r & ST_BTN_IDLE);
                btn_state_next_r <= ST_BTN_IDLE;
                
                btn_state_r <= btn_state_next_r;
              end
              else if (^P1I) begin
                // 10|01 are bad transitions when not waiting for terminating 10.  11 is NOP when we are waiting for 10.
                // exiting rather than ignoring these states seems to fix a few games like Bonk's Adventure (hang at start) and Pokemon Gold (no background)
                btn_state_r <= ST_BTN_IDLE;
              end
            end
          endcase
        end
      end
    end
    
    REG_PKTRDY_r[0] <= (REG_PKTRDY_r[0] & ~reg_pktrdy_clear_r) | btn_pktrdy_set_r;
  end
end
  
//-------------------------------------------------------------------
// DBG
//-------------------------------------------------------------------

`ifdef SGB_DEBUG
reg [7:0]   dbg_data_r = 0;

assign DBG_DATA_OUT = dbg_data_r;

assign dbg_row_address[0] = DBG_ADDR[8:0];
assign dbg_row_address[1] = DBG_ADDR[8:0];
assign dbg_row_address[2] = DBG_ADDR[8:0];
assign dbg_row_address[3] = DBG_ADDR[8:0];

assign dbg_row_wrdata[0] = 0;
assign dbg_row_wrdata[1] = 0;
assign dbg_row_wrdata[2] = 0;
assign dbg_row_wrdata[3] = 0;

assign dbg_row_wren[0] = 0;
assign dbg_row_wren[1] = 0;
assign dbg_row_wren[2] = 0;
assign dbg_row_wren[3] = 0;

always @(posedge CLK) begin
  if (~DBG_ADDR[11]) begin
    casez(DBG_ADDR[7:0])
      8'h00:    dbg_data_r <= REG_LCDCHW_r;
      8'h01:    dbg_data_r <= REG_LCDCHR_r;
      8'h02:    dbg_data_r <= REG_PKTRDY_r;
      8'h03:    dbg_data_r <= REG_CTL_r;
      8'h04:    dbg_data_r <= REG_PAD_r[0];
      8'h05:    dbg_data_r <= REG_PAD_r[1];
      8'h06:    dbg_data_r <= REG_PAD_r[2];
      8'h07:    dbg_data_r <= REG_PAD_r[3];
      8'h08:    dbg_data_r <= REG_CHDAT_r;
      8'h1?:    dbg_data_r <= REG_PKT_r[DBG_ADDR[3:0]];
      8'h20:    dbg_data_r <= P1I;
      8'h21:    dbg_data_r <= P1O;
      8'h22:    dbg_data_r <= btn_state_r;
      8'h23:    dbg_data_r <= btn_prev_r;
      8'h24:    dbg_data_r <= btn_curr_id_r;
      8'h25:    dbg_data_r <= btn_bit_pos_r;
      8'h30:    dbg_data_r <= REG_LCDCHW_r[`LCDC_CHAR_ROW];
      8'h31:    dbg_data_r <= REG_LCDCHW_r[`LCDC_ROW_INDEX];
      8'h32:    dbg_data_r <= pix_row_index_write_r[7:0];
      8'h33:    dbg_data_r <= pix_row_index_write_r[8];
      8'h34:    dbg_data_r <= reg_row_index_read_r[7:0];
      8'h35:    dbg_data_r <= reg_row_index_read_r[8];
      
      default:  dbg_data_r <= 0;
    endcase
  end
  else begin
    dbg_data_r <= dbg_row_rddata[DBG_ADDR[10:9]];
  end

end
`endif
  
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:31:43 08/22/2017 
// Design Name: 
// Module Name:    dma 
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
module dma(
  input clkin,
  input reset,
  input enable,

  input [3:0] reg_addr,
  input [7:0] reg_data_in,
  output [7:0] reg_data_out,

  input reg_oe_falling,
  input reg_we_rising,
  
  output loop_enable,

  input  BUS_RDY,
  output BUS_RRQ,
  output BUS_WRQ,
  
  output [23:0] ROM_ADDR,
  output [15:0] ROM_DATA_OUT,
  output        ROM_WORD_ENABLE,
  input  [15:0] ROM_DATA_IN
);

parameter ST_IDLE   = 0;
parameter ST_READ   = 1;
parameter ST_WRITE  = 2;
parameter ST_DONE   = 3;

parameter OP_COPY  = 0;
parameter OP_RESET = 1;
parameter OP_SET   = 2;
parameter OP_DEBUG = 3;

// Register bank
reg [7:0] dma_r[9:0];

reg [2:0]  state; initial state = ST_IDLE;

initial begin
  dma_r[0] = 8'h00; // dst bank
  dma_r[1] = 8'h00; // src bank
  dma_r[2] = 8'h00; // dst[7:0]
  dma_r[3] = 8'h00; // dst[15:8]
  dma_r[4] = 8'h00; // src[7:0]
  dma_r[5] = 8'h00; // src[15:0]
  dma_r[6] = 8'h00; // len[7:0]
  dma_r[7] = 8'h00; // len[15:8]
  dma_r[8] = 8'h00; // len[23:16]
  dma_r[9] = 8'h00; // opcode[7:3], loop, direction, trigger
end

reg [7:0] data_out_r;
assign reg_data_out = data_out_r;

integer i;
always @(posedge clkin) begin
  if(reg_oe_falling & enable) begin
    case(reg_addr)
      4'h0: data_out_r <= 8'h53;
      4'h1: data_out_r <= 8'h2D;
      4'h2: data_out_r <= 8'h44;
      4'h3: data_out_r <= 8'h4D;
      4'h4: data_out_r <= 8'h41;
      4'h5: data_out_r <= 8'h31;
      4'h9: data_out_r <= dma_r[reg_addr];
		  default: data_out_r <= 8'h00;
    endcase
  end
end

always @(posedge clkin) begin
  if (reset) begin
    for (i = 0; i < 10; i = i + 1) dma_r[i] <= 0;
  end
  else if(reg_we_rising & enable) begin
    dma_r[reg_addr] <= reg_data_in;
  end
  else if (state == ST_DONE) begin
    dma_r[9][0] <= 0;   // clear single-op trigger
  end
end

wire [23:0] SRC_ADDR, DST_ADDR, LEN;
wire [4:0] OPCODE;
wire LOOP, DIR, TRIG, WORD_MODE;

assign SRC_ADDR = {dma_r[1], dma_r[3], dma_r[2]};
assign DST_ADDR = {dma_r[0], dma_r[5], dma_r[4]};
assign LEN      = {dma_r[8], dma_r[7], dma_r[6]};
assign OPCODE   = dma_r[9][7:3];
assign LOOP     = dma_r[9][2];
assign DIR      = dma_r[9][1];
assign TRIG     = dma_r[9][0];
// this covers misaligned addresses, misaligned length, as well as byte overlaps
assign WORD_MODE = !SRC_ADDR[0] && !DST_ADDR[0] && !LEN[0];

reg [15:0] data;
reg [4:0]  opcode_r;
reg        loop_r;      initial loop_r = 0;
reg        dir_r;
reg        trig_r;      initial trig_r = 0;
reg        word_mode_r;
reg [23:0] src_addr_r, dst_addr_r, length_r, mod_r;

// 1-trigger queue: the savestate handler fires its second op without polling, so a
// trigger arriving while the copier is busy is latched with the op snapshotted and
// started in ST_IDLE.  One slot is all it needs; a further trigger while one is
// already pending is dropped, as every trigger during a busy copier was before.
reg        pending;     initial pending = 0;
reg [23:0] shadow_src, shadow_dst, shadow_len;
reg        shadow_word, shadow_dir;
reg [4:0]  shadow_op;
wire op_kick = reg_we_rising & enable & (reg_addr == 4'd9) & reg_data_in[0];

assign BUS_RRQ = BUS_RDY && (state == ST_READ);
assign BUS_WRQ = BUS_RDY && (state == ST_WRITE);
assign ROM_ADDR = (state == ST_READ) ? src_addr_r : dst_addr_r;
assign ROM_DATA_OUT =   (opcode_r == OP_COPY)  ? (dst_addr_r[0] ? {ROM_DATA_IN[7:0],ROM_DATA_IN[15:8]} : ROM_DATA_IN)
                      : (opcode_r == OP_RESET) ? 16'h0000
                      : (opcode_r == OP_SET)   ? 16'hFFFF
                      : (opcode_r == OP_DEBUG) ? {dst_addr_r[3:0],loop_enable,ROM_WORD_ENABLE,mod_r[1:0],dst_addr_r[3:0],loop_enable,ROM_WORD_ENABLE,mod_r[1:0]}
                      : 0;
assign ROM_WORD_ENABLE = word_mode_r;
assign loop_enable = loop_r;
wire [23:0] length_next = length_r - (word_mode_r ? 2 : 1);

always @(posedge clkin) begin
  if (reset) begin
    loop_r    <= 0;
    state     <= ST_IDLE;
    trig_r    <= 0;
    pending   <= 0;
  end
  else begin
    trig_r  <= TRIG;

    // when idle the fresh trigger is handled by the op_kick path below
    if (op_kick && (state != ST_IDLE) && !pending) begin
      pending     <= 1'b1;
      shadow_src  <= SRC_ADDR;
      shadow_dst  <= DST_ADDR;
      shadow_len  <= LEN;
      shadow_word <= WORD_MODE;
      shadow_op   <= reg_data_in[7:3];  // dma_r[9] being written this cycle
      shadow_dir  <= reg_data_in[1];
    end

    case (state)
      ST_IDLE: begin
        if (pending) begin
          // start the op snapshotted while the previous one ran
          src_addr_r  <= shadow_src;
          dst_addr_r  <= shadow_dst;
          length_r    <= shadow_len;
          mod_r       <= shadow_word ? (shadow_dir ? -2 : 2) : (shadow_dir ? -1 : 1);
          opcode_r    <= shadow_op;
          word_mode_r <= shadow_word;
          dir_r       <= shadow_dir;
          loop_r      <= 0;
          pending     <= 0;
          if (shadow_op == OP_COPY) state <= ST_READ;
          else                      state <= ST_WRITE;
        end
        else if (op_kick) begin
          // Single-op start, detected by the dma_r[9] write rather than a TRIG
          // edge: robust to the bit already being 1, which happens when a colliding
          // register write skips the ST_DONE clear.
          src_addr_r  <= SRC_ADDR;
          dst_addr_r  <= DST_ADDR;
          length_r    <= LEN;
          mod_r       <= WORD_MODE ? (reg_data_in[1] ? -2 : 2) : (reg_data_in[1] ? -1 : 1);
          opcode_r    <= reg_data_in[7:3];
          loop_r      <= reg_data_in[2];
          dir_r       <= reg_data_in[1];
          word_mode_r <= WORD_MODE;

          if (reg_data_in[7:3] == OP_COPY) state <= ST_READ;
          else                             state <= ST_WRITE;
        end
      end
      ST_READ: begin
        if (BUS_RDY) begin
          src_addr_r <= src_addr_r + mod_r;
          state <= ST_WRITE;
        end
      end
      ST_WRITE: begin
        if (BUS_RDY) begin
          dst_addr_r <= dst_addr_r + mod_r;
          length_r <= length_next;

          if      (length_next == 0)    state <= ST_DONE;
          else if (opcode_r == OP_COPY) state <= ST_READ;
          else                          state <= ST_WRITE;
        end
      end
      ST_DONE: begin
        loop_r <= 0;
        state  <= ST_IDLE;
      end
    endcase
  end
end

endmodule

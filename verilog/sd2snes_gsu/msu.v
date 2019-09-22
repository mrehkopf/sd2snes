`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    14:55:04 12/14/2010
// Design Name:
// Module Name:    msu
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
module msu(
  input clkin,
  input enable,
  input [13:0] pgm_address,
  input [7:0] pgm_data,
  input pgm_we,
  input [2:0] reg_addr,
  input [7:0] reg_data_in,
  output [7:0] reg_data_out,
  input reg_oe_falling,
  input reg_oe_rising,
  input reg_we_rising,
  output [7:0] status_out,
  output [7:0] volume_out,
  output volume_latch_out,
  output [31:0] addr_out,
  output [15:0] track_out,
  input [5:0] status_reset_bits,
  input [5:0] status_set_bits,
  input status_reset_we,
  input [13:0] msu_address_ext,
  input msu_address_ext_write,

  output DBG_msu_reg_oe_rising,
  output DBG_msu_reg_oe_falling,
  output DBG_msu_reg_we_rising,
  output [13:0] DBG_msu_address,
  output DBG_msu_address_ext_write_rising
);

`define MSU

`ifndef MSU
assign reg_data_out = 0;

assign status_out = 0;
assign volume_out = 0;
assign volume_latch_out = 0;
assign addr_out = 0;
assign track_out = 0;

assign DBG_msu_reg_oe_rising = 0;
assign DBG_msu_reg_oe_falling = 0;
assign DBG_msu_reg_we_rising = 0;
assign DBG_msu_address = 0;
assign DBG_msu_address_ext_write_rising = 0;
`else
reg [1:0] status_reset_we_r;
always @(posedge clkin) status_reset_we_r = {status_reset_we_r[0], status_reset_we};
wire status_reset_en = (status_reset_we_r == 2'b01);

reg [13:0] msu_address_r;
wire [13:0] msu_address = msu_address_r;
initial msu_address_r = 13'b0;

wire [7:0] msu_data;
reg [7:0] msu_data_r;

reg [2:0] msu_address_ext_write_sreg;
always @(posedge clkin)
  msu_address_ext_write_sreg <= {msu_address_ext_write_sreg[1:0], msu_address_ext_write};
wire msu_address_ext_write_rising = (msu_address_ext_write_sreg[2:1] == 2'b01);

reg [31:0] addr_out_r;
assign addr_out = addr_out_r;

reg [15:0] track_out_r;
assign track_out = track_out_r;

reg [7:0] volume_r;
assign volume_out = volume_r;

reg volume_start_r;
assign volume_latch_out = volume_start_r;

reg audio_start_r;
reg audio_busy_r;
reg data_start_r;
reg data_busy_r;
reg ctrl_start_r;
reg audio_error_r;
reg [2:0] audio_ctrl_r;
reg [1:0] audio_status_r;

initial begin
  audio_busy_r = 1'b1;
  data_busy_r = 1'b1;
  audio_error_r = 1'b0;
  volume_r = 8'h00;
  addr_out_r = 32'h00000000;
  track_out_r = 16'h0000;
  data_start_r = 1'b0;
  audio_start_r = 1'b0;
end

assign DBG_msu_address = msu_address;
assign DBG_msu_reg_oe_rising = reg_oe_rising;
assign DBG_msu_reg_oe_falling = reg_oe_falling;
assign DBG_msu_reg_we_rising = reg_we_rising;
assign DBG_msu_address_ext_write_rising = msu_address_ext_write_rising;

assign status_out = {msu_address_r[13], // 7
                     audio_start_r,     // 6
                     data_start_r,      // 5
                     volume_start_r,    // 4
                     audio_ctrl_r,      // 3:1
                     ctrl_start_r};     // 0

initial msu_address_r = 14'h1234;

`ifdef MK2
msu_databuf snes_msu_databuf (
  .clka(clkin),
  .wea(~pgm_we), // Bus [0 : 0]
  .addra(pgm_address), // Bus [13 : 0]
  .dina(pgm_data), // Bus [7 : 0]
  .clkb(clkin),
  .addrb(msu_address), // Bus [13 : 0]
  .doutb(msu_data)
); // Bus [7 : 0]
`endif
`ifdef MK3
msu_databuf snes_msu_databuf (
  .clock(clkin),
  .wren(~pgm_we), // Bus [0 : 0]
  .wraddress(pgm_address), // Bus [13 : 0]
  .data(pgm_data), // Bus [7 : 0]
  .rdaddress(msu_address), // Bus [13 : 0]
  .q(msu_data)
); // Bus [7 : 0]
`endif
reg [7:0] data_out_r;
assign reg_data_out = data_out_r;

always @(posedge clkin) begin
  if(msu_address_ext_write_rising)
    msu_address_r <= msu_address_ext;
  else if(reg_oe_rising & enable & (reg_addr == 3'h1)) begin
    msu_address_r <= msu_address_r + 1;
  end
end

always @(posedge clkin) begin
  if(reg_oe_falling & enable)
    case(reg_addr)
      3'h0: data_out_r <= {data_busy_r, audio_busy_r, audio_status_r, audio_error_r, 3'b001};
      3'h1: data_out_r <= msu_data;
      3'h2: data_out_r <= 8'h53;
      3'h3: data_out_r <= 8'h2d;
      3'h4: data_out_r <= 8'h4d;
      3'h5: data_out_r <= 8'h53;
      3'h6: data_out_r <= 8'h55;
      3'h7: data_out_r <= 8'h31;
    endcase
end

always @(posedge clkin) begin
  if(reg_we_rising & enable) begin
    case(reg_addr)
      3'h0: addr_out_r[7:0] <= reg_data_in;
      3'h1: addr_out_r[15:8] <= reg_data_in;
      3'h2: addr_out_r[23:16] <= reg_data_in;
      3'h3: begin
        addr_out_r[31:24] <= reg_data_in;
        data_start_r <= 1'b1;
        data_busy_r <= 1'b1;
      end
      3'h4: begin
        track_out_r[7:0] <= reg_data_in;
      end
      3'h5: begin
        track_out_r[15:8] <= reg_data_in;
        audio_start_r <= 1'b1;
        audio_busy_r <= 1'b1;
      end
      3'h6: begin
        volume_r <= reg_data_in;
        volume_start_r <= 1'b1;
      end
      3'h7: begin
        if(!audio_busy_r) begin
          audio_ctrl_r <= reg_data_in[2:0];
          ctrl_start_r <= 1'b1;
        end
      end
    endcase
  end else if (status_reset_en) begin
    audio_busy_r <= (audio_busy_r | status_set_bits[5]) & ~status_reset_bits[5];
    if(status_reset_bits[5]) audio_start_r <= 1'b0;
    data_busy_r <= (data_busy_r | status_set_bits[4]) & ~status_reset_bits[4];
    if(status_reset_bits[4]) data_start_r <= 1'b0;
    audio_error_r <= (audio_error_r | status_set_bits[3]) & ~status_reset_bits[3];
    audio_status_r <= (audio_status_r | status_set_bits[2:1]) & ~status_reset_bits[2:1];
    ctrl_start_r <= (ctrl_start_r | status_set_bits[0]) & ~status_reset_bits[0];
  end else begin
    volume_start_r <= 1'b0;
  end
end
`endif

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    21:16:09 07/10/2009
// Design Name:
// Module Name:    spi
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
module spi(
  input clk,
  input SCK,
  input MOSI,
  inout MISO,
  input SSEL,
  output cmd_ready,
  output param_ready,
  output [7:0] cmd_data,
  output [7:0] param_data,
  output endmessage,
  output startmessage,
  input [7:0] input_data,
  output [31:0] byte_cnt,
  output [2:0] bit_cnt
);

reg [7:0] cmd_data_r;
reg [7:0] param_data_r;

reg [2:0] SSELr;
reg [2:0] SSELSCKr;

always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
always @(posedge SCK) SSELSCKr <= {SSELSCKr[1:0], SSEL};

wire SSEL_inactive = SSELr[1];
wire SSEL_active = ~SSELr[1];  // SSEL is active low
wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge
assign endmessage = SSEL_endmessage;
assign startmessage = SSEL_startmessage;

// bit count for one SPI byte + byte count for the message
reg [2:0] bitcnt;
initial bitcnt = 3'b000;
wire bitcnt_msb = bitcnt[2];
reg [2:0] bitcnt_wrap_r;
always @(posedge clk) bitcnt_wrap_r <= {bitcnt_wrap_r[1:0], bitcnt_msb};
wire byte_received_sync = (bitcnt_wrap_r[2:1] == 2'b10);

reg [31:0] byte_cnt_r;

reg byte_received;  // high when a byte has been received
reg [7:0] byte_data_received;

assign bit_cnt = bitcnt;

always @(posedge SCK) begin
  if(SSELSCKr[1]) bitcnt <= 3'b000;
  else bitcnt <= bitcnt + 3'b001;
end

always @(posedge SCK) begin
  if(~SSELSCKr[1])
    byte_data_received <= {byte_data_received[6:0], MOSI};
  if(~SSELSCKr[1] && bitcnt==3'b111)
    byte_received <= 1'b1;
  else byte_received <= 1'b0;
end

//reg [2:0] byte_received_r;
//always @(posedge clk) byte_received_r <= {byte_received_r[1:0], byte_received};
//wire byte_received_sync = (byte_received_r[2:1] == 2'b01);

always @(posedge clk) begin
  if(SSEL_inactive)
    byte_cnt_r <= 16'h0000;
  else if(byte_received_sync)
    byte_cnt_r <= byte_cnt_r + 16'h0001;
end

reg [7:0] byte_data_sent;

assign MISO = ~SSEL ? input_data[7-bitcnt] : 1'bZ;  // send MSB first

reg cmd_ready_r;
reg param_ready_r;
reg cmd_ready_r2;
reg param_ready_r2;
assign cmd_ready = cmd_ready_r;
assign param_ready = param_ready_r;
assign cmd_data = cmd_data_r;
assign param_data = param_data_r;
assign byte_cnt = byte_cnt_r;

always @(posedge clk) cmd_ready_r2 = byte_received_sync && byte_cnt_r == 32'h0;
always @(posedge clk) param_ready_r2 = byte_received_sync && byte_cnt_r > 32'h0;

// fill registers
always @(posedge clk) begin
  if (SSEL_startmessage)
    cmd_data_r <= 8'h00;
  else if(cmd_ready_r2)
    cmd_data_r <= byte_data_received;
  else if(param_ready_r2)
    param_data_r <= byte_data_received;
end

// delay ready signals by one clock
always @(posedge clk) begin
  cmd_ready_r <= cmd_ready_r2;
  param_ready_r <= param_ready_r2;
end

endmodule

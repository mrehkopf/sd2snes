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

// sync SCK to the FPGA clock using a 3-bits shift register
reg [2:0] SCKr;
always @(posedge clk) SCKr <= {SCKr[1:0], SCK};

wire SCK_risingedge = (SCKr[1:0]==2'b01);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCKr[1:0]==2'b10);  // and falling edges

// same thing for SSEL
reg [2:0] SSELr;  always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
wire SSEL_active = ~SSELr[1];  // SSEL is active low
wire SSEL_startmessage = (SSELr[1:0]==2'b10);  // message starts at falling edge
wire SSEL_endmessage = (SSELr[1:0]==2'b01);  // message stops at rising edge
assign endmessage = SSEL_endmessage;
assign startmessage = SSEL_startmessage;

// and for MOSI
reg [1:0] MOSIr;  always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
wire MOSI_data = MOSIr[0];

// bit count for one SPI byte + byte count for the message
reg [2:0] bitcnt;
reg [31:0] byte_cnt_r;

reg byte_received;  // high when a byte has been received
reg [7:0] byte_data_received;

assign bit_cnt = bitcnt;

always @(posedge clk)
begin
  if(~SSEL_active) begin
    bitcnt <= 3'b000;
  end
  else if(SCK_risingedge) begin
    bitcnt <= bitcnt + 3'b001;
    // shift received data into the register
    byte_data_received <= {byte_data_received[6:0], MOSI_data};
  end
end

always @(posedge clk)
  byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'b111);

always @(posedge clk) begin
  if(~SSEL_active)
    byte_cnt_r <= 16'h0000;
  else if(byte_received) begin
    byte_cnt_r <= byte_cnt_r + 16'h0001;
  end
end

reg [7:0] byte_data_sent;

always @(posedge clk) begin
  if(SSEL_active) begin
    if(SSEL_startmessage)
      byte_data_sent <= 8'h5A;  // dummy byte
    else
      if(SCK_fallingedge) begin
        if(bitcnt==3'b000)
          byte_data_sent <= input_data; // after that, we send whatever we get
        else
          byte_data_sent <= {byte_data_sent[6:0], 1'b0};
      end
  end
end

assign MISO = SSEL_active ? byte_data_sent[7] : 1'bZ;  // send MSB first

reg cmd_ready_r;
reg param_ready_r;
reg cmd_ready_r2;
reg param_ready_r2;
assign cmd_ready = cmd_ready_r;
assign param_ready = param_ready_r;
assign cmd_data = cmd_data_r;
assign param_data = param_data_r;
assign byte_cnt = byte_cnt_r;

always @(posedge clk) cmd_ready_r2 = byte_received && byte_cnt_r == 32'h0;
always @(posedge clk) param_ready_r2 = byte_received && byte_cnt_r > 32'h0;

// fill registers
always @(posedge clk) begin
  if (SSEL_startmessage)
    cmd_data_r <= 8'h00;
  else if(cmd_ready_r2)
    cmd_data_r <= byte_data_received;
  else if(param_ready_r2)
    param_data_r <= byte_data_received;
end

// delay ready signals by one clock (why did I do this again...)
always @(posedge clk) begin
  cmd_ready_r <= cmd_ready_r2;
  param_ready_r <= param_ready_r2;
end

endmodule

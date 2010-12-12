`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:26:11 07/23/2010 
// Design Name: 
// Module Name:    dac_test 
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
module dac_test(
    input clkin,
    output sdout,
    output lrck,
    output mclk
    );
	 
reg [15:0] cnt;
reg [15:0] smpcnt;
wire [15:0] sample = {smpcnt[10] ? ~smpcnt[9:0] : smpcnt[9:0], 6'b0};
wire [15:0] sample2 = {smpcnt[9] ? ~smpcnt[8:0] : smpcnt[8:0], 7'b0};
reg [15:0] smpshift;

assign mclk = cnt[3];   // mclk = clk/8
assign lrck = cnt[11];	// lrck = mclk/256
wire sclk = cnt[6];		// sclk = lrck*32

reg [7:0] volume;
reg [1:0] lrck_sreg;
reg sclk_sreg;
wire lrck_rising = ({lrck_sreg[0],lrck} == 2'b01);
wire lrck_falling = ({lrck_sreg[0],lrck} == 2'b10);

wire sclk_rising = ({sclk_sreg, sclk} == 2'b01);

reg sdout_reg;
assign sdout = sdout_reg;

initial begin
	cnt = 16'b0;
	smpcnt = 16'b0;
	lrck_sreg = 2'b0;
	sclk_sreg = 1'b0;
	volume = 8'b0;
end

always @(posedge clkin) begin
	cnt <= cnt + 1;
	lrck_sreg <= {lrck_sreg[0], lrck};
	sclk_sreg <= sclk;
end

always @(posedge clkin) begin
   if (lrck_rising) begin	// right channel
		smpshift <= (({16'h0, sample} * volume) >> 8) ^ 16'h8000; // convert to signed
	end else if (lrck_falling) begin		// left channel
		smpshift <= (({16'h0, sample2} * volume) >> 8) ^ 16'h8000;
	end else begin
		if (sclk_rising) begin
			smpcnt <= smpcnt + 1;
			sdout_reg <= smpshift[15];
			smpshift <= {smpshift[14:0], 1'b0};
		end
	end
end

endmodule

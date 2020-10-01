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
module dac(
  input clkin,
  input sysclk,
  input we,
  input[10:0] pgm_address,
  input[7:0] pgm_data,
  input play,
  input reset,
  output sdout,
  output lrck,
  output mclk,
  output DAC_STATUS
);

reg[8:0] dac_address_r;
wire[8:0] dac_address = dac_address_r;

wire[31:0] dac_data;
assign DAC_STATUS = dac_address_r[8];
reg[7:0] vol_reg;
reg[7:0] vol_target_reg;
reg[1:0] vol_latch_reg;
reg vol_valid;
reg[2:0] sysclk_sreg;
wire sysclk_rising = (sysclk_sreg[2:1] == 2'b01);

reg [25:0] interpol_count;

always @(posedge clkin) begin
  sysclk_sreg <= {sysclk_sreg[1:0], sysclk};
end

`ifdef MK2
dac_buf snes_dac_buf (
  .clka(clkin),
  .wea(~we), // Bus [0 : 0]
  .addra(pgm_address), // Bus [10 : 0]
  .dina(pgm_data), // Bus [7 : 0]
  .clkb(clkin),
  .addrb(dac_address), // Bus [8 : 0]
  .doutb(dac_data)); // Bus [31 : 0]
`endif

`ifdef MK3
dac_buf snes_dac_buf (
  .clock(clkin),
  .wren(~we), // Bus [0 : 0]
  .wraddress(pgm_address), // Bus [10 : 0]
  .data(pgm_data), // Bus [7 : 0]
  .rdaddress(dac_address), // Bus [8 : 0]
  .q(dac_data)); // Bus [31 : 0]
`endif

reg [8:0] cnt;
reg [15:0] smpcnt;
reg [1:0] samples;
reg [15:0] smpshift;

assign mclk = cnt[2]; // mclk = clk/8
assign lrck = cnt[8]; // lrck = mclk/128
wire sclk = cnt[3];   // sclk = lrck*32

reg [2:0] lrck_sreg;
reg [2:0] sclk_sreg;
wire lrck_rising = ({lrck_sreg[2:1]} == 2'b01);
wire lrck_falling = ({lrck_sreg[2:1]} == 2'b10);

wire sclk_rising = ({sclk_sreg[2:1]} == 2'b01);

reg sdout_reg;
assign sdout = sdout_reg;

reg [1:0] reset_sreg;
wire reset_rising = (reset_sreg[1:0] == 2'b01);

reg play_r;

initial begin
  cnt = 9'h100;
  smpcnt = 16'b0;
  lrck_sreg = 2'b11;
  sclk_sreg = 1'b0;
  dac_address_r = 10'b0;
  vol_valid = 1'b0;
  vol_latch_reg = 1'b0;
  vol_reg = 8'h0;
  vol_target_reg = 8'hff;
  samples <= 2'b00;
end

always @(posedge clkin) begin
  if(reset_rising) begin
    dac_address_r <= 0;
    interpol_count <= 0;
  end else if(sysclk_rising) begin
    if(interpol_count > 59378938) begin
      interpol_count <= interpol_count + 122500 - 59501439;
      dac_address_r <= dac_address_r + play_r;
    end else begin
      interpol_count <= interpol_count + 122500;
    end
  end
end

always @(posedge clkin) begin
  cnt <= cnt + 1;
  lrck_sreg <= {lrck_sreg[1:0], lrck};
  sclk_sreg <= {sclk_sreg[1:0], sclk};
  play_r <= play;
  reset_sreg <= {reset_sreg[0], reset};
end

// ramp volume only every 4 samples
always @(posedge clkin) begin
  if (lrck_rising && &samples[1:0]) begin
    if(vol_reg > vol_target_reg)
      vol_reg <= vol_reg - 1;
    else if(vol_reg < vol_target_reg)
      vol_reg <= vol_reg + 1;
  end
end

always @(posedge clkin) begin
  if (lrck_rising) begin // right channel
    smpshift <= (({16'h0, dac_data[31:16]^16'h8000} * vol_reg) >> 8) ^ 16'h8000;
    samples <= samples + 1;
  end else if (lrck_falling) begin // left channel
    smpshift <= (({16'h0, dac_data[15:0]^16'h8000} * vol_reg) >> 8) ^ 16'h8000;
  end else begin
    if (sclk_rising) begin
      smpcnt <= smpcnt + 1;
      sdout_reg <= smpshift[15];
      smpshift <= {smpshift[14:0], 1'b0};
    end
  end
end

endmodule

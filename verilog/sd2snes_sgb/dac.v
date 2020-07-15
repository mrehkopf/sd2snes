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
`include "config.vh"

module dac(
  input clkin,
  input sysclk,
  input we,
  input[10:0] pgm_address,
  input[7:0] pgm_data,
  input[7:0] volume,
  input [19:0] sgb_apu_dat,
  input        sgb_apu_clk_edge,
  input vol_latch,
  input [2:0] vol_select,
  input [8:0] dac_address_ext,
  input play,
  input reset,
  input palmode,
  output sdout,
  output mclk_out,
  output lrck_out,
  output sclk_out,
  output DAC_STATUS
);

integer i;

reg[8:0] dac_address_r;
reg[8:0] dac_address_r_sync;
wire[8:0] dac_address = dac_address_r_sync;

wire[31:0] dac_data;
assign DAC_STATUS = dac_address_r[8];
reg[10:0] vol_reg;
reg[10:0] vol_target_reg;
reg[1:0] vol_latch_reg;
reg vol_valid;
reg[2:0] sysclk_sreg;
wire sysclk_rising = (sysclk_sreg[2:1] == 2'b01);

reg[8:0] sgb_vol_reg = 9'h100;

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

reg [10:0] cnt;
reg [15:0] smpcnt;
reg [1:0] samples;
reg [15:0] smpshift;

wire mclk = cnt[2]; // mclk = clk/8
wire lrck = cnt[8]; // lrck = mclk/64
wire sclk = cnt[3]; // sclk = lrck*32

reg [2:0] mclk_sreg;
reg [2:0] lrck_sreg;
reg [1:0] sclk_sreg;

assign mclk_out = ~mclk_sreg[2];
assign lrck_out = lrck_sreg[2];
assign sclk_out = sclk_sreg[1];

wire lrck_rising = ({lrck_sreg[0],lrck} == 2'b01);
wire lrck_falling = ({lrck_sreg[0],lrck} == 2'b10);

wire sclk_rising = ({sclk_sreg[0],sclk} == 2'b01);
wire sclk_falling = ({sclk_sreg[0],sclk} == 2'b10);

wire vol_latch_rising = (vol_latch_reg[1:0] == 2'b01);
reg sdout_reg;
assign sdout = sdout_reg;

reg play_r;

initial begin
  cnt = 9'h100;
  smpcnt = 16'b0;
  lrck_sreg = 2'b00;
  sclk_sreg = 2'b00;
  mclk_sreg = 2'b00;
  dac_address_r = 9'b0;
  vol_valid = 1'b0;
  vol_latch_reg = 1'b0;
  vol_reg = 9'h000;
  vol_target_reg = 9'h000;
  samples <= 2'b00;
end

/*
  21477272.727272... /  37500 *  1232 = 44100 * 16
  21281370           / 709379 * 23520 = 44100 * 16
*/
reg [19:0] phaseacc = 0;
wire [14:0] phasemul = (palmode ? 23520 : 1232);
wire [19:0] phasediv = (palmode ? 709379 : 37500);
reg [3:0] subcount = 0;

reg int_strobe = 0, comb_strobe = 0;

always @(posedge clkin) begin
  int_strobe <= 0;
  comb_strobe <= 0;
  if(reset) begin
    dac_address_r <= dac_address_ext;
    phaseacc <= 0;
    subcount <= 0;
  end else if(sysclk_rising) begin
    if(phaseacc >= phasediv) begin
      phaseacc <= phaseacc - phasediv + phasemul;
      subcount <= subcount + 1;
      int_strobe <= 1;
      if (subcount == 0) begin
        comb_strobe <= 1;
        dac_address_r <= dac_address_r + play_r;
      end
    end else begin
      phaseacc <= phaseacc + phasemul;
    end
  end
end

parameter ST0_IDLE  = 10'b1000000000;
parameter ST1_COMB1 = 10'b0000000001;
parameter ST2_COMB2 = 10'b0000000010;
parameter ST3_COMB3 = 10'b0000000100;
parameter ST4_INT1  = 10'b0000010000;
parameter ST5_INT2  = 10'b0000100000;
parameter ST6_INT3  = 10'b0001000000;

`define MSU_CIC_BITS (16+3*4) // 3 stages, *16 (2^4)

reg [(`MSU_CIC_BITS-1):0] ci[2:0][1:0], co[2:0][1:0], io[2:0][1:0];
reg [9:0] cicstate = 10'h200;
wire [(`MSU_CIC_BITS-1):0] bufi[1:0];
assign bufi[1] = {{(`MSU_CIC_BITS-16){dac_data[31]}}, dac_data[31:16]};
assign bufi[0] = {{(`MSU_CIC_BITS-16){dac_data[15]}}, dac_data[15:0]};

`ifdef MSU_AUDIO
always @(posedge clkin) begin
  if(reset) begin
    cicstate <= ST0_IDLE;
    for (i = 0; i < 2; i = i + 1) begin
      {ci[2][i], ci[1][i], ci[0][i]} <= 0;
      {co[2][i], co[1][i], co[0][i]} <= 0;
      {io[2][i], io[1][i], io[0][i]} <= 0;
    end
  end else if(int_strobe) begin
    if(comb_strobe) cicstate <= ST1_COMB1;
    else cicstate <= ST4_INT1;
  end else begin
    case(cicstate)
/****** COMB STAGES ******/
      ST1_COMB1: begin
        cicstate <= ST2_COMB2;
        for (i = 0; i < 2; i = i + 1) begin
          ci[0][i] <= bufi[i];
          co[0][i] <= bufi[i] - ci[0][i];
        end
      end
      ST2_COMB2: begin
        cicstate <= ST3_COMB3;
        for (i = 0; i < 2; i = i + 1) begin
          ci[1][i] <= co[0][i];
          co[1][i] <= co[0][i] - ci[1][i];
        end
      end
      ST3_COMB3: begin
        cicstate <= ST4_INT1;
        for (i = 0; i < 2; i = i + 1) begin
          ci[2][i] <= co[1][i];
          co[2][i] <= co[1][i] - ci[2][i];
        end
      end
/****** INTEGRATOR STAGES ******/
      ST4_INT1: begin
        for (i = 0; i < 2; i = i + 1) begin
          io[0][i] <= co[2][i] + io[0][i];
        end
        cicstate <= ST5_INT2;
      end
      ST5_INT2: begin
        for (i = 0; i < 2; i = i + 1) begin
          io[1][i] <= io[0][i] + io[1][i];
        end
        cicstate <= ST6_INT3;
      end
      ST6_INT3: begin
        for (i = 0; i < 2; i = i + 1) begin
          io[2][i] <= io[1][i] + io[2][i];
        end
        cicstate <= ST0_IDLE;
      end
      default: begin
        cicstate <= ST0_IDLE;
      end
    endcase
  end
end
`endif

/*
  Downsampler for SGB
  4 MHz input sample rate
  /64 downsample
  
  10b input.
*/

`define SGB_CIC_BITS (10+3*6) // 3 stages, /64 (2^6)

reg [(`SGB_CIC_BITS-1):0] sgb_ci[2:0][1:0], sgb_io[2:0][1:0], sgb_co[2:0][1:0];
reg [9:0] sgb_cicstate = 10'h200;
reg [9:0] sgb_cicstate_next = 10'h200;
reg [5:0] sgb_phasediv = 0;
reg       sgb_apu_clk_edge_r = 0;

wire [(`SGB_CIC_BITS-1):0] sgb_bufi[1:0];
assign sgb_bufi[1] = {{(`SGB_CIC_BITS-10){sgb_apu_dat[19]}}, sgb_apu_dat[19:10]};
assign sgb_bufi[0] = {{(`SGB_CIC_BITS-10){sgb_apu_dat[9]}}, sgb_apu_dat[9:0]};

always @(posedge clkin) begin
  sgb_apu_clk_edge_r <= sgb_apu_clk_edge;

  if(reset) begin
    sgb_cicstate <= ST0_IDLE;
    for (i = 0; i < 2; i = i + 1) begin
      {sgb_ci[2][i], sgb_ci[1][i], sgb_ci[0][i]} <= 0;
      {sgb_io[2][i], sgb_io[1][i], sgb_io[0][i]} <= 0;
      {sgb_co[2][i], sgb_co[1][i], sgb_co[0][i]} <= 0;
    end
    
    sgb_phasediv <= 0;
  end else if(sgb_apu_clk_edge_r) begin
    sgb_cicstate <= ST4_INT1;
    sgb_cicstate_next <= ~|sgb_phasediv ? ST1_COMB1 : ST0_IDLE;
    
    sgb_phasediv <= sgb_phasediv + 1;
  end else begin
    case(sgb_cicstate)
/****** COMB STAGES ******/
      ST1_COMB1: begin
        sgb_cicstate <= ST2_COMB2;
        for (i = 0; i < 2; i = i + 1) begin
          sgb_ci[0][i] <= sgb_io[2][i];
          sgb_co[0][i] <= sgb_io[2][i] - sgb_ci[0][i];
        end
      end
      ST2_COMB2: begin
        sgb_cicstate <= ST3_COMB3;
        for (i = 0; i < 2; i = i + 1) begin
          sgb_ci[1][i] <= sgb_co[0][i];
          sgb_co[1][i] <= sgb_co[0][i] - sgb_ci[1][i];
        end
      end
      ST3_COMB3: begin
        sgb_cicstate <= ST0_IDLE;
        for (i = 0; i < 2; i = i + 1) begin
          sgb_ci[2][i] <= sgb_co[1][i];
          sgb_co[2][i] <= sgb_co[1][i] - sgb_ci[2][i];
        end
      end
/****** INTEGRATOR STAGES ******/
      ST4_INT1: begin
        for (i = 0; i < 2; i = i + 1) begin
          sgb_io[0][i] <= sgb_bufi[i] + sgb_io[0][i];
        end
        sgb_cicstate <= ST5_INT2;
      end
      ST5_INT2: begin
        for (i = 0; i < 2; i = i + 1) begin
          sgb_io[1][i] <= sgb_io[0][i] + sgb_io[1][i];
        end
        sgb_cicstate <= ST6_INT3;
      end
      ST6_INT3: begin
        for (i = 0; i < 2; i = i + 1) begin
          sgb_io[2][i] <= sgb_io[1][i] + sgb_io[2][i];
        end
        sgb_cicstate <= sgb_cicstate_next;
      end
      default: begin
        sgb_cicstate <= ST0_IDLE;
      end
    endcase
  end
end

always @(posedge clkin) begin
  cnt <= cnt + 1;
  mclk_sreg <= {mclk_sreg[1:0], mclk};
  lrck_sreg <= {lrck_sreg[1:0], lrck};
  sclk_sreg <= {sclk_sreg[0], sclk};
  vol_latch_reg <= {vol_latch_reg[0], vol_latch};
  play_r <= play;
end

wire [9:0] vol_orig = volume + volume[7];
wire [9:0] vol_3db = volume + volume[7:1] + volume[7];
wire [9:0] vol_6db = {1'b0, volume, volume[7]} + volume[7];
wire [9:0] vol_9db = {1'b0, volume, 1'b0} + volume + volume[7:6];
wire [9:0] vol_12db = {volume, volume[7:6]};

reg [9:0] vol_scaled;
always @* begin
  case(vol_select)
    3'b000: vol_scaled = vol_orig;
    3'b001: vol_scaled = vol_3db;
    3'b010: vol_scaled = vol_6db;
    3'b011: vol_scaled = vol_9db;
    3'b100: vol_scaled = vol_12db;
    default: vol_scaled = vol_orig;
  endcase
end

always @(posedge clkin) begin
  vol_target_reg <= vol_scaled;
end

always @(posedge clkin) begin
  if (lrck_rising) begin
    dac_address_r_sync <= dac_address_r;
  end
end

// ramp volume only on sample boundaries
always @(posedge clkin) begin
  if (lrck_rising) begin
    if(vol_reg > vol_target_reg)
      vol_reg <= vol_reg - 1;
    else if(vol_reg < vol_target_reg)
      vol_reg <= vol_reg + 1;
  end
end

wire signed [15:0] dac_data_ch = lrck ? {{(16+12-`MSU_CIC_BITS){io[2][1][(`MSU_CIC_BITS-1)]}},io[2][1][(`MSU_CIC_BITS-1):12]} : {{(16+12-`MSU_CIC_BITS){io[2][0][(`MSU_CIC_BITS-1)]}},io[2][0][(`MSU_CIC_BITS-1):12]};
wire signed [25:0] dac_vol_sample;
wire signed [25:0] vol_sample;
wire signed [15:0] vol_sample_sat;

// TODO: arbitrary scaling which used to be in SGB APU
wire signed [15:0] sgb_data_ch = lrck ? {{(16+18-`SGB_CIC_BITS-4){sgb_co[2][1][(`SGB_CIC_BITS-1)]}},sgb_co[2][1][(`SGB_CIC_BITS-1):18],4'h0} : {{(16+18-`SGB_CIC_BITS-4){sgb_co[2][0][(`SGB_CIC_BITS-1)]}},sgb_co[2][0][(`SGB_CIC_BITS-1):18],4'h0};
//wire signed [15:0] sgb_data_ch = lrck ? {{2{sgb_apu_dat[19]}},sgb_apu_dat[19:10],4'h0} : {{2{sgb_apu_dat[9]}},sgb_apu_dat[9:0],4'h0};
wire signed [25:0] sgb_vol_sample;

assign dac_vol_sample = dac_data_ch * $signed({1'b0, vol_reg});
// TODO: using arbitrary volume reg (constant) for now
assign sgb_vol_sample = sgb_data_ch * $signed({1'b0, sgb_vol_reg});

reg signed [25:0] dac_vol_sample_r;
reg signed [25:0] sgb_vol_sample_r;
always @(posedge clkin) begin
  dac_vol_sample_r <= dac_vol_sample;
  sgb_vol_sample_r <= sgb_vol_sample;
end

assign vol_sample = dac_vol_sample_r + sgb_vol_sample_r;
assign vol_sample_sat = ((vol_sample[25:23] == 3'b000 || vol_sample[25:23] == 3'b111) ? vol_sample[23:8]
                      : vol_sample[25] ? 16'sh8000
                      : 16'sh7fff);                      
                      
always @(posedge clkin) begin
  if (sclk_falling) begin
    smpcnt <= smpcnt + 1;
    sdout_reg <= smpshift[15];
    if (lrck_rising | lrck_falling) begin
      smpshift <= vol_sample_sat;
    end else begin
      smpshift <= {smpshift[14:0], 1'b0};
    end
  end
end

endmodule

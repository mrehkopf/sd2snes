`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:53:07 07/01/2014 
// Design Name: 
// Module Name:    cheat 
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
module cheat(
  input clk,
  input [23:0] SNES_ADDR,
  input [7:0] SNES_DATA,
  input snescmd_wr_strobe,
  input [2:0] pgm_idx,
  input pgm_we,
  input [31:0] pgm_in,
  output [7:0] data_out,
  output cheat_hit
);

reg cheat_enable;
reg hook_enable;
initial cheat_enable = 0;
initial hook_enable = 0;

reg [23:0] cheat_addr[5:0];
reg [7:0] cheat_data[5:0];
reg [5:0] cheat_enable_mask;
wire [5:0] cheat_match_bits ={(cheat_enable_mask[5] & (SNES_ADDR == cheat_addr[5])),
                              (cheat_enable_mask[4] & (SNES_ADDR == cheat_addr[4])),
                              (cheat_enable_mask[3] & (SNES_ADDR == cheat_addr[3])),
                              (cheat_enable_mask[2] & (SNES_ADDR == cheat_addr[2])),
                              (cheat_enable_mask[1] & (SNES_ADDR == cheat_addr[1])),
                              (cheat_enable_mask[0] & (SNES_ADDR == cheat_addr[0]))};
wire cheat_addr_match = |cheat_match_bits;

wire [1:0] hook_match_bits ={SNES_ADDR == 24'h00FFEA, SNES_ADDR == 24'h00FFEB};
wire hook_addr_match = |hook_match_bits;

assign data_out = cheat_match_bits[0] ? cheat_data[0]
                : cheat_match_bits[1] ? cheat_data[1]
                : cheat_match_bits[2] ? cheat_data[2]
                : cheat_match_bits[3] ? cheat_data[3]
                : cheat_match_bits[4] ? cheat_data[4]
                : cheat_match_bits[5] ? cheat_data[5]
                : hook_match_bits[1] ? 8'h20
                : 8'h2a;

assign cheat_hit = (cheat_enable & cheat_addr_match) | (hook_enable & hook_addr_match); 

always @(posedge clk) begin
  if(snescmd_wr_strobe & ~|SNES_ADDR[7:0]) begin
    case(SNES_DATA)
      8'h82: cheat_enable <= 1;
      8'h83: cheat_enable <= 0;
      8'h84: hook_enable <= 0;
    endcase
  end else if(pgm_we) begin
    if(pgm_idx < 6) begin
      cheat_addr[pgm_idx] <= pgm_in[31:8];
      cheat_data[pgm_idx] <= pgm_in[7:0];
    end else if(pgm_idx == 6) begin // set status
      hook_enable <= pgm_in[7];
      cheat_enable <= pgm_in[6];
      cheat_enable_mask <= pgm_in[5:0];
    end
  end
end

endmodule

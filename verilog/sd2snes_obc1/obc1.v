`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    22:14:09 03/08/2014
// Design Name:
// Module Name:    obc1
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
module obc1(
  input clk,
  input enable,
  input [7:0] data_in,
  output [7:0] data_out,
  input [12:0] addr_in,
  input reg_we_rising
);

reg [7:0] obc1_regs [7:0];

wire [6:0] oam_number = obc1_regs[6][6:0];

wire obc_bank = obc1_regs[5][0];

wire low_en = enable & ((addr_in & 13'h1a00) == 13'h1800);
wire high_en = enable & ((addr_in & 13'h1a00) == 13'h1a00);
wire reg_en = enable & ((addr_in & 13'h1ff8) == 13'h1ff0);

wire [2:0] obc_reg = addr_in[2:0];

wire oam_low_we  = enable & (reg_we_rising) & (((addr_in & 13'h1ffc) == 13'h1ff0) | low_en);
wire oam_high_we = enable & (reg_we_rising) & (addr_in == 13'h1ff4);
wire snes_high_we = enable & (reg_we_rising) & high_en;

wire [9:0] oam_low_addr = (~reg_en) ? addr_in[9:0] : {~obc_bank, oam_number, addr_in[1:0]};
wire [7:0] oam_high_addr = (~reg_en) ? addr_in[5:0] : {~obc_bank, oam_number};

wire [7:0] low_douta;
wire [7:0] high_doutb;

`ifdef MK2
obc_lower oam_low (
  .clka(clk), // input clka
  .wea(oam_low_we), // input [0 : 0] wea
  .addra(oam_low_addr), // input [9 : 0] addra
  .dina(data_in), // input [7 : 0] dina
  .douta(low_douta) // output [7 : 0] douta
);

obc_upper oam_high (
  .clka(clk), // input clka
  .wea(oam_high_we), // input [0 : 0] wea
  .addra(oam_high_addr), // input [7 : 0] addra
  .dina(data_in[1:0]), // input [1 : 0] dina
  .douta(douta), // unused
  .clkb(clk), // input clkb
  .web(snes_high_we), // input [0 : 0] web
  .addrb(addr_in[5:0]), // input [5 : 0] addrb
  .dinb(data_in),
  .doutb(high_doutb) // output [7 : 0] doutb
);
`endif
`ifdef MK3
obc_lower oam_low (
  .clock(clk), // input clka
  .wren(oam_low_we), // input [0 : 0] wea
  .address(oam_low_addr), // input [9 : 0] addra
  .data(data_in), // input [7 : 0] dina
  .q(low_douta) // output [7 : 0] douta
);

obc_upper oam_high (
  .clock(clk), // input clka
  .wren_a(oam_high_we), // input [0 : 0] wea
  .address_a(oam_high_addr), // input [7 : 0] addra
  .data_a(data_in[1:0]), // input [1 : 0] dina
  .q_a(douta), // unused
  .wren_b(snes_high_we), // input [0 : 0] web
  .address_b(addr_in[5:0]), // input [5 : 0] addrb
  .data_b(data_in),
  .q_b(high_doutb) // output [7 : 0] doutb
);
`endif
assign data_out = reg_en ? obc1_regs[addr_in[2:0]]
                  : low_en ? low_douta
                  : high_en ? high_doutb
                  : 8'h77;

always @(posedge clk) begin
  if(reg_en & reg_we_rising) begin
    obc1_regs[obc_reg] <= data_in;
  end
end

endmodule

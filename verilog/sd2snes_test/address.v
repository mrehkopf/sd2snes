`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// Company: Rehkopf
// Engineer: Rehkopf
// 
// Create Date:    01:13:46 05/09/2009 
// Design Name: 
// Module Name:    address 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: Address logic w/ SaveRAM masking
//
// Dependencies: 
//
// Revision: 
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module address(
  input CLK,
  input [23:0] SNES_ADDR,   // requested address from SNES
  output [23:0] ram0_addr,
  output [18:0] ram1_addr,
  output [7:0] PA_addr,
  output [12:0] bram_addr,
  input [7:0] ram0_bank,
  input ram0_linear,
  output ram0_enable,
  output ram1_enable,
  output PA_enable,
  output bram_enable,
  output irq_enable,
  output bank_enable,
  output linear_enable
);

wire [23:0] SRAM_SNES_ADDR;

assign ram0bank0_enable = (SNES_ADDR[23:15] == 9'h001) | (SNES_ADDR[23:16] == 8'hC0);
assign ram0bankx_enable = (SNES_ADDR[23:16] == 8'hC8);
assign ram0linear_enable = ram0_linear & (SNES_ADDR[22] | SNES_ADDR[15]);
assign ram0_enable = ram0linear_enable | ram0bank0_enable | ram0bankx_enable;
assign ram1_enable = ~ram0_enable & (SNES_ADDR[23:20] == 4'hD);
assign PA_enable = ~ram0_enable & (SNES_ADDR[23:20] == 4'hE);
assign bram_enable = ~ram0_enable & (SNES_ADDR[23:20] == 4'hF);
wire bank_enable_ = (SNES_ADDR == 24'h0055AA);
wire irq_enable_ = (SNES_ADDR == 24'h002222);
wire linear_enable_ = (SNES_ADDR == 24'h003333);

reg [2:0] bank_enable_r;
reg [2:0] irq_enable_r;
reg [2:0] linear_enable_r;
always @(posedge CLK) begin
  bank_enable_r <= {bank_enable_r[1:0], bank_enable_};
  irq_enable_r <= {irq_enable_r[1:0], irq_enable_};
  linear_enable_r <= {linear_enable_r[1:0], linear_enable_};
end
assign bank_enable = bank_enable_r[2];
assign irq_enable = irq_enable_r[2];
assign linear_enable = linear_enable_r[2];

assign ram0_addr = ram0_linear ? SNES_ADDR
                 : {2'b00,SNES_ADDR[21:0]};

assign ram1_addr = SNES_ADDR[18:0];

assign PA_addr = SNES_ADDR[7:0];

assign bram_addr = SNES_ADDR[12:0];

endmodule

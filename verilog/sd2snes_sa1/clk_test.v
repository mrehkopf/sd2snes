`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    22:40:46 12/20/2010
// Design Name:
// Module Name:    clk_test
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
module clk_test(
  input clk,
  input sysclk,
  output [31:0] snes_sysclk_freq
);

reg [31:0] snes_sysclk_freq_r;
assign snes_sysclk_freq = snes_sysclk_freq_r;

reg [31:0] sysclk_counter;
reg [31:0] sysclk_value;

initial snes_sysclk_freq_r = 32'hFFFFFFFF;
initial sysclk_counter = 0;
initial sysclk_value = 0;

reg [1:0] sysclk_sreg;
always @(posedge clk) sysclk_sreg <= {sysclk_sreg[0], sysclk};
wire sysclk_rising = (sysclk_sreg == 2'b01);

always @(posedge clk) begin
  if(sysclk_counter < 96000000) begin
    sysclk_counter <= sysclk_counter + 1;
    if(sysclk_rising) sysclk_value <= sysclk_value + 1;
  end else begin
    snes_sysclk_freq_r <= sysclk_value;
    sysclk_counter <= 0;
    sysclk_value <= 0;
  end
end

endmodule

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
  input read,
  input write,
  input pawr,
  input pard,
  input refresh,
  input cpuclk,
  input romsel,
  input cicclk,
  output reg [31:0] snes_sysclk_freq,
  output reg [31:0] snes_read_freq,
  output reg [31:0] snes_write_freq,
  output reg [31:0] snes_pawr_freq,
  output reg [31:0] snes_pard_freq,
  output reg [31:0] snes_refresh_freq,
  output reg [31:0] snes_cpuclk_freq,
  output reg [31:0] snes_romsel_freq,
  output reg [31:0] snes_cicclk_freq
);

reg [31:0] sysclk_counter;
reg [31:0] sysclk_value;
reg [31:0] read_value;
reg [31:0] write_value;
reg [31:0] pard_value;
reg [31:0] pawr_value;
reg [31:0] refresh_value;
reg [31:0] cpuclk_value;
reg [31:0] romsel_value;
reg [31:0] cicclk_value;

initial snes_sysclk_freq = 32'hFFFFFFFF;
initial sysclk_counter = 0;
initial sysclk_value = 0;
initial read_value = 0;
initial write_value = 0;
initial pard_value = 0;
initial pawr_value = 0;
initial refresh_value = 0;
initial cpuclk_value = 0;
initial romsel_value = 0;
initial cicclk_value = 0;

reg [1:0] sysclk_sreg;
reg [1:0] read_sreg;
reg [1:0] write_sreg;
reg [1:0] pard_sreg;
reg [1:0] pawr_sreg;
reg [1:0] refresh_sreg;
reg [1:0] cpuclk_sreg;
reg [1:0] romsel_sreg;
reg [1:0] cicclk_sreg;

always @(posedge clk) romsel_sreg <= {romsel_sreg[0], romsel};
wire romsel_rising = (romsel_sreg == 2'b01);
always @(posedge clk) cpuclk_sreg <= {cpuclk_sreg[0], cpuclk};
wire cpuclk_rising = (cpuclk_sreg == 2'b01);
always @(posedge clk) sysclk_sreg <= {sysclk_sreg[0], sysclk};
wire sysclk_rising = (sysclk_sreg == 2'b01);
always @(posedge clk) read_sreg <= {read_sreg[0], read};
wire read_rising = (read_sreg == 2'b01);
always @(posedge clk) write_sreg <= {write_sreg[0], write};
wire write_rising = (write_sreg == 2'b01);
always @(posedge clk) pard_sreg <= {pard_sreg[0], pard};
wire pard_rising = (pard_sreg == 2'b01);
always @(posedge clk) pawr_sreg <= {pawr_sreg[0], pawr};
wire pawr_rising = (pawr_sreg == 2'b01);
always @(posedge clk) refresh_sreg <= {refresh_sreg[0], refresh};
wire refresh_rising = (refresh_sreg == 2'b01);
always @(posedge clk) cicclk_sreg <= {cicclk_sreg[0], cicclk};
wire cicclk_rising = (cicclk_sreg == 2'b01);

always @(posedge clk) begin
  if(sysclk_counter < 96000000) begin
    sysclk_counter <= sysclk_counter + 1;
    if(sysclk_rising) sysclk_value <= sysclk_value + 1;
    if(read_rising) read_value <= read_value + 1;
    if(write_rising) write_value <= write_value + 1;
    if(pard_rising) pard_value <= pard_value + 1;
    if(pawr_rising) pawr_value <= pawr_value + 1;
    if(refresh_rising) refresh_value <= refresh_value + 1;
    if(cpuclk_rising) cpuclk_value <= cpuclk_value + 1;
    if(romsel_rising) romsel_value <= romsel_value + 1;
    if(cicclk_rising) cicclk_value <= cicclk_value + 1;
  end else begin
    snes_sysclk_freq <= sysclk_value;
    snes_read_freq <= read_value;
    snes_write_freq <= write_value;
    snes_pard_freq <= pard_value;
    snes_pawr_freq <= pawr_value;
    snes_refresh_freq <= refresh_value;
    snes_cpuclk_freq <= cpuclk_value;
    snes_romsel_freq <= romsel_value;
    snes_cicclk_freq <= cicclk_value;
    sysclk_counter <= 0;
    sysclk_value <= 0;
    read_value <= 0;
    write_value <= 0;
    pard_value <= 0;
    pawr_value <= 0;
    refresh_value <= 0;
    cpuclk_value <= 0;
    romsel_value <= 0;
    cicclk_value <= 0;
  end
end

endmodule

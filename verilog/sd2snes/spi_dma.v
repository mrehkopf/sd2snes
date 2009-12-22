`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:18:56 12/20/2009 
// Design Name: 
// Module Name:    spi_dma 
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
module spi_dma(
    input clk,
    output spi_dma_ovr,
    input spi_dma_miso,
    output spi_dma_sck,
    input spi_dma_trig,
    output spi_dma_nextaddr,
    output [7:0] spi_dma_sram_data,
    output spi_dma_sram_we,
    output spi_dma_done
    );

reg spi_dma_sram_we_r;
reg spi_dma_done_r;
reg spi_dma_ovr_r;
reg spi_dma_nextaddr_r;
reg [7:0] spi_dma_sram_data_r;

reg [3:0] spi_dma_bitcnt; // extra bits
reg [9:0] spi_dma_bytecnt;
reg [3:0] spi_dma_clkcnt;
reg [3:0] spi_dma_sck_int_r;
reg [5:0] spi_dma_trig_r;
reg [1:0] spi_dma_miso_r;
reg spi_dma_sck_out_r;
reg spi_dma_sck_out_r2;

initial begin
   spi_dma_clkcnt <= 4'b0000;
   spi_dma_bitcnt <= 4'b1110;
   spi_dma_bytecnt <= 10'b0000000000;
   spi_dma_nextaddr_r <= 1'b0;
   spi_dma_sram_we_r <= 1'b1;
   spi_dma_done_r <= 1'b1;
   spi_dma_sck_int_r <= 4'b0000;
   spi_dma_trig_r <= 6'b000000;
   spi_dma_ovr_r <= 1'b0;
   spi_dma_sck_out_r <= 1'b0;
   spi_dma_sck_out_r2 <= 1'b0;
end

// synthesize clock
wire spi_dma_sck_int = spi_dma_clkcnt[1];
assign spi_dma_sck = spi_dma_sck_out_r & spi_dma_sck_out_r2;
always @(posedge clk) begin
   spi_dma_clkcnt <= spi_dma_clkcnt + 1;
   spi_dma_sck_int_r <= {spi_dma_sck_int_r[2:0], spi_dma_sck_int};
   spi_dma_trig_r <= {spi_dma_trig_r[4:0], spi_dma_trig};
   spi_dma_miso_r <= {spi_dma_miso_r[0], spi_dma_miso};
end

wire spi_dma_trig_rising = (spi_dma_trig_r[5:1] == 5'b00011);
wire spi_dma_trig_falling = (spi_dma_trig_r[5:1] == 5'b11100);
wire spi_dma_sck_rising = (spi_dma_sck_int_r[1:0] == 2'b01);
wire spi_dma_sck_falling = (spi_dma_sck_int_r[1:0] == 2'b10);
wire spi_dma_sck_rising2 = (spi_dma_sck_int_r[1:0] == 2'b01);
wire spi_dma_sck_falling2 = (spi_dma_sck_int_r[1:0] == 2'b10);

assign spi_dma_nextaddr = spi_dma_nextaddr_r;
assign spi_dma_sram_data = spi_dma_sram_data_r;
assign spi_dma_sram_we = spi_dma_sram_we_r;
assign spi_dma_done = spi_dma_done_r;
assign spi_dma_ovr = spi_dma_ovr_r;

always @(posedge clk) begin
   if (spi_dma_trig_falling & !spi_dma_ovr_r) begin
      spi_dma_done_r <= 0;
      spi_dma_ovr_r <= 1;
   end else if (spi_dma_bitcnt == 0 && spi_dma_bytecnt == 512) begin
      spi_dma_done_r <= 1;
      spi_dma_ovr_r <= 0;
   end
end

always @(posedge clk) begin
   if(spi_dma_sck_falling)
      spi_dma_sck_out_r2 <= 0;
   else if(spi_dma_sck_rising)
      spi_dma_sck_out_r2 <= 1;
end

always @(posedge clk) begin
   if (spi_dma_sck_rising & spi_dma_ovr_r & spi_dma_bitcnt < 8)
      spi_dma_sram_data_r <= {spi_dma_sram_data_r[6:0], spi_dma_miso};
end

always @(posedge clk) begin
   if(spi_dma_sck_rising & spi_dma_ovr_r) begin
      if (spi_dma_bitcnt < 8) begin
         spi_dma_sck_out_r <= 1;
         spi_dma_bitcnt <= spi_dma_bitcnt + 1;
      end else if (spi_dma_bitcnt == 8) begin
         spi_dma_sck_out_r <= 0;
         spi_dma_bitcnt <= spi_dma_bitcnt + 1;
         spi_dma_sram_we_r <= 0;
      end else if (spi_dma_bitcnt == 9) begin
         spi_dma_sck_out_r <= 0;
         spi_dma_sram_we_r <= 1;
         spi_dma_bytecnt <= spi_dma_bytecnt + 1;
         spi_dma_bitcnt <= 10;
      end else if (spi_dma_bitcnt == 10) begin
         spi_dma_nextaddr_r <= 1;
         spi_dma_bitcnt <= spi_dma_bitcnt + 1;
      end else if (spi_dma_bitcnt == 11) begin
         spi_dma_nextaddr_r <= 0;
         spi_dma_bitcnt <= spi_dma_bitcnt + 1;
      end else if (spi_dma_bitcnt == 12) begin
         spi_dma_bitcnt <= 0;
      end else if (spi_dma_bitcnt == 4'b1101) begin
         spi_dma_sck_out_r <= 0;
         spi_dma_bitcnt <= 4'b1110;
      end else if (spi_dma_bitcnt == 4'b1110) begin
         spi_dma_bitcnt <= spi_dma_bitcnt + 1;
      end else if (spi_dma_bitcnt == 4'b1111) begin
         spi_dma_bitcnt <= 0;
      end
   end else if (spi_dma_sck_rising & !spi_dma_ovr_r) begin
      spi_dma_bitcnt <= 4'b1101;
      spi_dma_bytecnt <= 10'b0000000000;
   end
end

endmodule

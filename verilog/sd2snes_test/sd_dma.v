`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    19:19:08 12/01/2010
// Design Name:
// Module Name:    sd_dma
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
module sd_dma(
  input [3:0] SD_DAT,
  inout SD_CLK,
  input CLK,
  input SD_DMA_EN,
  output SD_DMA_STATUS,
  output SD_DMA_SRAM_WE,
  output SD_DMA_NEXTADDR,
  output [7:0] SD_DMA_SRAM_DATA,
  input SD_DMA_PARTIAL,
  input [10:0] SD_DMA_PARTIAL_START,
  input [10:0] SD_DMA_PARTIAL_END
);

reg [10:0] SD_DMA_STARTr;
reg [10:0] SD_DMA_ENDr;
reg SD_DMA_PARTIALr;
always @(posedge CLK) SD_DMA_PARTIALr <= SD_DMA_PARTIAL;

reg SD_DMA_DONEr;
reg[1:0] SD_DMA_DONEr2;
initial begin
  SD_DMA_DONEr2 = 2'b00;
  SD_DMA_DONEr = 1'b0;
end
always @(posedge CLK) SD_DMA_DONEr2 <= {SD_DMA_DONEr2[0], SD_DMA_DONEr};
wire SD_DMA_DONE_rising = (SD_DMA_DONEr2[1:0] == 2'b01);

reg [1:0] SD_DMA_ENr;
initial SD_DMA_ENr = 2'b00;
always @(posedge CLK) SD_DMA_ENr <= {SD_DMA_ENr[0], SD_DMA_EN};
wire SD_DMA_EN_rising = (SD_DMA_ENr [1:0] == 2'b01);

reg SD_DMA_STATUSr;
assign SD_DMA_STATUS = SD_DMA_STATUSr;

reg SD_DMA_CLKMASKr = 1'b1;

// we need 1042 cycles (startbit + 1024 nibbles + 16 crc + stopbit)
reg [10:0] cyclecnt;
initial cyclecnt = 11'd0;

reg SD_DMA_SRAM_WEr;
initial SD_DMA_SRAM_WEr = 1'b1;
assign SD_DMA_SRAM_WE = (cyclecnt < 1025 && SD_DMA_STATUSr) ? SD_DMA_SRAM_WEr : 1'b1;

reg SD_DMA_NEXTADDRr;
assign SD_DMA_NEXTADDR = (cyclecnt < 1025 && SD_DMA_STATUSr) ? SD_DMA_NEXTADDRr : 1'b0;

reg[7:0] SD_DMA_SRAM_DATAr;
assign SD_DMA_SRAM_DATA = SD_DMA_SRAM_DATAr;

// we have 4 internal cycles per SD clock, 8 per RAM byte write
reg [2:0] clkcnt;
initial clkcnt = 3'b000;
reg [1:0] SD_CLKr;
initial SD_CLKr = 2'b11;
always @(posedge CLK)
  if(SD_DMA_EN_rising) SD_CLKr <= 2'b11;
  else SD_CLKr <= {SD_CLKr[0], clkcnt[1]};

assign SD_CLK = SD_DMA_CLKMASKr ? 1'bZ : SD_CLKr[1];

always @(posedge CLK) begin
  if(SD_DMA_EN_rising) begin
    SD_DMA_STATUSr <= 1'b1;
    SD_DMA_STARTr <= (SD_DMA_PARTIALr ? SD_DMA_PARTIAL_START : 11'h0);
    SD_DMA_ENDr <= (SD_DMA_PARTIALr ? SD_DMA_PARTIAL_END : 11'd1024);
  end
  else if (SD_DMA_DONE_rising) SD_DMA_STATUSr <= 1'b0;
end

always @(posedge CLK) begin
  if(SD_DMA_EN_rising) begin
    SD_DMA_CLKMASKr <= 1'b0;
  end
  else if (SD_DMA_DONEr) begin
    SD_DMA_CLKMASKr <= 1'b1;
  end
end
always @(posedge CLK) begin
  if(cyclecnt == 1042) SD_DMA_DONEr <= 1;
  else SD_DMA_DONEr <= 0;
end

always @(posedge CLK) begin
  if(SD_DMA_EN_rising || !SD_DMA_STATUSr) begin
    clkcnt <= 0;
  end else begin
    if(SD_DMA_STATUSr) begin
      clkcnt <= clkcnt + 1;
    end
  end
end

always @(posedge CLK) begin
  if(SD_DMA_EN_rising || !SD_DMA_STATUSr) cyclecnt <= 0;
  else if(clkcnt[1:0] == 2'b10) cyclecnt <= cyclecnt + 1;
end

// we have 8 clk cycles to complete one RAM write
// (4 clk cycles per SD_CLK; 2 SD_CLK cycles per byte)
always @(posedge CLK) begin
  if(SD_DMA_STATUSr) begin
    case(clkcnt[2:0])
      3'h0: begin
        SD_DMA_SRAM_DATAr[7:4] <= SD_DAT;
        if(cyclecnt>SD_DMA_STARTr && cyclecnt <= SD_DMA_ENDr) SD_DMA_NEXTADDRr <= 1'b1;
      end
      3'h1:
        SD_DMA_NEXTADDRr <= 1'b0;
      3'h2:
        if(cyclecnt>=SD_DMA_STARTr && cyclecnt < SD_DMA_ENDr) SD_DMA_SRAM_WEr <= 1'b0;
//      3'h3:
      3'h4:
        SD_DMA_SRAM_DATAr[3:0] <= SD_DAT;
//  3'h5:
//  3'h6:
      3'h7:
        SD_DMA_SRAM_WEr <= 1'b1;
    endcase
  end
end

endmodule


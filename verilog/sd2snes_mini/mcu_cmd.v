`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    21:57:50 08/25/2009
// Design Name:
// Module Name:    mcu_cmd
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
module mcu_cmd(
  input clk,
  input cmd_ready,
  input param_ready,
  input [7:0] cmd_data,
  input [7:0] param_data,
  output reg mcu_rrq = 0,
  output reg mcu_wrq = 0,
  input mcu_rq_rdy,
  output [7:0] mcu_data_out,
  input [7:0] mcu_data_in,
  output [7:0] spi_data_out,
  input [31:0] spi_byte_cnt,
  input [2:0] spi_bit_cnt,
  output [23:0] addr_out,
  output [23:0] saveram_mask_out,
  output [23:0] rom_mask_out
);

reg [7:0] MCU_DATA_OUT_BUF;
reg [7:0] MCU_DATA_IN_BUF;
reg [2:0] mcu_nextaddr_buf;

wire mcu_nextaddr;

reg [23:0] SAVERAM_MASK;
reg [23:0] ROM_MASK;

reg [23:0] ADDR_OUT_BUF;

assign spi_data_out = MCU_DATA_IN_BUF;

initial begin
  ADDR_OUT_BUF = 0;
end

// command interpretation
always @(posedge clk) begin
  if (param_ready) begin
    casex (cmd_data[7:0])
      8'h1x:
        case (spi_byte_cnt)
          32'h2:
            ROM_MASK[23:16] <= param_data;
          32'h3:
            ROM_MASK[15:8] <= param_data;
          32'h4:
            ROM_MASK[7:0] <= param_data;
        endcase
      8'h2x:
        case (spi_byte_cnt)
          32'h2:
            SAVERAM_MASK[23:16] <= param_data;
          32'h3:
            SAVERAM_MASK[15:8] <= param_data;
          32'h4:
            SAVERAM_MASK[7:0] <= param_data;
        endcase
      8'h9x:
        MCU_DATA_OUT_BUF <= param_data;
    endcase
  end
end

always @(posedge clk) begin
  if(param_ready && cmd_data[7:4] == 4'h0)  begin
    case (spi_byte_cnt)
      32'h2: begin
        ADDR_OUT_BUF[23:16] <= param_data;
        ADDR_OUT_BUF[15:0] <= 16'b0;
      end
      32'h3:
        ADDR_OUT_BUF[15:8] <= param_data;
      32'h4:
        ADDR_OUT_BUF[7:0] <= param_data;
    endcase
  end else if ((mcu_nextaddr & (cmd_data[7:5] == 3'h4)
               && (cmd_data[3])
               && (spi_byte_cnt >= (32'h1+cmd_data[4])))
              ) begin
    ADDR_OUT_BUF <= ADDR_OUT_BUF + 1;
  end
end

// value fetch during last SPI bit
always @(posedge clk) begin
  if (cmd_data[7:4] == 4'h8 && mcu_nextaddr)
    MCU_DATA_IN_BUF <= mcu_data_in;
  else if (cmd_ready | param_ready /* bit_cnt == 7 */) begin
    if (cmd_data[7:0] == 8'hF0)
      MCU_DATA_IN_BUF <= 8'hA5;
    else if (cmd_data[7:0] == 8'hFF)
      MCU_DATA_IN_BUF <= param_data;
  end
end

// nextaddr pulse generation
always @(posedge clk) begin
  mcu_nextaddr_buf <= {mcu_nextaddr_buf[1:0], mcu_rq_rdy};
end

always @(posedge clk) begin
  mcu_rrq <= 1'b0;
  if((param_ready | cmd_ready) && cmd_data[7:4] == 4'h8) begin
    mcu_rrq <= 1'b1;
  end
end

always @(posedge clk) begin
  mcu_wrq <= 1'b0;
  if(param_ready && cmd_data[7:4] == 4'h9) begin
    mcu_wrq <= 1'b1;
  end
end

// trigger for nextaddr
assign mcu_nextaddr = mcu_nextaddr_buf == 2'b01;

assign addr_out = ADDR_OUT_BUF;

assign mcu_data_out = MCU_DATA_OUT_BUF;
assign rom_mask_out = ROM_MASK;
assign saveram_mask_out = SAVERAM_MASK;

assign DBG_mcu_nextaddr = mcu_nextaddr;
endmodule

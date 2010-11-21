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
    output [3:0] mcu_mapper,
    output [3:0] mcu_sram_size,
    output mcu_read,
    output mcu_write,
    output [7:0] mcu_data_out,
    input [7:0] mcu_data_in,
    output [7:0] spi_data_out,
    input [31:0] spi_byte_cnt,
    input [2:0] spi_bit_cnt,
    output [23:0] addr_out,
    output [3:0] mapper,
    input endmessage,
    input startmessage,
    output [23:0] saveram_mask_out,
    output [23:0] rom_mask_out,
    
    // SPI "DMA" extension
    input spi_dma_ovr,
    input spi_dma_nextaddr,
    input [7:0] spi_dma_sram_data,
    input spi_dma_sram_we
    );

reg [3:0] MAPPER_BUF;
reg [3:0] SRAM_SIZE_BUF;
reg MCU_READ_BUF;
reg MCU_WRITE_BUF;
reg [23:0] ADDR_OUT_BUF;
reg [7:0] MCU_DATA_OUT_BUF;
reg [7:0] MCU_DATA_IN_BUF;
reg [1:0] mcu_nextaddr_buf;
wire mcu_nextaddr;
wire spi_dma_nextaddr_trig;
reg [2:0] spi_dma_nextaddr_r;

reg [1:0] SRAM_MASK_IDX;
reg [23:0] SAVERAM_MASK;
reg [23:0] ROM_MASK;

assign spi_data_out = MCU_DATA_IN_BUF;

initial begin
   ADDR_OUT_BUF = 0;
   spi_dma_nextaddr_r = 0;
end

// command interpretation
always @(posedge clk) begin
   if (cmd_ready) begin
      case (cmd_data[7:4])
         4'h3:
            MAPPER_BUF <= cmd_data[3:0];
      endcase
   end else if (param_ready) begin
      case (cmd_data[7:4])
         4'h0:
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
         4'h1:
            case (spi_byte_cnt)
               32'h2:
                  ROM_MASK[23:16] <= param_data;
               32'h3:
                  ROM_MASK[15:8] <= param_data;                  
               32'h4:
                  ROM_MASK[7:0] <= param_data;
            endcase
         4'h2:
            case (spi_byte_cnt)
               32'h2:
                  SAVERAM_MASK[23:16] <= param_data;
               32'h3:
                  SAVERAM_MASK[15:8] <= param_data;                  
               32'h4:
                  SAVERAM_MASK[7:0] <= param_data;
            endcase
         4'h9:
            MCU_DATA_OUT_BUF <= param_data;
      endcase
   end
   if (spi_dma_nextaddr_trig | (mcu_nextaddr & (cmd_data[7:5] == 3'h4) && (cmd_data[0]) && (spi_byte_cnt > (32'h1+cmd_data[4]))))
      ADDR_OUT_BUF <= ADDR_OUT_BUF + 1;
end

// value fetch during last SPI bit
always @(posedge clk) begin
   if (spi_bit_cnt == 3'h7)
      if (cmd_data[7:0] == 8'hF0)
         MCU_DATA_IN_BUF <= 8'hA5;
      else if (cmd_data[7:0] == 8'hFF)
		   MCU_DATA_IN_BUF <= param_data;
		else
         MCU_DATA_IN_BUF <= mcu_data_in;
end

// nextaddr pulse generation
always @(posedge clk) begin
   if (spi_bit_cnt == 3'h0)
      mcu_nextaddr_buf <= {mcu_nextaddr_buf[0], 1'b1};
   else
      mcu_nextaddr_buf <= {mcu_nextaddr_buf[0], 1'b0};
end

assign spi_dma_nextaddr_trig = (spi_dma_nextaddr_r[2:1] == 2'b01);
always @(posedge clk) begin
   spi_dma_nextaddr_r <= {spi_dma_nextaddr_r[1:0], spi_dma_nextaddr};
end

// r/w pulse
always @(posedge clk) begin
   if ((spi_bit_cnt == 3'h1 || spi_bit_cnt == 3'h2 || spi_bit_cnt == 3'h3) & (cmd_data[7:4] == 4'h9) & (spi_byte_cnt > 32'h1))
      MCU_WRITE_BUF <= 1'b0;
   else
      MCU_WRITE_BUF <= 1'b1;

// Read pulse is two spi cycles to ensure that the value
// is ready in the 2nd cycle in MCU master mode
   if ((spi_bit_cnt == 3'h5 || spi_bit_cnt == 3'h6 || spi_bit_cnt == 3'h7) & (cmd_data[7:4] == 4'h8) & (spi_byte_cnt > 32'h0))
      MCU_READ_BUF <= 1'b0;
   else
      MCU_READ_BUF <= 1'b1;
end

// trigger for nextaddr
assign mcu_nextaddr = mcu_nextaddr_buf == 2'b01;

assign mcu_read = MCU_READ_BUF;
assign mcu_write = spi_dma_ovr ? spi_dma_sram_we : MCU_WRITE_BUF;
assign addr_out = ADDR_OUT_BUF;
assign mcu_data_out = spi_dma_ovr ? spi_dma_sram_data : MCU_DATA_OUT_BUF;
assign mcu_mapper = MAPPER_BUF;
assign mcu_sram_size = SRAM_SIZE_BUF;
assign rom_mask_out = ROM_MASK;
assign saveram_mask_out = SAVERAM_MASK;

endmodule

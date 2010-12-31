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
    
    // SD "DMA" extension
	 output SD_DMA_EN,
	 input SD_DMA_STATUS,
    input SD_DMA_NEXTADDR,
    input [7:0] SD_DMA_SRAM_DATA,
    input SD_DMA_SRAM_WE,
	 output [1:0] SD_DMA_TGT,
	 output SD_DMA_PARTIAL,
	 output [11:0] SD_DMA_PARTIAL_START,
	 output [11:0] SD_DMA_PARTIAL_END,
	 
	 // DAC
	 output [10:0] dac_addr_out,
//	 output [7:0] dac_volume_out,
//	 output dac_volume_latch_out,
	 input DAC_STATUS,
	 output dac_play_out,
	 output dac_reset_out,
	 
	 // MSU data
	 output [13:0] msu_addr_out,
	 input [6:0] MSU_STATUS,
	 output [5:0] msu_status_reset_out,
	 output [5:0] msu_status_set_out,
	 output msu_status_reset_we,
	 input [31:0] msu_addressrq,
	 input [15:0] msu_trackrq,
	 input [7:0] msu_volumerq,
	 output [13:0] msu_ptr_out,
	 output msu_reset_out,
	 
	 // SNES sync/clk
 	 input snes_sysclk	 
    );


wire [31:0] snes_sysclk_freq;

clk_test snes_clk_test (
    .clk(clk), 
    .sysclk(snes_sysclk), 
    .snes_sysclk_freq(snes_sysclk_freq)
    );


reg [3:0] MAPPER_BUF;
reg [3:0] SRAM_SIZE_BUF;
reg MCU_READ_BUF;
reg MCU_WRITE_BUF;
reg [23:0] ADDR_OUT_BUF;
reg [10:0] DAC_ADDR_OUT_BUF;
reg [7:0] DAC_VOL_OUT_BUF;
reg DAC_VOL_LATCH_BUF;
reg DAC_PLAY_OUT_BUF;
reg DAC_RESET_OUT_BUF;
reg [13:0] MSU_ADDR_OUT_BUF;
reg [13:0] MSU_PTR_OUT_BUF;
reg [5:0] msu_status_set_out_buf;
reg [5:0] msu_status_reset_out_buf;
reg msu_status_reset_we_buf;
reg MSU_RESET_OUT_BUF;

reg [31:0] SNES_SYSCLK_FREQ_BUF;

reg [7:0] MCU_DATA_OUT_BUF;
reg [7:0] MCU_DATA_IN_BUF;
reg [1:0] mcu_nextaddr_buf;
reg SD_DMA_NEXTADDRr;
always @(posedge clk) SD_DMA_NEXTADDRr <= SD_DMA_NEXTADDR;

wire mcu_nextaddr;

reg DAC_STATUSr;
reg SD_DMA_STATUSr;
reg [6:0] MSU_STATUSr;
always @(posedge clk) begin
	DAC_STATUSr <= DAC_STATUS;
	SD_DMA_STATUSr <= SD_DMA_STATUS;
	MSU_STATUSr <= MSU_STATUS;
end

reg SD_DMA_PARTIALr;
assign SD_DMA_PARTIAL = SD_DMA_PARTIALr;

reg SD_DMA_ENr;
assign SD_DMA_EN = SD_DMA_ENr;

reg [1:0] SD_DMA_TGTr;
assign SD_DMA_TGT = SD_DMA_TGTr;

reg [11:0] SD_DMA_PARTIAL_STARTr;
reg [11:0] SD_DMA_PARTIAL_ENDr;
assign SD_DMA_PARTIAL_START = SD_DMA_PARTIAL_STARTr;
assign SD_DMA_PARTIAL_END = SD_DMA_PARTIAL_ENDr;

reg [2:0] spi_dma_nextaddr_r;

reg [1:0] SRAM_MASK_IDX;
reg [23:0] SAVERAM_MASK;
reg [23:0] ROM_MASK;

assign spi_data_out = MCU_DATA_IN_BUF;

initial begin
   ADDR_OUT_BUF = 0;
	DAC_ADDR_OUT_BUF = 0;
	MSU_ADDR_OUT_BUF = 0;
	DAC_VOL_OUT_BUF = 0;
	DAC_VOL_LATCH_BUF = 0;
   spi_dma_nextaddr_r = 0;
	SD_DMA_ENr = 0;
end

// command interpretation
always @(posedge clk) begin
   if (cmd_ready) begin
      case (cmd_data[7:4])
         4'h3: // select mapper
            MAPPER_BUF <= cmd_data[3:0];
		   4'h4: begin// SD DMA
			   SD_DMA_ENr <= 1;
				SD_DMA_TGTr <= cmd_data[1:0];
				SD_DMA_PARTIALr <= cmd_data[2];
			end
			4'h8: SD_DMA_TGTr <= 2'b00;
			4'h9: SD_DMA_TGTr <= cmd_data[1:0];
//			4'hE:
			   // select memory unit
      endcase
   end else if (param_ready) begin
      casex (cmd_data[7:0])
         8'h0x:
				case (cmd_data[1:0])
				   2'b01: begin
						case (spi_byte_cnt)
							32'h2: begin
								DAC_ADDR_OUT_BUF[10:8] <= param_data[2:0];
								DAC_ADDR_OUT_BUF[7:0] <= 8'b0;
							end
							32'h3:
								DAC_ADDR_OUT_BUF[7:0] <= param_data;
						endcase				
					end
					2'b10: begin
						case (spi_byte_cnt)
							32'h2: begin
								MSU_ADDR_OUT_BUF[13:8] <= param_data[5:0];
								MSU_ADDR_OUT_BUF[7:0] <= 8'b0;
							end
							32'h3:
								MSU_ADDR_OUT_BUF[7:0] <= param_data;
						endcase				
					end
					default:
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
				endcase
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
			8'h4x:
			   SD_DMA_ENr <= 1'b0;
//			8'h5x:
//				case (spi_byte_cnt)
//					32'h2:
//						DAC_VOL_OUT_BUF <= param_data;
//					32'h3:
//						DAC_VOL_LATCH_BUF <= 1'b1;
//					32'h4:
//						DAC_VOL_LATCH_BUF <= 1'b0;
//				endcase
			8'h6x:
				case (spi_byte_cnt)
					32'h2:
						SD_DMA_PARTIAL_STARTr[10:9] <= param_data[1:0];
					32'h3:
						SD_DMA_PARTIAL_STARTr[8:0] <= {param_data, 1'b0};
					32'h4:
						SD_DMA_PARTIAL_ENDr[10:9] <= param_data[1:0];
					32'h5:
						SD_DMA_PARTIAL_ENDr[8:0] <= {param_data, 1'b0};
				endcase
         8'h9x:
            MCU_DATA_OUT_BUF <= param_data;
			8'he0:
				case (spi_byte_cnt)
					32'h2: begin
						msu_status_set_out_buf <= param_data[5:0];
					end
					32'h3: begin
						msu_status_reset_out_buf <= param_data[5:0];
						msu_status_reset_we_buf <= 1'b1;
					end
					32'h4:
						msu_status_reset_we_buf <= 1'b0;
				endcase
			8'he1: // pause DAC
				DAC_PLAY_OUT_BUF <= 1'b0;
			8'he2: // resume DAC
				DAC_PLAY_OUT_BUF <= 1'b1;
			8'he3: // reset DAC (set DAC playback address = 0)
				case (spi_byte_cnt)
					32'h2:
						DAC_RESET_OUT_BUF <= 1'b1;
					32'h3:
						DAC_RESET_OUT_BUF <= 1'b0;
				endcase
			8'he4: // reset MSU read buffer pointer
				case (spi_byte_cnt)
				   32'h2: begin
						MSU_PTR_OUT_BUF[13:8] <= param_data[5:0];
						MSU_PTR_OUT_BUF[7:0] <= 8'h0;
					end
					32'h3: begin
						MSU_PTR_OUT_BUF[7:0] <= param_data;
						MSU_RESET_OUT_BUF <= 1'b1;
					end
					32'h4:
						MSU_RESET_OUT_BUF <= 1'b0;
				endcase
      endcase
   end
   if (SD_DMA_NEXTADDR | (mcu_nextaddr & (cmd_data[7:5] == 3'h4) && (cmd_data[3]) && (spi_byte_cnt > (32'h1+cmd_data[4])))) begin
		case (SD_DMA_TGTr)
			2'b00: ADDR_OUT_BUF <= ADDR_OUT_BUF + 1;
			2'b01: DAC_ADDR_OUT_BUF <= DAC_ADDR_OUT_BUF + 1;
			2'b10: MSU_ADDR_OUT_BUF <= MSU_ADDR_OUT_BUF + 1;
		endcase
	end
end

// value fetch during last SPI bit
always @(posedge clk) begin
   if (spi_bit_cnt == 3'h7)
      if (cmd_data[7:0] == 8'hF0)
         MCU_DATA_IN_BUF <= 8'hA5;
		else if (cmd_data[7:0] == 8'hF1)
			case (spi_byte_cnt[0])
				1'b1: // buffer status
					MCU_DATA_IN_BUF <= {SD_DMA_STATUSr, DAC_STATUSr, MSU_STATUSr[6], 5'b0};
				1'b0: // control status
					MCU_DATA_IN_BUF <= {2'b0, MSU_STATUSr[5:0]};
			endcase
		else if (cmd_data[7:0] == 8'hF2)
		   case (spi_byte_cnt)
				32'h1:
					MCU_DATA_IN_BUF <= msu_addressrq[31:24];
				32'h2:
					MCU_DATA_IN_BUF <= msu_addressrq[23:16];
				32'h3:
					MCU_DATA_IN_BUF <= msu_addressrq[15:8];
				32'h4:
					MCU_DATA_IN_BUF <= msu_addressrq[7:0];				
			endcase
		else if (cmd_data[7:0] == 8'hF3)
		   case (spi_byte_cnt)
				32'h1:
					MCU_DATA_IN_BUF <= msu_trackrq[15:8];
				32'h2:
					MCU_DATA_IN_BUF <= msu_trackrq[7:0];				
			endcase
		else if (cmd_data[7:0] == 8'hF4)
			MCU_DATA_IN_BUF <= msu_volumerq;
		else if (cmd_data[7:0] == 8'hFE)
		   case (spi_byte_cnt)
				32'h1:
					SNES_SYSCLK_FREQ_BUF <= snes_sysclk_freq;
				32'h2:
					MCU_DATA_IN_BUF <= SNES_SYSCLK_FREQ_BUF[31:24];
				32'h3:
					MCU_DATA_IN_BUF <= SNES_SYSCLK_FREQ_BUF[23:16];
				32'h4:
					MCU_DATA_IN_BUF <= SNES_SYSCLK_FREQ_BUF[15:8];
				32'h5:
					MCU_DATA_IN_BUF <= SNES_SYSCLK_FREQ_BUF[7:0];
			endcase
      else if (cmd_data[7:0] == 8'hFF)
		   MCU_DATA_IN_BUF <= param_data;
		else if (cmd_data[7:4] == 4'h8)
         MCU_DATA_IN_BUF <= mcu_data_in;
	   else
         MCU_DATA_IN_BUF <= cmd_data;
		   
end

// nextaddr pulse generation
always @(posedge clk) begin
   if (spi_bit_cnt == 3'h0)
      mcu_nextaddr_buf <= {mcu_nextaddr_buf[0], 1'b1};
   else
      mcu_nextaddr_buf <= {mcu_nextaddr_buf[0], 1'b0};
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
assign mcu_write = SD_DMA_STATUS ? (SD_DMA_TGTr == 2'b00 ? SD_DMA_SRAM_WE : 1'b1) : MCU_WRITE_BUF;
assign addr_out = ADDR_OUT_BUF;
assign dac_addr_out = DAC_ADDR_OUT_BUF;
assign msu_addr_out = MSU_ADDR_OUT_BUF;
assign dac_volume_out = DAC_VOL_OUT_BUF;
assign dac_volume_latch_out = DAC_VOL_LATCH_BUF;
assign dac_play_out = DAC_PLAY_OUT_BUF;
assign dac_reset_out = DAC_RESET_OUT_BUF;
assign msu_status_reset_we = msu_status_reset_we_buf;
assign msu_status_reset_out = msu_status_reset_out_buf;
assign msu_status_set_out = msu_status_set_out_buf;
assign msu_reset_out = MSU_RESET_OUT_BUF;
assign msu_ptr_out = MSU_PTR_OUT_BUF;
assign mcu_data_out = SD_DMA_STATUS ? SD_DMA_SRAM_DATA : MCU_DATA_OUT_BUF;
assign mcu_mapper = MAPPER_BUF;
assign mcu_sram_size = SRAM_SIZE_BUF;
assign rom_mask_out = ROM_MASK;
assign saveram_mask_out = SAVERAM_MASK;
	 
endmodule

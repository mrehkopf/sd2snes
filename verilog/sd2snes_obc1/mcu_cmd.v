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
  output [2:0] mcu_mapper,
  output mcu_rrq,
  output mcu_write,
  output mcu_wrq,
  input mcu_rq_rdy,
  output [7:0] mcu_data_out,
  input [7:0] mcu_data_in,
  output [7:0] spi_data_out,
  input [31:0] spi_byte_cnt,
  input [2:0] spi_bit_cnt,
  output [23:0] addr_out,
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
  output [10:0] SD_DMA_PARTIAL_START,
  output [10:0] SD_DMA_PARTIAL_END,
  output reg SD_DMA_START_MID_BLOCK,
  output reg SD_DMA_END_MID_BLOCK,

  // DAC
  output [10:0] dac_addr_out,
  input DAC_STATUS,
  output reg dac_play_out = 0,
  output reg dac_reset_out = 0,
  output reg [2:0] dac_vol_select_out = 3'b000,
  output reg dac_palmode_out = 0,

  // MSU data
  output [13:0] msu_addr_out,
  input [7:0] MSU_STATUS,
  output [5:0] msu_status_reset_out,
  output [5:0] msu_status_set_out,
  output msu_status_reset_we,
  input [31:0] msu_addressrq,
  input [15:0] msu_trackrq,
  input [7:0] msu_volumerq,
  output [13:0] msu_ptr_out,
  output msu_reset_out,

  // feature enable
  output reg [7:0] featurebits_out,

  output reg region_out,
  // SNES sync/clk
  input snes_sysclk,

  // snes cmd interface
  input [7:0] snescmd_data_in,
  output reg [7:0] snescmd_data_out,
  output reg [8:0] snescmd_addr_out,
  output reg snescmd_we_out,

  // cheat configuration
  output reg [7:0] cheat_pgm_idx_out,
  output reg [31:0] cheat_pgm_data_out,
  output reg cheat_pgm_we_out,

  // debug
  output DBG_mcu_nextaddr
);

initial begin
  region_out = 0;
  SD_DMA_START_MID_BLOCK = 0;
  SD_DMA_END_MID_BLOCK = 0;
end

wire [31:0] snes_sysclk_freq;

clk_test snes_clk_test (
  .clk(clk),
  .sysclk(snes_sysclk),
  .snes_sysclk_freq(snes_sysclk_freq)
);


reg [2:0] MAPPER_BUF;
reg [23:0] ADDR_OUT_BUF;
reg [10:0] DAC_ADDR_OUT_BUF;
reg [7:0] DAC_VOL_OUT_BUF;
reg [13:0] MSU_ADDR_OUT_BUF;
reg [13:0] MSU_PTR_OUT_BUF;
reg [5:0] msu_status_set_out_buf;
reg [5:0] msu_status_reset_out_buf;
reg msu_status_reset_we_buf;
reg MSU_RESET_OUT_BUF;

reg [31:0] SNES_SYSCLK_FREQ_BUF;

reg [7:0] MCU_DATA_OUT_BUF;
reg [7:0] MCU_DATA_IN_BUF;
reg [2:0] mcu_nextaddr_buf;

wire mcu_nextaddr;

reg DAC_STATUSr;
reg SD_DMA_STATUSr;
reg [7:0] MSU_STATUSr;
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

reg [10:0] SD_DMA_PARTIAL_STARTr;
reg [10:0] SD_DMA_PARTIAL_ENDr;
assign SD_DMA_PARTIAL_START = SD_DMA_PARTIAL_STARTr;
assign SD_DMA_PARTIAL_END = SD_DMA_PARTIAL_ENDr;

reg [23:0] SAVERAM_MASK;
reg [23:0] ROM_MASK;

assign spi_data_out = MCU_DATA_IN_BUF;

initial begin
  ADDR_OUT_BUF = 0;
  DAC_ADDR_OUT_BUF = 0;
  MSU_ADDR_OUT_BUF = 0;
  SD_DMA_ENr = 0;
  MAPPER_BUF = 1;
  SD_DMA_PARTIALr = 0;
end

// command interpretation
always @(posedge clk) begin
  snescmd_we_out <= 1'b0;
  cheat_pgm_we_out <= 1'b0;
  dac_reset_out <= 1'b0;
  if (cmd_ready) begin
    case (cmd_data[7:4])
      4'h3: // select mapper
        MAPPER_BUF <= cmd_data[2:0];
      4'h4: begin// SD DMA
        SD_DMA_ENr <= 1;
        SD_DMA_TGTr <= cmd_data[1:0];
        SD_DMA_PARTIALr <= cmd_data[2];
      end
      4'h8: SD_DMA_TGTr <= 2'b00;
      4'h9: SD_DMA_TGTr <= 2'b00; // cmd_data[1:0]; // not implemented
//      4'hE:
//      select memory unit
    endcase
  end else if (param_ready) begin
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
      8'h4x:
        SD_DMA_ENr <= 1'b0;
      8'h6x:
        case (spi_byte_cnt)
          32'h2: begin
            SD_DMA_START_MID_BLOCK <= param_data[7];
            SD_DMA_PARTIAL_STARTr[10:9] <= param_data[1:0];
          end
          32'h3:
            SD_DMA_PARTIAL_STARTr[8:0] <= {param_data, 1'b0};
          32'h4: begin
            SD_DMA_END_MID_BLOCK <= param_data[7];
            SD_DMA_PARTIAL_ENDr[10:9] <= param_data[1:0];
          end
          32'h5:
            SD_DMA_PARTIAL_ENDr[8:0] <= {param_data, 1'b0};
        endcase
      8'h9x:
        MCU_DATA_OUT_BUF <= param_data;
      8'hd0:
        case (spi_byte_cnt)
          32'h2:
            snescmd_addr_out[7:0] <= param_data;
          32'h3:
            snescmd_addr_out[8] <= param_data[0];
        endcase
      8'hd1:
        snescmd_addr_out <= snescmd_addr_out + 1;
      8'hd2: begin
        case (spi_byte_cnt)
          32'h2:
            snescmd_we_out <= 1'b1;
          32'h3:
            snescmd_addr_out <= snescmd_addr_out + 1;
        endcase
        snescmd_data_out <= param_data;
      end
      8'hd3: begin
        case (spi_byte_cnt)
          32'h2:
            cheat_pgm_idx_out <= param_data[2:0];
          32'h3:
            cheat_pgm_data_out[31:24] <= param_data;
          32'h4:
            cheat_pgm_data_out[23:16] <= param_data;
          32'h5:
            cheat_pgm_data_out[15:8] <= param_data;
          32'h6: begin
            cheat_pgm_data_out[7:0] <= param_data;
            cheat_pgm_we_out <= 1'b1;
          end
        endcase
      end
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
        dac_play_out <= 1'b0;
      8'he2: // resume DAC
        dac_play_out <= 1'b1;
      8'he3: // reset DAC (set DAC playback address = 0)
        dac_reset_out <= 1'b1; // reset by default value, see above
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
      8'hec: // set DAC properties
        begin
          dac_vol_select_out <= param_data[2:0];
          dac_palmode_out <= param_data[7];
        end
      8'hed:
        featurebits_out <= param_data;
      8'hee:
        region_out <= param_data[0];
    endcase
  end
end

always @(posedge clk) begin
  if(param_ready && cmd_data[7:4] == 4'h0)  begin
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
  end else if (SD_DMA_NEXTADDR | (mcu_nextaddr & (cmd_data[7:5] == 3'h4)
                                  && (cmd_data[3])
                                  && (spi_byte_cnt >= (32'h1+cmd_data[4])))
  ) begin
    case (SD_DMA_TGTr)
      2'b00: ADDR_OUT_BUF <= ADDR_OUT_BUF + 1;
      2'b01: DAC_ADDR_OUT_BUF <= DAC_ADDR_OUT_BUF + 1;
      2'b10: MSU_ADDR_OUT_BUF <= MSU_ADDR_OUT_BUF + 1;
    endcase
  end
end

// value fetch during last SPI bit
always @(posedge clk) begin
  if (cmd_data[7:4] == 4'h8 && mcu_nextaddr)
    MCU_DATA_IN_BUF <= mcu_data_in;
  else if (cmd_ready | param_ready /* bit_cnt == 7 */) begin
    if (cmd_data[7:0] == 8'hF0)
      MCU_DATA_IN_BUF <= 8'hA5;
    else if (cmd_data[7:0] == 8'hF1)
      case (spi_byte_cnt[0])
        1'b1: // buffer status (1st byte)
          MCU_DATA_IN_BUF <= {SD_DMA_STATUSr, DAC_STATUSr, MSU_STATUSr[7], 5'b0};
        1'b0: // control status (2nd byte)
          MCU_DATA_IN_BUF <= {1'b0, MSU_STATUSr[6:0]};
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
    else if (cmd_data[7:0] == 8'hD1)
      MCU_DATA_IN_BUF <= snescmd_data_in;
  end
end

// nextaddr pulse generation
always @(posedge clk) begin
  mcu_nextaddr_buf <= {mcu_nextaddr_buf[1:0], mcu_rq_rdy};
end

parameter ST_RQ = 2'b01;
parameter ST_IDLE = 2'b10;

reg [1:0] rrq_state;
initial rrq_state = ST_IDLE;
reg mcu_rrq_r;

reg [1:0] wrq_state;
initial wrq_state = ST_IDLE;
reg mcu_wrq_r;

always @(posedge clk) begin
  case(rrq_state)
    ST_IDLE: begin
      if((param_ready | cmd_ready) && cmd_data[7:4] == 4'h8) begin
        mcu_rrq_r <= 1'b1;
        rrq_state <= ST_RQ;
      end else
        rrq_state <= ST_IDLE;
    end
    ST_RQ: begin
      mcu_rrq_r <= 1'b0;
      rrq_state <= ST_IDLE;
    end
  endcase
end

always @(posedge clk) begin
  case(wrq_state)
    ST_IDLE: begin
      if(param_ready && cmd_data[7:4] == 4'h9) begin
        mcu_wrq_r <= 1'b1;
        wrq_state <= ST_RQ;
      end else
        wrq_state <= ST_IDLE;
    end
    ST_RQ: begin
      mcu_wrq_r <= 1'b0;
      wrq_state <= ST_IDLE;
    end
  endcase
end

// trigger for nextaddr
assign mcu_nextaddr = mcu_nextaddr_buf == 2'b01;

assign mcu_rrq = mcu_rrq_r;
assign mcu_wrq = mcu_wrq_r;
assign mcu_write = SD_DMA_STATUS
                   ? (SD_DMA_TGTr == 2'b00
                      ? SD_DMA_SRAM_WE
                      : 1'b1
                     )
                   : 1'b1;

assign addr_out = ADDR_OUT_BUF;
assign dac_addr_out = DAC_ADDR_OUT_BUF;
assign msu_addr_out = MSU_ADDR_OUT_BUF;
assign msu_status_reset_we = msu_status_reset_we_buf;
assign msu_status_reset_out = msu_status_reset_out_buf;
assign msu_status_set_out = msu_status_set_out_buf;
assign msu_reset_out = MSU_RESET_OUT_BUF;
assign msu_ptr_out = MSU_PTR_OUT_BUF;

assign mcu_data_out = SD_DMA_STATUS ? SD_DMA_SRAM_DATA : MCU_DATA_OUT_BUF;
assign mcu_mapper = MAPPER_BUF;
assign rom_mask_out = ROM_MASK;
assign saveram_mask_out = SAVERAM_MASK;

assign DBG_mcu_nextaddr = mcu_nextaddr;
endmodule

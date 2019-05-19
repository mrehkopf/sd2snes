`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    13:33:14 02/09/2011
// Design Name:
// Module Name:    srtc
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
module srtc(
  input clkin,
  input addr_in,
  input [3:0] data_in,
  output [7:0] data_out,
  input [59:0] rtc_data_in,
  output [59:0] rtc_data_out,
  input reg_oe_falling,
  input reg_oe_rising,
  input reg_we_rising,
  input enable,
  output rtc_we,
  input reset,

  /* DEBUG */
  output [4:0] srtc_state,
  output srtc_reg_we_rising,
  output [3:0] srtc_rtc_ptr,
  output [5:0] srtc_we_sreg
);

reg [59:0] rtc_data_r;
reg [59:0] rtc_data_out_r;
assign rtc_data_out = rtc_data_out_r;

reg [3:0] rtc_ptr;

reg [7:0] data_out_r;
reg [4:0] mode_r;
reg rtc_we_r;
assign rtc_we = rtc_we_r;
assign data_out = data_out_r;

reg [1:0] reset_sreg;
always @(posedge clkin) reset_sreg <= {reset_sreg[0], reset};
wire reset_rising = (reset_sreg[1:0] == 2'b01);

reg[2:0] we_countdown_r;

parameter SRTC_IDLE = 5'b00001;
parameter SRTC_READ = 5'b00010;
parameter SRTC_COMMAND = 5'b00100;
parameter SRTC_WRITE = 5'b01000;
parameter SRTC_WRITE2 = 5'b10000;

assign srtc_reg_we_rising = reg_we_rising;
assign srtc_state = mode_r;
assign srtc_rtc_ptr = rtc_ptr;

initial begin
  rtc_we_r = 0;
  mode_r = SRTC_READ;
  rtc_ptr = 4'hf;
  data_out_r = 8'h00;
end

always @(posedge clkin) begin
  if(reset_rising) begin
    mode_r <= SRTC_READ;
    rtc_ptr <= 4'hf;
  end else if(reg_we_rising && enable) begin
    case (addr_in)
//     1'b0: // data register is read only
      1'b1: // control register
        case (data_in)
          4'hd: begin
            mode_r <= SRTC_READ;
            rtc_ptr <= 4'hf;
          end
          4'he: begin
            mode_r <= SRTC_COMMAND;
          end
          default: begin
            if(mode_r == SRTC_COMMAND) begin
              case (data_in)
                4'h0: begin
                  mode_r <= SRTC_WRITE;
                  rtc_data_out_r <= rtc_data_in;
                  rtc_ptr <= 4'h0;
                end
                4'h4: begin
                  mode_r <= SRTC_IDLE;
                  rtc_ptr <= 4'hf;
                end
                default:
                  mode_r <= SRTC_IDLE;
              endcase
            end else if(mode_r == SRTC_WRITE) begin
              rtc_ptr <= rtc_ptr + 1;
              case(rtc_ptr)
                0: rtc_data_out_r[3:0] <= data_in;
                1: rtc_data_out_r[7:4] <= data_in;
                2: rtc_data_out_r[11:8] <= data_in;
                3: rtc_data_out_r[15:12] <= data_in;
                4: rtc_data_out_r[19:16] <= data_in;
                5: rtc_data_out_r[23:20] <= data_in;
                6: rtc_data_out_r[27:24] <= data_in;
                7: rtc_data_out_r[31:28] <= data_in;
                8: begin
                  rtc_data_out_r[35:32] <= (data_in < 10)
                                           ? data_in
                                           : data_in - 10;
                  rtc_data_out_r[39:36] <= data_in < 10 ? 0 : 1;
                end
                9: rtc_data_out_r[43:40] <= data_in;
                10: rtc_data_out_r[47:44] <= data_in;
                11: begin
                  rtc_data_out_r[51:48] <= (data_in < 10)
                                           ? data_in
                                           : data_in - 10;
                  rtc_data_out_r[55:52] <= data_in < 10 ? 1 : 2;
                end
              endcase
              mode_r <= SRTC_WRITE2;
              we_countdown_r <= 4;
              rtc_we_r <= 1;
            end
          end
        endcase
    endcase
  end else if(reg_oe_falling && enable) begin
    case (addr_in)
      1'b0: // read data register
      if(mode_r == SRTC_READ) begin
        case(rtc_ptr)
          0: data_out_r <= rtc_data_r[3:0];
          1: data_out_r <= rtc_data_r[7:4];
          2: data_out_r <= rtc_data_r[11:8];
          3: data_out_r <= rtc_data_r[15:12];
          4: data_out_r <= rtc_data_r[19:16];
          5: data_out_r <= rtc_data_r[23:20];
          6: data_out_r <= rtc_data_r[27:24];
          7: data_out_r <= rtc_data_r[31:28];
          8: data_out_r <= rtc_data_r[35:32]
                           + (rtc_data_r[39:36] << 1)
                           + (rtc_data_r[39:36] << 3);
          9: data_out_r <= rtc_data_r[43:40];
          10: data_out_r <= rtc_data_r[47:44];
          11: data_out_r <= rtc_data_r[51:48]
                            + (rtc_data_r[55:52] << 1)
                            + (rtc_data_r[55:52] << 3) - 10;
          12: data_out_r <= rtc_data_r[59:56];
//       14: mode_r <= SRTC_IDLE;
          15: begin
            rtc_data_r <= rtc_data_in;
            data_out_r <= 8'h0f;
          end
          default: data_out_r <= 8'h0f;
        endcase
        rtc_ptr <= rtc_ptr == 13 ? 15 : rtc_ptr + 1;
      end else begin
        data_out_r <= 8'h00;
      end
//      1'b1: // control register is write only
    endcase
  end else if(mode_r == SRTC_WRITE2) begin
    we_countdown_r <= we_countdown_r - 1;
    if (we_countdown_r == 3'b000) begin
      mode_r <= SRTC_WRITE;
      rtc_we_r <= 0;
    end
  end
end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    23:32:12 01/08/2011
// Design Name:
// Module Name:    rtc_srtc
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
module rtc (
  input clkin,
  input pgm_we,
  input [55:0] rtc_data_in,
  input we1,
  input [59:0] rtc_data_in1,
  output [59:0] rtc_data
);

reg [59:0] rtc_data_r;
reg [59:0] rtc_data_out_r;

reg [1:0] pgm_we_sreg;
always @(posedge clkin) pgm_we_sreg <= {pgm_we_sreg[0], pgm_we};
wire pgm_we_rising = (pgm_we_sreg[1:0] == 2'b01);

reg [2:0] we1_sreg;
always @(posedge clkin) we1_sreg <= {we1_sreg[1:0], we1};
wire we1_rising = (we1_sreg[2:1] == 2'b01);

reg [31:0] tick_cnt;

always @(posedge clkin) begin
  tick_cnt <= tick_cnt + 1;
  if((tick_cnt == 24000000) || pgm_we_rising) tick_cnt <= 0;
end

assign rtc_data = rtc_data_out_r;

reg [21:0] rtc_state;
reg carry;

reg [3:0] dom1[11:0];
reg [3:0] dom10[11:0];
reg [3:0] month;
reg [1:0] year;

reg [4:0] dow_day;
reg [3:0] dow_month;
reg [13:0] dow_year;
reg [6:0] dow_year1;
reg [6:0] dow_year100;
reg [15:0] dow_tmp;

parameter [21:0]
  STATE_SEC1     = 22'b0000000000000000000001,
  STATE_SEC10    = 22'b0000000000000000000010,
  STATE_MIN1     = 22'b0000000000000000000100,
  STATE_MIN10    = 22'b0000000000000000001000,
  STATE_HOUR1    = 22'b0000000000000000010000,
  STATE_HOUR10   = 22'b0000000000000000100000,
  STATE_DAY1     = 22'b0000000000000001000000,
  STATE_DAY10    = 22'b0000000000000010000000,
  STATE_MON1     = 22'b0000000000000100000000,
  STATE_MON10    = 22'b0000000000001000000000,
  STATE_YEAR1    = 22'b0000000000010000000000,
  STATE_YEAR10   = 22'b0000000000100000000000,
  STATE_YEAR100  = 22'b0000000001000000000000,
  STATE_YEAR1000 = 22'b0000000010000000000000,
  STATE_DOW0     = 22'b0000000100000000000000,
  STATE_DOW1     = 22'b0000001000000000000000,
  STATE_DOW2     = 22'b0000010000000000000000,
  STATE_DOW3     = 22'b0000100000000000000000,
  STATE_DOW4     = 22'b0001000000000000000000,
  STATE_DOW5     = 22'b0010000000000000000000,
  STATE_LATCH    = 22'b0100000000000000000000,
  STATE_IDLE     = 22'b1000000000000000000000;

initial begin
  rtc_state = STATE_IDLE;
  dom1[0] = 1; dom10[0] = 3;
  dom1[1] = 8; dom10[1] = 2;
  dom1[2] = 1; dom10[2] = 3;
  dom1[3] = 0; dom10[3] = 3;
  dom1[4] = 1; dom10[4] = 3;
  dom1[5] = 0; dom10[5] = 3;
  dom1[6] = 1; dom10[6] = 3;
  dom1[7] = 1; dom10[7] = 3;
  dom1[8] = 0; dom10[8] = 3;
  dom1[9] = 1; dom10[9] = 3;
  dom1[10] = 0; dom10[10] = 3;
  dom1[11] = 1; dom10[11] = 3;
  month = 0;
  rtc_data_r = 60'h220110301000000;
  tick_cnt = 0;
end

wire is_leapyear_feb = (month == 1) && (year[1:0] == 2'b00);

always @(posedge clkin) begin
  if(!tick_cnt) begin
    rtc_state <= STATE_SEC1;
  end else begin
    case (rtc_state)
      STATE_SEC1:
        rtc_state <= STATE_SEC10;
      STATE_SEC10:
        rtc_state <= STATE_MIN1;
      STATE_MIN1:
        rtc_state <= STATE_MIN10;
      STATE_MIN10:
        rtc_state <= STATE_HOUR1;
      STATE_HOUR1:
        rtc_state <= STATE_HOUR10;
      STATE_HOUR10:
        rtc_state <= STATE_DAY1;
      STATE_DAY1:
        rtc_state <= STATE_DAY10;
      STATE_DAY10:
        rtc_state <= STATE_MON1;
      STATE_MON1:
        rtc_state <= STATE_MON10;
      STATE_MON10:
        rtc_state <= STATE_YEAR1;
      STATE_YEAR1:
        rtc_state <= STATE_YEAR10;
      STATE_YEAR10:
        rtc_state <= STATE_YEAR100;
      STATE_YEAR100:
        rtc_state <= STATE_YEAR1000;
      STATE_YEAR1000:
        rtc_state <= STATE_DOW0;
      STATE_DOW0:
        rtc_state <= STATE_DOW1;
      STATE_DOW1:
        rtc_state <= STATE_DOW2;
      STATE_DOW2:
        rtc_state <= STATE_DOW3;
      STATE_DOW3:
        rtc_state <= STATE_DOW4;
      STATE_DOW4:
        if(dow_tmp > 13)
          rtc_state <= STATE_DOW4;
        else
          rtc_state <= STATE_DOW5;
      STATE_DOW5:
        rtc_state <= STATE_LATCH;
      STATE_LATCH:
        rtc_state <= STATE_IDLE;
      default:
        rtc_state <= STATE_IDLE;
    endcase
  end
end

always @(posedge clkin) begin
  if(pgm_we_rising) begin
    rtc_data_r[55:0] <= rtc_data_in;
  end else if (we1_rising) begin
    rtc_data_r <= rtc_data_in1;
  end else begin
    case(rtc_state)
      STATE_SEC1: begin
        if(rtc_data_r[3:0] == 9) begin
          rtc_data_r[3:0] <= 0;
          carry <= 1;
        end else begin
          rtc_data_r[3:0] <= rtc_data_r[3:0] + 1;
          carry <= 0;
        end
      end
      STATE_SEC10: begin
        if(carry) begin
          if(rtc_data_r[7:4] == 5) begin
            rtc_data_r[7:4] <= 0;
            carry <= 1;
          end else begin
            rtc_data_r[7:4] <= rtc_data_r[7:4] + 1;
            carry <= 0;
          end
        end
      end
      STATE_MIN1: begin
        if(carry) begin
          if(rtc_data_r[11:8] == 9) begin
            rtc_data_r[11:8] <= 0;
            carry <= 1;
          end else begin
            rtc_data_r[11:8] <= rtc_data_r[11:8] + 1;
            carry <= 0;
          end
        end
      end
      STATE_MIN10: begin
        if(carry) begin
          if(rtc_data_r[15:12] == 5) begin
            rtc_data_r[15:12] <= 0;
            carry <= 1;
          end else begin
            rtc_data_r[15:12] <= rtc_data_r[15:12] + 1;
            carry <= 0;
          end
        end
      end
      STATE_HOUR1: begin
        if(carry) begin
          if(rtc_data_r[23:20] == 2 && rtc_data_r[19:16] == 3) begin
            rtc_data_r[19:16] <= 0;
            carry <= 1;
          end else if (rtc_data_r[19:16] == 9) begin
            rtc_data_r[19:16] <= 0;
            carry <= 1;
         end else begin
            rtc_data_r[19:16] <= rtc_data_r[19:16] + 1;
            carry <= 0;
          end
        end
      end
      STATE_HOUR10: begin
        if(carry) begin
          if(rtc_data_r[23:20] == 2) begin
            rtc_data_r[23:20] <= 0;
            carry <= 1;
          end else begin
            rtc_data_r[23:20] <= rtc_data_r[23:20] + 1;
            carry <= 0;
          end
        end
      end
      STATE_DAY1: begin
        if(carry) begin
          if(rtc_data_r[31:28] == dom10[month]
             && rtc_data_r[27:24] == dom1[month] + is_leapyear_feb) begin
            rtc_data_r[27:24] <= 0;
            carry <= 1;
          end else if (rtc_data_r[27:24] == 9) begin
            rtc_data_r[27:24] <= 0;
            carry <= 1;
          end else begin
            rtc_data_r[27:24] <= rtc_data_r[27:24] + 1;
            carry <= 0;
          end
        end
      end
      STATE_DAY10: begin
        if(carry) begin
          if(rtc_data_r[31:28] == dom10[month]) begin
            rtc_data_r[31:28] <= 0;
            rtc_data_r[27:24] <= 1;
            carry <= 1;
          end else begin
            rtc_data_r[31:28] <= rtc_data_r[31:28] + 1;
            carry <= 0;
          end
        end
      end
      STATE_MON1: begin
        if(carry) begin
          if(rtc_data_r[39:36] == 1 && rtc_data_r[35:32] == 2) begin
            rtc_data_r[35:32] <= 1;
            carry <= 1;
          end else if (rtc_data_r[35:32] == 9) begin
            rtc_data_r[35:32] <= 0;
            carry <= 1;
          end else begin
            rtc_data_r[35:32] <= rtc_data_r[35:32] + 1;
            carry <= 0;
          end
        end
      end
      STATE_MON10: begin
        if(carry) begin
          if(rtc_data_r[39:36] == 1) begin
            rtc_data_r[39:36] <= 0;
            carry <= 1;
          end else begin
            rtc_data_r[39:36] <= rtc_data_r[39:36] + 1;
            carry <= 0;
          end
        end
      end
      STATE_YEAR1: begin
        month <= rtc_data_r[35:32] + (rtc_data_r[36] ? 10 : 0) - 1;
        if(carry) begin
          if(rtc_data_r[43:40] == 9) begin
            rtc_data_r[43:40] <= 0;
            carry <= 1;
          end else begin
            rtc_data_r[43:40] <= rtc_data_r[43:40] + 1;
            carry <= 0;
          end
        end
      end
      STATE_YEAR10: begin
        if(carry) begin
          if(rtc_data_r[47:44] == 9) begin
            rtc_data_r[47:44] <= 0;
            carry <= 1;
          end else begin
            rtc_data_r[47:44] <= rtc_data_r[47:44] + 1;
            carry <= 0;
          end
        end
      end
      STATE_YEAR100: begin
        if(carry) begin
          if(rtc_data_r[51:48] == 9) begin
            rtc_data_r[51:48] <= 0;
            carry <= 1;
          end else begin
            rtc_data_r[51:48] <= rtc_data_r[51:48] + 1;
            carry <= 0;
          end
        end
      end
      STATE_YEAR1000: begin
        if(carry) begin
          if(rtc_data_r[55:52] == 9) begin
            rtc_data_r[55:52] <= 0;
            carry <= 1;
          end else begin
            rtc_data_r[55:52] <= rtc_data_r[55:52] + 1;
            carry <= 0;
          end
        end
      end
      STATE_DOW0: begin
        dow_year1 <= rtc_data_r[43:40]
                     +(rtc_data_r[47:44] << 1) + (rtc_data_r[47:44] << 3);

        dow_year100 <= rtc_data_r[51:48]
                       +(rtc_data_r[55:52] << 1) + (rtc_data_r[55:52] << 3);

        dow_month <= month + 1;
        dow_day <= rtc_data_r[27:24]
                   + (rtc_data_r[31:28] << 1)
                   + (rtc_data_r[31:28] << 3);
      end
      STATE_DOW1: begin
        year <= dow_year1[1:0];
        if(dow_month <= 2) begin
          dow_month <= dow_month + 10;
          dow_year <= dow_year1
                      + (dow_year100 << 2)
                      + (dow_year100 << 5)
                      + (dow_year100 << 6) - 1;
          if(dow_year1)
            dow_year1 <= dow_year1 - 1;
          else begin
            dow_year1 <= 99;
            dow_year100 <= dow_year100 - 1;
          end
        end else begin
          dow_month <= dow_month - 2;
          dow_year <= dow_year1 + (dow_year100 << 2) + (dow_year100 << 5) + (dow_year100 << 6);
        end
      end
      STATE_DOW2: begin
        dow_tmp <= (83 * dow_month);
      end
      STATE_DOW3: begin
        dow_tmp <= (dow_tmp >> 5)
                   + dow_day
                   + dow_year
                   + (dow_year >> 2)
                   - (dow_year100)
                   + (dow_year100 >> 2);
      end
      STATE_DOW4: begin
        dow_tmp <= dow_tmp - 7;
      end
      STATE_DOW5: begin
        rtc_data_r[59:56] <= {1'b0, dow_tmp[2:0]};
      end
      STATE_LATCH: begin
        rtc_data_out_r <= rtc_data_r;
      end
    endcase
  end
end

endmodule

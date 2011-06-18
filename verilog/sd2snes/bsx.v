`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:43:54 02/06/2011 
// Design Name: 
// Module Name:    bsx 
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
module bsx(
  input clkin,
  input reg_oe,
  input reg_we,
  input [23:0] snes_addr,
  input [7:0] reg_data_in,
  output [7:0] reg_data_out,
  input [7:0] reg_reset_bits,
  input [7:0] reg_set_bits,
  output [14:0] regs_out,
  input pgm_we,
  input [14:0] regs_in,
  input use_bsx,
  output data_ovr,
  output flash_writable,
  input [59:0] rtc_data
);

wire [3:0] reg_addr = snes_addr[19:16]; // 00-0f:5000-5fff
wire [4:0] base_addr = snes_addr[4:0];  // 88-9f -> 08-1f
wire [15:0] flash_addr = snes_addr[15:0];

reg flash_ovr_r;
reg flash_we_r;
reg [16:0] flash_cmd0;
reg [24:0] flash_cmd5555;

wire cart_enable = (use_bsx) && ((snes_addr[23:12] & 12'hf0f) == 12'h005);

wire base_enable = (use_bsx) && (!snes_addr[22] && (snes_addr[15:0] >= 16'h2188)
                                 && (snes_addr[15:0] <= 16'h219f));

wire flash_enable = (snes_addr[23:16] == 8'hc0);

wire is_flash_special_address = (flash_addr == 16'h0002
                                 || flash_addr == 16'h5555
                                 || flash_addr == 16'h2aaa
                                 || flash_addr == 16'h0000
                                 || (flash_addr >= 16'hff00
                                     && flash_addr <= 16'hff13));

wire flash_ovr = (use_bsx)
                 && (flash_enable & flash_ovr_r)
                 && is_flash_special_address;

assign flash_writable = (use_bsx)
                        && flash_enable
                        && flash_we_r
                        && !is_flash_special_address;

assign data_ovr = cart_enable | base_enable | flash_ovr;

reg [5:0] reg_oe_sreg;
always @(posedge clkin) reg_oe_sreg <= {reg_oe_sreg[4:0], reg_oe};
wire reg_oe_falling = (reg_oe_sreg[3:0] == 4'b1000);
wire reg_oe_rising = (reg_oe_sreg[3:0] == 4'b0001);

reg [1:0] reg_we_sreg;
always @(posedge clkin) reg_we_sreg <= {reg_we_sreg[0], reg_we};
wire reg_we_rising = (reg_we_sreg[1:0] == 2'b01);

reg [1:0] pgm_we_sreg;
always @(posedge clkin) pgm_we_sreg <= {pgm_we_sreg[0], pgm_we};
wire pgm_we_rising = (pgm_we_sreg[1:0] == 2'b01);

reg [15:0] regs_tmpr;
reg [14:0] regs_outr;
reg [7:0] reg_data_outr;

reg [7:0] base_regs[31:8];
reg [4:0] bsx_counter;
reg [7:0] flash_vendor_data[7:0];

assign regs_out = regs_outr;
assign reg_data_out = reg_data_outr;

wire [7:0] rtc_sec = rtc_data[3:0] + (rtc_data[7:4] << 3) + (rtc_data[7:4] << 1);
wire [7:0] rtc_min = rtc_data[11:8] + (rtc_data[15:12] << 3) + (rtc_data[15:12] << 1);
wire [7:0] rtc_hour = rtc_data[19:16] + (rtc_data[23:20] << 3) + (rtc_data[23:20] << 1);
wire [7:0] rtc_day = rtc_data[27:24] + (rtc_data[31:28] << 3) + (rtc_data[31:28] << 1);
wire [7:0] rtc_month = rtc_data[35:32] + (rtc_data[39:36] << 3) + (rtc_data[39:36] << 1);
wire [7:0] rtc_year1 = rtc_data[43:40] + (rtc_data[47:44] << 3) + (rtc_data[47:44] << 1);
wire [7:0] rtc_year100 = rtc_data[51:48] + (rtc_data[55:52] << 3) + (rtc_data[55:52] << 1);

initial begin
  regs_tmpr <= 16'b0_000000100000000;
  regs_outr <= 15'b000000100000000;
  bsx_counter <= 0;
  base_regs[8] <= 0;
  base_regs[9] <= 0;
  base_regs[10] <= 0;
  base_regs[11] <= 8'h9f;
  base_regs[12] <= 8'h10;
  base_regs[13] <= 8'h9f;
  base_regs[14] <= 0;
  base_regs[15] <= 0;
  base_regs[16] <= 0;
  base_regs[17] <= 8'h9f;
  base_regs[18] <= 8'h01;
  base_regs[19] <= 8'h9f;
  base_regs[20] <= 0;
  base_regs[21] <= 0;
  base_regs[22] <= 8'h02;
  base_regs[23] <= 8'hff;
  base_regs[24] <= 8'h80;
  base_regs[25] <= 8'h01;
  base_regs[26] <= 0;
  base_regs[27] <= 0;
  base_regs[28] <= 0;
  base_regs[29] <= 0;
  base_regs[30] <= 0;
  base_regs[31] <= 0;
  flash_vendor_data[3'h0] <= 8'h4d;
  flash_vendor_data[3'h1] <= 8'h00;
  flash_vendor_data[3'h2] <= 8'h50;
  flash_vendor_data[3'h3] <= 8'h00;
  flash_vendor_data[3'h4] <= 8'h00;
  flash_vendor_data[3'h5] <= 8'h00;
  flash_vendor_data[3'h6] <= 8'h2a;
  flash_vendor_data[3'h7] <= 8'h00;
  flash_ovr_r <= 1'b0;
  flash_we_r <= 1'b0;
end


always @(posedge clkin) begin
  if(reg_oe_falling) begin
    if(cart_enable)
      reg_data_outr <= {regs_outr[reg_addr], 7'b0};
    else if(base_enable) begin
      case(base_addr)
        5'b10010: begin
          if(bsx_counter < 18) begin
            bsx_counter <= bsx_counter + 1;
            case (bsx_counter)
              5:
                reg_data_outr <= 8'h1;
              6:
                reg_data_outr <= 8'h1;
              10:
                reg_data_outr <= rtc_sec;
              11:
                reg_data_outr <= rtc_min;
              12:
                reg_data_outr <= rtc_hour;
              default:
                reg_data_outr <= 8'h0;
            endcase
          end else begin
            reg_data_outr <= 8'h0;
            bsx_counter <= 0;
          end
        end
        5'b10011:
          reg_data_outr <= base_regs[base_addr] & 8'h3f;
        default:
          reg_data_outr <= base_regs[base_addr];
      endcase
    end else if (flash_enable) begin
      casex (flash_addr)
        16'h0002:
          reg_data_outr <= 8'h80;
        16'h5555:
          reg_data_outr <= 8'h80;
        16'b1111111100000xxx:
          reg_data_outr <= flash_vendor_data[flash_addr&16'h0007];
        default:
          reg_data_outr <= 8'h00;
      endcase
    end
  end else if(pgm_we_rising) begin
    regs_tmpr[8:1] <= (regs_tmpr[8:1] | reg_set_bits[7:0]) & ~reg_reset_bits[7:0];
      regs_outr[8:1] <= (regs_outr[8:1] | reg_set_bits[7:0]) & ~reg_reset_bits[7:0];
  end else if(reg_we_rising && cart_enable) begin
    if(reg_addr == 4'he && reg_data_in[7])
      regs_outr <= regs_tmpr | 16'b0100000000000000;
    else
      regs_tmpr[reg_addr] <= reg_data_in[7];
  end else if(reg_we_rising && base_enable) begin
    case(base_addr)
      5'h0f: begin
        base_regs[base_addr-1] <= base_regs[base_addr]-(base_regs[base_addr-1] >> 1);
        base_regs[base_addr] <= base_regs[base_addr] >> 1;
      end
      5'h11: begin
        bsx_counter <= 0;
        base_regs[base_addr] <= reg_data_in;
      end
      5'h12: begin
        base_regs[8'h10] <= 8'h80;
      end
      default:
        base_regs[base_addr] <= reg_data_in;
    endcase
  end else if(reg_we_rising && flash_enable) begin
    case(flash_addr)
      16'h0000: begin
        flash_cmd0 <= {flash_cmd0[7:0], reg_data_in};
        if(flash_cmd0[7:0] == 8'h38 && reg_data_in == 8'hd0)
          flash_ovr_r <= 1;
      end
      16'h5555: begin
        flash_cmd5555 <= {flash_cmd5555[15:0], reg_data_in};
        if(flash_cmd5555[15:0] == 16'haa55) begin
          case (reg_data_in)
            8'hf0: begin
              flash_ovr_r <= 0;
              flash_we_r <= 0;
            end
            8'ha0: begin
              flash_ovr_r <= 1;
              flash_we_r <= 1;
            end
            8'h70: begin
              flash_we_r <= 0;
            end
          endcase
        end
      end
      16'h2aaa: begin
        flash_cmd5555 <= {flash_cmd5555[15:0], reg_data_in};
      end
   endcase
  end
end

endmodule

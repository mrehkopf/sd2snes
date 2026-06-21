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
  input reg_oe_falling,
  input reg_oe_rising,
  input reg_we_rising,
  input [23:0] snes_addr_in,
  input [7:0] reg_data_in,
  output [7:0] reg_data_out,
  input [7:0] reg_reset_bits,
  input [7:0] reg_set_bits,
  output [14:0] regs_out,
  input pgm_we,
  input use_bsx,
  input bs_slot,    // slotted cart: pack only, no MCC.  LoROM slot -> flash $C0-$DF
  input bs_hirom,   // HiROM slot -> window $E0-$EF
  output data_ovr,
  output flash_writable,
  input [59:0] rtc_data_in,
  output [9:0] bs_page_out, // support only page 0000-03ff
  output bs_page_enable,
  output [8:0] bs_page_offset,
  input feat_bs_base_enable,
  // Flash erase request to the MCU (the FPGA can't fill 64KB; the MCU does the
  // sram_memset(0xFF)).  bs_erase_seq increments on each erase; the MCU compares it
  // to its last-seen value and erases bs_erase_blk (0xF = whole pack).
  output [1:0] bs_erase_seq,
  output [3:0] bs_erase_blk
);

`define BSX_ENABLE

`ifndef BSX_ENABLE
assign reg_data_out = 0;
assign regs_out = 0;
assign data_ovr = 0;
assign flash_writeable = 0;
assign bs_page_out = 0;
assign bs_page_enable = 0;
assign bs_page_offset = 0;
`else
reg [59:0] rtc_data; always @(posedge clkin) rtc_data <= rtc_data_in;
reg [23:0] snes_addr; always @(posedge clkin) snes_addr <= snes_addr_in;

wire [3:0] reg_addr = snes_addr[19:16]; // 00-0f:5000-5fff
wire [4:0] base_addr = snes_addr[4:0];  // 88-9f -> 08-1f
wire [15:0] flash_addr = snes_addr[15:0];

reg flash_ovr_r;
reg flash_we_r;
reg flash_status_r = 0;
reg [7:0] flash_cmd0;

// MCC registers (00-0f:5xxx) exist only on the BS-X base cart, never on a
// slotted cart -> gate them off in slot mode so the game's low banks are free.
wire cart_enable = (use_bsx) && ~bs_slot && ((snes_addr[23:12] & 12'hf0f) == 12'h005);

wire base_enable = feat_bs_base_enable
                   & (use_bsx) && (!snes_addr[22] && (snes_addr[15:0] >= 16'h2188)
                                 && (snes_addr[15:0] <= 16'h219f));

// flash window: base $C0, LoROM slot $C0-$DF, HiROM slot $E0-$EF
wire flash_enable = bs_hirom
                    ? (snes_addr[23:20] == 4'he)
                    : ((snes_addr[23:16] == 8'hc0)
                       | (bs_slot & (snes_addr[23:21] == 3'b110)));

// command/vendor mode returns the register; array mode ($FF) reads PSRAM
wire flash_ovr = (use_bsx) && (flash_enable & flash_ovr_r);

// program data phase; main.v does the write (skips $FF) via the copier path
assign flash_writable = (use_bsx)
                        && flash_enable
                        && flash_we_r;

assign data_ovr = (cart_enable | base_enable | flash_ovr) & ~bs_page_enable;

// --- Flash block-erase tracking -------------------------------------------
// block-erase = $20 (setup) then $D0 (confirm) at the block address.
// 64KB blocks: HiROM bank $E0+blk, LoROM 2 banks/block ($C0+2*blk).
reg erase_setup_r = 0;      // saw $20 (block erase setup)
reg erase_all_setup_r = 0;  // saw $A7 (chip/all erase setup)
// a delete can fire several erases, so a 1-bit toggle would alias -> 2-bit seq the
// MCU compares (any change = erase).  bs_erase_blk = last block, 0xF = whole pack.
reg [1:0] bs_erase_seq_r = 0;
reg [3:0] bs_erase_blk_r = 0;
assign bs_erase_seq = bs_erase_seq_r;
assign bs_erase_blk = bs_erase_blk_r;
wire [3:0] erase_blk_of_addr = bs_hirom ? snes_addr[19:16] : snes_addr[20:17];
// busy timer held after a $D0 so the game waits while the MCU erases the block (~0.4s)
reg [24:0] erase_busy_cnt = 0;
wire erase_busy = (erase_busy_cnt != 0);


reg [9:0] bs_page0;
reg [9:0] bs_page1;

reg [8:0] bs_page0_offset;
reg [8:0] bs_page1_offset;
reg [4:0] bs_stb0_offset;
reg [4:0] bs_stb1_offset;

wire bs_sta0_en = base_addr == 5'h0a;
wire bs_stb0_en = base_addr == 5'h0b;
wire bs_page0_en = base_addr == 5'h0c;

wire bs_sta1_en = base_addr == 5'h10;
wire bs_stb1_en = base_addr == 5'h11;
wire bs_page1_en = base_addr == 5'h12;

assign bs_page_enable = base_enable & ((|bs_page0 & (bs_page0_en | bs_sta0_en | bs_stb0_en))
                                      |(|bs_page1 & (bs_page1_en | bs_sta1_en | bs_stb1_en)));

assign bs_page_out = (bs_page0_en | bs_sta0_en | bs_stb0_en) ? bs_page0 : bs_page1;

assign bs_page_offset = bs_sta0_en ? 9'h032
                      : bs_stb0_en ? (9'h034 + bs_stb0_offset)
                      : bs_sta1_en ? 9'h032
                      : bs_stb1_en ? (9'h034 + bs_stb1_offset)
                      : (9'h048 + (bs_page0_en ? bs_page0_offset : bs_page1_offset));

reg [1:0] pgm_we_sreg;
always @(posedge clkin) pgm_we_sreg <= {pgm_we_sreg[0], pgm_we};
wire pgm_we_rising = (pgm_we_sreg[1:0] == 2'b01);

reg [14:0] regs_tmpr;
reg [14:0] regs_outr;
reg [7:0] reg_data_outr;

reg [7:0] base_regs[31:8];
reg [4:0] bsx_counter;
reg [7:0] flash_vendor_data[7:0];

assign regs_out = regs_outr;
assign reg_data_out = reg_data_outr;

reg [7:0] rtc_sec, rtc_sec_pre0, rtc_sec_pre1;

reg [7:0] rtc_min, rtc_min_pre0, rtc_min_pre1;
reg [7:0] rtc_hour, rtc_hour_pre0, rtc_hour_pre1;
reg [7:0] rtc_day, rtc_day_pre0, rtc_day_pre1;
reg [7:0] rtc_month, rtc_month_pre0, rtc_month_pre1;
reg [7:0] rtc_dow;
reg [7:0] rtc_year1, rtc_year1_pre0, rtc_year1_pre1;
reg [7:0] rtc_year100, rtc_year100_pre0, rtc_year100_pre1;
reg [15:0] rtc_year, rtc_year_pre0, rtc_year_pre1, rtc_year_pre2;

// wire [7:0] rtc_sec_pre = rtc_data[3:0] + (rtc_data[7:4] << 3) + (rtc_data[7:4] << 1);
// wire [7:0] rtc_min_pre = rtc_data[11:8] + (rtc_data[15:12] << 3) + (rtc_data[15:12] << 1);
// wire [7:0] rtc_hour_pre = rtc_data[19:16] + (rtc_data[23:20] << 3) + (rtc_data[23:20] << 1);
// wire [7:0] rtc_day_pre = rtc_data[27:24] + (rtc_data[31:28] << 3) + (rtc_data[31:28] << 1);
// wire [7:0] rtc_month_pre = rtc_data[35:32] + (rtc_data[39:36] << 3) + (rtc_data[39:36] << 1);
// wire [7:0] rtc_dow_pre = {4'b0,rtc_data[59:56]};
// wire [7:0] rtc_year1_pre = rtc_data[43:40] + (rtc_data[47:44] << 3) + (rtc_data[47:44] << 1);
// wire [7:0] rtc_year100_pre = rtc_data[51:48] + (rtc_data[55:52] << 3) + (rtc_data[55:52] << 1);
// wire [15:0] rtc_year_pre = (rtc_year100 << 6) + (rtc_year100 << 5) + (rtc_year100 << 2) + rtc_year1;

always @(posedge clkin) begin
  rtc_sec_pre1 <= rtc_data[3:0];
  rtc_sec_pre0 <= rtc_sec_pre1 + (rtc_data[7:4] << 3);
  rtc_sec <= rtc_sec_pre0 + (rtc_data[7:4] << 1);

  rtc_min_pre1 <= rtc_data[11:8];
  rtc_min_pre0 <= rtc_min_pre1 + (rtc_data[15:12] << 3);
  rtc_min <= rtc_min_pre0 + (rtc_data[15:12] << 1);

  rtc_hour_pre1 <= rtc_data[19:16];
  rtc_hour_pre0 <= rtc_hour_pre1 + (rtc_data[23:20] << 3);
  rtc_hour <= rtc_hour_pre0 + (rtc_data[23:20] << 1);
  
  rtc_day_pre1 <= rtc_data[27:24];
  rtc_day_pre0 <= rtc_day_pre1 + (rtc_data[31:28] << 3);
  rtc_day <= rtc_day_pre0 + (rtc_data[31:28] << 1);
  
  rtc_month_pre1 <= rtc_data[35:32];
  rtc_month_pre0 <= rtc_month_pre1 + (rtc_data[39:36] << 3);
  rtc_month <= rtc_month_pre0 + (rtc_data[39:36] << 1);
  
  rtc_dow <= {4'b0, rtc_data[59:56]};
  
  rtc_year1_pre1 <= rtc_data[43:40];
  rtc_year1_pre0 <= rtc_year1_pre1 + (rtc_data[47:44] << 3);
  rtc_year1 <= rtc_year1_pre0 + (rtc_data[47:44] << 1);
  
  rtc_year100_pre1 <= rtc_data[51:48];
  rtc_year100_pre0 <= rtc_year100_pre1 + (rtc_data[55:52] << 3);
  rtc_year100 <= rtc_year100_pre0 + (rtc_data[55:52] << 1);
  
  rtc_year_pre2 <= (rtc_year100 << 6);
  rtc_year_pre1 <= rtc_year_pre2 + (rtc_year100 << 5);
  rtc_year_pre0 <= rtc_year_pre1 + (rtc_year100 << 2);
  rtc_year <= rtc_year_pre0 + rtc_year1;
end

initial begin
  regs_tmpr <= 15'b000101111101100;
  regs_outr <= 15'b000101111101100;
  bsx_counter <= 0;
  base_regs[5'h08] <= 0;
  base_regs[5'h09] <= 0;
  base_regs[5'h0a] <= 8'h01;
  base_regs[5'h0b] <= 0;
  base_regs[5'h0c] <= 0;
  base_regs[5'h0d] <= 0;
  base_regs[5'h0e] <= 0;
  base_regs[5'h0f] <= 0;
  base_regs[5'h10] <= 8'h01;
  base_regs[5'h11] <= 0;
  base_regs[5'h12] <= 0;
  base_regs[5'h13] <= 0;
  base_regs[5'h14] <= 0;
  base_regs[5'h15] <= 0;
  base_regs[5'h16] <= 0;
  base_regs[5'h17] <= 0;
  base_regs[5'h18] <= 0;
  base_regs[5'h19] <= 0;
  base_regs[5'h1a] <= 0;
  base_regs[5'h1b] <= 0;
  base_regs[5'h1c] <= 0;
  base_regs[5'h1d] <= 0;
  base_regs[5'h1e] <= 0;
  base_regs[5'h1f] <= 0;
  flash_vendor_data[3'h0] <= 8'h4d;
  flash_vendor_data[3'h1] <= 8'h00;
  flash_vendor_data[3'h2] <= 8'h50;
  flash_vendor_data[3'h3] <= 8'h00;
  flash_vendor_data[3'h4] <= 8'h00;
  flash_vendor_data[3'h5] <= 8'h00;
  flash_vendor_data[3'h6] <= 8'h1a;
  flash_vendor_data[3'h7] <= 8'h00;
  flash_ovr_r <= 1'b0;
  flash_we_r <= 1'b0;
  bs_page0 <= 10'h0;
  bs_page1 <= 10'h0;
  bs_page0_offset <= 9'h0;
  bs_page1_offset <= 9'h0;
  bs_stb0_offset <= 5'h00;
  bs_stb1_offset <= 5'h00;
end

always @(posedge clkin) begin
  if(erase_busy_cnt != 0) erase_busy_cnt <= erase_busy_cnt - 1'b1;  // WSM busy timer (a $D0 reloads it below)
  if(reg_oe_rising && base_enable) begin
    case(base_addr)
      5'h0b: begin
        bs_stb0_offset <= bs_stb0_offset + 1;
        base_regs[5'h0d] <= base_regs[5'h0d] | reg_data_in;
      end
      5'h0c: bs_page0_offset <= bs_page0_offset + 1;
      5'h11: begin
        bs_stb1_offset <= bs_stb1_offset + 1;
        base_regs[5'h13] <= base_regs[5'h13] | reg_data_in;
      end
      5'h12: bs_page1_offset <= bs_page1_offset + 1;
    endcase
  end else if(reg_oe_falling) begin
    if(cart_enable)
      reg_data_outr <= {regs_outr[reg_addr], 7'b0};
    else if(base_enable) begin
      case(base_addr)
        5'h0c, 5'h12: begin
          case (bs_page1_offset)
            4: reg_data_outr <= 8'h3;
            5: reg_data_outr <= 8'h1;
            6: reg_data_outr <= 8'h1;
            10: reg_data_outr <= rtc_sec;
            11: reg_data_outr <= rtc_min;
            12: reg_data_outr <= rtc_hour;
            13: reg_data_outr <= rtc_dow;
            14: reg_data_outr <= rtc_day;
            15: reg_data_outr <= rtc_month;
            16: reg_data_outr <= rtc_year[7:0];
            17: reg_data_outr <= rtc_hour;
            default: reg_data_outr <= 8'h0;
          endcase
        end
        5'h0d, 5'h13: begin
          reg_data_outr <= base_regs[base_addr];
          base_regs[base_addr] <= 8'h00;
        end
        default:
          reg_data_outr <= base_regs[base_addr];
      endcase
    end else if (flash_enable) begin
      // CSR ready = $80, busy = $00 (bit7); the game polls this after a $D0 and waits
      // while erase_busy so the MCU can fill the block before the next erase.
      casex (flash_addr)
        16'b1111111100000xxx:
          reg_data_outr <= flash_status_r ? (erase_busy ? 8'h00 : 8'h80) : flash_vendor_data[flash_addr&16'h0007];
        16'b1111111100001xxx,
        16'b11111111000100xx:
          reg_data_outr <= flash_status_r ? (erase_busy ? 8'h00 : 8'h80) : 8'h00;
        default:
          reg_data_outr <= (erase_busy ? 8'h00 : 8'h80);
      endcase
    end
  end else if(pgm_we_rising) begin
    regs_tmpr[8:1] <= (regs_tmpr[8:1] | reg_set_bits[7:0]) & ~reg_reset_bits[7:0];
    regs_outr[8:1] <= (regs_outr[8:1] | reg_set_bits[7:0]) & ~reg_reset_bits[7:0];
  end else if(reg_we_rising && cart_enable) begin
    if(reg_addr == 4'he)
      regs_outr <= regs_tmpr;
    else begin
      regs_tmpr[reg_addr] <= reg_data_in[7];
      if(reg_addr == 4'h1) regs_outr[reg_addr] <= reg_data_in[7];
    end
  end else if(reg_we_rising && base_enable) begin
    case(base_addr)
      5'h09: begin
        base_regs[8'h09] <= reg_data_in;
        bs_page0 <= {reg_data_in[1:0], base_regs[8'h08]};
        bs_page0_offset <= 9'h00;
      end
      5'h0b: begin
        bs_stb0_offset <= 5'h00;
      end
      5'h0c: begin
        bs_page0_offset <= 9'h00;
      end
      5'h0f: begin
        base_regs[8'h0f] <= reg_data_in;
        bs_page1 <= {reg_data_in[1:0], base_regs[8'h0e]};
        bs_page1_offset <= 9'h00;
      end
      5'h11: begin
        bs_stb1_offset <= 5'h00;
      end
      5'h12: begin
        bs_page1_offset <= 9'h00;
      end
      default:
        base_regs[base_addr] <= reg_data_in;
    endcase
  end else if(reg_we_rising && flash_enable && (regs_outr[4'hc] | bs_slot)) begin
    if(flash_we_r) begin
      flash_we_r <= 0;  // this write is the program byte, not a command
    end else begin
      // program/erase are issued at the target/block address (tracked here regardless
      // of address); program only arms the write byte and leaves the read mode alone.
      case(reg_data_in)
        8'h10, 8'h40: begin flash_we_r <= 1'b1; erase_setup_r <= 1'b0; erase_all_setup_r <= 1'b0; end
        8'h20: begin erase_setup_r <= 1'b1; erase_all_setup_r <= 1'b0; end
        8'ha7: begin erase_all_setup_r <= 1'b1; erase_setup_r <= 1'b0; end
        8'hd0: begin
          // block = the $D0 (confirm) address, not $20 (setup): $20 is at the command
          // port, $D0 at the block address ($C4:8000 -> block 2).
          if(erase_setup_r) begin
            bs_erase_seq_r <= bs_erase_seq_r + 1'b1; bs_erase_blk_r <= erase_blk_of_addr;
            erase_busy_cnt <= {25{1'b1}};
            flash_ovr_r <= 1'b1; flash_status_r <= 1'b1;
          end else if(erase_all_setup_r) begin
            bs_erase_seq_r <= bs_erase_seq_r + 1'b1; bs_erase_blk_r <= 4'hf;
            erase_busy_cnt <= {25{1'b1}};
            flash_ovr_r <= 1'b1; flash_status_r <= 1'b1;
          end
          erase_setup_r <= 1'b0; erase_all_setup_r <= 1'b0;
        end
        default: begin erase_setup_r <= 1'b0; erase_all_setup_r <= 1'b0; end
      endcase
      // mode commands ($FF/$70/$72/$75) only at the command port, so a stray pack
      // write can't flip the read mode (HiROM $E0:0000 / LoROM $C0:0000)
      if(bs_hirom ? ((snes_addr[23:16] == 8'he0) && (flash_addr[14:0] == 15'h0000))
         : bs_slot ? ((snes_addr[23:16] == 8'hc0) && (flash_addr[14:0] == 15'h0000))
         : (flash_addr == 16'h0000)) begin
        flash_cmd0 <= reg_data_in;
        if(flash_cmd0 == 8'h72 && reg_data_in == 8'h75) begin
          flash_ovr_r <= 1'b1; flash_status_r <= 1'b0;
        end else if(reg_data_in == 8'hff) begin
          flash_ovr_r <= 1'b0;
        end else if(reg_data_in[7:1] == 7'b0111000 || (flash_cmd0 == 8'h38 && reg_data_in == 8'hd0)) begin
          flash_ovr_r <= 1'b1; flash_status_r <= 1'b1;
        end
      end
    end
  end
end
`endif

endmodule
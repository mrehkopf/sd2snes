`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    16:53:07 07/01/2014
// Design Name:
// Module Name:    cheat
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
module cheat(
  input clk,
  input [23:0] SNES_ADDR,
  input [7:0] SNES_DATA,
  input SNES_reset_strobe,
  input snescmd_wr_strobe,
  input SNES_cycle_start,
  input [2:0] pgm_idx,
  input pgm_we,
  input [31:0] pgm_in,
  output [7:0] data_out,
  output cheat_hit,
  output snescmd_unlock
);

reg cheat_enable = 0;
reg nmi_enable = 0;
reg irq_enable = 0;
reg holdoff_enable = 0; // temp disable hooks after reset

reg auto_nmi_enable = 1;
reg auto_irq_enable = 0;
reg auto_nmi_enable_sync = 0;
reg auto_irq_enable_sync = 0;
reg hook_enable_sync = 0;

reg [1:0] sync_delay = 2'b10;

reg [4:0] nmi_usage = 5'h00;
reg [4:0] irq_usage = 5'h00;
reg [20:0] usage_count = 21'h1fffff;

reg [29:0] hook_enable_count = 0;
reg hook_disable = 0;

reg [3:0] unlock_token = 0;
reg [6:0] temp_unlock_delay = 0;
reg temp_vector_unlock = 0;

reg [23:0] cheat_addr[5:0];
reg [7:0] cheat_data[5:0];
reg [5:0] cheat_enable_mask;
wire [5:0] cheat_match_bits ={(cheat_enable_mask[5] & (SNES_ADDR == cheat_addr[5])),
                              (cheat_enable_mask[4] & (SNES_ADDR == cheat_addr[4])),
                              (cheat_enable_mask[3] & (SNES_ADDR == cheat_addr[3])),
                              (cheat_enable_mask[2] & (SNES_ADDR == cheat_addr[2])),
                              (cheat_enable_mask[1] & (SNES_ADDR == cheat_addr[1])),
                              (cheat_enable_mask[0] & (SNES_ADDR == cheat_addr[0]))};
wire cheat_addr_match = |cheat_match_bits;

wire [1:0] nmi_match_bits = {SNES_ADDR == 24'h00FFEA, SNES_ADDR == 24'h00FFEB};
wire [1:0] irq_match_bits = {SNES_ADDR == 24'h00FFEE, SNES_ADDR == 24'h00FFEF};

wire nmi_addr_match = |nmi_match_bits;
wire irq_addr_match = |irq_match_bits;


wire hook_enable = ~|hook_enable_count & ~hook_disable;

assign snescmd_unlock = &unlock_token | temp_vector_unlock;

assign data_out = cheat_match_bits[0] ? cheat_data[0]
                : cheat_match_bits[1] ? cheat_data[1]
                : cheat_match_bits[2] ? cheat_data[2]
                : cheat_match_bits[3] ? cheat_data[3]
                : cheat_match_bits[4] ? cheat_data[4]
                : cheat_match_bits[5] ? cheat_data[5]
                : nmi_match_bits[1] ? 8'hb0
                : irq_match_bits[1] ? 8'hc4
                : 8'h2b;

assign cheat_hit = (cheat_enable & cheat_addr_match)
                   | (hook_enable_sync & (((auto_nmi_enable_sync & nmi_enable) & nmi_addr_match)
                                           |((auto_irq_enable_sync & irq_enable) & irq_addr_match)));

always @(posedge clk) usage_count <= usage_count - 1;

// Try and autoselect NMI or IRQ hook
always @(posedge clk) begin
  if(usage_count == 21'b0) begin
    nmi_usage <= ~hook_disable & SNES_cycle_start & nmi_match_bits[1];
    irq_usage <= ~hook_disable & SNES_cycle_start & irq_match_bits[1];
    if(|nmi_usage & |irq_usage) begin
      auto_nmi_enable <= 1'b1;
      auto_irq_enable <= 1'b0;
    end else if(irq_usage == 5'b0) begin
      auto_nmi_enable <= 1'b1;
      auto_irq_enable <= 1'b0;
    end else if(nmi_usage == 5'b0) begin
      auto_nmi_enable <= 1'b0;
      auto_irq_enable <= 1'b1;
    end
  end else begin
    if(SNES_cycle_start & nmi_match_bits[0] & ~hook_disable) nmi_usage <= nmi_usage + 1;
    if(SNES_cycle_start & irq_match_bits[0] & ~hook_disable) irq_usage <= irq_usage + 1;
  end
end

// Temporary allow entry of snescmd area by the CPU, software must then unlock
// permanently
always @(posedge clk) begin
  if(SNES_cycle_start) begin
    if(nmi_addr_match | irq_addr_match) begin
      temp_unlock_delay <= 7'd72;
      temp_vector_unlock <= 1'b1;
    end else begin
      if (|temp_unlock_delay) temp_unlock_delay <= temp_unlock_delay - 1;
      if (temp_unlock_delay == 7'd0) begin
        temp_vector_unlock <= 1'b0;
      end
    end
  end
end

// Do not change vectors while they are being read
always @(posedge clk) begin
  if(SNES_cycle_start) begin
    if(nmi_addr_match | irq_addr_match) sync_delay <= 2'b10;
    else begin
      if (|sync_delay) sync_delay <= sync_delay - 1;
      if (sync_delay == 2'b00) begin
        auto_nmi_enable_sync <= auto_nmi_enable;
        auto_irq_enable_sync <= auto_irq_enable;
        hook_enable_sync <= hook_enable;
      end
    end
  end
end

// write/read inhibit bram area from SNES
always @(posedge clk) begin
  if(snescmd_wr_strobe) begin
    if(SNES_ADDR[8:0] == 9'h1f4 && SNES_DATA == 8'h48) unlock_token[0] <= 1'b1;
    else if(SNES_ADDR[8:0] == 9'h1f5 && SNES_DATA == 8'h75) unlock_token[1] <= 1'b1;
    else if(SNES_ADDR[8:0] == 9'h1f6 && SNES_DATA == 8'h72) unlock_token[2] <= 1'b1;
    else if(SNES_ADDR[8:0] == 9'h1f7 && SNES_DATA == 8'h7a) unlock_token[3] <= 1'b1;
    else if(SNES_ADDR[8:2] == 9'b1111101) unlock_token <= 4'b0000;
  end else if(SNES_reset_strobe) unlock_token <= 4'b0000;
end

// feature control
always @(posedge clk) begin
  if((snescmd_unlock & snescmd_wr_strobe & ~|SNES_ADDR[8:0] & (SNES_DATA == 8'h85))
     | (holdoff_enable & SNES_reset_strobe)) begin
    hook_enable_count <= 30'd860000000;
  end else if (|hook_enable_count) begin
    hook_enable_count <= hook_enable_count - 1;
  end
end

always @(posedge clk) begin
  if(snescmd_unlock & snescmd_wr_strobe) begin
    if(~|SNES_ADDR[8:0]) begin
      case(SNES_DATA)
        8'h82: cheat_enable <= 1;
        8'h83: cheat_enable <= 0;
        8'h84: {nmi_enable, irq_enable} <= 2'b00;
      endcase
    end else if(SNES_ADDR[8:0] == 9'h1fd) begin
      hook_disable <= SNES_DATA[0];
    end
  end else if(pgm_we) begin
    if(pgm_idx < 6) begin
      cheat_addr[pgm_idx] <= pgm_in[31:8];
      cheat_data[pgm_idx] <= pgm_in[7:0];
    end else if(pgm_idx == 6) begin // set rom patch enable
      cheat_enable_mask <= pgm_in[5:0];
    end else if(pgm_idx == 7) begin // set/reset global enable / hooks
    // pgm_in[7:4] are reset bit flags
    // pgm_in[3:0] are set bit flags
      {holdoff_enable, irq_enable, nmi_enable, cheat_enable} <= ({holdoff_enable, irq_enable, nmi_enable, cheat_enable} & ~pgm_in[7:4])
                                                                 | pgm_in[3:0];
    end
  end
end

endmodule

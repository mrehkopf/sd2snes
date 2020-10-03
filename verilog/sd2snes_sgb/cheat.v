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
`include "config.vh"

module cheat(
  input clk,
  input [7:0] SNES_PA,
  input [23:0] SNES_ADDR,
  input [7:0] SNES_DATA,
  input SNES_wr_strobe,
  input SNES_rd_strobe,
  input SNES_reset_strobe,
  input snescmd_enable,
  input nmicmd_enable,
  input return_vector_enable,
  input reset_vector_enable,
  input branch1_enable,
  input branch2_enable,
  
  input button_enable,
  input button_addr,
  input snescmd_rdy,
  output snescmd_we_cheat,
  output [8:0] snescmd_addr_cheat,
  output [7:0] snescmd_data_cheat,
  output button_ctx_valid,
  output button_ctx_mode,
  input  [11:0] DBG_ADDR,
  output [7:0] DBG_DATA_OUT,

  input pad_latch,
  input snes_ajr,
  input SNES_cycle_start,
  input [2:0] pgm_idx,
  input pgm_we,
  input [31:0] pgm_in,
  output [7:0] data_out,
  output cheat_hit,
  output snescmd_unlock  
);

wire snescmd_wr_strobe = snescmd_enable & SNES_wr_strobe;

reg cheat_enable = 0;
reg nmi_enable = 0;
reg irq_enable = 0;
reg holdoff_enable = 0; // temp disable hooks after reset
reg buttons_enable = 0;
reg wram_present = 0;

// SGB hooks rely on the use of the unmodified SGB2 SNES ROM to detect WRAM writes
// to store button data.  This has several benefits over the existing NMI hook code
// for SGB:
// 1) No NMI needs to be enabled and V/H IRQ doesn't need to be used.
// 2) No SNES code overhead for recording button state.
// 3) Less FPGA code.
//
// This hook is not perfect and relies on hardcoded WRAM addresses for snooping the data.  It's
// possible that these addresses match during an injected SNES ROM causing problems.  But much like the original
// hooks the fix is simple: disable them.  More address checks may be added to help avoid this (e.g. ROM addresses).

wire [1:0]  rst_match_bits = {SNES_ADDR == 24'h00FFFC, SNES_ADDR == 24'h00FFFD};

reg  [29:0] hook_enable_count = 0;
// support the reset hook for booting the SNES ROM
reg  [1:0]  reset_unlock_r = 2'b10;
wire        reset_unlock = |reset_unlock_r;
wire        rst_addr_match = |rst_match_bits;
wire        hook_enable = ~|hook_enable_count;
reg         snescmd_unlock_r = 0;

assign      data_out = rst_match_bits[1] ? 8'h6b : 8'h2a;
assign      cheat_hit = (reset_unlock & rst_addr_match);
assign      snescmd_unlock = snescmd_unlock_r;

// make patched reset vector visible for first fetch only
// (including masked read by Ultra16)
always @(posedge clk) begin
  if(SNES_reset_strobe) begin
    reset_unlock_r <= 2'b11;
  end else if(SNES_cycle_start) begin
    if(rst_addr_match & |reset_unlock_r) begin
      reset_unlock_r <= reset_unlock_r - 1;
    end
  end
end

// handle unlocks for reset
reg snescmd_unlock_disable_strobe = 1'b0;
reg [6:0] snescmd_unlock_disable_countdown = 0;
reg snescmd_unlock_disable = 0;

always @(posedge clk) begin
  if(SNES_reset_strobe) begin
    snescmd_unlock_r <= 0;
    snescmd_unlock_disable <= 0;
  end else begin
    if(SNES_rd_strobe) begin
      if(rst_match_bits[1] & |reset_unlock_r) begin
        snescmd_unlock_r <= 1;
      end
    end
    // give some time to exit snescmd memory and jump to original vector
    if(SNES_cycle_start) begin
      if(snescmd_unlock_disable) begin
        if(|snescmd_unlock_disable_countdown) begin
          snescmd_unlock_disable_countdown <= snescmd_unlock_disable_countdown - 1;
        end else if(snescmd_unlock_disable_countdown == 0) begin
          snescmd_unlock_r <= 0;
          snescmd_unlock_disable <= 0;
        end
      end
    end
    if(snescmd_unlock_disable_strobe) begin
      snescmd_unlock_disable_countdown <= 7'd72;
      snescmd_unlock_disable <= 1;
    end
  end
end

// CMD 0x85: disable hooks for 10 seconds
always @(posedge clk) begin
  if((snescmd_unlock & snescmd_wr_strobe & ~|SNES_ADDR[8:0] & (SNES_DATA == 8'h85))
     | (holdoff_enable & SNES_reset_strobe)) begin
    hook_enable_count <= 30'd840000000; // 10 seconds
  end else if (snescmd_we_cheat | button_ctx_valid) begin
    hook_enable_count <= 30'd42000000; // 0.5 seconds
  end else if (|hook_enable_count) begin
    hook_enable_count <= hook_enable_count - 1;
  end
end

// MCU writes and internal updates
// Only need to support IRQ/NMI (now hook enable) buttons, and holdoff
always @(posedge clk) begin
  if(SNES_reset_strobe) begin
    snescmd_unlock_disable_strobe <= 1'b0;
  end else begin
    snescmd_unlock_disable_strobe <= 1'b0;
    
    if(snescmd_unlock & snescmd_wr_strobe) begin
      if(~|SNES_ADDR[8:0]) begin
        case(SNES_DATA)
          8'h82: cheat_enable <= 1;
          8'h83: cheat_enable <= 0;
          8'h84: {nmi_enable, irq_enable} <= 2'b00;
        endcase
      end else if(SNES_ADDR[8:0] == 9'h1fd) begin
        snescmd_unlock_disable_strobe <= 1'b1;
      end
    end else if(pgm_we) begin
      if(pgm_idx == 7) begin // set/reset global enable / hooks
      // pgm_in[7:4] are reset bit flags
      // pgm_in[3:0] are set bit flags
        {wram_present, buttons_enable, holdoff_enable, irq_enable, nmi_enable, cheat_enable}
         <= ({wram_present, buttons_enable, holdoff_enable, irq_enable, nmi_enable, cheat_enable}
          & ~pgm_in[13:8])
          | pgm_in[5:0];
      end
    end
  end
end

// record buttons

reg         pad_valid_r = 0;
reg  [15:0] pad_data_r  = 0;
reg         cmd_valid_r;
reg  [15:0] cmd_data_r;

// map controller input to cmd output
// check button combinations
// L+R+Start+Select : $3030
// L+R+Select+X     : $2070
// L+R+Start+A      : $10b0 // unsupported
// L+R+Start+B      : $9030 // unsupported
// L+R+Start+Y      : $5030
// L+R+Start+X      : $1070
wire        button_reset_game  = (cmd_data_r == 16'h3030);
wire        button_reset_menu  = (cmd_data_r == 16'h2070);
wire        button_hook_dis    = (cmd_data_r == 16'h5030);
wire        button_hook_dis_10 = (cmd_data_r == 16'h1070);
wire        button_valid       = button_reset_game | button_reset_menu | button_hook_dis | button_hook_dis_10;

// allow any directional buttons and yba values.  anything involving select should press select first
wire        button_state_save  = ({2'b00,cmd_data_r[13:12],1'b0,cmd_data_r[6:4]} == 8'h05);
wire        button_state_load  = ({2'b00,cmd_data_r[13:12],1'b0,cmd_data_r[6:4]} == 8'h06);
wire        button_state       = button_state_save | button_state_load;

always @(posedge clk) begin
  pad_valid_r <= 0;
  if(SNES_wr_strobe & button_enable) begin
    if (~button_addr) pad_data_r[7:0] <= SNES_DATA; else pad_data_r[15:8] <= SNES_DATA;
    
    // enable the joypad state machine after lower order bytes are written second
    if (~button_addr) pad_valid_r <= 1;
  end
end

// generate SNESCMD operations to communicate back with the menu
always @(posedge clk) begin
  if (SNES_reset_strobe) begin
    cmd_valid_r <= 0;
  end
  else begin
    if (cmd_valid_r & (snescmd_we_cheat | ~button_valid)) begin
      cmd_valid_r <= 0;
    end
    // avoid writing when snescmd is unlocked to reduce races with snes communicating with MCU
    // it may not matter because the buttons aren't read until out of reset when we should never get into
    // the hook inside SNES Code
    else if (~snescmd_unlock_r & pad_valid_r & hook_enable & (nmi_enable | irq_enable) & buttons_enable) begin
      cmd_valid_r <= 1;
      cmd_data_r  <= pad_data_r;
    end
  end
end

assign snescmd_we_cheat   = cmd_valid_r & button_valid & snescmd_rdy;
assign snescmd_addr_cheat = 9'h000;
assign snescmd_data_cheat = ( button_reset_game  ? 8'h80 // reset to game
                            : button_reset_menu  ? 8'h81 // reset to menu
                            : button_hook_dis    ? 8'h84 // disable in-game hooks completely
                            : button_hook_dis_10 ? 8'h85 // disable in-game hooks for 10 seconds
                            :                      8'h00
                            );

// These pulse for a single clock.  The SGB CTX state machine decides whether to use or ignore them.
// override cheat bit to enable save states
assign button_ctx_valid = cheat_enable & cmd_valid_r & button_state;
assign button_ctx_mode  = button_state_load; // 0=save 1=load

reg  [7:0]  dbg_data_r;
assign DBG_DATA_OUT = dbg_data_r;

always @(posedge clk) begin
  casez(DBG_ADDR[3:0])
    4'h0:    dbg_data_r <= pad_valid_r;
    4'h1:    dbg_data_r <= cmd_valid_r;
    4'h2:    dbg_data_r <= pad_data_r[7:0];
    4'h3:    dbg_data_r <= pad_data_r[15:8];
    4'h4:    dbg_data_r <= cmd_data_r[7:0];
    4'h5:    dbg_data_r <= cmd_data_r[15:8];
    4'h6:    dbg_data_r <= snescmd_unlock_r;
    4'h7:    dbg_data_r <= hook_enable;
    4'h8:    dbg_data_r <= nmi_enable;
    4'h9:    dbg_data_r <= irq_enable;
    4'hA:    dbg_data_r <= buttons_enable;
    4'hB:    dbg_data_r <= cheat_enable;
    4'hC:    dbg_data_r <= snescmd_we_cheat;
    4'hD:    dbg_data_r <= snescmd_data_cheat;
    4'hE:    dbg_data_r <= button_state_save;
    4'hF:    dbg_data_r <= button_state_load;

    default:  dbg_data_r <= 0;
  endcase
end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: ikari
//
// Create Date:    17:09:03 01/16/2011
// Design Name:
// Module Name:    upd77c25
// Project Name: sd2snes
// Target Devices: xc3s400
// Tool versions: ISE 13.1
// Description: NEC uPD77C25 core (for SNES DSP1-4)
//
// Dependencies:
//
// Revision:
// Revision 0.2 - core fully operational, firmware download
//
//////////////////////////////////////////////////////////////////////////////////
`include "config.vh"

module upd77c25(
  input [7:0] DI,
  output [7:0] DO,
  input A0,
  input enable,
  input reg_oe_falling,
  input reg_oe_rising,
  input reg_we_rising,
  input RST,
  input CLK,

  input PGM_WR,
  input [23:0] PGM_DI,
  input [10:0] PGM_WR_ADDR,

  input DAT_WR,
  input [15:0] DAT_DI,
  input [10:0] DAT_WR_ADDR,

  input DP_enable,
  input [10:0] DP_ADDR,

  input [15:0] dsp_feat,

  // savestate scan port (Phase 1: read-only)
  input ss_halt,        // MCU debug halt request
  input ss_window_en,   // 1 = DSP1-4 (sca handler active); 0 = ST0010 (plain RAM)
  output ss_halted,     // 1 = freeze in effect, safe to snapshot/restore

  // debug
  output [15:0] updDR,
  output [15:0] updSR,
  output [10:0] updPC,
  output [15:0] updA,
  output [15:0] updB,
  output [5:0] updFL_A,
  output [5:0] updFL_B
);

parameter STATE_FETCH = 8'b00000001;
parameter STATE_LOAD  = 8'b00000010;
parameter STATE_ALU1  = 8'b00000100;
parameter STATE_ALU2  = 8'b00001000;
parameter STATE_STORE = 8'b00010000;
parameter STATE_NEXT  = 8'b00100000;
parameter STATE_IDLE1 = 8'b01000000;
parameter STATE_IDLE2 = 8'b10000000;

parameter I_OP = 2'b00;
parameter I_RT = 2'b01;
parameter I_JP = 2'b10;
parameter I_LD = 2'b11;

parameter SR_RQM = 15;
parameter SR_DRS = 12;
parameter SR_DRC = 10;

reg [1:0] flags_ov0;
reg [1:0] flags_ov1;
reg [1:0] flags_z;
reg [1:0] flags_c;
reg [1:0] flags_s0;
reg [1:0] flags_s1;

reg [10:0] pc;        // program counter

reg [7:0] insn_state; // execute state

reg [1:0] regs_dpb;
reg [3:0] regs_dph;
reg [3:0] regs_dpl;

reg [10:0] regs_rp;

wire [15:0] ram_dina;
reg [15:0] ram_dina_r;
assign ram_dina = ram_dina_r;

wire [23:0] pgm_doutb;

`ifdef MK2
`ifndef DEBUG
upd77c25_pgmrom pgmrom (
  .clka(CLK), // input clka
  .wea(PGM_WR), // input [0 : 0] wea
  .addra(PGM_WR_ADDR), // input [10 : 0] addra
  .dina(PGM_DI), // input [23 : 0] dina
  .clkb(CLK), // input clkb
  .addrb(pc), // input [10 : 0] addrb
  .doutb(pgm_doutb) // output [23 : 0] doutb
);
`endif
`endif
`ifdef MK3
upd77c25_pgmrom pgmrom (
  .clock(CLK), // input clka
  .wren(PGM_WR), // input [0 : 0] wea
  .wraddress(PGM_WR_ADDR), // input [10 : 0] addra
  .data(PGM_DI), // input [23 : 0] dina
  .rdaddress(pc), // input [10 : 0] addrb
  .q(pgm_doutb) // output [23 : 0] doutb
);
`endif

wire [23:0] opcode_w = pgm_doutb;
reg [1:0] op;
reg [1:0] op_pselect;
reg [3:0] op_alu;
reg op_asl;
reg [1:0] op_dpl;
reg [3:0] op_dphm;
reg op_rpdcr;
reg [3:0] op_src;
reg [3:0] op_dst;

wire [15:0] dat_doutb;

`ifdef MK2
`ifndef DEBUG
upd77c25_datrom datrom (
  .clka(CLK), // input clka
  .wea(DAT_WR), // input [0 : 0] wea
  .addra(DAT_WR_ADDR), // input [10 : 0] addra
  .dina(DAT_DI), // input [15 : 0] dina
  .clkb(CLK), // input clkb
  .addrb(regs_rp), // input [10 : 0] addrb
  .doutb(dat_doutb) // output [15 : 0] doutb
);
`endif
`endif
`ifdef MK3
upd77c25_datrom datrom (
  .clock(CLK), // input clka
  .wren(DAT_WR), // input [0 : 0] wea
  .wraddress(DAT_WR_ADDR), // input [10 : 0] addra
  .data(DAT_DI), // input [15 : 0] dina
  .rdaddress(regs_rp), // input [10 : 0] addrb
  .q(dat_doutb) // output [15 : 0] doutb
);
`endif

wire [15:0] ram_douta;
wire [9:0] ram_addra;
reg [7:0] DP_DOr;
wire [7:0] DP_DO;
wire [7:0] UPD_DO;

// suppress RAM write when the access targets the scan register-file / control
// Declared before first use: XST rejects use-before-declaration, Quartus does not.
wire ss_ctrl;
wire ss_regwin;
reg  ss_frozen; initial ss_frozen = 1'b0;
wire ram_web = reg_we_rising & DP_enable & ~ss_regwin & ~ss_ctrl;

`ifdef MK2
`ifndef DEBUG
upd77c25_datram datram (
  .clka(CLK), // input clka
  .wea(ram_wea), // input [0 : 0] wea
  .addra(ram_addra), // input [9 : 0] addra
  .dina(ram_dina), // input [15 : 0] dina
  .douta(ram_douta), // output [15 : 0] douta
  .clkb(CLK), // input clkb
  .web(ram_web), // input [0 : 0] web
  .addrb(DP_ADDR), // input [10 : 0] addrb
  .dinb(DI), // input [7 : 0] dinb
  .doutb(DP_DO) // output [7 : 0] doutb
);
`endif
`endif
`ifdef MK3
upd77c25_datram datram (
  .clock(CLK), // input clka
  .wren_a(ram_wea), // input [0 : 0] wea
  .address_a(ram_addra), // input [9 : 0] addra
  .data_a(ram_dina), // input [15 : 0] dina
  .q_a(ram_douta), // output [15 : 0] douta
  .wren_b(ram_web), // input [0 : 0] web
  .address_b(DP_ADDR), // input [10 : 0] addrb
  .data_b(DI), // input [7 : 0] dinb
  .q_b(DP_DO) // output [7 : 0] doutb
);
`endif
// Gate the core's port-A RAM write while halted so it cannot race the port-B
// restore; a pending write replays on unhalt, since insn_state is preserved.
assign ram_wea = ((op != I_JP) && op_dst == 4'b1111 && insn_state == STATE_NEXT) & ~ss_frozen;
assign ram_addra = {regs_dpb,
                    regs_dph | ((|(insn_state & (STATE_ALU1 | STATE_ALU2)) && op_dst == 4'b1100)
                                ? 4'b0100
                                : 4'b0000),
                    regs_dpl};

reg signed [15:0] regs_k;
reg signed [15:0] regs_l;
reg [15:0] regs_trb;
reg [15:0] regs_tr;
reg [15:0] regs_dr;
reg [15:0] regs_sr;
reg [3:0] regs_sp;

reg cond_true;

reg [8:0] jp_brch;
reg [10:0] jp_na;

reg [15:0] ld_id;
reg [3:0] ld_dst;

wire [31:0] mul_result = regs_k * regs_l;
reg [15:0] regs_m;
reg [15:0] regs_n;

reg [15:0] alu_p;
reg [15:0] alu_q;
reg [15:0] alu_r;

reg [1:0] alu_store;

reg [10:0] stack [15:0];

reg [15:0] idb;

reg [15:0] regs_ab [1:0];

reg [3:0] cpu_wait = 0;

assign updDR = regs_dr;
assign updSR = regs_sr;
assign updPC = pc;
assign updA = regs_ab[0];
assign updB = regs_ab[1];
assign updFL_A = {flags_s1[0],flags_s0[0],flags_c[0],flags_z[0],flags_ov1[0],flags_ov0[0]};
assign updFL_B = {flags_s1[1],flags_s0[1],flags_c[1],flags_z[1],flags_ov1[1],flags_ov0[1]};

// ---- savestate scan port -------------------------------------------------
// While halted every always block below holds.  The architectural and pipeline
// state is exposed as a flat byte window at DP_ADDR $600-$6FF (a port-B gap DSP1
// never touches); $7FF is the halt control byte.  Offset map below.
// ss_window_en separates DSP1-4 from the ST0010, which shares this core and uses
// the full 2 KB RAM window for the game; there it is 0 and the window stays RAM.
// Two halt sources: ss_halt (MCU) and ss_halt_snes (handler, via $7FF).  The
// latter lives in its own block so it stays writable while everything else holds.
reg ss_halt_snes;
initial ss_halt_snes = 1'b0;
wire ss_halt_eff = ss_halt | ss_halt_snes;
assign ss_ctrl = ss_window_en & DP_enable & (DP_ADDR == 11'h7ff);
always @(posedge CLK) begin
  if(~RST) ss_halt_snes <= 1'b0;
  else if(ss_ctrl & reg_we_rising) ss_halt_snes <= DI[0];
end

// Boundary-gated freeze: on a halt request let the DSP finish the current
// transaction and stop at an idle instruction boundary, so the cut stays
// consistent with the SNES CPU and the handshake re-syncs on resume.  A counter
// forces the freeze after 256 cycles, so it can never hang.
reg [7:0] ss_wait; initial ss_wait = 8'h00;
wire ss_boundary = (insn_state == STATE_FETCH) & regs_sr[SR_RQM];
always @(posedge CLK) begin
  if(~RST | ~ss_halt_eff) begin
    ss_frozen <= 1'b0;
    ss_wait   <= 8'h00;
  end else if(~ss_frozen) begin
    ss_wait <= ss_wait + 1'b1;
    if(ss_boundary | (&ss_wait)) ss_frozen <= 1'b1;
  end
end
assign ss_halted = ss_frozen;

// $600-$6FF register-file window (live only once actually frozen)
assign ss_regwin = ss_window_en & DP_enable & ss_frozen & (DP_ADDR[10:8] == 3'b110);

// Window writes are pipelined one cycle through local flops.  DP_enable comes from
// address.v, which ANDs the hook unlock (a flop in cheat.v, far away on the die)
// with the address decode; feeding that straight into the register-file write
// demux builds a 7-level path that misses timing on the Mk.II.  Latching the
// request first makes those writes flop-to-flop out of local registers, and the
// extra cycle is invisible: the write strobe comes from a SNES bus cycle that
// lasts tens of clocks.
reg       ss_wr_r;   initial ss_wr_r  = 1'b0;
reg [7:0] ss_off_r;  initial ss_off_r = 8'h00;
reg [7:0] ss_di_r;   initial ss_di_r  = 8'h00;
always @(posedge CLK) begin
  ss_wr_r  <= ss_regwin & reg_we_rising;
  ss_off_r <= DP_ADDR[7:0];
  ss_di_r  <= DI;
end
wire [3:0] ss_stk_idx_r = (ss_off_r - 8'h34) >> 1;
wire [3:0] ss_stk_idx = (DP_ADDR[7:0] - 8'h34) >> 1;
reg [7:0] ss_reg_do;
// Read the arrays through scalar wires so the combinational readback mux below reads
// scalars, not 2D arrays -- XST (mk2) rejects a memory array in an @(*) sensitivity list
// (Xst:902 "Unexpected ... event"); Quartus (mk3) tolerates it.  Behavior-neutral.
wire [15:0] ss_rab0 = regs_ab[0];
wire [15:0] ss_rab1 = regs_ab[1];
wire [10:0] ss_stk  = stack[ss_stk_idx];
always @(*) begin
  if (DP_ADDR[7:0] >= 8'h34 && DP_ADDR[7:0] <= 8'h53)
    ss_reg_do = DP_ADDR[0] ? {5'b0, ss_stk[10:8]}
                           : ss_stk[7:0];
  else case (DP_ADDR[7:0])
    8'h00: ss_reg_do = pc[7:0];
    8'h01: ss_reg_do = {5'b0, pc[10:8]};
    8'h02: ss_reg_do = ss_rab0[7:0];
    8'h03: ss_reg_do = ss_rab0[15:8];
    8'h04: ss_reg_do = ss_rab1[7:0];
    8'h05: ss_reg_do = ss_rab1[15:8];
    8'h06: ss_reg_do = regs_tr[7:0];
    8'h07: ss_reg_do = regs_tr[15:8];
    8'h08: ss_reg_do = regs_trb[7:0];
    8'h09: ss_reg_do = regs_trb[15:8];
    8'h0a: ss_reg_do = regs_dr[7:0];
    8'h0b: ss_reg_do = regs_dr[15:8];
    8'h0c: ss_reg_do = regs_sr[7:0];
    8'h0d: ss_reg_do = regs_sr[15:8];
    8'h0e: ss_reg_do = regs_rp[7:0];
    8'h0f: ss_reg_do = {5'b0, regs_rp[10:8]};
    8'h10: ss_reg_do = regs_k[7:0];
    8'h11: ss_reg_do = regs_k[15:8];
    8'h12: ss_reg_do = regs_l[7:0];
    8'h13: ss_reg_do = regs_l[15:8];
    8'h14: ss_reg_do = regs_m[7:0];
    8'h15: ss_reg_do = regs_m[15:8];
    8'h16: ss_reg_do = regs_n[7:0];
    8'h17: ss_reg_do = regs_n[15:8];
    8'h18: ss_reg_do = {regs_dph, regs_dpl};
    8'h19: ss_reg_do = {6'b0, regs_dpb};
    8'h1a: ss_reg_do = {4'b0, regs_sp};
    8'h1b: ss_reg_do = insn_state;
    8'h1c: ss_reg_do = {2'b0, updFL_A};
    8'h1d: ss_reg_do = {2'b0, updFL_B};
    8'h1e: ss_reg_do = idb[7:0];
    8'h1f: ss_reg_do = idb[15:8];
    8'h20: ss_reg_do = alu_p[7:0];
    8'h21: ss_reg_do = alu_p[15:8];
    8'h22: ss_reg_do = alu_q[7:0];
    8'h23: ss_reg_do = alu_q[15:8];
    8'h24: ss_reg_do = alu_r[7:0];
    8'h25: ss_reg_do = alu_r[15:8];
    8'h26: ss_reg_do = ram_dina_r[7:0];
    8'h27: ss_reg_do = ram_dina_r[15:8];
    8'h28: ss_reg_do = ld_id[7:0];
    8'h29: ss_reg_do = ld_id[15:8];
    8'h2a: ss_reg_do = {op, op_pselect, op_alu};
    8'h2b: ss_reg_do = {op_asl, op_dpl, op_dphm, op_rpdcr};
    8'h2c: ss_reg_do = {op_src, op_dst};
    8'h2d: ss_reg_do = {ld_dst, 1'b0, alu_store, cond_true};
    8'h2e: ss_reg_do = jp_brch[7:0];
    8'h2f: ss_reg_do = {7'b0, jp_brch[8]};
    8'h30: ss_reg_do = jp_na[7:0];
    8'h31: ss_reg_do = {5'b0, jp_na[10:8]};
    8'h32: ss_reg_do = {4'b0, cpu_wait};
    8'h33: ss_reg_do = 8'hd1; // magic, sanity-check on restore
    default: ss_reg_do = 8'h00;
  endcase
end
// --------------------------------------------------------------------------

initial begin
  alu_store = 2'b11;
  insn_state = STATE_IDLE1;
  regs_sp = 4'b0000;
  pc = 11'b0;
  regs_sr = 16'b0;
  regs_rp = 16'h0000;
  regs_dpb = 2'b0;
  regs_dph = 4'b0;
  regs_dpl = 4'b0;
  regs_k = 16'b0;
  regs_l = 16'b0;
  regs_ab[0] = 16'b0;
  regs_ab[1] = 16'b0;
  flags_ov0 = 2'b0;
  flags_ov1 = 2'b0;
  flags_z = 2'b0;
  flags_c = 2'b0;
  flags_s0 = 2'b0;
  flags_s1 = 2'b0;
  regs_tr = 16'b0;
  regs_trb = 16'b0;
  regs_dr = 16'b0;
end

always @(posedge CLK) begin
  if(RST & ~ss_frozen) begin
    if(enable & reg_we_rising & (A0 == 1'b0)) begin
      if(!regs_sr[SR_DRC]) begin
        if(regs_sr[SR_DRS] == 1'b1) begin
          regs_sr[SR_RQM] <= 1'b0;
        end
      end else begin
        regs_sr[SR_RQM] <= 1'b0;
      end
    end
    else if(enable & reg_oe_rising & (A0 == 1'b0)) begin
      if(!regs_sr[SR_DRC]) begin
        if(regs_sr[SR_DRS] == 1'b1) begin
          regs_sr[SR_RQM] <= 1'b0;
        end
      end else begin
        regs_sr[SR_RQM] <= 1'b0;
      end
    end else if((op_src == 4'b1000 && op[1] == 1'b0 && insn_state == STATE_STORE)
             || (op_dst == 4'b0110 && op != 2'b10 && insn_state == STATE_STORE)) begin
      regs_sr[SR_RQM] <= 1'b1;
    end
  end else if(RST & ss_frozen) begin
    if(ss_wr_r & (ss_off_r == 8'h0d))
      regs_sr[SR_RQM] <= ss_di_r[7]; // restore bit 15 (offset $0d high byte)
  end else begin
    regs_sr[SR_RQM] <= 1'b0;
  end
end

always @(posedge CLK) begin
  if(RST & ~ss_frozen) begin
    if(enable & reg_we_rising & (A0 == 1'b0)) begin
      if(!regs_sr[SR_DRC]) begin
        if(regs_sr[SR_DRS] == 1'b0) begin
          regs_sr[SR_DRS] <= 1'b1;
        end else begin
          regs_sr[SR_DRS] <= 1'b0;
        end
      end
    end else if(enable & reg_oe_rising) begin
      case(A0)
        1'b0: begin
          if(!regs_sr[SR_DRC]) begin
            if(regs_sr[SR_DRS] == 1'b0) begin
              regs_sr[SR_DRS] <= 1'b1;
            end else begin
              regs_sr[SR_DRS] <= 1'b0;
            end
          end
        end
      endcase
    end
  end else if(RST & ss_frozen) begin
    if(ss_wr_r & (ss_off_r == 8'h0d))
      regs_sr[SR_DRS] <= ss_di_r[4]; // restore bit 12 (offset $0d high byte)
  end else begin
    regs_sr[SR_DRS] <= 1'b0;
  end
end

always @(posedge CLK) begin
  if(RST & ~ss_frozen) begin
    if(enable & reg_we_rising & (A0 == 1'b0)) begin
      if(!regs_sr[SR_DRC]) begin
        if(regs_sr[SR_DRS] == 1'b0) begin
          regs_dr[7:0] <= DI;
        end else begin
          regs_dr[15:8] <= DI;
        end
      end else begin
        regs_dr[7:0] <= DI;
      end
    end else if(ld_dst == 4'b0110 && insn_state == STATE_STORE) begin
      if (op == I_OP || op == I_RT) regs_dr <= idb;
      else if (op == I_LD) regs_dr <= ld_id;
    end
  end else if(RST & ss_frozen) begin
    if(ss_wr_r) begin
      if(ss_off_r == 8'h0a) regs_dr[7:0]  <= ss_di_r; // restore low byte
      if(ss_off_r == 8'h0b) regs_dr[15:8] <= ss_di_r; // restore high byte
    end
  end else begin
    regs_dr <= 16'h0000;
  end
end

assign UPD_DO = (A0 ? regs_sr[15:8] : (regs_sr[SR_DRC] ? regs_dr[7:0] : (regs_sr[SR_DRS] ? regs_dr[15:8] : regs_dr[7:0])));
assign DO = ss_ctrl ? {7'b0, ss_halted}
          : ss_regwin ? ss_reg_do
          : (DP_enable ? DP_DO : UPD_DO);

always @(posedge CLK) begin
  if(RST & ~ss_frozen) begin
    case(insn_state)
      STATE_FETCH: begin
        insn_state <= STATE_LOAD;
        if(op == I_OP || op == I_RT) begin
          if(|op_alu) begin
            flags_z[op_asl] <= (alu_r == 0);
            flags_s0[op_asl] <= alu_r[15];
          end
          case(op_alu)
            4'b0001, 4'b0010, 4'b0011, 4'b1010, 4'b1101, 4'b1110, 4'b1111: begin
              flags_c[op_asl] <= 0;
              flags_ov0[op_asl] <= 0;
              flags_ov1[op_asl] <= 0;
            end
            4'b0100, 4'b0101, 4'b0110, 4'b0111, 4'b1000, 4'b1001: begin
              if(op_alu[0]) begin
                flags_c[op_asl] <= (alu_r < alu_q);
                flags_ov0[op_asl] <= (alu_q[15] ^ alu_r[15]) & ~(alu_q[15] ^ alu_p[15]);
                if((alu_q[15] ^ alu_r[15]) & ~(alu_q[15] ^ alu_p[15])) begin
                  flags_s1[op_asl] <= flags_ov1[op_asl] ^ ~alu_r[15];
                  flags_ov1[op_asl] <= ~flags_ov1[op_asl];
                end
              end else begin
                flags_c[op_asl] <= (alu_r > alu_q);
                flags_ov0[op_asl] <= (alu_q[15] ^ alu_r[15]) & (alu_q[15] ^ alu_p[15]);
                if((alu_q[15] ^ alu_r[15]) & (alu_q[15] ^ alu_p[15])) begin
                  flags_s1[op_asl] <= flags_ov1[op_asl] ^ ~alu_r[15];
                  flags_ov1[op_asl] <= ~flags_ov1[op_asl];
                end
              end
            end
            4'b1011: begin
              flags_c[op_asl] <= alu_q[0];
              flags_ov0[op_asl] <= 0;
              flags_ov1[op_asl] <= 0;
            end
            4'b1100: begin
              flags_c[op_asl] <= alu_q[15];
              flags_ov0[op_asl] <= 0;
              flags_ov1[op_asl] <= 0;
            end
          endcase
        end

        op <= opcode_w[23:22];
        op_pselect <= opcode_w[21:20];
        op_alu <= opcode_w[19:16];
        op_asl <= opcode_w[15];
        op_dpl <= opcode_w[14:13];
        op_dphm <= opcode_w[12:9];
        op_rpdcr <= opcode_w[8];
        op_src <= opcode_w[7:4];
        op_dst <= opcode_w[3:0];
        jp_brch <= opcode_w[21:13];
        jp_na <= opcode_w[12:2];

        ld_id <= opcode_w[21:6];
        ld_dst <= opcode_w[3:0];

        regs_m <= {mul_result[31], mul_result[29:15]};
        regs_n <= {mul_result[14:0], 1'b0};
      end
      STATE_LOAD: begin
        insn_state <= STATE_ALU1;
        case(op)
          I_OP, I_RT: begin
            case(op_src)
              4'b0000: idb <= regs_trb;
              4'b0001: idb <= regs_ab[0];
              4'b0010: idb <= regs_ab[1];
              4'b0011: idb <= regs_tr;
              4'b0100: idb <= {regs_dpb,regs_dph,regs_dpl};
              4'b0101: idb <= regs_rp;
              4'b0110: idb <= dat_doutb; // Address: [regs_rp]
              4'b0111: idb <= flags_s1[0] ? 16'h7fff : 16'h8000;
              4'b1000: idb <= regs_dr;
              4'b1001: idb <= regs_dr;
              4'b1010: idb <= regs_sr;
              4'b1101: idb <= regs_k;
              4'b1110: idb <= regs_l;
              4'b1111: idb <= ram_douta; // Address: [regs_dp]
            endcase
          end
        endcase
      end
      STATE_ALU1: begin
        insn_state <= STATE_ALU2;
        case(op)
          I_OP, I_RT: begin
            alu_q <= regs_ab[op_asl];
            if(op_alu[3:1] == 3'b100) begin
              alu_p <= 16'h0001;
            end else begin
              case(op_pselect)
                2'b00:
                  alu_p <= ram_douta;
                2'b01:
                  alu_p <= idb;
                2'b10:
                  alu_p <= regs_m;
                2'b11:
                  alu_p <= regs_n;
              endcase
            end
          end
          I_JP: begin
            case(jp_brch)
              9'b100_000_000: cond_true <= 1;
              9'b101_000_000: cond_true <= 1;
              9'b010_000_000: cond_true <= (flags_c[0] == 0);
              9'b010_000_010: cond_true <= (flags_c[0] == 1);
              9'b010_000_100: cond_true <= (flags_c[1] == 0);
              9'b010_000_110: cond_true <= (flags_c[1] == 1);
              9'b010_001_000: cond_true <= (flags_z[0] == 0);
              9'b010_001_010: cond_true <= (flags_z[0] == 1);
              9'b010_001_100: cond_true <= (flags_z[1] == 0);
              9'b010_001_110: cond_true <= (flags_z[1] == 1);
              9'b010_010_000: cond_true <= (flags_ov0[0] == 0);
              9'b010_010_010: cond_true <= (flags_ov0[0] == 1);
              9'b010_010_100: cond_true <= (flags_ov0[1] == 0);
              9'b010_010_110: cond_true <= (flags_ov0[1] == 1);
              9'b010_011_000: cond_true <= (flags_ov1[0] == 0);
              9'b010_011_010: cond_true <= (flags_ov1[0] == 1);
              9'b010_011_100: cond_true <= (flags_ov1[1] == 0);
              9'b010_011_110: cond_true <= (flags_ov1[1] == 1);
              9'b010_100_000: cond_true <= (flags_s0[0] == 0);
              9'b010_100_010: cond_true <= (flags_s0[0] == 1);
              9'b010_100_100: cond_true <= (flags_s0[1] == 0);
              9'b010_100_110: cond_true <= (flags_s0[1] == 1);
              9'b010_101_000: cond_true <= (flags_s1[0] == 0);
              9'b010_101_010: cond_true <= (flags_s1[0] == 1);
              9'b010_101_100: cond_true <= (flags_s1[1] == 0);
              9'b010_101_110: cond_true <= (flags_s1[1] == 1);
              9'b010_110_000: cond_true <= (regs_dpl == 0);
              9'b010_110_001: cond_true <= (regs_dpl != 0);
              9'b010_110_010: cond_true <= (regs_dpl == 4'b1111);
              9'b010_110_011: cond_true <= (regs_dpl != 4'b1111);
              9'b010_111_100: cond_true <= (regs_sr[SR_RQM] == 0);
              9'b010_111_110: cond_true <= (regs_sr[SR_RQM] == 1);
              default: cond_true <= 0;
            endcase
          end
        endcase
      end
      STATE_ALU2: begin
        insn_state <= STATE_STORE;
      end
      STATE_STORE: begin
        insn_state <= STATE_NEXT;
        if(op[1] == 1'b0) begin
          case(op_alu)
            4'b0001: alu_r <= alu_q | alu_p;
            4'b0010: alu_r <= alu_q & alu_p;
            4'b0011: alu_r <= alu_q ^ alu_p;
            4'b0100: alu_r <= alu_q - alu_p;
            4'b0101: alu_r <= alu_q + alu_p;
            4'b0110: alu_r <= alu_q - alu_p - flags_c[~op_asl];
            4'b0111: alu_r <= alu_q + alu_p + flags_c[~op_asl];
            4'b1000: alu_r <= alu_q - alu_p;
            4'b1001: alu_r <= alu_q + alu_p;
            4'b1010: alu_r <= ~alu_q;
            4'b1011: alu_r <= {alu_q[15], alu_q[15:1]};
            4'b1100: alu_r <= {alu_q[14:0], flags_c[~op_asl]};
            4'b1101: alu_r <= {alu_q[13:0], 2'b11};
            4'b1110: alu_r <= {alu_q[11:0], 4'b1111};
            4'b1111: alu_r <= {alu_q[7:0], alu_q[15:8]};
          endcase
        end
        case(op)
          I_OP, I_RT: begin
            case(op_dst)
              4'b0001: begin
                regs_ab[0] <= idb;
                alu_store <= 2'b10;
              end
              4'b0010: begin
                regs_ab[1] <= idb;
                alu_store <= 2'b01;
              end
              4'b0011: regs_tr <= idb;
              4'b0100: {regs_dpb,regs_dph,regs_dpl} <= idb[9:0];
              4'b0101: regs_rp <= idb;
//              4'b0110: regs_dr <= idb;
              4'b0111: begin
                regs_sr[14] <= idb[14];
                regs_sr[13] <= idb[13];
                regs_sr[11] <= idb[11];
                regs_sr[SR_DRC] <= idb[10];
                regs_sr[9] <= idb[9];
                regs_sr[8] <= idb[8];
                regs_sr[7] <= idb[7];
                regs_sr[1] <= idb[1];
                regs_sr[0] <= idb[0];
              end
              4'b1010: regs_k <= idb;
              4'b1011: begin
                regs_k <= idb;
                regs_l <= dat_doutb;
              end
              4'b1100: begin
                regs_k <= ram_douta;
                regs_l <= idb;
              end
              4'b1101: regs_l <= idb;
              4'b1110: regs_trb <= idb;
              4'b1111: ram_dina_r <= idb;
            endcase
          end
          I_LD: begin
            case(ld_dst)
              4'b0001: regs_ab[0] <= ld_id;
              4'b0010: regs_ab[1] <= ld_id;
              4'b0011: regs_tr <= ld_id;
              4'b0100: {regs_dpb,regs_dph,regs_dpl} <= ld_id[9:0];
              4'b0101: regs_rp <= ld_id;
//              4'b0110: regs_dr <= ld_id;
              4'b0111: begin
                regs_sr[14] <= ld_id[14];
                regs_sr[13] <= ld_id[13];
                regs_sr[11] <= ld_id[11];
                regs_sr[SR_DRC] <= ld_id[10];
                regs_sr[9] <= ld_id[9];
                regs_sr[8] <= ld_id[8];
                regs_sr[7] <= ld_id[7];
                regs_sr[1] <= ld_id[1];
                regs_sr[0] <= ld_id[0];
              end
              4'b1010: regs_k <= ld_id;
              4'b1011: begin
                regs_k <= ld_id;
                regs_l <= dat_doutb;
              end
              4'b1100: begin
                regs_k <= ram_douta;
                regs_l <= ld_id;
              end
              4'b1101: regs_l <= ld_id;
              4'b1110: regs_trb <= ld_id;
              4'b1111: ram_dina_r <= ld_id;
            endcase
          end
        endcase
        case(op)
          I_OP, I_RT: begin
            if(op_rpdcr) regs_rp <= regs_rp - 1;
            if(op == I_OP) pc <= pc + 1;
            else begin
              pc <= stack[regs_sp-1];
              regs_sp <= regs_sp - 1;
            end
          end
          I_JP: begin
            if(cond_true) begin
              pc <= jp_na;
              if(jp_brch[8:6] == 3'b101) begin
                stack[regs_sp] <= pc + 1;
                regs_sp <= regs_sp + 1;
              end
            end else pc <= pc + 1;
          end
          I_LD: begin
            pc <= pc + 1;
          end
        endcase
        cpu_wait <= dsp_feat[3:0];
      end

      STATE_NEXT: begin
        insn_state <= STATE_NEXT;
        if(~|cpu_wait) insn_state <= STATE_IDLE1;
        cpu_wait <= cpu_wait - 1;
      end

      STATE_IDLE1: begin
        insn_state <= STATE_FETCH;
        case(op)
          I_OP, I_RT: begin
            case(op_dpl)
              2'b01: regs_dpl <= regs_dpl + 1;
              2'b10: regs_dpl <= regs_dpl - 1;
              2'b11: regs_dpl <= 4'b0000;
            endcase
            regs_dph <= regs_dph ^ op_dphm;
            if(|op_alu && alu_store[op_asl]) regs_ab[op_asl] <= alu_r;
            alu_store <= 2'b11;
          end
        endcase
      end
    endcase
  end else if(RST & ss_frozen) begin
    // savestate RESTORE (Phase 2): load FSM-owned state from the scan window.
    // regs_dr and regs_sr bits 15/12 are restored in their own blocks below;
    // everything else is here. Mirrors the read mux offset map exactly.
    if(ss_wr_r) begin
      if(ss_off_r >= 8'h34 && ss_off_r <= 8'h53) begin
        if(ss_off_r[0]) stack[ss_stk_idx_r][10:8] <= ss_di_r[2:0];
        else            stack[ss_stk_idx_r][7:0]  <= ss_di_r;
      end else case(ss_off_r)
        8'h00: pc[7:0]          <= ss_di_r;
        8'h01: pc[10:8]         <= ss_di_r[2:0];
        8'h02: regs_ab[0][7:0]  <= ss_di_r;
        8'h03: regs_ab[0][15:8] <= ss_di_r;
        8'h04: regs_ab[1][7:0]  <= ss_di_r;
        8'h05: regs_ab[1][15:8] <= ss_di_r;
        8'h06: regs_tr[7:0]     <= ss_di_r;
        8'h07: regs_tr[15:8]    <= ss_di_r;
        8'h08: regs_trb[7:0]    <= ss_di_r;
        8'h09: regs_trb[15:8]   <= ss_di_r;
        // $0a/$0b regs_dr restored in its own block
        8'h0c: begin regs_sr[7] <= ss_di_r[7]; regs_sr[1] <= ss_di_r[1]; regs_sr[0] <= ss_di_r[0]; end
        8'h0d: begin regs_sr[14] <= ss_di_r[6]; regs_sr[13] <= ss_di_r[5]; regs_sr[11] <= ss_di_r[3];
                     regs_sr[SR_DRC] <= ss_di_r[2]; regs_sr[9] <= ss_di_r[1]; regs_sr[8] <= ss_di_r[0]; end
        8'h0e: regs_rp[7:0]     <= ss_di_r;
        8'h0f: regs_rp[10:8]    <= ss_di_r[2:0];
        8'h10: regs_k[7:0]      <= ss_di_r;
        8'h11: regs_k[15:8]     <= ss_di_r;
        8'h12: regs_l[7:0]      <= ss_di_r;
        8'h13: regs_l[15:8]     <= ss_di_r;
        8'h14: regs_m[7:0]      <= ss_di_r;
        8'h15: regs_m[15:8]     <= ss_di_r;
        8'h16: regs_n[7:0]      <= ss_di_r;
        8'h17: regs_n[15:8]     <= ss_di_r;
        8'h18: begin regs_dph <= ss_di_r[7:4]; regs_dpl <= ss_di_r[3:0]; end
        8'h19: regs_dpb <= ss_di_r[1:0];
        8'h1a: regs_sp  <= ss_di_r[3:0];
        8'h1b: insn_state <= ss_di_r;
        8'h1c: begin flags_s1[0] <= ss_di_r[5]; flags_s0[0] <= ss_di_r[4]; flags_c[0] <= ss_di_r[3];
                     flags_z[0] <= ss_di_r[2]; flags_ov1[0] <= ss_di_r[1]; flags_ov0[0] <= ss_di_r[0]; end
        8'h1d: begin flags_s1[1] <= ss_di_r[5]; flags_s0[1] <= ss_di_r[4]; flags_c[1] <= ss_di_r[3];
                     flags_z[1] <= ss_di_r[2]; flags_ov1[1] <= ss_di_r[1]; flags_ov0[1] <= ss_di_r[0]; end
        8'h1e: idb[7:0]    <= ss_di_r;
        8'h1f: idb[15:8]   <= ss_di_r;
        8'h20: alu_p[7:0]  <= ss_di_r;
        8'h21: alu_p[15:8] <= ss_di_r;
        8'h22: alu_q[7:0]  <= ss_di_r;
        8'h23: alu_q[15:8] <= ss_di_r;
        8'h24: alu_r[7:0]  <= ss_di_r;
        8'h25: alu_r[15:8] <= ss_di_r;
        8'h26: ram_dina_r[7:0]  <= ss_di_r;
        8'h27: ram_dina_r[15:8] <= ss_di_r;
        8'h28: ld_id[7:0]  <= ss_di_r;
        8'h29: ld_id[15:8] <= ss_di_r;
        8'h2a: begin op <= ss_di_r[7:6]; op_pselect <= ss_di_r[5:4]; op_alu <= ss_di_r[3:0]; end
        8'h2b: begin op_asl <= ss_di_r[7]; op_dpl <= ss_di_r[6:5]; op_dphm <= ss_di_r[4:1]; op_rpdcr <= ss_di_r[0]; end
        8'h2c: begin op_src <= ss_di_r[7:4]; op_dst <= ss_di_r[3:0]; end
        8'h2d: begin ld_dst <= ss_di_r[7:4]; alu_store <= ss_di_r[2:1]; cond_true <= ss_di_r[0]; end
        8'h2e: jp_brch[7:0] <= ss_di_r;
        8'h2f: jp_brch[8]   <= ss_di_r[0];
        8'h30: jp_na[7:0]   <= ss_di_r;
        8'h31: jp_na[10:8]  <= ss_di_r[2:0];
        8'h32: cpu_wait     <= ss_di_r[3:0];
        default: ; // $33 magic (read-only)
      endcase
    end
  end else begin
    insn_state <= STATE_IDLE1;
    pc <= 11'b0;
    regs_sp <= 4'b0000;
    cond_true <= 0;
    regs_sr[14] <= 0;
    regs_sr[13] <= 0;
    regs_sr[11] <= 0;
    regs_sr[SR_DRC] <= 0;
    regs_sr[9] <= 0;
    regs_sr[8] <= 0;
    regs_sr[7] <= 0;
    regs_rp <= 16'h0000;
    regs_dpb <= 2'b0;
    regs_dph <= 4'b0;
    regs_dpl <= 4'b0;
    regs_k <= 16'b0;
    regs_l <= 16'b0;
    regs_ab[0] <= 16'b0;
    regs_ab[1] <= 16'b0;
    flags_ov0 <= 2'b0;
    flags_ov1 <= 2'b0;
    flags_z <= 2'b0;
    flags_c <= 2'b0;
    flags_s0 <= 2'b0;
    flags_s1 <= 2'b0;
    regs_tr <= 16'b0;
    regs_trb <= 16'b0;
    op_pselect <= 2'b0;
    op_alu <= 4'b0;
    op_asl <= 1'b0;
    op_dpl <= 2'b0;
    op_dphm <= 4'b0;
    op_rpdcr <= 1'b0;
    op_src <= 4'b0;
    op_dst <= 4'b0;
    jp_brch <= 9'b0;
    jp_na <= 11'b0;
    ld_id <= 16'b0;
    ld_dst <= 4'b0;
    regs_m <= 16'b0;
    regs_n <= 16'b0;
  end
end

endmodule

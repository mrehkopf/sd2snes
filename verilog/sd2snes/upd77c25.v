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
module upd77c25(
  input [7:0] DI,
  output [7:0] DO,
  input A0,
  input nCS,
  input nRD,
  input nWR,
  input RST,
  input CLK,

  input PGM_WR,
  input [23:0] PGM_DI,
  input [10:0] PGM_WR_ADDR,

  input DAT_WR,
  input [15:0] DAT_DI,
  input [9:0] DAT_WR_ADDR,
  
  // debug
  output [15:0] DR,
  output [15:0] SR,
  output [10:0] PC,
  output [15:0] A,
  output [15:0] B,
  output [5:0] FL_A,
  output [5:0] FL_B
);
	 
parameter STATE_FETCH = 8'b00000001;
parameter STATE_LOAD = 8'b00000010;
parameter STATE_ALU1 = 8'b00000100;
parameter STATE_ALU2 = 8'b00001000;
parameter STATE_STORE = 8'b00010000;
parameter STATE_NEXT = 8'b00100000;
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

reg [3:0] regs_dph;
reg [3:0] regs_dpl;

reg [9:0] regs_rp;

wire [15:0] ram_dina;
reg [15:0] ram_dina_r;
assign ram_dina = ram_dina_r;

wire [10:0] pgm_addra;
wire [23:0] pgm_dina;
wire [23:0] pgm_doutb;

upd77c25_pgmrom pgmrom (
  .clka(CLK), // input clka
  .wea(PGM_WR), // input [0 : 0] wea
  .addra(PGM_WR_ADDR), // input [10 : 0] addra
  .dina(PGM_DI), // input [23 : 0] dina
  .clkb(CLK), // input clkb
  .addrb(pc), // input [10 : 0] addrb
  .doutb(pgm_doutb) // output [23 : 0] doutb
);

wire [23:0] opcode_w = pgm_doutb;
reg [23:0] opcode;
reg [1:0] op;
reg [1:0] op_pselect;
reg [3:0] op_alu;
reg op_asl;
reg [1:0] op_dpl;
reg [3:0] op_dphm;
reg op_rpdcr;
reg [3:0] op_src;
reg [3:0] op_dst;

wire [9:0] dat_addra;
wire [15:0] dat_dina;
wire [15:0] dat_doutb;

upd77c25_datrom datrom (
  .clka(CLK), // input clka
  .wea(DAT_WR), // input [0 : 0] wea
  .addra(DAT_WR_ADDR), // input [9 : 0] addra
  .dina(DAT_DI), // input [15 : 0] dina
  .clkb(CLK), // input clkb
  .addrb(regs_rp), // input [9 : 0] addrb
  .doutb(dat_doutb) // output [15 : 0] doutb
);

wire [15:0] ram_douta;
wire [7:0] ram_addra;
upd77c25_datram datram (
	.clka(CLK),
	.wea(ram_wea), // Bus [0 : 0] 
	.addra(ram_addra), // Bus [7 : 0] 
	.dina(ram_dina), // Bus [15 : 0] 
	.douta(ram_douta)); // Bus [15 : 0] 

assign ram_wea = ((op != I_JP) && op_dst == 4'b1111 && insn_state == STATE_NEXT);
assign ram_addra = {regs_dph | ((insn_state == STATE_ALU2 && op_dst == 4'b1100) ? 4'b0100 : 4'b0000), regs_dpl};
reg signed [15:0] regs_k;
reg signed [15:0] regs_l;
reg [15:0] regs_trb;
reg [15:0] regs_tr;
reg [15:0] regs_dr;
reg [15:0] regs_sr;
reg [15:0] regs_si;
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

reg [15:0] stack [15:0];

reg [15:0] idb;

reg [15:0] regs_ab [1:0];

assign DR = regs_dr;
assign SR = regs_sr;
assign PC = pc;
assign A = regs_ab[0];
assign B = regs_ab[1];
assign FL_A = {flags_s1[0],flags_s0[0],flags_c[0],flags_z[0],flags_ov1[0],flags_ov0[0]};
assign FL_B = {flags_s1[1],flags_s0[1],flags_c[1],flags_z[1],flags_ov1[1],flags_ov0[1]};


initial begin
  alu_store = 2'b11;
  insn_state = STATE_IDLE1;
  regs_sp = 4'b0000;
  pc = 11'b0;
  regs_sr = 16'b0;
  regs_rp = 16'h03ff;
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

end

reg [7:0] reg_nCS_sreg;
initial reg_nCS_sreg = 8'b11111111;
always @(posedge CLK) reg_nCS_sreg <= {reg_nCS_sreg[6:0], nCS};

reg [5:0] reg_oe_sreg;
initial reg_oe_sreg = 6'b111111;
always @(posedge CLK) reg_oe_sreg <= {reg_oe_sreg[4:0], nRD};
wire reg_oe_rising = !reg_nCS_sreg[2] && (reg_oe_sreg[5:0] == 6'b000001);

reg [5:0] reg_we_sreg;
initial reg_we_sreg = 6'b111111;
always @(posedge CLK) reg_we_sreg <= {reg_we_sreg[4:0], nWR};
wire reg_we_rising = !reg_nCS_sreg[2] && (reg_we_sreg[5:0] == 6'b000001);

reg [7:0] A0r;
initial A0r = 8'b11111111;
always @(posedge CLK) A0r <= {A0r[6:0], A0};

reg [7:0] last_op;
initial last_op = 8'h00;
always @(posedge CLK) begin
  if(RST) begin
    if((op_src == 4'b1000 && op[1] == 1'b0 && insn_state == STATE_STORE)
    || (op_dst == 4'b0110 && op != 2'b10 && insn_state == STATE_STORE)) regs_sr[SR_RQM] <= 1'b1;
    else if((reg_we_rising) && (A0r[3] == 1'b0)) begin
      if(!regs_sr[SR_DRC]) begin
        if(regs_sr[SR_DRS] == 1'b1) begin
          regs_sr[SR_RQM] <= 1'b0;
        end
      end else begin
        regs_sr[SR_RQM] <= 1'b0;
      end
    end
    else if(reg_oe_rising && (A0r[3] == 1'b0)) begin
      if(!regs_sr[SR_DRC]) begin
        if(regs_sr[SR_DRS] == 1'b1) begin
          regs_sr[SR_RQM] <= 1'b0;
        end
      end else begin
        regs_sr[SR_RQM] <= 1'b0;
      end
    end
  end else begin
    regs_sr[SR_RQM] <= 1'b0;
  end
end

always @(posedge CLK) begin
  if(RST) begin
    if(reg_we_rising && (A0r[3] == 1'b0)) begin
      if(!regs_sr[SR_DRC]) begin
        if(regs_sr[SR_DRS] == 1'b0) begin
          regs_sr[SR_DRS] <= 1'b1;
        end else begin
          regs_sr[SR_DRS] <= 1'b0;
        end
      end 
    end else if(reg_oe_rising) begin
      case(A0r[3])
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
  end else begin
    regs_sr[SR_DRS] <= 1'b0;
  end
end

always @(posedge CLK) begin
  if(RST) begin
    if(reg_we_rising && (A0r[3] == 1'b0)) begin
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
  end else begin
    regs_dr <= 16'h0000;
  end
end

assign DO = (A0 ? regs_sr[15:8] : (regs_sr[SR_DRC] ? regs_dr[7:0] : (regs_sr[SR_DRS] ? regs_dr[15:8] : regs_dr[7:0])));

always @(posedge CLK) begin
  if(RST) begin
    case(insn_state)
      STATE_FETCH: begin
        insn_state <= STATE_LOAD;
        opcode <= opcode_w;
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
              4'b0100: idb <= {regs_dph,regs_dpl};
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
        endcase
      end
      STATE_ALU2: begin
        insn_state <= STATE_STORE;
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
      end
      STATE_STORE: begin
        insn_state <= STATE_NEXT;
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
              4'b0100: {regs_dph,regs_dpl} <= idb[7:0];
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
          I_LD: begin
            case(ld_dst)
              4'b0001: regs_ab[0] <= ld_id;
              4'b0010: regs_ab[1] <= ld_id;
              4'b0011: regs_tr <= ld_id;
              4'b0100: {regs_dph,regs_dpl} <= ld_id[7:0];
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
      STATE_NEXT: begin
        insn_state <= STATE_IDLE1;

        case(op)
          I_OP, I_RT: begin
            if(|op_alu && alu_store[op_asl]) regs_ab[op_asl] <= alu_r;
            alu_store <= 2'b11;

            if(op_rpdcr) regs_rp <= regs_rp - 1;
            case(op_dpl)
              2'b01: regs_dpl <= regs_dpl + 1;
              2'b10: regs_dpl <= regs_dpl - 1;
              2'b11: regs_dpl <= 4'b0000;
            endcase
            regs_dph <= regs_dph ^ op_dphm;
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
      end
      STATE_IDLE1: insn_state <= STATE_IDLE2;
      STATE_IDLE2: insn_state <= STATE_FETCH;
      
    endcase
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
    regs_rp <= 16'h03ff;
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
    opcode <= 23'b0;
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

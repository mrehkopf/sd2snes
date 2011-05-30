`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:09:03 01/16/2011 
// Design Name: 
// Module Name:    upd77c25 
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
module upd77c25(
  input [7:0] DI,
  output reg [7:0] DO,
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
  input [9:0] DAT_WR_ADDR
);
	 
parameter I_OP = 2'b00;
parameter I_RT = 2'b01;
parameter I_JP = 2'b10;
parameter I_LD = 2'b11;

parameter SR_RQM = 15;
parameter SR_DRS = 12;
parameter SR_DRC = 10;

parameter FL_OV0 = 0;
parameter FL_OV1 = 1;
parameter FL_Z = 2;
parameter FL_C = 3;
parameter FL_S0 = 4;
parameter FL_S1 = 5;

reg [5:0] flags_r[1:0];
reg [5:0] flags_in;
reg [5:0] flags_out;

reg [10:0] pc;        // program counter

reg [1:0] insn_state; // execute clock state

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
	.clka(CLK),
	.wea(PGM_WR), // Bus [0 : 0] 
	.addra(PGM_WR_ADDR), // Bus [10 : 0] 
	.dina(PGM_DI), // Bus [23 : 0] 
	.clkb(CLK),
	.addrb(pc), // Bus [10 : 0] 
	.doutb(pgm_doutb)); // Bus [23 : 0] 

wire [23:0] opcode = pgm_doutb;
wire [1:0] op = opcode[23:22];
wire [1:0] op_pselect = opcode[21:20];
wire [3:0] op_alu = opcode[19:16];
wire op_asl = opcode[15];
wire [1:0] op_dpl = opcode[14:13];
wire [3:0] op_dphm = opcode[12:9];
wire op_rpdcr = opcode[8];
wire [3:0] op_src = opcode[7:4];
wire [3:0] op_dst = opcode[3:0];

wire [9:0] dat_addra;
wire [15:0] dat_dina;
wire [15:0] dat_doutb;

upd77c25_datrom datrom (
	.clka(CLK),
	.wea(DAT_WR), // Bus [0 : 0] 
	.addra(DAT_WR_ADDR), // Bus [9 : 0] 
	.dina(DAT_DI), // Bus [15 : 0] 
	.clkb(CLK),
	.addrb(regs_rp), // Bus [9 : 0] 
	.doutb(dat_doutb)); // Bus [15 : 0] 

wire [15:0] ram_douta;
upd77c25_datram datram (
	.clka(CLK),
	.wea(ram_wea), // Bus [0 : 0] 
	.addra({regs_dph | (op_dst == 4'b1100 ? 4'b0100 : 4'b0000), regs_dpl}), // Bus [7 : 0] 
	.dina(ram_dina), // Bus [15 : 0] 
	.douta(ram_douta)); // Bus [15 : 0] 

assign ram_wea = ((op != I_JP) && op_dst == 4'b1111 && insn_state == 2'b01);

reg signed [15:0] regs_k;
reg signed [15:0] regs_l;
reg [15:0] regs_trb;
reg [15:0] regs_tr;
reg [15:0] regs_dr;
reg [15:0] regs_sr;
reg [15:0] regs_si;
reg [3:0] regs_sp;

reg cond_true;

wire [8:0] jp_brch = opcode[21:13];
wire [10:0] jp_na = opcode[12:2];

wire [15:0] ld_id = opcode[21:6];
wire [3:0] ld_dst = opcode[3:0];

wire [31:0] mul_result = regs_k * regs_l;
wire [15:0] regs_m = mul_result[30:15];
wire [15:0] regs_n = {mul_result[14:0], 1'b0};

reg signed [15:0] alu_p;
reg signed [15:0] alu_q;
reg signed [15:0] alu_r;

reg [15:0] stack [15:0];

reg [15:0] idb;

reg signed [15:0] regs_ab [1:0];

initial begin
  insn_state = 2'b10;
  regs_sp = 4'b0000;
  pc = 11'b0;
  regs_sr = 16'b0;
  regs_rp = 16'b0;
  regs_dph = 4'b0;
  regs_dpl = 4'b0;
  regs_k = 16'b0;
  regs_l = 16'b0;
  regs_ab[0] = 16'b0;
  regs_ab[1] = 16'b0;
  flags_r[0] = 6'b0;
  flags_r[1] = 6'b0;
  regs_tr = 16'b0;
  regs_trb = 16'b0;
  regs_dr = 16'b0;
end

always @(regs_trb, regs_ab[0], regs_ab[1], regs_tr, regs_dph,
         regs_dpl, regs_rp, dat_doutb, flags_r[0][FL_S1],
         regs_dr, regs_sr, regs_k, regs_l, ram_douta, op_src)
begin
  case(op_src)
    4'b0000: idb = regs_trb;
    4'b0001: idb = regs_ab[0];
    4'b0010: idb = regs_ab[1];
    4'b0011: idb = regs_tr;
    4'b0100: idb = {regs_dph,regs_dpl};
    4'b0101: idb = regs_rp;
    4'b0110: idb = dat_doutb; // Address: [regs_rp]
    4'b0111: idb = flags_r[0][FL_S1] ? 16'h7fff : 16'h8000;
    4'b1000: idb = regs_dr;
    4'b1001: idb = regs_dr;
    4'b1010: idb = regs_sr;
    4'b1101: idb = regs_k;
    4'b1110: idb = regs_l;
    4'b1111: idb = ram_douta; // Address: [regs_dp]
  endcase
end

always @(op_pselect, ram_douta, idb, regs_m, regs_n) begin
  case(op_pselect)
    2'b00:
      alu_p = ram_douta;
    2'b01:
      alu_p = idb;
    2'b10:
      alu_p = regs_m;
    2'b11:
      alu_p = regs_n;
  endcase
end

always @(op_asl, regs_ab[0], regs_ab[1], flags_r[0], flags_r[1]) begin
  alu_q = regs_ab[op_asl];
  flags_in = flags_r[op_asl];
end

always @(op_alu, alu_p, alu_q, flags_in[FL_C]) begin
  case(op_alu)
    4'b0001: alu_r = alu_q | alu_p;
    4'b0010: alu_r = alu_q & alu_p;
    4'b0011: alu_r = alu_q ^ alu_p;
    4'b0100: alu_r = alu_q - alu_p;
    4'b0101: alu_r = alu_q + alu_p;
    4'b0110: alu_r = alu_q - alu_p - flags_in[FL_C];
    4'b0111: alu_r = alu_q + alu_p + flags_in[FL_C];
    4'b1000: alu_r = alu_q - 1;
    4'b1001: alu_r = alu_q + 1;
    4'b1010: alu_r = ~alu_q;
    4'b1011: alu_r = alu_q >>> 1;
    4'b1100: alu_r = (alu_q << 1) | flags_in[FL_C];
    4'b1101: alu_r = (alu_q << 2) | 2'b11;
    4'b1110: alu_r = (alu_q << 4) | 4'b1111;
    4'b1111: alu_r = {alu_q[7:0], alu_q[15:8]};
  endcase
end

always @(op_alu, alu_r, flags_in, alu_p, alu_q) begin
  flags_out = flags_in;
  flags_out[FL_Z] = (alu_r == 0);
  flags_out[FL_S0] = alu_r[15];
  case(op_alu)
    4'b0001, 4'b0010, 4'b0011, 4'b1010, 4'b1101, 4'b1110, 4'b1111: begin
      flags_out[FL_C] = 0;
      flags_out[FL_OV0] = 0;
      flags_out[FL_OV1] = 0;
    end
    4'b0100, 4'b0101, 4'b0110, 4'b0111, 4'b1000, 4'b1001: begin
      if(op_alu[0]) begin
        flags_out[FL_OV0] = (alu_q ^ alu_r) & ~(alu_q ^ alu_p) & 16'h8000;
        flags_out[FL_C] = (alu_r < alu_q);
      end else begin
        flags_out[FL_OV0] = (alu_q ^ alu_r) & (alu_q ^ alu_p) & 16'h8000;
        flags_out[FL_C] = (alu_r > alu_q);
      end
      if(flags_out[FL_OV0]) begin
        flags_out[FL_S1] = flags_in[FL_OV0] ^ !(alu_r & 16'h8000);
        flags_out[FL_OV1] = !flags_in[FL_OV1];
      end
    end
    4'b1011: begin
      flags_out[FL_C] = alu_q[0];
      flags_out[FL_OV0] = 0;
      flags_out[FL_OV1] = 0;
    end
    4'b1100: begin
      flags_out[FL_C] = alu_q[15];
      flags_out[FL_OV0] = 0;
      flags_out[FL_OV1] = 0;
    end
  endcase
end

reg [5:0] reg_oe_sreg;
always @(posedge CLK) reg_oe_sreg <= {reg_oe_sreg[4:0], nRD};
wire reg_oe_falling = !nCS && (reg_oe_sreg[3:0] == 4'b1000);

reg [1:0] reg_we_sreg;
always @(posedge CLK) reg_we_sreg <= {reg_we_sreg[0], nWR};
wire reg_we_rising = !nCS && (reg_we_sreg[1:0] == 2'b01);

always @(posedge CLK) begin
  if(RST) begin
    if(reg_we_rising && A0 == 1'b0) begin
      if(!regs_sr[SR_DRC]) begin
        if(regs_sr[SR_DRS] == 1'b0) begin
          regs_sr[SR_DRS] <= 1'b1;
          regs_dr[7:0] <= DI;
        end else begin
          regs_sr[SR_DRS] <= 1'b0;
          regs_sr[SR_RQM] <= 1'b0;
          regs_dr[15:8] <= DI;
        end
      end else begin
        regs_sr[SR_RQM] <= 1'b0;
        regs_dr[7:0] <= DI;
      end
    end else if(reg_oe_falling) begin
      case(A0)
        1'b0: begin
          if(!regs_sr[SR_DRC]) begin
            if(regs_sr[SR_DRS] == 1'b0) begin
              regs_sr[SR_DRS] <= 1'b1;
              DO <= regs_dr[7:0];
            end else begin
              regs_sr[SR_DRS] <= 1'b0;
              regs_sr[SR_RQM] <= 1'b0;
              DO <= regs_dr[15:8];
            end
          end else begin
            regs_sr[SR_RQM] <= 1'b0;
            DO <= regs_dr[7:0];
          end
        end
        1'b1: DO <= regs_sr[15:8];
      endcase
    end
    if(op_src == 4'b1000 && op[1] == 1'b0) regs_sr[SR_RQM] <= 1;
    else if(op_dst == 4'b0110 && op != 2'b10) regs_sr[SR_RQM] <= 1;
    
    if(op_dst == 4'b0110 && insn_state == 2'b00) begin
      if (op == I_OP || op == I_RT) regs_dr <= idb;
      else if (op == I_LD) regs_dr <= ld_id;
    end
  end else begin
    regs_dr <= 16'h0000;
    regs_sr[SR_DRS] <= 1'b0;
    regs_sr[SR_RQM] <= 1'b0;
    DO <= 8'h00;
  end
end

always @(posedge CLK) begin
  if(RST) begin
    case(insn_state)
      2'b00: begin
        insn_state <= 2'b01;
        case(op)
          I_OP, I_RT: begin
  //          if(op_src == 4'b1000) regs_sr[SR_RQM] <= 1;
            regs_ab[op_asl] <= alu_r;
            case(op_dst)
              4'b0001: regs_ab[0] <= idb;
              4'b0010: regs_ab[1] <= idb;
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
            flags_r[op_asl] <= flags_out;
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
              9'b010_000_000: cond_true <= (flags_r[0][FL_C] == 0);
              9'b010_000_010: cond_true <= (flags_r[0][FL_C] == 1);
              9'b010_000_100: cond_true <= (flags_r[1][FL_C] == 0);
              9'b010_000_110: cond_true <= (flags_r[1][FL_C] == 1);
              9'b010_001_000: cond_true <= (flags_r[0][FL_Z] == 0);
              9'b010_001_010: cond_true <= (flags_r[0][FL_Z] == 1);
              9'b010_001_100: cond_true <= (flags_r[1][FL_Z] == 0);
              9'b010_001_110: cond_true <= (flags_r[1][FL_Z] == 1);
              9'b010_010_000: cond_true <= (flags_r[0][FL_OV0] == 0);
              9'b010_010_010: cond_true <= (flags_r[0][FL_OV0] == 1);
              9'b010_010_100: cond_true <= (flags_r[1][FL_OV0] == 0);
              9'b010_010_110: cond_true <= (flags_r[1][FL_OV0] == 1);
              9'b010_011_000: cond_true <= (flags_r[0][FL_OV1] == 0);
              9'b010_011_010: cond_true <= (flags_r[0][FL_OV1] == 1);
              9'b010_011_100: cond_true <= (flags_r[1][FL_OV1] == 0);
              9'b010_011_110: cond_true <= (flags_r[1][FL_OV1] == 1);
              9'b010_100_000: cond_true <= (flags_r[0][FL_S0] == 0);
              9'b010_100_010: cond_true <= (flags_r[0][FL_S0] == 1);
              9'b010_100_100: cond_true <= (flags_r[1][FL_S0] == 0);
              9'b010_100_110: cond_true <= (flags_r[1][FL_S0] == 1);
              9'b010_101_000: cond_true <= (flags_r[0][FL_S1] == 0);
              9'b010_101_010: cond_true <= (flags_r[0][FL_S1] == 1);
              9'b010_101_100: cond_true <= (flags_r[1][FL_S1] == 0);
              9'b010_101_110: cond_true <= (flags_r[1][FL_S1] == 1);
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
      2'b01: begin
        case(op)
          I_OP, I_RT: begin
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
                stack[regs_sp] <= pc;
                regs_sp <= regs_sp + 1;
              end
            end else pc <= pc + 1;
          end
          I_LD: begin
            pc <= pc + 1;
          end
        endcase
        insn_state <= 2'b10;
      end
      2'b10: insn_state <= 2'b00;
    endcase
  end else begin
    insn_state <= 2'b10;
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
    regs_rp <= 16'b0;
    regs_dph <= 4'b0;
    regs_dpl <= 4'b0;
    regs_k <= 16'b0;
    regs_l <= 16'b0;
    regs_ab[0] <= 16'b0;
    regs_ab[1] <= 16'b0;
    flags_r[0] <= 6'b0;
    flags_r[1] <= 6'b0;
    regs_tr <= 16'b0;
    regs_trb <= 16'b0;
  end
end

endmodule

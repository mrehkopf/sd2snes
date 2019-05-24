`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    23:14:37 10/13/2011
// Design Name:
// Module Name:    cx4
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
module cx4(
  input [7:0] DI,
  output [7:0] DO,
  input [12:0] ADDR,
  input CS,
  input SNES_VECT_EN,
  input reg_we_rising,
  input CLK,
  input [7:0] BUS_DI,
  output [23:0] BUS_ADDR,
  output BUS_RRQ,
  input BUS_RDY,
  output cx4_active,
  output [2:0] cx4_busy_out,
  input speed
);

reg [2:0] cx4_busy;
parameter BUSY_CACHE = 2'b00;
parameter BUSY_DMA   = 2'b01;
parameter BUSY_CPU   = 2'b10;
assign cx4_busy_out = cx4_busy;

wire datram_enable = CS & (ADDR[11:0] < 12'hc00);
wire mmio_enable = CS & (ADDR[12:5] == 8'b11111010) & (ADDR[4:0] < 5'b10011);
wire status_enable = CS & (ADDR[12:5] == 8'b11111010) & (ADDR[4:0] >= 5'b10011);
wire vector_enable = (CS & (ADDR[12:5] == 8'b11111011)) | (cx4_active & SNES_VECT_EN);
wire gpr_enable = CS & (&(ADDR[12:7]) && ADDR[5:4] != 2'b11);
wire pgmrom_enable = CS & (ADDR[12:5] == 8'b11110000);

wire [7:0] DATRAM_DO;
reg  [7:0] MMIO_DOr;
wire [7:0] MMIO_DO;
wire [7:0] STATUS_DO;
wire [7:0] VECTOR_DO;
wire [7:0] GPR_DO;

assign DO = datram_enable ? DATRAM_DO
            : mmio_enable ? MMIO_DO
            : status_enable ? STATUS_DO
            : vector_enable ? VECTOR_DO
            : gpr_enable ? GPR_DO
            : 8'h00;

/* 0x1f40 - 0x1f52: MMIO
   SNES: 8 bits / CX4: various */
reg [23:0] cx4_mmio_dmasrc;
reg [15:0] cx4_mmio_dmalen;
reg [23:0] cx4_mmio_dmatgt;
reg        cx4_mmio_cachepage;
reg [23:0] cx4_mmio_pgmoff;
reg  [1:0] cx4_mmio_savepage;
reg [14:0] cx4_mmio_pgmpage;
reg  [7:0] cx4_mmio_pc;
reg  [7:0] cx4_mmio_r1f50;
reg        cx4_mmio_r1f51;
reg        cx4_mmio_r1f52;
/* 0x1f53 - 0x1f5f: status register */
assign cx4_active = |cx4_busy;
/* 0x1f60 - 0x1f7f: reset vectors */
reg  [7:0] vector [31:0];
/* 0x1f80 - 0x1faf (0x1fc0 - 0x1fef): general purpose register file
   SNES: 8 bits / CX4: 24 bits */
reg  [7:0] gpr [47:0];
wire [47:0] cpu_mul_result;

reg [14:0] cx4_mmio_pagemem[1:0];

reg [23:0] const [15:0];

reg [14:0] cachetag [1:0];
reg  [1:0] cachevalid;

reg [14:0] cache_pgmpage;
reg [14:0] cpu_cache_pgmpage;
reg        cache_cachepage;
reg        cpu_cache_cachepage;
reg        cpu_cache_done;
reg  [7:0] cpu_pc_stack [7:0];
reg  [7:0] cpu_page_stack;

initial begin
  cache_pgmpage = 15'b0;
  cpu_cache_pgmpage = 15'b0;
  cache_cachepage = 1'b0;
  cpu_cache_cachepage = 1'b0;
  cpu_cache_done = 1'b0;
  cachetag[0] = 14'h0000;
  cachetag[1] = 14'h0000;
  cachevalid = 2'b00;
  cx4_busy = 3'b000;
  cx4_mmio_pgmoff = 24'h000000;
  cx4_mmio_pgmpage = 15'h0000;
  cx4_mmio_dmasrc = 24'h000000;
  cx4_mmio_dmalen = 16'h0000;
  cx4_mmio_dmatgt = 24'h000000;
  cx4_mmio_savepage = 2'b00;
  const[0] = 24'h000000;
  const[1] = 24'hffffff;
  const[2] = 24'h00ff00;
  const[3] = 24'hff0000;
  const[4] = 24'h00ffff;
  const[5] = 24'hffff00;
  const[6] = 24'h800000;
  const[7] = 24'h7fffff;
  const[8] = 24'h008000;
  const[9] = 24'h007fff;
  const[10] = 24'hff7fff;
  const[11] = 24'hffff7f;
  const[12] = 24'h010000;
  const[13] = 24'hfeffff;
  const[14] = 24'h000100;
  const[15] = 24'h00feff;
  cpu_pc_stack[0] = 8'b0;
  cpu_pc_stack[1] = 8'b0;
  cpu_pc_stack[2] = 8'b0;
  cpu_pc_stack[3] = 8'b0;
  cpu_pc_stack[4] = 8'b0;
  cpu_pc_stack[5] = 8'b0;
  cpu_pc_stack[6] = 8'b0;
  cpu_pc_stack[7] = 8'b0;
  cpu_page_stack = 8'b0;
end

assign MMIO_DO = MMIO_DOr;
assign VECTOR_DO = vector [ADDR[4:0]];
assign GPR_DO = gpr [ADDR[5:0]];
assign STATUS_DO = {1'b0, cx4_active, 4'b0000, ~cx4_active, 1'b0};

wire DATRAM_WR_EN = datram_enable & reg_we_rising;
wire MMIO_WR_EN = mmio_enable & reg_we_rising;
wire VECTOR_WR_EN = vector_enable & reg_we_rising;
wire GPR_WR_EN = gpr_enable & reg_we_rising;

reg [23:0] cpu_idb; // tmp register for reg file read

/* Need to cache when:
   1f48 is written
  AND (selected cache page is invalid
       OR selected cache page does not contain requested page already)
*/
reg CACHE_TRIG_ENr;
reg CACHE_TRIG_EN2r;
reg cpu_cache_en;
initial begin
  CACHE_TRIG_ENr = 1'b0;
  CACHE_TRIG_EN2r = 1'b0;
  cpu_cache_en = 1'b0;
end
always @(posedge CLK) CACHE_TRIG_EN2r <= CACHE_TRIG_ENr;
wire CACHE_TRIG_EN = CACHE_TRIG_EN2r;

reg DMA_TRIG_ENr;
initial DMA_TRIG_ENr = 1'b0;
wire DMA_TRIG_EN = DMA_TRIG_ENr;

reg CACHE_BUS_RRQr;
reg DMA_BUS_RRQr;
reg cpu_bus_rq;

initial begin
  CACHE_BUS_RRQr = 1'b0;
  DMA_BUS_RRQr = 1'b0;
  cpu_bus_rq = 1'b0;
end

assign BUS_RRQ = CACHE_BUS_RRQr | DMA_BUS_RRQr | cpu_bus_rq;

reg cpu_page;
reg [14:0] cpu_p;
reg [7:0] cpu_pc;
reg [23:0] cpu_a;
reg fl_n;
reg fl_z;
reg fl_c;


reg cpu_go_en_r;
initial cpu_go_en_r = 1'b0;

initial begin
  cx4_mmio_r1f50 = 8'h33;
  cx4_mmio_r1f51 = 1'b0;
  cx4_mmio_r1f52 = 1'b1;
end

always @(posedge CLK) begin
  case (ADDR[4:0])
    5'h00: MMIO_DOr <= cx4_mmio_dmasrc[7:0];   // 1f40
    5'h01: MMIO_DOr <= cx4_mmio_dmasrc[15:8];  // 1f41
    5'h02: MMIO_DOr <= cx4_mmio_dmasrc[23:16]; // 1f42
    5'h03: MMIO_DOr <= cx4_mmio_dmalen[7:0];   // 1f43
    5'h04: MMIO_DOr <= cx4_mmio_dmalen[15:8];  // 1f44
    5'h05: MMIO_DOr <= cx4_mmio_dmatgt[7:0];   // 1f45
    5'h06: MMIO_DOr <= cx4_mmio_dmatgt[15:8];  // 1f46
    5'h07: MMIO_DOr <= cx4_mmio_dmatgt[23:16]; // 1f47
    5'h08: MMIO_DOr <= {7'b0, cx4_mmio_cachepage};
    5'h09: MMIO_DOr <= cx4_mmio_pgmoff[7:0];   // 1f49
    5'h0a: MMIO_DOr <= cx4_mmio_pgmoff[15:8];  // 1f4a
    5'h0b: MMIO_DOr <= cx4_mmio_pgmoff[23:16]; // 1f4b
    5'h0c: MMIO_DOr <= {6'b0, cx4_mmio_savepage};    // 1f4c
    5'h0d: MMIO_DOr <= cx4_mmio_pgmpage[7:0];  // 1f4d
    5'h0e: MMIO_DOr <= {1'b0, cx4_mmio_pgmpage[14:8]};   // 1f4e
    5'h0f: MMIO_DOr <= cx4_mmio_pc;  // 1f4f
    5'h10: MMIO_DOr <= cx4_mmio_r1f50; // 1f50
    5'h11: MMIO_DOr <= {7'b0, cx4_mmio_r1f51};      // 1f51
    5'h12: MMIO_DOr <= {7'b0, cx4_mmio_r1f52};      // 1f52
    default: MMIO_DOr <= 8'hff;
  endcase
end

always @(posedge CLK) begin
  if(MMIO_WR_EN) begin
    case(ADDR[4:0])
      5'h00: cx4_mmio_dmasrc[7:0] <= DI;   // 1f40
      5'h01: cx4_mmio_dmasrc[15:8] <= DI;  // 1f41
      5'h02: cx4_mmio_dmasrc[23:16] <= DI; // 1f42
      5'h03: cx4_mmio_dmalen[7:0] <= DI;   // 1f43
      5'h04: cx4_mmio_dmalen[15:8] <= DI;  // 1f44
      5'h05: cx4_mmio_dmatgt[7:0] <= DI;   // 1f45
      5'h06: cx4_mmio_dmatgt[15:8] <= DI;  // 1f46
      5'h07: begin
        cx4_mmio_dmatgt[23:16] <= DI; // 1f47
        DMA_TRIG_ENr <= 1'b1;
      end
      5'h08: begin
        cx4_mmio_cachepage <= DI[0];  // 1f48
        CACHE_TRIG_ENr <= 1'b1;
      end
      5'h09: cx4_mmio_pgmoff[7:0] <= DI;   // 1f49
      5'h0a: cx4_mmio_pgmoff[15:8] <= DI;  // 1f4a
      5'h0b: cx4_mmio_pgmoff[23:16] <= DI; // 1f4b
      5'h0c: begin
        cx4_mmio_savepage <= DI[1:0];
        if(DI[0]) cx4_mmio_pagemem[0] <= cx4_mmio_pgmpage;
        if(DI[1]) cx4_mmio_pagemem[1] <= cx4_mmio_pgmpage;
      end
      5'h0d: cx4_mmio_pgmpage[7:0] <= DI;  // 1f4d
      5'h0e: cx4_mmio_pgmpage[14:8] <= DI[6:0];   // 1f4e
      5'h0f: begin
        cx4_mmio_pc <= DI;  // 1f4f
        if(cx4_mmio_savepage[0]
           && cx4_mmio_pagemem[0] == cx4_mmio_pgmpage)
          cx4_mmio_cachepage <= 1'b0;
        else if(cx4_mmio_savepage[1]
                && cx4_mmio_pagemem[1] == cx4_mmio_pgmpage)
          cx4_mmio_cachepage <= 1'b1;
        cpu_go_en_r <= 1'b1;
      end
      5'h10: cx4_mmio_r1f50 <= DI & 8'h77; // 1f50
      5'h11: cx4_mmio_r1f51 <= DI[0];      // 1f51
      5'h12: cx4_mmio_r1f52 <= DI[0];      // 1f52
    endcase
  end else begin
    CACHE_TRIG_ENr <= 1'b0;
    DMA_TRIG_ENr <= 1'b0;
    cpu_go_en_r <= 1'b0;
  end
end

always @(posedge CLK) begin
  if(VECTOR_WR_EN) vector[ADDR[4:0]] <= DI;
end

reg [4:0] CACHE_ST;
parameter ST_CACHE_IDLE  = 5'b00001;
parameter ST_CACHE_START = 5'b00010;
parameter ST_CACHE_WAIT  = 5'b00100;
parameter ST_CACHE_ADDR  = 5'b01000;
parameter ST_CACHE_END   = 5'b10000;
initial CACHE_ST = ST_CACHE_IDLE;

reg [4:0] DMA_ST;
parameter ST_DMA_IDLE  = 5'b00001;
parameter ST_DMA_START = 5'b00010;
parameter ST_DMA_WAIT  = 5'b00100;
parameter ST_DMA_ADDR  = 5'b01000;
parameter ST_DMA_END   = 5'b10000;
initial DMA_ST = ST_DMA_IDLE;

reg [23:0] CACHE_SRC_ADDRr;
wire [22:0] MAPPED_CACHE_SRC_ADDR = {CACHE_SRC_ADDRr[23:16],CACHE_SRC_ADDRr[14:0]};
reg [23:0] DMA_SRC_ADDRr;
wire [22:0] MAPPED_DMA_SRC_ADDR = {DMA_SRC_ADDRr[23:16],DMA_SRC_ADDRr[14:0]};
wire [22:0] MAPPED_CPU_BUS_ADDR;

assign BUS_ADDR =  cx4_busy[BUSY_CACHE] ? MAPPED_CACHE_SRC_ADDR
                 : cx4_busy[BUSY_DMA] ? MAPPED_DMA_SRC_ADDR
                 : MAPPED_CPU_BUS_ADDR;

reg cx4_pgmrom_we;
initial cx4_pgmrom_we = 1'b0;
reg [9:0] cx4_pgmrom_addr;
reg [19:0] cache_count;
initial cache_count = 20'b0;

always @(posedge CLK) begin
  case(CACHE_ST)
    ST_CACHE_IDLE: begin
      if(CACHE_TRIG_EN
         & (~cachevalid[cx4_mmio_cachepage]
            | |(cachetag[cx4_mmio_cachepage] ^ cx4_mmio_pgmpage))) begin
        CACHE_ST <= ST_CACHE_START;
        cache_pgmpage <= cx4_mmio_pgmpage;
        cache_cachepage <= cx4_mmio_cachepage;
        cx4_busy[BUSY_CACHE] <= 1'b1;
      end else if(cpu_cache_en
         & (~cachevalid[~cpu_page]
            | |(cachetag[~cpu_page] ^ cpu_p))) begin
        CACHE_ST <= ST_CACHE_START;
        cache_pgmpage <= cpu_p;
        cache_cachepage <= ~cpu_page;
        cx4_busy[BUSY_CACHE] <= 1'b1;
      end
      else CACHE_ST <= ST_CACHE_IDLE;
    end
    ST_CACHE_START: begin
      cx4_busy[BUSY_CACHE] <= 1'b1;
      CACHE_SRC_ADDRr <= cx4_mmio_pgmoff + {cache_pgmpage, 9'b0};
      cx4_pgmrom_addr <= {cache_cachepage, 9'b0};
      CACHE_ST <= ST_CACHE_WAIT;
      cache_count <= 10'b0;
      CACHE_BUS_RRQr <= 1'b1;
    end
    ST_CACHE_WAIT: begin
      CACHE_BUS_RRQr <= 1'b0;
      if(~CACHE_BUS_RRQr & BUS_RDY) begin
        CACHE_ST <= ST_CACHE_ADDR;
        cx4_pgmrom_we <= 1'b1;
        cache_count <= cache_count + 1;
      end else CACHE_ST <= ST_CACHE_WAIT;
    end
    ST_CACHE_ADDR: begin
      cx4_pgmrom_we <= 1'b0;
      CACHE_SRC_ADDRr <= CACHE_SRC_ADDRr + 1;
      cx4_pgmrom_addr <= cx4_pgmrom_addr + 1;
      if(cache_count == 9'h1ff) begin
        cx4_busy[BUSY_CACHE] <= 1'b0;
        cachetag[cache_cachepage] <= cache_pgmpage;
        cachevalid[cache_cachepage] <= 1'b1;
        CACHE_ST <= ST_CACHE_IDLE;
      end else begin
        CACHE_BUS_RRQr <= 1'b1;
        CACHE_ST <= ST_CACHE_WAIT;
      end
    end
  endcase
end

reg cx4_dma_datram_we;
reg cx4_cpu_datram_we;
initial cx4_dma_datram_we = 1'b0;
initial cx4_cpu_datram_we = 1'b0;
wire cx4_datram_we = cx4_dma_datram_we | cx4_cpu_datram_we;
reg [11:0] cx4_dma_datram_addr;
reg [11:0] cx4_cpu_datram_addr;
wire [11:0] cx4_datram_addr = cx4_busy[BUSY_DMA] ? cx4_dma_datram_addr : cx4_cpu_datram_addr;
reg [23:0] cx4_cpu_datram_di;
wire [7:0] cx4_datram_di = cx4_busy[BUSY_DMA] ? BUS_DI : cx4_cpu_datram_di;
reg [15:0] dma_count;
initial dma_count = 16'b0;

always @(posedge CLK) begin
  case(DMA_ST)
    ST_DMA_IDLE: begin
      if(DMA_TRIG_EN) begin
        DMA_ST <= ST_DMA_START;
      end else DMA_ST <= ST_DMA_IDLE;
    end
    ST_DMA_START: begin
      cx4_busy[BUSY_DMA] <= 1'b1;
      DMA_SRC_ADDRr <= cx4_mmio_dmasrc;
      cx4_dma_datram_addr <= (cx4_mmio_dmatgt & 24'h000fff);
      DMA_ST <= ST_DMA_WAIT;
      dma_count <= cx4_mmio_dmalen;
      DMA_BUS_RRQr <= 1'b1;
    end
    ST_DMA_WAIT: begin
      DMA_BUS_RRQr <= 1'b0;
      if(~DMA_BUS_RRQr & BUS_RDY) begin
        DMA_ST <= ST_DMA_ADDR;
        cx4_dma_datram_we <= 1'b1;
        dma_count <= dma_count - 1;
      end else DMA_ST <= ST_DMA_WAIT;
    end
    ST_DMA_ADDR: begin
      cx4_dma_datram_we <= 1'b0;
      DMA_SRC_ADDRr <= DMA_SRC_ADDRr + 1;
      cx4_dma_datram_addr <= cx4_dma_datram_addr + 1;
      if(dma_count == 16'h0000) begin
        cx4_busy[BUSY_DMA] <= 1'b0;
        DMA_ST <= ST_DMA_IDLE;
      end else begin
        DMA_BUS_RRQr <= 1'b1;
        DMA_ST <= ST_DMA_WAIT;
      end
    end
  endcase
end

/***************************
 =========== CPU ===========
 ***************************/
reg [5:0] CPU_STATE;
reg [2:0] cpu_sp;
initial cpu_sp = 3'b000;
wire [15:0] cpu_op_w;
reg [15:0] cpu_op;
reg [23:0] cpu_busdata;
reg [23:0] cpu_romdata;
reg [23:0] cpu_ramdata;
reg [23:0] cpu_busaddr;
assign MAPPED_CPU_BUS_ADDR = {cpu_busaddr[23:16], cpu_busaddr[14:0]};
reg [23:0] cpu_romaddr;
reg [23:0] cpu_ramaddr;
reg [23:0] cpu_acch;
reg [23:0] cpu_accl;
reg [23:0] cpu_mul_a;
reg [23:0] cpu_mul_b;
reg [24:0] cpu_alu_res;
reg [23:0] cpu_dummy;
reg [23:0] cpu_tmp;

reg [23:0] cpu_sa;  // tmp register for shifted accumulator
reg [7:0] cpu_wait;
initial cpu_wait = 8'h00;

wire [9:0] cx4_datrom_addr = cpu_a[9:0];
wire [23:0] cx4_datrom_do;
wire [7:0] cx4_datram_do;

parameter ST_CPU_IDLE = 6'b000001;
parameter ST_CPU_0    = 6'b000010;
parameter ST_CPU_1    = 6'b000100;
parameter ST_CPU_2    = 6'b001000;
parameter ST_CPU_3    = 6'b010000;
parameter ST_CPU_4    = 6'b100000;

initial CPU_STATE = ST_CPU_IDLE;

parameter OP_NOP   = 5'b00000;
parameter OP_JP    = 5'b00001;
parameter OP_SKIP  = 5'b00010;
parameter OP_RT    = 5'b00011;
parameter OP_LD    = 5'b00100;
parameter OP_ST    = 5'b00101;
parameter OP_SWP   = 5'b00110;
parameter OP_RDROM = 5'b00111;
parameter OP_RDRAM = 5'b01000;
parameter OP_WRRAM = 5'b01001;
parameter OP_ALU   = 5'b01010;
parameter OP_MUL   = 5'b01011;
parameter OP_WAI   = 5'b01100;
parameter OP_BUS   = 5'b01101;
parameter OP_CMP   = 5'b01110;
parameter OP_SEX   = 5'b01111;
parameter OP_HLT   = 5'b10000;

parameter MUL_DELAY = 3'h2;

wire [6:0] op_id = cpu_op_w[15:10];
reg [7:0] op_param;
reg [4:0] op;
reg [1:0] op_sa;
reg op_imm;
reg op_p;
reg op_call;
reg op_jump;
reg condtrue;
reg mul_strobe = 0;

always @(posedge CLK) begin
  if(cpu_go_en_r) cx4_busy[BUSY_CPU] <= 1'b1;
  else if(op == OP_HLT) cx4_busy[BUSY_CPU] <= 1'b0;
end

always @(posedge CLK) begin
  case(op_sa)
    2'b00: cpu_sa <= cpu_a;
    2'b01: cpu_sa <= cpu_a << 1;
    2'b10: cpu_sa <= cpu_a << 8;
    2'b11: cpu_sa <= cpu_a << 16;
  endcase
end

reg jp_docache;
initial jp_docache = 1'b0;

always @(posedge CLK) begin
  mul_strobe <= 1'b0;
  case(CPU_STATE)
    ST_CPU_IDLE: begin
      if(cpu_go_en_r) begin
        cpu_pc <= cx4_mmio_pc;
        cpu_page <= cx4_mmio_cachepage;
        cpu_p <= cx4_mmio_pgmpage;
        op <= OP_NOP;
        CPU_STATE <= ST_CPU_2;
      end
      else CPU_STATE <= ST_CPU_IDLE;
    end
    ST_CPU_0: begin // Phase 0:
      cpu_cache_en <= 1'b0;
      if(op == OP_HLT) begin
        CPU_STATE <= ST_CPU_IDLE;
      end
      else CPU_STATE <= ST_CPU_1;
      case(op)
        OP_JP: begin
          case(cpu_op[11:10])
            2'b10: condtrue <= 1'b1;
            2'b11: condtrue <= fl_z;
            2'b00: condtrue <= fl_c;
            2'b01: condtrue <= fl_n;
          endcase
          if(op_p && !jp_docache) begin
            jp_docache <= 1'b1;
            cpu_cache_en <= 1'b1;
          end
        end
        OP_SKIP: begin
          case(cpu_op[9:8])
            2'b01: condtrue <= (fl_c == cpu_op[0]);
            2'b10: condtrue <= (fl_z == cpu_op[0]);
            2'b11: condtrue <= (fl_n == cpu_op[0]);
          endcase
        end
        OP_LD, OP_ALU, OP_MUL, OP_CMP, OP_SEX: begin
          if(op == OP_MUL) begin
            mul_strobe <= 1'b1;
          end
          if(op_imm) begin
            cpu_idb <= {16'b0, op_param};
          end else begin
            casex(op_param)
              8'h00: cpu_idb <= cpu_a;
              8'h01: cpu_idb <= cpu_mul_result[47:24];
              8'h02: cpu_idb <= cpu_mul_result[23:0];
              8'h03: cpu_idb <= cpu_busdata;
              8'h08: cpu_idb <= cpu_romdata;
              8'h0c: cpu_idb <= cpu_ramdata;
              8'h13: cpu_idb <= cpu_busaddr;
              8'h1c: cpu_idb <= cpu_ramaddr;
              8'h5x: cpu_idb <= const[op_param[3:0]];
              8'h6x: cpu_idb <= {gpr[op_param[3:0]*3+2],
                                 gpr[op_param[3:0]*3+1],
                                 gpr[op_param[3:0]*3]};
              default: cpu_idb <= 24'b0;
            endcase
          end
        end
        OP_ST: begin
          cpu_idb <= cpu_a;
        end
        OP_SWP: begin
          cpu_idb <= cpu_a;
          casex(op_param)
            8'h00: cpu_tmp <= cpu_a;
//            8'h01: cpu_tmp <= cpu_acch;
//            8'h02: cpu_tmp <= cpu_accl;
            8'h03: cpu_tmp <= cpu_busdata;
            8'h08: cpu_tmp <= cpu_romdata;
            8'h0c: cpu_tmp <= cpu_ramdata;
            8'h13: cpu_tmp <= cpu_busaddr;
            8'h1c: cpu_tmp <= cpu_ramaddr;
            8'h5x: cpu_tmp <= const[op_param[3:0]];
            8'h6x: cpu_tmp <= {gpr[op_param[3:0]*3+2],
                               gpr[op_param[3:0]*3+1],
                               gpr[op_param[3:0]*3]};
            default: cpu_tmp <= 24'b0;
          endcase
        end
        OP_RDRAM, OP_WRRAM: begin
          if(op_imm) cx4_cpu_datram_addr <= {16'b0, op_param} + cpu_ramaddr;
          else casex(op_param)
            8'h00: cx4_cpu_datram_addr <= cpu_a;
            8'h01: cx4_cpu_datram_addr <= cpu_acch;
            8'h02: cx4_cpu_datram_addr <= cpu_accl;
            8'h03: cx4_cpu_datram_addr <= cpu_busdata;
            8'h08: cx4_cpu_datram_addr <= cpu_romdata;
            8'h0c: cx4_cpu_datram_addr <= cpu_ramdata;
            8'h13: cx4_cpu_datram_addr <= cpu_busaddr;
            8'h1c: cx4_cpu_datram_addr <= cpu_ramaddr;
            8'h5x: cx4_cpu_datram_addr <= const[op_param[3:0]];
            8'h6x: cx4_cpu_datram_addr <= {gpr[op_param[3:0]*3+2],
                                           gpr[op_param[3:0]*3+1],
                                           gpr[op_param[3:0]*3]};
            default: cx4_cpu_datram_addr <= 24'b0;
          endcase
        end
        OP_BUS: cpu_bus_rq <= 1'b1;
      endcase
    end
    ST_CPU_1: begin
      CPU_STATE <= ST_CPU_2;
      condtrue <= 1'b0;
      case(op)
        OP_JP: begin
          cpu_cache_en <= 1'b0;
          if(!cpu_cache_en && !cx4_busy[BUSY_CACHE]) begin
            jp_docache <= 1'b0;
            if(condtrue) begin
              if(op_call) begin
                cpu_page_stack[cpu_sp] <= cpu_page;
                cpu_pc_stack[cpu_sp] <= cpu_pc + 1;
                cpu_sp <= cpu_sp + 1;
              end
              cpu_pc <= op_param;
              cpu_page <= cpu_page ^ op_p;
            end else cpu_pc <= cpu_pc + 1;
          end
        end
        OP_SKIP: begin
          if(condtrue) cpu_pc <= cpu_pc + 2;
          else cpu_pc <= cpu_pc + 1;
        end
        OP_RT: begin
          cpu_page <= cpu_page_stack[cpu_sp - 1];
          cpu_pc <= cpu_pc_stack[cpu_sp - 1];
          cpu_sp <= cpu_sp - 1;
        end
        OP_WAI: if(BUS_RDY) cpu_pc <= cpu_pc + 1;
        OP_BUS: begin
          cpu_bus_rq <= 1'b0;
          cpu_pc <= cpu_pc + 1;
        end
        default: cpu_pc <= cpu_pc + 1;
      endcase
    end
    ST_CPU_2: begin
      CPU_STATE <= ST_CPU_3;
      case(op)
        OP_LD: begin
          casex(cpu_op[11:8])
            4'b0x00: cpu_a <= cpu_idb;
            4'b0x11: cpu_p <= cpu_idb;
            4'b1100: cpu_p[7:0] <= op_param;
            4'b1101: cpu_p[14:8] <= op_param;
          endcase
        end
        OP_ST, OP_SWP: begin
          casex(op_param)
//            8'h01: cpu_acch <= cpu_idb;
//            8'h02: cpu_accl <= cpu_idb;
            8'h08: cpu_romdata <= cpu_idb;
            8'h0c: cpu_ramdata <= cpu_idb;
            8'h13: cpu_busaddr <= cpu_idb;
            8'h1c: cpu_ramaddr <= cpu_idb;
          endcase
          if(op==OP_SWP) cpu_a <= cpu_tmp;
        end
        OP_RDROM: cpu_romdata <= cx4_datrom_do;
        OP_RDRAM: begin
          case(cpu_op[9:8])
            2'b00: cpu_ramdata[7:0] <= cx4_datram_do;
            2'b01: cpu_ramdata[15:8] <= cx4_datram_do;
            2'b10: cpu_ramdata[23:16] <= cx4_datram_do;
          endcase
        end
        OP_WRRAM: begin
          case(cpu_op[9:8])
            2'b00: cx4_cpu_datram_di <= cpu_ramdata[7:0];
            2'b01: cx4_cpu_datram_di <= cpu_ramdata[15:8];
            2'b10: cx4_cpu_datram_di <= cpu_ramdata[23:16];
          endcase
          cx4_cpu_datram_we <= 1'b1;
        end
        OP_CMP: begin
          case(cpu_op[15:11])
            5'b01001: cpu_alu_res <= cpu_idb - cpu_sa;
            5'b01010: cpu_alu_res <= cpu_sa - cpu_idb;
          endcase
        end
        OP_SEX: begin
          case(cpu_op[9:8])
            2'b01: cpu_alu_res <= {{16{cpu_idb[7]}}, cpu_idb[7:0]};
            2'b10: cpu_alu_res <= {{8{cpu_idb[15]}}, cpu_idb[15:0]};
          endcase
        end
        OP_ALU: begin
          case(cpu_op[15:11])
            5'b10000: cpu_alu_res <= cpu_sa + cpu_idb;
            5'b10001: cpu_alu_res <= cpu_idb - cpu_sa;
            5'b10010: cpu_alu_res <= cpu_sa - cpu_idb;
            5'b10101: cpu_alu_res <= cpu_sa ^ cpu_idb;
            5'b10110: cpu_alu_res <= cpu_sa & cpu_idb;
            5'b10111: cpu_alu_res <= cpu_sa | cpu_idb;
            5'b11000: cpu_alu_res <= cpu_a >> cpu_idb;
            5'b11001: cpu_alu_res <= ($signed(cpu_a)) >>> cpu_idb[4:0];
            5'b11010: cpu_alu_res[23:0] <= {cpu_a, cpu_a} >> cpu_idb[4:0];
            5'b11011: cpu_alu_res <= cpu_a << cpu_idb;
          endcase
        end
      endcase
    end
    ST_CPU_3: begin
      case(op)
        OP_BUS: cpu_busaddr <= cpu_busaddr + 1;
        OP_WRRAM: cx4_cpu_datram_we <= 1'b0;
        OP_CMP: begin
          fl_n <= cpu_alu_res[23];
          fl_z <= cpu_alu_res[23:0] == 24'b0;
          fl_c <= ~cpu_alu_res[24];
        end
        OP_SEX: cpu_a <= cpu_alu_res[23:0];
        OP_ALU: begin
          cpu_a <= cpu_alu_res[23:0];
          case(cpu_op[15:11])
            5'b10000: begin
              fl_n <= cpu_alu_res[23];
              fl_z <= cpu_alu_res[23:0] == 24'b0;
              fl_c <= cpu_alu_res[24];
            end
            5'b10001, 5'b10010: begin
              fl_n <= cpu_alu_res[23];
              fl_z <= cpu_alu_res[23:0] == 24'b0;
              fl_c <= ~cpu_alu_res[24];
            end
            default: begin
              fl_n <= cpu_alu_res[23];
              fl_z <= cpu_alu_res[23:0] == 24'b0;
            end
          endcase
        end
      endcase
      cpu_op <= cpu_op_w;

      casex(cpu_op_w[15:11])
        5'b00100: begin // SKIP
          cpu_wait <= 8'h01;
          CPU_STATE <= speed ? ST_CPU_0 : ST_CPU_4;
        end
        5'b00111: begin // RT
          cpu_wait <= 8'h03;
          CPU_STATE <= speed ? ST_CPU_0 : ST_CPU_4;
        end
        5'b00x01, 5'b00x10: begin // JP
          if(cpu_op_w[13]) begin // CALL
            cpu_wait <= 8'h03;
          end else begin
            cpu_wait <= 8'h03;
          end
          CPU_STATE <= speed ? ST_CPU_0 : ST_CPU_4;
        end
/*        5'b01110, 5'b01101, 5'b11101: begin // RDROM, RDRAM, WRRAM
          cpu_wait <= 8'h03;
          CPU_STATE <= speed ? ST_CPU_0 : ST_CPU_4;
        end
/*        5'b10011: begin // MUL
          cpu_wait <= 8'h03;
          CPU_STATE <= ST_CPU_4;
        end*/
/*        5'b01000: begin // BUSRD
          cpu_wait <= 8'h03;
          CPU_STATE <= ST_CPU_4;
        end*/
        default: begin
          cpu_wait <= 8'h00;
          CPU_STATE <= ST_CPU_0;
        end
      endcase

      casex(cpu_op_w[15:11])
        5'b00000: op <= OP_NOP;

        5'b00x01: op <= OP_JP;
        5'b00x10: op <= OP_JP;
        5'b00100: op <= OP_SKIP;
        5'b00111: op <= OP_RT;

        5'b01100: op <= OP_LD;
        5'b01111: op <= OP_LD;
        5'b11100: op <= OP_ST;
        5'b11110: op <= OP_SWP;

        5'b01110: op <= OP_RDROM;
        5'b01101: op <= OP_RDRAM;
        5'b11101: op <= OP_WRRAM;

        5'b01001: op <= OP_CMP;
        5'b01010: op <= OP_CMP;
        5'b01011: op <= OP_SEX;
        5'b10000: op <= OP_ALU;
        5'b10001: op <= OP_ALU;
        5'b10010: op <= OP_ALU;
        5'b10101: op <= OP_ALU;
        5'b10110: op <= OP_ALU;
        5'b10111: op <= OP_ALU;
        5'b11000: op <= OP_ALU;
        5'b11001: op <= OP_ALU;
        5'b11010: op <= OP_ALU;
        5'b11011: op <= OP_ALU;
        5'b10011: op <= OP_MUL;

        5'b00011: op <= OP_WAI;
        5'b01000: op <= OP_BUS;

        5'b11111: op <= OP_HLT;
      endcase
      op_imm <= cpu_op_w[10];
      op_p <= cpu_op_w[9];
      op_call <= cpu_op_w[13];
      op_param <= cpu_op_w[7:0];
      op_sa <= cpu_op_w[9:8];
    end
    ST_CPU_4: begin
      cpu_wait <= cpu_wait - 1;
      if(cpu_wait) CPU_STATE <= ST_CPU_4;
      else CPU_STATE <= ST_CPU_0;
    end
  endcase
end

reg[2:0] BUSRD_STATE;
parameter ST_BUSRD_IDLE = 3'b001;
parameter ST_BUSRD_WAIT = 3'b010;
parameter ST_BUSRD_END  = 3'b100;
initial BUSRD_STATE = ST_BUSRD_IDLE;
reg cpu_bus_rq2;
always @(posedge CLK) cpu_bus_rq2 <= cpu_bus_rq;

always @(posedge CLK) begin
  if(CPU_STATE == ST_CPU_2
     && (op == OP_ST || op == OP_SWP)
     && op_param == 8'h03)
    cpu_busdata <= cpu_idb;
  else begin
    case(BUSRD_STATE)
      ST_BUSRD_IDLE: begin
        if(cpu_bus_rq2) begin
          BUSRD_STATE <= ST_BUSRD_WAIT;
        end
      end
      ST_BUSRD_WAIT: begin
        if(BUS_RDY) BUSRD_STATE <= ST_BUSRD_END;
        else BUSRD_STATE <= ST_BUSRD_WAIT;
      end
      ST_BUSRD_END: begin
        if(~cpu_busaddr[22]) cpu_busdata <= BUS_DI;
        else cpu_busdata <= 8'h00;
      end
    endcase
  end
end

// gpr write, either by CPU or by MMIO
always @(posedge CLK) begin
  if(CPU_STATE == ST_CPU_2
          && (op == OP_ST || op == OP_SWP)
          && (op_param[7:4] == 4'h6)) begin
    gpr[op_param[3:0]*3+2] <= cpu_idb[23:16];
    gpr[op_param[3:0]*3+1] <= cpu_idb[15:8];
    gpr[op_param[3:0]*3] <= cpu_idb[7:0];
  end
  else if(GPR_WR_EN) gpr[ADDR[5:0]] <= DI;
end

// external multiplier
always @(posedge CLK) begin
  if(mul_strobe) begin
    cpu_mul_a <= cpu_a;
    cpu_mul_b <= cpu_idb;
  end
end

/***************************
 =========== MEM ===========
 ***************************/
`ifdef MK2
cx4_datrom cx4_datrom (
  .clka(CLK), // input clka
  .addra(cx4_datrom_addr), // input [9 : 0] addrb
  .douta(cx4_datrom_do) // output [23 : 0] doutb
);

cx4_datram cx4_datram (
  .clka(CLK), // input clka
  .wea(DATRAM_WR_EN), // input [0 : 0] wea
  .addra(ADDR[11:0]), // input [11 : 0] addra
  .dina(DI), // input [7 : 0] dina
  .douta(DATRAM_DO), // output [7 : 0] douta
  .clkb(CLK), // input clkb
  .web(cx4_datram_we), // input [0 : 0] web
  .addrb(cx4_datram_addr), // input [11 : 0] addrb
  .dinb(cx4_datram_di), // input [7 : 0] dinb
  .doutb(cx4_datram_do) // output [7 : 0] doutb
);

cx4_pgmrom cx4_pgmrom (
  .clka(CLK), // input clka
  .wea(cx4_pgmrom_we), // input [0 : 0] wea
  .addra(cx4_pgmrom_addr), // input [9 : 0] addra
  .dina(BUS_DI), // input [7 : 0] dina
  .clkb(CLK), // input clkb
  .addrb({cpu_page,cpu_pc}), // input [8 : 0] addrb
  .doutb(cpu_op_w) // output [15 : 0] doutb
);

cx4_mul cx4_mul (
  .clk(CLK), // input clk
  .a(cpu_mul_a), // input [23 : 0] a
  .b(cpu_mul_b), // input [23 : 0] b
  .p(cpu_mul_result) // output [47 : 0] p
);
`endif
`ifdef MK3
cx4_datrom cx4_datrom (
  .clock(CLK), // input clka
  .address(cx4_datrom_addr), // input [9 : 0] addrb
  .q(cx4_datrom_do) // output [23 : 0] doutb
);

cx4_datram cx4_datram (
  .clock(CLK), // input clka
  .wren_a(DATRAM_WR_EN), // input [0 : 0] wea
  .address_a(ADDR[11:0]), // input [11 : 0] addra
  .data_a(DI), // input [7 : 0] dina
  .q_a(DATRAM_DO), // output [7 : 0] douta
  .wren_b(cx4_datram_we), // input [0 : 0] web
  .address_b(cx4_datram_addr), // input [11 : 0] addrb
  .data_b(cx4_datram_di), // input [7 : 0] dinb
  .q_b(cx4_datram_do) // output [7 : 0] doutb
);

cx4_pgmrom cx4_pgmrom (
  .clock(CLK), // input clka
  .wren(cx4_pgmrom_we), // input [0 : 0] wea
  .wraddress(cx4_pgmrom_addr), // input [9 : 0] addra
  .data(BUS_DI), // input [7 : 0] dina
  .rdaddress({cpu_page,cpu_pc}), // input [8 : 0] addrb
  .q(cpu_op_w) // output [15 : 0] doutb
);

cx4_mul cx4_mul (
  .clock(CLK), // input clk
  .dataa(cpu_mul_a), // input [23 : 0] a
  .datab(cpu_mul_b), // input [23 : 0] b
  .result(cpu_mul_result) // output [47 : 0] p
);
`endif
endmodule

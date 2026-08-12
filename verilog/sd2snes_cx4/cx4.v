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
  input pause,        // in-game savestate handler: freeze the coprocessor (cache/DMA/CPU
                      // FSMs) so it neither drifts nor contends the bus while the SNES
                      // CPU is frozen in the handler.  Transparent -- state is held,
                      // resumes exactly on release ($202C, driven from main.v).
  input SS_EN,        // savestate scan window active ($E8:00xx, offset = ADDR[7:0])
  input RST,          // SNES reset strobe: drop any pending savestate halt/freeze
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

/* ---------------------------------------------------------------------------
   Savestate window ($E8:00xx) and freeze control.
   Declared up here (before the first use, which is the CPU busy latch below)
   because XST on mk2 requires declaration before use.  The freeze FSM itself
   lives further down, where CPU_STATE/CACHE_ST/DMA_ST are already declared.
   --------------------------------------------------------------------------- */
reg        ss_halt_r;    initial ss_halt_r   = 1'b0;
reg        ss_frozen_r;  initial ss_frozen_r = 1'b0;
reg        ss_dirty_r;   initial ss_dirty_r  = 1'b0;
reg  [7:0] ss_pre_r;     initial ss_pre_r    = 8'h00;    // timeout prescaler
reg [13:0] ss_wait_r;    initial ss_wait_r   = 14'h0000;
reg  [3:0] ss_settle_r;  initial ss_settle_r = 4'h0;
reg  [7:0] ss_ridx_r;    initial ss_ridx_r   = 8'h00;    // $E4 readback index
reg        ss_rd_r;      initial ss_rd_r     = 1'b0;
reg  [7:0] SS_DOr;

// Single CPU-core gate: the pause freezes the core, a requested-but-not-reached
// savestate halt overrides it so a mid-program CX4 can run to its stop point, and
// once frozen the core is held unconditionally.
wire cx4_cpu_en = ~((pause & ~(ss_halt_r & ~ss_frozen_r)) | ss_frozen_r);

wire ss_win     = SS_EN;
wire SS_WR_EN   = ss_win & reg_we_rising;
wire ss_norm    = SS_WR_EN & (ADDR[7:0] == 8'hf0);   // normalize pulse
wire ss_commit  = SS_WR_EN & (ADDR[7:0] == 8'he3);   // commit staged cpu_idb
wire [2:0] ss_cidx = DI[2:0];
wire ss_pcs_wr  = SS_WR_EN & (ADDR[7:3] == 5'b00100);   // $20-$27 pc stack
wire ss_core_wr = SS_WR_EN & ((ADDR[7:0] == 8'h14) | (ADDR[7:0] == 8'h15)
                             |(ADDR[7:0] == 8'h16) | (ADDR[7:0] == 8'he0)
                             |(ADDR[7:0] == 8'he1) | (ADDR[7:0] == 8'he2));
wire ss_core_act = ss_rd_r | ss_norm | ss_commit | ss_pcs_wr | ss_core_wr;

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
reg  [7:0] VECTOR_DOr;
reg  [7:0] GPR_DOr;

assign DO = datram_enable ? DATRAM_DO
            : mmio_enable ? MMIO_DO
            : status_enable ? STATUS_DO
            : vector_enable ? VECTOR_DOr
            : gpr_enable ? GPR_DOr
            // window last: every enable above needs CS (0 in $E8), so this keeps
            // the DATRAM_DO path one mux level shorter.
            : ss_win ? SS_DOr
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

reg [23:0] constrom [15:0];

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
  cachetag[0] = 15'h0000;
  cachetag[1] = 15'h0000;
  cachevalid = 2'b00;
  cx4_busy = 3'b000;
  cx4_mmio_pgmoff = 24'h000000;
  cx4_mmio_pgmpage = 15'h0000;
  cx4_mmio_dmasrc = 24'h000000;
  cx4_mmio_dmalen = 16'h0000;
  cx4_mmio_dmatgt = 24'h000000;
  cx4_mmio_savepage = 2'b00;
  constrom[0] = 24'h000000;
  constrom[1] = 24'hffffff;
  constrom[2] = 24'h00ff00;
  constrom[3] = 24'hff0000;
  constrom[4] = 24'h00ffff;
  constrom[5] = 24'hffff00;
  constrom[6] = 24'h800000;
  constrom[7] = 24'h7fffff;
  constrom[8] = 24'h008000;
  constrom[9] = 24'h007fff;
  constrom[10] = 24'hff7fff;
  constrom[11] = 24'hffff7f;
  constrom[12] = 24'h010000;
  constrom[13] = 24'hfeffff;
  constrom[14] = 24'h000100;
  constrom[15] = 24'h00feff;
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
assign STATUS_DO = {1'b0, cx4_active, 4'b0000, ~cx4_active, 1'b0};
always @(posedge CLK) VECTOR_DOr <= vector[ADDR[4:0]];
always @(posedge CLK) GPR_DOr <= gpr[ADDR[5:0]];

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
    // Window restore, in the else arm on purpose: the clears above are one-shot
    // strobes that must keep firing every non-MMIO clock, and the two write enables
    // are different SNES cycles that never coincide.
    if(SS_WR_EN) begin
      case(ADDR[7:0])
        8'h18: cx4_mmio_cachepage <= DI[0];
        8'h19: cx4_mmio_savepage <= DI[1:0];
      endcase
    end
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
reg [8:0] cache_count;
initial cache_count = 9'b0;

// Not pause-gated: an in-flight fill has to drain, or the cached program is left
// corrupt (caches only refill on a page switch).  With the CPU and the SNES frozen
// nothing kicks a new fill.
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
      cache_count <= 9'b0;
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
  // window $17: invalidate the cache so the restore's native replay refills both
  // pages.  Last in the block so it wins over the chain above.
  if(SS_WR_EN & (ADDR[7:0] == 8'h17)) cachevalid <= DI[1:0];
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
wire [7:0] cx4_datram_di = cx4_busy[BUSY_DMA] ? BUS_DI : cx4_cpu_datram_di[7:0];
reg [15:0] dma_count;
initial dma_count = 16'b0;

// NOT pause-gated: same drain rationale as the cache pipe above.
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
      cx4_dma_datram_addr <= cx4_mmio_dmatgt[11:0];
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

reg [7:0] op_param;
reg [4:0] op;
reg [1:0] op_sa;
reg op_imm;
reg op_p;
reg op_call;
reg op_jump;
reg condtrue;
reg mul_strobe = 0;

// Normalize ($F0): a dirty freeze can leave BUSY_CPU stuck at 1, which saturates
// every busywait the handler does afterwards.
always @(posedge CLK) begin
  if(ss_norm) cx4_busy[BUSY_CPU] <= 1'b0;
  else if(cx4_cpu_en) begin
    if(cpu_go_en_r) cx4_busy[BUSY_CPU] <= 1'b1;
    else if(op == OP_HLT) cx4_busy[BUSY_CPU] <= 1'b0;
  end
end

always @(posedge CLK) if(cx4_cpu_en) begin
  case(op_sa)
    2'b00: cpu_sa <= cpu_a;
    2'b01: cpu_sa <= cpu_a << 1;
    2'b10: cpu_sa <= cpu_a << 8;
    2'b11: cpu_sa <= cpu_a << 16;
  endcase
end

reg jp_docache;
initial jp_docache = 1'b0;

// One write and one read port, both address-muxed with the window, so the
// distributed-RAM inference survives.  Safe because the window only reads while
// frozen, with the native consumer stopped.
wire [2:0] pcs_waddr = ss_pcs_wr ? ADDR[2:0] : cpu_sp;
wire [7:0] pcs_wdata = ss_pcs_wr ? DI        : (cpu_pc + 8'd1);
wire [2:0] pcs_raddr = ss_frozen_r ? ADDR[2:0] : (cpu_sp - 3'd1);
wire [7:0] pcs_rdata = cpu_pc_stack[pcs_raddr];

// Readback mux ($E4), deliberately small: only the 5 registers the handler asks
// for, and NOT a reuse of the native register-file read.  Hoisting that out of the
// clocked body turns the variable-index gpr[]/constrom[] lookups into an
// asynchronous mux worth several hundred LUTs on mk2.  The handler reads gpr and
// constrom through their native space anyway.
wire [23:0] ss_idb_rd = (ss_ridx_r == 8'h00) ? cpu_a
                      : (ss_ridx_r == 8'h08) ? cpu_romdata
                      : (ss_ridx_r == 8'h0c) ? cpu_ramdata
                      : (ss_ridx_r == 8'h13) ? cpu_busaddr
                      : (ss_ridx_r == 8'h1c) ? cpu_ramaddr
                      : 24'b0;

always @(posedge CLK) begin
  if(ss_core_act) begin
    /* ---- savestate window arm: runs while the core is FROZEN, so it has to
       SUPPRESS the native body rather than live inside it (cx4_cpu_en is 0
       there).  Every register touched here is owned by this block. ---- */
    if(ss_rd_r) cpu_idb <= ss_idb_rd;                     // $E4 readback select
    if(ss_pcs_wr) cpu_pc_stack[pcs_waddr] <= pcs_wdata;   // $20-$27
    if(ss_core_wr) begin
      case(ADDR[7:0])
        8'h14: cpu_page_stack <= DI;
        8'h15: cpu_sp <= DI[2:0];
        8'h16: begin fl_n <= DI[0]; fl_z <= DI[1]; fl_c <= DI[2]; end
        8'he0: cpu_idb[7:0] <= DI;                        // staging lanes
        8'he1: cpu_idb[15:8] <= DI;
        8'he2: cpu_idb[23:16] <= DI;
      endcase
    end
    if(ss_commit) begin
      case(ss_cidx)
        3'd0: cpu_a <= cpu_idb;
        3'd1: cpu_romdata <= cpu_idb;
        3'd2: cpu_ramdata <= cpu_idb;
        3'd3: cpu_busaddr <= cpu_idb;
        3'd4: cpu_ramaddr <= cpu_idb;
        default: ;                  // 5 = multiplier latch, owned by the mul block
      endcase
    end
    if(ss_norm) begin
      // park at the canonical boundary: with op != OP_HLT the busy bit sticks,
      // cpu_cache_en kicks spurious fills and cx4_cpu_datram_we rewrites a data
      // RAM byte every clock.
      CPU_STATE <= ST_CPU_IDLE;
      op <= OP_HLT;
      cpu_wait <= 8'h00;
      condtrue <= 1'b0;
      jp_docache <= 1'b0;
      cpu_cache_en <= 1'b0;
      mul_strobe <= 1'b0;
      cpu_bus_rq <= 1'b0;
      cx4_cpu_datram_we <= 1'b0;
    end
  end
  else if(cx4_cpu_en) begin
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
              8'h5x: cpu_idb <= constrom[op_param[3:0]];
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
            8'h5x: cpu_tmp <= constrom[op_param[3:0]];
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
            8'h5x: cx4_cpu_datram_addr <= constrom[op_param[3:0]];
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
                cpu_pc_stack[pcs_waddr] <= pcs_wdata;
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
          cpu_pc <= pcs_rdata;
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
end

reg[2:0] BUSRD_STATE;
parameter ST_BUSRD_IDLE = 3'b001;
parameter ST_BUSRD_WAIT = 3'b010;
parameter ST_BUSRD_END  = 3'b100;
initial BUSRD_STATE = ST_BUSRD_IDLE;
reg cpu_bus_rq2;
always @(posedge CLK) cpu_bus_rq2 <= cpu_bus_rq;

// No savestate arm here: BUSRD_STATE is stuck-at-END by construction (nothing ever
// leaves ST_BUSRD_END), so cpu_busdata is reloaded from BUS_DI on every enabled
// clock and restoring it would be a no-op.  For the same reason BUSRD_STATE is kept
// OUT of the freeze predicate -- including it would stop the freeze from ever
// converging after the game's first OP_BUS.
always @(posedge CLK) if(cx4_cpu_en) begin
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

// gpr write, either by CPU or by MMIO.  The MMIO arm relaxes the gate so the
// savestate restore can write the 48 GPR bytes while frozen -- it uses the NATIVE
// $00:7F80-$7FAF addresses ($E8 does not decode GPR, CS is 0 there), so no second
// write port is needed.
always @(posedge CLK) begin
  if(cx4_cpu_en & CPU_STATE == ST_CPU_2
          && (op == OP_ST || op == OP_SWP)
          && (op_param[7:4] == 4'h6)) begin
    gpr[op_param[3:0]*3+2] <= cpu_idb[23:16];
    gpr[op_param[3:0]*3+1] <= cpu_idb[15:8];
    gpr[op_param[3:0]*3] <= cpu_idb[7:0];
  end
  else if(GPR_WR_EN & (cx4_cpu_en | ss_frozen_r)) gpr[ADDR[5:0]] <= DI;
end

// external multiplier
always @(posedge CLK) begin
  // savestate commit 5 ($E3): this IS the native mul_strobe path, so restoring
  // cpu_mul_a/cpu_mul_b costs enable terms only.
  if(ss_commit & (ss_cidx == 3'd5)) begin
    cpu_mul_a <= cpu_a;
    cpu_mul_b <= cpu_idb;
  end
  else if(cx4_cpu_en) begin
    if(mul_strobe) begin
      cpu_mul_a <= cpu_a;
      cpu_mul_b <= cpu_idb;
    end
  end
end

/***************************
 ======== SAVESTATE ========
 ***************************/
// $E4: latch the readback index and pulse ss_rd_r for one clock; the CPU block
// loads cpu_idb from ss_idb_rd on the next edge, where the SNES then reads it back
// through $00-$02.  The index is the NATIVE op_param encoding (see the handler).
always @(posedge CLK) begin
  ss_rd_r <= 1'b0;
  if(SS_WR_EN & (ADDR[7:0] == 8'he4)) begin
    ss_ridx_r <= DI;
    ss_rd_r <= 1'b1;
  end
end

// Freeze predicate.  Compared with == on purpose: XST/Quartus re-encode FSMs by
// default, so a one-hot bit test would survive compilation while silently meaning
// something else.  BUSRD_STATE is deliberately absent (stuck-at-END, see above).
wire ss_idle_w = ~|cx4_busy
               & (CPU_STATE == ST_CPU_IDLE)
               & (CACHE_ST  == ST_CACHE_IDLE)
               & (DMA_ST    == ST_DMA_IDLE)
               & ~CACHE_TRIG_ENr & ~CACHE_TRIG_EN2r & ~DMA_TRIG_ENr & ~cpu_go_en_r;

// Halt protocol (window $FE bit0, same semantics as the GSU/SA-1 cores): on a halt
// request let the CX4 run to its stop point, then hold it frozen after a 16-cycle
// settle (covers both CACHE_TRIG stages).  A saturating timeout -- prescaler 8 bits
// + counter 14 bits = ~45.9ms @80MHz, split in two short carry chains to help
// placement on the nearly full mk2 -- freezes anyway and latches ss_dirty_r (sticky
// until the next halt request): a dirty capture may lose one in-flight CX4 program.
// ss_frozen_r is monotonic while halted, so the restore's cache replay (which wakes
// CACHE_ST again) does not thaw the core.
always @(posedge CLK) begin
  if(RST) begin
    ss_halt_r <= 1'b0; ss_frozen_r <= 1'b0; ss_dirty_r <= 1'b0;
    ss_pre_r <= 8'h00; ss_wait_r <= 14'h0000; ss_settle_r <= 4'h0;
  end
  else begin
    // halt control write: this block is not pause-gated, so the request lands
    // while the core still runs
    if(SS_WR_EN & (ADDR[7:0] == 8'hfe)) begin
      ss_halt_r <= DI[0];
      if(DI[0]) begin
        ss_dirty_r <= 1'b0; ss_pre_r <= 8'h00; ss_wait_r <= 14'h0000; ss_settle_r <= 4'h0;
      end
    end
    if(~ss_halt_r) begin
      ss_frozen_r <= 1'b0; ss_pre_r <= 8'h00; ss_wait_r <= 14'h0000; ss_settle_r <= 4'h0;
    end else if(~ss_frozen_r) begin
      if(ss_idle_w) begin
        if(&ss_settle_r) ss_frozen_r <= 1'b1;
        else             ss_settle_r <= ss_settle_r + 1'b1;
      end else begin
        ss_settle_r <= 4'h0;
        if(&ss_wait_r[13:11]) begin
          ss_frozen_r <= 1'b1;
          ss_dirty_r <= 1'b1;
        end else begin
          ss_pre_r <= ss_pre_r + 1'b1;
          if(&ss_pre_r) ss_wait_r <= ss_wait_r + 1'b1;
        end
      end
    end
  end
end

// Read the arrays through scalar wires so the window mux never indexes a 2D array
// where XST (mk2) chokes; cpu_pc_stack is NOT unrolled this way -- it goes through
// the single pcs_rdata port to keep its RAM inference.
wire [14:0] ss_ctag0 = cachetag[0];
wire [14:0] ss_ctag1 = cachetag[1];
wire [14:0] ss_pmem0 = cx4_mmio_pagemem[0];
wire [14:0] ss_pmem1 = cx4_mmio_pagemem[1];

// Window read mux.  Registered like MMIO_DOr/VECTOR_DOr/GPR_DOr: SNES_ADDR is
// stable for many CLK cycles before the read strobe, so no new combinational path
// reaches SNES_DATA.  Offsets not listed read $00 and ignore writes.
always @(posedge CLK) begin
  casex(ADDR[7:0])
    8'h00: SS_DOr <= cpu_idb[7:0];        // readback of the register picked by $E4
    8'h01: SS_DOr <= cpu_idb[15:8];
    8'h02: SS_DOr <= cpu_idb[23:16];
    8'h04: SS_DOr <= cpu_mul_a[7:0];
    8'h05: SS_DOr <= cpu_mul_a[15:8];
    8'h06: SS_DOr <= cpu_mul_a[23:16];
    8'h08: SS_DOr <= cpu_mul_b[7:0];
    8'h09: SS_DOr <= cpu_mul_b[15:8];
    8'h0a: SS_DOr <= cpu_mul_b[23:16];
    8'h0c: SS_DOr <= ss_ctag0[7:0];
    8'h0d: SS_DOr <= {1'b0, ss_ctag0[14:8]};
    8'h0e: SS_DOr <= ss_ctag1[7:0];
    8'h0f: SS_DOr <= {1'b0, ss_ctag1[14:8]};
    8'h10: SS_DOr <= ss_pmem0[7:0];
    8'h11: SS_DOr <= {1'b0, ss_pmem0[14:8]};
    8'h12: SS_DOr <= ss_pmem1[7:0];
    8'h13: SS_DOr <= {1'b0, ss_pmem1[14:8]};
    8'h14: SS_DOr <= cpu_page_stack;
    8'h15: SS_DOr <= {5'b0, cpu_sp};
    8'h16: SS_DOr <= {5'b0, fl_c, fl_z, fl_n};
    8'h17: SS_DOr <= {6'b0, cachevalid};
    8'h18: SS_DOr <= {7'b0, cx4_mmio_cachepage};
    8'h19: SS_DOr <= {6'b0, cx4_mmio_savepage};
    // diag: bit4 = dirty capture, bits 3:1 = cx4_busy, bit0 = frozen
    8'h1a: SS_DOr <= {3'b0, ss_dirty_r, cx4_busy[2], cx4_busy[1], cx4_busy[0], ss_frozen_r};
    8'b00100xxx: SS_DOr <= pcs_rdata;     // $20-$27 cpu_pc_stack, single port
    8'hfe: SS_DOr <= {7'b0, ss_frozen_r}; // halt status
    8'hff: SS_DOr <= 8'h5c;               // magic
    default: SS_DOr <= 8'h00;             // incl. the $03/$07/$0B/$1B-$1F pad lanes
  endcase
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

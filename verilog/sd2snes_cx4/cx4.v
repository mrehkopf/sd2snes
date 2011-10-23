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
    input nRD,
    input nWR,
    input CLK,
    input [23:0] DATROM_DI,
    input DATROM_WE,
    input [9:0] DATROM_ADDR,
	 input [7:0] BUS_DI,
	 output [23:0] BUS_ADDR,
	 output BUS_RRQ,
	 input BUS_RDY,
	 output cx4_active
    );

reg [2:0] cx4_busy;
parameter BUSY_CACHE = 2'b00;
parameter BUSY_DMA   = 2'b01;
parameter BUSY_CPU   = 2'b10;

wire datram_enable = CS & (ADDR[11:0] < 12'hc00);
wire mmio_enable = CS & (ADDR[12:5] == 8'b11111010) & (ADDR[4:0] <= 8'b11000);
wire status_enable = CS & (ADDR[12:5] == 8'b11111010) & (ADDR[4:0] > 8'b11000);
wire vector_enable = CS & (ADDR[12:5] == 8'b11111011);
wire gpr_enable = CS & (&(ADDR[12:7]) && ADDR[5:4] != 2'b11);
wire pgmrom_enable = CS & (ADDR[12:5] == 8'b11110000);

wire [7:0] DATRAM_DO;
reg [7:0] MMIO_DOr;
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
reg cx4_mmio_cachepage;
reg [23:0] cx4_mmio_pgmoff;
reg [1:0] cx4_mmio_r1f4c;
reg [14:0] cx4_mmio_pgmpage;
reg [7:0] cx4_mmio_pc;
reg [7:0] cx4_mmio_r1f50;
reg cx4_mmio_r1f51;
reg cx4_mmio_r1f52;
/* 0x1f53 - 0x1f5f: status register */
assign cx4_active = |cx4_busy;
/* 0x1f60 - 0x1f7f: reset vectors */
reg [7:0] vector [31:0];
/* 0x1f80 - 0x1faf (0x1fc0 - 0x1fef): general purpose register file 
   SNES: 8 bits / CX4: 24 bits */
reg [7:0] gpr [47:0];
wire [47:0] cpu_mul_result;

reg [23:0] const [15:0];

reg [15:0] cachetag [1:0]; // 15: valid; 14-0: bank number
initial begin
  cachetag[0] = 16'h0000;
  cachetag[1] = 16'h0000;  
  cx4_busy = 3'b000;
  cx4_mmio_pgmoff = 24'h000000;
  cx4_mmio_pgmpage = 15'h0000;
  cx4_mmio_dmasrc = 24'h000000;
  cx4_mmio_dmalen = 16'h0000;
  cx4_mmio_dmatgt = 24'h000000;
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
end

assign MMIO_DO = MMIO_DOr;
assign VECTOR_DO = vector [ADDR[4:0]];
assign GPR_DO = gpr [ADDR[5:0]];
assign STATUS_DO = {1'b0, cx4_active, 4'b0000, ~cx4_active, 1'b0};

reg [7:0] DIr;
always @(posedge CLK) DIr <= DI;

reg [4:0] datram_enable_sreg;
initial datram_enable_sreg = 5'b11111;
always @(posedge CLK) datram_enable_sreg <= {datram_enable_sreg[3:0], datram_enable};

reg [5:0] nWR_sreg;
always @(posedge CLK) nWR_sreg <= {nWR_sreg[4:0], nWR};
wire WR_EN = (nWR_sreg[5:0] == 6'b000001);
wire DATRAM_WR_EN = datram_enable & WR_EN;
wire MMIO_WR_EN = mmio_enable & WR_EN;
wire VECTOR_WR_EN = vector_enable & WR_EN;
wire GPR_WR_EN = gpr_enable & WR_EN;

reg [23:0] cpu_idb; // tmp register for reg file read

/* Need to cache when:
   1f48 is written
	AND (selected cache page is invalid
	     OR selected cache page does not contain requested page already)
*/
reg CACHE_TRIG_ENr;
reg CACHE_TRIG_EN2r;
initial begin
  CACHE_TRIG_ENr = 1'b0;
  CACHE_TRIG_EN2r = 1'b0;
end
always @(posedge CLK) CACHE_TRIG_EN2r <= CACHE_TRIG_ENr;
wire CACHE_TRIG_EN = CACHE_TRIG_EN2r;

reg DMA_TRIG_ENr;
initial DMA_TRIG_ENr = 1'b0;
wire DMA_TRIG_EN = DMA_TRIG_ENr;

reg CACHE_BUS_RRQr;
reg DMA_BUS_RRQr;
initial begin
  CACHE_BUS_RRQr = 1'b0;
  DMA_BUS_RRQr = 1'b0;
end
assign BUS_RRQ = CACHE_BUS_RRQr | DMA_BUS_RRQr;

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
	 5'h0c: MMIO_DOr <= {6'b0, cx4_mmio_r1f4c};    // 1f4c
	 5'h0d: MMIO_DOr <= cx4_mmio_pgmpage[7:0];  // 1f4d
	 5'h0e: MMIO_DOr <= {1'b0, cx4_mmio_pgmpage[14:8]};   // 1f4e
	 5'h0f: MMIO_DOr <= cx4_mmio_pc;  // 1f4f
	 5'h10: MMIO_DOr <= cx4_mmio_r1f50; // 1f50
    5'h11: MMIO_DOr <= {7'b0, cx4_mmio_r1f51};      // 1f51
	 5'h12: MMIO_DOr <= {7'b0, cx4_mmio_r1f52};      // 1f52    
	 
	 5'h13: MMIO_DOr <= cpu_mul_result[47:40];   // 1f40
	 5'h14: MMIO_DOr <= cpu_mul_result[39:32];   // 1f40
	 5'h15: MMIO_DOr <= cpu_mul_result[31:24];   // 1f40
	 5'h16: MMIO_DOr <= cpu_mul_result[23:16];   // 1f40
	 5'h17: MMIO_DOr <= cpu_mul_result[15:8];   // 1f40
	 5'h18: MMIO_DOr <= cpu_mul_result[7:0];   // 1f40

	 
//	 5'h14: MMIO_DOr <= cachetag[0][15:8];   // 1f40
//	 5'h15: MMIO_DOr <= cachetag[0][7:0];  // 1f41
//	 5'h16: MMIO_DOr <= cachetag[1][15:8]; // 1f42
//	 5'h17: MMIO_DOr <= cachetag[1][7:0];   // 1f43
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
	   5'h0c: cx4_mmio_r1f4c <= DI[1:0];    // 1f4c
	   5'h0d: cx4_mmio_pgmpage[7:0] <= DI;  // 1f4d
	   5'h0e: cx4_mmio_pgmpage[14:8] <= DI[6:0];   // 1f4e
	   5'h0f: cx4_mmio_pc <= DI;  // 1f4f
	   5'h10: cx4_mmio_r1f50 <= DI & 8'h77; // 1f50
	   5'h11: cx4_mmio_r1f51 <= DI[0];      // 1f51
	   5'h12: cx4_mmio_r1f52 <= DI[0];      // 1f52
	 endcase
  end else begin
    CACHE_TRIG_ENr <= 1'b0;
	 DMA_TRIG_ENr <= 1'b0;
  end
end
  
always @(posedge CLK) begin
  if(VECTOR_WR_EN) vector[ADDR[4:0]] <= DI;
end

always @(posedge CLK) begin
  if(GPR_WR_EN) gpr[ADDR[5:0]] <= DI;
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

assign BUS_ADDR =  cx4_busy[BUSY_CACHE] ? MAPPED_CACHE_SRC_ADDR
                 : cx4_busy[BUSY_DMA] ? MAPPED_DMA_SRC_ADDR
					  : 24'h000000 /* XXX cx4_bus_addr */;

reg cx4_pgmrom_we;
initial cx4_pgmrom_we = 1'b0;
reg [9:0] cx4_pgmrom_addr;
reg [19:0] cache_count;
initial cache_count = 20'b0;

always @(posedge CLK) begin
  case(CACHE_ST)
	 ST_CACHE_IDLE: begin
	   if(CACHE_TRIG_EN 
		   & (~cachetag[cx4_mmio_cachepage][15]
             | |(cachetag[cx4_mmio_cachepage][14:0] ^ cx4_mmio_pgmpage)))
      begin
		  CACHE_ST <= ST_CACHE_START;
	   end else CACHE_ST <= ST_CACHE_IDLE;
	 end
	 ST_CACHE_START: begin
		cx4_busy[BUSY_CACHE] <= 1'b1;
		CACHE_SRC_ADDRr <= cx4_mmio_pgmoff + {cx4_mmio_pgmpage, 9'b0};
		cx4_pgmrom_addr <= {cx4_mmio_cachepage, 9'b0};
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
		  cachetag[cx4_mmio_cachepage] <= {1'b1,cx4_mmio_pgmpage};
		  CACHE_ST <= ST_CACHE_IDLE;
	   end else begin
		  CACHE_BUS_RRQr <= 1'b1;
		  CACHE_ST <= ST_CACHE_WAIT;
	   end
	 end
  endcase
end

reg cx4_datram_we;
initial cx4_datram_we = 1'b0;
reg [11:0] cx4_datram_addr;
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
 /* XXX Rename to DMA_TGT_ADDRr and switch */
      cx4_datram_addr <= (cx4_mmio_dmatgt & 24'h000fff);
		DMA_ST <= ST_DMA_WAIT;
		dma_count <= cx4_mmio_dmalen;
      DMA_BUS_RRQr <= 1'b1;
	 end
	 ST_DMA_WAIT: begin
	   DMA_BUS_RRQr <= 1'b0;
	   if(~DMA_BUS_RRQr & BUS_RDY) begin
		  DMA_ST <= ST_DMA_ADDR;
 /* XXX Rename to DMA_TGT_WEr and switch */
		  cx4_datram_we <= 1'b1;
		  dma_count <= dma_count - 1;
	   end else DMA_ST <= ST_DMA_WAIT;
	 end
	 ST_DMA_ADDR: begin
 /* XXX Rename to DMA_TGT_WEr and switch */
	   cx4_datram_we <= 1'b0;
	   DMA_SRC_ADDRr <= DMA_SRC_ADDRr + 1;
	   cx4_datram_addr <= cx4_datram_addr + 1;
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
reg [7:0] CPU_STATE;
reg cpu_page;
reg [7:0] cpu_pc;
reg [8:0] cpu_stack [7:0];
reg [2:0] cpu_sp;
wire [15:0] cpu_op_w;
reg [15:0] cpu_op;
reg [23:0] cpu_a;
reg [23:0] cpu_busdata;
reg [23:0] cpu_romdata;
reg [23:0] cpu_ramdata;
reg [23:0] cpu_busaddr;
reg [23:0] cpu_romaddr;
reg [23:0] cpu_ramaddr;
reg [23:0] cpu_acch;
reg [23:0] cpu_accl;
reg [23:0] cpu_mul_src;

reg [23:0] cpu_sa;  // tmp register for shifted accumulator
reg fl_n;
reg fl_z;
reg fl_c;
reg [15:0] cpu_p;

reg [9:0] cx4_datrom_addr;
wire [23:0] cx4_datrom_do;
wire [7:0] cx4_datram_do;

parameter ST_CPU_IDLE = 8'b00000001;
parameter ST_CPU_0    = 8'b00000010;
parameter ST_CPU_1    = 8'b00000100;
parameter ST_CPU_2    = 8'b00001000;
parameter ST_CPU_3    = 8'b00010000;

initial CPU_STATE <= ST_CPU_IDLE;

parameter OP_ALU = 4'b0000;
parameter OP_LD  = 4'b0001;
parameter OP_ST  = 4'b0010;
parameter OP_JP  = 4'b0011;
parameter OP_SWP = 4'b0100;
parameter OP_HLT = 4'b0101;
parameter OP_BUS = 4'b0110;
parameter OP_STA = 4'b0111;
parameter OP_NOP = 4'b1111;


wire [6:0] op_id = cpu_op_w[15:10];
reg [7:0] op_param;
reg [2:0] op;
reg [1:0] op_sa;
reg op_imm;
reg op_p;
reg op_call;
reg op_jump;
reg cond_true;
reg cpu_go_rq;
reg cpu_bus_rq;

always @(posedge CLK) begin
  case(CPU_STATE)
    ST_CPU_IDLE: begin
	   if(cpu_go_rq) begin
		  cpu_pc <= cx4_mmio_pc;
		  op <= OP_NOP;
		  CPU_STATE <= ST_CPU_2;
		end
		else CPU_STATE <= ST_CPU_IDLE;
	 end
	 ST_CPU_0: begin // Phase 0: 
      CPU_STATE <= ST_CPU_1;
      case(op)
		  OP_ALU, OP_LD, OP_SWP: begin
		    if(cpu_op[15:10] == 6'b111000) cpu_idb <= cpu_a; // reg[imm] <- a
			 else if(op_imm) cpu_idb <= {16'b0, op_param};
		    else casex(op_param)
			   8'h00: cpu_idb <= cpu_a;
				8'h01: cpu_idb <= cpu_acch;
				8'h02: cpu_idb <= cpu_accl;
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
			 if(op==OP_ALU) begin
			   case(op_sa)
				  2'b00: cpu_sa <= cpu_a;
				  2'b01: cpu_sa <= cpu_a << 1;
				  2'b10: cpu_sa <= cpu_a << 8;
				  2'b11: cpu_sa <= cpu_a << 16;
				endcase
			 end
		  end
		  OP_JP: begin
		    casex(cpu_op[12:8])
			   5'b010xx: cond_true <= 1'b1;
				5'b011xx: cond_true <= fl_z;
				5'b100xx: cond_true <= fl_c;
				5'b101xx: cond_true <= fl_n;
				5'b00101: cond_true <= (fl_c == cpu_op[0]);
				5'b00110: cond_true <= (fl_z == cpu_op[0]);
				5'b00111: cond_true <= (fl_n == cpu_op[0]);
				default: cond_true <= 1'b1;
			 endcase
		  end
		  OP_BUS: cpu_bus_rq <= 1'b1;
		endcase
	 end
	 ST_CPU_1: begin
	   CPU_STATE <= ST_CPU_2;
	   case(op)
		  OP_LD: begin
          cx4_datram_addr <= op_imm ? op_param : (cpu_ramaddr + cpu_idb);
			 cx4_datrom_addr <= cpu_a[9:0];
		  end
		  OP_ST: begin
		    cx4_datram_addr <= op_imm ? op_param : (cpu_ramaddr + cpu_idb);
			 cx4_datram_we <= 1'b1;
		  end
		  OP_JP: begin
		    if(cond_true) begin
			   casex(cpu_op[12:11])
				  2'b01, 2'b10: begin
				    // TODO if(op_p)
					 if(op_call) begin
					   cpu_stack[cpu_sp] <= {cpu_page, cpu_pc+1};
						cpu_sp <= cpu_sp - 1;
					 end
					 cpu_pc <= op_param;
              end
				  2'b00: begin
				    cpu_pc <= cpu_pc + 2;
				  end
				  2'b11: begin
				    if(cpu_op[13]) begin
				      {cpu_page, cpu_pc} <= cpu_stack[cpu_sp+1];
					   cpu_sp <= cpu_sp + 1;
				    end else begin
					   if(BUS_RDY) cpu_pc <= cpu_pc + 1;
					 end
				  end
				  default: cpu_pc <= cpu_pc + 1;
				endcase
			 end
		  end
  		  OP_BUS: cpu_bus_rq <= 1'b0;
		endcase
	 end
	 ST_CPU_2: begin
      CPU_STATE <= ST_CPU_3;
	   case(op)
		  OP_ST: begin
			 cx4_datram_we <= 1'b0;
		  end
		endcase
	 end
	 ST_CPU_3: begin
      CPU_STATE <= ST_CPU_0;
	   case(op)
		  OP_LD, OP_SWP: begin
		    casex(cpu_op[15:8])
				8'b01100x00: cpu_a <= cpu_idb;
				8'b01100x11: cpu_p <= cpu_idb;
				8'b01111100: cpu_p[7:0] <= op_param;
				8'b01111101: cpu_p[15:8] <= op_param;
				8'b01110000: cpu_romdata <= cx4_datrom_do;
				8'b01101x00: cpu_ramdata[7:0] <= cx4_datram_do;
				8'b01101x01: cpu_ramdata[15:8] <= cx4_datram_do;
				8'b01101x10: cpu_ramdata[23:16] <= cx4_datram_do;
				8'b11110000, 8'b11100000: begin
				  if(cpu_op[12]) cpu_a <= cpu_idb;
				  casex(op_param)
			       8'h00: cpu_a <= cpu_a;
				    8'h01: cpu_acch <= cpu_a;
				    8'h02: cpu_accl <= cpu_a;
				    8'h03: cpu_busdata <= cpu_a;
				    8'h08: cpu_romdata <= cpu_a;
				    8'h0c: cpu_ramdata <= cpu_a;
				    8'h13: cpu_busaddr <= cpu_a;
				    8'h1c: cpu_ramaddr <= cpu_a;
				    8'h6x: {gpr[op_param[3:0]*3+2],
				            gpr[op_param[3:0]*3+1],
								gpr[op_param[3:0]*3]} <= cpu_a;
				  endcase
				end
			 endcase
		  end
		endcase
	   cpu_op <= cpu_op_w;
      op_param <= cpu_op_w[7:0];
      op <= &(op_id) ? OP_HLT
          :(op_id[5:4] == 2'b00) ? OP_JP
			 :(op_id[5:2] == 4'b0110
			   || op_id[5:2] == 4'b0111				
			  ) ? OP_LD
			 :(op_id[5:1] == 5'b11101) ? OP_ST
			 :(op_id[5:1] == 5'b01000) ? OP_BUS
			 :(op_id[5:3] == 3'b010
			   || op_id[5:3] == 3'b100
				|| op_id[5:3] == 3'b101
				|| op_id[5:3] == 3'b110) ? OP_ALU
			 : (op_id == 6'b111100 || op_id == 6'b111000) ? OP_SWP
			 : OP_NOP;
	   op_imm <= cpu_op_w[10];
		op_sa <= cpu_op_w[9:8];
		op_p <= cpu_op_w[9];
		op_call <= cpu_op_w[13];
		cond_true <= 1'b0;
	 end
  endcase
end


/***************************
 =========== MEM ===========
 ***************************/
cx4_datrom cx4_datrom (
  .clka(CLK), // input clka
  .wea(DATROM_WE), // input [0 : 0] wea
  .addra(DATROM_ADDR), // input [9 : 0] addra
  .dina(DATROM_DI), // input [23 : 0] dina
  .clkb(CLK), // input clkb
  .addrb(cx4_datrom_addr), // input [9 : 0] addrb
  .doutb(cx4_datrom_do) // output [23 : 0] doutb
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
  .dinb(BUS_DI), // input [7 : 0] dinb
  .doutb(cx4_datram_do) // output [7 : 0] doutb
);

cx4_pgmrom cx4_pgmrom (
  .clka(CLK), // input clka
  .wea(cx4_pgmrom_we), // input [0 : 0] wea
  .addra(cx4_pgmrom_addr), // input [9 : 0] addra
  .dina(BUS_DI), // input [7 : 0] dina
  .clkb(CLK), // input clkb
  .addrb(cpu_pc), // input [8 : 0] addrb
  .doutb(cpu_op_w) // output [15 : 0] doutb
);

cx4_mul cx4_mul (
  .clk(CLK), // input clk
  .a(cpu_a), // input [23 : 0] a
  .b(cpu_mul_src), // input [23 : 0] b
  .p(cpu_mul_result) // output [47 : 0] p
);
endmodule

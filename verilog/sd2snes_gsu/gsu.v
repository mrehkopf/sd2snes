`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    06:32:24 02/24/2018 
// Design Name: 
// Module Name:    gsu 
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
module gsu(
  input         RST,
  input         CLK,
  
  // MMIO interface
  input         ENABLE,
  input         SNES_RD_start,
  input         SNES_WR_start,
  input         SNES_WR_end,
  input  [23:0] SNES_ADDR,
  input  [7:0]  DATA_IN,
  output        DATA_ENABLE,
  output [7:0]  DATA_OUT,
  
  // RAM interface
  input         ROM_BUS_RDY,
  output        ROM_BUS_RRQ,
  output        ROM_BUS_WRQ,
  output [23:0] ROM_BUS_ADDR,
  input  [7:0]  ROM_BUS_RDDATA,
  output [7:0]  ROM_BUS_WRDATA,
  
  // ACTIVE interface
  output        ACTIVE,
  
  // State debug read interface
  input  [9:0]  PGM_ADDR, // [9:0]
  output [7:0]  PGM_DATA, // [7:0]

  // config interface
  input [7:0] reg_group_in,
  input [7:0] reg_index_in,
  input [7:0] reg_value_in,
  input [7:0] reg_invmask_in,
  input       reg_we_in,
  input [7:0] reg_read_in,
  output[7:0] config_data_out,
  // config interface

  output DBG
);

// temporaries
integer i;
wire pipeline_advance;

//-------------------------------------------------------------------
// INPUTS
//-------------------------------------------------------------------
reg [7:0] data_in_r;
reg [23:0] addr_in_r;

always @(posedge CLK) begin
  data_in_r <= DATA_IN;
  addr_in_r <= SNES_ADDR;
end

//-------------------------------------------------------------------
// PARAMETERS
//-------------------------------------------------------------------
parameter NUM_GPR = 16;

parameter
  R0    = 8'h00,
  R1    = 8'h01,
  R2    = 8'h02,
  R3    = 8'h03,
  R4    = 8'h04,
  R5    = 8'h05,
  R6    = 8'h06,
  R7    = 8'h07,
  R8    = 8'h08,
  R9    = 8'h09,
  R10   = 8'h0A,
  R11   = 8'h0B,
  R12   = 8'h0C,
  R13   = 8'h0D,
  R14   = 8'h0E,
  R15   = 8'h0F
  ;

parameter
  ADDR_R0    = 8'h00,
  ADDR_R1    = 8'h02,
  ADDR_R2    = 8'h04,
  ADDR_R3    = 8'h06,
  ADDR_R4    = 8'h08,
  ADDR_R5    = 8'h0A,
  ADDR_R6    = 8'h0C,
  ADDR_R7    = 8'h0E,
  ADDR_R8    = 8'h10,
  ADDR_R9    = 8'h12,
  ADDR_R10   = 8'h14,
  ADDR_R11   = 8'h16,
  ADDR_R12   = 8'h18,
  ADDR_R13   = 8'h1A,
  ADDR_R14   = 8'h1C,
  ADDR_R15   = 8'h1E,
  ADDR_GPRL  = 8'b000x_xxx0,
  ADDR_GPRH  = 8'b000x_xxx1,
  
  ADDR_SFR   = 8'h30,
  ADDR_BRAMR = 8'h33,
  ADDR_PBR   = 8'h34,
  ADDR_ROMBR = 8'h35,
  ADDR_CFGR  = 8'h37,
  ADDR_SCBR  = 8'h38,
  ADDR_CLSR  = 8'h39,
  ADDR_SCMR  = 8'h3A,
  ADDR_VCR   = 8'h3B,
  ADDR_RAMBR = 8'h3C,
  ADDR_CBR   = 8'h3E,
  
  ADDR_CACHE_BASE = 10'h100
  ;

// instructions
parameter
  OP_STOP          = 8'h00,
  OP_NOP           = 8'h01,
  OP_CACHE         = 8'h02,
  
  // bra (no reset state)
  OP_BRA           = 8'h05,
  OP_BGE           = 8'h06,
  OP_BLT           = 8'h07,
  OP_BNE           = 8'h08,
  OP_BEQ           = 8'h09,
  OP_BPL           = 8'h0A,
  OP_BMI           = 8'h0B,
  OP_BCC           = 8'h0C,
  OP_BCS           = 8'h0D,
  OP_BVC           = 8'h0E,
  OP_BVS           = 8'h0F,
  // jmps/loops
  OP_LINK_JMP_LJMP = 8'h9x,
  OP_LOOP          = 8'h3C,
  
  // prefix (also see branch) no reset state
  OP_ALT1          = 8'h3D,
  OP_ALT2          = 8'h3E,
  OP_ALT3          = 8'h3F,
  OP_TO            = 8'h1x,
  OP_WITH          = 8'h2x,
  OP_FROM          = 8'hBx,
  
  // MOV
  // MOVE/MOVES use WITH/TO and WITH/FROM
  OP_IBT           = 8'hAx,
  OP_IWT           = 8'hFx, // LEA
  // load from ROM
  OP_GETB          = 8'hEF,
  // load from RAM
  OP_LD            = 8'h4x, // 4 opcodes
  OP_ST            = 8'h3x, // 4 opcodes
  OP_SBK           = 8'h90,
  OP_GETC_RAMB_ROMB= 8'hDF,
  
  // BITMAP
  OP_CMODE_COLOR   = 8'h4E,
  OP_PLOT_RPIX     = 8'h4C,
  
  // ALU
  OP_ADD           = 8'h5x,
  OP_SUB           = 8'h6x,
  OP_AND_BIC       = 8'h7x,
  OP_OR_XOR        = 8'hCx,
  OP_NOT           = 8'h4F,
  
  // ROTATE/SHIFT/INC/DEC
  OP_LSR           = 8'h03,
  OP_ASR_DIV2      = 8'h96,
  OP_ROL           = 8'h04,
  OP_ROR           = 8'h97,
  OP_INC           = 8'hDx,
  OP_DEC           = 8'hEx,
  
  // BYTE
  OP_SWAP          = 8'h4D,
  OP_SEX           = 8'h95,
  OP_LOB           = 8'h9E,
  OP_HIB           = 8'hC0,
  OP_MERGE         = 8'h70,
  
  // MULTIPLY
  OP_FMULT_LMULT   = 8'h9F,
  OP_MULT_MULT     = 8'h8x
  
  ;

//-------------------------------------------------------------------
// CONFIG
//-------------------------------------------------------------------

parameter CONFIG_REGISTERS = 2;
reg [7:0] config_r[CONFIG_REGISTERS-1:0]; initial for (i = 0; i < CONFIG_REGISTERS; i = i + 1) config_r[i] = 8'h00;

always @(posedge CLK) begin
  if (RST) begin
    for (i = 0; i < CONFIG_REGISTERS; i = i + 1) config_r[i] <= 8'h00;
  end
  else if (reg_we_in && (reg_group_in == 8'h03)) begin
    if (reg_index_in < CONFIG_REGISTERS) config_r[reg_index_in] <= (config_r[reg_index_in] & reg_invmask_in) | (reg_value_in & ~reg_invmask_in);
  end
end

assign config_data_out = config_r[reg_read_in];

wire       CONFIG_STEP_ENABLED = config_r[0][0] | 1'b1; // FIXME: temporary enable
wire [7:0] CONFIG_STEP_COUNT   = config_r[1];

//-------------------------------------------------------------------
// FLOPS
//-------------------------------------------------------------------
reg cache_rom_rd_r; initial cache_rom_rd_r = 0;
reg gsu_rom_rd_r; initial gsu_rom_rd_r = 0;
reg gsu_ram_rd_r; initial gsu_ram_rd_r = 0;
reg gsu_ram_wr_r; initial gsu_ram_wr_r = 0;

reg [23:0] cache_rom_addr_r;
reg [23:0] data_rom_addr_r;

reg [1:0] gsu_cycle_r; initial gsu_cycle_r = 0;

always @(posedge CLK) gsu_cycle_r <= gsu_cycle_r + 1;

// Assert clock enable every 4 FPGA clocks.  Delays are calculated in
// terms of GSU clocks so this is used to align transitions and
// operate counters.
assign gsu_clock_en = &gsu_cycle_r;

//-------------------------------------------------------------------
// STATE
//-------------------------------------------------------------------
reg [15:0] REG_r   [15:0];

// Special Registers
reg [15:0] SFR_r;   // 3030-3031
reg [7:0]  BRAMR_r; // 3033
reg [7:0]  PBR_r;   // 3034
reg [7:0]  ROMBR_r; // 3036
reg [7:0]  CFGR_r;  // 3037
reg [7:0]  SCBR_r;  // 3038
reg [7:0]  CLSR_r;  // 3039
reg [7:0]  SCMR_r;  // 303A
reg [7:0]  VCR_r;   // 303B
reg [7:0]  RAMBR_r; // 303C
reg [15:0] CBR_r;   // 303E
// unmapped
reg [7:0]  COLR_r;
reg [7:0]  POR_r;
reg [7:0]  SREG_r;
reg [7:0]  DREG_r;
reg [7:0]  ROMRDBUF_r;
reg [7:0]  RAMWRBUF_r;
reg [15:0] RAMADDR_r;

// Important breakouts
assign SFR_Z    = SFR_r[1];
assign SFR_CY   = SFR_r[2];
assign SFR_S    = SFR_r[3];
assign SFR_OV   = SFR_r[4];
assign SFR_GO   = SFR_r[5];
assign SFR_RR   = SFR_r[6];
assign SFR_ALT1 = SFR_r[8];
assign SFR_ALT2 = SFR_r[9];
assign SFR_IL   = SFR_r[10];
assign SFR_IH   = SFR_r[11];
assign SFR_B    = SFR_r[12];
assign SFR_IRQ  = SFR_r[15];

assign BRAMR_EN = BRAMR_r[0];

assign CFGR_MS0 = CFGR_r[5];
assign CFGR_IRQ = CFGR_r[7];

assign CLSR_CLS = CLSR_r[0];

wire [1:0] SCMR_MD; assign SCMR_MD = SCMR_r[1:0];
wire [1:0] SCMR_HT; assign SCMR_HT = {SCMR_r[5],SCMR_r[2]};
assign SCMR_RAN = SCMR_r[3];
assign SCMR_RON = SCMR_r[4];

assign POR_TRS  = POR_r[0];
assign POR_DTH  = POR_r[1];
assign POR_HN   = POR_r[2];
assign POR_FNB  = POR_r[3];
assign POR_OBJ  = POR_r[4];

//-------------------------------------------------------------------
// PIPELINE IO
//-------------------------------------------------------------------
// Fetch -> Execute
// The fetch pipe and execution pipe are synchronized via the opbuf.
// Fetch operates one byte ahead of execution.
reg [7:0]  i2e_op_r[1:0]; initial for (i = 0; i < 2; i = i + 1) i2e_op_r[i] = OP_NOP;
reg        i2e_ptr_r; initial i2e_ptr_r = 0;

// Execute -> RegisterFile
reg        e2r_val_r;
reg        e2r_dreg_r;
reg [7:0]  e2r_data_r;

// Fetch -> Common
reg        i2c_waitcnt_val_r; initial i2c_waitcnt_val_r = 0;
reg        i2c_waitcnt_r;

// Execute -> Common
reg        e2c_waitcnt_val_r; initial e2c_waitcnt_val_r = 0;
reg        e2c_waitcnt_r;

//-------------------------------------------------------------------
// FIXME: Pixel Buffer
//-------------------------------------------------------------------

//-------------------------------------------------------------------
// Cache
//-------------------------------------------------------------------
// GSU/SNES interface
reg        cache_mmio_wren_r; initial cache_mmio_wren_r = 0;
reg  [7:0] cache_mmio_wrdata_r;
reg  [8:0] cache_mmio_addr_r;

reg        cache_gsu_wren_r; initial cache_gsu_wren_r = 0;
reg  [7:0] cache_gsu_wrdata_r;
reg  [8:0] cache_gsu_addr_r;

wire       cache_wren;
wire [8:0] cache_addr;
wire [7:0] cache_wrdata;
wire [7:0] cache_rddata;
// 
wire       debug_cache_wren;
wire [8:0] debug_cache_addr;
wire [7:0] debug_cache_wrdata;
wire [7:0] debug_cache_rddata;

assign cache_wren   = SFR_GO ? cache_gsu_wren_r   : cache_mmio_wren_r;
assign cache_addr   = SFR_GO ? cache_gsu_addr_r   : cache_mmio_addr_r;
assign cache_wrdata = SFR_GO ? cache_gsu_wrdata_r : cache_mmio_wrdata_r;

assign debug_cache_wren = 0;
assign debug_cache_addr = {~PGM_ADDR[8],PGM_ADDR[7:0]};

// valid bits
reg [31:0] cache_val_r; initial cache_val_r = 0;

gsu_cache cache (
  .clka(CLK), // input clka
  .wea(cache_wren), // input [0 : 0] wea
  .addra(cache_addr), // input [8 : 0] addra
  .dina(cache_wrdata), // input [7 : 0] dina
  .douta(cache_rddata), // output [7 : 0] douta
  
  .clkb(CLK), // input clkb
  .web(debug_cache_wren), // input [0 : 0] web
  .addrb(debug_cache_addr), // input [8 : 0] addrb
  .dinb(debug_cache_wrdata), // input [7 : 0] dinb
  .doutb(debug_cache_rddata) // output [7 : 0] doutb
);

//-------------------------------------------------------------------
// REGISTER/MMIO ACCESS
//-------------------------------------------------------------------
// This handles all state read and write.  The main execution pipeline
// feeds intermediate results back here.
reg        data_enable_r;
reg [7:0]  data_out_r;
reg [7:0]  data_flop_r;

always @(posedge CLK) begin
  if (RST) begin
    for (i = 0; i < NUM_GPR; i = i + 1) begin
      REG_r[i] <= 0;
    end
    
    SFR_r   <= 0;
    BRAMR_r <= 0;
    PBR_r   <= 0;
    ROMBR_r <= 0;
    CFGR_r  <= 0;
    SCBR_r  <= 0;
    CLSR_r  <= 0;
    SCMR_r  <= 0;
    VCR_r   <= 4;
    RAMBR_r <= 0;
    
    COLR_r  <= 0;
    POR_r   <= 0;
    SREG_r  <= 0;
    DREG_r  <= 0;
    
    ROMRDBUF_r <= 0;
    RAMWRBUF_r <= 0;
    RAMADDR_r  <= 0;
    
    data_enable_r <= 0;
    data_flop_r <= 0;
    cache_mmio_wren_r <= 0;
  end
  else begin
    // True data enable.  This assumes we need unmapped read addresses to be openbus.
    if (ENABLE) begin
      if (SNES_RD_start) begin
        if (~|addr_in_r[9:8]) begin
          casex (addr_in_r[7:0])
            ADDR_GPRL : if (~SFR_GO) data_enable_r <= 1;
            ADDR_GPRH : if (~SFR_GO) data_enable_r <= 1;
          
            ADDR_SFR  : data_enable_r <= 1;
            ADDR_SFR+1: data_enable_r <= 1;
            //ADDR_BRAMR: begin data_enable_r <= 1; data_out_r <= BRAMR_r; end
            ADDR_PBR  : if (~SFR_GO) data_enable_r <= 1;
            ADDR_ROMBR: if (~SFR_GO) data_enable_r <= 1;
            //ADDR_CFGR : begin data_enable_r <= 1; data_out_r <= CFGR_r; end
            //ADDR_SCBR : begin data_enable_r <= 1; data_out_r <= SCBR_r; end
            //ADDR_CLSR : begin data_enable_r <= 1; data_out_r <= CLSR_r; end
            //ADDR_SCMR : begin data_enable_r <= 1; data_out_r <= SCMR_r; end
            ADDR_VCR  : data_enable_r <= 1;
            ADDR_RAMBR: if (~SFR_GO) data_enable_r <= 1;
            ADDR_CBR+0: if (~SFR_GO) data_enable_r <= 1;
            ADDR_CBR+1: if (~SFR_GO) data_enable_r <= 1;
          endcase
        end
        else begin
          data_enable_r <= 1;
        end
      end
    end
    else begin
      data_enable_r <= 0;
    end
  
    if (SFR_GO) begin
      // TODO: figure out how to deal with conflicts between SFX and SNES.
      // handle GSU register writes
      if (pipeline_advance) begin
        // branches either only write R15 or cause an increment
        if (e2r_val_r) begin
          if (e2r_dreg_r == R15) begin
            REG_r[e2r_dreg_r] <= e2r_data_r;
          end
          else begin
            REG_r[e2r_dreg_r] <= e2r_data_r;
            REG_r[R15] <= REG_r[R15] + 1;
          end
        end
        else begin
          REG_r[R15] <= REG_r[R15] + 1;
        end
      end
      
      // handle the select set of R and W registers the snes has access to.
      if (SNES_WR_end & ENABLE & ({addr_in_r[9:1],1'b0} == ADDR_SFR || addr_in_r[9:0] == ADDR_SCMR)) begin
        // FIXME: need to handle conflicts with GSU writes to these registers.
        casex (addr_in_r[7:0])
          ADDR_SFR  : SFR_r[6:1] <= data_in_r[6:1];
          ADDR_SFR+1: {SFR_r[15],SFR_r[12:8]} <= {data_in_r[7],data_in_r[4:0]};
          ADDR_SCMR : SCMR_r[5:0] <= data_in_r[5:0];
        endcase
      end
      else if (SNES_RD_start & ENABLE) begin
        casex (addr_in_r[7:0])
          ADDR_SFR  : data_out_r <= SFR_r[7:0];
          ADDR_SFR+1: data_out_r <= SFR_r[15:8];
          ADDR_VCR  : data_out_r <= VCR_r;
        endcase
      end
      
    end
    else if (ENABLE) begin
      if (SNES_RD_start) begin
        if (~|addr_in_r[9:8]) begin
          casex (addr_in_r[7:0])
            ADDR_GPRL : data_out_r <= REG_r[addr_in_r[4:1]][7:0];
            ADDR_GPRH : data_out_r <= REG_r[addr_in_r[4:1]][15:8];
          
            ADDR_SFR  : data_out_r <= SFR_r[7:0];
            ADDR_SFR+1: data_out_r <= SFR_r[15:8];
            //ADDR_BRAMR: data_out_r <= BRAMR_r;
            ADDR_PBR  : data_out_r <= PBR_r;
            ADDR_ROMBR: data_out_r <= ROMBR_r;
            //ADDR_CFGR : data_out_r <= CFGR_r;
            //ADDR_SCBR : data_out_r <= SCBR_r;
            //ADDR_CLSR : data_out_r <= CLSR_r;
            //ADDR_SCMR : data_out_r <= SCMR_r;
            ADDR_VCR  : data_out_r <= VCR_r;
            ADDR_RAMBR: data_out_r <= RAMBR_r;
            ADDR_CBR+0: data_out_r <= CBR_r[7:0];
            ADDR_CBR+1: data_out_r <= CBR_r[15:8];
          endcase
        end
        else begin
          cache_mmio_addr_r <= {~addr_in_r[8],addr_in_r[7:0]};
        end
      end
      else if (SNES_WR_end) begin
        if (~|addr_in_r[9:8]) begin
          casex (addr_in_r[7:0])
            ADDR_GPRL : data_flop_r <= data_in_r;
            ADDR_GPRH : begin REG_r[addr_in_r[4:1]] <= {data_in_r,data_flop_r}; if (addr_in_r[4:1] == R15) SFR_r[5] <= 1; end
          
            ADDR_SFR  : SFR_r[6:1] <= data_in_r[6:1];
            ADDR_SFR+1: {SFR_r[15],SFR_r[12:8]} <= {data_in_r[7],data_in_r[4:0]};
            ADDR_BRAMR: BRAMR_r[0] <= data_in_r[0];
            ADDR_PBR  : PBR_r <= data_in_r;
            //ADDR_ROMBR: ROMBR_r <= data_in_r;
            ADDR_CFGR : {CFGR_r[7],CFGR_r[5]} <= {data_in_r[7],data_in_r[5]};
            ADDR_SCBR : SCBR_r <= data_in_r;
            ADDR_CLSR : CLSR_r[0] <= data_in_r[0];
            ADDR_SCMR : SCMR_r[5:0] <= data_in_r[5:0];
            //ADDR_VCR  : VCR_r <= data_in_r;
            //ADDR_RAMBR: RAMBR_r[0] <= data_in_r[0];
            //ADDR_CBR+0: CBR_r[7:4] <= data_in_r[7:4];
            //ADDR_CBR+1: CBR_r[15:8] <= data_in_r;
          endcase
        end
        else begin
          cache_mmio_wren_r <= 1;
          cache_mmio_wrdata_r <= data_in_r;
          cache_mmio_addr_r <= {~addr_in_r[8],addr_in_r[7:0]};
        end
      end
    end
    else begin
      if (data_enable_r) data_out_r <= cache_rddata;
      cache_mmio_wren_r <= 0;
    end
  end
end

//-------------------------------------------------------------------
// COMMON PIPELINE
//-------------------------------------------------------------------

// step counter for pipelines
reg [7:0] stepcnt_r; initial stepcnt_r = 0;

reg [3:0] fetch_waitcnt_r;
reg [3:0] exe_waitcnt_r;

always @(posedge CLK) begin
  if (RST) begin
    fetch_waitcnt_r <= 0;
    exe_waitcnt_r <= 0;
    
    stepcnt_r <= 0;
  end
  else begin
    // decrement delay counters
    if (i2c_waitcnt_val_r) fetch_waitcnt_r <= i2c_waitcnt_r;
    else if (gsu_clock_en & |fetch_waitcnt_r) fetch_waitcnt_r <= fetch_waitcnt_r - 1;

    if (e2c_waitcnt_val_r) exe_waitcnt_r <= e2c_waitcnt_r;
    else if (gsu_clock_en & |exe_waitcnt_r) exe_waitcnt_r <= exe_waitcnt_r - 1;
    
    if (pipeline_advance) stepcnt_r <= CONFIG_STEP_COUNT;
  end
end

//-------------------------------------------------------------------
// MEMORY READ PIPELINE
//-------------------------------------------------------------------
parameter
  ST_FILL_IDLE      = 8'b00000001,
  ST_FILL_FETCH_RD  = 8'b00000010,
  ST_FILL_DATA_RD   = 8'b00000100,
  ST_FILL_DATA_WR   = 8'b00001000,
  ST_FILL_FETCH_END = 8'b00010000,
  ST_FILL_DATA_END  = 8'b00100000
  ;
reg [7:0] FILL_STATE; initial FILL_STATE = ST_FILL_IDLE;
reg rom_bus_rrq_r; initial rom_bus_rrq_r = 0;
reg rom_bus_wrq_r; initial rom_bus_wrq_r = 0;
reg [23:0] rom_bus_addr_r;
reg [7:0] rom_bus_data_r;
//reg [3:0] rom_waitcnt_r;

// The ROM/RAM should be dedicated to the GSU whenever it wants to do a fetch
always @(posedge CLK) begin
  if (RST) begin
    FILL_STATE <= ST_FILL_IDLE;
    
    gsu_rom_rd_r <= 0; // FIXME:
    gsu_ram_rd_r <= 0; // FIXME:
    gsu_ram_wr_r <= 0; // FIXME:
  end
  else begin
    case (FILL_STATE)
      ST_FILL_IDLE: begin
        // TODO: determine if the cache can make demand fetches
        if (gsu_rom_rd_r & SCMR_RON) begin
          rom_bus_rrq_r <= 1;
          rom_bus_addr_r <= 0; // TODO: get correct cache address for demand fetch
          FILL_STATE <= ST_FILL_DATA_RD;
        end
        else if (gsu_ram_rd_r & SCMR_RAN) begin
          rom_bus_rrq_r <= 1;
          rom_bus_addr_r <= 0; // TODO: get correct cache address for demand fetch
          FILL_STATE <= ST_FILL_DATA_RD;
        end
        else if (gsu_ram_wr_r & SCMR_RAN) begin
          rom_bus_wrq_r <= 1;
          rom_bus_addr_r <= 0; // TODO: get correct cache address for demand fetch
          rom_bus_data_r <= 0; // TODO: data to write
          FILL_STATE <= ST_FILL_DATA_WR;
        end
        else if (cache_rom_rd_r & SCMR_RON) begin
          rom_bus_rrq_r <= 1;
          rom_bus_addr_r <= cache_rom_addr_r;
          FILL_STATE <= ST_FILL_FETCH_RD;
        end
      end
      ST_FILL_FETCH_RD,
      ST_FILL_DATA_RD,
      ST_FILL_DATA_WR: begin
        rom_bus_rrq_r <= 0;
        rom_bus_wrq_r <= 0;
        
        if (~(rom_bus_rrq_r | rom_bus_wrq_r) & ROM_BUS_RDY) begin
          rom_bus_data_r <= ROM_BUS_RDDATA;
          FILL_STATE <= (|(FILL_STATE & ST_FILL_FETCH_RD)) ? ST_FILL_FETCH_END : ST_FILL_DATA_END;
        end
      end
      ST_FILL_FETCH_END,
      ST_FILL_DATA_END: begin
        FILL_STATE <= ST_FILL_IDLE;
      end
    endcase
  end
end

assign ROM_BUS_RRQ = rom_bus_rrq_r;
assign ROM_BUS_WRQ = rom_bus_wrq_r;
assign ROM_BUS_ADDR = rom_bus_addr_r;
assign ROM_BUS_WRDATA = rom_bus_data_r;

//-------------------------------------------------------------------
// FETCH PIPELINE
//-------------------------------------------------------------------
// The frontend of the pipeline starts with the fetch operation which
// is pipelined relative to execute and operates a clock ahead.

// The cache holds instructions to execute and is accesible by the GSU
// using a PC of 0-$1FF.  It is true dual port to support debug reads
// and writes.

// The fetch pipeline is composed primarily of the cache lookup state machine
// which can access the cache once per GSU clock.  It synchronizes with the
// 4x FPGA clock and the execution pipeline.  It does this 
// - Cache hit
// - ROM fill (into cache if offset)
parameter
  ST_FETCH_IDLE   = 8'b00000001,
  ST_FETCH_LOOKUP = 8'b00000010,
  ST_FETCH_HIT    = 8'b00000100,
  ST_FETCH_FILL   = 8'b00001000,
  ST_FETCH_WAIT   = 8'b00010000
  ;
reg [7:0] FETCH_STATE; initial FETCH_STATE = ST_FETCH_IDLE;

// Fetch operations
// - Check if cache hit (use valid bits) or !cache address
// - if miss or no allocate then load miss pipeline
// - read data out of cache or from fill
// - wait for cycles to expire and edge

reg [7:0] fetch_data_r;

wire[15:0] cache_offset = REG_r[R15][15:0] - CBR_r;
wire       cache_hit = (~|cache_offset[15:9] & cache_val_r[cache_offset[12:4]]);

assign     i2c_setcnt = cache_hit & |(FETCH_STATE & ST_FETCH_LOOKUP);

always @(posedge CLK) begin
  if (RST) begin
    FETCH_STATE <= ST_FETCH_IDLE;

    i2e_op_r[0] <= OP_NOP;
    i2e_ptr_r <= 0;
  end
  else begin
    case (FETCH_STATE)
      ST_FETCH_IDLE: begin
        // align to GSU clock
        if (SFR_GO & gsu_clock_en) begin
          FETCH_STATE <= ST_FETCH_LOOKUP;
        end
      end
      ST_FETCH_LOOKUP: begin
        // check if cache hit
        if (cache_hit) begin
          i2c_waitcnt_val_r <= 1;
          i2c_waitcnt_r <= 0;
          cache_gsu_addr_r <= REG_r[R15][8:0];
          FETCH_STATE <= ST_FETCH_HIT;
        end
        else begin
          // TODO: fill address
          i2c_waitcnt_val_r <= 1;
          i2c_waitcnt_r <= 4; // TODO: account for slow clock.
          
          cache_rom_rd_r <= 1;
          cache_rom_addr_r <= (PBR_r < 8'h60) ? (PBR_r[6] ? {PBR_r,REG_r[R15]} : {PBR_r[4:0],REG_r[R15][14:0]}) : 24'hE00000 + {PBR_r[4:0],REG_r[R15]};
          
          FETCH_STATE <= ST_FETCH_FILL;
        end
      end
      ST_FETCH_HIT: begin
        i2c_waitcnt_val_r <= 0;
        fetch_data_r <= cache_rddata;
        FETCH_STATE <= ST_FETCH_WAIT;
      end
      ST_FETCH_FILL: begin
        // TODO: get correct data from ROM
        i2c_waitcnt_val_r <= 0;
        cache_rom_rd_r <= 0;
        
        if (|(FILL_STATE & ST_FILL_FETCH_END)) begin
          fetch_data_r <= rom_bus_data_r;
          FETCH_STATE <= ST_FETCH_WAIT;
        end
      end
      ST_FETCH_WAIT: begin
        if (pipeline_advance) begin
          // TODO: fetch address increment
          i2e_op_r[~i2e_ptr_r] <= fetch_data_r;
          i2e_ptr_r <= ~i2e_ptr_r;

          if (SFR_GO) FETCH_STATE <= ST_FETCH_LOOKUP;
          else        FETCH_STATE <= ST_FETCH_IDLE;
        end
      end
    endcase
  end
end

//-------------------------------------------------------------------
// EXECUTION PIPELINE
//-------------------------------------------------------------------
parameter
  ST_EXE_IDLE      = 8'b00000001,
  
  ST_EXE_DECODE    = 8'b00000010,
  ST_EXE_REGREAD   = 8'b00000100,
  ST_EXE_EXECUTE   = 8'b00001000,
  //ST_EXE_WRITEBACK = 6'b010000,
  ST_EXE_WAIT      = 8'b00100000
  ;
reg [7:0] EXE_STATE; initial EXE_STATE = ST_EXE_IDLE;

reg [7:0] exe_data_r;
always @(posedge CLK) begin
  if (RST) begin
    EXE_STATE <= ST_EXE_IDLE;
  end
  else begin
    case (EXE_STATE)
      ST_EXE_IDLE: begin
        // align to GSU clock.  Sinks up with fetch.
        if (SFR_GO & gsu_clock_en) begin
          EXE_STATE <= ST_EXE_DECODE;
        end
      end
      ST_EXE_DECODE: begin
        // determine operands
        EXE_STATE <= ST_EXE_EXECUTE;
      end
      ST_EXE_EXECUTE: begin
        EXE_STATE <= ST_EXE_WAIT;
        
        e2r_val_r <= 0;
        e2r_dreg_r <= 0;
        e2r_data_r <= 0;
      end
      ST_EXE_WAIT: begin
        if (pipeline_advance) begin
          if (SFR_GO) EXE_STATE <= ST_EXE_DECODE;
          else        EXE_STATE <= ST_EXE_IDLE;
        end
      end
      
    endcase
  end
end

assign pipeline_advance = gsu_clock_en & ~|fetch_waitcnt_r & ~|exe_waitcnt_r & |(EXE_STATE & ST_EXE_WAIT) & |(FETCH_STATE & ST_FETCH_WAIT) & (~CONFIG_STEP_ENABLED | (stepcnt_r != CONFIG_STEP_COUNT));

//-------------------------------------------------------------------
// DEBUG OUTPUT
//-------------------------------------------------------------------
reg [7:0] pgmdata_out; //initial pgmdata_out_r = 0;

// TODO: also map other non-visible state
always @(REG_r[0], REG_r[1], REG_r[2], REG_r[3], REG_r[4], REG_r[5], REG_r[6], REG_r[7],
         REG_r[8], REG_r[9], REG_r[10], REG_r[11], REG_r[12], REG_r[13], REG_r[14], REG_r[15]
         //SFR_r, BRAMR_r, PBR_r, ROMBR_r, CFGR_r, SCBR_r, CLSR_r, SCMR_r, VCR_r, RAMBR_r, CBR_r
        ) begin
  casex (PGM_ADDR[9:0])
    {2'h0,ADDR_GPRL } : pgmdata_out = REG_r[PGM_ADDR[4:1]][7:0];
    {2'h0,ADDR_GPRH } : pgmdata_out = REG_r[PGM_ADDR[4:1]][15:8];          
    {2'h0,ADDR_SFR  } : pgmdata_out = SFR_r[7:0];
    {2'h0,ADDR_SFR+1} : pgmdata_out = SFR_r[15:8];
    {2'h0,ADDR_BRAMR} : pgmdata_out = BRAMR_r;
    {2'h0,ADDR_PBR  } : pgmdata_out = PBR_r;
    {2'h0,ADDR_ROMBR} : pgmdata_out = ROMBR_r;
    {2'h0,ADDR_CFGR } : pgmdata_out = CFGR_r;
    {2'h0,ADDR_SCBR } : pgmdata_out = SCBR_r;
    {2'h0,ADDR_CLSR } : pgmdata_out = CLSR_r;
    {2'h0,ADDR_SCMR } : pgmdata_out = SCMR_r;
    {2'h0,ADDR_VCR  } : pgmdata_out = VCR_r;
    {2'h0,ADDR_RAMBR} : pgmdata_out = RAMBR_r;
    {2'h0,ADDR_CBR+0} : pgmdata_out = CBR_r[7:0];
    {2'h0,ADDR_CBR+1} : pgmdata_out = CBR_r[15:8];
    10'h40            : pgmdata_out = COLR_r;
    10'h41            : pgmdata_out = POR_r;
    10'h42            : pgmdata_out = SREG_r;
    10'h43            : pgmdata_out = DREG_r;
    10'h44            : pgmdata_out = ROMRDBUF_r;
    10'h45            : pgmdata_out = RAMWRBUF_r;
    10'h46            : pgmdata_out = RAMADDR_r[7:0];
    10'h47            : pgmdata_out = RAMADDR_r[15:8];

    // TODO: add more internal temps @ $80
    
    10'h1xx,
    10'h2xx           : pgmdata_out = debug_cache_rddata;
    
    // fetch state
    10'h300           : pgmdata_out = FETCH_STATE;
    // exe state
    10'h320           : pgmdata_out = EXE_STATE;
    10'h321           : pgmdata_out = i2e_op_r[i2e_ptr_r];
    // cache state
    //10'h340
    // fill state
    //10'h360           : pgmdata_out = cache_rom_rd_r;
    // interface state
    10'h380           : pgmdata_out = i2e_op_r[0];
    10'h381           : pgmdata_out = i2e_op_r[1];
    // config state
    10'h3A0           : pgmdata_out = config_r[0];
    10'h3A1           : pgmdata_out = config_r[1];

    10'h3C0           : pgmdata_out = FILL_STATE;
    
    default           : pgmdata_out = 8'hFF;
  endcase
end

//-------------------------------------------------------------------
// MISC OUTPUTS
//-------------------------------------------------------------------
assign DBG = 0;
assign DATA_ENABLE = data_enable_r;
assign DATA_OUT = data_out_r;

assign PGM_DATA = pgmdata_out;

assign ACTIVE = ~|(FILL_STATE & ST_FILL_IDLE);

endmodule

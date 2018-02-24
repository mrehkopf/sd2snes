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
  input         SNES_WR_end,
  input  [23:0] SNES_ADDR,
  input  [7:0]  DATA_IN,
  output        DATA_ENABLE,
  output [7:0]  DATA_OUT,
  
  // State debug read interface
  input  [9:0]  PGM_ADDR, // [9:0]
  output [7:0]  PGM_DATA, // [7:0]
  
  output DBG
);

// temporaries
integer i;
reg [15:0] reg_tmp;

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
  
  ADDR_CACHE_BASE = 10'h100
  ;

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
assign SFR_R    = SFR_r[6];
assign SFR_ALT1 = SFR_r[8];
assign SFR_ALT2 = SFR_r[9];
assign SFR_IL   = SFR_r[10];
assign SFR_IH   = SFR_r[11];
assign SFR_B    = SFR_r[12];
assign SFR_IRQ  = SFR_r[15];

assign BRAM_EN  = BRAM_r[0];

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
// FIXME: Pixel Buffer
//-------------------------------------------------------------------

//-------------------------------------------------------------------
// Cache
//-------------------------------------------------------------------
// GSU/SNES interface
reg        cache_mmio_wren_r;
reg  [7:0] cache_mmio_wrdata_r;
reg  [8:0] cache_mmio_addr_r;

wire       cache_wren;
wire [8:0] cache_addr;
wire [7:0] cache_wrdata;
wire [7:0] cache_rddata;
// 
wire       debug_cache_wren;
wire [8:0] debug_cache_addr;
wire [7:0] debug_cache_wrdata;
wire [7:0] debug_cache_rddata;

assign cache_wren = cache_mmio_wren_r;
assign cache_addr = cache_mmio_addr_r;
assign cache_wrdata = cache_mmio_wrdata_r;
assign debug_cache_wren = 0;

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
reg       data_enable_r;
reg [7:0] data_out_r;
reg [7:0] data_flop_r;

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
    
    data_flop_r <= 0;
    cache_mmio_wren_r <= 0;
  end
  else begin
    if (SFR_GO) begin
      // need to handle reads and writes to select registers otherwise SFX chip has control
    end
    else if (gsu_enable) begin
      if (SNES_RD_start) begin
        if (~|SNES_ADDR[9:8]) begin
          casex (SNES_ADDR[7:0])
            ADDR_GPRL : begin data_enable_r <= 1; data_out_r <= REG_r[SNES_ADDR[4:1]][7:0]; end
            ADDR_GPRH : begin data_enable_r <= 1; data_out_r <= REG_r[SNES_ADDR[4:1]][15:8]; end
          
            ADDR_SFR  : begin data_enable_r <= 1; data_out_r <= SFR_r[7:0]; end
            ADRR_SFR+1: begin data_enable_r <= 1; data_out_r <= SFR_r[15:8]; end
            //ADDR_BRAMR: begin data_enable_r <= 1; data_out_r <= BRAMR_r; end
            ADDR_PBR  : begin data_enable_r <= 1; data_out_r <= PBR_r; end
            ADDR_ROMBR: begin data_enable_r <= 1; data_out_r <= ROMBR_r; end
            //ADDR_CFGR : begin data_enable_r <= 1; data_out_r <= CFGR_r; end
            //ADDR_SCBR : begin data_enable_r <= 1; data_out_r <= SCBR_r; end
            //ADDR_CLSR : begin data_enable_r <= 1; data_out_r <= CLSR_r; end
            //ADDR_SCMR : begin data_enable_r <= 1; data_out_r <= SCMR_r; end
            ADDR_VCR  : begin data_enable_r <= 1; data_out_r <= VCR_r; end
            ADDR_RAMBR: begin data_enable_r <= 1; data_out_r <= RAMBR_r; end
            ADDR_CBR+0: begin data_enable_r <= 1; data_out_r <= CBR_r[7:0]; end
            ADDR_CBR+1: begin data_enable_r <= 1; data_out_r <= CBR_r[15:8]; end
          endcase
        end
        else begin
          data_enable_r <= 1;
          cache_mmio_addr_r <= {~addr_in_r[8],addr_in_r[7:0]};
        end
      end
      else if (SNES_WR_end) begin
        if (~|SNES_ADDR[9:8]) begin
          casex (SNES_ADDR[7:0])
            ADDR_GPRL : data_flop_r <= data_in_r;
            ADDR_GPRH : REG_r[SNES_ADDR[4:1]] <= {data_in_r,data_flop_r};
          
            ADDR_SFR  : SFR_r[6:1] <= data_in_r[6:1];
            ADRR_SFR+1: {SFR_r[15],SFR_r[12:8]} <= {data_in_r[7],data_in_r[4:0]};
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
      data_enable_r <= 0;
      cache_wren_r <= 0;
    end
  end
end

//-------------------------------------------------------------------
// CACHE PIPELINE
//-------------------------------------------------------------------
// The cache holds instructions to execute and is accesible by the GSU
// using a PC of 0-$1FF.  It is true dual port to support debug reads
// and writes.

//-------------------------------------------------------------------
// EXECUTION PIPELINE
//-------------------------------------------------------------------

//-------------------------------------------------------------------
// DEBUG OUTPUT
//-------------------------------------------------------------------


//-------------------------------------------------------------------
// MISC OUTPUTS
//-------------------------------------------------------------------
assign DBG = 0;
assign DATA_ENABLE = data_enable_r;
assign DATA_OUT = data_out_r;

endmodule

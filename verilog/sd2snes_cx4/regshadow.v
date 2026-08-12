`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// Company: sd2snes
// Module Name: regshadow
// Description:
//   Write-only shadow of the PPU ($2100-$213F) and CPU ($4200-$421F) registers,
//   read back by the in-game savestate handler through the hook window:
//     $F90500-$F9057F : PPU regs, stride-2 (1st write, 2nd write)
//     $F90700-$F9071F : CPU regs, stride-1
//   base/DSP/SA-1 get this from ctx.v, which does not fit the mk2 Spartan-3.
//
//   The scroll ($210D-$2114) and mode-7 ($211B-$2120) registers latch 16 bits from
//   two consecutive writes, so the pair is stored, not just the last byte (ctx.v
//   does the same via rBG/rM7).  Non-double regs store (value, value).
//
//   Storage (256x8, one RAMB16):
//     mem[$00-$7F] PPU pairs, mem[{PA,1'b0}] = 1st write, mem[{PA,1'b1}] = 2nd
//     mem[$80-$9F] CPU regs
//   REGSHADOW_1DEEP selects the older layout (PPU mem[$00-$3F], CPU mem[$40-$5F]);
//   main.v indexes both under the same macro.
//
//   Compile gates, mutually exclusive, for mk2 area/timing:
//     REGSHADOW_NO_M7  drop the mode-7 tracker, keep the scroll pair (gsu mk2)
//     REGSHADOW_1DEEP  drop the pair scheme entirely (cx4 mk2)
//////////////////////////////////////////////////////////////////////////////////
module regshadow(
  input clk,
  input pawr_end,            // settled rising edge of /PAWR
  input wr_end,              // settled rising edge of /WR
  input [23:0] snes_addr,
  input [7:0] snes_pa,
  input [7:0] snes_data,
  input [8:0] rd_addr,
  output reg [7:0] rd_data
);

// 1DEEP removes what NO_M7 thins, so defining both is always a mistake and 1DEEP
// would silently win.  The bare identifier is illegal Verilog: fail at parse time.
`ifdef REGSHADOW_1DEEP
 `ifdef REGSHADOW_NO_M7
   ERROR_REGSHADOW_1DEEP_and_REGSHADOW_NO_M7_are_mutually_exclusive
 `endif
`endif

(* ram_style = "block" *) reg [7:0] mem [0:255];

wire       ppu_wr = pawr_end & (snes_pa < 8'h40);
// $4200-$421F in any bank with ADDR[22]=0: games write them through FastROM banks,
// so a bank-$00-only decode misses those writes.
wire       cpu_wr = wr_end & ~snes_addr[22]
                           & (snes_addr[15:5] == 11'b01000010000);

`ifdef REGSHADOW_1DEEP
wire       wr_en  = ppu_wr | cpu_wr;
wire [7:0] wr_a   = ppu_wr ? {2'b00, snes_pa[5:0]}
                           : {3'b010, snes_addr[4:0]};

always @(posedge clk) begin
  if (wr_en)
    mem[wr_a] <= snes_data;
  rd_data <= mem[rd_addr[7:0]];
end
`else
// Previous-byte trackers (ctx.v's rBG/rM7): consumed before being updated.
reg [7:0]  prev_bg;   initial prev_bg = 0;
`ifndef REGSHADOW_NO_M7
reg [7:0]  prev_m7;   initial prev_m7 = 0;
`endif
wire is_bg_dbl = (snes_pa >= 8'h0D) && (snes_pa <= 8'h14);
`ifndef REGSHADOW_NO_M7
wire is_m7_dbl = ((snes_pa >= 8'h0D) && (snes_pa <= 8'h0E))
              || ((snes_pa >= 8'h1B) && (snes_pa <= 8'h20));
`endif

// The strobe cycle stores the current byte (odd offset), the next cycle stores the
// previous one (even offset) out of these defer flops.  Bus writes are dozens of
// clocks apart, so the defer can never collide with the next write.
reg        wr2_pend;  initial wr2_pend = 0;
reg [7:0]  wr2_a;     initial wr2_a = 0;
reg [7:0]  wr2_d;     initial wr2_d = 0;

wire       wr_en  = ppu_wr | cpu_wr | wr2_pend;
wire [7:0] wr_a   = wr2_pend ? wr2_a
                  : ppu_wr   ? {1'b0, snes_pa[5:0], 1'b1}
                             : {3'b100, snes_addr[4:0]};
wire [7:0] wr_d   = wr2_pend ? wr2_d : snes_data;

// One write enable and one write address in the process: anything else falls out
// of the XST block-RAM template and the memory is built from flip-flops instead.
// The arm is edge-guarded so a strobe wider than one cycle cannot re-arm with the
// trackers already updated, which would degrade the pair back to (value, value).
always @(posedge clk) begin
  if (wr_en)
    mem[wr_a] <= wr_d;
  rd_data <= mem[rd_addr[7:0]];
  if (ppu_wr & ~wr2_pend) begin
    wr2_pend <= 1'b1;
    wr2_a    <= {1'b0, snes_pa[5:0], 1'b0};
`ifndef REGSHADOW_NO_M7
    wr2_d    <= is_bg_dbl ? prev_bg : is_m7_dbl ? prev_m7 : snes_data;
`else
    wr2_d    <= is_bg_dbl ? prev_bg : snes_data;
`endif
    if (is_bg_dbl) prev_bg <= snes_data;
`ifndef REGSHADOW_NO_M7
    if (is_m7_dbl) prev_m7 <= snes_data;
`endif
  end else if (~ppu_wr) begin
    wr2_pend <= 1'b0;
  end
end
`endif

endmodule

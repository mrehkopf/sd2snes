// ---------------------------------------------------------------------------
// spc7110_map.v -- SPC7110 memory control unit: the four 1 MB cartridge
// windows selected by $4830-$4834 plus the $6000-7FFF SRAM gate.
//
// Copyright (c) 2004-2025 ares team, Near et al
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
// Adapted for RTL from the ares SPC7110 implementation (ISC licensed).
//
// Behaviour (ares mcuromRead()/mcuramRead()).  The two
// SNES ranges the cartridge claims fold into one 23 bit linear address:
//
//   $00-3f,80-bf:8000-ffff   mask 0x800000 -> lin = snes_addr[22:0]
//   $c0-ff:0000-ffff         mask 0xc00000 -> lin = snes_addr[21:0]
//
// lin[21:20] then picks the window and lin[19:0] is the offset inside it:
//
//   window 0  PROM 0x000000 when a PROM exists, else data ROM block r4830 & 7
//   window 1  PROM 0x100000 when r4834 & 4, else data ROM block r4831 & 7.
//             The reference tests ONLY the flag there, so with the flag set
//             and no PROM present the access resolves to nothing: rom_hit = 0,
//             never a fallback to r4831 (the ares window-1 branch is unconditional).
//   window 2  data ROM block r4832 & 7
//   window 3  data ROM block r4833 & 7
//
// Every data ROM path goes through the same dataromRead() pre-masking as
// spc7110_data: the block address is masked with (0x100000 << (r4834 & 3)) - 1
// and an address carrying 0x400000 with a data ROM smaller than 8 MB reads
// 0x00, which is reported here as rom_hit = 0 (nothing to fetch from PSRAM).
//
// PSRAM layout: the cartridge image is contiguous with
// the PROM at 0x000000, so drom_base IS the PROM size.  The module derives
// "a PROM exists" from drom_base != 0 and the PROM mirror mask from
// drom_base - 1; every SPC7110 cartridge has power of two PROM and data ROM,
// which is the same assumption the drom_mask input already makes.
//
// psram_addr is forced to 0 when rom_hit is 0 (including the SRAM window), so
// a consumer can never latch a stale ROM address on a cycle that has none.
// The SRAM offset itself is not produced here: is_sram only reports that the
// access belongs to the save RAM, which the integration maps at its own base.
// ---------------------------------------------------------------------------
module spc7110_map(
  input       [23:0] snes_addr,

  input       [7:0]  r4830,
  input       [7:0]  r4831,
  input       [7:0]  r4832,
  input       [7:0]  r4833,
  input       [7:0]  r4834,

  input       [23:0] drom_base,   // = PROM size; data ROM origin in PSRAM
  input       [23:0] drom_mask,   // physical data ROM mirror mask

  output             rom_hit,
  output      [23:0] psram_addr,
  output             is_sram
);

  // -------------------------------------------------------------------------
  // address decode
  // -------------------------------------------------------------------------
  // banks $00-3f and $80-bf are exactly the banks with bit 22 clear
  wire lo_bank = ~snes_addr[22];
  wire hi_bank = snes_addr[23] & snes_addr[22];   // $c0-ff

  wire rom_win = (lo_bank & snes_addr[15]) | hi_bank;

  // Both folds land on the same 22 bits: removing bit 23 from $00-3f/$80-bf
  // and bits 23:22 from $c0-ff leaves snes_addr[21:0] either way, because the
  // banks of the first range always have bit 22 clear.
  wire [1:0]  win   = snes_addr[21:20];
  wire [19:0] off20 = snes_addr[19:0];

  // -------------------------------------------------------------------------
  // program ROM
  // -------------------------------------------------------------------------
  wire        prom_present = |drom_base;
  wire [23:0] prom_mask    = drom_base - 24'd1;

  // Which branch the reference takes.  Window 0 asks "does a PROM exist" and
  // falls back to the data ROM when it does not; window 1 asks ONLY about
  // r4834 bit 2 and takes the PROM branch unconditionally when it is set --
  // there is no fallback to r4831 there.  With the bit set and no PROM the
  // access therefore resolves to nothing at all (matching the reference).
  wire prom_branch = ((win == 2'd0) & prom_present)
                   | ((win == 2'd1) & r4834[2]);

  wire use_prom = rom_win & prom_branch & prom_present;

  // 0x000000 for window 0, 0x100000 for window 1
  wire [23:0] prom_lin = {3'b000, (win == 2'd1), off20};
  wire [23:0] prom_off = prom_lin & prom_mask;

  // -------------------------------------------------------------------------
  // data ROM
  // -------------------------------------------------------------------------
  reg [2:0] blk;
  always @* begin
    case(win)
      2'd0:    blk = r4830[2:0];
      2'd1:    blk = r4831[2:0];
      2'd2:    blk = r4832[2:0];
      default: blk = r4833[2:0];
    endcase
  end

  reg [22:0] size_mask;
  always @* begin
    case(r4834[1:0])
      2'd0:    size_mask = 23'h0fffff;   //  8 Mbit
      2'd1:    size_mask = 23'h1fffff;   // 16 Mbit
      2'd2:    size_mask = 23'h3fffff;   // 32 Mbit
      default: size_mask = 23'h7fffff;   // 64 Mbit
    endcase
  end

  wire [22:0] drom_lin  = {blk, off20};
  wire        drom_kill = (r4834[1:0] != 2'b11) & drom_lin[22];
  wire [23:0] drom_off  = {1'b0, drom_lin & size_mask} & drom_mask;

  // -------------------------------------------------------------------------
  // outputs
  // -------------------------------------------------------------------------
  assign is_sram = lo_bank & r4830[7] & (snes_addr[15:13] == 3'b011);

  // the PROM branch answers only if a PROM is there, the data ROM branch only
  // if the 0x400000 guard of dataromRead() does not fire
  assign rom_hit = rom_win & (prom_branch ? prom_present : ~drom_kill);

  assign psram_addr = ~rom_hit   ? 24'h000000 :
                       use_prom  ? prom_off   :
                                   (drom_base + drom_off);

endmodule

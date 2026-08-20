// ---------------------------------------------------------------------------
// spc7110_dcu.v -- SPC7110 decompression unit (DCU): arithmetic decoder,
// context model, colour map and tile buffer for the $4800-$480C register block.
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
// Adapted for RTL from the ares SPC7110 implementation (ISC licensed);
// original decompressor by neviksti, optimized by talarubi.
//
// Structure (C++ -> RTL map):
//   - sequencer FSM : $4806 begin-transfer, seek loop, 8-row tile fill
//   - decoder FSM   : one decode() call = 8 pixels x bpp planes
//   - move-to-front : one shared combinational unit, 4 uses per pixel
//   - context store : 80 x 21 bit block RAM holding the UNPACKED model
//   - evolution ROM : 64 x 20 bit block RAM (53 used)
//   - byte prefetch : 8 deep FIFO in front of the data ROM port, so the
//                     arithmetic coder never waits on data ROM latency
//   - tile buffer   : two 32 byte buffers; $4800 is served from the buffer the
//                     SNES owns while the other one is refilled in the
//                     background, so a register read never stalls the bus.
//
// ACCEPTED DIVERGENCE from the reference model (deliberate, documented): because
// the refill runs ahead, r4807 and r480b bit0 are sampled when a tile STARTS
// being decoded, up to one tile earlier than the reference, which consumes them
// lazily on the first read of the tile.  Real silicon also decodes ahead -- the
// ready bit of $480C exists for that reason -- and no known driver rewrites the
// stride between the $4806 trigger and the end of the transfer.  A game that
// did would show one tile decoded with the previous stride; vectors that
// exercise it are kept as documentation outside the gate.
// ---------------------------------------------------------------------------

module spc7110_dcu(
  input             clkin,
  input             rst,

  // register writes ($4801-$480B)
  input             we_4801,
  input             we_4802,
  input             we_4803,
  input             we_4804,
  input             we_4805,
  input             we_4806,
  input             we_4807,
  input             we_4808,
  input             we_4809,
  input             we_480a,
  input             we_480b,
  input      [7:0]  wdata,

  // $4800 read strobe: one byte consumed by the SNES
  input             rd_4800,

  // r4834[1:0]: data ROM size, drives the dataromRead() pre-masking below
  input      [1:0]  drom_size,

  output     [7:0]  dcu_data,
  output            dcu_ready,

  // register read-back
  output     [7:0]  r4801,
  output     [7:0]  r4802,
  output     [7:0]  r4803,
  output     [7:0]  r4804,
  output     [7:0]  r4805,
  output     [7:0]  r4806,
  output     [7:0]  r4807,
  output     [7:0]  r4808,
  output     [7:0]  r4809,
  output     [7:0]  r480a,
  output     [7:0]  r480b,
  output     [7:0]  r480c,

  // data ROM port (contract section 1): level request, 1 clk ack, 1 byte
  output            drom_req,
  output     [23:0] drom_addr,
  input             drom_ack,
  input      [7:0]  drom_data
);

  // -------------------------------------------------------------------------
  // control registers
  // -------------------------------------------------------------------------
  reg  [7:0]  q4801, q4802;
  reg  [6:0]  q4803;                  // n7 in the reference: bit 7 is dropped
  reg  [7:0]  q4804, q4805, q4806, q4807;
  reg  [15:0] qcount;                 // {r480a, r4809}, decremented per $4800 read
  reg  [1:0]  q480b;                  // written as (data & 3)
  reg         qdone;                  // $480C bit 7

  assign r4801 = q4801;
  assign r4802 = q4802;
  assign r4803 = {1'b0, q4803};
  assign r4804 = q4804;
  assign r4805 = q4805;
  assign r4806 = q4806;
  assign r4807 = q4807;
  assign r4808 = 8'h00;
  assign r4809 = qcount[7:0];
  assign r480a = qcount[15:8];
  assign r480b = {6'b000000, q480b};
  assign r480c = {qdone, 7'b0000000};

  // -------------------------------------------------------------------------
  // functions
  // -------------------------------------------------------------------------

  // moveToFront(), split in two pipeline stages.  Fused, the nibble search and
  // the 64-bit rotate shared one clock and formed the critical path of the
  // whole core (the scan/apply split below is what keeps it off the critical path).
  //
  // stage A -- which nibble matches:
  // Written without a variable part-select on purpose: XST rejects those on a
  // signal ("Variable index is not supported in signal"), so the per-nibble
  // compare is done on the whole word and the 16 results are picked out with
  // constant bit-selects.  e = bitwise equality, a2 bit 4j = "nibble j matches".
  function [15:0] mtf_hit;
    input [63:0] list;
    input [3:0]  nib;
    reg   [63:0] e, a1, a2;
    begin
      e  = ~(list ^ {16{nib}});
      a1 = e  & (e  >> 1);
      a2 = a1 & (a1 >> 2);
      mtf_hit = {a2[60], a2[56], a2[52], a2[48], a2[44], a2[40], a2[36], a2[32],
                 a2[28], a2[24], a2[20], a2[16], a2[12], a2[ 8], a2[ 4], a2[ 0]};
    end
  endfunction

  // stage B -- rotate the list up to the match.  pfx[j] is "nibble j sits
  // ABOVE the first match", so it keeps its value; everything at or below the
  // match shifts up one nibble and the match itself lands in the low four bits.
  // Same shape as the reference implementation: (list & mask) | (list << 4 &
  // ~mask), with the nibble dropped into the low four bits.  keep is pfx
  // widened to one bit per nibble, built by a static concatenation so no
  // variable index reaches a signal.
  function [63:0] mtf_apply;
    input [63:0] list;
    input [15:0] pfx;
    input [3:0]  nib;
    input        any;
    reg   [63:0] keep;
    begin
      keep = {{4{pfx[15]}}, {4{pfx[14]}}, {4{pfx[13]}}, {4{pfx[12]}},
              {4{pfx[11]}}, {4{pfx[10]}}, {4{pfx[ 9]}}, {4{pfx[ 8]}},
              {4{pfx[ 7]}}, {4{pfx[ 6]}}, {4{pfx[ 5]}}, {4{pfx[ 4]}},
              {4{pfx[ 3]}}, {4{pfx[ 2]}}, {4{pfx[ 1]}}, {4{pfx[ 0]}}};
      if(!any) begin
        mtf_apply = list;             // not in the list: unchanged (as in C)
      end else begin
        mtf_apply      = (list & keep) | ((list << 4) & ~keep);
        mtf_apply[3:0] = nib;
      end
    end
  endfunction

  // number of left shifts needed to bring range back above Max/2 (=127);
  // replaces the "while(range <= Max/2)" loop with one barrel shift.
  function [3:0] norm_k;
    input [8:0] r;
    begin
      if     (r[8]) norm_k = 4'd0;
      else if(r[7]) norm_k = 4'd0;
      else if(r[6]) norm_k = 4'd1;
      else if(r[5]) norm_k = 4'd2;
      else if(r[4]) norm_k = 4'd3;
      else if(r[3]) norm_k = 4'd4;
      else if(r[2]) norm_k = 4'd5;
      else if(r[1]) norm_k = 4'd6;
      else          norm_k = 4'd7;    // r[0] or r == 0 (unreachable)
    end
  endfunction

  // dataromRead() address mask: size = 1 << (r4834 & 3) megabytes.
  function [23:0] dsz_mask;
    input [1:0] sz;
    begin
      case(sz)
        2'd0:    dsz_mask = 24'h0fffff;
        2'd1:    dsz_mask = 24'h1fffff;
        2'd2:    dsz_mask = 24'h3fffff;
        default: dsz_mask = 24'h7fffff;
      endcase
    end
  endfunction

  // -------------------------------------------------------------------------
  // data ROM port: one request in flight, load-address unit has priority over
  // the decompressor byte prefetch.  Both users go through dataromRead(), so
  // the size mask and the $400000 hole are applied here, before the request
  // leaves the module: an address in the hole is answered with 00 and never
  // reaches the bus.
  // -------------------------------------------------------------------------
  reg         req_v;
  reg         req_owner;              // 1 = load address unit, 0 = prefetch
  reg  [23:0] req_addr;
  reg         la_kill, pf_kill;       // discard the answer of a stale request

  // Handshake rule: the request must drop combinationally with the ack (a
  // held request would be re-sampled by the arbiter as a second transaction,
  // issuing the very same read twice).
  assign drom_req  = req_v && !drom_ack;
  assign drom_addr = req_addr;

  // load address unit ($4804 write): 4 sequential bytes at table + index*4
  // la_cur is the address of the byte la_st is fetching, kept as its own
  // counter instead of being recomputed as base + (la_st - 1): that adder put
  // a full 24 bit carry chain between la_st and the $400000 hole test, and the
  // hole test drives the D input of dcu_addr_r.  Equivalent by construction --
  // it is loaded with the base when la_st is armed and steps on exactly the
  // events that step la_st.
  reg  [2:0]  la_st;                  // 0 idle, 1..4 = fetching byte 0..3
  reg  [23:0] la_cur;
  reg  [1:0]  dcu_mode_r;
  reg  [22:0] dcu_addr_r;
  wire        la_busy = (la_st != 3'd0);

  // byte prefetch FIFO.  Occupancy is its own up/down counter rather than
  // (fifo_wp - fifo_rp): that subtractor sat in front of fifo_empty ->
  // ar2_go -> the clock enable of the whole arithmetic step, so the write
  // pointer reached range/input/bits through two extra levels of logic.  The
  // counter is exact by construction -- it moves on the very conditions that
  // move the two pointers, and the transfer restart zeroes it with the same
  // priority it zeroes them.  It never leaves 0..8, so bit 3 alone means full.
  reg  [7:0]  fifo_mem [0:7];
  reg  [3:0]  fifo_wp, fifo_rp;
  reg  [3:0]  fifo_cnt;
  reg  [23:0] pf_addr;
  reg         pf_en;
  wire        fifo_empty = (fifo_cnt == 4'd0);
  wire [7:0]  fifo_dout  = fifo_mem[fifo_rp[2:0]];
  wire        pf_need    = pf_en && !fifo_cnt[3];

  // dataromRead() of the next byte each user wants
  wire [23:0] la_masked = la_cur & dsz_mask(drom_size);
  wire        la_hole   = (drom_size != 2'd3) && la_cur[22];
  wire [23:0] pf_masked = pf_addr & dsz_mask(drom_size);
  wire        pf_hole   = (drom_size != 2'd3) && pf_addr[22];

  // -------------------------------------------------------------------------
  // decompressor state
  // -------------------------------------------------------------------------
  reg  [1:0]  mode;                   // 0 = 1bpp, 1 = 2bpp, 2 = 4bpp
  wire        bpp1 = (mode == 2'd0);
  wire        bpp2 = (mode == 2'd1);
  wire        bpp4 = (mode == 2'd2);

  reg  [3:0]  bits_r;                 // bits remaining in input (1..8)
  reg  [8:0]  range_r;                // arithmetic range (Max+1 = 256 at init)
  reg  [15:0] input_r;
  reg  [7:0]  output_r;
  reg  [63:0] pixels_r;
  reg  [63:0] colormap_r;
  reg  [63:0] map_r;
  reg  [31:0] result_r;

  localparam [63:0] CMAP_INIT = 64'hfedcba9876543210;

  // context store: {swap, probability[7:0], next0[5:0], next1[5:0]}
  // Two invariants every reader of this table may rely on: (1) the read
  // address is bounded by construction -- set_w <= 4 (diff_w is 0..4) and
  // idx_w <= 14, so ctx_raddr <= 78 never leaves ctxmem[0:79]; (2) ST_BT_CLR
  // rewrites entries 0..79 with CTX_INIT before every transfer, including
  // after an abort, so every probability a decode can observe is a row of the
  // evolution table (all reachable probabilities lie in [8'h01, 8'h5a]).
  reg  [20:0] ctxmem [0:79];
  reg  [20:0] ctx_q;
  reg  [6:0]  ctx_raddr;
  reg         ctx_re;
  reg         ctx_we;
  reg  [6:0]  ctx_waddr;
  reg  [20:0] ctx_wdata;
  wire [5:0]  c_next0 = ctx_q[11:6];
  wire [5:0]  c_next1 = ctx_q[ 5:0];

  localparam [20:0] CTX_INIT = {1'b0, 20'h5a041};   // swap 0, evolution[0]

  // evolution ROM: {probability[7:0], next0[5:0], next1[5:0]}.  Both successor
  // states are read at once and the decoded symbol picks one a clock later:
  // addressing the ROM with (symbol ? next1 : next0) put the whole
  // context-read -> subtract -> compare chain in front of a block RAM address
  // pin, which was the worst path of the core on Spartan-3.  The two reads are
  // the two ports of one ROM, so the second one is free.
  // XST warns "Signal <evo> is used but never assigned" for this
  // initial-block ROM; the warning is spurious -- the INIT strings in the
  // generated bitstream carry the table below verbatim.
  reg  [19:0] evo [0:63];
  reg  [19:0] evo_q0, evo_q1;

  initial begin
    evo[ 0] = 20'h5a041;  evo[ 1] = 20'h25086;  evo[ 2] = 20'h110c8;
    evo[ 3] = 20'h0810a;  evo[ 4] = 20'h0314c;  evo[ 5] = 20'h0114f;
    evo[ 6] = 20'h5a1c7;  evo[ 7] = 20'h3f213;  evo[ 8] = 20'h2c255;
    evo[ 9] = 20'h20296;  evo[10] = 20'h172d7;  evo[11] = 20'h11319;
    evo[12] = 20'h0c35a;  evo[13] = 20'h0939c;  evo[14] = 20'h073dd;
    evo[15] = 20'h0541f;  evo[16] = 20'h04460;  evo[17] = 20'h034a2;
    evo[18] = 20'h02163;  evo[19] = 20'h5a514;  evo[20] = 20'h48567;
    evo[21] = 20'h3a5a8;  evo[22] = 20'h2e5ea;  evo[23] = 20'h2662c;
    evo[24] = 20'h1f66d;  evo[25] = 20'h196ae;  evo[26] = 20'h156d9;
    evo[27] = 20'h1171a;  evo[28] = 20'h0e75a;  evo[29] = 20'h0b79b;
    evo[30] = 20'h097dc;  evo[31] = 20'h0881d;  evo[32] = 20'h0785e;
    evo[33] = 20'h0589f;  evo[34] = 20'h048e1;  evo[35] = 20'h04921;
    evo[36] = 20'h03962;  evo[37] = 20'h029a3;  evo[38] = 20'h02164;
    evo[39] = 20'h58a27;  evo[40] = 20'h4da6f;  evo[41] = 20'h43ab0;
    evo[42] = 20'h3baf1;  evo[43] = 20'h34b32;  evo[44] = 20'h2eb73;
    evo[45] = 20'h29bac;  evo[46] = 20'h2562d;  evo[47] = 20'h56c2f;
    evo[48] = 20'h4fc6f;  evo[49] = 20'h47cb0;  evo[50] = 20'h41cf1;
    evo[51] = 20'h3cd32;  evo[52] = 20'h37af3;  evo[53] = 20'h00000;
    evo[54] = 20'h00000;  evo[55] = 20'h00000;  evo[56] = 20'h00000;
    evo[57] = 20'h00000;  evo[58] = 20'h00000;  evo[59] = 20'h00000;
    evo[60] = 20'h00000;  evo[61] = 20'h00000;  evo[62] = 20'h00000;
    evo[63] = 20'h00000;
  end

  always @(posedge clkin) begin
    if(ctx_we) ctxmem[ctx_waddr] <= ctx_wdata;
    if(ctx_re) ctx_q <= ctxmem[ctx_raddr];
    evo_q0 <= evo[c_next0];
    evo_q1 <= evo[c_next1];
  end

  // -------------------------------------------------------------------------
  // sequencer / decoder state
  // -------------------------------------------------------------------------
  localparam [3:0] ST_IDLE    = 4'd0;
  localparam [3:0] ST_BT_CHK  = 4'd1;
  localparam [3:0] ST_BT_CLR  = 4'd2;
  localparam [3:0] ST_BT_INIT = 4'd3;
  localparam [3:0] ST_BT_IN0  = 4'd4;
  localparam [3:0] ST_BT_IN1  = 4'd5;
  localparam [3:0] ST_BT_DEC  = 4'd6;
  localparam [3:0] ST_BT_DECW = 4'd7;
  localparam [3:0] ST_BT_SEEK = 4'd8;
  localparam [3:0] ST_BT_SKW  = 4'd9;
  localparam [3:0] ST_BT_ARM  = 4'd10;
  localparam [3:0] ST_F_ROW   = 4'd11;
  localparam [3:0] ST_F_SEEK  = 4'd12;
  localparam [3:0] ST_F_SKW   = 4'd13;

  localparam [2:0] DC_IDLE = 3'd0;
  localparam [2:0] DC_PIX  = 3'd1;
  localparam [2:0] DC_CTX  = 3'd2;
  localparam [2:0] DC_AR1  = 3'd3;
  localparam [2:0] DC_AR2  = 3'd4;
  localparam [2:0] DC_END  = 3'd5;

  reg  [3:0]  state;
  reg  [2:0]  dc_state;
  reg         dc_busy;
  reg         bt_pending;
  reg         xfer_active;
  reg  [6:0]  clr_cnt;
  reg  [15:0] seek_cnt;
  reg  [2:0]  row;
  reg  [7:0]  row_seek;

  // Tile buffers: two 32 byte pages.  Byte ADDRESSED rather than one flat
  // vector: a variable index into a memory is the form XST accepts, while a
  // variable part-select of a signal is not.
  //
  // Each page is split into four eight entry banks by (address bit 4, address
  // bit 0), which is exactly how a row is laid out: a row writes byte 2r to
  // bank a, 2r+1 to bank b, 2r+16 to bank c and 2r+17 to bank d, so no bank
  // ever takes more than one byte per row and each of them has a single write
  // port.  That is what lets the pages live in eight small memories instead of
  // 512 flip flops behind a 32:1 read mux -- the flip flop form spread over
  // the whole die and its clock enable was the longest route in the core.
  // 1bpp writes one byte per row, alternating between banks a and b.
  //
  // THE READ IS ASYNCHRONOUS AND HAS TO STAY THAT WAY.  dcu_data is combinational
  // out of these banks, so they must be LUT RAM (or flip flops), never block RAM.
  // Left to itself XST spends whatever block RAM is still free on them and
  // reports what it does with it: "The RAM <Mram_tb1b> will be implemented as a
  // BLOCK RAM, absorbing the following register(s): <rd_off>".  Absorbing rd_off
  // means the read address stops being a wire into an asynchronous array and
  // becomes the block RAM's own address register -- and on silicon that register
  // never advances: the three banks that landed in block RAM returned entry 0 for
  // all eight indices, every time.  Measured on a Mk.II with a probe cartridge
  // that reads a known transfer out of $4800 four times at four different paces:
  // tb0a-d and tb1a (LUT RAM) byte exact, tb1b/tb1c/tb1d (block RAM) every index
  // equal to index 0.  On screen that is a handful of tiles wrong in an otherwise
  // correct image, identical in every fit, which is what it looked like.
  // An earlier revision of this comment claimed the two forms were equivalent
  // because a page is only written while its buf_valid bit is clear.  That
  // argument only ever covered read-during-write; it says nothing about the
  // address register, and it was wrong.
  // Cyclone IV has neither form and keeps the flip flops, so the attribute is
  // scoped to the flavour that needs it and the mk3 netlist is untouched.
`ifdef MK2
  (* ram_style = "distributed" *)
`endif
  reg  [7:0]   tb0a [0:7], tb0b [0:7], tb0c [0:7], tb0d [0:7];
`ifdef MK2
  (* ram_style = "distributed" *)
`endif
  reg  [7:0]   tb1a [0:7], tb1b [0:7], tb1c [0:7], tb1d [0:7];
  reg  [1:0]   buf_valid;
  reg          rd_sel, fill_sel;
  reg  [4:0]   rd_off;

  // decode() iteration state
  reg  [2:0]  pix;
  reg  [1:0]  plane;
  reg  [2:0]  diff_r;
  reg  [3:0]  pa_r, pb_r, pc_r;
  reg  [6:0]  ctx_addr_r;
  reg  [3:0]  k_r;
  reg  [15:0] input_a_r;
  reg  [8:0]  range_a_r;
  reg         norm_r;
  reg         swap_nx_r;
  reg         sym_r;                  // decoded symbol, picks the successor state

  // move-to-front chain, two stages deep.  A pixel needs four moves: three that
  // build "map" from the OLD colormap (pc, pb, pa) and one that advances the
  // colormap itself (pa).  The colormap move is independent of the map chain,
  // so it is interleaved into the slots the dependent chain leaves free, and
  // the four moves still finish in six clocks -- the same window the fused
  // version used, which is what keeps 2bpp at seven clocks per pixel:
  //
  //   clk 1  A(map <- cm , pc)
  //   clk 2  B(map)               A(cm  <- cm , pa)
  //   clk 3  B(cm)                A(map <- map, pb)
  //   clk 4  B(map)
  //   clk 5                       A(map <- map, pa)
  //   clk 6  B(map)  <- map final, read by the pixel epilogue on clk 7
  //
  // Invariant that makes the interleave safe: no write to the register a
  // stage A read lands between that A and its own B.  (Note the clk1->clk2
  // pair: A reads colormap_r while its B writes map_r -- the colormap write
  // of clk 3 comes after, which is exactly the reference's "map is a copy of
  // colormap taken BEFORE the colormap advances".)
  //
  // Which slot runs on the next clock is known a full clock ahead, so the
  // nibble and the two select bits of stage A are REGISTERS, loaded by the
  // decoder block below.  The lists themselves are still read in the stage A
  // cycle, so the invariant above is untouched -- only the operand select
  // moves.
  reg  [2:0]  mtf_ph;                 // 0 idle, 2..6 = clk 2..6 above
  reg         b_valid;                // stage B has work this cycle
  reg  [15:0] b_pfx;
  reg         b_any;
  reg  [3:0]  b_nib;
  reg         b_lsel;                 // stage B list:   0 = colormap_r, 1 = map_r
  reg         b_dest;                 // stage B target: 0 = colormap_r, 1 = map_r
  wire        mtf_busy = (mtf_ph != 3'd0) || b_valid;

  wire        bt_abort = bt_pending && !la_busy;

  // -------------------------------------------------------------------------
  // combinational decode datapath
  // -------------------------------------------------------------------------

  // pixel setup: pa/pb/pc and the "which of the three neighbours differ" code
  wire [3:0] pa_w = bpp2 ? {2'b00, pixels_r[3:2]}   : pixels_r[3:0];
  wire [3:0] pb_w = bpp2 ? {2'b00, pixels_r[15:14]} : pixels_r[31:28];
  wire [3:0] pc_w = bpp2 ? {2'b00, pixels_r[17:16]} : pixels_r[35:32];
  wire [3:0] match_w = pa_w ^ pb_w ^ pc_w;
  wire [2:0] diff_w = ((pa_w == pb_w) && (pb_w == pc_w)) ? 3'd0 :
                      ((match_w ^ pa_w) == 4'd0)         ? 3'd1 :
                      ((match_w ^ pb_w) == 4'd0)         ? 3'd2 :
                      ((match_w ^ pc_w) == 4'd0)         ? 3'd3 : 3'd4;

  // Stage A operand: REGISTERS, loaded one clock before the stage A that uses
  // them (the schedule is known that early -- see the decoder block).  Decoding
  // them out of mtf_ph in the same cycle put a two level nibble multiplexer AND
  // the fan-out-14 mtf_ph net in front of mtf_hit -> prefix-OR -> b_pfx, which
  // was the worst path of the whole core; the registered form starts that chain
  // at a flip flop instead.  Nothing about the schedule changes: the values
  // presented here are exactly what the combinational decode produced.
  //
  // Do NOT pin these down with register_balancing = "no".  XST retimes them
  // backward across their own input multiplexer and fans a_nib out into ten
  // replicas placed next to the sixteen nibble comparators; the multiplexer it
  // leaves behind is local and cheap, and the replication is worth far more
  // than the level it costs.  Measured on this design: the attribute (or
  // turning balancing off project-wide) costs 1.2 ns / 2.4 ns of worst-case
  // slack respectively.  Registering the operand is still what makes that
  // possible -- with the schedule decoded in the same cycle, the multiplexer
  // hung off mtf_ph, a sequencer register the balancer cannot replicate.
  reg        a_fire;
  reg  [3:0] a_nib;
  reg        a_lsel, a_dest;

  wire [63:0] a_list = a_lsel ? map_r : colormap_r;
  wire [15:0] a_hit  = mtf_hit(a_list, a_nib);
  // mask of everything strictly above the lowest set bit, as an explicit
  // 4-level prefix-OR tree.  pfx_or8[i] = |a_hit[i:0], so shifting left once
  // gives "some bit set strictly below i" = the wanted mask; a_hit == 0
  // collapses to all-zero.  The earlier form (a_hit & -a_hit, then
  // (a_low << 1) - 1) is equivalent but maps to two 16-bit carry chains in
  // series, which dominated this path on Spartan-3.
  wire [15:0] pfx_or1 = a_hit   | {a_hit[14:0],   1'b0};
  wire [15:0] pfx_or2 = pfx_or1 | {pfx_or1[13:0], 2'b0};
  wire [15:0] pfx_or4 = pfx_or2 | {pfx_or2[11:0], 4'b0};
  wire [15:0] pfx_or8 = pfx_or4 | {pfx_or4[7:0],  8'b0};
  wire [15:0] a_pfx   = {pfx_or8[14:0], 1'b0};

  wire [63:0] b_list  = b_lsel ? map_r : colormap_r;
  wire [63:0] mtf_res = mtf_apply(b_list, b_pfx, b_nib, b_any);

  // context selection for the current plane
  wire [3:0] bit_w = bpp1 ? (4'd1 << pix[1:0]) : (4'd1 << plane);
  wire [3:0] hist_w = (bit_w - 4'd1) & output_r[3:0];
  wire [2:0] set_w = bpp1 ? {2'b00, pix[2]} :
                     bpp2 ? diff_r :
                     ((plane[1]) && (hist_w <= 4'd1)) ? diff_r : 3'd0;
  wire [3:0] idx_w = bit_w + hist_w - 4'd1;

  // arithmetic step
  wire        c_swap  = ctx_q[20];
  wire [7:0]  c_prob  = ctx_q[19:12];
  wire [8:0]  lps_sub = range_r - {1'b0, c_prob};
  wire [7:0]  lps_off = lps_sub[7:0];

  // symbol is "input[15:8] >= lps_off", stated as "probability >= range -
  // input[15:8]" so that the probability -- the one operand that arrives late,
  // straight out of the context store -- crosses ONE carry chain instead of the
  // subtractor and the comparator in series.  The threshold is built from
  // registers only, so it is ready long before the context read lands.  The
  // +256 bias keeps both sides unsigned and ten bits wide, so nothing wraps:
  //     X >= R - P   <=>   P >= R - X   <=>   256+P >= 256+R-X
  // Same function as the original whenever R - P fits the eight bits of
  // lps_off, which the decoder guarantees at every step: renormalisation
  // leaves range in [128,256] and every probability the evolution table can
  // reach is in [1,0x5a], so R - P stays in [38,255].  The equivalence and
  // both bounds were enumerated exhaustively against the original expression
  // over the whole operating domain.
  wire [9:0]  sym_thr = {1'b0, range_r} + 10'd256 - {2'b00, input_r[15:8]};
  wire        symbol  = ({2'b01, c_prob} >= sym_thr);

  // range - lps_off is exactly {lps_sub[8], c_prob}: taking the low eight bits
  // of (range - probability) back out of range returns the probability, plus
  // the 256 the truncation removed.  True for every 9 bit range and 8 bit
  // probability, so the second subtractor of the old form is pure wiring.
  wire [8:0]  range_a = symbol ? {lps_sub[8], c_prob} : {1'b0, lps_off};
  wire [15:0] input_a = symbol ? (input_r - {lps_off, 8'h00}) : input_r;
  wire [3:0]  k_w     = norm_k(range_a);
  wire        swap_nx = c_swap ^ (symbol & (c_prob > 8'h55));

  // successor state, chosen after the fact from the two that were read
  wire [19:0] evo_q   = sym_r ? evo_q1 : evo_q0;

  // normalisation / input refill
  // The reference merges the refilled byte with "input += read()", but the two
  // operands can never overlap, so this is an OR -- which takes a 16 bit carry
  // chain off the end of the refill path.  Proof by induction on the invariant
  // "the low (8 - bits) bits of input are zero", which holds after the two
  // initial reads (bits = 8, nothing required) and is preserved by every step:
  //   * a batch of k shifts without a refill leaves (8 - bits) + k zeros and
  //     sets bits to bits - k, so (8 - bits_new) = (8 - bits) + k;
  //   * a batch WITH a refill shifts by k = bits + kb, so the shifted input
  //     ends with (8 - bits) + bits + kb = 8 + kb zeros while the byte lands in
  //     bits [kb, kb+7] -- disjoint -- and bits_new = 8 - kb leaves exactly the
  //     kb zeros the invariant then asks for;
  //   * the MPS/LPS rescale only subtracts from the top byte.
  // k is at most 7 and bits at least 1, so a batch needs at most one byte.
  // The disjointness is also asserted on live operands at every refill of the
  // decode test suite.
  wire        need_byte = (k_r != 4'd0) && (k_r >= bits_r);
  wire [3:0]  kb        = k_r - bits_r;
  wire [15:0] input_new = (input_a_r << k_r) |
                          (need_byte ? ({8'h00, fifo_dout} << kb) : 16'h0000);
  wire [3:0]  bits_new  = need_byte ? (4'd8 - kb) : (bits_r - k_r);
  wire [8:0]  range_new = range_a_r << k_r;

  wire        last_plane = bpp1 ? 1'b1 : bpp2 ? (plane == 2'd1) : (plane == 2'd3);
  wire        ar2_go = !(need_byte && fifo_empty) && !(last_plane && mtf_busy);
  wire        dec_pop = (dc_state == DC_AR2) && ar2_go && need_byte;
  wire        seq_pop = ((state == ST_BT_IN0) || (state == ST_BT_IN1)) && !fifo_empty;

  // the three events that move the FIFO pointers in the arbiter below, named
  // here so the occupancy counter tracks them exactly
  wire        fifo_push = (req_v && drom_ack && !req_owner && !pf_kill) ||
                          (!req_v && !la_busy && pf_need && pf_hole);
  wire        fifo_pop  = seq_pop || dec_pop;

  // pixel epilogue
  wire [3:0]  pe_raw = bpp1 ? {3'b000, output_r[0]} :
                       bpp2 ? {2'b00, output_r[1:0]} : output_r[3:0];
  wire [3:0]  pe_index = bpp1 ? {3'b000, pe_raw[0] ^ pixels_r[15]} : pe_raw;
  wire [63:0] pe_shift = map_r >> {pe_index, 2'b00};
  wire [3:0]  pe_nib = pe_shift[3:0];
  wire [63:0] pixels_new = bpp1 ? {pixels_r[62:0], pe_nib[0]} :
                           bpp2 ? {pixels_r[61:0], pe_nib[1:0]} :
                                  {pixels_r[59:0], pe_nib};

  // deinterleave: pure wiring (inverse Morton transform of the reference)
  wire [15:0] px16 = pixels_r[15:0];
  wire [31:0] px32 = pixels_r[31:0];
  wire [15:0] deint2 = {px16[14], px16[12], px16[10], px16[ 8],
                        px16[ 6], px16[ 4], px16[ 2], px16[ 0],
                        px16[15], px16[13], px16[11], px16[ 9],
                        px16[ 7], px16[ 5], px16[ 3], px16[ 1]};
  wire [31:0] deint4 = {px32[28], px32[24], px32[20], px32[16],
                        px32[12], px32[ 8], px32[ 4], px32[ 0],
                        px32[29], px32[25], px32[21], px32[17],
                        px32[13], px32[ 9], px32[ 5], px32[ 1],
                        px32[30], px32[26], px32[22], px32[18],
                        px32[14], px32[10], px32[ 6], px32[ 2],
                        px32[31], px32[27], px32[23], px32[19],
                        px32[15], px32[11], px32[ 7], px32[ 3]};

  // decode() start pulse, asserted combinationally so the decoder starts on the
  // same edge the sequencer enters its wait state
  wire dec_start = (state == ST_BT_DEC) ||
                   ((state == ST_BT_SEEK) && (seek_cnt != 16'd0)) ||
                   ((state == ST_F_SEEK)  && (row_seek != 8'd0));

  wire fill_needed = xfer_active && !(fill_sel ? buf_valid[1] : buf_valid[0]);

  // Clock 1 of the move-to-front schedule is the DC_PIX cycle itself, so its
  // stage A operand has to be latched during the cycle BEFORE it -- either the
  // DC_IDLE that starts a decode, or the last DC_AR2 of the previous pixel.
  // In the DC_AR2 case pixels_r is shifted on the very same edge, and the
  // shift makes the pc nibble of the next cycle identical to the pb nibble of
  // this one: pixels_new[17:16] == pixels_r[15:14] in 2bpp and
  // pixels_new[35:32] == pixels_r[31:28] in 4bpp, which is pb_w in both.  So
  // no part of pixels_new -- and in particular not the pixel epilogue that
  // produces it -- reaches this register.
  wire [3:0] pc_nxt   = (dc_state == DC_AR2) ? pb_w : pc_w;
  wire       nxt_is_pix = !bpp1 &&
                         (((dc_state == DC_IDLE) && dec_start) ||
                          ((dc_state == DC_AR2) && ar2_go && last_plane &&
                           (pix != 3'd7)));

  // $4800 read path: bank by (bit 4, bit 0), index with the bits between
  wire [4:0] off_mask = bpp1 ? 5'd7 : bpp2 ? 5'd15 : 5'd31;
  wire [2:0] rd_idx   = rd_off[3:1];
  wire [7:0] tb0_lo   = rd_off[0] ? tb0b[rd_idx] : tb0a[rd_idx];
  wire [7:0] tb0_hi   = rd_off[0] ? tb0d[rd_idx] : tb0c[rd_idx];
  wire [7:0] tb1_lo   = rd_off[0] ? tb1b[rd_idx] : tb1a[rd_idx];
  wire [7:0] tb1_hi   = rd_off[0] ? tb1d[rd_idx] : tb1c[rd_idx];
  wire [7:0] tb0_byte = rd_off[4] ? tb0_hi : tb0_lo;
  wire [7:0] tb1_byte = rd_off[4] ? tb1_hi : tb1_lo;
  assign dcu_ready = qdone && (rd_sel ? buf_valid[1] : buf_valid[0]);
  assign dcu_data  = dcu_ready ? (rd_sel ? tb1_byte : tb0_byte) : 8'h00;
  wire   rd_take   = rd_4800 && dcu_ready;
  wire   rd_wrap   = rd_take && (rd_off == off_mask);

  // Tile buffer fill.  The four byte offsets of a row -- 2r, 2r+1, 2r+16 and
  // 2r+17 -- are one per bank, so the bank index is the row itself; 1bpp puts
  // its single byte at offset r, which lands in bank a or b at r/2.
  wire       fill_wr  = (state == ST_F_ROW);
  wire [2:0] fill_idx = bpp1 ? {1'b0, row[2:1]} : row;
  wire       fill_a   = fill_wr && (!bpp1 || !row[0]);
  wire       fill_b   = fill_wr && (!bpp1 ||  row[0]);
  wire       fill_cd  = fill_wr && bpp4;
  wire [7:0] fill_db  = bpp1 ? result_r[7:0] : result_r[15:8];

  // Deliberately outside the sequencer's abort guard: a transfer restart
  // clears buf_valid and refills every readable byte from row 0 before the
  // page can be read again, so a byte written into an aborted fill is
  // overwritten before it is reachable.  Keeping the abort out of the write
  // enable is also what keeps these banks off the sequencer's fan-out.  No
  // reset either: nothing reads a page before buf_valid says it is filled.
  always @(posedge clkin) begin
    if(!fill_sel) begin
      if(fill_a)  tb0a[fill_idx] <= result_r[7:0];
      if(fill_b)  tb0b[fill_idx] <= fill_db;
      if(fill_cd) tb0c[row]      <= result_r[23:16];
      if(fill_cd) tb0d[row]      <= result_r[31:24];
    end else begin
      if(fill_a)  tb1a[fill_idx] <= result_r[7:0];
      if(fill_b)  tb1b[fill_idx] <= fill_db;
      if(fill_cd) tb1c[row]      <= result_r[23:16];
      if(fill_cd) tb1d[row]      <= result_r[31:24];
    end
  end

  // -------------------------------------------------------------------------
  // context / evolution port muxing
  // -------------------------------------------------------------------------
  always @* begin
    ctx_re    = 1'b0;
    ctx_raddr = {set_w, idx_w};
    ctx_we    = 1'b0;
    ctx_waddr = ctx_addr_r;
    ctx_wdata = norm_r ? {swap_nx_r, evo_q} : {swap_nx_r, ctx_q[19:0]};
    if(state == ST_BT_CLR) begin
      ctx_we    = 1'b1;
      ctx_waddr = clr_cnt;
      ctx_wdata = CTX_INIT;
    end else begin
      if(dc_state == DC_CTX) ctx_re = 1'b1;
      if((dc_state == DC_AR2) && ar2_go) ctx_we = 1'b1;
    end
  end

  // -------------------------------------------------------------------------
  // data ROM arbiter, load address unit, prefetch FIFO
  // -------------------------------------------------------------------------
  always @(posedge clkin) begin
    if(rst) begin
      req_v      <= 1'b0;
      req_owner  <= 1'b0;
      req_addr   <= 24'h000000;
      la_kill    <= 1'b0;
      pf_kill    <= 1'b0;
      la_st      <= 3'd0;
      la_cur     <= 24'h000000;
      dcu_mode_r <= 2'd0;
      dcu_addr_r <= 23'd0;
      fifo_wp    <= 4'd0;
      fifo_rp    <= 4'd0;
      fifo_cnt   <= 4'd0;
      pf_addr    <= 24'h000000;
      pf_en      <= 1'b0;
    end else begin
      if(req_v && drom_ack) begin
        req_v <= 1'b0;
        if(req_owner) begin
          if(!la_kill) begin
            case(la_st)
              3'd1: dcu_mode_r         <= drom_data[1:0];
              3'd2: dcu_addr_r[22:16]  <= drom_data[6:0];
              3'd3: dcu_addr_r[15:8]   <= drom_data;
              3'd4: dcu_addr_r[7:0]    <= drom_data;
              default: ;
            endcase
            la_st  <= (la_st == 3'd4) ? 3'd0 : (la_st + 3'd1);
            la_cur <= la_cur + 24'd1;
          end
          la_kill <= 1'b0;
        end else begin
          if(!pf_kill) begin
            fifo_mem[fifo_wp[2:0]] <= drom_data;
            fifo_wp <= fifo_wp + 4'd1;
          end
          pf_kill <= 1'b0;
        end
      end else if(!req_v) begin
        if(la_st != 3'd0) begin
          if(la_hole) begin
            case(la_st)
              3'd1: dcu_mode_r        <= 2'd0;
              3'd2: dcu_addr_r[22:16] <= 7'd0;
              3'd3: dcu_addr_r[15:8]  <= 8'h00;
              3'd4: dcu_addr_r[7:0]   <= 8'h00;
              default: ;
            endcase
            la_st  <= (la_st == 3'd4) ? 3'd0 : (la_st + 3'd1);
            la_cur <= la_cur + 24'd1;
          end else begin
            req_v     <= 1'b1;
            req_owner <= 1'b1;
            req_addr  <= la_masked;
          end
        end else if(pf_need) begin
          if(pf_hole) begin
            fifo_mem[fifo_wp[2:0]] <= 8'h00;
            fifo_wp <= fifo_wp + 4'd1;
            pf_addr <= pf_addr + 24'd1;
          end else begin
            req_v     <= 1'b1;
            req_owner <= 1'b0;
            req_addr  <= pf_masked;
            pf_addr   <= pf_addr + 24'd1;
          end
        end
      end

      if(seq_pop || dec_pop) fifo_rp <= fifo_rp + 4'd1;

      // $4804 write (re)starts the load address unit.  Last write to la_cur in
      // the block, so it beats the step above exactly as it already beats the
      // la_st advance next to it.
      if(we_4804) begin
        la_cur  <= {1'b0, q4803, q4802, q4801} + {14'd0, wdata, 2'b00};
        la_st   <= 3'd1;
        la_kill <= req_v && req_owner && !drom_ack;
      end

      // initialize(): the byte stream restarts at the decompression origin
      if(state == ST_BT_INIT) begin
        fifo_wp <= 4'd0;
        fifo_rp <= 4'd0;
        pf_addr <= {1'b0, dcu_addr_r};
        pf_en   <= 1'b1;
        pf_kill <= req_v && !req_owner && !drom_ack;
      end

      // occupancy, with the restart winning over a push or a pop exactly as it
      // does over the two pointers above
      if(state == ST_BT_INIT)          fifo_cnt <= 4'd0;
      else if(fifo_push && !fifo_pop)  fifo_cnt <= fifo_cnt + 4'd1;
      else if(fifo_pop  && !fifo_push) fifo_cnt <= fifo_cnt - 4'd1;
    end
  end

  // -------------------------------------------------------------------------
  // register writes, $4800 read side effects
  // -------------------------------------------------------------------------
  always @(posedge clkin) begin
    if(rst) begin
      q4801  <= 8'h00;  q4802 <= 8'h00;  q4803 <= 7'h00;
      q4804  <= 8'h00;  q4805 <= 8'h00;  q4806 <= 8'h00;  q4807 <= 8'h00;
      qcount <= 16'h0000;
      q480b  <= 2'b00;
    end else begin
      if(we_4801) q4801 <= wdata;
      if(we_4802) q4802 <= wdata;
      if(we_4803) q4803 <= wdata[6:0];
      if(we_4804) q4804 <= wdata;
      if(we_4805) q4805 <= wdata;
      if(we_4806) q4806 <= wdata;
      if(we_4807) q4807 <= wdata;
      if(we_4809) qcount[7:0]  <= wdata;
      if(we_480a) qcount[15:8] <= wdata;
      if(we_480b) q480b <= wdata[1:0];
      // the counter decrements on every $4800 read, done or not
      if(rd_4800 && !we_4809 && !we_480a) qcount <= qcount - 16'd1;
    end
  end

  // -------------------------------------------------------------------------
  // sequencer: begin transfer, seek, tile fill, buffer bookkeeping
  // -------------------------------------------------------------------------
  always @(posedge clkin) begin
    if(rst) begin
      state       <= ST_IDLE;
      bt_pending  <= 1'b0;
      xfer_active <= 1'b0;
      qdone       <= 1'b0;
      mode        <= 2'd0;
      clr_cnt     <= 7'd0;
      seek_cnt    <= 16'd0;
      row         <= 3'd0;
      row_seek    <= 8'd0;
      buf_valid   <= 2'b00;
      rd_sel      <= 1'b0;
      fill_sel    <= 1'b0;
      rd_off      <= 5'd0;
      bits_r      <= 4'd8;
      range_r     <= 9'd256;
      input_r     <= 16'h0000;
      output_r    <= 8'h00;
      pixels_r    <= 64'd0;
      colormap_r  <= CMAP_INIT;
      map_r       <= CMAP_INIT;
      result_r    <= 32'd0;
    end else begin
      if(bt_abort) begin
        // a new transfer discards every decoder and buffer state, so aborting
        // an in-flight background fill here is safe
        bt_pending  <= 1'b0;
        xfer_active <= 1'b0;
        buf_valid   <= 2'b00;
        state       <= ST_BT_CHK;
      end else begin
        case(state)
          ST_IDLE: begin
            if(fill_needed) begin
              row   <= 3'd0;
              state <= ST_F_ROW;
            end
          end

          // dcuBeginTransfer(): mode 3 is invalid, nothing happens at all
          ST_BT_CHK: begin
            if(dcu_mode_r == 2'd3) begin
              state <= ST_IDLE;
            end else begin
              mode    <= dcu_mode_r;
              clr_cnt <= 7'd0;
              state   <= ST_BT_CLR;
            end
          end

          // initialize(): clear the context model
          ST_BT_CLR: begin
            clr_cnt <= clr_cnt + 7'd1;
            if(clr_cnt == 7'd79) state <= ST_BT_INIT;
          end

          ST_BT_INIT: begin
            bits_r     <= 4'd8;
            range_r    <= 9'd256;
            output_r   <= 8'h00;
            pixels_r   <= 64'd0;
            colormap_r <= CMAP_INIT;
            map_r      <= CMAP_INIT;
            result_r   <= 32'd0;
            state      <= ST_BT_IN0;
          end

          // input = read() << 8 | read()
          ST_BT_IN0: begin
            if(!fifo_empty) begin
              input_r[15:8] <= fifo_dout;
              state         <= ST_BT_IN1;
            end
          end
          ST_BT_IN1: begin
            if(!fifo_empty) begin
              input_r[7:0] <= fifo_dout;
              seek_cnt     <= q480b[1] ? {q4806, q4805} : 16'd0;
              state        <= ST_BT_DEC;
            end
          end

          ST_BT_DEC:  state <= ST_BT_DECW;
          ST_BT_DECW: if(!dc_busy) state <= ST_BT_SEEK;

          // while(seek--) decode();
          ST_BT_SEEK: begin
            if(seek_cnt == 16'd0) begin
              state <= ST_BT_ARM;
            end else begin
              seek_cnt <= seek_cnt - 16'd1;
              state    <= ST_BT_SKW;
            end
          end
          ST_BT_SKW: if(!dc_busy) state <= ST_BT_SEEK;

          ST_BT_ARM: begin
            xfer_active <= 1'b1;
            buf_valid   <= 2'b00;
            rd_sel      <= 1'b0;
            fill_sel    <= 1'b0;
            rd_off      <= 5'd0;
            state       <= ST_IDLE;
          end

          // dcuRead() tile refill: the row is stored by the tile buffer block
          // above, this only arms the seek to the next one
          ST_F_ROW: begin
            row_seek <= q480b[0] ? q4807 : 8'd1;
            state    <= ST_F_SEEK;
          end

          ST_F_SEEK: begin
            if(row_seek == 8'd0) begin
              if(row == 3'd7) begin
                if(fill_sel) buf_valid[1] <= 1'b1;
                else         buf_valid[0] <= 1'b1;
                fill_sel            <= ~fill_sel;
                qdone               <= 1'b1;
                state               <= ST_IDLE;
              end else begin
                row   <= row + 3'd1;
                state <= ST_F_ROW;
              end
            end else begin
              row_seek <= row_seek - 8'd1;
              state    <= ST_F_SKW;
            end
          end
          ST_F_SKW: if(!dc_busy) state <= ST_F_SEEK;

          default: state <= ST_IDLE;
        endcase

        // ------------------------------------------------------------------
        // decoder writes into the shared decompressor state
        // ------------------------------------------------------------------
        if(b_valid) begin
          if(b_dest) map_r      <= mtf_res;
          else       colormap_r <= mtf_res;
        end

        if(dc_state == DC_AR1) begin
          output_r <= {output_r[6:0], symbol ^ c_swap};
        end

        if((dc_state == DC_AR2) && ar2_go) begin
          range_r <= range_new;
          input_r <= input_new;
          bits_r  <= bits_new;
          if(last_plane) pixels_r <= pixels_new;
        end

        if(dc_state == DC_END) begin
          result_r <= bpp1 ? pixels_r[31:0] :
                      bpp2 ? {16'h0000, deint2} : deint4;
        end
      end

      // ------------------------------------------------------------------
      // $4800 consumption: never blocks, always serves the buffered byte
      // ------------------------------------------------------------------
      if(rd_take) begin
        if(rd_wrap) begin
          rd_off              <= 5'd0;
          if(rd_sel) buf_valid[1] <= 1'b0;
          else       buf_valid[0] <= 1'b0;
          rd_sel              <= ~rd_sel;
        end else begin
          rd_off <= rd_off + 5'd1;
        end
      end

      // $4806 write arms a transfer and clears the done flag.  Last in the
      // block on purpose: it must override a fill that completes in the very
      // same cycle, and it must re-arm bt_pending even when an abort is being
      // taken right now.
      if(we_4806) begin
        qdone      <= 1'b0;
        bt_pending <= 1'b1;
      end
    end
  end

  // -------------------------------------------------------------------------
  // decoder: one decode() call
  // -------------------------------------------------------------------------
  always @(posedge clkin) begin
    if(rst) begin
      dc_state  <= DC_IDLE;
      dc_busy   <= 1'b0;
      mtf_ph    <= 3'd0;
      b_valid    <= 1'b0;
      a_fire    <= 1'b0;
      a_nib     <= 4'd0;
      a_lsel    <= 1'b0;
      a_dest    <= 1'b0;
      pix       <= 3'd0;
      plane     <= 2'd0;
      diff_r    <= 3'd0;
      pa_r      <= 4'd0;
      pb_r      <= 4'd0;
      pc_r      <= 4'd0;
      ctx_addr_r<= 7'd0;
      k_r       <= 4'd0;
      input_a_r <= 16'h0000;
      range_a_r <= 9'd0;
      norm_r    <= 1'b0;
      swap_nx_r <= 1'b0;
      sym_r     <= 1'b0;
    end else if(bt_abort) begin
      dc_state <= DC_IDLE;
      dc_busy  <= 1'b0;
      mtf_ph   <= 3'd0;
      b_valid   <= 1'b0;
      a_fire   <= 1'b0;
    end else begin
      // move-to-front chain, running beside the plane loop
      if(dc_state == DC_PIX) mtf_ph <= 3'd2;
      else if(mtf_ph != 3'd0) mtf_ph <= (mtf_ph == 3'd6) ? 3'd0 : (mtf_ph + 3'd1);

      // Stage A operand of the NEXT clock.  The four arms are the four clocks
      // of the schedule above, each decoded one clock early: the arm that fires
      // clock 1 runs in the cycle before DC_PIX, the arm that fires clock 2
      // runs in DC_PIX itself (pa_w is what pa_r is being loaded with on this
      // same edge), and clocks 3 and 5 come off mtf_ph 2 and 4.  The four are
      // mutually exclusive by construction: DC_PIX is only ever entered with
      // the chain idle, because ar2_go holds the last plane of a pixel back
      // while mtf_busy is set, so mtf_ph is 0 in DC_PIX and in the cycle before
      // it.
      if(nxt_is_pix) begin
        a_fire <= 1'b1;  a_nib <= pc_nxt;  a_lsel <= 1'b0;  a_dest <= 1'b1;
      end else if(dc_state == DC_PIX) begin
        a_fire <= 1'b1;  a_nib <= pa_w;    a_lsel <= 1'b0;  a_dest <= 1'b0;
      end else if(mtf_ph == 3'd2) begin
        a_fire <= 1'b1;  a_nib <= pb_r;    a_lsel <= 1'b1;  a_dest <= 1'b1;
      end else if(mtf_ph == 3'd4) begin
        a_fire <= 1'b1;  a_nib <= pa_r;    a_lsel <= 1'b1;  a_dest <= 1'b1;
      end else begin
        a_fire <= 1'b0;
      end

      // stage A latches everything stage B needs on the next clock
      b_valid <= a_fire;
      if(a_fire) begin
        b_pfx  <= a_pfx;
        b_any  <= |a_hit;
        b_nib  <= a_nib;
        b_lsel <= a_lsel;
        b_dest <= a_dest;
      end

      case(dc_state)
        DC_IDLE: begin
          if(dec_start) begin
            dc_busy <= 1'b1;
            pix     <= 3'd0;
            plane   <= 2'd0;
            dc_state <= bpp1 ? DC_CTX : DC_PIX;
          end
        end

        // pixel setup: latch pa/pb/pc/diff and update the colormap
        DC_PIX: begin
          pa_r   <= pa_w;
          pb_r   <= pb_w;
          pc_r   <= pc_w;
          diff_r <= diff_w;
          plane  <= 2'd0;
          dc_state <= DC_CTX;
        end

        // issue the context read
        DC_CTX: begin
          ctx_addr_r <= {set_w, idx_w};
          dc_state   <= DC_AR1;
        end

        // symbol decision; both evolution ROM reads for the writeback land at
        // the end of this state and sym_r picks between them
        DC_AR1: begin
          k_r       <= k_w;
          input_a_r <= input_a;
          range_a_r <= range_a;
          norm_r    <= (k_w != 4'd0);
          swap_nx_r <= swap_nx;
          sym_r     <= symbol;
          dc_state  <= DC_AR2;
        end

        // renormalisation, refill, context writeback, pixel epilogue
        DC_AR2: begin
          if(ar2_go) begin
            if(!last_plane) begin
              plane    <= plane + 2'd1;
              dc_state <= DC_CTX;
            end else if(pix != 3'd7) begin
              pix      <= pix + 3'd1;
              dc_state <= bpp1 ? DC_CTX : DC_PIX;
            end else begin
              dc_state <= DC_END;
            end
          end
        end

        DC_END: begin
          dc_busy  <= 1'b0;
          dc_state <= DC_IDLE;
        end

        default: dc_state <= DC_IDLE;
      endcase
    end
  end

endmodule

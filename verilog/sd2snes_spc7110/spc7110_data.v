// ---------------------------------------------------------------------------
// spc7110_data.v -- SPC7110 data port unit: 23 bit offset, adjust, stride and
// the four auto-increment sources behind the $4810-$481A register block.
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
// Behaviour (ares data.cpp + the $4810-$481A cases of spc7110.cpp):
//
//   r4818 bit 0  stride enabled (otherwise the stride is 1)
//        bit 1   the adjust is added to the offset at READ time
//        bit 2   the stride is signed
//        bit 3   the adjust is signed
//        bit 4   the auto-increment target is the ADJUST, not the offset
//        bits 6:5 auto-increment source:
//                 0 = only a $4810 read
//                 1 = also a $4814 write
//                 2 = also a $4815 write
//                 3 = also a $481A read
//        (a write to $4818 keeps 7 bits and always re-reads)
//
//   Every event listed below updates the registers in its own cycle and then
//   launches ONE data ROM read in the background; $4810 always returns the
//   byte that is already buffered, so a register read never stalls the SNES
//   bus (reads always serve the already-buffered byte).
//
//     write $4813 : offset high byte (7 bits), then read
//     write $4814 : adjust low byte,  then offset += adjust when source == 1
//     write $4815 : adjust high byte, then offset += adjust when source == 2;
//                   when the source is not 2 the write still re-reads if bit 1
//                   is set.  (The reference performs that first read even when
//                   source == 2, but the increment immediately reads again and
//                   overwrites it, so only the second read is issued here.)
//     write $4818 : settings, then read
//     read  $4810 : offset += stride (or adjust += stride when bit 4), read
//     read  $481A : offset += adjust when source == 3, then read
//
//   The dataromRead() pre-masking of the reference lives HERE (inside the
//   section 2): the offset is masked with (0x100000 << drom_size) - 1, and an
//   address carrying 0x400000 with a data ROM smaller than 8 MB serves 0x00
//   without touching the bus at all.  The mirroring of the PHYSICAL data ROM
//   image is the integration's DROM_MASK, outside this module.
//
//   PIPELINE (mk2 timing pass).  The read address is produced ONE CYCLE after
//   the event that asks for it.  The reason is timing: computing it in the
//   event cycle means "offset + stride" feeding "+ adjust", two 23 bit adders
//   in series behind the stride and settings muxes -- 12 levels of logic, the
//   worst path of the Spartan-3 flavor.  Since dataPortRead() reads with the
//   offset and the settings the event LEAVES BEHIND, the address is simply
//   "off + adjust" over the registers on the next cycle, so the two adders
//   land in different cycles and neither feeds the other.
//   The extra clock only delays when drom_req goes up; the data ROM latency
//   is arbitrary by contract, $4810 still answers from the buffered byte, and
//   no register read-back is delayed by it.  Back to back events keep the
//   "last event wins the pending slot" behaviour of the unpipelined version.
//
//   Interface assumption shared with spc7110_regs: every we_*/rd_* strobe is
//   a ONE cycle pulse and at most one of them is high at a time (they come
//   from a single decoded SNES access).  When two would overlap the case
//   below resolves them in the listed order, but the SNES bus cannot produce
//   that.
//
//   Widths that matter: r4813 is 7 bits, so the stored offset is 23 bits and
//   both offset arithmetic and the read address wrap at that boundary exactly
//   like the n24 -> setDataOffset() path of the reference.
// ---------------------------------------------------------------------------
module spc7110_data(
  input              clkin,
  input              rst,

  // register writes ($4811-$4818, $481A)
  input              we_4811,
  input              we_4812,
  input              we_4813,
  input              we_4814,
  input              we_4815,
  input              we_4816,
  input              we_4817,
  input              we_4818,
  input              we_481a,   // no register behind it; kept for the decoder
  input       [7:0]  wdata,

  // read strobes with a side effect
  input              rd_4810,
  input              rd_481a,

  // r4834[1:0]: data ROM size, drives the dataromRead() pre-masking
  input       [1:0]  drom_size,

  // read-back
  output      [7:0]  r4810,
  output      [7:0]  r4811,
  output      [7:0]  r4812,
  output      [7:0]  r4813,
  output      [7:0]  r4814,
  output      [7:0]  r4815,
  output      [7:0]  r4816,
  output      [7:0]  r4817,
  output      [7:0]  r4818,
  output      [7:0]  r481a,

  // data ROM port (req/ack handshake, one byte per transaction)
  output             drom_req,
  output      [23:0] drom_addr,
  input              drom_ack,
  input       [7:0]  drom_data
);

  // -------------------------------------------------------------------------
  // state
  // -------------------------------------------------------------------------
  reg [22:0] off;      // $4811-$4813 (the high byte keeps 7 bits)
  reg [15:0] adj;      // $4814-$4815
  reg [15:0] strd;     // $4816-$4817
  reg [6:0]  cfg;      // $4818
  reg [7:0]  dbyte;    // $4810

  assign r4810 = dbyte;
  assign r4811 = off[7:0];
  assign r4812 = off[15:8];
  assign r4813 = {1'b0, off[22:16]};
  assign r4814 = adj[7:0];
  assign r4815 = adj[15:8];
  assign r4816 = strd[7:0];
  assign r4817 = strd[15:8];
  assign r4818 = {1'b0, cfg};
  assign r481a = 8'h00;   // the reference always returns 0x00 here

  // -------------------------------------------------------------------------
  // combinational event decode
  // -------------------------------------------------------------------------
  // stride, sign extended when bit 2 is set
  wire [15:0] strd_sel = cfg[0] ? strd : 16'h0001;
  wire [22:0] strd_ext = cfg[2] ? {{7{strd_sel[15]}}, strd_sel}
                                : {7'h00, strd_sel};

  reg  [15:0] adj_wr;      // $4814/$4815 after the byte write of THIS event
  reg  [15:0] adj_nx;      // next value of $4814-$4815
  reg  [22:0] off_nx;      // next value of $4811-$4813
  reg         ev_read;     // this event launches a data ROM read

  // The adjust that an event adds to the OFFSET is always the byte-written
  // one, never the stride-incremented one: the increment belongs to the
  // $4810 read strobe and the offset-plus-adjust events are other strobes.
  // Keeping the two apart is what stops synthesis from stringing the 16 bit
  // adjust adder in front of the 23 bit offset adder.
  wire [22:0] adj_off = cfg[3] ? {{7{adj_wr[15]}}, adj_wr} : {7'h00, adj_wr};

  always @* begin
    // ---- $4814/$4815 byte writes and the bit 4 increment target ------------
    adj_wr = adj;
    if(we_4814) adj_wr = {adj[15:8], wdata};
    if(we_4815) adj_wr = {wdata, adj[7:0]};

    adj_nx = (rd_4810 && cfg[4]) ? (adj + strd_ext[15:0]) : adj_wr;

    // ---- offset update and read launch -------------------------------------
    off_nx  = off;
    ev_read = 1'b0;

    case(1'b1)
      we_4811: off_nx = {off[22:8], wdata};
      we_4812: off_nx = {off[22:16], wdata, off[7:0]};
      we_4813: begin
        off_nx  = {wdata[6:0], off[15:0]};
        ev_read = 1'b1;
      end
      we_4814: begin
        if(cfg[6:5] == 2'd1) begin
          off_nx  = off + adj_off;
          ev_read = 1'b1;
        end
      end
      we_4815: begin
        if(cfg[6:5] == 2'd2) begin
          off_nx  = off + adj_off;
          ev_read = 1'b1;
        end else if(cfg[1]) begin
          ev_read = 1'b1;
        end
      end
      we_4818: ev_read = 1'b1;
      rd_4810: begin
        if(!cfg[4]) off_nx = off + strd_ext;
        ev_read = 1'b1;
      end
      rd_481a: begin
        if(cfg[6:5] == 2'd3) begin
          off_nx  = off + adj_off;
          ev_read = 1'b1;
        end
      end
      default: ;
    endcase

  end

  // -------------------------------------------------------------------------
  // read address, ONE PIPELINE STAGE BEHIND THE EVENT
  // -------------------------------------------------------------------------
  // dataPortRead() is dataromRead(offset + adjust) with the offset and the
  // settings the event LEAVES BEHIND, so the address is exactly what the
  // registers hold on the cycle AFTER the event -- no need to compute it from
  // the pre-event state through a second adder in the same cycle.  The
  // reference truncates the sum to 24 bits, but bit 23 is dead downstream
  // (see size_mask), so the whole path is kept 23 bits wide.
  wire [22:0] adj_rd  = cfg[3] ? {{7{adj[15]}}, adj} : {7'h00, adj};
  wire [22:0] radj_rd = cfg[1] ? adj_rd : 23'h000000;
  wire [22:0] addr_c  = off + radj_rd;

  // -------------------------------------------------------------------------
  // dataromRead() pre-masking (see the ares reference)
  // -------------------------------------------------------------------------
  // 23 bits: every mask clears bit 23 of the read address and only bit 22
  // drives the 0x400000 guard, so bit 23 of "offset + adjust" is dead and is
  // never carried around.
  reg [22:0] size_mask;
  always @* begin
    case(drom_size)
      2'd0:    size_mask = 23'h0fffff;   //  8 Mbit
      2'd1:    size_mask = 23'h1fffff;   // 16 Mbit
      2'd2:    size_mask = 23'h3fffff;   // 32 Mbit
      default: size_mask = 23'h7fffff;   // 64 Mbit
    endcase
  end

  // -------------------------------------------------------------------------
  // background data ROM engine: at most one request in flight, request held
  // until ack, address stable while the request is up
  // -------------------------------------------------------------------------
  reg        rd_arm;       // stage 1: an event asked for a read this cycle
  reg        rd_pend;      // stage 2: rd_addr holds the address to fetch
  reg [22:0] rd_addr;
  reg        busy;
  reg        req_v;
  reg [22:0] req_addr;

  // "if((r4834 & 3) != 3 && (address & 0x400000)) return 0x00;"
  wire rd_kill = (drom_size != 2'd3) & rd_addr[22];

  // Handshake rule: the request is a level held until the ack, and it
  // drops COMBINATIONALLY on the ack cycle -- a level sensitive arbiter must
  // never see the same request twice.
  assign drom_req  = req_v & ~drom_ack;
  assign drom_addr = {1'b0, req_addr};

  always @(posedge clkin) begin
    if(rst) begin
      off      <= 23'h000000;
      adj      <= 16'h0000;
      strd     <= 16'h0000;
      cfg      <= 7'h00;
      dbyte    <= 8'h00;
      rd_arm   <= 1'b0;
      rd_pend  <= 1'b0;
      rd_addr  <= 23'h000000;
      busy     <= 1'b0;
      req_v    <= 1'b0;
      req_addr <= 23'h000000;
    end else begin
      off <= off_nx;
      adj <= adj_nx;
      if(we_4816) strd[7:0]  <= wdata;
      if(we_4817) strd[15:8] <= wdata;
      if(we_4818) cfg        <= wdata[6:0];

      // ---- engine ---------------------------------------------------------
      if(busy) begin
        if(drom_ack) begin
          dbyte <= drom_data;
          busy  <= 1'b0;
          req_v <= 1'b0;
        end
      end else if(rd_pend) begin
        rd_pend <= 1'b0;
        if(rd_kill) begin
          // outside the visible data ROM: serve 0x00, never touch the bus
          dbyte <= 8'h00;
        end else begin
          req_v    <= 1'b1;
          req_addr <= rd_addr & size_mask;
          busy     <= 1'b1;
        end
      end

      // ---- pipeline stage 1 -> 2 -------------------------------------------
      // One cycle after the event, off/adj/cfg already hold the post-event
      // state, so addr_c IS the address dataPortRead() would compute.  This
      // is the split that keeps the two 23 bit adders (offset update and
      // offset+adjust) in different cycles instead of in series.
      // The assignments sit AFTER the engine block so an address latched in
      // the very cycle the engine consumed the previous one is not lost.
      if(rd_arm) begin
        rd_pend <= 1'b1;
        rd_addr <= addr_c;
      end
      rd_arm <= ev_read;
    end
  end

endmodule

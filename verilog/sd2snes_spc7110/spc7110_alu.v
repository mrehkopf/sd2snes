// ---------------------------------------------------------------------------
// spc7110_alu.v -- SPC7110 arithmetic logic unit: 16x16 multiply and 32/16
// divide, signed or unsigned, behind the $4820-$482F register block.
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
// Behaviour (ares alu.cpp + the $4820-$482F cases of spc7110.cpp):
//   - a write to $4825 latches the multiplier high byte, sets r482f |= 0x81
//     and queues a multiply;  a write to $4827 latches the divisor high byte,
//     sets r482f |= 0x80 and queues a divide;  either unit clears ONLY bit 7
//     when it finishes (r482f &= 0x7f), so bit 0 stays set forever once the
//     first multiply has been triggered.
//     Bit 7 is therefore not a plain flip-flop: it reads
//     "busy | mul_pending | div_pending", so a unit that
//     finishes while the OTHER one is still queued cannot report idle with
//     the queued operands not yet consumed.  Bit 0 is the only stored bit.
//   - $482E keeps bit 0 only; that bit selects signed arithmetic.
//   - divide by zero yields quotient 0 and remainder = dividend[15:0].
//   - signed divide truncates toward zero and the remainder takes the sign of
//     the dividend, which is what the C++ operators of the reference do.
//     0x80000000 / -1 has no representable quotient: the restoring divider
//     wraps to 0x80000000 with remainder 0 (two's complement; what a restoring
//     divider produces naturally -- unverified on real silicon).
//
// Interface assumption shared with spc7110_regs: every we_* strobe is a ONE
// cycle pulse and at most one of them is high at a time (they come from a
// single decoded SNES write).  A strobe held high for several cycles would
// queue one operation per cycle.
//
// Structure:
//   - multiply : one registered signed 17x17 product (fits an embedded 18x18
//                multiplier of the Cyclone IV), 3 clocks end to end.
//   - divide   : restoring shift/subtract, 1 quotient bit per clock, 32
//                iterations, ~36 clocks end to end.  Both are far inside the
//                the design budgets (multiply <= 64 clocks, divide <= 96).
// ---------------------------------------------------------------------------
module spc7110_alu(
  input              clkin,
  input              rst,

  // register writes ($4820-$4827, $482E)
  input              we_4820,
  input              we_4821,
  input              we_4822,
  input              we_4823,
  input              we_4824,
  input              we_4825,
  input              we_4826,
  input              we_4827,
  input              we_482e,
  input       [7:0]  wdata,

  // read-back
  output      [7:0]  r4820,
  output      [7:0]  r4821,
  output      [7:0]  r4822,
  output      [7:0]  r4823,
  output      [7:0]  r4824,
  output      [7:0]  r4825,
  output      [7:0]  r4826,
  output      [7:0]  r4827,
  output      [7:0]  r4828,
  output      [7:0]  r4829,
  output      [7:0]  r482a,
  output      [7:0]  r482b,
  output      [7:0]  r482c,
  output      [7:0]  r482d,
  output      [7:0]  r482e,
  output      [7:0]  r482f
);

  // -------------------------------------------------------------------------
  // operand / result registers
  // -------------------------------------------------------------------------
  reg  [7:0]  q4820, q4821, q4822, q4823;   // multiplicand B0-B1 / dividend
  reg  [7:0]  q4824, q4825;                 // multiplier
  reg  [7:0]  q4826, q4827;                 // divisor
  reg  [31:0] res;                          // $4828-$482B (product / quotient)
  reg  [15:0] rmd;                          // $482C-$482D (remainder)
  reg         sgn;                          // $482E bit 0
  reg         sticky0;                      // $482F bit 0: set by $4825 forever

  assign r4820 = q4820;
  assign r4821 = q4821;
  assign r4822 = q4822;
  assign r4823 = q4823;
  assign r4824 = q4824;
  assign r4825 = q4825;
  assign r4826 = q4826;
  assign r4827 = q4827;
  assign r4828 = res[7:0];
  assign r4829 = res[15:8];
  assign r482a = res[23:16];
  assign r482b = res[31:24];
  assign r482c = rmd[7:0];
  assign r482d = rmd[15:8];
  assign r482e = {7'b0, sgn};
  // r482f is assigned below, next to the sequencer state it reports

  // -------------------------------------------------------------------------
  // operand views, taken at the moment an operation starts
  // -------------------------------------------------------------------------
  wire [31:0] dividend = {q4823, q4822, q4821, q4820};
  wire [15:0] divisor  = {q4827, q4826};
  wire [15:0] mcand    = {q4821, q4820};
  wire [15:0] mplier   = {q4825, q4824};

  wire        dvd_neg  = sgn & dividend[31];
  wire        dsr_neg  = sgn & divisor[15];
  wire [31:0] dvd_mag  = dvd_neg ? (~dividend + 32'd1) : dividend;
  wire [15:0] dsr_mag  = dsr_neg ? (~divisor  + 16'd1) : divisor;

  // -------------------------------------------------------------------------
  // sequencer
  // -------------------------------------------------------------------------
  localparam [2:0] ST_IDLE = 3'd0,
                   ST_MUL0 = 3'd1,
                   ST_MUL1 = 3'd2,
                   ST_DIV  = 3'd3,
                   ST_FIX  = 3'd4;

  reg  [2:0]  state;
  reg         mul_pending, div_pending;
  wire        busy = (state != ST_IDLE);

  // $482F: bit 7 = busy or queued, bit 0 sticks once a multiply was requested
  assign r482f = {busy | mul_pending | div_pending, 6'b0, sticky0};

  // multiply datapath -- signed 17x17 covers both signed and unsigned 16x16
  reg  signed [16:0] ma, mb;
  reg  signed [33:0] mprod;

  // divide datapath
  reg  [31:0] dvd;                          // quotient accumulates from the LSB
  reg  [16:0] rem;
  reg  [15:0] dsr;
  reg  [5:0]  cnt;
  reg         q_neg, r_neg;

  wire [16:0] rem_shift = {rem[15:0], dvd[31]};
  wire [17:0] rem_diff  = {1'b0, rem_shift} - {2'b0, dsr};
  wire        rem_ge    = ~rem_diff[17];

  always @(posedge clkin) begin
    if(rst) begin
      state       <= ST_IDLE;
      mul_pending <= 1'b0;
      div_pending <= 1'b0;
      sticky0     <= 1'b0;
      ma          <= 17'sd0;
      mb          <= 17'sd0;
      mprod       <= 34'sd0;
      dvd         <= 32'h0;
      rem         <= 17'h0;
      dsr         <= 16'h0;
      cnt         <= 6'd0;
      q_neg       <= 1'b0;
      r_neg       <= 1'b0;
      res         <= 32'h0;
      rmd         <= 16'h0;
      q4820       <= 8'h00;
      q4821       <= 8'h00;
      q4822       <= 8'h00;
      q4823       <= 8'h00;
      q4824       <= 8'h00;
      q4825       <= 8'h00;
      q4826       <= 8'h00;
      q4827       <= 8'h00;
      sgn         <= 1'b0;
    end else begin
      case(state)
        ST_IDLE: begin
          // ares main(): the multiply is serviced before the divide
          if(mul_pending) begin
            mul_pending <= 1'b0;
            ma    <= {sgn & mcand[15],  mcand};
            mb    <= {sgn & mplier[15], mplier};
            state <= ST_MUL0;
          end else if(div_pending) begin
            div_pending <= 1'b0;
            q_neg <= dvd_neg ^ dsr_neg;
            r_neg <= dvd_neg;
            dsr   <= dsr_mag;
            if(divisor == 16'h0000) begin
              // illegal division by zero: quotient 0, remainder = dividend
              dvd   <= 32'h0;
              rem   <= {1'b0, dividend[15:0]};
              q_neg <= 1'b0;
              r_neg <= 1'b0;
              cnt   <= 6'd0;
            end else begin
              dvd <= dvd_mag;
              rem <= 17'h0;
              cnt <= 6'd32;
            end
            state <= ST_DIV;
          end
        end

        ST_MUL0: begin
          mprod <= ma * mb;
          state <= ST_MUL1;
        end

        ST_MUL1: begin
          res   <= mprod[31:0];
          state <= ST_IDLE;
        end

        ST_DIV: begin
          if(cnt == 6'd0) begin
            state <= ST_FIX;
          end else begin
            rem <= rem_ge ? rem_diff[16:0] : rem_shift;
            dvd <= {dvd[30:0], rem_ge};
            cnt <= cnt - 6'd1;
          end
        end

        ST_FIX: begin
          // the result registers land on the same edge that drops busy, so
          // $482F bit 7 never falls before $4828-$482D are stable
          res   <= q_neg ? (~dvd       + 32'd1) : dvd;
          rmd   <= r_neg ? (~rem[15:0] + 16'd1) : rem[15:0];
          state <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase

      // ----- register writes -------------------------------------------------
      if(we_4820) q4820 <= wdata;
      if(we_4821) q4821 <= wdata;
      if(we_4822) q4822 <= wdata;
      if(we_4823) q4823 <= wdata;
      if(we_4824) q4824 <= wdata;
      if(we_4825) begin q4825 <= wdata; mul_pending <= 1'b1; sticky0 <= 1'b1; end
      if(we_4826) q4826 <= wdata;
      if(we_4827) begin q4827 <= wdata; div_pending <= 1'b1; end
      if(we_482e) sgn   <= wdata[0];
    end
  end

endmodule

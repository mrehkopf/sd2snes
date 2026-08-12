`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// tb_regshadow_wide -- proves the defer arm is edge-guarded against a multi-cycle `pawr_end`.
// All four cores emit a 1-cycle strobe today; this TB asserts that (a) width==1 is
// bit-identical to the unguarded form and (b) widths 2/3/5 still reconstruct the
// (prev, current) pair instead of silently degrading to (value, value).
// Under REGSHADOW_1DEEP there is no defer at all (a single write per strobe cycle,
// idempotent while the strobe is held), so the same stimulus must land the last byte.
//////////////////////////////////////////////////////////////////////////////////
`ifdef REGSHADOW_1DEEP
  `define P1(pa)  (9'h000 + (pa))
  `define P2(pa)  (9'h000 + (pa))
`else
  `define P1(pa)  (9'h000 + ((pa)<<1))
  `define P2(pa)  (9'h000 + ((pa)<<1) + 1)
`endif
`ifdef REGSHADOW_1DEEP
  `define BG1ST(lo,hi) (hi)
  `define M71ST(lo,hi) (hi)
`elsif REGSHADOW_NO_M7
  `define BG1ST(lo,hi) (lo)
  `define M71ST(lo,hi) (hi)
`else
  `define BG1ST(lo,hi) (lo)
  `define M71ST(lo,hi) (lo)
`endif

module tb_regshadow_wide;
  reg clk = 0; always #5 clk = ~clk;
  reg pawr_end = 0, wr_end = 0;
  reg [23:0] snes_addr = 0; reg [7:0] snes_pa = 0, snes_data = 0;
  reg [8:0] rd_addr = 0; wire [7:0] rd_data;
  integer errors = 0;

  regshadow dut(.clk(clk), .pawr_end(pawr_end), .wr_end(wr_end), .snes_addr(snes_addr),
                .snes_pa(snes_pa), .snes_data(snes_data), .rd_addr(rd_addr), .rd_data(rd_data));

  // PPU write with the strobe held high for `width` module cycles; PA/data are held
  // stable for the whole pulse (that is what a real widened strobe would look like,
  // since the taps are latched during the /PAWR window), then the bus goes to junk.
  task ppuw_w(input [7:0] pa, input [7:0] d, input integer width);
    integer i;
    begin
      @(negedge clk); snes_pa = pa; snes_data = d; pawr_end = 1;
      for (i = 0; i < width; i = i + 1) @(negedge clk);
      pawr_end = 0; snes_data = 8'hAA; snes_pa = 8'h7F;   // junk after the pulse
      repeat (8) @(negedge clk);
    end
  endtask

  task chk(input [8:0] off, input [7:0] exp, input [255:0] name);
    begin
      rd_addr = off; @(posedge clk); @(posedge clk);
      if (rd_data !== exp) begin
        errors = errors + 1;
        $display("  FAIL %0s mem[$%03h]=$%02h exp $%02h", name, off, rd_data, exp);
      end else
        $display("  OK   %0s mem[$%03h]=$%02h", name, off, rd_data);
    end
  endtask

  // BG1HOFS ($210D) written low-then-high, the Star Fox scroll case.
  task bg_pair_at_width(input integer w);
    begin
      $display("== strobe width %0d: $210D <- $F8 then $01 ==", w);
      ppuw_w(8'h0D, 8'hF8, w);
      ppuw_w(8'h0D, 8'h01, w);
      chk(`P1(8'h0D), `BG1ST(8'hF8, 8'h01), "BG1HOFS 1st");
      chk(`P2(8'h0D), 8'h01,                "BG1HOFS 2nd");
    end
  endtask

  initial begin
`ifdef REGSHADOW_1DEEP
    $display("### mode: REGSHADOW_1DEEP (no defer; wide strobe = idempotent rewrite) ###");
`else
 `ifdef REGSHADOW_NO_M7
    $display("### mode: REGSHADOW_NO_M7 ###");
 `else
    $display("### mode: default ###");
 `endif
`endif
    repeat (4) @(negedge clk);

    bg_pair_at_width(1);   // the real hardware case -- must stay byte-identical
    bg_pair_at_width(2);   // degrades to (v,v) without the ~wr2_pend guard
    bg_pair_at_width(3);
    bg_pair_at_width(5);

    $display("== width 3, M7A ($211B) pair ==");
    ppuw_w(8'h1B, 8'h20, 3); ppuw_w(8'h1B, 8'h01, 3);
    chk(`P1(8'h1B), `M71ST(8'h20, 8'h01), "M7A 1st");
    chk(`P2(8'h1B), 8'h01,                "M7A 2nd");

    $display("== width 4, non-double $2105 stays (v,v) ==");
    ppuw_w(8'h05, 8'h09, 4);
    chk(`P1(8'h05), 8'h09, "BGMODE 1st"); chk(`P2(8'h05), 8'h09, "BGMODE 2nd");

    $display("== width 2 burst across regs: $210D,$210E,$210D,$210E ==");
    ppuw_w(8'h0D, 8'h11, 2); ppuw_w(8'h0E, 8'h22, 2);
    ppuw_w(8'h0D, 8'h33, 2); ppuw_w(8'h0E, 8'h44, 2);
    // prev_bg is a single shared tracker (ctx.v semantics): the 1st-write slot of a
    // reg holds whatever byte went to ANY BG-double reg immediately before it.
    chk(`P1(8'h0D), `BG1ST(8'h22, 8'h33), "BG1HOFS 1st");
    chk(`P2(8'h0D), 8'h33,                "BG1HOFS 2nd");
    chk(`P1(8'h0E), `BG1ST(8'h33, 8'h44), "BG1VOFS 1st");
    chk(`P2(8'h0E), 8'h44,                "BG1VOFS 2nd");

    if (errors) $display("\n==> FAIL: %0d error(s)", errors);
    else        $display("\n==> PASS: strobe widths 1..5 handled correctly in this mode");
    $finish;
  end
endmodule

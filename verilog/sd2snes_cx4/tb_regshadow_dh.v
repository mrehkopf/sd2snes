`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// tb_regshadow_dh -- clock-accurate check of the CX4 savestate register-shadow capture
// (RAW-PULSE-ALIGNED shallow capture).  The 80 MHz CX4 /PAWR pulse is only ~4 FPGA
// cycles; the deep SNES_PA debounce (PAr[5]&[4], ~5 cyc) lagged past it, a cycle-count
// strobe overshot into the next store, and committing PA at the debounced rising edge
// grabbed the NEXT store's address in a tight BG-setup burst (STA $2107/$2108/$210B).
// Fix: take DATA, PA and the /PAWR gate all from the SAME shallow 1-cycle tap
// (SNES_*r[0]); latch during the pulse and commit at its end, so the current store's
// PA+DATA are captured together, before the next store's pulse.  This TB models the
// exact pipeline plus a TIGHT back-to-back burst (small inter-write gap) -- the case
// that corrupted the BG on hardware.
//////////////////////////////////////////////////////////////////////////////////
module tb_regshadow_dh;
  reg clk = 0;
  always #5 clk = ~clk;

  reg        SNES_PAWR_IN = 1'b1;
  reg  [7:0] SNES_PA_IN   = 8'h00;
  reg  [7:0] SNES_DATA    = 8'h00;

  reg [7:0] SNES_PAWRr = 8'b11111111;
  reg [7:0] SNES_PAr [6:0];
  reg [7:0] SNES_DATAr [1:0];
  integer k;
  initial begin
    for(k=0;k<7;k=k+1) SNES_PAr[k]=8'h00;
    SNES_DATAr[0]=8'h00; SNES_DATAr[1]=8'h00;
  end

  always @(posedge clk) begin
    SNES_PAWRr <= {SNES_PAWRr[6:0], SNES_PAWR_IN};
    SNES_PAr[6]<=SNES_PAr[5]; SNES_PAr[5]<=SNES_PAr[4]; SNES_PAr[4]<=SNES_PAr[3];
    SNES_PAr[3]<=SNES_PAr[2]; SNES_PAr[2]<=SNES_PAr[1]; SNES_PAr[1]<=SNES_PAr[0];
    SNES_PAr[0]<=SNES_PA_IN;
    SNES_DATAr[1]<=SNES_DATAr[0]; SNES_DATAr[0]<=SNES_DATA;
  end

  // ---- raw-pulse-aligned capture under test (verbatim plan for main.v) ----
  reg rs_pawr0_d = 1'b1;
  always @(posedge clk) rs_pawr0_d <= SNES_PAWRr[0];
  wire rs_commit = SNES_PAWRr[0] & ~rs_pawr0_d;   // /PAWR rising = pulse end
  reg [7:0] rs_data_l = 0, rs_pa_l = 0;
  always @(posedge clk) if(~SNES_PAWRr[0]) begin  // during the pulse (raw low, 1-cyc)
    rs_data_l <= SNES_DATAr[0];
    rs_pa_l   <= SNES_PAr[0];
  end

  reg  [8:0] rd_addr = 0;
  wire [7:0] rd_data;
  regshadow dut(
    .clk(clk), .pawr_end(rs_commit), .wr_end(1'b0),
    .snes_addr(24'h000000), .snes_pa(rs_pa_l), .snes_data(rs_data_l),
    .rd_addr(rd_addr), .rd_data(rd_data)
  );

  integer errors = 0;

  // single write with address setup/hold, /PAWR low `width`, then `gap` idle cycles
  task ppu_write(input [7:0] pa, input [7:0] data, input integer width, input integer gap);
    integer i;
    begin
      SNES_PA_IN = pa; @(posedge clk); @(posedge clk);
      SNES_DATA  = data; @(posedge clk);
      SNES_PAWR_IN = 1'b0;
      for(i=0;i<width;i=i+1) @(posedge clk);
      SNES_PAWR_IN = 1'b1;
      SNES_DATA = 8'hAA;                 // bus junk right after the write
      for(i=0;i<gap;i=i+1) @(posedge clk);
    end
  endtask

  task check(input [7:0] pa, input [7:0] expect_);
    begin
      // Read index must track whichever layout regshadow.v built (same gate as
      // main.v's regshadow_raddr).  Every PA exercised here is a NON-double reg, so
      // the expected byte is the same in both modes -- only the address moves.
`ifdef REGSHADOW_1DEEP
      rd_addr = {2'b00, pa[6:0]};                  // 1-deep: mem[PA]
`else
      // stride-2 pair layout: mem[{pa,1'b1}] = 2nd (current) write byte,
      // mem[{pa,1'b0}] = 1st write byte.  Non-double regs hold (v,v) in both
      // halves; check the current-byte half.
      rd_addr = {1'b0, pa[6:0], 1'b1};
`endif
      @(posedge clk); @(posedge clk);
      if(rd_data !== expect_) begin
        errors = errors + 1;
        $display("  FAIL mem[$%02h]=$%02h exp $%02h", pa, rd_data, expect_);
      end else
        $display("  OK   mem[$%02h]=$%02h", pa, rd_data);
    end
  endtask

  initial begin
    repeat(4) @(posedge clk);

    $display("== OBSEL alone, long pulse 12 (96MHz-like) ==");
    ppu_write(8'h01,8'h30,12,10); check(8'h01,8'h30);

    $display("== OBSEL alone, short pulse 4 (80MHz-like) ==");
    ppu_write(8'h01,8'h30,4,10); check(8'h01,8'h30);

    $display("== BG setup TIGHT burst: $2107/$2108/$210B, pulse 4, gap 3 (the failing case) ==");
    ppu_write(8'h07,8'h5c,4,3);
    ppu_write(8'h08,8'h50,4,3);
    ppu_write(8'h0b,8'h34,4,3);
    ppu_write(8'h05,8'h09,4,10);   // BGMODE logo depois
    check(8'h07,8'h5c); check(8'h08,8'h50); check(8'h0b,8'h34); check(8'h05,8'h09);

    $display("== OBSEL followed by a tight $21xx (must not contaminate) ==");
    ppu_write(8'h01,8'h20,4,3);
    ppu_write(8'h07,8'h5c,4,10);
    check(8'h01,8'h20); check(8'h07,8'h5c);

    $display("== SETINI $2133 tight ==");
    ppu_write(8'h33,8'h00,4,10); check(8'h33,8'h00);

    if(errors==0) $display("\n==> PASS: raw-pulse capture correct for short/long/burst pulses");
    else          $display("\n==> FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule

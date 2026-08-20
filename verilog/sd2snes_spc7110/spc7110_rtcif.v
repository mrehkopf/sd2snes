`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    spc7110_rtcif
// Project Name:   sd2snes
//
// Description:
//   SPC7110 real time clock interface: the $4840-$4842 register block through
//   which the SNES talks to the external Epson RTC-4513 found on the Far East
//   of Eden Zero (Tengai Makyou Zero) cartridge.
//
//   This module implements the register/command protocol only.  Time keeping
//   stays where it already is: rtc.v from sd2snes_base counts in exactly the
//   packed nibble format the MCU uses for SPI command $e5, and this module
//   snapshots that counter on chip select, serves nibbles out of the snapshot,
//   and writes a modified snapshot back through the same port srtc.v uses
//   (we1 / rtc_data_in1).  There is deliberately no second seconds counter in
//   here.
//
//   Protocol sources (public documentation only):
//     - nocash "fullsnes", section "SNES Cart SPC7110 with RTC-4513 Real Time
//       Clock": port list, transfer sequence (switch CE from LOW to HIGH, send
//       command, send starting index, read or write one or more 4bit data
//       units with automatic index increment and wrap from 0Fh to 00h, finally
//       switch CE back LOW), commands 03h/0Ch, and the RTC-4513 register table.
//     - nesdev forum topic 4106, Dark Force's SPC7110 register notes: $4841
//       takes the command byte as the first write after RTC enable, then the
//       index of the register to access, then data; the index auto-increments
//       after each subsequent read/write; $4842 bit7 is the ready flag the game
//       tests before reading RTC data.
//
//   RTC-4513 register index <-> rtc.v rtc_data[59:0] nibble map:
//
//     idx  RTC-4513 register        rtc_data      mask  non-counter bits
//     0    seconds, ones            [3:0]         f     -
//     1    seconds, tens            [7:4]         7     bit3 = LOST
//     2    minutes, ones            [11:8]        f     -
//     3    minutes, tens            [15:12]       7     bit3 = WRAP
//     4    hours, ones              [19:16]       f     -
//     5    hours, tens              [23:20]       3     bit3 = WRAP, bit2 = PM/AM
//     6    day of month, ones       [27:24]       f     -
//     7    day of month, tens       [31:28]       3     bit3 = WRAP, bit2 = RAM
//     8    month, ones              [35:32]       f     -
//     9    month, tens              [39:36]       1     bit3 = WRAP, bit2..1 = RAM
//     a    year, ones               [43:40]       f     -
//     b    year, tens               [47:44]       f     -
//     c    day of week (0 = Sunday) [59:56]       7     bit3 = WRAP
//     d    control register D       -             f     kept locally, reset 1
//     e    control register E       -             f     kept locally, reset f
//     f    control register F       -             f     kept locally, reset 6
//
//   The "mask" column is what a write keeps: everything outside it is a flag or
//   user RAM on the RTC-4513, not part of the BCD counter, and must not reach
//   rtc.v (see the write case).  Those bits read back as 0; the three user RAM
//   bits at indices 7 and 9 are not stored.
//
//   Two control bits do have an effect and are carried out at the moment the
//   register is written: RESET (F bit0) zeroes the seconds, 30ADJ (D bit3)
//   zeroes the seconds and adds one minute when the seconds were >= 30.  The
//   rest of D/E/F is plain read/write storage.
//
//   rtc_data[51:48] (century, ones) and [55:52] (century, thousands) have no
//   RTC-4513 index: the chip only keeps a two digit year.  A write therefore
//   starts from the snapshot instead of from zero, which carries the century -
//   and the day of week rtc.v computes - through untouched.
//
//   The WRAP bits ("time changed during access") are always reported as 0: the
//   whole session is served from one snapshot taken at chip select, so the time
//   cannot change underneath a running transfer and the game never has to
//   deselect and read again.  Same reasoning for LOST: the MCU programs the
//   clock on every game load, so the time is never lost.
//
//   $4842 bit7 is the ready flag.  On real hardware the SPC7110 moves the
//   nibble over a 4 bit serial bus to the RTC and the flag is low while that
//   runs; Dark Force adds that it is "cleared after successful read".  Here the
//   data is available immediately, so the flag is modelled as a consumable: a
//   data read at $4841 arms it, reading $4842 consumes it.  Both driver shapes
//   terminate - "poll until ready, then read" costs at most one extra poll, and
//   "read, then poll until the flag clears" ends on the first poll.
//
//   Bus interface notes for the integration (spc7110_regs.v):
//     - we_484x / rd_484x are one clock strobes.  r4840..r4842 are
//       combinational, so rd_4841 has to be the END of the SNES read cycle
//       (SNES_RD_end, the way srtc.v is wired): the index auto-increment must
//       not change the byte the SNES is latching.
//     - rtc_we / rtc_data_wr go to rtc.v's we1 / rtc_data_in1.  rtc.v samples
//       we1 through a 3 stage shift register on its own clock (CLKIN, 8 MHz on
//       mk3) while this module runs on CLK2, so the strobe is held WE_PULSE
//       clocks - long enough to survive that clock ratio.
//
//////////////////////////////////////////////////////////////////////////////////
module spc7110_rtcif(
  input             clkin,
  input             rst,

  // register writes (one clock strobes, data on wdata)
  input             we_4840,
  input             we_4841,
  input             we_4842,
  input      [7:0]  wdata,

  // register reads (one clock strobes at the end of the SNES read cycle)
  input             rd_4840,
  input             rd_4841,
  input             rd_4842,

  // read-back
  output     [7:0]  r4840,
  output     [7:0]  r4841,
  output     [7:0]  r4842,

  // time keeping (rtc.v)
  input      [59:0] rtc_data,
  output            rtc_we,
`ifndef MK2
  output     [59:0] rtc_data_wr,

  // Battery backup state (SPI $e6 reads it, $e7 restores it).  bkp_time is the
  // time the cartridge shows - the freeze register while the clock is stopped,
  // rtc.v otherwise - with the day of week counter already substituted into
  // [59:56].  bkp_flags is {stopped, dow_owned}.  bkp_we is a one clock strobe
  // that loads all of it back.
  output     [59:0] bkp_time,
  output     [1:0]  bkp_flags,
  input             bkp_we,
  input      [59:0] bkp_time_in,
  input      [1:0]  bkp_flags_in
`else
  // mk2 flavor: no virtual battery ($e6/$e7 handover gated out, contract $0Ca).
  // The freeze register and STOP stay - they are cheap and the game uses them
  // inside a session; what goes is only the handover to and from the MCU.
  output     [59:0] rtc_data_wr
`endif
);

// Width of the rtc.v write strobe, in clkin cycles.  rtc.v edge-detects we1
// with a three stage shift register clocked at CLKIN; 64 CLK2 cycles are
// slightly over five CLKIN periods at the mk3 96/8 MHz ratio.
parameter WE_PULSE = 7'd64;

// A time write is normally committed when the game deselects the chip.  If a
// game ever leaves CE high after writing, this watchdog commits it anyway
// after 2^STALE_BITS idle clocks (~44 ms at 96 MHz).
parameter STALE_BITS = 22;

localparam CMD_WRITE = 4'h3;   // fullsnes: 03h = write mode
localparam CMD_READ  = 4'hc;   // fullsnes: 0Ch = read mode

localparam ST_CMD    = 2'd0;   // waiting for the command byte
localparam ST_INDEX  = 2'd1;   // waiting for the starting index
localparam ST_XFER   = 2'd2;   // data nibbles, index auto-increments

reg        ce;                 // $4840 bit0: chip select
reg [1:0]  state;
reg [3:0]  index;
reg [3:0]  cmd;

reg [59:0] snap;               // coherent copy of rtc_data for this session
reg [59:0] wr_hold;            // what rtc.v gets to see while rtc_we is up
reg [3:0]  ctrl_d, ctrl_e, ctrl_f;

reg        dirty;              // a time register was written this session
reg        rtc_we_r;
reg [6:0]  we_cnt;
reg [STALE_BITS-1:0] idle_cnt;

// rtc.v only publishes rtc_data once per second (its STATE_LATCH), so for up
// to a second after a write the counter output still shows the old time.  A
// session opened in that window must not snapshot it, or a game that writes
// the clock and reads it straight back would see its write disappear.
// wr_pending says "the last thing written is newer than what rtc_data shows";
// it clears as soon as rtc.v publishes a new second.
reg        wr_pending;
reg [59:0] rtc_prev;

// $4842 bit7.  On the real cartridge the SPC7110 shifts the nibble to the RTC
// over a 4 bit serial bus, so the flag drops while a transfer is running and
// the game polls it; Dark Force's notes add "high bit cleared after successful
// read".  Here the data is available immediately, so the flag is modelled as a
// consumable: a data read at $4841 arms it and reading $4842 consumes it.
// That satisfies BOTH shapes of driver loop - "poll until ready, then read"
// falls through after at most one extra poll, and "read, then poll until the
// flag clears" terminates on the first poll.  An always-ready $4842 would hang
// the second shape forever.
reg        busy_r;

// Day of week (index Ch).  On the RTC-4513 this register is a plain modulo 7
// counter: the host loads it with whatever value it likes and the chip steps it
// by one at midnight - it is NOT derived from the date.  rtc.v, by contrast,
// recomputes the weekday from the calendar on every one second pass and
// overwrites whatever was written, so a value the game puts there survives less
// than a second.
//
// The cartridge's own factory check program proves the counter semantics: it
// sets the clock to 1999-12-31 23:59:59 with weekday 6, while 1999-12-31 was a
// Friday (5), and then expects to read weekday 0 after the roll into
// 2000-01-01, which was a Saturday (6).  The expected value is deliberately one
// step off the real calendar, so no date-derived weekday can ever satisfy it.
//
// dow_r is that counter.  Until the game writes index Ch, dow_owned is 0 and it
// simply mirrors rtc.v, which is what gives a sensible weekday for the wall
// clock the MCU programs at load time.  The first write takes ownership; from
// then on the value is kept here and stepped at midnight.  date_ref is the date
// dow_r is in step with, century included: without the century the roll
// 2000-01-01 -> 2100-01-01 this test can produce would be invisible.
//
// dow_ss is the per session copy, so index Ch stays as coherent as every other
// index.
reg [3:0]  dow_r;
reg [3:0]  dow_ss;
reg        dow_owned;
reg [31:0] date_ref;

// STOP (control register F, bit1) and the freeze register.
//
// The polarity of this bit is the one the cartridge's own factory check program
// demonstrates, not the one fullsnes prints: bit1 = 1 STOPS the clock, bit1 = 0
// lets it run.  The program writes F=$07 to freeze, programs the calendar,
// writes F=$04 and only then does the clock advance; it finishes by writing
// F=$06, and the MODE 2 test that follows a power cycle requires the calendar
// to have stayed exactly where it was.  fullsnes ("0=Stop, 1=Normal") is
// inverted; Dark Force ("1 - stop timer") is right.
//
// While stopped, every session is served from frz instead of from rtc.v, which
// keeps counting underneath - stopping it is not possible from here, and would
// be wrong anyway, since the MCU reprograms it on every load.  Clearing STOP
// commits the frozen time back through the normal write path, so the clock
// resumes where it was left rather than where rtc.v happens to be.
//
// stopped is NOT ctrl_f[1] itself.  ctrl_f keeps its documented power-up value
// of 6, which has bit1 set, but a freshly configured core has no battery state
// to defend: it has just been handed the wall clock by the MCU and must run.
// So the effective flag starts at 0 and only follows the game's own writes to
// register F (or an $e7 restore) - a game that never touches the RTC keeps the
// wall clock it was given.
reg        stopped;
reg [59:0] frz;

`ifndef MK2
// The state the MCU hands back with $e7, kept in its own registers.  The module
// sits in reset (SNES_DEADr) for the whole time the MCU is setting the
// cartridge up, so the restore has to be latched here and the reset branch has
// to seed the working registers from it - otherwise the reset that is still
// running would throw it away before the SNES ever starts.  bkp_valid is only
// cleared by FPGA configuration, i.e. once per game load, which is exactly when
// "there is no backup" is the right answer.
reg [59:0] bkp_hold;
reg [1:0]  bkp_hold_f;
reg        bkp_valid;
`endif
// Whether that seed has already been planted.  rst here is SNES_DEADr, which
// goes high for every console reset and not just for the load, but the RTC-4513
// is battery backed: it sits outside the console's reset domain and a reset
// does not touch the calendar, the weekday, STOP or the control registers.  So
// the seed is applied only while a handover is outstanding - from the moment
// $e7 arrives until the console actually starts running - and every reset after
// that leaves the chip alone.
reg        bkp_applied;

// what the cartridge shows: the freeze register, or the live counter
wire [59:0] time_src = stopped ? frz : rtc_data;

initial begin
  ce       = 1'b0;
  state    = ST_CMD;
  index    = 4'h0;
  cmd      = 4'h0;
  snap     = 60'h0;
  wr_hold  = 60'h0;
  ctrl_d   = 4'h1;
  ctrl_e   = 4'hf;
  ctrl_f   = 4'h6;
  dirty    = 1'b0;
  rtc_we_r = 1'b0;
  we_cnt   = 7'd0;
  idle_cnt = {STALE_BITS{1'b0}};
  wr_pending = 1'b0;
  rtc_prev   = 60'h0;
  busy_r     = 1'b0;
  dow_r      = 4'h0;
  dow_ss     = 4'h0;
  dow_owned  = 1'b0;
  date_ref   = 32'h0;
  stopped    = 1'b0;
  frz        = 60'h0;
`ifndef MK2
  bkp_hold   = 60'h0;
  bkp_hold_f = 2'b00;
  bkp_valid  = 1'b0;
`endif
  bkp_applied = 1'b0;
end

// ---------------------------------------------------------------------------
// read-back
// ---------------------------------------------------------------------------
reg [3:0] nibble;
always @* begin
  case (index)
    4'h0:    nibble = snap[3:0];
    4'h1:    nibble = snap[7:4];
    4'h2:    nibble = snap[11:8];
    4'h3:    nibble = snap[15:12];
    4'h4:    nibble = snap[19:16];
    4'h5:    nibble = snap[23:20];
    4'h6:    nibble = snap[27:24];
    4'h7:    nibble = snap[31:28];
    4'h8:    nibble = snap[35:32];
    4'h9:    nibble = snap[39:36];
    4'ha:    nibble = snap[43:40];
    4'hb:    nibble = snap[47:44];
    4'hc:    nibble = dow_ss;
    4'hd:    nibble = ctrl_d;
    4'he:    nibble = ctrl_e;
    default: nibble = ctrl_f;
  endcase
end

assign r4840 = {7'h00, ce};
assign r4841 = ce ? {4'h0, nibble} : 8'h00;
assign r4842 = {~busy_r, 7'h00};            // bit7 = ready

assign rtc_we      = rtc_we_r;
assign rtc_data_wr = wr_hold;

`ifndef MK2
assign bkp_time    = {dow_owned ? dow_r : time_src[59:56], time_src[55:0]};
assign bkp_flags   = {stopped, dow_owned};
`endif

// ---------------------------------------------------------------------------
// command / index / data machine
// ---------------------------------------------------------------------------
wire ce_rising  =  wdata[0] & ~ce;
wire ce_falling = ~wdata[0] &  ce;
wire stale      = dirty & ce & (idle_cnt == {STALE_BITS{1'b1}});

always @(posedge clkin) begin
`ifndef MK2
  // accepted in reset as well as out of it - see bkp_hold above
  if (bkp_we) begin
    bkp_hold    <= bkp_time_in;
    bkp_hold_f  <= bkp_flags_in;
    bkp_valid   <= 1'b1;
    bkp_applied <= 1'b0;      // a fresh handover, waiting to be planted
  end

`endif

  if (rst) begin
    // Bus and session state only.  The console going away drops chip select, so
    // whatever transfer was open is abandoned - and abandoned WITHOUT being
    // committed, which is what dirty <= 0 says: a half written time never
    // reaches the clock.  Everything that belongs to the chip rather than to
    // the bus is deliberately left alone.
    ce       <= 1'b0;
    state    <= ST_CMD;
    index    <= 4'h0;
    cmd      <= 4'h0;
    dirty    <= 1'b0;
    rtc_we_r <= 1'b0;
    we_cnt   <= 7'd0;
    idle_cnt <= {STALE_BITS{1'b0}};
    busy_r   <= 1'b0;

    // The handover from the MCU.  The MCU holds the console in reset for the
    // whole time it is setting the cartridge up, so this keeps tracking until
    // the console starts; from then on bkp_applied is set and a player pressing
    // reset finds the clock exactly as the game left it.
`ifndef MK2
    if (!bkp_applied) begin
      snap       <= bkp_valid ? bkp_hold        : rtc_data;
      wr_hold    <= rtc_data;
      ctrl_d     <= 4'h1;
      ctrl_e     <= 4'hf;
      ctrl_f     <= 4'h6;
      wr_pending <= 1'b0;
      rtc_prev   <= rtc_data;
      dow_r      <= bkp_valid ? bkp_hold[59:56] : rtc_data[59:56];
      dow_ss     <= bkp_valid ? bkp_hold[59:56] : rtc_data[59:56];
      dow_owned  <= bkp_valid ? bkp_hold_f[0]   : 1'b0;
      date_ref   <= bkp_valid ? bkp_hold[55:24] : rtc_data[55:24];
      stopped    <= bkp_valid ? bkp_hold_f[1]   : 1'b0;
      frz        <= bkp_valid ? bkp_hold        : rtc_data;
    end
`else
    // Same block with the handover selections collapsed: with no backup to
    // plant, every seed comes from the wall clock the MCU programmed ($e5).
    // bkp_applied itself stays - it is what makes a console reset leave the
    // clock alone once the game is running, which is RTC-4513 behaviour and
    // not part of the handover.
    if (!bkp_applied) begin
      snap       <= rtc_data;
      wr_hold    <= rtc_data;
      ctrl_d     <= 4'h1;
      ctrl_e     <= 4'hf;
      ctrl_f     <= 4'h6;
      wr_pending <= 1'b0;
      rtc_prev   <= rtc_data;
      dow_r      <= rtc_data[59:56];
      dow_ss     <= rtc_data[59:56];
      dow_owned  <= 1'b0;
      date_ref   <= rtc_data[55:24];
      stopped    <= 1'b0;
      frz        <= rtc_data;
    end
`endif
  end else begin
    // the console is running: the handover is done with
    bkp_applied <= 1'b1;

    // $4842: armed by a data read, consumed by reading the status
    if (rd_4842) busy_r <= 1'b0;
    if (ce & rd_4841) busy_r <= 1'b1;

    // write strobe timer (a commit below may restart it)
    if (we_cnt != 7'd0) begin
      we_cnt <= we_cnt - 7'd1;
      if (we_cnt == 7'd1) rtc_we_r <= 1'b0;
    end

    // rtc.v published something new (a new second, or a fresh time from the
    // MCU's $e5): what it shows is current again.  Comparing the whole word
    // and not just the seconds also covers a reprogram that lands on the same
    // seconds digit.
    rtc_prev <= rtc_data;
    if (rtc_data != rtc_prev) wr_pending <= 1'b0;

    // Day of week step: rtc.v moved onto a date the counter is not in step
    // with, i.e. one midnight, so one step.  Both halves of the condition earn
    // their keep.  It has to be an EDGE on rtc_data, because a commit points
    // date_ref at the date that was just written and rtc_data has not published
    // it yet - a plain level compare would fire on that gap.  And it has to
    // compare against date_ref, because rtc.v publishes only once per second:
    // depending on where the write lands in that pass it either publishes the
    // written 23:59:59 first and rolls over on the following pass, or increments
    // it straight away so that the write becoming visible and the midnight roll
    // are the SAME transition.  With both halves either order steps exactly
    // once.  Until the game claims the register the value just follows rtc.v.
    if (!stopped && (rtc_data[55:24] != rtc_prev[55:24])
                 && (rtc_data[55:24] != date_ref)) begin
      date_ref <= rtc_data[55:24];
      dow_r    <= (dow_r == 4'd6) ? 4'd0 : dow_r + 4'd1;
    end
    if (!dow_owned) dow_r <= time_src[59:56];

    // watchdog for a session that never deselects
    if (dirty & ce) idle_cnt <= idle_cnt + {{(STALE_BITS-1){1'b0}}, 1'b1};
    else            idle_cnt <= {STALE_BITS{1'b0}};

    if (we_4840) begin
      ce <= wdata[0];
      if (ce_rising) begin
        // start of a session: take the snapshot the whole transfer works on.
        // While a write has not shown up on rtc_data yet, keep serving it.
        state  <= ST_CMD;
        index  <= 4'h0;
        cmd    <= 4'h0;
        busy_r <= 1'b0;
        // frozen: frz is authoritative, so wr_pending does not apply
        if (stopped)          snap <= frz;
        else if (!wr_pending) snap <= rtc_data;
        dow_ss <= dow_owned ? dow_r : time_src[59:56];
      end
      if (ce_falling) begin
        state  <= ST_CMD;
        busy_r <= 1'b0;
        // fullsnes: TEST (bit3) and RESET (bit0) auto-clear on CE = LOW
        ctrl_f <= ctrl_f & 4'b0110;
        if (dirty) begin
          wr_hold    <= snap;
          rtc_we_r   <= 1'b1;
          we_cnt     <= WE_PULSE;
          dirty      <= 1'b0;
          wr_pending <= 1'b1;
          date_ref   <= snap[55:24];   // dow_r is in step with what we wrote
        end
        // still stopped at the end of the session: whatever the session leaves
        // in snap is what the chip goes on showing
        if (stopped) frz <= snap;
      end
    end else if (ce & we_4841) begin
      idle_cnt <= {STALE_BITS{1'b0}};
      case (state)
        ST_CMD: begin
          cmd <= wdata[3:0];
          // only the two documented commands open a transfer; anything else is
          // ignored rather than left to wedge the machine
          if (wdata[3:0] == CMD_WRITE || wdata[3:0] == CMD_READ)
            state <= ST_INDEX;
        end
        ST_INDEX: begin
          // the starting index itself does not increment
          index <= wdata[3:0];
          state <= ST_XFER;
        end
        default: begin
          index <= index + 4'h1;        // wraps 0f -> 00 by construction
          // Only the counter bits of each index reach the clock.  The rest of
          // the nibble is a flag or user RAM on the RTC-4513 (see the map in
          // the header), and letting it through would push a non-BCD digit
          // into rtc.v: writing 8 to index 3 (the WRAP bit) would give a
          // minutes-tens digit of 8, writing 4 to index 5 (PM/AM) an
          // hours-tens digit of 4.  Masked-off bits read back as 0; the three
          // user RAM bits are not stored.
          case (index)
            4'h0: begin snap[3:0]   <= wdata[3:0];         dirty <= 1'b1; end
            4'h1: begin snap[7:4]   <= wdata[3:0] & 4'h7;  dirty <= 1'b1; end
            4'h2: begin snap[11:8]  <= wdata[3:0];         dirty <= 1'b1; end
            4'h3: begin snap[15:12] <= wdata[3:0] & 4'h7;  dirty <= 1'b1; end
            4'h4: begin snap[19:16] <= wdata[3:0];         dirty <= 1'b1; end
            4'h5: begin snap[23:20] <= wdata[3:0] & 4'h3;  dirty <= 1'b1; end
            4'h6: begin snap[27:24] <= wdata[3:0];         dirty <= 1'b1; end
            4'h7: begin snap[31:28] <= wdata[3:0] & 4'h3;  dirty <= 1'b1; end
            4'h8: begin snap[35:32] <= wdata[3:0];         dirty <= 1'b1; end
            4'h9: begin snap[39:36] <= wdata[3:0] & 4'h1;  dirty <= 1'b1; end
            4'ha: begin snap[43:40] <= wdata[3:0];         dirty <= 1'b1; end
            4'hb: begin snap[47:44] <= wdata[3:0];         dirty <= 1'b1; end
            4'hc: begin
              snap[59:56] <= wdata[3:0] & 4'h7;
              dow_r       <= wdata[3:0] & 4'h7;
              dow_ss      <= wdata[3:0] & 4'h7;
              dow_owned   <= 1'b1;
              dirty       <= 1'b1;
            end
            4'hd: begin
              ctrl_d <= wdata[3:0];
              // 30ADJ (bit3): "Set seconds to zero, and, if seconds was >= 30,
              // increase minutes" (fullsnes).  The carry stops at the minute -
              // the sources only ask for the minute, and cascading is rtc.v's
              // job - so minute 59 SATURATES: the seconds still go to zero but
              // the minute stays put.  Wrapping it to 00 instead would move the
              // clock 59 minutes BACKWARDS, an error about sixty times larger
              // than the one minute the saturation costs.
              if (wdata[3]) begin
                snap[7:0] <= 8'h00;
                dirty     <= 1'b1;
                if (snap[7:4] >= 4'h3) begin
                  if (snap[11:8] == 4'h9) begin
                    if (snap[15:12] != 4'h5) begin       // not 59: carry
                      snap[11:8]  <= 4'h0;
                      snap[15:12] <= snap[15:12] + 4'h1;
                    end
                  end else
                    snap[11:8] <= snap[11:8] + 4'h1;
                end
              end
            end
            4'he: ctrl_e <= wdata[3:0];
            default: begin
              ctrl_f <= wdata[3:0];
              // RESET (bit0): "Stop clock and reset seconds to 00h" (fullsnes);
              // Dark Force reads it the same way.  The clock itself is rtc.v
              // and cannot be stopped from here, so only the seconds are
              // zeroed.  The bit auto-clears on CE = LOW.
              if (wdata[0]) begin
                snap[7:0] <= 8'h00;
                dirty     <= 1'b1;
              end
              // STOP (bit1).  Clearing it resumes: mark the session dirty so
              // the frozen time - which snap was loaded from at chip select -
              // is committed back into rtc.v by the normal write path.
              stopped <= wdata[1];
              if (stopped && !wdata[1]) dirty <= 1'b1;
            end
          endcase
        end
      endcase
    end else if (ce & rd_4841) begin
      idle_cnt <= {STALE_BITS{1'b0}};
      if (state == ST_XFER) index <= index + 4'h1;
    end else if (stale) begin
      wr_hold    <= snap;
      rtc_we_r   <= 1'b1;
      we_cnt     <= WE_PULSE;
      dirty      <= 1'b0;
      wr_pending <= 1'b1;
      date_ref   <= snap[55:24];
      if (stopped) frz <= snap;
    end

`ifndef MK2
    // MCU restore of the backed up state ($e7).  Last in the block on purpose:
    // it overrides anything the SNES side did in the same clock.  The time
    // itself also goes to rtc.v, through $e5, before this arrives; frz is what
    // makes a stopped clock come back at exactly the second it was left on.
    if (bkp_we) begin
      frz        <= bkp_time_in;
      snap       <= bkp_time_in;
      dow_r      <= bkp_time_in[59:56];
      dow_ss     <= bkp_time_in[59:56];
      dow_owned  <= bkp_flags_in[0];
      stopped    <= bkp_flags_in[1];
      date_ref   <= bkp_time_in[55:24];
      wr_pending <= 1'b0;
      dirty      <= 1'b0;
    end
`endif
  end
end

// we_4842 is accepted and ignored ($4842 is status only); rd_4840 and rd_4842
// have no side effects on the RTC-4513.

endmodule

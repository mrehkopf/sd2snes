`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    spc7110_regs
// Project Name:   sd2snes
//
// Description:
//   SPC7110 register block.  Owns the fine decode of $4800-$484F, the memory
//   control registers $4830-$4834, and the routing of access strobes and
//   read-back to the five units that implement the chip:
//
//     $4800-$480C  spc7110_dcu    decompression unit
//     $4810-$481A  spc7110_data   data port
//     $4820-$482F  spc7110_alu    multiply / divide
//     $4830-$4834  here           bank windows + SRAM enable (spc7110_map reads
//                                 them and produces the cartridge address)
//     $4840-$4842  spc7110_rtcif  RTC-4513 interface
//
//   The frame (main.v) decodes the window itself and passes reg_enable plus the
//   register index; this module never sees a bank.  That is also where the two
//   whole-bank aliases of the reference are resolved ($50:xxxx -> $4800,
//   $58:xxxx -> $4808), so they arrive here indistinguishable from a direct
//   access.  Registers with no unit behind them read back $00 and drop writes;
//   $4808 is one of them, so a write through the $58 alias is dropped too.
//
//   Strobes.  we_* comes from the END of the SNES write cycle and rd_* from the
//   END of the read cycle, so exactly one strobe is high for exactly one clock
//   per SNES access.  That is a hard requirement of the units: they queue one
//   operation per strobe cycle, and the read-back of the data port, the DCU and
//   the RTC interface is combinational, so a strobe taken at the START of a read
//   would auto-increment the pointer under the byte the SNES is latching.
//
//   The reference model folds $4840-$484F back onto $4800-$483F (it has no RTC);
//   real hardware does not, and neither does this decode.
//
//   Reset is synchronous and active high (SNES_DEADr in the frame): the chip
//   comes up with the power-on register values of the reference and the units
//   drop whatever they were doing, which is what the MCU needs while it loads a
//   ROM into PSRAM.
//////////////////////////////////////////////////////////////////////////////////
module spc7110_regs(
  input             clkin,
  input             rst,
// SPC7110 behaviour referenced here follows the ares implementation (ISC);
// the full ISC notice is carried in spc7110_map.v / spc7110_dcu.v.

  /* SNES register window $4800-$484F, decoded by the frame */
  input             reg_enable,
  input      [7:0]  reg_addr,       // SNES_ADDR[7:0]
  input      [7:0]  reg_din,        // registered SNES data bus
  input             wr_end,         // SNES_WR_end
  input             rd_end,         // SNES_RD_end
  output     [7:0]  reg_dout,

  /* cartridge address mapping (spc7110_map) */
  input      [23:0] snes_addr,
  input      [23:0] drom_base,
  input      [23:0] drom_mask,
  output            map_rom_hit,
  output     [23:0] map_psram_addr,
  output            map_is_sram,

  /* data ROM ports, one per requester; the frame arbitrates and fetches */
  output            data_drom_req,
  output     [23:0] data_drom_addr,
  input             data_drom_ack,
  output            dcu_drom_req,
  output     [23:0] dcu_drom_addr,
  input             dcu_drom_ack,
  input      [7:0]  drom_data,

  /* RTC-4513 time keeping (rtc.v) */
  input      [59:0] rtc_data,
  output            rtc_we,
`ifndef MK2
  output     [59:0] rtc_data_wr,

  /* RTC-4513 battery backup state, straight through to spc7110_rtcif (SPI $e6
     reads it, $e7 restores it) */
  output     [59:0] bkp_time,
  output     [1:0]  bkp_flags,
  input             bkp_we,
  input      [59:0] bkp_time_in,
  input      [1:0]  bkp_flags_in
`else
  /* mk2 flavor: no virtual battery (contract $0Ca) */
  output     [59:0] rtc_data_wr
`endif
);

// -----------------------------------------------------------------------------
// access strobes
//
// The decode below is combinational ("_d") and is REGISTERED before it reaches
// the units.  SNES_ADDR arrives from a shift register the fitter maps into block
// RAM, whose clock-to-output is slow; decoding it and then running the data
// port's two chained 23 bit adders inside the same clock misses the 96 MHz
// period by about 0.9 ns.  With the strobe registered, the adders start from a
// plain flip-flop and the decode gets a clock of its own.
//
// The extra clock changes nothing that is observable: the strobes are still one
// clock pulses with at most one high at a time, and they already fire at the END
// of the SNES access, long after the byte was latched off the bus.
//
// No reset term is needed on the registered strobes: reg_enable (the frame's
// spc7110_reg_enable) is held at 0 for as long as rst is asserted, so wr and rd
// are 0 through the whole reset and on the clock it releases.
// -----------------------------------------------------------------------------
wire wr = reg_enable & wr_end;
wire rd = reg_enable & rd_end;

wire [7:0] a = reg_addr;

wire blk_48_0x = (a[7:4] == 4'h0);
wire blk_48_1x = (a[7:4] == 4'h1);
wire blk_48_2x = (a[7:4] == 4'h2);
wire blk_48_3x = (a[7:4] == 4'h3);
wire blk_48_4x = (a[7:4] == 4'h4);

// decompression unit ($4800-$480C).  $4800 and $4808 take no write.
wire we_4801_d = wr & blk_48_0x & (a[3:0] == 4'h1);
wire we_4802_d = wr & blk_48_0x & (a[3:0] == 4'h2);
wire we_4803_d = wr & blk_48_0x & (a[3:0] == 4'h3);
wire we_4804_d = wr & blk_48_0x & (a[3:0] == 4'h4);
wire we_4805_d = wr & blk_48_0x & (a[3:0] == 4'h5);
wire we_4806_d = wr & blk_48_0x & (a[3:0] == 4'h6);
wire we_4807_d = wr & blk_48_0x & (a[3:0] == 4'h7);
wire we_4808_d = wr & blk_48_0x & (a[3:0] == 4'h8);
wire we_4809_d = wr & blk_48_0x & (a[3:0] == 4'h9);
wire we_480a_d = wr & blk_48_0x & (a[3:0] == 4'ha);
wire we_480b_d = wr & blk_48_0x & (a[3:0] == 4'hb);
// a read of $4800 consumes one decompressed byte and decrements {r480a,r4809}
wire rd_4800_d = rd & blk_48_0x & (a[3:0] == 4'h0);

// data port ($4810-$481A).  $4810 and $481A also have a read side effect.
wire we_4811_d = wr & blk_48_1x & (a[3:0] == 4'h1);
wire we_4812_d = wr & blk_48_1x & (a[3:0] == 4'h2);
wire we_4813_d = wr & blk_48_1x & (a[3:0] == 4'h3);
wire we_4814_d = wr & blk_48_1x & (a[3:0] == 4'h4);
wire we_4815_d = wr & blk_48_1x & (a[3:0] == 4'h5);
wire we_4816_d = wr & blk_48_1x & (a[3:0] == 4'h6);
wire we_4817_d = wr & blk_48_1x & (a[3:0] == 4'h7);
wire we_4818_d = wr & blk_48_1x & (a[3:0] == 4'h8);
wire we_481a_d = wr & blk_48_1x & (a[3:0] == 4'ha);
wire rd_4810_d = rd & blk_48_1x & (a[3:0] == 4'h0);
wire rd_481a_d = rd & blk_48_1x & (a[3:0] == 4'ha);

// arithmetic logic unit ($4820-$482F)
wire we_4820_d = wr & blk_48_2x & (a[3:0] == 4'h0);
wire we_4821_d = wr & blk_48_2x & (a[3:0] == 4'h1);
wire we_4822_d = wr & blk_48_2x & (a[3:0] == 4'h2);
wire we_4823_d = wr & blk_48_2x & (a[3:0] == 4'h3);
wire we_4824_d = wr & blk_48_2x & (a[3:0] == 4'h4);
wire we_4825_d = wr & blk_48_2x & (a[3:0] == 4'h5);
wire we_4826_d = wr & blk_48_2x & (a[3:0] == 4'h6);
wire we_4827_d = wr & blk_48_2x & (a[3:0] == 4'h7);
wire we_482e_d = wr & blk_48_2x & (a[3:0] == 4'he);

// memory control unit ($4830-$4834), the register file below
wire we_4830_d = wr & blk_48_3x & (a[3:0] == 4'h0);
wire we_4831_d = wr & blk_48_3x & (a[3:0] == 4'h1);
wire we_4832_d = wr & blk_48_3x & (a[3:0] == 4'h2);
wire we_4833_d = wr & blk_48_3x & (a[3:0] == 4'h3);
wire we_4834_d = wr & blk_48_3x & (a[3:0] == 4'h4);

// RTC-4513 interface ($4840-$4842)
wire we_4840_d = wr & blk_48_4x & (a[3:0] == 4'h0);
wire we_4841_d = wr & blk_48_4x & (a[3:0] == 4'h1);
wire we_4842_d = wr & blk_48_4x & (a[3:0] == 4'h2);
wire rd_4840_d = rd & blk_48_4x & (a[3:0] == 4'h0);
wire rd_4841_d = rd & blk_48_4x & (a[3:0] == 4'h1);
wire rd_4842_d = rd & blk_48_4x & (a[3:0] == 4'h2);


// registered strobes: this is what the units see
reg [7:0] wdata;
reg we_4801, we_4802, we_4803, we_4804;
reg we_4805, we_4806, we_4807, we_4808;
reg we_4809, we_480a, we_480b, rd_4800;
reg we_4811, we_4812, we_4813, we_4814;
reg we_4815, we_4816, we_4817, we_4818;
reg we_481a, rd_4810, rd_481a, we_4820;
reg we_4821, we_4822, we_4823, we_4824;
reg we_4825, we_4826, we_4827, we_482e;
reg we_4830, we_4831, we_4832, we_4833;
reg we_4834, we_4840, we_4841, we_4842;
reg rd_4840, rd_4841, rd_4842;

always @(posedge clkin) begin
  wdata <= reg_din;
  we_4801  <= we_4801_d;
  we_4802  <= we_4802_d;
  we_4803  <= we_4803_d;
  we_4804  <= we_4804_d;
  we_4805  <= we_4805_d;
  we_4806  <= we_4806_d;
  we_4807  <= we_4807_d;
  we_4808  <= we_4808_d;
  we_4809  <= we_4809_d;
  we_480a  <= we_480a_d;
  we_480b  <= we_480b_d;
  rd_4800  <= rd_4800_d;
  we_4811  <= we_4811_d;
  we_4812  <= we_4812_d;
  we_4813  <= we_4813_d;
  we_4814  <= we_4814_d;
  we_4815  <= we_4815_d;
  we_4816  <= we_4816_d;
  we_4817  <= we_4817_d;
  we_4818  <= we_4818_d;
  we_481a  <= we_481a_d;
  rd_4810  <= rd_4810_d;
  rd_481a  <= rd_481a_d;
  we_4820  <= we_4820_d;
  we_4821  <= we_4821_d;
  we_4822  <= we_4822_d;
  we_4823  <= we_4823_d;
  we_4824  <= we_4824_d;
  we_4825  <= we_4825_d;
  we_4826  <= we_4826_d;
  we_4827  <= we_4827_d;
  we_482e  <= we_482e_d;
  we_4830  <= we_4830_d;
  we_4831  <= we_4831_d;
  we_4832  <= we_4832_d;
  we_4833  <= we_4833_d;
  we_4834  <= we_4834_d;
  we_4840  <= we_4840_d;
  we_4841  <= we_4841_d;
  we_4842  <= we_4842_d;
  rd_4840  <= rd_4840_d;
  rd_4841  <= rd_4841_d;
  rd_4842  <= rd_4842_d;
end

// -----------------------------------------------------------------------------
// memory control registers $4830-$4834
//
// Write masks and power-on values are the reference ones: $4830 keeps the SRAM
// enable plus the three block bits, the other four keep three bits each.  The
// masked bits read back as 0, which is what the reference reports too.
// -----------------------------------------------------------------------------
reg [7:0] q4830;
reg [7:0] q4831;
reg [7:0] q4832;
reg [7:0] q4833;
reg [7:0] q4834;

initial begin
  q4830 = 8'h00;
  q4831 = 8'h00;
  q4832 = 8'h01;
  q4833 = 8'h02;
  q4834 = 8'h00;
end

always @(posedge clkin) begin
  if(rst) begin
    q4830 <= 8'h00;
    q4831 <= 8'h00;
    q4832 <= 8'h01;
    q4833 <= 8'h02;
    q4834 <= 8'h00;
  end else begin
    if(we_4830) q4830 <= wdata & 8'h87;
    if(we_4831) q4831 <= wdata & 8'h07;
    if(we_4832) q4832 <= wdata & 8'h07;
    if(we_4833) q4833 <= wdata & 8'h07;
    if(we_4834) q4834 <= wdata & 8'h07;
  end
end

// data ROM size, shared by the two units that pre-mask their own reads
wire [1:0] drom_size = q4834[1:0];

// -----------------------------------------------------------------------------
// units
// -----------------------------------------------------------------------------
wire [7:0] dcu_data;
wire [7:0] d4801, d4802, d4803, d4804, d4805, d4806, d4807;
wire [7:0] d4808, d4809, d480a, d480b, d480c;

spc7110_dcu spc7110_dcu_i(
  .clkin(clkin),
  .rst(rst),
  .we_4801(we_4801),
  .we_4802(we_4802),
  .we_4803(we_4803),
  .we_4804(we_4804),
  .we_4805(we_4805),
  .we_4806(we_4806),
  .we_4807(we_4807),
  .we_4808(we_4808),
  .we_4809(we_4809),
  .we_480a(we_480a),
  .we_480b(we_480b),
  .wdata(wdata),
  .rd_4800(rd_4800),
  .drom_size(drom_size),
  .dcu_data(dcu_data),
  // dcu_ready is not part of the register map: dcu_data already reads $00 while
  // the buffer the SNES owns is being refilled, and $480C bit7 is the flag the
  // game polls.  Left open on purpose.
  .dcu_ready(),
  .r4801(d4801),
  .r4802(d4802),
  .r4803(d4803),
  .r4804(d4804),
  .r4805(d4805),
  .r4806(d4806),
  .r4807(d4807),
  .r4808(d4808),
  .r4809(d4809),
  .r480a(d480a),
  .r480b(d480b),
  .r480c(d480c),
  .drom_req(dcu_drom_req),
  .drom_addr(dcu_drom_addr),
  .drom_ack(dcu_drom_ack),
  .drom_data(drom_data)
);

wire [7:0] p4810, p4811, p4812, p4813, p4814;
wire [7:0] p4815, p4816, p4817, p4818, p481a;

spc7110_data spc7110_data_i(
  .clkin(clkin),
  .rst(rst),
  .we_4811(we_4811),
  .we_4812(we_4812),
  .we_4813(we_4813),
  .we_4814(we_4814),
  .we_4815(we_4815),
  .we_4816(we_4816),
  .we_4817(we_4817),
  .we_4818(we_4818),
  .we_481a(we_481a),
  .wdata(wdata),
  .rd_4810(rd_4810),
  .rd_481a(rd_481a),
  .drom_size(drom_size),
  .r4810(p4810),
  .r4811(p4811),
  .r4812(p4812),
  .r4813(p4813),
  .r4814(p4814),
  .r4815(p4815),
  .r4816(p4816),
  .r4817(p4817),
  .r4818(p4818),
  .r481a(p481a),
  .drom_req(data_drom_req),
  .drom_addr(data_drom_addr),
  .drom_ack(data_drom_ack),
  .drom_data(drom_data)
);

wire [7:0] m4820, m4821, m4822, m4823, m4824, m4825, m4826, m4827;
wire [7:0] m4828, m4829, m482a, m482b, m482c, m482d, m482e, m482f;

spc7110_alu spc7110_alu_i(
  .clkin(clkin),
  .rst(rst),
  .we_4820(we_4820),
  .we_4821(we_4821),
  .we_4822(we_4822),
  .we_4823(we_4823),
  .we_4824(we_4824),
  .we_4825(we_4825),
  .we_4826(we_4826),
  .we_4827(we_4827),
  .we_482e(we_482e),
  .wdata(wdata),
  .r4820(m4820),
  .r4821(m4821),
  .r4822(m4822),
  .r4823(m4823),
  .r4824(m4824),
  .r4825(m4825),
  .r4826(m4826),
  .r4827(m4827),
  .r4828(m4828),
  .r4829(m4829),
  .r482a(m482a),
  .r482b(m482b),
  .r482c(m482c),
  .r482d(m482d),
  .r482e(m482e),
  .r482f(m482f)
);

spc7110_map spc7110_map_i(
  .snes_addr(snes_addr),
  .r4830(q4830),
  .r4831(q4831),
  .r4832(q4832),
  .r4833(q4833),
  .r4834(q4834),
  .drom_base(drom_base),
  .drom_mask(drom_mask),
  .rom_hit(map_rom_hit),
  .psram_addr(map_psram_addr),
  .is_sram(map_is_sram)
);

wire [7:0] c4840, c4841, c4842;

spc7110_rtcif spc7110_rtcif_i(
  .clkin(clkin),
  .rst(rst),
  .we_4840(we_4840),
  .we_4841(we_4841),
  .we_4842(we_4842),
  .wdata(wdata),
  .rd_4840(rd_4840),
  .rd_4841(rd_4841),
  .rd_4842(rd_4842),
  .r4840(c4840),
  .r4841(c4841),
  .r4842(c4842),
  .rtc_data(rtc_data),
  .rtc_we(rtc_we),
`ifndef MK2
  .rtc_data_wr(rtc_data_wr),
  .bkp_time(bkp_time),
  .bkp_flags(bkp_flags),
  .bkp_we(bkp_we),
  .bkp_time_in(bkp_time_in),
  .bkp_flags_in(bkp_flags_in)
`else
  .rtc_data_wr(rtc_data_wr)
`endif
);

// -----------------------------------------------------------------------------
// read-back mux
//
// Purely combinational, as the invariant of the register block demands: a read
// never waits for a data ROM fetch.  $4800 is served from the tile buffer the
// SNES owns ($00 while it is still being refilled, which is what the DCU already
// drives on dcu_data), and $4810 from the byte the data port fetched ahead.
// -----------------------------------------------------------------------------
reg [7:0] dout;
always @* begin
  dout = 8'h00;
  case(a)
    8'h00: dout = dcu_data;
    8'h01: dout = d4801;
    8'h02: dout = d4802;
    8'h03: dout = d4803;
    8'h04: dout = d4804;
    8'h05: dout = d4805;
    8'h06: dout = d4806;
    8'h07: dout = d4807;
    8'h08: dout = d4808;
    8'h09: dout = d4809;
    8'h0a: dout = d480a;
    8'h0b: dout = d480b;
    8'h0c: dout = d480c;

    8'h10: dout = p4810;
    8'h11: dout = p4811;
    8'h12: dout = p4812;
    8'h13: dout = p4813;
    8'h14: dout = p4814;
    8'h15: dout = p4815;
    8'h16: dout = p4816;
    8'h17: dout = p4817;
    8'h18: dout = p4818;
    8'h1a: dout = p481a;

    8'h20: dout = m4820;
    8'h21: dout = m4821;
    8'h22: dout = m4822;
    8'h23: dout = m4823;
    8'h24: dout = m4824;
    8'h25: dout = m4825;
    8'h26: dout = m4826;
    8'h27: dout = m4827;
    8'h28: dout = m4828;
    8'h29: dout = m4829;
    8'h2a: dout = m482a;
    8'h2b: dout = m482b;
    8'h2c: dout = m482c;
    8'h2d: dout = m482d;
    8'h2e: dout = m482e;
    8'h2f: dout = m482f;

    8'h30: dout = q4830;
    8'h31: dout = q4831;
    8'h32: dout = q4832;
    8'h33: dout = q4833;
    8'h34: dout = q4834;

    8'h40: dout = c4840;
    8'h41: dout = c4841;
    8'h42: dout = c4842;

    default: dout = 8'h00;
  endcase
end

assign reg_dout = dout;

endmodule

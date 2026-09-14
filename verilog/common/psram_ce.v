`timescale 1ns / 1ps
`default_nettype none

// Mk.III PSRAM /CE helper
//
// Keeping /CE asserted on the same PSRAM chip for too long causes data
// corruption due to refresh issues; therefore /CE must only be asserted during
// an actual active PSRAM cycle
//
// SD DMA supplies its access window, including address setup, from
// its own byte sequencer.
//
// The recovery signal forces a gap between writes

module psram_ce(
  input  CLK,
  input  ROM_CHIP,

  input  SNES_REQUEST,
  input  SNES_CYCLE_START_EARLY,
  input  SNES_CYCLE_START,
  input  SNES_CYCLE_END,
  input  SNES_DEAD,

  input  OTHER_ACTIVE,

  input  SD_DMA_TO_ROM,
  input  SD_DMA_SRAM_ACTIVE,
  input  SD_WRITE_N,

  output ROM_1CE,
  output ROM_2CE
);

reg snes_active = 1'b0;

reg ce_recovery_r = 1'b0;
reg snes_active_n = 1'b0;
reg other_active_n = 1'b0;
reg sd_write_n_n = 1'b1;

// OTHER_ACTIVE may fall on a rising CLK edge, this might lead to immediate
// /CE takeover by the next owner; prevent that using other_active_n which is
// generated on falling CLK edges
wire other_owner_idle = !OTHER_ACTIVE && !other_active_n;

always @(posedge CLK) begin
  if (SNES_DEAD || SNES_CYCLE_END)
    snes_active <= 1'b0;
  else if (SNES_CYCLE_START_EARLY && other_owner_idle && !SD_DMA_TO_ROM)
    snes_active <= SNES_REQUEST;
  else if (SNES_CYCLE_START)
    snes_active <= SNES_REQUEST;
end

// CE recovery is generated on negative clock edges for a full clock period to
// achieve earlier cycle end detection and ensure that the minimum tCPH of
// 5ns is met, and steer clear of immediate takeover by the next owner
always @(negedge CLK) begin
  ce_recovery_r <= (snes_active_n & ~snes_active)
                 | (other_active_n & ~OTHER_ACTIVE)
                 | (SD_DMA_TO_ROM & ~sd_write_n_n & SD_WRITE_N);
  snes_active_n <= snes_active;
  other_active_n <= OTHER_ACTIVE;
  sd_write_n_n <= SD_DMA_TO_ROM ? SD_WRITE_N : 1'b1;
end

wire snes_early_active = SNES_CYCLE_START_EARLY
                         && SNES_REQUEST
                         && !SNES_DEAD
                         && other_owner_idle;
wire snes_start_active = SNES_CYCLE_START
                         && SNES_REQUEST
                         && !SNES_DEAD
                         && other_owner_idle;
wire ce_active = SD_DMA_TO_ROM ? SD_DMA_SRAM_ACTIVE
                               : (snes_active
                                  || snes_early_active
                                  || snes_start_active
                                  || OTHER_ACTIVE);

assign ROM_1CE = !ce_active || ce_recovery_r ||  ROM_CHIP;
assign ROM_2CE = !ce_active || ce_recovery_r || !ROM_CHIP;

endmodule

`default_nettype wire

CORE = spc7110

VSRC = address.v cheat.v clk_test.v dac.v DCM_Scope.v main.v mcu_cmd.v msu.v \
       rtc.v sd_dma.v spc7110_alu.v spc7110_data.v spc7110_dcu.v spc7110_map.v \
       spc7110_regs.v spc7110_rtcif.v spi.v
VHSRC =

COMMON_IP = dac_buf msu_databuf snescmd_buf

XIL_IP =
XIL_IPCORE_DIR = ip/mk2

INT_IP = pll

# Registers XST is ALLOWED to absorb into a BLOCK RAM address port (Xst:3226).
# ctx_q is synchronous-read by construction; everything else in this core must
# stay asynchronous-read (the tile buffers shipped broken once when XST turned
# three of them into BRAMs that never advanced their address on real silicon).
# Extend with | when adding a legitimately synchronous-read array.
XST_ABSORB_WHITELIST = ctx_q

include ../settings.mk
include ../common.mk

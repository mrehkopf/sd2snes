/* ___DISCLAIMER___ */

#ifndef _TESTS_H
#define _TESTS_H

int test_sd(void);
int test_rtc(void);
int test_cic(void);
int test_fpga(void);
int test_mem(void);
int test_clk(void);

enum tests { TEST_SD = 0,
             TEST_USB,
             TEST_RTC,
             TEST_CIC,
             TEST_FPGA,
             TEST_RAM,
             TEST_CLK,
             TEST_DAC,
             TEST_SNES_IRQ,
             TEST_SNES_RAM,
             TEST_SNES_PA };

enum teststates { NO_RUN = 0, PASSED, FAILED };

#endif

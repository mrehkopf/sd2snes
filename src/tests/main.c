#include <arm/NXP/LPC17xx/LPC17xx.h>
#include <string.h>
#include "config.h"
#include "obj/autoconf.h"
#include "clock.h"
#include "uart.h"
#include "bits.h"
#include "power.h"
#include "timer.h"
#include "ff.h"
#include "diskio.h"
#include "spi.h"
#include "fileops.h"
#include "fpga.h"
#include "fpga_spi.h"
#include "filetypes.h"
#include "memory.h"
#include "snes.h"
#include "led.h"
#include "sort.h"
#include "cic.h"
#include "tests.h"
#include "cli.h"
#include "sdnative.h"
#include "crc.h"
#include "smc.h"
#include "msu1.h"
#include "rtc.h"
#include "tests.h"

#define EMC0TOGGLE	(3<<4)
#define MR0R		(1<<1)

int i;

int sd_offload = 0, ff_sd_offload = 0, sd_offload_tgt = 0;
int sd_offload_partial = 0;
uint16_t sd_offload_partial_start = 0;
uint16_t sd_offload_partial_end = 0;

volatile enum diskstates disk_state;
extern volatile tick_t ticks;
extern snes_romprops_t romprops;
extern volatile int reset_changed;

enum system_states {
  SYS_RTC_STATUS = 0
};

FIL logfile;

int main(void) {
  LPC_GPIO2->FIODIR = BV(4) | BV(5);
  LPC_GPIO1->FIODIR = BV(23) | BV(SNES_CIC_PAIR_BIT);
  BITBAND(SNES_CIC_PAIR_REG->FIOSET, SNES_CIC_PAIR_BIT) = 1;
  LPC_GPIO0->FIODIR = BV(16);

 /* connect UART3 on P0[25:26] + SSP0 on P0[15:18] + MAT3.0 on P0[10] */
  LPC_PINCON->PINSEL1 = BV(18) | BV(19) | BV(20) | BV(21) /* UART3 */
                      | BV(3) | BV(5);                    /* SSP0 (FPGA) except SS */
  LPC_PINCON->PINSEL0 = BV(31);                            /* SSP0 */
/*                      | BV(13) | BV(15) | BV(17) | BV(19)  SSP1 (SD) */

 /* pull-down CIC data lines */
  LPC_PINCON->PINMODE0 = BV(0) | BV(1) | BV(2) | BV(3);

  clock_disconnect();
  snes_init();
  snes_reset(1);
  power_init();
  timer_init();
  uart_init();
  fpga_spi_init();
  spi_preinit();
  led_init();
  led_std();
  rdyled(1);
  readled(0);
  writeled(0);
 /* do this last because the peripheral init()s change PCLK dividers */
  clock_init();
  LPC_PINCON->PINSEL0 |= BV(20) | BV(21);                  /* MAT3.0 (FPGA clock) */
  sdn_init();
  printf("\n\nsd2snes mk.2\n============\nfw ver.: " VER "\ncpu clock: %d Hz\n", CONFIG_CPU_FREQUENCY);
  printf("PCONP=%lx\n", LPC_SC->PCONP);

  file_init();
  cic_init(0);
/* setup timer (fpga clk) */
  LPC_TIM3->CTCR=0;
  LPC_TIM3->EMR=EMC0TOGGLE;
  LPC_TIM3->MCR=MR0R;
  LPC_TIM3->MR0=1;
  LPC_TIM3->TCR=1;
  fpga_init();

  char *testnames[12] = { "SD      ", "USB     ", "RTC     ", "CIC     ",
                          "FPGA    ", "RAM     ", "SD DMA  ", "CLK     ",
                          "DAC     ", "SNES IRQ", "SNES RAM", "SNES PA "};

  char *teststate_names [3] = { "no run", "Passed", "FAILED" };
  char *teststate_colornames [3] = { "no run", "\x1b[32;1mPassed\x1b[m", "\x1b[31;1mFAILED\x1b[m" };

  int testresults[12] = { NO_RUN, NO_RUN, NO_RUN, NO_RUN, NO_RUN,
                          NO_RUN, NO_RUN, NO_RUN, NO_RUN, NO_RUN,
                          NO_RUN, NO_RUN };
  rdyled(0);
  writeled(1);
  readled(1);
  f_open(&logfile, "/sd2snes/test_log.txt", FA_WRITE | FA_CREATE_ALWAYS);
  rdyled(1);
  writeled(0);
  readled(0);
  LOGPRINT("===log opened===\n");
  f_sync(&logfile);
  LOGPRINT("derp\n");
  f_sync(&logfile);
  testresults[TEST_SD] = test_sd();
  f_sync(&logfile);
//testresults[TEST_USB] = test_usb();
  testresults[TEST_RTC] = test_rtc();
  f_sync(&logfile);
  delay_ms(209);
  testresults[TEST_CIC] = test_cic();
  f_sync(&logfile);
  testresults[TEST_FPGA] = test_fpga();
  f_sync(&logfile);
  testresults[TEST_RAM] = test_mem();
  f_sync(&logfile);
  testresults[TEST_SDDMA] = test_sddma();
  f_sync(&logfile);
  LOGPRINT("Loading SNES test ROM\n=====================\n");
  f_sync(&logfile);
  load_rom((uint8_t*)"/sd2snes/test.bin", 0, LOADROM_WITH_RESET);
  LOGPRINT("\n\n\n");
  delay_ms(1000);
  testresults[TEST_CLK] = test_clk();
  f_sync(&logfile);
  fpga_set_bram_addr(0x1fff);
  fpga_write_bram_data(0x01); // tell SNES test program to continue
  uint8_t snestest_irq_state, snestest_pa_state, snestest_mem_state, snestest_mem_bank;
  uint8_t snestest_irq_done = 0, snestest_pa_done = 0, snestest_mem_done = 0;
  uint8_t last_irq_state = 0x77, last_pa_state = 0x77, last_mem_state = 0x77, last_mem_bank = 0x77;
  uint32_t failed_addr = 0;
  int snes_timeout = 0;
  tick_t now = getticks();
  while(!(snestest_irq_done & snestest_pa_done & snestest_mem_done) && !snes_timeout) {
    fpga_set_bram_addr(0);
    snestest_irq_state = fpga_read_bram_data();
    snestest_mem_state = fpga_read_bram_data();
    snestest_pa_state = fpga_read_bram_data();
    snestest_mem_bank = fpga_read_bram_data();
    if(snestest_irq_state != last_irq_state
       || snestest_mem_state != last_mem_state
       || snestest_pa_state != last_pa_state
       || snestest_mem_bank != last_mem_bank) {
      LOGPRINT("SNES test status: IRQ: %02x   PA: %02x   MEM: %02x/%02x\n", snestest_irq_state, snestest_pa_state, snestest_mem_state, snestest_mem_bank);
      f_sync(&logfile);
      now = getticks();
    } else {
      /* no status reports from SNES in 5 seconds -> dead */
      if(getticks() > now + 500) {
        LOGPRINT("Timeout! SNES appears to be dead!\n");
        snes_timeout = 1;
      }
    }
    last_irq_state = snestest_irq_state;
    last_mem_state = snestest_mem_state;
    last_pa_state = snestest_pa_state;
    last_mem_bank = snestest_mem_bank;
    if(snestest_pa_state != 0x00) snestest_pa_done = 1;
    if(snestest_irq_state != 0x00) snestest_irq_done = 1;
    if(snestest_mem_state == 0xff || snestest_mem_state == 0x5a) snestest_mem_done = 1;
    cli_entrycheck();
  }
  LOGPRINT("\n");
  f_sync(&logfile);
  if(snestest_pa_state == 0xff || !snestest_pa_done) testresults[TEST_SNES_PA] = FAILED;
  else testresults[TEST_SNES_PA] = PASSED;
  if(snestest_irq_state == 0xff || !snestest_irq_done) testresults[TEST_SNES_IRQ] = FAILED;
  else testresults[TEST_SNES_IRQ] = PASSED;
  if(!snestest_mem_done) {
    testresults[TEST_SNES_RAM] = FAILED;
  } else if(snestest_mem_state == 0xff) {
    testresults[TEST_SNES_RAM] = FAILED;
    fpga_set_bram_addr(4);
    failed_addr = fpga_read_bram_data();
    failed_addr |= fpga_read_bram_data() << 8;
    failed_addr |= fpga_read_bram_data() << 16;
    LOGPRINT("SNES MEM test FAILED (failed address: %06lx)\n", failed_addr);
  }
  else testresults[TEST_SNES_RAM] = PASSED;
  LOGPRINT("\n\nTEST SUMMARY\n============\n\n");
  LOGPRINT("Test      Result\n----------------\n");
  int testcount;
  for(testcount=0; testcount < 12; testcount++) {
    f_printf(&logfile, "%s  %s\n", testnames[testcount], teststate_names[testresults[testcount]]);
    printf("%s  %s\n", testnames[testcount], teststate_colornames[testresults[testcount]]);
  }
  f_close(&logfile);
  while(1) {
    toggle_rdy_led();
    toggle_read_led();
    delay_ms(200);
    toggle_read_led();
    toggle_write_led();
    delay_ms(200);
    toggle_write_led();
    toggle_rdy_led();
    delay_ms(200);
    cli_entrycheck();
  }
  cli_loop();
  while(1);
}


#include <string.h>
#include "config.h"
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

#include "usb.h"
#include "version.h"

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
const char fwhdr[CONFIG_FW_HEADERSIZE] __attribute__ ((section(".fwhdr")));

int main(void) {
  // TODO required for stm32?!
  // SCB->CPACR |= 0x00f00000;
  uart_init();
  printf("power_init\n");
  power_init();
  uart_init();
  GPIO_MODE_OUT(SNES_CIC_PAIR_REG, SNES_CIC_PAIR_BIT);
  SET_BIT(SNES_CIC_PAIR_REG, SNES_CIC_PAIR_BIT);
  GPIO_MODE_OUT(FPGA_SSREG, FPGA_SSBIT);

  printf("usb_dummy_init\n");
  usb_dummy_init();

 /* XXX check this connect UART3 on P0[25:26] + SSP0 on P0[15:18] */

  /* pull-down CIC data lines */
  GPIO_PULLDOWN(SNES_CIC_D0_REG, SNES_CIC_D0_BIT);
  GPIO_PULLDOWN(SNES_CIC_D1_REG, SNES_CIC_D1_BIT);

  printf("led_init\n");
  led_init();

  led_std();
  rdyled(1); readled(1); writeled(1);
  clock_disconnect();
  rdyled(1); readled(1); writeled(0);
  printf("snes_init\n");
  snes_init();
  snes_reset(1);
  printf("timer_init\n");
  timer_init();
  rdyled(1); readled(0); writeled(1);
  printf("uart_init\n");
  uart_init();
  rdyled(0); readled(1); writeled(1);
  printf("fpga_spi_init\n");
  fpga_spi_init();
  rdyled(1); readled(1); writeled(0);
  printf("spi_preinit\n");
  spi_preinit();
  rdyled(1); readled(0); writeled(0);
 /* do this last because the peripheral init()s change PCLK dividers */
  printf("clock_init\n");
  clock_init();
  printf("sdn_init\n");
  sdn_init();
  printf("delay_ms(500)\n");
  delay_ms(500);
  printf("\n\n\n\n\n");
  printf("\n\n" DEVICE_NAME "\n======================\n\nfw ver.: " CONFIG_VERSION "\ncpu clock: %d Hz\n", CONFIG_CPU_FREQUENCY);
#ifdef CONFIG_MK3_STM32
  printf("AHB1ENR=%lx\n", RCC->AHB1ENR);
  printf("AHB2ENR=%lx\n", RCC->AHB2ENR);
  printf("APB1ENR=%lx\n", RCC->APB1ENR);
  printf("APB2ENR=%lx\n", RCC->APB2ENR);
#else
  printf("PCONP=%lx\n", LPC_SC->PCONP);
#endif
  file_init();
  cic_init(0);

  fpga_init();

  char *testnames[12] = { "SD      ", "USB     ", "RTC     ", "CIC     ",
                          "FPGA    ", "RAM     ", "SD DMA  ", "CLK     ",
                          "DAC     ", "SNES IRQ", "SNES RAM", "SNES PA " };

  char *teststate_names [4] = { "no run", "Passed", "FAILED", "not implemented" };
  char *teststate_colornames [4] = { "no run", "\x1b[32;1mPassed\x1b[m", "\x1b[31;1mFAILED\x1b[m", "\x1b[30;1mnot implemented\x1b[m" };

  const char* mem_errors[13] = {"** SNES MEM TEST A10 ERROR. CHECK RA108, U103, FPGA\n",
                                "** SNES MEM TEST A11 ERROR. CHECK RA109, U103, FPGA\n",
                                "** SNES MEM TEST A12 ERROR. CHECK RA109, U103, FPGA\n",
                                "** SNES MEM TEST A13 ERROR. CHECK RA108, U103, FPGA\n",
                                "** SNES MEM TEST A14 ERROR. CHECK RA108, U103, FPGA\n",
                                "** SNES MEM TEST A16 ERROR. CHECK RA107, U103, FPGA\n",
                                "** SNES MEM TEST A17 ERROR. CHECK RA106, U102, FPGA\n",
                                "** SNES MEM TEST A18 ERROR. CHECK RA106, U102, FPGA\n",
                                "** SNES MEM TEST A19 ERROR. CHECK RA105, U102, FPGA\n",
                                "** SNES MEM TEST A20 ERROR. CHECK RA105, U102, FPGA\n",
                                "** SNES MEM TEST A21 ERROR. CHECK RA104, U102, FPGA\n",
                                "** SNES MEM TEST A22 ERROR. CHECK RA104, U102, FPGA\n",
                                "** SNES MEM TEST A23 ERROR. CHECK RA103, U102, FPGA\n"
                                };
  int testresults[12] = { NO_RUN, NO_IMPL, NO_RUN, NO_RUN, NO_RUN,
                          NO_RUN, NO_RUN, NO_RUN, NO_IMPL, NO_RUN,
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
  testresults[TEST_SD] = test_sd();
  f_sync(&logfile);
//testresults[TEST_USB] = test_usb();
  testresults[TEST_RTC] = test_rtc();
  f_sync(&logfile);
  delay_ms(209);
//testresults[TEST_CIC] = test_cic();
  f_sync(&logfile);
  testresults[TEST_FPGA] = test_fpga();
  f_sync(&logfile);
  testresults[TEST_RAM] = test_memconn();
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
  int overallresult = PASSED;
for(int i=0; i<1; i++) {
  // snes_reset(1);
  // delay_ms(20);
  // snes_reset(0);
  // delay_ms(200);
  fpga_set_bram_addr(4);
  fpga_write_bram_data(0xff); // write memory error log termination
  fpga_set_bram_addr(0x1f);
  fpga_write_bram_data(0x01); // tell SNES test program to continue
  uint8_t snestest_irq_state, snestest_pa_state, snestest_mem_state, snestest_mem_bank;
  uint8_t snestest_irq_done = 0, snestest_pa_done = 0, snestest_mem_done = 0;
  uint8_t last_irq_state = 0x77, last_pa_state = 0x77, last_mem_state = 0x77, last_mem_bank = 0x77;
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
      /* no status reports from SNES in 2 seconds -> dead */
      if(getticks() > now + 200) {
        LOGPRINT("** SNES CPU ERROR. CHECK RAM TEST, CLK TEST, FBA101, FBA102, RA103-109, RA121-122, U101-103, FPGA\n");
        snestest_mem_state = 0xff;
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
  if(snestest_pa_state != 0x5a || !snestest_pa_done) {
    testresults[TEST_SNES_PA] = FAILED;
    if(!snes_timeout) {
      LOGPRINT("** SNES PA BUS ERROR. CHECK RA101-102, RA109-110, U101, U103, FPGA\n");
    }
//    break;
  } else {
    testresults[TEST_SNES_PA] = PASSED;
  }
  if(snestest_irq_state != 0x5a || !snestest_irq_done) {
    testresults[TEST_SNES_IRQ] = FAILED;
    if(!snes_timeout) {
      LOGPRINT("** SNES IRQ ERROR. CHECK Q101, R102, R103, FPGA pin B1\n");
    }
//    break;
  } else {
    testresults[TEST_SNES_IRQ] = PASSED;
  }
  if(!snestest_mem_done) {
    testresults[TEST_SNES_RAM] = FAILED;
  } else if(snestest_mem_state != 0x5a && !snes_timeout) {
    testresults[TEST_SNES_RAM] = FAILED;
    fpga_set_bram_addr(4);
    uint8_t errorindex, num_mem_errors = 0;
    while((errorindex = fpga_read_bram_data()) != 0xff && num_mem_errors < 13) {
      LOGPRINT(mem_errors[errorindex]);
      num_mem_errors++;
    }
    if(num_mem_errors > 10) {
      LOGPRINT("** GENERAL MEM TEST ERRORS. CHECK RA102-103, RA107, U101-103, FPGA\n");
    }
    if(num_mem_errors || snes_timeout) break;
  }
  else testresults[TEST_SNES_RAM] = snes_timeout ? FAILED : PASSED;
}
  LOGPRINT("\n\nTEST SUMMARY\n============\n\n");
  LOGPRINT("Test      Result\n----------------\n");
  int numtests = 12;
  for(int testcount=0; testcount < numtests; testcount++) {
    f_printf(&logfile, "%s  %s\n", testnames[testcount], teststate_names[testresults[testcount]]);
    printf("%s  %s\n", testnames[testcount], teststate_colornames[testresults[testcount]]);
    if(testresults[testcount] == FAILED) {
      overallresult = FAILED;
    }
  }
  f_close(&logfile);
  led_pwm();
  int ledbright = 15;
  rdyled(0);
  readled(0);
  writeled(0);
  while(1) {
    if(overallresult == PASSED) {
      rdybright(ledbright);
    } else {
      writebright(ledbright);
    }
    ledbright = (ledbright - 1) & 0xf;
    delay_ms(66);
    cli_entrycheck();
  }
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


/* ___DISCLAIMER___ */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "config.h"
#include "uart.h"
#include "timer.h"
#include "led.h"
#include "cli.h"
#include "fpga.h"
#include "fpga_spi.h"
#include "ff.h"
#include "fileops.h"
#include "crc32.h"
#include "diskio.h"
#include "cic.h"
#include "rtc.h"
#include "memory.h"
#include "snes.h"
#include "cli.h"

#include "tests.h"

#define PROGRESS	("-\\|/")

int test_sd() {
  printf("SD test... please insert card\n=============================\n");
  while(disk_status(0) & (STA_NOINIT|STA_NODISK)) cli_entrycheck();

  file_open((uint8_t*)"/sd2snes/testfile.bin", FA_WRITE | FA_CREATE_ALWAYS);
  if(file_res) {
    printf("could not open /sd2snes/testfile.bin: Error %d\n", file_res);
    printf("FAILED\n\n\n");
    return FAILED;
  }
  uint32_t testval = 0x55AA55AA;
  uint32_t crc = 0;
  uint32_t count, blkcount;
  for(count=0; count < 8192; count++) {
    for(blkcount=0; blkcount < 512; blkcount++) {
      file_buf[blkcount] = testval&0xff;
      crc=crc32_update(crc, testval&0xff);
      testval ^= (crc * (count + blkcount + 7)) - 1;
    }
    file_write();
  }
  printf("crc1 = %08lx ", crc);
  file_close();
  file_open((uint8_t*)"/sd2snes/testfile.bin", FA_READ);
  uint32_t crc2 = 0;
  for(count=0; count < 8192; count++) {
    file_read();
    for(blkcount=0; blkcount < 512; blkcount++) {
      testval = file_buf[blkcount];
      crc2 = crc32_update(crc2, testval&0xff);
    }
  }
  file_close();
  printf("crc2 = %08lx ", crc2);
  if(crc==crc2) {
    printf("  PASSED\n\n\n");
    return PASSED;
  } else {
    printf("  FAILED\n\n\n");
    return FAILED;
  }
}

int test_cic() {
  int cic_state = get_cic_state();
  printf("CIC Test:\n=========\n");
  printf("Current CIC state: %s\n", get_cic_statename(cic_state));
  if(cic_state == CIC_FAIL) {
    printf("CIC reports error, push reset...\n");
    while((cic_state = get_cic_state()) == CIC_FAIL);
  }
  if(cic_state == CIC_OK) {
    printf("CIC reports OK; no pair mode available. Provoking CIC error...\n");
    cic_pair(1,1);
    delay_ms(200);
    cic_init(0);
    printf("new CIC state: %s\n", get_cic_statename(get_cic_state()));
    if(get_cic_state() == CIC_FAIL) {
      printf("***Please reset SNES***\n");
      int failcount=2;
      while(failcount--) {
        while(get_cic_state() == CIC_FAIL);
        delay_ms(200);
      }
      if(get_cic_state() != CIC_FAIL) {
        printf("PASSED\n\n\n");
        return PASSED;
      }
      printf("CIC did not recover properly.\nFAILED\n");
      return FAILED;
    }
    printf("FAILED\n\n\n");
    return FAILED;
  }
  if(cic_state == CIC_SCIC) {
    printf("CIC reports OK; pair mode available. Switching to pair mode...\n");
    cic_init(1);
    delay_ms(100);
    cic_pair(0,0);
    delay_ms(1000);
    printf("new CIC state: %s\n", get_cic_statename(cic_state = get_cic_state()));
    if(get_cic_state() != CIC_PAIR) {
      printf("FAILED to switch to pair mode!!!\n");
      return FAILED;
    }
  }
  if(cic_state == CIC_PAIR) {
    cic_init(1);
    cic_pair(0,0);
    printf("cycling modes, observe power LED color\n");
    for(cic_state = 0; cic_state < 17; cic_state++) {
      cic_videomode(cic_state & 1);
      delay_ms(200);
    }
  }
  printf("PASSED\n\n\n");
  return PASSED;
}

int test_rtc() {
  struct tm time;
  printf("RTC Test\n========\n");
  printf("setting clock to 2011-01-01 00:00:00\n");
  set_bcdtime(0x20110101000000LL);
  printf("waiting 5 seconds\n");
  delay_ms(5000);
//  uint64_t newtime = get_bcdtime();
  printf("new time: ");
  read_rtc(&time);
  printtime(&time);
  if((get_bcdtime() & 0xffffffffffffff) >= 0x20110101000004LL) {
    printf("PASSED\n\n\n");
    return PASSED;
  } else printf("FAILED\n\n\n");
  return FAILED;
}

int test_fpga() {
  printf("FPGA test\n=========\n");
  printf("configuring fpga...\n");
  fpga_pgm((uint8_t*)"/sd2snes/test.bit");
  printf("basic communication test...");
  if(fpga_test() != FPGA_TEST_TOKEN) {
    printf("FAILED\n\n\n");
    return FAILED;
  } else printf("PASSED\n\n\n");
  return PASSED;
}

int test_mem() {
  printf("RAM test\n========\n");
  printf("Testing RAM0 (128Mbit) - writing RAM -");
  uint32_t addr;
  snes_reset(1);
  fpga_select_mem(0);
  set_mcu_addr(0);
  FPGA_DESELECT();
  delay_ms(1);
  FPGA_SELECT();
  delay_ms(1);
  FPGA_TX_BYTE(0x98);
  for(addr=0; addr < 16777216; addr++) {
    if((addr&0xffff) == 0)printf("\x8%c", PROGRESS[(addr>>16)&3]);
    FPGA_TX_BYTE((addr)+(addr>>8)+(addr>>16));
    FPGA_WAIT_RDY();
  }
  FPGA_DESELECT();
  printf(" verifying RAM -");
  uint8_t data, expect, error=0, failed=0;
  set_mcu_addr(0);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x88);
  for(addr=0; addr < 16777216; addr++) {
    if((addr&0xffff) == 0)printf("\x8%c", PROGRESS[(addr>>16)&3]);
    FPGA_WAIT_RDY();
    data = FPGA_RX_BYTE();
    expect = (addr)+(addr>>8)+(addr>>16);
    if(data != expect) {
      printf("error @0x%06lx: expected 0x%02x, got 0x%02x\n", addr, expect, data);
      error++;
      failed=1;
      if(error>20) {
        printf("too many errors, aborting\n");
        break;
      }
    }
  }
  FPGA_DESELECT();
  if(error) printf("RAM0 FAILED\n");
  else printf("RAM0 PASSED\n");
  printf("Testing RAM1 (4Mbit) - writing RAM - ");
  snes_reset(1);
  fpga_select_mem(1);
  for(addr=0; addr < 524288; addr++) {
    sram_writebyte((addr)+(addr>>8)+(addr>>16), addr);
  }
  printf("verifying RAM...");
  error = 0;
  for(addr=0; addr < 524288; addr++) {
    data = sram_readbyte(addr);
    expect = (addr)+(addr>>8)+(addr>>16);
    if(data != expect) {
      printf("error @0x%05lx: expected 0x%02x, got 0x%02x\n", addr, expect, data);
      error++;
      failed=1;
      if(error>20) {
        printf("too many errors, aborting\n");
        break;
      }
    }
  }
  if(error) printf("RAM1 FAILED\n\n\n");
  else printf("RAM1 PASSED\n\n\n");
  if(failed) return FAILED;
  return PASSED;
}

int test_clk() {
  uint32_t sysclk[4];
  int32_t diff, max_diff = 0;
  int i, error=0;
  printf("sysclk test\n===========\n");
  printf("measuring SNES clock...\n");
  for(i=0; i<4; i++) {
    sysclk[i]=get_snes_sysclk();
    if(sysclk[i] < 21000000 || sysclk[i] > 22000000) error = 1;
    printf("%lu Hz ", sysclk[i]);
    if(i) {
      diff = sysclk[i] - sysclk[i-1];
      if(diff < 0) diff = -diff;
      if(diff > max_diff) max_diff = diff;
      printf("diff = %ld  max = %ld", diff, max_diff);
    }
    printf("\n");
    delay_ms(1010);
  }
  if(error) {
    printf("clock frequency out of range!\n");
  }
  if(diff > 1000000) {
    printf("clock variation too great!\n");
    error = 1;
  }
  printf("   CPUCLK: %lu\n", get_snes_cpuclk());
  printf("  READCLK: %lu\n", get_snes_readclk());
  printf(" WRITECLK: %lu\n", get_snes_writeclk());
  printf("  PARDCLK: %lu\n", get_snes_pardclk());
  printf("  PAWRCLK: %lu\n", get_snes_pawrclk());
  printf("  REFRCLK: %lu\n", get_snes_refreshclk());
  printf("ROMSELCLK: %lu\n", get_snes_romselclk());
  if(error) {
    printf("FAILED\n\n\n");
    return FAILED;
  }
  printf("PASSED\n\n\n");
  return PASSED;
}

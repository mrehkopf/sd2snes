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

extern FIL logfile;

int test_sd() {
  LOGPRINT("SD test... please insert card\n=============================\n");
  f_sync(&logfile);
  while(disk_status(0) & (STA_NOINIT|STA_NODISK)) cli_entrycheck();

  file_open((uint8_t*)"/sd2snes/testfile.bin", FA_WRITE | FA_CREATE_ALWAYS);
  if(file_res) {
    LOGPRINT("could not open /sd2snes/testfile.bin: Error %d\n", file_res);
    LOGPRINT("FAILED\n\n\n");
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
  LOGPRINT("crc1 = %08lx ", crc);
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
  LOGPRINT("crc2 = %08lx ", crc2);
  if(crc==crc2) {
    LOGPRINT("  PASSED\n\n\n");
    return PASSED;
  } else {
    LOGPRINT("  FAILED\n\n\n");
    return FAILED;
  }
}

int test_cic() {
  int cic_state = get_cic_state();
  LOGPRINT("CIC Test:\n=========\n");
  LOGPRINT("Current CIC state: %s\n", get_cic_statename(cic_state));
  if(cic_state == CIC_FAIL) {
    tick_t now = getticks();
    LOGPRINT("CIC reports error, push reset...\n");
    while(((cic_state = get_cic_state()) == CIC_FAIL) && (getticks() < now + 1000)) {
      toggle_rdy_led();
      delay_ms(200);
    }
    rdyled(1);
    if(cic_state == CIC_FAIL) {
      LOGPRINT("CIC did not come up ok within 10 seconds.\nFAILED\n");
      return FAILED;
    }
  }
  if(cic_state == CIC_OK) {
    LOGPRINT("CIC reports OK; no pair mode available. Provoking CIC error...\n");
    cic_pair(1,1);
    delay_ms(200);
    cic_init(0);
    delay_ms(100);
    LOGPRINT("new CIC state: %s\n", get_cic_statename(get_cic_state()));
    if(get_cic_state() == CIC_FAIL) {
      LOGPRINT("***Please reset SNES***\n");
      int failcount=2;
      while(failcount--) {
        while(get_cic_state() == CIC_FAIL) {
          toggle_rdy_led();
          delay_ms(200);
        }
        delay_ms(200);
      }
      rdyled(1);
      if(get_cic_state() != CIC_FAIL) {
        LOGPRINT("PASSED\n\n\n");
        return PASSED;
      }
      LOGPRINT("CIC did not recover properly.\nFAILED\n");
      return FAILED;
    }
    LOGPRINT("FAILED\n\n\n");
    return FAILED;
  }
  if(cic_state == CIC_SCIC) {
    LOGPRINT("CIC reports OK; pair mode available. Switching to pair mode...\n");
    cic_init(1);
    delay_ms(100);
    cic_pair(0,0);
    delay_ms(1000);
    LOGPRINT("new CIC state: %s\n", get_cic_statename(cic_state = get_cic_state()));
    if(get_cic_state() != CIC_PAIR) {
      LOGPRINT("FAILED to switch to pair mode!!!\n");
      return FAILED;
    }
  }
  if(cic_state == CIC_PAIR) {
    cic_init(1);
    cic_pair(0,0);
    LOGPRINT("cycling modes, observe power LED color\n");
    for(cic_state = 0; cic_state < 17; cic_state++) {
      cic_videomode(cic_state & 1);
      delay_ms(200);
    }
  }
  LOGPRINT("PASSED\n\n\n");
  return PASSED;
}

int test_rtc() {
  struct tm time;
  LOGPRINT("RTC Test\n========\n");
  LOGPRINT("setting clock to 2011-01-01 00:00:00\n");
  set_bcdtime(0x20110101000000LL);
  LOGPRINT("waiting 5 seconds\n");
  delay_ms(5000);
//  uint64_t newtime = get_bcdtime();
  LOGPRINT("new time: ");
  read_rtc(&time);
  printtime(&time);
  if((get_bcdtime() & 0xffffffffffffff) >= 0x20110101000004LL) {
    LOGPRINT("PASSED\n\n\n");
    return PASSED;
  } else LOGPRINT("FAILED\n\n\n");
  return FAILED;
}

int test_fpga() {
  LOGPRINT("FPGA test\n=========\n");
  LOGPRINT("configuring fpga...\n");
  fpga_pgm((uint8_t*)"/sd2snes/test.bit");
  LOGPRINT("basic communication test...");
  if(fpga_test() != FPGA_TEST_TOKEN) {
    LOGPRINT("FAILED\n\n\n");
    return FAILED;
  } else LOGPRINT("PASSED\n\n\n");
  return PASSED;
}

int test_mem() {
  LOGPRINT("RAM test\n========\n");
  LOGPRINT("Testing RAM0 (128Mbit) - clearing RAM -");
  sram_memset(0, 16777216, 0);
  LOGPRINT(" writing RAM -");
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
  LOGPRINT(" verifying RAM -");
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
      LOGPRINT("error @0x%06lx: expected 0x%02x, got 0x%02x\n", addr, expect, data);
      error++;
      failed=1;
      if(error>20) {
        LOGPRINT("too many errors, aborting\n");
        break;
      }
    }
  }
  FPGA_DESELECT();
  if(error) {
    LOGPRINT("RAM0 FAILED\n");
  } else {
    LOGPRINT("RAM0 PASSED\n\n\n");
  }
  save_sram((uint8_t*)"/sd2snes/ram0dump.bin", 16777216, 0);
  LOGPRINT("Testing RAM1 (4Mbit) - writing RAM - ");
  snes_reset(1);
  fpga_select_mem(1);
  for(addr=0; addr < 524288; addr++) {
    sram_writebyte((addr)+(addr>>8)+(addr>>16), addr);
  }
  LOGPRINT("verifying RAM...");
  error = 0;
  for(addr=0; addr < 524288; addr++) {
    data = sram_readbyte(addr);
    expect = (addr)+(addr>>8)+(addr>>16);
    if(data != expect) {
      LOGPRINT("error @0x%05lx: expected 0x%02x, got 0x%02x\n", addr, expect, data);
      error++;
      failed=1;
      if(error>20) {
        LOGPRINT("too many errors, aborting\n");
        break;
      }
    }
  }
  if(error) {
    LOGPRINT("RAM1 FAILED\n\n\n");
  } else {
    LOGPRINT("RAM1 PASSED\n\n\n");
  }
  save_sram((uint8_t*)"/sd2snes/ram1dump.bin", 524288, 0);
  if(failed) return FAILED;
  return PASSED;
}

int test_clk() {
  uint32_t sysclk[4];
  int32_t diff, max_diff = 0;
  int i, error=0;
  LOGPRINT("sysclk test\n===========\n");
  LOGPRINT("measuring SNES clock...\n");
  for(i=0; i<4; i++) {
    sysclk[i]=get_snes_sysclk();
    if(sysclk[i] < 21000000 || sysclk[i] > 22000000) error = 1;
    LOGPRINT("%lu Hz ", sysclk[i]);
    if(i) {
      diff = sysclk[i] - sysclk[i-1];
      if(diff < 0) diff = -diff;
      if(diff > max_diff) max_diff = diff;
      LOGPRINT("diff = %ld  max = %ld", diff, max_diff);
    }
    LOGPRINT("\n");
    delay_ms(1010);
  }
  if(error) {
    LOGPRINT("clock frequency out of range!\n");
  }
  if(diff > 1000000) {
    LOGPRINT("clock variation too great!\n");
    error = 1;
  }
  LOGPRINT("   CPUCLK: %lu\n", get_snes_cpuclk());
  LOGPRINT("  READCLK: %lu\n", get_snes_readclk());
  LOGPRINT(" WRITECLK: %lu\n", get_snes_writeclk());
  LOGPRINT("  PARDCLK: %lu\n", get_snes_pardclk());
  LOGPRINT("  PAWRCLK: %lu\n", get_snes_pawrclk());
  LOGPRINT("  REFRCLK: %lu\n", get_snes_refreshclk());
  LOGPRINT("ROMSELCLK: %lu\n", get_snes_romselclk());
  if(error) {
    LOGPRINT("FAILED\n\n\n");
    return FAILED;
  }
  LOGPRINT("PASSED\n\n\n");
  return PASSED;
}

int test_sddma() {
//  int i=0;
//  for(i=0; i<4; i++) {
    uint32_t len;
    fpga_select_mem(0);
    LOGPRINT("SD DMA test\n===========\nclearing RAM - ");
    sram_memset(0, 16777216, 0);
    LOGPRINT("loading test file - ");
    if((len = load_sram_offload((uint8_t*)"/sd2snes/dmatest.bin", 0)) != 16777216) {
      LOGPRINT("DMA test file size mismatch! (expected 16777216, got %lu)\nFAILED\n\n\n", len);
      return FAILED;
    }

    LOGPRINT("verifying -");

    uint32_t addr;
    uint8_t data, expect;
    int error = 0;
    set_mcu_addr(0);
    FPGA_SELECT();
    FPGA_TX_BYTE(0x88);
    for(addr=0; addr < 16777216; addr++) {
      if((addr&0xffff) == 0)printf("\x8%c", PROGRESS[(addr>>16)&3]);
      FPGA_WAIT_RDY();
      data = FPGA_RX_BYTE();
      expect = (addr)+(addr>>8)+(addr>>16);
      if(data != expect) {
        LOGPRINT("error @0x%06lx: expected 0x%02x, got 0x%02x\n", addr, expect, data);
        error++;
        if(error>20) {
          LOGPRINT("too many errors, aborting\n");
          break;
        }
      }
    }
    FPGA_DESELECT();
    save_sram((uint8_t*)"/sd2snes/dma_dump.bin", 16777216, 0);
    if(error) {
      LOGPRINT("FAILED\n\n\n");
      return FAILED;
    }
//  }
  LOGPRINT("PASSED\n\n\n");
  return PASSED;
}

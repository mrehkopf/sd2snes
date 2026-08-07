/* ___DISCLAIMER___ */

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
#include "check.h"

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
  for(count=0; count < 1024; count++) {
    for(blkcount=0; blkcount < 512; blkcount++) {
      file_buf[blkcount] = testval&0xff;
      crc=crc32_update(crc, testval&0xff);
      testval ^= (crc * (count + blkcount + 7)) - 1;
    }
    file_write(512);
  }
  LOGPRINT("crc1 = %08lx ", crc);
  file_close();
  file_open((uint8_t*)"/sd2snes/testfile.bin", FA_READ);
  uint32_t crc2 = 0;
  for(count=0; count < 1024; count++) {
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
  enum teststates result;
  struct tm time;
  LOGPRINT("RTC Test\n========\n");
  LOGPRINT("setting clock to 2019-02-23 00:00:00\n");
  set_bcdtime(0x20190223000000LL);
  LOGPRINT("waiting 2 seconds\n");
  delay_ms(2010);
  LOGPRINT("new time: ");
  read_rtc(&time);
  printtime(&time);
  if((get_bcdtime() & 0xffffffffffffff) >= 0x20190223000002LL) {
    LOGPRINT("PASSED\n\n\n");
    result = PASSED;
  } else {
    LOGPRINT("FAILED\n\n\n");
    result = FAILED;
  }
  return result;
}

int test_fpga() {
  uint8_t testbyte = 0;
  LOGPRINT("FPGA test\n=========\n");
  LOGPRINT("configuring fpga...\n");
  fpga_pgm((uint8_t*)"/sd2snes/fpga_test." FPGA_CONF_EXT);
  LOGPRINT("basic communication test...");
  if((testbyte = fpga_test()) != FPGA_TEST_TOKEN) {
    LOGPRINT("Expected: %02x; received: %02x\n", FPGA_TEST_TOKEN, testbyte);
    LOGPRINT("FAILED\n\n\n");
    return FAILED;
  } else LOGPRINT("PASSED\n\n\n");
  return PASSED;
}

int test_memconn() {
  LOGPRINT("RAM connection test\n===================\n");
  uint32_t error[3] = {0, 0, 0};
  uint32_t dataerror[3] = {0, 0, 0};
  uint8_t knownaddr[3][24] = {{0},{0},{0}};
  uint8_t knowndata16[2][16] = {{0},{0}};
  uint8_t knowndata8[8] = {0};
  uint8_t knowncoll16[2][24][24] = {{{0},{0}},{{0},{0}}};
  uint8_t knowncoll8[20][20] = {{0},{0}};
  uint8_t knownlog[10] = {0};
  uint8_t data = 1;
  uint32_t data16 = 1;
  uint32_t addr = 0;
  uint32_t offset;
  uint8_t chip = 0;
  uint8_t line = 0;
  uint8_t shortcount = 0;
  uint32_t shortoffset = 0;
  uint8_t shortline = 0;
  uint32_t error_sum = 0;
//  uint8_t dataerror = 0;
  int iter = 0;
  int localerror;

  // RAM 0 TESTS (2 ICs)
  fpga_select_mem(0);

  const uint8_t ram0_bases[] = RAM0_BASES;
  for(chip = 1; chip <= RAM0_NUM_CHIPS; chip++) {
    addr = ram0_bases[chip-1];
    LOGPRINT("\nTesting RAM0.%d (U50%d)...\n", chip, chip);

    for(iter = 0; iter < 256; iter++) {
      line = 0;
      data = 1;

      for(int i = 0; i < RAM0_NUM_CHIPS; i++) {
        sram_writeshort(0x0000, ram0_bases[i]);
        for(offset = RAM0_SECOND_ADDR; offset <= 0x800000; offset <<= 1) {
          sram_writeshort(0x0000, offset + ram0_bases[i]);
        }
      }

      // check for byte select error
      localerror = 0;
      for(int byte = 0; byte < 2; byte++) {
        // clear test location
        sram_writeshort(0x7777, addr);

        // set FPGA internal data register without writing to test location
        // (write to dummy address)
        sram_writeshort(0x55aa, 0x56789a);

        // perform byte write and check that the other byte of the 16-bit word
        // did not assume an incorrect value
        sram_writebyte(0x22, addr ^ byte);
        if(sram_readbyte((addr + 1) ^ byte) != 0x77) {
          localerror = 1;
        }
      }
      if(localerror) {
          if(!knownlog[0 + (chip - 1)]) {
            LOGPRINT("  U50%d ERROR - CHECK LB# / UB#\n", chip);
            knownlog[0 + (chip - 1)] = 1;
          }
         error[chip]++;
      }

      // check data lines (15:0)
      sram_writeshort(0x0000, addr);
      for(data16 = 1; data16 <= 0x8000; data16 <<= 1) {
        localerror = 0;
        sram_writeshort(data16, addr);
        if(!(sram_readshort(addr) & data16)) localerror = 1;
        sram_writeshort(~data16, addr);
        if((sram_readshort(addr) & data16)) localerror = 1;
        if(localerror) {
          if(!knowndata16[(chip - 1)][line]) {
            LOGPRINT("  U50%d ERROR - CHECK D%d\n", chip, line ^ 8);
            knowndata16[(chip - 1)][line] = 1;
            dataerror[chip]++;
            error[chip]++;
          }
        }
        line++;
      }

      if(dataerror[chip]) {
        if(!knownlog[2 + (chip - 1)]) {
          LOGPRINT("  U50%d DATA LINE / BYTE ERRORS DETECTED. Address line tests may be unreliable\n", chip);
          knownlog[2 + (chip - 1)] = 1;
        }
      }

      line = 0;
      // check actual address lines
      for(offset = RAM0_SECOND_ADDR; offset <= 0x800000; offset <<= 1) {
        for(shortoffset = RAM0_SECOND_ADDR; shortoffset <= 0x800000; shortoffset <<= 1) {
          sram_writeshort(0, addr + shortoffset);
        }
        sram_writebyte(0x00, addr);
        sram_writebyte(0xff, addr + offset);
        // check data disconnects/shorts + address disconnects
        if(!sram_readbyte(addr + offset) || sram_readbyte(addr)) {
          if(!knownaddr[chip][line]) {
            LOGPRINT("  U50%d ERROR - CHECK A%d\n", chip, line);
            knownaddr[chip][line] = 1;
            error[chip]++;
          }
        }

        // check possible shorted address lines
        shortcount = 0;
        shortline = 0;
        for(shortoffset = RAM0_SECOND_ADDR; shortoffset <= 0x800000; shortoffset <<= 1) {
          if(sram_readbyte(addr + shortoffset)) {
            shortcount++;
          }
          if(shortcount > 1) {
            shortcount = 1;
            if(!knowncoll16[chip-1][line][shortline]) {
              LOGPRINT("  U50%d ERROR - CHECK POSSIBLE SHORT A%d - A%d\n", chip, line, shortline);
              knowncoll16[chip-1][line][shortline] = 1;
            }
          }
          shortline++;
        }
        line++;
      }
      if(error[chip] > 20) {
        if(!knownlog[4 + (chip - 1)]) {
          LOGPRINT("  U50%d GENERAL ERROR - CHECK CE# / OE# / WE#\n", chip);
          knownlog[4 + (chip - 1)] = 1;
        }
      }
    }
    error_sum += error[chip];
  }
  if(error_sum > 40) {
    if(!knownlog[6]) {
      #ifdef CONFIG_MK2
      LOGPRINT("  U501 ERROR - CHECK FPGA CE# / OE# / WE#\n");
      #else
        #ifdef CONFIG_MK3
          LOGPRINT("  U501 + U502 ERROR - CHECK FPGA CE# / OE# / WE#\n");
        #endif
      #endif
      knownlog[6] = 1;
    }
  }

    // RAM 1 TESTS
  fpga_select_mem(1);
  LOGPRINT("\nTesting RAM1 (U511)...\n");

  for(iter = 0; iter < 256; iter++) {

    addr = 0;
    line = 0;
    data = 1;
    chip = 0;

    for(offset = 1; offset <= 0x20000; offset <<= 1) {
      sram_writebyte(0x00, offset);
    }

    // check data lines (7:0)
    sram_writebyte(0x00, addr);
    for(data = 1; data; data <<= 1) {
      localerror = 0;
      sram_writebyte(data, addr);
      if(!(sram_readbyte(addr) & data)) localerror = 1;
      sram_writebyte(~data, addr);
      if(sram_readbyte(addr) & data) localerror = 1;
      if(localerror) {
        if(!knowndata8[line]) {
          LOGPRINT("  U511 ERROR - CHECK D%d\n", line);
          knowndata8[line] = 1;
          dataerror[chip]++;
          error[chip]++;
        }
      }
      line++;
    }

    if(dataerror[chip]) {
      if(!knownlog[7]) {
        LOGPRINT("  U511 DATA LINE ERRORS DETECTED. Address line tests may be unreliable\n");
        knownlog[7] = 1;
      }
    }

    line = 0;
    for(offset = 1; offset <= 0x20000; offset <<= 1) {
      for(shortoffset = 1; shortoffset <= 0x20000; shortoffset <<= 1) {
        sram_writebyte(0, addr + shortoffset);
      }
      sram_writebyte(0x00, addr);
      sram_writebyte(0xff, addr + offset);
      if(!sram_readbyte(addr + offset) || sram_readbyte(addr)) {
        if(!knownaddr[chip][line]) {
          LOGPRINT("  U511 ERROR - CHECK A%d\n", line);
          knownaddr[chip][line] = 1;
          error[chip]++;
        }
      }

      // check possible shorted address lines
      shortcount = 0;
      shortline = 0;
      for(shortoffset = 1; shortoffset <= 0x20000; shortoffset <<= 1) {
        if(sram_readbyte(addr + shortoffset)) {
          if(line != shortline) shortcount++;
        }
        if(shortcount) {
          shortcount = 0;
          if(!knowncoll8[line][shortline]) {
            LOGPRINT("  U511 ERROR - CHECK SHORT A%d - A%d\n", line, shortline);
            knowncoll8[line][shortline] = 1;
            error[chip]++;
          }
        }
        shortline++;
      }
      line++;
    }
  }
  if(error[0] || error[1] || error[2]) {
    LOGPRINT("FAILED\n\n");
    return FAILED;
  }
  LOGPRINT("PASSED\n\n");
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
    LOGPRINT("Saving dump to /sd2snes/ram0dump.bin...");
    save_sram((uint8_t*)"/sd2snes/ram0dump.bin", 16777216, 0);
    LOGPRINT("\n\n\n");
  } else {
    LOGPRINT("RAM0 PASSED\n\n\n");
  }
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
    LOGPRINT("RAM1 FAILED\n");
    LOGPRINT("Saving dump to /sd2snes/ram1dump.bin...");
    save_sram((uint8_t*)"/sd2snes/ram1dump.bin", 524288, 0);
    LOGPRINT("\n\n\n");
  } else {
    LOGPRINT("RAM1 PASSED\n\n\n");
  }
  if(failed) return FAILED;
  return PASSED;
}

int test_clk() {
  uint32_t sysclk[4];
  int32_t diff = 0, max_diff = 0;
  int i, error = 0;
  int sysclkerror = 0;
  int cpuclkerror = 0;
  int cicclkerror = 0;
  int pardclkerror = 0;
  int pawrclkerror = 0;
  int readclkerror = 0;
  int writeclkerror = 0;
  int refreshclkerror = 0;
  int romselclkerror = 0;
  int othererror = 0;

  LOGPRINT("sysclk test\n===========\n");
  LOGPRINT("measuring SNES clock...\n");
  for(i = 0; i < 4; i++) {
    sysclk[i] = get_snes_sysclk();
    if(sysclk[i] < 21000000 || sysclk[i] > 22000000) sysclkerror = 1;
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
    sysclkerror = 1;
  }
  if(get_snes_cpuclk() < 100) cpuclkerror = 1;
  if(get_snes_pardclk() < 100) pardclkerror = 1;
  if(get_snes_pawrclk() < 100) pawrclkerror = 1;
  if(get_snes_readclk() < 100) readclkerror = 1;
  if(get_snes_writeclk() < 100) writeclkerror = 1;
  if(get_snes_refreshclk() < 100) refreshclkerror = 1;
  if(get_snes_romselclk() < 100) romselclkerror = 1;
  LOGPRINT("   CPUCLK: %lu\n", get_snes_cpuclk());
  LOGPRINT("  READCLK: %lu\n", get_snes_readclk());
  LOGPRINT(" WRITECLK: %lu\n", get_snes_writeclk());
  LOGPRINT("  PARDCLK: %lu\n", get_snes_pardclk());
  LOGPRINT("  PAWRCLK: %lu\n", get_snes_pawrclk());
  LOGPRINT("  REFRCLK: %lu\n", get_snes_refreshclk());
  LOGPRINT("ROMSELCLK: %lu\n", get_snes_romselclk());

#ifdef CONFIG_MK3
  if(get_snes_cicclk() < 100) cicclkerror = 1;
  LOGPRINT("   CICCLK: %lu\n", get_snes_cicclk());
#endif

  if(sysclkerror) {
    LOGPRINT("** SYSCLK ERROR. CHECK C151, R151, R152, R153, RA110, U103\n");
  }
  if(cicclkerror) {
    LOGPRINT("** CICCLK ERROR. CHECK R331, R334, R335, FPGA pin N2\n");
  }
  if(cpuclkerror) {
    LOGPRINT("** CPUCLK ERROR. CHECK RA102, R331, R332, R333, U331, U401 pin 74\n")
  }
  if(pardclkerror) {
    LOGPRINT("** /PARD ERROR. CHECK RAM TEST, SNES TEST, RA109, U103, FPGA pin B9\n");
  }
  if(pawrclkerror) {
    LOGPRINT("** /PAWR ERROR. CHECK RAM TEST, SNES TEST, RA109, U103, FPGA pin C9\n");
  }
  if(readclkerror) {
    LOGPRINT("** /READ ERROR. CHECK RAM TEST, SNES TEST, RA103, U102, FPGA pin C1\n");
  }
  if(writeclkerror) {
    LOGPRINT("** /WRITE ERROR. CHECK RAM TEST, SNES TEST, RA102, U101, FPGA pin K2\n");
  }
  if(refreshclkerror) {
    LOGPRINT("** REFRESH ERROR. CHECK RA110, U103, FPGA pin F9\n");
  }
  if(romselclkerror) {
    LOGPRINT("** ROMSEL ERROR. CHECK RAM TEST, SNES TEST, RA103, U102, FPGA pin C2\n");
  }
  othererror = pardclkerror | pawrclkerror | readclkerror | writeclkerror | romselclkerror;
  if(othererror) {
    LOGPRINT("** CONTROL SIGNAL ERRORS DETECTED. See above errors\n   and check all RA, FBA, U101-103 connections.\n");
  }
  error |= othererror | sysclkerror | cicclkerror | cpuclkerror | refreshclkerror;
  if(error) {
    LOGPRINT("FAILED\n\n\n");
    return FAILED;
  }
  LOGPRINT("PASSED\n\n\n");
  return PASSED;
}

int test_sddma() {
  uint32_t len;
  fpga_select_mem(0);
  LOGPRINT("SD DMA test\n===========\nclearing RAM - ");
  sram_memset(0, 1048576, 0);
  LOGPRINT("loading test file - ");
  if((len = load_sram_offload((uint8_t*)"/sd2snes/dmatest.bin", 0)) != 1048576) {
    LOGPRINT("DMA test file size mismatch! (expected 1048576, got %lu)\nFAILED\n\n\n", len);
    return FAILED;
  }

  LOGPRINT("verifying -");

  uint32_t addr;
  uint8_t data, expect;
  int error = 0;
  set_mcu_addr(0);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x88);
  uint8_t patt[4] = {0xff, 0x55, 0xaa, 0x00};
  for(addr=0; addr < 1048576; addr++) {
    if((addr&0xffff) == 0)printf("\x8%c", PROGRESS[(addr>>16)&3]);
    FPGA_WAIT_RDY();
    data = FPGA_RX_BYTE();
    expect = patt[(addr >> 18) & 3] ^ ((addr & 1) * 255);
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
  if(error) {
    LOGPRINT("** SD DMA ERROR. CHECK RAM TEST, SD SLOT, FPGA, U401\n");
    LOGPRINT("FAILED\n");
    LOGPRINT("Saving dump to /sd2snes/dma_dump.bin...");
    save_sram((uint8_t*)"/sd2snes/dma_dump.bin", 1048576, 0);
    LOGPRINT("\n\n\n");
    return FAILED;
  }
  LOGPRINT("PASSED\n\n\n");
  return PASSED;
}

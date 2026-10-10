/* tapplay - TAP file playback for sd2iec hardware
   Copyright (C) 2009  Ingo Korb <ingo@akana.de>

   Inspiration and low-level SD/MMC access based on code from MMC2IEC
     by Lars Pontoppidan et al., see sdcard.c|h and config.h.

   FAT filesystem access based on code from ChaN and Jim Brain, see ff.c|h.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License only.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


   cli.c: The command line interface

*/

#include <arm/bits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include "config.h"
#include "diskio.h"
#include "ff.h"
#include "timer.h"
#include "uart.h"
#include "fileops.h"
#include "memory.h"
#include "snes.h"
#include "fpga.h"
#include "fpga_spi.h"
#include "cic.h"
#include "ymodem.h"
#include "rtc.h"

#include "cli.h"
#if defined(CONFIG_SD_HWSDIO) || defined(CONFIG_SD_HWSDIO_SELFTEST)
#include "sdnative.h"
#endif
#ifdef CONFIG_SD_HWSDIO_SELFTEST
#include "crc32.h"
#endif

#define MAX_LINE 250

/* Variables */
static char cmdbuffer[MAX_LINE+1];
static char *curchar;

/* Word lists */
static char command_words[] =
  "cd\0reset\0sreset\0dir\0ls\0test\0exit\0loadrom\0loadraw\0saveraw\0put\0rm\0mkdir\0d4\0vmode\0mapper\0settime\0time\0setfeature\0hexdump\0w8\0w16\0memset\0cheat\0fpgaconf\0chipfeat\0bsregs\0gameloop\0dacboost\0cat\0mv\0sdstat\0sdtest\0sdwtest\0sdotest\0";
enum { CMD_CD = 0, CMD_RESET, CMD_SRESET, CMD_DIR, CMD_LS, CMD_TEST, CMD_EXIT, CMD_LOADROM, CMD_LOADRAW, CMD_SAVERAW, CMD_PUT, CMD_RM, CMD_MKDIR, CMD_D4, CMD_VMODE, CMD_MAPPER, CMD_SETTIME, CMD_TIME, CMD_SETFEATURE, CMD_HEXDUMP, CMD_W8, CMD_W16, CMD_MEMSET, CMD_CHEAT, CMD_FPGACONF, CMD_CHIPFEAT, CMD_BSREGS, CMD_GAMELOOP, CMD_DACBOOST, CMD_CAT, CMD_MV, CMD_SDSTAT, CMD_SDTEST, CMD_SDWTEST, CMD_SDOTEST };

/* ------------------------------------------------------------------------- */
/*   Parse functions                                                         */
/* ------------------------------------------------------------------------- */

/* Skip spaces at curchar */
static uint8_t skip_spaces(void) {
  uint8_t res = (*curchar == ' ' || *curchar == 0);

  while (*curchar == ' ')
    curchar++;

  return res;
}

/* return pointer to the next argument. Argument stops at a whitespace or end of
   string; whitespace may be escaped with a backslash '\'. curchar is unescaped
   in place. */
static char *parse_string(void) {
  int ignore_space = 0;
  char *begin = curchar;

  /* walk string, remove backslashes that may escape spaces */
  while(*curchar && (*curchar != ' ' || (ignore_space && (*curchar ==  ' ')))) {
    ignore_space = 0;
    if(*curchar == '\\') {
      ignore_space = 1;
      memmove(curchar, curchar + 1, strlen(curchar+1)+1);
    } else {
      curchar++;
    }
  }

  /* separate next token if present */
  if(*curchar) {
    *curchar = 0;
    curchar++;
    skip_spaces();
  }

  /* return start of this token */
  return begin;
}

/* Parse the string in curchar for an integer with bounds [lower,upper] */
static int32_t parse_unsigned(uint32_t lower, uint32_t upper, uint8_t base) {
  char *end;
  uint32_t result;

  if (strlen(curchar) == 1 && *curchar == '?') {
    printf("Number between %ld[0x%lx] and %ld[0x%lx] expected\n",lower,lower,upper,upper);
    return -2;
  }

  errno = 0;
  result = strtoul(curchar, &end, base);
  if ((*end != ' ' && *end != 0) || errno != 0) {
    printf("Invalid numeric argument\n");
    return -1;
  }

  curchar = end;
  skip_spaces();

  if (result < lower || result > upper) {
    printf("Numeric argument out of range (%ld..%ld)\n",lower,upper);
    return -1;
  }

  return result;
}
/* Parse the string starting with curchar for a word in wordlist */
static int8_t parse_wordlist(char *wordlist) {
  uint8_t i, matched;
  char *cur, *ptr;
  char c;

  i = 0;
  ptr = wordlist;

  // Command list on "?"
  if (strlen(curchar) == 1 && *curchar == '?') {
    printf("Commands available: \n ");
    while (1) {
      c = *ptr++;
      if (c == 0) {
        if (*ptr == 0) {
          printf("\n");
          return -2;
        } else {
          printf("\n ");
        }
      } else
        uart_putc(c);
    }
  }

  while (1) {
    cur = curchar;
    matched = 1;
    c = *ptr;
    do {
      // If current word list character is \0: No match found
      if (c == 0) {
        printf("Unknown word: %s\n(use ? for help)",curchar);
        return -1;
      }

      if (tolower((int)c) != tolower((int)*cur)) {
        // Check for end-of-word
        if (cur != curchar && (*cur == ' ' || *cur == 0)) {
          // Partial match found, return that
          break;
        } else {
          matched = 0;
          break;
        }
      }
      ptr++;
      cur++;
      c = *ptr;
    } while (c != 0);

    if (matched) {
      char *tmp = curchar;

      curchar = cur;
      // Return match only if whitespace or end-of-string follows
      // (avoids mismatching partial words)
      if (skip_spaces()) {
        return i;
      } else {
        printf("Unknown word: %s\n(use ? for help)\n",tmp);
        return -1;
      }
    } else {
      // Try next word in list
      i++;
      while (*ptr++ != 0) ;
    }
  }
}

/* Read a line from serial, uses cmdbuffer as storage */
static char *getline(char *prompt) {
  int i=0;
  char c;

  printf("\n%s",prompt);
  memset(cmdbuffer,0,sizeof(cmdbuffer));

  while (1) {
    c = uart_getc();
    if (c == 13)
      break;

    if (c == 27 || c == 3) {
      printf("\\\n%s",prompt);
      i = 0;
      memset(cmdbuffer,0,sizeof(cmdbuffer));
      continue;
    }

    if (c == 127 || c == 8) {
      if (i > 0) {
        i--;
        uart_putc(8);   // backspace
        uart_putc(' '); // erase character
        uart_putc(8);   // backspace
      } else
        continue;
    } else {
      if (i < sizeof(cmdbuffer)-1) {
        cmdbuffer[i++] = c;
        uart_putc(c);
      }
    }
  }
  cmdbuffer[i] = 0;
  return cmdbuffer;
}


/* ------------------------------------------------------------------------- */
/*   Command functions                                                       */
/* ------------------------------------------------------------------------- */

/* Reset */
static void cmd_reset(void) {
  NVIC_SystemReset();
}

/* Show the contents of the current directory */
static void cmd_show_directory(void) {
  FRESULT res;
  DIR dh;
  FILINFO finfo;
  uint8_t *name;
  uint8_t buf[256];
  f_getcwd((TCHAR*)buf, 255);

  res = f_opendir(&dh, (TCHAR*)buf);
  if (res != FR_OK) {
    print_fresult(res, "f_opendir failed");
    return;
  }

  finfo.lfname = (TCHAR*)buf;
  finfo.lfsize = 255;

  do {
    /* Read the next entry */
    res = f_readdir(&dh, &finfo);
    if (res != FR_OK) {
      print_fresult(res, "f_readdir failed");
      return;
    }

    /* Abort if none was found */
    if (!finfo.fname[0])
      break;

    /* Skip volume labels */
    if (finfo.fattrib & AM_VOL)
      continue;

    /* Select between LFN and 8.3 name */
    if (finfo.lfname[0])
      name = (uint8_t*)finfo.lfname;
    else {
      name = (uint8_t*)finfo.fname;
      strlwr((char *)name);
    }

    printf("%s [%s] (%ld)",finfo.lfname, finfo.fname, finfo.fsize);

    /* Directory indicator (Unix-style) */
    if (finfo.fattrib & AM_DIR)
      uart_putc('/');

    printf("\n");
  } while (finfo.fname[0]);
}

static void cmd_loadrom(void) {
  uint32_t address = 0;
  uint8_t flags = LOADROM_WITH_SRAM | LOADROM_WITH_RESET;
  strncpy((char*)file_lfn, (const char*)curchar, 255);
  load_rom((uint8_t*)curchar, address, flags);
}

static void cmd_loadraw(void) {
  uint32_t address = parse_unsigned(0,16777216,16);
  load_sram((uint8_t*)curchar, address);
}

static void cmd_saveraw(void) {
  uint32_t address = parse_unsigned(0,16777216,16);
  uint32_t length = parse_unsigned(0,16777216,16);
  if(address != -1 && length != -1)
    save_sram((uint8_t*)curchar, length, address);
}

static void cmd_d4(void) {
  int32_t hz;

  if(get_cic_state() != CIC_PAIR) {
    printf("not in pair mode\n");
  } else {
    hz = parse_unsigned(50,60,10);
    if(hz==50) {
      cic_d4(CIC_PAL);
    } else {
      cic_d4(CIC_NTSC);
    }
    printf("ok\n");
  }
}

static void cmd_vmode(void) {
  int32_t hz;
  if(get_cic_state() != CIC_PAIR) {
    printf("not in pair mode\n");
  } else {
    hz = parse_unsigned(50,60,10);
    if(hz==50) {
      cic_videomode(CIC_PAL);
    } else {
      cic_videomode(CIC_NTSC);
    }
    printf("ok\n");
  }
}

void cmd_put(void) {
  if(*curchar != 0) {
    file_open((uint8_t*)curchar, FA_CREATE_ALWAYS | FA_WRITE);
    if(file_res) {
      printf("FAIL: error opening file %s\n", curchar);
    } else {
      printf("OK, start YMODEM transfer now.\n");
      ymodem_rxfile(&file_handle);
    }
    file_close();
  } else {
    printf("Usage: put <filename>\n");
  }
}

void cmd_rm(void) {
  FRESULT res = f_unlink(curchar);
  if(res) print_fresult(res, "Error %d removing %s", res, curchar);
}

void cmd_mkdir(void) {
  FRESULT res = f_mkdir(curchar);
  if(res) print_fresult(res, "Error %d creating directory %s\n", res, curchar);
}

void cmd_mapper(void) {
  int32_t mapper;
  mapper = parse_unsigned(0,7,10);
  set_mapper((uint8_t)mapper & 0x7);
  printf("mapper set to %ld\n", mapper);
}

void cmd_sreset(void) {
  if(*curchar != 0) {
    int32_t resetstate;
    resetstate = parse_unsigned(0,1,10);
    snes_reset(resetstate);
  } else {
    snes_reset_pulse();
  }
}
void cmd_settime(void) {
  struct tm time;
  if(strlen(curchar) != 4+2+2 + 2+2+2) {
    printf("invalid time format (need YYYYMMDDhhmmss)\n");
  } else {
    time.tm_sec = atoi(curchar+4+2+2+2+2);
    curchar[4+2+2+2+2] = 0;
    time.tm_min = atoi(curchar+4+2+2+2);
    curchar[4+2+2+2] = 0;
    time.tm_hour = atoi(curchar+4+2+2);
    curchar[4+2+2] = 0;
    time.tm_mday = atoi(curchar+4+2);
    curchar[4+2] = 0;
    time.tm_mon = atoi(curchar+4);
    curchar[4] = 0;
    time.tm_year = atoi(curchar);
    set_rtc(&time);
  }
}

void cmd_time(void) {
  struct tm time;
  read_rtc(&time);
  printf("%04d-%02d-%02d %02d:%02d:%02d\n", time.tm_year, time.tm_mon,
    time.tm_mday, time.tm_hour, time.tm_min, time.tm_sec);
}

void cmd_setfeature(void) {
  uint16_t feat = parse_unsigned(0, 65535, 16);
  fpga_set_features(feat);
}

void cmd_hexdump(void) {
  uint32_t offset = parse_unsigned(0, 16777215, 16);
  uint32_t len = parse_unsigned(0, 16777216, 16);
  sram_hexdump(offset, len);
}

void cmd_w8(void) {
  uint32_t offset = parse_unsigned(0, 16777215, 16);
  uint8_t val = parse_unsigned(0, 255, 16);
  sram_writebyte(val, offset);
}

void cmd_w16(void) {
  uint32_t offset = parse_unsigned(0, 16777215, 16);
  uint16_t val = parse_unsigned(0, 65535, 16);
  sram_writeshort(val, offset);
}

void cmd_memset(void) {
  uint32_t offset = parse_unsigned(0, 16777215, 16);
  uint32_t len = parse_unsigned(0, 16777216, 16);
  uint8_t val = parse_unsigned(0, 255, 16);
  sram_memset(offset, len, val);
}

void cmd_cheat(void) {
  uint8_t index = parse_unsigned(0, 7, 10);
  uint32_t code = parse_unsigned(0, 0xffffffff, 16);
  fpga_write_cheat(index, code);
}

void cmd_test(void) {
  int i;
  uint8_t databuf[1024];
  fpga_set_snescmd_addr(SNESCMD_MCU_CMD);
  for(i=0; i<1024; i++) {
    databuf[i]=fpga_read_snescmd();
  }
  uart_trace(databuf, 0, 1024);
}

void cmd_fpgaconf(void) {
  if(!strncmp(curchar, "ROM", 3)) {
    fpga_rompgm();
    set_rom_mask(0x3fffff);
  } else {
    fpga_pgm((uint8_t*)curchar);
  }
}

void cmd_chipfeat(void) {
  int32_t feat = parse_unsigned(0, 0xffff, 16);
  if(feat != -1) fpga_set_chipfeat((uint16_t) feat);
}

void cmd_bsregs(void) {
  uint8_t set = parse_unsigned(0, 0xff, 16);
  uint8_t reset = parse_unsigned(0, 0xff, 16);
  set_bsx_regs(set, reset);
}

static void cmd_gameloop(void) {
  snes_set_mcu_cmd(SNES_CMD_GAMELOOP);
}

static void cmd_dacboost(void) {
  int8_t boost = parse_unsigned(0, 255, 16);
  if(boost != -1) fpga_set_dac_boost(boost);
}

static void cmd_cat(void) {
  FRESULT res;
  FIL catfile;
  TCHAR buf[256];
  if(strlen(curchar) == 0) {
    printf("Usage: cat <filename>\n");
  } else {
    res = f_open(&catfile, (const TCHAR*)curchar, FA_READ);
    if(res == FR_OK) {
      while(f_gets(buf, sizeof(buf), &catfile)) {
        uart_puts(buf);
      }
    } else {
      print_fresult(res, "f_open %s failed", curchar);
    }
  }
}

static void cmd_mv(void) {
//  FRESULT res;
//  FIL mvfile;
  char *arg1 = parse_string();
  char *arg2 = parse_string();
  if(!*arg2 || !*arg1) {
    printf("Usage: mv <source> <destination>\n");
    return;
  }
  printf("%s --> %s\n", arg1, arg2);
  file_res = f_rename(arg1, arg2);
  if(file_res) {
    print_fresult(file_res, "f_rename(\"%s\", \"%s\") failed", arg1, arg2);
  }
}

#ifdef CONFIG_SD_HWSDIO_SELFTEST
/* SD self tests comparing the SDIO host with the bit-banged path,
   left in for now */

/* 2048 byte scratch buffers (+4 bytes slack for unaligned access), word aligned */
static uint32_t sdtest_buf[2][513];
static FIL sdtest_file;

#define SDTEST_US(cycles) ((cycles) / (CONFIG_CPU_FREQUENCY / 1000000))

static void sdtest_printstats(void) {
#ifdef CONFIG_SD_HWSDIO
  sdn_hw_printstats();
#else
  printf("(hardware SDIO disabled: all transfers are bit-banged)\n");
#endif
}

static void sdtest_cyccnt_init(void) {
  CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
  DWT->CTRL |= DWT_CTRL_CYCCNTENA_Msk;
}

static uint32_t sdtest_kbps(uint32_t kbytes, uint32_t us) {
  return us ? (uint32_t)(((uint64_t)kbytes * 1000000) / us) : 0;
}

/* read count sectors starting at sector through one path, 4 sectors per call.
   modes:
    0: SDIO host, aligned buffer
    1: SDIO host, unaligned buffer (DMA bounce buffer path)
    2: bit-banged

   returns the number of failed calls
*/
static int sdtest_pass(uint32_t sector, uint32_t count, int mode, uint32_t *crc, uint32_t *us) {
  uint8_t *buf = (uint8_t*)sdtest_buf[0] + (mode == 1 ? 1 : 0);
  int errors = 0;
  uint32_t t0;
  *crc = crc32_init();
  *us = 0;
  sd_offload = 0;
  sd_force_bb = (mode == 2);
  for(uint32_t i = 0; i < count; i += 4) {
    uint32_t n = (count - i) < 4 ? (count - i) : 4;
    t0 = DWT->CYCCNT;
    if(disk_read(0, buf, sector + i, n) != RES_OK) {
      errors++;
    }
    *us += SDTEST_US(DWT->CYCCNT - t0);
    for(uint32_t j = 0; j < n * 512; j++) {
      *crc = crc32_update(*crc, buf[j]);
    }
  }
  sd_force_bb = 0;
  *crc = crc32_finalize(*crc);
  return errors;
}

/* sdtest <sector(hex)> <count>: read a sector range through the SDIO host
   and through bit-banging, compare and time both */
static void cmd_sdtest(void) {
  static const char *names[3] = { "host, aligned  ", "host, unaligned", "bit-banged     " };
  int32_t sector = parse_unsigned(0, 0x7fffffff, 16);
  int32_t count;
  uint32_t crc[3], us[3];
  int err[3];
  if(sector < 0) {
    printf("Usage: sdtest <first sector (hex)> <sector count>\n");
    return;
  }
  count = parse_unsigned(1, 65536, 10);
  if(count < 0) {
    printf("Usage: sdtest <first sector (hex)> <sector count>\n");
    return;
  }
  sdtest_cyccnt_init();
  /* sequential reads */
  for(int mode = 0; mode < 3; mode++) {
    err[mode] = sdtest_pass(sector, count, mode, &crc[mode], &us[mode]);
    printf("%s: crc=%08lx failed calls=%d  %lu us = %lu KB/s\n", names[mode], crc[mode],
           err[mode], us[mode], sdtest_kbps(count / 2, us[mode]));
  }
  if(crc[0] != crc[2] || crc[1] != crc[2]) {
    /* locate the differences sector by sector */
    uint8_t *hw = (uint8_t*)sdtest_buf[0], *bb = (uint8_t*)sdtest_buf[1];
    int shown = 0;
    printf("MISMATCH, comparing sector by sector...\n");
    for(int32_t i = 0; i < count && shown < 8; i++) {
      disk_read(0, hw, sector + i, 1);
      sd_force_bb = 1;
      disk_read(0, bb, sector + i, 1);
      sd_force_bb = 0;
      if(memcmp(hw, bb, 512)) {
        printf("  sector %08lx differs\n", sector + i);
        shown++;
      }
    }
  } else {
    printf("OK: all paths read identical data\n");
  }
  /* scattered single sector reads (command overhead and access time) */
  uint32_t reads = count < 64 ? count : 64;
  uint32_t stride = count / reads;
  for(int mode = 0; mode < 3; mode += 2) {
    uint32_t total = 0, t0;
    sd_force_bb = (mode == 2);
    for(uint32_t i = 0; i < reads; i++) {
      t0 = DWT->CYCCNT;
      disk_read(0, (uint8_t*)sdtest_buf[0], sector + ((i * 7) % reads) * stride, 1);
      total += SDTEST_US(DWT->CYCCNT - t0);
    }
    sd_force_bb = 0;
    printf("%s: %lu scattered single sector reads, avg %lu us\n", names[mode], reads, total / reads);
  }
  sdtest_printstats();
}

static void sdtest_pattern(uint8_t *buf, uint32_t len, uint32_t seed) {
  uint32_t x = seed * 2654435761u + 0x9e3779b9u;
  while(len--) {
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *buf++ = x;
  }
}

/* sdwtest <KB>: write a pattern file, read it back via SDIO and bitbanging,
                 compare, delete */
static void cmd_sdwtest(void) {
  static const TCHAR path[] = "/sd2snes/sdtest.bin";
  int32_t kbytes = parse_unsigned(2, 16384, 10);
  uint8_t *wbuf = (uint8_t*)sdtest_buf[0], *rbuf = (uint8_t*)sdtest_buf[1];
  uint32_t chunks, us = 0, t0, mismatches[2] = { 0, 0 };
  FRESULT res;
  UINT bytes;
  if(kbytes < 0) {
    printf("Usage: sdwtest <size in KB>\n");
    return;
  }
  chunks = kbytes / 2;
  sdtest_cyccnt_init();
  res = f_open(&sdtest_file, path, FA_CREATE_ALWAYS | FA_WRITE);
  if(res != FR_OK) {
    print_fresult(res, "f_open %s failed", path);
    return;
  }
  for(uint32_t c = 0; c < chunks; c++) {
    sdtest_pattern(wbuf, 2048, c);
    t0 = DWT->CYCCNT;
    res = f_write(&sdtest_file, wbuf, 2048, &bytes);
    us += SDTEST_US(DWT->CYCCNT - t0);
    if(res != FR_OK || bytes != 2048) {
      print_fresult(res, "f_write failed");
      break;
    }
  }
  t0 = DWT->CYCCNT;
  f_close(&sdtest_file);
  us += SDTEST_US(DWT->CYCCNT - t0);
  printf("wrote %lu KB: %lu us = %lu KB/s\n", chunks * 2, us, sdtest_kbps(chunks * 2, us));
  for(int pass = 0; pass < 2; pass++) {
    res = f_open(&sdtest_file, path, FA_READ);
    if(res != FR_OK) {
      print_fresult(res, "f_open %s failed", path);
      return;
    }
    sd_force_bb = pass;
    for(uint32_t c = 0; c < chunks; c++) {
      sdtest_pattern(wbuf, 2048, c);
      for(int part = 0; part < 4; part++) {
        res = f_read(&sdtest_file, rbuf, 512, &bytes);
        if(res != FR_OK || bytes != 512 || memcmp(rbuf, wbuf + part * 512, 512)) {
          if(mismatches[pass]++ < 8) {
            printf("  %s: mismatch at offset %08lx\n", pass ? "bit-banged" : "host", (c * 4 + part) * 512);
          }
        }
      }
    }
    sd_force_bb = 0;
    f_close(&sdtest_file);
  }
  printf("readback: host %lu bad sectors, bit-banged %lu bad sectors\n", mismatches[0], mismatches[1]);
  f_unlink(path);
  sdtest_printstats();
}

/* sdotest <file> [offset] [chunk]: load up to 1MB of a file into cart memory
   at $000000 through FPGA SD DMA (offload) from an odd offset in odd sized
   chunks to force so partial sectors and mid-block continuations occur.
   Every third chunk is followed by an unrelated read through the SDIO host
   The result is read back from cart RAM and compared with data from card
   directly */
#define SDOTEST_ADDR   (0x000000)
#define SDOTEST_MAXLEN (0x100000)
static void cmd_sdotest(void) {
  char *path = parse_string();
  uint32_t offset = 1001, chunk = 1000, len, done, crc_cart, crc_file, us = 0, t0;
  uint8_t *buf = (uint8_t*)sdtest_buf[0];
  int32_t val;
  FRESULT res;
  UINT bytes;
  if(!*path) {
    printf("Usage: sdotest <file> [offset (default 1001)] [chunk size (default 1000)]\n");
    return;
  }
  if(*curchar) {
    if((val = parse_unsigned(0, 0x7fffffff, 10)) < 0) return;
    offset = val;
  }
  if(*curchar) {
    if((val = parse_unsigned(1, 2048, 10)) < 0) return;
    chunk = val;
  }
  res = f_open(&sdtest_file, (const TCHAR*)path, FA_READ);
  if(res != FR_OK) {
    print_fresult(res, "f_open %s failed", path);
    return;
  }
  if(offset >= f_size(&sdtest_file)) {
    printf("offset beyond end of file (size %lu)\n", f_size(&sdtest_file));
    f_close(&sdtest_file);
    return;
  }
  len = f_size(&sdtest_file) - offset;
  if(len > SDOTEST_MAXLEN) len = SDOTEST_MAXLEN;
  sdtest_cyccnt_init();
  /* offloaded load, interleaved with host reads */
  set_mcu_addr(SDOTEST_ADDR);
  ff_sd_offload = 1;
  sd_offload_tgt = 0;
  f_lseek(&sdtest_file, offset);
  for(done = 0; done < len; done += bytes) {
    uint32_t n = (len - done) < chunk ? (len - done) : chunk;
    ff_sd_offload = 1;
    sd_offload_tgt = 0;
    t0 = DWT->CYCCNT;
    res = f_read(&sdtest_file, buf, n, &bytes);
    us += SDTEST_US(DWT->CYCCNT - t0);
    if(res != FR_OK || bytes != n) {
      print_fresult(res, "offloaded f_read failed at %lu", done);
      break;
    }
    if(!((done / chunk) % 3)) {
      disk_read(0, (uint8_t*)sdtest_buf[1], 0, 1);
    }
  }
  ff_sd_offload = 0;
  printf("offloaded %lu bytes from offset %lu in %lu byte chunks: %lu us\n", done, offset, chunk, us);
  /* read back over SPI */
  crc_cart = crc32_init();
  for(uint32_t i = 0; i < len; i += 2048) {
    uint32_t n = (len - i) < 2048 ? (len - i) : 2048;
    sram_readblock(buf, SDOTEST_ADDR + i, n);
    for(uint32_t j = 0; j < n; j++) {
      crc_cart = crc32_update(crc_cart, buf[j]);
    }
  }
  crc_cart = crc32_finalize(crc_cart);
  /* reference through the SDIO host */
  crc_file = crc32_init();
  f_lseek(&sdtest_file, offset);
  for(uint32_t i = 0; i < len; i += bytes) {
    uint32_t n = (len - i) < 512 ? (len - i) : 512;
    res = f_read(&sdtest_file, buf, n, &bytes);
    if(res != FR_OK || bytes != n) {
      print_fresult(res, "f_read failed at %lu", i);
      break;
    }
    for(uint32_t j = 0; j < n; j++) {
      crc_file = crc32_update(crc_file, buf[j]);
    }
  }
  crc_file = crc32_finalize(crc_file);
  f_close(&sdtest_file);
  printf("cart memory crc=%08lx, file crc=%08lx: %s\n", crc_cart, crc_file,
         crc_cart == crc_file ? "OK" : "MISMATCH");
  sdtest_printstats();
}

#endif

#ifdef CONFIG_SD_HWSDIO
static void cmd_sdstat(void) {
  if(!strcmp(curchar, "reset")) {
    memset(&sd_hw_stats, 0, sizeof(sd_hw_stats));
  }
  sdn_hw_printstats();
}
#endif

static void cmd_cd(void) {
#if _FS_RPATH
  FRESULT res;
  uint8_t buf[256];
  if (strlen(curchar) == 0) {
    f_getcwd((TCHAR*)buf, 255);
    printf("%s\n", buf);
  } else {
    res = f_chdir((const TCHAR *)curchar);
    if (res != FR_OK) {
      print_fresult(res, "f_chdir %s failed", curchar);
    } else {
      printf("Ok.\n");
    }
  }
#else
  printf("cd not supported.\n");
#endif
}

/* ------------------------------------------------------------------------- */
/*   CLI interface functions                                                 */
/* ------------------------------------------------------------------------- */

void cli_init(void) {
}

void cli_entrycheck() {
  if(uart_gotc() && uart_getc() == 27) {
    printf("*** BREAK\n");
    cli_loop();
  }
}

void cli_loop(void) {
  while (1) {
    curchar = getline(">");
    printf("\n");

    /* Remove whitespace */
    while (*curchar == ' ') curchar++;
    while (strlen(curchar) > 0 && curchar[strlen(curchar)-1] == ' ')
      curchar[strlen(curchar)-1] = 0;

    /* Ignore empty lines */
    if (strlen(curchar) == 0)
      continue;

    /* Parse command */
    int8_t command = parse_wordlist(command_words);
    if (command < 0)
      continue;

    switch (command) {
      case CMD_CD:
        cmd_cd();
        break;

      case CMD_RESET:
        cmd_reset();
        break;

      case CMD_SRESET:
        cmd_sreset();
        break;

      case CMD_DIR:
      case CMD_LS:
        cmd_show_directory();
        break;

      case CMD_EXIT:
        return;
        break;

      case CMD_LOADROM:
        cmd_loadrom();
        break;

      case CMD_LOADRAW:
        cmd_loadraw();
        break;

      case CMD_SAVERAW:
        cmd_saveraw();
        break;

      case CMD_RM:
        cmd_rm();
        break;

      case CMD_MKDIR:
        cmd_mkdir();
        break;

      case CMD_D4:
        cmd_d4();
        break;

      case CMD_VMODE:
        cmd_vmode();
        break;

      case CMD_PUT:
        cmd_put();
        break;

      case CMD_MAPPER:
        cmd_mapper();
        break;

      case CMD_SETTIME:
        cmd_settime();
        break;

      case CMD_TIME:
        cmd_time();
        break;

      case CMD_TEST:
        cmd_test();
        break;

      case CMD_SETFEATURE:
        cmd_setfeature();
        break;

      case CMD_HEXDUMP:
        cmd_hexdump();
        break;

      case CMD_W8:
        cmd_w8();
        break;

      case CMD_W16:
        cmd_w16();
        break;

      case CMD_MEMSET:
        cmd_memset();
        break;

      case CMD_CHEAT:
        cmd_cheat();
        break;

      case CMD_FPGACONF:
        cmd_fpgaconf();
        break;

      case CMD_CHIPFEAT:
        cmd_chipfeat();
        break;

      case CMD_BSREGS:
        cmd_bsregs();
        break;

      case CMD_GAMELOOP:
        cmd_gameloop();
        break;

      case CMD_DACBOOST:
        cmd_dacboost();
        break;

      case CMD_CAT:
        cmd_cat();
        break;

      case CMD_MV:
        cmd_mv();
        break;

#ifdef CONFIG_SD_HWSDIO
      case CMD_SDSTAT:
        cmd_sdstat();
        break;
#endif

#ifdef CONFIG_SD_HWSDIO_SELFTEST
      case CMD_SDTEST:
        cmd_sdtest();
        break;

      case CMD_SDWTEST:
        cmd_sdwtest();
        break;

      case CMD_SDOTEST:
        cmd_sdotest();
        break;
#endif

      default:
        break;
    }
  }
}

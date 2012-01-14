/* sd2snes - SD card based universal cartridge for the SNES
   Copyright (C) 2009-2010 Maximilian Rehkopf <otakon@gmx.net>
   AVR firmware portion

   Inspired by and based on code from sd2iec, written by Ingo Korb et al.
   See sdcard.c|h, config.h.

   FAT file system access based on code by ChaN, Jim Brain, Ingo Korb,
   see ff.c|h.

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

   memory.c: RAM operations
*/


#include "config.h"
#include "uart.h"
#include "fpga.h"
#include "crc.h"
#include "crc32.h"
#include "ff.h"
#include "fileops.h"
#include "spi.h"
#include "fpga_spi.h"
#include "led.h"
#include "smc.h"
#include "memory.h"
#include "snes.h"
#include "timer.h"
#include "rle.h"
#include "diskio.h"
#include "snesboot.h"
#include "msu1.h"

#include <string.h>
char* hex = "0123456789ABCDEF";

extern snes_romprops_t romprops;

void sram_hexdump(uint32_t addr, uint32_t len) {
  static uint8_t buf[16];
  uint32_t ptr;
  for(ptr=0; ptr < len; ptr += 16) {
    sram_readblock((void*)buf, ptr+addr, 16);
    uart_trace(buf, 0, 16);
  }
}

void sram_writebyte(uint8_t val, uint32_t addr) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x98); /* WRITE */
  FPGA_TX_BYTE(val);
  FPGA_WAIT_RDY();
  FPGA_DESELECT();
}

uint8_t sram_readbyte(uint32_t addr) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x88); /* READ */
  FPGA_WAIT_RDY();
  uint8_t val = FPGA_RX_BYTE();
  FPGA_DESELECT();
  return val;
}

void sram_writeshort(uint16_t val, uint32_t addr) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x98); /* WRITE */
  FPGA_TX_BYTE(val&0xff);
  FPGA_WAIT_RDY();
  FPGA_TX_BYTE((val>>8)&0xff);
  FPGA_WAIT_RDY();
  FPGA_DESELECT();
}

void sram_writelong(uint32_t val, uint32_t addr) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x98); /* WRITE */
  FPGA_TX_BYTE(val&0xff);
  FPGA_WAIT_RDY();
  FPGA_TX_BYTE((val>>8)&0xff);
  FPGA_WAIT_RDY();
  FPGA_TX_BYTE((val>>16)&0xff);
  FPGA_WAIT_RDY();
  FPGA_TX_BYTE((val>>24)&0xff);
  FPGA_WAIT_RDY();
  FPGA_DESELECT();
}

uint16_t sram_readshort(uint32_t addr) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x88);
  FPGA_WAIT_RDY();
  uint32_t val = FPGA_RX_BYTE();
  FPGA_WAIT_RDY();
  val |= ((uint32_t)FPGA_RX_BYTE()<<8);
  FPGA_DESELECT();
  return val;
}

uint32_t sram_readlong(uint32_t addr) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x88);
  FPGA_WAIT_RDY();
  uint32_t val = FPGA_RX_BYTE();
  FPGA_WAIT_RDY();
  val |= ((uint32_t)FPGA_RX_BYTE()<<8);
  FPGA_WAIT_RDY();
  val |= ((uint32_t)FPGA_RX_BYTE()<<16);
  FPGA_WAIT_RDY();
  val |= ((uint32_t)FPGA_RX_BYTE()<<24);
  FPGA_DESELECT();
  return val;
}

void sram_readlongblock(uint32_t* buf, uint32_t addr, uint16_t count) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x88);
  uint16_t i=0;
  while(i<count) {
    FPGA_WAIT_RDY();
    uint32_t val = (uint32_t)FPGA_RX_BYTE()<<24;
    FPGA_WAIT_RDY();
    val |= ((uint32_t)FPGA_RX_BYTE()<<16);
    FPGA_WAIT_RDY();
    val |= ((uint32_t)FPGA_RX_BYTE()<<8);
    FPGA_WAIT_RDY();
    val |= FPGA_RX_BYTE();
    buf[i++] = val;
  }
  FPGA_DESELECT();
}

void sram_readblock(void* buf, uint32_t addr, uint16_t size) {
  uint16_t count=size;
  uint8_t* tgt = buf;
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x88);	/* READ */
  while(count--) {
    FPGA_WAIT_RDY();
    *(tgt++) = FPGA_RX_BYTE();
  }
  FPGA_DESELECT();
}

void sram_writeblock(void* buf, uint32_t addr, uint16_t size) {
  uint16_t count=size;
  uint8_t* src = buf;
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x98);	/* WRITE */
  while(count--) {
    FPGA_TX_BYTE(*src++);
    FPGA_WAIT_RDY();
  }
  FPGA_DESELECT();
}

uint32_t load_rom(uint8_t* filename, uint32_t base_addr, uint8_t flags) {
  UINT bytes_read;
  DWORD filesize;
  UINT count=0;
  tick_t ticksstart, ticks_total=0;
  ticksstart=getticks();
  printf("%s\n", filename);
  file_open(filename, FA_READ);
  if(file_res) {
    uart_putc('?');
    uart_putc(0x30+file_res);
    return 0;
  }
  filesize = file_handle.fsize;
  smc_id(&romprops);
  file_close();
  /* reconfigure FPGA if necessary */
  if(romprops.fpga_conf) {
    printf("reconfigure FPGA with %s...\n", romprops.fpga_conf);
    fpga_pgm((uint8_t*)romprops.fpga_conf);
  }
  set_mcu_addr(base_addr);
  file_open(filename, FA_READ);
  f_lseek(&file_handle, romprops.offset);
  for(;;) {
    ff_sd_offload=1;
    sd_offload_tgt=0;
    bytes_read = file_read();
    if (file_res || !bytes_read) break;
    if(!(count++ % 512)) {
      uart_putc('.');
    }
  }
  file_close();
  set_mapper(romprops.mapper_id);
  printf("rom header map: %02x; mapper id: %d\n", romprops.header.map, romprops.mapper_id);
  ticks_total=getticks()-ticksstart;
  printf("%u ticks total\n", ticks_total);
  if(romprops.mapper_id==3) {
    printf("BSX Flash cart image\n");
    printf("attempting to load BSX BIOS /sd2snes/bsxbios.bin...\n");
    load_sram_offload((uint8_t*)"/sd2snes/bsxbios.bin", 0x800000);
    printf("Type: %02x\n", romprops.header.destcode);
    set_bsx_regs(0xc0, 0x3f);
    uint16_t rombase;
    if(romprops.header.ramsize & 1) {
      rombase = 0xff00;
//      set_bsx_regs(0x36, 0xc9);
    } else {
      rombase = 0x7f00;
//      set_bsx_regs(0x34, 0xcb);
    }
    sram_writebyte(0x33, rombase+0xda);
    sram_writebyte(0x00, rombase+0xd4);
    sram_writebyte(0xfc, rombase+0xd5);
    set_fpga_time(0x0220110301180530LL);
  }
  if(romprops.has_dspx || romprops.has_cx4) {
    printf("DSPx game. Loading firmware image %s...\n", romprops.dsp_fw);
    load_dspx(romprops.dsp_fw, romprops.fpga_features);
    /* fallback to DSP1B firmware if DSP1.bin is not present */
    if(file_res && romprops.dsp_fw == DSPFW_1) {
      load_dspx(DSPFW_1B, romprops.fpga_features);
    }
    if(file_res) {
      snes_menu_errmsg(MENU_ERR_NODSP, (void*)romprops.dsp_fw);
    }
  }
  uint32_t rammask;
  uint32_t rommask;

  while(filesize > (romprops.romsize_bytes + romprops.offset)) {
    romprops.romsize_bytes <<= 1;
  }

  if(romprops.header.ramsize == 0) {
    rammask = 0;
  } else {
    rammask = romprops.ramsize_bytes - 1;
  }
  rommask = romprops.romsize_bytes - 1;
  printf("ramsize=%x rammask=%lx\nromsize=%x rommask=%lx\n", romprops.header.ramsize, rammask, romprops.header.romsize, rommask);
  set_saveram_mask(rammask);
  set_rom_mask(rommask);
  readled(0);
  if(flags & LOADROM_WITH_SRAM) {
    if(romprops.ramsize_bytes) {
      strcpy(strrchr((char*)filename, (int)'.'), ".srm");
      printf("SRM file: %s\n", filename);
      load_sram(filename, SRAM_SAVE_ADDR);
    } else {
      printf("No SRAM\n");
    }
  }

  printf("check MSU...");
  if(msu1_check(filename)) {
    romprops.fpga_features |= FEAT_MSU1;
    romprops.has_msu1 = 1;
  } else {
    romprops.has_msu1 = 0;
  }
  printf("done\n");

  romprops.fpga_features |= FEAT_SRTC;
  romprops.fpga_features |= FEAT_213F;

  fpga_set_213f(romprops.region);
  fpga_set_features(romprops.fpga_features);

  if(flags & LOADROM_WITH_RESET) {
    fpga_dspx_reset(1);
    snes_reset(1);
    delay_ms(10);
    snes_reset(0);
    fpga_dspx_reset(0);
  }

  return (uint32_t)filesize;
}

uint32_t load_sram_offload(uint8_t* filename, uint32_t base_addr) {
  set_mcu_addr(base_addr);
  UINT bytes_read;
  DWORD filesize;
  file_open(filename, FA_READ);
  filesize = file_handle.fsize;
  if(file_res) return 0;
  for(;;) {
    ff_sd_offload=1;
    sd_offload_tgt=0;
    bytes_read = file_read();
    if (file_res || !bytes_read) break;
  }
  file_close();
  return (uint32_t)filesize;
}

uint32_t load_sram(uint8_t* filename, uint32_t base_addr) {
  set_mcu_addr(base_addr);
  UINT bytes_read;
  DWORD filesize;
  file_open(filename, FA_READ);
  filesize = file_handle.fsize;
  if(file_res) {
    printf("load_sram: could not open %s, res=%d\n", filename, file_res);
    return 0;
  }
  for(;;) {
    bytes_read = file_read();
    if (file_res || !bytes_read) break;
    FPGA_SELECT();
    FPGA_TX_BYTE(0x98);
    for(int j=0; j<bytes_read; j++) {
      FPGA_TX_BYTE(file_buf[j]);
      FPGA_WAIT_RDY();
    }
    FPGA_DESELECT();
  }
  file_close();
  return (uint32_t)filesize;
}

uint32_t load_sram_rle(uint8_t* filename, uint32_t base_addr) {
  uint8_t data;
  set_mcu_addr(base_addr);
  DWORD filesize;
  file_open(filename, FA_READ);
  filesize = file_handle.fsize;
  if(file_res) return 0;
  FPGA_SELECT();
  FPGA_TX_BYTE(0x98);
  for(;;) {
    data = rle_file_getc();
    if (file_res || file_status) break;
    FPGA_TX_BYTE(data);
    FPGA_WAIT_RDY();
  }
  FPGA_DESELECT();
  file_close();
  return (uint32_t)filesize;
}

uint32_t load_bootrle(uint32_t base_addr) {
  uint8_t data;
  set_mcu_addr(base_addr);
  DWORD filesize = 0;
  rle_mem_init(bootrle, sizeof(bootrle));

  FPGA_SELECT();
  FPGA_TX_BYTE(0x98);
  for(;;) {
    data = rle_mem_getc();
    if(rle_state) break;
    FPGA_TX_BYTE(data);
    FPGA_WAIT_RDY();
    filesize++;
  }
  FPGA_DESELECT();
  return (uint32_t)filesize;
}


void save_sram(uint8_t* filename, uint32_t sram_size, uint32_t base_addr) {
  uint32_t count = 0;
  uint32_t num = 0;

  FPGA_DESELECT();
  file_open(filename, FA_CREATE_ALWAYS | FA_WRITE);
  if(file_res) {
    uart_putc(0x30+file_res);
  }
  while(count<sram_size) {
    set_mcu_addr(base_addr+count);
    FPGA_SELECT();
    FPGA_TX_BYTE(0x88); /* read */
    for(int j=0; j<sizeof(file_buf); j++) {
      FPGA_WAIT_RDY();
      file_buf[j] = FPGA_RX_BYTE();
      count++;
    }
    FPGA_DESELECT();
    num = file_write();
    if(file_res) {
      uart_putc(0x30+file_res);
    }
  }
  file_close();
}


uint32_t calc_sram_crc(uint32_t base_addr, uint32_t size) {
  uint8_t data;
  uint32_t count;
  uint32_t crc;
  crc=0;
  crc_valid=1;
  set_mcu_addr(base_addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x88);
  for(count=0; count<size; count++) {
    FPGA_WAIT_RDY();
    data = FPGA_RX_BYTE();
    if(get_snes_reset()) {
      crc_valid = 0;
      break;
    }
    crc += crc32_update(crc, data);
  }
  FPGA_DESELECT();
  return crc;
}

uint8_t sram_reliable() {
  uint16_t score=0;
  uint32_t val;
  uint8_t result = 0;
/*while(score<SRAM_RELIABILITY_SCORE) {
    if(sram_readlong(SRAM_SCRATCHPAD)==val) {
      score++;
    } else {
      set_pwr_led(0);
      score=0;
    }
  } */
  for(uint16_t i = 0; i < SRAM_RELIABILITY_SCORE; i++) {
    val=sram_readlong(SRAM_SCRATCHPAD);
    if(val==0x12345678) {
      score++;
    } else {
      printf("i=%d val=%08lX\n", i, val);
    }
  }
  if(score<SRAM_RELIABILITY_SCORE) {
    result = 0;
/*  dprintf("score=%d\n", score); */
  } else {
    result = 1;
  }
  rdyled(result);
  return result;
}

void sram_memset(uint32_t base_addr, uint32_t len, uint8_t val) {
  set_mcu_addr(base_addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x98);
  for(uint32_t i=0; i<len; i++) {
    FPGA_TX_BYTE(val);
    FPGA_WAIT_RDY();
  }
  FPGA_DESELECT();
}

uint64_t sram_gettime(uint32_t base_addr) {
  set_mcu_addr(base_addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x88);
  uint8_t data;
  uint64_t result = 0LL;
  /* 1st nibble is the century - 10 (binary)
     4th nibble is the month (binary)
     all other fields are BCD */
  for(int i=0; i<12; i++) {
    FPGA_WAIT_RDY();
    data = FPGA_RX_BYTE();
    data &= 0xf;
    switch(i) {
      case 0:
        result = (result << 4) | ((data / 10) + 1);
        result = (result << 4) | (data % 10);
        break;
      case 3:
        result = (result << 4) | ((data / 10));
        result = (result << 4) | (data % 10);
        break;
      default:
        result = (result << 4) | data;
    }
  }
  FPGA_DESELECT();
  return result & 0x00ffffffffffffffLL;
}

void load_dspx(const uint8_t *filename, uint8_t coretype) {
  UINT bytes_read;
  DWORD filesize;
  uint16_t word_cnt;
  uint8_t wordsize_cnt = 0;
  uint16_t sector_remaining = 0;
  uint16_t sector_cnt = 0;
  uint16_t pgmsize = 0;
  uint16_t datsize = 0;
  uint32_t pgmdata = 0;
  uint16_t datdata = 0;

  if(coretype & FEAT_ST0010) {
    datsize = 1536;
    pgmsize = 2048;
  } else if (coretype & FEAT_DSPX) {
    datsize = 1024;
    pgmsize = 2048;
  } else if (coretype & FEAT_CX4) {
    datsize = 0;
    pgmsize = 1024; /* Cx4 data ROM */
  } else {
    printf("load_dspx: unknown core (%02x)!\n", coretype);
  }

  file_open((uint8_t*)filename, FA_READ);
  filesize = file_handle.fsize;
  if(file_res) {
    printf("Could not read %s: error %d\n", filename, file_res);
    return;
  }

  fpga_reset_dspx_addr();

  for(word_cnt = 0; word_cnt < pgmsize;) {
    if(!sector_remaining) {
      bytes_read = file_read();
      sector_remaining = bytes_read;
      sector_cnt = 0;
    }
    pgmdata = (pgmdata << 8) | file_buf[sector_cnt];
    sector_cnt++;
    wordsize_cnt++;
    sector_remaining--;
    if(wordsize_cnt == 3){
      wordsize_cnt = 0;
      word_cnt++;
      fpga_write_dspx_pgm(pgmdata);
    }
  }

  wordsize_cnt = 0;
  if(coretype & FEAT_ST0010) {
    file_seek(0xc000);
    sector_remaining = 0;
  }

  for(word_cnt = 0; word_cnt < datsize;) {
    if(!sector_remaining) {
      bytes_read = file_read();
      sector_remaining = bytes_read;
      sector_cnt = 0;
    }
    datdata = (datdata << 8) | file_buf[sector_cnt];
    sector_cnt++;
    wordsize_cnt++;
    sector_remaining--;
    if(wordsize_cnt == 2){
      wordsize_cnt = 0;
      word_cnt++;
      fpga_write_dspx_dat(datdata);
    }
  }

  fpga_reset_dspx_addr();

  file_close();

}

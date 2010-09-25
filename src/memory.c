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

char* hex = "0123456789ABCDEF";

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
  FPGA_TX_BYTE(0x91); /* WRITE */
  FPGA_TX_BYTE(val);
  FPGA_TX_BYTE(0x00); /* dummy */
  FPGA_DESELECT();
}

uint8_t sram_readbyte(uint32_t addr) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x81); /* READ */
  FPGA_TX_BYTE(0x00); /* dummy */
  uint8_t val = FPGA_TXRX_BYTE(0x00);
  FPGA_DESELECT();
  return val;
}

void sram_writeshort(uint16_t val, uint32_t addr) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x91); /* WRITE */
  FPGA_TX_BYTE(val&0xff);
  FPGA_TX_BYTE((val>>8)&0xff);
  FPGA_TX_BYTE(0x00); /* dummy */
  FPGA_DESELECT();
}

void sram_writelong(uint32_t val, uint32_t addr) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x91); /* WRITE */
  FPGA_TX_BYTE(val&0xff);
  FPGA_TX_BYTE((val>>8)&0xff);
  FPGA_TX_BYTE((val>>16)&0xff);
  FPGA_TX_BYTE((val>>24)&0xff);
  FPGA_TX_BYTE(0x00);
  FPGA_DESELECT();
}

uint16_t sram_readshort(uint32_t addr) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x81);
  FPGA_TX_BYTE(0x00);
  uint32_t val = FPGA_TXRX_BYTE(0x00);
  val |= ((uint32_t)FPGA_TXRX_BYTE(0x00)<<8);
  FPGA_DESELECT();
  return val;
}

uint32_t sram_readlong(uint32_t addr) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x81);
  FPGA_TX_BYTE(0x00);
  uint32_t val = FPGA_TXRX_BYTE(0x00);
  val |= ((uint32_t)FPGA_TXRX_BYTE(0x00)<<8);
  val |= ((uint32_t)FPGA_TXRX_BYTE(0x00)<<16);
  val |= ((uint32_t)FPGA_TXRX_BYTE(0x00)<<24);
  FPGA_DESELECT();
  return val;
}

void sram_readlongblock(uint32_t* buf, uint32_t addr, uint16_t count) {
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x81);
  FPGA_TX_BYTE(0x00);
  uint16_t i=0;
  while(i<count) {
    uint32_t val = (uint32_t)FPGA_TXRX_BYTE(0x00)<<24;
    val |= ((uint32_t)FPGA_TXRX_BYTE(0x00)<<16);
    val |= ((uint32_t)FPGA_TXRX_BYTE(0x00)<<8);
    val |= FPGA_TXRX_BYTE(0x00);
    buf[i++] = val;
  }
  FPGA_DESELECT();
}

void sram_readblock(void* buf, uint32_t addr, uint16_t size) {
  uint16_t count=size;
  uint8_t* tgt = buf;
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x81);	/* READ */
  FPGA_TX_BYTE(0x00);	/* dummy */
  while(count--) {
    *(tgt++) = FPGA_TXRX_BYTE(0x00);
  }
  FPGA_DESELECT();
}

void sram_writeblock(void* buf, uint32_t addr, uint16_t size) {
  uint16_t count=size;
  uint8_t* src = buf;
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x91);	/* WRITE */
  while(count--) {
    FPGA_TX_BYTE(*src++);
  }
  FPGA_TX_BYTE(0x00);	/* dummy */
  FPGA_DESELECT();
}

uint32_t load_rom(uint8_t* filename, uint32_t base_addr) {
  UINT bytes_read;
  DWORD filesize;
  UINT count=0;
  file_open(filename, FA_READ);
  filesize = file_handle.fsize;
  smc_id(&romprops);
  set_mcu_addr(base_addr);
  printf("no nervous breakdown beyond this point! or else!\n");
  if(file_res) {
    uart_putc('?');
    uart_putc(0x30+file_res);
    return 0;
  }
  f_lseek(&file_handle, romprops.offset);
  FPGA_DESELECT();
  for(;;) {
/*  SPI_OFFLOAD=1; */
    bytes_read = file_read();
    if (file_res || !bytes_read) break;
    if(!(count++ % 32)) {
      toggle_read_led();
/*    bounce_busy_led(); */
      uart_putc('.');
    }
    FPGA_SELECT();
    FPGA_TX_BYTE(0x91); /* write w/ increment */
    for(int j=0; j<bytes_read; j++) {
      FPGA_TX_BYTE(file_buf[j]);
    }
    FPGA_TX_BYTE(0x00); /* dummy tx for increment+write pulse */
    FPGA_DESELECT();
  }
  file_close();
  set_mapper(romprops.mapper_id);
  printf("rom header map: %02x; mapper id: %d\n", romprops.header.map, romprops.mapper_id);

  uint32_t rammask;
  uint32_t rommask;
	
  if(filesize > (romprops.romsize_bytes + romprops.offset)) {
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

  return (uint32_t)filesize;
}

uint32_t load_sram(uint8_t* filename, uint32_t base_addr) {
  set_mcu_addr(base_addr);
  UINT bytes_read;
  DWORD filesize;
  file_open(filename, FA_READ);
  filesize = file_handle.fsize;
  if(file_res) return 0;
  for(;;) {
    bytes_read = file_read();
    if (file_res || !bytes_read) break;
    FPGA_SELECT();
    FPGA_TX_BYTE(0x91);
    for(int j=0; j<bytes_read; j++) {
      FPGA_TX_BYTE(file_buf[j]);
    }
    FPGA_TX_BYTE(0x00); /* dummy tx */
    FPGA_DESELECT();
  }
  file_close();
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
    FPGA_TX_BYTE(0x81); /* read */
    FPGA_TX_BYTE(0x00); /* dummy */
    for(int j=0; j<sizeof(file_buf); j++) {
      file_buf[j] = FPGA_TXRX_BYTE(0x00);
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
  FPGA_TX_BYTE(0x81);
  FPGA_TX_BYTE(0x00);
  for(count=0; count<size; count++) {
    data = FPGA_TXRX_BYTE(0x00);
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
/*  } else {
      dprintf("i=%d val=%08lX\n", i, val); */
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

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
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

memory.c: RAM operations
*/


#include "config.h"
#include "uart.h"
#include "fpga.h"
#include "cfg.h"
#include "cic.h"
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
#include "cli.h"
#include "cheat.h"
#include "rtc.h"

#include <string.h>
char* hex = "0123456789ABCDEF";

extern snes_romprops_t romprops;
extern uint32_t saveram_crc_old;
extern cfg_t CFG;
extern status_t ST;

void sram_hexdump(uint32_t addr, uint32_t len) {
  static uint8_t buf[16];
  uint32_t ptr;
  for(ptr=0; ptr < len; ptr += 16) {
    sram_readblock((void*)buf, ptr+addr, 16);
    uart_trace(buf-ptr-addr, ptr+addr, 16);
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
  FPGA_TX_BYTE(0x88);   /* READ */
  while(count--) {
    FPGA_WAIT_RDY();
    *(tgt++) = FPGA_RX_BYTE();
  }
  FPGA_DESELECT();
}

uint16_t sram_readstrn(void* buf, uint32_t addr, uint16_t size) {
  uint16_t elemcount = 0;
  uint16_t count = size;
  uint8_t* tgt = buf;
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x88);   /* READ */
  while(count--) {
    FPGA_WAIT_RDY();
    if(!(*(tgt++) = FPGA_RX_BYTE())) break;
    elemcount++;
  }
  tgt--;
  if(*tgt) *tgt = 0;
  FPGA_DESELECT();
  return elemcount;
}

uint16_t sram_writestrn(void* buf, uint32_t addr, uint16_t size) {
  uint16_t elemcount = 0;
  uint16_t count = size;
  uint8_t *src = buf;
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x98);   /* WRITE */
  if(*src) {
    while(count > 1) {
      FPGA_TX_BYTE(*src++);
      FPGA_WAIT_RDY();
      elemcount++;
      count--;
      if(!(*src)) break;
    }
  }
  FPGA_TX_BYTE(0);
  FPGA_WAIT_RDY();
  FPGA_DESELECT();
  return elemcount;
}

void sram_writeblock(void* buf, uint32_t addr, uint16_t size) {
  uint16_t count = size;
  uint8_t* src = buf;
  set_mcu_addr(addr);
  FPGA_SELECT();
  FPGA_TX_BYTE(0x98);   /* WRITE */
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

  if(filename == (uint8_t*)"/sd2snes/menu.bin") {
    fpga_set_features(romprops.fpga_features | FEAT_CMD_UNLOCK);
  }
  /* TODO check prerequisites and set error code here */
  if(flags & LOADROM_WAIT_SNES) snes_set_snes_cmd(0x55);
  /* reconfigure FPGA if necessary */
  if(flags & LOADROM_WAIT_SNES) {
    while(snes_get_mcu_cmd() != SNES_CMD_FPGA_RECONF);
  }
  if(romprops.fpga_conf) {
    printf("reconfigure FPGA with %s...\n", romprops.fpga_conf);
    fpga_pgm((uint8_t*)romprops.fpga_conf);
    fpga_set_features(romprops.fpga_features | FEAT_CMD_UNLOCK);
  }
  if(flags & LOADROM_WAIT_SNES) snes_set_snes_cmd(0x77);
  set_mcu_addr(base_addr + romprops.load_address);
  file_open(filename, FA_READ);
  ff_sd_offload=1;
  sd_offload_tgt=0;
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
  printf("rom header map: %02x; mapper id: %d\n", romprops.header.map, romprops.mapper_id);
  ticks_total=getticks()-ticksstart;
  printf("%u ticks total\n", ticks_total);
  if(romprops.mapper_id==3) {
    printf("BSX Flash cart image\n");
    printf("attempting to load BSX BIOS /sd2snes/bsxbios.bin...\n");
    load_sram_offload((uint8_t*)"/sd2snes/bsxbios.bin", 0x800000, LOADRAM_AUTOSKIP_HEADER);
    printf("attempting to load BS data file /sd2snes/bsxpage.bin...\n");
    load_sram_offload((uint8_t*)"/sd2snes/bsxpage.bin", 0x900000, 0);
    printf("Type: %02x\n", romprops.header.destcode);
    set_bsx_regs(0xf6, 0x09);
    uint16_t rombase;
    if(romprops.header.ramsize & 1) {
      rombase = romprops.load_address + 0xff00;
// set_bsx_regs(0x36, 0xc9);
    } else {
      rombase = romprops.load_address + 0x7f00;
// set_bsx_regs(0x34, 0xcb);
    }
    sram_writebyte(0x33, rombase+0xda);
    sram_writebyte(0x00, rombase+0xd4);
    sram_writebyte(0x00, rombase+0xd5);
    if(CFG.bsx_use_usertime) {
      set_fpga_time(srtctime2bcdtime(CFG.bsx_time));
    } else {
      set_fpga_time(get_bcdtime());
    }
  }
  if(romprops.has_dspx) {
    printf("DSPx game. Loading firmware image %s...\n", romprops.dsp_fw);
    load_dspx(romprops.dsp_fw, romprops.fpga_features);
    /* fallback to DSP1B firmware if DSP1.bin is not present */
    if(file_res && romprops.dsp_fw == DSPFW_1) {
      load_dspx(DSPFW_1B, romprops.fpga_features);
    }
    if(file_res) {
      snes_menu_errmsg(MENU_ERR_SUPPLFILE, (void*)romprops.dsp_fw);
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
      sram_memset(SRAM_SAVE_ADDR, romprops.ramsize_bytes, 0xFF);
      migrate_and_load_srm(filename, SRAM_SAVE_ADDR);
      /* file not found error is ok (SRM file might not exist yet) */
      if(file_res == FR_NO_FILE) file_res = 0;
      saveram_crc_old = calc_sram_crc(SRAM_SAVE_ADDR, romprops.ramsize_bytes);
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

  if(cfg_is_r213f_override_enabled() && (filename != (uint8_t*)"/sd2snes/menu.bin") && !ST.is_u16) {
    romprops.fpga_features |= FEAT_213F; /* e.g. for general consoles */
  }
  fpga_set_213f(romprops.region);
//  fpga_set_features(romprops.fpga_features);
  fpga_set_dspfeat(romprops.fpga_dspfeat);
  dac_pause();
  dac_reset(0);
  if(get_cic_state() == CIC_PAIR) {
    if(filename != (uint8_t*)"/sd2snes/menu.bin") {
      if(CFG.vidmode_game == VIDMODE_AUTO) {
        cic_videomode(romprops.region);
      } else {
        cic_videomode(CFG.vidmode_game);
      }
      cic_d4(romprops.region);
    }
  }

  if(flags & LOADROM_WAIT_SNES) {
    while(snes_get_mcu_cmd() != SNES_CMD_RESET) cli_entrycheck();
  }

  set_mapper(romprops.mapper_id);

//printf("%04lx\n", romprops.header_address + ((void*)&romprops.header.vect_irq16 - (void*)&romprops.header));
  if(flags & (LOADROM_WITH_RESET|LOADROM_WAIT_SNES)) {
    printf("resetting SNES\n");
    fpga_dspx_reset(1);
    snes_reset(1);
    if(ST.is_u16 && (ST.u16_cfg & 0x01)) {
      delay_ms(60*SNES_RESET_PULSELEN_MS);
    } else {
      delay_ms(SNES_RESET_PULSELEN_MS);
    }
    snescmd_prepare_nmihook();
    cheat_yaml_load(filename);
// XXX    cheat_yaml_save(filename);
    cheat_program();
    fpga_set_features(romprops.fpga_features);
    snes_reset(0);
    fpga_dspx_reset(0);
  }

  return (uint32_t)filesize;
}

uint32_t load_spc(uint8_t* filename, uint32_t spc_data_addr, uint32_t spc_header_addr) {
  DWORD filesize;
  UINT bytes_read;
  uint8_t data;
  UINT j;

  printf("%s\n", filename);

  file_open(filename, FA_READ); /* Open SPC file */
  if(file_res) return 0;
  filesize = file_handle.fsize;
  if (filesize < 65920) { /* At this point, we care about filesize only */
    file_close(); /* since SNES decides if it is an SPC file */
    sram_writebyte(0, spc_header_addr); /* If file is too small, destroy previous SPC header */
    return 0;
  }

  set_mcu_addr(spc_data_addr);
  f_lseek(&file_handle, 0x100L); /* Load 64K data segment */

  for(;;) {
    bytes_read = file_read();
    if (file_res || !bytes_read) break;
    FPGA_SELECT();
    FPGA_TX_BYTE(0x98);
    for(j=0; j<bytes_read; j++) {
      FPGA_TX_BYTE(file_buf[j]);
      FPGA_WAIT_RDY();
    }
    FPGA_DESELECT();
  }

  file_close();
  file_open(filename, FA_READ); /* Reopen SPC file to reset file_getc state*/

  set_mcu_addr(spc_header_addr);
  f_lseek(&file_handle, 0x0L); /* Load 256 bytes header */

  FPGA_SELECT();
  FPGA_TX_BYTE(0x98);
  for (j = 0; j < 256; j++) {
    data = file_getc();
    FPGA_TX_BYTE(data);
    FPGA_WAIT_RDY();
  }
  FPGA_DESELECT();

  file_close();
  file_open(filename, FA_READ); /* Reopen SPC file to reset file_getc state*/

  set_mcu_addr(spc_header_addr+0x100);
  f_lseek(&file_handle, 0x10100L); /* Load 128 DSP registers */

  FPGA_SELECT();
  FPGA_TX_BYTE(0x98);
  for (j = 0; j < 128; j++) {
    data = file_getc();
    FPGA_TX_BYTE(data);
    FPGA_WAIT_RDY();
  }
  FPGA_DESELECT();
  file_close(); /* Done ! */

  /* clear echo buffer to avoid artifacts */
  uint8_t esa = sram_readbyte(spc_header_addr+0x100+0x6d);
  uint8_t edl = sram_readbyte(spc_header_addr+0x100+0x7d);
  uint8_t flg = sram_readbyte(spc_header_addr+0x100+0x6c);
  if(!(flg & 0x20) && (edl & 0x0f)) {
    int echo_start = esa << 8;
    int echo_length = (edl & 0x0f) << 11;
    printf("clearing echo buffer %04x-%04x...\n", echo_start, echo_start+echo_length-1);
    sram_memset(spc_data_addr+echo_start, echo_length, 0);
  }

  return (uint32_t)filesize;
}

uint32_t load_sram_offload(uint8_t* filename, uint32_t base_addr, uint8_t flags) {
  set_mcu_addr(base_addr);
  UINT bytes_read;
  DWORD filesize;
  file_open(filename, FA_READ);
  filesize = file_handle.fsize;
  if(file_res) return 0;
  if(flags & LOADRAM_AUTOSKIP_HEADER) {
    if((filesize & 0xffff) == 0x200) {
      ff_sd_offload=1;
      f_lseek(&file_handle, 0x200L);
      printf("load_sram_offload: skipping 512b header\n");
    }
  }
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

uint32_t migrate_and_load_srm(uint8_t* filename, uint32_t base_addr) {
  uint8_t srmfile[256] = SAVE_BASEDIR;
  append_file_basename((char*)srmfile, (char*)filename, ".srm", sizeof(srmfile));
  printf("SRM file: %s\n", srmfile);

  uint32_t filesize;
  /* check for SRM file in new centralized sram folder */
  filesize = load_sram(srmfile, base_addr);
  if(file_res) {
    /* try to move SRM file from old place to new one and to load again */
    strcpy(strrchr((char*)filename, (int)'.'), ".srm");
    printf("%s not found, trying to load and migrate %s...\n", srmfile, filename);
    /* check if new sram folder exists, create it if it doesn't */
    check_or_create_folder(SAVE_BASEDIR);
    f_rename((TCHAR*)filename, (TCHAR*)srmfile);
    filesize = load_sram(srmfile, base_addr);
    if(file_res) {
      printf("migrate_and_load_sram: could not open %s, res=%d\n", srmfile, file_res);
      return 0;
    }
  }
  return (uint32_t)filesize;
}

uint32_t load_sram(uint8_t* filename, uint32_t base_addr) {
  UINT bytes_read;
  DWORD filesize;

  set_mcu_addr(base_addr);
  file_open((uint8_t*)filename, FA_READ);
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

void save_srm(uint8_t* filename, uint32_t sram_size, uint32_t base_addr) {
    char srmfile[256] = SAVE_BASEDIR;
    check_or_create_folder(SAVE_BASEDIR);
    append_file_basename(srmfile, (char*)filename, ".srm", sizeof(srmfile));
    save_sram((uint8_t*)srmfile, sram_size, base_addr);
}

void save_sram(uint8_t* filename, uint32_t sram_size, uint32_t base_addr) {
  uint32_t count = 0;

  FPGA_DESELECT();
  file_open(filename, FA_CREATE_ALWAYS | FA_WRITE);
  if(file_res) {
    uart_putc(0x30+file_res);
    return;
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
    file_write();
    if(file_res) {
      uart_putc(0x30+file_res);
      return;
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
/* dprintf("score=%d\n", score); */
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

void load_dspx(const uint8_t *filename, uint8_t coretype) {
  UINT bytes_read;
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
  } else {
    printf("load_dspx: unknown core (%02x)!\n", coretype);
  }

  file_open((uint8_t*)filename, FA_READ);
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

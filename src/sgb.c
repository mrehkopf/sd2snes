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

   smc.c: SMC file related operations
*/

#include "fileops.h"
#include "config.h"
#include "uart.h"
#include "smc.h"
#include "sgb.h"
#include "string.h"
#include "fpga_spi.h"
#include "snes.h"
#include "fpga.h"
#include "cfg.h"
#include "memory.h"
#include "crc32.h"
#include "rtc.h"
#include "cheat.h"
#include "msu1.h"
#include "led.h"

extern cfg_t CFG;
sgb_romprops_t sgb_romprops;

void sgb_id(sgb_romprops_t* props, uint8_t *filename) {
  sgb_header_t* header = &(props->header);

  props->mapper_id = 0;
  props->ramsize_bytes = 0;
  props->romsize_bytes = 0;
  props->sgb_boot = NULL;
  props->fpga_conf = NULL;
  props->has_sgb = 0;
  props->has_rtc = 0;
  props->srambase = 0;
  props->sramsize_bytes = 0;
  props->error = 0;
  props->error_param = NULL;

  /* check for GB ROM */
  char *ext = strrchr((char*)filename, (int)'.');
  if(!ext || strncmp(ext, ".gb", 3)) return;

  printf("Loading SGB\n");
  props->has_sgb = 1;
  
  file_readblock(header, 0x100, sizeof(sgb_header_t));

  /* FPGA mapper
      0 = MBC0
      1 = MBC1      mapper_id[3] = MBC1M/Multicart
      2 = MBC2
      3 = MBC3      mapper_id[3] = RTC
      5 = MBC5
      6 = Unmapped
      7 = Unmapped

      
  */
  switch (header->carttype) {
    case 0x00:
      // MBC0
      props->mapper_id = 0x00;
      break;
    case 0x01: case 0x02: case 0x03:
      // MBC1
      props->mapper_id = 0x01;
      break;
    case 0x05: case 0x06:
      // MBC2
      props->mapper_id = 0x02;
      break;
    case 0x0F: case 0x10:
      // MBC3 RTC
      props->has_rtc = 1;
      props->mapper_id = 0x03 | 0x08; // add RTC bit
      break;
    case 0x11: case 0x12: case 0x13:
      // MBC3 no RTC
      props->mapper_id = 0x03;
      break;
    case 0x19: case 0x1A: case 0x1B: case 0x1C: case 0x1D: case 0x1E:
      // MBC5
      props->mapper_id = 0x05;
      break;
    default:
      // unsupported mapper.  default to MBC1 which is most widely used
      props->mapper_id = 0x01;
      break;
  }
  
  /* CartRAM size in bytes */
  switch (header->ramsize) {
    case 0x00: props->ramsize_bytes = 0;        break;
    case 0x01: props->ramsize_bytes = 2*1024;   break;
    case 0x02: props->ramsize_bytes = 8*1024;   break;
    case 0x03: props->ramsize_bytes = 32*1024;  break;
    case 0x04: props->ramsize_bytes = 128*1024; break;
    default:   props->ramsize_bytes = 0;        break;
  }
  if (props->mapper_id == 2) props->ramsize_bytes = 512;
  
  /* ROM size in bytes */
  switch (header->romsize) {
    case 0x52: case 0x53: case 0x54:
      props->romsize_bytes += (uint32_t)(32 * 1024) << ((header->romsize >> 4) & 0x0F);
      //break;
    case 0x00: case 0x01: case 0x02: case 0x03:
    case 0x04: case 0x05: case 0x06: case 0x07:
      props->romsize_bytes += (uint32_t)(32 * 1024) << ((header->romsize >> 0) & 0x0F);
      break;
    default:   props->romsize_bytes = 0; break;
  }
  
  /* Handle MBC1M.  Size is minimum to support 2+ files and logo region needs to match.  This is a hack.  See SameBoy */
  if (props->mapper_id == 0x01 && props->romsize_bytes >= (256 + 16) * 1024) {
    uint8_t logo[0x30];
    file_readblock(logo, 0x40104, sizeof(logo));
    if (!memcmp(header->logo, logo, sizeof(logo))) {
      props->mapper_id |= 0x08;
    }
  }
  
  /* SGB BOOT ROM filename */
  props->sgb_boot = SGBFW;
  
  /* saveram base address */
  props->srambase = 0;

  /* saveram size in bytes */
  props->sramsize_bytes = props->ramsize_bytes;

  /* features */
  props->fpga_sgbfeat = ( (((uint16_t)CFG.sgb_volume_boost & 0x7) << 0)
                        | (((uint16_t)CFG.sgb_enh_override & 0x1) << 8)
                        );

  /* SGB debug print */
  if (props->has_sgb) {
    printf("SGB:  has_sgb=%1d  mapper=0x%02x  ramsize_bytes=%ld  romsize_bytes=%ld  srambase=0x%06lx  sramsize_bytes=%ld\n", props->has_sgb,
                                                                                                                             props->mapper_id,
                                                                                                                             props->ramsize_bytes,
                                                                                                                             props->romsize_bytes,
                                                                                                                             props->srambase,
                                                                                                                             props->sramsize_bytes);
    printf("SGB:  carttype=0x%02x  romsize=0x%02x  ramsize=0x%02x\n", props->header.carttype,
                                                                      props->header.romsize,
                                                                      props->header.ramsize);
  }

}

uint8_t sgb_update_file(uint8_t **filename_ref) {
  if (sgb_romprops.has_sgb) {
    file_close();

    *filename_ref = (uint8_t *)SGBSR;
    uint8_t *filename = *filename_ref;
    file_open(filename, FA_READ);
    if(file_res) {
      uart_putc('?');
      uart_putc(0x30+file_res);
      sgb_romprops.has_sgb = 0;
      return 0;
    }
  }
  
  return 1;
}

uint8_t sgb_update_romprops(snes_romprops_t *romprops, uint8_t *filename) {
  if (sgb_romprops.has_sgb) {
    /* confirm properties of the SNES image */
    if (  !(romprops->mapper_id == 1)                                      // LOROM
       || !(0 < romprops->header.romsize && romprops->header.romsize < 10) // 512KB
       || !(file_handle.fsize <= (512 * 1024))
       || !(romprops->sramsize_bytes == 0)                                 // no SaveRAM
       ) {
      sgb_romprops.has_sgb = 0;
      printf("SGB SNES image does meet requirements: mapper=0x%02x, romsize=0x%02x, filesize=%ld, sramsize_bytes=%ld.\n", romprops->mapper_id,
                                                                                                                          romprops->header.romsize,
                                                                                                                          file_handle.fsize,
                                                                                                                          romprops->sramsize_bytes);
      return 0;
    }
    
    romprops->fpga_conf = FPGA_SGB;
    romprops->load_address = 0x880000;

#ifdef CONFIG_MK2
    // FIXME: temporary workaround for MSU
    if (msu1_check(filename)) {
      // msu1_check has several side effects.  assume they can be safely ignored for this workaround
      extern FIL msudata;      
      f_close(&msudata);
      romprops->fpga_conf = ((const uint8_t*)"/sd2snes/fpga_sgb_msu." FPGA_CONF_EXT);
    }
#endif
  }
  
  return 1;
}

void sgb_cheat_program(void) {
  if (sgb_romprops.has_sgb) {
    /* update cheats based on SGB file and configuration state */
    uint8_t state = sgb_bios_state();
        
    /* hooks disabled if bios files don't match */
    if (state != SGB_BIOS_OK && !CFG.sgb_bios_override) cheat_nmi_enable(0);
    if (state != SGB_BIOS_OK && !CFG.sgb_bios_override) cheat_irq_enable(0);
    
    /* save states (repurpose cheats) enabled via config */
    cheat_enable((CFG.sgb_enable_state && sgb_romprops.ramsize_bytes <= 64 * 1024) ? 1 : 0);
    
    /* wram never present */
    cheat_wram_present(0);
  }
}

uint8_t sgb_bios_state(void) {
  uint8_t state = SGB_BIOS_OK;

  file_open(SGBFW, FA_READ);
  if (file_res) {
    state = SGB_BIOS_MISSING;
  }
  else {
    uint32_t crc = 0;
    UINT bytes_read = 0;
    
    while ((bytes_read = file_read())) {
      if (file_res) break;

      for (UINT i = 0; i < bytes_read; i++) crc = crc32_update(crc, file_buf[i]);
    }
    if (state <= SGB_BIOS_MISMATCH && crc != 0x5e46583b) {
      printf("SGB sgb2_boot.bin CRC mismatch: 0x%08x\n", (unsigned int)crc);
      state = SGB_BIOS_MISMATCH;
    }
  }
  file_close();

  file_open(SGBSR, FA_READ);
  if (file_res) {
    state = SGB_BIOS_MISSING;
  }
  else {
    uint32_t crc = 0;
    UINT bytes_read = 0;
    
    while ((bytes_read = file_read())) {
      if (file_res) break;

      for (UINT i = 0; i < bytes_read; i++) crc = crc32_update(crc, file_buf[i]);
    }
    if (state <= SGB_BIOS_MISMATCH && crc != 0xbe7164e9) {
      printf("SGB sgb2_snes.bin CRC mismatch: 0x%08x\n", (unsigned int)crc);
      state = SGB_BIOS_MISMATCH;
    }
  }
  file_close();
  
  return state;
}

void sgb_gtc_load(uint8_t* filename) {
  if (sgb_romprops.has_sgb && sgb_romprops.has_rtc) {
    struct tm time;
    struct gtm gtime_cur;
    struct gtm gtime_ts;
  
    char gtcfile[256] = SAVE_BASEDIR;
    check_or_create_folder(SAVE_BASEDIR);
    append_file_basename(gtcfile, (char*)filename, ".gtc", sizeof(gtcfile));
    file_open((uint8_t *)gtcfile, FA_READ);
  
    /* get current time in gtime format */
    read_rtc(&time);
    time2gtime(&gtime_cur, &time);

    printf("SGB load curr time: year=%hd, mon=%hhd, days=%hhd, hour=%hhd, min=%hhd, sec=%hhd\n", time.tm_year,
                                                                                                 time.tm_mon,
                                                                                                 time.tm_mday,
                                                                                                 time.tm_hour,
                                                                                                 time.tm_min,
                                                                                                 time.tm_sec);
    printf("SGB load curr gtime RTC: days=%ld, hour=%hhd, min=%hhd, sec=%hhd\n", gtime_cur.gtm_days,
                                                                                 gtime_cur.gtm_hour,
                                                                                 gtime_cur.gtm_min,
                                                                                 gtime_cur.gtm_sec);
  
    if(file_res) {
      /* create GTC file if it doesn't exist.  load the delta of the current time and the contents of the file into the GB RTC */
      file_open((uint8_t *)gtcfile, FA_CREATE_ALWAYS | FA_WRITE);
      if(file_res) {
        uart_putc(0x30+file_res);
        return;
      }
  
      gtime_ts = gtime_cur;
      writeled(1);
      file_writeblock(&gtime_ts, 0, sizeof(gtime_ts));
      writeled(0);
    }
    else {
      file_readblock(&gtime_ts, 0, sizeof(gtime_ts));
    }

    /* if the menu time was rolled back to before the current TS then give up and set them equal.
       The GB RTC can't represent time in the past older than the TS. */
    if (get_deltagtime(&gtime_cur, &gtime_ts)) {
      printf("SGB load GB RTC underflow\n");
      file_writeblock(&gtime_cur, 0, sizeof(gtime_cur));
      memset(&gtime_cur, 0, sizeof(gtime_cur));
    }
    
    uint64_t ftime = 0;
    ftime |= (uint64_t)(gtime_cur.gtm_sec               ) <<  0; // sec
    ftime |= (uint64_t)(gtime_cur.gtm_min               ) <<  8; // min
    ftime |= (uint64_t)(gtime_cur.gtm_hour              ) << 16; // hour
    ftime |= (uint64_t)(gtime_cur.gtm_days % 512        ) << 24; // days
    ftime |= (uint64_t)(gtime_cur.gtm_days / 512 ? 1 : 0) << 39; // overflow
    set_fpga_time(ftime);

    unsigned ftimel = (ftime >>  0) & 0xFFFFFFFF;
    unsigned ftimeh = (ftime >> 32) & 0xFFFFFFFF;
    printf("SGB load GB RTC: days=%ld, hour=%hhd, min=%hhd, sec=%hhd, ftime=0x%04x%04x\n", gtime_cur.gtm_days,
                                                                                           gtime_cur.gtm_hour,
                                                                                           gtime_cur.gtm_min,
                                                                                           gtime_cur.gtm_sec,
                                                                                           ftimeh, ftimel);
    
    file_close();
  }
}

void sgb_gtc_save(uint8_t* filename) {
  if (sgb_romprops.has_sgb && sgb_romprops.has_rtc) {
    struct tm time;
    struct gtm gtime_cur;
    struct gtm gtime_ts;
    struct gtm gtime_gtc;

    /* read GTC */
    uint64_t ftime = get_fpga_time();
    
    /* read RTC */
    read_rtc(&time);
    time2gtime(&gtime_cur, &time);
    gtime_gtc.gtm_sec  = (ftime >> 0)  & 0x3F;
    gtime_gtc.gtm_min  = (ftime >> 8)  & 0x3F;
    gtime_gtc.gtm_hour = (ftime >> 16) & 0x1F;
    gtime_gtc.gtm_days = (ftime >> 24) & 0x1FF;
    
    /* if it has been written and is not halted then compute a new delta */
    if (((ftime >> 55) & 0x1) && !((ftime >> 38) & 0x1)) {      
      /* update the timestamp file.  gtime_ts = (gtime_cur - gtime_gtc) */
      char gtcfile[256] = SAVE_BASEDIR;
      check_or_create_folder(SAVE_BASEDIR);
      append_file_basename(gtcfile, (char*)filename, ".gtc", sizeof(gtcfile));
      file_open((uint8_t *)gtcfile, FA_WRITE);
      if (file_res) {
        uart_putc(0x30+file_res);
        return;
      }
      
      if (get_deltagtime(&gtime_cur, &gtime_gtc)) {
        printf("SGB save GB RTC underflow.  This should never happen.\n");
      }
      file_writeblock(&gtime_cur, 0, sizeof(gtime_ts));

      unsigned ftimel = (ftime >>  0) & 0xFFFFFFFF;
      unsigned ftimeh = (ftime >> 32) & 0xFFFFFFFF;
      printf("SGB save GB RTC: days=%ld, hour=%hhd, min=%hhd, sec=%hhd, ftime=0x%04x%04x\n", gtime_cur.gtm_days,
                                                                                             gtime_cur.gtm_hour,
                                                                                             gtime_cur.gtm_min,
                                                                                             gtime_cur.gtm_sec,
                                                                                             ftimeh, ftimel);
                                                                         
      file_close();
    }
  }
}

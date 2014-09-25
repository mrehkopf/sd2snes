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

   filetypes.c: directory scanning and file type detection
*/

#include <string.h>
#include "config.h"
#include "uart.h"
#include "filetypes.h"
#include "ff.h"
#include "smc.h"
#include "fileops.h"
#include "crc.h"
#include "memory.h"
#include "led.h"
#include "sort.h"

#include "timer.h"

/*
 * directory format:
 *  I. Pointer tables
 *      3 bytes   pointer to file entry
 *      1 byte    type of entry
 *                (see enum SNES_FTYPE in filetypes.h)
 *
 * II. File entries
 *      6 bytes   size string (e.g. " 1024k")
 *      n bytes   file/dir name
 */

uint16_t scan_dir(const uint8_t *path, const uint32_t base_addr, const SNES_FTYPE type_mask) {
  DIR dir;
  FRESULT res;
  FILINFO fno;
  TCHAR *fn;
  uint32_t ptr_tbl_off = base_addr;
  uint32_t file_tbl_off = base_addr + 0x10000;
  char buf[7];
  char *size_units[3] = {" ", "k", "M"};
  uint32_t entry_fsize;
  uint8_t entry_unit_idx;
  size_t fnlen;

  fno.lfsize = 255;
  fno.lfname = (TCHAR*)file_lfn;
  res = f_opendir(&dir, (TCHAR*)path);
printf("opendir res=%d\n", res);
  uint16_t numentries = 0;
  int ticks=getticks();
  SNES_FTYPE type;
printf("start\n");
  if (res == FR_OK) {
    for (;;) {
      res = f_readdir(&dir, &fno);
      if(res != FR_OK || fno.fname[0] == 0 || numentries >= 16000)break;
      fn = *fno.lfname ? fno.lfname : fno.fname;
      type = determine_filetype(fno);
      if(type & type_mask) {
        switch(type) {
          case TYPE_ROM:
          case TYPE_SPC:
          case TYPE_SUBDIR:
          case TYPE_PARENT:
            if(fno.fattrib & AM_DIR) {
              if((fn[0]=='.' && fn[1]==0) || (fno.fattrib & (AM_HID | AM_SYS))) continue; /* omit './' directory */
              snprintf(buf, sizeof(buf), " <dir>");
            } else {
              entry_fsize = fno.fsize;
              entry_unit_idx = 0;
              while(entry_fsize > 9999) {
                entry_fsize >>= 10;
                entry_unit_idx++;
              }
              snprintf(buf, sizeof(buf), "% 5ld", entry_fsize);
              strncat(buf, size_units[entry_unit_idx], 1);
            }
            fnlen = strlen(fn);
            if(fno.fattrib & AM_DIR) {
              fn[fnlen] = '/';
              fn[fnlen+1] = 0;
              fnlen++;
            }
            sram_writeblock(buf, file_tbl_off, 6);
            sram_writeblock(fn, file_tbl_off+6, fnlen+1);
            sram_writelong((file_tbl_off-SRAM_MENU_ADDR) | ((uint32_t)type << 24), ptr_tbl_off);
            file_tbl_off += fnlen+7;
            ptr_tbl_off += 4;
            numentries++;
            break;
          case TYPE_UNKNOWN:
          default:
            break;
        }
      }
    }
  }
  /* write directory termination */
  sram_writelong(0, ptr_tbl_off);
  sort_dir(SRAM_DIR_ADDR, numentries);
printf("end\n");
printf("%d entries, time: %d\n", numentries, getticks()-ticks);
  return numentries;
}

SNES_FTYPE determine_filetype(FILINFO fno) {
  char* ext;
  if(fno.fattrib & AM_DIR) {
    if(!strcmp(fno.fname, "..")) {
      return TYPE_PARENT;
    }
    return TYPE_SUBDIR;
  }
  ext = strrchr(fno.fname, '.');
  if(ext == NULL)
    return TYPE_UNKNOWN;
  if(  (!strcasecmp(ext+1, "SMC"))
     ||(!strcasecmp(ext+1, "SFC"))
     ||(!strcasecmp(ext+1, "FIG"))
     ||(!strcasecmp(ext+1, "SWC"))
     ||(!strcasecmp(ext+1, "BS"))
    ) {
    return TYPE_ROM;
  }
/*  if(  (!strcasecmp(ext+1, "IPS"))
     ||(!strcasecmp(ext+1, "UPS"))
    ) {
    return TYPE_IPS;
  }*/
  if(!strcasecmp(ext+1, "SPC")) {
    return TYPE_SPC;
  }
  if(!strcasecmp(ext+1, "CHT")) {
    return TYPE_CHT;
  }
  if(!strcasecmp(ext+1, "SKIN")) {
    return TYPE_SKIN;
  }
  return TYPE_UNKNOWN;
}

FRESULT get_db_id(uint32_t* id) {
  file_open((uint8_t*)"/sd2snes/sd2snes.db", FA_READ);
  if(file_res == FR_OK) {
    file_readblock(id, 0, 4);
/* XXX */// *id=0xdead;
    file_close();
  } else {
    *id=0xdeadbeef;
  }
  return file_res;
}

int get_num_dirent(uint32_t addr) {
  int result = 0;
  while(sram_readlong(addr+result*4)) {
    result++;
  }
  return result;
}

void sort_all_dir(uint32_t endaddr) {
  uint32_t entries = 0;
  uint32_t current_base = SRAM_DIR_ADDR;
  while(current_base<(endaddr)) {
    while(sram_readlong(current_base+entries*4)) {
      entries++;
    }
    int ticks=getticks();
    printf("sorting dir @%lx, entries: %ld, time: ", current_base, entries);
    sort_dir(current_base, entries);
    printf("%d\n", getticks()-ticks);
    current_base += 4*entries + 4;
    entries = 0;
  }
}

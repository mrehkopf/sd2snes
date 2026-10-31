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

   filetypes.h: directory scanning and file type detection
*/

#ifndef FILETYPES_H
#define FILETYPES_H

#ifdef DEBUG_FS
#define DBG_FS
#else
#define DBG_FS while(0)
#endif

#include "ff.h"

#define FS_MAX_DEPTH	(10)
/* rely on optimization to reduce every occurrence to the same location. */
#define SYS_DIR_NAME	((const char*)"sd2snes")
typedef enum {
  TYPE_UNKNOWN =   0,
  TYPE_ROM     =   1,
  TYPE_SRM     =   2,
  TYPE_SPC     =   3,
  TYPE_IPS     =   4,
  TYPE_CHT     =   5,
  TYPE_SKIN    =   6,
  TYPE_SUBDIR  =  64,
  TYPE_PARENT  = 128
} SNES_FTYPE;


SNES_FTYPE determine_filetype(FILINFO fno);
uint16_t scan_dir(const uint8_t *path, uint32_t base_addr, const SNES_FTYPE *filetypes);
int get_num_dirent(uint32_t addr);
void sort_all_dir(uint32_t endaddr);
void make_filesize_string(char *buf, uint32_t size);
int is_requested_filetype(SNES_FTYPE type, const SNES_FTYPE *filetypes);
#endif

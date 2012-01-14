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

   fileops.c: simple file access functions
*/

#include "config.h"
#include "uart.h"
#include "ff.h"
#include "fileops.h"
#include "diskio.h"

/*
WCHAR ff_convert(WCHAR w, UINT dir) {
  return w;
}*/

int newcard;

void file_init() {
  file_res=f_mount(0, &fatfs);
  newcard = 0;
}

void file_reinit(void) {
  disk_init();
  file_init();
}

FRESULT dir_open_by_filinfo(DIR* dir, FILINFO* fno) {
  return l_opendirbycluster(&fatfs, dir, (TCHAR*)"", fno->clust);
}

void file_open_by_filinfo(FILINFO* fno) {
  file_res = l_openfilebycluster(&fatfs, &file_handle, (TCHAR*)"", fno->clust, fno->fsize);
}

void file_open(uint8_t* filename, BYTE flags) {
  if (disk_state == DISK_CHANGED) {
    file_reinit();
    newcard = 1;
  }
  file_res = f_open(&file_handle, (TCHAR*)filename, flags);
  file_block_off = sizeof(file_buf);
  file_block_max = sizeof(file_buf);
  file_status = file_res ? FILE_ERR : FILE_OK;
}

void file_close() {
  file_res = f_close(&file_handle);
}

void file_seek(uint32_t offset) {
  file_res = f_lseek(&file_handle, (DWORD)offset);
}

UINT file_read() {
  UINT bytes_read;
  file_res = f_read(&file_handle, file_buf, sizeof(file_buf), &bytes_read);
  return bytes_read;
}

UINT file_write() {
  UINT bytes_written;
  file_res = f_write(&file_handle, file_buf, sizeof(file_buf), &bytes_written);
  if(bytes_written < sizeof(file_buf)) {
    printf("wrote less than expected - card full?\n");
  }
  return bytes_written;
}

UINT file_readblock(void* buf, uint32_t addr, uint16_t size) {
  UINT bytes_read;
  file_res = f_lseek(&file_handle, addr);
  if(file_handle.fptr != addr) {
    return 0;
  }
  file_res = f_read(&file_handle, buf, size, &bytes_read);
  return bytes_read;
}

UINT file_writeblock(void* buf, uint32_t addr, uint16_t size) {
  UINT bytes_written;
  file_res = f_lseek(&file_handle, addr);
  if(file_res) return 0;
  file_res = f_write(&file_handle, buf, size, &bytes_written);
  return bytes_written;
}

uint8_t file_getc() {
  if(file_block_off == file_block_max) {
    file_block_max = file_read();
    if(file_block_max == 0) file_status = FILE_EOF;
    file_block_off = 0;
  }
  return file_buf[file_block_off++];
}

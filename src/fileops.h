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

   fileops.h: simple file access functions
*/

#ifndef FILEOPS_H
#define FILEOPS_H
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

#include "ff.h"

enum filestates { FILE_OK=0, FILE_ERR, FILE_EOF };

extern BYTE file_buf[512] __attribute__((aligned(4)));
extern FATFS fatfs;
extern FIL file_handle;
extern FRESULT file_res;
extern uint8_t file_lfn[258];
extern uint8_t file_path[256];
extern uint16_t file_block_off, file_block_max;
extern enum filestates file_status;

void file_init(void);
void file_open(const uint8_t* filename, BYTE flags);
FRESULT dir_open_by_filinfo(DIR* dir, FILINFO* fno_param);
void file_open_by_filinfo(FILINFO* fno);
void file_close(void);
void file_seek(uint32_t offset);
UINT file_read(void);
UINT file_write(size_t len);
UINT file_readblock(void* buf, uint32_t addr, uint16_t size);
UINT file_writeblock(void* buf, uint32_t addr, uint16_t size);
uint8_t file_getc(void);

void append_file_basename(char *dirbase, char *filename, char *extension, int num);
FRESULT check_or_create_folder(TCHAR *dir);

char *get_fresult_name(FRESULT res);
char *get_fresult_friendlyname(FRESULT res);

void print_fresult(FRESULT res, const char *fmt, ...);
void vprint_fresult(FRESULT res, const char *fmt, va_list arglist);

// New file api that allows for opening and closing multiple files (dont know how useful this would be)
/*
typedef struct {
    FIL handle;
    FRESULT res;
    BYTE buf[512] __attribute__((aligned(4)));
    uint16_t block_off;
    uint16_t block_max;
    enum filestates status;
} file_ctx_t;

void file_open_ctx(file_ctx_t *ctx, const TCHAR *filename, BYTE flags);
void file_close_ctx(file_ctx_t *ctx);
void file_seek_ctx(file_ctx_t *ctx, uint32_t offset);
UINT file_read_ctx(file_ctx_t *ctx);
UINT file_write_ctx(file_ctx_t *ctx, size_t len);
UINT file_readblock_ctx(file_ctx_t *ctx, void* buf, uint32_t addr, uint16_t size);
UINT file_writeblock_ctx(file_ctx_t *ctx, void* buf, uint32_t addr, uint16_t size);
uint8_t file_getc_ctx(file_ctx_t *ctx);
*/
#endif

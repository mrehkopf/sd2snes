// insert cool lenghty disclaimer here
// fileops.h

#ifndef FILEOPS_H
#define FILEOPS_H
#include "ff.h"

BYTE file_buf[512];
FATFS fatfs;
FIL file_handle;
FRESULT file_res;
uint8_t file_lfn[256];

void file_init(void);
void file_open(uint8_t* filename, BYTE flags);
void file_open_by_filinfo(FILINFO* fno);
void file_close(void);
UINT file_read(void);
UINT file_write(void);
UINT file_readblock(void* buf, uint32_t addr, uint16_t size);
UINT file_writeblock(void* buf, uint32_t addr, uint16_t size);
#endif

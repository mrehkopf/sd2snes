// insert cool lenghty disclaimer here
// fileops.h

#ifndef FILEOPS_H
#define FILEOPS_H
#include "ff.h"

BYTE file_buf[512];
FATFS fatfs;
FIL file_handle;
FRESULT file_res;

void file_init(void);
void file_open(char* filename, BYTE flags);
void file_close(void);
UINT file_read(void);
UINT file_write(void);
#endif

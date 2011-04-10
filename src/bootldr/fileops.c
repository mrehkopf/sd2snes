
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

UINT file_read() {
  UINT bytes_read;
  file_res = f_read(&file_handle, file_buf, sizeof(file_buf), &bytes_read);
  return bytes_read;
}

/*UINT file_write() {
  UINT bytes_written;
  file_res = f_write(&file_handle, file_buf, sizeof(file_buf), &bytes_written);
  if(bytes_written < sizeof(file_buf)) {
    printf("wrote less than expected - card full?\n");
  }
  return bytes_written;
}*/

UINT file_readblock(void* buf, uint32_t addr, uint16_t size) {
  UINT bytes_read;
  file_res = f_lseek(&file_handle, addr);
  if(file_handle.fptr != addr) {
    return 0;
  }
  file_res = f_read(&file_handle, buf, size, &bytes_read);
  return bytes_read;
}

/*UINT file_writeblock(void* buf, uint32_t addr, uint16_t size) {
  UINT bytes_written;
  file_res = f_lseek(&file_handle, addr);
  if(file_res) return 0;
  file_res = f_write(&file_handle, buf, size, &bytes_written);
  return bytes_written;
}*/

uint8_t file_getc() {
  if(file_block_off == file_block_max) {
    file_block_max = file_read();
    if(file_block_max == 0) file_status = FILE_EOF;
    file_block_off = 0;
  }
  return file_buf[file_block_off++];
}

// insert cool lengthy disclaimer here
// fileops.c: convenience

#include "config.h"
#include "uart.h"
#include "ff.h"
#include "fileops.h"

void file_init() {
	f_mount(0, &fatfs);
}

void file_open(char* filename, BYTE flags) {
	file_res = f_open(&file_handle, filename, flags);
}

void file_close() {
	file_res = f_close(&file_handle);
}

UINT file_read() {
	UINT bytes_read;
	file_res = f_read(&file_handle, file_buf, sizeof(file_buf), &bytes_read);
	return bytes_read;
}

UINT file_write() {
	UINT bytes_written;
	file_res = f_write(&file_handle, file_buf, sizeof(file_buf), &bytes_written);
	return bytes_written;
}

UINT file_readblock(void* buf, uint32_t addr, uint16_t size) {
	UINT bytes_read;
	file_res = f_lseek(&file_handle, addr);
	if(file_res) return 0;
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

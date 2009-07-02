// insert cool lenghty disclaimer here
// fileops.c: fatfs wrapping for convenience

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


#include "rle.h"
#include "fileops.h"

uint8_t rle_file_getc() {
  static uint16_t rle_filled = 0;
  static uint8_t data;
  if(!rle_filled) {
    data = file_getc();
    switch(data) {
      case RLE_RUN:
        data = file_getc();
        rle_filled = file_getc()-1;
        break;
      case RLE_RUNLONG:
        data = file_getc();
        rle_filled = file_getc();
        rle_filled |= file_getc() << 8;
        rle_filled--;
        break;
      case RLE_ESC:
        data = file_getc();
        break;
    }
  } else {
    rle_filled--;
  }
  if(file_status || file_res) rle_filled = 0;
  return data;
}

void rle_mem_init(const uint8_t* address, uint32_t len) {
  rle_mem_ptr = address;
  rle_mem_endptr = address+len;
  rle_state = 0;
}

uint8_t rle_mem_getc() {
  static uint16_t rle_mem_filled = 0;
  static uint8_t rle_mem_data;
  if(!rle_mem_filled) {
    rle_mem_data = *(rle_mem_ptr++);
    switch(rle_mem_data) {
      case RLE_RUN:
        rle_mem_data = *(rle_mem_ptr)++;
        rle_mem_filled = *(rle_mem_ptr)++ - 1;
        break;
      case RLE_RUNLONG:
        rle_mem_data = *(rle_mem_ptr)++;
        rle_mem_filled = *(rle_mem_ptr)++;
        rle_mem_filled |= *(rle_mem_ptr)++ << 8;
        rle_mem_filled--;
        break;
      case RLE_ESC:
        rle_mem_data = *(rle_mem_ptr)++;
        break;
    }
  } else {
    rle_mem_filled--;
  }
  if(rle_mem_ptr>=rle_mem_endptr){
    rle_mem_filled = 0;
    rle_state = 1;
  }
  return rle_mem_data;
}

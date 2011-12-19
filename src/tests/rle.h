#ifndef RLE_H
#define RLE_H

#include <arm/NXP/LPC17xx/LPC17xx.h>

#define RLE_ESC     (0x9b)
#define RLE_RUN     (0x5b)
#define RLE_RUNLONG (0x77)

uint8_t rle_file_getc(void);
uint8_t rle_mem_getc(void);
void rle_mem_init(const uint8_t *address, uint32_t len);
const uint8_t *rle_mem_ptr;
const uint8_t *rle_mem_endptr;
uint8_t rle_state;

#endif

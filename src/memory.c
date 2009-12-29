// insert cool lengthy disclaimer here
// memory.c: SRAM operations

#include <stdint.h>
#include <avr/pgmspace.h>
#include <util/delay.h>
#include "config.h"
#include "uart.h"
#include "fpga.h"
#include "crc16.h"
#include "ff.h"
#include "fileops.h"
#include "spi.h"
#include "fpga_spi.h"
#include "avrcompat.h"
#include "led.h"
#include "smc.h"
#include "fpga_spi.h"
#include "memory.h"
#include "snes.h"

char* hex = "0123456789ABCDEF";

void sram_hexdump(uint32_t addr, uint32_t len) {
	static uint8_t buf[16];
	uint32_t ptr;
	for(ptr=0; ptr < len; ptr += 16) {
		sram_readblock((void*)buf, ptr+addr, 16);
		uart_trace(buf, 0, 16);
	}
}

void sram_writebyte(uint8_t val, uint32_t addr) {
	set_avr_addr(addr);
	spi_fpga();
	spiTransferByte(0x91); // WRITE
	spiTransferByte(val);
	spiTransferByte(0x00); // dummy
	spi_none();
}

uint8_t sram_readbyte(uint32_t addr) {
	set_avr_addr(addr);
	spi_fpga();
	spiTransferByte(0x81); // READ
	spiTransferByte(0x00); // dummy
	uint8_t val = spiTransferByte(0x00);
	spi_none();
	return val;
}

void sram_writeshort(uint16_t val, uint32_t addr) {
	set_avr_addr(addr);
	spi_fpga();
	spiTransferByte(0x91); // WRITE
	spiTransferByte(val&0xff);		// 7-0
	spiTransferByte((val>>8)&0xff);		// 15-8
	spiTransferByte(0x00); // dummy
	spi_none();
}

void sram_writelong(uint32_t val, uint32_t addr) {
	set_avr_addr(addr);
	spi_fpga();
	spiTransferByte(0x91); // WRITE
	spiTransferByte(val&0xff);		// 7-0
	spiTransferByte((val>>8)&0xff);		// 15-8
	spiTransferByte((val>>16)&0xff);	// 23-15
	spiTransferByte((val>>24)&0xff);	// 31-24
	spiTransferByte(0x00); // dummy
	spi_none();
}

uint16_t sram_readshort(uint32_t addr) {
	set_avr_addr(addr);
	spi_fpga();
	spiTransferByte(0x81);
	spiTransferByte(0x00);

	uint32_t val = spiTransferByte(0x00);
	val |= ((uint32_t)spiTransferByte(0x00)<<8);
	spi_none();
	return val;
}

uint32_t sram_readlong(uint32_t addr) {
	set_avr_addr(addr);
	spi_fpga();
	spiTransferByte(0x81);
	spiTransferByte(0x00);
	uint32_t count=0;
	uint32_t val = spiTransferByte(count & 0xff);
	count++;
	val |= ((uint32_t)spiTransferByte(count & val)<<8);
	count++;
	val |= ((uint32_t)spiTransferByte(count & val)<<16);
	count++;
	val |= ((uint32_t)spiTransferByte(count & val)<<24);
	count++;
	spi_none();
	return val;
}

void sram_readblock(void* buf, uint32_t addr, uint16_t size) {
	uint16_t count=size;
	uint8_t* tgt = buf;
	set_avr_addr(addr);
	spi_fpga();
	spiTransferByte(0x81);	// READ
	spiTransferByte(0x00);	// dummy
	while(count--) {
		*(tgt++) = spiTransferByte(0x00);
	}
	spi_none();
}

void sram_writeblock(void* buf, uint32_t addr, uint16_t size) {
	uint16_t count=size;
	uint8_t* src = buf;
	set_avr_addr(addr);
	spi_fpga();
	spiTransferByte(0x91);	// WRITE 
	while(count--) {
		spiTransferByte(*src++);
	}
	spiTransferByte(0x00);	// dummy
	spi_none();
}

uint32_t load_rom(uint8_t* filename, uint32_t base_addr) {
//	uint8_t dummy;
	UINT bytes_read;
	DWORD filesize;
	UINT count=0;
	file_open(filename, FA_READ);
	filesize = file_handle.fsize;
	smc_id(&romprops);
	set_avr_addr(base_addr);
	dprintf("no nervous breakdown beyond this point! or else!\n");
	if(file_res) {
		uart_putc('?');
		uart_putc(0x30+file_res);
		return 0;
	}
	f_lseek(&file_handle, romprops.offset);
	spi_none();
	for(;;) {
		SPI_OFFLOAD=1;
		spi_none();
		bytes_read = file_read();
		if (file_res || !bytes_read) break;
		if(!(count++ % 8)) {
//			toggle_busy_led();
			bounce_busy_led();
			uart_putc('.');
		}
/*		spi_fpga();
		spiTransferByte(0x91); // write w/ increment
		if(!(count++ % 8)) {
//			toggle_busy_led();
			bounce_busy_led();
			uart_putc('.');
		}
		for(int j=0; j<bytes_read; j++) {
//			spiTransferByte(file_buf[j]);
			SPDR = file_buf[j];
			loop_until_bit_is_set(SPSR, SPIF);
			dummy = SPDR;
		}
		spiTransferByte(0x00); // dummy tx for increment+write pulse		*/
	}
	file_close();
	spi_none();
	set_avr_mapper(romprops.mapper_id);
	uart_puthex(romprops.header.map);
	uart_putc(0x30+romprops.mapper_id);

	uint32_t rammask;
	uint32_t rommask;
	
	if(filesize > (romprops.romsize_bytes + romprops.offset)) {
		romprops.romsize_bytes <<= 1;
	}

	if(romprops.header.ramsize == 0) {
		rammask = 0;
	} else {
		rammask = romprops.ramsize_bytes - 1;
	}
	rommask = romprops.romsize_bytes - 1;

	uart_putc(' ');
	uart_puthex(romprops.header.ramsize);
	uart_putc('-');
	uart_puthexlong(rammask);
	uart_putc(' ');
	uart_puthex(romprops.header.romsize);
	uart_putc('-');
	uart_puthexlong(rommask);
	set_saveram_mask(rammask);
	set_rom_mask(rommask);

	return (uint32_t)filesize;
}

uint32_t load_sram(uint8_t* filename, uint32_t base_addr) {
	set_avr_addr(base_addr);
	UINT bytes_read;
	DWORD filesize;
	file_open(filename, FA_READ);
	filesize = file_handle.fsize;
	if(file_res) return 0;
	for(;;) {
//		FPGA_SS_HIGH();
//		SPI_SS_LOW();
		SPI_OFFLOAD=1;
		bytes_read = file_read();
//		SPI_SS_HIGH();
		if (file_res || !bytes_read) break;
//		FPGA_SS_LOW();
/*		spiTransferByte(0x91);
		for(int j=0; j<bytes_read; j++) {
			spiTransferByte(file_buf[j]);
		}
		spiTransferByte(0x00); // dummy tx
		FPGA_SS_HIGH(); // */
	}
	file_close();
	return (uint32_t)filesize;
}


void save_sram(uint8_t* filename, uint32_t sram_size, uint32_t base_addr) {
	uint32_t count = 0;
	uint32_t num = 0;

	spi_none();
	file_open(filename, FA_CREATE_ALWAYS | FA_WRITE);
	if(file_res) {
		uart_putc(0x30+file_res);
	}
	while(count<sram_size) {
		set_avr_addr(base_addr+count);
		spi_fpga();
		spiTransferByte(0x81); // read
		spiTransferByte(0); // dummy
		for(int j=0; j<sizeof(file_buf); j++) {
			file_buf[j] = spiTransferByte(0x00);
			count++;
		}
		spi_none();
		num = file_write();
		if(file_res) {
			uart_putc(0x30+file_res);
		}
	}
	file_close();
}


uint32_t calc_sram_crc(uint32_t base_addr, uint32_t size) {
	uint8_t data;
	uint32_t count;
	uint16_t crc;
	crc=0;
	crc_valid=1;
	set_avr_addr(base_addr);
	spi_fpga();
	spiTransferByte(0x81);
	spiTransferByte(0x00);
	for(count=0; count<size; count++) {
		data = spiTransferByte(0);
		if(get_snes_reset()) {
			crc_valid = 0;
			break;
		}
		crc += crc16_update(crc, &data, 1);
	}
	spi_none();
	return crc;
}

uint8_t sram_reliable() {
	uint16_t score=0;
	uint32_t val;
//	uint32_t val = sram_readlong(SRAM_SCRATCHPAD);
	uint8_t result = 0;
/*	while(score<SRAM_RELIABILITY_SCORE) {
		if(sram_readlong(SRAM_SCRATCHPAD)==val) {
			score++;
		} else {
			set_pwr_led(0);
			score=0;
		}
	}*/
	for(uint16_t i = 0; i < SRAM_RELIABILITY_SCORE; i++) {
		val=sram_readlong(SRAM_SCRATCHPAD);
		if(val==0x12345678) {
			score++;
//		} else {
//			dprintf("i=%d val=%08lX\n", i, val);
		}
	}
	if(score<SRAM_RELIABILITY_SCORE) {
		result = 0;
		dprintf("score=%d\n", score);
	} else {
		result = 1;
	}
	set_pwr_led(result);
	return result;
}

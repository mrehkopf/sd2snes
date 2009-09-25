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

char* hex = "0123456789ABCDEF";

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
	spi_sd();
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
	spi_sd();
}

uint32_t load_rom(char* filename) {
	snes_romprops_t romprops;
	set_avr_bank(0);
	UINT bytes_read;
	DWORD filesize;
	UINT count=0;
	file_open(filename, FA_READ);
	filesize = file_handle.fsize;
	smc_id(&romprops);
	if(file_res) {
		uart_putc('?');
		uart_putc(0x30+file_res);
		return 0;
	}
	f_lseek(&file_handle, romprops.offset);
	for(;;) {
		FPGA_SS_HIGH();
		SPI_SS_LOW();
		bytes_read = file_read();
		SPI_SS_HIGH();
		if (file_res || !bytes_read) break;
		FPGA_SS_LOW();
		spiTransferByte(0x91); // write w/ increment
		if(!(count++ % 16)) {
			toggle_busy_led();
			uart_putc('.');
		}
		for(int j=0; j<bytes_read; j++) {
			spiTransferByte(file_buf[j]);
		}
		spiTransferByte(0x00); // dummy tx for increment+write pulse
		FPGA_SS_HIGH();
	}
	file_close();
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

uint32_t load_sram(char* filename) {
	set_avr_bank(3);
	UINT bytes_read;
	DWORD filesize;
	file_open(filename, FA_READ);
	filesize = file_handle.fsize;
	if(file_res) return 0;
	for(;;) {
		FPGA_SS_HIGH();
		SPI_SS_LOW();
		bytes_read = file_read();
		SPI_SS_HIGH();
		if (file_res || !bytes_read) break;
		FPGA_SS_LOW();
		spiTransferByte(0x91);
		for(int j=0; j<bytes_read; j++) {
			spiTransferByte(file_buf[j]);
		}
		spiTransferByte(0x00); // dummy tx
		FPGA_SS_HIGH();
	}
	file_close();
	return (uint32_t)filesize;
}


void save_sram(char* filename, uint32_t sram_size, uint32_t base_addr) {
    uint32_t count = 0;
	uint32_t num = 0;

	spi_sd();
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
		spi_sd();
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
	set_avr_addr(base_addr);
	SPI_SS_HIGH();
	FPGA_SS_HIGH();
	FPGA_SS_LOW();
	spiTransferByte(0x81);
	spiTransferByte(0x00);
	for(count=0; count<size; count++) {
		data = spiTransferByte(0);
		crc += crc16_update(crc, &data, 1);
	}
	FPGA_SS_HIGH();
	return crc;
}

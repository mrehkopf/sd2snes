// insert cool lenghty disclaimer here
// memory.c: ROM+RAM operations

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

char* hex = "0123456789ABCDEF";

uint32_t load_rom(char* filename) {
// TODO Mapper, Mirroring, Bankselect
//	snes_rom_properties_t romprops;
//	set_avr_bank(0);
	UINT bytes_read;
	DWORD filesize;
	UINT count=0;
	file_open(filename, FA_READ);
	filesize = file_handle.fsize;
	if(file_res) {
		uart_putc('?');
		uart_putc(0x30+file_res);
		return 0;
	}
//	snes_rom_id(&romprops, &file_handle);
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
//			uart_putc((file_buf[j] > 0x20)
//						&& (file_buf[j] < ('z'+1)) ? file_buf[j]:'.');
//			_delay_ms(2);
		}
		spiTransferByte(0x00); // dummy tx for increment+write pulse
		FPGA_SS_HIGH();
	}
	file_close();
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
    }
    file_close();
}


uint32_t calc_sram_crc(uint32_t size) {
	uint8_t data;
	uint32_t count;
	uint16_t crc;
	crc=0;
	set_avr_bank(3);
	SPI_SS_HIGH();
	FPGA_SS_HIGH();
	FPGA_SS_LOW();
	spiTransferByte(0x81);
	spiTransferByte(0x00);
	for(count=0; count<size; count++) {
		data = spiTransferByte(0);
/*		uart_putc(hex[(data>>4)]);
		uart_putc(hex[data&0xf]);
		uart_putc(' ');
		_delay_ms(2);*/
		crc += crc16_update(crc, &data, 1);
	}
	FPGA_SS_HIGH();
/*	uart_putc(hex[(crc>>28)&0xf]);
	uart_putc(hex[(crc>>24)&0xf]);
	uart_putc(hex[(crc>>20)&0xf]);
	uart_putc(hex[(crc>>16)&0xf]); */
	uart_putc(hex[(crc>>12)&0xf]);
	uart_putc(hex[(crc>>8)&0xf]);
	uart_putc(hex[(crc>>4)&0xf]);
	uart_putc(hex[(crc)&0xf]);
	uart_putcrlf();
	return crc;
}

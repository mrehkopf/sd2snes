// insert cool lenghty disclaimer here

// fpga.c: FPGA (re)programming
// XXX TODO move SPI functions to fpga_spi.c!

/*

   FPGA pin mapping
   ================
   PROG_B		PD3		OUT
   CCLK			PD4		OUT
   INIT_B		PD7		IN
   DIN			PC7		OUT
   DONE			PA3		IN
 */

#include <avr/pgmspace.h>
#include <util/delay.h>
#include "fpga.h"
#include "config.h"
#include "uart.h"
#include "sdcard.h"
#include "diskio.h"
#include "integer.h"
#include "ff.h"
#include "fileops.h"
#include "fpga_spi.h"
#include "spi.h"
#include "avrcompat.h"

/*DWORD get_fattime(void) {
	return 0L;
}*/
void set_prog_b(uint8_t val) {
	if(val) {
		PORTD |= _BV(PD3);
	} else {
		PORTD &= ~_BV(PD3);
	}
}

void set_cclk(uint8_t val) {
	if(val) {
		PORTD |= _BV(PD4);
	} else {
		PORTD &= ~_BV(PD4);
	}
}

void fpga_init() {
	DDRD &= ~_BV(PD7);  // PD7 is input

	DDRC = _BV(PC7);	// for FPGA config, PC7 is output

	DDRD |= _BV(PD3) | _BV(PD4); // PD3, PD4 are outputs
	
	DDRA = ~_BV(PA3); // PA3 is input <- DONE

	DDRB |= _BV(PB2); // DMA_CTRL preinit
	PORTB |= _BV(PB2);
	SPI_OFFLOAD=0;
	set_cclk(0);    // initial clk=0
}

int fpga_get_done(void) {
	return PINA & _BV(PA3);
}

void fpga_postinit() {
	DDRA |= _BV(PA0) | _BV(PA1) | _BV(PA2) | _BV(PA4) | _BV(PA5) | _BV(PA6); // MAPPER+NEXTADDR output
	DDRB |= _BV(PB1) | _BV(PB0);	// turn PB2 into output, enable AVR_BANK
	DDRD |= _BV(PD7);	// turn PD7 into output
}

void fpga_pgm(uint8_t* filename) {
	int MAXRETRIES = 10;
	int retries = MAXRETRIES;
	do {
		set_prog_b(0);
		uart_putc('P');
		set_prog_b(1);
		loop_until_bit_is_set(PIND, PD7);
		uart_putc('p');
		
		UINT bytes_read;

		// open configware file
		file_open(filename, FA_READ);
		if(file_res) {
			uart_putc('?');
			uart_putc(0x30+file_res);
			return;
		}
	
		for (;;) {
			bytes_read = file_read();
			if (file_res || bytes_read == 0) break;   // error or eof
			for(int i=0; i<bytes_read; i++) {
				FPGA_SEND_BYTE_SERIAL(file_buf[i]);
			}
		}
		file_close();
		_delay_ms(100);
	} while (!fpga_get_done() && retries--);
	if(!fpga_get_done()) {
		dprintf("FPGA failed to configure after %d tries.\n", MAXRETRIES);
		_delay_ms(50);
	}
	fpga_postinit();
}

void set_avr_ena(uint8_t val) {
	if(val) { // shared mode
		PORTD |= _BV(PD7);
		// Disable SPI double speed mode -> clock = f/4
		SPSR = 0;
		dprintf("SPI slow\n");
	} else { // avr only
		PORTD &= ~_BV(PD7);
		// Enable SPI double speed mode -> clock = f/2
		SPSR = _BV(SPI2X);
		dprintf("SPI fast\n");
	}
}

void set_avr_mapper(uint8_t val) {
	SPI_SS_HIGH();
	FPGA_SS_LOW();
	spiTransferByte(0x30 | (val & 0x0f));
	FPGA_SS_HIGH();
	SPI_SS_LOW();
}

void set_avr_bank(uint8_t val) {
	SPI_SS_HIGH();
	FPGA_SS_LOW();
	spiTransferByte(0x00); // SET ADDRESS
	spiTransferByte(val * 0x20); // select chip
	spiTransferByte(0x00); // select chip
	spiTransferByte(0x00); // select chip
	FPGA_SS_HIGH();
	SPI_SS_LOW();
}

uint8_t fpga_test() {
	spi_fpga();
	spiTransferByte(0xF0); // TEST
	spiTransferByte(0x00); // dummy
	uint8_t result = spiTransferByte(0x00);
	spi_none();
	return result;
}


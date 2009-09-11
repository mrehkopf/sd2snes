// insert cool lenghty disclaimer here

// fpga.c: FPGA (re)programming
// XXX TODO move SPI functions to fpga_spi.c!

/*

   FPGA pin mapping
   ================
 PSM:
 ====
   FPGA			AVR		dir
   ------------------------
   PROG_B		PD3		OUT
   CCLK			PD4		OUT
   CS_B			PD7		OUT
   INIT_B		PB2		IN
   RDWR_B		PB3		OUT

   D7			PC0		OUT
   D6			PC1		OUT
   D5			PC2		OUT
   D4			PC3		OUT
   D3			PC4		OUT
   D2			PC5		OUT
   D1			PC6		OUT
   D0			PC7		OUT

 SSM:
 ====
   PROG_B		PD3		OUT
   CCLK			PD4		OUT
   INIT_B		PD7		IN
   DIN			PC7		OUT
 */

#include <avr/pgmspace.h>
#include "fpga.h"
#include "config.h"
#include "uart.h"
#include "sdcard.h"
#include "diskio.h"
#include "ff.h"
#include "fileops.h"
#include "fpga_spi.h"
#include "spi.h"
#include "avrcompat.h"

DWORD get_fattime(void) {
	return 0L;
}
void set_prog_b(uint8_t val) {
	if(val) {
		PORTD |= _BV(PD3);
	} else {
		PORTD &= ~_BV(PD3);
	}
}

void set_cs_b(uint8_t val) {
	if(val) {
		PORTD |= _BV(PD7);
	} else {
		PORTD &= ~_BV(PD7);
	}
}

void set_rdwr_b(uint8_t val) {
	if(val) {
		PORTB |= _BV(PB3);
	} else {
		PORTB &= ~_BV(PB3);
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
	DDRB |= _BV(PB3);	// PB3 is output

    DDRD &= ~_BV(PD7);  // PD7 is input

    DDRC = _BV(PC7);	// for FPGA config, PC7 is output

	DDRD |= _BV(PD3) | _BV(PD4); // PD3, PD4 are outputs
	set_cclk(0);    // initial clk=0
}

int fpga_get_done(void) {
	return 0;
}

void fpga_postinit() {
	DDRA |= _BV(PA0) | _BV(PA1) | _BV(PA2) | _BV(PA4) | _BV(PA5) | _BV(PA6); // MAPPER+NEXTADDR output
	DDRB |= _BV(PB2) | _BV(PB1) | _BV(PB0);	// turn PB2 into output, enable AVR_BANK
    DDRD |= _BV(PD7);	// turn PD7 into output
}

void fpga_pgm(char* filename) {
	set_prog_b(0);
	uart_putc('P');
	set_prog_b(1);
	loop_until_bit_is_set(PIND, PD7);
	uart_putc('p');
	
//	FIL in;
//	FRESULT res;
	UINT bytes_read;

	// open configware file
//	res=f_open(&in, filename, FA_READ);
	file_open(filename, FA_READ);
	if(file_res) {
		uart_putc('?');
		uart_putc(0x30+file_res);
		return;
	}
	// file open successful
	set_cs_b(0);
	set_rdwr_b(0);

    for (;;) {
//        res = f_read(&in, file_buf, sizeof(file_buf), &bytes_read);
		bytes_read = file_read();
        if (file_res || bytes_read == 0) break;   // error or eof
		for(int i=0; i<bytes_read; i++) {
			//FPGA_SEND_BYTE(file_buf[i]);
			FPGA_SEND_BYTE_SERIAL(file_buf[i]);
		}
    }

	file_close();
	fpga_postinit();
}


void set_avr_read(uint8_t val) {
	if(val) {
		PORTB |= _BV(PB3);
	} else {
		PORTB &= ~_BV(PB3);
	}
}

void set_avr_write(uint8_t val) {
	if(val) {
		PORTB |= _BV(PB2);
	} else {
		PORTB &= ~_BV(PB2);
	}
}

void set_avr_ena(uint8_t val) {
	if(val) {
		PORTD |= _BV(PD7);
	} else {
		PORTD &= ~_BV(PD7);
	}
}

void set_avr_nextaddr(uint8_t val) {
	if(val) {
		PORTA |= _BV(PA4);
	} else {
		PORTA &= ~_BV(PA4);
	}
}

void set_avr_addr_reset(uint8_t val) {
	if(val) {
		PORTA |= _BV(PA5);
	} else {
		PORTA &= ~_BV(PA5);
	}
}

void set_avr_data(uint8_t data) {
	PORTC = data;
}

void set_avr_addr_en(uint8_t val) {
	if(val) {
		PORTA |= _BV(PA6);
	} else {
		PORTA &= ~_BV(PA6);
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

// insert cool lenghty disclaimer here

// fpga.c: FPGA (re)programming

/*

   FPGA pin mapping
   ================

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

 */

#include <avr/pgmspace.h>
#include "fpga.h"
#include "config.h"
#include "uart.h"
#include "sdcard.h"
#include "diskio.h"
#include "ff.h"
#include "fileops.h"

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
    DDRB &= ~_BV(PB2);  // PB2 is input

    DDRC = 0xff;	// for FPGA config, all PORTC pins are outputs

	DDRD |= _BV(PD3) | _BV(PD4) | _BV(PD7); // PD3, PD4, PD7 are outputs

	set_cclk(0);    // initial clk=0
}

int fpga_get_done(void) {
	return 0;
}

void fpga_postinit() {
	DDRA |= _BV(PA0) | _BV(PA1) | _BV(PA2) | _BV(PA4) | _BV(PA5) | _BV(PA6); // MAPPER+NEXTADDR output
	DDRB |= _BV(PB2) | _BV(PB1) | _BV(PB0);	// turn PB2 into output, enable AVR_BANK
}

void fpga_pgm(char* filename) {
	set_prog_b(0);
	uart_putc('P');
	set_prog_b(1);
	loop_until_bit_is_set(PINB, PB2);
	uart_putc('p');
	
	FIL in;
	FRESULT res;
	UINT bytes_read;

	// open configware file
	res=f_open(&in, filename, FA_READ);
	if(res) {
		uart_putc('?');
		return;
	}
	// file open successful
	set_cs_b(0);
	set_rdwr_b(0);

    for (;;) {
        res = f_read(&in, file_buf, sizeof(file_buf), &bytes_read);
        if (res || bytes_read == 0) break;   // error or eof
		for(int i=0; i<bytes_read; i++) {
			FPGA_SEND_BYTE(file_buf[i]);
		}
    }

	f_close(&in);
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
	PORTA &= 0xF0;
	PORTA |= val&0x07;
}

void set_avr_bank(uint8_t val) {
	PORTB &= 0xFC;
	PORTB |= val&0x03;
}

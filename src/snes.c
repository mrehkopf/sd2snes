// insert cool lengthy disclaimer here

// snes.c: SNES hardware control (resetting)

#include <avr/io.h>
#include "avrcompat.h"
#include "config.h"
#include "uart.h"
#include "snes.h"
#include "memory.h"
#include "fileops.h"
#include "ff.h"


uint8_t initloop=1;
uint32_t sram_crc, sram_crc_old;
uint32_t sram_size = 8192; // sane default

void snes_init() {
	DDRD |= _BV(PD5);	// PD5 = RESET_DIR
	DDRD |= _BV(PD6); 	// PD6 = RESET
	snes_reset(1); 
}

/*
 * sets the SNES reset state.
 *
 *  state: put SNES in reset state when 1, release when 0
 */
void snes_reset(int state) {
	if(state) {
		DDRD |= _BV(PD6);	// /RESET pin -> out
		PORTD &= ~_BV(PD6); // /RESET = 0
		PORTD |= _BV(PD5);  // RESET_DIR = 1;
	} else {
		PORTD &= ~_BV(PD5); // RESET_DIR = 0;
		DDRD &= ~_BV(PD6);  // /RESET pin -> in
		PORTD |= _BV(PD6);  // /RESET = 1
	}
}

/*
 * SD2SNES main loop.
 * monitors SRAM changes, menu selections and other things
 */
void snes_main_loop() {
	if(initloop) {
		sram_crc_old = calc_sram_crc(sram_size);
		initloop=0;
	}
	sram_crc = calc_sram_crc(sram_size);
	if(sram_crc != sram_crc_old) {
		uart_putc('U');
		uart_putcrlf();
		save_sram("/test.srm", sram_size);
	}
	sram_crc_old = sram_crc;
	uart_putc('.');
}

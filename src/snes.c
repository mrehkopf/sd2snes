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
#include "led.h"


uint8_t initloop=1;
uint32_t saveram_crc, saveram_crc_old;
uint32_t saveram_size = 8192; // sane default
uint32_t saveram_base_addr = 0x600000; // chip 3
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
		saveram_crc_old = calc_sram_crc(saveram_base_addr, saveram_size);
		save_sram("/quite a long test filename.srm", saveram_size, saveram_base_addr);
		initloop=0;
	}
	saveram_crc = calc_sram_crc(saveram_base_addr, saveram_size);
	if(saveram_crc != saveram_crc_old) {
		uart_putc('U');
		uart_puthexshort(saveram_crc);
		uart_putcrlf();
		set_busy_led(1);
		save_sram("/quite a long test filename.srm", saveram_size, saveram_base_addr);
		set_busy_led(0);
	}
	saveram_crc_old = saveram_crc;
}

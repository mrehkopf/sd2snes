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
		PORTD &= ~_BV(PD6);	// /RESET = 0
		PORTD |= _BV(PD5);	// RESET_DIR = 1;
	} else {
		PORTD &= ~_BV(PD5);	// RESET_DIR = 0;
		DDRD &= ~_BV(PD6);	// /RESET pin -> in
		PORTD |= _BV(PD6);	// /RESET = pullup
	}
}

/*
 * gets the SNES reset state.
 *
 * returns: 1 when reset, 0 when not reset
 */
uint8_t get_snes_reset() {
//	DDRD &= ~_BV(PD6);	// /RESET pin -> in
//	PORTD &= ~_BV(PD5);	// RESET_DIR (external buffer) = 0
	return !(PIND & _BV(PD6));
}

/*
 * SD2SNES main loop.
 * monitors SRAM changes and other things
 */
uint32_t diffcount = 0, samecount = 0;
void snes_main_loop() {
	if(initloop) {
		saveram_crc_old = calc_sram_crc(saveram_base_addr, saveram_size);
		initloop=0;
	}
	saveram_crc = calc_sram_crc(saveram_base_addr, saveram_size);
	if(crc_valid) {
		if(saveram_crc != saveram_crc_old) {
			if(samecount) {
				diffcount=1;
			} else {
				diffcount++;
			}
			samecount=0;
		}
		if(saveram_crc == saveram_crc_old) {
			samecount++;
		}
		if(diffcount>=1 && samecount==3) {
			uart_putc('U');
			uart_puthexshort(saveram_crc);
			uart_putcrlf();
			set_busy_led(1);
			save_sram(file_lfn, saveram_size, saveram_base_addr);
			set_busy_led(0);
		}
		saveram_crc_old = saveram_crc;
	}
	dprintf("valid=%d diffcount=%ld samecount=%ld\n", crc_valid, diffcount, samecount);
}

/*
 * SD2SNES menu loop.
 * monitors menu selection. return when selection was made.
 */
uint8_t menu_main_loop() {
	uint8_t cmd = 0;
	sram_writebyte(0, SRAM_CMD_ADDR);
	while(!cmd) {
		if(!get_snes_reset()) {
			cmd = sram_readbyte(SRAM_CMD_ADDR);
		}
		if(get_snes_reset()) {
			cmd = 0;
		}
	}
	return cmd;
}

void get_selected_name(uint8_t* fn) {
	uint32_t addr = sram_readlong(SRAM_FD_ADDR);
	dprintf("fd addr=%lX\n", addr);
	sram_readblock(fn, addr+0x41, 256);
}

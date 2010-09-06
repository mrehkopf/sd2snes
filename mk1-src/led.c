/* sd2snes - SD card based universal cartridge for the SNES
   Copyright (C) 2009-2010 Maximilian Rehkopf <otakon@gmx.net>
   AVR firmware portion

   Inspired by and based on code from sd2iec, written by Ingo Korb et al.
   See sdcard.c|h, config.h.

   FAT file system access based on code by ChaN, Jim Brain, Ingo Korb,
   see ff.c|h.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License only.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

   led.c: LED control
*/

#include <avr/io.h>
#include <util/delay.h>
#include "config.h"
#include "led.h"

static uint8_t led_bright[16]={255,253,252,251,249,247,244,239,232,223,210,191,165,127,74,0};
static uint8_t curr_bright = 15;
static uint8_t led_bounce_dir = 1;

volatile uint8_t led_state;

void led_panic(void) {
        led_std();

        while(1) {
                set_pwr_led(1);
                set_busy_led(1);
                _delay_ms(150);
                set_pwr_led(0);
                set_busy_led(0);
                _delay_ms(150);
        }

}

void toggle_busy_led(void) {
	PORTB &= ~_BV(PB3);
	DDRB ^= _BV(PB3);
}

void toggle_pwr_led(void) {
	PORTB &= ~_BV(PB0);
	DDRB ^= _BV(PB0);
}

void set_busy_led(uint8_t state) {
	PORTB &= ~_BV(PB3);
	if(state) {
		DDRB |= _BV(PB3);
	} else {
		DDRB &= ~_BV(PB3);
	}
}

void set_pwr_led(uint8_t state) {
	PORTB &= ~_BV(PB0);
	if(state) {
		DDRB |= _BV(PB0);
	} else {
		DDRB &= ~_BV(PB0);
	}
}

void set_busy_pwm(uint8_t brightness) {
	OCR0A = led_bright[brightness];
	set_busy_led(1);
}

void bounce_busy_led() {
	set_busy_pwm(curr_bright);
	if(led_bounce_dir) {
		curr_bright--;
		if(curr_bright==0) {
			led_bounce_dir = 0;
		}
	} else {
		curr_bright++;
		if(curr_bright==15) {
			led_bounce_dir = 1;
		}
	}
}

void led_pwm() {
        set_busy_led(1);
        TCCR0A = 0x83;
        TCCR0B = 0x01;
}

void led_std() {
	set_busy_led(0);
	TCCR0A = 0;
	TCCR0B = 0;
}

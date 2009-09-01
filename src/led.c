/* sd2iec - SD/MMC to Commodore serial bus interface/controller
   Copyright (C) 2007-2009  Ingo Korb <ingo@akana.de>

   Inspiration and low-level SD/MMC access based on code from MMC2IEC
     by Lars Pontoppidan et al., see sdcard.c|h and config.h.

   FAT filesystem access based on code from ChaN and Jim Brain, see ff.c|h.

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


   led.c: Overdesigned LED handling

*/

#include <avr/io.h>
#include "config.h"
#include "led.h"

volatile uint8_t led_state;

/**
 * update_leds - set LEDs to correspond to the buffer status
 *
 * This function sets the busy/dirty LEDs to correspond to the current state
 * of the buffers, i.e. busy on of at least one non-system buffer is
 * allocated and dirty on if at least one buffer is allocated for writing.
 * Call if you have manually changed the LEDs and you want to restore the
 * "default" state.
 */
void update_leds(void) {
}

void toggle_busy_led(void) {
	PORTB &= ~_BV(PB1);
	DDRB ^= _BV(PB1);
}

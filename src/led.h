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


   led.h: Definitions for the LEDs

*/

#ifndef LED_H
#define LED_H

#include "config.h"
#include "uart.h"

/* LED-to-bit mapping - BUSY/DIRTY are only used for SINGLE_LED */
#define LED_ERROR      1
#define LED_BUSY       2
#define LED_DIRTY      4

extern volatile uint8_t led_state;

/* Update the LEDs to match the buffer state */
void update_leds(void);
void toggle_busy_led(void);
void set_busy_led(uint8_t);


#endif

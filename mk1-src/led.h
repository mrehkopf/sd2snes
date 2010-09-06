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
void toggle_busy_led(void);
void toggle_pwr_led(void);
void set_busy_led(uint8_t);
void set_pwr_led(uint8_t);
void set_busy_pwm(uint8_t brightness);
void bounce_busy_led(void);
void led_pwm(void);
void led_std(void);
void led_panic(void);
#endif

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


   config.h: User-configurable options to simplify hardware changes and/or
             reduce the code/ram requirements of the code.


   Based on MMC2IEC, original copyright header follows:

//
// Title        : MMC2IEC - Configuration
// Author       : Lars Pontoppidan
// Date         : Jan. 2007
// Version      : 0.7
// Target MCU   : AtMega32(L) at 8 MHz
//
//
// DISCLAIMER:
// The author is in no way responsible for any problems or damage caused by
// using this code. Use at your own risk.
//
// LICENSE:
// This code is distributed under the GNU Public License
// which can be found at http://www.gnu.org/licenses/gpl.txt
//

*/

#ifndef CONFIG_H
#define CONFIG_H

#include "autoconf.h"

#  define HW_NAME "SD2IEC"
#  define HAVE_SD
#  define SDCARD_DETECT         (!(PIND & _BV(PD2)))
#  define SDCARD_DETECT_SETUP() do { DDRD &= ~_BV(PD2); PORTD |= _BV(PD2); } while(0)
#  if defined __AVR_ATmega32__
#    define SD_CHANGE_SETUP()   do { MCUCR |= _BV(ISC00); GICR |= _BV(INT0); } while(0)
#  elif defined __AVR_ATmega644__ || defined __AVR_ATmega644P__
#    define SD_CHANGE_SETUP()   do { EICRA |= _BV(ISC00); EIMSK |= _BV(INT0); } while(0)
#  else
#    error Unknown chip!
#  endif
#  define SD_CHANGE_VECT        INT0_vect
#  define SDCARD_WP             (PIND & _BV(PD6))
#  define SDCARD_WP_SETUP()     do { DDRD &= ~ _BV(PD6); PORTD |= _BV(PD6); } while(0)
#  define SD_CHANGE_ICR         MCUCR
#  define SD_SUPPLY_VOLTAGE     (1L<<21)
#  define DEVICE_SELECT         (8+!(PINA & _BV(PA2))+2*!(PINA & _BV(PA3)))
#  define DEVICE_SELECT_SETUP() do {        \
             DDRA  &= ~(_BV(PA2)|_BV(PA3)); \
             PORTA |=   _BV(PA2)|_BV(PA3);  \
          } while (0)
#  define BUSY_LED_SETDDR()     DDRA  |= _BV(PA0)
#  define BUSY_LED_ON()         PORTA &= ~_BV(PA0)
#  define BUSY_LED_OFF()        PORTA |= _BV(PA0)
#  define DIRTY_LED_SETDDR()    DDRA  |= _BV(PA1)
#  define DIRTY_LED_ON()        PORTA &= ~_BV(PA1)
#  define DIRTY_LED_OFF()       PORTA |= _BV(PA1)
#  define DIRTY_LED_PORT        PORTA
#  define DIRTY_LED_BIT()       _BV(PA1)
#  define AUX_LED_SETDDR()      do {} while (0)
#  define AUX_LED_ON()          do {} while (0)
#  define AUX_LED_OFF()         do {} while (0)
#  define BUTTON_PIN            PINA
#  define BUTTON_PORT           PORTA
#  define BUTTON_DDR            DDRA
#  define BUTTON_MASK           (_BV(PA4)|_BV(PA5))
#  define BUTTON_NEXT           _BV(PA4)
#  define BUTTON_PREV           _BV(PA5)

/* An interrupt for detecting card changes implies hotplugging capability */
#if defined(SD_CHANGE_VECT) || defined (CF_CHANGE_VECT)
#  define HAVE_HOTPLUG
#endif

/* Generate dummy functions for the BUSY LED if required */
#ifdef SINGLE_LED
#  define BUSY_LED_SETDDR() do {} while(0)
#  define BUSY_LED_ON()     do {} while(0)
#  define BUSY_LED_OFF()    do {} while(0)
#endif

/* Create some temporary symbols so we can calculate the number of */
/* enabled storage devices.                                        */
#ifdef HAVE_SD
#  define TMP_SD 1
#endif

/* Remove the temporary symbols */
#undef TMP_SD

#endif

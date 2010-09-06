/* sd2snes - SD card based universal cartridge for the SNES
   Copyright (C) 2009-2010 Maximilian Rehkopf <otakon@gmx.net>
   This file was adapted from sd2iec, written by Ingo Korb.
   Original copyright header follows:
*/
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


   spi.c: Low level SPI access

   Extended, optimized and cleaned version of code from MMC2IEC,
   original copyright header follows:

//
// Title        : SPI module
// Author       : Lars Pontoppidan
// Date         : January, 2007
// Version      : 1.03
// Target MCU   : Atmel AVR Series
//
// DESCRIPTION:
// This module implements initialization, sending and receiving bytes using
// hardware SPI on an AVR.
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

// FIXME: Integrate into sdcard.c

#include <avr/io.h>
#include "avrcompat.h"
#include "spi.h"

// access routines
void spiInit(void)
{
  volatile uint8_t dummy;

  // setup SPI I/O pins
  SPI_PORT = (SPI_PORT & ~SPI_MASK) | SPI_SCK | SPI_SS | SPI_MISO;
  SPI_DDR  = (SPI_DDR  & ~SPI_MASK) | SPI_SCK | SPI_SS | SPI_MOSI;

  // setup SPI interface:
  //   interrupts disabled, SPI enabled, MSB first, master mode,
  //   leading edge rising, sample on leading edge, clock = f/4
  SPCR = 0b01010000;

  // Enable SPI double speed mode -> clock = f/2
  SPSR = _BV(SPI2X);

  // clear status
  dummy = SPSR;

  // clear receive buffer
  dummy = SPDR;
}


inline uint8_t spiTransferByte(uint8_t data)
{
  // send the given data
  SPDR = data;

  // wait for transfer to complete
  loop_until_bit_is_set(SPSR, SPIF);
  // *** reading of the SPSR and SPDR are crucial
  // *** to the clearing of the SPIF flag
  // *** in non-interrupt mode

  // return the received data
  return SPDR;
}


inline uint32_t spiTransferLong(const uint32_t data)
{
  // It seems to be necessary to use the union in order to get efficient
  // assembler code.
  // Beware, endian unsafe union
  union {
    uint32_t l;
    uint8_t  c[4];
  } long2char;

  long2char.l = data;

  // send the given data
  SPDR = long2char.c[3];
  // wait for transfer to complete
  loop_until_bit_is_set(SPSR, SPIF);
  long2char.c[3] = SPDR;

  SPDR = long2char.c[2];
  // wait for transfer to complete
  loop_until_bit_is_set(SPSR, SPIF);
  long2char.c[2] = SPDR;

  SPDR = long2char.c[1];
  // wait for transfer to complete
  loop_until_bit_is_set(SPSR, SPIF);
  long2char.c[1] = SPDR;

  SPDR = long2char.c[0];
  // wait for transfer to complete
  loop_until_bit_is_set(SPSR, SPIF);
  long2char.c[0] = SPDR;

  return long2char.l;
}

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


   spi.h: Definitions for the low-level SPI routines

   Based on original code by Lars Pontoppidan et al., see spi.c
   for full copyright details.

*/

#ifndef SPI_H
#define SPI_H

// function prototypes

// SPI interface initializer
void spiInit(void);

// spiTransferByte(u08 data) waits until the SPI interface is ready
// and then sends a single byte over the SPI port.  The function also
// returns the byte that was received during transmission.
uint8_t spiTransferByte(uint8_t data);

// spiTransferLong(u08 data) waits until the SPI interface is ready
// and then sends the long with MSB first over the SPI port.
uint32_t spiTransferLong(uint32_t data);

// Macros for setting slave select:
#ifdef CONFIG_TWINSD
# define SPI_SS_HIGH(card) do { \
    if (card == 0) {            \
      SPI_PORT |= SPI_SS;       \
    } else {                    \
      SD2_PORT |= SD2_CS;       \
    }                           \
  } while (0)
#define SPI_SS_LOW(card) do {       \
    if (card == 0) {                \
      SPI_PORT &= (uint8_t)~SPI_SS; \
    } else {                        \
      SD2_PORT &= (uint8_t)~SD2_CS; \
    }                               \
  } while (0)
#else
# define SPI_SS_HIGH(card)  SPI_PORT |= SPI_SS
# define SPI_SS_LOW(card)   SPI_PORT &= (uint8_t)~SPI_SS
#endif

#endif

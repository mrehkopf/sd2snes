/* sd2iec - SD/MMC to Commodore serial bus interface/controller
   Copyright (C) 2007-2010  Ingo Korb <ingo@akana.de>

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

/* Low speed 400kHz for init, fast speed <=20MHz (MMC limit) */
typedef enum { SPI_SPEED_FAST, SPI_SPEED_SLOW } spi_speed_t;

/* Initialize SPI interface */
void spi_init(spi_speed_t speed);

/* Transmit a single byte */
void spi_tx_byte(uint8_t data);

/* Transmit a data block */
void spi_tx_block(const void *data, unsigned int length);

/* Receive a single byte */
uint8_t spi_rx_byte(void);

/* Receive a data block */
void spi_rx_block(void *data, unsigned int length);

/* Switch speed of SPI interface */
void spi_set_speed(spi_speed_t speed);

#endif

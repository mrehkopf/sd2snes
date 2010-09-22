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

   fpga_spi.h: functions for SPI ctrl, SRAM interfacing and feature configuration
*/

#ifndef _FPGA_SPI_H
#define _FPGA_SPI_H

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"

#define FPGA_SS_BIT	16
#define FPGA_SS_REG	LPC_GPIO0

#define FPGA_SELECT()	do {FPGA_TX_SYNC(); BITBAND(FPGA_SS_REG->FIOCLR, FPGA_SS_BIT) = 1;} while (0)
#define FPGA_DESELECT()	do {FPGA_TX_SYNC(); BITBAND(FPGA_SS_REG->FIOSET, FPGA_SS_BIT) = 1;} while (0)

#define FPGA_TX_SYNC()     spi_tx_sync(SPI_FPGA)
#define FPGA_TX_BYTE(x)    spi_tx_byte(x, SPI_FPGA)
#define FPGA_RX_BYTE()     spi_rx_byte(SPI_FPGA)
#define FPGA_TXRX_BYTE(x)  spi_txrx_byte(x, SPI_FPGA)
#define FPGA_TX_BLOCK(x,y) spi_tx_block(x,y,SPI_FPGA)
#define FPGA_RX_BLOCK(x,y) spi_rx_block(x,y,SPI_FPGA)

#define FPGA_SPI_FAST()    spi_set_speed(SPI_SPEED_FPGA_FAST, SPI_FPGA)
#define FPGA_SPI_SLOW()    spi_set_speed(SPI_SPEED_FPGA_SLOW, SPI_FPGA)

void fpga_spi_init(void);
void fpga_spi_test(void);
void spi_fpga(void);
void spi_sd(void);
void spi_none(void);
void set_mcu_addr(uint32_t);
void set_saveram_mask(uint32_t);
void set_rom_mask(uint32_t);
void set_mapper(uint8_t val);

#endif

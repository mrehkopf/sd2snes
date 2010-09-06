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
/*

	SPI commands

	cmd	param		function	
   =============================================
	00	bb[hh[ll]]	set address to 0xbb0000, 0xbbhh00, or 0xbbhhll
	10	bbhhll		set SNES input address mask to 0xbbhhll
	20	bbhhll		set SRAM address mask to 0xbbhhll
	3m	-		set mapper to m
				0=HiROM, 1=LoROM, 2=ExHiROM, 7=Menu
	80	-		read with increment
	81	-		read w/o increment
	90	{xx}*		write xx with increment
	91	{xx}*		write xx w/o increment
	F0	-		receive test token (to see if FPGA is alive)
	
*/

#include <avr/pgmspace.h>
#include <util/delay.h>
#include "avrcompat.h"
#include "fpga.h"
#include "config.h"
#include "uart.h"
#include "spi.h"
#include "fpga_spi.h"

void spi_fpga(void) {
	SPI_SS_HIGH();
	FPGA_SS_LOW();
}

void spi_sd(void) {
	FPGA_SS_HIGH();
	SPI_SS_LOW();
}

void spi_none(void) {
	FPGA_SS_HIGH();
	SPI_SS_HIGH();
}

void fpga_spi_init(void) {
	DDRC = _BV(PC7);
	FPGA_SS_HIGH();
}

void set_avr_addr(uint32_t address) {
	spi_fpga();
	spiTransferByte(0x00);
	spiTransferByte((address>>16)&0xff);
	spiTransferByte((address>>8)&0xff);
	spiTransferByte((address)&0xff);
	spi_none();
}

void set_saveram_mask(uint32_t mask) {
	spi_fpga();
	spiTransferByte(0x20);
	spiTransferByte((mask>>16)&0xff);
	spiTransferByte((mask>>8)&0xff);
	spiTransferByte((mask)&0xff);
	spi_none();
}

void set_rom_mask(uint32_t mask) {
	spi_fpga();
	spiTransferByte(0x10);
	spiTransferByte((mask>>16)&0xff);
	spiTransferByte((mask>>8)&0xff);
	spiTransferByte((mask)&0xff);
	spi_none();
}

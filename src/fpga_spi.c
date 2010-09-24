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

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "fpga.h"
#include "config.h"
#include "uart.h"
#include "spi.h"
#include "fpga_spi.h"
#include "timer.h"

void fpga_spi_init(void) {
  spi_init(SPI_SPEED_FPGA_FAST, SPI_FPGA);
}

void set_mcu_addr(uint32_t address) {
  FPGA_SELECT();
  FPGA_TX_BYTE(0x00);
  FPGA_TX_BYTE((address>>16)&0xff);
  FPGA_TX_BYTE((address>>8)&0xff);
  FPGA_TX_BYTE((address)&0xff);
  FPGA_DESELECT();
}

void set_saveram_mask(uint32_t mask) {
  FPGA_SELECT();
  FPGA_TX_BYTE(0x20);
  FPGA_TX_BYTE((mask>>16)&0xff);
  FPGA_TX_BYTE((mask>>8)&0xff);
  FPGA_TX_BYTE((mask)&0xff);
  FPGA_DESELECT();
}

void set_rom_mask(uint32_t mask) {
  FPGA_SELECT();
  FPGA_TX_BYTE(0x10);
  FPGA_TX_BYTE((mask>>16)&0xff);
  FPGA_TX_BYTE((mask>>8)&0xff);
  FPGA_TX_BYTE((mask)&0xff);
  FPGA_DESELECT();
}

void set_mapper(uint8_t val) {
  FPGA_SELECT();
  FPGA_TX_BYTE(0x30 | (val & 0x0f));
  FPGA_DESELECT();
}

uint8_t fpga_test() {
  FPGA_SELECT();
  FPGA_TX_BYTE(0xF0); /* TEST */
  FPGA_TX_BYTE(0x00); /* dummy */
  uint8_t result = FPGA_RX_BYTE();
  FPGA_DESELECT();
  return result;
}


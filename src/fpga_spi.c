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
	0t	bbhhll		set address to 0xbbhhll
				t = target
				target: 0 = RAM
					1 = MSU Audio buffer
					2 = MSU Data buffer
				targets 1 & 2 only require 2 address bytes to
				be written.

	10	bbhhll		set SNES input address mask to 0xbbhhll
	20	bbhhll		set SRAM address mask to 0xbbhhll

	3m	-		set mapper to m
				0=HiROM, 1=LoROM, 2=ExHiROM, 6=SF96, 7=Menu

	4s	-		trigger SD DMA (512b from SD to memory)
                                s: Bit 2 = partial, Bit 1:0 = target
                                target: see above

	60	sssseeee	set SD DMA partial transfer start+end
				ssss = start offset (msb first)
				eeee = end offset (msb first)
	
	80	-		read with increment (RAM only)
	81	-		read w/o increment (RAM only)

	90	{xx}*		write xx with increment (RAM only)
	91	{xx}*		write xx w/o increment (RAM only)

	E0	ssrr		set MSU-1 status register (=FPGA status byte 2)
				ss = bits to set in status register (1=set)
				rr = bits to reset in status register (1=reset)

	E1	-		pause DAC
	E2	-		resume/play DAC
	E3	-		reset DAC playback pointer (0)
	E4	-		reset MSU read pointer (0)

	F0	-		receive test token (to see if FPGA is alive)
	F1	-		receive status

	F2	-		get MSU data address (32bit, MSB first)
	F3	-		get MSU audio track no. (16bit, MSB first)
	F4	-		get MSU volume (8bit)

	FE	-		get SNES master clock frequency (32bit, MSB first)
	FF	{xx]*		echo (returns the sent data in the next byte)
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
  spi_init(SPI_SPEED_FPGA_FAST);
}

void set_msu_addr(uint16_t address) {
  FPGA_SELECT();
  FPGA_TX_BYTE(0x02);
  FPGA_TX_BYTE((address>>8)&0xff);
  FPGA_TX_BYTE((address)&0xff);
  FPGA_DESELECT();
}

void set_dac_addr(uint16_t address) {
  FPGA_SELECT();
  FPGA_TX_BYTE(0x01);
  FPGA_TX_BYTE((address>>8)&0xff);
  FPGA_TX_BYTE((address)&0xff);
  FPGA_DESELECT();
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

uint16_t fpga_status() {
  FPGA_SELECT();
  FPGA_TX_BYTE(0xF1); /* STATUS */
  FPGA_TX_BYTE(0x00); /* dummy */
  uint16_t result = (FPGA_RX_BYTE()) << 8;
  result |= FPGA_RX_BYTE();
  FPGA_DESELECT();
  return result;
}

void fpga_set_sddma_range(uint16_t start, uint16_t end) {
  FPGA_SELECT();
  FPGA_TX_BYTE(0x60); /* DMA_RANGE */
  FPGA_TX_BYTE(start>>8);
  FPGA_TX_BYTE(start&0xff);
  FPGA_TX_BYTE(end>>8);
  FPGA_TX_BYTE(end&0xff);
//if(tgt==1 && (test=FPGA_RX_BYTE()) != 0x41) printf("!!!!!!!!!!!!!!! -%02x- \n", test);
  FPGA_DESELECT();
}

void fpga_sddma(uint8_t tgt, uint8_t partial) {
  uint32_t test = 0;
  uint8_t status = 0;
  BITBAND(SD_CLKREG->FIODIR, SD_CLKPIN) = 0;
  FPGA_SELECT();
  FPGA_TX_BYTE(0x40 | (tgt & 0x3) | ((partial & 1) << 2) ); /* DO DMA */
  FPGA_TX_BYTE(0x00); /* dummy for falling DMA_EN edge */
//if(tgt==1 && (test=FPGA_RX_BYTE()) != 0x41) printf("!!!!!!!!!!!!!!! -%02x- \n", test);
  FPGA_DESELECT();
  FPGA_SELECT();
  FPGA_TX_BYTE(0xF1); /* STATUS */
  FPGA_TX_BYTE(0x00); /* dummy */
  while((status=FPGA_RX_BYTE()) & 0x80) {
    FPGA_RX_BYTE(); /* eat the 2nd status byte */
    test++;
  }
  FPGA_DESELECT();
  if(test<10)printf("loopy: %ld %02x\n", test, status);
  BITBAND(SD_CLKREG->FIODIR, SD_CLKPIN) = 1;
}

void set_dac_vol(uint8_t volume) {
  FPGA_SELECT();
  FPGA_TX_BYTE(0x50);
  FPGA_TX_BYTE(volume);
  FPGA_TX_BYTE(0x00); /* latch rise */
  FPGA_TX_BYTE(0x00); /* latch fall */
  FPGA_DESELECT();
}

void dac_play() {
  FPGA_SELECT();
  FPGA_TX_BYTE(0xe2);
  FPGA_TX_BYTE(0x00); /* latch reset */
  FPGA_DESELECT();
}

void dac_pause() {
  FPGA_SELECT();
  FPGA_TX_BYTE(0xe1);
  FPGA_TX_BYTE(0x00); /* latch reset */
  FPGA_DESELECT();
}

void dac_reset() {
  FPGA_SELECT();
  FPGA_TX_BYTE(0xe3);
  FPGA_TX_BYTE(0x00); /* latch reset */
  FPGA_TX_BYTE(0x00); /* latch reset */
  FPGA_DESELECT();
}

void msu_reset(uint16_t address) {
  FPGA_SELECT();
  FPGA_TX_BYTE(0xe4);
  FPGA_TX_BYTE((address>>8) & 0xff); /* address hi */
  FPGA_TX_BYTE(address & 0xff);      /* address lo */
  FPGA_TX_BYTE(0x00);                /* latch reset */
  FPGA_TX_BYTE(0x00);                /* latch reset */
  FPGA_DESELECT();
}

void set_msu_status(uint8_t set, uint8_t reset) {
  FPGA_SELECT();
  FPGA_TX_BYTE(0xe0);
  FPGA_TX_BYTE(set);
  FPGA_TX_BYTE(reset);
  FPGA_TX_BYTE(0x00); /* latch reset */
  FPGA_DESELECT();
}

uint8_t get_msu_volume() {
  FPGA_SELECT();
  FPGA_TX_BYTE(0xF4); /* MSU_VOLUME */
  FPGA_TX_BYTE(0x00); /* dummy */
  uint8_t result = FPGA_RX_BYTE();
  FPGA_DESELECT();
  return result;
}

uint16_t get_msu_track() {
  FPGA_SELECT();
  FPGA_TX_BYTE(0xF3); /* MSU_TRACK */
  FPGA_TX_BYTE(0x00); /* dummy */
  uint16_t result = (FPGA_RX_BYTE()) << 8;
  result |= FPGA_RX_BYTE();
  FPGA_DESELECT();
  return result;
}

uint32_t get_msu_offset() {
  FPGA_SELECT();
  FPGA_TX_BYTE(0xF2); /* MSU_OFFSET */
  FPGA_TX_BYTE(0x00); /* dummy */
  uint32_t result = (FPGA_RX_BYTE()) << 24;
  result |= (FPGA_RX_BYTE()) << 16;
  result |= (FPGA_RX_BYTE()) << 8;
  result |= (FPGA_RX_BYTE());
  FPGA_DESELECT();
  return result;
}

uint32_t get_snes_sysclk() {
  FPGA_SELECT();
  FPGA_TX_BYTE(0xFE); /* GET_SYSCLK */
  FPGA_TX_BYTE(0x00); /* dummy */
  FPGA_TX_BYTE(0x00); /* dummy */
  uint32_t result = (FPGA_RX_BYTE()) << 24;
  result |= (FPGA_RX_BYTE()) << 16;
  result |= (FPGA_RX_BYTE()) << 8;
  result |= (FPGA_RX_BYTE());
  FPGA_DESELECT();
  return result;
}

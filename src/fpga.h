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

   fpga.h: FPGA (re)configuration
*/

#ifndef FPGA_H
#define FPGA_H

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"

void fpga_set_prog_b(uint8_t val);
void fpga_set_cclk(uint8_t val);
int fpga_get_initb(void);

void fpga_init(void);
void fpga_postinit(void);
void fpga_pgm(uint8_t* filename);
void fpga_rompgm(void);

uint8_t SPI_OFFLOAD;

const uint8_t *fpga_config;

#define FPGA_CX4 ((const uint8_t*)"/sd2snes/fpga_cx4.bit")
#define FPGA_OBC1 ((const uint8_t*)"/sd2snes/fpga_obc1.bit")
#define FPGA_GSU ((const uint8_t*)"/sd2snes/fpga_gsu.bit")
#define FPGA_SA1 ((const uint8_t*)"/sd2snes/fpga_sa1.bit")
#define FPGA_BASE ((const uint8_t*)"/sd2snes/fpga_base.bit")
#define FPGA_ROM ((const uint8_t*)"rom")

#define CCLKREG  LPC_GPIO0
#define PROGBREG LPC_GPIO1
#define INITBREG LPC_GPIO2
#define DINREG   LPC_GPIO2
#define DONEREG  LPC_GPIO0

#define CCLKBIT  (11)
#define PROGBBIT (15)
#define INITBBIT (9)
#define DINBIT   (8)
#define DONEBIT  (22)


#define FPGA_TEST_TOKEN	(0xa5)

// some macros for bulk transfers (faster)
#define FPGA_SEND_BYTE_SERIAL(data)	do {SET_FPGA_DIN(data>>7); CCLK();\
SET_FPGA_DIN(data>>6); CCLK(); SET_FPGA_DIN(data>>5); CCLK();\
SET_FPGA_DIN(data>>4); CCLK(); SET_FPGA_DIN(data>>3); CCLK();\
SET_FPGA_DIN(data>>2); CCLK(); SET_FPGA_DIN(data>>1); CCLK();\
SET_FPGA_DIN(data); CCLK();} while (0)
#define SET_CCLK()			do {BITBAND(LPC_GPIO0->FIOSET, 11) = 1;} while (0)
#define CLR_CCLK()			do {BITBAND(LPC_GPIO0->FIOCLR, 11) = 1;} while (0)
#define CCLK()				do {SET_CCLK(); CLR_CCLK();} while (0)
#define SET_FPGA_DIN(data)		do {LPC_GPIO2->FIOPIN1 = data;} while (0)
#endif

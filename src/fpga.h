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
#include "config.h"

void fpga_set_prog_b(uint8_t val);
void fpga_set_cclk(uint8_t val);
int fpga_get_initb(void);

void fpga_init(void);
void fpga_postinit(void);
void fpga_pgm(uint8_t* filename);
void fpga_rompgm(void);

uint8_t SPI_OFFLOAD;

const uint8_t *fpga_config;

#define FPGA_CX4 ((const uint8_t*)"/sd2snes/fpga_cx4." FPGA_CONF_EXT)
#define FPGA_OBC1 ((const uint8_t*)"/sd2snes/fpga_obc1." FPGA_CONF_EXT)
#define FPGA_GSU ((const uint8_t*)"/sd2snes/fpga_gsu." FPGA_CONF_EXT)
#define FPGA_SA1 ((const uint8_t*)"/sd2snes/fpga_sa1." FPGA_CONF_EXT)
#define FPGA_SDD1 ((const uint8_t*)"/sd2snes/fpga_sdd1." FPGA_CONF_EXT)
#define FPGA_BASE ((const uint8_t*)"/sd2snes/fpga_base." FPGA_CONF_EXT)
#define FPGA_ROM ((const uint8_t*)"rom")

#define FPGA_TEST_TOKEN	(0xa5)

// some macros for bulk transfers (faster)
#define SET_CCLK()          do {BITBAND(FPGA_CCLKREG->FIOSET, FPGA_CCLKBIT) = 1;} while (0)
#define CLR_CCLK()          do {BITBAND(FPGA_CCLKREG->FIOCLR, FPGA_CCLKBIT) = 1;} while (0)
#define CCLK()              do {SET_CCLK(); CLR_CCLK();} while (0)
#define SET_FPGA_DIN(data)  do {FPGA_DINREG->FIOPIN1 = data;} while (0)
#endif
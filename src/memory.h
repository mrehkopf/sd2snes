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

   memory.h: RAM operations
*/

#ifndef MEMORY_H
#define MEMORY_H

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "smc.h"

#define MENU_ADDR_BRAM_SRC      (0xFF00)

#define SRAM_ROM_ADDR           (0x000000L)
#define SRAM_SAVE_ADDR          (0xE00000L)

#define SRAM_MENU_ADDR          (0xC00000L)
#define SRAM_DIR_ADDR           (0xC10000L)
#define SRAM_DB_ADDR            (0xC80000L)

#define SRAM_NUM_CHEATS         (0xCFFFFEL)
#define SRAM_CHEAT_ADDR         (0xD00000L) /* banks D0-DF for 2048 cheats per YML file */

#define SRAM_SPC_DATA_ADDR      (0xFD0000L)
#define SRAM_SPC_HEADER_ADDR    (0xFE0000L)

#define SRAM_SKIN_ADDR          (0xF00000L)
#define SRAM_MENU_FILEPATH_ADDR (0xFF0000L)
#define SRAM_MENU_CFG_ADDR      (0xFF0100L)
#define SRAM_CMD_ADDR           (0xFF1000L)
#define SRAM_PARAM_ADDR         (0xFF1004L)
#define SRAM_STATUS_ADDR        (0xFF1100L)
#define SRAM_SYSINFO_ADDR       (0xFF1200L)
#define SRAM_LASTGAME_ADDR      (0xFF1420L)
#define SRAM_SCRATCHPAD         (0xFFFF00L)
#define SRAM_DIRID              (0xFFFFF0L)
#define SRAM_RELIABILITY_SCORE  (0x100)

#define LOADROM_WITH_SRAM   (1)
#define LOADROM_WITH_RESET  (2)
#define LOADROM_WAIT_SNES   (4)

#define SAVE_BASEDIR    ("/sd2snes/saves/")

uint32_t load_rom(uint8_t* filename, uint32_t base_addr, uint8_t flags);
uint32_t load_spc(uint8_t* filename, uint32_t spc_data_addr, uint32_t spc_header_addr);
uint32_t migrate_and_load_srm(uint8_t *filename, uint32_t base_addr);
uint32_t load_sram(uint8_t* filename, uint32_t base_addr);
uint32_t load_sram_offload(uint8_t* filename, uint32_t base_addr);
uint32_t load_sram_rle(uint8_t* filename, uint32_t base_addr);
uint32_t load_bootrle(uint32_t base_addr);
void load_dspx(const uint8_t* filename, uint8_t st0010);
void sram_hexdump(uint32_t addr, uint32_t len);
uint8_t sram_readbyte(uint32_t addr);
uint16_t sram_readshort(uint32_t addr);
uint32_t sram_readlong(uint32_t addr);
void sram_writebyte(uint8_t val, uint32_t addr);
void sram_writeshort(uint16_t val, uint32_t addr);
void sram_writelong(uint32_t val, uint32_t addr);
void sram_readblock(void* buf, uint32_t addr, uint16_t size);
uint16_t sram_readstrn(void* buf, uint32_t addr, uint16_t size);
void sram_readlongblock(uint32_t* buf, uint32_t addr, uint16_t count);
void sram_writeblock(void* buf, uint32_t addr, uint16_t size);
void save_srm(uint8_t* filename, uint32_t sram_size, uint32_t base_addr);
void save_sram(uint8_t* filename, uint32_t sram_size, uint32_t base_addr);
uint32_t calc_sram_crc(uint32_t base_addr, uint32_t size);
uint8_t sram_reliable(void);
void sram_memset(uint32_t base_addr, uint32_t len, uint8_t val);

#endif

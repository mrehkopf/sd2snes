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

   sgb.h: SGB file structures
*/

#ifndef SGB_H
#define SGB_H

#define SGBFW   ((const uint8_t*)"/sd2snes/sgb2_boot.bin")
#define SGBSR   ((const uint8_t*)"/sd2snes/sgb2_snes.bin")

typedef struct __attribute__ ((__packed__)) _sgb_header {
  uint8_t entry[4];      /* 0x100 */
  uint8_t logo[48];      /* 0x104 */
  uint8_t name[16];      /* 0x134 */
  uint8_t licensee2[2];  /* 0x144 */
  uint8_t sgb;           /* 0x146 */
  uint8_t carttype;      /* 0x147 */
  uint8_t romsize;       /* 0x148 */
  uint8_t ramsize;       /* 0x149 */
  uint8_t destcode;      /* 0x14A */
  uint8_t licensee;      /* 0x14B */
  uint8_t mask_version;  /* 0x14C */
  uint8_t chk;           /* 0x14D */
  uint8_t gchk[2];       /* 0x14E */
} sgb_header_t;

typedef struct __attribute__ ((__packed__)) _sgb_romprops {
  uint8_t mapper_id;          /* FPGA mapper */
  uint8_t pad1;               /* for alignment */
  uint32_t ramsize_bytes;     /* CartRAM size in bytes */
  uint32_t romsize_bytes;     /* ROM size in bytes (rounded up) */
  const uint8_t* sgb_boot;    /* SGB BOOT ROM filename */
  const uint8_t* fpga_conf;   /* FPGA config file to load (default: base) */
  uint8_t has_sgb;            /* SGB presence flag */
  uint8_t has_rtc;            /* RTC presence flag */
  uint32_t srambase;          /* saveram base address */
  uint32_t sramsize_bytes;    /* saveram size in bytes */
  uint8_t error;              /* error text ID */
  uint8_t* error_param;       /* \0 separated list of parameters for error text */
  sgb_header_t header;        /* original header from ROM image */
} sgb_romprops_t;

enum { SGB_BIOS_CHECK = 0, SGB_BIOS_OK = 1, SGB_BIOS_MISMATCH = 2, SGB_BIOS_MISSING = 3 };

void sgb_id(sgb_romprops_t*, uint8_t *);
uint8_t sgb_update_file(uint8_t **);
uint8_t sgb_update_romprops(snes_romprops_t*, uint8_t *filename);
void sgb_cheat_program(void);
uint8_t sgb_bios_state(void);
void sgb_gtc_load(uint8_t* filename);
void sgb_gtc_save(uint8_t* filename);

#endif

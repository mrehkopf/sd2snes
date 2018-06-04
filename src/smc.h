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

   smc.h: SMC file structures
*/

#ifndef SMC_H
#define SMC_H

#define DSPFW_1 ((const uint8_t*)"/sd2snes/dsp1.bin")
#define DSPFW_2 ((const uint8_t*)"/sd2snes/dsp2.bin")
#define DSPFW_3 ((const uint8_t*)"/sd2snes/dsp3.bin")
#define DSPFW_4 ((const uint8_t*)"/sd2snes/dsp4.bin")
#define DSPFW_1B ((const uint8_t*)"/sd2snes/dsp1b.bin")
#define DSPFW_ST0010 ((const uint8_t*)"/sd2snes/st0010.bin")

typedef struct __attribute__ ((__packed__)) _snes_header {
  uint8_t maker[2];     /* 0xB0 */
  uint8_t gamecode[4];  /* 0xB2 */
  uint8_t fixed_00[7];  /* 0xB6 */
  uint8_t expramsize;   /* 0xBD */
  uint8_t specver;      /* 0xBE */
  uint8_t carttype2;    /* 0xBF */
  uint8_t name[21];     /* 0xC0 */
  uint8_t map;          /* 0xD5 */
  uint8_t carttype;     /* 0xD6 */
  uint8_t romsize;      /* 0xD7 */
  uint8_t ramsize;      /* 0xD8 */
  uint8_t destcode;     /* 0xD9 */
  uint8_t licensee;     /* 0xDA */
  uint8_t ver;          /* 0xDB */
  uint16_t cchk;        /* 0xDC */
  uint16_t chk;         /* 0xDE */
  uint32_t pad1;        /* 0xE0 */
  uint16_t vect_cop16;  /* 0xE4 */
  uint16_t vect_brk16;  /* 0xE6 */
  uint16_t vect_abt16;  /* 0xE8 */
  uint16_t vect_nmi16;  /* 0xEA */
  uint16_t pad2;        /* 0xEC */
  uint16_t vect_irq16;  /* 0xEE */
  uint32_t pad3;        /* 0xF0 */
  uint16_t vect_cop8;   /* 0xF4 */
  uint16_t pad4;        /* 0xF6 */
  uint16_t vect_abt8;   /* 0xF8 */
  uint16_t vect_nmi8;   /* 0xFA */
  uint16_t vect_reset;  /* 0xFC */
  uint16_t vect_brk8;   /* 0xFE */
} snes_header_t;

typedef struct __attribute__ ((__packed__)) _snes_romprops {
  uint16_t offset;            /* start of actual ROM image */
  uint8_t mapper_id;          /* FPGA mapper */
  uint8_t pad1;               /* for alignment */
  uint32_t expramsize_bytes;  /* ExpRAM size in bytes */
  uint32_t ramsize_bytes;     /* CartRAM size in bytes */
  uint32_t romsize_bytes;     /* ROM size in bytes (rounded up) */
  const uint8_t* dsp_fw;      /* DSP (NEC / Hitachi) ROM filename */
  const uint8_t* fpga_conf;   /* FPGA config file to load (default: base) */
  uint8_t has_dspx;           /* DSP[1-4] presence flag */
  uint8_t has_st0010;         /* st0010 presence flag (additional to dspx) */
  uint8_t has_st0011;         /* st0011 presence flag */
  uint8_t has_st0018;         /* st0018 presence flag */
  uint8_t has_msu1;           /* MSU1 presence flag */
  uint8_t has_cx4;            /* CX4 presence flag */
  uint8_t has_obc1;           /* OBC1 presence flag */
  uint8_t has_gsu;            /* GSU presence flag */
  uint8_t has_gsu_sram;       /* GSU saveram presence flag */
  uint8_t has_sa1;            /* SA-1 presence flag */
  uint8_t has_sdd1;           /* S-DD1 presence flag */
  uint8_t has_spc7110;        /* SPC7110 presence flag */
  uint8_t fpga_features;      /* feature/peripheral enable bits */
  uint16_t fpga_dspfeat;      /* DSP configuration bits */
  uint8_t region;             /* game region (derived from destination code) */
  uint32_t load_address;      /* where to load the ROM image */
  uint32_t header_address;    /* location of ROM header in RAM */
  uint8_t error;              /* error text ID */
  uint8_t* error_param;       /* \0 separated list of parameters for error text */
  snes_header_t header;       /* original header from ROM image */
} snes_romprops_t;

void smc_id(snes_romprops_t*);
uint8_t smc_headerscore(uint32_t addr, snes_header_t* header);

#endif

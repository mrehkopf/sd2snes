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

   smc.c: SMC file related operations
*/

#include "fileops.h"
#include "config.h"
#include "uart.h"
#include "smc.h"
#include "string.h"
#include "fpga_spi.h"

snes_romprops_t romprops;

uint32_t hdr_addr[6] = {0xffb0, 0x101b0, 0x7fb0, 0x81b0, 0x40ffb0, 0x4101b0};
uint8_t countAllASCII(uint8_t* data, int size) {
  uint8_t res = 0;
  do {
    size--;
    if(data[size] >= 0x20 && data[size] <= 0x7e) {
      res++;
    }
  } while (size);
  return res;
}

uint8_t countAllJISX0201(uint8_t* data, int size) {
  uint8_t res = 0;
  do {
    size--;
    if((data[size] >= 0x20 && data[size] <= 0x7e)
       ||(data[size] >= 0xa1 && data[size] <= 0xdf)) {
      res++;
    }
  } while (size);
  return res;
}

uint8_t isFixed(uint8_t* data, int size, uint8_t value) {
  uint8_t res = 1;
  do {
    size--;
    if(data[size] != value) {
      res = 0;
    }
  } while (size);
  return res;
}

uint8_t checkChksum(uint16_t cchk, uint16_t chk) {
  uint32_t sum = cchk + chk;
  uint8_t res = 0;
  if(sum==0x0000ffff) {
    res = 0x10;
  }
  return res;
}

void smc_id(snes_romprops_t* props) {
  uint8_t score, maxscore=1, score_idx=2; /* assume LoROM */
  snes_header_t* header = &(props->header);

  props->has_dspx = 0;
  props->has_st0010 = 0;
  props->has_cx4 = 0;
  props->fpga_features = 0;
  props->fpga_conf = NULL;
  for(uint8_t num = 0; num < 6; num++) {
    if(!file_readblock(header, hdr_addr[num], sizeof(snes_header_t))
       || file_res) {
      score = 0;
    } else {
      score = smc_headerscore(header)/(1+(num&1));
      if((file_handle.fsize & 0x2ff) == 0x200) {
        if(num&1) {
          score+=20;
        } else {
          score=0;
        }
      } else {
        if(!(num&1)) {
          score+=20;
        } else {
          score=0;
        }
      }
    }
//printf("%d: offset = %lX; score = %d\n", num, hdr_addr[num], score); // */
    if(score>=maxscore) {
      score_idx=num;
      maxscore=score;
    }
  }

  if(score_idx & 1) {
    props->offset = 0x200;
  } else {
    props->offset = 0;
  }

  /* restore the chosen one */
/*dprintf("winner is %d\n", score_idx); */
  file_readblock(header, hdr_addr[score_idx], sizeof(snes_header_t));

  if(header->name[0x13] == 0x00 || header->name[0x13] == 0xff) {
    if(header->name[0x14] == 0x00) {
      const uint8_t n15 = header->map;
      if(n15 == 0x00 || n15 == 0x80 || n15 == 0x84 || n15 == 0x9c
        || n15 == 0xbc || n15 == 0xfc) {
        if(header->licensee == 0x33 || header->licensee == 0xff) {
          props->mapper_id = 0;
/*XXX do this properly */
          props->ramsize_bytes = 0x8000;
          props->romsize_bytes = 0x100000;
          props->expramsize_bytes = 0;
          props->mapper_id = 3; /* BS-X Memory Map */
          return;
        }
      }
    }
  }
  switch(header->map & 0xef) {

    case 0x21: /* HiROM */
      props->mapper_id = 0;
      if(header->map == 0x31 && (header->carttype == 0x03 || header->carttype == 0x05)) {
        props->has_dspx = 1;
        props->dsp_fw = DSPFW_1B;
        props->fpga_features |= FEAT_DSPX;
      }
      break;

    case 0x20: /* LoROM */
      props->mapper_id = 1;
      if (header->map == 0x20 && header->carttype == 0xf3) {
        props->has_cx4 = 1;
        props->dsp_fw = CX4FW;
        props->fpga_conf = FPGA_CX4;
        props->fpga_features |= FEAT_CX4;
      }
      else if ((header->map == 0x20 && header->carttype == 0x03) ||
          (header->map == 0x30 && header->carttype == 0x05 && header->licensee != 0xb2)) {
        props->has_dspx = 1;
        props->fpga_features |= FEAT_DSPX;
        // Pilotwings uses DSP1 instead of DSP1B
        if(!memcmp(header->name, "PILOTWINGS", 10)) {
          props->dsp_fw = DSPFW_1;
        } else {
          props->dsp_fw = DSPFW_1B;
        }
      } else if (header->map == 0x20 && header->carttype == 0x05) {
        props->has_dspx = 1;
        props->dsp_fw = DSPFW_2;
        props->fpga_features |= FEAT_DSPX;
      } else if (header->map == 0x30 && header->carttype == 0x05 && header->licensee == 0xb2) {
        props->has_dspx = 1;
        props->dsp_fw = DSPFW_3;
        props->fpga_features |= FEAT_DSPX;
      } else if (header->map == 0x30 && header->carttype == 0x03) {
        props->has_dspx = 1;
        props->dsp_fw = DSPFW_4;
        props->fpga_features |= FEAT_DSPX;
      } else if (header->map == 0x30 && header->carttype == 0xf6 && header->romsize >= 0xa) {
        props->has_dspx = 1;
        props->has_st0010 = 1;
        props->dsp_fw = DSPFW_ST0010;
        props->fpga_features |= FEAT_ST0010;
        header->ramsize = 2;
      }
      break;

    case 0x25: /* ExHiROM */
      props->mapper_id = 2;
      break;

    case 0x22: /* ExLoROM */
      if(file_handle.fsize > 0x400200) {
        props->mapper_id = 6; /* SO96 */
      } else {
        props->mapper_id = 1;
      }
      break;

    default: /* invalid/unsupported mapper, use header location */
      switch(score_idx) {
        case 0:
        case 1:
          props->mapper_id = 0;
          break;
        case 2:
        case 3:
          if(file_handle.fsize > 0x800200) {
            props->mapper_id = 6; /* SO96 interleaved */
          } else if(file_handle.fsize > 0x400200) {
            props->mapper_id = 1; /* ExLoROM */
          } else {
            props->mapper_id = 1; /* LoROM */
          }
          break;
        case 4:
        case 5:
          props->mapper_id = 2;
          break;
        default:
          props->mapper_id = 1; // whatever
      }
  }
  if(header->romsize == 0 || header->romsize > 13) {
    header->romsize = 13;
  }
  props->ramsize_bytes = (uint32_t)1024 << header->ramsize;
  props->romsize_bytes = (uint32_t)1024 << header->romsize;
  props->expramsize_bytes = (uint32_t)1024 << header->expramsize;
/*dprintf("ramsize_bytes: %ld\n", props->ramsize_bytes); */
  if(props->ramsize_bytes > 32768 || props->ramsize_bytes < 2048) {
    props->ramsize_bytes = 0;
  }
/*dprintf("ramsize_bytes: %ld\n", props->ramsize_bytes); */
}

uint8_t smc_headerscore(snes_header_t* header) {
  uint8_t score=0;
  score += countAllASCII(header->maker, sizeof(header->maker));
  score += countAllASCII(header->gamecode, sizeof(header->gamecode));
  score += isFixed(header->fixed_00, sizeof(header->fixed_00), 0x00);
  score += countAllJISX0201(header->name, sizeof(header->name));
  score += 3*isFixed(&header->licensee, sizeof(header->licensee), 0x33);
  score += checkChksum(header->cchk, header->chk);
  return score;
}


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
#include "snes.h"
#include "fpga.h"
#include "cfg.h"
#include "memory.h"

extern cfg_t CFG;
snes_romprops_t romprops;

uint32_t hdr_addr[6] = {0xffb0, 0x101b0, 0x7fb0, 0x81b0, 0x40ffb0, 0x4101b0};

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
    res = 1;
  }
  return res;
}

void smc_id(snes_romprops_t* props) {
  uint8_t score, maxscore=1, score_idx=2; /* assume LoROM */
  uint8_t ext_coprocessor=0;
  snes_header_t* header = &(props->header);

  props->load_address = 0;
  props->has_dspx = 0;
  props->has_st0010 = 0;
  props->has_cx4 = 0;
  props->has_obc1 = 0;
  props->has_gsu = 0;
  props->has_sa1 = 0;
  props->has_sdd1 = 0;
  props->srambase = 0;
  props->sramsize_bytes = 0;
  props->fpga_features = 0;
  props->fpga_dspfeat = 0;
  props->fpga_conf = NULL;
  for(uint8_t num = 0; num < 6; num++) {
    score = smc_headerscore(hdr_addr[num], header);
    printf("%d: offset = %lX; score = %d\n", num, hdr_addr[num], score); // */
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
  file_readblock(header, hdr_addr[score_idx], sizeof(snes_header_t));

  if(header->name[0x13] == 0x00 || header->name[0x13] == 0xff) {
    if(header->name[0x14] == 0x00) {
      const uint8_t n15 = header->map;
      if(n15 == 0x00 || n15 == 0x80 || n15 == 0x84 || n15 == 0x8c
        || n15 == 0x9c || n15 == 0xbc || n15 == 0xfc) {
        if(header->licensee == 0x33 || header->licensee == 0xff) {
          props->mapper_id = 0;
/*XXX do this properly */
          props->ramsize_bytes  = 0x8000;
          props->sramsize_bytes = props->ramsize_bytes;
          props->romsize_bytes  = 0x100000;
          props->expramsize_bytes = 0;
          props->mapper_id = 3; /* BS-X Memory Map */
          props->region = 0; /* BS-X only existed in Japan */
          uint8_t alloc = header->name[0x10];
          if(alloc) {
            while(!(alloc & 0x01)) {
              props->load_address += 0x20000;
              alloc >>= 1;
            }
          }
          printf("load address: %lx\n", props->load_address);
          return;
        }
      }
    }
  }

  ext_coprocessor = ((header->carttype & 0xf0) == 0xf0);

  switch(header->map & 0xef) {
    case 0x20: /* LoROM */
      props->mapper_id = 1;
      /* Cx4 LoROM */
      if (header->map == 0x20 && ext_coprocessor && header->carttype2 == 0x10) {
        props->has_cx4 = 1;
        props->fpga_conf = FPGA_CX4;
        props->fpga_dspfeat = CFG.cx4_speed;
      }
      /* DSP1/1B LoROM */
      else if ((header->map == 0x20 && header->carttype == 0x03) ||
          (header->map == 0x30 && header->carttype == 0x05 && header->licensee != 0xb2)) {
        props->has_dspx = 1;
        props->fpga_features |= FEAT_DSPX;
        /* Pilotwings uses DSP1 instead of DSP1B */
        if(!memcmp(header->name, "PILOTWINGS", 10)) {
          props->dsp_fw = DSPFW_1;
        } else {
          props->dsp_fw = DSPFW_1B;
        }
      }
      /* DSP2 LoROM */
      else if (header->map == 0x20 && header->carttype == 0x05) {
        props->has_dspx = 1;
        props->dsp_fw = DSPFW_2;
        props->fpga_features |= FEAT_DSPX;
      }
      /* DSP3 LoROM */
      else if (header->map == 0x30 && header->carttype == 0x05 && header->licensee == 0xb2) {
        props->has_dspx = 1;
        props->dsp_fw = DSPFW_3;
        props->fpga_features |= FEAT_DSPX;
      }
      /* DSP4 LoROM */
      else if (header->map == 0x30 && header->carttype == 0x03) {
        props->has_dspx = 1;
        props->dsp_fw = DSPFW_4;
        props->fpga_features |= FEAT_DSPX;
      }
      /* ST0010 LoROM */
      else if (header->map == 0x30 && header->carttype == 0xf6 && header->romsize >= 0xa) {
        props->has_dspx = 1;
        props->has_st0010 = 1;
        props->dsp_fw = DSPFW_ST0010;
        props->fpga_features |= FEAT_ST0010;
        header->ramsize = 2;
      }
      /* ST0011 LoROM */
      else if (header->map == 0x30 && header->carttype == 0xf6 && header->romsize < 0xa) {
        props->has_st0011 = 1;
        props->error = MENU_ERR_NOIMPL;
        props->error_param = (uint8_t*)"ST0011";
      }
      /* ST0018 LoROM */
      else if (header->map == 0x30 && header->carttype == 0xf5) {
        props->has_st0011 = 1;
        props->error = MENU_ERR_NOIMPL;
        props->error_param = (uint8_t*)"ST0018";
      }
      /* OBC1 LoROM */
      else if (header->map == 0x30 && header->carttype == 0x25) {
        props->has_obc1 = 1;
        props->fpga_conf = FPGA_OBC1;
      }
      /* SuperFX LoROM */
      else if (header->map == 0x20 && ((header->carttype >= 0x13 && header->carttype <= 0x15) ||
          header->carttype == 0x1a)) {
        props->has_gsu = 1;
        props->fpga_conf = FPGA_GSU;
        props->fpga_dspfeat = CFG.gsu_speed;
        header->ramsize = header->expramsize & 0x7;
      }
      break;

    case 0x21: /* HiROM */
      props->mapper_id = 0;
      /* DSP1B HiROM */
      if((header->map & 0xef) == 0x21 && (header->carttype == 0x03 || header->carttype == 0x05)) {
        props->has_dspx = 1;
        props->dsp_fw = DSPFW_1B;
        props->fpga_features |= FEAT_DSPX;
      }
      break;

    case 0x22: /* ExLoROM */
      /* Star Ocean 96MBit */
      if(file_handle.fsize > 0x600200) {
        props->mapper_id = 6;
      }
      /* S-DD1 */
      else if(header->carttype == 0x43 || header->carttype == 0x45) {
        props->mapper_id = 4;
        props->has_sdd1 = 1;
        props->fpga_conf = FPGA_SDD1;
      }
      /* Standard LoROM */
      else {
        props->mapper_id = 1;
      }
      break;

    case 0x23: /* SA1 */
      if(header->carttype == 0x32 || header->carttype == 0x34 || header->carttype == 0x35 || header->carttype == 0x36) {
        props->has_sa1 = 1;
        props->fpga_conf = FPGA_SA1;
      }
      break;

    case 0x25: /* ExHiROM */
      props->mapper_id = 2;
      break;

    case 0x2a: /* SPC7110 */
      if(header->carttype == 0xf5 || header->carttype == 0xf9) {
        props->has_spc7110 = 1;
        props->error = MENU_ERR_NOIMPL;
        props->error_param = (uint8_t*)"SPC7110";
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
          } else {
            props->mapper_id = 1; /* (Ex)LoROM */
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
    props->romsize_bytes = 1024;
    header->romsize = 0;
    if(file_handle.fsize >= 1024) {
      while(props->romsize_bytes < file_handle.fsize-1) {
        header->romsize++;
        props->romsize_bytes <<= 1;
      }
    }
  }
  props->ramsize_bytes = (uint32_t)1024 << header->ramsize;
  props->romsize_bytes = (uint32_t)1024 << header->romsize;
  props->expramsize_bytes = (uint32_t)1024 << header->expramsize;
/*dprintf("ramsize_bytes: %ld\n", props->ramsize_bytes); */
  if(props->ramsize_bytes < 2048) {
    props->ramsize_bytes = 0;
  }
  props->region = (header->destcode <= 1 || header->destcode >= 13) ? 0 : 1;

  // adjust sram size for special cart types
  if (  (props->has_gsu && (header->carttype != 0x15 && header->carttype != 0x1a))
     || (props->has_sa1 && (header->carttype == 0x34)                            )
     ) {
    // no sram in ram
    props->sramsize_bytes = 0;
  }
  else {
    props->sramsize_bytes = props->ramsize_bytes;
  }

  if(header->carttype == 0x55) {
    props->fpga_features |= FEAT_SRTC;
  }

  /* ~12.5MHz for ST0010, 8MHz for DSPx */
  if(props->has_dspx) {
    if(props->has_st0010) {
      props->fpga_dspfeat = 0;
    } else {
      props->fpga_dspfeat = 4; /* 4 extra waitstates */
    }
  }

  props->header_address = hdr_addr[score_idx] - props->offset;
}

uint8_t smc_headerscore(uint32_t addr, snes_header_t* header) {
  int score=0;
  uint8_t reset_inst;
  uint16_t header_offset;
  if((addr & 0xfff) == 0x1b0) {
    header_offset = 0x200;
  } else {
    header_offset = 0;
  }
  if((file_readblock(header, addr, sizeof(snes_header_t)) < sizeof(snes_header_t))
     || file_res) {
    return 0;
  }
  uint8_t mapper = header->map & ~0x10;
  uint8_t bsxmapper = header->ramsize & ~0x10;

  uint16_t resetvector = header->vect_reset; /* not endian safe! */
  uint32_t file_addr = (((addr - header_offset) & ~0x7fff) | (resetvector & 0x7fff)) + header_offset;
  uint8_t bsx_bytecode_adjust = 0;

  if(resetvector < 0x8000) return 0;

  score += 2*isFixed(&header->licensee, sizeof(header->licensee), 0x33);
  score += 4*checkChksum(header->cchk, header->chk);
  if(header->carttype < 0x08) score++;
  if(header->romsize < 0x10) score++;
  if(header->ramsize < 0x08) score++;
  if(header->destcode < 0x0e) score++;
  /* BS-X ROM type / run flags */
  if(!(header->destcode & 0x40) && !(header->destcode & 0xf)) score++;
  /* BS-X bytecode instead of 65c816 binary - vectors will be invalid */
  if(header->gamecode[0] == 0x00 && header->gamecode[1] == 0x01
     && header->gamecode[2] == 0x00 && header->gamecode[3] == 0x00) {
    score++;
    bsx_bytecode_adjust = 2;
  }

  if((addr-header_offset) == 0x007fb0 && (mapper == 0x20 || bsxmapper == 0x20)) score += 2;
  if((addr-header_offset) == 0x00ffb0 && (mapper == 0x21 || bsxmapper == 0x21)) score += 2;
  if((addr-header_offset) == 0x007fb0 && mapper == 0x22) score += 2;
  if((addr-header_offset) == 0x40ffb0 && mapper == 0x25) score += 2;

  file_readblock(&reset_inst, file_addr, 1);
  switch(reset_inst) {
    case 0x78: /* sei */
    case 0x18: /* clc */
    case 0x38: /* sec */
    case 0x9c: /* stz abs */
    case 0x4c: /* jmp abs */
    case 0x5c: /* jml abs */
      score += 8;
      break;

    case 0xc2: /* rep */
    case 0xe2: /* sep */
    case 0xad: /* lda abs */
    case 0xae: /* ldx abs */
    case 0xac: /* ldy abs */
    case 0xaf: /* lda abs long */
    case 0xa9: /* lda imm */
    case 0xa2: /* ldx imm */
    case 0xa0: /* ldy imm */
    case 0x20: /* jsr abs */
    case 0x22: /* jsl abs */
      score += 4;
      break;

    case 0x40: /* rti */
    case 0x60: /* rts */
    case 0x6b: /* rtl */
    case 0xcd: /* cmp abs */
    case 0xec: /* cpx abs */
    case 0xcc: /* cpy abs */
      score -= (4 - bsx_bytecode_adjust);
      break;

    case 0x00: /* brk */
    case 0x02: /* cop */
    case 0xdb: /* stp */
    case 0x42: /* wdm */
    case 0xff: /* sbc abs long indexed */
      score -= (8 - bsx_bytecode_adjust);
      break;
  }

  if(score && addr > 0x400000) score += 4;
  if(score < 0) score = 0;
  return score;
}


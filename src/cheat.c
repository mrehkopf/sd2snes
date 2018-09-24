#include "config.h"
#include "fileops.h"
#include "uart.h"
#include "memory.h"
#include "fpga_spi.h"
#include "snes.h"
#include "cheat.h"
#include "yaml.h"
#include "cfg.h"

#include <string.h>
#include <stdlib.h>

extern cfg_t CFG;
extern snes_romprops_t romprops;

uint8_t rom_index;
uint8_t wram_index;
uint8_t enable_mask;

uint8_t cheat_is_wram_cheat(uint32_t code) {
  return ((code & 0xfe000000) == 0x7e000000)
        || (!(code & 0x40000000)
            && ((code & 0xffff00) < 0x200000));
}

void cheat_init(void) {
  rom_index = 0;
  wram_index = 0;
  enable_mask = 0;
  snescmd_writebyte(ASM_RTS, SNESCMD_WRAM_CHEATS);
}

void cheat_program() {
  cheat_record_t cheat;
  uint32_t cheat_record_addr = SRAM_CHEAT_ADDR;
  int cheat_count;
  int cheat_index;

  cheat_count = sram_readshort(SRAM_NUM_CHEATS);

  printf("cheat_program: %d cheats present\n", cheat_count);
  /* get list of activated cheats from menu */
  cheat_init(); /* reset counters and state */
  for(cheat_index = 0; cheat_index < cheat_count; cheat_index++) {
    sram_readblock(&cheat, cheat_record_addr, sizeof(cheat_record_t));
    if(cheat.flags & CHEAT_FLAG_ENABLE) {
      for(int patch_index = 0; patch_index < cheat.numpatches; patch_index++) {
        cheat_program_single(cheat.patches+patch_index);
      }
    }
    cheat_record_addr += 512;
  }
  /* put number of WRAM cheats + enable flag */
  snescmd_writebyte(wram_index, SNESCMD_NMI_WRAM_PATCH_COUNT);
  printf("enable mask=%02x\n", enable_mask);
  fpga_write_cheat(6, enable_mask);
  cheat_enable(CFG.enable_cheats);
  //cheat_nmi_enable(romprops.has_gsu ? 0 : CFG.enable_irq_hook);
  cheat_nmi_enable(CFG.enable_ingame_hook);
  //cheat_irq_enable(romprops.has_gsu ? 0 : CFG.enable_irq_hook);
  cheat_irq_enable((romprops.has_gsu && !strncmp((char *)romprops.header.name, "DOOM", strlen("DOOM"))) ? 0 : CFG.enable_ingame_hook);
  cheat_holdoff_enable(CFG.enable_hook_holdoff);
  cheat_buttons_enable(CFG.enable_ingame_buttons);
  cheat_wram_present(wram_index);
}

void cheat_program_single(cheat_patch_record_t *cheat) {
  uint8_t is_wram_cheat;
  /* determine ROM or WRAM cheat */
  is_wram_cheat = cheat_is_wram_cheat(cheat->code);
  /* apply cheat to FPGA / NMI hook */
  if(is_wram_cheat) {
    cheat_program_ram_cheat(wram_index++, cheat);
  } else if(rom_index < 6) {
    enable_mask |= (1 << rom_index);
    cheat_program_rom_cheat(rom_index++, cheat);
  }
}

void cheat_program_rom_cheat(int index, cheat_patch_record_t *cheat) {
  uint32_t code = cheat->code;
  printf("ROM cheat #%d: %04lx\n", index, cheat->code);
  fpga_write_cheat(index, code);
}

void cheat_program_ram_cheat(int index, cheat_patch_record_t *cheat) {
  uint16_t address = SNESCMD_WRAM_CHEATS + 6 * index;
  fpga_set_snescmd_addr(address);
  fpga_write_snescmd(ASM_LDA_IMM);
  fpga_write_snescmd(cheat->fields.patchvalue);
  fpga_write_snescmd(ASM_STA_ABSLONG);
  fpga_write_snescmd(cheat->fields.patchaddr & 0xff);
  fpga_write_snescmd(cheat->fields.patchaddr >> 8);
  fpga_write_snescmd(cheat->fields.patchbank);
  fpga_write_snescmd(ASM_RTS);
  printf("RAM cheat #%d: %02x%04x %02x\n", index, cheat->fields.patchbank, cheat->fields.patchaddr, cheat->fields.patchvalue);
}

void cheat_load_to_menu(int index, cheat_record_t *cheat) {
  uint32_t offset = SRAM_CHEAT_ADDR + 512 * index;
  sram_writeblock(cheat, offset, sizeof(cheat_record_t));
  sram_writeblock(cheat->patches, offset+256, cheat->numpatches*4);
}

void cheat_save_from_menu(int index, cheat_record_t *cheat) {
  uint32_t offset = SRAM_CHEAT_ADDR + 512 * index;
  sram_readblock(cheat, offset, sizeof(cheat_record_t)-4);
  sram_readblock(cheat->patches, offset+256, cheat->numpatches*4);
}

void cheat_enable(int enable) {
  uint16_t flags;
  /* switch ROM cheats */
  printf("cheat_enable->%d\n", enable);
  flags = (enable ? 0x0001 : 0x0100);
  fpga_write_cheat(7, flags);
  /* switch WRAM cheats */
  snescmd_writebyte(enable ? 0 : 1, SNESCMD_NMI_DISABLE_WRAM);
}

void cheat_nmi_enable(int enable) {
  uint16_t flags;
  printf("nmi_enable->%d\n", enable);
  flags = (enable ? 0x0002 : 0x0200);
  fpga_write_cheat(7, flags);
}

void cheat_irq_enable(int enable) {
  uint16_t flags;
  printf("irq_enable->%d\n", enable);
  flags = (enable ? 0x0004 : 0x0400);
  fpga_write_cheat(7, flags);
}

void cheat_holdoff_enable(int enable) {
  uint16_t flags;
  printf("holdoff_enable->%d\n", enable);
  flags = (enable ? 0x0008 : 0x0800);
  fpga_write_cheat(7, flags);
}

void cheat_buttons_enable(int enable) {
  uint16_t flags;
  printf("buttons_enable->%d\n", enable);
  flags = (enable ? 0x0010 : 0x1000);
  fpga_write_cheat(7, flags);
}

void cheat_wram_present(int enable) {
  uint16_t flags;
  printf("wram_present->%d\n", enable);
  flags = (enable ? 0x0020 : 0x2000);
  fpga_write_cheat(7, flags);
}

/* read cheats from YAML file to ROM for menu usage */
void cheat_yaml_load(uint8_t* romfilename) {
  yaml_token_t token;
  char line[256] = CHEAT_BASEDIR;
  cheat_record_t cheat;

  append_file_basename(line, (char*)romfilename, ".yml", sizeof(line));
  check_or_create_folder(CHEAT_BASEDIR);
  printf("Cheat YAML file: %s\n", line);
  yaml_file_open(line, FA_READ);
  if(file_res) {
    printf("no cheat list YML found\n");
  }
  /* read cheat entries */
  int cheat_idx = 0;
  while(yaml_next_item()) {
    int i=0;
    if(yaml_get_itemvalue("Name", &token)) {
      strncpy(cheat.description, token.stringvalue, 254);
      cheat.description[253] = 0;
    }
    printf("%s\n", token.stringvalue);
    yaml_get_itemvalue("Enabled", &token);
    cheat.flags = (token.boolvalue ? 0x80 : 0x00);
    printf("  enabled: %d\n", token.boolvalue);
    yaml_get_itemvalue("Code", &token);
    if(token.type == YAML_LIST_START) {
      for(i=0; i < CHEAT_NUM_CODES_PER_CHEAT; i++) {
        if(yaml_get_next(&token) == EOF) break;
        if(token.type == YAML_LIST_END) break;
        cheat.patches[i].code = cheat_str2bin(token.stringvalue);
      }
      cheat.numpatches = i;
    } else if (token.type != YAML_NONE) {
      cheat.patches[0].code = cheat_str2bin(token.stringvalue);
      cheat.numpatches = 1;
    } else {
      /* empty list */
      cheat.numpatches = 0;
    }
    printf("  num codes: %d\n", cheat.numpatches);
    for(i=0; i<cheat.numpatches; i++) {
      printf("  - %08lX\n", cheat.patches[i].code);
    }
    /* a single cheat + codes have been read, put in RAM */
    cheat_load_to_menu(cheat_idx, &cheat);
    cheat_idx++;
  }
  sram_writeshort((uint16_t)cheat_idx, SRAM_NUM_CHEATS);
  yaml_file_close();
  file_res = 0; /* soft fail, suppress LED blink */
  printf("Total number of cheats: %d\n", cheat_idx);
}

/* save cheats to YAML file from ROM/menu */
void cheat_yaml_save(uint8_t *romfilename) {
  cheat_record_t cheat;
  char line[256] = CHEAT_BASEDIR;
  int numcheats = sram_readshort(SRAM_CHEAT_ADDR);

  append_file_basename(line, (char*)romfilename, ".yml", sizeof(line));
  printf("Cheat YAML file: %s\n", line);

  file_open((uint8_t*)line, FA_WRITE | FA_CREATE_ALWAYS);
  f_puts("---\n# Generated by sd2snes\n", &file_handle);
  for(int cheat_idx = 0; cheat_idx < numcheats; cheat_idx++) {
    cheat_save_from_menu(cheat_idx, &cheat);
    f_printf(&file_handle, "- Name: \"%s\"\n", cheat.description);
    f_printf(&file_handle, "  Enabled: %s\n", cheat.flags & CHEAT_FLAG_ENABLE ? "true" : "false");
    f_printf(&file_handle, "  Code:\n");
    for(int i = 0; i < cheat.numpatches; i++) {
      uint32_t gg_code = cheat_raw2gg(cheat.patches[i].code);
      f_printf(&file_handle, "  - \"%08lX\"    ", cheat.patches[i].code);
      if(cheat_is_wram_cheat(cheat.patches[i].code)) {
        f_printf(&file_handle, "# GG code: N/A (WRAM cheat)\n");
      } else {
        f_printf(&file_handle, "# GG code: %04lX-%04lX\n", gg_code >> 16, gg_code & 0xffff);
      }
    }
  }
  file_close();
}

uint32_t cheat_str2bin(char *string) {
  char code[9];
  uint32_t patch;
  if(string[4] == '-') {
    /* GG code */
    printf("GG code: %s\n", string);
    memcpy(code, string, 4);
    strncpy(code+4, string+5, 4);
    code[8] = 0;
    patch = (uint32_t)strtoul(code, NULL, 16);
    patch = cheat_gg2raw(patch);
  } else {
    /* PAR/RAW code */
    patch = (uint32_t)strtoul(string, NULL, 16);
    printf("PAR code: %08lX\n", patch);
  }
  return patch;
}

uint32_t cheat_gg2raw(uint32_t patch) {
  uint8_t gg2raw_tab[16] = {
    0x4, 0x6, 0xd, 0xe,
    0x2, 0x7, 0x8, 0x3,
    0xb, 0x5, 0xc, 0x9,
    0xa, 0x0, 0xf, 0x1
  };
  uint32_t decrypt = 0;
  /* translate nibbles */
  for(int i=0; i<8; i++) {
    decrypt = ((decrypt >> 4) & 0x0fffffff)
            | ((uint32_t)(gg2raw_tab[patch & 0xf]) << 28);
    patch >>= 4;
  }
  /* remap bits: VVVVVVVVAAAABBBBCCDDDDEEEEFFFFGG
              => DDDDFFFFAAAAGGCCBBBBEEEEVVVVVVVV */
  decrypt = ((decrypt & 0xff000000) >> 24)
          |  (decrypt & 0x00f00000)
          | ((decrypt & 0x000f0000) >> 4)
          | ((decrypt & 0x0000c000) << 2)
          | ((decrypt & 0x00003c00) << 18)
          | ((decrypt & 0x000003c0) << 2)
          | ((decrypt & 0x0000003c) << 22)
          | ((decrypt & 0x00000003) << 18);
  return decrypt;
}

uint32_t cheat_raw2gg(uint32_t patch) {
  uint8_t raw2gg_tab[16] = {
    0xd, 0xf, 0x4, 0x7,
    0x0, 0x9, 0x1, 0x5,
    0x6, 0xb, 0xc, 0x8,
    0xa, 0x2, 0x3, 0xe
  };
  uint32_t encrypt = 0;
  /* remap bits: AAAABBBBCCCCDDEEFFFFGGGGVVVVVVVV
              => VVVVVVVVCCCCFFFFEEAAAAGGGGBBBBDD */
  patch = ((patch & 0xf0000000) >> 18)
        | ((patch & 0x0f000000) >> 22)
        |  (patch & 0x00f00000)
        | ((patch & 0x000c0000) >> 18)
        | ((patch & 0x00030000) >> 2)
        | ((patch & 0x0000f000) << 4)
        | ((patch & 0x00000f00) >> 2)
        | ((patch & 0x000000ff) << 24);
  /* translate nibbles */
  for(int i=0; i<8; i++) {
    encrypt = ((encrypt >> 4) & 0x0fffffff)
            | ((uint32_t)(raw2gg_tab[patch & 0xf]) << 28);
    patch >>= 4;
  }
  return encrypt;
}

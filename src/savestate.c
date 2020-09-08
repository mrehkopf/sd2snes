#include "config.h"
#include "fileops.h"
#include "uart.h"
#include "memory.h"
#include "fpga_spi.h"
#include "snes.h"
#include "savestate.h"
#include "yaml.h"
#include "cfg.h"
#include "cheat.h"

#include <string.h>
#include <stdlib.h>

extern cfg_t CFG;
extern cfg_t CFG_DEFAULT;
extern snes_romprops_t romprops;

char * inputs = "BYsSudlrAXLR";

void savestate_program() {
  if(romprops.fpga_conf != NULL) // currently only works with fpga_base
    return;

  sram_writeset(0x0, SS_CODE_ADDR, 0x10000);

  char *savestate_code = "/sd2snes/savestate.bin";
  file_open((uint8_t*) savestate_code, FA_READ);

  fpga_set_snescmd_addr(SNESCMD_EXE);

  if(CFG.enable_ingame_savestate && file_status == FILE_OK) {
    cheat_nmi_enable(0); // disable ingame hooks because it doesn't work with savestates currently
    file_close();

    load_sram((uint8_t*) savestate_code, SS_CODE_ADDR);    
    uint8_t size = sram_readbyte(SS_CODE_ADDR);
    for(uint8_t x = 1; x < size; x++)
      fpga_write_snescmd(sram_readbyte(SS_CODE_ADDR + x));

    sram_writeshort(0x0101, SS_REQ_ADDR);
    sram_writebyte(CFG.loadstate_delay, SS_DELAY_ADDR);
    sram_writebyte(CFG.enable_savestate_slots, SS_SLOTS_ADDR);
    sram_writebyte(CFG.enable_ingame_savestate, SS_CTRL_ADDR);

    savestate_set_inputs();
    savestate_set_fixes();
    load_backup_state();
  } else {
    fpga_write_snescmd(0x00);
    file_close();
  }
}

void savestate_set_inputs() {
  int err = 0;
  char buf[5];
  char * str;
  uint16_t input;
  snprintf(buf, 5, "%04X", romprops.header.chk);

  input = savestate_parse_input(CFG.ingame_savestate_buttons);
  if(input == 0) input = savestate_parse_input(CFG_DEFAULT.ingame_savestate_buttons);
  sram_writeshort(input, SS_SAVE_INPUT_ADDR);

  input = savestate_parse_input(CFG.ingame_loadstate_buttons);
  if(input == 0) input = savestate_parse_input(CFG_DEFAULT.ingame_loadstate_buttons);
  sram_writeshort(input, SS_LOAD_INPUT_ADDR);

  input = savestate_parse_input(CFG.ingame_changestate_buttons);
  if(input == 0) input = savestate_parse_input(CFG_DEFAULT.ingame_changestate_buttons);
  sram_writeshort(input, SS_SLOTS_INPUT_ADDR);
  
  yaml_file_open(SS_INPUTFILE, FA_READ);
  if(file_res) {
    err = file_res;
  }
  if(!err) {
    yaml_token_t tok;
    if(yaml_get_itemvalue(buf, &tok)) { 
      str = strtok(tok.stringvalue, ";, \t");
      input = savestate_parse_input(str);
      if(input > 0) sram_writeshort(input, SS_SAVE_INPUT_ADDR);
      str = strtok(NULL, ";, \t");
      input = savestate_parse_input(str);
      if(input > 0) sram_writeshort(input, SS_LOAD_INPUT_ADDR);
    }
  }
  yaml_file_close();
}


uint16_t savestate_parse_input(char * str) {
  uint16_t input = 0;

  for(uint8_t x=0; x < strlen(str); x++){
    input |= 1 << (0xF - (strchr(inputs, str[x]) - inputs));
  }

  return input;
}

void savestate_set_fixes() {
  int err = 0;
  char buf[8];
  snprintf(buf, 5, "%04X", romprops.header.chk);

  sram_writeshort(0x0000, SS_FIXES_ADDR);
  
  yaml_file_open(SS_FIXESFILE, FA_READ);
  if(file_res) {
    err = file_res;
  }
  if(!err) {
    yaml_token_t tok;
    if(yaml_get_itemvalue(buf, &tok)) { 
      uint16_t src;
      uint32_t dst;

      //checksum
      sram_writeshort(romprops.header.chk, SS_FIXES_ADDR);

      //dst address
      strncpy(buf, tok.stringvalue, 6); buf[6] = '\0';
      dst = strtol(buf, NULL, 16);
      sram_writelong(dst, SS_FIXES_ADDR+2);

      //src offset
      strncpy(buf, strchr(tok.stringvalue, ',')+1, 4); buf[4] = '\0';
      src = strtol(buf, NULL, 16);
      sram_writeshort(src, SS_FIXES_ADDR+6);

      //rompatch
      if(strchr(tok.stringvalue, ';') != NULL){
        strncpy(buf, strchr(tok.stringvalue, ';')+1, 6); buf[6] = '\0';
        dst = strtol(buf, NULL, 16);
        strncpy(buf, strrchr(tok.stringvalue, ',')+1, 2); buf[2] = '\0';
        uint8_t byte = strtol(buf, NULL, 16);
        if(dst > 0){
          sram_writebyte(byte, dst);        
        }
      }
    }
  }
  sram_writeshort(0x0000, SS_FIXES_ADDR+8);
  yaml_file_close();
}

void load_backup_state() {
  uint8_t slot = CFG.enable_savestate_slots ? sram_readbyte(SS_SLOTS_ADDR) : 1;
  char line[256] = SS_BASEDIR;
  check_or_create_folder(SS_BASEDIR);
  cfg_get_last_game(file_lfn, 0);
  append_file_basename(line, (char*)file_lfn, "%02d.state", sizeof(line));
  snprintf(line, 256, line, slot);

  load_sram((uint8_t*) line, 0xF00000L);
  file_res = FR_OK;
}

void save_backup_state() {
  uint8_t slot = CFG.enable_savestate_slots ? sram_readbyte(SS_SLOTS_ADDR) : 1;
  char line[256] = SS_BASEDIR;
  check_or_create_folder(SS_BASEDIR);
  cfg_get_last_game(file_lfn, 0);
  append_file_basename(line, (char*)file_lfn, "%02d.state", sizeof(line));
  snprintf(line, 256, line, slot);

  save_sram((uint8_t*) line, 0x50000L, 0xF00000L);
}
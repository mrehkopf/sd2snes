#include "config.h"
#include "fileops.h"
#include "uart.h"
#include "memory.h"
#include "fpga_spi.h"
#include "snes.h"
#include "savestate.h"
#include "yaml.h"
#include "cfg.h"

#include <string.h>
#include <stdlib.h>

extern cfg_t CFG;
extern snes_romprops_t romprops;


void savestate_program() {
  char *savestate_code = "/sd2snes/savestate.bin";
  file_open((uint8_t*) savestate_code, FA_READ);
  if(!romprops.has_gsu && !romprops.has_sa1 && !romprops.has_cx4 && !romprops.has_sdd1)
  if(CFG.enable_ingame_savestate && file_status == FILE_OK) {
    file_close();
    load_sram((uint8_t*) savestate_code, SS_CODE_ADDR);
    sram_writeshort(0x0101, SS_REQ_ADDR);
    sram_writebyte(CFG.loadstate_delay, SS_DELAY_ADDR);
    sram_writebyte(CFG.enable_savestate_slots, SS_SLOTS_ADDR);
    sram_writebyte(CFG.enable_ingame_savestate, SS_CTRL_ADDR);

    savestate_set_inputs();
    savestate_set_fixes();
    load_backup_state();

    fpga_set_snescmd_addr(SNESCMD_EXE);
    //jml $FC0000
    fpga_write_snescmd(0x5C);
    fpga_write_snescmd(0x00);
    fpga_write_snescmd(0x00);
    fpga_write_snescmd(0xFC);

    //jmp ($FFEA)
    fpga_write_snescmd(0x6C);
    fpga_write_snescmd(0xEA);
    fpga_write_snescmd(0xFF);
    return;
  } 

  fpga_set_snescmd_addr(SNESCMD_EXE);
  fpga_write_snescmd(0x00);
  file_close();
}

void savestate_set_inputs() {
  int err = 0;
  char buf[5];
  snprintf(buf, 5, "%04X", romprops.header.chk);

  sram_writeshort(CFG.ingame_savestate_buttons, SS_SAVE_INPUT_ADDR);
  sram_writeshort(CFG.ingame_loadstate_buttons, SS_LOAD_INPUT_ADDR);
  sram_writeshort(CFG.ingame_changestate_buttons, SS_SLOTS_INPUT_ADDR);
  
  yaml_file_open(SS_INPUTFILE, FA_READ);
  if(file_res) {
    err = file_res;
  }
  if(!err) {
    yaml_token_t tok;
    if(yaml_get_itemvalue(buf, &tok)) { 
      uint16_t input;
      strncpy(buf, tok.stringvalue, 4);
      input = strtol(buf, NULL, 16);
      sram_writeshort(input, SS_SAVE_INPUT_ADDR);
      strncpy(buf, strrchr(tok.stringvalue, ',')+1, 4);
      input = strtol(buf, NULL, 16);
      sram_writeshort(input, SS_LOAD_INPUT_ADDR);
    }
  }
  yaml_file_close();
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
      strncpy(buf, strchr(tok.stringvalue, ';')+1, 6); buf[6] = '\0';
      dst = strtol(buf, NULL, 16);
      strncpy(buf, strrchr(tok.stringvalue, ',')+1, 2); buf[2] = '\0';
      uint8_t byte = strtol(buf, NULL, 16);
      if(dst > 0){
        sram_writebyte(byte, dst);        
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
  if(file_res == FR_NO_FILE) file_res = 0;
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
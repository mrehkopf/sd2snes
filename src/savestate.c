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
extern snes_romprops_t romprops;

char * inputs = "BYsSudlrAXLR";

void savestate_program() {
  if(romprops.fpga_conf != NULL) // currently only works with fpga_base
    return;

/*
 * savestate code is run from bank C0 directly
 * 2C00 hook is now left alone
 */

  if(CFG.enable_ingame_savestate && file_status == FILE_OK) {
    sram_writeshort(0x0101, SS_REQ_ADDR);
    sram_writebyte(CFG.loadstate_delay, SS_DELAY_ADDR);
    sram_writebyte(CFG.enable_savestate_slots, SS_SLOTS_ADDR);
    sram_writebyte(CFG.enable_ingame_savestate, SS_CTRL_ADDR);

    savestate_set_inputs();
    savestate_set_fixes();
    load_backup_state();
  } else {
    /* TODO find a way to disable savestate handler (which are called from in-game hook) */
//    fpga_write_snescmd(0x00);
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
  sram_writeshort(input, SS_SAVE_INPUT_ADDR);

  input = savestate_parse_input(CFG.ingame_loadstate_buttons);
  sram_writeshort(input, SS_LOAD_INPUT_ADDR);

  input = savestate_parse_input(CFG.ingame_changestate_buttons);
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

/* convert a YAML record into binary fix data for the savestate handler.
   XXX Also patches the ROM directly when ROM patch directive found
*/
int savestate_parse_yaml_fix(ssfix_record_t *fix, yaml_token_t *tok) {
  uint32_t dst;
  char *pos;

  //dst address
  pos = tok->stringvalue;
  fix->dst = strtol(pos, &pos, 16);

  //src offset
  if(*pos != ',') {
    /* invalid record */
    return 0;
  }
  pos++; /* skip comma */
  fix->src = strtol(pos, &pos, 16);

  //rompatch
  if(*pos) {
    pos++;
    if(*pos == ';') {
      dst = strtol(pos, &pos, 16);
      if(*pos == ',') {
        pos++;
        uint8_t byte = strtol(pos, &pos, 16);
        if(dst > 0){
          sram_writebyte(byte, dst);
        }
      }
    }
  }
  return 1;
}

/*
  convert savestate fix record into executable code and deploy at addr.
  Returns: number of bytes written
*/
int savestate_write_fix_code(ssfix_record_t *fix, uint32_t addr) {
  int count = 0;
  uint8_t fixcode[10];
  memset(fixcode, 0, sizeof(fixcode));
  if(fix->src >= 0x2140 && fix->src <= 0x2143){
    fixcode[count++] = ASM_LDA_ABSLONG;
    fixcode[count++] = (fix->src >> 0) & 0xff;
    fixcode[count++] = (fix->src >> 8) & 0xff;
    fixcode[count++] = 0;
  } else {
    fixcode[count++] = ASM_LDA_IMM;
    fixcode[count++] = fix->src & 0xff;
  }
  fixcode[count++] = ASM_STA_ABSLONG;
  fixcode[count++] = (fix->dst >>  0) & 0xff;
  fixcode[count++] = (fix->dst >>  8) & 0xff;
  fixcode[count++] = (fix->dst >> 16) & 0xff;

  sram_writeblock(fixcode, addr, count);
  return count;
}

  return input;
}

void savestate_set_fixes() {
  int err = 0;
  char chksum[5];
  uint32_t addr = SS_FIXES_ADDR;
  yaml_token_t tok;
  tok.type = YAML_KEY;
  snprintf(chksum, 5, "%04X", romprops.header.chk);
  yaml_file_open(SS_FIXESFILE, FA_READ);
  if(file_res) {
    err = file_res;
  }
  if(!err) {
    while(yaml_get_value(chksum, &tok, YAML_SCOPE_GLOBAL)) {
      ssfix_record_t fix;
      if(tok.type == YAML_LIST_START) {
        while(yaml_get_next(&tok)) {
          if(tok.type == YAML_LIST_END) break;
            if(savestate_parse_yaml_fix(&fix, &tok)) {
              // printf("Fix record (list/std): tgt=%06lx src=%04x operator=%02x operand=%02x\n", fix.dst, fix.src, fix.operator, fix.operand);
              addr += savestate_write_fix_code(&fix, addr);
            }
          }
      } else {
          if(savestate_parse_yaml_fix(&fix, &tok)) {
            // printf("Fix record (single/std): tgt=%06lx src=%04x operator=%02x operand=%02x\n", fix.dst, fix.src, fix.operator, fix.operand);
            addr += savestate_write_fix_code(&fix, addr);
          }
      }

    }
  }
  sram_writebyte(ASM_RTL, addr);
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
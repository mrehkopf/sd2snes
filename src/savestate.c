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
#include "fpga.h"

#include <string.h>
#include <stdlib.h>

extern cfg_t CFG;
extern snes_romprops_t romprops;

void savestate_program() {
  if(romprops.fpga_conf != NULL
     && romprops.fpga_conf != FPGA_BASE
     /* && romprops.fpga_conf != FPGA_DSP */) {
    savestate_enable_handler(0);
    return;
  }

/*
 * savestate code is run from bank C0 directly
 * 2C00 "EXE" hook is now left alone so it doesn't clash with USB hook features
 */

  savestate_enable_handler(CFG.enable_ingame_savestate);
  if(CFG.enable_ingame_savestate) {
    sram_writeshort(0x0101, SS_REQ_ADDR);
    sram_writebyte(CFG.loadstate_delay, SS_DELAY_ADDR);
    sram_writebyte(CFG.enable_savestate_slots, SS_SLOTS_ADDR);
    sram_writebyte(CFG.enable_ingame_savestate, SS_CTRL_ADDR);
    savestate_set_inputs();
    savestate_set_fixes();
    load_backup_state();
  }
}

void savestate_set_inputs() {
  int err = 0;
  char buf[5];
  char * str;
  uint16_t input;
  snprintf(buf, 5, "%04X", romprops.header.chk);

  input = CFG.ingame_buttons_savestate;
  sram_writeshort(input, SS_SAVE_INPUT_ADDR);

  input = CFG.ingame_buttons_loadstate;
  sram_writeshort(input, SS_LOAD_INPUT_ADDR);

  input = CFG.ingame_buttons_changestate;
  sram_writeshort(input, SS_SLOTS_INPUT_ADDR);

  yaml_file_open(SS_INPUTFILE, FA_READ);
  if(file_res) {
    err = file_res;
  }
  if(!err) {
    yaml_token_t tok;
    if(yaml_get_itemvalue(buf, &tok)) { 
      str = strtok(tok.stringvalue, ";, \t");
      input = cfg_buttons_string2bits(str);
      if(input > 0) sram_writeshort(input, SS_SAVE_INPUT_ADDR);
      str = strtok(NULL, ";, \t");
      input = cfg_buttons_string2bits(str);
      if(input > 0) sram_writeshort(input, SS_LOAD_INPUT_ADDR);
    }
  }
  yaml_file_close();
}

/* convert a YAML record into binary fix data for the savestate handler.
   XXX Also patches the ROM directly when ROM patch directive found
*/
int savestate_parse_yaml_fix(ssfix_record_t *fix, yaml_token_t *tok) {
  fix->operator = SS_OP_NONE;
  fix->operand = 0;
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

  //operation
  if(*pos && *pos != ';' && *pos != ' ') {
    switch(*pos) {
      case '^': // EOR
        fix->operator = SS_OP_EOR;
        break;
      case '&': // AND
        fix->operator = SS_OP_AND;
        break;
      case '|': // OR
        fix->operator = SS_OP_OR;
        break;
      default:
        /* invalid record */
        return 0;
    }
    //operand
    pos++;
    fix->operand = strtol(pos, &pos, 16);
  }

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
  if(fix->operator) {
    fixcode[count++] = fix->operator;
    fixcode[count++] = fix->operand;
  }
  fixcode[count++] = ASM_STA_ABSLONG;
  fixcode[count++] = (fix->dst >>  0) & 0xff;
  fixcode[count++] = (fix->dst >>  8) & 0xff;
  fixcode[count++] = (fix->dst >> 16) & 0xff;

  sram_writeblock(fixcode, addr, count);
  return count;
}

/*
  convert literal savestate code string str into binary and deploy at addr
  Returns: number of bytes written
*/
int savestate_write_fix_literal(char *str, uint32_t addr) {
  int count = 0;
  uint8_t fixcode[64];
  char c, d;
  while((c = *str++) && (count < sizeof(fixcode))) {
    /* skip prefix */
    if(c == '@') continue;
    /* stop on incomplete hex tuple */
    if (!(d = *str++)) break;
    c = (c & 0x40) ? (c & 0x7) + 9 : c & 0xf;
    d = (d & 0x40) ? (d & 0x7) + 9 : d & 0xf;
    fixcode[count++] = (c << 4) | d;
  }
  sram_writeblock(fixcode, addr, count);
  return count;
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
          if(tok.stringvalue[0] == '@') {
            /* code literal */
            // printf("Fix record (list/literal): %s\n", tok.stringvalue);
            addr += savestate_write_fix_literal(tok.stringvalue, addr);
          } else {
            if(savestate_parse_yaml_fix(&fix, &tok)) {
              // printf("Fix record (list/std): tgt=%06lx src=%04x operator=%02x operand=%02x\n", fix.dst, fix.src, fix.operator, fix.operand);
              addr += savestate_write_fix_code(&fix, addr);
            }
          }
        }
      } else {
        if(tok.stringvalue[0] == '@') {
          /* code literal */
          // printf("Fix record (single/literal): %s\n", tok.stringvalue);
          addr += savestate_write_fix_literal(tok.stringvalue, addr);
        } else {
          if(savestate_parse_yaml_fix(&fix, &tok)) {
            // printf("Fix record (single/std): tgt=%06lx src=%04x operator=%02x operand=%02x\n", fix.dst, fix.src, fix.operator, fix.operand);
            addr += savestate_write_fix_code(&fix, addr);
          }
        }
      }

    }
  }
  sram_writebyte(ASM_RTL, addr);
  yaml_file_close();
}

void savestate_enable_handler(int enable) {
  uint16_t flags;
  printf("savestate_enable_handler->%d\n", enable);
  flags = (enable ? 0x0040 : 0x4000);
  fpga_write_cheat(7, flags);
}

void load_backup_state() {
  uint8_t slot = CFG.enable_savestate_slots ? sram_readbyte(SS_SLOTS_ADDR) : 1;
  char line[256] = SS_BASEDIR;
  char extend[10];
  check_or_create_folder(SS_BASEDIR);
  cfg_get_last_game(file_lfn, 0);
  snprintf(extend, sizeof(extend), "%02d.state", slot);
  append_file_basename(line, (char*)file_lfn, extend, sizeof(line));

  load_sram((uint8_t*) line, 0xF00000L);
  file_res = FR_OK;
}

void save_backup_state() {
  uint8_t slot = CFG.enable_savestate_slots ? sram_readbyte(SS_SLOTS_ADDR) : 1;
  char line[256] = SS_BASEDIR;
  char extend[10];
  check_or_create_folder(SS_BASEDIR);
  cfg_get_last_game(file_lfn, 0);
  snprintf(extend, sizeof(extend), "%02d.state", slot);
  append_file_basename(line, (char*)file_lfn, extend, sizeof(line));

  save_sram((uint8_t*) line, 0x50000L, 0xF00000L);
}
#include <string.h>
#include "cfg.h"
#include "config.h"
#include "uart.h"
#include "fileops.h"
#include "memory.h"

cfg_t CFG = {
  .cfg_ver_maj = 1,
  .cfg_ver_min = 1,
  .num_recent_games = 0,
  .vidmode_menu = VIDMODE_AUTO,
  .vidmode_game = VIDMODE_AUTO,
  .pair_mode_allowed = 0,
  .bsx_use_systime = 0,
  .bsx_time = 0x0619970301180530LL,
  .r213f_override = 1
};

int cfg_save() {
  int err = 0;
  file_open(CFG_FILE, FA_CREATE_ALWAYS | FA_WRITE);
  if(file_writeblock(&CFG, 0, sizeof(CFG)) < sizeof(CFG)) {
    err = file_res;
  }
  file_close();
  return err;
}

int cfg_load() {
  int err = 0;
  file_open(CFG_FILE, FA_READ);
  if(file_readblock(&CFG, 0, sizeof(CFG)) < sizeof(CFG)) {
    err = file_res;
  }
  file_close();
  return err;
}

int cfg_add_last_game(uint8_t *fn) {
  int err = 0, index, index2, found = 0, foundindex = 0, written = 0;
  TCHAR fntmp[10][256];
  file_open(LAST_FILE, FA_READ);
  for(index = 0; index < 10; index++) {
    f_gets(fntmp[index], 255, &file_handle);
    if((*fntmp[index] == 0) || (*fntmp[index] == '\n')) {
      break; /* last entry found */
    }
    if(!strncasecmp((TCHAR*)fn, fntmp[index], 255)) {
      found = 1; /* file already in list */
      foundindex = index;
    }
  }
  file_close();
  file_open(LAST_FILE, FA_CREATE_ALWAYS | FA_WRITE);
  /* always put new entry on top of list */
  err = f_puts((const TCHAR*)fn, &file_handle);
  err = f_putc(0, &file_handle);
  written++;
  if(index > 9 + found) index = 9 + found; /* truncate oldest entry */
  /* allow number of destination entries to be the same as source in case
* we're only moving a previous entry to top */
  for(index2 = 0; index2 < index; index2++) {
    if(found && (index2 == foundindex)){
      continue; /* omit found entry here to prevent dupe */
    }
    err = f_puts(fntmp[index2], &file_handle);
    err = f_putc(0, &file_handle);
    written++;
  }
  file_close();
  cfg_set_num_recent_games(written);
  return err;
}

int cfg_get_last_game(uint8_t *fn, uint8_t index) {
  int err = 0;
  file_open(LAST_FILE, FA_READ);
  do {
    f_gets((TCHAR*)fn, 255, &file_handle);
  } while (index--);
  file_close();
  return err;
}

void cfg_dump_recent_games_for_snes(uint32_t address) {
  TCHAR fntmp[256];
  int err = 0, index;
  file_open(LAST_FILE, FA_READ);
  for(index = 0; index < 10 && !err; index++) {
    f_gets(fntmp, 255, &file_handle);
    sram_writeblock(strrchr((const char*)fntmp, '/')+1, address+256*index, 256);
  }
  file_close();
}

void cfg_set_num_recent_games(uint8_t valid) {
  CFG.num_recent_games = valid;
}
uint8_t cfg_get_num_recent_games() {
  return CFG.num_recent_games;
}

void cfg_set_pair_mode_allowed(uint8_t allowed) {
  CFG.pair_mode_allowed = allowed;
}
uint8_t cfg_is_pair_mode_allowed() {
  return CFG.pair_mode_allowed;
}

void cfg_set_r213f_override(uint8_t enable) {
  CFG.r213f_override = enable;
}
uint8_t cfg_is_r213f_override_enabled() {
  return CFG.r213f_override;
}

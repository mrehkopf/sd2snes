#include <string.h>
#include "cfg.h"
#include "config.h"
#include "uart.h"
#include "fileops.h"
#include "memory.h"

cfg_t CFG_DEFAULT = {
  .cfg_ver_maj = 2,
  .cfg_ver_min = 1,
  .num_recent_games = 0,
  .vidmode_menu = VIDMODE_AUTO,
  .vidmode_game = VIDMODE_AUTO,
  .pair_mode_allowed = 0,
  .bsx_use_usertime = 0,
  .bsx_time = 0x0619970301180530LL,
  .r213f_override = 1
};

cfg_t CFG;

int cfg_save() {
  int err = 0;
  file_open(CFG_FILE, FA_CREATE_ALWAYS | FA_WRITE);
  if(file_writeblock(&CFG, 0, sizeof(cfg_t)) < sizeof(cfg_t)) {
    err = file_res;
  }
  file_close();
  return err;
}

int cfg_load() {
  int err = 0;
printf("sizeof cfg_t=%d\n", sizeof(cfg_t));
  file_open(CFG_FILE, FA_READ);
  if(file_res) {
    err = file_res;
  } else if(file_readblock(&CFG, 0, sizeof(cfg_t)) < sizeof(cfg_t)) {
    err = file_res;
  }
  if(CFG.cfg_ver_maj != CFG_DEFAULT.cfg_ver_maj) {
    printf("config version mismatch, loading defaults...\n");
    err = 1;
  }
  if(err) memcpy(&CFG, &CFG_DEFAULT, sizeof(cfg_t));
  file_close();
  return err;
}

int cfg_add_last_game(uint8_t *fn) {
  int err = 0, index, index2, found = 0, foundindex = 0, written = 0;
  TCHAR fqfn[256];
  TCHAR fntmp[10][256];
  file_open(LAST_FILE, FA_READ);
  fqfn[0] = 0;
  if(fn[0] !=  '/') {
    strncpy(fqfn, (const char*)file_path, 256);
  }
  strncat(fqfn, (const char*)fn, 256);
  for(index = 0; index < 10; index++) {
    f_gets(fntmp[index], 255, &file_handle);
    if((*fntmp[index] == 0) || (*fntmp[index] == '\n')) {
      break; /* last entry found */
    }
    if(!strncasecmp((TCHAR*)fqfn, fntmp[index], 255)) {
      found = 1; /* file already in list */
      foundindex = index;
    }
  }
  file_close();
  file_open(LAST_FILE, FA_CREATE_ALWAYS | FA_WRITE);
  /* always put new entry on top of list */
  err = f_puts((const TCHAR*)fqfn, &file_handle);
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

void cfg_set_vidmode_game(cfg_vidmode_t vidmode) {
  CFG.vidmode_game = vidmode;
}

cfg_vidmode_t cfg_get_vidmode_game() {
  return CFG.vidmode_game;
}

void cfg_set_vidmode_menu(cfg_vidmode_t vidmode) {
  CFG.vidmode_menu = vidmode;
}

cfg_vidmode_t cfg_get_vidmode_menu() {
  return CFG.vidmode_menu;
}



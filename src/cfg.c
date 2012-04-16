#include "cfg.h"
#include "config.h"
#include "uart.h"
#include "fileops.h"

cfg_t CFG = {
  .cfg_ver_maj = 1,
  .cfg_ver_min = 0,
  .last_game_valid = 0,
  .vidmode_menu = VIDMODE_AUTO,
  .vidmode_game = VIDMODE_AUTO,
  .pair_mode_allowed = 0,
  .bsx_use_systime = 0,
  .bsx_time = 0x0619970301180530LL
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

int cfg_save_last_game(uint8_t *fn) {
  int err = 0;
  file_open(LAST_FILE, FA_CREATE_ALWAYS | FA_WRITE);
  err = f_puts((const TCHAR*)fn, &file_handle);
  file_close();
  return err;
}

int cfg_get_last_game(uint8_t *fn) {
  int err = 0;
  file_open(LAST_FILE, FA_READ);
  f_gets((TCHAR*)fn, 255, &file_handle);
  file_close();
  return err;
}

void cfg_set_last_game_valid(uint8_t valid) {
  CFG.last_game_valid = valid;
}

uint8_t cfg_is_last_game_valid() {
  return CFG.last_game_valid;
}

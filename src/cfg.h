#ifndef _CFG_H
#define _CFG_H

#include <stdint.h>

#define CFG_FILE ((const uint8_t*)"/sd2snes/sd2snes.cfg")
#define LAST_FILE ((const uint8_t*)"/sd2snes/lastgame.cfg")

typedef enum {
  VIDMODE_AUTO = 0,
  VIDMODE_60,
  VIDMODE_50
} cfg_vidmode_t;

typedef struct _cfg_block {
  uint8_t cfg_ver_maj;
  uint8_t cfg_ver_min;
  uint8_t last_game_valid;
  uint8_t vidmode_menu;
  uint8_t vidmode_game;
  uint8_t pair_mode_allowed;
  uint8_t bsx_use_systime;
  uint64_t bsx_time;
} cfg_t;

int cfg_save(void);
int cfg_load(void);

int cfg_save_last_game(uint8_t *fn);
int cfg_get_last_game(uint8_t *fn);

cfg_vidmode_t cfg_get_vidmode_menu(void);
cfg_vidmode_t cfg_get_vidmode_game(void);

void cfg_set_last_game_valid(uint8_t);
uint8_t cfg_is_last_game_valid(void);
uint8_t cfg_is_pair_mode_allowed(void);

#endif

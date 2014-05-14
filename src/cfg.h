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
  uint8_t cfg_ver_maj;       /* version of config */
  uint8_t cfg_ver_min;
  uint8_t num_recent_games;  /* entries present in history */
  uint8_t vidmode_menu;      /* menu video mode */
  uint8_t vidmode_game;      /* game video mode */
  uint8_t pair_mode_allowed; /* use pair mode if available */
  uint8_t bsx_use_systime;   /* use system time for BS */
  uint64_t bsx_time;         /* user setting for BS time */
  uint8_t r213f_override;    /* override register 213f bit 4 */
} cfg_t;

int cfg_save(void);
int cfg_load(void);

int cfg_add_last_game(uint8_t *fn);
int cfg_get_last_game(uint8_t *fn, uint8_t index);
void cfg_dump_recent_games_for_snes(uint32_t address);

cfg_vidmode_t cfg_get_vidmode_menu(void);
cfg_vidmode_t cfg_get_vidmode_game(void);

void cfg_set_num_recent_games(uint8_t);
uint8_t cfg_get_num_recent_games(void);

void cfg_set_pair_mode_allowed(uint8_t);
uint8_t cfg_is_pair_mode_allowed(void);

void cfg_set_r213f_override(uint8_t);
uint8_t cfg_is_r213f_override_enabled(void);

#endif

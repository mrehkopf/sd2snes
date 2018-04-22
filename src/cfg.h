#ifndef _CFG_H
#define _CFG_H

#include <stdint.h>

#define CFG_FILE ("/sd2snes/config.yml")
#define LAST_FILE ((const uint8_t*)"/sd2snes/lastgame.cfg")
#define LAST_FILE_BAK ((const uint8_t*)"/sd2snes/~lastgame.cfg")

#define CFG_VIDMODE_MENU            ("VideoModeMenu")
#define CFG_VIDMODE_GAME            ("VideoModeGame")
#define CFG_PAIR_MODE_ALLOWED       ("PairModeAllowed")
#define CFG_BSX_USE_USERTIME        ("BSXUseUsertime")
#define CFG_BSX_TIME                ("BSXTime")
#define CFG_R213F_OVERRIDE          ("R213fOverride")
#define CFG_ENABLE_IRQ_HOOK         ("EnableIRQHook")
#define CFG_ENABLE_IRQ_BUTTONS      ("EnableIRQButtons")
#define CFG_ENABLE_IRQ_HOLDOFF      ("EnableIRQHoldoff")
#define CFG_ENABLE_SCREENSAVER      ("EnableScreensaver")
#define CFG_SCREENSAVER_TIMEOUT     ("ScreensaverTimeout")
#define CFG_SORT_DIRECTORIES        ("SortDirectories")
#define CFG_HIDE_EXTENSIONS         ("HideExtensions")
#define CFG_CX4_SPEED               ("Cx4Speed")
#define CFG_SKIN_NAME               ("SkinName")
#define CFG_CONTROL_TYPE            ("ControlType")
#define CFG_MSU_VOLUME_BOOST        ("MSUVolumeBoost")
#define CFG_1CHIP_BRIGHTNESS_PATCH  ("1CHIPBrightnessPatch")

typedef enum {
  VIDMODE_60 = 0,
  VIDMODE_50,
  VIDMODE_AUTO
} cfg_vidmode_t;

typedef struct __attribute__ ((__packed__)) _cfg_block {
  uint8_t vidmode_menu;            /* menu video mode */
  uint8_t vidmode_game;            /* game video mode */
  uint8_t pair_mode_allowed;       /* use pair mode if available */
  uint8_t bsx_use_usertime;        /* use user defined time for BS */
  uint8_t bsx_time[12];            /* user setting for BS time (in S-RTC format)*/
  uint8_t r213f_override;          /* override register 213f bit 4 */
  uint8_t enable_irq_hook;         /* enable hook routines */
  uint8_t enable_irq_buttons;      /* enable in-game buttons in hook routines */
  uint8_t enable_irq_holdoff;      /* enable temp hook disable after reset */
  uint8_t enable_screensaver;      /* enable screen saver */
  uint16_t screensaver_timeout;    /* screensaver activate timeout in frames */
  uint8_t sort_directories;        /* sort directories (slower) (default: on) */
  uint8_t hide_extensions;         /* hide file extensions (default: off) */
  uint8_t cx4_speed;               /* Cx4 speed (0: original, 1: no waitstates */
  uint8_t skin_name[128];          /* file name of selected skin */
  uint8_t control_type;            /* control type (0: A=OK, B=Cancel; 1: A=Cancel, B=OK) */
  uint8_t msu_volume_boost;        /* volume boost (0: none; 1=+3.5dB; 2=+6dB; 3=+9dB; 4=+12dB) */
  uint8_t patch_1chip_brightness;  /* override register 2100 bits 3-0 */
} cfg_t;

int cfg_save(void);
int cfg_load(void);

int cfg_validity_check_recent_games(void);
int cfg_add_last_game(uint8_t *fn);
int cfg_get_last_game(uint8_t *fn, uint8_t index);
void cfg_dump_recent_games_for_snes(uint32_t address);

void cfg_load_to_menu(void);
void cfg_get_from_menu(void);

void cfg_set_vidmode_menu(cfg_vidmode_t vidmode);
cfg_vidmode_t cfg_get_vidmode_menu(void);

void cfg_set_vidmode_game(cfg_vidmode_t vidmode);
cfg_vidmode_t cfg_get_vidmode_game(void);

void cfg_set_num_recent_games(uint8_t);
uint8_t cfg_get_num_recent_games(void);

void cfg_set_pair_mode_allowed(uint8_t);
uint8_t cfg_is_pair_mode_allowed(void);

void cfg_set_r213f_override(uint8_t);
uint8_t cfg_is_r213f_override_enabled(void);

void cfg_set_patch_1chip_brightness(uint8_t);
uint8_t cfg_is_patch_1chip_brightness(void);
#endif

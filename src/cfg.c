#include <string.h>
#include <stdlib.h>

#include "cfg.h"
#include "config.h"
#include "uart.h"
#include "fileops.h"
#include "memory.h"
#include "yaml.h"
#include "rtc.h"
#include "snes.h"

cfg_t CFG_DEFAULT = {
  .vidmode_menu = VIDMODE_60,
  .vidmode_game = VIDMODE_AUTO,
  .pair_mode_allowed = 0,
  .bsx_use_usertime = 0,
  .bsx_time = {0x0, 0x3, 0x5, 0x0, 0x8, 0x1, 0x1, 0x0, 0x3, 0x7, 0x9, 0x9},
  .r213f_override = 1,
  .enable_ingame_hook = 0,
  .enable_ingame_buttons = 1,
  .enable_hook_holdoff = 1,
  .enable_screensaver = 1,
  .screensaver_timeout = 600,
  .sort_directories = 1,
  .hide_extensions = 0,
  .cx4_speed = 0,
  .skin_name = "sd2snes.skin",
  .control_type = 0,
  .msu_volume_boost = 0,
  .onechip_transient_fixes = 0,
  .brightness_limit = 15,
  .gsu_speed = 0,
  .reset_to_menu = 0,
  .led_brightness = 15,
  .enable_cheats = 1,
  .reset_patch = 0,
  .enable_ingame_savestate = 0,
  .loadstate_delay = 10,
  .enable_savestate_slots = 1,
  .ingame_savestate_buttons = "SL",
  .ingame_loadstate_buttons = "SR",
  .ingame_changestate_buttons = "s",
  .sgb_enable_ingame_hook = 0,
  .sgb_enable_state = 0,
  .sgb_volume_boost = 0,
  .sgb_enh_override = 0,
  .sgb_clock_fix = 1,
  .sgb_bios_version = 2
};

cfg_t CFG;
extern mcu_status_t STM;

int cfg_save() {
  int err = 0;
  uint64_t bcdtime = srtctime2bcdtime(CFG.bsx_time);
  file_open((uint8_t*)CFG_FILE, FA_CREATE_ALWAYS | FA_WRITE);
  f_puts("---\n", &file_handle);
  f_puts("##############################\n", &file_handle);
  f_puts("# sd2snes configuration file #\n", &file_handle);
  f_puts("##############################\n\n", &file_handle);
  f_puts("# Allow SuperCIC Pair Mode (required for video mode setting)\n", &file_handle);
  f_printf(&file_handle, "%s: %s\n", CFG_PAIR_MODE_ALLOWED, CFG.pair_mode_allowed ? "true" : "false");
  f_printf(&file_handle, "\n# Video mode (%d = 60Hz, %d = 50Hz, %d = Auto (game only))\n", VIDMODE_60, VIDMODE_50, VIDMODE_AUTO);
  f_printf(&file_handle, "%s: %d\n", CFG_VIDMODE_MENU, CFG.vidmode_menu);
  f_printf(&file_handle, "%s: %d\n", CFG_VIDMODE_GAME, CFG.vidmode_game);
  f_printf(&file_handle, "\n# Satellaview Settings\n#  %s: use user defined time instead of real time\n", CFG_BSX_USE_USERTIME);
  f_printf(&file_handle, "#  %s: user defined Satellaview broadcast time (format: YYYYMMDDhhmmss)\n", CFG_BSX_TIME);
  f_printf(&file_handle, "%s: %s\n", CFG_BSX_USE_USERTIME, CFG.bsx_use_usertime ? "true" : "false");
  f_printf(&file_handle, "%s: %06lX%08lX\n", CFG_BSX_TIME, (uint32_t)(bcdtime>>32), (uint32_t)(bcdtime & 0xffffffffLL));
  f_puts("\n# Enable PPU region flag patching\n", &file_handle);
  f_printf(&file_handle, "%s: %s\n", CFG_R213F_OVERRIDE, CFG.r213f_override ? "true" : "false");
  f_puts("\n# Enable 1CHIP transient fixes (experimental) - Fix some 1CHIP related graphical issues\n", &file_handle);
  f_printf(&file_handle, "%s: %s\n", CFG_1CHIP_TRANSIENT_FIXES, CFG.onechip_transient_fixes ? "true" : "false");
  f_puts("\n# Brightness limit - can be used to limit RGB output levels on S-CPUN based consoles\n", &file_handle);
  f_printf(&file_handle, "%s: %d\n", CFG_BRIGHTNESS_LIMIT, CFG.brightness_limit);
  f_puts("\n# Reset to menu on short reset\n", &file_handle);
  f_printf(&file_handle, "%s: %s\n", CFG_ENABLE_RST_TO_MENU, CFG.reset_to_menu ? "true" : "false");
  f_puts("\n# Initial cheats state when loading a game (true: enabled, false: disabled)\n", &file_handle);
  f_printf(&file_handle, "%s: %s\n", CFG_ENABLE_CHEATS, CFG.enable_cheats ? "true" : "false");
  f_puts("\n\n# IRQ hook related settings\n", &file_handle);
  f_printf(&file_handle, "#  %s: Overall enable IRQ hooks (required for in-game buttons & WRAM cheats)\n", CFG_ENABLE_INGAME_HOOK);
  f_printf(&file_handle, "%s: %s\n", CFG_ENABLE_INGAME_HOOK, CFG.enable_ingame_hook ? "true" : "false");
  f_printf(&file_handle, "#  %s: Enable in-game buttons (en/disable cheats, reset sd2snes...)\n", CFG_ENABLE_INGAME_BUTTONS);
  f_printf(&file_handle, "%s: %s\n", CFG_ENABLE_INGAME_BUTTONS, CFG.enable_ingame_buttons ? "true" : "false");
  f_printf(&file_handle, "#  %s: Enable 10s grace period after reset before enabling in-game hooks\n", CFG_ENABLE_HOOK_HOLDOFF);
  f_printf(&file_handle, "%s: %s\n", CFG_ENABLE_HOOK_HOLDOFF, CFG.enable_hook_holdoff ? "true" : "false");
  f_printf(&file_handle, "%s: %s\n", CFG_RESET_PATCH, CFG.reset_patch ? "true" : "false");
  f_puts("\n", &file_handle);
  f_printf(&file_handle, "#  %s: Enable in-game savestate\n", CFG_ENABLE_INGAME_SAVESTATE);
  f_printf(&file_handle, "%s: %d\n", CFG_ENABLE_INGAME_SAVESTATE, CFG.enable_ingame_savestate);
  f_printf(&file_handle, "#  %s: Load state delay (frames),\n", CFG_LOADSTATE_DELAY);
  f_printf(&file_handle, "%s: %d\n", CFG_LOADSTATE_DELAY, CFG.loadstate_delay);
  f_printf(&file_handle, "#  %s: Enable in-game savestate (0: disabled, 1: enabled)\n", CFG_ENABLE_INGAME_SAVESTATE);
  f_printf(&file_handle, "%s: %s\n", CFG_ENABLE_SAVESTATE_SLOTS, CFG.enable_savestate_slots ? "true" : "false");
  f_printf(&file_handle, "#  %s: In-game save state buttons (buttons: BYsSudlrAXLR, default: start+l),\n", CFG_INGAME_SAVESTATE_BUTTONS);
  f_printf(&file_handle, "%s: %s\n", CFG_INGAME_SAVESTATE_BUTTONS, CFG.ingame_savestate_buttons);
  f_printf(&file_handle, "#  %s: In-game load state buttons (buttons: BYsSudlrAXLR, default: start+r),\n", CFG_INGAME_LOADSTATE_BUTTONS);
  f_printf(&file_handle, "%s: %s\n", CFG_INGAME_LOADSTATE_BUTTONS, CFG.ingame_loadstate_buttons);
  f_printf(&file_handle, "#  %s: In-game change state slot buttons (buttons: BYsSudlrAXLR, don't use dpad buttons, default: select),\n", CFG_INGAME_CHANGESTATE_BUTTONS);
  f_printf(&file_handle, "%s: %s\n", CFG_INGAME_CHANGESTATE_BUTTONS, CFG.ingame_changestate_buttons);
  f_puts("\n", &file_handle);
  f_printf(&file_handle, "#  %s: SGB enable hooks (%s or %s enables SGB hooks.  zero overhead.)\n", CFG_SGB_ENABLE_INGAME_HOOK, CFG_SGB_ENABLE_INGAME_HOOK, CFG_ENABLE_INGAME_HOOK);
  f_printf(&file_handle, "%s: %s\n", CFG_SGB_ENABLE_INGAME_HOOK, CFG.sgb_enable_ingame_hook ? "true" : "false");
  f_printf(&file_handle, "#  %s: SGB enable save states (only works with ingame hooks when supported boot and bios/snes is used)\n", CFG_SGB_ENABLE_STATE);
  f_printf(&file_handle, "%s: %s\n", CFG_SGB_ENABLE_STATE, CFG.sgb_enable_state ? "true" : "false");
  f_printf(&file_handle, "#  %s: SGB audio volume boost\n#    (0: none; 1: +3.5dBFS; 2: +6dBFS; 3: +9.5dBFS; 4: +12dBFS)\n", CFG_SGB_VOLUME_BOOST);
  f_printf(&file_handle, "%s: %d\n", CFG_SGB_VOLUME_BOOST, CFG.sgb_volume_boost);
  f_printf(&file_handle, "#  %s: SGB enhancements override (false: enhancements enabled; true: enhancements disabled)\n", CFG_SGB_ENH_OVERRIDE);
  f_printf(&file_handle, "%s: %s\n", CFG_SGB_ENH_OVERRIDE, CFG.sgb_enh_override ? "true" : "false");
#ifdef CONFIG_MK3
  f_printf(&file_handle, "#  %s: SGB sprite increase per scanline.  not compatible with all games  (false: 10 sprites (default); true: 16 sprites)\n", CFG_SGB_SPR_INCREASE);
  f_printf(&file_handle, "%s: %s\n", CFG_SGB_SPR_INCREASE, CFG.sgb_spr_increase ? "true" : "false");
#endif
  f_printf(&file_handle, "#  %s: SGB timing/clock (true: original/sgb2, false: snes/sgb1)\n", CFG_SGB_CLOCK_FIX);
  f_printf(&file_handle, "%s: %s\n", CFG_SGB_CLOCK_FIX, CFG.sgb_clock_fix ? "true" : "false");
  f_printf(&file_handle, "#  %s: SGB bios firmware version (defined number loads: sgbX_boot.bin and sgbX_snes.bin)\n", CFG_SGB_BIOS_VERSION);
  f_printf(&file_handle, "%s: %d\n", CFG_SGB_BIOS_VERSION, CFG.sgb_bios_version);

  f_puts("\n# Screensaver settings\n", &file_handle);
  f_printf(&file_handle, "#  %s: Enable screensaver\n", CFG_ENABLE_SCREENSAVER);
//  f_printf(&file_handle, "#  %s: Dim screen after n seconds\n", CFG_SCREENSAVER_TIMEOUT);
  f_printf(&file_handle, "%s: %s\n", CFG_ENABLE_SCREENSAVER, CFG.enable_screensaver ? "true" : "false");
//  f_printf(&file_handle, "%s: %d\n", CFG_SCREENSAVER_TIMEOUT, CFG.screensaver_timeout);
  f_puts("\n# UI related settings\n", &file_handle);
  f_printf(&file_handle, "#  %s: Sort directories (slower but files are guaranteed to be in order)\n", CFG_SORT_DIRECTORIES);
  f_printf(&file_handle, "#  %s: Hide file extensions\n", CFG_HIDE_EXTENSIONS);
  f_printf(&file_handle, "#  %s: LED brightness (0: minimum, 15: maximum)\n", CFG_LED_BRIGHTNESS);
  f_printf(&file_handle, "%s: %s\n", CFG_SORT_DIRECTORIES, CFG.sort_directories ? "true" : "false");
  f_printf(&file_handle, "%s: %s\n", CFG_HIDE_EXTENSIONS, CFG.hide_extensions ? "true" : "false");
  f_printf(&file_handle, "%s: %d\n", CFG_LED_BRIGHTNESS, CFG.led_brightness);
  f_puts("\n# Enhancement chip settings\n", &file_handle);
  f_printf(&file_handle, "#  %s: Cx4 core speed (0: original, 1: fast, all instructions are single cycle)\n", CFG_CX4_SPEED);
  f_printf(&file_handle, "%s: %d\n", CFG_CX4_SPEED, CFG.cx4_speed);
  f_printf(&file_handle, "#  %s: SuperFX core speed (0: original, 1: fast, instructions execute as fast as the implementation allows)\n", CFG_GSU_SPEED);
  f_printf(&file_handle, "%s: %d\n", CFG_GSU_SPEED, CFG.gsu_speed);
  f_printf(&file_handle, "#  %s: MSU audio volume boost\n#    (0: none; 1: +3.5dBFS; 2: +6dBFS; 3: +9.5dBFS; 4: +12dBFS)\n", CFG_MSU_VOLUME_BOOST);
  f_printf(&file_handle, "%s: %d\n", CFG_MSU_VOLUME_BOOST, CFG.msu_volume_boost);
  file_close();
  return err;
}

int cfg_load() {
  int err = 0;
  /* pre-load defaults */
  memcpy(&CFG, &CFG_DEFAULT, sizeof(cfg_t));
  yaml_file_open(CFG_FILE, FA_READ);
  if(file_res) {
    err = file_res;
  }
  if(!err) {
    yaml_token_t tok;
    /* get config entries */
    if(yaml_get_itemvalue(CFG_VIDMODE_MENU, &tok)) {
      CFG.vidmode_menu = tok.longvalue;
    }
    if(yaml_get_itemvalue(CFG_VIDMODE_GAME, &tok)) {
      CFG.vidmode_game = tok.longvalue;
    }
    if(yaml_get_itemvalue(CFG_PAIR_MODE_ALLOWED, &tok)) {
      CFG.pair_mode_allowed = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_BSX_USE_USERTIME, &tok)) {
      CFG.bsx_use_usertime = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_BSX_TIME, &tok)) {
      uint64_t bcdtime = strtoll(tok.stringvalue, NULL, 16);
      bcdtime2srtctime(bcdtime, CFG.bsx_time);
    }
    if(yaml_get_itemvalue(CFG_R213F_OVERRIDE, &tok)) {
      CFG.r213f_override = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_ENABLE_INGAME_HOOK, &tok)) {
      CFG.enable_ingame_hook = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_ENABLE_INGAME_BUTTONS, &tok)) {
      CFG.enable_ingame_buttons = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_ENABLE_HOOK_HOLDOFF, &tok)) {
      CFG.enable_hook_holdoff = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_ENABLE_SCREENSAVER, &tok)) {
      CFG.enable_screensaver = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_SORT_DIRECTORIES, &tok)) {
      CFG.sort_directories = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_HIDE_EXTENSIONS, &tok)) {
      CFG.hide_extensions = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_CX4_SPEED, &tok)) {
      CFG.cx4_speed = tok.longvalue;
    }
    if(yaml_get_itemvalue(CFG_GSU_SPEED, &tok)) {
      CFG.gsu_speed = tok.longvalue;
    }
    if(yaml_get_itemvalue(CFG_MSU_VOLUME_BOOST, &tok)) {
      CFG.msu_volume_boost = tok.longvalue;
    }
    if(yaml_get_itemvalue(CFG_1CHIP_TRANSIENT_FIXES, &tok)) {
      CFG.onechip_transient_fixes = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_BRIGHTNESS_LIMIT, &tok)) {
      CFG.brightness_limit = tok.longvalue & 0xf;
    }
    if(yaml_get_itemvalue(CFG_ENABLE_RST_TO_MENU, &tok)) {
      CFG.reset_to_menu = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_LED_BRIGHTNESS, &tok)) {
      CFG.led_brightness = tok.longvalue;
      if(CFG.led_brightness > 15) {
        CFG.led_brightness = 15;
      }
    }
    if(yaml_get_itemvalue(CFG_ENABLE_CHEATS, &tok)) {
      CFG.enable_cheats = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_RESET_PATCH, &tok)) {
      CFG.reset_patch = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_ENABLE_INGAME_SAVESTATE, &tok)) {
      CFG.enable_ingame_savestate = tok.longvalue;
    }
    if(yaml_get_itemvalue(CFG_LOADSTATE_DELAY, &tok)) {
      CFG.loadstate_delay = tok.longvalue;
    }
    if(yaml_get_itemvalue(CFG_ENABLE_SAVESTATE_SLOTS, &tok)) {
      CFG.enable_savestate_slots = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_INGAME_SAVESTATE_BUTTONS, &tok)) {
      strcpy(CFG.ingame_savestate_buttons, tok.stringvalue);
    }
    if(yaml_get_itemvalue(CFG_INGAME_LOADSTATE_BUTTONS, &tok)) {
      strcpy(CFG.ingame_loadstate_buttons, tok.stringvalue);
    }
    if(yaml_get_itemvalue(CFG_SGB_ENABLE_INGAME_HOOK, &tok)) {
      CFG.sgb_enable_ingame_hook = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_SGB_ENABLE_STATE, &tok)) {
      CFG.sgb_enable_state = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_SGB_VOLUME_BOOST, &tok)) {
      CFG.sgb_volume_boost = tok.longvalue;
    }
    if(yaml_get_itemvalue(CFG_SGB_ENH_OVERRIDE, &tok)) {
      CFG.sgb_enh_override = tok.boolvalue ? 1 : 0;
    }
#ifdef CONFIG_MK3
    if(yaml_get_itemvalue(CFG_SGB_SPR_INCREASE, &tok)) {
      CFG.sgb_spr_increase = tok.boolvalue ? 1 : 0;
    }
#endif
    if(yaml_get_itemvalue(CFG_SGB_CLOCK_FIX, &tok)) {
      CFG.sgb_clock_fix = tok.boolvalue ? 1 : 0;
    }
    if(yaml_get_itemvalue(CFG_SGB_BIOS_VERSION, &tok)) {
      CFG.sgb_bios_version = tok.longvalue;
    }
  }
  yaml_file_close();
  return err;
}

int cfg_validity_check_recent_games() {
  int err = 0, index, index_max, write_indices[10], rewrite_lastfile = 0;
  TCHAR fntmp[10][256];
  file_open(LAST_FILE, FA_READ);
  if(file_status == FILE_ERR) {
    return 0;
  }
  for(index = 0; index < 10 && !f_eof(&file_handle); index++) {
    f_gets(fntmp[index], 255, &file_handle);
  }
  if(!f_eof(&file_handle))
    index_max = 10;
  else
    index_max = index;
  file_close();
  for(index = 0; index < index_max; index++) {
    file_open((uint8_t*)fntmp[index], FA_READ);
    write_indices[index] = file_status;
    if(file_status != FILE_OK)
      rewrite_lastfile = 1;
    file_close();
  }
  if(rewrite_lastfile) {
    f_rename ((TCHAR*)LAST_FILE, (TCHAR*)LAST_FILE_BAK);
    file_open(LAST_FILE, FA_CREATE_ALWAYS | FA_WRITE);
    for(index = 0; index < index_max; index++) {
      if(write_indices[index] == FILE_OK) {
        err = f_puts(fntmp[index], &file_handle);
        err = f_putc(0, &file_handle);
      }
    }
    file_close();
  }
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
    fqfn[255] = 0;
  }
  strncat(fqfn, (const char*)fn, 256 - strlen(fqfn) - 1);
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
  int index;
  file_open(LAST_FILE, FA_READ);
  for(index = 0; index < 10 && !f_eof(&file_handle); index++) {
    f_gets(fntmp, 255, &file_handle);
    sram_writestrn(strrchr((const char*)fntmp, '/')+1, address+256*index, 256);
  }
  STM.num_recent_games = index;
  file_close();
}

int cfg_validity_check_favorite_games() {
  int err = 0, index, index_max, write_indices[10], rewrite_favoritefile = 0;
  TCHAR fntmp[10][256];
  file_open(FAVORITES_FILE, FA_READ);
  if(file_status == FILE_ERR) {
    return 0;
  }
  for(index = 0; index < 10 && !f_eof(&file_handle); index++) {
    f_gets(fntmp[index], 255, &file_handle);
  }
  if(!f_eof(&file_handle))
    index_max = 10;
  else
    index_max = index;
  file_close();
  for(index = 0; index < index_max; index++) {
    file_open((uint8_t*)fntmp[index], FA_READ);
    write_indices[index] = file_status;
    if(file_status != FILE_OK)
      rewrite_favoritefile = 1;
    file_close();
  }
  if(rewrite_favoritefile) {
    f_rename ((TCHAR*)FAVORITES_FILE, (TCHAR*)FAVORITES_FILE_BAK);
    file_open(FAVORITES_FILE, FA_CREATE_ALWAYS | FA_WRITE);
    for(index = 0; index < index_max; index++) {
      if(write_indices[index] == FILE_OK) {
        err = f_puts(fntmp[index], &file_handle);
        err = f_putc(0, &file_handle);
      }
    }
    file_close();
  }
  return err;
}

int cfg_add_favorite_game(uint8_t *fn) {
  int err = 0, index, index2, found = 0, foundindex = 0, written = 0;
  TCHAR fqfn[256];
  TCHAR fntmp[10][256];
  file_open(FAVORITES_FILE, FA_READ);
  fqfn[0] = 0;
  if(fn[0] !=  '/') {
    strncpy(fqfn, (const char*)file_path, 256);
    fqfn[255] = 0;
  }
  strncat(fqfn, (const char*)fn, 256 - strlen(fqfn) - 1);
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

  if(index > 9 + found) {
    //List is full and game is not already in list, refuse to add it
    return 1;
  }

  file_open(FAVORITES_FILE, FA_CREATE_ALWAYS | FA_WRITE);
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
  return err;
}

int cfg_remove_favorite_game(uint8_t index_to_remove) {
  int err = 0, index, index2, written = 0;
  TCHAR fntmp[10][256];

  // Load current favorites list into memory
  file_open(FAVORITES_FILE, FA_READ);
  for(index = 0; index < 10; index++) {
    f_gets(fntmp[index], 255, &file_handle);
    if((*fntmp[index] == 0) || (*fntmp[index] == '\n')) {
      break; /* last entry found */
    }
  }
  file_close();

  //Write back all favorites except the one at index_to_remove
  file_open(FAVORITES_FILE, FA_CREATE_ALWAYS | FA_WRITE);
  for(index2 = 0; index2 < index; index2++) {
    if(index2 == index_to_remove){
      continue;
    }
    err = f_puts(fntmp[index2], &file_handle);
    err = f_putc(0, &file_handle);
    written++;
  }
  file_close();
  return err;
}

int cfg_get_favorite_game(uint8_t *fn, uint8_t index) {
  int err = 0;
  file_open(FAVORITES_FILE, FA_READ);
  do {
    f_gets((TCHAR*)fn, 255, &file_handle);
  } while (index--);
  file_close();
  return err;
}

void cfg_dump_favorite_games_for_snes(uint32_t address) {
  TCHAR fntmp[256];
  int index;
  file_open(FAVORITES_FILE, FA_READ);
  for(index = 0; index < 10 && !f_eof(&file_handle); index++) {
    f_gets(fntmp, 255, &file_handle);
    sram_writestrn(strrchr((const char*)fntmp, '/')+1, address+256*index, 256);
  }
  STM.num_favorite_games = index;
  file_close();
}

/* make binary config available to menu */
void cfg_load_to_menu() {
  sram_writeblock(&CFG, SRAM_MENU_CFG_ADDR, sizeof(cfg_t));
}

/* dump binary config from menu */
void cfg_get_from_menu() {
  sram_readblock(&CFG, SRAM_MENU_CFG_ADDR, sizeof(cfg_t));
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

void cfg_set_onechip_transient_fixes(uint8_t enable) {
  CFG.onechip_transient_fixes = enable;
}
uint8_t cfg_is_onechip_transient_fixes() {
  return CFG.onechip_transient_fixes;
}

void cfg_set_brightness_limit(uint8_t limit) {
  CFG.brightness_limit = limit;
}

uint8_t cfg_get_brightness_limit() {
  return CFG.brightness_limit;
}

void cfg_set_reset_to_menu(uint8_t enable) {
  CFG.reset_to_menu = enable;
}
uint8_t cfg_is_reset_to_menu() {
  return CFG.reset_to_menu;
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

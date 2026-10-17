; Menu tables, built with the macros from menu.inc (record layouts and macro
; parameters are documented there).
;
; entry types (MTYPE_*):
;   MTYPE_FUNC          function call
;   MTYPE_SUBMENU       submenu
;   MTYPE_VALUE         value setting
;   MTYPE_FUNC_CLOSE    function call; the menu is closed upon return
;
; value types (OPTTYPE_*); the value is shown next to the entry unless OPTTYPE_NONE:
;   OPTTYPE_BYTE        unsigned char         preset: value_range min, max
;   OPTTYPE_WORD        unsigned short        preset: value_range min, max
;   OPTTYPE_STRING      C string              preset: max. string length
;   OPTTYPE_KVBYTE      multiple choice       preset: kv table (8-bit key)
;   OPTTYPE_KVWORD      multiple choice       preset: kv table (16-bit key)
;   OPTTYPE_FILESEL     file select           preset: long pointer to file path, 1 byte file type mask
;   OPTTYPE_TIME        date (BCDTime)        no preset

menu_enttab_mm:
; HEADER
  .menu_header 1, text_mainmenu
; ENTRIES
  .menu_func text_mm_last, select_last_file, mdesc_mm_last
  .menu_func text_mm_favorites, select_favorite_file, mdesc_mm_favorites
  .menu_func mtext_mm_sysinfo, show_sysinfo, mdesc_mm_sysinfo
  .menu_submenu mtext_mm_cfg, menu_enttab_cfg, mdesc_mm_cfg
  .menu_end

menu_enttab_cfg:
; HEADER
  .menu_header 1, mtext_mm_cfg
; ENTRIES
  .menu_func mtext_cfg_time, rtc_init, mdesc_cfg_time
  .menu_submenu mtext_cfg_bsx, menu_enttab_bsx, mdesc_cfg_bsx
  .menu_submenu mtext_cfg_browser, menu_enttab_browser, mdesc_cfg_browser
  .menu_submenu mtext_cfg_chip, menu_enttab_chip, mdesc_cfg_chip
  .menu_submenu mtext_cfg_sgb, menu_enttab_sgb, mdesc_cfg_sgb
  .menu_submenu mtext_cfg_ingame, menu_enttab_ingame, mdesc_cfg_ingame
  .menu_submenu mtext_cfg_savestates, menu_enttab_savestates, mdesc_cfg_savestates
  .menu_submenu mtext_cfg_scic, menu_enttab_scic, mdesc_cfg_scic
  .menu_end

menu_enttab_bsx:
; HEADER
  .menu_header 1, mtext_cfg_bsx
; ENTRIES
  .menu_value mtext_bsx_timesource, kv_bsx_timesource, OPTTYPE_KVBYTE, CFG_BSX_USE_USERTIME, mdesc_bsx_timesource
  .menu_value mtext_bsx_time, 0, OPTTYPE_TIME, CFG_BSX_TIME, mdesc_bsx_time
  .menu_end

menu_enttab_browser:
; HEADER
  .menu_header 1, mtext_cfg_browser
; ENTRIES
  .menu_value mtext_browser_sort, kv_yesno, OPTTYPE_KVBYTE, CFG_SORT_DIRECTORIES, mdesc_browser_sort
  .menu_value mtext_browser_hide_ext, kv_yesno, OPTTYPE_KVBYTE, CFG_HIDE_EXTENSIONS, mdesc_browser_hide_ext
  .menu_value mtext_browser_screensaver, kv_onoff, OPTTYPE_KVBYTE, CFG_ENABLE_SCREENSAVER, mdesc_browser_screensaver
  .menu_value mtext_browser_ledbright, kv_led_bright, OPTTYPE_KVBYTE, CFG_LED_BRIGHTNESS, mdesc_browser_ledbright, mfunc_chg_ledbright
;  .menu_value mtext_browser_screensaver_timeout, kv_screensaver_timeout, OPTTYPE_KVBYTE, CFG_SCREENSAVER_TIMEOUT, mdesc_browser_screensaver_timeout
  .menu_end

menu_enttab_chip:
; HEADER
  .menu_header 1, mtext_cfg_chip
; ENTRIES
  .menu_value mtext_chip_cx4_speed, kv_cx4_speed, OPTTYPE_KVBYTE, CFG_CX4_SPEED, mdesc_chip_cx4_speed
  .menu_value mtext_chip_gsu_speed, kv_gsu_speed, OPTTYPE_KVBYTE, CFG_GSU_SPEED, mdesc_chip_gsu_speed
  .menu_value mtext_chip_msu1_volume_boost, kv_volume_boost, OPTTYPE_KVBYTE, CFG_MSU_VOLUME_BOOST, mdesc_chip_msu1_volume_boost
  .menu_end

menu_enttab_sgb:
; HEADER
  .menu_header 1, mtext_cfg_sgb
; ENTRIES
  .menu_value mtext_sgb_enable_hooks, kv_onoff, OPTTYPE_KVBYTE, CFG_SGB_ENABLE_INGAMEHOOK, mdesc_sgb_enable_hooks
  .menu_value mtext_sgb_enable_state, kv_onoff, OPTTYPE_KVBYTE, CFG_SGB_ENABLE_STATE, mdesc_sgb_enable_state
  .menu_value mtext_sgb_enh_override, kv_enabledisable, OPTTYPE_KVBYTE, CFG_SGB_ENH_OVERRIDE, mdesc_sgb_enh_override
  .menu_value mtext_sgb_spr_increase, kv_onoff, OPTTYPE_KVBYTE, CFG_SGB_SPR_INCREASE, mdesc_sgb_spr_increase
  .menu_value mtext_sgb_clock, kv_sgb_clock, OPTTYPE_KVBYTE, CFG_SGB_CLOCK_FIX, mdesc_sgb_clock
  .menu_value mtext_sgb_volume_boost, kv_volume_boost, OPTTYPE_KVBYTE, CFG_SGB_VOLUME_BOOST, mdesc_sgb_volume_boost
  .menu_value mtext_sgb_bios, opt_1_to_2, OPTTYPE_BYTE, CFG_SGB_BIOS_VERSION, mdesc_sgb_bios
  .menu_end

menu_enttab_ingame:
; HEADER
  .menu_header 1, mtext_cfg_ingame
; ENTRIES
  .menu_value mtext_ingame_autosave, kv_onoff, OPTTYPE_KVBYTE, CFG_ENABLE_AUTOSAVE, mdesc_ingame_autosave
  .menu_value mtext_ingame_autosave_msu1, kv_onoff, OPTTYPE_KVBYTE, CFG_ENABLE_AUTOSAVE_MSU1, mdesc_ingame_autosave_msu1, , , mfunc_isenabled_autosave
  .menu_value mtext_ingame_cheats, kv_yesno, OPTTYPE_KVBYTE, CFG_ENABLE_CHEATS, mdesc_ingame_cheats
  .menu_value mtext_ingame_shortreset, kv_onoff, OPTTYPE_KVBYTE, CFG_ENABLE_RST_TO_MENU, mdesc_ingame_shortreset
  .menu_value mtext_ingame_enable, kv_onoff, OPTTYPE_KVBYTE, CFG_ENABLE_INGAME_HOOK, mdesc_ingame_enable
  .menu_value mtext_ingame_buttons, kv_onoff, OPTTYPE_KVBYTE, CFG_ENABLE_INGAME_BUTTONS, mdesc_ingame_buttons, , , mfunc_isenabled_hooks
  .menu_value mtext_ingame_holdoff, kv_onoff, OPTTYPE_KVBYTE, CFG_ENABLE_HOOK_HOLDOFF, mdesc_ingame_holdoff, , , mfunc_isenabled_hooks
  .menu_value mtext_ingame_regionpatch, kv_onoff, OPTTYPE_KVBYTE, CFG_R213F_OVERRIDE, mdesc_ingame_regionpatch
  .menu_value mtext_ingame_1chiptransientfixes, kv_onoff, OPTTYPE_KVBYTE, CFG_1CHIP_TRANSIENT_FIXES, mdesc_ingame_1chiptransientfixes
  .menu_value mtext_ingame_brightlimit, kv_bright_limit, OPTTYPE_KVBYTE, CFG_BRIGHTNESS_LIMIT, mdesc_ingame_brightlimit, mfunc_chg_brightness
  .menu_value mtext_ingame_resetpatch, kv_onoff, OPTTYPE_KVBYTE, CFG_RESET_PATCH, mdesc_ingame_resetpatch
  .menu_end

menu_enttab_savestates:
; HEADER
  .menu_header 1, mtext_cfg_savestates
; ENTRIES
  .menu_value mtext_ingame_savestate, kv_savestates, OPTTYPE_KVBYTE, CFG_ENABLE_INGAME_SAVESTATE, mdesc_ingame_savestate
  .menu_value mtext_savestate_slots, kv_onoff, OPTTYPE_KVBYTE, CFG_ENABLE_SAVESTATE_SLOTS, mdesc_savestate_slots, , , mfunc_isenabled_savestate
  .menu_value mtext_loadstate_delay, opt_0_to_30, OPTTYPE_BYTE, CFG_LOADSTATE_DELAY, mdesc_loadstate_delay, , , mfunc_isenabled_savestate
  .menu_end

menu_enttab_scic:
; HEADER
  .menu_header 1, mtext_cfg_scic
; ENTRIES
  .menu_value mtext_scic_enable, kv_yesno, OPTTYPE_KVBYTE, CFG_PAIR_MODE_ALLOWED, mdesc_scic_enable
  .menu_value mtext_scic_vmode_menu, kv_vmode_noauto, OPTTYPE_KVBYTE, CFG_VIDMODE_MENU, mdesc_scic_vmode_menu, , , mfunc_isenabled_scic
  .menu_value mtext_scic_vmode_game, kv_vmode, OPTTYPE_KVBYTE, CFG_VIDMODE_GAME, mdesc_scic_vmode_game, , , mfunc_isenabled_scic
  .menu_end

menu_enttab_filesel_context_file:
; HEADER
  .menu_header 1, text_filesel_selected_file
; ENTRIES
  .menu_func_close text_filesel_context_add_to_favorites, add_selected_file_to_favorites, mdesc_filesel_context_add_to_favorites
  .menu_func_close text_filesel_set_as_autoboot, set_selected_as_autoboot_rom, mdesc_filesel_set_as_autoboot
  .menu_func_close text_cheats, cheat_menu_file, mdesc_cheats
  .menu_end

menu_enttab_recent_context:
; HEADER
  .menu_header 1, text_filesel_selected_file
; ENTRIES
  .menu_func_close text_filesel_context_add_to_favorites, add_recent_file_to_favorites, mdesc_filesel_context_add_to_favorites
  .menu_func_close text_filesel_set_as_autoboot, set_recent_as_autoboot_rom, mdesc_filesel_set_as_autoboot
  .menu_func_close text_recent_context_remove_from_recent, remove_selected_recent_file, mdesc_recent_context_remove_from_recent
  .menu_func_close text_cheats, cheat_menu_recent, mdesc_cheats
  .menu_end

menu_enttab_filesel_favorites_context:
; HEADER
  .menu_header 1, text_filesel_selected_file
; ENTRIES
  .menu_func_close text_filesel_context_remove_from_favorites, remove_selected_favorite_file, mdesc_filesel_context_remove_from_favorites
  .menu_func_close text_filesel_set_as_autoboot, set_favorite_as_autoboot_rom, mdesc_filesel_set_as_autoboot
  .menu_func_close text_cheats, cheat_menu_favorite, mdesc_cheats
  .menu_end

; cheat editor (cheat.asm): the functions only record the choice in
; cheat_action, the cheat editor acts on it after the menu has closed (they
; run in the frame of show_menu, so they can't reach the editor's frames)
menu_enttab_cheat_options:
; HEADER
  .menu_header 1, text_cheat_options
; ENTRIES
  .menu_func_close text_cheat_edit, cheat_act_edit, mdesc_cheat_edit, mfunc_isenabled_cheat
  .menu_func_close text_cheat_add, cheat_act_add, mdesc_cheat_add
  .menu_func_close text_cheat_remove, cheat_act_remove, mdesc_cheat_remove, mfunc_isenabled_cheat
  .menu_value mtext_ingame_cheats, kv_yesno, OPTTYPE_KVBYTE, CFG_ENABLE_CHEATS, mdesc_ingame_cheats
  .menu_value mtext_ingame_enable, kv_onoff, OPTTYPE_KVBYTE, CFG_ENABLE_INGAME_HOOK, mdesc_ingame_enable
  .menu_end

menu_enttab_cheat_remove:
; HEADER
  .menu_header 1, text_cheat_remove_title
; ENTRIES
  .menu_func_close text_cheat_remove, cheat_act_remove, mdesc_cheat_remove
  .menu_func_close text_cancel, cheat_act_none, mdesc_cancel
  .menu_end

menu_enttab_cheat_code:
; HEADER
  .menu_header 1, text_cheat_code_options
; ENTRIES
  .menu_func_close text_cheat_edit_code, cheat_act_edit, mdesc_cheat_edit_code, mfunc_isenabled_cheat
  .menu_func_close text_cheat_add_code, cheat_act_add, mdesc_cheat_add_code
  .menu_func_close text_cheat_remove_code, cheat_act_remove, mdesc_cheat_remove_code, mfunc_isenabled_cheat
  .menu_end

; menu hook functions are called with 8-bit accumulator by
; menu_check_disabled_func and menu_check_change_hook (menu.asm)
  .as

mfunc_isenabled_always:
  sec
  rtl

mfunc_isenabled_never:
  clc
  rtl

; the options menu of the cheat list or the cheat editor is opened for a
; selected cheat or code (cheat.asm sets cheat_nosel before it opens them)
mfunc_isenabled_cheat:
  lda @l wram(cheat_nosel)
  lsr a
  rtl

mfunc_isenabled_hooks:
  lda @l CFG_ENABLE_INGAME_HOOK
  eor #$ff
  ror
  rtl

mfunc_isdisabled_hooks:
  lda @l CFG_ENABLE_INGAME_HOOK
  eor #$00
  ror
  rtl

mfunc_isenabled_savestate:
  lda @l CFG_ENABLE_INGAME_SAVESTATE
  and @l CFG_ENABLE_INGAME_HOOK
  eor #$ff
  ror
  rtl

mfunc_isenabled_scic:
  lda @l CFG_PAIR_MODE_ALLOWED
  and @l ST_PAIRMODE
  eor #$ff
  ror
  rtl

mfunc_isenabled_autosave:
  lda @l CFG_ENABLE_AUTOSAVE
  eor #$ff
  ror
  rtl

mfunc_chg_brightness:
  sta wram(tgt_bright)
  sta wram(menu_brightness)
  rtl

mfunc_chg_ledbright:
  sta @l CFG_LED_BRIGHTNESS
  lda #CMD_LED_BRIGHTNESS
- sta @l MCU_CMD
  cmp @l SNES_CMD
  bne -
  rtl

kv_bsx_timesource:
  .kv $0000, text_rtc
  .kv $0001, text_custom
  .kv_end

kv_onoff:
  .kv $0000, text_off
  .kv $0001, text_on
  .kv_end

kv_enabledisable:
  .kv $0000, text_enabled
  .kv $0001, text_disabled
  .kv_end

kv_yesno:
  .kv $0000, text_no
  .kv $0001, text_yes
  .kv_end

kv_scic_yesno:
  .kv $0000, text_no
  .kv $0001, text_yes
  .kv_end

kv_vmode:
  .kv $0002, text_auto
kv_vmode_noauto:
  .kv $0001, text_50Hz
  .kv $0000, text_60Hz
  .kv_end

kv_cx4_speed:
  .kv $0000, text_normal
  .kv $0001, text_fast
  .kv_end

kv_gsu_speed:
  .kv $0000, text_normal
  .kv $0001, text_fast
  .kv_end

kv_sgb_clock:
  .kv $0000, text_sgb_clock1
  .kv $0001, text_sgb_clock2
  .kv_end

kv_region:
  .kv $0000, text_off
  .kv $0001, text_auto
  .kv $0002, text_pal
  .kv $0003, text_ntsc
  .kv_end

kv_screensaver_timeout:
  .kv $0001, text_1min
  .kv $0002, text_2min
  .kv $0003, text_3min
  .kv $0004, text_4min
  .kv $0005, text_5min
  .kv $000a, text_10min
  .kv $000f, text_15min
  .kv $0014, text_20min
  .kv $001e, text_30min
  .kv $002d, text_45min
  .kv $003c, text_60min
  .kv_end

kv_volume_boost:
  .kv $0000, text_off
  .kv $0001, text_3_5db
  .kv $0002, text_6db
  .kv $0003, text_9_5db
  .kv $0004, text_12db
  .kv_end

kv_bright_limit:
  .kv $0008, text_minus7
  .kv $0009, text_minus6
  .kv $000a, text_minus5
  .kv $000b, text_minus4
  .kv $000c, text_minus3
  .kv $000d, text_minus2
  .kv $000e, text_minus1
  .kv $000f, text_off
  .kv_end

kv_savestates:
  .kv $0000, text_off
  .kv $0001, text_on
;  .kv $0001, text_on_p1
;  .kv $0002, text_on_p2
  .kv_end

opt_0_to_30:
  .value_range $0000, $001E

opt_1_to_2:
  .value_range $0001, $0002

kv_led_bright:
  .kv $0000, text_off
  .kv $0001, text_1
  .kv $0002, text_2
  .kv $0003, text_3
  .kv $0004, text_4
  .kv $0005, text_5
  .kv $0006, text_6
  .kv $0007, text_7
  .kv $0008, text_8
  .kv $0009, text_9
  .kv $000a, text_10
  .kv $000b, text_11
  .kv $000c, text_12
  .kv $000d, text_13
  .kv $000e, text_14
  .kv $000f, text_15_max
  .kv_end

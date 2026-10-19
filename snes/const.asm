version:        .text "                            v0.1", 0
zero:           .word 0
bg2tile:        .byte $20
hdma_mode_src:  .byte 56, $03, $01, $05, $00
hdma_bg1scroll_src:
  .byte 56
  .byte $00, $00, $ff, $03
  .byte 127
  .byte $fc, $00, $0d, $00
  .byte 24
  .byte $fc, $00, $0d, $00
  .byte 1
  .byte $fc, $00, $0f, $00
  .byte $00
hdma_bg2scroll_src:
  .byte 56
  .byte $ff, $03
  .byte 127
  .byte $0d, $00
  .byte 24
  .byte $0d, $00
  .byte 1
  .byte $0f, $00
  .byte 0

space64:
  .byte $20, $20, $20, $20, $20, $20, $20, $20
  .byte $20, $20, $20, $20, $20, $20, $20, $20
  .byte $20, $20, $20, $20, $20, $20, $20, $20
  .byte $20, $20, $20, $20, $20, $20, $20, $20
  .byte $20, $20, $20, $20, $20, $20, $20, $20
  .byte $20, $20, $20, $20, $20, $20, $20, $20
  .byte $20, $20, $20, $20, $20, $20, $20, $20
  .byte $20, $20, $20, $20, $20, $20, $20, $20
  .byte $00

text_dirmark:   .text " <dir>", 0
window_nw:      .byte 20
window_ne:      .byte 21
window_sw:      .byte 22
window_se:      .byte 23
window_nh:      .byte 24
window_sh:      .byte 25
window_wv:      .byte 26
window_ev:      .byte 27
window_tl:      .byte 28
window_tr:      .byte 29
window_wt:      .byte 30      ; separator: tee from the left border
window_et:      .byte 31      ; separator: tee from the right border
text_clkset:    .text "Please set the time", 0
time_win_x:     .byte 20
time_win_y:     .byte 17
time_win_w:     .byte 25
time_win_h:     .byte 3
main_win_x:     .byte 18
main_win_y:     .byte 11
main_win_w:     .byte 27
main_win_h:     .byte 13
text_mainmenu:  .text "Main Menu", 0
sysinfo_win_x:  .byte 10
sysinfo_win_y:  .byte 9
sysinfo_win_w:  .byte 43
sysinfo_win_h:  .byte 17
last_win_x:     .byte 2
last_win_y:     .byte 12
last_win_w:     .byte 60

text_ellipse:                     .byte 127, 128, 0
text_mm_file:                     .text "File Browser", 0
text_mm_last:                     .text "Recent Games", 0
text_mm_favorites:                .text "Favorite Games", 0
mtext_mm_cfg:                     .text "Configuration", 0
mtext_mm_sysinfo:                 .text "System Information", 0
mtext_cfg_time:                   .text "Set Clock", 0
mtext_cfg_bsx:                    .text "BS-X Settings", 0
mtext_cfg_browser:                .text "Browser Settings", 0
mtext_cfg_chip:                   .text "Chip Options", 0
mtext_cfg_sgb:                    .text "SGB Settings", 0
mtext_cfg_ingame:                 .text "In-game Settings", 0
mtext_cfg_savestates:             .text "Savestates Settings", 0
mtext_cfg_scic:                   .text "SuperCIC Settings", 0
mtext_bsx_timesource:             .text "BS-X clock", 0
mtext_bsx_time:                   .text "Custom time", 0
mtext_scic_enable:                .text "Enable SuperCIC", 0
mtext_scic_vmode_menu:            .text " ", 129, "Menu video mode", 0
mtext_scic_vmode_game:            .text " ", 129, "Game video mode", 0
mtext_browser_sort:               .text "Sort directories", 0
mtext_browser_hide_ext:           .text "Hide file extensions", 0
mtext_browser_screensaver:        .text "Screensaver", 0
mtext_browser_screensaver_timeout: .text "Fade screen after", 0
mtext_browser_ledbright:          .text "LED brightness", 0
mtext_ingame_cheats:              .text "Start with cheats enabled", 0
mtext_ingame_shortreset:          .text "Reset to menu", 0
mtext_ingame_enable:              .text "In-game hook", 0
mtext_ingame_buttons:             .text " ", 129, "In-game buttons", 0
mtext_ingame_holdoff:             .text " ", 129, "Initial holdoff", 0
mtext_ingame_savestate:           .text "In-game savestates", 0
mtext_savestate_slots:            .text " ", 129, "Savestate slots", 0
mtext_loadstate_delay:            .text " ", 129, "Load delay (frames)", 0
mtext_sgb_enable_hooks:           .text "In-game hooks", 0
mtext_sgb_enable_state:           .text "Savestates (XR, XL)", 0
mtext_sgb_enh_override:           .text "SGB features", 0
mtext_sgb_spr_increase:           .text "Maximum sprites limit (40)", 0
mtext_sgb_volume_boost:           .text "Volume boost", 0
mtext_sgb_clock:                  .text "Clock (Timing)", 0
mtext_sgb_bios:                   .text "BIOS version", 0
mtext_ingame_regionpatch:         .text "Auto region patch", 0
mtext_ingame_1chiptransientfixes: .text "1CHIP transient fixes", 0
mtext_ingame_brightlimit:         .text "Brightness limit", 0
mtext_ingame_resetpatch:          .text "Reset patch for clock phase", 0
mtext_ingame_autosave:            .text "Autosave", 0
mtext_ingame_autosave_msu1:       .text " ", 129, "MSU-1 Autosave", 0
mtext_chip_cx4_speed:             .text "Cx4 speed", 0
mtext_chip_gsu_speed:             .text "SuperFX speed", 0
mtext_chip_msu1_volume_boost:     .text "MSU-1 volume boost", 0

mdesc_mm_last:                    .text "Show up to 10 most recently played games", 0
mdesc_mm_favorites:               .text "Show up to 10 favorite games", 0
mdesc_mm_cfg:                     .text "Configure the sd2snes", 0
mdesc_mm_sysinfo:                 .text "Info about FW version, SD Card, SNES, CIC", 127, 128, 0
mdesc_cfg_time:                   .text "Set the date and time", 0
mdesc_cfg_bsx:                    .text "BS-X/Satellaview specific settings", 0
mdesc_cfg_browser:                .text "Change file browser settings", 0
mdesc_cfg_chip:                   .text "Set special chip features", 0
mdesc_cfg_ingame:                 .text "Set in-game features", 0
mdesc_cfg_sgb:                    .text "Set Super Game Boy features", 0
mdesc_cfg_savestates:             .text "Set savestates features", 0
mdesc_cfg_scic:                   .text "Enable/Disable SuperCIC and set video modes", 0
mdesc_bsx_timesource:             .text "Choose what date and time BS-X games see", 0
mdesc_bsx_time:                   .text "Set custom time and date for BS-X games", 0
mdesc_scic_enable:                .text "Required for SuperCIC enhanced features", 0
mdesc_scic_vmode_menu:            .text "Set video mode for menu", 0
mdesc_scic_vmode_game:            .text "Set video mode for games", 0
mdesc_browser_sort:               .text "Choose whether to sort file lists", 0
mdesc_browser_hide_ext:           .text "Choose whether to hide file extensions", 0
mdesc_browser_screensaver:        .text "Fade-out the screen after some time", 0
mdesc_browser_screensaver_timeout: .text "Set time after which to fade the screen", 0
mdesc_browser_ledbright:          .text "Change brightness of LEDs", 0
mdesc_ingame_cheats:              .text "Whether to start out with cheats enabled. Can be changed using in-game buttons", 0
mdesc_ingame_shortreset:          .text "Go back to menu on short reset if enabled", 0
mdesc_ingame_enable:              .text "Required for in-game buttons and 7E/7F cheats", 0
mdesc_ingame_buttons:             .text "Enable in-game buttons (reset, en/disable cheats", 127, 128, "). Requires in-game hook to be enabled.", 0
mdesc_ingame_holdoff:             .text "Wait 10 seconds before enabling hook (helps some games boot with hook enabled)", 0
mdesc_ingame_savestate:           .text "Enable in-game savestates and choose controller. Default: Save - Start+L / Load - Start+R", 0
mdesc_savestate_slots:            .text "Enable savestate slots. Select+Dpad: Each direction is a slot to choose", 0
mdesc_loadstate_delay:            .text "Adjust the load state delay (frames)", 0
mdesc_sgb_enable_hooks:           .text "Required for in-game buttons", 0
mdesc_sgb_enable_state:           .text "Enable built-in savestates on SGB2 (XR, XL)", 0
mdesc_sgb_enh_override:           .text "Disable/enable the SGB enhancements", 0
mdesc_sgb_spr_increase:           .text "Increase number of supported visible sprites", 0
mdesc_sgb_volume_boost:           .text "Set volume boost for SGB audio if its too quiet", 0
mdesc_sgb_clock:                  .text "Adjusts the SGB clock (timing)", 0
mdesc_sgb_bios:                   .text "Select a SGB firmware/BIOS version", 0
mdesc_ingame_regionpatch:         .text "Bypass simple region protection by games", 0
mdesc_ingame_1chiptransientfixes: .text "Patch brightness changes to fix sync glitches, fading scanlines and missing shadow on 1CHIP/Jr. consoles", 0
mdesc_ingame_brightlimit:         .text "Limit overall brightness (e.g. on 1CHIP consoles to meet RGB line levels)", 0
mdesc_ingame_resetpatch:          .text "Enable reset patch to align clocks.  Fixes graphical issues in some games", 0
mdesc_ingame_autosave:            .text "Automatically save SRM file when Save RAM contents change", 0
mdesc_ingame_autosave_msu1:       .text "MSU-1: Take some opportunities to auto-save SRM file. May cause brief stuttering.", 0
mdesc_chip_cx4_speed:             .text "Set speed of Cx4 soft core", 0
mdesc_chip_gsu_speed:             .text "Set speed of SuperFX soft core", 0
mdesc_chip_msu1_volume_boost:     .text "Set volume boost for MSU1 audio if your sd2snes is too quiet (Rev. E-G)", 0
mdesc_cx4_speed_fast:             .text "Run as fast as possible", 0
mdesc_cx4_speed_normal:           .text "Run at approx. original speed", 0
mdesc_gsu_speed_fast:             .text "Run as fast as possible", 0
mdesc_gsu_speed_normal:           .text "Run at approx. original speed", 0

text_filesel_selected_file: .text "Selected file", 0
text_filesel_context_add_to_favorites: .text "Add to favorites", 0
mdesc_filesel_context_add_to_favorites: .text "Add the selected file to favorites", 0

text_filesel_context_remove_from_favorites: .text "Remove from favorites", 0
mdesc_filesel_context_remove_from_favorites: .text "Remove the selected file from favorites", 0

text_recent_context_remove_from_recent: .text "Remove from recent games", 0
mdesc_recent_context_remove_from_recent: .text "Remove selected file from the recent games list", 0

text_filesel_set_as_autoboot: .text "Set as autoboot", 0
mdesc_filesel_set_as_autoboot: .text "Boot this ROM automatically on next power-on (hold START during powerup/reset to cancel)", 0

text_statusbar_play: .text "A:Play B:Back X:Menu", 0
text_statusbar_keys: .text "A:Select B:Back X:Menu Y:Context", 0
text_statusbar_spc: .text "B:Back", 0
text_statusbar_menu: .text "A:Select B:Back", 0
text_last:          .text "Recent games", 0
text_favorite:      .text "Favorite games", 0
text_system:        .text "CPU/PPU1/PPU2: a/b/c        VMode: x0Hz", 0

text_on_p1:     .text "On: P1", 0
text_on_p2:     .text "On: P2", 0
text_on:        .text "On", 0
text_off:       .text "Off", 0
text_enabled:   .text "Enabled", 0
text_disabled:  .text "Disabled", 0
text_normal:    .text "Normal", 0
text_fast:      .text "Fast", 0
text_rtc:       .text "Real-time", 0
text_custom:    .text "Custom", 0
text_yes:       .text "Yes", 0
text_no:        .text "No", 0
text_50Hz:      .text "50Hz", 0
text_60Hz:      .text "60Hz", 0
text_auto:      .text "Auto", 0
text_pal:       .text "PAL", 0
text_ntsc:      .text "NTSC", 0
text_add:       .text "Add", 0
text_remove:    .text "Remove", 0
text_edit:      .text "Edit", 0
text_save:      .text "Save", 0

text_1min:      .text "1 min", 0
text_2min:      .text "2 mins", 0
text_3min:      .text "3 mins", 0
text_4min:      .text "4 mins", 0
text_5min:      .text "5 mins", 0
text_10min:     .text "10 mins", 0
text_15min:     .text "15 mins", 0
text_20min:     .text "20 mins", 0
text_30min:     .text "30 mins", 0
text_45min:     .text "45 mins", 0
text_60min:     .text "1 hour", 0

text_minus1:    .text "-1", 0
text_minus2:    .text "-2", 0
text_minus3:    .text "-3", 0
text_minus4:    .text "-4", 0
text_minus5:    .text "-5", 0
text_minus6:    .text "-6", 0
text_minus7:    .text "-7", 0

text_1:         .text "1", 0
text_2:         .text "2", 0
text_3:         .text "3", 0
text_4:         .text "4", 0
text_5:         .text "5", 0
text_6:         .text "6", 0
text_7:         .text "7", 0
text_8:         .text "8", 0
text_9:         .text "9", 0
text_10:        .text "10", 0
text_11:        .text "11", 0
text_12:        .text "12", 0
text_13:        .text "13", 0
text_14:        .text "14", 0
text_15_max:    .text "15 (max)", 0

text_3_5db:     .text "+3.5dBFS", 0
text_6db:       .text "+6dBFS", 0
text_9_5db:     .text "+9.5dBFS", 0
text_12db:      .text "+12dBFS", 0

text_sgb_clock1: .text "SGB1: 4.295 MHz", 0
text_sgb_clock2: .text "SGB2: 4.194 MHz", 0

text_spcplay:   .text "SPC Music Player", 0
spcplay_win_x:  .byte 15
spcplay_win_y:  .byte 15
spcplay_win_w:  .byte 33
spcplay_win_h:  .byte 3

text_spcload:   .text "Loading SPC data to SPC700", 127, 128, 0
text_spcstarta: .text "**** Now playing SPC tune ****", 0
text_spcstartb: .text "Name:  ", 0
text_spcstartc: .text "Song:  ", 0
text_spcstartd: .text "Artist:", 0
text_spc_statusbar: .text "B:Back", 0

spcstart_win_x: .byte 10
spcstart_win_y: .byte 13
spcstart_win_w: .byte 44
spcstart_win_h: .byte 9

text_loading:   .text "Loading", 127, 128, "                        ", 0
text_saving:    .text "Saving", 127, 128, "                         ", 0
loading_win_x:  .byte 2
loading_win_y:  .byte 28
loading_win_w:  .byte 34
loading_win_h:  .byte 1

text_cheat:     .text "Cheats for ", 0
text_cheat_press_a:         .text "Press A to continue", 0
text_cheat_wram:            .text "WRAM", 0
text_cheat_rom:             .text "ROM ", 0
text_cheat_msg_rom:         .text "Not enough ROM patch slots (max. 6)", 0
text_cheat_msg_wram:        .text "Not enough WRAM patch slots (max. 32)", 0
cheat_tab_head: .text "Name                                         Codes State", 0
cheat_detail_head: .text "Code       Type Patch", 0

text_cheats:                .text "Cheats", 127, 128, 0
mdesc_cheats:               .text "Show, enable and edit the cheats of the selected file", 0
text_cheat_options:         .text "Cheat options", 0
text_cheat_edit:            .text "Edit cheat", 0
mdesc_cheat_edit:           .text "Edit name and codes of the selected cheat", 0
text_cheat_add:             .text "Add new cheat", 0
mdesc_cheat_add:            .text "Create a new cheat", 0
text_cheat_remove:          .text "Remove cheat", 0
mdesc_cheat_remove:         .text "Delete the selected cheat", 0
text_cheat_remove_title:    .text "Remove cheat?", 0
text_cancel:                .text "Cancel", 0
mdesc_cancel:               .text "Keep everything as it is", 0
text_cheat_code_options:    .text "Code options", 0
text_cheat_edit_code:       .text "Edit code", 0
mdesc_cheat_edit_code:      .text "Change the selected code", 0
text_cheat_remove_code:     .text "Remove code", 0
mdesc_cheat_remove_code:    .text "Delete the selected code", 0
text_cheat_add_code:        .text "Add code", 0
mdesc_cheat_add_code:       .text "Enter a new code for this cheat", 0
text_cheat_add_row:         .text "Add new cheat", 127, 128, 0
text_cheat_add_code_row:    .text "Add code", 127, 128, 0
text_cheat_rom_patches:     .text "ROM patches: ", 0
text_cheat_wram_patches:    .text "WRAM patches: ", 0
text_cheat_warn_hook:       .text "WRAM codes need the in-game hook", 0
text_cheat_warn_start:      .text "Cheats start disabled", 0
text_cheat_help_list:       .text "A:Edit X:On/Off Y:More B:Back START:Play", 0
text_cheat_help_edit:       .text "A:Edit Y:More START:Done B:Discard", 0
text_cheat_help_entry:      .text "START:OK B:Cancel", 0
text_cheat_msg_off:         .text "Cheat disabled: not enough patch slots", 0
text_cheat_msg_full:        .text "Maximum number of cheats reached", 0
text_cheat_msg_codes:       .text "Maximum number of codes reached", 0
text_cheat_msg_digits:      .text "Please enter all 8 digits", 0
text_cheat_msg_namefull:    .text "The name can't get any longer", 0
text_cheat_err_load:        .text "Could not read the cheat file.", 0
text_cheat_err_save:        .text "Could not save the cheat file.", 0
text_cheat_new_name:        .text "New Cheat ", 0
text_cheat_name:            .text "Name:", 0
text_cheat_enabled:         .text "Enabled:", 0
text_cheat_hex_title:       .text "Enter code", 0
text_cheat_format:          .text "Format:", 0
text_cheat_fmt_par:         .text "PAR       ", 0
text_cheat_fmt_gg:          .text "Game Genie", 0
text_cheat_code:            .text "Code:", 0
text_cheat_hex_help:        .text "A:Type X:Delete L/R:Cursor", 0
text_cheat_hex_help2:       .text "SELECT:PAR/Game Genie", 0
text_cheat_kb_title:        .text "Cheat name", 0
text_cheat_kb_help:         .text "A:Type Y:Space X:Delete L/R:Cursor SELECT:Clear", 0
text_cheat_as_gg:           .text "GG:  ", 0
text_cheat_as_par:          .text "PAR: ", 0
text_cheat_caret:           .text "^", 0
; name keyboard, one row of keys after the other (no double quotes: the
; YAML parser in the firmware has no escapes)
cheat_kb_keys:              .text "ABCDEFGHIJKLM", "NOPQRSTUVWXYZ"
                            .text "abcdefghijklm", "nopqrstuvwxyz"
                            .text "0123456789.,-", "!?':;+*/&%#()"
cheat_kb_keys_end:

text_spcid:     .text "SNES-SPC700"

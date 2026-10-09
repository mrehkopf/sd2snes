; menu entry structure:

; HEADER SIZE: 4 bytes
; HEADER:
; 1 byte   line spacing for menu display
; 3 bytes  long pointer to menu window title

; ENTRY SIZE: 23 bytes
; ENTRIES:
; 1 byte   entry type (see below)
; 3 bytes  long pointer to menu entry text
; 3 bytes  long pointer to routine / submenu structure / preset table
; 1 byte   data type of parameter (see below)
; 3 bytes  long pointer to parameter value (of data type above)
; 3 bytes  long pointer to text description of item
; Function pointers: (address - 1!)
; 3 bytes  long pointer to change-hook function (called whenever the value is changed during selection; no return value)
; 3 bytes  long pointer to post-hook function (called when the value is set; no return value)
; 3 bytes  long pointer to isEnabled function (return: c=0: enabled, c=1: disabled)

; entry types:
; 00  termination
; 01  function call
; 02  submenu
; 03  value setting
; 04  function call where the menu should be closed upon return

; data types:
; 00  no parameter
; 01  unsigned char
; 02  unsigned short
; 03  string literal (C type string)
; 04  multiple choice (key-value table - 8-bit key)
; 05  multiple choice (key-value table - 16-bit key)
; 06  file select
; 07  date

; parameter is displayed when data type is not 0

; preset table/value:
; data types 01,02: two 16-bit values - (min, max)
; data type     03: one 16-bit value  - max string length
; data type  04,05: table of tuples of entries
;                   1. 16-bit setting value (type 04 only uses low byte)
;                   2. 24-bit pointer to C string of value
;                   (val=$ffff terminates)
; data type     06: 3 bytes - long pointer to file path
;                   1 byte - file type mask
; data type     07: not used

menu_enttab_mm:
; HEADER
 .byte 1               ; listsel_step=1
 .word <>text_mainmenu ; window title
 .byte `text_mainmenu  ; for this menu
; ENTRIES
 .byte MTYPE_FUNC
 .word <>text_mm_last
 .byte `text_mm_last
 .word <>select_last_file-1
 .byte `select_last_file-1
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_mm_last
 .byte `mdesc_mm_last
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_FUNC
 .word <>text_mm_favorites
 .byte `text_mm_favorites
 .word <>select_favorite_file-1
 .byte `select_favorite_file-1
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_mm_favorites
 .byte `mdesc_mm_favorites
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_FUNC
 .word <>mtext_mm_sysinfo
 .byte `mtext_mm_sysinfo
 .word <>show_sysinfo-1
 .byte `show_sysinfo-1
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_mm_sysinfo
 .byte `mdesc_mm_sysinfo
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_SUBMENU
 .word <>mtext_mm_cfg
 .byte `mtext_mm_cfg
 .word <>menu_enttab_cfg
 .byte `menu_enttab_cfg
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_mm_cfg
 .byte `mdesc_mm_cfg
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte 0

menu_enttab_cfg:
; HEADER
 .byte 1              ; listsel_step=1
 .word <>mtext_mm_cfg
 .byte `mtext_mm_cfg
; ENTRIES
 ;.byt MTYPE_SUBMENU
 ;.word !test_mtext_title
 ;.byt ^test_mtext_title
 ;.word !menu_enttab_test
 ;.byt ^menu_enttab_test
 ;.byt 0
 ;.byt 0,0,0

 .byte MTYPE_FUNC
 .word <>mtext_cfg_time
 .byte `mtext_cfg_time
 .word <>rtc_init-1
 .byte `rtc_init
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_cfg_time
 .byte `mdesc_cfg_time
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_SUBMENU
 .word <>mtext_cfg_bsx
 .byte `mtext_cfg_bsx
 .word <>menu_enttab_bsx
 .byte `menu_enttab_bsx
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_cfg_bsx
 .byte `mdesc_cfg_bsx
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_SUBMENU
 .word <>mtext_cfg_browser
 .byte `mtext_cfg_browser
 .word <>menu_enttab_browser
 .byte `menu_enttab_browser
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_cfg_browser
 .byte `mdesc_cfg_browser
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_SUBMENU
 .word <>mtext_cfg_chip
 .byte `mtext_cfg_chip
 .word <>menu_enttab_chip
 .byte `menu_enttab_chip
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_cfg_chip
 .byte `mdesc_cfg_chip
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_SUBMENU
 .word <>mtext_cfg_sgb
 .byte `mtext_cfg_sgb
 .word <>menu_enttab_sgb
 .byte `menu_enttab_sgb
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_cfg_sgb
 .byte `mdesc_cfg_sgb
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_SUBMENU
 .word <>mtext_cfg_ingame
 .byte `mtext_cfg_ingame
 .word <>menu_enttab_ingame
 .byte `menu_enttab_ingame
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_cfg_ingame
 .byte `mdesc_cfg_ingame
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_SUBMENU
 .word <>mtext_cfg_savestates
 .byte `mtext_cfg_savestates
 .word <>menu_enttab_savestates
 .byte `menu_enttab_savestates
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_cfg_savestates
 .byte `mdesc_cfg_savestates
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_SUBMENU
 .word <>mtext_cfg_scic
 .byte `mtext_cfg_scic
 .word <>menu_enttab_scic
 .byte `menu_enttab_scic
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_cfg_scic
 .byte `mdesc_cfg_scic
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte 0

menu_enttab_bsx:
; HEADER
 .byte 1
 .word <>mtext_cfg_bsx
 .byte `mtext_cfg_bsx
; ENTRIES
 .byte MTYPE_VALUE
 .word <>mtext_bsx_timesource
 .byte `mtext_bsx_timesource
 .word <>kv_bsx_timesource
 .byte `kv_bsx_timesource
 .byte OPTTYPE_KVBYTE
 .word <>CFG_BSX_USE_USERTIME
 .byte `CFG_BSX_USE_USERTIME
 .word <>mdesc_bsx_timesource
 .byte `mdesc_bsx_timesource
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_bsx_time
 .byte `mtext_bsx_time
 .word 0
 .byte 0
 .byte OPTTYPE_TIME
 .word <>CFG_BSX_TIME
 .byte `CFG_BSX_TIME
 .word <>mdesc_bsx_time
 .byte `mdesc_bsx_time
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte 0

menu_enttab_browser:
; HEADER
 .byte 1
 .word <>mtext_cfg_browser
 .byte `mtext_cfg_browser
; ENTRIES
 .byte MTYPE_VALUE
 .word <>mtext_browser_sort
 .byte `mtext_browser_sort
 .word <>kv_yesno
 .byte `kv_yesno
 .byte OPTTYPE_KVBYTE
 .word <>CFG_SORT_DIRECTORIES
 .byte `CFG_SORT_DIRECTORIES
 .word <>mdesc_browser_sort
 .byte `mdesc_browser_sort
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_browser_hide_ext
 .byte `mtext_browser_hide_ext
 .word <>kv_yesno
 .byte `kv_yesno
 .byte OPTTYPE_KVBYTE
 .word <>CFG_HIDE_EXTENSIONS
 .byte `CFG_HIDE_EXTENSIONS
 .word <>mdesc_browser_hide_ext
 .byte `mdesc_browser_hide_ext
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_browser_screensaver
 .byte `mtext_browser_screensaver
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_ENABLE_SCREENSAVER
 .byte `CFG_ENABLE_SCREENSAVER
 .word <>mdesc_browser_screensaver
 .byte `mdesc_browser_screensaver
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_browser_ledbright
 .byte `mtext_browser_ledbright
 .word <>kv_led_bright
 .byte `kv_led_bright
 .byte OPTTYPE_KVBYTE
 .word <>CFG_LED_BRIGHTNESS
 .byte `CFG_LED_BRIGHTNESS
 .word <>mdesc_browser_ledbright
 .byte `mdesc_browser_ledbright
 .word <>(mfunc_chg_ledbright-1)
 .byte `(mfunc_chg_ledbright-1)
 .byte 0, 0, 0
 .byte 0, 0, 0

; .byt  MTYPE_VALUE
; .word !mtext_browser_screensaver_timeout
; .byt  ^mtext_browser_screensaver_timeout
; .word !kv_screensaver_timeout
; .byt  ^kv_screensaver_timeout
; .byt  OPTTYPE_KVBYTE
; .word !CFG_SCREENSAVER_TIMEOUT
; .byt  ^CFG_SCREENSAVER_TIMEOUT
; .word !mdesc_browser_screensaver_timeout
; .byt  ^mdesc_browser_screensaver_timeout
; .byt  0,0,0
; .byt  0,0,0
; .byt  0,0,0

 .byte 0

menu_enttab_chip:
; HEADER
 .byte 1
 .word <>mtext_cfg_chip
 .byte `mtext_cfg_chip
; ENTRIES
 .byte MTYPE_VALUE
 .word <>mtext_chip_cx4_speed
 .byte `mtext_chip_cx4_speed
 .word <>kv_cx4_speed
 .byte `kv_cx4_speed
 .byte OPTTYPE_KVBYTE
 .word <>CFG_CX4_SPEED
 .byte `CFG_CX4_SPEED
 .word <>mdesc_chip_cx4_speed
 .byte `mdesc_chip_cx4_speed
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_chip_gsu_speed
 .byte `mtext_chip_gsu_speed
 .word <>kv_gsu_speed
 .byte `kv_gsu_speed
 .byte OPTTYPE_KVBYTE
 .word <>CFG_GSU_SPEED
 .byte `CFG_GSU_SPEED
 .word <>mdesc_chip_gsu_speed
 .byte `mdesc_chip_gsu_speed
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_chip_msu1_volume_boost
 .byte `mtext_chip_msu1_volume_boost
 .word <>kv_volume_boost
 .byte `kv_volume_boost
 .byte OPTTYPE_KVBYTE
 .word <>CFG_MSU_VOLUME_BOOST
 .byte `CFG_MSU_VOLUME_BOOST
 .word <>mdesc_chip_msu1_volume_boost
 .byte `mdesc_chip_msu1_volume_boost
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte 0

menu_enttab_sgb:
; HEADER
 .byte 1
 .word <>mtext_cfg_sgb
 .byte `mtext_cfg_sgb
; ENTRIES

 .byte MTYPE_VALUE
 .word <>mtext_sgb_enable_hooks
 .byte `mtext_sgb_enable_hooks
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_SGB_ENABLE_INGAMEHOOK
 .byte `CFG_SGB_ENABLE_INGAMEHOOK
 .word <>mdesc_sgb_enable_hooks
 .byte `mdesc_sgb_enable_hooks
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_sgb_enable_state
 .byte `mtext_sgb_enable_state
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_SGB_ENABLE_STATE
 .byte `CFG_SGB_ENABLE_STATE
 .word <>mdesc_sgb_enable_state
 .byte `mdesc_sgb_enable_state
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_sgb_enh_override
 .byte `mtext_sgb_enh_override
 .word <>kv_enabledisable
 .byte `kv_enabledisable
 .byte OPTTYPE_KVBYTE
 .word <>CFG_SGB_ENH_OVERRIDE
 .byte `CFG_SGB_ENH_OVERRIDE
 .word <>mdesc_sgb_enh_override
 .byte `mdesc_sgb_enh_override
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_sgb_spr_increase
 .byte `mtext_sgb_spr_increase
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_SGB_SPR_INCREASE
 .byte `CFG_SGB_SPR_INCREASE
 .word <>mdesc_sgb_spr_increase
 .byte `mdesc_sgb_spr_increase
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_sgb_clock
 .byte `mtext_sgb_clock
 .word <>kv_sgb_clock
 .byte `kv_sgb_clock
 .byte OPTTYPE_KVBYTE
 .word <>CFG_SGB_CLOCK_FIX
 .byte `CFG_SGB_CLOCK_FIX
 .word <>mdesc_sgb_clock
 .byte `mdesc_sgb_clock
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_sgb_volume_boost
 .byte `mtext_sgb_volume_boost
 .word <>kv_volume_boost
 .byte `kv_volume_boost
 .byte OPTTYPE_KVBYTE
 .word <>CFG_SGB_VOLUME_BOOST
 .byte `CFG_SGB_VOLUME_BOOST
 .word <>mdesc_sgb_volume_boost
 .byte `mdesc_sgb_volume_boost
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_sgb_bios
 .byte `mtext_sgb_bios
 .word <>opt_1_to_2
 .byte `opt_1_to_2
 .byte OPTTYPE_BYTE
 .word <>CFG_SGB_BIOS_VERSION
 .byte `CFG_SGB_BIOS_VERSION
 .word <>mdesc_sgb_bios
 .byte `mdesc_sgb_bios
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte 0

menu_enttab_ingame:
; HEADER
 .byte 1
 .word <>mtext_cfg_ingame
 .byte `mtext_cfg_ingame
; ENTRIES

 .byte MTYPE_VALUE
 .word <>mtext_ingame_autosave
 .byte `mtext_ingame_autosave
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_ENABLE_AUTOSAVE
 .byte `CFG_ENABLE_AUTOSAVE
 .word <>mdesc_ingame_autosave
 .byte `mdesc_ingame_autosave
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_ingame_autosave_msu1
 .byte `mtext_ingame_autosave_msu1
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_ENABLE_AUTOSAVE_MSU1
 .byte `CFG_ENABLE_AUTOSAVE_MSU1
 .word <>mdesc_ingame_autosave_msu1
 .byte `mdesc_ingame_autosave_msu1
 .byte 0, 0, 0
 .byte 0, 0, 0
 .word <>(mfunc_isenabled_autosave-1)
 .byte `(mfunc_isenabled_autosave-1)

 .byte MTYPE_VALUE
 .word <>mtext_ingame_cheats
 .byte `mtext_ingame_cheats
 .word <>kv_yesno
 .byte `kv_yesno
 .byte OPTTYPE_KVBYTE
 .word <>CFG_ENABLE_CHEATS
 .byte `CFG_ENABLE_CHEATS
 .word <>mdesc_ingame_cheats
 .byte `mdesc_ingame_cheats
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_ingame_shortreset
 .byte `mtext_ingame_shortreset
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_ENABLE_RST_TO_MENU
 .byte `CFG_ENABLE_RST_TO_MENU
 .word <>mdesc_ingame_shortreset
 .byte `mdesc_ingame_shortreset
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_ingame_enable
 .byte `mtext_ingame_enable
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_ENABLE_INGAME_HOOK
 .byte `CFG_ENABLE_INGAME_HOOK
 .word <>mdesc_ingame_enable
 .byte `mdesc_ingame_enable
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_ingame_buttons
 .byte `mtext_ingame_buttons
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_ENABLE_INGAME_BUTTONS
 .byte `CFG_ENABLE_INGAME_BUTTONS
 .word <>mdesc_ingame_buttons
 .byte `mdesc_ingame_buttons
 .byte 0, 0, 0
 .byte 0, 0, 0
 .word <>(mfunc_isenabled_hooks-1)
 .byte `(mfunc_isenabled_hooks-1)

 .byte MTYPE_VALUE
 .word <>mtext_ingame_holdoff
 .byte `mtext_ingame_holdoff
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_ENABLE_HOOK_HOLDOFF
 .byte `CFG_ENABLE_HOOK_HOLDOFF
 .word <>mdesc_ingame_holdoff
 .byte `mdesc_ingame_holdoff
 .byte 0, 0, 0
 .byte 0, 0, 0
 .word <>(mfunc_isenabled_hooks-1)
 .byte `(mfunc_isenabled_hooks-1)

 .byte MTYPE_VALUE
 .word <>mtext_ingame_regionpatch
 .byte `mtext_ingame_regionpatch
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_R213F_OVERRIDE
 .byte `CFG_R213F_OVERRIDE
 .word <>mdesc_ingame_regionpatch
 .byte `mdesc_ingame_regionpatch
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_ingame_1chiptransientfixes
 .byte `mtext_ingame_1chiptransientfixes
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_1CHIP_TRANSIENT_FIXES
 .byte `CFG_1CHIP_TRANSIENT_FIXES
 .word <>mdesc_ingame_1chiptransientfixes
 .byte `mdesc_ingame_1chiptransientfixes
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_ingame_brightlimit
 .byte `mtext_ingame_brightlimit
 .word <>kv_bright_limit
 .byte `kv_bright_limit
 .byte OPTTYPE_KVBYTE
 .word <>CFG_BRIGHTNESS_LIMIT
 .byte `CFG_BRIGHTNESS_LIMIT
 .word <>mdesc_ingame_brightlimit
 .byte `mdesc_ingame_brightlimit
 .word <>(mfunc_chg_brightness-1)
 .byte `(mfunc_chg_brightness-1)
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_ingame_resetpatch
 .byte `mtext_ingame_resetpatch
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_RESET_PATCH
 .byte `CFG_RESET_PATCH
 .word <>mdesc_ingame_resetpatch
 .byte `mdesc_ingame_resetpatch
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte 0

menu_enttab_savestates:
; HEADER
 .byte 1
 .word <>mtext_cfg_savestates
 .byte `mtext_cfg_savestates
; ENTRIES
 .byte MTYPE_VALUE
 .word <>mtext_ingame_savestate
 .byte `mtext_ingame_savestate
 .word <>kv_savestates
 .byte `kv_savestates
 .byte OPTTYPE_KVBYTE
 .word <>CFG_ENABLE_INGAME_SAVESTATE
 .byte `CFG_ENABLE_INGAME_SAVESTATE
 .word <>mdesc_ingame_savestate
 .byte `mdesc_ingame_savestate
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_savestate_slots
 .byte `mtext_savestate_slots
 .word <>kv_onoff
 .byte `kv_onoff
 .byte OPTTYPE_KVBYTE
 .word <>CFG_ENABLE_SAVESTATE_SLOTS
 .byte `CFG_ENABLE_SAVESTATE_SLOTS
 .word <>mdesc_savestate_slots
 .byte `mdesc_savestate_slots
 .byte 0, 0, 0
 .byte 0, 0, 0
 .word <>(mfunc_isenabled_savestate-1)
 .byte `(mfunc_isenabled_savestate-1)

 .byte MTYPE_VALUE
 .word <>mtext_loadstate_delay
 .byte `mtext_loadstate_delay
 .word <>opt_0_to_30
 .byte `opt_0_to_30
 .byte OPTTYPE_BYTE
 .word <>CFG_LOADSTATE_DELAY
 .byte `CFG_LOADSTATE_DELAY
 .word <>mdesc_loadstate_delay
 .byte `mdesc_loadstate_delay
 .byte 0, 0, 0
 .byte 0, 0, 0
 .word <>(mfunc_isenabled_savestate-1)
 .byte `(mfunc_isenabled_savestate-1)

 .byte 0

menu_enttab_scic:
; HEADER
 .byte 1
 .word <>mtext_cfg_scic
 .byte `mtext_cfg_scic
; ENTRIES
 .byte MTYPE_VALUE
 .word <>mtext_scic_enable
 .byte `mtext_scic_enable
 .word <>kv_yesno
 .byte `kv_yesno
 .byte OPTTYPE_KVBYTE
 .word <>CFG_PAIR_MODE_ALLOWED
 .byte `CFG_PAIR_MODE_ALLOWED
 .word <>mdesc_scic_enable
 .byte `mdesc_scic_enable
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_VALUE
 .word <>mtext_scic_vmode_menu
 .byte `mtext_scic_vmode_menu
 .word <>kv_vmode_noauto
 .byte `kv_vmode_noauto
 .byte OPTTYPE_KVBYTE
 .word <>CFG_VIDMODE_MENU
 .byte `CFG_VIDMODE_MENU
 .word <>mdesc_scic_vmode_menu
 .byte `mdesc_scic_vmode_menu
 .byte 0, 0, 0
 .byte 0, 0, 0
 .word <>(mfunc_isenabled_scic-1)
 .byte `(mfunc_isenabled_scic-1)

 .byte MTYPE_VALUE
 .word <>mtext_scic_vmode_game
 .byte `mtext_scic_vmode_game
 .word <>kv_vmode
 .byte `kv_vmode
 .byte OPTTYPE_KVBYTE
 .word <>CFG_VIDMODE_GAME
 .byte `CFG_VIDMODE_GAME
 .word <>mdesc_scic_vmode_game
 .byte `mdesc_scic_vmode_game
 .byte 0, 0, 0
 .byte 0, 0, 0
 .word <>(mfunc_isenabled_scic-1)
 .byte `(mfunc_isenabled_scic-1)

 .byte 0

menu_enttab_filesel_context_file:
; HEADER
 .byte 1              ; listsel_step=1
 .word <>text_filesel_selected_file ; window title
 .byte `text_filesel_selected_file  ; for this menu
; ENTRIES
 .byte MTYPE_FUNC_CLOSE
 .word <>text_filesel_context_add_to_favorites
 .byte `text_filesel_context_add_to_favorites
 .word <>add_selected_file_to_favorites-1
 .byte `add_selected_file_to_favorites-1
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_filesel_context_add_to_favorites
 .byte `mdesc_filesel_context_add_to_favorites
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_FUNC_CLOSE
 .word <>text_filesel_set_as_autoboot
 .byte `text_filesel_set_as_autoboot
 .word <>set_selected_as_autoboot_rom-1
 .byte `set_selected_as_autoboot_rom-1
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_filesel_set_as_autoboot
 .byte `mdesc_filesel_set_as_autoboot
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte 0

menu_enttab_recent_context:
; HEADER
 .byte 1              ; listsel_step=1
 .word <>text_filesel_selected_file ; window title
 .byte `text_filesel_selected_file  ; for this menu
; ENTRIES
 .byte MTYPE_FUNC_CLOSE
 .word <>text_filesel_context_add_to_favorites
 .byte `text_filesel_context_add_to_favorites
 .word <>add_recent_file_to_favorites-1
 .byte `add_recent_file_to_favorites-1
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_filesel_context_add_to_favorites
 .byte `mdesc_filesel_context_add_to_favorites
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_FUNC_CLOSE
 .word <>text_filesel_set_as_autoboot
 .byte `text_filesel_set_as_autoboot
 .word <>set_recent_as_autoboot_rom-1
 .byte `set_recent_as_autoboot_rom-1
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_filesel_set_as_autoboot
 .byte `mdesc_filesel_set_as_autoboot
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_FUNC_CLOSE
 .word <>text_recent_context_remove_from_recent
 .byte `text_recent_context_remove_from_recent
 .word <>remove_selected_recent_file-1
 .byte `remove_selected_recent_file-1
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_recent_context_remove_from_recent
 .byte `mdesc_recent_context_remove_from_recent
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte 0

menu_enttab_filesel_favorites_context:
; HEADER
 .byte 1              ; listsel_step=1
 .word <>text_filesel_selected_file ; window title
 .byte `text_filesel_selected_file  ; for this menu
; ENTRIES
 .byte MTYPE_FUNC_CLOSE
 .word <>text_filesel_context_remove_from_favorites
 .byte `text_filesel_context_remove_from_favorites
 .word <>remove_selected_favorite_file-1
 .byte `remove_selected_favorite_file-1
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_filesel_context_remove_from_favorites
 .byte `mdesc_filesel_context_remove_from_favorites
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte MTYPE_FUNC_CLOSE
 .word <>text_filesel_set_as_autoboot
 .byte `text_filesel_set_as_autoboot
 .word <>set_favorite_as_autoboot_rom-1
 .byte `set_favorite_as_autoboot_rom-1
 .byte 0
 .byte 0, 0, 0
 .word <>mdesc_filesel_set_as_autoboot
 .byte `mdesc_filesel_set_as_autoboot
 .byte 0, 0, 0
 .byte 0, 0, 0
 .byte 0, 0, 0

 .byte 0

mfunc_set_bsx_time:
  php
  sep #$20
  .as
  lda #`CFG_BSX_TIME
  pha
  pea <>CFG_BSX_TIME
    jsr time_init
  pla
  pla
  pla
  plp
  rtl

mfunc_isenabled_always:
  sec
  rtl

mfunc_isenabled_never:
  clc
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
.word $0000, <>text_rtc
.byte `text_rtc
.word $0001, <>text_custom
.byte `text_custom
.word $ffff

kv_onoff:
.word $0000, <>text_off
.byte `text_off
.word $0001, <>text_on
.byte `text_on
.word $ffff

kv_enabledisable:
.word $0000, <>text_enabled
.byte `text_enabled
.word $0001, <>text_disabled
.byte `text_disabled
.word $ffff

kv_yesno:
.word $0000, <>text_no
.byte `text_no
.word $0001, <>text_yes
.byte `text_yes
.word $ffff

kv_scic_yesno:
.word $0000, <>text_no
.byte `text_no
.word $0001, <>text_yes
.byte `text_yes
.word $ffff

kv_vmode:
.word $0002, <>text_auto
.byte `text_auto
kv_vmode_noauto:
.word $0001, <>text_50Hz
.byte `text_50Hz
.word $0000, <>text_60Hz
.byte `text_60Hz
.word $ffff

kv_cx4_speed:
.word $0000, <>text_normal
.byte `text_normal
.word $0001, <>text_fast
.byte `text_fast
.word $ffff

kv_gsu_speed:
.word $0000, <>text_normal
.byte `text_normal
.word $0001, <>text_fast
.byte `text_fast
.word $ffff

kv_sgb_clock:
.word $0000, <>text_sgb_clock1
.byte `text_sgb_clock1
.word $0001, <>text_sgb_clock2
.byte `text_sgb_clock2
.word $ffff

kv_region:
.word $0000, <>text_off
.byte `text_off
.word $0001, <>text_auto
.byte `text_auto
.word $0002, <>text_pal
.byte `text_pal
.word $0003, <>text_ntsc
.byte `text_ntsc
.word $ffff

kv_screensaver_timeout:
.word $0001, <>text_1min
.byte `text_1min
.word $0002, <>text_2min
.byte `text_2min
.word $0003, <>text_3min
.byte `text_3min
.word $0004, <>text_4min
.byte `text_4min
.word $0005, <>text_5min
.byte `text_5min
.word $000a, <>text_10min
.byte `text_10min
.word $000f, <>text_15min
.byte `text_15min
.word $0014, <>text_20min
.byte `text_20min
.word $001e, <>text_30min
.byte `text_30min
.word $002d, <>text_45min
.byte `text_45min
.word $003c, <>text_60min
.byte `text_60min
.word $ffff

kv_volume_boost:
.word $0000, <>text_off
.byte `text_off
.word $0001, <>text_3_5db
.byte `text_3_5db
.word $0002, <>text_6db
.byte `text_6db
.word $0003, <>text_9_5db
.byte `text_9_5db
.word $0004, <>text_12db
.byte `text_12db
.word $ffff

kv_bright_limit:
.word $0008, <>text_minus7
.byte `text_minus7
.word $0009, <>text_minus6
.byte `text_minus6
.word $000a, <>text_minus5
.byte `text_minus5
.word $000b, <>text_minus4
.byte `text_minus4
.word $000c, <>text_minus3
.byte `text_minus3
.word $000d, <>text_minus2
.byte `text_minus2
.word $000e, <>text_minus1
.byte `text_minus1
.word $000f, <>text_off
.byte `text_off
.word $ffff

kv_savestates:
.word $0000, <>text_off
.byte `text_off
.word $0001, <>text_on
.byte `text_on
;.word $0001, !text_on_p1 : .byt ^text_on_p1
;.word $0002, !text_on_p2 : .byt ^text_on_p2
.word $ffff

opt_0_to_30:
.word $0000, $001E

opt_1_to_2:
.word $0001, $0002

kv_led_bright:
.word $0000, <>text_off
.byte `text_off
.word $0001, <>text_1
.byte `text_1
.word $0002, <>text_2
.byte `text_2
.word $0003, <>text_3
.byte `text_3
.word $0004, <>text_4
.byte `text_4
.word $0005, <>text_5
.byte `text_5
.word $0006, <>text_6
.byte `text_6
.word $0007, <>text_7
.byte `text_7
.word $0008, <>text_8
.byte `text_8
.word $0009, <>text_9
.byte `text_9
.word $000a, <>text_10
.byte `text_10
.word $000b, <>text_11
.byte `text_11
.word $000c, <>text_12
.byte `text_12
.word $000d, <>text_13
.byte `text_13
.word $000e, <>text_14
.byte `text_14
.word $000f, <>text_15_max
.byte `text_15_max
.word $ffff

menu_enttab_test:
; HEADER
 .byte 1
 .word <>test_mtext_title
 .byte `test_mtext_title
; ENTRIES
 .byte MTYPE_VALUE
 .word <>test_mtext_entry_byte
 .byte `test_mtext_entry_byte
 .word <>test_mtext_entry_byte_ptab
 .byte `test_mtext_entry_byte_ptab
 .byte OPTTYPE_BYTE
 .word $F000
 .byte $7F
 .byte MTYPE_VALUE
 .word <>test_mtext_entry_word
 .byte `test_mtext_entry_word
 .word <>test_mtext_entry_word_ptab
 .byte `test_mtext_entry_word_ptab
 .byte OPTTYPE_WORD
 .word $F001
 .byte $7F
 .byte MTYPE_VALUE
 .word <>test_mtext_entry_string
 .byte `test_mtext_entry_string
 .word $0008
 .byte 0
 .byte OPTTYPE_STRING
 .word $F003
 .byte $7F
 .byte MTYPE_VALUE
 .word <>test_mtext_entry_kvbyte
 .byte `test_mtext_entry_kvbyte
 .word <>test_mtext_entry_kvbyte_ptab
 .byte `test_mtext_entry_kvbyte_ptab
 .byte OPTTYPE_KVBYTE
 .word $F00B
 .byte $7F
 .byte MTYPE_VALUE
 .word <>test_mtext_entry_kvword
 .byte `test_mtext_entry_kvword
 .word <>test_mtext_entry_kvword_ptab
 .byte `test_mtext_entry_kvword_ptab
 .byte OPTTYPE_KVWORD
 .word $F00C
 .byte $7F
 .byte MTYPE_VALUE
 .word <>test_mtext_entry_file
 .byte `test_mtext_entry_file
 .word <>test_mtext_entry_file_path
 .byte `test_mtext_entry_file_path
 .byte OPTTYPE_FILESEL
 .word $F00E
 .byte $7F

 .byte 0

test_mtext_title:             .text "Test Menu", 0
test_mtext_entry_byte:        .text "Byte Select", 0
test_mtext_entry_word:        .text "Word Select", 0
test_mtext_entry_string:      .text "String Select", 0
test_mtext_entry_kvbyte:      .text "8bit Key-Value Select", 0
test_mtext_entry_kvword:      .text "16bit Key-Value Select", 0
test_mtext_entry_file:        .text "File Select", 0
test_mtext_entry_byte_ptab:   .word $000e, $00e9
test_mtext_entry_word_ptab:   .word $0052, $fecd
test_mtext_entry_kvbyte_ptab: .word $0000, <>text_on
                              .byte `text_on
                              .word $0003, <>text_off
                              .byte `text_off
                              .word $0001, <>text_yes
                              .byte `text_yes
                              .word $000e, <>text_no
                              .byte `text_no
                              .word $0004, <>text_fast
                              .byte `text_fast
                              .word $ffff

test_mtext_entry_kvword_ptab: .word $10f0, <>text_50Hz
                              .byte `text_50Hz
                              .word $20e3, <>text_60Hz
                              .byte `text_60Hz
                              .word $0008, <>text_normal
                              .byte `text_normal
                              .word $0133, <>text_rtc
                              .byte `text_rtc
                              .word $010a, <>text_auto
                              .byte `text_auto
                              .word $ffff

test_mtext_entry_file_path:   .byte TYPE_IPS
                              .word <>rootdir
                              .byte `rootdir

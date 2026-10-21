APUIO0                      = $2140
APUIO1                      = $2141
APUIO2                      = $2142
APUIO3                      = $2143

; VRAM layout (word addresses)
LOGO_BASE                   = $0000     ; logo tiles (8bpp), see FONT_BASE
BG1_TILE_BASE               = $1C00     ; BG1 tilemap, 32x32
BG2_TILE_BASE               = $2000     ; BG2 tilemap, 32x32
OBJ_TILE_BASE               = $2000     ; sprite tiles; 0-63 lie under the BG2 tilemap
OBJ_FIRST_TILE              = 64        ; first usable sprite tile
OBJ_PAGES_BASE              = $3000     ; sprite tiles 256-511, three pages of $1000
FONT_BASE                   = $6000     ; font, 4bpp, 16x8 per character
OBSEL_PAGE0                 = $60 | (OBJ_TILE_BASE >> 13) ; 16x16+32x32, tiles 256-511 at OBJ_PAGES_BASE
; BG1 and BG2 read the font from FONT_BASE: BG1 (4bpp) uses tile 2 * char,
; BG2 (2bpp) tile 4 * char (bitplanes 0+1 of the left half). In mode 3, BG1
; (8bpp) has the same base, and the logo tiles $100-$1DF wrap around to
; LOGO_BASE.
        .cerror (FONT_BASE + $100 * 32) & $7fff != LOGO_BASE, "logo tiles must follow the font base (with wrap-around)"
        .cerror OBJ_TILE_BASE + $1000 != OBJ_PAGES_BASE, "OBSEL name select 0 must point at OBJ_PAGES_BASE"

MCU_CMD                     = $002A00
SNES_CMD                    = $002A02
MCU_PARAM                   = $002A04
WARM_SIGNATURE              = $002AFD
WARM_COMPLEMENT             = $002AF9
SAVED_SP                    = $002AFB

BRAM_PAYLOAD                = $002A10
BRAM_RETURN_VECTOR          = $002A6C
BRAM_RESET_HOOK             = $002A7D
NMI_WRAM_CHEATS             = $002AD8
NMI_PAD                     = $002BF0
NMI_CMD                     = $002BF2
BRAM_UNLOCK                 = $002BF4
MIRROR_4200                 = $002BFA
PAD_LATCH                   = $002BFB
NMI_BUTTONS_ENABLE          = $002BFC
NMI_VECT_DISABLE            = $002BFD
NMI_WRAM_PATCH_DISABLE      = $002BFE
NMI_WRAM_PATCH_COUNT        = $002BFF
NMI_EXEC                    = $002C00
WINDOW_STACK_BASE           = $7E2000
CHEAT_EDIT_BUF              = $7F0000   ; cheat record being edited
CHEAT_NAME_BUF              = $7F0200   ; cheat name being edited

BG2_TILE_BUF                = $7EA000
BG1_TILE_BUF                = $7EB000

ROOT_DIR                    = $C20000
SKIN_ADDR                   = $F00000     ; skin file, loaded by the MCU (SRAM_SKIN_ADDR)
SKIN_MAX_SIZE               = $FFFF
SKIN_SRC_CONFIG             = 0         ; CMD_LOAD_SKIN: the configured skin
SKIN_SRC_SELECTED           = 1         ; the selected file (MCU_PARAM: dir, file entry)
SKIN_SRC_BUILTIN            = 2         ; CMD_SET_SKIN: none (built-in skin)
SKIN_SRC_SHOWN              = 3         ; CMD_SET_SKIN: the selected file, already loaded (preview)

NUM_CHEATS                  = $CFFFFE
CHEAT_ADDR                  = $D00000

SPC_DATA                    = $FD0000
SPC_HEADER                  = $FE0000
SPC_DSP_REGS                = $FE0100

FILESEL_CWD                 = $FF0000
CFG_ADDR                    = $FF0100
CHEAT_STATUS                = $FF0F00   ; result of CMD_LOAD_CHT/CMD_SAVE_CHT
CHEAT_ROMNAME               = $FF0F01   ; file name for the cheat window title
ST_MCU_ADDR                 = $FF1100
ST_SNES_ADDR                = $FF1110
SYSINFO_BLK                 = $FF1200
LAST_GAME                   = $FF1420
WRAM_BAK                    = $FF2000
FAVORITE_GAMES              = $FF4000

CMD_LOADROM                 = $01       ; shortcut - load ROM with default settings
CMD_SETRTC                  = $02
CMD_SYSINFO                 = $03
CMD_LOADLAST                = $04
CMD_LOADSPC                 = $05
CMD_LOADFAVORITE            = $06
CMD_SET_ALLOW_PAIR          = $07
CMD_SET_VIDMODE_GAME        = $08
CMD_SET_VIDMODE_MENU        = $09
CMD_READDIR                 = $0A
CMD_FPGA_RECONF             = $0B
CMD_LOAD_CHT                = $0C
CMD_SAVE_CHT                = $0D
CMD_SAVE_CFG                = $0E
CMD_SET_CFG                 = $0F
CMD_SELECTROM               = $10       ; TODO WIP
CMD_RUNROM                  = $11       ; TODO WIP - ROM must first be selected by SELECTROM
CMD_LED_BRIGHTNESS          = $12
CMD_ADD_FAVORITE_ROM        = $13
CMD_ADD_FAVORITE_RECENT     = $14
CMD_REMOVE_FAVORITE_ROM     = $15
CMD_REMOVE_RECENT_ROM       = $16
CMD_SET_AUTOBOOT_ROM        = $17       ; set autoboot from file browser
CMD_SET_AUTOBOOT_FAV        = $18       ; set autoboot from favorites (index in MCU_PARAM)
CMD_SET_AUTOBOOT_RECENT     = $19
CMD_CLR_AUTOBOOT_ROM        = $1a       ; clear autoboot ROM setting
CMD_LOAD_AUTOBOOT           = $1b       ; trigger autoboot at cold boot
CMD_LOAD_SKIN               = $1c       ; load a skin to SKIN_ADDR (source in MCU_PARAM+8)
CMD_SET_SKIN                = $1d       ; select the skin and load it (source in MCU_PARAM+8)
CMD_SAVESTATE               = $40
CMD_LOADSTATE               = $41
CMD_MCU_RDY                 = $55
CMD_RESET                   = $80
CMD_RESET_TO_MENU           = $81
CMD_ENABLE_CHEATS           = $82
CMD_DISABLE_CHEATS          = $83
CMD_KILL_NMIHOOK            = $84
CMD_TEMP_KILL_NMIHOOK       = $85
CMD_RESET_LOOP_FAIL         = $88
CMD_RESET_LOOP_PASS         = $89
CMD_RESET_LOOP_TIMEOUT      = $8A
CMD_COMBO_TRANSITION        = $90

; MCU_PARAM+8 of CMD_LOAD_CHT/CMD_SAVE_CHT: where the file was selected
CHEAT_SRC_BROWSER           = $00       ; file pointers in MCU_PARAM+0..7
CHEAT_SRC_RECENT            = $01       ; list index in MCU_PARAM
CHEAT_SRC_FAVORITE          = $02       ; list index in MCU_PARAM
; values of CHEAT_STATUS
CHEAT_STATUS_OK             = $00
CHEAT_STATUS_ERR            = $01

; cheat records at CHEAT_ADDR (cheat_record_t in src/cheat.h)
CHEAT_REC_FLAGS             = 0         ; bit 7: enabled
CHEAT_REC_NAME              = 1         ; NUL terminated
CHEAT_REC_NUMCODES          = 255
CHEAT_REC_CODES             = 256       ; 4 bytes each: value, address lo/hi, bank
CHEAT_REC_CODEFMT           = 416       ; 1 byte each: CHEAT_CODEFMT_*
CHEAT_REC_SIZE              = 456
CHEAT_REC_STRIDE            = 512
CHEAT_FLAG_ENABLE           = $80
CHEAT_CODEFMT_GG            = $01       ; code was entered as a Game Genie code
CHEAT_MAX_CHEATS            = 2048
CHEAT_NUM_CODES             = 40        ; per cheat
CHEAT_NUM_ROM_PATCHES       = 6
CHEAT_NUM_WRAM_PATCHES      = 32
CHEAT_NAME_MAXLEN           = 240

CFG_VIDMODE_MENU                = CFG_ADDR+$0000
CFG_VIDMODE_GAME                = CFG_ADDR+$0001
CFG_PAIR_MODE_ALLOWED           = CFG_ADDR+$0002
CFG_BSX_USE_USERTIME            = CFG_ADDR+$0003
CFG_BSX_TIME                    = CFG_ADDR+$0004
CFG_R213F_OVERRIDE              = CFG_ADDR+$0010
CFG_ENABLE_INGAME_HOOK          = CFG_ADDR+$0011
CFG_ENABLE_INGAME_BUTTONS       = CFG_ADDR+$0012
CFG_ENABLE_HOOK_HOLDOFF         = CFG_ADDR+$0013
CFG_ENABLE_SCREENSAVER          = CFG_ADDR+$0014
CFG_SCREENSAVER_TIMEOUT         = CFG_ADDR+$0015
CFG_SORT_DIRECTORIES            = CFG_ADDR+$0017
CFG_HIDE_EXTENSIONS             = CFG_ADDR+$0018
CFG_CX4_SPEED                   = CFG_ADDR+$0019
CFG_SKIN_NAME                   = CFG_ADDR+$001A
CFG_CONTROL_TYPE                = CFG_ADDR+$009A
CFG_MSU_VOLUME_BOOST            = CFG_ADDR+$009B
CFG_1CHIP_TRANSIENT_FIXES       = CFG_ADDR+$009C
CFG_BRIGHTNESS_LIMIT            = CFG_ADDR+$009D
CFG_GSU_SPEED                   = CFG_ADDR+$009E
CFG_ENABLE_RST_TO_MENU          = CFG_ADDR+$009F
CFG_LED_BRIGHTNESS              = CFG_ADDR+$00A0
CFG_ENABLE_CHEATS               = CFG_ADDR+$00A1
CFG_RESET_PATCH                 = CFG_ADDR+$00A2
CFG_ENABLE_INGAME_SAVESTATE     = CFG_ADDR+$00A3
CFG_LOADSTATE_DELAY             = CFG_ADDR+$00A4
CFG_ENABLE_SAVESTATE_SLOTS      = CFG_ADDR+$00A5
CFG_INGAME_BUTTONS_SAVE_STATE   = CFG_ADDR+$00A6
CFG_INGAME_BUTTONS_LOAD_STATE   = CFG_ADDR+$00A8
CFG_INGAME_BUTTONS_CHANGE_STATE = CFG_ADDR+$00AA
CFG_SGB_ENABLE_INGAMEHOOK       = CFG_ADDR+$00AC
CFG_SGB_ENABLE_STATE            = CFG_ADDR+$00AD
CFG_SGB_VOLUME_BOOST            = CFG_ADDR+$00AE
CFG_SGB_ENH_OVERRIDE            = CFG_ADDR+$00AF
CFG_SGB_SPR_INCREASE            = CFG_ADDR+$00B0
CFG_SGB_CLOCK_FIX               = CFG_ADDR+$00B1
CFG_SGB_BIOS_VERSION            = CFG_ADDR+$00B2
CFG_ENABLE_AUTOSAVE             = CFG_ADDR+$00B3
CFG_ENABLE_AUTOSAVE_MSU1        = CFG_ADDR+$00B4
CFG_BUTTON_STYLE                = CFG_ADDR+$00B5

BCDTime .struct
  s1                             .byte ?
  s10                            .byte ?
  m1                             .byte ?
  m10                            .byte ?
  h1                             .byte ?
  h10                            .byte ?
  d1                             .byte ?
  d10                            .byte ?
  mon                            .byte ?
  y1                             .byte ?
  y10                            .byte ?
  y100                           .byte ?
.ends

ST_RTC_VALID                = ST_MCU_ADDR+$0000
ST_NUM_RECENT_GAMES         = ST_MCU_ADDR+$0001
ST_PAIRMODE                 = ST_MCU_ADDR+$0002
ST_NUM_FAVORITE_GAMES       = ST_MCU_ADDR+$0003
ST_AUTOBOOT_ENABLED         = ST_MCU_ADDR+$0004

ST_IS_U16                   = ST_SNES_ADDR+$0000
ST_U16_CFG                  = ST_SNES_ADDR+$0001
ST_HAS_SATELLAVIEW          = ST_SNES_ADDR+$0002

MTYPE_FUNC                  = $01
MTYPE_SUBMENU               = $02
MTYPE_VALUE                 = $03
MTYPE_FUNC_CLOSE            = $04

OPTTYPE_NONE                = $00
OPTTYPE_BYTE                = $01
OPTTYPE_WORD                = $02
OPTTYPE_STRING              = $03
OPTTYPE_KVBYTE              = $04
OPTTYPE_KVWORD              = $05
OPTTYPE_FILESEL             = $06
OPTTYPE_TIME                = $07

VIDMODE_NTSC                = $00
VIDMODE_PAL                 = $01
VIDMODE_AUTO                = $02

IDLE_THRES                  = 33000

TYPE_ROM                    = $01
TYPE_SRM                    = $02
TYPE_SPC                    = $03
TYPE_IPS                    = $04
TYPE_CHT                    = $05
TYPE_SKIN                   = $06
TYPE_SUBDIR                 = $40
TYPE_PARENT                 = $80

DIM_BRIGHTNESS              = $03

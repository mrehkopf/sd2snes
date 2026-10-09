;  Savestate code variables defaults
; #define SS_INPUT_SAVE #$2010	; select + r
; #define SS_INPUT_LOAD #$2020 ; select + l
; #define SS_INPUT_COMPARE #$2000 ; select

;  temporary state machine variable
CS_SAVE_REQ   = $FE1000
CS_LOAD_REQ   = $FE1001
CS_SAVE_INPUT = $FE1002
CS_LOAD_INPUT = $FE1004
CS_INPUT_NEXT = $FE1006
CS_INPUT_CUR  = $FE1008
CS_INPUT_PREV = $FE100A
CS_STATE      = $FE100C
CS_DELAY      = $FE100E
CS_SLOT       = $FE100F
CS_SLOT_INPUT = $FE1010
CS_CTRL       = $FE1012
CS_FIXES      = $FE1014

SS_CODE       = $FC0000       ; should be unused
SS_DATA       = $FC2000       ; should be unused
SS_RETURN     = $002C04

; MCU_CMD = $002A00 (defined in memmap.inc)
; SNES_CMD = $002A02 (defined in memmap.inc)
; MCU_PARAM = $002A04 (defined in memmap.inc)

; =======
;  LOROM
; =======
; lorom

;  Savestate code variables
SS_BANK = $C0C0       ; (LSB is irrelevant, padding for PEA)

; #define SRAM_WRAM_7E0000 $710000
; #define SRAM_WRAM_7E8000 $720000
; #define SRAM_WRAM_7F0000 $730000
; #define SRAM_WRAM_7F8000 $740000
; #define SRAM_VRAM_0000 $750000
; #define SRAM_VRAM_8000 $760000
SRAM_DMA_BANK = $F41000
SRAM_PPU_BANK = $F45000
SRAM_OTH_BANK = $F45080
; #define SRAM_CGRAM $772000
; #define SRAM_OAM $772200
; #define SRAM_VALIDITY $774000
SRAM_SAVED_SP = $F46000
; #define SRAM_VM_RETURN $774006
SRAM_SAVED_40 = $F46002

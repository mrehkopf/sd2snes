//  Savestate code variables defaults
// #define SS_INPUT_SAVE #$2010	; select + r
// #define SS_INPUT_LOAD #$2020 ; select + l
// #define SS_INPUT_COMPARE #$2000 ; select

//  temporary state machine variable
#define CS_SAVE_REQ   $FE1000
#define CS_LOAD_REQ   $FE1001
#define CS_SAVE_INPUT $FE1002
#define CS_LOAD_INPUT $FE1004
#define CS_INPUT_NEXT $FE1006
#define CS_INPUT_CUR  $FE1008
#define CS_INPUT_PREV $FE100A
#define CS_STATE      $FE100C
#define CS_DELAY      $FE100E
#define CS_SLOT       $FE100F
#define CS_SLOT_INPUT $FE1010
#define CS_CTRL       $FE1012
#define CS_FIXES      $FE1014

#define SS_CODE       $FC0000 ; should be unused
#define SS_DATA       $FC2000 ; should be unused
#define SS_RETURN     $002C04

#define MCU_CMD       $002A00
#define SNES_CMD      $002A02
#define MCU_PARAM     $002A04

// =======
//  LOROM
// =======
// lorom

//  Savestate code variables
#define SS_BANK $C0C0 // (LSB is irrelevant, padding for PEA)

// #define SRAM_WRAM_7E0000 $710000
// #define SRAM_WRAM_7E8000 $720000
// #define SRAM_WRAM_7F0000 $730000
// #define SRAM_WRAM_7F8000 $740000
// #define SRAM_VRAM_0000 $750000
// #define SRAM_VRAM_8000 $760000
#define SRAM_DMA_BANK $F41000
#define SRAM_PPU_BANK $F45000
#define SRAM_OTH_BANK $F45080
// #define SRAM_CGRAM $772000
// #define SRAM_OAM $772200
// #define SRAM_VALIDITY $774000
#define SRAM_SAVED_SP $F46000
// #define SRAM_VM_RETURN $774006
#define SRAM_SAVED_40 $F46002

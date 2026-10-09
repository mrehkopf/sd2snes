; SD2SNES menu ROM, top-level unit

        .cpu "65816"
        .databank 0             ; bank-0 addresses (registers, low WRAM) are absolute
        .dpage ?                ; direct page only where explicitly specified
; we use -a to be able to map Unicode code points later, but it implies PETSCII
; conversion, so remap to ASCII
        .enc "ascii"
        .cdef " ~", 32

; helper function for long-addressing WRAM where needed
wram    .sfunction _a, _a | $7e0000

        .include "memmap.inc"
        .include "savestate.inc"
        .include "stack.inc"
        .include "dma.inc"
        .include "longbranch.inc"
        .include "menu.inc"

        * = $0000               ; file offset of $0000 => SNES $c00000
        .logical $c00000
        .include "reset.asm"
        .include "main.asm"
        .include "font.asm"
        .include "palette.asm"
        .include "data.asm"
        .include "const.asm"
        .include "logo.asm"
        .include "logospr.asm"
        .include "dma.asm"
        .include "filesel.asm"
        .include "pad.asm"
        .include "time.asm"
        .include "sysinfo.asm"
        .include "spc700.asm"
        .include "spcplay.asm"
        .include "menu.asm"
        .include "menudata.asm"
        .include "ui.asm"
        .include "nmihook.asm"
        .include "common.asm"
        .include "savestate.asm"
        .include "near.asm"
        .cerror * > $c0ff00, "code overlaps header at $C0FF00"
        .endlogical

        * = $ff00
        .logical $c0ff00
        .include "header.asm"
        .endlogical

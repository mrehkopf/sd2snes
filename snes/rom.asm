; SD2SNES menu ROM, top-level unit

        .cpu "65816"
        .databank 0             ; bank-0 addresses (registers, low WRAM) are absolute
        .dpage ?                ; direct page only where explicitly specified
; we use -a to be able to map Unicode code points later, but it implies PETSCII
; conversion, so remap to ASCII
        .enc "ascii"
        .cdef " ~", 32
        .tdef "•™", [149, 153]  ; CP1252, as the font (skin-format.md)
        .edef "…", [$81, $8d]   ; the menu's ellipsis: two characters undefined in CP1252

; helper function for long-addressing WRAM where needed
wram    .sfunction _a, _a | $7e0000

        .include "memmap.inc"
        .include "savestate.inc"
        .include "stack.inc"
        .include "dma.inc"
        .include "longbranch.inc"
        .include "menu.inc"
        .include "print.inc"

; code that runs from WRAM is copied to its run address by store_wram_routines
WRAMCODE_START  = $7ef000       ; run address of wramcode
WRAMCODE_MAX    = $100
; WRAM staging area for bramcode, right after wramcode
; some code is copied further from WRAM to BRAM (after potential FPGA reconfig)
BRAMSTAGE_START = WRAMCODE_START + WRAMCODE_MAX
BRAMCODE_MAX    = $f0           ; snescmd block RAM from BRAM_PAYLOAD (and BRAMSTAGE size)
; the IRQ handler runs in low WRAM: the native IRQ vector (bank 0) points there
IRQCODE_MAX     = $60           ; irqcode_ram in data.asm

        * = $0000               ; file offset of $0000 => SNES $c00000
        .logical $c00000
        .include "reset.asm"
        .include "main.asm"
        .include "data.asm"
        .include "const.asm"
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
        .include "cheat.asm"
        .include "skin.asm"

; code that runs from RAM, at its load address
WRAMCODE_LOAD:
        .logical WRAMCODE_START
WRAMCODE_RUN:
        .dsection wramcode
WRAMCODE_SIZE = * - WRAMCODE_RUN
        .endlogical
BRAMCODE_LOAD:
        .logical BRAM_PAYLOAD
BRAMCODE_RUN:
        .dsection bramcode
BRAMCODE_SIZE = * - BRAMCODE_RUN
        .endlogical
IRQCODE_LOAD:
        .logical irqcode_ram
IRQCODE_RUN:
        .dsection irqcode
IRQCODE_SIZE = * - IRQCODE_RUN
        .endlogical
        .cerror * > $c0ff00, "code overlaps header at $C0FF00"
        .endlogical
        .cerror WRAMCODE_SIZE > WRAMCODE_MAX, format("wramcode too big: $%x bytes (max: $%x)", WRAMCODE_SIZE, WRAMCODE_MAX)
        .cerror BRAMCODE_SIZE > BRAMCODE_MAX, format("bramcode too big: $%x bytes (max: $%x)", BRAMCODE_SIZE, BRAMCODE_MAX)
        .cerror IRQCODE_SIZE > IRQCODE_MAX, format("irqcode too big: $%x bytes (max: $%x)", IRQCODE_SIZE, IRQCODE_MAX)
        .cerror irq_obsel != IRQCODE_RUN, "irq_obsel must start irqcode (IRQ vector)"

        * = $ff00
        .logical $c0ff00
        .include "header.asm"
        .endlogical

; data bank: data that the code reaches with long addresses only
        * = $10000              ; file offset of $10000 => SNES $c10000
        .logical $c10000
        .dsection databank
        .cerror * > $c20000, format("data bank overflows by $%x bytes", * - $c20000)
        .fill $c20000 - *, 0    ; the image size must be a power of two
        .endlogical

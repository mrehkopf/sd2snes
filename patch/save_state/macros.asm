macro a8()
	sep #$20
endmacro

macro a16()
	rep #$20
endmacro

macro i8()
	rep #$10
endmacro

macro ai8()
	sep #$30
endmacro

macro ai16()
	rep #$30
endmacro

macro i16()
	rep #$10
endmacro

macro cgram()
    php
    %a8()
    lda #$00
    sta $2121
    lda $213B
    lda $213B
    plp
endmacro

macro save_registers()
    pha
    phx
    phy
    ;sta !SRAM_REG_A
    ;txa
    ;sta !SRAM_REG_X
    ;tya
    ;sta !SRAM_REG_Y
endmacro

macro load_registers()
    ply
    plx
    pla
    ;lda !SRAM_REG_Y
    ;tay
    ;lda !SRAM_REG_X
    ;tax
    ;lda !SRAM_REG_A
endmacro

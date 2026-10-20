; the default skin, in the skin file format (see skin-format.md): one chunk
; per asset

; gradient lines: count lines of one background color (color 0)
grad_lines .macro count, color
  .rept \count
  .byte 0, 0
  .word \color
  .endrept
.endm

default_skin:

; palette: all of CGRAM
cgen .block
  .skin_chunk "CGEN"
  .word 0, 256                  ; first color, number of colors
  .byte $1f, $7c, $ff, $7f, $c6, $18, $18, $63
  .byte $40, $08, $ff, $43, $c6, $0c, $18, $33
  .byte $60, $0c, $f0, $43, $c3, $0c, $0c, $33
  .byte $80, $10, $b1, $7f, $a1, $24, $ec, $62
  .byte $80, $0c, $ff, $43, $c6, $0c, $18, $33
  .byte $80, $14, $bf, $45, $66, $14, $58, $39
  .byte $a0, $14, $94, $52, $c6, $18, $ce, $39
  .byte $05, $21, $ff, $32, $a7, $10, $38, $2a
  .byte $30, $42, $f0, $43, $c3, $0c, $0c, $33
  .byte $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00
  .byte $0f, $3e, $b1, $7f, $a1, $24, $ec, $62
  .byte $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00
  .byte $cd, $3d, $ff, $43, $c6, $0c, $18, $33
  .byte $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00
  .byte $c1, $18, $bf, $45, $66, $14, $58, $39
  .byte $a5, $14, $79, $7b, $e6, $1c, $63, $0c
  .byte $de, $7f, $bd, $7f, $08, $21, $8c, $31
  .byte $6a, $2d, $08, $25, $61, $29, $00, $21
  .byte $52, $4a, $94, $52, $c6, $18, $ce, $39
  .byte $c4, $45, $45, $5a, $a5, $6e, $e6, $7e
  .byte $c7, $10, $b4, $66, $82, $35, $27, $35
  .byte $8b, $3d, $66, $59, $85, $69, $6f, $76
  .byte $d6, $5a, $ff, $32, $a7, $10, $38, $2a
  .byte $83, $75, $37, $7f, $46, $45, $0a, $7a
  .byte $9b, $7f, $d2, $7a, $15, $7f, $c0, $3c
  .byte $08, $11, $21, $25, $86, $52, $0e, $25
  .byte $d9, $1c, $f1, $1c, $9e, $14, $ef, $1c
  .byte $ca, $18, $9d, $14, $36, $29, $d3, $72
  .byte $50, $5a, $81, $28, $cd, $49, $6a, $26
  .byte $c7, $15, $63, $25, $4f, $23, $ac, $1e
  .byte $05, $0d, $0e, $2b, $25, $0d, $c4, $08
  .byte $62, $04, $e7, $29, $b2, $18, $6c, $0c
  .byte $82, $04, $ce, $19, $31, $1a, $ff, $17
  .byte $dd, $1b, $7b, $1f, $4a, $11, $d6, $1a
  .byte $29, $73, $4d, $63, $50, $4f, $d3, $26
  .byte $b8, $37, $26, $08, $fe, $20, $94, $3f
  .byte $a3, $04, $6b, $2d, $39, $67, $7a, $6b
  .byte $ce, $39, $46, $29, $94, $52, $ad, $35
  .byte $a2, $14, $aa, $35, $c0, $18, $18, $63
  .byte $e0, $1c, $a0, $18, $c3, $18, $29, $25
  .byte $4a, $29, $ff, $7f, $21, $04, $bd, $73
  .byte $fe, $7b, $e7, $18, $42, $08, $00, $00
  .byte $1f, $74, $00, $00, $08, $21, $8c, $31
  .byte $ce, $39, $bd, $77, $7b, $6f, $39, $67
  .byte $d6, $5a, $94, $52, $ff, $7f, $10, $42
  .byte $4a, $29, $84, $10, $c6, $18, $52, $4a
  .byte $1f, $74, $45, $11, $e3, $10, $a1, $0c
  .byte $e8, $19, $4f, $27, $0e, $23, $ed, $22
  .byte $2e, $23, $09, $1a, $cc, $22, $24, $11
  .byte $10, $42, $10, $42, $10, $42, $10, $42
  .byte $1f, $74, $df, $17, $47, $15, $c3, $0c
  .byte $0e, $12, $7b, $13, $b9, $33, $06, $7f
  .byte $2c, $63, $75, $3b, $72, $4f, $93, $16
  .byte $aa, $15, $24, $15, $17, $13, $50, $16
  .byte $1f, $74, $0e, $21, $54, $29, $a6, $14
  .byte $7e, $14, $5a, $2d, $10, $21, $0d, $25
  .byte $eb, $20, $9c, $14, $99, $14, $37, $29
  .byte $f6, $1c, $96, $14, $d3, $1c, $f1, $1c
chunk_end:
.endblock

; font: 256 characters of 16x8 pixels, 4bpp
; text font: characters 16-255, CP1252 (font.py)
font .block
  .skin_chunk "FONT"
  .word 16, 240                 ; first character, number of characters
  .binary "font.chr"
chunk_end:
.endblock

; buttons: characters 0-15 and the colors of their palettes (font.py)
buttons_font .block
  .skin_chunk "FONT"
  .word 0, 16
  .binary "buttons.chr"
chunk_end:
.endblock

  .include "buttons.asm"

; logo: 224 tiles (32x7), 8bpp
logo .block
  .skin_chunk "LOGO"
  .binary "logo.chr"
chunk_end:
.endblock

; background gradient: per line CGADD, CGADD, color
grad .block
  .skin_chunk "GRAD"
  .grad_lines 44, $2d60
  .grad_lines 10, $0000
  .grad_lines 2, $2d60
  .grad_lines 11, $0000
  .grad_lines 11, $0420
  .grad_lines 11, $0840
  .grad_lines 11, $0c60
  .grad_lines 11, $1080
  .grad_lines 11, $14a0
  .grad_lines 11, $18c0
  .grad_lines 11, $1ce0
  .grad_lines 11, $2100
  .grad_lines 11, $2520
  .grad_lines 11, $2940
  .grad_lines 27, $2d60
  .grad_lines 2, $0420
  .grad_lines 11, $2d60
  .grad_lines 7, $0420
chunk_end:
.endblock

; selection bar: height, first line relative to the top line of the row,
; then the lines of the normal and of the active bar: CGADSUB, COLDATA for
; red, green, blue
crsr .block
  .skin_chunk "CRSR"
  .byte 9, 0
  .byte $33, $20|10, $40|15, $80|31 ; normal: upper border
  .rept 7
  .byte $33, $20|10, $40|0, $80|31  ; bar
  .endrept
  .byte $73, $20|10, $40|0, $80|31  ; lower border: half
  .byte $33, $20|22, $40|15, $80|10 ; active: upper border
  .rept 7
  .byte $33, $20|22, $40|0, $80|10  ; bar
  .endrept
  .byte $73, $20|22, $40|0, $80|10  ; lower border: half
chunk_end:
.endblock

; sprites: the paint drips of the logo
oamt .block
  .skin_chunk "OAMT"
  .word (tiles_end - tiles) / 32 ; tiles from OBJ_FIRST_TILE on
  .byte (oam_h - oam_l) / 4     ; sprites
  .byte 0
  .fill GRAD_LINES, 0           ; sprite page per line
oam_l:
  .byte 88, 56, 64, $08
  .byte 104, 56, 66, $08
  .byte 120, 56, 68, $08
  .byte 136, 56, 70, $08
  .byte 88, 72, 72, $08
  .byte 157, 56, 74, $0a
  .byte 172, 56, 76, $0c
  .byte 172, 72, 78, $0c
  .byte 172, 88, 96, $0c
  .byte 194, 56, 98, $0e
  .byte 194, 72, 100, $0e
oam_h:
  .byte 0, 0, 0
tiles:
  .binary "logospr.chr"
tiles_end:
chunk_end:
.endblock

default_skin_end:
  .fill SKIN_HEADER_SIZE, 0     ; no chunk follows (for tools reading the ROM)

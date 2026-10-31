; print constant text at a constant position with print_text (ui.asm)
;   .print_at text, x, y, palette, count
; needs 8-bit A (.call checks the pushed bytes); destroys A and the flags
print_at .macro text, x, y, pal, count
  lda #`\text
  .param pha
  .param pea, <>\text
  lda #\x
  .param pha
  lda #\y
  .param pha
  lda #\pal
  .param pha
  lda #\count
  .param pha
  .call print_text
  .unparam print_text
.endm

; buttons in strings: BUTTON_CODE, then the code of the button (never 0 or
; 1, which end a string). print_text shows the button graphics (BG1, 16
; pixels wide) on an even column, and two characters of text instead on an
; odd one; either way a button takes two columns, like its two bytes.
BUTTON_CODE = $90               ; no character in CP1252
        .edef "{A}", [BUTTON_CODE, 'A']
        .edef "{B}", [BUTTON_CODE, 'B']
        .edef "{X}", [BUTTON_CODE, 'X']
        .edef "{Y}", [BUTTON_CODE, 'Y']
        .edef "{L}", [BUTTON_CODE, 'L']
        .edef "{R}", [BUTTON_CODE, 'R']
        .edef "{START}", [BUTTON_CODE, 'S']
        .edef "{SELECT}", [BUTTON_CODE, 's']
        .edef "{UP}", [BUTTON_CODE, 'u']
        .edef "{DOWN}", [BUTTON_CODE, 'd']
        .edef "{LEFT}", [BUTTON_CODE, 'l']
        .edef "{RIGHT}", [BUTTON_CODE, 'r']

; button_table entry: the code, the BG1 tiles of the button (character 0-15
; and palette, see skin/buttons.asm) in the Japan/Europe and in the US style
; (CFG_BUTTON_STYLE), and the text for odd columns
ButtonEntry .struct code, jp_char, jp_pal, us_char, us_pal, text
  code          .byte \code
  tiles         .word (\jp_char * 2) | (\jp_pal << 10) | $2000, (\us_char * 2) | (\us_pal << 10) | $2000
  text          .text \text
.ends

BUTTON_ENTRY_SIZE = 7           ; (size(ButtonEntry) doesn't count the text)

button_entry .macro code, jp_char, jp_pal, us_char, us_pal, text
_entry:
  .dstruct ButtonEntry, \code, \jp_char, \jp_pal, \us_char, \us_pal, \text
  .cerror * - _entry != BUTTON_ENTRY_SIZE, "a button_table entry has 2 characters of text"
.endm

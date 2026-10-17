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

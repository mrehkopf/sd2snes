waitblank:
  php
  sep #$30
  .as
  .xs
- lda @l $004212
  bmi -
- lda @l $004212
  bpl -
  plp
  rts

; strlen
; characters 0 and 1 are considered "end of string"
; arguments: DB=data bank, Y=offset (16-bit index!)
; return: Y=strlen
strlen:
  php
  rep #$10
  .xl
  sep #$20
  .as
  phx
  ldx #$0000
- lda @w $0,y
  lsr
  beq +
  iny
  inx
  bra -
+ txy
  plx
  plp
  rts

; bin2dec
; convert a number to 5 decimal digits, right-aligned with leading
; spaces, plus a NUL (6 bytes)
; re-entrant (no hardware divider), any D and DB
; params (push order): p_buf (long: bank, then address), p_value (word)
bin2dec .block
  .virtual #0,d
Frame .block
  value         .word ?         ; what is left to convert
  digit         .word ?
  started       .word ?         ; non-zero once a digit other than 0 was written
  _             .dstruct SaveJSR
  p_value       .word ?         ; pushed last
  p_buf         .long ?         ; pushed first
.endblock
  .endvirtual
  .enter
  rep #$30
  .al
  .xl
  lda Frame.p_value
  sta Frame.value
  stz Frame.started
  ldy #$0000                    ; position in the buffer
  ldx #$0000                    ; power of ten
next_digit:
  stz Frame.digit
- lda Frame.value
  cmp @l powers,x
  bcc +
  sbc @l powers,x               ; (carry is set)
  sta Frame.value
  inc Frame.digit
  bra -
+ lda Frame.digit
  ora Frame.started
  bne +
  lda #' '                      ; leading zero
  bra store
+ lda Frame.digit
  ora #'0'
  sta Frame.started
store:
  sta [Frame.p_buf],y           ; (the high byte is overwritten next)
  iny
  inx
  inx
  cpx #powers_end - powers
  bcc next_digit
  lda Frame.value               ; last digit, followed by the NUL
  ora #'0'
  sta [Frame.p_buf],y
  .leave
  rts

powers:
  .word 10000, 1000, 100, 10
powers_end:
.endblock

; bin2dec16
; arguments: A=value (16 bits)
; return: 6 bytes of ASCII decoded decimal (5 digits+NUL) in stringbuf
; (for code not converted to bin2dec yet)
bin2dec16:
  php
  rep #$30
  .al
  .xl
  tax
  sep #$20
  .as
  lda #`wram(stringbuf)
  .param pha
  rep #$20
  .al
  .param pea, stringbuf
  .param phx
  .call bin2dec
  .unparam bin2dec
  plp
  rts

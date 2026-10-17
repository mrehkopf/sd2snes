; sysinfo.a65: display sysinfo text block
.text "===SHOW_SYSINFO==="
show_sysinfo .block
; menu function (called via RTL)
  .virtual #0,d
Frame .block
  system        .fill 40        ; text_system with the values filled in
  src           .word ?         ; current line of SYSINFO_BLK
  y             .byte ?         ; its row
  lines         .byte ?         ; lines left
  _             .dstruct SaveJSL
.endblock
  .endvirtual
  .enter
  phb
  sep #$20
  .as
  rep #$10
  .xl
  lda #$80
  pha
  plb
  stz bar_wl
  dec bar_wl
  stz bar_xl
  dec bar_xl
  stz bar_yl
  dec bar_yl
  lda #`mtext_mm_sysinfo
  sta window_tbank
  ldx #<>mtext_mm_sysinfo
  stx window_taddr
  lda @l sysinfo_win_x
  sta window_x
  lda @l sysinfo_win_y
  sta window_y
  lda @l sysinfo_win_w
  sta window_w
  lda @l sysinfo_win_h
  sta window_h
  jsr push_window
  jsr draw_window

  ldx #38
copy_snes_system_text:
  lda @l text_system,x
  sta Frame.system,x
  dex
  bpl copy_snes_system_text

sysinfo_printloop:
  sep #$20
  .as
  rep #$10
  .xl
  lda #CMD_SYSINFO
  sta @l MCU_CMD
- lda @l SNES_CMD
  cmp #CMD_SYSINFO
  bne -
  ldx #<>SYSINFO_BLK            ; 12 lines of 40 characters from the MCU
  stx Frame.src
  lda @l sysinfo_win_y
  inc a
  inc a
  sta Frame.y
  lda #12
  sta Frame.lines
- lda #`SYSINFO_BLK
  .param pha
  ldx Frame.src
  .param phx
  lda @l sysinfo_win_x
  inc a
  inc a
  .param pha
  lda Frame.y
  .param pha
  lda #$00
  .param pha
  lda #40
  .param pha
  .call print_text
  .unparam print_text
  inc Frame.y
  rep #$20
  .al
  lda Frame.src
  clc
  adc #40
  sta Frame.src
  sep #$20
  .as
  dec Frame.lines
  bne -
  ldx #17
  lda $213e
  and #$0f
  clc
  adc #$30
  sta Frame.system,x
  ldx #19
  lda $213f
  and #$0f
  clc
  adc #$30
  sta Frame.system,x
  ldx #15
  lda $4210
  and #$0f
  clc
  adc #$30
  sta Frame.system,x
  ldx #35
  lda $213f
  eor #$10
  and #$10
  adc #$f0
  lda #$35
  adc #$00
  sta Frame.system,x
  lda #$00                      ; System text, in the frame (bank 0)
  .param pha
  rep #$20
  .al
  tdc
  clc
  adc #Frame.system - Frame
  .param pha
  sep #$20
  .as
  lda #12
  .param pha
  lda #23
  .param pha
  lda #$00
  .param pha
  lda #39
  .param pha
  .call print_text
  .unparam print_text
- lda isr_done
  lsr
  bcc -
  jsr printtime
  jsr read_pad
  lda pad_b
  ora pad_a
  bne +
  jmp sysinfo_printloop
+ lda #CMD_MCU_RDY
  sta @l MCU_CMD
- cmp @l SNES_CMD
  bne -
  jsr pop_window
  plb
  .leave
  rtl
.endblock

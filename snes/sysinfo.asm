; sysinfo.a65: display sysinfo text block
.text "===SHOW_SYSINFO==="
show_sysinfo:
  php
  sep #$20
  .as
  rep #$10
  .xl
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
  inc a
  inc a
  pha
  stz print_x+1
  lda @l sysinfo_win_y
  sta window_y
  inc a
  inc a
  pha
  stz print_y+1
  lda @l sysinfo_win_w
  sta window_w
  lda @l sysinfo_win_h
  sta window_h
  jsr push_window
  jsr draw_window
  stz print_pal

  ldx #38
copy_snes_system_text:
  lda @l text_system,x
  sta wram(snes_system_config),x
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
  lda #`SYSINFO_BLK
  ldx #<>SYSINFO_BLK
  sta print_bank
  stx print_src
  stz print_pal
  pla
  sta print_y
  pla
  sta print_x
  lda #40
  sta print_count
  lda #12
- pha
  jsr hiprint
  inc print_y
  rep #$20
  .al
  lda print_src
  clc
  adc #40
  sta print_src
  sep #$20
  .as
  pla
  dec a
  bne -

  ldx #17
  lda $213e
  and #$0f
  clc
  adc #$30
  sta wram(snes_system_config),x

  ldx #19
  lda $213f
  and #$0f
  clc
  adc #$30
  sta wram(snes_system_config),x

  ldx #15
  lda $4210
  and #$0f
  clc
  adc #$30
  sta wram(snes_system_config),x

  ldx #35
  lda $213f
  eor #$10
  and #$10
  adc #$f0
  lda #$35
  adc #$00
  sta wram(snes_system_config),x

  lda #`wram(snes_system_config) ; System text
  ldx #snes_system_config
  sta print_bank
  stx print_src
  stz print_pal
  lda #39
  sta print_count
  lda #23
  sta print_y
  lda #12
  sta print_x
  jsr hiprint

- lda isr_done
  lsr
  bcc -
  jsr printtime
  jsr read_pad
  lda pad_b
  ora pad_a
  bne +
  lda @l sysinfo_win_x
  inc a
  inc a
  pha
  lda @l sysinfo_win_y
  inc a
  inc a
  pha
  jmp sysinfo_printloop
+ plp
  lda #CMD_MCU_RDY
  sta @l MCU_CMD
- cmp @l SNES_CMD
  bne -
  jsr pop_window
  rtl

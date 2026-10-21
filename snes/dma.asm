NMITIMEN        = $b1           ; VBlank NMI, H/V timer IRQ (irq_obsel), auto joypad read
HDMA_CHANNELS   = %01111011     ; channels 0, 1, 3-6 (setup_hdma)
OBSEL_HTIME     = 16            ; the dot where irq_obsel's timer fires
OBSEL_VBLANK    = 225           ; VTIME of the chain's first entry (VBlank)

killdma:
  php
  rep #$20
  .al
  sep #$10
  .xs
  stz $420b
  lda #$ffff
  ldy #$7c
- dey
  dey
  sta $4300,y
  bne -
  plp
  rts

setup_hdma:
  sep #$20
  .as
  rep #$10
  .xl

  lda #$02      ;A to B; direct; 2x single reg
  sta $4300     ;ch. 0 for y scroll
  lda #$10      ;2110 = BG2VOFS
  sta $4301
  lda #`wram(hdma_bg2scroll)
  ldy #hdma_bg2scroll
  sty $4302
  sta $4304

  lda #$03      ;A to B; direct; 2x 2x single reg
  sta $4310     ;ch. 1 for the background gradient
  lda #$21      ;2121 = CG addr, 2122 = CG data
  sta $4311
  lda #`wram(hdma_grad)
  ldy #hdma_grad
  sty $4312
  sta $4314

  lda #$00      ;A to B; direct; 1x single reg
  sta $4330     ;ch. 3 for mode switch
  lda #$05      ;2105 = BG mode
  sta $4331
  lda #`wram(hdma_mode)
  ldy #hdma_mode
  sty $4332
  sta $4334

  lda #$03      ;A to B; direct; 2x 2x single reg
  sta $4340     ;ch. 4 for scroll
  lda #$0d      ;210d = BG1HOFS
  sta $4341
  lda #`wram(hdma_bg1scroll)
  ldy #hdma_bg1scroll
  sty $4342
  sta $4344

  lda #$01      ;A to B; direct; 1x two reg
  sta $4350     ;ch. 5 for the selection bar
  lda #$31      ;2131 + 2132 = math, color constant
  sta $4351
  lda #`wram(hdma_bar1)
  ldy #hdma_bar1
  sty $4352
  sta $4354

  lda #$02      ;A to B; direct; 2x single reg
  sta $4360     ;ch. 6 for the selection bar
  lda #$32      ;2132 = color constant
  sta $4361
  lda #`wram(hdma_bar2)
  ldy #hdma_bar2
  sty $4362
  sta $4364

  ldx #OBSEL_HTIME
  stx $4207     ;HTIME (build_obsel sets VTIME)
  jsr waitblank
  lda #HDMA_CHANNELS
  sta $420c     ;enable HDMA
  lda #NMITIMEN
  sta $4200     ;enable V-BLANK NMI, H/V timer IRQ
  cli
  rts

; ROM header, reset/interrupt stubs and vectors at $C0FF00
hdr_start:
; pointer to the in-game NMI/IRQ hook, read by firmware (snescmd_prepare_nmihook)
  .word <>nmihook

RESET:
  sei
  clc
  xce
  rep #$20
  .al
  lda #$1fff
  tcs
  jml GAME_MAIN

NMI_16bit:
  php
    rep #$30
    .al
    .xl
    pha
    phx
    phy
    phd
    phb
    jsl NMI_ROUTINE
    rep #$30
    .al
    .xl
int_exit:
    plb
    pld
    ply
    plx
    pla
  plp
  rti

IRQ_16bit:
  php
    rep #$30
    .al
    .xl
    pha
    phx
    phy
    phd
    phb
    jsl IRQ_ROUTINE
    rep #$30
    .al
    .xl
    bra int_exit

;error vectors
ABT_8bit:
ABT_16bit:
BRK_8bit:
BRK_16bit:
COP_8bit:
COP_16bit:
IRQ_8bit:
NMI_8bit:
- wai
  lda $abcdef
  bra -

  .fill $B0 - (* - hdr_start), 0
  .text "MR"            ; 2 bytes - company id
  .text "SNSD"          ; 4 bytes - rom id

  .fill $C0 - (* - hdr_start), 0
  .text "SD2SNES MENU v1.12.0 "
;        123456789012345678901  -  max 21 chars
  .cerror * - hdr_start != $D5, "ROM title must be exactly 21 characters"
  .byte $31             ; rom map + speed (HiROM FastROM)
  .byte $55             ; rom type   SRTC
  .byte $06             ; rom size   64 kByte
  .byte $03             ; sram size  8 kBit
  .byte $01             ; rom region 1 = USA
  .byte $33             ; company id flag
  .byte $00             ; version
  .word $0000, $0000    ; checksum complement, checksum (written by sneschksum)

  .fill $E4 - (* - hdr_start), 0
; native mode vectors
  .word <>COP_16bit
  .word <>BRK_16bit
  .word <>ABT_16bit
  .word <>NMI_16bit
  .word $0000
  .word <>IRQ_16bit
; emulation mode vectors
  .fill 4, 0
  .word <>COP_8bit
  .word $0000
  .word <>ABT_8bit
  .word <>NMI_8bit
  .word <>RESET
  .word <>IRQ_8bit      ; IRQ/BRK
  .cerror * - hdr_start != $100, "header overflows $C0FFFF!"

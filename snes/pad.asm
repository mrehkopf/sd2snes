pad_init:
  php
  rep #$30
  .xl
  .al
  stz pad1mem
  stz pad1trig
  plp
  rts

; read controllers 1 and 2 directly (with auto joypad read off), e.g. at
; power-on before NMI is enabled
; returns: A (16-bit): the buttons of both, as in $4218 (BYsSudlrAXLR0000)
read_pad_serial:
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda #$01
  sta @l $004016  ; latch the buttons
  dec a
  sta @l $004016
  ldy #$0000
  ldx #16
- lda @l $004016  ; bit 0: next button of controller 1
  ora @l $004017  ; (controller 2)
  lsr
  rep #$20
  .al
  tya
  rol
  tay
  sep #$20
  .as
  dex
  bne -
  rep #$20
  .al
  tya
  plp
  rts

read_pad:
  php
  phb
    sep #$20
    .as
    lda #$80
    pha
    plb
    rep #$30
    .xl
    .al
    stz pad_b      ; (including y)
    stz pad_select ; (including start)
    stz pad_up     ; (including down)
    stz pad_left   ; (including right)
    stz pad_a      ; (including x)
    stz pad_l      ; (including r)

read_pad1:        ; byetUDLRaxlriiii
    ldx pad1mem   ; save previous state of the buttons for later
    lda $4218     ; Controller 1
    and #$000f    ; ignore non-standard controllers (ID != 0)
    bne +
    lda $4218
+   sta pad1mem
    lda $421a     ; Controller 2
    and #$000f    ; ignore non-standard controllers (ID != 0)
    bne +
    lda $421a
+   ora pad1mem   ; combine buttons of both controllers
    sta pad1mem
    and #$0f00    ; UDLR = directional buttons support auto-repeat
    bne read_pad1_count
    stz pad1delay
read_pad1_cont1:
    txa           ; restore previous state of the buttons in A for comparison (for button press event detection)
    eor pad1mem
    and pad1mem
    sta pad1trig
    lda #$0010
    cmp pad1delay
    bne read_pad1_cont2
    stz pad1mem
    lda #$000d
    sta pad1delay
read_pad1_cont2:
    lda pad1trig
    sep #$20
    .as
    rol
    rol pad_a
    rol
    rol pad_x
    rol
    rol pad_l
    rol
    rol pad_r
    xba
    rol
    rol pad_b
    rol
    rol pad_y
    rol
    rol pad_select
    rol
    rol pad_start
    rol
    rol pad_up
    rol
    rol pad_down
    rol
    rol pad_left
    rol
    rol pad_right
  plb
  plp
  rts

read_pad1_count:
    lda pad1delay
    inc a
    sta pad1delay
    bra read_pad1_cont1

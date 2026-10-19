; skin assets and the HDMA tables built from them
;
; Assets that change per scanline come as per-line data; the menu builds
; the HDMA tables from it:
; - background gradient: channel 1 writes CGADD twice and CGDATA twice per
;   line (build_grad)
; - sprite pages: channel 2 writes OBSEL (build_obsel)
; - selection bar: channel 5 writes CGADSUB and COLDATA, channel 6 writes
;   COLDATA twice, so every bar line sets a full RGB color (set_bar_color)

GRAD_LINES      = 224           ; lines of per-line data (gradient, sprite pages)
BAR_MAX_LINES   = 16            ; selection bar height

HDMA_GRAD_SIZE  = 1 + 127*4 + 1 + (GRAD_LINES-127)*4 + 1
HDMA_OBSEL_SIZE = GRAD_LINES*2 + 1 ; worst case: a new page on every line
HDMA_BAR_SIZE   = 3 + 3 + 1 + BAR_MAX_LINES*2 + 3 + 1

; build the background gradient table for HDMA channel 1
; NMI must be off: uses DMA channel 7 and the WRAM port
; params: p_src (long): GRAD_LINES records [CGADD, CGADD, color lo, color hi]
build_grad .block
  .virtual #0,d
Frame .block
  _             .dstruct SaveJSR
  p_src         .long ?         ; records (pushed first: bank, then address)
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  rep #$10
  .xl
  ldx #hdma_grad
  stx $2181
  lda #`wram(hdma_grad)
  sta $2183
  stz $4370                     ; A to B, increment
  lda #$80                      ; WRAM port ($2180)
  sta $4371
  ldx Frame.p_src
  stx $4372
  lda Frame.p_src+2
  sta $4374
  lda #$80 | 127                ; repeat mode: one record per line
  sta $2180
  ldx #127*4
  stx $4375
  lda #$80
  sta $420b
  lda #$80 | (GRAD_LINES-127)   ; the remaining lines; the DMA source
  sta $2180                     ; address continues
  ldx #(GRAD_LINES-127)*4
  stx $4375
  lda #$80
  sta $420b
  stz $2180                     ; end of table
  .leave
  rts
.endblock

; build the sprite page table for HDMA channel 2 (OBSEL): one entry per run
; of lines with the same page, so OBSEL is written only where the page
; changes (and every 127 lines). The last run gets a single line: OBSEL keeps
; its value after the end of the table, so a skin without page changes
; writes OBSEL once per frame, at line 0.
; params: p_src (long): GRAD_LINES page numbers (0-2: sprite tiles 256-511
;         at OBJ_PAGES_BASE + page * $1000)
build_obsel .block
  .virtual #0,d
Frame .block
  count         .byte ?         ; lines in the current run
  value         .byte ?         ; OBSEL value of the current run
  last          .word ?         ; first line of the last run
  _             .dstruct SaveJSR
  p_src         .long ?         ; page numbers (pushed first: bank, then address)
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  rep #$10
  .xl
  ldy #GRAD_LINES-1             ; find the last run
  jsr obsel_value
  sta Frame.value
- dey
  bmi +
  jsr obsel_value
  cmp Frame.value
  beq -
+ iny
  sty Frame.last
  ldx #$0000                    ; table offset
  ldy #$0000                    ; line
  cpy Frame.last
  beq last_run
run:
  jsr obsel_value
  sta Frame.value
  stz Frame.count
same:
  inc Frame.count
  iny
  cpy Frame.last
  beq emit
  lda Frame.count
  cmp #127
  beq emit
  jsr obsel_value
  cmp Frame.value
  beq same
emit:
  lda Frame.count
  sta wram(hdma_obsel),x
  inx
  lda Frame.value
  sta wram(hdma_obsel),x
  inx
  cpy Frame.last
  bne run
last_run:
  lda #1                        ; Y = Frame.last
  sta wram(hdma_obsel),x
  inx
  jsr obsel_value
  sta wram(hdma_obsel),x
  inx
  lda #$00                      ; end of table
  sta wram(hdma_obsel),x
  .leave
  rts

; OBSEL value for line Y
obsel_value:
  .as
  .xl
  lda [Frame.p_src],y
  and #$03
  asl
  asl
  asl
  ora #OBSEL_PAGE0
  rts
.endblock

; set_bar_color: build the selection bar tables (HDMA channels 5 and 6)
; from the cursor asset at crsr_ptr; the NMI fills in the lines above the
; bar (bytes 0 and 3 of both tables)
; params: p_variant: 0: normal, 1: active (editing a value)
; keeps X and Y
set_bar_color .block
  .virtual #0,d
Frame .block
  src           .long ?         ; cursor asset
  lines         .word ?         ; bar lines left
  _             .dstruct SaveJSR
  p_variant     .byte ?
.endblock
  .endvirtual
  .enter
  rep #$30
  .al
  .xl
  phx
  phy
  lda wram(crsr_ptr)
  sta Frame.src
  lda wram(crsr_ptr+1)
  sta Frame.src+1
  lda [Frame.src]               ; height (low byte), first line (high byte)
  sep #$20
  .as
  xba
  sta wram(bar_yoffset)
  xba
  rep #$20
  .al
  and #$00ff
  sta Frame.lines
  ldy #$0002                    ; the records of variant 0 follow
  lda Frame.p_variant
  and #$00ff
  beq +
  lda Frame.lines               ; variant 1: after h records of 4 bytes
  asl
  asl
  adc #$0002
  tay
+ sep #$20
  .as
  lda Frame.lines
  ora #$80                      ; repeat mode: one record per line
  sta wram(hdma_bar1+6)
  sta wram(hdma_bar2+6)
  lda #$00
  sta wram(hdma_bar1+1)         ; lines above the bar: no color math,
  sta wram(hdma_bar1+2)         ; COLDATA without a color selected
  sta wram(hdma_bar1+4)
  sta wram(hdma_bar1+5)
  sta wram(hdma_bar2+1)
  sta wram(hdma_bar2+2)
  sta wram(hdma_bar2+4)
  sta wram(hdma_bar2+5)
  rep #$20
  .al
  ldx #$0000
- lda [Frame.src],y             ; CGADSUB, first COLDATA
  sta wram(hdma_bar1+7),x
  iny
  iny
  lda [Frame.src],y             ; second and third COLDATA
  sta wram(hdma_bar2+7),x
  iny
  iny
  inx
  inx
  dec Frame.lines
  bne -
  lda #$0001                    ; after the bar: 1 line without color math
  sta wram(hdma_bar1+7),x       ; and black, then the end of the table
  sta wram(hdma_bar2+7),x
  lda #$00e0
  sta wram(hdma_bar1+9),x
  lda #$0000
  sta wram(hdma_bar2+9),x
  ply
  plx
  .leave
  rts
.endblock

; ---------------------------------------------------------------------------
; default skin

; gradient lines: count lines of one background color (color 0)
grad_lines .macro count, color
  .rept \count
  .byte 0, 0
  .word \color
  .endrept
.endm

  .section databank
default_grad:
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
  .cerror * - default_grad != GRAD_LINES * 4, "default_grad must have GRAD_LINES lines"

default_obsel:
  .fill GRAD_LINES, 0           ; page 0 on every line

; selection bar: height, first line relative to the top line of the row,
; then the lines of the normal and of the active bar: CGADSUB, COLDATA for
; red, green, blue
default_crsr:
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
  .send databank

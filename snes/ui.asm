.text "===HIPRINT==="
; print a string in mode 5 using pseudo-8x8 tiles on two BG layers:
; even columns go to BG2, odd columns to BG1.
; characters 0 and 1 are considered "end of string".
; re-entrant: everything lives in the stack frame, any D and DB
; params (push order): p_src (long: bank, then address), p_x, p_y, p_pal,
; p_count (only these characters at most)
; returns:
; A: number of characters printed
; X: the character after them, bit 0 cleared (0 = end of string reached)
print_text .block
  .virtual #0,d
Frame .block
  attr          .word ?         ; palette and priority bits of the tiles
  count         .word ?         ; p_count
  offset        .word ?         ; column, then offset in the tile buffers
  _             .dstruct SaveJSR
  p_count       .byte ?         ; maximum number of characters, pushed last
  p_pal         .byte ?         ; palette
  p_y           .byte ?         ; row
  p_x           .byte ?         ; column
  p_src         .long ?         ; string, pushed first (bank, then address)
.endblock
  .endvirtual
  .enter
  rep #$30
  .al
  .xl
  lda Frame.p_pal
  and #$00ff
  xba
  asl
  asl
  ora #$2000
  sta Frame.attr
  ldy #$0000
  lda Frame.p_count
  and #$00ff
  sta Frame.count
  beq out
  lda Frame.p_x                 ; offset in the tile buffers:
  and #$00ff                    ; 64 * row + column, word aligned
  sta Frame.offset
  lda Frame.p_y
  and #$00ff
  xba
  lsr
  lsr
  clc
  adc Frame.offset
  and #$fffe
  tax
  lda Frame.p_x
  lsr
  bcs bg1
bg2:
  lda [Frame.p_src],y
  ror
  and #$007f
  beq out
  rol
  asl
  ora Frame.attr
  sta @l BG2_TILE_BUF,x
  iny
  cpy Frame.count
  beq out
bg1:
  lda [Frame.p_src],y
  ror
  and #$007f
  beq out
  rol
  asl
  ora Frame.attr
  sta @l BG1_TILE_BUF,x
  inx
  inx
  iny
  cpy Frame.count
  bne bg2
out:
  lda [Frame.p_src],y           ; character after the printed ones
  and #$00fe
  tax
  .leave
  tya
  rts
.endblock

; draw the current window (window_x/y/w/h) with its title (window_taddr/
; window_tbank, none if the string is empty)
draw_window .block
  .virtual #0,d
Frame .block
  row           .fill 64        ; text of one window row
  title         .long ?         ; window title
  x             .byte ?         ; where print_str prints
  y             .byte ?
  count         .byte ?         ; characters print_str prints at most
  done          .byte ?         ; characters print_str printed
  rows          .word ?         ; rows left to draw
  _             .dstruct SaveJSR
.endblock
  .endvirtual
  phb
  .enter
  sep #$20
  .as
  rep #$10
  .xl
  lda #$80
  pha
  plb
  lda window_x
  sta Frame.x
  lda window_y
  sta Frame.y
  lda window_w
  sta Frame.count
; upper border
  lda @l window_nh
  jsr fill_row
  lda @l window_nw
  sta Frame.row
  lda @l window_ne
  jsr set_last
  jsr print_row
; title, if not empty
  ldx window_taddr
  stx Frame.title
  lda window_tbank
  sta Frame.title+2
  lda [Frame.title]
  beq notitle
  inc Frame.x
  inc Frame.x
  lda #$01
  sta Frame.count
  lda #`window_tl
  ldx #<>window_tl
  jsr print_str
  inc Frame.x
  lda window_w
  sta Frame.count
  lda window_tbank
  ldx window_taddr
  jsr print_str
  lda Frame.done
  clc
  adc Frame.x
  sta Frame.x
  lda #$01
  sta Frame.count
  lda #`window_tr
  ldx #<>window_tr
  jsr print_str
  lda window_x
  sta Frame.x
  lda window_w
  sta Frame.count
notitle:
; left and right borders, space inside the window
  lda @l space64
  jsr fill_row
  lda @l window_wv
  sta Frame.row
  lda @l window_ev
  jsr set_last
  rep #$20
  .al
  lda window_h
  and #$00ff
  dec a
  dec a
  sta Frame.rows
  sep #$20
  .as
- inc Frame.y
  jsr print_row
  rep #$20
  .al
  dec Frame.rows
  sep #$20
  .as
  bne -
; lower border
  lda @l window_sh
  jsr fill_row
  lda @l window_sw
  sta Frame.row
  lda @l window_se
  jsr set_last
  inc Frame.y
  jsr print_row
  .leave
  plb
  rts

; helpers in the frame of draw_window

; fill Frame.row with window_w times A
fill_row:
  .as
  pha
  rep #$20
  .al
  lda window_w
  and #$00ff
  tax
  sep #$20
  .as
  pla
- dex
  bmi +
  sta Frame.row,x
  bra -
+ rts

; put A at the last position of Frame.row
set_last:
  .as
  pha
  rep #$20
  .al
  lda window_w
  and #$00ff
  dec a
  tax
  sep #$20
  .as
  pla
  sta Frame.row,x
  rts

; print Frame.row
print_row:
  .as
  lda #$00                      ; on the stack: bank 0
  pha
  rep #$20
  .al
  tdc
  clc
  adc #Frame.row - Frame
  tax
  sep #$20
  .as
  pla
; print the string at A:X (bank:address) at Frame.x/y in the window frame
; palette, at most Frame.count characters; sets Frame.done
print_str:
  .as
  .param pha
  rep #$20
  .al
  txa
  .param pha
  sep #$20
  .as
  lda Frame.x
  .param pha
  lda Frame.y
  .param pha
  lda #$03
  .param pha
  lda Frame.count
  .param pha
  .call print_text
  sta Frame.done
  .unparam print_text
  rts
.endblock

draw_loading_window:
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda @l loading_win_x
  sta window_x
  lda listdisp
  clc
  adc #$0a
  sta window_y
  lda @l loading_win_w
  sta window_w
  lda @l loading_win_h
  sta window_h
  jsr push_window
  lda #`text_loading
  .param pha
  .param pea, <>text_loading
  lda window_x
  .param pha
  lda window_y
  .param pha
  lda #$00
  .param pha
  lda window_w
  .param pha
  .call print_text
  .unparam print_text
  plp
  rts


; window stack: entries at WINDOW_STACK_BASE + window_stack_head, each a
; WindowStackEntry followed by the saved tile map rows of the window area
; first BG1, then BG2 (2 * <height> rows of <width bytes rounded up to words>)
WindowStackEntry .struct
  prevptr       .word ?         ; offset of the previous entry, $ffff = none
  xpos          .word ?         ; window_x
  ypos          .word ?         ; window_y
  width         .word ?         ; window_w
  height        .word ?         ; window_h
  cursor        .word ?         ; listsel_sel
  step          .word ?         ; listsel_step
  maxcursor     .word ?         ; listsel_max
.ends
; (listsel_* are kept with the window stack in case nested selection lists are
;  invoked; in other cases they are unused but do no harm)

; save_rows/restore_rows use one MVN bank operand for both tile buffers
.cerror (`BG1_TILE_BUF) != `BG2_TILE_BUF, "BG1_TILE_BUF and BG2_TILE_BUF must share a bank"

; save the area of the current window (window_x/y/w/h) on the window stack
push_window .block
  .virtual #0,d
Frame .block
  count         .word ?         ; bytes per row - 1, for MVN
  height        .word ?         ; rows of the window
  rows          .word ?         ; rows left in the current pass
  buf_offset    .word ?         ; offset of the window in the tile buffers
  buf_addr      .word ?         ; current row in the tile buffer
  _             .dstruct SaveJSR
.endblock
  .endvirtual
  phb
  .enter
  sep #$20
  .as
  lda #$80
  pha
  plb
  rep #$30
  .al
  .xl
; write pointer to current head
  lda window_stack_head
  cmp #$ffff
  bne pushw_skip_current_head
; empty stack - initialize
  ldx #$0000
  stx window_stack_head
  lda #$ffff
  bra pushw_write_element
pushw_skip_current_head:
; calculate address of next stack element
  tax
  phx                 ; save "previous" head
  lda @l WINDOW_STACK_BASE+WindowStackEntry.width,x
  and #$00fe
  clc
  adc #$0002
  sep #$20
  .as
  sta $211b
  stz $211b
  lda @l WINDOW_STACK_BASE+WindowStackEntry.height,x
  sta $211c
  rep #$20
  .al
  lda $2134
  asl
  clc
  adc #size(WindowStackEntry)
  adc window_stack_head
  sta window_stack_head
  tax
  pla                 ; restore "previous" head
pushw_write_element:
  sta @l WINDOW_STACK_BASE+WindowStackEntry.prevptr,x
; write current window position and dimensions
  lda window_x
  and #$00ff
  sta @l WINDOW_STACK_BASE+WindowStackEntry.xpos,x
  lda window_y
  and #$00ff
  sta @l WINDOW_STACK_BASE+WindowStackEntry.ypos,x
  lda window_w
  and #$00ff
  sta @l WINDOW_STACK_BASE+WindowStackEntry.width,x
  ora #$0001
  sta Frame.count
  lda window_h
  and #$00ff
  sta @l WINDOW_STACK_BASE+WindowStackEntry.height,x
  sta Frame.height
  lda listsel_sel
  and #$00ff
  sta @l WINDOW_STACK_BASE+WindowStackEntry.cursor,x
  lda listsel_step
  and #$00ff
  sta @l WINDOW_STACK_BASE+WindowStackEntry.step,x
  lda listsel_max
  and #$00ff
  sta @l WINDOW_STACK_BASE+WindowStackEntry.maxcursor,x
  lda @l WINDOW_STACK_BASE+WindowStackEntry.ypos,x
  xba                 ; calculate start offset (64*window_y + window_x)
  lsr
  lsr
  clc
  adc @l WINDOW_STACK_BASE+WindowStackEntry.xpos,x
  and #$fffe          ; align to 16 bit
  sta Frame.buf_offset
  lda window_stack_head
  clc
  adc #size(WindowStackEntry)
  adc #<>WINDOW_STACK_BASE
  tay                 ; destination address (incremented by MVN)
  lda #<>BG1_TILE_BUF
  jsr save_rows
  lda #<>BG2_TILE_BUF
  jsr save_rows
  .leave
  plb
  rts

; copy Frame.height rows of the window from the tile buffer at A to the
; window stack at Y
save_rows:
  clc
  adc Frame.buf_offset
  sta Frame.buf_addr
  lda Frame.height
  sta Frame.rows
- ldx Frame.buf_addr
  lda Frame.count
  mvn #`BG1_TILE_BUF, #`WINDOW_STACK_BASE
  lda Frame.buf_addr
  clc
  adc #$0040
  sta Frame.buf_addr
  dec Frame.rows
  bne -
  rts
.endblock


; restore the area of the topmost window stack entry and the window
; dimensions of the entry below it (if any, otherwise of the restored one)
pop_window .block
  .virtual #0,d
Frame .block
  count         .word ?         ; bytes per row - 1, for MVN
  height        .word ?         ; rows of the window
  rows          .word ?         ; rows left in the current pass
  buf_offset    .word ?         ; offset of the window in the tile buffers
  buf_addr      .word ?         ; current row in the tile buffer
  _             .dstruct SaveJSR
.endblock
  .endvirtual
  phb
  .enter
  sep #$20
  .as
  lda #$80
  pha
  plb
  rep #$30
  .al
  .xl
; write pointer to current head
  lda window_stack_head
  tax
  cmp #$ffff
  bne popw_rewind_head
; empty stack - do nothing
  .leave
  plb
  rts
popw_rewind_head:
; restore data needed to recover from current window
  lda @l WINDOW_STACK_BASE+WindowStackEntry.width,x
  ora #$0001
  sta Frame.count
  lda @l WINDOW_STACK_BASE+WindowStackEntry.height,x
  sta Frame.height
  sep #$20
  .as
  lda @l WINDOW_STACK_BASE+WindowStackEntry.cursor,x
  sta listsel_sel
  lda @l WINDOW_STACK_BASE+WindowStackEntry.step,x
  sta listsel_step
  lda @l WINDOW_STACK_BASE+WindowStackEntry.maxcursor,x
  sta listsel_max
  rep #$20
  .al
  lda @l WINDOW_STACK_BASE+WindowStackEntry.ypos,x
  xba                 ; calculate dest offset (64*window_y + window_x)
  lsr
  lsr
  clc
  adc @l WINDOW_STACK_BASE+WindowStackEntry.xpos,x
  and #$fffe          ; align to 16 bit
  sta Frame.buf_offset
  lda window_stack_head
  clc
  adc #size(WindowStackEntry)
  adc #<>WINDOW_STACK_BASE
  tax                 ; source address (incremented by MVN)
  phb                 ; MVN sets DB to the tile buffer bank; keep DB=$80 for the code below
    lda #<>BG1_TILE_BUF
    jsr restore_rows
    lda #<>BG2_TILE_BUF
    jsr restore_rows
  plb
; restore address of previous stack element
  ldx window_stack_head
  txy
  lda @l WINDOW_STACK_BASE+WindowStackEntry.prevptr,x
  tax
  sta window_stack_head
  sep #$20
  .as
; peek into previous head (if any) to restore dimensions of previous window
; otherwise restore dimensions of current window
  cpx #$ffff
  bne +
  tyx
+ lda @l WINDOW_STACK_BASE+WindowStackEntry.xpos,x
  sta window_x
  lda @l WINDOW_STACK_BASE+WindowStackEntry.ypos,x
  sta window_y
  lda @l WINDOW_STACK_BASE+WindowStackEntry.width,x
  sta window_w
  lda @l WINDOW_STACK_BASE+WindowStackEntry.height,x
  sta window_h
  .leave
  plb
  rts

; copy Frame.height rows of the window from the window stack at X to the
; tile buffer at A
restore_rows:
  clc
  adc Frame.buf_offset
  sta Frame.buf_addr
  lda Frame.height
  sta Frame.rows
- ldy Frame.buf_addr
  lda Frame.count
  mvn #`WINDOW_STACK_BASE, #`BG1_TILE_BUF
  lda Frame.buf_addr
  clc
  adc #$0040
  sta Frame.buf_addr
  dec Frame.rows
  bne -
  rts
.endblock

hide_cursor:
  php
  sep #$20
  .as
  stz bar_wl
  dec bar_wl
  stz bar_xl
  dec bar_xl
  stz bar_yl
  dec bar_yl
  plp
  rts

window_greyout .block
  .virtual #0,d
Frame .block
  vcount        .word ?
  start_offset  .word ?
  _             .dstruct SaveJSR
.endblock
  .endvirtual
  .enter
  phb
    sep #$20
    .as
    lda #$7e
    pha
    plb
    rep #$20
    .al
    lda @w window_h
    and #$00ff
    sta Frame.vcount
    lda @w window_y
    and #$00ff
    xba                       ; * 256
    lsr                       ; / 2
    lsr                       ; / 2  => * 64
    sta Frame.start_offset    ; 64 * window_y
    lda @w window_x
    and #$00ff
    clc
    adc Frame.start_offset
    and #$fffe
    sta Frame.start_offset
    tax
greyout_start:
    lda @w window_w
    and #$00ff
    tay
    lda @w window_x
    lsr
    bcs greyout_bg1
greyout_bg2:
    lda @w <>BG2_TILE_BUF,x
    and #$03ff
    ora #$3800
    sta @w <>BG2_TILE_BUF,x
    dey
    beq greyout_next
greyout_bg1:
    lda @w <>BG1_TILE_BUF,x
    and #$03ff
    ora #$3800
    sta @w <>BG1_TILE_BUF,x
    inx
    inx
    dey
    bne greyout_bg2
greyout_next:
    dec Frame.vcount
    beq greyout_out
    lda Frame.start_offset
    clc
    adc #$0040
    sta Frame.start_offset
    tax
    bra greyout_start
greyout_out:
  plb
  .leave
  rts
.endblock

; right-align: calculate the column to print a string at so that it ends
;              at the right edge of the window (window_x, window_w)
; params:
; db: bank of string to print
; y: address of string to print
; returns: the column in the low byte of A
right_align:
  php
    jsr strlen            ; right-align:
    sep #$20
    .as
    rep #$10
    .xl
    tya                   ; column = window_x+window_w-2-strlen
    sec                   ; = ~(strlen-window_x)+1+window_w-2
    sbc wram(window_x)
    eor #$ff
    clc
    adc wram(window_w)
    dec a                 ; = ~(strlen-window_x)+window_w-1
  plp
  rts

; bar_color: change select bar color
; params:
; a: bar "palette" number
set_bar_color:
  php
    sep #$30
    .as
    .xs
    asl
    asl
    tax
    lda @l hdma_bar_color_src,x
    sta wram(hdma_math+2)
    lda @l hdma_bar_color_src+1,x
    sta wram(hdma_math+5)
    lda @l hdma_bar_color_src+2,x
    sta wram(hdma_math+8)
    lda @l hdma_bar_color_src+3,x
    sta wram(hdma_math+11)
  plp
  rts

; disable screen update (DMA from WRAM to VRAM)
disable_screen_update:
  inc screen_dma_disable
  rts

; enable screen update (DMA from WRAM to VRAM)
enable_screen_update:
  stz screen_dma_disable
  rts

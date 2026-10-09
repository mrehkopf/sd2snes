timebox_data:
; string offset, selection width, bcdtime offset
  .byte 0, 4, 9
  .byte 5, 2, 8
  .byte 8, 2, 6
  .byte 11, 2, 4
  .byte 14, 2, 2
  .byte 17, 2, 0

time_month:
  .byte 3, 1
  .byte 2, 8
  .byte 3, 1
  .byte 3, 0
  .byte 3, 1
  .byte 3, 0
  .byte 3, 1
  .byte 3, 1
  .byte 3, 0
  .byte 3, 1
  .byte 3, 0
  .byte 3, 1

.xl ; expected by routines in this file

time_init:
p_time_x    = $04
p_time_y    = $03
p_time_bank := $02
p_time_addr := $00
locals_     := $10
w_time_addr = $00
w_time_bank = $02
w_time_work = $03
w_time_s1   = $03
w_time_s10  = $04
w_time_m1   = $05
w_time_m10  = $06
w_time_h1   = $07
w_time_h10  = $08
w_time_d1   = $09
w_time_d10  = $0a
w_time_mon  = $0b
w_time_y1   = $0c
w_time_y10  = $0d
w_time_y100 = $0e
w_time_tmp  = $0f
  #AllocStack
  sep #$20
  .as
  phb
    lda #$80
    pha
    plb
    lda locals_+p_time_bank+5,d
    ldy locals_+p_time_addr+5,d
    sta w_time_bank,d
    sty w_time_addr,d
    jsr gettime
    jsr time_make_working_copy
    stz time_sel
    stz time_exit
    stz time_cancel
time_update:
    lda #$00
    pha
    rep #$20
    .al
    tdc
    clc
    adc #w_time_work
    pha
    sep #$20
    .as
      jsr rendertime
    plx
    pla
    lda #`wram(stringbuf)
    sta print_bank
    ldx #stringbuf
    stx print_src
    lda locals_+p_time_x+5,d
    sta print_x
    lda locals_+p_time_y+5,d
    sta print_y
    stz print_pal
    jsr hiprint
    lda time_sel
    asl
    clc
    adc time_sel
    xba
    lda #$00
    xba
    tax
    lda @l timebox_data,x
    clc
    adc locals_+p_time_x+5,d
    sta bar_xl
    lda locals_+p_time_y+5,d
    dec a
    sta bar_yl
    inx
    lda @l timebox_data,x
    sta bar_wl
    inx
    lda @l timebox_data,x
    sta time_ptr
timeloop1:
    lda isr_done
    lsr
    bcc timeloop1
    stz isr_done
    jsr read_pad
    lda pad_right
    bne tkey_right
    lda pad_left
    bne tkey_left
    lda pad_down
    bne tkey_down
    lda pad_up
    bne tkey_up
    lda pad_b
    bne tkey_b
    lda pad_a
    bne tkey_a
; do stuff
    lda time_exit
    bne timesave
; set clock
    lda time_cancel
    bne timenosave
    beq timeloop1
timesave:
    jsr time_save_working_copy
  plb
  #FreeStack
  .as
  sec
  rts
timenosave:
  plb
  #FreeStack
  .as
  clc
  rts

tkey_b:
  inc time_cancel
  jmp time_update

tkey_a:
  inc time_exit
  jmp time_update

tkey_left:
  jsr time_key_left
  jmp time_update

tkey_right:
  jsr time_key_right
  jmp time_update

tkey_up:
  jsr time_key_up
  jmp time_update

tkey_down:
  jsr time_key_down
  jmp time_update

time_key_left:
  lda time_sel
  beq +
  dec time_sel
+
  rts

time_key_right:
  lda time_sel
  cmp #5
  beq +
  inc time_sel
+
  rts

time_key_up:
  lda time_ptr
  cmp #4
  beq time_inc_hour_jmp
  cmp #6
  beq time_inc_day_jmp
  cmp #8
  beq time_inc_mon_jmp
  cmp #9
  beq time_inc_year_jmp
  xba
  lda #$00
  xba
  tax
  lda w_time_s1,d,x
  inc a
  cmp #$0a
  bmi time_inc_minsec1_normal
  stz w_time_s1,d,x
  lda w_time_s10,d,x
  inc a
  cmp #$06
  bmi time_inc_minsec10_normal
  stz w_time_s10,d,x
  bra +
time_inc_minsec10_normal:
  sta w_time_s10,d,x
  bra +
time_inc_minsec1_normal:
  sta w_time_s1,d,x
+
  rts

time_inc_hour_jmp:
  jsr time_inc_hour
  rts

time_inc_day_jmp:
  jsr time_inc_day
  rts

time_inc_mon_jmp:
  jsr time_inc_mon
  rts

time_inc_year_jmp:
  jsr time_inc_year
  lda w_time_mon,d
  jsr time_adjust_mon
  rts

time_inc_hour:
  lda w_time_h10,d
  cmp #$02
  bne time_inc_hour_normal
  lda w_time_h1,d
  inc a
  cmp #$04
  bmi +
  stz w_time_h1,d
  stz w_time_h10,d
  rts
+
  sta w_time_h1,d
  rts
time_inc_hour_normal:
  lda w_time_h1,d
  inc a
  cmp #$0a
  bmi +
  stz w_time_h1,d
  inc w_time_h10,d
  rts
+
  sta w_time_h1,d
  rts

time_inc_day:
  lda w_time_mon,d
  dec a
  asl
  xba
  lda #$00
  xba
  tax
  lda @l time_month,x
  cmp w_time_d10,d
  bne time_inc_day_normal
  inx
  jsr is_leapyear_feb
  lda @l time_month,x
  dec a
  adc #$00
  cmp w_time_d1,d
  bpl +
  stz w_time_d1,d
  stz w_time_d10,d
+
  inc w_time_d1,d
  rts
time_inc_day_normal:
  lda w_time_d1,d
  inc a
  cmp #$0a
  bmi +
  stz w_time_d1,d
  inc w_time_d10,d
  rts
+
  sta w_time_d1,d
  rts

time_inc_mon:
  lda w_time_mon,d
  inc a
  cmp #13
  bmi +
  lda #$01
+
  jsr time_adjust_mon
  rts

time_adjust_mon:
  sta w_time_mon,d
  dec a
  asl
  xba
  lda #$00
  xba
  tax
  lda w_time_d10,d
  cmp @l time_month,x
  bcs time_mon_adjust
  rts
time_mon_adjust:
  php
  inx
  lda @l time_month,x
  pha
  jsr is_leapyear_feb ; c=1 -> a leapyear february
  pla
  adc #$00
  plp
  bne time_mon_doadjust
  cmp w_time_d1,d
  bcs +
time_mon_doadjust:
  sta w_time_d1,d
  dex
  lda @l time_month,x
  sta w_time_d10,d
+
  rts

time_inc_year:
  lda w_time_y1,d
  inc a
  cmp #$0a
  bmi time_inc_y1_normal
  stz w_time_y1,d
  lda w_time_y10,d
  inc a
  cmp #$0a
  bmi time_inc_y10_normal
  stz w_time_y10,d
  inc w_time_y100,d
  rts
time_inc_y10_normal:
  sta w_time_y10,d
  rts
time_inc_y1_normal:
  sta w_time_y1,d
  rts


time_key_down:
  lda time_ptr
  cmp #4
  beq time_dec_hour_jmp
  cmp #6
  beq time_dec_day_jmp
  cmp #8
  beq time_dec_mon_jmp
  cmp #9
  beq time_dec_year_jmp
  xba
  lda #$00
  xba
  tax
  lda w_time_s1,d,x
  dec a
  cmp #$ff
  bne time_dec_minsec1_normal
  lda #$09
  sta w_time_s1,d,x
  lda w_time_s10,d,x
  dec a
  cmp #$ff
  bne time_dec_minsec10_normal
  lda #$05
  sta w_time_s10,d,x
  bra +
time_dec_minsec10_normal:
  sta w_time_s10,d,x
  bra +
time_dec_minsec1_normal:
  sta w_time_s1,d,x
+
  rts

time_dec_hour_jmp:
  jsr time_dec_hour
  rts

time_dec_day_jmp:
  jsr time_dec_day
  rts

time_dec_mon_jmp:
  jsr time_dec_mon
  rts

time_dec_year_jmp:
  jsr time_dec_year
  lda w_time_mon,d
  jsr time_adjust_mon
  rts

time_dec_hour:
  lda w_time_h1,d
  dec a
  cmp #$ff
  bne time_dec_h1_normal
  lda w_time_h10,d
  bne time_dec_h10_normal
  lda #$02
  sta w_time_h10,d
  lda #$03
  sta w_time_h1,d
  rts
time_dec_h10_normal:
  lda #$09
  sta w_time_h1,d
  dec w_time_h10,d
  rts
time_dec_h1_normal:
  sta w_time_h1,d
  rts

time_dec_day:
  lda w_time_d10,d
  beq +
  lda w_time_d1,d
  dec a
  cmp #$ff
  bne time_dec_d1_normal
  bra time_dec_cont
+ lda w_time_d1,d
  dec a
  bne time_dec_d1_normal
time_dec_cont:
  lda w_time_d10,d
  bne time_dec_d10_normal
  lda w_time_mon,d
  dec a
  asl
  xba
  lda #$00
  xba
  tax
  lda @l time_month,x
  sta w_time_d10,d
  inx
  lda @l time_month,x
  pha
  jsr is_leapyear_feb
  pla
  adc #$00
  sta w_time_d1,d
  rts
time_dec_d10_normal:
  lda #$09
  sta w_time_d1,d
  dec w_time_d10,d
  rts
time_dec_d1_normal:
  sta w_time_d1,d
  rts

time_dec_mon:
  lda w_time_mon,d
  dec a
  bne +
  lda #12
+
  jsr time_adjust_mon
  rts

time_dec_year:
  lda w_time_y1,d
  dec a
  cmp #$ff
  bne time_dec_y1_normal
  lda #$09
  sta w_time_y1,d
  lda w_time_y10,d
  dec a
  cmp #$ff
  bne time_dec_y10_normal
  lda #$09
  sta w_time_y10,d
  dec w_time_y100,d
  rts
time_dec_y10_normal:
  sta w_time_y10,d
  rts
time_dec_y1_normal:
  sta w_time_y1,d
  rts

is_leapyear_feb:
  lda w_time_mon,d
  cmp #$02
  bne is_leapyear_feb_no
  lda w_time_y10,d
  asl
  sta w_time_tmp,d
  asl
  asl
  clc
  adc w_time_tmp,d
  clc
  adc w_time_y1,d
  sta w_time_tmp,d
  and #$03
  beq is_leapyear_4th ; every 4th year
is_leapyear_feb_no:
  clc
  rts

is_leapyear_4th:      ; leapyear candidate
  lda w_time_tmp,d    ; year=00?
  beq +               ; then check century
  sec                 ; else it's always a leapyear
  rts
+
  lda w_time_y100,d   ; century divisible by 4?
  clc
  adc #10
  and #$03
  beq is_leapyear_400th
  clc
  rts

is_leapyear_400th:
  sec
  rts

time_make_working_copy:
  php
  rep #$20
  .al
  ldy #$0000
  ldx #$0000
- lda [w_time_addr,d],y
  sta w_time_work,d,x
  inx
  inx
  iny
  iny
  cpy #$000c
  bne -
  plp
  rts

time_save_working_copy:
  php
  rep #$20
  .al
  ldy #$0000
  ldx #$0000
- lda w_time_work,d,x
  sta [w_time_addr,d],y
  inx
  inx
  iny
  iny
  cpy #$000c
  bne -
  plp
  rts

gettime:
  php
  sep #$20
  .as
  lda #$0d
  sta $2801
  lda $2800
  lda $2800
  sta time_s1
  lda $2800
  sta time_s10
  lda $2800
  sta time_m1
  lda $2800
  sta time_m10
  lda $2800
  sta time_h1
  lda $2800
  sta time_h10
  lda $2800
  sta time_d1
  lda $2800
  sta time_d10
  lda $2800
  sta time_mon
  lda $2800
  sta time_y1
  lda $2800
  sta time_y10
  lda $2800
  sta time_y100
  plp
  rts

rendertime:
; local variables
locals_     := $00
; caller variables
p_time_addr := $00
p_time_bank := $02
  #AllocStack
  sep #$20
  .as
  ldx #stringbuf
  ldy #$000b
  lda [locals_+p_time_addr+5,d],y   ; y100
  and #$0f
  cmp #$0a
  bpl y_skip1
  clc
  adc #$30
  sta @w 1,x
  lda #$31
  sta @w 0,x
  bra y_skip2
y_skip1:
  clc
  adc #$26
  sta @w 1,x
  lda #$32
  sta @w 0,x
y_skip2:
  inx
  inx
  dey
  lda [locals_+p_time_addr+5,d],y   ; y10
  and #$0f
  clc
  adc #$30
  sta @w 0,x
  inx
  dey
  lda [locals_+p_time_addr+5,d],y   ; y1
  and #$0f
  clc
  adc #$30
  sta @w 0,x
  inx
  lda #$2d
  sta @w 0,x
  inx
  dey
  lda [locals_+p_time_addr+5,d],y   ; mon
  and #$0f
  cmp #$0a
  bpl mon_skip1
  clc
  adc #$30
  sta @w 1,x
  lda #$30
  sta @w 0,x
  bra mon_skip2
mon_skip1:
  clc
  adc #$26
  sta @w 1,x
  lda #$31
  sta @w 0,x
mon_skip2:
  inx
  inx
  lda #$2d
  sta @w 0,x
  inx
  dey
  lda [locals_+p_time_addr+5,d],y   ; d10
  clc
  adc #$30
  sta @w 0,x
  inx
  dey
  lda [locals_+p_time_addr+5,d],y   ; d1
  clc
  adc #$30
  sta @w 0,x
  inx
  lda #$20
  sta @w 0,x
  inx
  dey
  lda [locals_+p_time_addr+5,d],y   ; h10
  clc
  adc #$30
  sta @w 0,x
  inx
  dey
  lda [locals_+p_time_addr+5,d],y   ; h1
  clc
  adc #$30
  sta @w 0,x
  inx
  lda #$3a
  sta @w 0,x
  inx
  dey
  lda [locals_+p_time_addr+5,d],y   ; m10
  clc
  adc #$30
  sta @w 0,x
  inx
  dey
  lda [locals_+p_time_addr+5,d],y   ; m1
  clc
  adc #$30
  sta @w 0,x
  inx
  lda #$3a
  sta @w 0,x
  inx
  dey
  lda [locals_+p_time_addr+5,d],y   ; s10
  clc
  adc #$30
  sta @w 0,x
  inx
  dey
  lda [locals_+p_time_addr+5,d],y   ; s1
  clc
  adc #$30
  sta @w 0,x
  stz @w 1,x
  #FreeStack
  .as
  rts

settime:
  lda time_y100
  sta @l MCU_PARAM
  lda time_y10
  sta @l MCU_PARAM+1
  lda time_y1
  sta @l MCU_PARAM+2
  lda time_mon
  sta @l MCU_PARAM+3
  lda time_d10
  sta @l MCU_PARAM+4
  lda time_d1
  sta @l MCU_PARAM+5
  lda time_h10
  sta @l MCU_PARAM+6
  lda time_h1
  sta @l MCU_PARAM+7
  lda time_m10
  sta @l MCU_PARAM+8
  lda time_m1
  sta @l MCU_PARAM+9
  lda time_s10
  sta @l MCU_PARAM+10
  lda time_s1
  sta @l MCU_PARAM+11
  lda #$02            ; set clock
  sta @l MCU_CMD
  lda #$00
  sta @l ST_RTC_VALID ; set rtc valid
  rts

printtime:
  php
  phb
    sep #$20
    .as
    lda #$80
    pha
    plb
    jsr gettime
    jsr render_rtc_time
    lda listdisp
    clc
    adc #$0a
    sta print_y
    lda #$2b
    sta print_x
    lda #$40
    sta print_count
    lda #`wram(stringbuf)
    sta print_bank
    ldx #stringbuf
    stx print_src
    stz print_pal
    jsr hiprint
  plb
  plp
  rts

render_rtc_time:
  php
  sep #$20
  .as
  lda #`wram(time_s1)
  pha
  pea time_s1
    jsr rendertime
  pla
  pla
  pla
  plp
  rts


rtc_init:
  php
  sep #$20
  .as
; draw window + current time setting
  lda #`text_clkset
  sta window_tbank
  ldx #<>text_clkset
  stx window_taddr
  lda @l time_win_x
  sta window_x
  inc a
  inc a
  inc a
  pha ; p_time_x
  lda @l time_win_w
  sta window_w
  lda @l time_win_y
  sta window_y
  inc a
  pha ; p_time_y
  lda @l time_win_h
  sta window_h
  jsr push_window
  jsr draw_window
  lda #`wram(time_s1)
  pha
  pea time_s1
    jsr time_init
  pla
  pla
  pla
  pla
  pla
  bcc +
  jsr settime
+ ; restore text area
  jsr pop_window
  plp
  rtl

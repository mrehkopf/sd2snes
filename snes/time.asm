timebox_data:
; string offset, selection width, BCDTime offset
  .byte 0, 4, BCDTime.y1
  .byte 5, 2, BCDTime.mon
  .byte 8, 2, BCDTime.d1
  .byte 11, 2, BCDTime.h1
  .byte 14, 2, BCDTime.m1
  .byte 17, 2, BCDTime.s1

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

time_init .block
; Edit date/time in place. Button handlers and working copy routines used
; below run in the same frame as a part of this block.
  .virtual #0,d
Frame .block
  time_addr     .word ?          ; long pointer to the BCDTime being edited
  time_bank     .byte ?
  work          .dstruct BCDTime ; working copy
  tmp           .byte ?
  _             .dstruct SaveJSR
  p_time_addr   .word ?          ; pushed last
  p_time_bank   .byte ?
  p_time_y      .byte ?
  p_time_x      .byte ?          ; pushed first
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  phb
    lda #$80
    pha
    plb
    lda Frame.p_time_bank
    ldy Frame.p_time_addr
    sta Frame.time_bank
    sty Frame.time_addr
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
    adc #Frame.work - Frame
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
    lda Frame.p_time_x
    sta print_x
    lda Frame.p_time_y
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
    adc Frame.p_time_x
    sta bar_xl
    lda Frame.p_time_y
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
  .leave
  .as
  sec
  rts
timenosave:
  plb
  .leave
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
  cmp #BCDTime.h1
  beq time_inc_hour_jmp
  cmp #BCDTime.d1
  beq time_inc_day_jmp
  cmp #BCDTime.mon
  beq time_inc_mon_jmp
  cmp #BCDTime.y1
  beq time_inc_year_jmp
  xba
  lda #$00
  xba
  tax
  lda Frame.work.s1,x
  inc a
  cmp #$0a
  bmi time_inc_minsec1_normal
  stz Frame.work.s1,x
  lda Frame.work.s10,x
  inc a
  cmp #$06
  bmi time_inc_minsec10_normal
  stz Frame.work.s10,x
  bra +
time_inc_minsec10_normal:
  sta Frame.work.s10,x
  bra +
time_inc_minsec1_normal:
  sta Frame.work.s1,x
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
  lda Frame.work.mon
  jsr time_adjust_mon
  rts

time_inc_hour:
  lda Frame.work.h10
  cmp #$02
  bne time_inc_hour_normal
  lda Frame.work.h1
  inc a
  cmp #$04
  bmi +
  stz Frame.work.h1
  stz Frame.work.h10
  rts
+
  sta Frame.work.h1
  rts
time_inc_hour_normal:
  lda Frame.work.h1
  inc a
  cmp #$0a
  bmi +
  stz Frame.work.h1
  inc Frame.work.h10
  rts
+
  sta Frame.work.h1
  rts

time_inc_day:
  lda Frame.work.mon
  dec a
  asl
  xba
  lda #$00
  xba
  tax
  lda @l time_month,x
  cmp Frame.work.d10
  bne time_inc_day_normal
  inx
  jsr is_leapyear_feb
  lda @l time_month,x
  dec a
  adc #$00
  cmp Frame.work.d1
  bpl +
  stz Frame.work.d1
  stz Frame.work.d10
+
  inc Frame.work.d1
  rts
time_inc_day_normal:
  lda Frame.work.d1
  inc a
  cmp #$0a
  bmi +
  stz Frame.work.d1
  inc Frame.work.d10
  rts
+
  sta Frame.work.d1
  rts

time_inc_mon:
  lda Frame.work.mon
  inc a
  cmp #13
  bmi +
  lda #$01
+
  jsr time_adjust_mon
  rts

time_adjust_mon:
  sta Frame.work.mon
  dec a
  asl
  xba
  lda #$00
  xba
  tax
  lda Frame.work.d10
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
  cmp Frame.work.d1
  bcs +
time_mon_doadjust:
  sta Frame.work.d1
  dex
  lda @l time_month,x
  sta Frame.work.d10
+
  rts

time_inc_year:
  lda Frame.work.y1
  inc a
  cmp #$0a
  bmi time_inc_y1_normal
  stz Frame.work.y1
  lda Frame.work.y10
  inc a
  cmp #$0a
  bmi time_inc_y10_normal
  stz Frame.work.y10
  inc Frame.work.y100
  rts
time_inc_y10_normal:
  sta Frame.work.y10
  rts
time_inc_y1_normal:
  sta Frame.work.y1
  rts


time_key_down:
  lda time_ptr
  cmp #BCDTime.h1
  beq time_dec_hour_jmp
  cmp #BCDTime.d1
  beq time_dec_day_jmp
  cmp #BCDTime.mon
  beq time_dec_mon_jmp
  cmp #BCDTime.y1
  beq time_dec_year_jmp
  xba
  lda #$00
  xba
  tax
  lda Frame.work.s1,x
  dec a
  cmp #$ff
  bne time_dec_minsec1_normal
  lda #$09
  sta Frame.work.s1,x
  lda Frame.work.s10,x
  dec a
  cmp #$ff
  bne time_dec_minsec10_normal
  lda #$05
  sta Frame.work.s10,x
  bra +
time_dec_minsec10_normal:
  sta Frame.work.s10,x
  bra +
time_dec_minsec1_normal:
  sta Frame.work.s1,x
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
  lda Frame.work.mon
  jsr time_adjust_mon
  rts

time_dec_hour:
  lda Frame.work.h1
  dec a
  cmp #$ff
  bne time_dec_h1_normal
  lda Frame.work.h10
  bne time_dec_h10_normal
  lda #$02
  sta Frame.work.h10
  lda #$03
  sta Frame.work.h1
  rts
time_dec_h10_normal:
  lda #$09
  sta Frame.work.h1
  dec Frame.work.h10
  rts
time_dec_h1_normal:
  sta Frame.work.h1
  rts

time_dec_day:
  lda Frame.work.d10
  beq +
  lda Frame.work.d1
  dec a
  cmp #$ff
  bne time_dec_d1_normal
  bra time_dec_cont
+ lda Frame.work.d1
  dec a
  bne time_dec_d1_normal
time_dec_cont:
  lda Frame.work.d10
  bne time_dec_d10_normal
  lda Frame.work.mon
  dec a
  asl
  xba
  lda #$00
  xba
  tax
  lda @l time_month,x
  sta Frame.work.d10
  inx
  lda @l time_month,x
  pha
  jsr is_leapyear_feb
  pla
  adc #$00
  sta Frame.work.d1
  rts
time_dec_d10_normal:
  lda #$09
  sta Frame.work.d1
  dec Frame.work.d10
  rts
time_dec_d1_normal:
  sta Frame.work.d1
  rts

time_dec_mon:
  lda Frame.work.mon
  dec a
  bne +
  lda #12
+
  jsr time_adjust_mon
  rts

time_dec_year:
  lda Frame.work.y1
  dec a
  cmp #$ff
  bne time_dec_y1_normal
  lda #$09
  sta Frame.work.y1
  lda Frame.work.y10
  dec a
  cmp #$ff
  bne time_dec_y10_normal
  lda #$09
  sta Frame.work.y10
  dec Frame.work.y100
  rts
time_dec_y10_normal:
  sta Frame.work.y10
  rts
time_dec_y1_normal:
  sta Frame.work.y1
  rts

is_leapyear_feb:
  lda Frame.work.mon
  cmp #$02
  bne is_leapyear_feb_no
  lda Frame.work.y10
  asl
  sta Frame.tmp
  asl
  asl
  clc
  adc Frame.tmp
  clc
  adc Frame.work.y1
  sta Frame.tmp
  and #$03
  beq is_leapyear_4th ; every 4th year
is_leapyear_feb_no:
  clc
  rts

is_leapyear_4th:      ; leapyear candidate
  lda Frame.tmp       ; year=00?
  beq +               ; then check century
  sec                 ; else it's always a leapyear
  rts
+
  lda Frame.work.y100 ; century divisible by 4?
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
- lda [Frame.time_addr],y
  sta Frame.work,x
  inx
  inx
  iny
  iny
  cpy #size(BCDTime)
  bne -
  plp
  rts

time_save_working_copy:
  php
  rep #$20
  .al
  ldy #$0000
  ldx #$0000
- lda Frame.work,x
  sta [Frame.time_addr],y
  inx
  inx
  iny
  iny
  cpy #size(BCDTime)
  bne -
  plp
  rts
.endblock

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

rendertime .block
; render the BCDTime pointed to by the params into stringbuf
  .virtual #0,d
Frame .block
  _             .dstruct SaveJSR
  p_time_addr   .word ?         ; long pointer to a BCDTime, pushed last
  p_time_bank   .byte ?         ; pushed first
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  ldx #stringbuf
  ldy #BCDTime.y100
  lda [Frame.p_time_addr],y         ; y100
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
  lda [Frame.p_time_addr],y         ; y10
  and #$0f
  clc
  adc #$30
  sta @w 0,x
  inx
  dey
  lda [Frame.p_time_addr],y         ; y1
  and #$0f
  clc
  adc #$30
  sta @w 0,x
  inx
  lda #$2d
  sta @w 0,x
  inx
  dey
  lda [Frame.p_time_addr],y         ; mon
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
  lda [Frame.p_time_addr],y         ; d10
  clc
  adc #$30
  sta @w 0,x
  inx
  dey
  lda [Frame.p_time_addr],y         ; d1
  clc
  adc #$30
  sta @w 0,x
  inx
  lda #$20
  sta @w 0,x
  inx
  dey
  lda [Frame.p_time_addr],y         ; h10
  clc
  adc #$30
  sta @w 0,x
  inx
  dey
  lda [Frame.p_time_addr],y         ; h1
  clc
  adc #$30
  sta @w 0,x
  inx
  lda #$3a
  sta @w 0,x
  inx
  dey
  lda [Frame.p_time_addr],y         ; m10
  clc
  adc #$30
  sta @w 0,x
  inx
  dey
  lda [Frame.p_time_addr],y         ; m1
  clc
  adc #$30
  sta @w 0,x
  inx
  lda #$3a
  sta @w 0,x
  inx
  dey
  lda [Frame.p_time_addr],y         ; s10
  clc
  adc #$30
  sta @w 0,x
  inx
  dey
  lda [Frame.p_time_addr],y         ; s1
  clc
  adc #$30
  sta @w 0,x
  stz @w 1,x
  .leave
  .as
  rts
.endblock

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

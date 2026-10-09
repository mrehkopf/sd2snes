MENU_NUM_DATA_TYPES = $07

mainmenu:
  sep #$20
  .as
  rep #$10
  .xl
  lda #$02
  sta window_x
  lda #$09
  sta window_y
  lda #60
  sta window_w
  lda #18
  sta window_h
  jsr push_window
  jsr window_greyout
  lda #$06
  sta window_x
  lda #$0b
  sta window_y
  phb
    lda #`menu_enttab_mm
    pha
    plb
    ldx #<>menu_enttab_mm
    jsr show_menu
  plb
  jsr pop_window
  rts

filesel_contextmenu_file:
  sep #$20
  .as
  rep #$10
  .xl
  lda #$02
  sta window_x
  lda #$09
  sta window_y
  lda #60
  sta window_w
  lda #18
  sta window_h
  jsr push_window
  jsr window_greyout
  lda #$06
  sta window_x
  lda #$0b
  sta window_y
  phb
    lda #`menu_enttab_filesel_context_file
    pha
    plb
    ldx #<>menu_enttab_filesel_context_file
    jsr show_menu
  plb
  jsr pop_window
  rts

filesel_favorites_contextmenu:
  sep #$20
  .as
  rep #$10
  .xl
  lda #$02
  sta window_x
  lda #$09
  sta window_y
  lda #60
  sta window_w
  lda #18
  sta window_h
  jsr push_window
  jsr window_greyout
  lda #$06
  sta window_x
  lda #$0b
  sta window_y
  phb
    lda #`menu_enttab_filesel_favorites_context
    pha
    plb
    ldx #<>menu_enttab_filesel_favorites_context
    jsr show_menu
  plb
  jsr pop_window
  rts

filesel_recent_contextmenu:
  sep #$20
  .as
  rep #$10
  .xl
  lda #$02
  sta window_x
  lda #$09
  sta window_y
  lda #60
  sta window_w
  lda #18
  sta window_h
  jsr push_window
  jsr window_greyout
  lda #$06
  sta window_x
  lda #$0b
  sta window_y
  phb
    lda #`menu_enttab_recent_context
    pha
    plb
    ldx #<>menu_enttab_recent_context
    jsr show_menu
  plb
  jsr pop_window
  rts

; menu_select:
; helper routine to select a list entry
; window and list items must be printed in advance
; used variables:
;
; window_x, window_y, window_w, window_h: for select bar setup
; listsel_max: number of list entries to select from
; listsel_step: spacing between list entries (y text lines)
; listsel_pickbutton: if 00, only allow button A to select an item,
;                     if 01, allow button A and Y to select an item
;
; return value: index of selected item in A,
;               or #$FF if no item was selected
;               listsel_pickbutton = 00 if button A was used,
;               listsel_pickbutton = 01 if button Y was used,
;               listsel_pickbutton = FF if button B (cancel) was used
menu_select:
  php
  sep #$20
  rep #$10
  .as
  .xl
  stz listsel_sel
  bra +
menu_select_noinit:
  php
  sep #$20
  rep #$10
  .as
  .xl
+
  lda window_x
  inc a
  inc a
  sta bar_xl
  lda window_w
  sec
  sbc #$04
  sta bar_wl
  lda listsel_sel
  sta $211b
  stz $211b
  lda listsel_step
  sta $211c
  lda window_y
  clc
  adc $2134
  sta bar_yl

menu_select_loop1:
  lda isr_done
  beq menu_select_loop1
  stz isr_done
  jsr printtime
  jsr read_pad
  lda pad_up
  bne menu_select_up
  lda pad_down
  bne menu_select_down
  lda pad_a
  bne menu_select_button_a
  lda pad_y
  bne menu_select_button_y
  lda pad_b
  bne menu_select_button_b
  bra menu_select_loop1
menu_select_up:
  lda listsel_sel
  beq menu_select_loop1
  dec listsel_sel
  lda bar_yl
  sec
  sbc listsel_step
  sta bar_yl
  bra menu_select_loop1
menu_select_down:
  lda listsel_sel
  inc a
  cmp listsel_max
  beq menu_select_loop1
  inc listsel_sel
  lda bar_yl
  clc
  adc listsel_step
  sta bar_yl
  bra menu_select_loop1
menu_select_button_a: ; always allow button a
  lda #$00
  sta listsel_pickbutton
  lda listsel_sel
  bra menu_select_exit
menu_select_button_y: ; check if we should allow button y
  lda listsel_pickbutton
  cmp #$01
  bne menu_select_loop1
  lda #$01
  sta listsel_pickbutton
  lda listsel_sel
  bra menu_select_exit
menu_select_button_b: ; cancel
  lda #$ff
  sta listsel_pickbutton
menu_select_exit:
  plp
  rts


.text "SHOW_MENU"
show_menu:
; params:
; x: offset of menu structure
; db: bank of menu structure
; local vars:
locals_         := $0c
w_numentries    = $00
w_max_lbl_len   = $02
w_max_opt_len   = $04
w_title_len     = $06
w_menu_addr     = $08
w_menu_bank     = $0a
  #AllocStack
; backup params
  sep #$20
  .as
  phb
  pla
  sta w_menu_bank,d
  stx w_menu_addr,d
  jsr menu_measure      ; determine required window dimensions
  sep #$20
  .as
  lda #$80
  phb
    pha
    plb
    lda w_numentries,d
    sta $211b
    stz $211b
    lda [w_menu_addr,d] ; listsel_step from menu structure
    sta $211c
    lda $2134
    sec
    sbc [w_menu_addr,d] ; listsel_step from menu structure
    inc a
    inc a
    inc a
    sta window_h
    lda w_max_lbl_len,d
    clc
    adc w_max_opt_len,d
; check whether window width is limited by label+option
; or by window title text
    cmp w_title_len,d
    bcs +
    lda w_title_len,d
    inc a
    inc a
+   clc
    adc #$04
    ldx w_max_opt_len,d
    beq +
    inc a
    inc a
    inc a
+   sta window_w
    jsr push_window
    lda [w_menu_addr,d]
    sta listsel_step
    stz listsel_sel
    ldy #$0001
    rep #$20
    .al
    lda [w_menu_addr,d],y
    sta window_taddr
    sep #$20
    .as
    iny
    iny
    lda [w_menu_addr,d],y
    sta window_tbank
    jsr draw_window
    jsr show_menu_entries
    lda w_numentries,d
    sta listsel_max
show_menu_loop:
    stz listsel_pickbutton
    jsr menu_select_noinit
    cmp #$ff
    beq show_menu_out
    sta $211b
    stz $211b
    lda #MENU_ENTRY_SIZE
    sta $211c
    rep #$20
    .al
    lda $2134
    clc
    adc #$04
    tay
    lda [w_menu_addr,d],y
    and #$00ff
    iny
    iny
    iny
    iny
    cmp #MTYPE_SUBMENU
    beq show_menu_submenu
    cmp #MTYPE_FUNC
    bne *+5
    brl show_menu_func
    cmp #MTYPE_FUNC_CLOSE
    bne *+5
    brl show_menu_func_close
    cmp #MTYPE_VALUE
    bne show_menu_cont
    jmp show_menu_editvalue
show_menu_cont:
    sep #$20
    .as
;    jsr pop_window
    jsr show_menu_entries
    jmp show_menu_loop
show_menu_out:
    sep #$20
    .as
    jsr pop_window
  plb
  #FreeStack
  rts

show_menu_entries:
  php
  sep #$20
  .as
  phb
    lda w_menu_bank,d
    pha
    plb
    ldx w_menu_addr,d
    inx
    inx
    inx
    inx
    lda w_max_lbl_len,d
    pha
    lda w_max_opt_len,d
    pha
    jsr menu_print_entries
    pla
    pla
  plb
  plp
  rts

show_menu_submenu:
    .al
    phy
      jsr push_window
      jsr window_greyout
    ply
    lda [w_menu_addr,d],y
    tax
    sep #$20
    .as
    lda wram(window_x)
    inc a
    inc a
    sta wram(window_x)
    lda wram(window_y)
    inc a
    sta wram(window_y)
    iny
    iny
    lda [w_menu_addr,d],y
    phb
      pha
      plb
      jsr show_menu
    plb
    phy
    jsr pop_window
    ply
    bra show_menu_cont

show_menu_func:
    phy
    jsr push_window
    jsr window_greyout
    ply
    phk
    per show_menu_func_cont-1
    rep #$20
    .al
    lda [w_menu_addr,d],y
    tax
    sep #$20
    .as
    iny
    iny
    lda [w_menu_addr,d],y
    pha
    phx
    rtl
show_menu_func_cont:
    phy
    jsr pop_window
    ply
    jmp show_menu_cont

show_menu_func_close:
    phy
    jsr push_window
    jsr window_greyout
    ply
    phk
    per show_menu_func_close_cont-1
    rep #$20
    .al
    lda [w_menu_addr,d],y
    tax
    sep #$20
    .as
    iny
    iny
    lda [w_menu_addr,d],y
    pha
    phx
    rtl
show_menu_func_close_cont:
    phy
    jsr pop_window
    ply
    jmp show_menu_out

show_menu_editvalue:
    phy
      phb
        rep #$20
        .al
        tya
        clc
        adc w_menu_addr,d
        sec
        sbc #$0004 ; subtract previous Y displacement
        tax
        sep #$20
        .as
        lda w_menu_bank,d
        pha
        plb
        jsr menu_edit_value
      plb
    ply
    jmp show_menu_cont

; params:
; x: offset of menu structure
; db: bank of menu structure
; returns:
; number of menu entries
; maximum menu label string length
; maximum menu option string length
.text "MENU_MEASURE"
menu_measure:
; local variables
locals_         := $02
w_max_kv_len    = $00
; ==== return variables (same as parameter variables at the caller)
r_numentries    = $00
r_max_lbl_len   = $02
r_max_opt_len   = $04
r_title_len     = $06
; ==== WORKING VARIABLES ON STACK ====
  #AllocStack            ; implies PHP : PHD : .al
  stz locals_+r_max_lbl_len+5,d ; initialize variable
  stz locals_+r_max_opt_len+5,d ; initialize variable
  stz locals_+r_numentries+5,d
  stz w_max_kv_len,d
; ====================================
; include window title in calculation
  sep #$20
  .as
  ldy @w $1,x
  lda @w $3,x
  phb
    pha
    plb
    jsr strlen
    sty locals_+r_title_len+5,d
  plb
  inx
  inx
  inx
  inx ; move pointer past menu header
  rep #$20
  .al
menu_measure_line_loop:
  lda @w $0,x          ; read menu entry type
  and #$00ff           ; (mask)
  beq menu_measure_out ; termination -> exit
  inc locals_+r_numentries+5,d ; entry counter
  phb
    sep #$20
    .as
    ldy @w $1,x        ; resolve pointer to menu entry text
    lda @w $3,x
    pha
    plb
    jsr strlen
  plb
  lda @w $0,x
  cmp #MTYPE_SUBMENU    ; add 2 chars for '...' on sub menu entries
  bne +
  iny
  iny
+ rep #$20
  .al
  cpy locals_+r_max_lbl_len+5,d ; replace max value with
  bmi +                         ; new length
  sty locals_+r_max_lbl_len+5,d ; if bigger or equal.
+ jsr menu_meas_opt             ; calculate max option string length
                               ; move to next entry.
  cmp locals_+r_max_opt_len+5,d
  bmi +
  sta locals_+r_max_opt_len+5,d
+ txa
  clc
  adc #MENU_ENTRY_SIZE
  tax
  bra menu_measure_line_loop
menu_measure_out:
  #FreeStack
  rts


; **** menu_meas_opt ****
; params:
; =======
; x : address of menu entry
; db: bank of menu entry
;
; returns:
; ========
; a: calculated max parameter length for values of this entry
menu_meas_no_set:
  .as
  lda #$00
  jmp menu_meas_opt_set
menu_meas_opt:
  php
    sep #$20
    .as
  ;  lda !$4, x         ; calculate space needed to show options
  ;  cmp #MTYPE_VALUE   ; only for "value set" entry types
  ;  bne menu_meas_no_set
    lda @w $7,x
    beq menu_meas_no_set ; no option
    cmp #$01           ; uint8
    bne menu_meas_opt_02
    lda #$03           ; "0"-"255" - 3 chars
    bra menu_meas_opt_set
menu_meas_opt_02:
    cmp #$02           ; uint16
    bne menu_meas_opt_03
    lda #$05           ; "0"-"65535" - 5 chars
    bra menu_meas_opt_set
menu_meas_opt_03:
    cmp #$03           ; string (free entry)
    bne menu_meas_opt_04
    lda @w $4,x        ; load length constraint
    bra menu_meas_opt_set
menu_meas_opt_04:
    cmp #$04           ; key-value (8bit)
    beq menu_meas_opt_keyval
    cmp #$05           ; key-value (16bit)
    bne menu_meas_opt_06
menu_meas_opt_keyval: ; count max value length
    pea $0000
    phb
      ldy @w $4,x      ; get pointer to
      lda @w $6,x      ; key-value table
      pha
      plb
      rep #$20
      .al
menu_meas_opt_nextkey:
      lda @w $0,y       ; get key
      cmp #$ffff
      beq +
      iny
      iny              ; move to value
      phy
        phb
          sep #$20
          .as
          lda @w $2,y    ; get bank of string
          pha
          rep #$20
          .al
          lda @w $0,y    ; get pointer to string
          plb
          tay
          jsr strlen     ; get length
        plb
        tya
        cmp 4,s  ; compare-replace
        bmi menu_meas_opt_keyval_skip
        sta 4,s
menu_meas_opt_keyval_skip:
      ply
      iny              ; move to next key
      iny
      iny
      bra menu_meas_opt_nextkey
+
    plb
    pla
    bra menu_meas_opt_set
menu_meas_opt_06:     ; file select (16 characters)
    .as
    cmp #$06
    bne menu_meas_opt_07
    lda #$10
    bra menu_meas_opt_set
menu_meas_opt_07:     ; date/time select (19 characters)
    lda #$13
    bra menu_meas_opt_set
menu_meas_opt_set:
  rep #$20
  .al
  and #$00ff
  plp
  rts

.text "MENU_PRINT_ENTRIES"
menu_print_entries:
locals_         := $00
; params
; x: address of menu entry structure
; db: bank of menu entry structure
p_max_lbl_len   = $01
p_max_opt_len   = $00
  #AllocStack
  sep #$20
  .as
  lda wram(window_y)
  inc a
  sta wram(print_y)
menu_print_ent_loop:
  lda wram(window_w)
  sta wram(print_count)
  lda wram(window_x)
  inc a
  inc a
  sta wram(print_x)
  lda @w 0,x ; entry type. 0 = termination
  bne +
  jmp menu_print_ent_out
+ lda @w 1,x ; address of option name string
  sta wram(print_src)
  lda @w 2,x ; (address cont'd)
  sta wram(print_src+1)
  lda @w 3,x ; bank of option name string
  sta wram(print_bank)
  jsr menu_check_disabled_func
  lda #$00
  bcc +
  lda #$06
+ sta wram(print_pal)
  phx
  jsr hiprint
  plx
  lda @w 0,x
  cmp #MTYPE_SUBMENU
  bne +
  lda wram(print_done)
  adc wram(print_x)
  dec a
  sta wram(print_x)
  lda #<text_ellipse
  sta wram(print_src)
  lda #>text_ellipse
  sta wram(print_src+1)
  lda #`text_ellipse
  sta wram(print_bank)
  phx
    jsr hiprint
  plx
+ lda locals_+p_max_lbl_len+5,d
  clc
  adc wram(window_x)
  adc #$05
  sta wram(print_x)
  lda locals_+p_max_opt_len+5,d
  sta wram(print_count)
  lda #`space64
  sta wram(print_bank)
  rep #$20
  .al
  lda #<>space64
  sta wram(print_src)
  phx
    jsr hiprint
  plx
  jsr menu_print_opt_string
  txa
  clc
  adc #MENU_ENTRY_SIZE
  tax
  sep #$20
  .as
  lda wram(print_y)
  clc
  adc wram(listsel_step)
  sta wram(print_y)
  jmp menu_print_ent_loop
menu_print_ent_out:
  #FreeStack
  rts

.text "MENU_PRINT_OPT_STRING"
menu_print_opt_string_none:
  jmp menu_print_opt_string_out
menu_print_opt_string:
; params
; x: address of menu entry structure
; db: bank of menu entry structure
locals_      := $0b
w_entry_addr = $00
w_entry_bank = $02
w_kvpar_addr = $03
w_kvpar_bank = $05
w_kvpar_data = $06
w_kvtab_addr = $08
w_kvtab_bank = $0a
  #AllocStack
  rep #$20
  .al
  lda @w $8,x
  sta w_entry_addr,d
  lda #stringbuf
  sta wram(print_src)
  sep #$20
  .as
  jsr menu_check_disabled_func
  lda #$01
  bcc +
  lda #$06
+ sta wram(print_pal)
  lda #$40
  sta wram(print_count)
  lda #`wram(stringbuf)
  sta wram(print_bank)
  lda @w $a,x
  sta w_entry_bank,d
;  lda !$0, x
;  cmp #MTYPE_VALUE
;  bne menu_print_opt_string_none
  lda @w $7,x
  beq menu_print_opt_string_none
  cmp #$01
  bne menu_print_opt_string_02
  rep #$20
  .al
  lda [w_entry_addr,d]
  and #$00ff
  phx
    jsr bin2dec16
    lda wram(print_src)
    tay
    sep #$20
    .as
    lda wram(print_bank)
    phb
      pha
      plb
      jsr right_align
    plb
    jsr hiprint
  plx
  jmp menu_print_opt_string_out
menu_print_opt_string_02:
  .as
  cmp #$02
  bne menu_print_opt_string_03
  rep #$20
  .al
  lda [w_entry_addr,d]
  phx
    jsr bin2dec16
    lda wram(print_src)
    tay
    sep #$20
    .as
    lda wram(print_bank)
    phb
      pha
      plb
      jsr right_align
    plb
    jsr hiprint
  plx
  jmp menu_print_opt_string_out
menu_print_opt_string_03:
  .as
  cmp #$03
  bne menu_print_opt_string_04
  rep #$20
  .al
  lda @w $8,x
  sta wram(print_src)
  tay
  sep #$20
  .as
  lda @w $4,x
  sta wram(print_count)
  lda @w $a,x
  sta wram(print_bank)
  phx
    phb
      pha
      plb
      jsr right_align
    plb
    jsr hiprint
  plx
  lda wram(window_w)
  sta wram(print_count)
  jmp menu_print_opt_string_out
menu_print_opt_string_04:
  .as
  cmp #$04
  beq menu_print_opt_string_keyval
  cmp #$05
  bne menu_print_opt_string_06
menu_print_opt_string_keyval:
  lda @w $a,x             ; load address
  ldy @w $8,x             ; of current setting
  sta w_kvpar_bank,d
  sty w_kvpar_addr,d
  rep #$20
  .al
  lda [w_kvpar_addr,d]    ; load currently set value
  ; mask for 8-bit key!
  phx
    ldy @w $7,x
    sep #$10
    .xs
    cpy #$05
    beq +
    and #$00ff
+   rep #$10
    .xl
  plx
  sta w_kvpar_data,d
  lda @w $4,x             ; load pointer to kvtable
  sta w_kvtab_addr,d
  sep #$20
  .as
  lda @w $6,x
  sta w_kvtab_bank,d
  phb
    pha
    plb
    rep #$20
    .al
    ldy w_kvtab_addr,d
    lda w_kvpar_data,d
    jsr menu_kv_lookup
; sanitize invalid option setting
    cpy #$ffff
    bne +
    ldy w_kvtab_addr,d    ; invalid setting -> default to first entry
+   lda @w $2,y
    pha                   ; save offset for right-align
      sta wram(print_src)
      sep #$20
      .as
      lda @w $4,y
      sta wram(print_bank)
      pha
      plb
    ply
    jsr right_align
  plb
  phx
    jsr hiprint
  plx
  jmp menu_print_opt_string_out
menu_print_opt_string_06:
  sep #$20
  .as
  cmp #$06
  bne menu_print_opt_string_07
  lda #$41
  sta wram(stringbuf)
  lda #$00
  sta wram(stringbuf+1)
  jsr menu_check_disabled_func
  lda #$02
  bcc +
  lda #$06
+ sta wram(print_pal)
  lda #$10
  sta wram(print_count)
  rep #$20
  .al
  lda #stringbuf
  sta wram(print_src)
  tay
  sep #$20
  .as
  lda #`wram(stringbuf)
  sta wram(print_bank)
  phx
    phb
      pha
      plb
      jsr right_align
    plb
    jsr hiprint
  plx
  bra menu_print_opt_string_out
menu_print_opt_string_07:
  sep #$20
  .as
  jsr menu_check_disabled_func
  lda #$02
  bcc +
  lda #$06
+ sta wram(print_pal)
  lda #$13
  sta wram(print_count)
  rep #$20
  .al
  lda #stringbuf
  sta wram(print_src)
  tay
  sep #$20
  .as
  lda #`wram(stringbuf)
  sta wram(print_bank)
  phx
    phb
      pha
      plb
      phy
        lda w_entry_bank,d
        ldx w_entry_addr,d
        pha
        phx
          jsr rendertime
        plx
        pla
      ply
      jsr right_align
    plb
    jsr hiprint
  plx
menu_print_opt_string_out:
  #FreeStack
  rts

; menu_kv_lookup
; look for key in a kv table
; and return address of kv entry
; params:
; y: address of entry table
; db: bank of entry table
; a: search value
; returns:
; y: address of table entry if found,
;    $ffff if not found
menu_kv_lookup:
  php
    rep #$30
    .xl
    .al
    pha
-   lda @w $0,y         ; compare with table key
    cmp #$ffff          ; termination
    beq +
    cmp $1,s           ; compare with search value
    beq menu_kv_lookup_out
    iny
    iny
    iny
    iny
    iny
    bra -
+   ldy #$ffff
menu_kv_lookup_out:
    pla
  plp
  rts

; menu_edit_value
; show a select/edit dialog depending on data type
; and store value in location according to menu
; entry structure
; params:
; db: bank of menu entry
; x: address of menu entry
.text "MENU_EDIT_VALUE"
menu_edit_value:
; local variables (also available to callees above "#undef _locals")
locals_         := $11
w_preset_addr   = $00
w_preset_bank   = $02
w_value_addr    = $03
w_value_bank    = $05
w_work_value    = $06
w_label_addr    = $08
w_label_bank    = $0a
w_value_len     = $0b
w_text_grey     = $0d
w_chgfunc_addr  = $0e
w_chgfunc_bank  = $10
; returns:
; carry flag: 1=value set, 0=cancelled
  #AllocStack
  ; prepare work variables for sub routines
  jsr menu_meas_opt
  sta w_value_len,d
  lda @w $4,x
  sta w_preset_addr,d
  lda @w $8,x
  sta w_value_addr,d
  lda @w 14,x
  sta w_chgfunc_addr,d
  lda #$0000 ; cleanup B for jump table offset
  sep #$20
  .as
  jsr menu_check_disabled_func
  ror
  sta w_text_grey,d
  lda @w $6,x
  sta w_preset_bank,d
  lda @w $a,x
  sta w_value_bank,d
  lda @w 16,x
  sta w_chgfunc_bank,d
; adjust selection bar to highlight parameter area
  lda wram(bar_xl)
  clc
  adc wram(bar_wl)
  sec
  sbc w_value_len,d
  sta wram(bar_xl)
  lda w_value_len,d
  sta wram(bar_wl)
  lda @w $7,x ; load data type
  cmp #MENU_NUM_DATA_TYPES+1
  bcs menu_edit_value_out ; do not jump to undefined
  asl ; prepare jump table pointer
  txy ; save address of menu entry (bank is still set)
  tax ; jump table offset
  phx
    lda #$01
    jsr set_bar_color
  plx
  rep #$20
  .al
  lda [w_value_addr,d]
  sta w_work_value,d
  jsr (menu_tab_edit_value_dialogs,x)
  bcc +
  lda #CMD_SAVE_CFG
- sta @l MCU_CMD
  cmp @l SNES_CMD
  bne -
  lda #$0000
  sta @l MCU_CMD
  bra menu_edit_value_skip_reset_chghook
+ lda [w_value_addr,d]
  sta w_work_value,d
  jsr menu_check_change_hook
menu_edit_value_skip_reset_chghook:
  phx
    lda #$0000
    jsr set_bar_color
  plx
menu_edit_value_out:
  #FreeStack
  rts



; **** menu value dialogs ****
; params:
; =======
;   y: address of menu entry struct
;  db: bank of menu entry struct
;
; returns:
; ========
;   c: set="value set" (call post edit hook)
;      clear="entry cancelled"
; the value itself is modified as a working copy and written back on demand.
menu_value_dialog_dummy:
  rts

menu_value_dialog_u8:
  php
    rep #$10
    .xl
    sep #$20
    .as
    phb
-     jsr waitblank
      jsr read_pad
      jsr printtime
      lda wram(pad_up)
      bne menu_value_dialog_u8_up
      lda wram(pad_down)
      bne menu_value_dialog_u8_down
      lda wram(pad_left)
      bne menu_value_dialog_u8_left
      lda wram(pad_right)
      bne menu_value_dialog_u8_right
      lda wram(pad_b)
      beq *+5
      brl menu_value_dialog_u8_cancel
      lda wram(pad_a)
      beq *+5
      brl menu_value_dialog_u8_set
      lda wram(pad_l)
      bne menu_value_dialog_u8_l
      lda wram(pad_r)
      bne menu_value_dialog_u8_r
      bra -
menu_value_dialog_u8_up:
      lda w_work_value,d
      ldy #$0002
      cmp [w_preset_addr,d],y
      bcc menu_value_dialog_u8_up_ok
menu_value_dialog_u8_up_nok:
      lda [w_preset_addr,d],y
      sta w_work_value,d
      bra +
menu_value_dialog_u8_up_ok:
      inc w_work_value,d
      bra +
menu_value_dialog_u8_down:
      lda w_work_value,d
      cmp [w_preset_addr,d]
      beq +
      bcs menu_value_dialog_u8_down_ok
menu_value_dialog_u8_down_nok:
      lda [w_preset_addr,d]
      sta w_work_value,d
      bra +
menu_value_dialog_u8_down_ok:
      dec w_work_value,d
      bra +
menu_value_dialog_u8_left:
      lda w_work_value,d
      sec
      sbc #9
      bcs menu_value_dialog_u8_left_noclip
      lda #$00
menu_value_dialog_u8_left_noclip:
      sta w_work_value,d
      cmp [w_preset_addr,d]
      beq +
      bcs menu_value_dialog_u8_down_ok
      bra menu_value_dialog_u8_down_nok
menu_value_dialog_u8_right:
      lda w_work_value,d
      clc
      adc #9
      bcc menu_value_dialog_u8_right_noclip
      lda #$ff
menu_value_dialog_u8_right_noclip:
      sta w_work_value,d
      ldy #$0002
      cmp [w_preset_addr,d],y
      beq +
      bcc menu_value_dialog_u8_up_ok
      bra menu_value_dialog_u8_up_nok
menu_value_dialog_u8_l:
      lda [w_preset_addr,d]
      sta w_work_value,d
      bra +
menu_value_dialog_u8_r:
      ldy #$0002
      lda [w_preset_addr,d],y
      sta w_work_value,d
      bra +
menu_value_dialog_u8_cancel:
    plb
  plp
  clc
  rts
menu_value_dialog_u8_set:
      lda w_work_value,d
      sta [w_value_addr,d]
      bra menu_value_dialog_u8_cont
menu_value_dialog_u8_print:
+     rep #$20
      .al
      lda w_work_value,d
      and #$00ff
      jsr bin2dec16
      phb
        sep #$20
        .as
        lda #`wram(stringbuf)
        pha
        plb
        ldy #stringbuf
        jsr right_align
        lda bar_yl
        inc a
        sta print_y
        lda #$01
        bit w_text_grey,d
        bpl +
        lda #$06
+       sta print_pal
        jsr hiprint
      plb
      brl -
menu_value_dialog_u8_cont:
    plb
  plp
  sec
  rts

menu_value_dialog_u16:
  php
    rep #$10
    .xl
    sep #$20
    .as
    phb
; adjust selection bar to highlight parameter area
      rep #$20
      .al
-     jsr waitblank
      jsr read_pad
      jsr printtime
      lda wram(pad_up)
      ror
      bcs menu_value_dialog_u16_up
      lda wram(pad_down)
      ror
      bcs menu_value_dialog_u16_down
      lda wram(pad_left)
      ror
      bcs menu_value_dialog_u16_left
      lda wram(pad_right)
      ror
      bcs menu_value_dialog_u16_right
      lda wram(pad_b)
      ror
      bcc *+5
      brl menu_value_dialog_u16_cancel
      lda wram(pad_a)
      ror
      bcc *+5
      brl menu_value_dialog_u16_set
      lda wram(pad_l)
      ror
      bcs menu_value_dialog_u16_l
      lda wram(pad_r)
      ror
      bcs menu_value_dialog_u16_r
      bra -
menu_value_dialog_u16_up:
      lda w_work_value,d
      ldy #$0002
      cmp [w_preset_addr,d],y
      bcc menu_value_dialog_u16_up_ok
menu_value_dialog_u16_up_nok:
      lda [w_preset_addr,d],y
      sta w_work_value,d
      bra +
menu_value_dialog_u16_up_ok:
      inc w_work_value,d
      bra +
menu_value_dialog_u16_down:
      lda w_work_value,d
      cmp [w_preset_addr,d]
      beq +
      bcs menu_value_dialog_u16_down_ok
menu_value_dialog_u16_down_nok:
      lda [w_preset_addr,d]
      sta w_work_value,d
      bra +
menu_value_dialog_u16_down_ok:
      dec w_work_value,d
      bra +
menu_value_dialog_u16_left:
      lda w_work_value,d
      sec
      sbc #99
      bcs menu_value_dialog_u16_left_noclip
      lda #$0000
menu_value_dialog_u16_left_noclip:
      sta w_work_value,d
      cmp [w_preset_addr,d]
      beq +
      bcs menu_value_dialog_u16_down_ok
      bra menu_value_dialog_u16_down_nok
menu_value_dialog_u16_right:
      lda w_work_value,d
      clc
      adc #99
      bcc menu_value_dialog_u16_right_noclip
      lda #$ffff
menu_value_dialog_u16_right_noclip:
      sta w_work_value,d
      ldy #$0002
      cmp [w_preset_addr,d],y
      beq +
      bcc menu_value_dialog_u16_up_ok
      bra menu_value_dialog_u16_up_nok
menu_value_dialog_u16_l:
      lda [w_preset_addr,d]
      sta w_work_value,d
      bra +
menu_value_dialog_u16_r:
      ldy #$0002
      lda [w_preset_addr,d],y
      sta w_work_value,d
      bra +
menu_value_dialog_u16_cancel:
    plb
  plp
  clc
  rts
menu_value_dialog_u16_set:
      lda w_work_value,d
      sta [w_value_addr,d]
      bra menu_value_dialog_u16_cont
menu_value_dialog_u16_print:
+     rep #$20
      .al
      lda w_work_value,d
      jsr bin2dec16
      phb
        sep #$20
        .as
        lda #`wram(stringbuf)
        pha
        plb
        ldy #stringbuf
        jsr right_align
        lda bar_yl
        inc a
        sta print_y
        lda #$01
        bit w_text_grey,d
        bpl +
        lda #$06
+       sta print_pal
        jsr hiprint
      plb
      rep #$20
      .al
      brl -
menu_value_dialog_u16_cont:
    plb
  plp
  sec
  rts

menu_value_dialog_string:
  rts

menu_value_dialog_kv8:
  php
    phb
      sep #$20
      .as
      lda w_preset_bank,d
      pha
      plb
      ldy w_preset_addr,d
      rep #$20
      .al
      lda w_work_value,d
      and #$00ff
      jsr menu_kv_lookup
; sanitize invalid option setting
      sep #$20
      .as
      cpy #$ffff
      bne menu_value_dialog_kv8_loop
      ldy w_preset_addr,d
menu_value_dialog_kv8_loop:
      phy
        jsr waitblank
        jsr read_pad
        jsr printtime
      ply
      lda wram(pad_up)
      bne menu_value_dialog_kv8_up
      lda wram(pad_down)
      bne menu_value_dialog_kv8_down
      lda wram(pad_a)
      bne menu_value_dialog_kv8_set
      lda wram(pad_b)
      bne menu_value_dialog_kv8_cancel
      bra menu_value_dialog_kv8_loop
menu_value_dialog_kv8_up:
      ldx @w $5,y
      cpx #$ffff
      beq +
      iny
      iny
      iny
      iny
      iny
      bra +
menu_value_dialog_kv8_down:
      cpy w_preset_addr,d
      beq +
      dey
      dey
      dey
      dey
      dey
      bra +
menu_value_dialog_kv8_set:
      lda @w $0,y
      sta [w_value_addr,d]
      brl menu_value_dialog_kv8_cont
menu_value_dialog_kv8_cancel:
    plb
  plp
  clc
  rts
+     lda #`space64
      sta wram(print_bank)
      rep #$20
      .al
      lda #<>space64
      sta wram(print_src)
      sep #$20
      .as
      lda wram(bar_yl)
      inc a
      sta wram(print_y)
      lda wram(window_x)
      clc
      adc wram(window_w)
      clc
      sbc w_value_len,d
      dec a
      sta wram(print_x)
      lda w_value_len,d
      sta wram(print_count)
      phy
        jsr hiprint
      ply
      rep #$20
      .al
      lda @w $0,y
      and #$00ff
      sta w_work_value,d
      lda @w $2,y
      sta wram(print_src)
      sta w_label_addr,d
      sep #$20
      .as
      lda @w $4,y
      sta wram(print_bank)
      lda #$01
      bit w_text_grey,d
      bpl +
      lda #$06
+     sta wram(print_pal)
      phy
        ldy w_label_addr,d
        lda wram(print_bank)
        phb
          pha
          plb
          jsr right_align
          jsr hiprint
        plb
      ply
      jsr menu_check_change_hook
      brl menu_value_dialog_kv8_loop
menu_value_dialog_kv8_cont:
    plb
  plp
  sec
  rts

menu_value_dialog_kv16:
  rts

menu_value_dialog_file:
  rts

menu_value_dialog_time:
  php
    sep #$20
    .as
    lda wram(window_x)
    clc
    adc wram(window_w)
    clc
    sbc w_value_len,d
    dec a
    pha ; p_time_x
    lda wram(bar_yl)
    inc a
    pha ; p_time_y
    lda w_value_bank,d
    pha
    ldx w_value_addr,d
    phx
    jsr time_init
    plx
    plx
    pla
    bcc menu_value_dialog_time_cancel
  plp
  sec
  rts
menu_value_dialog_time_cancel:
  plp
  clc
  rts

menu_check_change_hook:
  php
  sep #$20
  .as
  ; call function, if defined, to perform some action during value selection
    lda w_chgfunc_addr,d
    ora w_chgfunc_addr + 1,d
    ora w_chgfunc_bank,d
    clc
    beq menu_check_change_hook_exit
  ; push long return address for after function call
    phk
    per menu_check_change_hook_exit-1
  ; push long address of changeHook function
    lda w_chgfunc_bank,d
    pha
    lda w_chgfunc_addr + 1,d
    pha
    lda w_chgfunc_addr,d
    pha
    lda w_work_value,d
    rtl ; call the changeHook function
menu_check_change_hook_exit:
  plp
  rts



menu_check_disabled_func:
  .as
; call function, if defined, to determine whether menu entry should be drawn as active or inactive
  lda @w 20,x
  ora @w 21,x
  ora @w 22,x
  clc
  beq menu_check_disabled_func_exit
; push long return address for after function call
  phk
  per menu_check_disabled_func_exit-1
; push long address of isDisabled function
  lda @w 22,x
  pha
  lda @w 21,x
  pha
  lda @w 20,x
  pha
  rtl ; call the isDisabled function
menu_check_disabled_func_exit:
  rts

; jump table to different data type edit dialogs
menu_tab_edit_value_dialogs:
.word <>menu_value_dialog_dummy
.word <>menu_value_dialog_u8
.word <>menu_value_dialog_u16
.word <>menu_value_dialog_string
.word <>menu_value_dialog_kv8
.word <>menu_value_dialog_kv16
.word <>menu_value_dialog_file
.word <>menu_value_dialog_time

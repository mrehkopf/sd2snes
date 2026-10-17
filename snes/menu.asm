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
show_menu .block
; params:
; x: offset of menu structure
; db: bank of menu structure
  .virtual #0,d
Frame .block
  numentries    .word ?
  max_lbl_len   .word ?
  max_opt_len   .word ?
  title_len     .word ?
  menu_addr     .word ?
  menu_bank     .byte ?
  unused        .byte ?
  _             .dstruct SaveJSR
.endblock
  .endvirtual
  .enter
; backup params
  sep #$20
  .as
  phb
  pla
  sta Frame.menu_bank
  stx Frame.menu_addr
  jsr menu_measure        ; determine required window dimensions
  sep #$20
  .as
  lda #$80
  phb
    pha
    plb
    lda Frame.numentries
    sta $211b
    stz $211b
    lda [Frame.menu_addr] ; listsel_step from menu structure
    sta $211c
    lda $2134
    sec
    sbc [Frame.menu_addr] ; listsel_step from menu structure
    inc a
    inc a
    inc a
    sta window_h
    lda Frame.max_lbl_len
    clc
    adc Frame.max_opt_len
; check whether window width is limited by label+option
; or by window title text
    cmp Frame.title_len
    bcs +
    lda Frame.title_len
    inc a
    inc a
+   clc
    adc #$04
    ldx Frame.max_opt_len
    beq +
    inc a
    inc a
    inc a
+   sta window_w
    jsr push_window
    lda [Frame.menu_addr]
    sta listsel_step
    stz listsel_sel
    ldy #MenuHeader.title
    rep #$20
    .al
    lda [Frame.menu_addr],y
    sta window_taddr
    sep #$20
    .as
    iny
    iny
    lda [Frame.menu_addr],y
    sta window_tbank
    jsr draw_window
    jsr show_menu_entries
    lda Frame.numentries
    sta listsel_max
show_menu_loop:
    stz listsel_pickbutton
    jsr menu_select_noinit
    cmp #$ff
    beq show_menu_out
    sta $211b
    stz $211b
    lda #size(MenuEntry)
    sta $211c
    rep #$20
    .al
    lda $2134
    clc
    adc #size(MenuHeader)
    tay
    lda [Frame.menu_addr],y
    and #$00ff
    iny                         ; Y -> MenuEntry.target
    iny
    iny
    iny
    cmp #MTYPE_SUBMENU
    beq show_menu_submenu
    cmp #MTYPE_FUNC
    beq show_menu_func
    cmp #MTYPE_FUNC_CLOSE
    .jeq show_menu_func_close
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
  .leave
  rts

show_menu_entries:
  php
  sep #$20
  .as
  phb
    lda Frame.menu_bank
    pha
    plb
    ldx Frame.menu_addr
    inx                         ; skip MenuHeader
    inx
    inx
    inx
    lda Frame.max_lbl_len
    .param pha
    lda Frame.max_opt_len
    .param pha
    .call menu_print_entries
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
    lda [Frame.menu_addr],y
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
    lda [Frame.menu_addr],y
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
    lda [Frame.menu_addr],y
    tax
    sep #$20
    .as
    iny
    iny
    lda [Frame.menu_addr],y
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
    lda [Frame.menu_addr],y
    tax
    sep #$20
    .as
    iny
    iny
    lda [Frame.menu_addr],y
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
        adc Frame.menu_addr
        sec
        sbc #MenuEntry.target ; Y pointed to the target field
        tax
        sep #$20
        .as
        lda Frame.menu_bank
        pha
        plb
        jsr menu_edit_value
      plb
    ply
    jmp show_menu_cont

; helper for show_menu (no frame of its own)
; params:
; x: offset of menu structure
; db: bank of menu structure
.text "MENU_MEASURE"
menu_measure:
  php
  rep #$20
  .al
  stz Frame.max_lbl_len ; initialize variable
  stz Frame.max_opt_len ; initialize variable
  stz Frame.numentries
; include window title in calculation
  sep #$20
  .as
  ldy @w MenuHeader.title,x
  lda @w MenuHeader.title+2,x
  phb
    pha
    plb
    jsr strlen
    sty Frame.title_len
  plb
  inx
  inx
  inx
  inx ; move pointer past menu header
  rep #$20
  .al
menu_measure_line_loop:
  lda @w MenuEntry.type,x ; read menu entry type
  and #$00ff              ; (mask)
  beq menu_measure_out    ; termination -> exit
  inc Frame.numentries    ; entry counter
  phb
    sep #$20
    .as
    ldy @w MenuEntry.text,x ; resolve pointer to menu entry text
    lda @w MenuEntry.text+2,x
    pha
    plb
    jsr strlen
  plb
  lda @w MenuEntry.type,x
  cmp #MTYPE_SUBMENU    ; add 2 chars for '...' on sub menu entries
  bne +
  iny
  iny
+ rep #$20
  .al
  cpy Frame.max_lbl_len         ; replace max value with
  bmi +                         ; new length
  sty Frame.max_lbl_len         ; if bigger or equal.
+ jsr menu_meas_opt             ; calculate max option string length
                               ; move to next entry.
  cmp Frame.max_opt_len
  bmi +
  sta Frame.max_opt_len
+ txa
  clc
  adc #size(MenuEntry)
  tax
  bra menu_measure_line_loop
menu_measure_out:
  plp
  rts
.endblock


; **** menu_meas_opt ****
; params:
; =======
; x : address of menu entry
; db: bank of menu entry
;
; returns:
; ========
; a: calculated max parameter length for values of this entry
; Y IS CLOBBERED
menu_meas_opt .block
  .virtual #0,d
Frame .block
  max_len       .word ?         ; longest key-value text so far
  _             .dstruct SaveJSR
.endblock
  .endvirtual
  .enter
    sep #$20
    .as
  ;  lda !$4, x         ; calculate space needed to show options
  ;  cmp #MTYPE_VALUE   ; only for "value set" entry types
  ;  bne menu_meas_opt_none
    lda @w MenuEntry.dtype,x
    beq menu_meas_opt_none ; no option
    cmp #OPTTYPE_BYTE         ; uint8
    bne menu_meas_opt_02
    lda #$03                  ; "0"-"255" - 3 chars
    bra menu_meas_opt_set
menu_meas_opt_02:
    cmp #OPTTYPE_WORD         ; uint16
    bne menu_meas_opt_03
    lda #$05                  ; "0"-"65535" - 5 chars
    bra menu_meas_opt_set
menu_meas_opt_03:
    cmp #OPTTYPE_STRING       ; string (free entry)
    bne menu_meas_opt_04
    lda @w MenuEntry.target,x ; load length constraint
    bra menu_meas_opt_set
menu_meas_opt_04:
    cmp #OPTTYPE_KVBYTE       ; key-value (8bit)
    beq menu_meas_opt_keyval
    cmp #OPTTYPE_KVWORD       ; key-value (16bit)
    bne menu_meas_opt_06
menu_meas_opt_keyval: ; count max value length
    phb
      ldy @w MenuEntry.target,x   ; get pointer to
      lda @w MenuEntry.target+2,x ; key-value table
      pha
      plb
      rep #$20
      .al
      stz Frame.max_len
menu_meas_opt_nextkey:
      lda @w KVEntry.key,y ; get key
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
        cmp Frame.max_len ; compare-replace
        bmi menu_meas_opt_keyval_skip
        sta Frame.max_len
menu_meas_opt_keyval_skip:
      ply
      iny              ; move to next key
      iny
      iny
      bra menu_meas_opt_nextkey
+
    plb
    lda Frame.max_len
    bra menu_meas_opt_set
menu_meas_opt_06:     ; file select (16 characters)
    .as
    cmp #OPTTYPE_FILESEL
    bne menu_meas_opt_07
    lda #$10
    bra menu_meas_opt_set
menu_meas_opt_07:     ; date/time select (19 characters)
    lda #$13
    bra menu_meas_opt_set
menu_meas_opt_none:
    .as
    lda #$00
menu_meas_opt_set:
  rep #$20
  .al
  and #$00ff
  tay                           ; leave destroys A
  .leave
  tya
  rts
.endblock

.text "MENU_PRINT_ENTRIES"
menu_print_entries .block
; params
; x: address of menu entry structure
; db: bank of menu entry structure
  .virtual #0,d
Frame .block
  y             .byte ?         ; row of the entry
  x             .byte ?         ; column of the label
  pal           .byte ?         ; palette of the label
  done          .byte ?         ; length of the label
  _             .dstruct SaveJSR
  p_max_opt_len .byte ?         ; pushed last
  p_max_lbl_len .byte ?         ; pushed first
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  lda wram(window_y)
  inc a
  sta Frame.y
menu_print_ent_loop:
  lda wram(window_x)
  inc a
  inc a
  sta Frame.x
  lda @w MenuEntry.type,x ; entry type. 0 = termination
  bne +
  jmp menu_print_ent_out
+ jsr menu_check_disabled_func
  lda #$00
  bcc +
  lda #$06
+ sta Frame.pal
  phx
  lda @w MenuEntry.text+2,x ; option name string
  .param pha
  rep #$20
  .al
  lda @w MenuEntry.text,x
  .param pha
  sep #$20
  .as
  lda Frame.x
  .param pha
  lda Frame.y
  .param pha
  lda Frame.pal
  .param pha
  lda wram(window_w)
  .param pha
  .call print_text
  sta Frame.done
  .unparam print_text
  plx
  lda @w MenuEntry.type,x
  cmp #MTYPE_SUBMENU
  bne +
  phx
    lda #`text_ellipse          ; "..." right after sub menu names
    .param pha
    .param pea, <>text_ellipse
    lda Frame.x
    clc
    adc Frame.done
    .param pha
    lda Frame.y
    .param pha
    lda Frame.pal
    .param pha
    lda wram(window_w)
    .param pha
    .call print_text
    .unparam print_text
  plx
+ phx
    lda #`space64               ; clear the value
    .param pha
    .param pea, <>space64
    lda Frame.p_max_lbl_len
    clc
    adc wram(window_x)
    adc #$05
    .param pha
    lda Frame.y
    .param pha
    lda Frame.pal
    .param pha
    lda Frame.p_max_opt_len
    .param pha
    .call print_text
    .unparam print_text
  plx
  lda Frame.y
  .param pha
  .call menu_print_opt_string
  .unparam menu_print_opt_string
  rep #$20
  .al
  txa
  clc
  adc #size(MenuEntry)
  tax
  sep #$20
  .as
  lda Frame.y
  clc
  adc wram(listsel_step)
  sta Frame.y
  jmp menu_print_ent_loop
menu_print_ent_out:
  .leave
  rts
.endblock

.text "MENU_PRINT_OPT_STRING"
menu_print_opt_string .block
; params
; x: address of menu entry structure (preserved)
; db: bank of menu entry structure
; p_y: row
  .virtual #0,d
Frame .block
  entry_addr    .word ?
  entry_bank    .byte ?
  kvpar_addr    .word ?
  kvpar_bank    .byte ?
  kvpar_data    .word ?
  kvtab_addr    .word ?
  kvtab_bank    .byte ?
  text          .fill 20        ; the value as text, if it isn't one already
  pal           .byte ?         ; palette of the value
  count         .byte ?         ; characters of the value to print at most
  col           .byte ?
  _             .dstruct SaveJSR
  p_y           .byte ?
.endblock
  .endvirtual
  .enter
  rep #$20
  .al
  lda @w MenuEntry.value,x
  sta Frame.entry_addr
  sep #$20
  .as
  jsr menu_check_disabled_func
  lda #$01
  bcc +
  lda #$06
+ sta Frame.pal
  lda #$40
  sta Frame.count
  lda @w MenuEntry.value+2,x
  sta Frame.entry_bank
  lda @w MenuEntry.dtype,x
  .jeq menu_print_opt_string_out
  cmp #OPTTYPE_BYTE
  bne menu_print_opt_string_02
  rep #$20
  .al
  lda [Frame.entry_addr]
  and #$00ff
  bra menu_print_opt_string_number
menu_print_opt_string_02:
  .as
  cmp #OPTTYPE_WORD
  bne menu_print_opt_string_03
  rep #$20
  .al
  lda [Frame.entry_addr]
menu_print_opt_string_number:
  .al
  phx
    tay
    sep #$20
    .as
    lda #$00                    ; Frame.text, on the stack
    .param pha
    rep #$20
    .al
    tdc
    clc
    adc #Frame.text - Frame
    .param pha
    .param phy
    .call bin2dec
    .unparam bin2dec
    sep #$20
    .as
    jsr print_text_value
  plx
  jmp menu_print_opt_string_out
menu_print_opt_string_03:
  .as
  cmp #OPTTYPE_STRING
  bne menu_print_opt_string_04
  lda @w MenuEntry.target,x
  sta Frame.count
  phx
    lda @w MenuEntry.value+2,x
    pha
    rep #$20
    .al
    lda @w MenuEntry.value,x
    tax
    sep #$20
    .as
    pla
    jsr print_value
  plx
  jmp menu_print_opt_string_out
menu_print_opt_string_04:
  .as
  cmp #OPTTYPE_KVBYTE
  beq menu_print_opt_string_keyval
  cmp #OPTTYPE_KVWORD
  bne menu_print_opt_string_06
menu_print_opt_string_keyval:
  lda @w MenuEntry.value+2,x ; load address
  ldy @w MenuEntry.value,x   ; of current setting
  sta Frame.kvpar_bank
  sty Frame.kvpar_addr
  rep #$20
  .al
  lda [Frame.kvpar_addr]     ; load currently set value
  ; mask for 8-bit key!
  phx
    ldy @w MenuEntry.dtype,x
    sep #$10
    .xs
    cpy #OPTTYPE_KVWORD
    beq +
    and #$00ff
+   rep #$10
    .xl
  plx
  sta Frame.kvpar_data
  lda @w MenuEntry.target,x  ; load pointer to kvtable
  sta Frame.kvtab_addr
  sep #$20
  .as
  lda @w MenuEntry.target+2,x
  sta Frame.kvtab_bank
  phx
    phb
      pha
      plb
      rep #$20
      .al
      ldy Frame.kvtab_addr
      lda Frame.kvpar_data
      .param pha
      .call menu_kv_lookup
      pla
; sanitize invalid option setting
      cpy #$ffff
      bne +
      ldy Frame.kvtab_addr     ; invalid setting -> default to first entry
+     ldx @w KVEntry.text,y
      sep #$20
      .as
      lda @w KVEntry.text+2,y
    plb
    jsr print_value
  plx
  jmp menu_print_opt_string_out
menu_print_opt_string_06:
  sep #$20
  .as
  cmp #OPTTYPE_FILESEL
  bne menu_print_opt_string_07
  lda #$41
  sta Frame.text
  lda #$00
  sta Frame.text+1
  jsr menu_check_disabled_func
  lda #$02
  bcc +
  lda #$06
+ sta Frame.pal
  lda #$10
  sta Frame.count
  phx
    jsr print_text_value
  plx
  bra menu_print_opt_string_out
menu_print_opt_string_07:
  sep #$20
  .as
  jsr menu_check_disabled_func
  lda #$02
  bcc +
  lda #$06
+ sta Frame.pal
  lda #$13
  sta Frame.count
  phx
    lda #$00                    ; Frame.text, on the stack
    .param pha
    rep #$20
    .al
    tdc
    clc
    adc #Frame.text - Frame
    .param pha
    sep #$20
    .as
    lda Frame.entry_bank
    ldx Frame.entry_addr
    .param pha
    .param phx
    .call rendertime
    .unparam rendertime
    jsr print_text_value
  plx
menu_print_opt_string_out:
  .leave
  rts

; helpers in the frame of menu_print_opt_string

; print Frame.text as the value
print_text_value:
  .as
  lda #$00
  pha
  rep #$20
  .al
  tdc
  clc
  adc #Frame.text - Frame
  tax
  sep #$20
  .as
  pla
; print the string at A:X (bank:address) as the value: right-aligned in
; the window, with Frame.pal, at most Frame.count characters
print_value:
  .as
  pha
  phx
  phb
    pha
    plb
    txy
    jsr right_align
    sta Frame.col
  plb
  plx
  pla
  .param pha
  .param phx
  lda Frame.col
  .param pha
  lda Frame.p_y
  .param pha
  lda Frame.pal
  .param pha
  lda Frame.count
  .param pha
  .call print_text
  .unparam print_text
  rts
.endblock


; menu_kv_lookup
; look for key in a kv table
; and return address of kv entry
; params:
; y: address of entry table
; db: bank of entry table
; p_key: search value (word)
; returns:
; y: address of table entry if found,
;    $ffff if not found
menu_kv_lookup .block
  .virtual #0,d
Frame .block
  _             .dstruct SaveJSR
  p_key         .word ?         ; search value
.endblock
  .endvirtual
  .enter
    rep #$10
    .xl
-   lda @w KVEntry.key,y ; compare with table key
    cmp #$ffff           ; termination
    beq +
    cmp Frame.p_key      ; compare with search value
    beq menu_kv_lookup_out
    iny
    iny
    iny
    iny
    iny
    bra -
+   ldy #$ffff
menu_kv_lookup_out:
  .leave
  rts
.endblock

; menu_edit_value
; show a select/edit dialog depending on data type
; and store value in location according to menu
; entry structure
; params:
; db: bank of menu entry
; x: address of menu entry
.text "MENU_EDIT_VALUE"
menu_edit_value .block
; local variables (also used by the value dialogs and menu_check_change_hook,
; which run inside this frame and are therefore part of this block)
  .virtual #0,d
Frame .block
  preset_addr   .word ?
  preset_bank   .byte ?
  value_addr    .word ?
  value_bank    .byte ?
  work_value    .word ?
  label_addr    .word ?
  label_bank    .byte ?
  value_len     .word ?
  text_grey     .byte ?
  chgfunc_addr  .word ?
  chgfunc_bank  .byte ?
  text          .fill 6         ; the number being edited as text
  count         .byte ?         ; characters print_at_bar prints at most
  col           .byte ?
  _             .dstruct SaveJSR
.endblock
  .endvirtual
; returns:
; carry flag: 1=value set, 0=cancelled
  .enter
  ; prepare work variables for sub routines
  jsr menu_meas_opt
  sta Frame.value_len
  lda @w MenuEntry.target,x
  sta Frame.preset_addr
  lda @w MenuEntry.value,x
  sta Frame.value_addr
  lda @w MenuEntry.chg_func,x
  sta Frame.chgfunc_addr
  lda #$0000 ; cleanup B for jump table offset
  sep #$20
  .as
  jsr menu_check_disabled_func
  ror
  sta Frame.text_grey
  lda @w MenuEntry.target+2,x
  sta Frame.preset_bank
  lda @w MenuEntry.value+2,x
  sta Frame.value_bank
  lda @w MenuEntry.chg_func+2,x
  sta Frame.chgfunc_bank
; adjust selection bar to highlight parameter area
  lda wram(bar_xl)
  clc
  adc wram(bar_wl)
  sec
  sbc Frame.value_len
  sta wram(bar_xl)
  lda Frame.value_len
  sta wram(bar_wl)
  lda @w MenuEntry.dtype,x ; load data type
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
  lda [Frame.value_addr]
  sta Frame.work_value
  jsr (menu_tab_edit_value_dialogs,x)
  bcc +
  lda #CMD_SAVE_CFG
- sta @l MCU_CMD
  cmp @l SNES_CMD
  bne -
  lda #$0000
  sta @l MCU_CMD
  bra menu_edit_value_skip_reset_chghook
+ lda [Frame.value_addr]
  sta Frame.work_value
  jsr menu_check_change_hook
menu_edit_value_skip_reset_chghook:
  phx
    lda #$0000
    jsr set_bar_color
  plx
menu_edit_value_out:
  .leave
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
      bne menu_value_dialog_u8_cancel
      lda wram(pad_a)
      bne menu_value_dialog_u8_set
      lda wram(pad_l)
      bne menu_value_dialog_u8_l
      lda wram(pad_r)
      bne menu_value_dialog_u8_r
      bra -
menu_value_dialog_u8_up:
      lda Frame.work_value
      ldy #ValueRange.max
      cmp [Frame.preset_addr],y
      bcc menu_value_dialog_u8_up_ok
menu_value_dialog_u8_up_nok:
      lda [Frame.preset_addr],y
      sta Frame.work_value
      bra +
menu_value_dialog_u8_up_ok:
      inc Frame.work_value
      bra +
menu_value_dialog_u8_down:
      lda Frame.work_value
      cmp [Frame.preset_addr]
      beq +
      bcs menu_value_dialog_u8_down_ok
menu_value_dialog_u8_down_nok:
      lda [Frame.preset_addr]
      sta Frame.work_value
      bra +
menu_value_dialog_u8_down_ok:
      dec Frame.work_value
      bra +
menu_value_dialog_u8_left:
      lda Frame.work_value
      sec
      sbc #9
      bcs menu_value_dialog_u8_left_noclip
      lda #$00
menu_value_dialog_u8_left_noclip:
      sta Frame.work_value
      cmp [Frame.preset_addr]
      beq +
      bcs menu_value_dialog_u8_down_ok
      bra menu_value_dialog_u8_down_nok
menu_value_dialog_u8_right:
      lda Frame.work_value
      clc
      adc #9
      bcc menu_value_dialog_u8_right_noclip
      lda #$ff
menu_value_dialog_u8_right_noclip:
      sta Frame.work_value
      ldy #ValueRange.max
      cmp [Frame.preset_addr],y
      beq +
      bcc menu_value_dialog_u8_up_ok
      bra menu_value_dialog_u8_up_nok
menu_value_dialog_u8_l:
      lda [Frame.preset_addr]
      sta Frame.work_value
      bra +
menu_value_dialog_u8_r:
      ldy #ValueRange.max
      lda [Frame.preset_addr],y
      sta Frame.work_value
      bra +
menu_value_dialog_u8_cancel:
    plb
  plp
  clc
  rts
menu_value_dialog_u8_set:
      lda Frame.work_value
      sta [Frame.value_addr]
      bra menu_value_dialog_u8_cont
menu_value_dialog_u8_print:
+     rep #$20
      .al
      lda Frame.work_value
      and #$00ff
      jsr print_number
      sep #$20
      .as
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
      bcs menu_value_dialog_u16_cancel
      lda wram(pad_a)
      ror
      bcs menu_value_dialog_u16_set
      lda wram(pad_l)
      ror
      bcs menu_value_dialog_u16_l
      lda wram(pad_r)
      ror
      bcs menu_value_dialog_u16_r
      bra -
menu_value_dialog_u16_up:
      lda Frame.work_value
      ldy #ValueRange.max
      cmp [Frame.preset_addr],y
      bcc menu_value_dialog_u16_up_ok
menu_value_dialog_u16_up_nok:
      lda [Frame.preset_addr],y
      sta Frame.work_value
      bra +
menu_value_dialog_u16_up_ok:
      inc Frame.work_value
      bra +
menu_value_dialog_u16_down:
      lda Frame.work_value
      cmp [Frame.preset_addr]
      beq +
      bcs menu_value_dialog_u16_down_ok
menu_value_dialog_u16_down_nok:
      lda [Frame.preset_addr]
      sta Frame.work_value
      bra +
menu_value_dialog_u16_down_ok:
      dec Frame.work_value
      bra +
menu_value_dialog_u16_left:
      lda Frame.work_value
      sec
      sbc #99
      bcs menu_value_dialog_u16_left_noclip
      lda #$0000
menu_value_dialog_u16_left_noclip:
      sta Frame.work_value
      cmp [Frame.preset_addr]
      beq +
      bcs menu_value_dialog_u16_down_ok
      bra menu_value_dialog_u16_down_nok
menu_value_dialog_u16_right:
      lda Frame.work_value
      clc
      adc #99
      bcc menu_value_dialog_u16_right_noclip
      lda #$ffff
menu_value_dialog_u16_right_noclip:
      sta Frame.work_value
      ldy #ValueRange.max
      cmp [Frame.preset_addr],y
      beq +
      bcc menu_value_dialog_u16_up_ok
      bra menu_value_dialog_u16_up_nok
menu_value_dialog_u16_l:
      lda [Frame.preset_addr]
      sta Frame.work_value
      bra +
menu_value_dialog_u16_r:
      ldy #ValueRange.max
      lda [Frame.preset_addr],y
      sta Frame.work_value
      bra +
menu_value_dialog_u16_cancel:
    plb
  plp
  clc
  rts
menu_value_dialog_u16_set:
      lda Frame.work_value
      sta [Frame.value_addr]
      bra menu_value_dialog_u16_cont
menu_value_dialog_u16_print:
+     rep #$20
      .al
      lda Frame.work_value
      jsr print_number
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
      lda Frame.preset_bank
      pha
      plb
      ldy Frame.preset_addr
      rep #$20
      .al
      lda Frame.work_value
      and #$00ff
      .param pha
      .call menu_kv_lookup
      pla
; sanitize invalid option setting
      sep #$20
      .as
      cpy #$ffff
      bne menu_value_dialog_kv8_loop
      ldy Frame.preset_addr
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
      ldx @w size(KVEntry)+KVEntry.key,y     ; key of the next entry
      cpx #$ffff
      beq +
      iny
      iny
      iny
      iny
      iny
      bra +
menu_value_dialog_kv8_down:
      cpy Frame.preset_addr
      beq +
      dey
      dey
      dey
      dey
      dey
      bra +
menu_value_dialog_kv8_set:
      lda @w KVEntry.key,y
      sta [Frame.value_addr]
      brl menu_value_dialog_kv8_cont
menu_value_dialog_kv8_cancel:
    plb
  plp
  clc
  rts
+     sep #$20
      .as
      lda Frame.value_len
      sta Frame.count
      phy
        lda wram(window_x)      ; clear the value
        clc
        adc wram(window_w)
        clc
        sbc Frame.value_len
        dec a
        sta Frame.col
        lda #`space64
        ldx #<>space64
        jsr print_at_col
      ply
      rep #$20
      .al
      lda @w KVEntry.key,y
      and #$00ff
      sta Frame.work_value
      lda @w KVEntry.text,y
      sta Frame.label_addr
      sep #$20
      .as
      phy
        ldx Frame.label_addr
        lda @w KVEntry.text+2,y
        jsr print_at_bar
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
    sbc Frame.value_len
    dec a
    .param pha ; p_time_x
    lda wram(bar_yl)
    inc a
    .param pha ; p_time_y
    lda Frame.value_bank
    .param pha
    ldx Frame.value_addr
    .param phx
    .call time_init
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

; helpers for the value dialogs, in the frame of menu_edit_value

; print the number A (16-bit, A 16-bit) right-aligned at the bar
print_number:
  .al
  php
  tay
  sep #$20
  .as
  lda #$00                      ; Frame.text, on the stack
  .param pha
  rep #$20
  .al
  tdc
  clc
  adc #Frame.text - Frame
  .param pha
  .param phy
  .call bin2dec
  .unparam bin2dec
  tdc
  clc
  adc #Frame.text - Frame
  tax
  sep #$20
  .as
  lda #5
  sta Frame.count
  lda #$00
  jsr print_at_bar
  plp
  rts

; print the string at A:X (bank:address) right-aligned in the window
; at the row of the bar, at most Frame.count characters
print_at_bar:
  .as
  pha
  phx
  phb
    pha
    plb
    txy
    jsr right_align
    sta Frame.col
  plb
  plx
  pla
; print the string at A:X at Frame.col in the row of the bar
print_at_col:
  .as
  .param pha
  .param phx
  lda Frame.col
  .param pha
  lda wram(bar_yl)
  inc a
  .param pha
  lda #$01
  bit Frame.text_grey
  bpl +
  lda #$06
+ .param pha
  lda Frame.count
  .param pha
  .call print_text
  .unparam print_text
  rts

menu_check_change_hook:
  php
  sep #$20
  .as
  ; call function, if defined, to perform some action during value selection
    lda Frame.chgfunc_addr
    ora Frame.chgfunc_addr + 1
    ora Frame.chgfunc_bank
    clc
    beq menu_check_change_hook_exit
  ; push long return address for after function call
    phk
    per menu_check_change_hook_exit-1
  ; push long address of changeHook function
    lda Frame.chgfunc_bank
    pha
    lda Frame.chgfunc_addr + 1
    pha
    lda Frame.chgfunc_addr
    pha
    lda Frame.work_value
    rtl ; call the changeHook function
menu_check_change_hook_exit:
  plp
  rts
.endblock



menu_check_disabled_func:
  .as
; call function, if defined, to determine whether menu entry should be drawn as active or inactive
  lda @w MenuEntry.isenabled_func,x
  ora @w MenuEntry.isenabled_func+1,x
  ora @w MenuEntry.isenabled_func+2,x
  clc
  beq menu_check_disabled_func_exit
; push long return address for after function call
  phk
  per menu_check_disabled_func_exit-1
; push long address of isDisabled function
  lda @w MenuEntry.isenabled_func+2,x
  pha
  lda @w MenuEntry.isenabled_func+1,x
  pha
  lda @w MenuEntry.isenabled_func,x
  pha
  rtl ; call the isDisabled function
menu_check_disabled_func_exit:
  rts

; jump table to different data type edit dialogs
menu_tab_edit_value_dialogs:
.word <>menu_edit_value.menu_value_dialog_dummy
.word <>menu_edit_value.menu_value_dialog_u8
.word <>menu_edit_value.menu_value_dialog_u16
.word <>menu_edit_value.menu_value_dialog_string
.word <>menu_edit_value.menu_value_dialog_kv8
.word <>menu_edit_value.menu_value_dialog_kv16
.word <>menu_edit_value.menu_value_dialog_file
.word <>menu_edit_value.menu_value_dialog_time

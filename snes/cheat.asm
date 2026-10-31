; Cheat editor: show, enable, add, edit and remove the cheats of a file
;
; CMD_LOAD_CHT has the MCU read the cheat file of the selected file into the
; cheat area (NUM_CHEATS, CHEAT_ADDR, records as described by CHEAT_REC_* in
; memmap.inc), CMD_SAVE_CHT writes it back. The menu mapper lets the SNES
; write the cheat area, so the records are edited in place.
;
; The routines keep their state in their stack frames and work with any D:
; cheat_list holds the cheats' state (count, patches used, selection), the
; windows opened from it their own. Global are
; - the status bar message timer (cheat_msg_timer), as the status bar is
;   shared by all windows,
; - the copy of the cheat being edited in CHEAT_EDIT_BUF (cheat_fetch,
;   cheat_store), which the editor, the code pad and the name keyboard work
;   on (the keyboard on a copy of the name in CHEAT_NAME_BUF),
; - cheat_action and cheat_nosel, the interface to the functions of the
;   options menus: show_menu calls them in its own frame.
;
; All routines expect DB=$80, as set up by cheat_menu.

; message box: title "Error", the message, "OK" with the selection bar
ALERT_X          = 12
ALERT_Y          = 15
ALERT_W          = 40
ALERT_H          = 5
ALERT_OK_W       = 8                    ; width of the bar on "OK"

CHEAT_MSG_FRAMES = 150                  ; frames a status bar message stays

  .cerror (<>CHEAT_ADDR) != 0 || CHEAT_REC_STRIDE != $200, "cheat_rec_addr expects 512 byte records from a bank start"
  .cerror CHEAT_REC_SIZE & 1, "cheat records are copied word by word"
  .cerror CHEAT_NAME_MAXLEN > 253, "cheat name does not fit the record"

; ---------------------------------------------------------------------------
; send a command to the MCU and wait for it, with a busy note in the status bar
; A: command
; X: text of the busy note (bank of text_loading)
cheat_mcu_cmd:
  php
  sep #$20
  .as
  rep #$10
  .xl
  pha
  jsr cheat_clear_statusbar     ; the busy note covers only part of it
  jsr draw_busy_window
  pla
  jsl wram_mcu_cmd
  jsr pop_window
  plp
  rts

; ---------------------------------------------------------------------------
; frame loop, status bar and message box

; wait for the next frame, update the clock and the status bar, read the pad
; X: help text of the current window, shown again when a message is gone
cheat_frame:
  php
  sep #$20
  .as
  rep #$10
  .xl
- lda isr_done
  beq -
  stz isr_done
  phx
  jsr printtime
  plx
  lda cheat_msg_timer           ; remove an expired message
  beq +
  dec cheat_msg_timer
  bne +
  jsr cheat_statusbar
+ jsr read_pad
  plp
  rts

; print the help text of the current window to the status bar, unless a
; message is shown (cheat_frame calls this again when it is gone)
; X: help text (bank of text_cheat)
cheat_statusbar:
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda cheat_msg_timer
  bne +
  jsr cheat_clear_statusbar
  ldy #$0000
  jsr cheat_status_text
+ plp
  rts

; show a message in the status bar for a while
; X: message (bank of text_cheat)
cheat_message:
  php
  sep #$20
  .as
  rep #$10
  .xl
  jsr cheat_clear_statusbar
  lda #CHEAT_MSG_FRAMES
  sta cheat_msg_timer
  ldy #$0007
  jsr cheat_status_text
  plp
  rts

cheat_clear_statusbar:
  php
  sep #$20
  .as
  rep #$10
  .xl
  phx
  phy
  ldx #<>space64
  ldy #$0000
  jsr cheat_status_text
  ply
  plx
  plp
  rts

; print a text to the status bar
; X: text (bank of text_cheat), Y: palette
cheat_status_text:
  .as
  .xl
  lda #`text_cheat
  .param pha
  .param phx
  lda #$02
  .param pha
  lda listdisp
  clc
  adc #$0a
  .param pha
  tya
  .param pha
  lda #41                       ; up to the clock
  .param pha
  .call print_text
  .unparam print_text
  rts

; show an error message over the greyed-out browser area and wait for A
; or B (the selection bar is on "OK")
; X: message (bank of text_cheat)
; Y: help text of the current window (see cheat_frame)
cheat_alert .block
  .virtual #0,d
Frame .block
  help          .word ?
  bar_x         .byte ?         ; the selection bar of the window behind
  bar_y         .byte ?
  bar_w         .byte ?
  _             .dstruct SaveJSR
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  rep #$10
  .xl
  sty Frame.help
  phx
  ldx #<>cheat_rect_list        ; the browser area
  jsr cheat_greyout
  ldx #<>cheat_rect_alert
  jsr cheat_set_window
  ldx #<>text_cheat_error
  stx window_taddr
  lda #`text_cheat_error
  sta window_tbank
  jsr push_window
  jsr draw_window
  lda bar_xl
  sta Frame.bar_x
  lda bar_yl
  sta Frame.bar_y
  lda bar_wl
  sta Frame.bar_w
  lda #ALERT_X+(ALERT_W-ALERT_OK_W)/2
  sta bar_xl
  lda #ALERT_Y+2                 ; (the bar's line numbers are one less than the text's)
  sta bar_yl
  lda #ALERT_OK_W
  sta bar_wl
  plx
  lda #`text_cheat
  .param pha
  .param phx
  lda #ALERT_X+2
  .param pha
  lda #ALERT_Y+1
  .param pha
  lda #$00
  .param pha
  lda #ALERT_W-4
  .param pha
  .call print_text
  .unparam print_text
  .print_at text_cheat_ok, ALERT_X+ALERT_W/2-1, ALERT_Y+3, 0, 2
- ldx Frame.help
  jsr cheat_frame
  lda pad_a
  ora pad_b
  beq -
  lda Frame.bar_x
  sta bar_xl
  lda Frame.bar_y
  sta bar_yl
  lda Frame.bar_w
  sta bar_wl
  jsr pop_window                ; the message box
  jsr pop_window                ; the greyed-out browser area
  .leave
  rts
.endblock

; ---------------------------------------------------------------------------
; printing
;
; The windows start their Frame with a CheatWindow, as ".dstruct
; CheatWindow" without a label (so Frame.line, Frame.print_x etc.), and
; check that with ".cheat_window_check". The print and line helpers run in
; the frame of the window that calls them (D unchanged) and reach these
; members as Win.*: they print at print_x/print_y in palette print_pal, at
; most print_count characters, and build lines in line.

CHEAT_LINE_SIZE  = 57                   ; longest window line, with the NUL

CheatWindow .struct
  line          .fill CHEAT_LINE_SIZE ; line buffer for printing
  print_x       .byte ?         ; where the helpers print
  print_y       .byte ?
  print_pal     .byte ?
  print_count   .byte ?
.ends

  .virtual #0,d
Win .dstruct CheatWindow
  .endvirtual

; check that the Frame of a window starts with a CheatWindow
cheat_window_check .macro
  .cerror Frame.line != Win.line || Frame.print_count != Win.print_count, "Frame must start with .dstruct CheatWindow"
.endm

; print a string from the bank of text_cheat
; X: string address (preserved)
cheat_print_rom:
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda #`text_cheat
  jsr cheat_print_str
  plp
  rts

; print Win.line
cheat_print_line:
  php
  rep #$30
  .al
  .xl
  phx
  tdc
  clc
  adc #Win.line - Win
  tax
  sep #$20
  .as
  lda #$00                      ; bank of the stack
  jsr cheat_print_str
  plx
  plp
  rts

; print the string at A:X (bank:address); keeps X
cheat_print_str:
  .as
  .xl
  phx
  .param pha
  .param phx
  lda Win.print_x
  .param pha
  lda Win.print_y
  .param pha
  lda Win.print_pal
  .param pha
  lda Win.print_count
  .param pha
  .call print_text
  .unparam print_text
  plx
  rts

; fill Win.line with A (8-bit) spaces and terminate it (keeps X)
cheat_line_clear:
  php
  sep #$20
  .as
  rep #$10
  .xl
  phx
  rep #$20
  .al
  and #$00ff
  tax
  sep #$20
  .as
  stz Win.line,x
  lda #' '
- dex
  bmi +
  sta Win.line,x
  bra -
+ plx
  plp
  rts

; copy a NUL terminated string into Win.line (without its NUL)
; X: offset in Win.line, Y: string address in the bank of text_cheat
; returns X after the copied string
cheat_line_puts:
  php
  sep #$20
  .as
  rep #$10
  .xl
  phb
  lda #`text_cheat
  pha
  plb
- lda @w 0,y
  beq +
  sta Win.line,x
  inx
  iny
  bra -
+ plb
  plp
  rts

; set window_x/y/w/h from a rectangle (cheat_rect_*: x, y, w, h)
; X: address of the rectangle
cheat_set_window:
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda @l CHEAT_RECT_BANK,x
  sta window_x
  lda @l CHEAT_RECT_BANK+1,x
  sta window_y
  lda @l CHEAT_RECT_BANK+2,x
  sta window_w
  lda @l CHEAT_RECT_BANK+3,x
  sta window_h
  plp
  rts

; grey out a window to bring the one opened over it into focus;
; pop_window brings it back
; X: its rectangle
cheat_greyout:
  jsr cheat_set_window
  jsr push_window
  jmp window_greyout

; draw a frame (a window without title) inside the current window
; X: its rectangle
cheat_box:
  php
  rep #$10
  .xl
  jsr cheat_set_window
  ldx #<>space64+64             ; no title (empty string)
  stx window_taddr
  sep #$20
  .as
  lda #`space64
  sta window_tbank
  jsr draw_window
  plp
  rts

; draw a separator line across the current window
; A (8-bit): row
cheat_separator:
  php
  sep #$20
  .as
  rep #$10
  .xl
  phx
  tax
  lda window_x
  .param pha
  txa
  .param pha
  lda window_w
  .param pha
  .call draw_separator
  .unparam draw_separator
  plx
  plp
  rts

; convert a nibble into an ASCII hex digit
; A (8-bit): nibble
cheat_nib2asc:
  .as
  cmp #10
  bcc +
  adc #'A' - '0' - 10 - 1       ; carry is set
+ adc #'0'                      ; carry is clear here
  rts

; ---------------------------------------------------------------------------
; cheat records

; address of cheat record A (16-bit)
; returns A: bank, X: address (keeps the register sizes)
cheat_rec_addr:
  php
  rep #$30
  .al
  .xl
  asl a                         ; record offset = index * $200:
  xba                           ; the low 7 bits of the index * 2 become the
  pha                           ; high byte of the offset, the rest is the bank
  and #$ff00
  tax
  pla
  and #$00ff
  clc
  adc #`CHEAT_ADDR
  plp
  rts

; copy a cheat record
; params (push order): p_dst (long), p_src (long)
cheat_copy_record .block
  .virtual #0,d
Frame .block
  _             .dstruct SaveJSR
  p_src         .long ?         ; pushed last
  p_dst         .long ?         ; pushed first
.endblock
  .endvirtual
  .enter
  rep #$30
  .al
  .xl
  ldy #CHEAT_REC_SIZE-2
- lda [Frame.p_src],y
  sta [Frame.p_dst],y
  dey
  dey
  bpl -
  .leave
  rts
.endblock

; copy cheat record A (16-bit) to CHEAT_EDIT_BUF
cheat_fetch:
  php
  rep #$30
  .al
  .xl
  tay
  sep #$20
  .as
  lda #`CHEAT_EDIT_BUF
  .param pha
  .param pea, <>CHEAT_EDIT_BUF
  rep #$20
  .al
  tya
  jsr cheat_rec_addr
  sep #$20
  .as
  .param pha
  .param phx
  .call cheat_copy_record
  .unparam cheat_copy_record
  plp
  rts

; copy CHEAT_EDIT_BUF to cheat record A (16-bit)
cheat_store:
  php
  rep #$30
  .al
  .xl
  jsr cheat_rec_addr
  sep #$20
  .as
  .param pha
  .param phx
  lda #`CHEAT_EDIT_BUF
  .param pha
  .param pea, <>CHEAT_EDIT_BUF
  .call cheat_copy_record
  .unparam cheat_copy_record
  plp
  rts

; check whether a code patches WRAM, like cheat_is_wram_cheat in
; src/cheat.c: bank $7E/$7F, or an address below $2000 in a bank with bit 6
; clear
; A (16-bit): bytes 2 and 3 of the code (address high, bank); destroyed
; returns c=1 for WRAM
cheat_is_wram:
  php
  rep #$20
  .al
  cmp #$7e00                    ; bank $7E/$7F
  bcc +
  cmp #$8000
  bcc cheat_is_wram_yes
+ bit #$4000
  bne cheat_is_wram_no
  and #$00ff                    ; address high byte
  cmp #$0020
  bcc cheat_is_wram_yes
cheat_is_wram_no:
  plp
  clc
  rts
cheat_is_wram_yes:
  plp
  sec
  rts

; count the ROM and WRAM patches of a cheat record
; params: p_rec (long)
; returns X: ROM patches, Y: WRAM patches (needs 16-bit index registers)
cheat_count_patches .block
  .virtual #0,d
Frame .block
  rom           .word ?
  wram          .word ?
  left          .word ?         ; codes left to count
  _             .dstruct SaveJSR
  p_rec         .long ?
.endblock
  .endvirtual
  .enter
  rep #$30
  .al
  .xl
  stz Frame.rom
  stz Frame.wram
  ldy #CHEAT_REC_NUMCODES
  lda [Frame.p_rec],y
  and #$00ff
  beq out
  cmp #CHEAT_NUM_CODES+1
  bcc +
  lda #CHEAT_NUM_CODES
+ sta Frame.left
  ldy #CHEAT_REC_CODES+2        ; address high and bank of the first code
- lda [Frame.p_rec],y
  jsr cheat_is_wram
  bcc +
  inc Frame.wram
  bra ++
+ inc Frame.rom
+ iny
  iny
  iny
  iny
  dec Frame.left
  bne -
out:
  ldx Frame.rom
  ldy Frame.wram
  .leave
  rts
.endblock

; ---------------------------------------------------------------------------
; codes
;
; A code is 4 bytes as in the cheat records: value, address low, address
; high, bank. It is entered and shown as 8 digits (nibbles), most
; significant first: the raw code (bank, address, value; the PAR form) or
; the Game Genie code. The conversions follow cheat_gg2raw/cheat_raw2gg in
; src/cheat.c: after replacing each GG digit using a table the nibbles
; d0..d7 hold the bits VVVVVVVV AAAA BBBB CCDD DDEE EEFF FFGG, the raw code
; is DDDD FFFF AAAA GGCC BBBB EEEE VVVVVVVV.

cheat_gg2raw_tab:
  .byte $4, $6, $d, $e, $2, $7, $8, $3, $b, $5, $c, $9, $a, $0, $f, $1
cheat_raw2gg_tab:
  .byte $d, $f, $4, $7, $0, $9, $1, $5, $6, $b, $c, $8, $a, $2, $3, $e

; dst = ((lo & 3) << 2) | (hi >> 2) for the 2-bit fields that straddle
; nibbles; uses Frame.tmp of the routine it is expanded in
cheat_nibmix .macro lo, hi, dst
  lda \lo
  and #$03
  asl a
  asl a
  sta Frame.tmp
  lda \hi
  lsr a
  lsr a
  ora Frame.tmp
  sta \dst
.endm

; write the 8 digits of a code in raw (PAR) or Game Genie form
; params (push order): p_digits (long, 8 bytes), p_code (4 bytes as in the
; cheat records), p_fmt (CHEAT_CODEFMT_*)
cheat_code_digits .block
  .virtual #0,d
Frame .block
  raw           .fill 8         ; digits of the raw code
  nib           .fill 8         ; Game Genie digits before the table
  tmp           .byte ?
  _             .dstruct SaveJSR
  p_fmt         .byte ?         ; pushed last
  p_code        .fill 4
  p_digits      .long ?         ; pushed first
.endblock
  .endvirtual
  .enter
  sep #$30
  .as
  .xs
  ldx #3                        ; the raw digits, bank first
  ldy #0
- lda Frame.p_code,x
  lsr a
  lsr a
  lsr a
  lsr a
  sta [Frame.p_digits],y
  iny
  lda Frame.p_code,x
  and #$0f
  sta [Frame.p_digits],y
  iny
  dex
  bpl -
  lda Frame.p_fmt
  cmp #CHEAT_CODEFMT_GG
  bne out
  ldy #7                        ; Game Genie: mix the raw digits
- lda [Frame.p_digits],y
  tyx
  sta Frame.raw,x
  dey
  bpl -
  lda Frame.raw+6
  sta Frame.nib+0
  lda Frame.raw+7
  sta Frame.nib+1
  lda Frame.raw+2
  sta Frame.nib+2
  lda Frame.raw+4
  sta Frame.nib+3
  .cheat_nibmix Frame.raw+3, Frame.raw+0, Frame.nib+4
  .cheat_nibmix Frame.raw+0, Frame.raw+5, Frame.nib+5
  .cheat_nibmix Frame.raw+5, Frame.raw+1, Frame.nib+6
  .cheat_nibmix Frame.raw+1, Frame.raw+3, Frame.nib+7
  ldy #7
- ldx Frame.nib,y
  lda @l cheat_raw2gg_tab,x
  sta [Frame.p_digits],y
  dey
  bpl -
out:
  .leave
  rts
.endblock

; get the code of 8 digits in raw (PAR) or Game Genie form
; params (push order): p_digits (long), p_fmt (CHEAT_CODEFMT_*)
; returns X: bytes 0 and 1 of the code (value, address low), Y: bytes 2 and
; 3 (address high, bank) (needs 16-bit index registers)
cheat_digits_code .block
  .virtual #0,d
Frame .block
  raw           .fill 8         ; digits of the raw code
  nib           .fill 8         ; Game Genie digits after the table
  code          .fill 4
  tmp           .byte ?
  _             .dstruct SaveJSR
  p_fmt         .byte ?         ; pushed last
  p_digits      .long ?         ; pushed first
.endblock
  .endvirtual
  .enter
  sep #$30
  .as
  .xs
  ldy #7
  lda Frame.p_fmt
  bne gg
- lda [Frame.p_digits],y
  tyx
  sta Frame.raw,x
  dey
  bpl -
  bra pack
gg:
- lda [Frame.p_digits],y
  tax
  lda @l cheat_gg2raw_tab,x
  tyx
  sta Frame.nib,x
  dey
  bpl -
  .cheat_nibmix Frame.nib+4, Frame.nib+5, Frame.raw+0 ; D
  .cheat_nibmix Frame.nib+6, Frame.nib+7, Frame.raw+1 ; F
  lda Frame.nib+2                                     ; A
  sta Frame.raw+2
  .cheat_nibmix Frame.nib+7, Frame.nib+4, Frame.raw+3 ; G, C
  lda Frame.nib+3                                     ; B
  sta Frame.raw+4
  .cheat_nibmix Frame.nib+5, Frame.nib+6, Frame.raw+5 ; E
  lda Frame.nib+0                                     ; V
  sta Frame.raw+6
  lda Frame.nib+1
  sta Frame.raw+7
pack:
  ldx #6                        ; digit pairs from the value on
  ldy #0                        ; code byte
- lda Frame.raw,x
  asl a
  asl a
  asl a
  asl a
  ora Frame.raw+1,x
  phx
  tyx
  sta Frame.code,x
  plx
  iny
  dex
  dex
  bpl -
  rep #$30
  .al
  .xl
  ldx Frame.code
  ldy Frame.code+2
  .leave
  rts
.endblock

; write a code in raw (PAR) or Game Genie form: "7E0DBE09", "C2A8-DD08"
; params (push order): p_buf (long), p_code (4 bytes as in the cheat
; records), p_fmt (CHEAT_CODEFMT_*)
cheat_code_text .block
  .virtual #0,d
Frame .block
  digits        .fill 8
  _             .dstruct SaveJSR
  p_fmt         .byte ?         ; pushed last
  p_code        .fill 4
  p_buf         .long ?         ; pushed first
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  rep #$10
  .xl
  .param_dp Frame.digits
  .param pei, Frame.p_code+2
  .param pei, Frame.p_code
  lda Frame.p_fmt
  .param pha
  .call cheat_code_digits
  .unparam cheat_code_digits
  ldx #$0000
  ldy #$0000
- lda Frame.p_fmt
  cmp #CHEAT_CODEFMT_GG
  bne +
  cpx #$0004
  bne +
  lda #'-'
  sta [Frame.p_buf],y
  iny
+ lda Frame.digits,x
  jsr cheat_nib2asc
  sta [Frame.p_buf],y
  iny
  inx
  cpx #$0008
  bcc -
  .leave
  rts
.endblock

; describe a code: "WRAM 7E:0DBE = 09" (written over spaces)
; params (push order): p_buf (long), p_code (4 bytes as in the cheat records)
cheat_patch_text .block
  .virtual #0,d
Frame .block
  _             .dstruct SaveJSR
  p_code        .fill 4         ; pushed last
  p_buf         .long ?         ; pushed first
.endblock
  .endvirtual
  .enter
  rep #$30
  .al
  .xl
  lda Frame.p_code+2
  jsr cheat_is_wram
  sep #$20
  .as
  ldx #<>text_cheat_wram
  bcs +
  ldx #<>text_cheat_rom
+ ldy #$0000
  phb
  lda #`text_cheat
  pha
  plb
- lda @w 0,x
  beq +
  sta [Frame.p_buf],y
  inx
  iny
  bra -
+ plb
  iny
  lda Frame.p_code+3
  jsr put_hex8
  lda #':'
  sta [Frame.p_buf],y
  iny
  lda Frame.p_code+2
  jsr put_hex8
  lda Frame.p_code+1
  jsr put_hex8
  lda #' '
  sta [Frame.p_buf],y
  iny
  lda #'='
  sta [Frame.p_buf],y
  iny
  lda #' '
  sta [Frame.p_buf],y
  iny
  lda Frame.p_code
  jsr put_hex8
  .leave
  rts

; write A (8-bit) as two hex digits to [Frame.p_buf],y, advance Y
put_hex8:
  .as
  pha
  lsr a
  lsr a
  lsr a
  lsr a
  jsr cheat_nib2asc
  sta [Frame.p_buf],y
  iny
  pla
  and #$0f
  jsr cheat_nib2asc
  sta [Frame.p_buf],y
  iny
  rts
.endblock

; ===========================================================================
; cheat editor windows

; cheat list window
CHEAT_LIST_X     = 2
CHEAT_LIST_Y     = 9
CHEAT_LIST_W     = 60
CHEAT_LIST_H     = 18
CHEAT_LIST_COL   = CHEAT_LIST_X + 2     ; first text column
CHEAT_LIST_TEXTW = CHEAT_LIST_W - 4     ; text columns
CHEAT_LIST_HEAD  = CHEAT_LIST_Y + 1     ; table header, separator below
CHEAT_LIST_ROW0  = CHEAT_LIST_Y + 3     ; first list row
CHEAT_LIST_ROWS  = CHEAT_LIST_H - 7     ; list rows shown
CHEAT_LIST_FOOT  = CHEAT_LIST_ROW0 + CHEAT_LIST_ROWS ; separator, patches used, warnings
CHEAT_LIST_NAMEW = 44                   ; name column width
CHEAT_LIST_CODES = 48                   ; number of codes (2 digits)
CHEAT_LIST_STATE = 51                   ; "On"/"Off"

; cheat editor window
CEDIT_X          = 4
CEDIT_Y          = 10
CEDIT_W          = 56
CEDIT_H          = 17
CEDIT_COL        = CEDIT_X + 2
CEDIT_TEXTW      = CEDIT_W - 4
CEDIT_VALUE      = CEDIT_COL + 9        ; column of name and enable state
CEDIT_HEAD       = CEDIT_Y + 3          ; table header, separator below
CEDIT_ROW0       = CEDIT_Y + 5          ; first code row
CEDIT_ROWS       = CEDIT_H - 6          ; code rows shown
CEDIT_NAME       = 0                    ; editor rows: name,
CEDIT_ENABLE     = 1                    ; enable state,
CEDIT_FIRST_CODE = 2                    ; codes and "Add code"
CEDIT_PATCH      = 11                   ; column of the patch in a code row

; code pad window
HEX_X            = 17
HEX_Y            = 10
HEX_W            = 30
HEX_H            = 16
HEX_COL          = HEX_X + 2
HEX_VALUE        = HEX_COL + 8          ; column of format and code
; first column and row of the 4x4 keys
HEX_KEYS_COL     = HEX_X + (HEX_W - 10) / 2
HEX_KEYS_ROW     = HEX_Y + 8
HEX_AS_CODE      = 5                    ; the code after "GG:  "/"PAR: "

; name keyboard window
KB_X             = 4
KB_Y             = 10
KB_W             = 56
KB_H             = 14
KB_COL           = KB_X + 2
KB_FIELDW        = KB_W - 4             ; visible part of the name
KB_COLS          = 13                   ; keys per row
KB_ROWS          = 6
KB_KEYS_W        = KB_COLS * 3 - 2      ; width of a row of keys (3 columns apart)
; first column and row of the keys
KB_KEYS_COL      = KB_X + (KB_W - KB_KEYS_W) / 2
KB_KEYS_ROW      = KB_Y + 4

; window rectangles for cheat_set_window: x, y, w, h
cheat_rect_alert:   .byte ALERT_X, ALERT_Y, ALERT_W, ALERT_H
cheat_rect_list:    .byte CHEAT_LIST_X, CHEAT_LIST_Y, CHEAT_LIST_W, CHEAT_LIST_H
cheat_rect_edit:    .byte CEDIT_X, CEDIT_Y, CEDIT_W, CEDIT_H
cheat_rect_hex:     .byte HEX_X, HEX_Y, HEX_W, HEX_H
cheat_rect_hexkeys: .byte HEX_KEYS_COL - 2, HEX_KEYS_ROW - 1, 14, 6 ; around the keys
cheat_rect_kb:      .byte KB_X, KB_Y, KB_W, KB_H
cheat_rect_kbkeys:  .byte KB_KEYS_COL - 2, KB_KEYS_ROW - 1, KB_KEYS_W + 4, KB_ROWS + 2
cheat_rects_end:
CHEAT_RECT_BANK  = cheat_rect_alert & $ff0000

  .cerror (`cheat_rect_alert) != (`cheat_rects_end - 1), "cheat_set_window expects all rectangles in one bank"

; cheat_action values, set by the options menus
CHEAT_ACT_NONE   = 0
CHEAT_ACT_EDIT   = 1
CHEAT_ACT_ADD    = 2
CHEAT_ACT_REMOVE = 3

  .cerror cheat_kb_keys_end - cheat_kb_keys != KB_COLS * KB_ROWS, "cheat_kb_keys does not match the keyboard size"
  .cerror CHEAT_LIST_TEXTW >= CHEAT_LINE_SIZE || CEDIT_TEXTW >= CHEAT_LINE_SIZE || HEX_W - 4 >= CHEAT_LINE_SIZE || KB_FIELDW >= CHEAT_LINE_SIZE || KB_KEYS_W >= CHEAT_LINE_SIZE, "a window line doesn't fit CheatWindow.line"

; entry points from the file context menus (menu functions: called via RTL
; with A 8-bit, X/Y 16-bit; the file is described by MCU_PARAM as for loading)
  .as
  .xl
cheat_menu_file:
  lda #CHEAT_SRC_BROWSER
  bra cheat_menu
cheat_menu_recent:
  lda #CHEAT_SRC_RECENT
  bra cheat_menu
cheat_menu_favorite:
  lda #CHEAT_SRC_FAVORITE
cheat_menu:
  php
  phb
  sep #$20
  .as
  rep #$10
  .xl
  tay                           ; CHEAT_SRC_*
  lda #$80
  pha
  plb
  stz cheat_msg_timer
  tya
  sta @l MCU_PARAM+8
  phy
  lda #CMD_LOAD_CHT
  ldx #<>text_loading
  jsr cheat_mcu_cmd
  ply
  lda @l CHEAT_STATUS
  beq +
  ldx #<>text_cheat_err_load
  ldy #<>space64+64             ; no window, no help text (empty string)
  jsr cheat_alert
  bra cheat_menu_out
+ tya
  .param pha
  .call cheat_list
  .unparam cheat_list
cheat_menu_out:
  jsr cheat_clear_statusbar
  jsr filesel_statusbar
  plb
  plp
  rtl

; ---------------------------------------------------------------------------
; cheat list

cheat_play_cmds:                ; command to launch the file, per CHEAT_SRC_*
  .byte CMD_LOADROM, CMD_LOADLAST, CMD_LOADFAVORITE

; params: p_src (CHEAT_SRC_* of the file)
cheat_list .block
  .virtual #0,d
Frame .block
  .dstruct CheatWindow           ; line, print_x/y/pal/count
  title         .fill CHEAT_LIST_W-5 ; window title
  num           .fill 6         ; a decimal number (bin2dec)
  rec           .long ?         ; a cheat record
  count         .word ?         ; number of cheats
  rom           .word ?         ; ROM patches used by the enabled cheats
  wram          .word ?         ; WRAM patches used by the enabled cheats
  c_rom         .word ?         ; ROM patches of one cheat (cheat_count_rec)
  c_wram        .word ?         ; WRAM patches of one cheat (cheat_count_rec)
  sel           .word ?         ; selected list row (count: "Add new cheat")
  top           .word ?         ; first list row shown
  idx           .word ?         ; cheat being edited
  tmp           .word ?
  new           .byte ?         ; cheat being edited is new
  dirty         .byte ?         ; cheats changed since they were loaded
  fmt           .byte ?         ; format of the last code entered
  _             .dstruct SaveJSR
  p_src         .byte ?
.endblock
  .endvirtual
  .cheat_window_check
  .enter
  rep #$30
  .al
  .xl
  lda @l NUM_CHEATS
  cmp #CHEAT_MAX_CHEATS+1
  bcc +
  lda #CHEAT_MAX_CHEATS
+ sta Frame.count
  stz Frame.sel
  stz Frame.top
  sep #$20
  .as
  stz Frame.dirty
  stz Frame.fmt
  jsr cheat_budget_scan
  jsr cheat_list_open
redraw:
  jsr cheat_list_draw
  ldx #<>text_cheat_help_list
  jsr cheat_statusbar
loop:
  sep #$20
  .as
  ldx #<>text_cheat_help_list
  jsr cheat_frame
  lda pad_up
  beq +
  jsr up
  bra loop
+ lda pad_down
  beq +
  jsr down
  bra loop
+ lda pad_left
  beq +
  jsr page_up
  bra loop
+ lda pad_right
  beq +
  jsr page_down
  bra loop
+ lda pad_l
  beq +
  jsr first
  bra loop
+ lda pad_r
  beq +
  jsr last
  bra loop
+ lda pad_a
  beq +
  jsr button_a
  bra done
+ lda pad_x
  beq +
  jsr button_x
  bra done
+ lda pad_y
  beq +
  jsr options
  bra done
+ lda pad_start
  beq +
  jsr play
  bra done
+ lda pad_b
  beq loop
  jsr cheat_save
  jsr pop_window
  .leave
  rts
done:                           ; c=1: redraw everything
  .jcs redraw
  brl loop

up:
  rep #$20
  .al
  lda Frame.sel
  beq moved
  dec Frame.sel
  bra moved
down:
  rep #$20
  .al
  lda Frame.sel
  cmp Frame.count
  bcs moved
  inc Frame.sel
  bra moved
page_up:
  rep #$20
  .al
  lda Frame.sel
  sec
  sbc #CHEAT_LIST_ROWS
  bcs +
  lda #$0000
+ sta Frame.sel
  lda Frame.top
  sec
  sbc #CHEAT_LIST_ROWS
  bcs +
  lda #$0000
+ sta Frame.top
  bra moved
page_down:
  rep #$20
  .al
  lda Frame.sel
  clc
  adc #CHEAT_LIST_ROWS
  cmp Frame.count
  bcc +
  lda Frame.count
+ sta Frame.sel
  lda Frame.top
  clc
  adc #CHEAT_LIST_ROWS
  sta Frame.top
  bra moved
first:
  rep #$20
  .al
  stz Frame.sel
  bra moved
last:
  rep #$20
  .al
  lda Frame.count
  sta Frame.sel
moved:
  sep #$20
  .as
  jsr cheat_list_follow
  jsr cheat_list_rows
  jmp cheat_list_bar

; the other handlers return c=1 to have everything redrawn
button_a:
  rep #$20
  .al
  lda Frame.sel
  cmp Frame.count
  sep #$20
  .as
  bcs add                       ; "Add new cheat"
  bra edit

button_x:
  rep #$20
  .al
  lda Frame.sel
  cmp Frame.count
  sep #$20
  .as
  bcs +                         ; "Add new cheat": nothing to toggle
  jsr cheat_toggle
+ clc
  rts

options:
  stz cheat_action
  rep #$20
  .al
  lda Frame.sel                 ; c=1: "Add new cheat", no cheat selected
  cmp Frame.count
  sep #$20
  .as
  lda #$00
  rol a
  sta cheat_nosel
  ldx #<>cheat_rect_list
  jsr cheat_greyout
  lda #20
  sta window_x
  lda #12
  sta window_y
  phb
  lda #`menu_enttab_cheat_options
  pha
  plb
  ldx #<>menu_enttab_cheat_options
  jsr show_menu
  plb
  jsr pop_window
  lda cheat_action
  cmp #CHEAT_ACT_ADD
  beq add
  rep #$20
  .al
  lda Frame.sel                 ; edit and remove need a cheat
  cmp Frame.count
  sep #$20
  .as
  bcs +
  lda cheat_action
  cmp #CHEAT_ACT_EDIT
  beq edit
  cmp #CHEAT_ACT_REMOVE
  beq remove
+ sec                           ; the settings in the menu may change the warnings
  rts

edit:
  rep #$20
  .al
  lda Frame.sel
  sta Frame.idx
  jsr cheat_fetch
  sep #$20
  .as
  stz Frame.new
  jsr cheat_edit
  sec
  rts

add:
  rep #$20
  .al
  lda Frame.count
  cmp #CHEAT_MAX_CHEATS
  sep #$20
  .as
  bcc +
  ldx #<>text_cheat_msg_full
  jsr cheat_message
  clc
  rts
+ jsr cheat_init_new
  jsr cheat_edit
  sec
  rts

remove:
  stz cheat_action
  ldx #<>cheat_rect_list
  jsr cheat_greyout
  lda #22
  sta window_x
  lda #14
  sta window_y
  phb
  lda #`menu_enttab_cheat_remove
  pha
  plb
  ldx #<>menu_enttab_cheat_remove
  jsr show_menu
  plb
  jsr pop_window
  lda cheat_action
  cmp #CHEAT_ACT_REMOVE
  bne +
  rep #$20
  .al
  lda Frame.sel
  jsr cheat_set_ptr
  sec
  jsr cheat_budget_update       ; its patches are free again
  lda Frame.sel
  jsr cheat_delete
  sep #$20
  .as
  lda #$01
  sta Frame.dirty
  jsr cheat_list_follow
+ sec
  rts

play:
  jsr cheat_save
  bcc +
  jsl wram_wait_mcu
  rep #$20
  .al
  lda Frame.p_src
  and #$00ff
  tax
  sep #$20
  .as
  jsr cheat_clear_statusbar
  lda @l cheat_play_cmds,x
  jsr game_handshake            ; only returns if the MCU can't load the file
+ sec
  rts

; helpers in the frame of cheat_list

; keep the selected list row visible
cheat_list_follow .block
  php
  rep #$20
  .al
  lda Frame.count               ; no empty rows after the last page
  sec
  sbc #CHEAT_LIST_ROWS-1
  bcs +
  lda #$0000
+ cmp Frame.top
  bcs +
  sta Frame.top
+ lda Frame.sel
  cmp Frame.top
  bcs below_top
  sta Frame.top                 ; selection above the rows shown
  bra out
below_top:
  sec
  sbc #CHEAT_LIST_ROWS-1
  bcc out
  cmp Frame.top
  bcc out
  sta Frame.top                 ; selection below the rows shown
out:
  plp
  rts
.endblock

cheat_list_bar:
  php
  sep #$20
  .as
  lda #CHEAT_LIST_COL
  sta bar_xl
  lda #CHEAT_LIST_TEXTW
  sta bar_wl
  lda Frame.sel
  sec
  sbc Frame.top
  clc
  adc #CHEAT_LIST_ROW0-1
  sta bar_yl
  plp
  rts

; open the cheat list window and print its fixed parts
cheat_list_open:
  php
  sep #$20
  .as
  rep #$10
  .xl
  ldx #$0000                    ; window title: "Cheats for <file name>"
- lda @l text_cheat,x
  beq +
  sta Frame.title,x
  inx
  bra -
+ ldy #<>CHEAT_ROMNAME          ; (Frame.rec points to the file name here)
  sty Frame.rec
  lda #`CHEAT_ROMNAME
  sta Frame.rec+2
  ldy #$0000
- lda [Frame.rec],y
  beq +
  sta Frame.title,x
  inx
  iny
  cpx #CHEAT_LIST_W-6           ; what fits between the title marks
  bcc -
+ stz Frame.title,x
  rep #$20
  .al
  tdc
  clc
  adc #Frame.title - Frame
  sta window_taddr
  sep #$20
  .as
  stz window_tbank              ; the stack is in bank 0
  ldx #<>cheat_rect_list
  jsr cheat_set_window
  jsr push_window
  jsr draw_window
  lda #CHEAT_LIST_HEAD+1
  jsr cheat_separator
  lda #CHEAT_LIST_FOOT
  jsr cheat_separator
  lda #CHEAT_LIST_COL
  sta Frame.print_x
  lda #CHEAT_LIST_HEAD
  sta Frame.print_y
  lda #CHEAT_LIST_TEXTW
  sta Frame.print_count
  lda #$03
  sta Frame.print_pal
  ldx #<>cheat_tab_head
  jsr cheat_print_rom
  plp
  rts

; redraw the variable parts of the cheat list
cheat_list_draw:
  jsr cheat_list_budget
  jsr cheat_list_rows
  jmp cheat_list_bar

; print the number of patches used and the warnings
cheat_list_budget .block
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda #CHEAT_LIST_FOOT+1
  sta Frame.print_y
  lda #20
  sta Frame.print_count
; "ROM patches: n/6"
  lda #CHEAT_LIST_COL
  sta Frame.print_x
  lda #20
  jsr cheat_line_clear
  ldx #$0000
  ldy #<>text_cheat_rom_patches
  jsr cheat_line_puts
  inx
  rep #$20
  .al
  lda Frame.rom
  jsr line_dec                  ; two digits, the last one at X
  sep #$20
  .as
  inx
  ldy #<>rom_max
  jsr cheat_line_puts
  stz Frame.print_pal
  rep #$20
  .al
  lda Frame.rom
  cmp #CHEAT_NUM_ROM_PATCHES+1
  sep #$20
  .as
  bcc +
  lda #$07
  sta Frame.print_pal
+ jsr cheat_print_line
; "WRAM patches: n/32"
  lda #CHEAT_LIST_COL+22
  sta Frame.print_x
  lda #20
  jsr cheat_line_clear
  ldx #$0000
  ldy #<>text_cheat_wram_patches
  jsr cheat_line_puts
  inx
  rep #$20
  .al
  lda Frame.wram
  jsr line_dec
  sep #$20
  .as
  inx
  ldy #<>wram_max
  jsr cheat_line_puts
  stz Frame.print_pal
  rep #$20
  .al
  lda Frame.wram
  cmp #CHEAT_NUM_WRAM_PATCHES+1
  sep #$20
  .as
  bcc +
  lda #$07
  sta Frame.print_pal
+ jsr cheat_print_line
; warnings
  lda #CHEAT_LIST_FOOT+2
  sta Frame.print_y
  lda #CHEAT_LIST_COL
  sta Frame.print_x
  lda #CHEAT_LIST_TEXTW
  sta Frame.print_count
  ldx #<>space64
  jsr cheat_print_rom
  lda #$07
  sta Frame.print_pal
  lda @l CFG_ENABLE_INGAME_HOOK
  bne +
  rep #$20
  .al
  lda Frame.wram
  sep #$20
  .as
  beq +
  ldx #<>text_cheat_warn_hook
  jsr cheat_print_rom
+ lda @l CFG_ENABLE_CHEATS
  bne +
  lda #CHEAT_LIST_COL+CHEAT_LIST_TEXTW-21
  sta Frame.print_x
  ldx #<>text_cheat_warn_start
  jsr cheat_print_rom
+ plp
  rts

rom_max:
  .text format("/%d", CHEAT_NUM_ROM_PATCHES), 0
wram_max:
  .text format("/%d", CHEAT_NUM_WRAM_PATCHES), 0
.endblock

; print all list rows
cheat_list_rows:
  php
  rep #$30
  .al
  .xl
  ldx #$0000
- phx
  txa
  clc
  adc #CHEAT_LIST_ROW0
  sep #$20
  .as
  sta Frame.print_y
  rep #$20
  .al
  txa
  clc
  adc Frame.top
  jsr cheat_list_row
  plx
  inx
  cpx #CHEAT_LIST_ROWS
  bcc -
  plp
  rts

; print a list row
; A (16-bit): cheat index (count: "Add new cheat", beyond: empty row)
; Frame.print_y: screen row
cheat_list_row .block
  php
  rep #$30
  .al
  .xl
  pha
  sep #$20
  .as
  lda #CHEAT_LIST_COL
  sta Frame.print_x
  lda #CHEAT_LIST_TEXTW
  sta Frame.print_count
  stz Frame.print_pal
  jsr cheat_line_clear
  rep #$20
  .al
  pla
  cmp Frame.count
  beq add_row
  bcs empty
  jsr cheat_set_ptr
  sep #$20
  .as
  ldy #CHEAT_REC_NAME           ; name
  ldx #$0000
- lda [Frame.rec],y
  beq +
  sta Frame.line,x
  iny
  inx
  cpx #CHEAT_LIST_NAMEW
  bcc -
+ ldy #CHEAT_REC_NUMCODES       ; number of codes
  lda [Frame.rec],y
  rep #$20
  .al
  and #$00ff
  ldx #CHEAT_LIST_CODES+1
  jsr line_dec
  sep #$20
  .as
  jsr cheat_print_line
; state
  lda #CHEAT_LIST_COL+CHEAT_LIST_STATE
  sta Frame.print_x
  lda #3
  sta Frame.print_count
  ldx #<>text_off
  lda #$06
  sta Frame.print_pal
  jsr cheat_is_enabled
  bcc +
  ldx #<>text_on
  lda #$02
  sta Frame.print_pal
+ jsr cheat_print_rom
  plp
  rts
add_row:
  sep #$20
  .as
  ldx #$0000
  ldy #<>text_cheat_add_row
  jsr cheat_line_puts
  lda #$02
  sta Frame.print_pal
empty:
  sep #$20
  .as
  jsr cheat_print_line
  plp
  rts
.endblock

; write A (16-bit) as decimal number right-aligned into Frame.line
; X: offset of the last digit in Frame.line (preserved)
line_dec:
  php
  rep #$30
  .al
  .xl
  phx
  tay
  sep #$20
  .as
  .param_dp Frame.num
  .param phy
  .call bin2dec                 ; 5 digits right-aligned
  .unparam bin2dec
  ply                           ; Y: offset in Frame.line
  phy
  ldx #$0004
- lda Frame.num,x
  cmp #' '
  beq +
  phx
  tyx
  sta Frame.line,x
  plx
  dey
  dex
  bpl -
+ plx
  plp
  rts

; enable/disable the selected cheat
cheat_toggle .block
  php
  rep #$30
  .al
  .xl
  lda Frame.sel
  jsr cheat_set_ptr
  jsr cheat_is_enabled
  bcc enable
  sec
  jsr cheat_budget_update       ; subtract its patches while still enabled
  sep #$20
  .as
  lda [Frame.rec]
  and #~CHEAT_FLAG_ENABLE
  sta [Frame.rec]
  bra changed
enable:
  jsr cheat_budget_fits
  bcs +
  jsr cheat_message
  plp
  rts
+ sep #$20
  .as
  lda [Frame.rec]
  ora #CHEAT_FLAG_ENABLE
  sta [Frame.rec]
  clc
  jsr cheat_budget_update
changed:
  sep #$20
  .as
  lda #$01
  sta Frame.dirty
  jsr cheat_list_budget
  jsr cheat_list_rows
  plp
  rts
.endblock

; write the cheats back if they were changed
; returns c=1 if done, c=0 on error (after telling the user)
cheat_save:
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda Frame.dirty
  beq +
  lda #CMD_SAVE_CHT
  ldx #<>text_saving
  jsr cheat_mcu_cmd
  lda @l CHEAT_STATUS
  bne cheat_save_error
  stz Frame.dirty
+ plp
  sec
  rts
cheat_save_error:
  ldx #<>text_cheat_err_save
  ldy #<>text_cheat_help_list
  jsr cheat_alert
  plp
  clc
  rts

; prepare a new cheat in CHEAT_EDIT_BUF: "New Cheat <n>", enabled, no codes
cheat_init_new .block
  php
  sep #$20
  .as
  rep #$10
  .xl
  rep #$20
  .al
  lda Frame.count
  sta Frame.idx
  sep #$20
  .as
  lda #$01
  sta Frame.new
  ldx #CHEAT_REC_SIZE-1
  lda #$00
- sta @l CHEAT_EDIT_BUF,x
  dex
  bpl -
  lda #CHEAT_FLAG_ENABLE
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_FLAGS
  .param_dp Frame.num           ; number, right-aligned
  rep #$20
  .al
  lda Frame.count
  inc a
  .param pha
  sep #$20
  .as
  .call bin2dec
  .unparam bin2dec
  ldx #$0000
  ldy #<>text_cheat_new_name
  jsr cheat_line_puts
  txy                           ; Y: offset in Frame.line
  ldx #$0000
skip_space:
  lda Frame.num,x
  cmp #' '
  bne copy
  inx
  bra skip_space
copy:
  lda Frame.num,x
  phx
  tyx
  sta Frame.line,x
  plx
  cmp #$00
  beq +
  inx
  iny
  bra copy
+ ldx #$0000
- lda Frame.line,x
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_NAME,x
  beq +
  inx
  bra -
+ plp
  rts
.endblock

; edit the cheat in CHEAT_EDIT_BUF (Frame.idx, Frame.new) and store it
cheat_edit .block
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda Frame.new
  bne +
  rep #$20
  .al
  lda Frame.idx
  jsr cheat_set_ptr
  sec
  jsr cheat_budget_update       ; its old patches don't count while editing
  sep #$20
  .as
+ ldx #<>cheat_rect_list
  jsr cheat_greyout
  .param_dp Frame.fmt
  .call cheat_editor
  .unparam cheat_editor
  php
  jsr pop_window
  plp
  bcs done
  lda Frame.new                 ; discarded: back to the old patches
  bne out
  rep #$20
  .al
  lda Frame.idx
  jsr cheat_set_ptr
  clc
  jsr cheat_budget_update
  bra out
done:
  sep #$20
  .as
  lda #$01
  sta Frame.dirty
  lda @l CHEAT_EDIT_BUF+CHEAT_REC_NUMCODES
  bne keep
  lda Frame.new                 ; no codes: no cheat
  bne out
  rep #$20
  .al
  lda Frame.idx
  jsr cheat_delete
  jsr cheat_list_follow
  bra out
keep:
  sep #$20
  .as
  jsr cheat_ptr_editbuf
  jsr cheat_is_enabled
  bcc +
  jsr cheat_budget_fits
  bcs +
  lda @l CHEAT_EDIT_BUF+CHEAT_REC_FLAGS ; too many patches: store it disabled
  and #~CHEAT_FLAG_ENABLE
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_FLAGS
  ldx #<>text_cheat_msg_off
  jsr cheat_message
+ clc
  jsr cheat_budget_update
  rep #$20
  .al
  lda Frame.new
  and #$00ff
  beq +
  inc Frame.count
  lda Frame.count
  sta @l NUM_CHEATS
+ lda Frame.idx
  sta Frame.sel
  jsr cheat_store
  sep #$20
  .as
  jsr cheat_list_follow
out:
  plp
  rts
.endblock

; point Frame.rec to cheat record A (16-bit)
cheat_set_ptr:
  php
  rep #$30
  .al
  .xl
  phx
  jsr cheat_rec_addr
  stx Frame.rec
  sep #$20
  .as
  sta Frame.rec+2
  plx
  plp
  rts

; point Frame.rec to the cheat being edited (CHEAT_EDIT_BUF)
cheat_ptr_editbuf:
  php
  rep #$20
  .al
  lda #<>CHEAT_EDIT_BUF
  sta Frame.rec
  sep #$20
  .as
  lda #`CHEAT_EDIT_BUF
  sta Frame.rec+2
  plp
  rts

; remove cheat record A (16-bit), move the following ones up
cheat_delete:
  php
  rep #$30
  .al
  .xl
  sta Frame.tmp
- lda Frame.tmp
  inc a
  cmp Frame.count
  bcs +
  lda Frame.tmp                 ; destination: this record
  jsr cheat_rec_addr
  sep #$20
  .as
  .param pha
  .param phx
  rep #$20
  .al
  lda Frame.tmp                 ; source: the next one
  inc a
  jsr cheat_rec_addr
  sep #$20
  .as
  .param pha
  .param phx
  .call cheat_copy_record
  .unparam cheat_copy_record
  rep #$20
  .al
  inc Frame.tmp
  bra -
+ dec Frame.count
  lda Frame.count
  sta @l NUM_CHEATS
  plp
  rts

; c=1 if the cheat record at Frame.rec is enabled
cheat_is_enabled:
  php
  sep #$20
  .as
  lda [Frame.rec]               ; CHEAT_REC_FLAGS
  asl a
  bcs +
  plp
  clc
  rts
+ plp
  sec
  rts

; count the patches of the cheat record at Frame.rec into Frame.c_rom and
; Frame.c_wram
cheat_count_rec:
  php
  sep #$20
  .as
  rep #$10
  .xl
  phx
  lda Frame.rec+2
  .param pha
  .param pei, Frame.rec
  .call cheat_count_patches
  .unparam cheat_count_patches
  stx Frame.c_rom
  sty Frame.c_wram
  plx
  plp
  rts

; add (c=0) or subtract (c=1) the patches of the cheat record at Frame.rec
; to/from the patches used, if it is enabled
cheat_budget_update:
  php
  rep #$20
  .al
  bcs cheat_budget_update_sub
  jsr cheat_is_enabled
  bcc +
  jsr cheat_count_rec
  lda Frame.rom
  clc
  adc Frame.c_rom
  sta Frame.rom
  lda Frame.wram
  clc
  adc Frame.c_wram
  sta Frame.wram
+ plp
  rts
cheat_budget_update_sub:
  jsr cheat_is_enabled
  bcc +
  jsr cheat_count_rec
  lda Frame.rom
  sec
  sbc Frame.c_rom
  sta Frame.rom
  lda Frame.wram
  sec
  sbc Frame.c_wram
  sta Frame.wram
+ plp
  rts

; check whether the patches of the cheat record at Frame.rec fit next to
; the patches already used
; returns c=1 if they fit, else c=0 and X = message
cheat_budget_fits:
  php
  rep #$30
  .al
  .xl
  jsr cheat_count_rec
  lda Frame.rom
  clc
  adc Frame.c_rom
  cmp #CHEAT_NUM_ROM_PATCHES+1
  bcc +
  ldx #<>text_cheat_msg_rom
  plp
  clc
  rts
+ lda Frame.wram
  clc
  adc Frame.c_wram
  cmp #CHEAT_NUM_WRAM_PATCHES+1
  bcc +
  ldx #<>text_cheat_msg_wram
  plp
  clc
  rts
+ plp
  sec
  rts

; count the patches of all enabled cheats
cheat_budget_scan:
  php
  rep #$30
  .al
  .xl
  stz Frame.rom
  stz Frame.wram
  stz Frame.tmp
- lda Frame.tmp
  cmp Frame.count
  bcs +
  jsr cheat_set_ptr
  clc
  jsr cheat_budget_update
  inc Frame.tmp
  bra -
+ plp
  rts

.endblock

; options menu functions (menu_enttab_cheat_*): remember the choice
; (called via RTL with A 8-bit, X/Y 16-bit)
  .as
  .xl
cheat_act_none:
  lda #CHEAT_ACT_NONE
  bra cheat_act_set
cheat_act_edit:
  lda #CHEAT_ACT_EDIT
  bra cheat_act_set
cheat_act_add:
  lda #CHEAT_ACT_ADD
  bra cheat_act_set
cheat_act_remove:
  lda #CHEAT_ACT_REMOVE
cheat_act_set:
  sta @l wram(cheat_action)
  rtl

; ---------------------------------------------------------------------------
; cheat editor

; the editor window for the cheat in CHEAT_EDIT_BUF
; params: p_fmt (long: format of the last code entered, see cheat_hexpad)
; returns c=1: done, c=0: discard the changes
cheat_editor .block
  .virtual #0,d
Frame .block
  .dstruct CheatWindow           ; line, print_x/y/pal/count
  code          .fill 4         ; a code (cheat_get_code)
  sel           .word ?         ; selected row
  top           .word ?         ; first code shown
  codes         .word ?         ; number of codes
  last          .word ?         ; last row
  codefmt       .byte ?         ; format of Frame.code
  _             .dstruct SaveJSR
  p_fmt         .long ?
.endblock
  .endvirtual
  .cheat_window_check
  .enter
  rep #$30
  .al
  .xl
  stz Frame.sel
  stz Frame.top
  sep #$20
  .as
  ldx #<>text_cheat_edit
  stx window_taddr
  lda #`text_cheat_edit
  sta window_tbank
  ldx #<>cheat_rect_edit
  jsr cheat_set_window
  jsr push_window
  jsr draw_window
  lda #CEDIT_HEAD+1
  jsr cheat_separator
  lda #CEDIT_COL
  sta Frame.print_x
  lda #CEDIT_TEXTW
  sta Frame.print_count
  stz Frame.print_pal
  lda #CEDIT_Y+1
  sta Frame.print_y
  ldx #<>text_cheat_name
  jsr cheat_print_rom
  inc Frame.print_y
  ldx #<>text_cheat_enabled
  jsr cheat_print_rom
  inc Frame.print_y
  lda #$03
  sta Frame.print_pal
  ldx #<>cheat_detail_head
  jsr cheat_print_rom
redraw:
  jsr cheat_editor_draw
  ldx #<>text_cheat_help_edit
  jsr cheat_statusbar
loop:
  sep #$20
  .as
  ldx #<>text_cheat_help_edit
  jsr cheat_frame
  lda pad_up
  beq +
  rep #$20
  .al
  lda Frame.sel
  beq loop
  dec Frame.sel
  bra moved
+ lda pad_down
  beq +
  rep #$20
  .al
  lda Frame.sel
  cmp Frame.last
  bcs loop
  inc Frame.sel
  bra moved
+ lda pad_a
  beq +
  jsr button_a
  bra redraw
+ lda pad_y
  beq +
  jsr options
  bra redraw
+ lda pad_b
  beq +
  jsr pop_window                ; discard the changes
  .leave
  clc
  rts
  .as
+ lda pad_start
  beq loop
  jsr pop_window                ; done
  .leave
  sec
  rts
moved:
  sep #$20
  .as
  jsr cheat_editor_follow
  jsr cheat_editor_codes
  jsr cheat_editor_bar
  bra loop

button_a:
  rep #$20
  .al
  lda Frame.sel
  cmp #CEDIT_NAME
  bne +
  ldx #<>cheat_rect_edit
  jsr cheat_greyout
  jsr cheat_keyboard
  jmp pop_window
+ cmp #CEDIT_ENABLE
  bne +
  sep #$20
  .as
  lda @l CHEAT_EDIT_BUF+CHEAT_REC_FLAGS
  eor #CHEAT_FLAG_ENABLE
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_FLAGS
  rts
+ .al
  sec
  sbc #CEDIT_FIRST_CODE         ; code (or "Add code")
  jmp open_hexpad

options:
  sep #$20
  .as
  stz cheat_action
  rep #$20
  .al
  lda Frame.sel                 ; c=1: no code selected
  sec
  sbc #CEDIT_FIRST_CODE
  cmp Frame.codes
  sep #$20
  .as
  lda #$00
  rol a
  sta cheat_nosel
  ldx #<>cheat_rect_edit
  jsr cheat_greyout
  lda #22
  sta window_x
  lda #14
  sta window_y
  phb
  lda #`menu_enttab_cheat_code
  pha
  plb
  ldx #<>menu_enttab_cheat_code
  jsr show_menu
  plb
  jsr pop_window
  lda cheat_action
  cmp #CHEAT_ACT_ADD
  beq add
  lda cheat_nosel               ; edit and remove need a code
  bne +
  lda cheat_action
  cmp #CHEAT_ACT_EDIT
  beq button_a
  cmp #CHEAT_ACT_REMOVE
  beq remove
+ rts
add:
  rep #$20
  .al
  lda Frame.codes
  cmp #CHEAT_NUM_CODES
  bcs +
  jmp open_hexpad
+ sep #$20
  .as
  ldx #<>text_cheat_msg_codes
  jmp cheat_message
remove:
  rep #$20
  .al
  lda Frame.sel
  sec
  sbc #CEDIT_FIRST_CODE
  jmp cheat_code_remove

; helpers in the frame of cheat_editor

; open the code pad for code A (16-bit; the number of codes for a new one)
open_hexpad:
  php
  rep #$30
  .al
  .xl
  pha                           ; code
  ldx #<>cheat_rect_edit
  jsr cheat_greyout
  ply
  sep #$20
  .as
  lda Frame.p_fmt+2
  .param pha
  .param pei, Frame.p_fmt
  .param phy
  .call cheat_hexpad
  .unparam cheat_hexpad
  jsr pop_window
  plp
  rts

; keep the selected code visible
cheat_editor_follow .block
  php
  rep #$20
  .al
  lda Frame.sel
  sec
  sbc #CEDIT_FIRST_CODE
  bcc out                       ; name or enable state
  cmp Frame.top
  bcs +
  sta Frame.top
  bra out
+ sbc #CEDIT_ROWS-1             ; (carry is set)
  bcc out
  cmp Frame.top
  bcc out
  sta Frame.top
out:
  plp
  rts
.endblock

cheat_editor_bar .block
  php
  sep #$20
  .as
  lda #CEDIT_COL
  sta bar_xl
  lda #CEDIT_TEXTW
  sta bar_wl
  lda Frame.sel
  cmp #CEDIT_FIRST_CODE
  bcs +
  clc
  adc #CEDIT_Y                  ; row - 1 of name and enable state
  bra set
+ sec
  sbc Frame.top
  clc
  adc #CEDIT_ROW0-1-CEDIT_FIRST_CODE
set:
  sta bar_yl
  plp
  rts
.endblock

; print everything that can change in the editor
cheat_editor_draw:
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda #CEDIT_VALUE              ; name
  sta Frame.print_x
  lda #CEDIT_Y+1
  sta Frame.print_y
  lda #CEDIT_TEXTW-9
  sta Frame.print_count
  jsr cheat_line_clear
  ldx #$0000
- lda @l CHEAT_EDIT_BUF+CHEAT_REC_NAME,x
  beq +
  sta Frame.line,x
  inx
  cpx #CEDIT_TEXTW-9
  bcc -
+ lda #$01
  sta Frame.print_pal
  jsr cheat_print_line
  inc Frame.print_y             ; enable state
  lda #3
  sta Frame.print_count
  ldx #<>space64
  jsr cheat_print_rom
  ldx #<>text_no
  lda @l CHEAT_EDIT_BUF+CHEAT_REC_FLAGS
  bpl +
  ldx #<>text_yes
+ jsr cheat_print_rom
  jsr cheat_editor_codes
  jsr cheat_editor_bar
  plp
  rts

; print the code rows
cheat_editor_codes .block
  php
  rep #$30
  .al
  .xl
  lda @l CHEAT_EDIT_BUF+CHEAT_REC_NUMCODES
  and #$00ff
  sta Frame.codes
  clc
  adc #CEDIT_FIRST_CODE         ; last row: "Add code"
  cmp #CEDIT_FIRST_CODE+CHEAT_NUM_CODES
  bcc +
  dec a                         ; or the last code if there is no more room
+ sta Frame.last
  cmp Frame.sel
  bcs +
  sta Frame.sel
+ jsr cheat_editor_follow
  ldx #$0000
next_row:
  phx
  txa
  clc
  adc #CEDIT_ROW0
  sep #$20
  .as
  sta Frame.print_y
  lda #CEDIT_COL
  sta Frame.print_x
  lda #CEDIT_TEXTW
  sta Frame.print_count
  stz Frame.print_pal
  jsr cheat_line_clear
  rep #$20
  .al
  txa
  clc
  adc Frame.top
  cmp Frame.codes
  beq add_row
  bcs print
  jsr cheat_get_code            ; code row
  stx Frame.code
  sty Frame.code+2
  sep #$20
  .as
  sta Frame.codefmt
  .param_dp Frame.line
  .param pei, Frame.code+2
  .param pei, Frame.code
  lda Frame.codefmt
  .param pha
  .call cheat_code_text
  .unparam cheat_code_text
  .param_dp Frame.line+CEDIT_PATCH
  .param pei, Frame.code+2
  .param pei, Frame.code
  .call cheat_patch_text
  .unparam cheat_patch_text
  bra print
add_row:
  .al
  cmp #CHEAT_NUM_CODES
  bcs print
  sep #$20
  .as
  ldx #$0000
  ldy #<>text_cheat_add_code_row
  jsr cheat_line_puts
  lda #$02
  sta Frame.print_pal
print:
  jsr cheat_print_line
  rep #$30
  .al
  .xl
  plx
  inx
  cpx #CEDIT_ROWS
  .jcc next_row
  plp
  rts
.endblock

.endblock

; get code A (16-bit) of CHEAT_EDIT_BUF
; returns X: bytes 0 and 1 (value, address low), Y: bytes 2 and 3 (address
; high, bank), the low byte of A: its format (CHEAT_CODEFMT_*)
cheat_get_code:
  php
  rep #$30
  .al
  .xl
  pha
  asl a
  asl a
  tax
  lda @l CHEAT_EDIT_BUF+CHEAT_REC_CODES+2,x
  tay
  lda @l CHEAT_EDIT_BUF+CHEAT_REC_CODES,x
  plx
  pha
  sep #$20
  .as
  lda @l CHEAT_EDIT_BUF+CHEAT_REC_CODEFMT,x
  plx
  plp
  rts

; remove code A (16-bit) from CHEAT_EDIT_BUF
cheat_code_remove .block
  php
  rep #$30
  .al
  .xl
  pha
  asl a
  asl a
  tax
- lda @l CHEAT_EDIT_BUF+CHEAT_REC_CODES+4,x
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_CODES,x
  lda @l CHEAT_EDIT_BUF+CHEAT_REC_CODES+6,x
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_CODES+2,x
  inx
  inx
  inx
  inx
  cpx #(CHEAT_NUM_CODES-1)*4
  bcc -
  plx
  sep #$20
  .as
- lda @l CHEAT_EDIT_BUF+CHEAT_REC_CODEFMT+1,x
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_CODEFMT,x
  inx
  cpx #CHEAT_NUM_CODES-1
  bcc -
  lda @l CHEAT_EDIT_BUF+CHEAT_REC_NUMCODES
  dec a
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_NUMCODES
  plp
  rts
.endblock

; ---------------------------------------------------------------------------
; code pad: enter a code with a 4x4 matrix of hex digits

; edit a code of the cheat in CHEAT_EDIT_BUF
; params (push order): p_fmt (long: format of the last code entered: new
; codes start in it, it is set when a code is stored), p_idx (code to edit,
; the number of codes for a new one)
; returns c=1 if the code was stored
cheat_hexpad .block
  .virtual #0,d
Frame .block
  .dstruct CheatWindow           ; line, print_x/y/pal/count
  digits        .fill 8         ; digits entered, $ff = empty
  code          .fill 4         ; the code of the digits
  pos           .word ?         ; cursor
  row           .byte ?         ; selected key
  col           .byte ?
  fmt           .byte ?         ; format of the code
  tmp           .byte ?
  _             .dstruct SaveJSR
  p_idx         .word ?         ; pushed last
  p_fmt         .long ?         ; pushed first
.endblock
  .endvirtual
  .cheat_window_check
  .enter
  rep #$30
  .al
  .xl
  stz Frame.pos
  sep #$20
  .as
  stz Frame.row
  stz Frame.col
  lda Frame.p_idx
  cmp @l CHEAT_EDIT_BUF+CHEAT_REC_NUMCODES
  bcc existing
  lda [Frame.p_fmt]             ; new code: empty, format of the last one
  sta Frame.fmt
  ldx #$0007
  lda #$ff
- sta Frame.digits,x
  dex
  bpl -
  bra open
existing:
  rep #$20
  .al
  lda Frame.p_idx
  jsr cheat_get_code
  stx Frame.code
  sty Frame.code+2
  sep #$20
  .as
  sta Frame.fmt
  jsr cheat_hexpad_from_code
open:
  ldx #<>text_cheat_hex_title
  stx window_taddr
  lda #`text_cheat_hex_title
  sta window_tbank
  ldx #<>cheat_rect_hex
  jsr cheat_set_window
  jsr push_window
  jsr draw_window
  stz Frame.print_pal
  lda #HEX_COL
  sta Frame.print_x
  lda #HEX_W-4
  sta Frame.print_count
  lda #HEX_Y+1
  sta Frame.print_y
  ldx #<>text_cheat_format
  jsr cheat_print_rom
  lda #HEX_Y+3
  sta Frame.print_y
  ldx #<>text_cheat_code
  jsr cheat_print_rom
  lda #HEX_Y+13
  sta Frame.print_y
  ldx #<>text_cheat_hex_help
  jsr cheat_print_rom
  inc Frame.print_y
  ldx #<>text_cheat_hex_help2
  jsr cheat_print_rom
  ldx #<>cheat_rect_hexkeys     ; keys
  jsr cheat_box
  lda #HEX_KEYS_COL
  sta Frame.print_x
  lda #HEX_KEYS_ROW
  sta Frame.print_y
  lda #$00
- pha
  lda #10
  jsr cheat_line_clear
  pla
  ldx #$0000
- pha
  jsr cheat_nib2asc
  sta Frame.line,x
  pla
  inx
  inx
  inx
  inc a
  bit #$03
  bne -
  pha
  jsr cheat_print_line
  inc Frame.print_y
  pla
  cmp #$10
  bcc --
redraw:
  jsr cheat_hexpad_draw
  ldx #<>text_cheat_help_entry
  jsr cheat_statusbar
loop:
  sep #$20
  .as
  ldx #<>text_cheat_help_entry
  jsr cheat_frame
  lda pad_up
  beq +
  dec Frame.row
  brl key_moved
+ lda pad_down
  beq +
  inc Frame.row
  brl key_moved
+ lda pad_left
  beq +
  dec Frame.col
  brl key_moved
+ lda pad_right
  beq +
  inc Frame.col
  brl key_moved
+ lda pad_a
  beq +
  lda Frame.row                 ; enter the digit
  asl a
  asl a
  ora Frame.col
  ldx Frame.pos
  sta Frame.digits,x
  bra cursor_right
+ lda pad_x
  beq +
  ldx Frame.pos                 ; delete the digit at or before the cursor
  lda Frame.digits,x
  bpl clear
  txa
  beq redraw
  dex
  stx Frame.pos
clear:
  lda #$ff
  sta Frame.digits,x
  bra redraw
+ lda pad_l
  beq +
  lda Frame.pos
  beq loop
  dec Frame.pos
  bra redraw
+ lda pad_r
  beq +
cursor_right:
  lda Frame.pos
  cmp #$07
  .jcs redraw
  inc Frame.pos
  brl redraw
+ lda pad_select
  beq +
  jsr cheat_hexpad_complete
  bcc toggle
  jsr cheat_hexpad_to_code      ; convert the digits to the other format
  lda Frame.fmt
  eor #CHEAT_CODEFMT_GG
  sta Frame.fmt
  jsr cheat_hexpad_from_code
  brl redraw
toggle:
  lda Frame.fmt
  eor #CHEAT_CODEFMT_GG
  sta Frame.fmt
  brl redraw
+ lda pad_b
  beq +
  jsr pop_window                ; cancelled
  .leave
  clc
  rts
  .as
+ lda pad_start
  beq loop2
  jsr cheat_hexpad_complete
  bcs store
  ldx #<>text_cheat_msg_digits
  jsr cheat_message
loop2:
  jmp loop
key_moved:
  lda Frame.row
  and #$03
  sta Frame.row
  lda Frame.col
  and #$03
  sta Frame.col
  jsr cheat_hexpad_bar
  jmp loop
store:
  jsr cheat_hexpad_to_code
  rep #$30
  .al
  .xl
  lda Frame.p_idx
  asl a
  asl a
  tax
  lda Frame.code
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_CODES,x
  lda Frame.code+2
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_CODES+2,x
  ldx Frame.p_idx
  sep #$20
  .as
  lda Frame.fmt
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_CODEFMT,x
  sta [Frame.p_fmt]
  txa
  cmp @l CHEAT_EDIT_BUF+CHEAT_REC_NUMCODES
  bcc +
  inc a                         ; a new code
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_NUMCODES
+ jsr pop_window
  .leave
  sec
  rts

; helpers in the frame of cheat_hexpad

; c=1 if all digits of the code pad are entered
cheat_hexpad_complete:
  php
  sep #$30
  .as
  .xs
  ldx #7
- lda Frame.digits,x
  bmi +
  dex
  bpl -
  plp
  sec
  rts
+ plp
  clc
  rts

; Frame.digits (complete) -> Frame.code
cheat_hexpad_to_code:
  php
  sep #$20
  .as
  rep #$10
  .xl
  .param_dp Frame.digits
  lda Frame.fmt
  .param pha
  .call cheat_digits_code
  .unparam cheat_digits_code
  stx Frame.code
  sty Frame.code+2
  plp
  rts

; Frame.code -> Frame.digits, in the format Frame.fmt
cheat_hexpad_from_code:
  php
  sep #$20
  .as
  rep #$10
  .xl
  .param_dp Frame.digits
  .param pei, Frame.code+2
  .param pei, Frame.code
  lda Frame.fmt
  .param pha
  .call cheat_code_digits
  .unparam cheat_code_digits
  plp
  rts

cheat_hexpad_bar:
  php
  sep #$20
  .as
  lda Frame.col
  sta Frame.tmp
  asl a
  clc
  adc Frame.tmp
  adc #HEX_KEYS_COL
  sta bar_xl
  lda #1
  sta bar_wl
  lda Frame.row
  clc
  adc #HEX_KEYS_ROW-1
  sta bar_yl
  plp
  rts

; print format, code, cursor and what the code does
cheat_hexpad_draw .block
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda #HEX_VALUE                ; format
  sta Frame.print_x
  lda #HEX_Y+1
  sta Frame.print_y
  lda #10
  sta Frame.print_count
  lda #$01
  sta Frame.print_pal
  ldx #<>text_cheat_fmt_par
  lda Frame.fmt
  beq +
  ldx #<>text_cheat_fmt_gg
+ jsr cheat_print_rom
  lda #10                       ; code, "_" for missing digits
  jsr cheat_line_clear
  ldx #$0007
- lda Frame.digits,x
  bmi empty
  jsr cheat_nib2asc
  bra +
empty:
  lda #'_'
+ sta Frame.line,x
  dex
  bpl -
  lda Frame.fmt                 ; Game Genie: with a dash in the middle
  beq +
  ldx #$0003
- lda Frame.line+4,x
  sta Frame.line+5,x
  dex
  bpl -
  lda #'-'
  sta Frame.line+4
+ lda #HEX_Y+3
  sta Frame.print_y
  jsr cheat_print_line
  lda #10                       ; cursor
  jsr cheat_line_clear
  inc Frame.print_y
  stz Frame.print_pal
  jsr cheat_print_line
  lda Frame.fmt
  cmp #CHEAT_CODEFMT_GG         ; c=1: GG code
  lda Frame.pos
  bcc +
  cmp #$04
  bcc +
  inc a                         ; skip the dash
+ clc
  adc #HEX_VALUE
  sta Frame.print_x
  lda #$07
  sta Frame.print_pal
  ldx #<>text_cheat_caret
  jsr cheat_print_rom
  lda #HEX_COL                  ; what the code does
  sta Frame.print_x
  lda #HEX_W-4
  sta Frame.print_count
  stz Frame.print_pal
  lda #HEX_W-4
  jsr cheat_line_clear
  inc Frame.print_y
  jsr cheat_hexpad_complete
  bcc +
  jsr cheat_hexpad_to_code
  .param_dp Frame.line
  .param pei, Frame.code+2
  .param pei, Frame.code
  .call cheat_patch_text
  .unparam cheat_patch_text
+ jsr cheat_print_line
  lda #HEX_W-4                  ; the code in the other format
  jsr cheat_line_clear
  inc Frame.print_y
  jsr cheat_hexpad_complete
  bcc +
  ldx #$0000
  ldy #<>text_cheat_as_gg
  lda Frame.fmt
  beq as_gg
  ldy #<>text_cheat_as_par
as_gg:
  jsr cheat_line_puts
  .param_dp Frame.line+HEX_AS_CODE
  .param pei, Frame.code+2
  .param pei, Frame.code
  lda Frame.fmt
  eor #CHEAT_CODEFMT_GG
  .param pha
  .call cheat_code_text
  .unparam cheat_code_text
+ jsr cheat_print_line
  jsr cheat_hexpad_bar
  plp
  rts
.endblock

.endblock

; ---------------------------------------------------------------------------
; name keyboard: edit the name of the cheat in CHEAT_EDIT_BUF

kb_row_offsets:                 ; first key of each row in cheat_kb_keys
  .byte 0, 13, 26, 39, 52, 65

cheat_keyboard .block
  .virtual #0,d
Frame .block
  .dstruct CheatWindow           ; line, print_x/y/pal/count
  len           .word ?         ; length of the name
  cur           .word ?         ; cursor position in the name
  scroll        .word ?         ; first character of the name shown
  row           .byte ?         ; selected key
  col           .byte ?
  tmp           .byte ?
  _             .dstruct SaveJSR
.endblock
  .endvirtual
  .cheat_window_check
  .enter
  sep #$20
  .as
  rep #$10
  .xl
  ldx #$0000                    ; work on a copy of the name
- lda @l CHEAT_EDIT_BUF+CHEAT_REC_NAME,x
  sta @l CHEAT_NAME_BUF,x
  beq +
  inx
  cpx #CHEAT_NAME_MAXLEN
  bcc -
  lda #$00
  sta @l CHEAT_NAME_BUF,x
+ stx Frame.len
  stx Frame.cur
  ldx #$0000
  stx Frame.scroll
  stz Frame.row
  stz Frame.col
  ldx #<>text_cheat_kb_title
  stx window_taddr
  lda #`text_cheat_kb_title
  sta window_tbank
  ldx #<>cheat_rect_kb
  jsr cheat_set_window
  jsr push_window
  jsr draw_window
  stz Frame.print_pal
  lda #KB_COL
  sta Frame.print_x
  lda #KB_Y+12
  sta Frame.print_y
  lda #KB_FIELDW
  sta Frame.print_count
  ldx #<>text_cheat_kb_help
  jsr cheat_print_rom
  ldx #<>cheat_rect_kbkeys      ; keys
  jsr cheat_box
  lda #KB_KEYS_COL
  sta Frame.print_x
  lda #KB_KEYS_ROW
  sta Frame.print_y
  ldx #$0000                    ; X: key
- lda #KB_KEYS_W                ; (no spaces after the last key: frame)
  jsr cheat_line_clear
  ldy #$0000                    ; Y: position in the line
- lda @l cheat_kb_keys,x
  phx
  tyx
  sta Frame.line,x
  plx
  iny
  iny
  iny
  inx
  cpy #KB_COLS*3
  bcc -
  jsr cheat_print_line
  inc Frame.print_y
  cpx #KB_COLS*KB_ROWS
  bcc --
redraw:
  jsr cheat_keyboard_draw
  ldx #<>text_cheat_help_entry
  jsr cheat_statusbar
loop:
  sep #$20
  .as
  ldx #<>text_cheat_help_entry
  jsr cheat_frame
  lda pad_up
  beq +
  lda Frame.row
  bne up
  lda #KB_ROWS
up:
  dec a
  sta Frame.row
  bra key_moved
+ lda pad_down
  beq +
  lda Frame.row
  inc a
  cmp #KB_ROWS
  bcc down
  lda #$00
down:
  sta Frame.row
  bra key_moved
+ lda pad_left
  beq +
  lda Frame.col
  bne left
  lda #KB_COLS
left:
  dec a
  sta Frame.col
  bra key_moved
+ lda pad_right
  beq +
  lda Frame.col
  inc a
  cmp #KB_COLS
  bcc right
  lda #$00
right:
  sta Frame.col
key_moved:
  jsr cheat_keyboard_bar
  bra loop
+ lda pad_a
  beq +
  rep #$20
  .al
  lda Frame.row
  and #$00ff
  tax
  sep #$20
  .as
  lda @l kb_row_offsets,x
  clc
  adc Frame.col
  rep #$20
  .al
  and #$00ff
  tax
  sep #$20
  .as
  lda @l cheat_kb_keys,x
  jsr insert
  brl redraw
+ lda pad_y
  beq +
  lda #' '
  jsr insert
  brl redraw
+ lda pad_x
  beq +
  jsr delete
  brl redraw
+ lda pad_select
  beq +
  lda #$00                      ; clear the name
  sta @l CHEAT_NAME_BUF
  ldx #$0000
  stx Frame.len
  stx Frame.cur
  stx Frame.scroll
  brl redraw
+ lda pad_l
  beq +
  ldx Frame.cur
  .jeq loop
  dex
  stx Frame.cur
  brl redraw
+ lda pad_r
  beq +
  ldx Frame.cur
  cpx Frame.len
  bcs loop2
  inx
  stx Frame.cur
  brl redraw
+ lda pad_b
  beq +
  jsr pop_window
  .leave
  rts
+ lda pad_start
  beq loop2
  ldx #$0000                    ; take the new name
- lda @l CHEAT_NAME_BUF,x
  sta @l CHEAT_EDIT_BUF+CHEAT_REC_NAME,x
  beq +
  inx
  bra -
+ jsr pop_window
  .leave
  rts
loop2:
  jmp loop

; helpers in the frame of cheat_keyboard

; insert character A at the cursor
insert:
  .as
  ldx Frame.len
  cpx #CHEAT_NAME_MAXLEN
  bcc +
  ldx #<>text_cheat_msg_namefull
  jmp cheat_message
+ pha
- lda @l CHEAT_NAME_BUF,x       ; move the rest (with the NUL) to the right
  sta @l CHEAT_NAME_BUF+1,x
  cpx Frame.cur
  beq +
  dex
  bra -
+ pla
  sta @l CHEAT_NAME_BUF,x
  inx
  stx Frame.cur
  ldx Frame.len
  inx
  stx Frame.len
  rts

; delete the character before the cursor
delete:
  .as
  ldx Frame.cur
  beq +
  dex
  stx Frame.cur
- lda @l CHEAT_NAME_BUF+1,x     ; move the rest (with the NUL) to the left
  sta @l CHEAT_NAME_BUF,x
  beq ++
  inx
  bra -
+ rts
+ ldx Frame.len
  dex
  stx Frame.len
  rts

cheat_keyboard_bar:
  php
  sep #$20
  .as
  lda Frame.col
  sta Frame.tmp
  asl a
  clc
  adc Frame.tmp
  adc #KB_KEYS_COL
  sta bar_xl
  lda #1
  sta bar_wl
  lda Frame.row
  clc
  adc #KB_KEYS_ROW-1
  sta bar_yl
  plp
  rts

; print the visible part of the name and the cursor
cheat_keyboard_draw .block
  php
  rep #$30
  .al
  .xl
  lda Frame.cur                 ; scroll the name to the cursor
  cmp Frame.scroll
  bcs +
  sta Frame.scroll
+ sec
  sbc #KB_FIELDW-1
  bcc +
  cmp Frame.scroll
  bcc +
  sta Frame.scroll
+ sep #$20
  .as
  lda #KB_FIELDW
  jsr cheat_line_clear
  ldx Frame.scroll
  ldy #$0000
- lda @l CHEAT_NAME_BUF,x
  beq +
  phx
  tyx
  sta Frame.line,x
  plx
  inx
  iny
  cpy #KB_FIELDW
  bcc -
+ lda #KB_COL
  sta Frame.print_x
  lda #KB_Y+1
  sta Frame.print_y
  lda #KB_FIELDW
  sta Frame.print_count
  lda #$01
  sta Frame.print_pal
  jsr cheat_print_line
  lda #KB_FIELDW                ; cursor
  jsr cheat_line_clear
  inc Frame.print_y
  jsr cheat_print_line
  lda Frame.cur
  sec
  sbc Frame.scroll
  clc
  adc #KB_COL
  sta Frame.print_x
  lda #$07
  sta Frame.print_pal
  ldx #<>text_cheat_caret
  jsr cheat_print_rom
  jsr cheat_keyboard_bar
  plp
  rts
.endblock

.endblock

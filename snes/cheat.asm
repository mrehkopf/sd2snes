; Cheat editor: show, enable, add, edit and remove the cheats of a file
;
; CMD_LOAD_CHT has the MCU read the cheat file of the selected file into the
; cheat area (NUM_CHEATS, CHEAT_ADDR, records as described by CHEAT_REC_* in
; memmap.inc), CMD_SAVE_CHT writes it back. The menu mapper lets the SNES
; write the cheat area, so the records are edited in place.
;
; The routines keep their state in their stack frames and work with any D.
; Global are the status bar message timer (cheat_msg_timer), as the status
; bar is shared by all windows, and the copy of the cheat being edited in
; CHEAT_EDIT_BUF (cheat_fetch, cheat_store).
;
; All routines expect DB=$80, as set up by cheat_menu.

; message box
ALERT_X          = 12
ALERT_Y          = 15
ALERT_W          = 40
ALERT_H          = 6

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

; show a message box and wait for A or B
; X: message (bank of text_cheat)
; Y: help text of the current window (see cheat_frame)
cheat_alert .block
  .virtual #0,d
Frame .block
  help          .word ?
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
  lda #ALERT_X
  sta window_x
  lda #ALERT_Y
  sta window_y
  lda #ALERT_W
  sta window_w
  lda #ALERT_H
  sta window_h
  ldx #<>space64+64             ; no title (empty string)
  stx window_taddr
  lda #`space64
  sta window_tbank
  jsr push_window
  jsr draw_window
  jsr hide_cursor
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
  .print_at text_cheat_press_a, ALERT_X+2, ALERT_Y+3, 0, ALERT_W-4
- ldx Frame.help
  jsr cheat_frame
  lda pad_a
  ora pad_b
  beq -
  jsr pop_window
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

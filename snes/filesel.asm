filesel_init:
  sep #$20
  .as
  rep #$10
  .xl
  lda #`ROOT_DIR
  ldx #<>ROOT_DIR
  sta dirptr_bank
  stx dirptr_addr
  sta dirstart_bank
  stx dirstart_addr
  stz filesel_state
  stz dirend_onscreen
  lda #$02
  sta cursor_x
  lda #$09
  sta cursor_y
  lda #$01
  sta bar_xl
  lda #$3e
  sta bar_wl
  ldx #$0000
  stx dirptr_idx
  stx filesel_sel
  stx direntry_xscroll
  stx direntry_xscroll_state
  lda #$01
  sta filesel_dirty
  rep #$20
  .al
  lda #dirlog
  sta dirlog_idx
  sep #$20
  .as
  lda #`wram(dirlog)
  sta dirlog_idx+2
  lda #$2f ; '/'
  sta @l FILESEL_CWD
  lda #$00 ; '\0'
  sta @l FILESEL_CWD+1
  jsr filesel_request_filelist
  rts

fileselloop:
  sep #$20
  .as
  rep #$10
  .xl
  lda isr_done
  lsr
  bcc fileselloop
  stz isr_done
  jsr printtime
  jsr filesel_updates ; update stuff, check keys etc
  lda filesel_dirty   ; is there ANY reason to redraw the menu?
  cmp #$01
  beq fileselloop_redraw ; then do
  jsr scroll_direntry
  bra fileselloop
fileselloop_redraw:
  stz filesel_dirty
  jsr filesel_statusbar
  jsr filesel_redraw
  jsr filesel_cleanup ; update phase 2
  bra fileselloop
  rts

filesel_cleanup:
  sep #$20
  .as
  rep #$10
  .xl
  lda dirend_onscreen ; end of file list on screen?
  beq filesel_cleanup_out
  lda dirend_idx
  lsr
  lsr
  pha
filesel_cleanup_loop: ; pad rest of screen with empty lines
  cmp listdisp        ; end of screen reached?
  beq +               ; then leave
  pha
  clc
  adc #$09            ; first line in text area
  inc a
  rep #$20
  .al
  and #$00ff
  tay
  sep #$20
  .as
  lda #`space64
  .param pha
  .param pea, <>space64
  lda #$00
  .param pha
  tya
  .param pha
  lda #$00
  .param pha
  lda #64
  .param pha
  .call print_text
  .unparam print_text
  pla
  inc a
  bra filesel_cleanup_loop
+
  pla
  cmp filesel_sel
  beq filesel_cleanup_out
  bpl filesel_cleanup_out
  sta filesel_sel
filesel_cleanup_out:
  rts

filesel_updates:
; update selection, scroll etc
  lda filesel_sel
  asl
  asl
  sta dirptr_idx
  lda filesel_sel
  clc
  adc #$08
  sta bar_yl
  lda #$3e
  sta bar_wl
  lda #$01
  sta bar_xl
; get input
  jsr read_pad
  lda pad_down
  bne key_down
  lda pad_up
  bne key_up
  lda pad_right
  bne key_right
  lda pad_left
  bne key_left
  lda pad_b
  bne key_b
  lda pad_start
  bne key_start
  lda pad_select
  bne key_select
  lda pad_a
  bne key_a
  lda pad_x
  bne key_x
  lda pad_y
  bne key_y
  lda pad_l
  bne key_l
  lda pad_r
  bne key_r
  bra fileselupd_out
key_down:
  jsr filesel_key_down
  bra fileselupd_out
key_up:
  jsr filesel_key_up
  bra fileselupd_out
key_right:
  jsr filesel_key_right
  bra fileselupd_out
key_left:
  jsr filesel_key_left
  bra fileselupd_out
key_b:
  jsr filesel_key_b
  bra fileselupd_out
key_a:
  jsr filesel_key_a
  bra fileselupd_out
key_x:
  jsr filesel_key_x
  bra fileselupd_out
key_y:
  jsr filesel_key_y
  bra fileselupd_out
key_select:
  jsr filesel_key_select
  bra fileselupd_out
key_start:
  jsr filesel_key_start
  bra fileselupd_out
key_l:
  jsr filesel_key_l
  bra fileselupd_out
key_r:
  jsr filesel_key_r
  bra fileselupd_out

fileselupd_out:
  lda #$09
  sta cursor_y
  rts

filesel_redraw:
  lda filesel_state
  beq redraw_filelist
;  cmp 1
;  beq redraw_main
filesel_redraw_out:
  rts

redraw_filelist:
  ldy #$0000
  sty dirptr_idx
  sty direntry_fits_idx
  sty direntry_xscroll
  sty direntry_xscroll_state
  stz dirend_idx
  stz dirend_onscreen
redraw_filelist_loop:
  ldy dirptr_idx
  tya
  lsr
  lsr
  cmp listdisp
  beq redraw_filelist_last
  rep #$20
  .al
  lda [<dirptr_addr,d],y
  sta wram(dirent_addr)
  iny
  iny
  sep #$20
  .as
  lda [<dirptr_addr,d],y ; load fileinfo bank
  clc
  adc #$c0              ; add $C0 for memory map
  sta wram(dirent_bank) ; store as current bank
  cmp #$c0              ; if bank was 0 -> dirend entry in DB
  beq redraw_filelist_dirend ; handle dirend
  iny
  lda [<dirptr_addr,d],y
  iny
  sta wram(dirent_type)
  sty dirptr_idx
  jsr print_direntry
  inc direntry_fits_idx
  bra redraw_filelist_loop
redraw_filelist_dirend:
  dey                   ; recover last valid direntry number
  dey                   ; (we had 2x iny of the direntry pointer above,
  beq +
  dey                   ; so account for those too)
  dey
  dey
  dey
+ sty dirend_idx        ; dirend_idx <- last valid directory entry.
  lda #$01              ; encountered during redraw, so must be on screen
  sta dirend_onscreen
  bra redraw_filelist_out
redraw_filelist_last:   ; check if next offscreen item is end of dir
  iny
  iny
  lda [<dirptr_addr,d],y
  beq redraw_filelist_dirend
redraw_filelist_out:
  ldx #$0000
  stx dirptr_idx
  brl filesel_redraw_out

print_direntry .block
; print the directory entry dirent_* in row cursor_y and advance cursor_y
  .virtual #0,d
Frame .block
  y             .byte ?         ; row
  pal           .byte ?         ; palette by file type
  done          .byte ?         ; characters of the name printed
  _             .dstruct SaveJSR
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  rep #$10
  .xl
  lda cursor_y
  sta Frame.y
  inc a
  sta cursor_y
  lda dirent_type
  bit #TYPE_SUBDIR|TYPE_PARENT
  beq +
  lda #$01      ; different color for dirs
  bra dirent_type_cont
+ cmp #TYPE_SPC ; SPC -> palette 2
  bne +
  lda #$02
  bra dirent_type_cont
+ lda #$00      ; default -> palette 0
dirent_type_cont:
  sta Frame.pal
  rep #$20
  .al
  lda dirent_addr
  clc
  adc #$06      ; skip size string
  clc
  adc direntry_xscroll
  sta fd_fnoff
  sep #$20
  .as
; name
  lda dirent_bank
  .param pha
  ldx fd_fnoff
  .param phx
  lda cursor_x
  .param pha
  lda Frame.y
  .param pha
  lda Frame.pal
  .param pha
  lda #54
  .param pha
  .call print_text
  sta Frame.done
  txa
  ldy direntry_fits_idx
  sta @w direntry_fits,y
  .unparam print_text
; rest of the name column
  lda #`space64
  .param pha
  .param pea, <>space64
  lda cursor_x
  clc
  adc Frame.done
  .param pha
  lda Frame.y
  .param pha
  lda Frame.pal
  .param pha
  lda #54
  sec
  sbc Frame.done
  .param pha
  .call print_text
  .unparam print_text
; size or "<dir>"
  lda dirent_type
  and #$f0
  cmp #$80
  bne dirent_is_file_2
  lda #`text_dirmark
  ldx #<>text_dirmark
  bra dirent_type_cont_2
dirent_is_file_2:
  lda dirent_bank
  ldx dirent_addr
dirent_type_cont_2:
  .param pha
  .param phx
  lda #56
  .param pha
  lda Frame.y
  .param pha
  lda Frame.pal
  .param pha
  lda #6
  .param pha
  .call print_text
  .unparam print_text
  .leave
  rts
.endblock

filesel_key_down:
  .as
  .xl
  jsr scroll_direntry_clean
  lda listdisp
  dec a
  cmp filesel_sel
  bne down_noscroll
  lda #$01
  sta filesel_dirty
  lda dirend_onscreen
  bne down_out
  rep #$20
  .al
  lda dirptr_addr
  clc
  adc #$04
  bcc +
  inc dirptr_bank
+ sta dirptr_addr
  sep #$20
  .as
  rts
down_noscroll:
  lda dirend_onscreen
  beq +
  lda dirend_idx
  lsr
  lsr
  cmp filesel_sel
  beq fileselupd_lastcursor
  bcc fileselupd_lastcursor
+ lda filesel_sel
  inc a
  sta filesel_sel
down_out:
  rts

filesel_key_up:
  jsr scroll_direntry_clean
  lda filesel_sel
  bne up_noscroll
  lda #$01
  sta filesel_dirty
  rep #$20
  .al
  lda dirptr_addr
  cmp dirstart_addr
  beq up_out
  sec
  sbc #$04
  bcs +
  dec dirptr_bank
+ sta dirptr_addr
  bra up_out
up_noscroll:
  dec a
  sta filesel_sel
up_out:
  sep #$20
  .as
  rts

fileselupd_lastcursor:
  jsr scroll_direntry_clean
  lda dirend_idx
  lsr
  lsr
  sta filesel_sel
  rts

; go back one page
filesel_key_left:
  stz direntry_xscroll
  stz direntry_xscroll_state
  lda #$01        ; must redraw afterwards
  sta filesel_dirty
  rep #$20
  .al
  lda dirptr_addr ; get current direntry pointer
  beq +           ; special case: if 0, we are at the first entry in memory
  lsr
  lsr             ; make comparable to listdisp
  cmp listdisp    ; if there's less or equal previous entries...
  beq +           ; ...than display lines, reset to directory start
  bcc +
  sec
  sbc listdisp    ; subtract one screen page's worth of entries
  asl
  asl             ; make comparable to dirstart_addr again
  cmp dirstart_addr ; check whether calculated offset is before...
  bcc +           ; ...start of directory
- sta dirptr_addr ; store new selected entry
  sep #$20
  .as
  rts
+ lda dirstart_addr ; reset pointer to start of directory
  stz filesel_sel ; reset the selection cursor too
  bra -

; go forth one page
filesel_key_right:
  stz direntry_xscroll
  stz direntry_xscroll_state
  sep #$20
  .as
  lda dirend_onscreen
  bne fileselupd_lastcursor
  lda #$01
  sta filesel_dirty
  rep #$20
  .al
  lda listdisp
  asl
  asl
  clc
  adc dirptr_addr
  sta dirptr_addr
  lda listdisp
  asl
  asl
  clc
  adc dirptr_addr
  cmp dirend_addr
  bmi +
  lda dirend_addr
  lsr
  lsr
  sec
  sbc listdisp
  asl
  asl
  sta dirptr_addr
  sep #$20
  .as
  lda listdisp
  dec a
  sta filesel_sel
+ sep #$20
  .as
  rts

filesel_key_a:
  jsr select_item
  rts

filesel_key_select:
  jsl select_favorite_file
  rts

filesel_key_start:
  jsl select_last_file
  rts

filesel_key_b:
  stz direntry_xscroll
  stz direntry_xscroll_state
  jmp sel_is_parent

filesel_key_l:
  stz direntry_xscroll
  stz direntry_xscroll_state
  ldx dirstart_addr
  stx dirptr_addr
  ldx #$0000
  stx filesel_sel
  lda #$01
  sta filesel_dirty
  rts

filesel_key_r:
  stz direntry_xscroll
  stz direntry_xscroll_state
  lda dirend_onscreen
  beq +
  jmp fileselupd_lastcursor
+ lda #$01
  sta filesel_dirty
; subtract listdisp from index to get first entry pos
; if less than one screen's worth, set to 0000, set cursor to last file
; else set cursor to listdisp
  rep #$20
  .al
  lda dirend_addr
  lsr
  lsr
  sec
  sbc dirstart_addr
  cmp listdisp ; listdisp > ptr?
  bpl +
  beq +
  stz dirptr_addr
  tya
  lsr
  lsr
  dec a
  sep #$20
  .as
  sta filesel_sel
  bra filesel_key_r_out
+ sbc listdisp
  asl
  asl
  sta dirptr_addr
  sep #$20
  .as
  lda listdisp
  dec a
  sta filesel_sel
filesel_key_r_out:
  rts

select_item:
  rep #$20
  .al
  lda filesel_sel
  and #$00ff
  asl
  asl
  tay
  sep #$20
  .as
  iny
  iny
  iny
  lda [<dirptr_addr,d],y
  cmp #TYPE_ROM
  beq sel_is_file
  cmp #TYPE_SPC
  beq sel_is_spc
  cmp #TYPE_SUBDIR
  beq sel_is_dir
  cmp #TYPE_PARENT
  beq sel_is_parent
select_item_cont:
  rts
sel_is_file:
  jsr select_file
  bra select_item_cont
sel_is_parent:
  jsr select_parent
  bra select_item_cont
sel_is_dir:
  jsr select_dir
  bra select_item_cont
sel_is_spc:
  jsr select_spc
  bra select_item_cont

select_file:
; have MCU load the rom
  dey
  rep #$20
  .al
  lda [<dirptr_addr,d],y
  and #$00ff
  sta @l MCU_PARAM+6
  dey
  dey
  lda [<dirptr_addr,d],y
  sta @l MCU_PARAM+4
  lda #<>FILESEL_CWD
  sta @l MCU_PARAM
  sep #$20
  .as
  lda #`FILESEL_CWD
  sta @l MCU_PARAM+2
  lda #$00
  sta @l MCU_PARAM+3
  lda #CMD_LOADROM
  jsr game_handshake
  rts

select_dir:
  tyx
; save old dir position
  rep #$20
  .al
  ldy #$0000
  lda wram(dirstart_addr)
  sta [<dirlog_idx,d],y
  iny
  iny
  lda wram(dirstart_bank)
  sta [<dirlog_idx,d],y
  iny
  lda wram(dirptr_addr)
  sta [<dirlog_idx,d],y
  iny
  iny
  lda wram(dirptr_bank)
  sta [<dirlog_idx,d],y
  iny
  lda wram(filesel_sel)
  sta [<dirlog_idx,d],y
  lda wram(dirlog_idx)
  clc
  adc #$0008
  sta wram(dirlog_idx)
  sep #$20
  .as
;---
; y = direntry ptr
  txy
  dey
  lda [<dirptr_addr,d],y
  clc
  adc #$c0
  sta wram(dirent_bank)
  dey
  dey
  rep #$20
  .al
  lda [<dirptr_addr,d],y
  sta wram(dirent_addr)
  tay
  sep #$20
  .as
  lda wram(dirent_bank)
  phb
  pha
  plb
; append selected dir name to current working directory
  ldx #$0000
find_path_end:
  lda @l FILESEL_CWD,x
  beq path_end_found
  inx
  bra find_path_end
path_end_found:
  dex
  lda @l FILESEL_CWD,x
  cmp #$2f
  beq copy_new_path
  inx
copy_new_path:
  lda #$2f
  sta @l FILESEL_CWD,x
  inx
copy_new_path_loop:
  lda @w 6,y
  sta @l FILESEL_CWD,x
  beq +
  inx
  iny
  bra copy_new_path_loop
+ lda #$00
; kill trailing /
  dex
  sta @l FILESEL_CWD,x
  plb
; request directory listing
  jsr filesel_request_filelist
  rep #$20
  .al
  lda #$0000
  sta wram(dirptr_addr)
  sta wram(dirstart_addr)
  sep #$20
  .as
  sta wram(filesel_sel)
  sta wram(direntry_xscroll)
  sta wram(direntry_xscroll_state)
  lda #$01
  sta wram(filesel_dirty)
  rts

select_parent:
; truncate last subdirectory
  sep #$20
  .as
  ldx #$0000
- lda @l FILESEL_CWD,x
  beq parent_end_found
  inx
  bra -
parent_end_found:
  cpx #$0001
  beq cwd_is_root
- lda @l FILESEL_CWD,x
  cmp #$2f
  beq +
  dex
  bra -
+ cpx #$0000
  bne +
  inx
+ lda #$00
  sta @l FILESEL_CWD,x
  bra parent_do_chdir
cwd_is_root:
  rts
parent_do_chdir:
  jsr filesel_request_filelist
  lda wram(dirlog_idx)
  sec
  sbc #$0008
  sta wram(dirlog_idx)
  ldy #$0000
  lda [<dirlog_idx,d],y ; load dirstart_addr
  sta wram(dirstart_addr)
  iny
  iny
  sep #$20
  .as
  lda [<dirlog_idx,d],y ; load dirstart_bank
  sta wram(dirstart_bank)
  iny
  rep #$20
  .al
  lda [<dirlog_idx,d],y ; load dirptr_addr
  sta wram(dirptr_addr)
  iny
  iny
  sep #$20
  .as
  lda [<dirlog_idx,d],y ; load dirptr_bank
  sta wram(dirptr_bank)
  iny
  rep #$20
  .al
  lda [<dirlog_idx,d],y ; load filesel_sel
  sta wram(filesel_sel)
  sep #$20
  .as
  lda #$01
  sta wram(filesel_dirty)
  rts

select_spc:
  dey
  rep #$20
  .al
  lda [<dirptr_addr,d],y
  and #$00ff
  sta @l MCU_PARAM+6
  dey
  dey
  lda [<dirptr_addr,d],y
  sta @l MCU_PARAM+4
  lda #<>FILESEL_CWD
  sta @l MCU_PARAM
  sep #$20
  .as
  lda #`FILESEL_CWD
  sta @l MCU_PARAM+2
  lda #$00
  sta @l MCU_PARAM+3
  lda #CMD_LOADSPC
  sta @l MCU_CMD
wait_spc:
  lda @l MCU_CMD
  cmp #$00
  bne wait_spc
  jsr spcplayer
  rts

filesel_key_x:
  jsr mainmenu
  rts

filesel_key_y:
  jsr open_context_menu
  rts

open_context_menu:
  rep #$20
  .al
  lda filesel_sel
  and #$00ff
  asl
  asl
  tay
  sep #$20
  .as
  iny
  iny
  iny
  lda [<dirptr_addr,d],y
  cmp #TYPE_ROM
  beq ctx_is_file
  cmp #TYPE_SPC
  beq ctx_is_spc
  cmp #TYPE_SUBDIR
  beq ctx_is_dir
  cmp #TYPE_PARENT
  beq ctx_is_parent
open_context_menu_cont:
  rts
ctx_is_file:
; "save" selected file path to MCU_PARAM in case we need to send it there later
  dey
  rep #$20
  .al
  lda [<dirptr_addr,d],y
  and #$00ff
  sta @l MCU_PARAM+6
  dey
  dey
  lda [<dirptr_addr,d],y
  sta @l MCU_PARAM+4
  lda #<>FILESEL_CWD
  sta @l MCU_PARAM
  sep #$20
  .as
  lda #`FILESEL_CWD
  sta @l MCU_PARAM+2
  lda #$00
  sta @l MCU_PARAM+3
  jsr filesel_contextmenu_file
  bra open_context_menu_cont
ctx_is_parent:
  bra open_context_menu_cont
ctx_is_dir:
  bra open_context_menu_cont
ctx_is_spc:
  bra open_context_menu_cont

setup_224:
  php
  rep #$30
  .xl
  .al
  lda #18
  sta listdisp
  dec a
  cmp filesel_sel
  bmi setup_224_adjsel
  bra +
setup_224_adjsel:
  sta filesel_sel
+
  sep #$20
  .as
  lda #$0b
  sta $2110
  lda #$00
  sta $2110
  ora #$08
  sta $2133
  lda #$01
  sta filesel_dirty
  .print_at space64, 0, 27, 0, 64
  .print_at space64, 0, 28, 0, 64

  plp
  rts

filesel_statusbar:
  pha
  phx
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda #`text_statusbar_keys
  .param pha
  .param pea, <>text_statusbar_keys
  lda #$02
  .param pha
  lda @l wram(listdisp)
  clc
  adc #$0a
  .param pha
  lda #$00
  .param pha
  lda #$40
  .param pha
  .call print_text
  .unparam print_text
  plp
  plx
  pla
  rts

; print a list of games (recent games or favorites: 256 bytes per entry)
; into the list window (last_win_*), one per row
; params (push order): p_list (long), p_n (number of entries, at least 1)
print_game_list .block
  .virtual #0,d
Frame .block
  src           .word ?         ; current entry
  y             .byte ?         ; its row
  n             .byte ?         ; entries left
  _             .dstruct SaveJSR
  p_n           .byte ?         ; pushed last
  p_list        .long ?         ; pushed first
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  rep #$10
  .xl
  ldx Frame.p_list
  stx Frame.src
  lda Frame.p_n
  sta Frame.n
  lda @l last_win_y
  inc a
  sta Frame.y
- lda Frame.p_list+2
  .param pha
  ldx Frame.src
  .param phx
  lda @l last_win_x
  inc a
  inc a
  .param pha
  lda Frame.y
  .param pha
  lda #$00
  .param pha
  lda #56
  .param pha
  .call print_text
  .unparam print_text
  inc Frame.src+1
  inc Frame.y
  dec Frame.n
  bne -
  .leave
  rts
.endblock

select_last_file:
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda #$00
  sta listsel_backup
select_last_redraw:
  lda @l ST_NUM_RECENT_GAMES
  sta num_recent_games
  stz recent_sel
  bne +
  jmp select_last_file_out
+ lda #`text_last
  sta window_tbank
  ldx #<>text_last
  stx window_taddr
  lda @l last_win_x
  sta window_x
  lda @l last_win_y
  sta window_y
  lda @l last_win_w
  sta window_w
  lda @l ST_NUM_RECENT_GAMES
  inc a
  inc a
  sta window_h
  jsr push_window
  lda num_recent_games
  sta listsel_max
  dec a
  cmp listsel_backup
  bcs +
  sta listsel_backup
+ lda listsel_backup
  sta listsel_sel
  jsr draw_window
  lda #`LAST_GAME
  .param pha
  .param pea, <>LAST_GAME
  lda num_recent_games
  .param pha
  .call print_game_list
  .unparam print_game_list
  stz listsel_dirty
  jsr enable_screen_update
select_last_choose:
  lda #$01
  sta listsel_step
  sta listsel_pickbutton ; allow button Y
  jsr menu_select_noinit
  sta listsel_backup
  sta @l MCU_PARAM
  cmp #$ff
  beq select_last_file_done
  lda listsel_pickbutton
  cmp #$00 ; button A was pressed
  beq select_last_file_play
  cmp #$01 ; button Y was pressed
  beq select_last_file_context_menu
  bra select_last_file_done
select_last_file_play:
  sep #$20
  .as
  lda #CMD_LOADLAST
  jsr game_handshake
  brl select_favorite_file_done
select_last_file_context_menu:
  jsr filesel_recent_contextmenu
  lda listsel_dirty
  bne +
  jmp select_last_choose
+ stz listsel_dirty
  jsr pop_window
  jsr disable_screen_update
  jmp select_last_redraw
select_last_file_done:
  jsr pop_window
select_last_file_out:
  jsr enable_screen_update
  plp
  rtl

select_favorite_file:
; shows a window with a list of favorite games
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda #$00
  sta listsel_backup
select_favorite_redraw:
  lda @l ST_NUM_FAVORITE_GAMES
  bne +
  jmp select_favorite_file_out
+ sta num_favorite_games
  lda #`text_favorite
  sta window_tbank
  ldx #<>text_favorite
  stx window_taddr
  lda @l last_win_x
  sta window_x
  lda @l last_win_y
  sta window_y
  lda @l last_win_w
  sta window_w
  lda num_favorite_games
  inc a
  inc a
  sta window_h
  jsr push_window
  lda num_favorite_games
  sta listsel_max
  dec a ; listsel_max is an element count but listsel_sel is 0..max-1
  cmp listsel_backup
  bcs +
  sta listsel_backup
+ lda listsel_backup
  sta listsel_sel
  jsr draw_window
  lda #`FAVORITE_GAMES
  .param pha
  .param pea, <>FAVORITE_GAMES
  lda num_favorite_games
  .param pha
  .call print_game_list
  .unparam print_game_list
  stz listsel_dirty
  jsr enable_screen_update
select_favorite_choose:
  lda #$01
  sta listsel_step
  sta listsel_pickbutton ; allow button Y
  jsr menu_select_noinit
  sta listsel_backup
  sta @l MCU_PARAM ; store selected item index in mcu param
  cmp #$ff ; if no selected item, do nothing
  beq select_favorite_file_done
  lda listsel_pickbutton
  cmp #$00 ; if button A was pressed
  beq select_favorite_file_play
  cmp #$01 ; if button Y was pressed
  beq select_favorite_file_context_menu
  bra select_favorite_file_done ; unknown button was pressed
select_favorite_file_play:
  sep #$20
  .as
  lda #CMD_LOADFAVORITE
  jsr game_handshake
  bra select_favorite_file_done
select_favorite_file_context_menu:
  jsr filesel_favorites_contextmenu
  lda listsel_dirty          ; need redraw?
  bne +
  jmp select_favorite_choose ; return to previous view
+ stz listsel_dirty
  jsr pop_window
  jsr disable_screen_update
  jmp select_favorite_redraw   ; redraw favorite list
select_favorite_file_done:
  jsr pop_window
select_favorite_file_out:
  jsr enable_screen_update
  plp
  rtl

; TODO the following seven functions differ only in the command byte
;      sent to the MCU and whether the listsel_dirty flag is set.
;      consider merging!
add_selected_file_to_favorites:
; have MCU save the file to the favorites list
; the file path should already have been saved to MCU_PARAM before calling
; this routine
  php
  phb
  sep #$20
  .as
  jsr hide_cursor
  jsr draw_loading_window
  jsr waitblank
  lda #$00
  sta @l SNES_CMD
  lda #CMD_ADD_FAVORITE_ROM
  sta @l MCU_CMD
; wait for ACK/NACK
- lda @l SNES_CMD
  cmp #$55
; success
  beq +
  cmp #$aa
; failure
  beq +
  bra -
+ lda #$55
  sta @l MCU_CMD
  jsr pop_window
  plb
  plp
  rtl

add_recent_file_to_favorites:
; have MCU remove the file from the recent list
; the list index of the file should already have been saved to MCU_PARAM before
; calling this routine
  php
  phb
  sep #$20
  .as
  jsr hide_cursor
  jsr draw_loading_window
  jsr waitblank
  lda #$00
  sta @l SNES_CMD
  lda #CMD_ADD_FAVORITE_RECENT
  sta @l MCU_CMD
  ; wait for ACK/NACK
- lda @l SNES_CMD
  cmp #$55
  ; success
  beq +
  cmp #$aa
  ; failure
  beq +
  bra -
+ lda #$55
  sta @l MCU_CMD
;  sta listsel_dirty
  jsr pop_window
  plb
  plp
  rtl

remove_selected_recent_file:
; have MCU remove the file from the recent list
; the list index of the file should already have been saved to MCU_PARAM before
; calling this routine
  php
  phb
  sep #$20
  .as
  jsr hide_cursor
  jsr draw_loading_window
  jsr waitblank
  lda #$00
  sta @l SNES_CMD
  lda #CMD_REMOVE_RECENT_ROM
  sta @l MCU_CMD
  ; wait for ACK/NACK
- lda @l SNES_CMD
  cmp #$55
  ; success
  beq +
  cmp #$aa
  ; failure
  beq +
  bra -
+ lda #$55
  sta @l MCU_CMD
  sta listsel_dirty
  jsr pop_window
  plb
  plp
  rtl

remove_selected_favorite_file:
; have MCU remove the file from the favorites list
; the list index of the file should already have been saved to MCU_PARAM before
; calling this routine
  php
  phb
  sep #$20
  .as
  jsr hide_cursor
  jsr draw_loading_window
  jsr waitblank
  lda #$00
  sta @l SNES_CMD
  lda #CMD_REMOVE_FAVORITE_ROM
  sta @l MCU_CMD
  ; wait for ACK/NACK
- lda @l SNES_CMD
  cmp #$55
  ; success
  beq +
  cmp #$aa
  ; failure
  beq +
  bra -
+ lda #$55
  sta @l MCU_CMD
  sta listsel_dirty
  jsr pop_window
  plb
  plp
  rtl

set_selected_as_autoboot_rom:
; have MCU save the currently selected file as the autoboot ROM
; the file path should already have been saved to MCU_PARAM before calling
; this routine (done by open_context_menu / ctx_is_file)
  php
  phb
  sep #$20
  .as
  jsr hide_cursor
  jsr draw_loading_window
  jsr waitblank
  lda #$00
  sta @l SNES_CMD
  lda #CMD_SET_AUTOBOOT_ROM
  sta @l MCU_CMD
; wait for ACK/NACK
- lda @l SNES_CMD
  cmp #$55
; success
  beq +
  cmp #$aa
; failure
  beq +
  bra -
+ lda #$55
  sta @l MCU_CMD
  jsr pop_window
  plb
  plp
  rtl

set_recent_as_autoboot_rom:
; have MCU save the selected recent game as the autoboot ROM.
  php
  phb
  sep #$20
  .as
  jsr hide_cursor
  jsr draw_loading_window
  jsr waitblank
  lda #$00
  sta @l SNES_CMD
  lda #CMD_SET_AUTOBOOT_RECENT
  sta @l MCU_CMD
; wait for ACK/NACK
- lda @l SNES_CMD
  cmp #$55
; success
  beq +
  cmp #$aa
; failure
  beq +
  bra -
+ lda #$55
  sta @l MCU_CMD
  jsr pop_window
  plb
  plp
  rtl

set_favorite_as_autoboot_rom:
; have MCU save the selected favorite game as the autoboot ROM
; the list index of the favorite should already have been saved to MCU_PARAM
; before calling this routine (done by select_favorite_file)
  php
  phb
  sep #$20
  .as
  jsr hide_cursor
  jsr draw_loading_window
  jsr waitblank
  lda #$00
  sta @l SNES_CMD
  lda #CMD_SET_AUTOBOOT_FAV
  sta @l MCU_CMD
; wait for ACK/NACK
- lda @l SNES_CMD
  cmp #$55
; success
  beq +
  cmp #$aa
; failure
  beq +
  bra -
+ lda #$55
  sta @l MCU_CMD
  jsr pop_window
  plb
  plp
  rtl

scroll_direntry_clean:
  lda #$01
  sta direntry_xscroll_state
  stz direntry_xscroll
  stz direntry_xscroll_wait
  jsr scroll_direntry
  stz direntry_xscroll_state
  stz direntry_xscroll
  rts

scroll_direntry:
  ldy filesel_sel
  lda direntry_xscroll_state
  bne +
  lda direntry_fits,y
  bne scroll_direntry_enter
;  stz direntry_xscroll_state
  rts
scroll_direntry_enter:
  lda #$01
  sta direntry_xscroll_state
  stz direntry_xscroll_wait
+ lda direntry_xscroll_wait
  beq +
  dec direntry_xscroll_wait
  rts

+ lda direntry_xscroll
  bne scroll_direntry_scrollfast
  lda #$28
  bra +
scroll_direntry_scrollfast:
  lda #$10
+ sta direntry_xscroll_wait
  tya
  clc
  adc #$09
  sta cursor_y
  lda #$02
  sta cursor_x
  rep #$20
  .al
  lda filesel_sel
  asl
  asl
  tay
  lda [<dirptr_addr,d],y
  sta wram(dirent_addr)
  iny
  iny
  sep #$20
  .as
  lda [<dirptr_addr,d],y ; load fileinfo bank
  clc
  adc #$c0              ; add $C0 for memory map
  sta wram(dirent_bank) ; store as current bank
  iny
  lda [<dirptr_addr,d],y
  iny
  sta wram(dirent_type)
  ldy filesel_sel
  sty direntry_fits_idx
  phy
  jsr print_direntry
  ply
  lda direntry_fits,y
  bne +
  lda #$ff
  sta direntry_xscroll_state
  lda #$28
  sta direntry_xscroll_wait
+ lda direntry_xscroll_state
  clc
  adc direntry_xscroll
  sta direntry_xscroll
  bne +
  lda #$01
  sta direntry_xscroll_state
+ rts

filesel_request_filelist:
  php
  phb
  rep #$30
  .al
  .xl
  lda #<>FILESEL_CWD
  sta @l MCU_PARAM
  lda #<>ROOT_DIR
  sta @l MCU_PARAM+4
  sep #$20
  .as
  lda #`FILESEL_CWD
  sta @l MCU_PARAM+2
  lda #`ROOT_DIR
  sta @l MCU_PARAM+6
  lda #TYPE_PARENT
  sta @l MCU_PARAM+8
  lda #TYPE_SUBDIR
  sta @l MCU_PARAM+9
  lda #TYPE_ROM
  sta @l MCU_PARAM+10
  lda #TYPE_SPC
  sta @l MCU_PARAM+11
  lda #$00
  sta @l MCU_PARAM+12
  sta @l SNES_CMD
  lda #CMD_READDIR
  sta @l MCU_CMD
  lda #$00
  pha
  plb
  jsr hide_cursor
  jsr draw_loading_window
filesel_request_filelist_wait_mcu:
  jsl wram_wait_mcu
  jsr pop_window
  ldy #$0002
- lda [<dirstart_addr,d],y
  beq +
  iny
  iny
  iny
  iny
  bra -
+ rep #$20
  .al
  tya
  and #$fffc
  sta dirend_addr
  plb
  plp
  rts

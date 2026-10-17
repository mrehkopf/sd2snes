.virtual $0000          ; low WRAM mirror addresses (see wram() in rom.asm)

dirptr_addr:    .word 0
dirptr_bank:    .word 0
dirstart_addr:  .word 0
dirstart_bank:  .word 0
dirend_addr:    .word 0
dirend_bank:    .word 0
dirend_idx:     .word 0
dirptr_idx:     .word 0
dirent_addr:    .word 0
dirent_bank:    .word 0
dirent_type:    .byte 0
dirend_onscreen: .byte 0
dirlog_idx:     .byte 0, 0, 0 ; long ptr
direntry_fits_idx: .byte 0, 0
;----------parameters for dma----------
dma_a_bank:     .byte 0
dma_a_addr:     .word 0
dma_b_reg:      .byte 0
dma_len:        .word 0
dma_mode:       .byte 0

;----------state information----------
isr_done:       .byte 0     ; isr done flag
bar_xl:         .byte 0     ; logical x position of select bar
bar_yl:         .byte 0     ; logical y position of select bar
bar_x:          .byte 0     ; pixel x position of select bar
bar_y:          .byte 0     ; pixel y position of select bar
bar_w:          .byte 0     ; bar width
bar_wl:         .byte 0     ; bar width
filesel_state:  .byte 0     ; menu state (0=file select)
filesel_dirty:  .byte 0     ; menu dirty (e.g. after state change or when redraw is needed)
filesel_sel:    .word 0     ; selected item #
cursor_x:       .byte 0     ; current cursor position (x)
cursor_y:       .byte 0     ; current cursor position (y)
fd_addr:        .word 0     ; address of current "file descriptor"
fd_bank:        .byte 0     ; bank of current "file descriptor"
fd_fnoff:       .word 0     ; offset of filename in file descriptor
pad1mem:        .word 0
pad1trig:       .word 0
pad1delay:      .word 0
window_x:       .byte 0
window_y:       .byte 0
window_w:       .byte 0
window_h:       .byte 0
window_tbank:   .byte 0
window_taddr:   .word 0
;----------dialog specific data
time_s1:        .byte 0
time_s10:       .byte 0
time_m1:        .byte 0
time_m10:       .byte 0
time_h1:        .byte 0
time_h10:       .byte 0
time_d1:        .byte 0
time_d10:       .byte 0
time_mon:       .byte 0
time_y1:        .byte 0
time_y10:       .byte 0
time_y100:      .byte 0
; time_s1..time_y100 are passed to time_init/rendertime as a single BCDTime record
.cerror time_y100 - time_s1 != BCDTime.y100, "time_* variables do not match BCDTime layout"
time_sel:       .byte 0
time_exit:      .byte 0
time_cancel:    .byte 0
time_ptr:       .byte 0
time_tmp:       .byte 0
;--
mm_tmp:         .byte 0
mm_sel:         .byte 0
;--
num_recent_games: .byte 0
recent_sel:     .byte 0
num_favorite_games: .byte 0
;----------menu layout/system constants
listdisp:       .word 0 ; number of displayable list entries

;-misc
testvar:        .word 0, 0, 0, 0
;menu system
listsel_sel:        .byte 0
listsel_step:       .byte 0
listsel_max:        .byte 0
listsel_pickbutton: .byte 0
listsel_dirty:      .byte 0
listsel_backup:     .byte 0

screen_dma_disable: .word 0

;----------hdma tables in WRAM (must be stable when cartridge is cut off)
hdma_pal:
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0
hdma_cg_addr:
  .byte 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0
hdma_mode:      .byte 0, 0, 0, 0, 0
hdma_bg1scroll:
  .byte 0
  .byte 0, 0, 0, 0
  .byte 0
  .byte 0, 0, 0, 0
  .byte 0
  .byte 0, 0, 0, 0
  .byte 0
  .byte 0, 0, 0, 0
  .byte 0
hdma_bg2scroll:
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0
hdma_math:
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
hdma_math_upperborder:
  .byte 0
  .byte 0, 0
hdma_math_selection:
  .byte 0
  .byte 0, 0
hdma_math_lowerborder:
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0

hdma_window:
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0
  .byte 0, 0
  .byte 0
; dirlog format:
; dirstart_addr  2
; dirstart_bank  1
; dirptr_addr  2
; dirptr_bank  1
; menu_sel  2
; total    8 bytes
dirlog:
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

direntry_fits:
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
direntry_xscroll_state:
  .word 0
direntry_xscroll:
  .word 0
direntry_xscroll_wait:
  .word 0
current_dir:
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
infloop:        .byte 0, 0 ; to be filled w/ 80 FE
tgt_bright:     .byte 0
cur_bright:     .byte 0
menu_brightness: .byte 0
;-- pad
pad_b:          .byte 0
pad_y:          .byte 0
pad_select:     .byte 0
pad_start:      .byte 0
pad_up:         .byte 0
pad_down:       .byte 0
pad_left:       .byte 0
pad_right:      .byte 0
pad_a:          .byte 0
pad_x:          .byte 0
pad_l:          .byte 0
pad_r:          .byte 0

;------------------------
window_stack_head: .word 0
dbg_ptr:        .word 0
fade_speed:     .byte 0
fade_count:     .byte 0
idle_count:     .word 0
;----------cheat editor (cheat.asm; its windows keep their state in their frames)
cheat_msg_timer: .byte 0      ; frames until a status bar message goes away
; interface to the functions of its options menus (menudata.asm)
cheat_action:   .byte 0       ; CHEAT_ACT_* chosen in an options menu
cheat_nosel:    .byte 0       ; 1: the menu is not for a selected cheat/code
_END:           .byte 0
.cerror * > $2000, format("WRAM variables end at $%04x: they must fit the low WRAM mirror ($0000-$1fff)", *)
.endvirtual

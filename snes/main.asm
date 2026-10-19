.word <>nmihook
GAME_MAIN:
  sep #$20
  .as
  stz $4200     ; inhibit VBlank NMI
  lda #$01
  sta $420d
  rep #$20
  .al
  lda #$0000
  sta @l MCU_CMD ; clear MCU command register
  sta @l MCU_PARAM ; clear MCU command parameters
  sta @l MCU_PARAM+2
  stz dbg_ptr
  lda WARM_SIGNATURE ; Was CMD_RESET issued before reset?
  cmp #$fa50    ; If yes, then perform warm boot procedure
  bne coldboot
  eor WARM_COMPLEMENT
  inc a
  bne coldboot
  sta WARM_SIGNATURE
  sta WARM_COMPLEMENT
  lda SAVED_SP ; Restore previous stack pointer
  tcs
  ; restore menu state that might have been destroyed
  sep #$20
  .as
  rep #$10
  .xl
  stz $2183
  ldx #$0000
  stx $2181
  stz $4370
  ldx #<>WRAM_BAK
  lda #`WRAM_BAK
  stx $4372
  sta $4374
  ldx #$2000
  stx $4375
  lda #$80
  sta $4371
  sta $420b
  ; The following initialization processes must not touch memory
  ; structures used by the file selector!
  jsr killdma
  jsr apu_ram_init
  jsr waitblank
  jsr snes_init
  jsr setup_gfx
  jsr store_wram_routines
  jsr colortest
  jsr video_init
  jsr pad_init
  jsr setup_hdma
  jsr detect_ultra16
  jsr detect_satellaview
  lda @l CFG_BRIGHTNESS_LIMIT
  sta cur_bright
  sta tgt_bright
  sta menu_brightness
  sta $2100
  jml set_bank  ; Set bios bank, just to be sure
set_bank:
  plp           ; Restore processor state
  rts           ; Jump to the routine which called the sub-routine issuing CMD_RESET

coldboot:       ; Regular, cold-start init
  sep #$20
  .as
  jsr killdma
  jsr clear_wram
  jsr apu_ram_init
  jsr waitblank
  jsr snes_init
  jsr setup_gfx
  jsr store_wram_routines
  jsr colortest
  jsr video_init
  jsr pad_init
  jsr setup_hdma
  jsr detect_ultra16
  jsr detect_satellaview
  jsr wait_mcu_ready
  ; Check autoboot flag (set by MCU if autoboot.cfg is present)
  ; Screen is still black (tgt_bright set in video_init)
  ; If autoboot is inactive, START is held, or the ROM can't be loaded:
  ; fall through to normal menu startup
  lda @l ST_AUTOBOOT_ENABLED
  beq coldboot_autoboot_out       ; no autoboot configured
autoboot_start_poll:
  jsr waitblank         ; sync to VBlank boundary
  jsr read_pad          ; early enough to preempt Auto Joypad Read
  lda pad_start         ; TODO possibly use configurable button combo here
  bne coldboot_bypass_autoboot    ; START pressed -> bypass autoboot
  ; timeout - START not held: trigger autoboot
  jsr autoboot_cmd_handshake
  bra coldboot_autoboot_out
coldboot_bypass_autoboot:         ; clear autoboot flag, continue to menu
  jsr clr_autoboot_at_boot
coldboot_autoboot_out:
  jsr screen_on
  jsr filesel_init
  sep #$20
  .as
  lda @l ST_RTC_VALID
  beq +
  jsl rtc_init
+
  jsr fileselloop
  sei
  stz $4200
  jml wram(infloop) ; infinite loop in WRAM

colortest:
  sep #$20
  .as
  rep #$10
  .xl
  stz $2130
  rts

setup_gfx:
  sep #$20
  .as
  rep #$10
  .xl
  stz $4200
  stz $420b
  stz $420c
; clear tilemap buffers
  ldx #$8000
  stx $2181
  lda #$00
  sta $2183
  .DMA7 #$08, #$8000, #`zero, #<>zero, #$80

; fill the tile buffers with the space (BG1 tile 64, BG2 tile 128), the
; only character a skin font must leave blank; in BG2 rows 0-7 with tile 64:
; the logo lines show rows 0-6 in mode 3, where BG2 is 4bpp
  rep #$20
  .al
  ldx #$1000-2
- lda #$0040
  sta @l BG1_TILE_BUF,x
  cpx #8*64
  bcc +
  lda #$0080
+ sta @l BG2_TILE_BUF,x
  dex
  dex
  bpl -
  sep #$20
  .as

; clear BG1 tilemap
  ldx #BG1_TILE_BASE
  stx $2116
  .DMA7 #$09, #$800, #`zero, #<>zero, #$18

; clear BG2 tilemap
  ldx #BG2_TILE_BASE
  stx $2116
  .DMA7 #$09, #$800, #`zero, #<>zero, #$18

; all sprites off-screen until the skin places its own
  jsr clear_oam

; generate logo tilemap
  ldx #BG1_TILE_BASE
  stx $2116
  ldx #$0100
- stx $2118
  inx
  cpx #$01e0
  bne -

; palette, font, logo, sprites, and the HDMA tables in WRAM (so we can work
; "without" the cartridge) for the background gradient, the sprite pages
; and the selection bar
  jsr apply_skin

; screen mode
  lda #`wram(hdma_mode)
  ldx #hdma_mode
  stx $2181
  sta $2183
  .DMA7 #$00, #5, #`hdma_mode_src, #<>hdma_mode_src, #$80

; bg scroll
  lda #`wram(hdma_bg1scroll)
  ldx #hdma_bg1scroll
  stx $2181
  sta $2183
  .DMA7 #$00, #21, #`hdma_bg1scroll_src, #<>hdma_bg1scroll_src, #$80 ;

  lda #`wram(hdma_bg2scroll)
  ldx #hdma_bg2scroll
  stx $2181
  sta $2183
  .DMA7 #$00, #13, #`hdma_bg2scroll_src, #<>hdma_bg2scroll_src, #$80 ;

; initialize window stack
  ldx #$ffff
  stx window_stack_head
  rts

video_init:
  sep #$20       ; 8-bit accumulator
  .as
  rep #$10       ; 16-bit index
  .xl
  lda #$03      ; mode 3, mode 5 via HDMA
  sta $2105
  lda #BG1_TILE_BASE>>8 ; tilemap address, SC size 32x32
  sta $2107     ; for BG1
  lda #BG2_TILE_BASE>>8 ; tilemap address, SC size 32x32
  sta $2108     ; for BG2
  lda #(FONT_BASE>>12)*$11 ; chr base addr:
  sta $210b     ; BG1 and BG2 = FONT_BASE
  lda #$13      ; enable BG1+BG2+OBJ
  sta $212c     ; BG Main
  lda #$13      ; enable BG1+BG2+OBJ
  sta $212d     ; BG Sub
  lda #$20      ; Window 1 for color
  sta $2125     ; Color window
  lda #$01      ; cut off leftmost subscreen pixel garbage
  sta $2126
  lda #$fe
  sta $2127
  jsr setup_224
  lda #$10
  sta $2130
  lda #$1f
  sta $212e
  sta $212f
;  stz $2121
  lda #8
  sta bar_yl
  stz cur_bright
  stz tgt_bright
  stz menu_brightness
  lda #$01
  sta fade_speed
  stz fade_count
  stz idle_count
  stz idle_count+1
  stz screen_dma_disable
  stz screen_dma_disable+1
  rts

screen_on:
  stz $2100     ; screen on, 0% brightness
  lda @l CFG_BRIGHTNESS_LIMIT
  sta tgt_bright
  sta menu_brightness
  rts

snes_init:
  sep #$20       ; 8-bit accumulator
  .as
  rep #$10       ; 16-bit index
  .xl
  stz $4200
  lda #$ff
  sta $4201
  stz $4202
  stz $4203
  stz $4204
  stz $4205
  stz $4206
  stz $4207
  stz $4208
  stz $4209
  stz $420a
  stz $420b
  stz $420c
  lda #$8f
  sta $2100     ; INIDISP: force blank
  lda #OBSEL_PAGE0 ; 16x16+32x32; name=0; base=OBJ_TILE_BASE
  sta $2101
  stz $2102
  stz $2103
;  stz $2104    ; (OAM Data?!)
;  stz $2104    ; (OAM Data?!)
  stz $2105
  stz $2106
  stz $2107
  stz $2108
  stz $2109
  stz $210a
  stz $210b
  stz $210c
  stz $210d
  stz $210d
  stz $210e
  stz $210e
  stz $210f
  stz $210f
  lda #$05
  sta $2110
  stz $2110
  stz $2111
  stz $2111
  stz $2112
  stz $2112
  stz $2113
  stz $2113
  stz $2114
  stz $2114
  lda #$80
  sta $2115
  stz $2116
  stz $2117
;  stz $2118    ;(VRAM Data?!)
;  stz $2119    ;(VRAM Data?!)
  stz $211a
  stz $211b
  lda #$01
  sta $211b
  stz $211c
  stz $211c
  stz $211d
  stz $211d
  stz $211e
  sta $211e
  stz $211f
  stz $211f
  stz $2120
  stz $2120
  stz $2121
;  stz $2122    ; (CG Data?!)
;  stz $2122    ; (CG Data?!)
  stz $2123
  stz $2124
  stz $2125
  stz $2126
  stz $2127
  stz $2128
  stz $2129
  stz $212a
  stz $212b
  stz $212c
  stz $212d
  stz $212e
  stz $212f
  lda #$30
  sta $2130
  stz $2131
  lda #$e0
  sta $2132
  stz $2133
  rts

clear_vram:
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda $2100
  pha
  lda #$80
  sta $2100
  sta $2115
  ldx #$8000
  ldy #$0000
  stx $2116
- sty $2118
  dex
  bne -
  pla
  sta $2100
  plp
  rts

; fadeloop runs from block RAM while the FPGA is reconfigured (no ROM).
; It is copied ROM -> WRAM (store_wram_routines) -> block RAM
; (store_blockram_routine).
; acknowledge ready for ROM load
; wait for ACK
; fade screen
; acknowledge WRAM init done (send RESET)
.section bramcode
fadeloop:
  sep #$30
  .as
  .xs
  phk
  plb
  stz $4200
  sei
  sta MCU_CMD
  ldx cur_bright
fadeloop_start:
  lda $4212
  asl
  bcs fadeloop_start
- lda $4212
  asl
  bcc -
  dex
  dex
  stx $2100
  bpl fadeloop_start
  stz $2126
  stz $212e
  stz $2131
  stz $2130
  lda #$80
  sta $2100
  stz $2a00
  stz $420c
; DMA fill WRAM banks
  ldx #$00
  rep #$10
  .xl
  stz $2183
  stx $2181
  stx $4375
  lda #$55
  sta $2aff     ; WRAM fill value
  ldx #$8008
  stx $4370
  ldx #$2aff
  stx $4372
  stz $4374
  lda #$80
; fill bank $7e
  sta $420b
; fill bank $7f
  sta $420b
; reset PPU2 H/V odd/even read flag
; (fix for uninitialized $213c/$213d reads)
  lda $213f
; fix for uninitialized DMA transfers
  rep #$20
  .al
  lda #$ffff
  ldy #$007c
- dey
  dey
  sta $4300,y
  bne -
  lda #$fe80 ; - bra -
  sta @l $7fffe0
  lda #CMD_RESET
  sta MCU_CMD
  jml $7fffe0
- bra -
.send bramcode
.cerror fadeloop != BRAM_PAYLOAD, format("fadeloop is at $%04x, not at BRAM_PAYLOAD ($%04x): it must be the first bramcode fragment", fadeloop, BRAM_PAYLOAD)

; copy the wramcode routines to WRAM, and the bramcode payload (fadeloop) to
; its staging area in WRAM (from where store_blockram_routine copies it on)
store_wram_routines:
  php
  rep #$30
  .xl
  .al
  phb
  lda #WRAMCODE_SIZE-1
  ldx #<>WRAMCODE_LOAD
  ldy #<>WRAMCODE_RUN
  mvn #`WRAMCODE_LOAD, #`WRAMCODE_RUN
  lda #BRAMCODE_SIZE-1
  ldx #<>BRAMCODE_LOAD
  ldy #<>BRAMSTAGE_START
  mvn #`BRAMCODE_LOAD, #`BRAMSTAGE_START
  plb
  plp
  rts

; routines that run from WRAM (copied there by store_wram_routines)
.section wramcode
store_blockram_routine:
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda #$80
  sta infloop
  lda #$fe
  sta infloop+1
  rep #$20
  .al
  lda #BRAMCODE_SIZE-1
  ldx #<>BRAMSTAGE_START
  ldy #<>BRAMCODE_RUN
  phb
  mvn #`BRAMSTAGE_START, #`BRAMCODE_RUN
  plb
  plp
  rtl

wram_routine:
  php
  sep #$20
  .as
  rep #$10
  .xl
; acknowledge ready for FPGA reconf
  lda #CMD_FPGA_RECONF
  sta @l MCU_CMD
; wait for ACK (reconf done or not necessary)
- lda @l SNES_CMD
  cmp #$77
  bne -
; install fade loop in block RAM after FPGA reconf
; must reside in WRAM prior to copying! ROM not available
  jsl store_blockram_routine
  jsl fadeloop
  plp
  rtl

wram_wait_mcu:
  .as
- lda @l SNES_CMD
  cmp #$55
  bne -
  rtl

; send command A to the MCU and wait until it has been executed
; Waits for the MCU to finish a previous command first (CMD_SAVE_CFG doesn't
; wait for completion) and repeats the command until the MCU echoes it, so
; it can't get lost while the MCU re-enters its command loop.
wram_mcu_cmd:
  .as
  pha
- lda @l SNES_CMD
  cmp #$55
  bne -
  pla
- sta @l MCU_CMD
  cmp @l SNES_CMD
  bne -
- lda @l SNES_CMD
  cmp #$55
  bne -
  rtl

wram_load_ultra16_cfg:
  .as
  lda @l $0021c1
  and #$fe
  sta @l $0021c1
  lda @l $c70000
  pha
  lda @l $0021c1
  ora #$01
  sta @l $0021c1
  pla
  sta @l ST_U16_CFG
  rtl

.send wramcode

game_handshake:
  php
  sep #$20
  .as
  pha
  jsr hide_cursor
  jsr draw_loading_window
  jsr waitblank
; send initial request to MCU
  lda #$00
  sta @l SNES_CMD
  pla
  sta @l MCU_CMD
; wait for ACK/NACK with error (noimpl warning etc.)
- lda @l SNES_CMD
  cmp #$55
  beq +
  cmp #$aa
  beq game_handshake_error
  bra -
+ stz $4200
  sei
  lda #$55
  sta @l MCU_CMD
; jump to WRAM
  jsl wram_routine
  plp
  rts

game_handshake_error:
; TODO display meaningful error message
  jsr pop_window
  plp
  rts

wait_mcu_ready:
  php
  sep #$20
  .as
  lda #$00
  sta @l MCU_CMD
- lda @l SNES_CMD
  cmp #$55
  bne -
  plp
  rts

; autoboot_cmd_handshake: run game_handshake with CMD_LOAD_AUTOBOOT
autoboot_cmd_handshake:
  php
  sep #$20
  .as
  lda #CMD_LOAD_AUTOBOOT
  jsr game_handshake
  plp
  rts

; clr_autoboot_at_boot: called at cold boot when START is held.
; Sends CMD_CLR_AUTOBOOT_ROM to clear the autoboot ROM setting.
; Does NOT load a ROM; returns so the normal menu loop can proceed.
clr_autoboot_at_boot:
  php
  sep #$20
  .as
  lda #$00
  sta @l SNES_CMD
  lda #CMD_CLR_AUTOBOOT_ROM
  sta @l MCU_CMD
- lda @l SNES_CMD
  cmp #$55
  beq +
  cmp #$aa
  beq +
  bra -
+ lda #$55
  sta @l MCU_CMD
  plp
  rts

clear_wram:
  php
  rep #$10
  .xl
  ldx #$0000
  stz $2183
  stx $2181
  lda #$55
  sta $2aff     ; WRAM fill value
  ldx #$8008
  stx $4370
  ldx #$2aff
  stx $4372
  stz $4374
  lda #$80
; fill $7e0000-$7e1fef (spare a bit of stack)
  ldx #$1ff0
  stx $4375
  sta $420b
; fill $7e2000-$7effff
  ldx #$2000
  stx $2181
  ldx #$e000
  stx $4375
  sta $420b
; fill bank $7f
  ldx #$0000
  stx $4375
  sta $420b
  plp
  rts

backup_wram:
  php
  rep #$10
  .xl
  sep #$20
  .as
  ldx #$0000
  stx $2181
  stz $2183
  .DMA7 #$80, #$2000, #`WRAM_BAK, #<>WRAM_BAK, #$80
  plp
  rts

detect_ultra16:
  php
  sep #$20
  .as
  lda #$aa
  sta @l $0021c0
  lda @l $0021c0
  cmp #$55
  beq detect_ultra16_found
  lda #$00
  sta @l ST_IS_U16
  bra detect_ultra16_out
detect_ultra16_found:
  lda @l $0021c2
  sta @l ST_IS_U16
  jsl wram_load_ultra16_cfg
  lda @l $0021c1
  and #$fb
  sta @l $0021c1
detect_ultra16_out:
  lda #$55
  sta @l $0021c0
  plp
  rts

detect_satellaview:
  php
  sep #$20
  .as
  lda #$aa
  sta $2188
  cmp $2188
  bne detect_satellaview_out
  lda #$55
  sta $2188
  cmp $2188
  bne detect_satellaview_out
detect_satellaview_found:
  stz $2188
  stz $2189
  stz $218e
  stz $218f
  lda #$01
  sta @l ST_HAS_SATELLAVIEW
  plp
  rts
detect_satellaview_out:
  lda #$00
  sta @l ST_HAS_SATELLAVIEW
  plp
  rts

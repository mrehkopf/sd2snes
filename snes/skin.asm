; skins: replacement graphics and colors for the menu
;
; The file format is described in skin-format.md. A skin is a sequence of
; chunks ("SNS", version, ID, length, payload), each replacing one asset of
; the default skin (skin/default.asm, applied first). walk_skin applies them;
; chunks with an unknown ID or version, or with the wrong payload size for
; their asset, are skipped. The MCU loads the skin file (smaller than
; 64 KB) to SKIN_ADDR, followed by a zero word or the end of the bank.
;
; Assets that change per line (gradient, sprite pages, selection bar) are
; data, not HDMA tables; the menu builds the tables from them:
; - background gradient: channel 1 writes CGADD twice and CGDATA twice per
;   line (build_grad)
; - sprite pages: channel 2 writes OBSEL (build_obsel)
; - selection bar: channel 5 writes CGADSUB and COLDATA, channel 6 writes
;   COLDATA twice, so every bar line sets a full RGB color (set_bar_color)

GRAD_LINES      = 224           ; lines of per-line data (gradient, sprite pages)
BAR_MAX_LINES   = 16            ; selection bar height

; skin file: chunks of a header and a payload (skin-format.md)
SKIN_HEADER_SIZE = 12           ; "SNS", version, ID (4 characters), length (32 bits)
SKIN_VERSION    = 1

; payload sizes of the assets with a fixed size
FONT_SIZE       = 256*64        ; 16x8 characters, 4bpp
LOGO_SIZE       = 224*64        ; 32x7 tiles, 8bpp
GRAD_SIZE       = GRAD_LINES*4
OAMT_HEAD_SIZE  = 4 + GRAD_LINES ; tiles, sprites, reserved, sprite pages
OAMT_MAX_TILES  = (FONT_BASE - OBJ_TILE_BASE) / 16 - OBJ_FIRST_TILE
OAMT_MAX_SPRITES = 96           ; the menu keeps sprites 96-127 for itself

; header of a chunk of the default skin; the payload ends at "chunk_end"
; in the block of the chunk
skin_chunk .segment id
  .text "SNS"
  .byte SKIN_VERSION
  .text \id
  .dword chunk_end - _payload
_payload:
.endsegment

HDMA_GRAD_SIZE  = 1 + 127*4 + 1 + (GRAD_LINES-127)*4 + 1
HDMA_OBSEL_SIZE = GRAD_LINES*2 + 1 ; worst case: a new page on every line
HDMA_BAR_SIZE   = 3 + 3 + 1 + BAR_MAX_LINES*2 + 3 + 1

; build the background gradient table for HDMA channel 1
; NMI must be off: uses DMA channel 7 and the WRAM port
; params: p_src (long): GRAD_LINES records [CGADD, CGADD, color lo, color hi]
build_grad .block
  .virtual #0,d
Frame .block
  _             .dstruct SaveJSR
  p_src         .long ?         ; records (pushed first: bank, then address)
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  rep #$10
  .xl
  ldx #hdma_grad
  stx $2181
  lda #`wram(hdma_grad)
  sta $2183
  stz $4370                     ; A to B, increment
  lda #$80                      ; WRAM port ($2180)
  sta $4371
  ldx Frame.p_src
  stx $4372
  lda Frame.p_src+2
  sta $4374
  lda #$80 | 127                ; repeat mode: one record per line
  sta $2180
  ldx #127*4
  stx $4375
  lda #$80
  sta $420b
  lda #$80 | (GRAD_LINES-127)   ; the remaining lines; the DMA source
  sta $2180                     ; address continues
  ldx #(GRAD_LINES-127)*4
  stx $4375
  lda #$80
  sta $420b
  stz $2180                     ; end of table
  .leave
  rts
.endblock

; build the sprite page table for HDMA channel 2 (OBSEL): one entry per run
; of lines with the same page, so OBSEL is written only where the page
; changes (and every 127 lines). The last run gets a single line: OBSEL keeps
; its value after the end of the table, so a skin without page changes
; writes OBSEL once per frame, at line 0.
; params: p_src (long): GRAD_LINES page numbers (0-2: sprite tiles 256-511
;         at OBJ_PAGES_BASE + page * $1000)
build_obsel .block
  .virtual #0,d
Frame .block
  count         .byte ?         ; lines in the current run
  value         .byte ?         ; OBSEL value of the current run
  last          .word ?         ; first line of the last run
  _             .dstruct SaveJSR
  p_src         .long ?         ; page numbers (pushed first: bank, then address)
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  rep #$10
  .xl
  ldy #GRAD_LINES-1             ; find the last run
  jsr obsel_value
  sta Frame.value
- dey
  bmi +
  jsr obsel_value
  cmp Frame.value
  beq -
+ iny
  sty Frame.last
  ldx #$0000                    ; table offset
  ldy #$0000                    ; line
  cpy Frame.last
  beq last_run
run:
  jsr obsel_value
  sta Frame.value
  stz Frame.count
same:
  inc Frame.count
  iny
  cpy Frame.last
  beq emit
  lda Frame.count
  cmp #127
  beq emit
  jsr obsel_value
  cmp Frame.value
  beq same
emit:
  lda Frame.count
  sta wram(hdma_obsel),x
  inx
  lda Frame.value
  sta wram(hdma_obsel),x
  inx
  cpy Frame.last
  bne run
last_run:
  lda #1                        ; Y = Frame.last
  sta wram(hdma_obsel),x
  inx
  jsr obsel_value
  sta wram(hdma_obsel),x
  inx
  lda #$00                      ; end of table
  sta wram(hdma_obsel),x
  .leave
  rts

; OBSEL value for line Y
obsel_value:
  .as
  .xl
  lda [Frame.p_src],y
  and #$03
  asl
  asl
  asl
  ora #OBSEL_PAGE0
  rts
.endblock

; set_bar_color: build the selection bar tables (HDMA channels 5 and 6)
; from the cursor asset at crsr_ptr; the NMI fills in the lines above the
; bar (bytes 0 and 3 of both tables)
; params: p_variant: 0: normal, 1: active (editing a value)
; keeps X and Y
set_bar_color .block
  .virtual #0,d
Frame .block
  src           .long ?         ; cursor asset
  lines         .word ?         ; bar lines left
  _             .dstruct SaveJSR
  p_variant     .byte ?
.endblock
  .endvirtual
  .enter
  rep #$30
  .al
  .xl
  phx
  phy
  lda wram(crsr_ptr)
  sta Frame.src
  lda wram(crsr_ptr+1)
  sta Frame.src+1
  lda [Frame.src]               ; height (low byte), first line (high byte)
  sep #$20
  .as
  xba
  sta wram(bar_yoffset)
  xba
  rep #$20
  .al
  and #$00ff
  sta Frame.lines
  ldy #$0002                    ; the records of variant 0 follow
  lda Frame.p_variant
  and #$00ff
  beq +
  lda Frame.lines               ; variant 1: after h records of 4 bytes
  asl
  asl
  adc #$0002
  tay
+ sep #$20
  .as
  lda Frame.lines
  ora #$80                      ; repeat mode: one record per line
  sta wram(hdma_bar1+6)
  sta wram(hdma_bar2+6)
  lda #$00
  sta wram(hdma_bar1+1)         ; lines above the bar: no color math,
  sta wram(hdma_bar1+2)         ; COLDATA without a color selected
  sta wram(hdma_bar1+4)
  sta wram(hdma_bar1+5)
  sta wram(hdma_bar2+1)
  sta wram(hdma_bar2+2)
  sta wram(hdma_bar2+4)
  sta wram(hdma_bar2+5)
  rep #$20
  .al
  ldx #$0000
- lda [Frame.src],y             ; CGADSUB, first COLDATA
  sta wram(hdma_bar1+7),x
  iny
  iny
  lda [Frame.src],y             ; second and third COLDATA
  sta wram(hdma_bar2+7),x
  iny
  iny
  inx
  inx
  dec Frame.lines
  bne -
  lda #$0001                    ; after the bar: 1 line without color math
  sta wram(hdma_bar1+7),x       ; and black, then the end of the table
  sta wram(hdma_bar2+7),x
  lda #$00e0
  sta wram(hdma_bar1+9),x
  lda #$0000
  sta wram(hdma_bar2+9),x
  ply
  plx
  .leave
  rts
.endblock


; all sprites small and below the screen (for both sprite sizes)
clear_oam:
  php
  sep #$20
  .as
  rep #$10
  .xl
  ldx #$0000
  stx $2102
  ldx #128
- stz $2104     ; X
  lda #224
  sta $2104     ; Y
  stz $2104     ; tile
  stz $2104     ; attributes
  dex
  bne -
  ldx #32
- stz $2104     ; X bit 8, size: small
  dex
  bne -
  plp
  rts

; apply the default skin, then the skin from the SD card (unless skin_skip)
; NMI must be off and the screen in forced blank
apply_skin:
  php
  sep #$20
  .as
  rep #$10
  .xl
  lda #`default_skin
  .param pha
  .param pea, <>default_skin
  .param pea, default_skin_end - default_skin
  .call walk_skin
  .unparam walk_skin
  lda @l skin_skip
  bne +
  lda #`SKIN_ADDR
  .param pha
  .param pea, <>SKIN_ADDR
  .param pea, SKIN_MAX_SIZE
  .call walk_skin
  .unparam walk_skin
+
  lda #$00                      ; normal selection bar
  .param pha
  .call set_bar_color
  .unparam set_bar_color
  plp
  rts

; apply the chunks of a skin. Chunks with an unknown ID or version, or a
; payload of the wrong size for their asset, are skipped; the walk ends at
; the first header without "SNS" or at a chunk that does not fit.
; NMI must be off and the screen in forced blank.
; params: p_src (long): first chunk, p_size: bytes from there (the chunks
;         must not cross a bank boundary)
walk_skin .block
  .virtual #0,d
Frame .block
  ptr           .long ?         ; current chunk, then its payload
  len           .word ?         ; payload length
  left          .word ?         ; bytes after the current chunk
  id            .dword ?        ; ID of the current chunk
  version       .word ?         ; "S", version
  src           .word ?         ; handlers: source address
  size          .word ?         ; handlers: size
  count         .word ?         ; handlers: number of items
  sprites       .word ?         ; OAMT: number of sprites
  _             .dstruct SaveJSR
  p_size        .word ?
  p_src         .long ?         ; pushed first (bank, then address)
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  phb
  lda #$00                      ; the handlers access the PPU and DMA
  pha                           ; registers with absolute addresses
  plb
  rep #$30
  .al
  .xl
  lda Frame.p_src
  sta Frame.ptr
  lda Frame.p_src+1
  sta Frame.ptr+1
  lda Frame.p_size
  sta Frame.left
next:
  lda Frame.left
  sec
  sbc #SKIN_HEADER_SIZE
  bcc done                      ; no room for a header
  sta Frame.left
  lda [Frame.ptr]
  cmp #'S' | 'N' << 8
  bne done
  ldy #$0002
  lda [Frame.ptr],y
  sta Frame.version
  and #$00ff
  cmp #'S'
  bne done
  ldy #$0004
  lda [Frame.ptr],y
  sta Frame.id
  ldy #$0006
  lda [Frame.ptr],y
  sta Frame.id+2
  ldy #$000a
  lda [Frame.ptr],y             ; length, high word
  bne done                      ; longer than any skin
  dey
  dey
  lda [Frame.ptr],y             ; length, low word
  sta Frame.len
  lda Frame.left
  sec
  sbc Frame.len
  bcc done                      ; the payload does not fit
  sta Frame.left
  lda Frame.ptr
  clc
  adc #SKIN_HEADER_SIZE
  sta Frame.ptr                 ; the payload
  lda Frame.version
  and #$ff00
  cmp #SKIN_VERSION << 8
  bne skip
  ldx #$0000
find:
  lda @l chunk_types,x
  beq skip                      ; unknown ID
  cmp Frame.id
  bne +
  lda @l chunk_types+2,x
  cmp Frame.id+2
  beq found
+ txa
  clc
  adc #6
  tax
  bra find
found:
  jsr (chunk_types+4,x)
  rep #$30
  .al
  .xl
skip:
  lda Frame.ptr
  clc
  adc Frame.len
  sta Frame.ptr
  brl next
done:
  plb
  .leave
  rts

chunk_types:
  .text "CGEN"
  .word <>cgen
  .text "FONT"
  .word <>font
  .text "LOGO"
  .word <>logo
  .text "GRAD"
  .word <>grad
  .text "CRSR"
  .word <>crsr
  .text "OAMT"
  .word <>oamt
  .word 0

; The handlers run in the frame of walk_skin with A, X and Y 16-bit; they
; check the payload (Frame.ptr, Frame.len) and apply it.

; palette: first color, number of colors, colors
cgen:
  .al
  .xl
  lda [Frame.ptr]               ; first color
  cmp #256
  bcs cgen_out
  ldy #$0002
  lda [Frame.ptr],y             ; number of colors
  beq cgen_out
  sta Frame.count
  clc
  adc [Frame.ptr]
  cmp #257
  bcs cgen_out                  ; beyond color 255
  lda Frame.count
  asl
  sta Frame.size
  adc #$0004
  cmp Frame.len
  bne cgen_out
  lda Frame.ptr
  clc
  adc #$0004
  sta Frame.src
  sep #$20
  .as
  lda [Frame.ptr]
  sta $2121
  .DMA7 #$00, Frame.size, Frame.ptr+2, Frame.src, #$22
cgen_out:
  rts

; font: FONT_SIZE bytes
font:
  .al
  .xl
  lda Frame.len
  cmp #FONT_SIZE
  bne +
  ldx #FONT_BASE
  stx $2116
  .DMA7 #$01, #FONT_SIZE, Frame.ptr+2, Frame.ptr, #$18
+ rts

; logo: LOGO_SIZE bytes
logo:
  .al
  .xl
  lda Frame.len
  cmp #LOGO_SIZE
  bne +
  ldx #LOGO_BASE
  stx $2116
  .DMA7 #$01, #LOGO_SIZE, Frame.ptr+2, Frame.ptr, #$18
+ rts

; background gradient: GRAD_SIZE bytes
grad:
  .al
  .xl
  lda Frame.len
  cmp #GRAD_SIZE
  bne +
  sep #$20
  .as
  lda Frame.ptr+2
  .param pha
  .param pei, (Frame.ptr)
  .call build_grad
  .unparam build_grad
+ rts

; selection bar: height, first line, 2 * height records of 4 bytes
crsr:
  .al
  .xl
  lda [Frame.ptr]
  and #$00ff
  beq +
  cmp #BAR_MAX_LINES+1
  bcs +
  asl
  asl
  asl
  adc #$0002                    ; (carry clear)
  cmp Frame.len
  bne +
  lda Frame.ptr
  sta wram(crsr_ptr)
  lda Frame.ptr+1
  sta wram(crsr_ptr+1)
+ rts

; sprites: number of tiles (16 bits), number of sprites, 0, sprite page per
; line, OAM entries (4 bytes each), their OAM high table bits (2 bits each),
; tiles from OBJ_FIRST_TILE on (32 bytes each)
oamt:
  .al
  .xl
  lda [Frame.ptr]               ; tiles
  cmp #OAMT_MAX_TILES+1
  .jcs oamt_out
  sta Frame.count
  ldy #$0002
  lda [Frame.ptr],y             ; sprites
  and #$00ff
  cmp #OAMT_MAX_SPRITES+1
  .jcs oamt_out
  sta Frame.sprites
  asl                           ; size: OAMT_HEAD_SIZE + 4 * sprites
  asl                           ;  + (sprites + 3) / 4 + 32 * tiles
  sta Frame.size
  lda Frame.sprites
  adc #3                        ; (carry clear)
  lsr
  lsr
  clc
  adc Frame.size
  adc #OAMT_HEAD_SIZE
  sta Frame.size
  lda Frame.count
  .rept 5
  asl
  .endrept
  adc Frame.size                ; (carry clear: at most 30720)
  cmp Frame.len
  .jne oamt_out
; sprite pages
  lda Frame.ptr
  clc
  adc #$0004
  sta Frame.src
  sep #$20
  .as
  lda Frame.ptr+2
  .param pha
  .param pei, (Frame.src)
  .call build_obsel
  .unparam build_obsel
; OAM
  jsr clear_oam
  rep #$20
  .al
  lda Frame.ptr
  clc
  adc #OAMT_HEAD_SIZE
  sta Frame.src
  lda Frame.sprites
  beq +
  asl
  asl
  sta Frame.size
  ldx #$0000
  stx $2102
  .DMA7 #$00, Frame.size, Frame.ptr+2, Frame.src, #$04
  .al                           ; (.DMA7 restores P)
  lda Frame.src                 ; OAM high table
  clc
  adc Frame.size
  sta Frame.src
  lda Frame.sprites
  clc
  adc #3
  lsr
  lsr
  sta Frame.size
  ldx #$0100
  stx $2102
  .DMA7 #$00, Frame.size, Frame.ptr+2, Frame.src, #$04
  .al                           ; (.DMA7 restores P)
  lda Frame.src
  clc
  adc Frame.size
  sta Frame.src                 ; tiles
; tiles
+ ldx #OBJ_TILE_BASE+OBJ_FIRST_TILE*16
  stx $2116
  .DMA7 #$09, #OAMT_MAX_TILES*32, #`zero, #<>zero, #$18
  .al                           ; (.DMA7 restores P)
  lda Frame.count
  beq oamt_out
  .rept 5
  asl
  .endrept
  sta Frame.size
  ldx #OBJ_TILE_BASE+OBJ_FIRST_TILE*16
  stx $2116
  .DMA7 #$01, Frame.size, Frame.ptr+2, Frame.src, #$18
oamt_out:
  rts
.endblock

; ---------------------------------------------------------------------------
; skin selection: skin files in the file browser (context menu) and the
; configuration menu

SKIN_ACTION_PREVIEW = 1         ; skin_action: set by the menu functions and
SKIN_ACTION_USE = 2             ; carried out after the menu has closed
SKIN_ACTION_CHOOSE = 3

; menu functions (entered with RTL, A 8-bit, DB = bank of the menu table)
skin_menu_preview:
  .as
  .xl
  lda #SKIN_ACTION_PREVIEW
  sta wram(skin_action)
  rtl

skin_menu_use:
  .as
  .xl
  lda #SKIN_ACTION_USE
  sta wram(skin_action)
  rtl

skin_menu_choose:
  .as
  .xl
  lda #SKIN_ACTION_CHOOSE
  sta wram(skin_action)
  lda #$01                      ; back to the file browser
  sta wram(menu_close_all)
  rtl

skin_menu_builtin:
  .as
  .xl
  lda #SKIN_SRC_BUILTIN
  jsr skin_set
  rtl

; select a skin (A: SKIN_SRC_SELECTED, the file in MCU_PARAM, or
; SKIN_SRC_BUILTIN) and apply it
skin_set:
  php
  sep #$20
  .as
  rep #$10
  .xl
  sta @l MCU_PARAM+8
  lda #CMD_SET_SKIN
  jsr skin_cmd
  lda #$00                      ; a skin chosen in the menu counts even if
  sta wram(skin_skip)           ; SELECT was held at power-on
  jsr reapply_skin
  plp
  rts

; show the skin selected in the file browser (MCU_PARAM) until A (use it)
; or B (back to the skin from before)
skin_preview .block
  php
  phb
  sep #$20
  .as
  rep #$10
  .xl
  lda #$00
  pha
  plb
  lda skin_skip                 ; restored for B
  pha
  lda #SKIN_SRC_SELECTED
  sta @l MCU_PARAM+8
  lda #CMD_LOAD_SKIN
  jsr skin_cmd
  stz skin_skip
  jsr filesel_set_bar           ; (the closed menu had the bar)
  jsr reapply_skin
  .print_at space64, 0, 28, 0, 64
  .print_at text_skin_preview_bar, 2, 28, 0, 64
wait:
  lda isr_done
  beq wait
  stz isr_done
  jsr printtime
  jsr read_pad
  lda pad_a
  bne use
  lda pad_b
  beq wait
  pla
  sta skin_skip
  lda #SKIN_SRC_CONFIG
  sta @l MCU_PARAM+8
  lda #CMD_LOAD_SKIN
  jsr skin_cmd
  jsr reapply_skin
  bra done
use:
  pla
  lda #SKIN_SRC_SELECTED        ; the skin is shown already
  sta @l MCU_PARAM+8
  lda #CMD_SET_SKIN
  jsr skin_cmd
done:
  .print_at space64, 0, 28, 0, 64
  jsr filesel_statusbar
  plb
  plp
  rts
.endblock

; send the skin command in A (CMD_LOAD_SKIN, CMD_SET_SKIN) to the MCU and
; wait for it in WRAM with NMI off: the MCU loads the skin by SD DMA, which
; takes over the cart memory bus, so the CPU must not read from it (NMI
; vector and handler) until the MCU is done. The HDMA tables are in WRAM.
skin_cmd:
  php
  sep #$20
  .as
  sei
  pha
  lda #$00
  sta @l $004200                ; no NMI
  pla
  jsl wram_mcu_cmd
  jsr waitblank                 ; the first NMI at the start of VBlank
  lda #$81
  sta @l $004200                ; VBlank NMI + auto joypad read
  plp
  rts

; apply the skins again after the MCU has loaded another one. The screen
; goes black for a moment: NMI and HDMA are off meanwhile (HDMA would change
; CGADD during the palette upload).
reapply_skin:
  php
  sep #$20
  .as
  rep #$10
  .xl
  jsr waitblank
  lda #$80
  sta @l $002100                ; forced blank
  lda #$00
  sta @l $004200
  sta @l $00420c
  jsr apply_skin
  jsr waitblank
  lda #$7f
  sta @l $00420c                ; HDMA ch. 0-6, as setup_hdma
  lda #$81
  sta @l $004200                ; VBlank NMI + auto joypad read
  lda wram(cur_bright)
  sta @l $002100
  plp
  rts

  .section databank
  .include "skin/default.asm"
  .send databank

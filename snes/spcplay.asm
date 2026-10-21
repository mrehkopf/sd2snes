; SPC Player
; SPC700 transfer and IO routines by Shay Green <gblargg@gmail.com>
; minor corrections by Maximilian Rehkopf <otakon@gmx.net>

spcplayer:
  php
  sep #$30
  .as
  .xs

  ldx #$0a            ; Check if SPC header is present
-
  lda @l SPC_HEADER,x
  cmp @l text_spcid,x
  beq +
  jmp spc_exit
+
  dex
  bne -

  rep #$10            ; Now draw lots of stuff
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

  stz bar_wl
  dec bar_wl
  stz bar_xl
  dec bar_xl
  stz bar_yl
  dec bar_yl

  lda #`text_spcplay  ; Loading window
  sta window_tbank
  ldx #<>text_spcplay
  stx window_taddr
  lda @l spcplay_win_x
  sta window_x
  lda @l spcplay_win_y
  sta window_y
  lda @l spcplay_win_w
  sta window_w
  lda @l spcplay_win_h
  sta window_h
  jsr draw_window

  .print_at text_spcload, 17, 16, 0, 29 ; Loading text

  stz isr_done
-
  lda isr_done        ; Wait until text is being printed...
  beq -

  jsr spc700_load     ; Load SPC into SPC700

  lda #`text_spcplay
  sta window_tbank
  ldx #<>text_spcplay
  stx window_taddr
  lda @l spcstart_win_x
  sta window_x
  lda @l spcstart_win_y
  sta window_y
  lda @l spcstart_win_w
  sta window_w
  lda @l spcstart_win_h
  sta window_h
  jsr draw_window

  .print_at text_spcstarta, 17, 15, 1, 30
  .print_at text_spcstartb, 12, 17, 1, 7
  .print_at SPC_HEADER+$4e, 20, 17, 0, 32  ; game title
  .print_at text_spcstartc, 12, 18, 1, 7
  .print_at SPC_HEADER+$2e, 20, 18, 0, 32  ; song title
  .print_at text_spcstartd, 12, 19, 1, 7

  ldx #<>SPC_HEADER+$b0         ; artist: $b0 (binary ID666) or $b1 (text)
  lda @l SPC_HEADER+$b0
  cmp #$41
  bpl +
  inx
+ lda #`SPC_HEADER
  .param pha
  .param phx
  lda #20
  .param pha
  lda #19
  .param pha
  lda #$00
  .param pha
  lda #32
  .param pha
  .call print_text
  .unparam print_text

spc_playloop:
  lda isr_done        ; SPC player loop
  lsr
  bcc spc_playloop
  jsr printtime
  stz isr_done

  jsr read_pad
  lda pad_b
  bne spc_key_b
  bra spc_playloop

spc_key_b:
  rep #$20
  .al
  tsc
  sta @l SAVED_SP      ; Save SP for later re-entry
  lda #$fa50           ; Write reset signature
  sta @l WARM_SIGNATURE
  eor #$ffff
  sta @l WARM_COMPLEMENT
  sep #$20
  .as

; Blank screen & issue CMD_RESET command to Microcontroller...
; ...this is required because there is no other way to stop S-SMP & S-DSP
  sei
  stz $2100
  jsr pop_window
  jsr backup_wram     ; Save menu state in case it gets overwritten by Ultra16
                      ; or other malware :P
  lda #CMD_RESET
  sta @l MCU_CMD
-
; At this point, the SNES waits for an external reset from the Microcontroller
  bra -

spc_exit:             ; Return from player in case of wrong SPC file data
  plp
  rts

;---------------------------------------
spc700_load:
  php
  sep #$20
  .as
  rep #$10
  .xl

  lda #NMITIMEN & ~$80 ; no NMI: the SPC player code is really timing
  sta $4200           ; sensitive ;) The H/V timer IRQ stays on for the
  cli                 ; sprite pages: the transfer routine leaves time for
                      ; it, and the timed parts mask it (exec_instr)
  jsr upload_dsp_regs ; Upload S-DSP registers
  jsr upload_high_ram ; Upload 63.5K of SPC700 ram
  jsr upload_low_ram  ; Upload rest of ram
  jsr restore_final   ; Restore SPC700 state & start execution
  lda #NMITIMEN       ; VBlank NMI, H/V timer IRQ, Auto Joypad Read
  sta $4200           ; enable V-BLANK NMI
  cli
  plp
  rts
;---------------------------------------
; Uploads DSP registers and some other setup code
upload_dsp_regs:

; ---- Begin upload

  ldy #$0002
  jsr spc_begin_upload

; ---- Upload loader

  ldx #$0000
-
  lda @l spc_loader,x
  jsr spc_upload_byte
  inx
  cpy #31             ; size of loader
  bne -

; ---- Upload SP, PC & PSW

  lda @l SPC_HEADER+43
  jsr spc_upload_byte
  lda @l SPC_HEADER+38
  jsr spc_upload_byte
  lda @l SPC_HEADER+37
  jsr spc_upload_byte
  lda @l SPC_HEADER+42
  jsr spc_upload_byte

; ---- Upload DSP registers

  ldx #$0000
-
; ---- initialize FLG and KON ($6c/$4c) to avoid artifacts
; (ikari_01)
  cpx #$4c
  bne +
  lda #$00
  bra upload_skip_load
+
  cpx #$6c
  bne +
  lda #$e0
  bra upload_skip_load
+
  lda @l SPC_DSP_REGS,x
upload_skip_load:
  jsr spc_upload_byte
  inx
  cpx #128
  bne -

; --- Upload fixed values for $F1-$F3

  ldy #$00f1
  jsr spc_next_upload

  lda #$80            ; stop timers
  jsr spc_upload_byte
  lda #$6c            ; get dspaddr set for later
  jsr spc_upload_byte
  lda #$60
  jsr spc_upload_byte

; ---- Upload $f8-$1ff

  ldy #$00f8
  jsr spc_next_upload

  ldx #$00f8
-
  lda @l SPC_DATA,x
  jsr spc_upload_byte
  inx
  cpx #$200
  bne -

; ---- Execute loader

  ldy #$0002
  jsr spc_execute
  rts
;---------------------------------------
upload_high_ram:

  ldy #$0002
  jsr spc_begin_upload

; ---- Upload transfer routine

  ldx #$0000
-
  lda @l spc_transfer,x
  jsr spc_upload_byte
  inx
  cpy #spc_transfer.size
  bne -

; ---- Execute transfer routine

  ldy #$0002
  sty APUIO2
  stz APUIO1
  lda APUIO0
  inc a
  inc a
  sta APUIO0
; Wait for acknowledgement
-
  cmp APUIO0
  bne -

; ---- Burst transfer of $0200-$FFFF (see spc_transfer)

  jsr spc_burst
  rts

; three bytes per chunk, one from each third of $0200-$FFFF, and a counter
; (spc_transfer); the next chunk is ready while the SPC700 stores this one
spc_burst .block
  .virtual #0,d
Frame .block
  count         .byte ?         ; counter of the chunk the SPC700 has
  _             .dstruct SaveJSR
.endblock
  .endvirtual
  .enter
  sep #$20
  .as
  rep #$10
  .xl
  ldx #$00ff                    ; offset in the thirds; its low byte: counter
  jsr prep
send:
  rep #$20
  .al
  sta APUIO0                    ; ports 0 and 1: the first two thirds
  sty APUIO2                    ; port 2: the last third, port 3: the counter
  sep #$20
  .as
  txa
  sta Frame.count
  bne +
  rep #$20                      ; last chunk of a page: on to the next page
  .al
  txa
  clc
  adc #$01ff
  tax
  sep #$20
  .as
  cpx #85 * $100 + $ff
  beq last
  bra ++
+ dex
+ jsr prep
  pha                           ; (the byte for port 0)
- lda APUIO3                    ; the SPC700 is done with the chunk
  cmp Frame.count
  bne -
  pla
  bra send
last:
- lda APUIO3
  cmp Frame.count
  bne -
  .leave
  rts

; the chunk at offset X: A (16-bit) the bytes of the first two thirds, Y the
; byte of the last third and the counter
prep:
  .as
  .xl
  lda @l SPC_DATA+$ab00,x
  xba
  txa
  xba
  rep #$20
  .al
  tay
  sep #$20
  .as
  lda @l SPC_DATA+$5700,x
  xba
  lda @l SPC_DATA+$0200,x
  rts
.endblock

;---------------------------------------
upload_low_ram:

; ---- Upload $0002-$00EF using IPL

  ldy #$0002
  jsr spc_begin_upload

  ldx #$0002
-
  lda @l SPC_DATA,x
  jsr spc_upload_byte
  inx
  cpx #$00f0
  bne -
  rts
;---------------------------------------
; Executes final restoration code
restore_final:
  jsr start_exec_io   ; prepare execution from I/O registers

  stz $420d           ; SPC700 I/O code requires SLOW timing

; ---- Restore first two bytes of RAM

  lda @l SPC_DATA
  xba
  lda #$e8            ; MOV A,#@SPC_DATA
  tax
  jsr exec_instr
  ldx #$00c4          ; MOV $00,A
  jsr exec_instr

  lda @l SPC_DATA+1
  xba
  lda #$e8            ; MOV A,#@SPC_DATA+1
  tax
  jsr exec_instr
  ldx #$01c4          ; MOV $01,A
  jsr exec_instr

; ---- Restore SP

  lda @l SPC_HEADER+43
  sec
  sbc #3
  xba
  lda #$cd            ; MOV X,#@SPC_HEADER+43
  tax
  jsr exec_instr
  ldx #$bd            ; MOV SP,X
  jsr exec_instr

; ---- Restore X

  lda @l SPC_HEADER+40
  xba
  lda #$cd            ; MOV X,#@SPC_HEADER+40
  tax
  jsr exec_instr

; ---- Restore Y

  lda @l SPC_HEADER+41
  xba
  lda #$8d            ; MOV Y,#@SPC_HEADER+41
  tax
  jsr exec_instr

; ---- Restore DSP FLG register

  lda @l SPC_DSP_REGS+$6c
  xba
  lda #$e8            ; MOV A,#@SPC_DSP_REGS+$6c
  tax
  jsr exec_instr
  ldx #$f3c4          ; MOV $f3,A -> $f2 has been set-up before by SPC700 loader
  jsr exec_instr

; ---- wait a bit (the newer S-APU takes its time to ramp up the volume)
; (ikari_01)
  lda #$10
- pha
  jsr waitblank
  pla
  dec a
  bne -

; ---- Restore DSP KON register

  lda #$4c
  xba
  lda #$e8            ; MOV A,#$4c
  tax
  jsr exec_instr
  ldx #$f2c4          ; MOV $f2,A
  jsr exec_instr
  lda @l SPC_DSP_REGS+$4c
  xba
  lda #$e8            ; MOV A,#@SPC_DSP_REGS+$4c
  tax
  jsr exec_instr
  ldx #$f3c4          ; MOV $f3,A
  jsr exec_instr

; ---- Restore DSP register address

  lda @l SPC_DATA+$f2
  xba
  lda #$e8            ; MOV A,#@SPC_DATA+$F2
  tax
  jsr exec_instr
  ldx #$f2c4          ; MOV dest,A
  jsr exec_instr

; ---- Restore CONTROL register

  lda @l SPC_DATA+$f1
  and #$cf            ; don't clear input ports
  xba
  lda #$e8            ; MOV A,#@SPC_DATA+$F1
  tax
  jsr exec_instr
  ldx #$f1c4          ; MOV $F1,A
  jsr exec_instr

;---- Restore A

  lda @l SPC_HEADER+39
  xba
  lda #$e8            ; MOV A,#@SPC_HEADER+39
  tax
  jsr exec_instr

;---- Restore PSW and PC

  php                 ; no IRQ until the ports are restored
  sei
  ldx #$7f00          ; NOP; RTI
  stx APUIO0
  lda #$fc            ; Patch loop to execute instruction just written
  sta APUIO3

;---- restore IO ports $f4 - $f7

  rep #$20
  .al
  lda @l SPC_DATA+$f4
  tax
  lda @l SPC_DATA+$f6
  sta APUIO2
  stx APUIO0          ; last to avoid overwriting RETI before run
  plp
  sep #$20
  .as

  lda #$01
  sta $420d           ; restore FAST CPU operation
  rts
;---------------------------------------
spc_begin_upload:
  sty APUIO2          ; Set address
  ldy #$bbaa          ; Wait for SPC
-
  cpy APUIO0
  bne -
  lda #$cc            ; Send acknowledgement
  sta APUIO1
  sta APUIO0
-                     ; Wait for acknowledgement
  cmp APUIO0
  bne -
  ldy #0              ; Initialize index
  rts
;---------------------------------------
spc_upload_byte:
  sta APUIO1
  tya                 ; Signal it's ready
  sta APUIO0
-                     ; Wait for acknowledgement
  cmp APUIO0
  bne -
  iny
  rts
;---------------------------------------
spc_next_upload:
  sty APUIO2
; Send command
; Special case operation has been fully tested.
  lda APUIO0
  inc a
  inc a
  bne +
  inc a
+
  sta APUIO1
  sta APUIO0

; Wait for acknowledgement
-
  cmp APUIO0
  bne -
  ldy #0
  rts
;---------------------------------------
spc_execute:
  sty APUIO2
  stz APUIO1
  lda APUIO0
  inc a
  inc a
  sta APUIO0

; Wait for acknowledgement
-
  cmp APUIO0
  bne -

  rts
;---------------------------------------
start_exec_io:
; Set execution address
  ldx #$00f5
  stx APUIO2

  stz APUIO1          ; NOP
  ldx #$fe2f          ; BRA *-2

; Signal to SPC that we're ready
  lda APUIO0
  inc a
  inc a
  sta APUIO0

; Wait for acknowledgement
-
  cmp APUIO0
  bne -

; Quickly write branch
  stx APUIO2

  rts
;---------------------------------------
exec_instr:
; Replace instruction
  stx APUIO0
  php                 ; no IRQ from here to the second write to APUIO3:
  sei                 ; the SPC700 must not run the instruction twice
  lda #$fc
  sta APUIO3          ; 30

; SPC BRA loop takes 4 cycles, so it reads
; the branch offset every 4 SPC cycles (84 master).
; We must handle the case where it read just before
; the write above, and when it reads just after it.
; If it reads just after, we have at least 7 SPC
; cycles (147 master) to change restore the branch
; offset.

; 48 minimum, 90 maximum
  ora #0
  ora #0
  ora #0
  nop
  nop
  nop

; 66 delay, about the middle of the above limits
  phd                 ; 4
  pld                 ; 5

; Give plenty of extra time if single execution
; isn't needed, as this avoids such tight timing
; requirements.

  phd                 ; 4
  pld                 ; 5
  phd                 ; 4
  pld                 ; 5

; Patch loop to skip first two bytes
  lda #$fe            ; 16
  sta APUIO3          ; 30
  plp

; 38 minimum (assuming 66 delay above)
  phd                 ; 4
  pld                 ; 5
; Give plenty of extra time if single execution
; isn't needed, as this avoids such tight timing
; requirements.
  phd
  pld
  phd
  pld
  rts

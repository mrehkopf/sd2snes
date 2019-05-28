org !SS_CODE
print "Savestate Bank Starting at: ", pc

.text
start:
  jmp .ss_init

.save_write_table
  ; Disable DMA
  dw $1000|$420B, $00
  dw $1000|$420C, $00
  ; Turn PPU off
  dw $1000|$2100, $80
  ; temp
  dw $0000|$2116, $0000  ; VRAM address >> 1.
  dw $8000|$2139, $0000  ; VRAM dummy read.
  ; Done
  dw $0000, .save_return

.load_write_table
  ; Disable DMA
  dw $1000|$420B, $00
  dw $1000|$420C, $00
  ; Turn PPU off
  dw $1000|$2100, $80
  ; Single address, A bus -> B bus.  B address = reflector to WRAM ($2180).
  dw $0000|$4310, $8000  ; direction = A->B, B addr = $2180
  ; Copy F00000-F0FFFF to WRAM 7E0000-7EFFFF.
  dw $0000|$4312, $0000  ; A addr = $xx0000
  dw $0000|$4314, $00F0  ; A addr = $F0xxxx, size = $xx00
  dw $0000|$4316, $0000  ; size = $00xx ($0000), unused bank reg = $00.
  dw $0000|$2181, $0000  ; WRAM addr = $xx0000
  dw $1000|$2183, $00    ; WRAM addr = $7Exxxx  (bank is relative to $7E)
  dw $1000|$420B, $02    ; Trigger DMA on channel 1
  ; Copy F10000-F1FFFF to WRAM 7F0000-7FFFFF.
  dw $0000|$4312, $0000  ; A addr = $xx0000
  dw $0000|$4314, $00F1  ; A addr = $F1xxxx, size = $xx00
  dw $0000|$4316, $0000  ; size = $00xx ($0000), unused bank reg = $00.
  dw $0000|$2181, $0000  ; WRAM addr = $xx0000
  dw $1000|$2183, $01    ; WRAM addr = $7Fxxxx  (bank is relative to $7E)
  dw $1000|$420B, $02    ; Trigger DMA on channel 1
  ; Address pair, A bus -> B bus.  B address = VRAM write ($2118).
  dw $0000|$4310, $1801  ; direction = A->B, B addr = $2118
  dw $1000|$2115, $80    ; VRAM address increment mode.
  ; Copy F20000-F2FFFF to VRAM 0000-FFFF.
  dw $0000|$2116, $0000  ; VRAM address >> 1.
  dw $0000|$4312, $0000  ; A addr = $xx0000
  dw $0000|$4314, $00F2  ; A addr = $F2xxxx, size = $xx00
  dw $0000|$4316, $0000  ; size = $00xx ($0000), unused bank reg = $00.
  dw $1000|$420B, $02    ; Trigger DMA on channel 1
  ; TODO: add audio
  ; Copy F40000-F401FF to CGRAM 000-1FF.
  dw $1000|$2121, $00    ; CGRAM address
  dw $0000|$4310, $2200  ; direction = A->B, byte reg, B addr = $2122
  dw $0000|$4312, $0000  ; A addr = $xx0000
  dw $0000|$4314, $00F4  ; A addr = $F4xxxx, size = $xx00
  dw $0000|$4316, $0002  ; size = $02xx ($0200), unused bank reg = $00.
  dw $1000|$420B, $02    ; Trigger DMA on channel 1
  ; Copy F40200-F4041F to OAM 000-21F.
  dw $0000|$2102, $0000  ; OAM address
  dw $0000|$4310, $0400  ; direction = A->B, byte reg, B addr = $2104
  dw $0000|$4312, $0200  ; A addr = $xx0200
  dw $0000|$4314, $20F4  ; A addr = $F4xxxx, size = $xx20
  dw $0000|$4316, $0002  ; size = $02xx ($0220), unused bank reg = $00.
  dw $1000|$420B, $02    ; Trigger DMA on channel 1
  ; Done
  dw $0000, .load_return

; general register restore
.register_restore_return
  %a8()
  %i16()

; restore $21XX
  ldx #$0002
  ldy #$0001

- cpy #$0002 : beq +
  cpy #$0003 : beq +
  cpy #$0004 : beq +
  cpy #$0018 : beq +
  cpy #$0019 : beq +
  cpy #$0022 : beq +

  lda !SRAM_PPU_BANK, x : sta $2100, y : inx
  lda !SRAM_PPU_BANK, x : sta $2100, y : dex

+ inx #2
  iny
  cpy #$0034
  beq +
  bra -

; restore $420X
+ ldx #$0001

- cpx #$0001 : beq +
  cpx #$000B : beq +
  cpx #$000C : beq +
  lda !SRAM_OTH_BANK, x
  sta $4200, x

+ inx
  cpx #$000E
  bne -
  
  %ai16()
  %load_registers()
  pld
  plb

  %a8()
  ; consume current NMI
  lda.l $004210
  
  ; align back with the NMI
  lda !SRAM_OTH_BANK
  and #$01
  ora #$80
  ;lda #$80
  sta.l $4200
  
- lda.l .CS_STATE
  cmp #$2
  bne -

  ; reset picture
  lda !SRAM_PPU_BANK
  sta.l $2100

  ; re-enable all interrupts
  lda !SRAM_OTH_BANK
  sta.l $4200
  ;lda !SRAM_OTH_BANK|$C
  ;stz $420C
  
; Code to run before returning back to the game
.ss_exit
  jmp.l hook_return
  ;rtl

.input_table
  ;  84218421 84210000
  ;  byetUDLR axlr0000
  ;
  ;  CKSUM  SAVE   LOAD
  ;dw $0325, $2080, $2020 ; CV4 (US) - leave as default since most people switch it
  ;dw $9324, $2080, $2020 ; CV4 (JP) - leave as default since most people switch it
  dw $2BCC, $0050, $0060 ; dkc1 v1.1 (US)
  dw $0C17, $0050, $0060 ; dkc1 v1.0 (JP)
  dw $9860, $0050, $0060 ; dkc2 (US)
  dw $35CE, $0050, $0060 ; dkc2 (JP)
  dw $B28C, $0050, $0060 ; dkc3 (US)
  dw $E545, $0050, $0060 ; dkc3 (JP)
  dw $F8DF, $6010, $6020 ; super metroid (*)
  dw $A0DA, $0050, $0060 ; smw (US)
  dw $8C80, $0050, $0060 ; smw (JP)
  dw $33C2, $1010, $1020 ; soe (US)
  ;dw $0C17, $0090, $00A0 ; super valis (US)
  ;dw $5B4C, $0090, $00A0 ; super valis (JP)

  dw $0000, $2010, $2020 ; default
  
; SMC (Self Modifying Code) to init on first pass
.ss_init
  %ai16()
  %save_registers()

  lda #.ss_start
  sta.l start+1

  %a8()
  ; save/load state machine
  lda #$00
  sta.l .CS_STATE
  
  ; rewrite inputs
  ldx #.input_table
- %a16()
  ; compare checksum
  lda.l !SS_FULL, x
  beq +
  cmp.l $00FFDE
  beq ++
  inx #6
  bra -
  
++ inx #2

  lda.l !SS_FULL, x : inx #2
  sta.l .CS_SAVE_INPUT

  lda.l !SS_FULL, x : inx #2
  sta.l .CS_LOAD_INPUT

  ;; change some games to use the hardware button capture
+ lda.l $00FFDE
  cmp #$783A : beq .controller_reg_patch ; claymates (US)
  cmp #$06D5 : beq .controller_reg_patch ; claymates (EU)
  cmp #$8FF5 : beq .controller_reg_patch ; FFMQ 1.1 (US)
  cmp #$4CDE : beq .controller_reg_patch ; FFMQ 1.0 (US)
  cmp #$0492 : beq .controller_reg_patch ; FFMQ 1.0 (JP)
  bra .button_reg_done
.controller_reg_patch
  lda #$0718
  sta.l .controller_reg+1
  %a8()
  lda #$F9
  sta.l .controller_reg+3
  %a16()
  
.button_reg_done
  lda #$0000
  sta.l .CS_SAVE_REQ
  %load_registers()
  
.ss_start
  %a8()  

  lda.l .CS_STATE
  beq +
  cmp #$01
  bne ++

  ;signal flag
  lda.l .CS_STATE
  inc
  sta.l .CS_STATE
  
  ; remove aligned NMI state from the stack.  this is pushed in hook.asm
  ; the fpga needs to be careful and not treat the nested NMI as an exit.
  ; a
  %a16() : pla
  ; p
  %a8() : pla

  lda $4210
  
  rti
  
++ inc
  ; skip 16 additional frames after last save to avoid blowing out the stack on nested handlers
  ; FIXME: get controls working where we don't repeat when holding buttons
  and #$0F
  sta.l .CS_STATE
  
; input handling
+ %ai16()
  ;%cgram()
  
  lda.l .CS_INPUT_CUR
  sta.l .CS_INPUT_PREV
.controller_reg
  lda.l .CS_INPUT_NEXT
  sta.l .CS_INPUT_CUR
  
  and.l .CS_SAVE_INPUT
  cmp.l .CS_SAVE_INPUT
  beq .save_state

  lda.l .CS_INPUT_CUR
  and.l .CS_LOAD_INPUT
  cmp.l .CS_LOAD_INPUT
  bne +
  jmp .load_state
  
  ; check programmable trigger
+ lda.l .CS_SAVE_REQ ; loads both
  beq .save_state_jump_exit
  phx
  tax
  lda #$0000
  sta.l .CS_SAVE_REQ
  txa
  plx
  and #$00FF
  bne .save_state
  jmp .load_state

.save_state_jump_exit
  jmp .ss_exit
  
.save_state
  ; check if this is SM
  %a16()
  lda.l $00FFDE
  cmp #$F8DF
  bne +
  ; if SM, check return address and make sure it's not in the sound loading code $808159-$808110
  lda 7,s
  cmp #$8059
  bcc +
  cmp #$8111
  bcs +
  %a8()
  bra .save_state_jump_exit
  
+ %a8()
  
  lda.l .CS_STATE
  bne .save_state_jump_exit
  inc
  sta.l .CS_STATE

  ; disable interrupts
  lda.l $F90700|$0000
  sta !SRAM_OTH_BANK
  and #$01
  sta.l $004200
  
  phb
  phd
  %ai16()
  %save_registers()
  
  %a8()
  
  ; disable DMA
  lda.l $F90700|$000C
  sta.l !SRAM_OTH_BANK|$C
  lda #$00
  sta.l $00420B
  sta.l $00420C
  
  ; save $21XX
+ %a8()
  ldy #$0000
  tyx

- lda.l $F90500|$0000, x : sta.l !SRAM_PPU_BANK, x : inx
  lda.l $F90500|$0000, x : sta.l !SRAM_PPU_BANK, x : inx
  iny
  cpy #$0040
  bne -
   
  ; save $420X
  %a8()
  ldx #$0001  

- lda.l $F90700|$0000, x
  sta.l !SRAM_OTH_BANK, x
-- inx
  cpx #$000C
  beq --
  cpx #$0010
  bne -
  
  ; save DMA registers
  %a8()
  ldy #$0000
  tyx
  
- lda.l $004300, x
  sta !SRAM_DMA_BANK, x
  inx
  iny
  cpy #$000B
  bne -
  cpx #$007B
  beq +
  inx #5
  ldy #$0000
  bra -
  
+ %ai16()
  ldy #.save_write_table

  ; run the unified VM. This covers save/load and all ROM mode types
.run_vm
  pea !SS_BANK
  plb
  plb
  jmp .vm
  
.save_return
  %ai16()

  ; copy region
  lda #$F5F0    ; srcBank:dstBank
  sta.l $002020
  lda #$0000    ; srcOffset
  sta.l $002022
  lda #$0000    ; dstOffset
  sta.l $002024
  lda #$0500    ; length[15:0]
  sta.l $002026
  %a8()
  lda #$04  ; length[23:16]
  sta.l $002028
  ; opcode[4:0], loop, dir, enable
  lda #$05
  sta.l $002029
  
  %a16()
  tsa
  sta.l !SRAM_SAVED_SP
  
  ;%cgram()
  
  %a8()
  pea $0000
  plb
  plb
 
  %a16()
  
  ;lda $2B00|$004E
  ;sta.l !SRAM_SAVED_40
  
  jmp .load_audio_start

.load_state_jump_exit
  jmp .ss_exit

.load_state
  ; check if this is SM
  %a16()
  lda.l $00FFDE
  cmp #$F8DF
  bne +
  ; if SM, check return address and make sure it's not in the sound loading code $808159-$808110
  lda 7,s
  cmp #$8059
  bcc +
  cmp #$8111
  bcs +
  %a8()
  bra .load_state_jump_exit

+ %a8()

  lda.l .CS_STATE
  bne .load_state_jump_exit
  inc
  sta.l .CS_STATE
  
  ; disable interrupts
  lda.l $F90700|$0000
  and #$01
  sta.l $4200
  
  phb
  phd
  %ai16()
  %save_registers()

  pea $0000
  plb
  plb

+ ldy #.load_write_table
  jmp .run_vm

.load_return
  %ai16()
  lda.l !SRAM_SAVED_SP
  tas
  
  pea $0000
  plb
  plb
  
  ; moved this up so we can reuse load_dma_regs for store
  %ai16()

.load_audio_start
  ldy #$0000
  phy
  ldx #.audio_table

- %a16()
  ; compare checksum
  lda.l !SS_FULL, x
  beq +
  cmp.l $00FFDE
  beq ++
  inx #8
  bra -
  
  ; set flag that we found patch
++ ply
  iny
  phy
  inx #2
  ; set offset
  lda.l !SS_FULL, x
  tay
  inx #2
 
  ; set bank
  lda.l !SS_FULL, x
  %a8()
  pha
  plb
  %a16()
  inx #2

  ; get source
  lda.l !SS_FULL, x
  phx
  ; test for constant outside of audio port range
  cmp #$2140
  bcc ++
  cmp #$2144
  bcs ++
  tax

  ; load source register
  %a8()
  lda.l $0000, x

++ %a8()
  sta $0000, y
  plx
  pea $0000
  plb
  plb
  inx #2
  
  bra -

  ; test for audio table matches
+ %a8()
  ply
  jmp .load_dma_regs_start

.audio_table
  ;  CKSUM  DST  SRC  
  dw $648D, $02F5,$00, $2140; super ghouls and ghosts (US)
  dw $FE0F, $02F5,$00, $2140; super ghouls and ghosts (US)
  dw $B6D4, $FFFB,$7E, $2140; final fight (US)
  dw $3288, $FFFB,$7E, $2140; final fight guy (US)
  dw $959E, $FFFB,$7E, $2140; final fight guy (JP)
  dw $A227, $FFFF,$7E, $2140; un squadron (US)
  dw $5B5A, $FFFF,$7E, $2140; un squadron/area88 (JP)
  dw $C47D, $FFFE,$7F, $2142; demon's crest (US)
  dw $2D7D, $FFFE,$7F, $2142; demon's crest (JP)
  dw $FE92, $FFFE,$7E, $2142; rockman & forte (JP)
  dw $F199, $FFFE,$7E, $2142; mm7 (US)
  dw $44D1, $FFFE,$7E, $2142; mm7 (JP)
  dw $4CC2, $FFFE,$7E, $2142; mmx1 v1.1 (US)
  dw $6569, $FFFE,$7E, $2142; mmx1 v1.0 (JP)
  dw $09B7, $FFFE,$7E, $2142; mmx2 (US)
  dw $8560, $FFFE,$7E, $2142; mmx2 (JP)
  dw $4055, $FFFE,$7E, $2142; mmx3 (US)
  dw $6BE2, $FFFE,$7E, $2142; mmx3 (JP)
  dw $060A, $0002,$00, $2142; aladdin (US)
  dw $5B9A, $0002,$00, $2142; aladdin (JP)
  dw $0B11, $FFFB,$7E, $2142; breath of fire 1 (US)
  dw $7C7D, $FFFC,$7E, $2142; breath of fire 2 (US)
  dw $2BCC, $0000,$00, $2140; dkc1 v1.1 (US)
  dw $0C17, $0000,$00, $2140; dkc1 v1.0 (JP)
  dw $9860, $0000,$00, $2140; dkc2 (US)
  dw $1202, $0000,$00, $2140; dkc2 1.0 (US)
  dw $35CE, $0000,$00, $2140; dkc2 (JP)
  dw $B28C, $0006,$00, $2140; dkc3 (US)
  dw $E545, $0006,$00, $2140; dkc3 (JP)
  dw $AD7F, $0000,$00, $2143; aliens 3 (US)
  dw $119A, $1CAD,$00, $2142; sf2 turbo - hyper fighting (US)
  dw $610A, $1D6B,$00, $2142; sf2 turbo - the new challenger (US)
  dw $3A88, $7F7E,$7F, $2142; sf2 - world fighter (US)
  dw $0A7D, $0676,$00, $2140; shaq-fu (US)
  dw $8C2C, $FFF8,$7E, $2140; super offroad - baja (US)
  dw $F50C, $001E,$00, $2143; zombies ate my neighbors (US)
  dw $5CBE, $1BFF,$00, $2140; super smash tv (US)
  dw $1B25, $0B0C,$00, $2143; super turrican 2 (US)
  dw $142F, $031B,$00,   $00; lost vikings 2 (US)
  dw $142F, $031C,$00,   $00; lost vikings 2 (US)
  dw $CAE6, $0624,$00, $2140; might and magic 3 (US)
  dw $CAE6, $0625,$00, $2141; might and magic 3 (US)
  dw $5AD0, $FF09,$7F, $2142; goof troop (US)
  dw $614A, $000A,$00, $2142; mickey's magical quest (US)
  dw $24DD, $0176,$7E, $2140; nosferatu (US) ; Something w/ interrupts going on in this game.
  dw $4D73, $0871,$7E, $2140; clock tower (JP)
  dw $64E9, $174B,$7E, $2142; ultimate mortal kombat 3 (US)
  
  ; FIXME add a common fix location that can be checked
  dw $0000, $0000,$00, $0000
  
.load_dma_regs_start
  %a8()
  ldx #$0000
  txy
  
- lda !SRAM_DMA_BANK, x
  sta $4300, x
  inx
  iny
  cpy #$000B
  bne -
  cpx #$007B
  beq +
  inx #5
  ldy #$0000
  bra -
  
  ; Restore registers and return.
+ jmp .register_restore_return
  
.vm
  ; Data format: xx xx yy yy
  ; xxxx = little-endian address to write to .vm's bank
  ; yyyy = little-endian value to write
  ; If xxxx has high bit set, read and discard instead of write.
  ; If xxxx has bit 12 set ($1000), byte instead of word.
  ; If yyyy has $DD in the low half, it means that this operation is a byte
  ; write instead of a word write.  If xxxx is $0000, end the VM.
  
  %a16();
  ; Read address to write to
  lda.w $0000, y
  beq .vm_done
  iny
  iny
  ; Check for read mode (high bit of address)
  ; Save off in carry flag for use later
  cmp.w #$8000
  and.w #$7FFF
  tax
  ; Check for byte mode
  bit.w #$1000
  beq .vm_word_mode
  and.w #$EFFF
  tax
  %a8();
.vm_word_mode
  ; Read value
  lda.w $0000, y
  iny
  iny
.vm_write
  bcs .vm_read
  sta $000000, x
  bra .vm
.vm_read
  ; "Subtract" $8000 from y by taking advantage of bank wrapping.
  lda $000000, x
  bra .vm

.vm_done
  ; A, X and Y are 16-bit at exit.
  ; Return to caller.  The word in the table after the terminator is the
  ; code address to return to.
  tyx
  jmp ($0002,x)

print "Savestate Bank Ending at: ", pc

; DATA
org !SS_DATA
print "Savestate Data Bank Starting at: ", pc
.data
; default to nonzero so we get through init
.CS_SAVE_REQ   db $01   ; $FC2000
.CS_LOAD_REQ   db $01   ; $FC2001
.CS_SAVE_INPUT dw $2010 ; $FC2002
.CS_LOAD_INPUT dw $2020 ; $FC2004

.CS_INPUT_NEXT dw $0000 ; $FC2006
.CS_INPUT_CUR  dw $0000
.CS_INPUT_PREV dw $0000
.CS_STATE      dw $0000

print "Savestate Data Bank Ending at: ", pc

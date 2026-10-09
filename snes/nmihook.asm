; *=$2A10
nmihook:
  php
  rep #$20
  .al
  pha
  lda @l $004218 ; initial backup as early as possible
  sta @l NMI_PAD
  sep #$20
  .as
nmi_branch1:
- bra -        ; branch1: filled in by FPGA
; rules for branch tgt:
;        if (buttons disabled OR manual read in progress) AND wram patching enabled: nmi_patches
;        if (buttons disabled OR manual read in progress) AND wram patching disabled: nmi_exit
;        if buttons enabled AND AJR enabled AND CMD != 0: nmi_echocmd
;        if buttons enabled AND AJR enabled AND CMD == 0 AND wram patching enabled: nmi_patches
;        if buttons enabled AND AJR enabled AND CMD == 0 AND wram patching disabled: nmi_exit
;        if buttons enabled AND AJR disabled: nmi_manual_read

; FPGA state:
;        - wram patching enabled (MCU side: cheats enabled AND wram cheats present) AND wram gate
;        - wram patching gate (FPGA side toggle)
;        - buttons enabled
;        - manual read in progress
;        - AJR enabled

; wram patching gate (same as cheat enable):
;        - if buttons enabled and CMD = $83: disable
;        - if buttons enabled and CMD = $82: enable

nmi_manual_read:
  phb
  phd
  lda #$2b
  xba
  lda #$00
  tcd
  phk
  plb
  lda #$01
  sta $4016
  stz $4016
  rep #$10
  .xl
  phx
  ldx #$0008
- lda $4016
  ror
  rol <NMI_PAD+1,d
  dex
  bne -
  ldx #$0008
- lda $4016
  ror
  rol <NMI_PAD,d
  dex
  bne -
  plx
  pld
  plb
; button combination -> command is mapped by FPGA
nmi_echocmd: ; echo cmd to MCU for misc handling
  lda @l NMI_CMD
  sta @l MCU_CMD
; 2nd branch point to determine whether to jump to WRAM cheats,
; halt system (for reset), or continue
nmi_branch2:
- bra - ; branch2: nmi_patches, nmi_savestate, nmi_stop, or nmi_exit
nmi_patches:
  jsr NMI_WRAM_CHEATS,k
nmi_branch3:
- bra - ; branch3: nmi_savestate or nmi_exit
nmi_savestate:
  jsl savestate_handler
nmi_exit:
; clean up
  rep #$20
  .al
  pla
  plp
  sta @l NMI_VECT_DISABLE
  jmp ($ff77) ; '77' is replaced by FPGA depending on hook entry

nmi_stop:
  sei
  sep #$20
  .as
  phk
  plb
  stz $4200
  lda #$80
  sta $2100
- bra -

resethook: ; EMULATION MODE
  .as
  .xs
  bra resethook_skip
  ; mask interrupt handler call
  sei
  ; x stores the count of scanlines
  ldx #$20
  ldy #$00
  ; setup irq on h-position $100.  this value was acquired via manual training
  lda #$00
  sta $4207
  inc a
  sta $4208
  lda #$10
  sta $4200
- wai
  ; sep seems to set the alignment correctly so an integer value in $4207/$4208 detects h-blank
  ; there seem to be more distinct phases now.  different padding may change this.
  sep #$20
  lda $4212
  ; ignore lines in v-blank
  bmi +
  ; decrement non-vblank scanlines encountered
  dex
  ; shift h-blank bit into upper position
  asl
  ; no error if not in h-blank
  bpl +
  ; increment error counter if h-blank is set (early h-blank)
  iny
  ; ack interrupt and check if we have hit all scanlines
+ lda $4211
  cpx #$00
  bne -
  ; stop interrupts and check if we have any errors
  stz $4200
  dex
  stx $4207
  dey
  bmi +
  ; perform reset
  lda #CMD_RESET_LOOP_FAIL
  sta @l MCU_CMD
- bra -
  ; clean up state
+ inx
  iny
resethook_skip:
  lda #CMD_RESET_LOOP_PASS
  sta @l MCU_CMD

resethook_loop:
- lda $4212
  bpl -
- lda $4212
  bmi -
  lda $213f
  bmi resethook_loop
  stz NMI_VECT_DISABLE
  jmp ($fffc)

nmihook_end:
.text "bram_end"

.cerror resethook - nmihook != BRAM_RESET_HOOK - BRAM_PAYLOAD, format("resethook must be at BRAM_RESET_HOOK (offset $%02x), but is at offset $%02x", BRAM_RESET_HOOK - BRAM_PAYLOAD, resethook - nmihook)
.cerror nmihook_end - nmihook > NMI_WRAM_CHEATS - BRAM_PAYLOAD, format("nmihook overlaps NMI_WRAM_CHEATS: $%02x bytes, $%02x available", nmihook_end - nmihook, NMI_WRAM_CHEATS - BRAM_PAYLOAD)

; The FPGA's in-game hook logic (cheat.v) patches the offsets of the three
; infinite loop branches above (nmi_branch1..3) with fixed values.
; Raise an error if they change.
; TODO automate this somehow?
fpga_branch .macro site, target, offset
  .cerror \target - (\site + 2) != \offset, format("FPGA branch offset changed (see cheat.v): %s -> %s is $%02x, expected $%02x", str(.\site), str(.\target), \target - (\site + 2), \offset)
.endm
.fpga_branch nmi_branch1, nmi_manual_read, $00
.fpga_branch nmi_branch1, nmi_echocmd,     $30
.fpga_branch nmi_branch1, nmi_patches,     $3a
.fpga_branch nmi_branch1, nmi_savestate,   $3f
.fpga_branch nmi_branch1, nmi_exit,        $43
.fpga_branch nmi_branch2, nmi_patches,     $00
.fpga_branch nmi_branch2, nmi_savestate,   $05
.fpga_branch nmi_branch2, nmi_exit,        $09
.fpga_branch nmi_branch2, nmi_stop,        $14
.fpga_branch nmi_branch3, nmi_savestate,   $00

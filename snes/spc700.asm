; APU RAM init routine
apu_ram_init:
  php
  sep #$20
  .as
  rep #$10
  .xl
  ldy #$0002
  jsr spc_begin_upload
  ldx #$0000
-
  lda @l apu_ram_init_code,x
  jsr spc_upload_byte
  inx
  cpx #35
  bne -
  ldx #$0002
  stx APUIO2
  stz APUIO1
  lda APUIO0
  inc a
  inc a
  sta APUIO0
- cmp APUIO0
  bne -
  plp
  rts

; All SPC700 routines in SPC700 machine code below this line

apu_ram_init_code:  ; .org $0002
  ; part1: fill $0100-$03ff with #$aa
  .byte $e8, $aa    ; mov a, #$aa
  .byte $8d, $00    ; mov y, #$00
  .byte $cd, $03    ; mov x, #$03
  ; loop:
  .byte $d6, $00, $01 ; mov !$0100+y, a
  .byte $fc           ; inc y
  .byte $d0, <(-6)    ; bne loop
  .byte $ab, $0a      ; inc loop+2
  .byte $1d           ; dec x
  .byte $d0, <(-11)   ; bne loop
  ; part2: zero $0400-$ffff
  .byte $e8, $00    ; mov a, #$00
  .byte $cd, $fc    ; mov x, #$fc
  ; loop2:
  .byte $d6, $00, $04 ; mov !$0400+y, a
  .byte $fc           ; inc y
  .byte $d0, <(-6)    ; bne loop2
  .byte $ab, $19      ; inc loop2+2
  .byte $1d           ; dec x
  .byte $d0, <(-11)   ; bne loop2
  ; Re-run IPL
  .byte $5f, $c0, $ff ; jmp $ffc0

; SPC player code
; SPC loader & transfer routines by Shay Green <gblargg@gmail.com>

spc_loader:         ; .org $0002
  .byte $f8, $21    ;  mov x,@loader_data
  .byte $bd         ;  mov sp,x
  .byte $cd, $22    ;  mov x,#@loader_data+1

; Push PC and PSW from SPC header
  .byte $bf         ;  mov a,(x)+
  .byte $2d         ;  push a
  .byte $bf         ;  mov a,(x)+
  .byte $2d         ;  push a
  .byte $bf         ;  mov a,(x)+
  .byte $2d         ;  push a

; Set FLG to $60 rather than value from SPC
  .byte $e8, $60    ;  mov a,#$60
  .byte $d4, $6c    ;  mov FLG+x,a

; Restore DSP registers
  .byte $8d, $00    ;  mov y,#0
  .byte $bf         ; next:  mov a,(x)+
  .byte $cb, $f2    ;  mov $f2,y
  .byte $c4, $f3    ;  mov $f3,a
  .byte $fc         ;  inc y
  .byte $10, <(-8)  ;  bpl next

  .byte $8f, $6c, $f2 ;  mov $f2,#FLG  ; set for later

; Rerun loader
  .byte $5f, $c0, $ff ;  jmp $ffc0

;---------------------------------------

spc_transfer:       ; .org $0002

  .byte $cd, $fe    ; mov x,#$fe    ; transfer 254 pages

; Transfer four-byte chunks
  .byte $8d, $3f      ; page: mov y,#$3f
  .byte $e4, $f4      ; quad: mov a,$f4
  .byte $d6, $00, $02 ; mov0: mov !$0200+y,a
  .byte $e4, $f5      ;  mov a,$f5
  .byte $d6, $40, $02 ; mov1: mov !$0240+y,a
  .byte $e4, $f6      ;  mov a,$f6
  .byte $d6, $80, $02 ; mov2: mov !$0280+y,a
  .byte $e4, $f7      ;  mov a,$f7  ; tell S-CPU we're ready for more
  .byte $cb, $f7      ;  mov $f7,Y
  .byte $d6, $c0, $02 ; mov3: mov !$02c0+y,a
  .byte $00           ;  nop ; give some time for S-CPU HDMA / WRAM refresh
  .byte $dc           ;  dec y
  .byte $10, <(-26)   ;  bpl quad
; Increment MSBs of addresses
  .byte $ab, $0a    ;  inc mov0+2
  .byte $ab, $0f    ;  inc mov1+2
  .byte $ab, $14    ;  inc mov2+2
  .byte $ab, $1b    ;  inc mov3+2
  .byte $1d         ;  dec x
  .byte $d0, <(-39) ;  bne page
; Rerun loader
  .byte $5f, $c0, $ff ;  jmp $ffc0

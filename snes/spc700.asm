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

; Burst transfer of $0200-$FFFF (spc_burst on the S-CPU): three thirds of
; 85 pages each ($0200, $5700, $AB00; the last two overlap on page $AB, which
; gets the same bytes twice), one byte of each per chunk. Port 3 carries the
; chunk counter (the offset in the page, $FF down to $00), written last: the
; SPC700 reads a chunk when the counter shows up and echoes it when done, so
; the S-CPU may be held up (IRQ, HDMA) at any time.
spc_transfer .block ; uploaded to and run at $0002
  .logical $0002
  .byte $cd, $ff      ;  mov x,#$ff    ; counter and offset in the page
  .byte $8d, 85       ;  mov y,#85     ; pages per third
wait:
  .byte $3e, $f7      ;  cmp x,$f7     ; the next chunk is there?
  .byte $d0, <(wait - (* + 2)) ; bne wait
  .byte $e4, $f4      ;  mov a,$f4
st0:
  .byte $d5, $00, $02 ;  mov !$0200+x,a
  .byte $e4, $f5      ;  mov a,$f5
st1:
  .byte $d5, $00, $57 ;  mov !$5700+x,a
  .byte $e4, $f6      ;  mov a,$f6
  .byte $d8, $f7      ;  mov $f7,x     ; done with the ports
st2:
  .byte $d5, $00, $ab ;  mov !$ab00+x,a
  .byte $1d           ;  dec x
  .byte $c8, $ff      ;  cmp x,#$ff
  .byte $d0, <(wait - (* + 2)) ; bne wait
; Next page in each third
  .byte $ab, <(st0 + 2) ; inc st0+2
  .byte $ab, <(st1 + 2) ; inc st1+2
  .byte $ab, <(st2 + 2) ; inc st2+2
  .byte $dc           ;  dec y
  .byte $d0, <(wait - (* + 2)) ; bne wait
; Rerun loader
  .byte $5f, $c0, $ff ;  jmp $ffc0
size = * - $0002
  .endlogical
  .cerror size > $ee, "the transfer routine must fit below $00f0"
.endblock

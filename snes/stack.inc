; stack frame macros for re-entrant functions
;
; A routine with a frame is a .block that describes its whole frame,
; starting at D+0 after "enter", as a direct-page located block "Frame":
;
;   name .block
;     .virtual #0,d
;   Frame .block
;     <locals>                    ; D+0 ...
;     _ .dstruct SaveJSR(/SaveJSL); saved D, P and return address
;     <parameters>                ; pushed by the caller, last pushed first
;   .endblock
;     .endvirtual
;     .enter
;     lda Frame.x                 ; always direct page (D+offset)
;     ...
;     .leave
;     rts
;   .endblock
;
; Every Frame member is a direct page address thanks to ".virtual #0,d" so
; "lda Frame.x" can't become absolute by mistake.
; To use offsets as immediates ("adc #Frame.x") use "pointer arithmetic":
; ("adc #Frame.x - Frame").
;
; For efficient handling the Direct Page register (D) is set to the top
; of the local variables by the "enter" macro and is restored with the
; "leave" macro alongside the status register (P) when the procedure is
; done.
; That way each call of the same code automatically references its own working
; set, enabling re-entrancy.
; The function body must start with ".enter" and end with ".leave" to maintain
; the direct page and status registers for stack frame handling.
;
; Helper functions that run in the frame of their caller (D unchanged) are
; placed inside the caller's .block, so Frame resolves to the caller's frame.
; It is possible to call subroutines even though a jsr/jsl alters the stack
; pointer because all local data is actually accessed via D, not the stack pointer.
; A routine should therefore not mess with D itself unless you know what you're
; doing.
;
; TODO Use .proc instead of .block? Advantages/Disadvantages?
; optimizing out unused .procs is likely desirable anyway.

SaveJSR .struct
  d     .word ?                 ; saved D (pushed by enter)
  p     .byte ?                 ; saved P (pushed by enter)
  ret   .addr ?                 ; JSR return address
.ends

SaveJSL .struct
  d     .word ?                 ; saved D (pushed by enter)
  p     .byte ?                 ; saved P (pushed by enter)
  ret   .long ?                 ; JSL return address
.ends

; Allocate the locals of Frame on the stack and point D at them.
; DESTROYS ACCUMULATOR, leaves A 16-bit
enter .segment
  php
  rep #$20
  .al
  phd
  tsc
  sec
  sbc #Frame._ - Frame
  tcs
  inc a
  tcd
.endsegment

; Free the locals of Frame and restore D and P.
; DESTROYS ACCUMULATOR
leave .segment
  tsc
  rep #$20
  .al
  clc
  adc #Frame._ - Frame
  tcs
  pld
  plp
.endsegment

; ---------------------------------------------------------------------------
; Stack parameters, checked at assembly time
;
; The caller marks each parameter push with the "param" macro and calls the
; routine with the "call" macro, e.g.
;   .param pha                    ; size follows the current .as/.al state
;   .param pea, time_s1
;   .call time_init               ; checks pushed bytes = parameters in Frame
; The expected size comes from the callee's Frame: everything after its
; "_" member (SaveJSR/SaveJSL).
; Pushes not marked with "param" (saving registers, calls in between) are
; not counted.
; After the call, it is currently the caller's responsibility to restore the
; stack pointer (i.e. pull the parameters from stack again), e.g. with
;   .unparam time_init

; size of the parameters in a Frame (everything below _ (SaveJSR))
frame_params .sfunction _f, size(_f) - (_f._ - _f) - size(_f._)

; bytes pushed by each push instruction (-1: accumulator size, -2: index
; register size); "param" with any other instruction fails with
; "not defined symbol 'param_push_<insn>'"
param_push_pha = -1
param_push_phx = -2
param_push_phy = -2
param_push_pea = 2
param_push_pei = 2
param_push_per = 2
param_push_phd = 2
param_push_phb = 1
param_push_phk = 1
param_push_php = 1

param_bytes := 0                ; parameter bytes pushed since the last call

param .macro insn, arg=
  \insn \arg
  .proff
  .virtual                      ; measure the current register sizes in bytes
_a: lda #0                      ; by calculating the distance between the labels
_x: ldx #0                      ; (_e-_x = 1+index, _x-_a = 1+accumulator)
_e:
  .endvirtual
_n := param_push_\insn
  .if _n == -1                  ; -1 = placeholder for accumulator size
_n := _x - _a - 1
  .elsif _n == -2               ; -2 = placeholder for index size
_n := _e - _x - 1
  .endif
  .pron
param_bytes ::= param_bytes + _n
.endm

call .macro target
  .cerror param_bytes != frame_params(\target.Frame), format("call %s: %d parameter bytes pushed, %d expected", str(.\target), param_bytes, frame_params(\target.Frame))
  jsr \target
param_bytes ::= 0
.endm

; Remove the parameters of "call target" from the stack again; the number
; of bytes comes from the callee's Frame like in "call". They are pulled
; into A, which keeps the carry, so a routine with parameters can return a
; flag in it like any other: it ends with ".leave" and then sec/clc before
; rts (".leave" restores the caller's P).
; DESTROYS ACCUMULATOR AND N/Z (keeps the accumulator size)
unparam .macro target
  .proff
  .virtual                      ; measure the current accumulator size
_a: lda #0
_e:
  .endvirtual
  .pron
_n := frame_params(\target.Frame)
  .if _e - _a == 2              ; 8-bit accumulator: pull bytes
  .if _n <= 8
  .rept _n
  pla
  .endrept
  .else
  .if _n & 1
  pla
  .endif
  rep #$20
  .al
  .rept _n / 2
  pla
  .endrept
  sep #$20
  .as
  .endif
  .else                         ; 16-bit accumulator: pull words
  .rept _n / 2
  pla
  .endrept
  .if _n & 1
  sep #$20
  .as
  pla
  rep #$20
  .al
  .endif
  .endif
.endm

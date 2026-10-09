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

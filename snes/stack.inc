; stack frame macros for re-entrant functions
;
; AllocStack allocates locals_ bytes on the stack and points the direct page
; at them, FreeStack frees them and restores D and P. Every routine that uses
; them sets locals_ (the snescom _locals; names starting with "_" are cheap
; local symbols in 64tass, which a macro body cannot see).
; Parameters pushed by the caller are at locals_+offset+5 (JSR) or
; locals_+offset+6 (JSL), the former StackParam()/StackParamFar().

; Allocate memory on stack and place DP at top
; DESTROYS ACCUMULATOR
AllocStack .macro
        php
        rep #$20
        .al
        phd
        tsc
        sec
        sbc #locals_
        tcs
        inc a
        tcd
        .endm

; Free memory on stack and restore DP
; DESTROYS ACCUMULATOR
FreeStack .macro
        tsc
        rep #$20
        .al
        clc
        adc #locals_
        tcs
        pld
        plp
        .endm

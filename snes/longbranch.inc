; long conditional branches (jeq, jne, jcc, jcs, jmi, jpl, jvc, jvs)
; with BRL instead of JMP so they stay relocatable
; A target within reach (backward or forward) gives a plain short branch,
; otherwise the 5-byte form "b<inverse> *+5 : brl target"

lbranch .macro bshort, binverse, target
  .if (\target) - (* + 2) >= -128 && (\target) - (* + 2) <= 127
    \bshort \target
  .else
    \binverse * + 5
    brl \target
  .endif
.endm

jeq .macro target
  .lbranch beq, bne, \target
.endm
jne .macro target
  .lbranch bne, beq, \target
.endm
jcc .macro target
  .lbranch bcc, bcs, \target
.endm
jcs .macro target
  .lbranch bcs, bcc, \target
.endm
jmi .macro target
  .lbranch bmi, bpl, \target
.endm
jpl .macro target
  .lbranch bpl, bmi, \target
.endm
jvc .macro target
  .lbranch bvc, bvs, \target
.endm
jvs .macro target
  .lbranch bvs, bvc, \target
.endm

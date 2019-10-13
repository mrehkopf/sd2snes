ORG $002C00 : ipsoffset $D00000
print "Hook Bank Starting at: ", pc

hook:
  php : %ai16() : pha
  lda.l $004218 ; need to access buttons as soon as possible
  sta.l $FC2006
  jmp.l !SS_CODE
hook_return:
  %ai16() : pla : plp
  jmp ($FFEA)
  
print "Hook Bank Ending at: ", pc

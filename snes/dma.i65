.link page $c0

#define hash #
#define f(x) x
#define imm(a) f(hash)a

#define DMA7(mode, len, a_bank, a_addr, b_reg) \
  php \
: sep imm($20) : .as \
: rep imm($10) : .xl \
: lda mode \
: sta $4370 \
: ldx a_addr \
: lda a_bank \
: stx $4372 \
: sta $4374 \
: ldx len \
: stx $4375 \
: lda b_reg \
: sta $4371 \
: lda imm($80) \
: sta $420b \
: plp

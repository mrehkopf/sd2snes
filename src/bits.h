#ifndef _ARM_BITS_H
#define _ARM_BITS_H

/* The classic macro */
#define BV(x) (1<<(x))

/* CM3 bit-band access macro - no error checks! */
#define BITBAND(addr,bit) \
  (*((volatile uint32_t*)( \
    (((uint32_t)&(addr) & 0x01ffffff) << 5) + \
    ((bit) << 2) + 0x02000000 + ((uint32_t)&(addr) & 0xfe000000) \
  )))

#define BITBAND_OFF(addr,offset,bit) \
  (*((volatile uint32_t*)( \
     ((((uint32_t)&(addr) + (offset)) & 0x01ffffff) << 5) + \
     ((bit) << 2) + 0x02000000 + (((uint32_t)&(addr) + (offset)) & 0xfe000000) \
  )))


#endif

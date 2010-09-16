#ifndef _LPC_H
#define _LPC_H

#define BV(x) (1<<(x))
#define BITBAND(addr,bit) (*((volatile unsigned long *)(((unsigned long)&(addr)-0x20000000)*32 + bit*4 + 0x22000000)))

#endif


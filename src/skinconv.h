#ifndef SKINCONV_H
#define SKINCONV_H

#include <stdint.h>

#define SKINCONV_ROM_SIZE (0x10000L)   /* size of an old menu ROM */

/* convert the old menu ROM at rom_addr (cart memory) into a skin at
   skin_addr; returns the size of the skin, 0 for an unknown menu version */
uint32_t skinconv_menu_rom(uint32_t rom_addr, uint32_t skin_addr);

/* convert the theme file (.thm of the sd2snes fork by ludufre, thm_size
   bytes at thm_addr) into a skin at skin_addr, using SKINCONV_ROM_SIZE
   bytes at work_addr; returns the size of the skin, 0 for no theme file */
uint32_t skinconv_theme(uint32_t thm_addr, uint32_t thm_size, uint32_t work_addr, uint32_t skin_addr);

#endif

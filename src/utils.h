/* sd2iec - SD/MMC to Commodore serial bus interface/controller
   Copyright (C) 2007-2009  Ingo Korb <ingo@akana.de>

   Inspiration and low-level SD/MMC access based on code from MMC2IEC
     by Lars Pontoppidan et al., see sdcard.c|h and config.h.

   FAT filesystem access based on code from ChaN and Jim Brain, see ff.c|h.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License only.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


   utils.c: Misc. utility functions that didn't fit elsewhere

*/

#ifndef UTILS_H
#define UTILS_H

/* Side-effect safe min/max */
#define max(a,b) \
       ({ typeof (a) _a = (a); \
           typeof (b) _b = (b); \
         _a > _b ? _a : _b; })

#define min(a,b) \
       ({ typeof (a) _a = (a); \
           typeof (b) _b = (b); \
         _a < _b ? _a : _b; })


/* Write a number to a string as ASCII */
uint8_t *appendnumber(uint8_t *msg, uint8_t value);

/* Convert between integer and BCD */
uint8_t bcd2int(uint8_t value);
uint8_t int2bcd(uint8_t value);

/* Tokenize a string like strtok_r, but with a single delimiter character only */
uint8_t *ustr1tok(uint8_t *str, const uint8_t delim, uint8_t **saveptr);

#endif

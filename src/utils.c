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

#include <stdint.h>
#include "ustring.h"

uint8_t *appendnumber(uint8_t *msg, uint8_t value) {
  if (value >= 100) {
    *msg++ = '0' + value/100;
    value %= 100;
  }

  *msg++ = '0' + value/10;
  *msg++ = '0' + value%10;

  return msg;
}

/* Convert a one-byte BCD value to a normal integer */
uint8_t bcd2int(uint8_t value) {
  return (value & 0x0f) + 10*(value >> 4);
}

/* Convert a uint8_t into a BCD value */
uint8_t int2bcd(uint8_t value) {
  return (value % 10) + 16*(value/10);
}

/* Similiar to strtok_r, but only a single delimiting character  */
uint8_t *ustr1tok(uint8_t *str, const uint8_t delim, uint8_t **saveptr) {
  uint8_t *tmp;

  if (str == NULL)
    str = *saveptr;

  /* Skip leading delimiters */
  while (*str == delim) str++;

  /* If there is anything left... */
  if (*str) {
    /* Search for the next delimiter */
    tmp = str;
    while (*tmp && *tmp != delim) tmp++;

    /* Terminate the string there */
    if (*tmp != 0)
      *tmp++ = 0;

    *saveptr = tmp;

    return str;
  } else
    return NULL;
}

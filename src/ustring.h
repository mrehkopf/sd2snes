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


   ustring.h: uint8_t wrappers for string.h-functions

*/

#ifndef USTRING_H
#define USTRING_H

#include <string.h>

#define ustrcasecmp_P(s1,s2) (strcasecmp_P((char *)(s1), (s2)))
#define ustrchr(s,c)         ((uint8_t *)strchr((char *)(s), (c)))
#define ustrcmp(s1,s2)       (strcmp((char *)(s1), (char *)(s2)))
#define ustrcmp_P(s1,s2)     (strcmp_P((char *)(s1), (s2)))
#define ustrcpy(s1,s2)       (strcpy((char *)(s1), (char *)(s2)))
#define ustrcpy_P(s1,s2)     (strcpy_P((char *)(s1), (s2)))
#define ustrncpy(s1,s2,n)    (strncpy((char *)(s1), (char *)(s2),(n)))
#define ustrlen(s)           (strlen((char *)(s)))
#define ustrrchr(s,c)        ((uint8_t *)strrchr((char *)(s), (c)))

#endif

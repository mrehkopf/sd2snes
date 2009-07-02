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


   sdcard.h: Definitions for the SD/MMC access routines

*/

#ifndef SDCARD_H
#define SDCARD_H

#include "diskio.h"

/* These functions are weak-aliased to disk_... */
void    sd_init(void);
DSTATUS sd_status(BYTE drv);
DSTATUS sd_initialize(BYTE drv);
DRESULT sd_read(BYTE drv, BYTE *buffer, DWORD sector, BYTE count);
DRESULT sd_write(BYTE drv, const BYTE *buffer, DWORD sector, BYTE count);
DRESULT sd_getinfo(BYTE drv, BYTE page, void *buffer);

#endif

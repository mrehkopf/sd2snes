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


   diskio.c: Generic disk access routines and supporting stuff

*/

#include "config.h"
#include "diskio.h"
#include "sdcard.h"

volatile enum diskstates disk_state;

#ifdef NEED_DISKMUX

uint32_t drive_config;

/* This function calculates the default drive configuration. */
/* Its result is static after compilation, but doing this in */
/* C in less messy than doing it with the preprocessor.      */
uint32_t get_default_driveconfig(void) {
  uint32_t result = 0xffffffffL;

  /* Order matters: Whatever is checked first will be last in the config */
#ifdef HAVE_DF
  result = (result << 4) + (DISK_TYPE_DF  << DRIVE_BITS) + 0;
#endif
#ifdef CONFIG_TWINSD
  result = (result << 4) + (DISK_TYPE_SD  << DRIVE_BITS) + 1;
#endif
#ifdef HAVE_SD
  result = (result << 4) + (DISK_TYPE_SD  << DRIVE_BITS) + 0;
#endif
#ifdef HAVE_ATA
  result = (result << 4) + (DISK_TYPE_ATA << DRIVE_BITS) + 0;
#endif
  return result;
}

void disk_init(void) {
#ifdef HAVE_SD
  sd_init();
#endif
#ifdef HAVE_ATA
  ata_init();
#endif
#ifdef HAVE_DF
  df_init();
#endif
}

DSTATUS disk_status(BYTE drv) {
  switch(drv >> DRIVE_BITS) {
#ifdef HAVE_DF
  case DISK_TYPE_DF:
    return df_status(drv & DRIVE_MASK);
#endif

#ifdef HAVE_ATA
  case DISK_TYPE_ATA:
    return ata_status(drv & DRIVE_MASK);

  case DISK_TYPE_ATA2:
    return ata_status((drv & DRIVE_MASK) + 2);
#endif

#ifdef HAVE_SD
  case DISK_TYPE_SD:
    return sd_status(drv & DRIVE_MASK);
#endif

  default:
    return STA_NOINIT|STA_NODISK;
  }
}

DSTATUS disk_initialize(BYTE drv) {
  switch(drv >> DRIVE_BITS) {
#ifdef HAVE_DF
  case DISK_TYPE_DF:
    return df_initialize(drv & DRIVE_MASK);
#endif

#ifdef HAVE_ATA
  case DISK_TYPE_ATA:
    return ata_initialize(drv & DRIVE_MASK);

  case DISK_TYPE_ATA2:
    return ata_initialize((drv & DRIVE_MASK) + 2);
#endif

#ifdef HAVE_SD
  case DISK_TYPE_SD:
    return sd_initialize(drv & DRIVE_MASK);
#endif

  default:
    return STA_NOINIT|STA_NODISK;
  }
}

DRESULT disk_read(BYTE drv, BYTE *buffer, DWORD sector, BYTE count) {
  switch(drv >> DRIVE_BITS) {
#ifdef HAVE_DF
  case DISK_TYPE_DF:
    return df_read(drv & DRIVE_MASK,buffer,sector,count);
#endif

#ifdef HAVE_ATA
  case DISK_TYPE_ATA:
    return ata_read(drv & DRIVE_MASK,buffer,sector,count);

  case DISK_TYPE_ATA2:
    return ata_read((drv & DRIVE_MASK) + 2,buffer,sector,count);
#endif

#ifdef HAVE_SD
  case DISK_TYPE_SD:
    return sd_read(drv & DRIVE_MASK,buffer,sector,count);
#endif

  default:
    return RES_ERROR;
  }
}

DRESULT disk_write(BYTE drv, const BYTE *buffer, DWORD sector, BYTE count) {
  switch(drv >> DRIVE_BITS) {
#ifdef HAVE_DF
  case DISK_TYPE_DF:
    return df_write(drv & DRIVE_MASK,buffer,sector,count);
#endif

#ifdef HAVE_ATA
  case DISK_TYPE_ATA:
    return ata_write(drv & DRIVE_MASK,buffer,sector,count);

  case DISK_TYPE_ATA2:
    return ata_write((drv & DRIVE_MASK) + 2,buffer,sector,count);
#endif

#ifdef HAVE_SD
  case DISK_TYPE_SD:
    return sd_write(drv & DRIVE_MASK,buffer,sector,count);
#endif

  default:
    return RES_ERROR;
  }
}

DRESULT disk_getinfo(BYTE drv, BYTE page, void *buffer) {
  switch(drv >> DRIVE_BITS) {
#ifdef HAVE_DF
  case DISK_TYPE_DF:
    return df_getinfo(drv & DRIVE_MASK,page,buffer);
#endif

#ifdef HAVE_ATA
  case DISK_TYPE_ATA:
    return ata_getinfo(drv & DRIVE_MASK,page,buffer);

  case DISK_TYPE_ATA2:
    return ata_getinfo((drv & DRIVE_MASK) + 2,page,buffer);
#endif

#ifdef HAVE_SD
  case DISK_TYPE_SD:
    return sd_getinfo(drv & DRIVE_MASK,page,buffer);
#endif

  default:
    return RES_ERROR;
  }
}


#endif

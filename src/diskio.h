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


   diskio.h: Definitions for the disk access routines

   Based on diskio.h from FatFS by ChaN, see ff.c for
   for full copyright details.

*/

#ifndef DISKIO_H
#define DISKIO_H

#include "integer.h"

/* Status of Disk Functions */
typedef BYTE    DSTATUS;

/* Disk Status Bits (DSTATUS) */
#define STA_NOINIT              0x01    /* Drive not initialized */
#define STA_NODISK              0x02    /* No medium in the drive */
#define STA_PROTECT             0x04    /* Write protected */

/* Results of Disk Functions */
typedef enum {
        RES_OK = 0,             /* 0: Successful */
        RES_ERROR,              /* 1: R/W Error */
        RES_WRPRT,              /* 2: Write Protected */
        RES_NOTRDY,             /* 3: Not Ready */
        RES_PARERR              /* 4: Invalid Parameter */
} DRESULT;

/**
 * struct diskinfo0_t - disk info data structure for page 0
 * @validbytes : Number of valid bytes in this struct
 * @maxpage    : Highest diskinfo page supported
 * @disktype   : type of the disk (DISK_TYPE_* values)
 * @sectorsize : sector size divided by 256
 * @sectorcount: number of sectors on the disk
 *
 * This is the struct returned in the data buffer when disk_getinfo
 * is called with page=0.
 */
typedef struct {
  uint8_t  validbytes;
  uint8_t  maxpage;
  uint8_t  disktype;
  uint8_t  sectorsize;   /* divided by 256 */
  uint32_t sectorcount;  /* 2 TB should be enough... (512 byte sectors) */
} diskinfo0_t;

/*---------------------------------------*/
/* Prototypes for disk control functions */

DSTATUS disk_initialize (BYTE);
DSTATUS disk_status (BYTE);
DRESULT disk_read (BYTE, BYTE*, DWORD, BYTE);
DRESULT disk_write (BYTE, const BYTE*, DWORD, BYTE);
#define disk_ioctl(a,b,c) RES_OK
DRESULT disk_getinfo(BYTE drv, BYTE page, void *buffer);

void disk_init(void);

/* Will be set to DISK_ERROR if any access on the card fails */
enum diskstates { DISK_CHANGED = 0, DISK_REMOVED, DISK_OK, DISK_ERROR };

extern volatile enum diskstates disk_state;

/* Disk type - part of the external API except for ATA2! */
#define DISK_TYPE_ATA        0
#define DISK_TYPE_ATA2       1
#define DISK_TYPE_SD         2
#define DISK_TYPE_DF         3
#define DISK_TYPE_NONE       7

#ifdef NEED_DISKMUX

/* Disk mux configuration */

extern uint32_t drive_config;

uint32_t get_default_driveconfig(void);

#  define set_map_drive(drv,val) (drive_config = \
      (drive_config & (0xffffffff - (0x0f << (drv * 4)))) \
                    | (val << (drv * 4)))
#  define map_drive(drv) ((drive_config >> (4 * drv)) & 0x0f)
#  define set_drive_config(config)  drive_config = config

/* Number of bits used for the drive, the disk type */
/* uses the remainder (4 bits per entry).           */
#  define DRIVE_BITS           1

/* Calculate mask from the shift value */
#  define DRIVE_MASK           ((1 << DRIVE_BITS)-1)

#else // NEED_DISKMUX

#  define set_map_drive(drv,val) do {} while(0)
#  define map_drive(drv) (drv)
#  define set_drive_config(conf) do {} while(0)
#  define get_default_driveconfig() 0

#endif // NEED_DISKMUX

#endif

/*-----------------------------------------------------------------------
/  Low level disk interface modlue include file   (C)ChaN, 2010
/-----------------------------------------------------------------------*/

#ifndef _DISKIO

#define _READONLY	0	/* 1: Remove write functions */
#define _USE_IOCTL	1	/* 1: Use disk_ioctl fucntion */

#include <arm/NXP/LPC17xx/LPC17xx.h>

#include "integer.h"


/* Status of Disk Functions */
typedef BYTE	DSTATUS;

/* Results of Disk Functions */
typedef enum {
	RES_OK = 0,		/* 0: Successful */
	RES_ERROR,		/* 1: R/W Error */
	RES_WRPRT,		/* 2: Write Protected */
	RES_NOTRDY,		/* 3: Not Ready */
	RES_PARERR		/* 4: Invalid Parameter */
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

int assign_drives (int, int);
DSTATUS disk_initialize (BYTE);
DSTATUS disk_status (BYTE);
DRESULT disk_read (BYTE, BYTE*, DWORD, BYTE);
#if	_READONLY == 0
DRESULT disk_write (BYTE, const BYTE*, DWORD, BYTE);
#endif
#define disk_ioctl(a,b,c) RES_OK

void disk_init(void);

/* Will be set to DISK_ERROR if any access on the card fails */
enum diskstates { DISK_CHANGED = 0, DISK_REMOVED, DISK_OK, DISK_ERROR };

extern int sd_offload, ff_sd_offload, sd_offload_tgt, newcard;
extern int sd_offload_partial;
extern uint16_t sd_offload_partial_start;
extern uint16_t sd_offload_partial_end;
extern volatile enum diskstates disk_state;

/* Disk type - part of the external API except for ATA2! */
#define DISK_TYPE_ATA        0
#define DISK_TYPE_ATA2       1
#define DISK_TYPE_SD         2
#define DISK_TYPE_DF         3
#define DISK_TYPE_NONE       7



/* Disk Status Bits (DSTATUS) */

#define STA_NOINIT		0x01	/* Drive not initialized */
#define STA_NODISK		0x02	/* No medium in the drive */
#define STA_PROTECT		0x04	/* Write protected */


/* Command code for disk_ioctrl fucntion */

/* Generic command (defined for FatFs) */
#define CTRL_SYNC			0	/* Flush disk cache (for write functions) */
#define GET_SECTOR_COUNT	1	/* Get media size (for only f_mkfs()) */
#define GET_SECTOR_SIZE		2	/* Get sector size (for multiple sector size (_MAX_SS >= 1024)) */
#define GET_BLOCK_SIZE		3	/* Get erase block size (for only f_mkfs()) */
#define CTRL_ERASE_SECTOR	4	/* Force erased a block of sectors (for only _USE_ERASE) */

/* Generic command */
#define CTRL_POWER			5	/* Get/Set power status */
#define CTRL_LOCK			6	/* Lock/Unlock media removal */
#define CTRL_EJECT			7	/* Eject media */

/* MMC/SDC specific ioctl command */
#define MMC_GET_TYPE		10	/* Get card type */
#define MMC_GET_CSD			11	/* Get CSD */
#define MMC_GET_CID			12	/* Get CID */
#define MMC_GET_OCR			13	/* Get OCR */
#define MMC_GET_SDSTAT		14	/* Get SD status */

/* ATA/CF specific ioctl command */
#define ATA_GET_REV			20	/* Get F/W revision */
#define ATA_GET_MODEL		21	/* Get model name */
#define ATA_GET_SN			22	/* Get serial number */

/* NAND specific ioctl command */
#define NAND_FORMAT			30	/* Create physical format */


#define _DISKIO
#endif

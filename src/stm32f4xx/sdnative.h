/* DISCLAIMER */

#ifndef SDNATIVE_H
#define SDNATIVE_H

#ifdef DEBUG_SD
#define DBG_SD
#else
#define DBG_SD while(0)
#endif

#ifdef DEBUG_SD_OFFLOAD
#define DBG_SD_OFFLOAD
#else
#define DBG_SD_OFFLOAD while(0)
#endif

#include "diskio.h"

#define CRC_ERROR        (0xf000)

extern int sd_offload;

/* These functions are weak-aliased to disk_... */
void    sdn_init(void);
DSTATUS sdn_status(BYTE drv);
DSTATUS sdn_initialize(BYTE drv);
DRESULT sdn_read(BYTE drv, BYTE *buffer, DWORD sector, UINT count);
DRESULT sdn_write(BYTE drv, const BYTE *buffer, DWORD sector, UINT count);
DRESULT sdn_getinfo(BYTE drv, BYTE page, void *buffer);
DRESULT sdn_ioctl(BYTE drv, BYTE cmd, void *buffer);

void    sdn_changed(void);
uint8_t* sdn_getcid(void);
void    sdn_gettacc(uint32_t *tacc_max, uint32_t *tacc_avg);
#endif

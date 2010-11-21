/* DISCLAIMER */

#ifndef SDNATIVE_H
#define SDNATIVE_H

#include "diskio.h"

/* These functions are weak-aliased to disk_... */
void    sdn_init(void);
DSTATUS sdn_status(BYTE drv);
DSTATUS sdn_initialize(BYTE drv);
DRESULT sdn_read(BYTE drv, BYTE *buffer, DWORD sector, BYTE count);
DRESULT sdn_write(BYTE drv, const BYTE *buffer, DWORD sector, BYTE count);
DRESULT sdn_getinfo(BYTE drv, BYTE page, void *buffer);

void    sdn_changed(void);

#endif


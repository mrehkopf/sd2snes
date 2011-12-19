#ifndef _XMODEM_H
#define _XMODEM_H

#include "ff.h"

#define ASC_ACK (0x06)
#define ASC_NAK (0x15)
#define ASC_SOH (0x01)
#define ASC_EOT (0x04)
#define XMODEM_BLKSIZE (128)

void xmodem_rxfile(FIL* fil);

#endif

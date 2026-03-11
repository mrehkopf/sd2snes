#ifndef _YMODEM_H
#define _YMODEM_H

#include "ff.h"

#define ASC_ACK (0x06)
#define ASC_NAK (0x15)
#define ASC_SOH (0x01)
#define ASC_STX (0x02)
#define ASC_EOT (0x04)
#define ASC_C   (0x43)

#define YMODEM_BLKSIZE (128)
#define YMODEM_BLKSIZE_1K (1024)

void ymodem_rxfile(FIL* fil);

#endif

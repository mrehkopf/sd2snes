/* ___DISCLAIMER___ */

#ifndef _POWER_H
#define _POWER_H

#include "bits.h"

#define PCUART0	(3)
#define PCUART1 (4)
#define PCUART2 (24)
#define PCUART3 (25)

#define PCTIM0  (1)
#define PCTIM1  (2)
#define PCTIM2  (22)
#define PCTIM3  (23)
#define PCRTC   (9)
#define PCRIT   (16)

#define PCCAN1  (13)
#define PCCAN2  (14)

#define PCPWM1  (6)
#define PCMCPWM (17)

#define PCSSP0  (21)
#define PCSSP1  (10)
#define PCSPI   (8)

#define PCI2C0  (7)
#define PCI2C1  (19)
#define PCI2C2  (26)

#define PCI2S   (27)
#define PCGPDMA (29)
#define PCENET  (30)
#define PCUSB   (31)
#define PCQEI   (18)
#define PCGPIO  (15)

void power_init(void);

#endif

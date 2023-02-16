#ifndef _CONFIG_H
#define _CONFIG_H

#include "autoconf.h"
#include CONFIG_MCU_H

#define CONFIG_FWVER (*((uint32_t*)CONFIG_FW_START+4))

#define IN_AHBRAM   __attribute__ ((section(".ahbram")))

#define SDCARD_DETECT   (!(BITBAND(SD_DTREG->GPIO_I, SD_DTBIT)))

#define SD_SUPPLY_VOLTAGE   (1L<<21) /* 3.3V - 3.4V */
#define CONFIG_SD_BLOCKTRANSFER   1
#define CONFIG_SD_AUTO_RETRIES    10

#ifdef SD_HAS_WP
  #define SDCARD_WP                 (BITBAND(SD_WPREG->GPIO_I, SD_WPBIT))
#else
  #define SDCARD_WP                 (0)
#endif

#endif

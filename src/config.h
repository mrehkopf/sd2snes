#ifndef _CONFIG_H
#define _CONFIG_H

#include "autoconf.h"

#define IN_AHBRAM   __attribute__ ((section(".ahbram")))

#define SD_DT_INT_SETUP()   do {\
                        BITBAND(LPC_GPIOINT->IO2IntEnR, SD_DT_BIT) = 1;\
                        BITBAND(LPC_GPIOINT->IO2IntEnF, SD_DT_BIT) = 1;\
                    } while(0)

#define SD_CHANGE_DETECT   (BITBAND(LPC_GPIOINT->IO2IntStatR, SD_DT_BIT)\
                   | BITBAND(LPC_GPIOINT->IO2IntStatF, SD_DT_BIT))

#define SD_CHANGE_CLR()   do {LPC_GPIOINT->IO2IntClr = BV(SD_DT_BIT);} while(0)

#define SDCARD_DETECT   (!(BITBAND(SD_DT_REG->FIOPIN, SD_DT_BIT)))

#define SD_SUPPLY_VOLTAGE   (1L<<21) /* 3.3V - 3.4V */
#define CONFIG_SD_BLOCKTRANSFER   1
#define CONFIG_SD_AUTO_RETRIES    10

#ifdef SD_HAS_WP
  #define SDCARD_WP                 (BITBAND(SD_WP_REG->FIOPIN, SD_WP_BIT))
#else
  #define SDCARD_WP                 (0)
#endif

#endif

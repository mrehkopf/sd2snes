#ifndef _CONFIG_H
#define _CONFIG_H

#include "autoconf.h"

// #define DEBUG_FS
// #define DEBUG_SD
// #define DEBUG_SD_OFFLOAD
// #define DEBUG_IRQ
// #define DEBUG_MSU1
// #define DEBUG_YAML

#define IN_AHBRAM                 __attribute__ ((section(".ahbram")))

#define SD_DT_INT_SETUP()         do {\
                                    BITBAND(LPC_GPIOINT->IO2IntEnR, SD_DT_BIT) = 1;\
                                    BITBAND(LPC_GPIOINT->IO2IntEnF, SD_DT_BIT) = 1;\
                                  } while(0)

#define SD_CHANGE_DETECT          (BITBAND(LPC_GPIOINT->IO2IntStatR, SD_DT_BIT)\
                                   |BITBAND(LPC_GPIOINT->IO2IntStatF, SD_DT_BIT))

#define SD_CHANGE_CLR()           do {LPC_GPIOINT->IO2IntClr = BV(SD_DT_BIT);} while(0)

#define SD_DT_REG                 LPC_GPIO0
#define SD_DT_BIT                 8
#define SD_WP_REG                 LPC_GPIO0
#define SD_WP_BIT                 6

#define SDCARD_DETECT             (!(BITBAND(SD_DT_REG->FIOPIN, SD_DT_BIT)))
#define SDCARD_WP                 (BITBAND(SD_WP_REG->FIOPIN, SD_WP_BIT))
#define SD_SUPPLY_VOLTAGE         (1L<<21) /* 3.3V - 3.4V */
#define CONFIG_SD_BLOCKTRANSFER   1
#define CONFIG_SD_AUTO_RETRIES    10
// #define SD_CHANGE_VECT
// #define CONFIG_SD_DATACRC 1

#define CONFIG_UART_NUM	          3
// #define CONFIG_CPU_FREQUENCY      90315789
#define CONFIG_CPU_FREQUENCY      96000000
//#define CONFIG_CPU_FREQUENCY      46000000
#define CONFIG_UART_PCLKDIV       1
#define CONFIG_UART_TX_BUF_SHIFT  8
#define CONFIG_UART_BAUDRATE      921600
//#define CONFIG_UART_BAUDRATE      115200
#define CONFIG_UART_DEADLOCKABLE

#define CONFIG_CLK_MULT           16
#define CONFIG_CLK_PREDIV         2
#define CONFIG_CLK_CCLKDIV        2

//#define CONFIG_CLK_MULT           43
//#define CONFIG_CLK_PREDIV         2
//#define CONFIG_CLK_CCLKDIV        6

#define SSP_CLK_DIVISOR           2

#define SNES_RESET_REG            LPC_GPIO1
#define SNES_RESET_BIT            26

#define SNES_CIC_D0_REG           LPC_GPIO0
#define SNES_CIC_D0_BIT           1

#define SNES_CIC_D1_REG           LPC_GPIO0
#define SNES_CIC_D1_BIT           0

#define SNES_CIC_STATUS_REG       LPC_GPIO1
#define SNES_CIC_STATUS_BIT       29

#define SNES_CIC_PAIR_REG         LPC_GPIO1
#define SNES_CIC_PAIR_BIT         25

#define FPGA_MCU_RDY_REG          LPC_GPIO2
#define FPGA_MCU_RDY_BIT          9

#define QSORT_MAXELEM             2048
#define SORT_STRLEN               256
#define CLTBL_SIZE                100

#define DIR_FILE_MAX              16380

#define SSP_REGS LPC_SSP0
#define SSP_PCLKREG PCLKSEL1
// 1: PCLKSEL0
#define SSP_PCLKBIT 10
// 1: 20
#define SSP_DMAID_TX 0
// 1: 2
#define SSP_DMAID_RX 1
// 1: 3
#define SSP_DMACH LPC_GPDMACH0

#define SD_CLKREG LPC_GPIO0
#define SD_CMDREG LPC_GPIO0
#define SD_DAT0REG LPC_GPIO2
#define SD_DAT1REG LPC_GPIO2
#define SD_DAT2REG LPC_GPIO2
#define SD_DAT3REG LPC_GPIO2

#define SD_CLKPIN (7)
#define SD_CMDPIN (9)
#define SD_DAT0PIN (0)
#define SD_DAT1PIN (1)
#define SD_DAT2PIN (2)
#define SD_DAT3PIN (3)

#define SD_DAT (LPC_GPIO2->FIOPIN0)

#define USB_CONNREG LPC_GPIO4
#define USB_CONNBIT 28

#endif

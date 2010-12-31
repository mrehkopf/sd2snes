#ifndef _CONFIG_H
#define _CONFIG_H

// #define DEBUG_SD
// #define DEBUG_IRQ
#define DEBUG_MSU1

#define VER                       "0.0.1(NSFW)"
#define IN_AHBRAM                 __attribute__ ((section(".ahbram")))


#define SD_DT_INT_SETUP()         do {\
                                    BITBAND(LPC_GPIOINT->IO2IntEnR, SD_DT_BIT) = 1;\
                                    BITBAND(LPC_GPIOINT->IO2IntEnF, SD_DT_BIT) = 1;\
                                  } while(0)

#define SD_CHANGE_DETECT          (BITBAND(LPC_GPIOINT->IO2IntStatR, SD_DT_BIT)\
                                   |BITBAND(LPC_GPIOINT->IO2IntStatF, SD_DT_BIT))

#define SD_CHANGE_CLR()           do {LPC_GPIOINT->IO2IntClr = BV(SD_DT_BIT);} while(0)

#define SD_DT_REG                 LPC_GPIO2
#define SD_DT_BIT                 3
#define SD_WP_REG                 LPC_GPIO2
#define SD_WP_BIT                 4

#define SDCARD_DETECT             (!(BITBAND(SD_DT_REG->FIOPIN, SD_DT_BIT)))
#define SDCARD_WP                 (BITBAND(SD_WP_REG->FIOPIN, SD_WP_BIT))
#define SD_SUPPLY_VOLTAGE         (1L<<21) /* 3.3V - 3.4V */
#define CONFIG_SD_BLOCKTRANSFER   1
#define CONFIG_SD_AUTO_RETRIES    10
// #define SD_CHANGE_VECT
// #define CONFIG_SD_DATACRC 1


#define CONFIG_UART_NUM	          3
#define CONFIG_CPU_FREQUENCY      90315789
#define CONFIG_UART_PCLKDIV       1
#define CONFIG_UART_TX_BUF_SHIFT  5
#define CONFIG_UART_BAUDRATE      921600
#define CONFIG_UART_DEADLOCKABLE

#define SSP_CLK_DIVISOR_FAST 2
#define SSP_CLK_DIVISOR_SLOW 250

#define SSP_CLK_DIVISOR_FPGA_FAST 6
#define SSP_CLK_DIVISOR_FPGA_SLOW 20

#define SNES_RESET_REG            LPC_GPIO1
#define SNES_RESET_BIT            29
/* XXX Rev.B: 1.26 */
#define SNES_CIC_D0_REG           LPC_GPIO1
#define SNES_CIC_D0_BIT           26
/* XXX Rev.B: 0.1 */
#define SNES_CIC_D1_REG           LPC_GPIO1
#define SNES_CIC_D1_BIT           25
/* XXX Rev.B: 0.0 */
#define SNES_CIC_STATUS_REG       LPC_GPIO0
#define SNES_CIC_STATUS_BIT       1
/* XXX Rev.B: 1.29 */
#define SNES_CIC_PAIR_REG         LPC_GPIO0
#define SNES_CIC_PAIR_BIT         0
/* XXX Rev.B: 1.25 */

#define QSORT_MAXELEM             1024

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
#define SD_DAT0REG LPC_GPIO0
#define SD_DAT1REG LPC_GPIO1
#define SD_DAT2REG LPC_GPIO1
#define SD_DAT3REG LPC_GPIO0

#define SD_CLKPIN (7)
#define SD_CMDPIN (9)
#define SD_DAT0PIN (8)
#define SD_DAT1PIN (14)
#define SD_DAT2PIN (15)
#define SD_DAT3PIN (6)

#define SD_DAT ((BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN))\
                |((SD_DAT1REG->FIOPIN1 >> 5) & 0x6)\
                |((BITBAND(SD_DAT3REG->FIOPIN, SD_DAT3PIN)) << 3))

#endif

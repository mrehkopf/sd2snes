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
#define SD_HAS_WP
#define SD_WP_REG                 LPC_GPIO0
#define SD_WP_BIT                 6

#define SDCARD_DETECT             (!(BITBAND(SD_DT_REG->FIOPIN, SD_DT_BIT)))

#ifdef SD_HAS_WP
  #define SDCARD_WP                 (BITBAND(SD_WP_REG->FIOPIN, SD_WP_BIT))
#else
  #define SDCARD_WP                 (0)
#endif

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

#define DEVICE_NAME "sd2snes Mk.II"

/*   PLL0 96MHz
     Base clock:   12MHz
     Multiplier:   16
     Pre-Divisor:   1
     Divisor:       4
*/
#define CONFIG_CLK_MULT           16
#define CONFIG_CLK_PREDIV         1
#define CONFIG_CLK_CCLKDIV        4

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

#define SNES_CIC_D0_MODEREG       LPC_PINCON->PINMODE0
#define SNES_CIC_D0_MODEBIT       1

#define SNES_CIC_D1_MODEREG       LPC_PINCON->PINMODE0
#define SNES_CIC_D1_MODEBIT       3

/*
   FPGA pin mapping
   ================
   CCLK        P0.11 out
   PROG_B      P1.15 out
   INIT_B      P2.9  in
   DIN         P2.8  out
   DONE        P0.22 in
 */

#define FPGA_CONF_EXT "bit"

#define FPGA_CCLKREG  LPC_GPIO0
#define FPGA_PROGBREG LPC_GPIO1
#define FPGA_INITBREG LPC_GPIO2
#define FPGA_DINREG   LPC_GPIO2
#define FPGA_DONEREG  LPC_GPIO0

#define FPGA_CCLKBIT  (11)
#define FPGA_PROGBBIT (15)
#define FPGA_INITBBIT (9)
#define FPGA_DINBIT   (8)
#define FPGA_DONEBIT  (22)

#define FPGA_SEND_BYTE_SERIAL(data) do {SET_FPGA_DIN(data>>7); CCLK();\
SET_FPGA_DIN(data>>6); CCLK(); SET_FPGA_DIN(data>>5); CCLK();\
SET_FPGA_DIN(data>>4); CCLK(); SET_FPGA_DIN(data>>3); CCLK();\
SET_FPGA_DIN(data>>2); CCLK(); SET_FPGA_DIN(data>>1); CCLK();\
SET_FPGA_DIN(data); CCLK();} while (0)

#define FPGA_MCU_RDY_REG          LPC_GPIO2
#define FPGA_MCU_RDY_BIT          9

#define FPGA_CLK_PINSEL           LPC_PINCON->PINSEL0
#define FPGA_CLK_PINSELBIT        21

#define EMR_FPGACLK_EMCxTOGGLE    (3<<4) /* EMC0TOGGLE */
#define MCR_FPGACLK_MRxR          (1<<1) /* MR0R */
#define TMR_FPGACLK_MR            LPC_TIM3->MR0

#define QSORT_MAXELEM             2048
#define SORT_STRLEN               256
#define CLTBL_SIZE                100

#define DIR_FILE_MAX              16380

#define SSP_REGS LPC_SSP0
#define SSP_PCLKREG PCLKSEL1
#define SSP_PCLKBIT 10
#define SSP_DMAID_TX 0
#define SSP_DMAID_RX 1
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

#define SD_DAT (SD_DAT0REG->FIOPIN0)

#define USB_CONNREG LPC_GPIO4
#define USB_CONNBIT 28
#define USB_CONN_MODEREG LPC_PINCON->PINMODE9
#define USB_CONN_MODEBIT 25
#define USB_VBUS_PINSEL LPC_PINCON->PINSEL3
#define USB_VBUS_PINSELBIT 29
#define USB_VBUS_MODEREG LPC_PINCON->PINMODE3
#define USB_VBUS_MODEBIT 29

#define DAC_DEMREG LPC_GPIO1
#define DAC_DEMBIT 24

/* LED connections Mk.II

   LED    color  IO    PWM
   ---------------------------
   ready  green  P2.4  PWM1[5]
   read   yellow P2.5  PWM1[6]
   write  red    P1.23 PWM1[4]
*/


#define LED_READY_REG             LPC_GPIO2
#define LED_READY_BIT             4
#define LED_READ_REG              LPC_GPIO2
#define LED_READ_BIT              5
#define LED_WRITE_REG             LPC_GPIO1
#define LED_WRITE_BIT             23

#define LED_READY_PINSEL          LPC_PINCON->PINSEL4
#define LED_READ_PINSEL           LPC_PINCON->PINSEL4
#define LED_WRITE_PINSEL          LPC_PINCON->PINSEL3

#define LED_READY_PINSELSHIFT      8
#define LED_READ_PINSELSHIFT      10
#define LED_WRITE_PINSELSHIFT     14

#define LED_READY_PINSELVAL       (0b01)
#define LED_READ_PINSELVAL        (0b01)
#define LED_WRITE_PINSELVAL       (0b10)

#define LED_READY_PCRBIT          13
#define LED_READ_PCRBIT           14
#define LED_WRITE_PCRBIT          12

#define LED_READY_MRNUM            5
#define LED_READ_MRNUM             6
#define LED_WRITE_MRNUM            4

#define LED_READY_MR              LPC_PWM1->MR5
#define LED_READ_MR               LPC_PWM1->MR6
#define LED_WRITE_MR              LPC_PWM1->MR4

#define BOOTLDR_SIZE              8192
#endif

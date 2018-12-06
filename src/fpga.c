/* sd2snes - SD card based universal cartridge for the SNES
   Copyright (C) 2009-2010 Maximilian Rehkopf <otakon@gmx.net>
   AVR firmware portion

   Inspired by and based on code from sd2iec, written by Ingo Korb et al.
   See sdcard.c|h, config.h.

   FAT file system access based on code by ChaN, Jim Brain, Ingo Korb,
   see ff.c|h.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License only.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

   fpga.c: FPGA (re)configuration
*/


#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"

#include "fpga.h"
#include "fpga_spi.h"
#include "config.h"
#include "uart.h"
#include "diskio.h"
#include "integer.h"
#include "ff.h"
#include "fileops.h"
#include "spi.h"
#include "led.h"
#include "timer.h"
#include "rle.h"
#include "cfgware.h"

void fpga_set_prog_b(uint8_t val) {
  if(val)
    BITBAND(FPGA_PROGBREG->FIOSET, FPGA_PROGBBIT) = 1;
  else
    BITBAND(FPGA_PROGBREG->FIOCLR, FPGA_PROGBBIT) = 1;
}

void fpga_set_cclk(uint8_t val) {
  if(val)
    BITBAND(FPGA_CCLKREG->FIOSET, FPGA_CCLKBIT) = 1;
  else
    BITBAND(FPGA_CCLKREG->FIOCLR, FPGA_CCLKBIT) = 1;
}

int fpga_get_initb() {
  return BITBAND(FPGA_INITBREG->FIOPIN, FPGA_INITBBIT);
}

void fpga_init() {
/* mainly GPIO directions */
  BITBAND(FPGA_CCLKREG->FIODIR, FPGA_CCLKBIT) = 1; /* CCLK */
  BITBAND(FPGA_DONEREG->FIODIR, FPGA_DONEBIT) = 0; /* DONE */
  BITBAND(FPGA_PROGBREG->FIODIR, FPGA_PROGBBIT) = 1; /* PROG_B */
  BITBAND(FPGA_DINREG->FIODIR, FPGA_DINBIT) = 1; /* DIN */
  BITBAND(FPGA_INITBREG->FIODIR, FPGA_INITBBIT) = 0; /* INIT_B */

  LPC_GPIO2->FIOMASK1 = 0;

  SPI_OFFLOAD=0;
  fpga_set_cclk(0);    /* initial clk=0 */
}

int fpga_get_done(void) {
  return BITBAND(FPGA_DONEREG->FIOPIN, FPGA_DONEBIT);
}

void fpga_postinit() {
  LPC_GPIO2->FIOMASK1 = 0;
  BITBAND(FPGA_DINREG->FIODIR, FPGA_DINBIT) = 0; /* DATA0 -> MCU_RDY */
}

void fpga_pgm(uint8_t* filename) {
  int MAXRETRIES = 10;
  int retries = MAXRETRIES;
  uint8_t data;
  int i;
  tick_t timeout;
  /* open configware file */
  file_open(filename, FA_READ);
  if(file_res) {
    uart_putc('?');
    uart_putc(0x30+file_res);
    return;
  }
  fpga_init();
  do {
    printf("fpga_pgm: configuring FPGA, attempts left: %d\n", retries);
    i=0;
    timeout = getticks() + 1;
    fpga_set_prog_b(0);
    while(BITBAND(FPGA_PROGBREG->FIOPIN, FPGA_PROGBBIT)) {
      if(getticks() > timeout) {
        printf("fpga_pgm: PROGB is stuck high!\n");
        led_panic(LED_PANIC_FPGA_PROGB_STUCK);
      }
    }
    timeout = getticks() + 100;
    uart_putc('P');
    fpga_set_prog_b(1);
    while(!fpga_get_initb()){
      if(getticks() > timeout) {
        printf("fpga_pgm: no response from FPGA trying to initiate configuration!\n");
        led_panic(LED_PANIC_FPGA_NO_INITB);
      }
    };
    timeout = getticks() + 100;
    while(fpga_get_done()) {
      if(getticks() > timeout) {
        printf("fpga_pgm: DONE is stuck high!\n");
        led_panic(LED_PANIC_FPGA_DONE_STUCK);
      }
    }
    LPC_GPIO2->FIOMASK1 = ~(BV(0));
    uart_putc('p');

    uart_putc('C');
    for (;;) {
      data = rle_file_getc();
      i++;
      if (file_status || file_res) break;   /* error or eof */
      FPGA_SEND_BYTE_SERIAL(data);
    }
    uart_putc('c');
    file_close();
    printf("fpga_pgm: %d bytes programmed\n", i);
    timeout = getticks() + 100;
    while(!fpga_get_done()) {
      if(getticks() > timeout) {
        printf("fpga_pgm: no DONE from FPGA! Retrying\n");
        break;
      }
    }
    CCLK(); CCLK(); CCLK();
    delay_ms(1);
  } while (!fpga_get_done() && retries--);
  if(!fpga_get_done()) {
    printf("fpga_pgm: FPGA failed to configure after %d tries.\n", MAXRETRIES);
    led_panic(LED_PANIC_FPGA_NOCONF);
  }
  printf("FPGA configured\n");
  fpga_config = filename;
  fpga_postinit();
}

void fpga_rompgm() {
  int MAXRETRIES = 10;
  int retries = MAXRETRIES;
  uint8_t data;
  int i;
  tick_t timeout;
  fpga_init();
  do {
    i=0;
    timeout = getticks() + 100;
    fpga_set_prog_b(0);
    uart_putc('P');
    fpga_set_prog_b(1);
    while(!fpga_get_initb()){
      if(getticks() > timeout) {
        printf("no response from FPGA trying to initiate configuration!\n");
        led_panic(LED_PANIC_FPGA_NO_INITB);
      }
    };
    timeout = getticks() + 100;
    while(fpga_get_done()) {
      if(getticks() > timeout) {
        printf("DONE is stuck high!\n");
        led_panic(LED_PANIC_FPGA_DONE_STUCK);
      }
    }
    LPC_GPIO2->FIOMASK1 = ~(BV(0));
    uart_putc('p');

    /* open configware file */
    rle_mem_init(cfgware, sizeof(cfgware));
    printf("sizeof(cfgware) = %d\n", sizeof(cfgware));
    for (;;) {
      data = rle_mem_getc();
      if(rle_state) break;
      i++;
      FPGA_SEND_BYTE_SERIAL(data);
    }
    uart_putc('c');
    printf("fpga_rompgm: %d bytes programmed\n", i);
    delay_ms(1);
  } while (!fpga_get_done() && retries--);
  if(!fpga_get_done()) {
    printf("FPGA failed to configure after %d tries.\n", MAXRETRIES);
    led_panic(LED_PANIC_FPGA_NOCONF);
  }
  printf("FPGA configured\n");
  fpga_config = FPGA_ROM;
  fpga_postinit();
}


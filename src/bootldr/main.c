#include <arm/NXP/LPC17xx/LPC17xx.h>
#include <string.h>
#include "config.h"
#include "obj/autoconf.h"
#include "clock.h"
#include "uart.h"
#include "bits.h"
#include "power.h"
#include "timer.h"
#include "ff.h"
#include "diskio.h"
#include "led.h"
#include "sdnative.h"
#include "crc.h"
#include "fileops.h"
#include "iap.h"

#define EMC0TOGGLE	(3<<4)
#define MR0R		(1<<1)

int i;

volatile enum diskstates disk_state;
extern volatile tick_t ticks;

int (*chain)(void) = (void*)(FW_START+0x000001c5);

int main(void) {
  SNES_CIC_PAIR_REG->FIODIR = BV(SNES_CIC_PAIR_BIT);
  BITBAND(SNES_CIC_PAIR_REG->FIOSET, SNES_CIC_PAIR_BIT) = 1;
/*  LPC_GPIO2->FIODIR = BV(0) | BV(1) | BV(2); */
//  LPC_GPIO0->FIODIR = BV(16);

 /* connect UART3 on P0[25:26] + SSP0 on P0[15:18] + MAT3.0 on P0[10] */
  LPC_PINCON->PINSEL1 = BV(18) | BV(19) | BV(20) | BV(21) /* UART3 */
                      | BV(3) | BV(5);                    /* SSP0 (FPGA) except SS */
  LPC_PINCON->PINSEL0 = BV(31);                            /* SSP0 */
/*                      | BV(13) | BV(15) | BV(17) | BV(19)  SSP1 (SD) */

 /* pull-down CIC data lines */
  LPC_PINCON->PINMODE0 = BV(0) | BV(1) | BV(2) | BV(3);

  clock_disconnect();
  power_init();
  timer_init();
  DBG_UART uart_init();
  led_init();
  readled(0);
  rdyled(1);
  writeled(0);
 /* do this last because the peripheral init()s change PCLK dividers */
  clock_init();
//  LPC_PINCON->PINSEL0 |= BV(20) | BV(21);                  /* MAT3.0 (FPGA clock) */
  sdn_init();
  DBG_BL printf("chksum=%08lx\n", *(uint32_t*)28);
  DBG_BL printf("\n\nsd2snes mk.2 bootloader\nver.: " VER "\ncpu clock: %ld Hz\n", CONFIG_CPU_FREQUENCY);
DBG_BL printf("PCONP=%lx\n", LPC_SC->PCONP);
/* setup timer (fpga clk) */
  LPC_TIM3->CTCR=0;
  LPC_TIM3->EMR=EMC0TOGGLE;
  LPC_TIM3->MCR=MR0R;
  LPC_TIM3->MR0=1;
  LPC_TIM3->TCR=1;
  NVIC->ICER[0] = 0xffffffff;
  NVIC->ICER[1] = 0xffffffff;
  FLASH_RES res = flash_file((uint8_t*)"/sd2snes/firmware.img");
  if(res == ERR_FLASHPREP || res == ERR_FLASHERASE || res == ERR_FLASH) {
    rdyled(0);
    writeled(1);
  }
  if(res == ERR_FILEHD || res == ERR_FILECHK) {
    rdyled(0);
    readled(1);
  }
  DBG_BL printf("flash result = %d\n", res);
  if(res != ERR_OK) {
    if((res = check_flash()) != ERR_OK) {
      DBG_BL printf("check_flash() failed with error %d, not booting.\n", res);
      while(1) {
        toggle_rdy_led();
        delay_ms(500);
      }
    }
  }
  NVIC_DisableIRQ(RIT_IRQn);
  NVIC_DisableIRQ(UART_IRQ);

  SCB->VTOR=FW_START+0x00000100;
  chain();
  while(1);
}


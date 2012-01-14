/* ___INGO___ */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "config.h"
#include "timer.h"
#include "clock.h"
#include "uart.h"
#include "sdnative.h"
#include "snes.h"
#include "led.h"
/* bit definitions */
#define RITINT 0
#define RITEN  3

#define PCRIT 16

extern volatile int sd_changed;
extern volatile int reset_changed;
volatile tick_t ticks;
volatile int wokefromrit;

void __attribute__((weak,noinline)) SysTick_Hook(void) {
  /* Empty function for hooking the systick handler */
}

/* Systick interrupt handler */
void SysTick_Handler(void) {
  ticks++;
  static uint16_t sdch_state = 0;
  static uint16_t reset_state = 0;
  static uint16_t led_test_state = 0;
  sdch_state = (sdch_state << 1) | SDCARD_DETECT | 0xe000;
  if((sdch_state == 0xf000) || (sdch_state == 0xefff)) {
    sd_changed = 1;
  }
  reset_state = (reset_state << 1) | get_snes_reset() | 0xe000;
  if((reset_state == 0xf000) || (reset_state == 0xefff)) {
    reset_changed = 1;
  }
  switch(led_test_state&0xc0) {
    case 0xc0: led_test_state = 0; break;
    case 0x00:
      rdyled(1);
      readled(0);
      writeled(0);
      break;

    case 0x40:
      rdyled(0);
      readled(1);
      writeled(0);
      break;

    case 0x80:
      rdyled(0);
      readled(0);
      writeled(1);
      break;
  }
//  led_test_state++;
  sdn_changed();
  SysTick_Hook();
}

void __attribute__((weak,noinline)) RIT_Hook(void) {
}

void RIT_IRQHandler(void) {
  LPC_RIT->RICTRL = BV(RITINT);
  NVIC_ClearPendingIRQ(RIT_IRQn);
  wokefromrit = 1;
  RIT_Hook();
}

void timer_init(void) {
  /* turn on power to RIT */
  BITBAND(LPC_SC->PCONP, PCRIT) = 1;

  /* clear RIT mask */
  LPC_RIT->RIMASK = 0; /*xffffffff;*/

  /* PCLK = CCLK */
  BITBAND(LPC_SC->PCLKSEL1, 26) = 1;
  BITBAND(LPC_SC->PCLKSEL1, PCLK_TIMER3) = 1;
  /* enable SysTick */
  SysTick_Config((SysTick->CALIB & SysTick_CALIB_TENMS_Msk));
}

void delay_us(unsigned int time) {
  /* Prepare RIT */
  LPC_RIT->RICOUNTER = 0;
  LPC_RIT->RICOMPVAL = (CONFIG_CPU_FREQUENCY / 1000000) * time;
  LPC_RIT->RICTRL    = BV(RITEN) | BV(RITINT);

  /* Wait until RIT signals an interrupt */
  while (!(BITBAND(LPC_RIT->RICTRL, RITINT))) ;

  /* Disable RIT */
  LPC_RIT->RICTRL = 0;
}

void delay_ms(unsigned int time) {
  /* Prepare RIT */
  LPC_RIT->RICOUNTER = 0;
  LPC_RIT->RICOMPVAL = (CONFIG_CPU_FREQUENCY / 1000) * time;
  LPC_RIT->RICTRL    = BV(RITEN) | BV(RITINT);

  /* Wait until RIT signals an interrupt */
  while (!(BITBAND(LPC_RIT->RICTRL, RITINT))) ;

  /* Disable RIT */
  LPC_RIT->RICTRL = 0;
}

void sleep_ms(unsigned int time) {

  wokefromrit = 0;
  /* Prepare RIT */
  LPC_RIT->RICOUNTER = 0;
  LPC_RIT->RICOMPVAL = (CONFIG_CPU_FREQUENCY / 1000) * time;
  LPC_RIT->RICTRL    = BV(RITEN) | BV(RITINT);
  NVIC_EnableIRQ(RIT_IRQn);

  /* Wait until RIT signals an interrupt */
//uart_putc(';');
  while(!wokefromrit) {
    __WFI();
  }
  NVIC_DisableIRQ(RIT_IRQn);
  /* Disable RIT */
  LPC_RIT->RICTRL = BV(RITINT);
}

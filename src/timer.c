/* ___INGO___ */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "config.h"
#include "timer.h"
#include "clock.h"


/* bit definitions */
#define RITINT 0
#define RITEN  3

#define PCRIT 16

volatile tick_t ticks;
extern uint32_t f_cpu;

void __attribute__((weak,noinline)) SysTick_Hook(void) {
  // Empty function for hooking the systick handler
}

/* Systick interrupt handler */
void SysTick_Handler(void) {
  ticks++;
  SysTick_Hook();
}

void timer_init(void) {
  /* turn on power to RIT */
  BITBAND(LPC_SC->PCONP, PCRIT) = 1;

  /* clear RIT mask */
  LPC_RIT->RIMASK = 0; //xffffffff;

  /* PCLK = CCLK */
  BITBAND(LPC_SC->PCLKSEL1, 26) = 1;
  BITBAND(LPC_SC->PCLKSEL1, PCLK_TIMER3) = 1;
  /* enable SysTick */
  SysTick_Config(SysTick->CALIB & SysTick_CALIB_TENMS_Msk);
}

extern int testval;

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
  LPC_RIT->RICTRL    = BV(RITEN) | BV(RITINT);
  LPC_RIT->RICOMPVAL = (f_cpu / 1000) * time;

  /* Wait until RIT signals an interrupt */
  while (!(BITBAND(LPC_RIT->RICTRL, RITINT))) ;

  /* Disable RIT */
  LPC_RIT->RICTRL = 0;
}

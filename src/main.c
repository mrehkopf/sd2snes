#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "clock.h"
#include "uart.h"
#include "lpc.h"

#define EMC0TOGGLE	(3<<4)
#define MR0R		(1<<1)
#define PCTIM3		(1<<23)

int i;

int main(void) {
  LPC_GPIO2->FIODIR = BV(0) | BV(1) | BV(2);
  LPC_GPIO1->FIODIR = 0;
  uint32_t p1;


  clock_init();
  uart_init();

/* setup timer (fpga clk) */
  LPC_SC->PCONP |= PCTIM3;	/* enable power */
  LPC_TIM3->CTCR=0;
  LPC_TIM3->EMR=EMC0TOGGLE;
  LPC_PINCON->PINSEL0=(0x3<<20);
  LPC_TIM3->MCR=MR0R;
  LPC_TIM3->MR0=1;
  LPC_TIM3->TCR=1;
  

  while (1) {
    p1 = LPC_GPIO1->FIOPIN;
    BITBAND(LPC_GPIO2->FIOPIN, 0) = (p1 & BV(29))>>29;
  }
}

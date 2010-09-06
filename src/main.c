/* The classic embedded version of "Hello World": A blinking LED */
#include <arm/NXP/LPC17xx/LPC17xx.h>

#define BV(x) (1<<(x))
#define BITBAND(addr,bit) (*((volatile unsigned long *)(((unsigned long)&(addr)-0x20000000)*32 + bit*4 + 0x22000000)))
#define PLL_MULT(x)	((x)&0x7fff)
#define PLL_PREDIV(x)	(((x)<<16)&0xff0000)
#define CLKSRC_MAINOSC	(1)
#define PLLE0		(1<<0)
#define PLLC0		(1<<1)
#define PLOCK0		(1<<26)
#define OSCEN		(1<<5)
#define OSCSTAT		(1<<6)
#define EMC0TOGGLE	(3<<4)
#define MR0R		(1<<1)
#define FLASH5C		(0x403A)
#define PCTIM3		(1<<23)

#define PCLK_CCLK(x)	(1<<(x))
#define PCLK_CCLK4(x)	(0)
#define PCLK_CCLK8(x)	(3<<(x))
#define PCLK_CCLK2(x)	(2<<(x))
#define PCLK_TIMER3	(14)

int i;

int main(void) {
  LPC_GPIO2->FIODIR = BV(0) | BV(1) | BV(2);
  LPC_GPIO1->FIODIR = 0;
  uint32_t p1;

/* setup PLL0 */
  LPC_SC->FLASHCFG=FLASH5C;
  LPC_SC->PLL0CON &= ~PLLC0;
  LPC_SC->PLL0FEED=0xaa;
  LPC_SC->PLL0FEED=0x55;
  LPC_SC->PLL0CON &= ~PLLE0;
  LPC_SC->PLL0FEED=0xaa;
  LPC_SC->PLL0FEED=0x55;

/* PLL is disabled and disconnected. setup PCLK NOW as it cannot be changed
   reliably with PLL0 connected.
   see:
   http://ics.nxp.com/support/documents/microcontrollers/pdf/errata.lpc1754.pdf
*/
  LPC_SC->PCLKSEL1=PCLK_CCLK(PCLK_TIMER3);
  
/* continue with PLL0 setup */
  LPC_SC->SCS=OSCEN;
  while(!(LPC_SC->SCS&OSCSTAT));
  LPC_SC->CLKSRCSEL=CLKSRC_MAINOSC;
  LPC_SC->PLL0CFG=PLL_MULT(428)|PLL_PREDIV(18);
  LPC_SC->PLL0FEED=0xaa;
  LPC_SC->PLL0FEED=0x55;
  LPC_SC->PLL0CON |= PLLE0;
  LPC_SC->PLL0FEED=0xaa;
  LPC_SC->PLL0FEED=0x55;
  LPC_SC->CCLKCFG=5;
  while(!(LPC_SC->PLL0STAT&PLOCK0));
  LPC_SC->PLL0CON |= PLLC0;
  LPC_SC->PLL0FEED=0xaa;
  LPC_SC->PLL0FEED=0x55;

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
    BITBAND(LPC_GPIO2->FIOSET, 2) = 1;
    for (i=0;i<100000;i++)
      __NOP();
    BITBAND(LPC_GPIO2->FIOCLR, 2) = 1;
    for (i=0;i<100000;i++)
      __NOP();
  }
}

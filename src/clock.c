/* ___DISCLAIMER___ */

/* clock.c: PLL, CCLK, PCLK controls */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "config.h"
#include "clock.h"
#include "bits.h"
#include "uart.h"

void clock_disconnect() {
  disconnectPLL0();
  disablePLL0();
}

void clock_init() {

/* set flash access time to 5 clks (80<f<=100MHz) */
  setFlashAccessTime(5);

/* setup PLL0 for 86MHz
   Base clock: 12MHz
   Multiplier:   23
   Pre-Divisor:   2
   Divisor:       6
   First, disable and disconnect PLL0.
*/
  clock_disconnect();

/* PLL is disabled and disconnected. setup PCLK NOW as it cannot be changed
   reliably with PLL0 connected.
   see:
   http://ics.nxp.com/support/documents/microcontrollers/pdf/errata.lpc1754.pdf
*/


/* continue with PLL0 setup:
   enable the xtal oscillator and wait for it to become stable
   set the oscillator as clk source for PLL0
   set PLL0 multiplier+predivider
   enable PLL0
   set CCLK divider
   wait for PLL0 to lock
   connect PLL0
   done
 */
  enableMainOsc();
  setClkSrc(CLKSRC_MAINOSC);
  setPLL0MultPrediv(CONFIG_CLK_MULT, CONFIG_CLK_PREDIV);
  enablePLL0();
  setCCLKDiv(CONFIG_CLK_CCLKDIV);
  connectPLL0();


/* configure PLL1 for USB operation */
  disconnectPLL1();
  disablePLL1();
  LPC_SC->PLL1CFG = 0x23;
  enablePLL1();
  connectPLL1();

}

void setFlashAccessTime(uint8_t clocks) {
  LPC_SC->FLASHCFG=FLASHTIM(clocks);
}

void setPLL0MultPrediv(uint16_t mult, uint8_t prediv) {
  LPC_SC->PLL0CFG=PLL_MULT(mult) | PLL_PREDIV(prediv);
  PLL0feed();
}

void enablePLL0() {
  LPC_SC->PLL0CON |= PLLE0;
  PLL0feed();
}

void disablePLL0() {
  LPC_SC->PLL0CON &= ~PLLE0;
  PLL0feed();
}

void connectPLL0() {
  while(!(LPC_SC->PLL0STAT & PLOCK0));
  LPC_SC->PLL0CON |= PLLC0;
  PLL0feed();
}

void disconnectPLL0() {
  LPC_SC->PLL0CON &= ~PLLC0;
  PLL0feed();
}

void setPLL1MultPrediv(uint16_t mult, uint8_t prediv) {
  LPC_SC->PLL1CFG=PLL_MULT(mult) | PLL_PREDIV(prediv);
  PLL1feed();
}

void enablePLL1() {
  LPC_SC->PLL1CON |= PLLE1;
  PLL1feed();
}

void disablePLL1() {
  LPC_SC->PLL1CON &= ~PLLE1;
  PLL1feed();
}

void connectPLL1() {
  while(!(LPC_SC->PLL1STAT & PLOCK1));
  LPC_SC->PLL1CON |= PLLC1;
  PLL1feed();
}

void disconnectPLL1() {
  LPC_SC->PLL1CON &= ~PLLC1;
  PLL1feed();
}

void setCCLKDiv(uint8_t div) {
  LPC_SC->CCLKCFG=CCLK_DIV(div);
}

void enableMainOsc() {
  LPC_SC->SCS=OSCEN;
  while(!(LPC_SC->SCS&OSCSTAT));
}

void disableMainOsc() {
  LPC_SC->SCS=0;
}

void PLL0feed() {
  LPC_SC->PLL0FEED=0xaa;
  LPC_SC->PLL0FEED=0x55;
}

void PLL1feed() {
  LPC_SC->PLL1FEED=0xaa;
  LPC_SC->PLL1FEED=0x55;
}

void setClkSrc(uint8_t src) {
  LPC_SC->CLKSRCSEL=src;
}

/* ___DISCLAIMER___ */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "timer.h"

void rdyled(unsigned int state) {
  BITBAND(LPC_GPIO2->FIODIR, 0) = state;
}

void readled(unsigned int state) {
  BITBAND(LPC_GPIO2->FIODIR, 1) = state;
}

void led_clkout32(uint32_t val) {
  while(1) {
    rdyled(1);
    delay_ms(400);
    readled((val & BV(31))>>31);
    rdyled(0);
    val<<=1;
    delay_ms(400);
  }
}

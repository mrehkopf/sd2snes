/* ___DISCLAIMER___ */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "power.h"


void power_init() {
  LPC_SC->PCONP |= (BV(PCTIM3) | BV(PCUART3));
}

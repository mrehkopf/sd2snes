#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "config.h"
#include "sdnative.h"
#include "uart.h"

void EINT3_IRQHandler(void) {
  NVIC_ClearPendingIRQ(EINT3_IRQn);
  if(SD_CHANGE_DETECT) {
    SD_CHANGE_CLR();
    sdn_changed();
  }
}



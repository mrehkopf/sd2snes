/* ___DISCLAIMER___ */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "power.h"

/*
   required units:
   * SSP0 (FPGA interface) [enabled via spi_init]
   * UART3 (debug console) [enabled via uart_init]
   * TIM3 (FPGA clock)
   * RTC
   * GPIO
   * GPDMA [enabled via spi_init]
   * USB [enabled via usb_init]
   * PWM1
*/
void power_init() {
  LPC_SC->PCONP = BV(PCSSP0)
                | BV(PCTIM3)
                | BV(PCRTC)
                | BV(PCGPIO)
                | BV(PCPWM1)
//                 | BV(PCUSB)
  ;
}

/* ___DISCLAIMER___ */

#include "config.h"
#include "bits.h"
#include "power.h"

/*
   required units:
   * SPI1 (FPGA interface)
   * UART2 (debug console) [enabled via uart_init]
   * TIM3 (LED PWM)
   * RTC
   * GPIO
   * GPDMA
   * USB [enabled via USB_Init]
   * TIM2 (delay_[um]s) [enabled via timer_init]
*/
void power_init() {
  /* enable FPU */
  SCB->CPACR |= 0x00f00000;

  /* enable peripherals on AHB1:
     GPIO, DMA2 */
  RCC->AHB1ENR = RCC_AHB1ENR_GPIOAEN
               | RCC_AHB1ENR_GPIOBEN
               | RCC_AHB1ENR_GPIOCEN
               | RCC_AHB1ENR_GPIODEN
               | RCC_AHB1ENR_GPIOHEN
               | RCC_AHB1ENR_DMA2EN;

  /* enable peripherals on APB1:
     TIM3, PWR control */
  RCC->APB1ENR = RCC_APB1ENR_TIM3EN
               | RCC_APB1ENR_PWREN;

  /* enable peripherals on APB2:
     SPI1, SYSCFG */
  RCC->APB2ENR = RCC_APB2ENR_SPI1EN
               | RCC_APB2ENR_SYSCFGEN;

  /* unlock backup domain */
  PWR->CR |= PWR_CR_DBP;
}

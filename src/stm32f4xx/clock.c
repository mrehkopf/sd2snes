/* ___DISCLAIMER___ */

/* clock.c: PLL, CCLK, PCLK controls */

#include "config.h"
#include "clock.h"
#include "bits.h"
#include "uart.h"

void clock_disconnect() {
 // do we need this on STM32?
}

void clock_init() {
/* set flash access time to 2 WS */
  setFlashAccessTime(FLASH_ACR_LATENCY_2WS);
  enableHSE();
  setupPLL(RCC_PLLCFGR_PLLSRC_HSE, CONFIG_CLK_PREDIV, CONFIG_CLK_MULT, CONFIG_CLK_CCLKDIV, CONFIG_USB_DIV);
  enablePLL();
  RCC->CFGR = RCC_CFGR_SW_PLL | RCC_CFGR_PPRE1_DIV2 | RCC_CFGR_MCO1_DIV1 | RCC_CFGR_MCO1_HSE;
  RCC->BDCR |= RCC_BDCR_LSEON;
  while(!(RCC->BDCR & RCC_BDCR_LSERDY));
  RCC->BDCR |= RCC_BDCR_RTCSEL_0 | RCC_BDCR_RTCEN;
  enableCache();
 /* MCO1 (FPGA clock) */
  GPIO_SEL_AF(FPGA_CLK_REG, FPGA_CLK_BIT, 0);
  GPIO_MODE_AF(FPGA_CLK_REG, FPGA_CLK_BIT);
}

void enableCache() {
  FLASH->ACR |= FLASH_ACR_ICEN | FLASH_ACR_DCEN | FLASH_ACR_PRFTEN;
}

void enableHSE() {
  RCC->CR |= RCC_CR_HSEON;
  while(!(RCC->CR & RCC_CR_HSERDY));
}

void setFlashAccessTime(uint8_t clocks) {
  FLASH->ACR = (FLASH->ACR & 0xfffffff0) | clocks;
}

void enablePLL() {
  RCC->CR |= RCC_CR_PLLON;
  while(!(RCC->CR & RCC_CR_PLLRDY));
}

void setupPLL(uint32_t src, uint32_t prediv, uint32_t mult, uint32_t sysclk_div, uint32_t usbclk_div) {
  sysclk_div = (sysclk_div / 2) - 1;
  RCC->PLLCFGR = (src & RCC_PLLCFGR_PLLSRC_Msk)
                | ((prediv     << RCC_PLLCFGR_PLLM_Pos) & RCC_PLLCFGR_PLLM_Msk)
                | ((mult       << RCC_PLLCFGR_PLLN_Pos) & RCC_PLLCFGR_PLLN_Msk)
                | ((sysclk_div << RCC_PLLCFGR_PLLP_Pos) & RCC_PLLCFGR_PLLP_Msk)
                | ((usbclk_div << RCC_PLLCFGR_PLLQ_Pos) & RCC_PLLCFGR_PLLQ_Msk);
}

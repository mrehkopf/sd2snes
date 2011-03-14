#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "config.h"
#include "uart.h"

void HardFault_Handler(void) {
  DBG_BL printf("HFSR: %lx\n", SCB->HFSR);
  DBG_UART uart_putc('H');
  while (1) ;
}

void MemManage_Handler(void) {
  DBG_BL printf("MemManage - CFSR: %lx; MMFAR: %lx\n", SCB->CFSR, SCB->MMFAR);
}

void BusFault_Handler(void) {
  DBG_BL printf("BusFault - CFSR: %lx; BFAR: %lx\n", SCB->CFSR, SCB->BFAR);
}

void UsageFault_Handler(void) {
  DBG_BL printf("UsageFault - CFSR: %lx; BFAR: %lx\n", SCB->CFSR, SCB->BFAR);
}


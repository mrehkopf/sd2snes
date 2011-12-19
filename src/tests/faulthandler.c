#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "uart.h"

void HardFault_Handler(void) {
  printf("HFSR: %lx\n", SCB->HFSR);
  while (1) ;
}

void MemManage_Handler(void) {
  printf("MemManage - CFSR: %lx; MMFAR: %lx\n", SCB->CFSR, SCB->MMFAR);
}

void BusFault_Handler(void) {
  printf("BusFault - CFSR: %lx; BFAR: %lx\n", SCB->CFSR, SCB->BFAR);
}

void UsageFault_Handler(void) {
  printf("UsageFault - CFSR: %lx; BFAR: %lx\n", SCB->CFSR, SCB->BFAR);
}


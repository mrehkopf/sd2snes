#ifndef LPC17XX_FLASH_H
#define LPC17XX_FLASH_H

#include <arm/core_cm3.h>

/*------------- Flash Control (FMC) -------------*/
typedef struct
{
       uint32_t RESERVED0[8];
  __IO uint32_t FMSSTART;
  __IO uint32_t FMSSTOP;
  __I  uint32_t FMSW0;
  __I  uint32_t FMSW1;
  __I  uint32_t FMSW2;
  __I  uint32_t FMSW3;
       uint32_t RESERVED1[1002];
  __I  uint32_t FMSTAT;
       uint32_t RESERVED2;
  __O  uint32_t FMSTATCLR;
} LPC_FMC_TypeDef;

#define LPC_FMC_BASE (LPC_APB1_BASE + 0x04000)
#define LPC_FMC      ((LPC_FMC_TypeDef*) LPC_FMC_BASE)

#endif

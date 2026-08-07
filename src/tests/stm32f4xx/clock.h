#ifndef _CLOCK_H
#define _CLOCK_H

#define RCC_CFGR_MCO1_DIV1  (0x00000000U)
#define RCC_CFGR_MCO1_DIV2  (0x04000000U)
#define RCC_CFGR_MCO1_DIV3  (0x05000000U)
#define RCC_CFGR_MCO1_DIV4  (0x06000000U)
#define RCC_CFGR_MCO1_DIV5  (0x07000000U)

#define RCC_CFGR_MCO1_HSI (0x00000000U)
#define RCC_CFGR_MCO1_LSE (0x00200000U)
#define RCC_CFGR_MCO1_HSE (0x00400000U)
#define RCC_CFGR_MCO1_PLL (0x00600000U)

void clock_disconnect(void);

void clock_init(void);

void setFlashAccessTime(uint8_t clocks);

void setupPLL(uint32_t src, uint32_t prediv, uint32_t mult, uint32_t sysclk_div, uint32_t usbclk_div);

void enablePLL(void);

void enableHSE(void);

void enableCache(void);

#endif

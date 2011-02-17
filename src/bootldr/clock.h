#ifndef _CLOCK_H
#define _CLOCK_H

#define PLL_MULT(x)     ((x-1)&0x7fff)
#define PLL_PREDIV(x)   (((x-1)<<16)&0xff0000)
#define CCLK_DIV(x)     ((x-1)&0xff)
#define CLKSRC_MAINOSC  (1)
#define PLLE0           (1<<0)
#define PLLC0           (1<<1)
#define PLOCK0          (1<<26)
#define OSCEN           (1<<5)
#define OSCSTAT         (1<<6)
#define FLASHTIM(x)     (((x-1)<<12)|0x3A)

#define PCLK_CCLK(x)    (1<<(x))
#define PCLK_CCLK4(x)   (0)
#define PCLK_CCLK8(x)   (3<<(x))
#define PCLK_CCLK2(x)   (2<<(x))

/* shift values for use with PCLKSEL0 */
#define PCLK_WDT	(0)
#define PCLK_TIMER0	(2)
#define PCLK_TIMER1	(4)
#define PCLK_UART0	(6)
#define PCLK_UART1	(8)
#define PCLK_PWM1	(12)
#define PCLK_I2C0	(14)
#define PCLK_SPI	(16)
#define PCLK_SSP1	(20)
#define PCLK_DAC	(22)
#define PCLK_ADC	(24)
#define PCLK_CAN1	(26)
#define PCLK_CAN2	(28)
#define PCLK_ACF	(30)

/* shift values for use with PCLKSEL1 */
#define PCLK_QEI	(0)
#define PCLK_GPIOINT	(2)
#define PCLK_PCB	(4)
#define PCLK_I2C1	(6)
#define PCLK_SSP0	(10)
#define PCLK_TIMER2	(12)
#define PCLK_TIMER3     (14)
#define PCLK_UART2	(16)
#define PCLK_UART3	(18)
#define PCLK_I2C2	(20)
#define PCLK_I2S	(22)
#define PCLK_RIT	(26)
#define PCLK_SYSCON	(28)
#define PCLK_MC		(30)

void clock_disconnect(void);

void clock_init(void);

void setFlashAccessTime(uint8_t clocks);

void setPLL0MultPrediv(uint16_t mult, uint8_t prediv);

void enablePLL0(void);

void disablePLL0(void);

void connectPLL0(void);

void disconnectPLL0(void);

void setCCLKDiv(uint8_t div);

void enableMainOsc(void);

void disableMainOsc(void);

void PLL0feed(void);

void setClkSrc(uint8_t src);


#endif

/* ___DISCLAIMER___ */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "timer.h"
#include "led.h"

static uint8_t led_bright[16]={255,253,252,251,249,247,244,239,232,223,210,191,165,127,74,0};

int led_rdyledstate = 0;
int led_readledstate = 0;
int led_writeledstate = 0;
int led_pwmstate = 0;

void rdyled(unsigned int state) {
  if(led_pwmstate) {
    rdybright(state?15:0);
  } else {
    BITBAND(LPC_GPIO2->FIODIR, 0) = state;
  }
  led_rdyledstate = state;
}

void readled(unsigned int state) {
  if(led_pwmstate) {
    readbright(state?15:0);
  } else {
    BITBAND(LPC_GPIO2->FIODIR, 1) = state;
  }
  led_readledstate = state;
}

void writeled(unsigned int state) {
  if(led_pwmstate) {
    writebright(state?15:0);
  } else {
    BITBAND(LPC_GPIO2->FIODIR, 2) = state;
  }
  led_writeledstate = state;
}

void rdybright(uint8_t bright) {
  LPC_PWM1->MR1 = led_bright[(bright & 15)];
  BITBAND(LPC_PWM1->LER, 1) = 1;
}
void readbright(uint8_t bright) {
  LPC_PWM1->MR2 = led_bright[(bright & 15)];
  BITBAND(LPC_PWM1->LER, 2) = 1;
}
void writebright(uint8_t bright) {
  LPC_PWM1->MR3 = led_bright[(bright & 15)];
  BITBAND(LPC_PWM1->LER, 3) = 1;
}

void led_clkout32(uint32_t val) {
  while(1) {
    rdyled(1);
    delay_ms(400);
    readled((val & BV(31))>>31);
    rdyled(0);
    val<<=1;
    delay_ms(400);
  }
}

void toggle_rdy_led() {
  rdyled(~led_rdyledstate);
}

void toggle_read_led() {
  readled(~led_readledstate);
}

void toggle_write_led() {
  writeled(~led_writeledstate);
}

void led_panic() {
  while(1) {
    LPC_GPIO2->FIODIR |= BV(0) | BV(1) | BV(2);
    delay_ms(350);
    LPC_GPIO2->FIODIR &= ~(BV(0) | BV(1) | BV(2));
    delay_ms(350);
  }
}

void led_pwm() {
/* connect PWM to P2.0 - P2.2 */
/* XXX Rev.B P2.???? */
  BITBAND(LPC_PINCON->PINSEL4, 1) = 0;
  BITBAND(LPC_PINCON->PINSEL4, 3) = 0;
  BITBAND(LPC_PINCON->PINSEL4, 5) = 0;

  BITBAND(LPC_PINCON->PINSEL4, 0) = 1;
  BITBAND(LPC_PINCON->PINSEL4, 2) = 1;
  BITBAND(LPC_PINCON->PINSEL4, 4) = 1;
 
  BITBAND(LPC_PWM1->PCR, 9) = 1;
  BITBAND(LPC_PWM1->PCR, 10) = 1;
  BITBAND(LPC_PWM1->PCR, 11) = 1;

  led_pwmstate = 1;
}

void led_std() {
  BITBAND(LPC_PINCON->PINSEL4, 1) = 0;
  BITBAND(LPC_PINCON->PINSEL4, 3) = 0;
  BITBAND(LPC_PINCON->PINSEL4, 5) = 0;

  BITBAND(LPC_PINCON->PINSEL4, 0) = 0;
  BITBAND(LPC_PINCON->PINSEL4, 2) = 0;
  BITBAND(LPC_PINCON->PINSEL4, 4) = 0;

  BITBAND(LPC_PWM1->PCR, 9) = 0;
  BITBAND(LPC_PWM1->PCR, 10) = 0;
  BITBAND(LPC_PWM1->PCR, 11) = 0;

  led_pwmstate = 0;
}

void led_init() {
/* power is already connected by default */
/* set PCLK divider to 8 */
  BITBAND(LPC_SC->PCLKSEL1, 21) = 1;
  BITBAND(LPC_SC->PCLKSEL1, 20) = 1;
  LPC_PWM1->MR0 = 255;
  BITBAND(LPC_PWM1->LER, 0) = 1;
  BITBAND(LPC_PWM1->TCR, 0) = 1;
  BITBAND(LPC_PWM1->TCR, 3) = 1;
  BITBAND(LPC_PWM1->MCR, 1) = 1;
}

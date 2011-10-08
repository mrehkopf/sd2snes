/* ___DISCLAIMER___ */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "timer.h"
#include "led.h"
#include "cli.h"

static uint8_t led_bright[16]={255,253,252,251,249,247,244,239,232,223,210,191,165,127,74,0};

int led_rdyledstate = 0;
int led_readledstate = 0;
int led_writeledstate = 0;
int led_pwmstate = 0;

/* LED connections (Rev.C)

   LED    color  IO    PWM
   ---------------------------
   ready  green  P2.4  PWM1[5]
   read   yellow P2.5  PWM1[6]
   write  red    P1.23 PWM1[4]
*/

void rdyled(unsigned int state) {
  if(led_pwmstate) {
    rdybright(state?15:0);
  } else {
    BITBAND(LPC_GPIO2->FIODIR, 4) = state;
  }
  led_rdyledstate = state;
}

void readled(unsigned int state) {
  if(led_pwmstate) {
    readbright(state?15:0);
  } else {
    BITBAND(LPC_GPIO2->FIODIR, 5) = state;
  }
  led_readledstate = state;
}

void writeled(unsigned int state) {
  if(led_pwmstate) {
    writebright(state?15:0);
  } else {
    BITBAND(LPC_GPIO1->FIODIR, 23) = state;
  }
  led_writeledstate = state;
}

void rdybright(uint8_t bright) {
  LPC_PWM1->MR5 = led_bright[(bright & 15)];
  BITBAND(LPC_PWM1->LER, 5) = 1;
}
void readbright(uint8_t bright) {
  LPC_PWM1->MR6 = led_bright[(bright & 15)];
  BITBAND(LPC_PWM1->LER, 6) = 1;
}
void writebright(uint8_t bright) {
  LPC_PWM1->MR4 = led_bright[(bright & 15)];
  BITBAND(LPC_PWM1->LER, 4) = 1;
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
    LPC_GPIO2->FIODIR |= BV(4) | BV(5);
    LPC_GPIO1->FIODIR |= BV(23);
    delay_ms(350);
    LPC_GPIO2->FIODIR &= ~(BV(4) | BV(5));
    LPC_GPIO1->FIODIR &= ~BV(23);
    delay_ms(350);
    cli_entrycheck();
  }
}

void led_pwm() {
/* Rev.C P2.4, P2.5, P1.23 */
  BITBAND(LPC_PINCON->PINSEL4, 9) = 0;
  BITBAND(LPC_PINCON->PINSEL4, 8) = 1;

  BITBAND(LPC_PINCON->PINSEL4, 11) = 0;
  BITBAND(LPC_PINCON->PINSEL4, 10) = 1;

  BITBAND(LPC_PINCON->PINSEL3, 15) = 1;
  BITBAND(LPC_PINCON->PINSEL3, 14) = 0;

  BITBAND(LPC_PWM1->PCR, 12) = 1;
  BITBAND(LPC_PWM1->PCR, 13) = 1;
  BITBAND(LPC_PWM1->PCR, 14) = 1;

  led_pwmstate = 1;
}

void led_std() {
  BITBAND(LPC_PINCON->PINSEL4, 9) = 0;
  BITBAND(LPC_PINCON->PINSEL4, 8) = 0;

  BITBAND(LPC_PINCON->PINSEL4, 11) = 0;
  BITBAND(LPC_PINCON->PINSEL4, 10) = 0;

  BITBAND(LPC_PINCON->PINSEL3, 15) = 0;
  BITBAND(LPC_PINCON->PINSEL3, 14) = 0;

  BITBAND(LPC_PWM1->PCR, 12) = 0;
  BITBAND(LPC_PWM1->PCR, 13) = 0;
  BITBAND(LPC_PWM1->PCR, 14) = 0;

  led_pwmstate = 0;
}

void led_init() {
/* power is already connected by default */
/* set PCLK divider to 8 */
  BITBAND(LPC_SC->PCLKSEL0, 13) = 1;
  BITBAND(LPC_SC->PCLKSEL0, 12) = 1;
  LPC_PWM1->MR0 = 255;
  BITBAND(LPC_PWM1->LER, 0) = 1;
  BITBAND(LPC_PWM1->TCR, 0) = 1;
  BITBAND(LPC_PWM1->TCR, 3) = 1;
  BITBAND(LPC_PWM1->MCR, 1) = 1;
}

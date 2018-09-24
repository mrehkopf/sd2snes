/* ___DISCLAIMER___ */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "timer.h"
#include "led.h"
#include "cli.h"
#include "fileops.h"
#include "cfg.h"

static uint16_t led_bright[16]={60000, 59920, 59871, 59794,
                                59669, 59469, 59148, 58633,
                                57806, 56481, 54354, 50942,
                                45469, 36688, 22601,     0};

int led_rdyledstate = 0;
int led_readledstate = 0;
int led_writeledstate = 0;
int led_pwmstate = 0;

extern cfg_t CFG;

/* LED connections (Rev.C)

   LED    color  IO    PWM
   ---------------------------
   ready  green  P2.4  PWM1[5]
   read   yellow P2.5  PWM1[6]
   write  red    P1.23 PWM1[4]
*/

void rdyled(unsigned int state) {
  if(led_pwmstate) {
    rdybright(state ? CFG.led_brightness : 0);
  } else {
    BITBAND(LPC_GPIO2->FIODIR, 4) = state;
  }
  led_rdyledstate = state;
}

void readled(unsigned int state) {
  if(led_pwmstate) {
    readbright(state ? CFG.led_brightness : 0);
  } else {
    BITBAND(LPC_GPIO2->FIODIR, 5) = state;
  }
  led_readledstate = state;
}

void writeled(unsigned int state) {
  if(led_pwmstate) {
    writebright(state ? CFG.led_brightness : 0);
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

void led_panic(uint8_t led_states) {
  led_std();
  while(1) {
    rdyled((led_states >> 2) & 1);
    readled((led_states >> 1) & 1);
    writeled(led_states & 1);
    delay_ms(100);
    rdyled(0);
    readled(0);
    writeled(0);
    delay_ms(100);
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
/* PWM rate 200Hz -> 60000 counts */
  LPC_PWM1->MR0 = 60000;
  BITBAND(LPC_PWM1->LER, 0) = 1;
  BITBAND(LPC_PWM1->TCR, 0) = 1;
  BITBAND(LPC_PWM1->TCR, 3) = 1;
  BITBAND(LPC_PWM1->MCR, 1) = 1;
}

/* LED error display; gets called by systick handler every 10ms */
void led_error() {
  static int led_error_state = 0;
  static int led_error_count = 0, saved_error_count = 0;
  static int framecount = 0, pausecount = 0;
  static int last_file_res = 0;
  if(file_res != last_file_res) {
    led_error_count = file_res;
    saved_error_count = led_error_count;
    last_file_res = file_res;
  }
  if(led_error_count || (led_error_state == 2)) {
    if(framecount == 14) {
      framecount = 0;
      if(led_error_state == 0) {
        led_error_state = 1;
        writeled(1);
      } else if (led_error_state == 1) {
        led_error_count--;
        if(led_error_count == 0) {
          led_error_state = 2;
        } else {
          led_error_state = 0;
        }
        writeled(0);
      } else if (led_error_state == 2) {
        pausecount++;
        if(pausecount == 5) {
          pausecount = 0;
          led_error_state = 0;
          led_error_count = saved_error_count;
        }
      }
    }
    framecount++;
  }
}

void led_set_brightness(uint8_t bright) {
  rdybright(led_rdyledstate ? bright : 0);
  readbright(led_readledstate ? bright : 0);
  writebright(led_writeledstate ? bright : 0);
  CFG.led_brightness = bright;
}
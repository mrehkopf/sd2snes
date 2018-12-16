/* ___DISCLAIMER___ */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "timer.h"
#include "led.h"
#include "cli.h"
#include "fileops.h"
#include "cfg.h"
#include "config.h"

static uint16_t led_bright[16]={60000, 59920, 59871, 59794,
                                59669, 59469, 59148, 58633,
                                57806, 56481, 54354, 50942,
                                45469, 36688, 22601,     0};

int led_rdyledstate = 0;
int led_readledstate = 0;
int led_writeledstate = 0;
int led_pwmstate = 0;

extern cfg_t CFG;

void rdyled(unsigned int state) {
  if(led_pwmstate) {
    rdybright(state ? CFG.led_brightness : 0);
  } else {
    BITBAND(LED_READY_REG->FIODIR, LED_READY_BIT) = state;
  }
  led_rdyledstate = state;
}

void readled(unsigned int state) {
  if(led_pwmstate) {
    readbright(state ? CFG.led_brightness : 0);
  } else {
    BITBAND(LED_READ_REG->FIODIR, LED_READ_BIT) = state;
  }
  led_readledstate = state;
}

void writeled(unsigned int state) {
  if(led_pwmstate) {
    writebright(state ? CFG.led_brightness : 0);
  } else {
    BITBAND(LED_WRITE_REG->FIODIR, LED_WRITE_BIT) = state;
  }
  led_writeledstate = state;
}

void rdybright(uint8_t bright) {
  LED_READY_MR = led_bright[(bright & 15)];
  BITBAND(LPC_PWM1->LER, LED_READY_MRNUM) = 1;
}

void readbright(uint8_t bright) {
  LED_READ_MR = led_bright[(bright & 15)];
  BITBAND(LPC_PWM1->LER, LED_READ_MRNUM) = 1;
}

void writebright(uint8_t bright) {
  LED_WRITE_MR = led_bright[(bright & 15)];
  BITBAND(LPC_PWM1->LER, LED_WRITE_MRNUM) = 1;
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
  LED_READY_PINSEL = (LED_READY_PINSEL & ~(0b11 << LED_READY_PINSELSHIFT))
                      | (LED_READY_PINSELVAL << LED_READY_PINSELSHIFT);
  LED_READ_PINSEL = (LED_READ_PINSEL & ~(0b11 << LED_READ_PINSELSHIFT))
                      | (LED_READ_PINSELVAL << LED_READ_PINSELSHIFT);
  LED_WRITE_PINSEL = (LED_WRITE_PINSEL & ~(0b11 << LED_WRITE_PINSELSHIFT))
                      | (LED_WRITE_PINSELVAL << LED_WRITE_PINSELSHIFT);

  BITBAND(LPC_PWM1->PCR, LED_READY_PCRBIT) = 1;
  BITBAND(LPC_PWM1->PCR, LED_READ_PCRBIT) = 1;
  BITBAND(LPC_PWM1->PCR, LED_WRITE_PCRBIT) = 1;

  BITBAND(LED_READY_REG->FIODIR, LED_READY_BIT) = 1;
  BITBAND(LED_READ_REG->FIODIR, LED_READ_BIT) = 1;
  BITBAND(LED_WRITE_REG->FIODIR, LED_WRITE_BIT) = 1;


  led_pwmstate = 1;
}

void led_std() {
  LED_READY_PINSEL = (LED_READY_PINSEL & ~(0b11 << LED_READY_PINSELSHIFT));
  LED_READ_PINSEL  = (LED_READ_PINSEL  & ~(0b11 << LED_READ_PINSELSHIFT));
  LED_WRITE_PINSEL = (LED_WRITE_PINSEL & ~(0b11 << LED_WRITE_PINSELSHIFT));

  BITBAND(LPC_PWM1->PCR, LED_READY_PCRBIT) = 0;
  BITBAND(LPC_PWM1->PCR, LED_READ_PCRBIT) = 0;
  BITBAND(LPC_PWM1->PCR, LED_WRITE_PCRBIT) = 0;

  led_pwmstate = 0;
}

void led_init() {
/* power is already connected by default */
/* set PCLK divider for PWM1 to CCLK / 8 */
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
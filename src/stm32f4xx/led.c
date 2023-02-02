/* ___DISCLAIMER___ */

#include "config.h"
#include "bits.h"
#include "timer.h"
#include "fileops.h"
#include "led.h"
#include "cli.h"
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

void rdyled(unsigned int state) {
  if(led_pwmstate) {
    rdybright(state ? CFG.led_brightness : 0);
  } else {
    OUT_BIT(LED_READY_REG, LED_READY_BIT, !state);
  }
  led_rdyledstate = state;
}

void readled(unsigned int state) {
  if(led_pwmstate) {
    readbright(state ? CFG.led_brightness : 0);
  } else {
    OUT_BIT(LED_READ_REG, LED_READ_BIT, !state);
  }
  led_readledstate = state;
}

void writeled(unsigned int state) {
  if(led_pwmstate) {
    writebright(state ? CFG.led_brightness : 0);
  } else {
    OUT_BIT(LED_WRITE_REG, LED_WRITE_BIT, !state);
  }
  led_writeledstate = state;
}

void rdybright(uint8_t bright) {
  TIM3->CCR1 = led_bright[(bright & 15)];
}

void readbright(uint8_t bright) {
  TIM3->CCR2 = led_bright[(bright & 15)];
}

void writebright(uint8_t bright) {
  TIM3->CCR3 = led_bright[(bright & 15)];
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
  GPIO_MODE_AF(LED_READY_REG, LED_READY_BIT);
  GPIO_MODE_AF(LED_READ_REG, LED_READ_BIT);
  GPIO_MODE_AF(LED_WRITE_REG, LED_WRITE_BIT);

  led_pwmstate = 1;
}

void led_std() {
  GPIO_MODE_OUT(LED_READY_REG, LED_READY_BIT);
  GPIO_MODE_OUT(LED_READ_REG, LED_READ_BIT);
  GPIO_MODE_OUT(LED_WRITE_REG, LED_WRITE_BIT);

  GPIO_OPENDRAIN(LED_READY_REG, LED_READY_BIT);
  GPIO_OPENDRAIN(LED_READ_REG, LED_READ_BIT);
  GPIO_OPENDRAIN(LED_WRITE_REG, LED_WRITE_BIT);

  led_pwmstate = 0;
}

void led_init() {
  led_std();

  /* set alt. functions for LED pins to TIM3_CHx */
  GPIO_SEL_AF(LED_READY_REG, LED_READY_BIT, 2);
  GPIO_SEL_AF(LED_READ_REG, LED_READ_BIT, 2);
  GPIO_SEL_AF(LED_WRITE_REG, LED_WRITE_BIT, 2);

  /* Counter frequency = PCLK/7 */
  TIM3->PSC = 6;

  /* PWM rate 200Hz -> 60000 counts */
  TIM3->ARR = 59999;

  /* set CH1-CH3 to PWM mode, enable preload */
  TIM3->CCMR1 = (0b110 << TIM_CCMR1_OC1M_Pos) | TIM_CCMR1_OC1PE
              | (0b110 << TIM_CCMR1_OC2M_Pos) | TIM_CCMR1_OC2PE;
  TIM3->CCMR2 = (0b110 << TIM_CCMR2_OC3M_Pos) | TIM_CCMR2_OC3PE;

  /* enable auto-reload preload */
  TIM3->CR1 = TIM_CR1_ARPE_Msk;

  /* latch setting registers */
  TIM3->EGR = TIM_EGR_UG;

  /* enable outputs */
  TIM3->CCER = TIM_CCER_CC1E | TIM_CCER_CC2E | TIM_CCER_CC3E;

  /* start PWM counters */
  BITBAND(TIM3->CR1, TIM_CR1_CEN_Pos) = 1;
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
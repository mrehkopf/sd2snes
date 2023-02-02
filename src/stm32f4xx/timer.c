/* ___INGO___ */

#include "config.h"
#include "power.h"
#include "bits.h"
#include "timer.h"
#include "clock.h"
#include "uart.h"
#include "sdnative.h"
#include "snes.h"
#include "led.h"
#include "cfg.h"
#include "cic.h"

extern volatile int sd_changed;
extern volatile int reset_changed;
extern volatile int reset_pressed;

volatile tick_t ticks;
volatile int wokefromtimer;

void __attribute__((weak,noinline)) SysTick_Hook(void) {
  /* Empty function for hooking the systick handler */
}

/* Systick interrupt handler */
void SysTick_Handler(void) {
  ticks++;
  static int warmup = 0;
  static uint16_t sdch_state = 0;
  static uint16_t reset_state = 0;
  sdch_state = (sdch_state << 1) | SDCARD_DETECT | 0xe000;
  if(warmup > WARMUP_TICKS && ((sdch_state == 0xf000) || (sdch_state == 0xefff))) {
    sd_changed = 1;
  }
  reset_state = (reset_state << 1) | get_snes_reset() | 0xff00;
  if((reset_state == 0xff80) || (reset_state == 0xff7f)) {
    reset_pressed = (reset_state == 0xff7f);
    reset_changed = 1;
    if(reset_pressed) {
      cic_init(0);
    } else {
      cic_init(cfg_is_pair_mode_allowed());
    }
  }
  led_error();
  sdn_changed();
  SysTick_Hook();
  if(warmup <= WARMUP_TICKS) warmup++;
}

void TIM2_IRQHandler(void) {
  BITBAND(TIM2->SR, TIM_SR_UIF_Pos) = 0;
  NVIC_ClearPendingIRQ(TIM2_IRQn);
  wokefromtimer = 1;
}

void timer_init(void) {
  /* turn on power to TIM2 which is used to implement delay_[um]s */
  BITBAND(RCC->APB1ENR, RCC_APB1ENR_TIM2EN_Pos) = 1;

  /* TIM2 settings: generate update IRQ flag */
  TIM2->DIER = TIM_DIER_UIE;

  uint64_t systick_load = (uint64_t)SysTick->CALIB
                        * (uint64_t)CONFIG_CPU_FREQUENCY
                        / SYSTICK_CALIB_CLOCK
                        * SYSTICK_DESIRED_MS
                        / SYSTICK_CALIB_MS;
  // printf("systick load value = %ld\n", (uint32_t)systick_load);
  SysTick_Config(systick_load & SysTick_CALIB_TENMS_Msk);
}

void delay_us(unsigned int time) {
  /* Prepare timer countdown value*/
  TIM2->CNT = (CONFIG_CPU_FREQUENCY / 1000000) * time;

  /* enable timer: update event on underflow only, count down, enable */
  TIM2->CR1 = TIM_CR1_URS | TIM_CR1_DIR | TIM_CR1_CEN;

  /* Wait until timer signals an update event */
  while (!(BITBAND(TIM2->SR, TIM_SR_UIF_Pos)));

  /* Clear update event flag and disable timer */
  BITBAND(TIM2->SR, TIM_SR_UIF_Pos) = 0;
  TIM2->CR1 = 0;
}

void delay_ms(unsigned int time) {
  /* Prepare timer countdown value*/
  TIM2->CNT = (CONFIG_CPU_FREQUENCY / 1000) * time;

  /* enable timer: update event on underflow, count down, enable */
  TIM2->CR1 = TIM_CR1_URS | TIM_CR1_DIR | TIM_CR1_CEN;

  /* Wait until timer signals an update event */
  while (!(BITBAND(TIM2->SR, TIM_SR_UIF_Pos)));

  /* Clear update event flag and disable timer */
  BITBAND(TIM2->SR, TIM_SR_UIF_Pos) = 0;
  TIM2->CR1 = 0;
}


void sleep_ms(unsigned int time) {

  /* clear any pending flags just in case */
  BITBAND(TIM2->SR, TIM_SR_UIF_Pos) = 0;
  NVIC_ClearPendingIRQ(TIM2_IRQn);
  wokefromtimer = 0;

  /* Prepare timer countdown value*/
  TIM2->CNT = (CONFIG_CPU_FREQUENCY / 1000) * time;

  /* enable timer: update event on underflow, count down, enable */
  NVIC_EnableIRQ(TIM2_IRQn);
  TIM2->CR1 = TIM_CR1_URS | TIM_CR1_DIR | TIM_CR1_CEN;

  /* Wait until timer signals an interrupt, ignore other wakeup reasons */
  while(!wokefromtimer) {
    __WFI();
  }

  NVIC_DisableIRQ(TIM2_IRQn);

  /* Disable timer */
  TIM2->CR1 = 0;
}

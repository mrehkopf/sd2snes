#include <arm/NXP/LPC17xx/LPC17xx.h>
#include <arm/bits.h>
#include "config.h"
#include "rtc.h"

rtcstate_t rtc_state;

#define CLKEN  0
#define CTCRST 1

void rtc_init(void) {
  if (LPC_RTC->CCR & BV(CLKEN)) {
    rtc_state = RTC_OK;
  } else {
    rtc_state = RTC_INVALID;
  }
}

void read_rtc(struct tm *time) {
  do {
    time->tm_sec  = LPC_RTC->SEC;
    time->tm_min  = LPC_RTC->MIN;
    time->tm_hour = LPC_RTC->HOUR;
    time->tm_mday = LPC_RTC->DOM;
    time->tm_mon  = LPC_RTC->MONTH;
    time->tm_year = LPC_RTC->YEAR - 1900;
    time->tm_wday = LPC_RTC->DOW;
  } while (time->tm_sec != LPC_RTC->SEC);
}

void set_rtc(struct tm *time) {
  LPC_RTC->CCR   = BV(CTCRST);
  LPC_RTC->SEC   = time->tm_sec;
  LPC_RTC->MIN   = time->tm_min;
  LPC_RTC->HOUR  = time->tm_hour;
  LPC_RTC->DOM   = time->tm_mday;
  LPC_RTC->MONTH = time->tm_mon;
  LPC_RTC->YEAR  = time->tm_year + 1900;
  LPC_RTC->DOW   = time->tm_wday;
  LPC_RTC->CCR   = BV(CLKEN);
}


uint32_t get_fattime(void) {
  struct tm time;

  read_rtc(&time);
  return ((uint32_t)time.tm_year-80) << 25 |
    ((uint32_t)time.tm_mon) << 21 |
    ((uint32_t)time.tm_mday)  << 16 |
    ((uint32_t)time.tm_hour)  << 11 |
    ((uint32_t)time.tm_min)   << 5  |
    ((uint32_t)time.tm_sec)   >> 1;
}

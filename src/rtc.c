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

uint64_t get_bcdtime(void) {
  struct tm time;
  read_rtc(&time);
  uint16_t year = time.tm_year + 1900;

  return ((uint64_t)(time.tm_wday % 7) << 56)
         |((uint64_t)((year / 1000) % 10) << 52)
         |((uint64_t)((year / 100) % 10) << 48)
         |((uint64_t)((year / 10) % 10) << 44)
         |((uint64_t)(year % 10) << 40)
         |((uint64_t)(time.tm_mon / 10) << 36)
         |((uint64_t)(time.tm_mon % 10) << 32)
         |((time.tm_mday / 10) << 28)
         |((time.tm_mday % 10) << 24)
         |((time.tm_hour / 10) << 20)
         |((time.tm_hour % 10) << 16)
         |((time.tm_min / 10) << 12)
         |((time.tm_min % 10) << 8)
         |((time.tm_sec / 10) << 4)
         |(time.tm_sec % 10);
}

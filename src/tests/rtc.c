#include <arm/NXP/LPC17xx/LPC17xx.h>
#include <arm/bits.h>
#include "config.h"
#include "rtc.h"
#include "uart.h"
#include "timer.h"
#include "power.h"

rtcstate_t rtc_state;

#define CLKEN  0
#define CTCRST 1

uint8_t rtc_isvalid(void) {
  if(LPC_RTC->GPREG0 == RTC_MAGIC) {
    return RTC_OK;
  }
  return RTC_INVALID;
}

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
    time->tm_year = LPC_RTC->YEAR;
    time->tm_wday = LPC_RTC->DOW;
  } while (time->tm_sec != LPC_RTC->SEC);
}

uint8_t calc_weekday(struct tm *time) {
  int month = time->tm_mon;
  int year = time->tm_year;
  int day = time->tm_mday;

  /* Variation of Sillke for the Gregorian calendar.
   * http://www.mathematik.uni-bielefeld.de/~sillke/ALGORITHMS/calendar/weekday.c */
  if (month <= 2) {
     month += 10;
     year--;
  } else month -= 2;
  return (83*month/32 + day + year + year/4 - year/100 + year/400) % 7;
}

void set_rtc(struct tm *time) {
  LPC_RTC->CCR   = BV(CTCRST);
  LPC_RTC->SEC   = time->tm_sec;
  LPC_RTC->MIN   = time->tm_min;
  LPC_RTC->HOUR  = time->tm_hour;
  LPC_RTC->DOM   = time->tm_mday;
  LPC_RTC->MONTH = time->tm_mon;
  LPC_RTC->YEAR  = time->tm_year;
  LPC_RTC->DOW   = calc_weekday(time);
  LPC_RTC->CCR   = BV(CLKEN);
  LPC_RTC->GPREG0 = RTC_MAGIC;
}

void invalidate_rtc() {
  LPC_RTC->GPREG0 = 0;
}

uint32_t get_fattime(void) {
  struct tm time;

  read_rtc(&time);
  return ((uint32_t)time.tm_year-1980) << 25 |
    ((uint32_t)time.tm_mon) << 21 |
    ((uint32_t)time.tm_mday)  << 16 |
    ((uint32_t)time.tm_hour)  << 11 |
    ((uint32_t)time.tm_min)   << 5  |
    ((uint32_t)time.tm_sec)   >> 1;
}

uint64_t get_bcdtime(void) {
  struct tm time;
  read_rtc(&time);
  uint16_t year = time.tm_year;

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

void set_bcdtime(uint64_t btime) {
  struct tm time;
  time.tm_sec = (btime & 0xf) + ((btime >> 4) & 0xf) * 10;
  time.tm_min = ((btime >> 8) & 0xf) + ((btime >> 12) & 0xf) * 10;
  time.tm_hour = ((btime >> 16) & 0xf) + ((btime >> 20) & 0xf) * 10;
  time.tm_mday = ((btime >> 24) & 0xf) + ((btime >> 28) & 0xf) * 10;
  time.tm_mon = ((btime >> 32) & 0xf) + ((btime >> 36) & 0xf) * 10;
  time.tm_year = ((btime >> 40) & 0xf) + ((btime >> 44) & 0xf) * 10
               + ((btime >> 48) & 0xf) * 100 + ((btime >> 52) & 0xf) * 1000;
  printtime(&time);
  set_rtc(&time);
}

void printtime(struct tm *time) {
  printf("%04d-%02d-%02d %02d:%02d:%02d\n", time->tm_year, time->tm_mon,
    time->tm_mday, time->tm_hour, time->tm_min, time->tm_sec);
}

void testbattery() {
  printf("%lx\n", LPC_RTC->GPREG0);
  LPC_RTC->GPREG0 = RTC_MAGIC;
  printf("%lx\n", LPC_RTC->GPREG0);
  LPC_RTC->CCR = 0;
  BITBAND(LPC_SC->PCONP, PCRTC) = 0;
  delay_ms(20000);
  BITBAND(LPC_SC->PCONP, PCRTC) = 1;
  printf("%lx\n", LPC_RTC->GPREG0);
  delay_ms(20);
  LPC_RTC->CCR = BV(CLKEN);
}

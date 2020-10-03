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

uint8_t rtc_isvalid() {
  if(LPC_RTC->GPREG0 == RTC_MAGIC) {
    return RTC_OK;
  }
  return RTC_INVALID;
}

void rtc_init() {
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

uint64_t get_bcdtime() {
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

void bcdtime2srtctime(uint64_t bcdtime, uint8_t *srtctime) {
  uint8_t century = ((bcdtime >> 52) & 0xf) * 10
                  + ((bcdtime >> 48) & 0xf);
  srtctime[11] = (century - 10) & 0xf;
  srtctime[10] = (bcdtime >> 44) & 0xf;
  srtctime[9] = (bcdtime >> 40) & 0xf;
  uint8_t month = ((bcdtime >> 36) & 0xf) * 10
                + ((bcdtime >> 32) & 0xf);
  srtctime[8] = month;
  srtctime[7] = (bcdtime >> 28) & 0xf;
  srtctime[6] = (bcdtime >> 24) & 0xf;
  srtctime[5] = (bcdtime >> 20) & 0xf;
  srtctime[4] = (bcdtime >> 16) & 0xf;
  srtctime[3] = (bcdtime >> 12) & 0xf;
  srtctime[2] = (bcdtime >> 8) & 0xf;
  srtctime[1] = (bcdtime >> 4) & 0xf;
  srtctime[0] = bcdtime & 0xf;
}

uint64_t srtctime2bcdtime(uint8_t *srtctime) {
  /* 1st nibble is the century - 10 (binary 0-f = 10xx-25xx)
     4th nibble is the month (binary 1-c)
     all other fields are BCD */
  uint64_t result = 0LL;
  uint8_t data;
  for(int i=0; i<12; i++) {
    data = srtctime[11-i];
    data &= 0xf;
    switch(i) {
      case 0:
        result = (result << 4) | ((data / 10) + 1);
        result = (result << 4) | (data % 10);
        break;
      case 3:
        result = (result << 4) | ((data / 10));
        result = (result << 4) | (data % 10);
        break;
      default:
        result = (result << 4) | data;
    }
  }
  return result & 0x00ffffffffffffffLL;
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

void time2gtime(struct gtm *gtime, struct tm *time) {
  gtime->gtm_sec  = time->tm_sec;
  gtime->gtm_min  = time->tm_min;
  gtime->gtm_hour = time->tm_hour;

  /* compute a day count from some fixed date */
  /* see http://howardhinnant.github.io/date_algorithms.html */
  int32_t year = time->tm_year;
  uint32_t mon = time->tm_mon;
  uint32_t day = time->tm_mday; // already starts at 1
  if (mon <= 2) year--;
  int32_t era = (year >= 0 ? year : year - 399) / 400;
  uint32_t yoe = (uint32_t)(year - era * 400);
  uint32_t doy = (153 * (mon + (mon > 2 ? -3 : 9)) + 2) / 5 + day - 1;
  uint32_t doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
  
  // force a positive value by making start of era -1 (-0400/03/01 y/m/d) a value of 0
  gtime->gtm_days = (uint32_t)((era + 1) * 146097 + (int32_t)doe);
}

uint8_t get_deltagtime(struct gtm *time1, struct gtm *time2) {
  uint8_t borrow = 0;

  /* the struct contains unsigned fields.  need to be careful not to underflow */
  if (time1->gtm_sec  < time2->gtm_sec  + borrow) { time1->gtm_sec  += 60 - borrow; borrow = 1; } else { time1->gtm_sec  -= borrow; borrow = 0; }
  time1->gtm_sec -= time2->gtm_sec;
  if (time1->gtm_min  < time2->gtm_min  + borrow) { time1->gtm_min  += 60 - borrow; borrow = 1; } else { time1->gtm_min  -= borrow; borrow = 0; }
  time1->gtm_min -= time2->gtm_min;
  if (time1->gtm_hour < time2->gtm_hour + borrow) { time1->gtm_hour += 24 - borrow; borrow = 1; } else { time1->gtm_hour -= borrow; borrow = 0; }
  time1->gtm_hour -= time2->gtm_hour;
  if (time1->gtm_days < time2->gtm_days + borrow) { time1->gtm_days += 1  - borrow; borrow = 1; } else { time1->gtm_days -= borrow; borrow = 0; }
  if (!borrow) time1->gtm_days -= time2->gtm_days;
  
  if (!(time1->gtm_sec < 60 && time1->gtm_min < 60 && time1->gtm_hour < 24))
    printf("GTC delta error gtime: days=%ld, hour=%hhd, min=%hhd, sec=%hhd\n", time1->gtm_days,
                                                                               time1->gtm_hour,
                                                                               time1->gtm_min,
                                                                               time1->gtm_sec);
  
  // borrowing a day signifies underflow and the delta is not valid
  return borrow;
}

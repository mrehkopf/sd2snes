/* sd2iec - SD/MMC to Commodore serial bus interface/controller
   Copyright (C) 2007-2010  Ingo Korb <ingo@akana.de>

   Inspiration and low-level SD/MMC access based on code from MMC2IEC
     by Lars Pontoppidan et al., see sdcard.c|h and config.h.

   FAT filesystem access based on code from ChaN and Jim Brain, see ff.c|h.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License only.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


   rtc.h: Definitions for RTC support

   There is no rtc.c, the functions defined here are implemented by a
   device-specific .c file, e.g. pcf8583.c.

*/

#ifndef RTC_H
#define RTC_H

#include <stdint.h>

typedef enum {
  RTC_NOT_FOUND,  /* No RTC present                    */
  RTC_INVALID,    /* RTC present, but contents invalid */
  RTC_OK          /* RTC present and working           */
} rtcstate_t;

struct tm {
  uint8_t tm_sec;  // 0..59
  uint8_t tm_min;  // 0..59
  uint8_t tm_hour; // 0..23
  uint8_t tm_mday; // 1..[28..31]
  uint8_t tm_mon;  // 0..11
  uint8_t tm_year; // since 1900, i.e. 2000 is 100
  uint8_t tm_wday; // 0 to 6, sunday is 6
  // A Unix struct tm has a few more fields we don't need in this application
};

extern rtcstate_t rtc_state;

void rtc_init(void);

/* Return current time in struct tm */
void read_rtc(struct tm *time);

/* Set time from struct tm */
void set_rtc(struct tm *time);

/* get current time in 60-bit BCD format (WYYYYMMDDHHMMSS) (W=DOW) */
uint64_t get_bcdtime(void);

#endif

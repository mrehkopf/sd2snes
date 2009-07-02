#ifndef TIME_H
#define TIME_H

typedef uint32_t time_t;
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

#endif	/* TIME_H */

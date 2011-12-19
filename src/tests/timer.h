#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>

typedef unsigned int tick_t;

extern volatile tick_t ticks;
#define HZ 100

/**
 * getticks - return the current system tick count
 *
 * This inline function returns the current system tick count.
 */
static inline tick_t getticks(void) {
  return ticks;
}

#define MS_TO_TICKS(x) (x/10)

/* Adapted from Linux 2.6 include/linux/jiffies.h:
 *
 *      These inlines deal with timer wrapping correctly. You are
 *      strongly encouraged to use them
 *      1. Because people otherwise forget
 *      2. Because if the timer wrap changes in future you won't have to
 *         alter your driver code.
 *
 * time_after(a,b) returns true if the time a is after time b.
 *
 * Do this with "<0" and ">=0" to only test the sign of the result. A
 * good compiler would generate better code (and a really good compiler
 * wouldn't care). Gcc is currently neither.
 * (">=0" refers to the time_after_eq macro which wasn't copied)
 */
#define time_after(a,b)         \
         ((int)(b) - (int)(a) < 0)
#define time_before(a,b)        time_after(b,a)


void timer_init(void);

/* delay for "time" microseconds - uses the RIT */
void delay_us(unsigned int time);

/* delay for "time" milliseconds - uses the RIT */
void delay_ms(unsigned int time);
void sleep_ms(unsigned int time);

#endif

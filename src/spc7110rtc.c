/* SPC7110 / RTC-4513 battery backup.  See spc7110rtc.h for what this is for. */

#include <stdint.h>
#include <string.h>

#include "spc7110rtc.h"

#ifndef SPC7110_RTC_HOSTTEST
#include "config.h"
#include "fileops.h"
#include "fpga_spi.h"
#include "memory.h"
#include "rtc.h"
#include "smc.h"
#include "uart.h"
#include "led.h"

/* the loaded ROM's properties (defined in smc.c, declared per-user like the
   other consumers -- cheat.c, msu1.c, memory.c do the same) */
extern snes_romprops_t romprops;
#endif

#define SECS_PER_DAY (86400)

/* ------------------------------------------------------------------------ */
/* calendar                                                                  */
/*                                                                           */
/* Days are counted from an epoch of 0000-03-01 with the year starting in     */
/* March, so February - the only month whose length moves - is always the     */
/* last one and no leap year special case is needed anywhere else.  Both      */
/* directions are exact for every year the RTC-4513 can express (0000-9999),  */
/* including 2000 and 2400 (leap) against 1900 and 2100 (not).                */
/* ------------------------------------------------------------------------ */

/* Gregorian day-count conversion below follows Howard Hinnant's public-domain
   "chrono-Compatible Low-Level Date Algorithms" (era/yoe/doy/doe form). */
static int32_t days_from_civil(int32_t y, int32_t m, int32_t d) {
  int32_t era;
  uint32_t yoe, doy, doe;

  y -= (m <= 2);
  era = (y >= 0 ? y : y - 399) / 400;
  yoe = (uint32_t)(y - era * 400);                                /* 0..399 */
  doy = (153u * (uint32_t)(m + (m > 2 ? -3 : 9)) + 2u) / 5u + (uint32_t)d - 1u;
  doe = yoe * 365u + yoe / 4u - yoe / 100u + doy;                 /* 0..146096 */
  return era * 146097 + (int32_t)doe;
}

static void civil_from_days(int32_t z, int32_t *py, int32_t *pm, int32_t *pd) {
  int32_t era, y;
  uint32_t doe, yoe, doy, mp, d, m;

  era = (z >= 0 ? z : z - 146096) / 146097;
  doe = (uint32_t)(z - era * 146097);                             /* 0..146096 */
  yoe = (doe - doe / 1460u + doe / 36524u - doe / 146096u) / 365u;
  y   = (int32_t)yoe + era * 400;
  doy = doe - (365u * yoe + yoe / 4u - yoe / 100u);
  mp  = (5u * doy + 2u) / 153u;
  d   = doy - (153u * mp + 2u) / 5u + 1u;
  m   = mp + (mp < 10u ? 3u : (uint32_t)-9);
  *py = y + (m <= 2);
  *pm = (int32_t)m;
  *pd = (int32_t)d;
}

static int bcd2bin(uint8_t b, int32_t *v) {
  if ((b & 0x0f) > 9 || (b >> 4) > 9) return -1;
  *v = (int32_t)(b >> 4) * 10 + (int32_t)(b & 0x0f);
  return 0;
}

static uint8_t bin2bcd(int32_t v) {
  return (uint8_t)((((v / 10) % 10) << 4) | (v % 10));
}

int spc7110_rtc_unpack(const uint8_t *time, spc7110_instant_t *out) {
  int32_t cent, year, mon, day, hour, min, sec;

  if (bcd2bin(time[0], &cent) || bcd2bin(time[1], &year)
   || bcd2bin(time[2], &mon)  || bcd2bin(time[3], &day)
   || bcd2bin(time[4], &hour) || bcd2bin(time[5], &min)
   || bcd2bin(time[6], &sec)) return -1;
  /* the day is only range checked, not checked against the month: a corrupt
     sidecar normalises (30 February becomes 2 March) instead of being thrown
     away, which is the friendlier failure for a clock */
  if (mon < 1 || mon > 12 || day < 1 || day > 31
   || hour > 23 || min > 59 || sec > 59) return -1;

  out->days = days_from_civil(cent * 100 + year, mon, day);
  out->secs = hour * 3600 + min * 60 + sec;
  return 0;
}

void spc7110_rtc_pack(const spc7110_instant_t *in, uint8_t *time) {
  int32_t y, m, d, s = in->secs;

  civil_from_days(in->days, &y, &m, &d);
  y %= 10000;
  if (y < 0) y += 10000;
  time[0] = bin2bcd(y / 100);
  time[1] = bin2bcd(y % 100);
  time[2] = bin2bcd(m);
  time[3] = bin2bcd(d);
  time[4] = bin2bcd(s / 3600);
  time[5] = bin2bcd((s / 60) % 60);
  time[6] = bin2bcd(s % 60);
}

static void normalise(spc7110_instant_t *t) {
  while (t->secs >= SECS_PER_DAY) { t->secs -= SECS_PER_DAY; t->days += 1; }
  while (t->secs < 0)             { t->secs += SECS_PER_DAY; t->days -= 1; }
}

void spc7110_rtc_diff(const spc7110_instant_t *a, const spc7110_instant_t *b,
                      spc7110_instant_t *d) {
  d->days = a->days - b->days;
  d->secs = a->secs - b->secs;
  normalise(d);
}

void spc7110_rtc_add(const spc7110_instant_t *a, const spc7110_instant_t *d,
                     spc7110_instant_t *r) {
  r->days = a->days + d->days;
  r->secs = a->secs + d->secs;
  normalise(r);
}

int32_t spc7110_rtc_midnights(const spc7110_instant_t *from,
                              const spc7110_instant_t *to) {
  return to->days - from->days;
}

#ifndef SPC7110_RTC_HOSTTEST

/* ------------------------------------------------------------------------ */
/* sidecar                                                                   */
/* ------------------------------------------------------------------------ */

#define SPC7110_RTC_VERSION (1)

typedef struct {
  uint8_t magic[4];                     /* "S7RT" */
  uint8_t version;
  uint8_t reserved[3];
  uint8_t flags;                        /* spc7110_rtc_state_t, flattened so */
  uint8_t time[SPC7110_RTC_TIMELEN];    /* the layout is fixed by this file  */
  uint8_t wall[SPC7110_RTC_TIMELEN];    /* console clock when this was saved */
  uint8_t pad;
} spc7110_rtc_file_t;

/* the layout above is the on-card format; a change has to bump the version */
typedef char spc7110_rtc_file_size_check[(sizeof(spc7110_rtc_file_t) == 24) ? 1 : -1];

static const uint8_t spc7110_rtc_magic[4] = { 'S', '7', 'R', 'T' };

/* last state written out, so the game loop only touches the card on a change */
static spc7110_instant_t spc7110_rtc_last_delta;
static uint8_t spc7110_rtc_last_flags;
static uint8_t spc7110_rtc_known;

/* how far the two clocks may disagree before the sidecar is rewritten.  The
   cartridge clock and the console clock are different crystals, so their
   seconds drift apart and the difference jitters by one either way; without a
   dead band that alone would write the card every few seconds. */
#define SPC7110_RTC_SLACK (2)

static void bcdtime_to_bytes(uint64_t t, uint8_t *b) {
  int i;
  for (i = 0; i < SPC7110_RTC_TIMELEN; i++)
    b[i] = (uint8_t)(t >> (8 * (SPC7110_RTC_TIMELEN - 1 - i)));
}

static uint64_t bytes_to_bcdtime(const uint8_t *b, uint8_t dow) {
  uint64_t t = ((uint64_t)(dow & 7)) << 56;
  int i;
  for (i = 0; i < SPC7110_RTC_TIMELEN; i++)
    t |= ((uint64_t)b[i]) << (8 * (SPC7110_RTC_TIMELEN - 1 - i));
  return t;
}

/* the SPI helpers speak eight plain bytes; marshal rather than rely on how the
   struct happens to be laid out */
static void spc7110_rtc_get(spc7110_rtc_state_t *st) {
  uint8_t b[FPGA_SPC7110_RTC_LEN];
  get_spc7110_rtc(b);
  st->flags = b[0];
  memcpy(st->time, b + 1, SPC7110_RTC_TIMELEN);
}

/* `shown` is the instant the cartridge has to report from now on; `prog` is
   what rtc.v is handed, which is one second less when the clock is running
   because programming it makes it run a pass straight away. */
static void spc7110_rtc_program(const spc7110_rtc_state_t *st,
                                const uint8_t *prog) {
  uint8_t b[FPGA_SPC7110_RTC_LEN];
  set_fpga_time(bytes_to_bcdtime(prog, st->flags & SPC7110_RTC_DOW_MASK));
  b[0] = st->flags;
  memcpy(b + 1, st->time, SPC7110_RTC_TIMELEN);
  set_spc7110_rtc(b);
}

/* no usable backup: behave exactly as before this file existed */
static void spc7110_rtc_wallclock(void) {
  set_fpga_time(get_bcdtime());
  spc7110_rtc_known = 0;
}

void spc7110_rtc_load(uint8_t *filename) {
  spc7110_rtc_file_t f;
  spc7110_rtc_state_t st;
  spc7110_instant_t stored, saved, now, delta, cur, prog;
  uint8_t wall[SPC7110_RTC_TIMELEN];
  uint8_t progtime[SPC7110_RTC_TIMELEN];
  char rtcfile[256] = SAVE_BASEDIR;
  uint32_t got;

  spc7110_rtc_known = 0;
  bcdtime_to_bytes(get_bcdtime(), wall);

  /* read path: name the sidecar, never create the folder here */
  append_file_basename(rtcfile, (char *)filename, ".rtc", sizeof(rtcfile));
  file_open((uint8_t *)rtcfile, FA_READ);
  if (file_res) { file_close(); spc7110_rtc_wallclock(); return; }
  got = file_readblock(&f, 0, sizeof(f));
  file_close();

  /* a truncated file is a broken file: fall back rather than read the tail of
     whatever the buffer happened to hold */
  if (got != sizeof(f)
   || memcmp(f.magic, spc7110_rtc_magic, sizeof(f.magic))
   || f.version != SPC7110_RTC_VERSION) {
    printf("SPC7110 RTC: unusable sidecar, using the console clock\n");
    spc7110_rtc_wallclock();
    return;
  }

  st.flags = f.flags;
  memcpy(st.time, f.time, SPC7110_RTC_TIMELEN);

  /* both are needed on either branch: `now` seeds the change detector even for
     a stopped clock, because that is what the save path will be comparing */
  if (spc7110_rtc_unpack(st.time, &stored) || spc7110_rtc_unpack(wall, &now)) {
    spc7110_rtc_wallclock();
    return;
  }

  if (st.flags & SPC7110_RTC_STOPPED) {
    /* stopped clocks do not age.  The core serves this out of its freeze
       register, so the second it comes back on is the second it was left on. */
    cur = stored;
  } else {
    if (spc7110_rtc_unpack(f.wall, &saved)) {
      spc7110_rtc_wallclock();
      return;
    }
    spc7110_rtc_diff(&now, &saved, &delta);
    /* console clock moved backwards (it was corrected, or never set): the
       cartridge clock cannot run backwards, so it simply does not advance */
    if (delta.days < 0) { delta.days = 0; delta.secs = 0; }
    spc7110_rtc_add(&stored, &delta, &cur);

    /* the weekday is a counter, not a function of the date: advance it by the
       number of midnights that went by, and by nothing else */
    st.flags = (uint8_t)((st.flags & ~SPC7110_RTC_DOW_MASK)
             | (uint8_t)(((uint32_t)(st.flags & SPC7110_RTC_DOW_MASK)
                          + (uint32_t)spc7110_rtc_midnights(&stored, &cur)) % 7));

    spc7110_rtc_pack(&cur, st.time);
  }

  /* rtc.v runs one per-second pass the moment it is programmed, so what it
     publishes is the value it was handed plus one second.  That second comes
     off here, and only here: `cur` stays the instant the cartridge shows.  A
     stopped clock is served out of the freeze register instead, so it needs no
     correction. */
  prog = cur;
  if (!(st.flags & SPC7110_RTC_STOPPED)) {
    prog.secs -= 1;
    if (prog.secs < 0) { prog.secs += SECS_PER_DAY; prog.days -= 1; }
  }
  spc7110_rtc_pack(&prog, progtime);

  spc7110_rtc_program(&st, progtime);

  /* Seed the change detector with EXACTLY what the save path will compare
     against, so the first pass of the game loop finds nothing to do: the frozen
     instant while stopped, the offset between the two clocks while running. */
  spc7110_rtc_last_flags = (uint8_t)(st.flags & ~SPC7110_RTC_DOW_MASK);
  if (st.flags & SPC7110_RTC_STOPPED) spc7110_rtc_last_delta = cur;
  else                                spc7110_rtc_diff(&cur, &now, &spc7110_rtc_last_delta);
  spc7110_rtc_known = 1;

  printf("SPC7110 RTC: restored %s, %02x%02x-%02x-%02x %02x:%02x:%02x\n",
         (st.flags & SPC7110_RTC_STOPPED) ? "stopped" : "running",
         st.time[0], st.time[1], st.time[2], st.time[3],
         st.time[4], st.time[5], st.time[6]);
}

void spc7110_rtc_save(uint8_t *filename) {
  spc7110_rtc_file_t f;
  spc7110_rtc_state_t st;
  spc7110_instant_t cart, now, delta;
  uint8_t wall[SPC7110_RTC_TIMELEN];
  char rtcfile[256] = SAVE_BASEDIR;
  uint8_t flags_stable;

  if (!romprops.has_spc7110) return;

  spc7110_rtc_get(&st);
  bcdtime_to_bytes(get_bcdtime(), wall);
  if (spc7110_rtc_unpack(st.time, &cart) || spc7110_rtc_unpack(wall, &now))
    return;

  /* What has to stay the same for the backup to still describe reality: the
     control flags, and either the frozen time (stopped) or the offset between
     the two clocks (running).  A clock that simply runs keeps both constant,
     so the card is never touched. */
  flags_stable = (uint8_t)(st.flags & ~SPC7110_RTC_DOW_MASK);
  if (st.flags & SPC7110_RTC_STOPPED) {
    delta = cart;
  } else {
    spc7110_rtc_diff(&cart, &now, &delta);
  }

  if (spc7110_rtc_known
   && flags_stable == spc7110_rtc_last_flags
   && delta.days == spc7110_rtc_last_delta.days
   && (delta.secs - spc7110_rtc_last_delta.secs) <= SPC7110_RTC_SLACK
   && (spc7110_rtc_last_delta.secs - delta.secs) <= SPC7110_RTC_SLACK)
    return;

  check_or_create_folder(SAVE_BASEDIR);
  append_file_basename(rtcfile, (char *)filename, ".rtc", sizeof(rtcfile));

  memcpy(f.magic, spc7110_rtc_magic, sizeof(f.magic));
  f.version = SPC7110_RTC_VERSION;
  f.reserved[0] = f.reserved[1] = f.reserved[2] = 0;
  f.flags = st.flags;
  memcpy(f.time, st.time, SPC7110_RTC_TIMELEN);
  memcpy(f.wall, wall, SPC7110_RTC_TIMELEN);
  f.pad = 0;

  file_open((uint8_t *)rtcfile, FA_CREATE_ALWAYS | FA_WRITE);
  if (file_res) { file_close(); return; }
  writeled(1);
  file_writeblock(&f, 0, sizeof(f));
  writeled(0);
  file_close();

  spc7110_rtc_last_flags = flags_stable;
  spc7110_rtc_last_delta = delta;
  spc7110_rtc_known = 1;
}

#endif /* SPC7110_RTC_HOSTTEST */

/* SPC7110 / RTC-4513 battery backup.
 *
 * The RTC-4513 on the Far East of Eden Zero cartridge is kept alive by a coin
 * cell: the calendar it holds - and whether it is running at all - survives a
 * power cycle.  Nothing on this board does: the FPGA is reconfigured on every
 * game load and the clock inside it is programmed from the console's own clock.
 *
 * The cartridge's factory check program needs the real behaviour.  Its second
 * pass programs the clock, stops it, and expects to find it on the same second
 * after the console has been switched off and on again.  So the state is kept
 * in a sidecar next to the save file and handed back to the core on load, the
 * same way the Super Game Boy keeps the MBC3 clock in a .gtc file.
 *
 * Sidecar: /sd2snes/saves/<romstem>.rtc, next to the .srm, versioned, 24 bytes.
 */
#ifndef SPC7110RTC_H
#define SPC7110RTC_H

#include <stdint.h>

/* Status byte of the backup, identical over SPI (command $e6 reads it, $e7
   restores it) and in the sidecar. */
#define SPC7110_RTC_STOPPED   (0x20)  /* control register F bit1 was set */
#define SPC7110_RTC_DOW_OWNED (0x10)  /* the game has written the weekday */
#define SPC7110_RTC_DOW_MASK  (0x0f)

/* Seven packed BCD bytes, most significant first, exactly the payload of SPI
   command $e5: century, year, month, day, hour, minute, second. */
#define SPC7110_RTC_TIMELEN   (7)

typedef struct {
  uint8_t flags;
  uint8_t time[SPC7110_RTC_TIMELEN];
} spc7110_rtc_state_t;

/* A calendar instant, split so that no intermediate result can overflow: whole
   days since the internal epoch, plus seconds inside the day.  Two SPC7110
   dates can be seventy years apart (the factory test drives the clock to 2100
   while the console sits in the 2020s), which is more seconds than a 32 bit
   count holds. */
typedef struct {
  int32_t days;
  int32_t secs;
} spc7110_instant_t;

/* Calendar helpers.  No hardware, no files - pure arithmetic seams that a
   host-side self test can exercise. */
int  spc7110_rtc_unpack(const uint8_t *time, spc7110_instant_t *out);
void spc7110_rtc_pack(const spc7110_instant_t *in, uint8_t *time);
void spc7110_rtc_diff(const spc7110_instant_t *a, const spc7110_instant_t *b,
                      spc7110_instant_t *d);
void spc7110_rtc_add(const spc7110_instant_t *a, const spc7110_instant_t *d,
                     spc7110_instant_t *r);
/* days between two instants, i.e. how many midnights were crossed */
int32_t spc7110_rtc_midnights(const spc7110_instant_t *from,
                              const spc7110_instant_t *to);

#ifndef SPC7110_RTC_HOSTTEST
/* Called from load_rom once the core is configured and before the SNES runs.
   Always programs the clock: with the backed up state when there is one, with
   the console's own time when there is not. */
void spc7110_rtc_load(uint8_t *filename);
/* Called from the game loop.  Reads the core's state over SPI and writes the
   sidecar only when it actually changed, so a free running clock costs no
   card writes at all. */
void spc7110_rtc_save(uint8_t *filename);
#endif

#endif

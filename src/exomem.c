/* exomem.c: exomizer-packed data in flash

   The boot screen, shown when no core can be loaded from the SD card, is
   kept packed in the firmware: its FPGA core (cfgware, packed at build
   time) and its SNES ROM (snesboot.h). Both were packed with exomizer raw
   -m EXO_WINDOW; the decoder needs the last EXO_WINDOW bytes it produced,
   and uses ptrcache for them: the directory sort's buffer is idle whenever
   the boot screen is set up. */

#include <stddef.h>
#include "config.h"
#include "exodecrunch.h"
#include "exomem.h"

extern uint32_t ptrcache[QSORT_MAXELEM];
_Static_assert(sizeof(ptrcache) >= EXO_WINDOW, "ptrcache is the exomizer window");

static struct exo_decrunch_ctx exomem_ctx IN_AHBRAM;
static const uint8_t *exomem_ptr, *exomem_end;
static uint8_t exomem_over;   /* read past the data: no end marker, it is corrupt */

static int exomem_read(void *unused) {
  (void)unused;
  if(exomem_ptr < exomem_end) return *exomem_ptr++;
  exomem_over = 1;
  return 0;
}

void exomem_init(const uint8_t *data, uint32_t len) {
  exomem_ptr = data;
  exomem_end = data + len;
  exomem_over = 0;
  exo_decrunch_new(&exomem_ctx, (unsigned char*)ptrcache, EXO_WINDOW, exomem_read, NULL);
}

int exomem_getc(void) {
  int c = exo_read_decrunched_byte(&exomem_ctx);
  return exomem_over ? -1 : c;
}

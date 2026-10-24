#ifndef EXOMEM_H
#define EXOMEM_H

#include <stdint.h>

/* unpack exomizer-packed data in flash (exomizer raw -m EXO_WINDOW) */
void exomem_init(const uint8_t *data, uint32_t len);
int exomem_getc(void);   /* the next byte, -1 at the end */

#endif

#ifndef HWINFO_H
#define HWINFO_H

#include <stdint.h>
#include "config.h"
#include "bits.h"

typedef enum {
  MAKER_IKARI_01    = 0x00,
  MAKER_KRIKZZ      = 0x01,
  MAKER_UNSUPPORTED = 0x02,
  MAKER_REDSCORPION = 0x08,
  MAKER_LEGACY      = 0x09
} hwinfo_maker;

typedef struct {
  hwinfo_maker maker;
  char         *makername;
  uint8_t      model;
  char         *modelname;
  uint8_t      revision;
  char         *revname;
} hwinfo_t;

uint8_t get_hwinfo(hwinfo_t *hw);

#endif
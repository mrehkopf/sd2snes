#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "config.h"
#include "uart.h"
#include "cic.h"

char *cicstatenames[4] = { "CIC_OK", "CIC_FAIL", "CIC_PAIR", "CIC_SCIC" };
char *cicstatefriendly[4] = {"Original or no CIC", "Original CIC (failed)", "SuperCIC enhanced", "SuperCIC detected, not used"};

void print_cic_state() {
  printf("CIC state: %s\n", get_cic_statename(get_cic_state()));
}

inline char *get_cic_statefriendlyname(enum cicstates state) {
  return cicstatefriendly[state];
}

inline char *get_cic_statename(enum cicstates state) {
  return cicstatenames[state];
}

enum cicstates get_cic_state() {
  uint32_t count;
  uint32_t togglecount = 0;
  uint8_t state, state_old;

  state_old = BITBAND(SNES_CIC_STATUS_REG->FIOPIN, SNES_CIC_STATUS_BIT);
/* this loop samples at ~10MHz */
  for(count=0; count<CIC_SAMPLECOUNT; count++) {
    state = BITBAND(SNES_CIC_STATUS_REG->FIOPIN, SNES_CIC_STATUS_BIT);
    if(state != state_old) {
      togglecount++;
    }
    state_old = state;
  }
  printf("CIC toggle: %ld\n", togglecount);
/* CIC_TOGGLE_THRESH_PAIR > CIC_TOGGLE_THRESH_SCIC */
  if(togglecount > CIC_TOGGLE_THRESH_PAIR) {
    return CIC_PAIR;
  } else if(togglecount > CIC_TOGGLE_THRESH_SCIC) {
    return CIC_SCIC;
  } else if(state) {
    return CIC_OK;
  } else return CIC_FAIL;
}

void cic_init(int allow_pairmode) {
  BITBAND(SNES_CIC_PAIR_REG->FIODIR, SNES_CIC_PAIR_BIT) = 1;
  if(allow_pairmode) {
    BITBAND(SNES_CIC_PAIR_REG->FIOCLR, SNES_CIC_PAIR_BIT) = 1;
  } else {
    BITBAND(SNES_CIC_PAIR_REG->FIOSET, SNES_CIC_PAIR_BIT) = 1;
  }
}

/* prepare GPIOs for pair mode + set initial modes */
void cic_pair(int init_vmode, int init_d4) {
  cic_videomode(init_vmode);
  cic_d4(init_d4);

  BITBAND(SNES_CIC_D0_REG->FIODIR, SNES_CIC_D0_BIT) = 1;
  BITBAND(SNES_CIC_D1_REG->FIODIR, SNES_CIC_D1_BIT) = 1;
}

void cic_videomode(int value) {
  if(value) {
    BITBAND(SNES_CIC_D0_REG->FIOSET, SNES_CIC_D0_BIT) = 1;
  } else {
    BITBAND(SNES_CIC_D0_REG->FIOCLR, SNES_CIC_D0_BIT) = 1;
  }
}

void cic_d4(int value) {
  if(value) {
    BITBAND(SNES_CIC_D1_REG->FIOSET, SNES_CIC_D1_BIT) = 1;
  } else {
    BITBAND(SNES_CIC_D1_REG->FIOCLR, SNES_CIC_D1_BIT) = 1;
  }
}


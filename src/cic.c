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

  state_old = BITBAND(SNES_CIC_STATUS_REG->GPIO_I, SNES_CIC_STATUS_BIT);
/* this loop samples at ~10MHz */
  for(count=0; count<CIC_SAMPLECOUNT; count++) {
    state = BITBAND(SNES_CIC_STATUS_REG->GPIO_I, SNES_CIC_STATUS_BIT);
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

void cic_preinit() {
  GPIO_MODE_IN(SNES_CIC_D0_REG, SNES_CIC_D0_BIT);
  GPIO_MODE_IN(SNES_CIC_D1_REG, SNES_CIC_D1_BIT);
}

void cic_init(int allow_pairmode) {
  GPIO_MODE_OUT(SNES_CIC_PAIR_REG, SNES_CIC_PAIR_BIT);
  OUT_BIT(SNES_CIC_PAIR_REG, SNES_CIC_PAIR_BIT, !allow_pairmode);
}

/* prepare GPIOs for pair mode + set initial modes */
void cic_pair(int init_vmode, int init_d4) {
  cic_videomode(init_vmode);
  cic_d4(init_d4);
}

void cic_videomode(int value) {
  OUT_BIT(SNES_CIC_D0_REG, SNES_CIC_D0_BIT, value);
  GPIO_MODE_OUT(SNES_CIC_D0_REG, SNES_CIC_D0_BIT);
}

void cic_d4(int value) {
  OUT_BIT(SNES_CIC_D1_REG, SNES_CIC_D1_BIT, value);
  GPIO_MODE_OUT(SNES_CIC_D1_REG, SNES_CIC_D1_BIT);
}


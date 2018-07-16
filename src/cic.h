#ifndef _CIC_H
#define _CIC_H

#define CIC_SAMPLECOUNT	(100000)
#define CIC_TOGGLE_THRESH_PAIR	(1000)
#define CIC_TOGGLE_THRESH_SCIC	(10)

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"

enum cicstates { CIC_OK = 0, CIC_FAIL, CIC_PAIR, CIC_SCIC };
enum cic_region { CIC_NTSC = 0, CIC_PAL };

void print_cic_state(void);
char *get_cic_statename(enum cicstates state);
char *get_cic_statefriendlyname(enum cicstates state);
enum cicstates get_cic_state(void);
void cic_init(int allow_pairmode);

void cic_pair(int init_vmode, int init_d4);
void cic_videomode(int value);
void cic_d4(int value);

#endif

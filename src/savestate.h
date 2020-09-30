#ifndef SAVESTATE_H
#define SAVESTATE_H


#include <arm/NXP/LPC17xx/LPC17xx.h>

#define SS_BASEDIR				("/sd2snes/states/")
#define SS_INPUTFILE			("/sd2snes/savestate_inputs.yml")
#define SS_FIXESFILE			("/sd2snes/savestate_fixes.yml")
#define SS_CODE_ADDR			0xFC0000L
#define SS_REQ_ADDR				0xFC2000L
#define SS_SAVE_INPUT_ADDR		0xFC2002L
#define SS_LOAD_INPUT_ADDR		0xFC2004L
#define SS_DELAY_ADDR			0xFC2014L
#define SS_SLOTS_ADDR			0xFC2015L
#define SS_SLOTS_INPUT_ADDR		0xFC2016L
#define SS_CTRL_ADDR			0xFC2018L
#define SS_FIXES_ADDR			0xFC2020L

void savestate_program(void);
void savestate_set_inputs(void);
uint16_t savestate_parse_input(char * str);
void savestate_set_fixes(void);
void load_backup_state(void);
void save_backup_state(void);

#endif

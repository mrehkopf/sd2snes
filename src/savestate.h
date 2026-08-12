#ifndef SAVESTATE_H
#define SAVESTATE_H


#include CONFIG_MCU_H
#include "snes.h"

#define SS_BASEDIR          ("/sd2snes/states/")
#define SS_INPUTFILE        ("/sd2snes/savestate_inputs.yml")
#define SS_FIXESFILE        ("/sd2snes/savestate_fixes.yml")
// #define SS_CODE_ADDR        0xFC0000L
#define SS_REQ_ADDR         0xFE1000L
#define SS_SAVE_INPUT_ADDR  0xFE1002L
#define SS_LOAD_INPUT_ADDR  0xFE1004L
#define SS_DELAY_ADDR       0xFE100EL
#define SS_SLOTS_ADDR       0xFE100FL
#define SS_SLOTS_INPUT_ADDR 0xFE1010L
#define SS_SA1_LOAD_ADDR    0xFE1013L
#define SS_CTRL_ADDR        0xFE1012L
#define SS_FIXES_ADDR       0xFE1014L

/* Per-coprocessor "this core can capture/restore its chip" flags, armed on every
   game load and read by the handler (lockstep with snes/savestate.i65).  0 makes
   the handler skip that chip entirely. */
#define SS_DSP_GATE_ADDR    0xFF0712L
#define SS_SA1_GATE_ADDR    0xFF0713L
#define SS_GSU_GATE_ADDR    0xFF0714L
#define SS_OBC1_GATE_ADDR   0xFF0718L
#define SS_SDD1_GATE_ADDR   0xFF0719L
#define SS_CX4_GATE_ADDR    0xFF071FL

typedef enum {
  SS_OP_NONE = 0,
  SS_OP_OR   = ASM_ORA_IMM,
  SS_OP_AND  = ASM_AND_IMM,
  SS_OP_EOR  = ASM_EOR_IMM
} ss_op;

typedef struct __attribute__ ((__packed__)) _ssfix_record {
  uint32_t dst;
  uint16_t src;
  ss_op    operator;
  uint8_t  operand;
/* ROM patches are applied immediately
  uint16_t rom_patch_addr;
  uint8_t  rom_patch_bank;
  uint8_t  rom_patch_value;*/
} ssfix_record_t;

void savestate_program(void);
void savestate_set_inputs(void);
void savestate_set_fixes(void);
void savestate_enable_handler(int enable);
void load_backup_state(void);
void save_backup_state(void);

#endif

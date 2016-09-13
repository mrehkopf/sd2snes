#ifndef CHEAT_H
#define CHEAT_H

/* sd2snes cheat capabilities:
 *  -  6 ROM patches
 *  - 20 WRAM patches
 *  - in-game button shortcuts to en/disable cheats
 */

/* menu cheat structure:
 *  I. 1 byte: number of following cheat records
 * II. n cheat records
 */

/* cheat record structure:
 *  1 byte : flags (bit 7: cheat enabled; bit 6-0: reserved)
 * 40 bytes: cheat description
 *  1 byte : number of patches for this cheat
 *  N TIMES:
 *     3 bytes: cheat address + bank
 *     1 byte : patch value
 */

#include <arm/NXP/LPC17xx/LPC17xx.h>

#define CHEAT_BASEDIR   ("/sd2snes/cheats/")

#define CHEAT_FLAG_ENABLE (0x80)
#define CHEAT_NUM_CODES_PER_CHEAT (40)

typedef union _cheat_patch_record {
  struct __attribute__ ((__packed__)) _patch_fields {
    uint8_t  patchvalue;
    uint16_t patchaddr;
    uint8_t  patchbank;
  } fields;
  uint32_t code;
} cheat_patch_record_t;

typedef struct __attribute__ ((__packed__)) _cheat_record {
  uint8_t flags;
  char description[254];
  uint8_t numpatches;
  cheat_patch_record_t patches[40];
} cheat_record_t;

/* deploy all cheats to SNES code / FPGA */
void cheat_program(void);

/* deploy a single cheat record */
void cheat_program_single(cheat_patch_record_t *cheat);

/* deploy ROM cheat to FPGA */
void cheat_program_rom_cheat(int index, cheat_patch_record_t *cheat);

/* deploy WRAM cheat to SNES code */
void cheat_program_ram_cheat(int index, cheat_patch_record_t *cheat);

/* load CHT file to RAM */
void cheat_load_to_menu(int index, cheat_record_t *cheat);
void cheat_save_from_menu(int index, cheat_record_t *cheat);

/* enable/disable ROM cheats + hooks */
void cheat_enable(int enable);
void cheat_nmi_enable(int enable);
void cheat_irq_enable(int enable);
void cheat_holdoff_enable(int enable);
void cheat_buttons_enable(int enable);
void cheat_wram_present(int enable);

/* read cheats from YAML file and convert to SNES structure */
void cheat_yaml_load(uint8_t *romfilename);
/* save SNES structure as YAML file */
void cheat_yaml_save(uint8_t *romfilename);

/* convert cheat code in string format to binary */
uint32_t cheat_str2bin(char *string);

/* convert between raw/PAR and GG codes */
uint32_t cheat_gg2raw(uint32_t code);
uint32_t cheat_raw2gg(uint32_t code);

#endif

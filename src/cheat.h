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

#include CONFIG_MCU_H

#define CHEAT_BASEDIR   ("/sd2snes/cheats/")

#define CHEAT_FLAG_ENABLE (0x80)
#define CHEAT_NUM_CODES_PER_CHEAT (40)

/* PSRAM-patched ROM cheats: per-record spare tail.  A record slot is
   flags(1) + desc(254) + numpatches(1) + patches(40*4) = 416 bytes, so the rest of
   the 512-byte slot holds, per code, the original ROM byte and an "applied" flag. */
#define CHEAT_REC_ORIG_OFS    (416)
#define CHEAT_REC_APPLIED_OFS (456)

/* Apply/restore ROM codes in the loaded image.  Only on cores whose comparators
   had to be dropped (Mk.II GSU and CX4), a no-op elsewhere.  Idempotent; called
   from deassert_reset(), after every image mutation and before the SNES runs. */
void cheat_rom_psram_apply(void);
uint8_t cheat_rom_psram_mode(void);

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

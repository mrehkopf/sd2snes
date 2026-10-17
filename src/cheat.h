#ifndef CHEAT_H
#define CHEAT_H

/* sd2snes cheat capabilities:
 *  -  6 ROM patches
 *  - 32 WRAM patches
 *  - in-game button shortcuts to en/disable cheats
 */

/* cheat area in PSRAM:
 *  SRAM_NUM_CHEATS: 16-bit number of cheat records
 *  SRAM_CHEAT_ADDR: cheat records, one every CHEAT_RECORD_STRIDE bytes
 */

/* cheat record structure (cheat_record_t):
 *  +0   1 byte : flags (bit 7: cheat enabled; bit 6-0: reserved)
 *  +1 254 bytes: cheat description, NUL terminated
 * +255  1 byte : number of patches (codes) for this cheat
 * +256 40 x 4 bytes: patches: value, address low, address high, bank
 */

#include CONFIG_MCU_H

#define CHEAT_BASEDIR   ("/sd2snes/cheats/")

#define CHEAT_FLAG_ENABLE         (0x80)

#define CHEAT_MAX_CHEATS          (2048)
#define CHEAT_RECORD_STRIDE       (512)
#define CHEAT_NUM_CODES_PER_CHEAT (40)
#define CHEAT_NUM_ROM_PATCHES     (6)
#define CHEAT_NUM_WRAM_PATCHES    (32)
/* longest name that still fits a 256 byte YAML line when saved */
#define CHEAT_NAME_MAXLEN         (240)

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
  cheat_patch_record_t patches[CHEAT_NUM_CODES_PER_CHEAT];
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

/* read cheats from YAML file and convert to SNES structure;
   a missing file yields zero cheats. Returns 0 or an FRESULT */
int cheat_yaml_load(uint8_t *romfilename);
/* save SNES structure as YAML file. Returns 0 or an FRESULT */
int cheat_yaml_save(uint8_t *romfilename);

/* convert cheat code in string format to binary */
uint32_t cheat_str2bin(char *string);

/* convert between raw/PAR and GG codes */
uint32_t cheat_gg2raw(uint32_t code);
uint32_t cheat_raw2gg(uint32_t code);

#endif

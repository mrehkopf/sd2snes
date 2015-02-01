#ifndef CHEAT_H
#define CHEAT_H

/* sd2snes cheat capabilities:
 *  -  6 ROM patches
 *  - 20 WRAM patches
 *  - in-game button shortcuts to en/disable cheats
 */

/* menu cheat structure:
 *  I. 1 byte: number of following cheat records
 * II. n cheat records according to CHT format
 */

/* snes9x CHT file format:
 *  - sequence of cheat data records 28 bytes each
 *
 *  offset  size  field
 *  =================================================================
 *      0     1   flags (bit 2: cheat disabled;
 *                       bit 3: cheat contains compare value)
 *      1     1   patch data value
 *      2     3   patch data address
 *      5     1   patch compare value (if flags bit 3 set)
 *      6     2   unused (set to FE FC by snes9x)
 *      8    20   cheat description (ASCII)
 *
 *  - compare value: only apply cheat if address previously
 *    contained this value - really only makes sense for bank-switched
 *    ROMs and isn't implemented right now
 */
#include <arm/NXP/LPC17xx/LPC17xx.h>

typedef struct _cht_record {
  uint8_t  flags;
  uint8_t  patchvalue;
  uint16_t patchaddr;
  uint8_t  patchbank;
  uint8_t  comparevalue;
  uint16_t pad1;
  uint8_t  description[20];
} cht_record_t;

/* deploy cheats to SNES code / FPGA */
void cheat_program(void);

/* deploy ROM cheat to FPGA */
void cheat_program_rom_cheat(int index, cht_record_t *cheat);

/* deploy WRAM cheat to SNES code */
void cheat_program_ram_cheat(int index, cht_record_t *cheat);

/* load CHT file to RAM */
void cheat_load_to_menu(uint8_t *filename, uint32_t address);
void cheat_save_from_menu(uint8_t *filename, uint32_t address);

/* enable/disable ROM cheats + hooks */
void cheat_enable(int enable);
void cheat_nmi_enable(int enable);
void cheat_irq_enable(int enable);
void cheat_holdoff_enable(int enable);

#endif

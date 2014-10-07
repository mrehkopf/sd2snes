#include "config.h"
#include "fileops.h"
#include "uart.h"
#include "memory.h"
#include "fpga_spi.h"
#include "snes.h"
#include "cheat.h"

void cheat_program() {
  cht_record_t cheat;
  uint32_t cht_record_addr = SRAM_CHEAT_ADDR + 1;
  uint8_t cht_count;
  uint8_t cht_index, rom_index = 0, wram_index = 0;
  uint8_t is_wram_cheat, is_disabled;
  uint32_t patch_addr;
  uint8_t enable_mask = 0;

  cht_count = sram_readbyte(SRAM_CHEAT_ADDR);
cht_count = 0;
  printf("cheat_program: %d cheats present\n", cht_count);
  /* get list of activated cheats from menu */
  for(cht_index = 0; cht_index < cht_count; cht_index++) {
    sram_readblock(&cheat, cht_record_addr, sizeof(cht_record_t));
  /* determine ROM or WRAM cheat */
    patch_addr = ((uint32_t)cheat.patchbank << 16) | cheat.patchaddr;
    is_wram_cheat = ((patch_addr & 0xfe0000) == 0x7e0000)
                    || (!(patch_addr & 0x400000)
                        && ((patch_addr & 0xffff) < 0x2000));
    is_disabled = cheat.flags & 0x04;
  /* apply cheat to FPGA / NMI hook */
    if(!is_disabled) {
      if(is_wram_cheat) {
        cheat_program_ram_cheat(wram_index++, &cheat);
      } else if(rom_index < 6){
        enable_mask |= (1 << rom_index);
        cheat_program_rom_cheat(rom_index++, &cheat);
      }
    }
    cht_record_addr += sizeof(cht_record_t);
  }
  /* put number of WRAM cheats + enable flag */
  snescmd_writebyte(wram_index, SNESCMD_NMI_WRAM_PATCH_COUNT);
  printf("enable mask=%02x\n", enable_mask);
  fpga_write_cheat(6, enable_mask);
  cheat_enable(1);
  cheat_nmi_enable(1);
  cheat_irq_enable(1);
  cheat_holdoff_enable(1);
}

void cheat_program_rom_cheat(int index, cht_record_t *cheat) {
  uint32_t code = ((uint32_t)cheat->patchbank << 24)
                  | ((uint32_t)cheat->patchaddr << 8)
                  | cheat->patchvalue;
  printf("ROM cheat #%d: %02x%04x %02x\n", index, cheat->patchbank, cheat->patchaddr, cheat->patchvalue);
  fpga_write_cheat(index, code);
}

void cheat_program_ram_cheat(int index, cht_record_t *cheat) {
  uint8_t address = SNESCMD_WRAM_CHEATS + 4 * index;
  fpga_set_snescmd_addr(address);
  fpga_write_snescmd(cheat->patchaddr & 0xff);
  fpga_write_snescmd(cheat->patchaddr >> 8);
  fpga_write_snescmd(cheat->patchbank);
  fpga_write_snescmd(cheat->patchvalue);
  printf("RAM cheat #%d: %02x%04x %02x\n", index, cheat->patchbank, cheat->patchaddr, cheat->patchvalue);
}

void cheat_load_to_menu(uint8_t *filename, uint32_t address) {
  printf("cheat_load_to_menu not implemented yet!\n");
}

void cheat_save_from_menu(uint8_t *filename, uint32_t address) {
  printf("cheat_save_from_menu not implemented yet!\n");
}

void cheat_enable(int enable) {
  uint8_t flags;
  /* switch ROM cheats */
  printf("cheat_enable->%d\n", enable);
  flags = (enable ? 0x01 : 0x10);
  fpga_write_cheat(7, flags);
  /* switch WRAM cheats */
  snescmd_writebyte(enable ? 0 : 1, SNESCMD_NMI_DISABLE_WRAM);
}

void cheat_nmi_enable(int enable) {
  uint8_t flags;
  printf("nmi_enable->%d\n", enable);
  flags = (enable ? 0x02 : 0x20);
  fpga_write_cheat(7, flags);
}

void cheat_irq_enable(int enable) {
  uint8_t flags;
  printf("irq_enable->%d\n", enable);
  flags = (enable ? 0x04 : 0x40);
  fpga_write_cheat(7, flags);
}

void cheat_holdoff_enable(int enable) {
  uint8_t flags;
  printf("holdoff_enable->%d\n", enable);
  flags = (enable ? 0x08 : 0x80);
  fpga_write_cheat(7, flags);
}

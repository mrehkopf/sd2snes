/* sd2snes - SD card based universal cartridge for the SNES
   ips.h: IPS ROM patch support
*/

#ifndef IPS_H
#define IPS_H

#include <stdint.h>

/* Maximum number of IPS patches shown in the selection menu */
#define IPS_MAX_PATCHES  7
/* Bytes reserved per display-name slot in the IPS SRAM list */
#define IPS_NAME_LEN     64
/* Bytes reserved per full-path slot in the IPS SRAM list */
#define IPS_PATH_LEN     256

/*
 * ips_pending_index: non-zero when a patch should be applied inside load_rom.
 * Set by the CMD_LOADROM handler in main.c before calling load_rom();
 * consumed (and cleared to 0) inside load_rom() after assert_reset/init.
 */
extern uint8_t ips_pending_index;

/*
 * ips_find_patches
 *   Scan the directory of rom_path for *.ips files whose name starts with
 *   the ROM stem (case-insensitive).  Up to IPS_MAX_PATCHES entries are
 *   sorted alphabetically and written to SRAM at sram_addr:
 *
 *     [sram_addr + 0]                          1 byte  num_patches (0..7)
 *     [sram_addr + 1 + N*IPS_NAME_LEN]        64 bytes display name (null-terminated)
 *     [sram_addr + 512 + N*IPS_PATH_LEN]     256 bytes full SD path  (null-terminated)
 *
 *   Returns num_patches.
 */
uint8_t ips_find_patches(const uint8_t *rom_path, uint32_t sram_addr);

/*
 * ips_apply
 *   Read the IPS full path for patch <index> (1-based) from SRAM at
 *   sram_addr + 512 + (index-1)*IPS_PATH_LEN, open it and apply the patch
 *   over the ROM already loaded in SRAM at rom_base_addr.
 *   Must be called while the SNES is held in hardware reset.
 *   Returns 0 on success, -1 on error (ROM may be partially patched).
 */
int ips_apply(uint32_t sram_addr, uint8_t index, uint32_t rom_base_addr);

#endif /* IPS_H */

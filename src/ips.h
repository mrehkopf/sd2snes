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
 *   original_rom_size is the byte length of the unpatched ROM image already
 *   in SRAM (romprops.romsize_bytes).  If the patch writes beyond this size
 *   the function zero-fills the gap first so that areas between IPS records
 *   contain 0x00 rather than leftover data from a previously loaded ROM.
 *
 *   rom_header_size is the number of bytes that were skipped at the start of
 *   the ROM file when loading into SRAM (i.e. the copier-header size, typically
 *   0 or 512).  If the IPS has records at offsets below 512 and rom_header_size
 *   is 0 the function auto-detects that the patch was authored for a headered
 *   ROM and applies a 512-byte offset correction automatically.
 *
 *   Returns the highest (offset + size) seen across all records — adjusted for
 *   the header offset — on success, or 0 on error.  If the returned value
 *   exceeds original_rom_size the caller must update the FPGA ROM mask.
 */
uint32_t ips_apply(uint32_t sram_addr, uint8_t index, uint32_t rom_base_addr,
                   uint32_t original_rom_size, uint32_t rom_header_size);

#endif /* IPS_H */

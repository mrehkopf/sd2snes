/* sd2snes - SD card based universal cartridge for the SNES
   patch.c: ROM patch support (IPS and BPS)
*/

#include "config.h"
#include "uart.h"
#include "ff.h"
#include "fileops.h"
#include "memory.h"
#include "fpga_spi.h"
#include "patch.h"
#include "timer.h"
#include "crc32.h"

#include <string.h>

uint8_t ips_pending_index = 0;

/* Case-insensitive prefix check: does str start with the first prefix_len
   characters of prefix?  Returns 1 on match, 0 otherwise. */
static int istartswith(const char *str, const char *prefix, size_t prefix_len) {
    for (size_t i = 0; i < prefix_len; i++) {
        char a = str[i], b = prefix[i];
        if (a >= 'a' && a <= 'z') a -= 32;
        if (b >= 'a' && b <= 'z') b -= 32;
        if (a != b) return 0;
    }
    return 1;
}

/* Case-insensitive string compare for sort (returns <0, 0, >0) */
static int istrcmp(const char *a, const char *b) {
    while (*a && *b) {
        char ca = *a, cb = *b;
        if (ca >= 'a' && ca <= 'z') ca -= 32;
        if (cb >= 'a' && cb <= 'z') cb -= 32;
        if (ca != cb) return (int)(unsigned char)ca - (int)(unsigned char)cb;
        a++; b++;
    }
    if (*a == 0 && *b == 0) return 0;
    return *a ? 1 : -1;
}

/* Scratch storage for up to 7 entries.  Placed in AHB RAM to avoid
   overflowing the small 16 KB main RAM.  AHB RAM is not zero-initialised;
   entries are fully written before being read. */
struct _ips_entry {
    char name[IPS_NAME_LEN];
    char full_path[IPS_PATH_LEN];
};
static struct _ips_entry ips_entries[IPS_MAX_PATCHES]
    __attribute__((section(".ahbram")));

uint8_t ips_find_patches(const uint8_t *rom_path, uint32_t sram_addr) {
    /* Zero the count byte up front so callers always see a valid value */
    sram_writebyte(0, sram_addr);

    const char *path = (const char *)rom_path;

    /* Find last '/' to split directory from filename */
    const char *last_slash = NULL;
    for (const char *p = path; *p; p++) {
        if (*p == '/') last_slash = p;
    }
    const char *filename = last_slash ? last_slash + 1 : path;

    /* Compute stem length (everything before the last '.', or whole name) */
    const char *last_dot = NULL;
    for (const char *p = filename; *p; p++) {
        if (*p == '.') last_dot = p;
    }
    size_t stem_len = last_dot ? (size_t)(last_dot - filename) : strlen(filename);
    if (stem_len == 0) return 0;

    /* Build directory path string */
    char dirpath[256];
    if (last_slash && last_slash != path) {
        size_t dirlen = (size_t)(last_slash - path);
        if (dirlen >= sizeof(dirpath)) dirlen = sizeof(dirpath) - 1;
        memcpy(dirpath, path, dirlen);
        dirpath[dirlen] = '\0';
    } else {
        dirpath[0] = '/';
        dirpath[1] = '\0';
    }

    DIR dir;
    FILINFO fno;
    /* Re-use the global LFN buffer (same as scan_dir in filetypes.c) */
    fno.lfsize = 255;
    fno.lfname = (TCHAR *)file_lfn;

    FRESULT res = f_opendir(&dir, dirpath);
    if (res != FR_OK) {
        printf("ips_find_patches: opendir(%s) failed: %d\n", dirpath, res);
        return 0;
    }

    uint8_t count = 0;

    for (;;) {
        res = f_readdir(&dir, &fno);
        if (res != FR_OK || fno.fname[0] == 0) break;
        /* Skip directories, hidden and system entries */
        if (fno.fattrib & (AM_DIR | AM_HID | AM_SYS)) continue;

        const char *fn = fno.lfname[0] ? fno.lfname : fno.fname;
        if (fn[0] == '.') continue;

        /* Check that the file has a '.' before extending */
        const char *dot = NULL;
        for (const char *p = fn; *p; p++) {
            if (*p == '.') dot = p;
        }
        if (!dot) continue;

        /* Check extension == "IPS" or "BPS" (case-insensitive) */
        const char *ext = dot + 1;
        char eu[4] = {0, 0, 0, 0};
        for (int i = 0; i < 3 && ext[i]; i++) {
            eu[i] = ext[i];
            if (eu[i] >= 'a' && eu[i] <= 'z') eu[i] -= 32;
        }
        int is_ips = (eu[0] == 'I' && eu[1] == 'P' && eu[2] == 'S' && eu[3] == 0);
        int is_bps = (eu[0] == 'B' && eu[1] == 'P' && eu[2] == 'S' && eu[3] == 0);
        if (!is_ips && !is_bps) continue;

        /* Filename must start with the ROM stem */
        if (!istartswith(fn, filename, stem_len)) continue;

        /* Also require total name length > stem_len so "ROM1.ips" (for ROM1.sfc)
           counts but a bare empty-extra file does not slip through */
        if (strlen(fn) <= stem_len) continue;

        if (count >= IPS_MAX_PATCHES) break;

        /* Display name: filename without the .ips extension */
        size_t name_len = (size_t)(dot - fn);
        if (name_len >= IPS_NAME_LEN) name_len = IPS_NAME_LEN - 1;
        memcpy(ips_entries[count].name, fn, name_len);
        ips_entries[count].name[name_len] = '\0';

        /* Full SD path: dirpath + '/' + fn */
        {
            int poff = 0;
            for (const char *d = dirpath; *d && poff < IPS_PATH_LEN - 1; )
                ips_entries[count].full_path[poff++] = *d++;
            if (poff > 0 && ips_entries[count].full_path[poff - 1] != '/'
                    && poff < IPS_PATH_LEN - 1)
                ips_entries[count].full_path[poff++] = '/';
            else if (poff == 0 && poff < IPS_PATH_LEN - 1)
                ips_entries[count].full_path[poff++] = '/';
            for (const char *f = fn; *f && poff < IPS_PATH_LEN - 1; )
                ips_entries[count].full_path[poff++] = *f++;
            ips_entries[count].full_path[poff] = '\0';
        }

        count++;
    }
    f_closedir(&dir);

    if (count == 0) return 0;

    /* Insertion sort by display name, ascending, case-insensitive */
    for (uint8_t i = 1; i < count; i++) {
        struct _ips_entry tmp;
        memcpy(&tmp, &ips_entries[i], sizeof(tmp));
        int8_t j = (int8_t)i - 1;
        while (j >= 0 && istrcmp(ips_entries[j].name, tmp.name) > 0) {
            memcpy(&ips_entries[j + 1], &ips_entries[j], sizeof(struct _ips_entry));
            j--;
        }
        memcpy(&ips_entries[j + 1], &tmp, sizeof(tmp));
    }

    /* Write results to SRAM */
    sram_writebyte(count, sram_addr);
    for (uint8_t i = 0; i < count; i++) {
        sram_writeblock(ips_entries[i].name,
                        sram_addr + 1 + (uint32_t)i * IPS_NAME_LEN,
                        (uint16_t)(strlen(ips_entries[i].name) + 1));
        sram_writeblock(ips_entries[i].full_path,
                        sram_addr + 512 + (uint32_t)i * IPS_PATH_LEN,
                        (uint16_t)(strlen(ips_entries[i].full_path) + 1));
    }

    printf("ips_find_patches: %d patch(es) for %s\n", count, rom_path);
    return count;
}

/* Write len bytes from buf to SRAM at addr using the FPGA SPI write-with-
   auto-increment command.  This mirrors the pattern in load_sram(). */
static void sram_write_from_buf(uint32_t addr, const uint8_t *buf, uint16_t len) {
    set_mcu_addr(addr);
    FPGA_SELECT();
    FPGA_TX_BYTE(0x98); /* WRITE, address auto-increment */
    for (uint16_t i = 0; i < len; i++) {
        FPGA_TX_BYTE(buf[i]);
        FPGA_WAIT_RDY();
    }
    FPGA_DESELECT();
}

uint32_t ips_apply(uint32_t sram_addr, uint8_t index, uint32_t rom_base_addr,
                   uint32_t original_rom_size, uint32_t rom_header_size) {
    if (index < 1 || index > IPS_MAX_PATCHES) return 0;

    /* Read the full IPS file path from SRAM */
    uint8_t ips_path[IPS_PATH_LEN];
    sram_readstrn(ips_path,
                  sram_addr + 512 + (uint32_t)(index - 1) * IPS_PATH_LEN,
                  sizeof(ips_path));

    printf("Applying IPS: %s\n", ips_path);

    file_open(ips_path, FA_READ);
    if (file_res != FR_OK) {
        printf("ips_apply: open failed (%d)\n", file_res);
        return 0;
    }

    /* Read and verify the 5-byte "PATCH" header */
    uint8_t hdr[5];
    UINT br;
    f_read(&file_handle, hdr, 5, &br);
    if (br != 5 || memcmp(hdr, "PATCH", 5) != 0) {
        printf("ips_apply: bad header\n");
        file_close();
        return 0;
    }

    /* ------------------------------------------------------------------
     * Pass 1: scan all record headers (skipping data bytes with f_lseek)
     * to determine max_end.  If the patch expands the ROM beyond
     * original_rom_size we must zero-fill the new area first — the SRAM
     * may contain old data from a previously loaded larger ROM.
     * ------------------------------------------------------------------ */
    uint32_t max_end = 0;
    uint32_t min_offset = 0xFFFFFFFFUL;
    uint32_t adj = 0;
    uint32_t adj_max_end = 0;
    uint8_t  rec[3];

    for (;;) {
        f_read(&file_handle, rec, 3, &br);
        if (br != 3) break;
        if (rec[0] == 0x45 && rec[1] == 0x4F && rec[2] == 0x46) break; /* EOF */

        uint8_t sz[2];
        f_read(&file_handle, sz, 2, &br);
        if (br != 2) break;
        uint16_t hunk_size = ((uint16_t)sz[0] << 8) | sz[1];

        if (hunk_size == 0) {
            /* RLE: 2-byte count, 1-byte value */
            uint8_t rle[3];
            f_read(&file_handle, rle, 3, &br);
            if (br != 3) break;
            uint32_t offset = ((uint32_t)rec[0] << 16) | ((uint32_t)rec[1] << 8) | rec[2];
            uint32_t rle_count = ((uint16_t)rle[0] << 8) | rle[1];
            if (offset < min_offset) min_offset = offset;
            if (offset + rle_count > max_end) max_end = offset + rle_count;
        } else {
            uint32_t offset = ((uint32_t)rec[0] << 16) | ((uint32_t)rec[1] << 8) | rec[2];
            if (offset < min_offset) min_offset = offset;
            if (offset + (uint32_t)hunk_size > max_end) max_end = offset + (uint32_t)hunk_size;
            /* Skip data bytes */
            f_lseek(&file_handle, file_handle.fptr + hunk_size);
        }
    }

    /* If the patch writes beyond the original ROM, zero-fill the extension
     * so that gaps between IPS records contain 0x00 as expected by the hack. */
    /* Determine the header-offset correction factor.
     * If the IPS was authored using a ROM with a copier header (common for
     * older IPS tools), its record offsets include those 512 header bytes.
     * When the ROM was loaded into SRAM without the header (rom_header_size==0
     * but the IPS starts below offset 512) we auto-detect this and compensate
     * so that the patch data lands at the correct SRAM positions. */
    adj = rom_header_size;
    if (adj == 0 && min_offset < 512)
        adj = 512;
    /* Secondary detection: IPS authored from a headered ROM where every
     * record offset includes the 512-byte copier header, and the last
     * record happens to end past the min_offset threshold.  A reliable
     * fingerprint is max_end == (power-of-2 ROM size) + 512 — the exact
     * file size of a headered ROM image.  Example: Mario Kart R has
     * max_end = 0x100200 = 1 MB + 512, so max_end - 512 = 0x100000 = 2^20. */
    if (adj == 0 && max_end > 512) {
        uint32_t maybe_romsize = max_end - 512;
        if (maybe_romsize && (maybe_romsize & (maybe_romsize - 1)) == 0)
            adj = 512;
    }
    if (adj > 0)
        printf("IPS: header offset correction: %lu bytes\n", (unsigned long)adj);

    adj_max_end = (max_end > adj) ? (max_end - adj) : 0;

    if (adj_max_end > original_rom_size) {
        uint32_t fill_len = adj_max_end - original_rom_size;
        printf("IPS: zeroing 0x%lx bytes from 0x%lx\n", (unsigned long)fill_len,
               (unsigned long)(rom_base_addr + original_rom_size));
        sram_memset(rom_base_addr + original_rom_size, fill_len, 0x00);
    }

    /* ------------------------------------------------------------------
     * Pass 2: seek back to the start of records and apply the patch.
     * ------------------------------------------------------------------ */
    f_lseek(&file_handle, 5); /* rewind to just after "PATCH" header */

    int err = 0;

    for (;;) {
        f_read(&file_handle, rec, 3, &br);
        if (br != 3) break;  /* truncated or EOF before "EOF" marker */

        /* IPS EOF marker: bytes 0x45 0x4F 0x46 ('E','O','F') */
        if (rec[0] == 0x45 && rec[1] == 0x4F && rec[2] == 0x46) break;

        /* 24-bit big-endian patch offset */
        uint32_t offset = ((uint32_t)rec[0] << 16)
                        | ((uint32_t)rec[1] <<  8)
                        |  (uint32_t)rec[2];

        /* 16-bit big-endian hunk size */
        uint8_t sz[2];
        f_read(&file_handle, sz, 2, &br);
        if (br != 2) { err = 1; break; }
        uint16_t hunk_size = ((uint16_t)sz[0] << 8) | sz[1];

        if (hunk_size == 0) {
            /* RLE record: 2-byte count + 1-byte fill value */
            uint8_t rle[3];
            f_read(&file_handle, rle, 3, &br);
            if (br != 3) { err = 1; break; }
            uint16_t rle_count = ((uint16_t)rle[0] << 8) | rle[1];
            uint8_t  rle_val   = rle[2];

            /* Skip records entirely within the header region. */
            if (offset + (uint32_t)rle_count <= adj) continue;
            /* Trim leading bytes that fall within the header region. */
            uint32_t rle_skip = (offset < adj) ? (adj - offset) : 0;
            uint32_t sram_off = (offset < adj) ? 0 : (offset - adj);
            uint16_t rle_write = (uint16_t)(rle_count - rle_skip);

            sram_memset(rom_base_addr + sram_off, rle_write, rle_val);
        } else {
            /* Data record: hunk_size bytes of replacement data. */
            /* Skip records entirely within the header region. */
            if (offset + (uint32_t)hunk_size <= adj) {
                f_lseek(&file_handle, file_handle.fptr + hunk_size);
                continue;
            }
            /* Seek past any leading bytes that fall within the header region. */
            uint32_t file_skip = (offset < adj) ? (adj - offset) : 0;
            if (file_skip > 0)
                f_lseek(&file_handle, file_handle.fptr + file_skip);
            uint32_t remain  = hunk_size - file_skip;
            uint32_t cur_off = (offset < adj) ? 0 : (offset - adj);
            while (remain > 0) {
                UINT to_read = (remain > sizeof(file_buf))
                               ? (UINT)sizeof(file_buf)
                               : (UINT)remain;
                f_read(&file_handle, file_buf, to_read, &br);
                if (br == 0) { err = 1; goto ips_apply_done; }
                sram_write_from_buf(rom_base_addr + cur_off, file_buf, (uint16_t)br);
                cur_off += br;
                remain  -= br;
            }
        }
    }

ips_apply_done:
    file_close();
    if (err) printf("ips_apply: error during patching\n");
    else     printf("ips_apply: done, adj=%lu adj_max_end=0x%lx\n",
                    (unsigned long)adj, (unsigned long)adj_max_end);
    return err ? 0 : adj_max_end;
}

/* ------------------------------------------------------------------
 * BPS patch support
 * ------------------------------------------------------------------ */

/* Read-ahead buffer for the BPS action stream.  Reading the patch file
 * one byte at a time through FatFS incurs per-call overhead on every VLI
 * byte; buffering ~256 bytes at once reduces that by ~256x. */
static uint8_t  bps_sb[256] __attribute__((section(".ahbram")));
static uint16_t bps_sb_pos;   /* next byte to consume */
static uint16_t bps_sb_len;   /* valid bytes in buffer */

/* Logical file position = fptr - (bps_sb_len - bps_sb_pos) */
#define BPS_LOGICAL_POS() \
    (file_handle.fptr - (uint32_t)(bps_sb_len - bps_sb_pos))

static uint8_t bps_read_byte(void) {
    if (bps_sb_pos >= bps_sb_len) {
        UINT br;
        f_read(&file_handle, bps_sb, sizeof(bps_sb), &br);
        bps_sb_len = (uint16_t)br;
        bps_sb_pos = 0;
        if (!br) return 0;
    }
    return bps_sb[bps_sb_pos++];
}

static uint32_t bps_decode_vli(void) {
    uint32_t data = 0, shift = 1;
    uint8_t x;
    for (;;) {
        x = bps_read_byte();
        data += (uint32_t)(x & 0x7f) * shift;
        if (x & 0x80) break;
        shift <<= 7;
        data += shift;
    }
    return data;
}

uint32_t bps_apply(uint32_t sram_addr, uint8_t index, uint32_t rom_base_addr,
                   uint32_t original_rom_size) {
    if (index < 1 || index > IPS_MAX_PATCHES) return 0;

    uint8_t bps_path[IPS_PATH_LEN];
    sram_readstrn(bps_path,
                  sram_addr + 512 + (uint32_t)(index - 1) * IPS_PATH_LEN,
                  sizeof(bps_path));

    printf("Applying BPS: %s\n", bps_path);

    file_open(bps_path, FA_READ);
    if (file_res != FR_OK) {
        printf("bps_apply: open failed (%d)\n", file_res);
        return 0;
    }

    /* Verify "BPS1" magic — read directly, buffer not yet active */
    uint8_t magic[4];
    UINT br;
    f_read(&file_handle, magic, 4, &br);
    if (br != 4 || memcmp(magic, "BPS1", 4) != 0) {
        printf("bps_apply: bad magic\n");
        file_close();
        return 0;
    }

    /* Activate buffered stream */
    bps_sb_pos = 0;
    bps_sb_len = 0;

    bps_decode_vli();                        /* source_size — unused */
    uint32_t target_size   = bps_decode_vli();
    uint32_t metadata_size = bps_decode_vli();

    if (metadata_size > 0) {
        /* Skip metadata: seek the real file cursor forward, then flush buffer */
        uint32_t logical = BPS_LOGICAL_POS();
        f_lseek(&file_handle, logical + metadata_size);
        bps_sb_pos = 0;
        bps_sb_len = 0;
    }

    /* Zero-fill any expansion area.
     * Skip for BPS: the BPS spec guarantees SourceRead only references
     * bytes within source_size, so the expansion region is fully written
     * by TargetRead / TargetCopy actions before it is ever read back. */
    tick_t t_bps_start = getticks();
    (void)t_bps_start; /* used below even when no memset */
    if (target_size > original_rom_size) {
        printf("BPS ROM expansion: 0x%lx -> 0x%lx\n",
               (unsigned long)original_rom_size, (unsigned long)target_size);
        /* No memset needed — expansion area is written before read by BPS actions */
    }

    /* In-place BPS patching overwrites SRAM as target bytes are written.
     * SourceCopy reads from the original source ROM, but those SRAM bytes
     * may have already been overwritten by a previous TargetRead or TargetCopy.
     * Fix: copy the source ROM to a scratch area above the target region
     * (rom_base_addr + target_size, safely below SRAM_SAVE_ADDR) and use
     * that read-only backup for all SourceCopy reads. */
    uint32_t source_base_addr = rom_base_addr + target_size;
    {
        uint32_t bak_off = 0;
        while (bak_off < original_rom_size) {
            uint16_t chunk = (original_rom_size - bak_off > (uint32_t)sizeof(file_buf))
                             ? (uint16_t)sizeof(file_buf)
                             : (uint16_t)(original_rom_size - bak_off);
            sram_readblock(file_buf, rom_base_addr + bak_off, chunk);
            sram_writeblock(file_buf, source_base_addr + bak_off, chunk);
            bak_off += chunk;
        }
    }

    /* Action data ends 12 bytes before EOF (3 x CRC32) */
    uint32_t action_end = file_handle.fsize - 12;

    uint32_t output_offset = 0;
    uint32_t source_rel    = 0;
    uint32_t target_rel    = 0;
    uint32_t n_actions     = 0;
    int err = 0;
    tick_t t_actions = getticks();

    /* Loop condition: check the logical (post-buffer) file position */
    while (BPS_LOGICAL_POS() < action_end && !err) {
        uint32_t d      = bps_decode_vli();
        uint8_t  action = (uint8_t)(d & 3);
        uint32_t length = (d >> 2) + 1;
        n_actions++;

        switch (action) {
            case 0: /* SourceRead: in-place — no-op */
                output_offset += length;
                break;

            case 1: { /* TargetRead: literal bytes from patch file.
                       * Drain the read-ahead buffer first, then bulk-read
                       * the remainder directly into file_buf (no copy via
                       * bps_sb needed). */
                /* Phase A: bytes already in bps_sb */
                uint16_t avail = bps_sb_len - bps_sb_pos;
                if (avail > (uint16_t)length) avail = (uint16_t)length;
                if (avail > 0) {
                    sram_write_from_buf(rom_base_addr + output_offset,
                                        bps_sb + bps_sb_pos, avail);
                    bps_sb_pos    += avail;
                    output_offset += avail;
                    length        -= avail;
                }
                /* Phase B: bulk read remaining bytes */
                while (length > 0) {
                    UINT to_read = (length > (uint32_t)sizeof(file_buf))
                                   ? (UINT)sizeof(file_buf) : (UINT)length;
                    f_read(&file_handle, file_buf, to_read, &br);
                    bps_sb_pos = 0;   /* fptr moved past our buffer */
                    bps_sb_len = 0;
                    if (br == 0) { err = 1; break; }
                    sram_write_from_buf(rom_base_addr + output_offset,
                                        file_buf, (uint16_t)br);
                    output_offset += br;
                    length        -= br;
                }
                break;
            }

            case 2: { /* SourceCopy: SRAM→SRAM copy from read-only source backup.
                       * Uses source_base_addr (a copy of the original ROM made before
                       * the action loop) so that in-place target writes can never
                       * corrupt the source bytes read here. */
                uint32_t d2    = bps_decode_vli();
                int32_t  delta = (d2 & 1) ? -(int32_t)(d2 >> 1) : (int32_t)(d2 >> 1);
                source_rel = (uint32_t)((int32_t)source_rel + delta);
                while (length > 0) {
                    uint16_t chunk = (length > (uint32_t)sizeof(file_buf))
                                     ? (uint16_t)sizeof(file_buf) : (uint16_t)length;
                    sram_readblock(file_buf, source_base_addr + source_rel, chunk);
                    sram_write_from_buf(rom_base_addr + output_offset,
                                        file_buf, chunk);
                    output_offset += chunk;
                    source_rel    += chunk;
                    length        -= chunk;
                }
                break;
            }

            case 3: { /* TargetCopy: copy from already-output data.
                       * src and dst offsets may overlap (RLE-style inflate).
                       *
                       * Fast path: when dist==1 the source byte is always the
                       * same value (a true RLE fill).  Read it once from SRAM
                       * and stream the fill value with sram_memset — avoids
                       * 1.14M individual sram_readblock+write pairs.
                       *
                       * General path: copy in chunks of min(length, dist, 512)
                       * so we never read ahead of the write cursor. */
                uint32_t d2    = bps_decode_vli();
                int32_t  delta = (d2 & 1) ? -(int32_t)(d2 >> 1) : (int32_t)(d2 >> 1);
                target_rel = (uint32_t)((int32_t)target_rel + delta);

                /* Check for RLE (dist == 0 or 1): the fill value is the byte
                 * at target_rel, and it stays constant throughout. */
                if (target_rel < output_offset &&
                    (output_offset - target_rel) <= 1) {
                    uint8_t fill;
                    sram_readblock(&fill, rom_base_addr + target_rel, 1);
                    /* Pre-fill file_buf with that byte for the memset-style write */
                    sram_memset(rom_base_addr + output_offset, length, fill);
                    target_rel    += length;
                    output_offset += length;
                } else {
                    while (length > 0) {
                        uint32_t chunk = length;
                        if (chunk > sizeof(file_buf))
                            chunk = sizeof(file_buf);
                        if (target_rel < output_offset) {
                            uint32_t dist = output_offset - target_rel;
                            if (chunk > dist) chunk = dist;
                        }
                        sram_readblock(file_buf, rom_base_addr + target_rel,
                                       (uint16_t)chunk);
                        sram_write_from_buf(rom_base_addr + output_offset,
                                            file_buf, (uint16_t)chunk);
                        target_rel    += chunk;
                        output_offset += chunk;
                        length        -= chunk;
                    }
                }
                break;
            }
        }
    }

    /* Read the BPS-embedded target CRC32 (at fsize-8..fsize-5) before closing */
    uint32_t bps_target_crc32 = 0;
    {
        uint8_t crc_bytes[4];
        UINT br2;
        f_lseek(&file_handle, file_handle.fsize - 8);
        f_read(&file_handle, crc_bytes, 4, &br2);
        if (br2 == 4) {
            bps_target_crc32 = (uint32_t)crc_bytes[0]
                             | ((uint32_t)crc_bytes[1] << 8)
                             | ((uint32_t)crc_bytes[2] << 16)
                             | ((uint32_t)crc_bytes[3] << 24);
        }
    }
    file_close();
    tick_t t_act_elapsed   = getticks() - t_actions;
    tick_t t_total_elapsed = getticks() - t_bps_start;
    printf("bps: %lu actions in %u ticks (%u ms), total %u ticks (%u ms)\n",
           (unsigned long)n_actions,
           (unsigned)t_act_elapsed,
           (unsigned)t_act_elapsed * 10u,
           (unsigned)t_total_elapsed,
           (unsigned)t_total_elapsed * 10u);
    if (err) {
        printf("bps_apply: error during patching\n");
    } else {
        printf("bps_apply: done, target_size=0x%lx\n", (unsigned long)target_size);
        /* Verify CRC32 of the patched SRAM against the BPS-embedded expected value.
         * Reads target_size bytes from SRAM in 512-byte chunks (~0.5 s for 2 MB). */
        uint32_t crc = crc32_init();
        uint32_t remaining = target_size, addr_off = 0;
        while (remaining > 0) {
            uint16_t chunk = (remaining > (uint32_t)sizeof(file_buf))
                             ? (uint16_t)sizeof(file_buf) : (uint16_t)remaining;
            sram_readblock(file_buf, rom_base_addr + addr_off, chunk);
            for (uint16_t i = 0; i < chunk; i++)
                crc = crc32_update(crc, file_buf[i]);
            addr_off  += chunk;
            remaining -= chunk;
        }
        crc = crc32_finalize(crc);
        printf("bps CRC32: expected=%08lx got=%08lx %s\n",
               (unsigned long)bps_target_crc32,
               (unsigned long)crc,
               crc == bps_target_crc32 ? "OK" : "MISMATCH");
    }
    return err ? 0 : target_size;
}

uint32_t patch_apply(uint32_t sram_addr, uint8_t index, uint32_t rom_base_addr,
                     uint32_t original_rom_size, uint32_t rom_header_size) {
    if (index < 1 || index > IPS_MAX_PATCHES) return 0;

    /* Read the stored SD path to determine the patch format from its extension */
    uint8_t path[IPS_PATH_LEN];
    sram_readstrn(path,
                  sram_addr + 512 + (uint32_t)(index - 1) * IPS_PATH_LEN,
                  sizeof(path));

    const char *dot = NULL;
    for (const char *p = (const char *)path; *p; p++)
        if (*p == '.') dot = p;

    if (dot) {
        char e0 = dot[1], e1 = dot[2], e2 = dot[3];
        if (e0 >= 'a' && e0 <= 'z') e0 -= 32;
        if (e1 >= 'a' && e1 <= 'z') e1 -= 32;
        if (e2 >= 'a' && e2 <= 'z') e2 -= 32;
        if (e0 == 'B' && e1 == 'P' && e2 == 'S')
            return bps_apply(sram_addr, index, rom_base_addr, original_rom_size);
    }
    return ips_apply(sram_addr, index, rom_base_addr, original_rom_size, rom_header_size);
}

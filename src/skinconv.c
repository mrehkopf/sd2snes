/* skinconv.c: old menu ROMs and themes as skins

   A menu ROM from before skin support (v0.1.7d - v1.12.x, stock or made
   with the theme editor) is converted into a skin the way the theme tool
   does it (www/themes/skinconv.js; keep the two in step, both must make
   the same skin). A theme file of the sd2snes fork by ludufre (.thm)
   holds the same assets as an old menu ROM: it is unpacked into the
   layout of one and converted as well. The ROM, the theme and the skin
   are in cart memory; the work data lives in ptrcache: the directory
   sort's buffer is idle whenever a skin is loaded. */

#include <string.h>
#include "config.h"
#include "memory.h"
#include "skinconv.h"

extern uint32_t ptrcache[QSORT_MAXELEM];

/* how the old menu used its assets (unchanged from v0.1.7d to v1.12.x) */
#define OAM_ENTRIES     24        /* oam_data_l: $60 bytes copied to OAM */
#define OAM_HIGH_BYTES  9         /* oam_data_h: 9 bytes copied to OAM $100 */
#define LOGOSPR_TILES   40        /* logospr: $500 bytes copied to VRAM */
#define HDMA_PAL_WRAM   (55 + 227) /* WRAM copies of hdma_pal_src and
                                     hdma_cg_addr_src, which follow each
                                     other in ROM and in WRAM */
#define HDMA_MATH_WRAM  19        /* WRAM copy of hdma_math_src */
#define FONT_SIZE       (256 * 16)
#define LOGO_TILES      224       /* 256x56 pixels, 8bpp */
#define MAX_BAR_HEIGHT  16
#define LINES           224
#define PIECES          (4 * OAM_ENTRIES)  /* 8x8 pieces of 16x16 sprites */
#define NO_TILE         0xffff

/* characters the menus with skin support use but old fonts leave empty:
   the bullet point and the separator tees, which join a horizontal line to
   the left and right window border (made from the font's own border
   characters if it has usable ones) */
#define FIRST_CHAR        16      /* old characters 0-15 were never shown */
#define OLD_ELLIPSIS_CHAR 127     /* 127 + 128; new menu: $81 + $8D */
#define OLD_BULLET_CHAR   129
#define ELLIPSIS_CHAR1    0x81
#define ELLIPSIS_CHAR2    0x8d
#define BULLET_CHAR       149
#define LINE_CHAR         25
#define LEFT_CHAR         26
#define RIGHT_CHAR        27
#define LEFT_TEE_CHAR     30
#define RIGHT_TEE_CHAR    31

static const uint8_t bullet[16] = {
  0x00, 0x00, 0x00, 0x60, 0x60, 0x90, 0x60, 0x90,
  0x00, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};
static const uint8_t left_tee[16] = {
  0x1c, 0x22, 0x1c, 0x22, 0x1c, 0x23, 0x1f, 0x20,
  0x1f, 0x20, 0x1c, 0x23, 0x1c, 0x22, 0x1c, 0x22
};
static const uint8_t right_tee[16] = {
  0x38, 0x44, 0x38, 0x44, 0x38, 0xc4, 0xf8, 0x04,
  0xf8, 0x04, 0x38, 0xc4, 0x38, 0x44, 0x38, 0x44
};

/* the sprite table of every old menu version (used when the offsets give
   no oam_data_l; no oam_data_h means all zeros) */
static const uint8_t stock_oam_l[4 * OAM_ENTRIES] = {
  88, 56, 0, 8,    96, 56, 1, 8,    104, 56, 2, 8,   112, 56, 3, 8,
  120, 56, 4, 8,   128, 56, 5, 8,   136, 56, 6, 8,   88, 64, 7, 8,
  96, 64, 8, 8,    104, 64, 9, 8,   112, 64, 10, 8,  88, 72, 14, 8,
  96, 72, 15, 8,   157, 56, 21, 10, 172, 56, 22, 12, 180, 56, 23, 12,
  172, 64, 24, 12, 172, 72, 26, 12, 172, 80, 28, 12, 172, 88, 30, 12,
  172, 96, 32, 12, 194, 56, 34, 14, 194, 64, 35, 14, 194, 72, 36, 14
};

/* free CGRAM colors that logo colors from the reserved range (the button
   palettes) move to, first these, in this order */
static const uint8_t logo_targets[] = {
  4, 8, 12, 16, 20, 24, 28, 32, 48, 64, 80, 96, 112,
  169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182,
  183, 184, 185, 186, 187, 188, 189, 190, 191,
  192, 208, 224, 240
};
#define MAX_SOURCES     39        /* reserved colors: 36-47, 52-63, 65-79 */

/* asset offsets (file offset = SNES address & $FFFF), in the order of the
   table after "_GFXPTR_" in v1.11.0 and later */
struct menu_offsets {
  uint16_t font, logo, logospr, hdma_math_src, hdma_bar_color_src,
           hdma_pal_src, oam_data_l, oam_data_h, palette;
};

/* older versions, by header checksum ($FFDE): the table of
   www/themes/index.html */
static const struct {
  uint16_t checksum;
  struct menu_offsets o;
} menu_versions[] = {
  { 0xD4F0, { 0x099D, 0x25C8, 0x5DC8, 0x1D02, 0x1D15, 0x1BC1, 0x1D1D, 0x1D7D, 0x199D } },  /* v0.1.7d */
  { 0xCDD1, { 0x099D, 0x25C8, 0x5DC8, 0x1D02, 0x1D15, 0x1BC1, 0x1D1D, 0x1D7D, 0x199D } },  /* v0.1.7e */
  { 0xAC48, { 0x099D, 0x2623, 0x5E23, 0x1D02, 0x1D15, 0x1BC1, 0x1D1D, 0x1D7D, 0x199D } },  /* v0.1.7e-gsu-v07 */
  { 0xEEFD, { 0x0996, 0x2776, 0x5F76, 0x1CFB, 0x1D0E, 0x1BBA, 0x1D16, 0x1D76, 0x1996 } },  /* v1.8.0 */
  { 0x4EDE, { 0x0996, 0x28BE, 0x60BE, 0x1CFB, 0x1D0E, 0x1BBA, 0x1D16, 0x1D76, 0x1996 } },  /* v1.8.0 - Savestate */
  { 0x723E, { 0x09C1, 0x28FB, 0x60FB, 0x1D26, 0x1D39, 0x1BE5, 0x1D41, 0x1DA1, 0x19C1 } },  /* v1.8.0 SDD1 */
  { 0x70DE, { 0x09C9, 0x2903, 0x6103, 0x1D2E, 0x1D41, 0x1BED, 0x1D49, 0x1DA9, 0x19C9 } },  /* v1.9.0 SDD1 */
  { 0x9DB3, { 0x09C9, 0x2903, 0x6103, 0x1D2E, 0x1D41, 0x1BED, 0x1D49, 0x1DA9, 0x19C9 } },  /* v1.9.0 */
  { 0x9DBB, { 0x09C9, 0x2903, 0x6103, 0x1D2E, 0x1D41, 0x1BED, 0x1D49, 0x1DA9, 0x19C9 } },  /* v1.10.0 */
  { 0x9DBC, { 0x09C9, 0x2903, 0x6103, 0x1D2E, 0x1D41, 0x1BED, 0x1D49, 0x1DA9, 0x19C9 } },  /* v1.10.1 */
  { 0x9DFF, { 0x09C9, 0x2903, 0x6103, 0x1D2E, 0x1D41, 0x1BED, 0x1D49, 0x1DA9, 0x19C9 } },  /* v1.10.2 */
  { 0xA3BF, { 0x09D2, 0x290C, 0x610C, 0x1D37, 0x1D4A, 0x1BF6, 0x1D52, 0x1DB2, 0x19D2 } },  /* v1.10.3 */
  { 0x2AC2, { 0x09D2, 0x2A31, 0x6231, 0x1D37, 0x1D4A, 0x1BF6, 0x1D52, 0x1DB2, 0x19D2 } },  /* v1.10.3-frs-v11 */
  { 0xF0BC, { 0x09D2, 0x2C1A, 0x641A, 0x1D37, 0x1D4A, 0x1BF6, 0x1D52, 0x1DB2, 0x19D2 } },  /* v1.10.3-frs-v12 */
  { 0x1AF2, { 0x09D2, 0x2C36, 0x6436, 0x1D37, 0x1D4A, 0x1BF6, 0x1D52, 0x1DB2, 0x19D2 } },  /* v1.10.3-frs-v12B */
  { 0x0969, { 0x09E1, 0x2D0A, 0x650A, 0x1D46, 0x1D59, 0x1C05, 0x1D61, 0x1DC1, 0x19E1 } },  /* v1.11.0b1 */
};

struct piece {                  /* an 8x8 piece of an old sprite */
  uint16_t x, t;
  uint8_t y, a;
};

struct group {                  /* a 16x16 sprite of the skin */
  uint16_t x, quad[4];          /* tiles: top left, top right, bottom ... */
  uint8_t y, a;
};

struct skinconv_work {
  struct menu_offsets o;
  uint32_t rom, out_addr;
  struct piece piece[PIECES];
  struct group group[PIECES];
  uint16_t palette[256];
  uint16_t lines[256];          /* hdma_lines(): offset + 1 of a line's data */
  uint8_t buf[HDMA_PAL_WRAM];   /* HDMA tables, OAM, "_GFXPTR_" search */
  uint8_t map[256], into[256];
  uint8_t logo_used[32], logo_final[32], sprite_colors[32], into_set[32],
          piece_used[PIECES / 8];
  uint8_t moving[MAX_SOURCES], targets[MAX_SOURCES];
  uint8_t bar[2][4 * MAX_BAR_HEIGHT];
  uint8_t glyph[4][16];
  uint8_t tile[64], pixels[64];
  uint8_t out[64];
  uint8_t out_n;
};
_Static_assert(sizeof(struct skinconv_work) <= sizeof(ptrcache), "ptrcache is skinconv's work area");

static struct skinconv_work *const w = (struct skinconv_work *)ptrcache;

static int bit(const uint8_t *set, uint8_t i) {
  return set[i >> 3] & (1 << (i & 7));
}

static void set_bit(uint8_t *set, uint8_t i) {
  set[i >> 3] |= 1 << (i & 7);
}

static int in_rom(uint32_t offset, uint32_t len) {
  return offset + len <= SKINCONV_ROM_SIZE;
}

static void rom_read(void *buf, uint32_t offset, uint16_t len) {
  sram_readblock(buf, w->rom + offset, len);
}

/* the skin is written in sequence */
static void out_flush(void) {
  if(w->out_n) {
    sram_writeblock(w->out, w->out_addr, w->out_n);
    w->out_addr += w->out_n;
    w->out_n = 0;
  }
}

static void out_byte(uint8_t b) {
  w->out[w->out_n++] = b;
  if(w->out_n == sizeof(w->out)) out_flush();
}

static void out_bytes(const uint8_t *src, uint16_t len) {
  while(len--) out_byte(*src++);
}

static void out_zero(uint16_t len) {
  while(len--) out_byte(0);
}

static void out_word(uint16_t v) {
  out_byte(v);
  out_byte(v >> 8);
}

static void out_chunk(const char *id, uint32_t len) {
  out_bytes((const uint8_t*)"SNS\1", 4);      /* version 1 */
  out_bytes((const uint8_t*)id, 4);
  out_word(len);
  out_word(len >> 16);
}

/* pixel values of an 8x8 tile with the given number of bit planes and back */
static void tile_pixels(const uint8_t *tile, uint8_t *px, int planes) {
  int x, y, p;
  for(y = 0; y < 8; y++) {
    for(x = 0; x < 8; x++) {
      uint8_t v = 0;
      for(p = 0; p < planes; p++) {
        v |= ((tile[16 * (p >> 1) + 2 * y + (p & 1)] >> (7 - x)) & 1) << p;
      }
      px[8 * y + x] = v;
    }
  }
}

static void tile_bytes(const uint8_t *px, uint8_t *tile, int planes) {
  int x, y, p;
  memset(tile, 0, 8 * planes);
  for(y = 0; y < 8; y++) {
    for(x = 0; x < 8; x++) {
      for(p = 0; p < planes; p++) {
        tile[16 * (p >> 1) + 2 * y + (p & 1)] |= ((px[8 * y + x] >> p) & 1) << (7 - x);
      }
    }
  }
}

/* Expand an HDMA table into w->lines, one entry per line: the offset + 1 of
   the bytes written on that line, or 0 if the channel writes nothing.
   Stops at the end mark, after max lines, or at the end of buf. Returns the
   number of lines. */
static uint16_t hdma_lines(const uint8_t *buf, uint16_t len, uint8_t unit, uint16_t max) {
  uint16_t n = 0, p = 0, k, count;
  uint8_t c, repeat;
  while(n < max && p < len) {
    c = buf[p++];
    if(!c) break;
    repeat = c & 0x80;
    count = (c & 0x7f) ? (c & 0x7f) : 128;
    for(k = 0; k < count && n < max; k++) {
      if(k == 0 || repeat) {
        if(p + unit > len) return n;
        w->lines[n++] = p + 1;
        p += unit;
      } else {
        w->lines[n++] = 0;
      }
    }
  }
  return n;
}

static int find_offsets(void) {
  static const char marker[] = "_GFXPTR_";
  uint32_t base, len, i;
  uint16_t checksum;
  /* v1.11.0 and later: the table after "_GFXPTR_" */
  for(base = 0; base + 8 <= SKINCONV_ROM_SIZE; base += sizeof(w->buf) - 7) {
    len = SKINCONV_ROM_SIZE - base;
    if(len > sizeof(w->buf)) len = sizeof(w->buf);
    rom_read(w->buf, base, len);
    for(i = 0; i + 8 <= len; i++) {
      if(!memcmp(w->buf + i, marker, 8)) {
        if(!in_rom(base + i + 8, sizeof(w->o))) return 0;
        rom_read(&w->o, base + i + 8, sizeof(w->o));
        return 1;
      }
    }
  }
  rom_read(&checksum, 0xffde, 2);
  for(i = 0; i < sizeof(menu_versions) / sizeof(menu_versions[0]); i++) {
    if(menu_versions[i].checksum == checksum) {
      w->o = menu_versions[i].o;
      return 1;
    }
  }
  return 0;
}

/* CGRAM colors reserved for button graphics, which a skin must not write */
static int reserved(int c) {
  return (c >= 36 && c <= 47) || (c >= 52 && c <= 63) || (c >= 65 && c <= 79);
}

/* colors 1-3 of the text palettes (BG2: 4p + 1..3, BG1: 16p + 1..3) */
static int text_color(int c) {
  return c < 32 ? (c & 3) != 0 : c < 128 && (c & 15) >= 1 && (c & 15) <= 3;
}

static int logo_target(int c) {
  return memchr(logo_targets, c, sizeof(logo_targets)) != NULL;
}

static int free_color(int c) {
  return !bit(w->logo_used, c) && !bit(w->sprite_colors, c);
}

static uint16_t color_dist2(int c, int d) {
  uint16_t a = w->palette[c], b = w->palette[d];
  int dr = (a & 31) - (b & 31), dg = ((a >> 5) & 31) - ((b >> 5) & 31),
      db = ((a >> 10) & 31) - ((b >> 10) & 31);
  return dr * dr + dg * dg + db * db;
}

static int on_screen(uint16_t x, uint8_t y) {
  int sx = x >= 256 ? x - 512 : x;   /* X is 9 bits */
  int k;
  if(sx <= -8 || sx >= 256) return 0;
  for(k = 0; k < 8; k++) {
    if(((y + k) & 0xff) < LINES) return 1;
  }
  return 0;
}

/* OAMT, part 1: the old 8x8 / 16x16 sprites, regrouped into 16x16 sprites
   (w->group), and the CGRAM colors they show (w->sprite_colors). Returns
   the number of sprites, -1 for a tile outside the ROM. */
static int sprite_groups(void) {
  static const uint8_t dx[3] = { 8, 0, 8 }, dy[3] = { 0, 8, 8 };
  uint8_t *oam_l = w->buf, *oam_h = w->buf + 4 * OAM_ENTRIES;
  int i, j, q, cx, cy, n, pieces = 0, groups = 0;
  if(w->o.oam_data_l) {
    rom_read(oam_l, w->o.oam_data_l, 4 * OAM_ENTRIES);
  } else {
    memcpy(oam_l, stock_oam_l, 4 * OAM_ENTRIES);
  }
  if(w->o.oam_data_h) {
    rom_read(oam_h, w->o.oam_data_h, OAM_HIGH_BYTES);
  } else {
    memset(oam_h, 0, OAM_HIGH_BYTES);
  }
  /* split into 8x8 pieces in OAM order */
  for(i = 0; i < OAM_ENTRIES; i++) {
    uint8_t high = oam_h[i >> 2] >> (2 * (i & 3));
    uint16_t x = oam_l[4 * i] | ((high & 1) << 8);
    uint8_t y = oam_l[4 * i + 1], a = oam_l[4 * i + 3];
    uint16_t t = oam_l[4 * i + 2] | ((a & 1) << 8);
    n = (high & 2) ? 2 : 1;
    for(cy = 0; cy < n; cy++) {
      for(cx = 0; cx < n; cx++) {
        /* tile numbers wrap within a row of 16 and within 16 rows */
        struct piece *p = &w->piece[pieces];
        p->t = (t & 0x100) | ((t + 16 * cy) & 0xf0) | ((t + cx) & 0x0f);
        p->x = (x + 8 * ((a & 0x40) ? n - 1 - cx : cx)) & 0x1ff;
        p->y = y + 8 * ((a & 0x80) ? n - 1 - cy : cy);
        p->a = a & 0xfe;
        if(on_screen(p->x, p->y)) pieces++;
      }
    }
  }
  /* regroup into 16x16 sprites */
  memset(w->piece_used, 0, sizeof(w->piece_used));
  for(i = 0; i < pieces; i++) {
    struct piece *p = &w->piece[i];
    struct group *g;
    if(bit(w->piece_used, i)) continue;
    set_bit(w->piece_used, i);
    g = &w->group[groups++];
    g->x = p->x;
    g->y = p->y;
    g->a = p->a;
    g->quad[0] = g->quad[1] = g->quad[2] = g->quad[3] = NO_TILE;
    if(p->a & 0xc0) {
      /* flipped: alone, in the quadrant that ends up at the sprite position */
      g->quad[((p->a & 0x40) ? 1 : 0) + ((p->a & 0x80) ? 2 : 0)] = p->t;
    } else {
      g->quad[0] = p->t;
      for(j = 0; j < pieces; j++) {
        struct piece *p2 = &w->piece[j];
        if(bit(w->piece_used, j) || p2->a != p->a) continue;
        for(q = 0; q < 3; q++) {
          if(p2->x == ((p->x + dx[q]) & 0x1ff) && p2->y == (uint8_t)(p->y + dy[q])
             && g->quad[q + 1] == NO_TILE) {
            g->quad[q + 1] = p2->t;
            set_bit(w->piece_used, j);
          }
        }
      }
    }
  }
  /* the colors the sprites show (tiles the old menu never loaded stay empty) */
  memset(w->sprite_colors, 0, sizeof(w->sprite_colors));
  for(i = 0; i < groups; i++) {
    for(q = 0; q < 4; q++) {
      uint16_t t = w->group[i].quad[q];
      if(t == NO_TILE || t >= LOGOSPR_TILES) continue;
      if(!in_rom(w->o.logospr + 32 * t, 32)) return -1;
      rom_read(w->tile, w->o.logospr + 32 * t, 32);
      tile_pixels(w->tile, w->pixels, 4);
      for(j = 0; j < 64; j++) {
        if(w->pixels[j]) set_bit(w->sprite_colors, 128 + 16 * ((w->group[i].a >> 1) & 7) + w->pixels[j]);
      }
    }
  }
  return groups;
}

/* LOGO and CGEN, part 1: move the logo colors out of the reserved range
   (w->map, w->palette; w->logo_final: the colors the logo ends up with).
   Too few free colors: merge colors into the most similar other logo
   color, the closest pair first, until the rest fit. No logo: only the
   palette. */
static void logo_colors(int logo) {
  int tile, i, j, c, k, moving = 0, targets = 0;
  rom_read(w->palette, w->o.palette, 512);
  memset(w->logo_used, 0, sizeof(w->logo_used));
  for(tile = 0; logo && tile < LOGO_TILES; tile++) {
    rom_read(w->tile, w->o.logo + 64 * tile, 64);
    tile_pixels(w->tile, w->pixels, 8);
    for(i = 0; i < 64; i++) set_bit(w->logo_used, w->pixels[i]);
  }
  for(c = 0; c < 256; c++) {
    if(bit(w->logo_used, c) && reserved(c)) w->moving[moving++] = c;
  }
  for(i = 0; i < (int)sizeof(logo_targets); i++) {
    if(free_color(logo_targets[i])) {
      if(targets < MAX_SOURCES) w->targets[targets] = logo_targets[i];
      targets++;
    }
  }
  for(c = 1; c < 256; c++) {
    if(free_color(c) && !text_color(c) && !reserved(c) && !logo_target(c)) {
      if(targets < MAX_SOURCES) w->targets[targets] = c;
      targets++;
    }
  }
  memset(w->into_set, 0, sizeof(w->into_set));
  while(moving > targets) {
    uint8_t best = w->moving[moving - 1], best_into = 0;
    uint16_t best_dist = 0xffff, d;
    for(i = 0; i < moving; i++) {
      c = w->moving[i];
      /* candidates: the logo colors that stay, then the moving ones */
      for(k = 1; k < 256 + moving; k++) {
        int to = k < 256 ? k : w->moving[k - 256];
        if(k < 256 && (!bit(w->logo_used, k) || reserved(k))) continue;
        d = to == c ? 0xffff : color_dist2(c, to);
        if(d < best_dist) {
          best = c;
          best_into = to;
          best_dist = d;
        }
      }
    }
    w->into[best] = best_into;
    set_bit(w->into_set, best);
    for(i = 0; w->moving[i] != best; i++);
    for(moving--; i < moving; i++) w->moving[i] = w->moving[i + 1];
  }
  for(c = 0; c < 256; c++) w->map[c] = c;
  for(i = 0; i < moving; i++) {
    w->map[w->moving[i]] = w->targets[i];
    w->palette[w->targets[i]] = w->palette[w->moving[i]];
  }
  memset(w->logo_final, 0, sizeof(w->logo_final));
  for(c = 0; c < 256; c++) {
    if(bit(w->logo_used, c) && reserved(c)) {
      for(j = c; bit(w->into_set, j); j = w->into[j]);
      w->map[c] = w->map[j];
    }
    if(bit(w->logo_used, c)) set_bit(w->logo_final, w->map[c]);
  }
}

/* Separator tee: the border character, and the line character on the side
   of the window inside (columns right of the border's rightmost pixel for
   the left border, left of its leftmost pixel for the right one). Returns
   0 if the border or the line is empty. */
static int make_tee(uint8_t *tee, const uint8_t *border, const uint8_t *line, int left) {
  int edge = left ? -1 : 8, x, y;
  uint8_t line_used = 0, inside, sel;
  for(y = 0; y < 8; y++) {
    line_used |= line[2 * y] | line[2 * y + 1];
    for(x = 0; x < 8; x++) {
      if(((border[2 * y] | border[2 * y + 1]) << x) & 0x80) {
        if(left ? x > edge : x < edge) edge = x;
      }
    }
  }
  if(edge == -1 || edge == 8 || !line_used) return 0;
  inside = left ? 0xff >> edge : 0xff << (7 - edge);
  for(y = 0; y < 2 * 8; y += 2) {
    sel = inside & (line[y] | line[y + 1]);
    tee[y] = (border[y] & ~sel) | (line[y] & sel);
    tee[y + 1] = (border[y + 1] & ~sel) | (line[y + 1] & sel);
  }
  return 1;
}

static int glyph_empty(const uint8_t *g) {
  int i;
  for(i = 0; i < 16; i++) {
    if(g[i]) return 0;
  }
  return 1;
}

static void glyph(uint8_t *g, int c) {
  rom_read(g, w->o.font + 16 * c, 16);
}

/* FONT: 2bpp 8x8 (16 bytes) -> 4bpp 16x8 (64 bytes), characters 16-255 */
static void out_font(void) {
  uint8_t *line = w->glyph[0], *left = w->glyph[1], *right = w->glyph[2],
          *g = w->glyph[3];
  int c;
  /* characters 30 and 31 were unused before */
  glyph(line, LINE_CHAR);
  glyph(g, LEFT_CHAR);
  c = make_tee(left, g, line, 1);
  glyph(g, RIGHT_CHAR);
  if(!make_tee(right, g, line, 0) || !c) {
    memcpy(left, left_tee, 16);
    memcpy(right, right_tee, 16);
  }
  out_chunk("FONT", 4 + (256 - FIRST_CHAR) * 64);
  out_word(FIRST_CHAR);
  out_word(256 - FIRST_CHAR);
  for(c = FIRST_CHAR; c < 256; c++) {
    if(c == LEFT_TEE_CHAR) {
      memcpy(g, left, 16);
    } else if(c == RIGHT_TEE_CHAR) {
      memcpy(g, right, 16);
    } else if(c == OLD_ELLIPSIS_CHAR || c == OLD_ELLIPSIS_CHAR + 1) {
      memset(g, 0, 16);
    } else if(c == ELLIPSIS_CHAR1) {
      glyph(g, OLD_ELLIPSIS_CHAR);
    } else if(c == ELLIPSIS_CHAR2) {
      glyph(g, OLD_ELLIPSIS_CHAR + 1);
    } else if(c == BULLET_CHAR) {
      glyph(g, OLD_BULLET_CHAR);
      if(glyph_empty(g)) {
        glyph(g, BULLET_CHAR);
        if(glyph_empty(g)) memcpy(g, bullet, 16);
      }
    } else {
      glyph(g, c);
    }
    out_bytes(g, 16);
    out_zero(64 - 16);
  }
}

/* GRAD: hdma_pal_src wrote color 0 -> one record per line */
static void out_gradient(void) {
  uint16_t n, y;
  uint8_t lohi[2];
  rom_read(lohi, w->o.palette, 2);
  rom_read(w->buf, w->o.hdma_pal_src, HDMA_PAL_WRAM);
  n = hdma_lines(w->buf, HDMA_PAL_WRAM, 2, LINES);
  out_chunk("GRAD", 4 * LINES);
  for(y = 0; y < LINES; y++) {
    if(y < n && w->lines[y]) {
      lohi[0] = w->buf[w->lines[y] - 1];
      lohi[1] = w->buf[w->lines[y]];
    }
    out_word(0);
    out_bytes(lohi, 2);
  }
}

static void coldata(uint8_t *rgb, uint8_t v) {
  int c;
  for(c = 0; c < 3; c++) {
    if(v & (0x20 << c)) rgb[c] = v & 0x1f;
  }
}

/* Selection bar of one variant of hdma_bar_color_src: per-line records
   [CGADSUB, $20|r, $40|g, $80|b] in rec; returns the number of lines, 0
   if the table can't be expressed as a bar */
static int bar_records(int variant, uint8_t *rec) {
  uint8_t *t = w->buf, rgb[3] = { 0, 0, 0 }, cgadsub = 0;
  const uint8_t *l;
  uint16_t n, y = 0;
  int pass, k, count = 0;
  rom_read(t, w->o.hdma_math_src, HDMA_MATH_WRAM);
  rom_read(t + HDMA_MATH_WRAM, w->o.hdma_bar_color_src + 4 * variant, 4);
  for(k = 0; k < 4; k++) {
    t[2 + 3 * k] = t[HDMA_MATH_WRAM + k];     /* what set_bar_color patches */
  }
  /* Entries 0 and 1 cover the lines above the bar (the NMI set their line
     counts); the bar starts with entry 2. COLDATA keeps its value from the
     end of the previous frame, so run the whole table once first. */
  n = hdma_lines(t + 6, HDMA_MATH_WRAM - 6, 2, 256);
  for(pass = 0; pass < 2; pass++) {
    coldata(rgb, t[2]);
    coldata(rgb, t[5]);
    count = 0;
    cgadsub = 0xff;
    for(y = 0; y < n; y++) {
      if(w->lines[y]) {
        l = t + 6 + w->lines[y] - 1;
        if(pass && !l[0]) break;              /* color math off: end of bar */
        cgadsub = l[0];
        coldata(rgb, l[1]);
      }
      if(pass && count < MAX_BAR_HEIGHT) {
        rec[4 * count] = cgadsub;
        rec[4 * count + 1] = 0x20 | rgb[0];
        rec[4 * count + 2] = 0x40 | rgb[1];
        rec[4 * count + 3] = 0x80 | rgb[2];
      }
      count++;
    }
  }
  /* never switches color math off, or no / too many lines */
  if(y == n || !count || count > MAX_BAR_HEIGHT) return 0;
  return count;
}

/* CRSR: selection bar, normal and active (editing) variant */
static void out_bar(void) {
  int h = bar_records(0, w->bar[0]);
  if(!h || bar_records(1, w->bar[1]) != h) return;  /* the default bar stays */
  out_chunk("CRSR", 2 + 8 * h);
  out_byte(h);
  out_byte(0);                                  /* starts at the top line of the row */
  out_bytes(w->bar[0], 4 * h);
  out_bytes(w->bar[1], 4 * h);
}

/* OAMT, part 2: sprite i uses the 2x2 tile block at row 2*(i div 8),
   column 2*(i mod 8) of the tile data, which starts at sprite tile 64 */
static void out_sprites(int s) {
  int tiles = (s + 7) / 8 * 2 * 16, hi_bytes = (s + 3) / 4, i, k, q;
  uint8_t hi;
  out_chunk("OAMT", 228 + 4 * s + hi_bytes + 32 * tiles);
  out_word(tiles);
  out_byte(s);
  out_zero(1 + 224);                            /* 224 x sprite page 0 */
  for(i = 0; i < s; i++) {
    int n = 64 + 32 * (i >> 3) + 2 * (i & 7);
    out_byte(w->group[i].x);
    out_byte(w->group[i].y);
    out_byte(n);
    out_byte(w->group[i].a | (n >> 8));
  }
  for(k = 0; k < hi_bytes; k++) {
    hi = 0;
    for(i = 4 * k; i < 4 * k + 4 && i < s; i++) {
      hi |= (w->group[i].x >> 8) << (2 * (i & 3));   /* size bit 0: 16x16 */
    }
    out_byte(hi);
  }
  for(k = 0; k < tiles; k++) {
    uint16_t t = NO_TILE;
    i = 8 * (k >> 5) + ((k & 15) >> 1);
    q = 2 * ((k >> 4) & 1) + (k & 1);
    if(i < s) t = w->group[i].quad[q];
    if(t != NO_TILE && t < LOGOSPR_TILES) {     /* else never loaded by the old menu */
      rom_read(w->tile, w->o.logospr + 32 * t, 32);
      out_bytes(w->tile, 32);
    } else {
      out_zero(32);
    }
  }
}

/* the parts of a skin that convert() makes */
#define PART_COLORS     0x01      /* CGEN: text colors, and the logo's */
#define PART_ALL_COLORS 0x02      /* CGEN: all writable colors */
#define PART_FONT       0x04
#define PART_LOGO       0x08
#define PART_GRADIENT   0x10
#define PART_BAR        0x20
#define PART_SPRITES    0x40

static int cgen_color(int c, uint8_t parts) {
  if(reserved(c) || !(parts & (PART_COLORS | PART_ALL_COLORS))) return 0;
  return (parts & PART_ALL_COLORS) || text_color(c)
         || ((parts & PART_LOGO) && c && bit(w->logo_final, c));
}

/* convert the assets at the offsets w->o of the "ROM" at w->rom */
static uint32_t convert(uint32_t skin_addr, uint8_t parts) {
  int sprites = 0, tile, first, count, c;
  if(parts & PART_SPRITES) {
    sprites = sprite_groups();
    if(sprites < 0) return 0;
  } else {
    /* the menu's own sprites stay: keep the logo out of their colors */
    memset(w->sprite_colors, 0, sizeof(w->sprite_colors) / 2);
    memset(w->sprite_colors + sizeof(w->sprite_colors) / 2, 0xff, sizeof(w->sprite_colors) / 2);
  }
  logo_colors(parts & PART_LOGO);
  w->out_addr = skin_addr;
  w->out_n = 0;
  /* CGEN: one chunk per run of colors */
  for(first = 0; first < 256; first += count) {
    for(count = 0; first + count < 256 && cgen_color(first + count, parts); count++);
    if(!count) {
      count = 1;
      continue;
    }
    out_chunk("CGEN", 4 + 2 * count);
    out_word(first);
    out_word(count);
    for(c = first; c < first + count; c++) out_word(w->palette[c]);
  }
  if(parts & PART_FONT) out_font();
  if(parts & PART_LOGO) {
    out_chunk("LOGO", 64 * LOGO_TILES);
    for(tile = 0; tile < LOGO_TILES; tile++) {
      rom_read(w->tile, w->o.logo + 64 * tile, 64);
      tile_pixels(w->tile, w->pixels, 8);
      for(c = 0; c < 64; c++) w->pixels[c] = w->map[w->pixels[c]];
      tile_bytes(w->pixels, w->tile, 8);
      out_bytes(w->tile, 64);
    }
  }
  if(parts & PART_GRADIENT) out_gradient();
  if(parts & PART_BAR) out_bar();
  if(parts & PART_SPRITES) out_sprites(sprites);
  out_flush();
  return w->out_addr - skin_addr;
}

uint32_t skinconv_menu_rom(uint32_t rom_addr, uint32_t skin_addr) {
  w->rom = rom_addr;
  if(!find_offsets()
     || !in_rom(w->o.font, FONT_SIZE) || !in_rom(w->o.logo, 64 * LOGO_TILES)
     || !in_rom(w->o.palette, 512) || !in_rom(w->o.hdma_pal_src, HDMA_PAL_WRAM)
     || !in_rom(w->o.hdma_math_src, HDMA_MATH_WRAM) || !in_rom(w->o.hdma_bar_color_src, 8)
     || (w->o.oam_data_l && !in_rom(w->o.oam_data_l, 4 * OAM_ENTRIES))
     || (w->o.oam_data_h && !in_rom(w->o.oam_data_h, OAM_HIGH_BYTES))) {
    return 0;
  }
  return convert(skin_addr, PART_ALL_COLORS | PART_FONT | PART_LOGO | PART_GRADIENT
                            | PART_BAR | PART_SPRITES);
}

/* Theme files (.thm) of ludufre's fork: "FXTHEME1", version 1, the number
   of parts (1-9), flags (2 bytes), 4 reserved bytes; then per part its slot
   (one of the "_GFXPTR_" assets), a reserved byte and its length (2 bytes);
   then the parts. The fork copies a part over the asset in its menu (up to
   the size of the asset), the logo palette to CGRAM 64-95 after the
   palette. Its font and sprite graphics are not in the theme, nor are they
   converted here; the flags (font outline and anti-aliasing off) are left
   out. */
#define THM_HEADER      16
#define THM_PARTS       9
#define THM_LOGO_PAL    1
#define THM_MATH        2
#define THM_BAR_COLOR   3
#define THM_PAL_SRC     4
#define THM_PALETTE     7
#define THM_LOGO        8

/* where the parts go in the old menu ROM made from them, and their size;
   the gradient table is read as HDMA_PAL_WRAM bytes */
static const struct {
  uint16_t offset, size;
} thm_slots[THM_PARTS] = {
  { 0, 0 },                     /* font: never part of a theme */
  { 0x0080, 64 },               /* logo palette: colors 64-95 of the palette */
  { 0x3c00, HDMA_MATH_WRAM },
  { 0x3c20, 8 },
  { 0x3a00, 55 },
  { 0, 0 },                     /* sprite positions: no sprite graphics */
  { 0, 0 },
  { 0x0000, 512 },
  { 0x0200, 64 * LOGO_TILES },
};
#define THM_ROM_SIZE    0x3c28

/* copy len bytes in cart memory */
static void copy(uint32_t dst, uint32_t src, uint32_t len) {
  uint16_t n;
  while(len) {
    n = len > sizeof(w->buf) ? sizeof(w->buf) : len;
    sram_readblock(w->buf, src, n);
    sram_writeblock(w->buf, dst, n);
    src += n;
    dst += n;
    len -= n;
  }
}

uint32_t skinconv_theme(uint32_t thm_addr, uint32_t thm_size, uint32_t work_addr, uint32_t skin_addr) {
  uint8_t head[THM_HEADER], toc[4 * THM_PARTS], slot, parts = 0;
  uint16_t have = 0;
  uint32_t data, len, i, row, n, logo_pal = 0, logo_pal_len = 0;
  sram_readblock(head, thm_addr, THM_HEADER);
  n = head[9];
  if(memcmp(head, "FXTHEME1", 8) || head[8] != 1 || !n || n > THM_PARTS
     || thm_size < THM_HEADER + 4 * n) {
    return 0;
  }
  sram_readblock(toc, thm_addr + THM_HEADER, 4 * n);
  data = THM_HEADER + 4 * n;
  for(i = 0; i < n; i++) data += toc[4 * i + 2] | (toc[4 * i + 3] << 8);
  if(data > thm_size) return 0;                 /* the parts don't fit */
  sram_memset(work_addr, THM_ROM_SIZE, 0);
  data = thm_addr + THM_HEADER + 4 * n;
  for(i = 0; i < n; i++, data += len) {
    slot = toc[4 * i];
    len = toc[4 * i + 2] | (toc[4 * i + 3] << 8);
    if(slot >= THM_PARTS || !thm_slots[slot].size || !len) continue;
    have |= 1 << slot;
    if(slot == THM_LOGO_PAL) {
      logo_pal = data;                          /* after the palette */
      logo_pal_len = len < 64 ? len : 64;
    } else if(slot == THM_LOGO && 2 * len == 64 * LOGO_TILES) {
      /* half width: the left half of each row, the right half empty */
      for(row = 0; row < 7; row++) {
        copy(work_addr + thm_slots[slot].offset + 2 * 16 * 64 * row, data + 16 * 64 * row, 16 * 64);
      }
    } else {
      copy(work_addr + thm_slots[slot].offset, data,
           len < thm_slots[slot].size ? len : thm_slots[slot].size);
    }
  }
  if(logo_pal) copy(work_addr + thm_slots[THM_LOGO_PAL].offset, logo_pal, logo_pal_len);
  w->rom = work_addr;
  w->o.palette = thm_slots[THM_PALETTE].offset;
  w->o.logo = thm_slots[THM_LOGO].offset;
  w->o.hdma_pal_src = thm_slots[THM_PAL_SRC].offset;
  w->o.hdma_math_src = thm_slots[THM_MATH].offset;
  w->o.hdma_bar_color_src = thm_slots[THM_BAR_COLOR].offset;
  if(have & (1 << THM_PALETTE)) {
    parts |= PART_COLORS;
    if(have & (1 << THM_LOGO)) parts |= PART_LOGO;
  }
  if(have & (1 << THM_PAL_SRC)) parts |= PART_GRADIENT;
  if((have & (1 << THM_MATH)) && (have & (1 << THM_BAR_COLOR))) parts |= PART_BAR;
  return convert(skin_addr, parts);
}

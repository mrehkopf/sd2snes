# Menu skin file format

A skin changes the look of the sd2snes menu: palette, font, logo, background gradient, selection
bar and background sprites. This document describes version 1 of the file format.

## Using a skin

- Skin files have the extension `.skin` and normally live in `/sd2snes/skins/` on the SD card.
- In the file browser, A or Y on a skin file offers "Preview" (shows the menu with the skin and
  asks "Apply skin?": "Use this skin" keeps it, "Revert" or B goes back) and "Use this skin".
- Configuration → Skin → "Choose a skin…" opens `/sd2snes/skins/` in the file browser; going
  back up from there returns to the directory from before. "Use the built-in skin" switches back
  to the original look.
- The choice is stored as `SkinName` in `/sd2snes/config.yml`: a file name in `/sd2snes/skins/`,
  or a full path starting with `/`. Empty (`SkinName: ""`, the default) means the built-in look.
- Old menu ROMs (`menu.bin` / `m3nu.bin` of v0.1.7d to v1.12.x, stock or themed) work as skins
  too: in `/sd2snes/skins/` and the folders in it, `.bin` files are listed like skin files, so a
  theme's folder can be copied there as it is. The firmware converts such a file (exactly 64 KB)
  into a skin when it loads it, the same way the theme tool's converter does
  (`www/themes/skinconv.js`, `src/skinconv.c`).
- A file that can't be used as a skin (a menu ROM of an unknown version, no skin file, a read
  error) gives a message when it is previewed or chosen, and the skin from before stays.
- The firmware loads the file every time it loads the menu. Other files of 64 KB or more are
  ignored, as is a file that cannot be read completely.
- Holding SELECT on either controller while the console is switched on starts the menu without
  the skin, in case a skin makes the menu unreadable.

## Structure

A skin is a sequence of chunks. Each chunk replaces one asset of the built-in look, so a skin only
needs the assets it changes. The built-in look is itself a skin (see "Default skin"), applied
before the skin file.

Chunk header (12 bytes, little endian):

| Offset | Size | Contents |
| --- | --- | --- |
| 0 | 3 | `SNS` |
| 3 | 1 | Version of this chunk's payload format, currently 1 |
| 4 | 4 | ID, 4 ASCII characters (see below) |
| 8 | 4 | Payload length *n* |
| 12 | *n* | Payload |

The next chunk follows directly after the payload; there is no padding and no file header.

The menu applies the chunks in file order:

- A chunk with an unknown ID or an unknown version is skipped.
- A chunk whose payload does not have the size its asset requires is skipped.
- The menu stops at the first header that does not start with `SNS`, and at a chunk that extends
  past the end of the file.
- An ID may occur more than once; later chunks override earlier ones. Palette chunks (`CGEN`) each
  change only their own range of colors.

| ID | Asset | Payload size |
| --- | --- | --- |
| `CGEN` | Palette (a range of colors) | 4 + 2 × number of colors |
| `FONT` | Font (a range of characters) | 4 + 64 × number of characters |
| `LOGO` | Logo | 14336 |
| `GRAD` | Background gradient (per line) | 896 |
| `CRSR` | Selection bar | 2 + 8 × height |
| `OAMT` | Background sprites | 228 + 4 × sprites + ⌈sprites / 4⌉ + 32 × tiles |

A skin with every asset at its maximum size is about 63.7 KB, within the 64 KB limit.

## Screen layout

The screen has 224 lines, numbered 0-223 from the top. Per-line data (`GRAD`, the sprite pages in
`OAMT`) has one entry per line: entry *n* applies to line *n*.

- **Lines 0-55: logo.** BG mode 3, 256 pixels wide: the logo is BG1 (8bpp).
- **Lines 56-223: text.** BG mode 5, 512 pixels wide (hi-res), 64 columns of 8 pixels. The even
  columns are on BG2 (2bpp), the odd columns on BG1 (4bpp). Text row *r* covers lines 8*r* − 15
  to 8*r* − 8; the file list starts at row 9 (lines 57-64), and the status bar is row 28 (lines
  209-216).
- **Sprites** can appear anywhere, behind or in front of the text (see `OAMT`). They are low-res
  (256 pixels across), like the logo.
- **Backdrop.** Wherever no layer has a pixel, the screen shows color 0, which the gradient
  normally sets per line.

## Palette (CGRAM)

All assets share the 256 colors of CGRAM; the color of a logo or sprite pixel is a CGRAM index.
This is how the menu uses CGRAM; a skin that replaces the logo or the sprites should keep their
colors out of the ranges the menu reads for text.

| Colors | Use |
| --- | --- |
| 0 | Backdrop, normally set per line by `GRAD` |
| 4*p* + 1 … 4*p* + 3, *p* = 0-7 | Text palette *p* on BG2 (colors 1-3 of the 2bpp palette) |
| 16*p* + 1 … 16*p* + 3, *p* = 0-7 | Text palette *p* on BG1; must equal the BG2 colors of the same palette, or text changes color from one column to the next |
| 36-47, 52-63, 65-79 | Reserved for button graphics in a later menu version (64, color 0 of BG1 palette 4, is transparent there and free) |
| 128-255 | Sprite palettes 0-7 (128 + 16*q* …), color 0 of each transparent |
| everything else | Free for the logo |

Text palettes used by the menu: 0 normal text, 1 directories and values, 2 SPC files and labels,
6 greyed-out windows (behind the active one). The text colors are 1 (fill), 2 (outline) and 3
(shade).

Because BG2 palette *p* (colors 4*p* … 4*p* + 3) overlaps BG1 palettes 0 and 1, the BG1 text
colors 16*p* + 1 … 16*p* + 3 for *p* = 0 and 1 lie inside the BG2 text palettes. As a result, text
palette 4 is always the same as text palette 1.

Only sprite palettes 4-7 (colors 192-255) take part in color math, so only sprites in those
palettes light up under the selection bar.

## Payloads

### `CGEN`: palette

| Offset | Size | Contents |
| --- | --- | --- |
| 0 | 2 | First color *f* (0-255) |
| 2 | 2 | Number of colors *c* (1-256, *f* + *c* ≤ 256) |
| 4 | 2*c* | Colors, BGR555 (bits 0-4 red, 5-9 green, 10-14 blue, bit 15 zero) |

### `FONT`: font

| Offset | Size | Contents |
| --- | --- | --- |
| 0 | 2 | First character *f* (0-255) |
| 2 | 2 | Number of characters *n* (1-256, *f* + *n* ≤ 256) |
| 4 | 64*n* | Characters |

A character is 16x8 pixels: two 8x8 4bpp tiles in the SNES format (32 bytes each: rows of
bitplanes 0+1, then rows of bitplanes 2+3), the left half, then the right half.

- Text characters are 8 pixels wide: the left half of the cell, in colors 0-3 (1 fill, 2 outline,
  3 shade). The even columns are on BG2 (2bpp), which shows only bitplanes 0+1 of the left half;
  the right half stays empty.
- Characters 0-15 are the controller buttons (see "Buttons" below); they use colors 4-15 and the
  right half, which only BG1 shows.
- The character set is CP1252, as the firmware converts file names to it. The menu's own texts
  also use the characters $81 and $8D, which are undefined in CP1252 and so never occur in file
  names: together they are its ellipsis ("…" in the menu sources), so it can look different from
  the 8 pixel CP1252 ellipsis (133). The bullet in menu entries is 149 (•).
- $8F and $9D, the other characters undefined in CP1252, are reserved for further menu glyphs.
  $90 never shows: it introduces a button in the menu's strings.
- Characters 0 and 1 end a string and are never printed as text.
- Character 32 (space) must be blank: the menu fills empty cells with it, and BG2 shows its left
  half next to the logo.

Like `CGEN`, a skin may contain several `FONT` chunks, each replacing its range of characters.

### Buttons

The menu shows controller buttons in its help texts with characters 0-15, 16x8 pixels each, always
on BG1 (an odd column; on an even one it prints two letters instead). Each button uses colors 1-15
of its BG1 palette (color 0 is transparent):

| Character | Button | Palette (CGRAM) |
| --- | --- | --- |
| 0, 2 | A, X (Japan/Europe: red, blue) | 2 (colors 4-15: 36-47) |
| 1, 3 | B, Y (Japan/Europe: yellow, green) | 4 (colors 1-15: 65-79) |
| 4-7 | A, B, X, Y (USA) | 3 (colors 4-15: 52-63) |
| 8-11 | L, R, START, SELECT | 3 |
| 12-15 | up, down, left, right | 3 |

Palettes 2 and 3 keep text colors 1-3, so their buttons use colors 4-15 only. The "Buttons" setting
in the menu (Configuration → Skin; `ButtonStyle` in config.yml) chooses between characters 0-3 and
4-7 for A, B, X and Y. The default skin has the buttons in their own `FONT` chunk (characters
0-15) and `CGEN` chunks, so a skin can replace the text font without them.

### `LOGO`: logo

224 tiles of 8x8 pixels, 8bpp in the SNES format (64 bytes each: rows of bitplanes 0+1, 2+3, 4+5,
6+7), in rows of 32 tiles: 256x56 pixels, shown on lines 0-55. A pixel value is a CGRAM index; 0 is
transparent (backdrop).

### `GRAD`: background gradient

224 records of 4 bytes, one per line: CGRAM address (twice, the second one counts), then a BGR555
color. On each line, before the line is drawn, the color is written to CGRAM at that address. The
address is normally 0 (the backdrop), but any color can be changed per line. For example, two
gradients at half the vertical resolution can alternate between even and odd lines. A color keeps
its value until it is written again, also into the next frame.

### `CRSR`: selection bar

The selection bar is drawn with color math: on each of its lines, a color (COLDATA) is added to,
subtracted from or averaged with the screen, inside a window around the selected item that the
menu sets.

| Offset | Size | Contents |
| --- | --- | --- |
| 0 | 1 | Height *h* in lines (1-16) |
| 1 | 1 | First line of the bar relative to the top line of the selected text row (signed) |
| 2 | 4*h* | Normal bar, one record per line |
| 2 + 4*h* | 4*h* | Active bar (while a value is edited), one record per line |

A record is the value for CGADSUB (`$2131`) followed by three values for COLDATA (`$2132`):

- **CGADSUB:** bit 7 subtract instead of add, bit 6 halve the result, bit 5 backdrop, bit 4
  sprites (palettes 4-7 only), bit 1 BG2, bit 0 BG1. Use bits 0 and 1 together: text uses both
  layers.
- **COLDATA:** bits 0-4 intensity, bit 5 red, bit 6 green, bit 7 blue. To set a color, write red,
  green and blue separately: `$20 | r`, `$40 | g`, `$80 | b`.

Above and below the bar, color math is off.

The default bar is 9 lines high, starting at the top line of the row:

- normal: line 0 adds (10, 15, 31), lines 1-7 add (10, 0, 31), line 8 averages with (10, 0, 31);
- active: the same with (22, 15, 10) and (22, 0, 10).

### `OAMT`: background sprites

Mode 5 has no free BG layer, so a background picture behind the text is made of sprites.

| Offset | Size | Contents |
| --- | --- | --- |
| 0 | 2 | Number of tiles *t* (0-960) |
| 2 | 1 | Number of sprites *s* (0-96) |
| 3 | 1 | 0 |
| 4 | 224 | Sprite page per line (0-2) |
| 228 | 4*s* | OAM entries: X (low 8 bits), Y, tile (low 8 bits), attributes |
| 228 + 4*s* | ⌈*s* / 4⌉ | OAM high table bits, 2 per sprite: bit 0 X bit 8, bit 1 size |
| 228 + 4*s* + ⌈*s* / 4⌉ | 32*t* | Tiles (8x8, 4bpp, SNES format) |

Sprites:

- **Size:** 16x16 (size bit 0) or 32x32 (size bit 1).
- **Position:** Y is the first line of the sprite in the numbering above (the hardware counts
  lines from 0 with an invisible first line, so OAM Y is the line before the sprite there).
- **Unused sprites:** sprites *s*-127 stay below the screen.
- **Tiles:** 16x16 sprites use tiles *n*, *n* + 1, *n* + 16, *n* + 17; 32x32 sprites use the
  4x4 block from *n* on, in rows of 16 tiles.
- **Attributes:** bit 0 is tile bit 8, bits 1-3 the sprite palette (use 4-7, see "Palette"),
  bits 4-5 the priority, bit 6 horizontal flip, bit 7 vertical flip.
- **Priority:**
  - 0 behind the text and behind the logo;
  - 1 behind the text, in front of the logo;
  - 2 in front of BG2 but behind BG1, which means every other text column (avoid);
  - 3 in front of the text.

Tiles: the tile data starts at sprite tile 64 (tiles 0-63 are not available). Data tile *k* is:

| *k* | Sprite tile |
| --- | --- |
| 0-191 | 64 + *k* |
| 192-447 | 256 + (*k* − 192), page 0 |
| 448-703 | 256 + (*k* − 448), page 1 |
| 704-959 | 256 + (*k* − 704), page 2 |

The page of a line selects which page sprites on that line take tiles 256-511 from. One picture
can therefore use more than 512 different tiles, e.g. page 0 for the upper part of the screen and
page 1 for the lower part. The page can change on any line, also in the middle of a sprite: the
menu switches it with a timer interrupt during the line before, while the PPU fetches no sprite
tiles. Each change costs a little CPU time, so keep them to the lines where the picture needs them.

Limits of the SNES: at most 32 sprites and 34 sprite tiles (8 pixels wide each) on one line.
32x32 sprites across the whole width are 8 sprites and 32 tiles per line.

## Default skin

The built-in look is a skin in this format, embedded in the menu ROM (`menu.bin`/`m3nu.bin`) at
file offset `$10000` and followed by 12 zero bytes. Tools can read it as a starting point for new
skins. It contains `CGEN` (all 256 colors), `FONT`, `LOGO`, `GRAD`, `CRSR` and `OAMT` (the paint
drips below the logo: 11 16x16 sprites in palettes 4-7, page 0 on every line).

The sources are in `snes/skin/`: `default.asm` with the chunks, and the binary graphics `font.chr`,
`logo.chr` and `logospr.chr` in the payload formats above. The menu code that applies skins is in
`snes/skin.asm`.

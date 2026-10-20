/*
 * skinconv.js: convert the assets of an old sd2snes menu ROM (menu.bin /
 * m3nu.bin, v0.1.7d - v1.12.x, stock or themed) into a menu skin file
 * (see snes/skin-format.md in the sd2snes sources).
 *
 *   SkinConv.convert(rom, offsets[, notes]) -> Uint8Array (the .skin file)
 *
 * rom:     the menu ROM (Uint8Array, file offset = SNES address & $FFFF)
 * offsets: the asset offsets of that ROM, as selectVersion() in index.html
 *          returns them (font, logo, logospr, hdma_math_src,
 *          hdma_bar_color_src, hdma_pal_src, oam_data_l, oam_data_h,
 *          palette)
 * notes:   optional array; the conversion appends a message for every
 *          chunk it leaves out or adjusts
 *
 * Works in the browser (global SkinConv) and in node (module.exports).
 */
(function (global) {
  'use strict';

  // How the old menu used its assets (setup_gfx, setup_hdma, set_bar_color
  // and the NMI handler; unchanged from v0.1.7d to v1.12.x):
  var OAM_ENTRIES = 24;         // oam_data_l: $60 bytes copied to OAM
  var OAM_HIGH_BYTES = 9;       // oam_data_h: 9 bytes copied to OAM $100
  var LOGOSPR_TILES = 40;       // logospr: $500 bytes copied to VRAM
  var HDMA_PAL_WRAM = 55 + 227; // WRAM copies of hdma_pal_src (55 bytes)
                                // and hdma_cg_addr_src (227 bytes), which
                                // follow each other in ROM and in WRAM
  var HDMA_MATH_WRAM = 19;      // WRAM copy of hdma_math_src
  var MAX_BAR_HEIGHT = 16;
  var LINES = 224;

  // the sprite table of every old menu version (used when the offsets
  // give no oam_data_l / oam_data_h)
  var STOCK_OAM_L = [
    88, 56, 0, 8,    96, 56, 1, 8,    104, 56, 2, 8,   112, 56, 3, 8,
    120, 56, 4, 8,   128, 56, 5, 8,   136, 56, 6, 8,   88, 64, 7, 8,
    96, 64, 8, 8,    104, 64, 9, 8,   112, 64, 10, 8,  88, 72, 14, 8,
    96, 72, 15, 8,   157, 56, 21, 10, 172, 56, 22, 12, 180, 56, 23, 12,
    172, 64, 24, 12, 172, 72, 26, 12, 172, 80, 28, 12, 172, 88, 30, 12,
    172, 96, 32, 12, 194, 56, 34, 14, 194, 64, 35, 14, 194, 72, 36, 14
  ];
  var STOCK_OAM_H = [0, 0, 0, 0, 0, 0, 0, 0, 0];

  // Characters the menus with skin support use but old fonts leave empty:
  // the bullet point (added in v1.8.0) and the separator tees, which join
  // a horizontal line (character 25) to the left (26) and right (27)
  // window border. The tees are made from the font's own border characters;
  // these are the standard ones for fonts without usable border characters.
  var BULLET_CHAR = 129;
  var BULLET = [0x00, 0x00, 0x00, 0x60, 0x60, 0x90, 0x60, 0x90,
                0x00, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
  var LINE_CHAR = 25, LEFT_CHAR = 26, RIGHT_CHAR = 27;
  var LEFT_TEE_CHAR = 30, RIGHT_TEE_CHAR = 31;
  var LEFT_TEE = [0x1c, 0x22, 0x1c, 0x22, 0x1c, 0x23, 0x1f, 0x20,
                  0x1f, 0x20, 0x1c, 0x23, 0x1c, 0x22, 0x1c, 0x22];
  var RIGHT_TEE = [0x38, 0x44, 0x38, 0x44, 0x38, 0xc4, 0xf8, 0x04,
                   0xf8, 0x04, 0x38, 0xc4, 0x38, 0x44, 0x38, 0x44];

  // CGRAM: colors reserved for button graphics (skin-format.md), which a
  // skin must not write, and the free colors that logo colors from there
  // move to. First these, in this order (the default skin of the new menu
  // uses them): color 0 of the BG2 text palettes 1-7 and of the BG1 text
  // palettes 2-7, sprite palettes 2-3, color 0 of sprite palettes 4-7;
  // then any other color that neither text, the logo nor the sprites use.
  // Color 64 is color 0 of BG1 palette 4, so a skin may set it.
  function reserved(c) {
    return (c >= 36 && c <= 47) || (c >= 52 && c <= 63) || (c >= 65 && c <= 79);
  }
  function writable(c) {
    return !reserved(c);
  }
  // colors 1-3 of the text palettes (BG2: 4p + 1..3, BG1: 16p + 1..3)
  function textColor(c) {
    return c < 32 ? (c & 3) !== 0 : c < 128 && (c & 15) >= 1 && (c & 15) <= 3;
  }
  var LOGO_TARGETS = [4, 8, 12, 16, 20, 24, 28, 32, 48, 64, 80, 96, 112];
  for (var c = 169; c <= 191; c++) {
    LOGO_TARGETS.push(c);
  }
  LOGO_TARGETS.push(192, 208, 224, 240);

  function bytes(rom, offset, length, what) {
    if (typeof offset !== 'number' || offset < 0 || offset + length > rom.length) {
      throw new Error('offset of ' + what + ' (' + offset + ') is outside the ROM');
    }
    return rom.subarray(offset, offset + length);
  }

  function chunk(id, payload) {
    var out = new Uint8Array(12 + payload.length);
    var n = payload.length;
    out.set([0x53, 0x4e, 0x53, 1], 0);        // "SNS", version 1
    for (var i = 0; i < 4; i++) {
      out[4 + i] = id.charCodeAt(i);
    }
    out.set([n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff, (n >>> 24) & 0xff], 8);
    out.set(payload, 12);
    return out;
  }

  // Expand an HDMA table into one entry per line: the bytes written on that
  // line (unit bytes), or null if the channel writes nothing on that line.
  // Stops at the end mark (line count 0), after maxLines lines, or at the
  // end of buf.
  function hdmaLines(buf, unit, maxLines) {
    var out = [];
    var p = 0;
    while (out.length < maxLines && p < buf.length) {
      var count = buf[p++];
      if (count === 0) {
        break;
      }
      var repeat = (count & 0x80) !== 0;
      var n = (count & 0x7f) || 128;
      for (var k = 0; k < n && out.length < maxLines; k++) {
        if (k === 0 || repeat) {
          if (p + unit > buf.length) {
            return out;
          }
          out.push(buf.subarray(p, p + unit));
          p += unit;
        } else {
          out.push(null);
        }
      }
    }
    return out;
  }

  // 2bpp 8x8 glyph (16 bytes) <-> 8 rows of 8 pixel values
  function glyphPixels(g) {
    var rows = [];
    for (var y = 0; y < 8; y++) {
      var row = [];
      for (var x = 0; x < 8; x++) {
        row.push(((g[2 * y] >> (7 - x)) & 1) | (((g[2 * y + 1] >> (7 - x)) & 1) << 1));
      }
      rows.push(row);
    }
    return rows;
  }
  function glyphBytes(rows) {
    var g = new Uint8Array(16);
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        g[2 * y] |= (rows[y][x] & 1) << (7 - x);
        g[2 * y + 1] |= (rows[y][x] >> 1) << (7 - x);
      }
    }
    return g;
  }

  // Separator tee: the border character, and the line character on the
  // side of the window inside (columns right of the border's rightmost
  // pixel for the left border, left of its leftmost pixel for the right one)
  function tee(border, line, left) {
    var edge = left ? -1 : 8;
    border.forEach(function (row) {
      row.forEach(function (v, x) {
        if (v) {
          edge = left ? Math.max(edge, x) : Math.min(edge, x);
        }
      });
    });
    var lineUsed = line.some(function (row) { return row.some(function (v) { return v; }); });
    if (edge === -1 || edge === 8 || !lineUsed) {
      return null;
    }
    return glyphBytes(border.map(function (row, y) {
      return row.map(function (v, x) {
        var inside = left ? x >= edge : x <= edge;
        return inside && line[y][x] ? line[y][x] : v;
      });
    }));
  }

  // FONT: 256 characters, 2bpp 8x8 (16 bytes) -> 4bpp 16x8 (64 bytes)
  function convertFont(rom, o, notes) {
    var font = bytes(rom, o.font, 256 * 16, 'font');
    var payload = new Uint8Array(256 * 64);
    function glyph(c) {
      return font.subarray(16 * c, 16 * c + 16);
    }
    for (var c = 0; c < 256; c++) {
      payload.set(glyph(c), 64 * c);
    }
    if (glyph(BULLET_CHAR).every(function (b) { return b === 0; })) {
      payload.set(BULLET, 64 * BULLET_CHAR);
      notes.push('Font: added the standard bullet point (character ' + BULLET_CHAR +
                 '), which this menu version does not have.');
    }
    // characters 30 and 31 were unused before
    var line = glyphPixels(glyph(LINE_CHAR));
    var left = tee(glyphPixels(glyph(LEFT_CHAR)), line, true);
    var right = tee(glyphPixels(glyph(RIGHT_CHAR)), line, false);
    if (!left || !right) {
      notes.push('Font: the window border characters (' + LINE_CHAR + '-' + RIGHT_CHAR +
                 ') are empty, added the standard window separators.');
    }
    payload.set(left && right ? left : LEFT_TEE, 64 * LEFT_TEE_CHAR);
    payload.set(left && right ? right : RIGHT_TEE, 64 * RIGHT_TEE_CHAR);
    return chunk('FONT', payload);
  }

  // GRAD: hdma_pal_src wrote color 0 (HDMA channel 1 set the CGRAM address
  // to 0 on every line) -> one record per line
  function convertGradient(rom, o) {
    var palette = bytes(rom, o.palette, 2, 'palette');
    var lines = hdmaLines(bytes(rom, o.hdma_pal_src, HDMA_PAL_WRAM, 'hdma_pal_src'),
                          2, LINES);
    var payload = new Uint8Array(4 * LINES);
    var lo = palette[0];
    var hi = palette[1];
    for (var y = 0; y < LINES; y++) {
      if (lines[y]) {
        lo = lines[y][0];
        hi = lines[y][1];
      }
      payload.set([0, 0, lo, hi], 4 * y);
    }
    return chunk('GRAD', payload);
  }

  // Selection bar of one variant of hdma_bar_color_src: the per-line records
  // [CGADSUB, $20|r, $40|g, $80|b], or null if the table cannot be
  // expressed as a bar.
  function barRecords(rom, o, variant) {
    var t = Uint8Array.from(bytes(rom, o.hdma_math_src, HDMA_MATH_WRAM, 'hdma_math_src'));
    var colors = bytes(rom, o.hdma_bar_color_src + 4 * variant, 4, 'hdma_bar_color_src');
    for (var k = 0; k < 4; k++) {
      t[2 + 3 * k] = colors[k];               // what set_bar_color patches
    }
    var rgb = [0, 0, 0];
    function coldata(v) {
      for (var c = 0; c < 3; c++) {
        if (v & (0x20 << c)) {
          rgb[c] = v & 0x1f;
        }
      }
    }
    // Entries 0 and 1 cover the lines above the bar (the NMI sets their line
    // counts); the bar starts with entry 2. COLDATA keeps its value from the
    // end of the previous frame, so run the whole table once first.
    var lines = hdmaLines(t.subarray(6), 2, 256);
    var pass, y, cgadsub, records;
    for (pass = 0; pass < 2; pass++) {
      coldata(t[2]);
      coldata(t[5]);
      records = [];
      cgadsub = -1;
      for (y = 0; y < lines.length; y++) {
        if (lines[y]) {
          if (pass === 1 && lines[y][0] === 0) {
            break;                            // color math off: end of bar
          }
          cgadsub = lines[y][0];
          coldata(lines[y][1]);
        }
        records.push([cgadsub, 0x20 | rgb[0], 0x40 | rgb[1], 0x80 | rgb[2]]);
      }
    }
    if (y === lines.length || records.length === 0 || records.length > MAX_BAR_HEIGHT) {
      return null;  // never switches color math off, or no / too many lines
    }
    return records;
  }

  // CRSR: selection bar, normal and active (editing) variant
  function convertBar(rom, o, notes) {
    var normal = barRecords(rom, o, 0);
    var active = barRecords(rom, o, 1);
    if (!normal || !active || normal.length !== active.length) {
      notes.push('Selection bar: left out (hdma_math_src does not describe a bar of 1-' +
                 MAX_BAR_HEIGHT + ' lines), the menu uses its default bar.');
      return null;
    }
    var h = normal.length;
    var payload = new Uint8Array(2 + 8 * h);
    payload[0] = h;
    payload[1] = 0;                           // starts at the top line of the row
    for (var y = 0; y < h; y++) {
      payload.set(normal[y], 2 + 4 * y);
      payload.set(active[y], 2 + 4 * h + 4 * y);
    }
    return chunk('CRSR', payload);
  }

  function onScreen(x, y) {
    var sx = x >= 256 ? x - 512 : x;          // X is 9 bits
    if (sx <= -8 || sx >= 256) {
      return false;
    }
    for (var k = 0; k < 8; k++) {
      if (((y + k) & 0xff) < LINES) {
        return true;
      }
    }
    return false;
  }

  // OAMT: the old 8x8 / 16x16 sprites, regrouped into 16x16 sprites (like
  // menutest/skin/spr16.py, which made the default skin's sprites).
  // Returns the chunk and the CGRAM colors the sprites show.
  function convertSprites(rom, o, notes) {
    var oamL = o.oam_data_l ? bytes(rom, o.oam_data_l, 4 * OAM_ENTRIES, 'oam_data_l')
                            : STOCK_OAM_L;
    var oamH = o.oam_data_h ? bytes(rom, o.oam_data_h, OAM_HIGH_BYTES, 'oam_data_h')
                            : STOCK_OAM_H;
    if (!o.oam_data_l || !o.oam_data_h) {
      notes.push('Sprites: no sprite table offsets, used the standard sprite positions.');
    }

    // 1. split into 8x8 pieces in OAM order
    var pieces = [];
    var hidden = 0;
    for (var i = 0; i < OAM_ENTRIES; i++) {
      var high = oamH[i >> 2] >> (2 * (i & 3));
      var x = oamL[4 * i] | ((high & 1) << 8);
      var y = oamL[4 * i + 1];
      var a = oamL[4 * i + 3];
      var t = oamL[4 * i + 2] | ((a & 1) << 8);
      var n = (high & 2) ? 2 : 1;
      for (var cy = 0; cy < n; cy++) {
        for (var cx = 0; cx < n; cx++) {
          // tile numbers wrap within a row of 16 and within 16 rows
          var pt = (t & 0x100) | ((t + 16 * cy) & 0xf0) | ((t + cx) & 0x0f);
          var px = (x + 8 * ((a & 0x40) ? n - 1 - cx : cx)) & 0x1ff;
          var py = (y + 8 * ((a & 0x80) ? n - 1 - cy : cy)) & 0xff;
          if (onScreen(px, py)) {
            pieces.push({ x: px, y: py, t: pt, a: a & 0xfe });
          } else {
            hidden++;
          }
        }
      }
    }
    if (hidden) {
      notes.push('Sprites: left out ' + hidden + ' off-screen 8x8 sprite(s).');
    }

    // 2. regroup into 16x16 sprites
    var used = [];
    var groups = [];
    pieces.forEach(function (p, i) {
      if (used[i]) {
        return;
      }
      used[i] = true;
      var quad = [null, null, null, null];
      if (p.a & 0xc0) {
        // flipped: alone, in the quadrant that ends up at the sprite position
        quad[((p.a & 0x40) ? 1 : 0) + ((p.a & 0x80) ? 2 : 0)] = p.t;
      } else {
        quad[0] = p.t;
        pieces.forEach(function (p2, j) {
          if (used[j] || p2.a !== p.a) {
            return;
          }
          [[8, 0], [0, 8], [8, 8]].forEach(function (d, q) {
            if (p2.x === ((p.x + d[0]) & 0x1ff) && p2.y === ((p.y + d[1]) & 0xff) &&
                quad[q + 1] === null) {
              quad[q + 1] = p2.t;
              used[j] = true;
            }
          });
        });
      }
      groups.push({ x: p.x, y: p.y, a: p.a, quad: quad });
    });

    // 3. sprite i uses the 2x2 tile block at row 2*(i div 8), column
    // 2*(i mod 8) of the tile data, which starts at sprite tile 64
    var s = groups.length;
    var tiles = Math.ceil(s / 8) * 2 * 16;
    var hiBytes = Math.ceil(s / 4);
    var payload = new Uint8Array(228 + 4 * s + hiBytes + 32 * tiles);
    var oam = 228;
    var hi = oam + 4 * s;
    var data = hi + hiBytes;
    var colors = [];                          // CGRAM colors the sprites show
    payload.set([tiles & 0xff, tiles >> 8, s, 0], 0);  // 224 x sprite page 0 follow
    groups.forEach(function (g, i) {
      var n = 64 + 32 * (i >> 3) + 2 * (i & 7);
      payload.set([g.x & 0xff, g.y, n & 0xff, g.a | (n >> 8)], oam + 4 * i);
      payload[hi + (i >> 2)] |= (g.x >> 8) << (2 * (i & 3));      // size bit 0: 16x16
      g.quad.forEach(function (t, q) {
        if (t === null || t >= LOGOSPR_TILES) {
          return;                             // never loaded by the old menu: empty
        }
        var k = n - 64 + (q & 1) + 16 * (q >> 1);
        var tile = bytes(rom, o.logospr + 32 * t, 32, 'logospr');
        payload.set(tile, data + 32 * k);
        for (var y = 0; y < 8; y++) {
          for (var x = 0; x < 8; x++) {
            var v = 0;
            for (var p = 0; p < 4; p++) {
              v |= ((tile[16 * (p >> 1) + 2 * y + (p & 1)] >> (7 - x)) & 1) << p;
            }
            if (v) {
              colors[128 + 16 * ((g.a >> 1) & 7) + v] = true;
            }
          }
        }
      });
    });
    return { chunk: chunk('OAMT', payload), colors: colors };
  }

  // LOGO (256x56 pixels, 8bpp) and CGEN: move the logo colors out of the
  // reserved range, then write all colors except the reserved range
  function convertLogoPalette(rom, o, spriteColors, notes) {
    var logo = Uint8Array.from(bytes(rom, o.logo, 14336, 'logo'));
    var palette = Uint8Array.from(bytes(rom, o.palette, 512, 'palette'));
    var pixels = new Uint8Array(224 * 64);
    var used = [];
    var tile, y, x, p, v;
    for (tile = 0; tile < 224; tile++) {
      for (y = 0; y < 8; y++) {
        for (x = 0; x < 8; x++) {
          v = 0;
          for (p = 0; p < 8; p++) {
            v |= ((logo[64 * tile + 16 * (p >> 1) + 2 * y + (p & 1)] >> (7 - x)) & 1) << p;
          }
          pixels[64 * tile + 8 * y + x] = v;
          used[v] = true;
        }
      }
    }
    var sources = [];
    for (v = 0; v < 256; v++) {
      if (used[v] && reserved(v)) {
        sources.push(v);
      }
    }
    var free = function (c) {
      return !used[c] && !spriteColors[c];
    };
    var targets = LOGO_TARGETS.filter(free);
    for (v = 1; v < 256; v++) {
      if (free(v) && !textColor(v) && !reserved(v) && LOGO_TARGETS.indexOf(v) < 0) {
        targets.push(v);
      }
    }
    // Too few targets: merge colors into the most similar other logo color,
    // the closest pair first, until the remaining ones fit
    var into = [];
    var moving = sources.slice();
    var worst = 0;
    if (sources.length > targets.length) {
      var kept = [];
      for (v = 1; v < 256; v++) {
        if (used[v] && !reserved(v)) {
          kept.push(v);
        }
      }
      var rgb = function (c) {
        var w = palette[2 * c] | (palette[2 * c + 1] << 8);
        return [w & 31, (w >> 5) & 31, (w >> 10) & 31];
      };
      var dist = function (c, d) {
        var a = rgb(c);
        var b = rgb(d);
        return Math.sqrt((a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1]) +
                         (a[2] - b[2]) * (a[2] - b[2]));
      };
      while (moving.length > targets.length) {
        var best = moving[moving.length - 1];
        var bestInto = 0;
        var bestDist = Infinity;
        moving.forEach(function (c) {
          kept.concat(moving).forEach(function (k) {
            var d = k === c ? Infinity : dist(c, k);
            if (d < bestDist) {
              best = c;
              bestInto = k;
              bestDist = d;
            }
          });
        });
        into[best] = bestInto;
        worst = Math.max(worst, bestDist === Infinity ? 0 : bestDist);
        moving.splice(moving.indexOf(best), 1);
      }
      notes.push('Logo: ' + sources.length + ' of its colors are in palette entries that ' +
                 'newer menus reserve (36-47, 52-63, 65-79), and only ' + targets.length +
                 ' free entries are left, so ' + (sources.length - targets.length) +
                 ' colors were merged into similar logo colors (largest difference ' +
                 worst.toFixed(1) + ' of 31 steps).');
    }
    var map = [];
    for (v = 0; v < 256; v++) {
      map[v] = v;
    }
    moving.forEach(function (c, i) {
      map[c] = targets[i];
      palette[2 * targets[i]] = palette[2 * c];
      palette[2 * targets[i] + 1] = palette[2 * c + 1];
    });
    sources.forEach(function (c) {
      var d = c;
      while (into[d] !== undefined) {
        d = into[d];
      }
      map[c] = map[d];
    });
    if (sources.length) {
      logo.fill(0);
      for (tile = 0; tile < 224; tile++) {
        for (y = 0; y < 8; y++) {
          for (x = 0; x < 8; x++) {
            v = map[pixels[64 * tile + 8 * y + x]];
            for (p = 0; p < 8; p++) {
              logo[64 * tile + 16 * (p >> 1) + 2 * y + (p & 1)] |= ((v >> p) & 1) << (7 - x);
            }
          }
        }
      }
    }

    // one CGEN chunk per run of writable colors
    var cgen = [];
    for (var first = 0; first < 256; ) {
      if (!writable(first)) {
        first++;
        continue;
      }
      var count = 1;
      while (first + count < 256 && writable(first + count)) {
        count++;
      }
      var payload = new Uint8Array(4 + 2 * count);
      payload.set([first & 0xff, first >> 8, count & 0xff, count >> 8], 0);
      payload.set(palette.subarray(2 * first, 2 * (first + count)), 4);
      cgen.push(chunk('CGEN', payload));
      first += count;
    }
    return { cgen: cgen, logo: chunk('LOGO', logo) };
  }

  function convert(rom, offsets, notes) {
    notes = notes || [];
    if (!(rom instanceof Uint8Array)) {
      rom = new Uint8Array(rom);
    }
    if (!offsets) {
      throw new Error('unknown menu version');
    }
    var font = convertFont(rom, offsets, notes);
    var grad = convertGradient(rom, offsets);
    var bar = convertBar(rom, offsets, notes);
    var sprites = convertSprites(rom, offsets, notes);
    var lp = convertLogoPalette(rom, offsets, sprites.colors, notes);
    var chunks = lp.cgen.concat([font, lp.logo, grad, bar, sprites.chunk])
      .filter(function (c) { return c; });
    var size = chunks.reduce(function (sum, c) { return sum + c.length; }, 0);
    var skin = new Uint8Array(size);
    var p = 0;
    chunks.forEach(function (c) {
      skin.set(c, p);
      p += c.length;
    });
    return skin;
  }

  // The chunks of a skin file: [{id, version, offset, length}], offset and
  // length of the payload
  function listChunks(skin) {
    var out = [];
    var p = 0;
    while (p + 12 <= skin.length && skin[p] === 0x53 && skin[p + 1] === 0x4e &&
           skin[p + 2] === 0x53) {
      var length = (skin[p + 8] | (skin[p + 9] << 8) | (skin[p + 10] << 16) |
                    (skin[p + 11] << 24)) >>> 0;
      if (p + 12 + length > skin.length) {
        break;
      }
      out.push({
        id: String.fromCharCode(skin[p + 4], skin[p + 5], skin[p + 6], skin[p + 7]),
        version: skin[p + 3], offset: p + 12, length: length
      });
      p += 12 + length;
    }
    return out;
  }

  // true for a menu that has skin support itself (its built-in skin at $10000)
  function hasSkinSupport(rom) {
    return rom.length >= 0x1000c && rom[0x10000] === 0x53 && rom[0x10001] === 0x4e &&
           rom[0x10002] === 0x53;
  }

  var api = {
    convert: convert,
    listChunks: listChunks,
    hasSkinSupport: hasSkinSupport
  };
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  } else {
    global.SkinConv = api;
  }
})(this);

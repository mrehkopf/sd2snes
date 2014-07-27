#include <stdio.h>
#include <stdint.h>
/* reorder entries in a palette file */
/* map action types:
   MA_NONE: do not map anything to this entry (constant 0000)
   MA_LOC:  map indexed entry of local palette to this entry
   MA_SRC:  map indexed entry of input palette to this entry
*/
enum map_action_type { MA_NONE = 0, MA_LOC, MA_SRC };

int map_action [256] = {
/* 0-3:   local entries (2-bit text palette 0 + 4-bit text palette 0)
   4-7:   local entries (2-bit text palette 1)
   8-11:  local entries (2-bit text palette 2)
   12-15: local entries (2-bit text palette 3)
   16-19: local entries (4-bit text palette 1 - 2-bit palette 4 not used)
   20-23: local entries (2-bit text palette 5)
   24-27: local entries (2-bit text palette 6)
   28-31: local entries (2-bit text palette 7) */
	MA_NONE, MA_LOC, MA_LOC, MA_LOC, MA_LOC, MA_LOC, MA_LOC, MA_LOC,
	MA_LOC, MA_LOC, MA_LOC, MA_LOC,	MA_LOC, MA_LOC, MA_LOC, MA_LOC,
	MA_LOC, MA_LOC, MA_LOC, MA_LOC,	MA_LOC, MA_LOC, MA_LOC, MA_LOC,
	MA_LOC, MA_LOC, MA_LOC, MA_LOC,	MA_LOC, MA_LOC, MA_LOC, MA_LOC,
/* 32-35: local entries (4-bit text palette 2)
   36-47: logo gfx */
	MA_LOC, MA_LOC, MA_LOC, MA_LOC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
/* 48-51: local entries (4-bit text palette 3)
   52-63: logo */
	MA_LOC, MA_LOC, MA_LOC, MA_LOC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
/* 48-51: local entries (4-bit text palette 4 - 4-bit only spare palette)
   52-63: logo */
	MA_LOC, MA_LOC, MA_LOC, MA_LOC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
/* 48-51: local entries (4-bit text palette 5)
   52-63: logo */
	MA_LOC, MA_LOC, MA_LOC, MA_LOC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
/* 48-51: local entries (4-bit text palette 6)
   52-63: logo */
	MA_LOC, MA_LOC, MA_LOC, MA_LOC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
/* 48-51: local entries (4-bit text palette 7)
   52-175: logo */
	MA_LOC, MA_LOC, MA_LOC, MA_LOC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
/* 176-191: sprites (reserved) */
	MA_NONE, MA_NONE, MA_NONE, MA_NONE, MA_NONE, MA_NONE, MA_NONE, MA_NONE,
	MA_NONE, MA_NONE, MA_NONE, MA_NONE, MA_NONE, MA_NONE, MA_NONE, MA_NONE,
/* 192-255: sprites (logo gfx overlays) */
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC,
	MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC, MA_SRC
};

/* Mapping table. This table specifies the source index in either the
   source palette file or the local palette, depending on the action
   specified in the table above. */
int map_idx [256] = {
	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
	0x04, 0x05, 0x06, 0x07, 0x14, 0x15, 0x16, 0x17,
	0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
	0x08, 0x09, 0x0a, 0x0b, 0x00, 0x01, 0x02, 0x03,
        0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b,
        0x0c, 0x0d, 0x0e, 0x0f, 0x0c, 0x0d, 0x0e, 0x0f,
	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
	0x10, 0x11, 0x12, 0x13, 0x18, 0x19, 0x1a, 0x1b,
	0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23,
	0x14, 0x15, 0x16, 0x17, 0x24, 0x25, 0x26, 0x27,
	0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
	0x18, 0x19, 0x1a, 0x1b, 0x30, 0x31, 0x32, 0x33,
	0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b,
	0x1c, 0x1d, 0x1e, 0x1f, 0x3c, 0x3d, 0x3e, 0x3f,
	0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
	0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
	0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
	0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
	0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
	0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
	0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7,
	0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf,
	0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7,
	0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf,
	0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7,
	0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef,
	0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7,
	0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
};

/* local palette. Basically a list of 2-bit palettes that is mirrored
   to the 4-bit palette locations by the map above. */
uint16_t local_palette [32] = {
	0x0000, 0x7fff, 0x18c6, 0x6318, 0x0000, 0x43ff, 0x0cc6, 0x3318,
	0x0000, 0x43f0, 0x0cc3, 0x330c, 0x0000, 0x7fb1, 0x24a1, 0x62ec,
	0x0000, 0x43ff, 0x0cc6, 0x3318, 0x0000, 0x45bf, 0x1466, 0x3958,
	0x0000, 0x5294, 0x18c6, 0x39ce, 0x0000, 0x32ff, 0x10a7, 0x2a38
};

int main(int argc, char **argv) {
	if(argc<3) {
		fprintf(stderr, "Usage: %s <infile> <outfile>\n", argv[0]);
		return 1;
	}
	FILE *in, *out;
	if((in=fopen(argv[1], "rb"))==NULL) {
		perror("Could not open input file");
		return 1;
	}
	if((out=fopen(argv[2], "wb"))==NULL) {
		perror("Could not open output file");
		return 1;
	}
	uint16_t palette_src[256];
	uint16_t palette_tgt[256];
	uint16_t palette_val;
	int tgt_index;
	fread(palette_src, 2, 256, in);
	for(tgt_index=0; tgt_index<256; tgt_index++) {
		switch(map_action[tgt_index]) {
			case MA_LOC:
				palette_val = local_palette[map_idx[tgt_index]];
				break;
			case MA_SRC:
				palette_val = palette_src[map_idx[tgt_index]];
				break;
			case MA_NONE:
			default:
				palette_val = 0x7c1f;
		}
		palette_tgt[tgt_index] = palette_val;
	}
	fwrite(palette_tgt, 2, 256, out);
	fclose(out);
	fclose(in);
	return 0;
}

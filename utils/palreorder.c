#include <stdio.h>
#include <stdint.h>

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
	uint16_t i=0;
	fread(palette_src, 2, 256, in);
	for(i=0; i<256; i++) {
		uint8_t tgt_index=i;
                if(tgt_index) {
                        if(tgt_index>224) { // move upper colors to start
                                tgt_index-=224;
                        } else if(tgt_index==224) { // remap 224 to 32, not 0
                                tgt_index=32;
                        } else {        // shift colors, leave gap 176-191
                                        // relocate 0xd0-0xdf (which would be
                                        // remapped to 0x00-0x0f) to 0xb0-0xbf
                                tgt_index+=32;
                                if(tgt_index>=176) {
                                        tgt_index+=16;
                                        if(tgt_index<16) tgt_index=0xb0+tgt_index;
                                }
                        }
                }

		palette_tgt[tgt_index] = palette_src[i];
	}
	fwrite(palette_tgt, 2, 256, out);
	fclose(out);
	fclose(in);
	return 0;
}

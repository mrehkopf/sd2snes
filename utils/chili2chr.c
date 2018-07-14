#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char** argv) {
	if(argc<2) {
		printf("Usage: %s <input> <output>\nCurrently only 4-to-2-bit supported\n", argv[0]);
	}
	FILE *in, *out;
	size_t in_off = 0, out_off = 0;
	uint8_t pixperbyte, mask_shift, mask, depth, planeidx;
	uint8_t current_pixel, current_in_tile;
	int i,j;
	if((in=fopen(argv[1], "rb"))==NULL) {
		perror("Could not open input file");
		return 1;
	}
	if((out=fopen(argv[2], "wb"))==NULL) {
		perror("Could not open output file");
		return 1;
	}
	size_t fsize, dsize;

	fseek(in, 0, SEEK_END);
	fsize = ftell(in);
	fseek(in, 0, SEEK_SET);

//	pixperbyte = 2;
//	mask_shift = 4;
//	mask = 0x03;
//	depth = 2;
// 4->2

//	pixperbyte = 2;
//	mask_shift = 4;
//	mask = 0x0f;
//	depth = 4;
// 4->4?

	pixperbyte = 1;
	mask_shift = 0;
	mask = 0xff;
	depth = 8;
// 8->8

	dsize = fsize * depth / (8/pixperbyte);
	uint16_t *obuf;

	if((obuf=malloc(dsize))==NULL) {
		perror("Could not reserve memory");
		fclose(out);
		fclose(in);
		return 1;
	}
	memset(obuf, 0, dsize);
	while (!feof(in)) {
		uint8_t chunk = fgetc(in);
		printf("%lX\n", out_off);
		for(i=0; i<pixperbyte; i++) {
			
			current_pixel = (in_off*pixperbyte+i)%8;
			current_in_tile = (in_off*pixperbyte+i)%64;
			if(!current_pixel && in_off) { // after 8 pixels:
				out_off++;
			}
			if(!current_in_tile && in_off) { // after 64 pixels:
				out_off += (depth/2-1) * 8;
			}
			uint8_t bits = (chunk&mask);
			chunk >>= mask_shift;
			for(planeidx=0; planeidx < depth/2; planeidx++) {
				for(j=0; j<2; j++) {
					obuf[out_off+planeidx*8] |= ((bits & (1<<(j+2*planeidx))) >> (j+2*planeidx) << ((8*j+7)-current_pixel));
				}
			}
		}
		in_off++;
	}
	fwrite(obuf, dsize, 1, out);
	free(obuf);
	fclose(out);
	fclose(in);
}

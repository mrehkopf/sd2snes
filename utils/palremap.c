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
	while(1) {
		uint8_t c=fgetc(in);
		if(feof(in))break;
//		if(c>=1 && c<=48) {
//			c+=207;
//		}

//		shift palette by 32
//		keep color 0
//		leave room for sprite pal 3 and 7 (176-192 and 240-255)
		if(c) {
			if(c>224) { // move upper colors to start
				c-=224;
			} else if(c==224) { // remap 224 to 32, not 0
				c=32;
			} else {	// shift colors, leave gap 176-191
					// relocate 0xd0-0xdf (which would be
					// remapped to 0x00-0x0f) to 0xb0-0xbf
				c+=32;
				if(c>=176) {
					c+=16;
					if(c<16) c=0xb0+c;
				}
			}
		}
		fputc(c, out);
	}
	fclose(out);
	fclose(in);
	return 0;
}

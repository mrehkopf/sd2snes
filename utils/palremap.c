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
		if(c>=1 && c<=43) {
			c+=212;
		}
		fputc(c, out);
	}
	fclose(out);
	fclose(in);
	return 0;
}

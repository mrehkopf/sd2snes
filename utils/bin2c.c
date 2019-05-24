#include <stdio.h>
#include <stdint.h>

int main(int argc, char **argv) {
	size_t count;

	if(argc<3) {
		fprintf(stderr, "Usage: %s <infile> <arrayname>\n", argv[0]);
		return 1;
	}
	FILE* in;
	if((in=fopen(argv[1], "rb"))==NULL) {
		perror("could not open input file");
		return 1;
	}
	printf("const uint8_t %s[] = {", argv[2]);
	count=0;
	while(1) {
		uint8_t c = fgetc(in);
		if(feof(in)) break;
		if(!(count%8)) {
			printf("%s\n  0x%02x", count ? "," : "", c);
		} else {
			printf(", 0x%02x", c);
		}
		count++;
	}
	printf("\n};");
	fclose(in);
	return 0;
}

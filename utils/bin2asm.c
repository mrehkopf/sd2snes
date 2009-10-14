#include <stdio.h>
#include <stdint.h>

int main(int argc, char **argv) {
	size_t count;

	if(argc<1) {
		fprintf(stderr, "Usage: %s <infile> \n", argv[0]);
		return 1;
	}
	FILE* in;
	if((in=fopen(argv[1], "rb"))==NULL) {
		perror("could not open input file");
		return 1;
	}
	printf("chgme   ");
	count=0;
	while(1) {
		uint8_t c = fgetc(in);
		if(feof(in)) break;
		if(!(count%8)) {
			if(count) printf("\n        ");
			printf(".byt  $%02x", c);
		} else {
			printf(", $%02x", c);
		}
		count++;
	}
	fclose(in);
	return 0;
	
}

#include <stdio.h>
#include <stdint.h>

int main(void) {
uint16_t tile=256;
	int i,j;
	FILE *out;
	if((out=fopen("tilemap", "wb"))==NULL) {
		perror("Could not open output file 'tilemap'");
		return 1;
	}
	for(i=0; i<7; i++) {
		for(j=0; j<32; j++)	{
			fwrite(&tile, 2, 1, out);
			tile++;
		}
	}
	fclose(out);
	return 0;
}

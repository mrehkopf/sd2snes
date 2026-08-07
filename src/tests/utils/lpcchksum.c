/*
 * calculate+inject LPC1700 vector checksum
 */

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>


uint32_t getu32(uint8_t *buffer) {
	return buffer[0]+(buffer[1]<<8)+(buffer[2]<<16)+(buffer[3]<<24);
}

void putu32(uint8_t *buffer, uint32_t data) {
	buffer[0]=(uint8_t)(data&0xff);
	buffer[1]=(uint8_t)((data>>8)&0xff);
	buffer[2]=(uint8_t)((data>>16)&0xff);
	buffer[3]=(uint8_t)((data>>24)&0xff);
}

int main(int argc, char **argv) {
	FILE *bin;
	uint32_t data;
	size_t len;
	int count;
	uint8_t *buffer;

	if(argc<2) {
		fprintf(stderr, "Usage: %s <binfile>\nThe original file will be modified!\n", argv[0]);
		return 1;
	}

	if((bin=fopen(argv[1], "rb"))==NULL) {
		perror("could not open input file");
		return 1;
	}
	
	fseek(bin, 0, SEEK_END);
	len=ftell(bin);
	fseek(bin, 0, SEEK_SET);
	if((buffer=malloc(len))==NULL) {
		perror("could not reserve memory");
		fclose(bin);
		return 1;
	}
	fread(buffer, len, 1, bin);
	fclose(bin);

	data=0;
	for(count=0; count<7; count++) {
		data+=getu32(buffer+4*count);
	}
	printf("data=%x chksum=%x\n", data, ~data+1);
	putu32(buffer+28,~data+1);

	if((bin=fopen(argv[1], "wb"))==NULL) {
		perror("could not open output file");
		free(buffer);
		return 1;
	}

	fwrite(buffer, len, 1, bin);
	fclose(bin);
	printf("done\n");
	free(buffer);

	return 0;
}

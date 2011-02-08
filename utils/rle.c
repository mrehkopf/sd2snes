#include <stdio.h>
#include <fcntl.h>
#include <stdint.h>

#define LEN_THRESH (3)

FILE *in, *out;
uint8_t data, datalast;
uint16_t len, first=1;
size_t off;

uint16_t getrunlength(uint8_t data) {
  uint16_t count=1;
  while(fgetc(in)==data && count<65535) {
    if(feof(in))break;
    count++;
  }
  return count;
}

void writerle(uint8_t data, uint16_t len) {
  if(len<256) {
    fputc(0x5b, out);
    fputc(data, out);
    fputc(len & 0xff, out);
  } else {
    fputc(0x77, out);
    fputc(data, out);
    fputc(len & 0xff, out);
    fputc(len >> 8, out);
  }
}

void writeliteral(uint8_t data) {
  if(data==0x5b || data==0x77 || data==0x9b) {
    fputc(0x9b, out);
  }
  fputc(data, out);
}

int main(int argc, char** argv) {
  if((in=fopen(argv[1], "rb"))==NULL) {
    perror("could not open input file");
    return 1;
  }
  if((out=fopen(argv[2], "wb"))==NULL) {
    perror("could not open output file");
    fclose(in);
    return 1;
  }
  len=0;
  while(!feof(in)) {
    data=fgetc(in);
    if(feof(in))break;
    off=ftell(in);
    if((len=getrunlength(data)) > LEN_THRESH) {
      writerle(data, len);
      fseek(in, -1, SEEK_CUR);
    } else {
      fseek(in, off, SEEK_SET);
      writeliteral(data);
    }
  }
  fclose(out);
  fclose(in);
  return 0;
}

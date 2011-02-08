#include <stdio.h>
#include <fcntl.h>
#include <stdint.h>

FILE *in, *out;
uint8_t data;
uint16_t len;

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
    switch(data) {
      case 0x9b:
        fputc(fgetc(in), out);
        break;
      case 0x5b:
        data=fgetc(in);
        len=fgetc(in);
        while(len--)fputc(data, out);
        break;
      case 0x77:
        data=fgetc(in);
        len = fgetc(in);
        len |= fgetc(in) << 8;
        while(len--)fputc(data, out);
        break;
      default:
        fputc(data, out);
    }
  }
  fclose(out);
  fclose(in);
  return 0;
}

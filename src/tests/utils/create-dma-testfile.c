#include <stdio.h>
#include <stdint.h>

int main(void) {
  FILE *out;
  out=fopen("dmatest.bin", "wb+");
  uint32_t count;
  uint8_t data;

  data = 0xff;
  for(count = 0; count < 262144; count++) {
    fputc(data, out);
    data = ~data;
  }
  data = 0x55;
  for(count = 0; count < 262144; count++) {
    fputc(data, out);
    data = ~data;
  }
  data = 0xaa;
  for(count = 0; count < 262144; count++) {
    fputc(data, out);
    data = ~data;
  }
  data = 0x00;
  for(count = 0; count < 262144; count++) {
    fputc(data, out);
    data = ~data;
  }
  fclose(out);
}

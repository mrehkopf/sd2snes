#include <stdio.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdlib.h>

int main(int argc, char **argv) {
  FILE *in;
  if(argc < 2) {
    printf("Usage: %s <inputfile> [<width (bytes), 1-4>]\n", argv[0]);
    return 1;
  }
  int width;
  if(argc < 3) {
    width=1;
  } else {
    width = strtol(argv[2], NULL, 0);
  }

  if((in=fopen(argv[1], "rb"))==NULL) {
    perror(argv[1]);
    return 1;
  }
  printf("memory_initialization_radix = 16;\n");
  printf("memory_initialization_vector =\n");
  uint32_t c, w;
  size_t len, off=0;
  fseek(in, 0, SEEK_END);
  len = ftell(in);
  fseek(in, 0, SEEK_SET);
  while(off < len) {
    c=0;
    for(w=0; w<width; w++) {
      c |= (fgetc(in) & 0xff) << (8*w);
    }
    printf("%x, \n", c);
    off += width;
  }
  fclose(in);
  return 0;
}

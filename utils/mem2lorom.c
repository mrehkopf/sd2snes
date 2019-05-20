#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char **argv) {
  if(argc<1){
    fprintf(stderr, "Usage: %s <hexadecimal address>\n", argv[0]);
    return 1;
  }
  uint32_t addr = strtoul(argv[1], NULL, 16);
  uint32_t tgt = (addr & 0x7fff)
               | ((addr & 0x7f0000) >> 1);
  printf("%06X -> %06X\n", addr, tgt);
  return 0;
}

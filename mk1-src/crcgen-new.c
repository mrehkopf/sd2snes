#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <inttypes.h>
#include <string.h>

#define lo8(x) (x & 0xFF)
#define hi8(x) ((x >> 8) & 0xFF)
#define xhi8(x) ((x >> 16) & 0xff)
#define xxhi8(x) ((x >> 24) & 0xff)

unsigned short crc_ccitt_update (uint16_t crc, uint8_t data)
{
  data ^= lo8 (crc);
  data ^= data << 4;
  return ((((uint16_t)data << 8) | hi8 (crc)) ^ (uint8_t)(data >> 4) ^ ((uint16_t)data << 3));
}	

int main(int argc, char *argv[]) {
  if (argc != 5) {
    printf("Usage: crcgen <filename> <length> <signature> <version>\r\n");
    return 1;
  }

  unsigned long length  = strtol(argv[2],NULL,0);
  unsigned long devid   = strtol(argv[3],NULL,0);
  unsigned long version = strtol(argv[4],NULL,0);

  if (length > length+8) {
    printf("Ha ha, very funny.\n");
    return 1;
  }

  uint8_t *data = malloc(length+8);

  if (!data) {
    perror("malloc");
    return 1;
  }

  memset(data, 0xff, length);
  
  FILE *f;
  
  f = fopen(argv[1], "rb+");
  
  if (f == 0) {
    printf("Unable to open file %s\r\n", argv[1]);
    return 1;
  }
  
  fread(data, 1, length, f);

  data[length-8] = lo8(devid);
  data[length-7] = hi8(devid);
  data[length-6] = xhi8(devid);
  data[length-5] = xxhi8(devid);
  data[length-4] = lo8(version);
  data[length-3] = hi8(version);

  unsigned long l;
  unsigned short crc = 0xFFFF;
  
  for (l=0; l < length-2; l++)
    crc = crc_ccitt_update(crc, data[l]);
  
  data[length-2] = lo8(crc);
  data[length-1] = hi8(crc);

  if (fseek(f, 0, SEEK_SET)) {
    perror("fseek");
    return 1;
  }

  if (fwrite(data, length, 1, f) != 1) {
    perror("fwrite");
    return 1;
  }
  
  fclose(f);
  
  return 0;
}


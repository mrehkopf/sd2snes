#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>

#define ll8(x)    (x & 0xff)
#define lh8(x)    ((x >> 8) & 0xff)
#define hl8(x)    ((x >> 16) & 0xff)
#define hh8(x)    ((x >> 24) & 0xff)

/* Generated on Thu Feb 17 10:57:01 2011,
 * by pycrc v0.7.1, http://www.tty1.net/pycrc/
 */
uint32_t crc_reflect(uint32_t data, size_t data_len)
{
    unsigned int i;
    uint32_t ret;

    ret = data & 0x01;
    for (i = 1; i < data_len; i++)
    {
        data >>= 1;
        ret = (ret << 1) | (data & 0x01);
    }
    return ret;
}

uint32_t crc_update(uint32_t crc, const uint8_t *buf, uint32_t len) {
    unsigned int i;
    uint32_t bit;
    uint8_t c;

    while (len--) {
        c = *buf++;
        for (i = 0x01; i & 0xff; i <<= 1) {
            bit = crc & 0x80000000;
            if (c & i) {
                bit = bit ? 0 : 1;
            }
            crc <<= 1;
            if (bit) {
                crc ^= 0x04c11db7;
            }
        }
        crc &= 0xffffffff;
    }
    return crc & 0xffffffff;
}

int main(int argc, char **argv) {
  FILE *f;
  size_t flen;

  if(argc < 3) {
    printf("Usage: genhdr <input file> <signature> <version>\n"
           "  input file: file to be headered\n"
           "  signature : magic value at start of header (4-char string)\n"
           "  version   : firmware version (decimal uint32)\n"
           "Output is written in place.\n");
    return 1;
  }
  if((f=fopen(argv[1], "rb+"))==NULL) {
    printf("Unable to open input file %s", argv[1]);
    perror("");
    return 1;
  }
  fseek(f,0,SEEK_END);
  flen=ftell(f);

  if(flen+256 < flen) {
    printf("File too large ;)\n");
    fclose(f);
    return 1;
  }
  char *remaining = NULL;
  uint32_t version = (uint32_t)strtoul(argv[3], &remaining, 0);
  if(*remaining) {
    printf("could not parse version number (remaining portion: %s)\n", remaining);
    fclose(f);
    return 1;
  }

  if(strlen(argv[2]) > 4) {
    printf("Magic string '%s' too long. Truncated to 4 characters.\n", argv[2]);
  }
  uint8_t *buf = malloc(flen+256);
  if(!buf) {
    perror("malloc");
    fclose(f);
    return -1;
  }
  memset(buf, 0xff, 256);
  fseek(f, 0, SEEK_SET);
  fread(buf+256, 1, flen, f);

  uint32_t crcc = 0xffffffff, crc;
  crcc = crc_update(crcc, buf+256, flen);
  crcc = crc_reflect(crcc, 32);
  crc = crcc ^ 0xffffffff;

  memset(buf, 0, 4);
  strncpy((char*)buf, argv[2], 4);

  buf[4]  = ll8(version);
  buf[5]  = lh8(version);
  buf[6]  = hl8(version);
  buf[7]  = hh8(version);

  buf[8]  = ll8(flen);
  buf[9]  = lh8(flen);
  buf[10] = hl8(flen);
  buf[11] = hh8(flen);

  buf[12] = ll8(crc);
  buf[13] = lh8(crc);
  buf[14] = hl8(crc);
  buf[15] = hh8(crc);

  buf[16] = ll8(crcc);
  buf[17] = lh8(crcc);
  buf[18] = hl8(crcc);
  buf[19] = hh8(crcc);

  fseek(f, 0, SEEK_SET);
  fwrite(buf, 1, 256+flen, f);
  fclose(f);
  free(buf);
  return 0;
}

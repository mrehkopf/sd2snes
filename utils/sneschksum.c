/*
   Primitive tool to fix the internal header checksum of
   a HiROM SNES image

   Computes a 16-bit sum of all bytes of the input file, with the checksum
   fields set to 0xffff (complement) and 0x0000 (checksum) beforehand.

   Only power-of-two image sizes are supported (no mirroring rules).

   Usage: sneschksum <file>
   <file> will be modified in-place!

*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdarg.h>
#include <errno.h>

#define HDR_CHKSUM_COMPL 0xffdc
#define HDR_CHKSUM       0xffde

static void perror_exit(const char *fmt, ...)
{
  int saved_errno = errno;
  va_list args;

  va_start(args, fmt);
  vfprintf(stderr, fmt, args);
  va_end(args);
  fprintf(stderr, ": %s\n", strerror(saved_errno));
  exit(EXIT_FAILURE);
}

int main(int argc, char **argv) {
  FILE *in;
  long size, i;
  uint8_t *buf;
  uint16_t sum = 0;

  if(argc != 2) {
    fprintf(stderr, "Usage: %s <file>\n", argv[0]);
    return 1;
  }

  if(!(in = fopen(argv[1], "r+b"))) {
    perror_exit("Cannot open work file %s", argv[1]);
  }

  fseek(in, 0, SEEK_END);
  size = ftell(in);
  if(size < 0x10000 || (size & (size - 1))) {
    fprintf(stderr, "%s: size %ld is not a power of two >= 64k\n", argv[1], size);
    return 1;
  }

  if(!(buf = malloc(size))) {
    perror_exit("malloc(%ld)", size);
  }

  fseek(in, 0, SEEK_SET);

  if(fread(buf, 1, size, in) != (size_t)size) {
    perror_exit("Reading from file %s", argv[1]);
  }

  buf[HDR_CHKSUM_COMPL] = 0xff;
  buf[HDR_CHKSUM_COMPL + 1] = 0xff;
  buf[HDR_CHKSUM] = 0x00;
  buf[HDR_CHKSUM + 1] = 0x00;
  for(i = 0; i < size; i++) {
    sum += buf[i];
  }
  buf[HDR_CHKSUM_COMPL] = ~sum & 0xff;
  buf[HDR_CHKSUM_COMPL + 1] = (~sum >> 8) & 0xff;
  buf[HDR_CHKSUM] = sum & 0xff;
  buf[HDR_CHKSUM + 1] = sum >> 8;
  fseek(in, HDR_CHKSUM_COMPL, SEEK_SET);

  if(fwrite(buf + HDR_CHKSUM_COMPL, 1, 4, in) != 4) {
    perror_exit("Couldn't write to file %s", argv[1]);
  }

  fclose(in);
  free(buf);

  printf("%s: checksum $%04X, complement $%04X\n", argv[1], sum, (uint16_t)~sum);
  return 0;
}

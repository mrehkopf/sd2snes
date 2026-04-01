#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <getopt.h>
#include <ctype.h>

#ifdef _WIN32
  #define SET_BINARY_MODE(file) _setmode(_fileno(file), _O_BINARY);
#else
  #define SET_BINARY_MODE(file)
#endif

#define l8(x)    (x & 0xff)
#define h8(x)    ((x >> 8) & 0xff)

typedef struct cfg {
  bool pal2bin;
  char *infile;
  char *outfile;
} cfg_t;

cfg_t cfg = {
  .pal2bin = false,
  .infile = NULL,
  .outfile = NULL
};

typedef struct _color {
  uint8_t r;
  uint8_t g;
  uint8_t b;
} color_t;

color_t *palette;

void convertbin2pal(FILE *in, FILE *out) {
  int alloc_thres = 256;
  int color_count = 0;
  palette = calloc(alloc_thres, sizeof(color_t));

  fputs("JASC-PAL\n", out);
  int h, l;
  uint16_t color;
  uint8_t r, g, b;

  while(1) {
    l = fgetc(in);
    h = fgetc(in);
    if(feof(in)) break;
    /* get 16-bit color value */
    color = (h << 8) | l;

    /* extract 5-bit components:
       0bbbbbgggggrrrrr */
    r = (color & 0x1f);
    g = (color >> 5) & 0x1f;
    b = (color >> 10) & 0x1f;

    /* expand to 8 bits:
          ...54321
          54321<<<
          ...>>543
       -> 54321543 */
    r = (r << 3) | (r >> 2);
    g = (g << 3) | (g >> 2);
    b = (b << 3) | (b >> 2);
    palette[color_count].r = r;
    palette[color_count].g = g;
    palette[color_count].b = b;
    color_count++;

    if(color_count == alloc_thres) {
      alloc_thres += 256;
      palette = realloc(palette, alloc_thres * sizeof(color_t));
    }
  }

  fprintf(out, "0100\n%d\n", color_count);
  for(int i = 0; i < color_count; i++) {
    fprintf(out, "%d %d %d\n", palette[i].r, palette[i].g, palette[i].b);
  }
}

void convertpal2bin(FILE *in, FILE *out) {
  int r, g, b;
  int color_count;
  uint16_t color;

  char line[80];
  char *line_ptr;

  fgets(line, sizeof(line)-1, in);
  line[strcspn(line, "\r\n")] = 0;
  if(strcmp(line, "JASC-PAL")) {
    fprintf(stderr, "Error: unrecognized PAL file format (not JASC-PAL)\n");
    abort();
  }
  fgets(line, sizeof(line)-1, in);
  fgets(line, sizeof(line)-1, in);
  color_count = strtol(line, NULL, 10);
  while(color_count--) {
    fgets(line, sizeof(line)-1, in);
    if(feof(in)) {
      break;
    }
    line_ptr = line;
    r = strtol(line_ptr, &line_ptr, 10);
    g = strtol(line_ptr, &line_ptr, 10);
    b = strtol(line_ptr, &line_ptr, 10);
    r >>= 3;
    g >>= 3;
    b >>= 3;
    color = r;
    color |= (g << 5);
    color |= (b << 10);
    fputc(l8(color), out);
    fputc(h8(color), out);
  }
}

int parse_opts(int argc, char *argv[]) {
  static const struct option lopts[] = {
    { "pal2bin", no_argument, NULL, 'b' },
    { "output",  required_argument, NULL, 'o' },
    { "help",    no_argument, NULL, 'h' },
    { NULL, no_argument, NULL, 0 }
  };

  int retval = 0;

  while(true) {
    int c;

    c = getopt_long(argc, argv, "hbo:", lopts, NULL);

    if(c == -1) {
      break;
    }

    switch(c) {
      case 'b':
        cfg.pal2bin = true;
        break;
      case 'o':
        cfg.outfile = optarg;
        break;
      case 'h':
        retval = 1;
        break;
      case '?':
        return 1;
        break;
    }
  }

  for(int index = optind; index < argc; index++) {
    if(cfg.infile != NULL) {
      fprintf(stderr, "Extra argument `%s'.\n", argv[index]);
    } else {
      cfg.infile = argv[index];
    }
  }

  return retval;
}

void print_usage(const char *prog) {
  printf("\nUsage: %s [-b] [-o <output file>] [<input file>]\n", prog);
  puts  ("Converts a raw SNES format palette (15-bit) to JASC .PAL format\n"
         "  input file       palette file to read (default: stdin)\n"
         "  -h --help        print this usage help\n"
         "  -o --output      converted output palette file to write (default: stdout)\n"
         "  -b --pal2bin     convert text palette (JASC) to bin (SNES raw) (default: bin to text)\n");
}

int main(int argc, char **argv) {
  FILE *in = stdin;
  FILE *out = stdout;

  if(parse_opts(argc, argv)) {
    print_usage(argv[0]);
    abort();
  }

  if(cfg.infile) {
    if((in=fopen(cfg.infile, "rb"))==NULL) {
      fprintf(stderr, "Unable to open input file %s: ", cfg.infile);
      perror("");
      return 1;
    }
  } else {
    SET_BINARY_MODE(stdin);
  }

  if(cfg.outfile) {
    if((out=fopen(cfg.outfile, "wb"))==NULL) {
      fprintf(stderr, "Unable to open output file %s: ", cfg.outfile);
      perror("");
      return 1;
    }
  } else {
    SET_BINARY_MODE(stdout);
  }

  if(cfg.pal2bin) {
    convertpal2bin(in, out);
  } else {
    convertbin2pal(in, out);
  }

  return 0;
}
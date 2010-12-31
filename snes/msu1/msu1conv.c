#include <stdio.h>
#include <fcntl.h>
#include <stdint.h>
#include <string.h>

uint16_t tilemap[28][18];

void preparetilemap(void) {
  uint16_t x, y;
  uint16_t tilecnt = 0;
  for(y=0; y<18; y+=2) {
    for(x=0; x<28; x++) {
      tilemap[x][y] = tilecnt;
      tilemap[x][y+1] = tilecnt + 0x10;
      tilecnt++;
      if(!(tilecnt & 0xf)) tilecnt += 0x10;
    }
  }
}

void converttile(char *in, char *out, uint8_t x, uint8_t y) {
  uint32_t srctilestart = (x*8)+(y*8*224);
  uint32_t tgttilestart = tilemap[x][y]*64;

  char *tin = in + srctilestart;
  char *tout = out + tgttilestart;

  memset(tout, 0, 64);

  int px, py;
  for(py = 0; py < 8; py++) {
    for(px = 0; px < 8; px++) {
      tout[ 0+2*py] |= ((tin[px+224*py] & 0x01) << 7) >> px;
      tout[ 1+2*py] |= ((tin[px+224*py] & 0x02) << 6) >> px;
      tout[16+2*py] |= ((tin[px+224*py] & 0x04) << 5) >> px;
      tout[17+2*py] |= ((tin[px+224*py] & 0x08) << 4) >> px;
      tout[32+2*py] |= ((tin[px+224*py] & 0x10) << 3) >> px;
      tout[33+2*py] |= ((tin[px+224*py] & 0x20) << 2) >> px;
      tout[48+2*py] |= ((tin[px+224*py] & 0x40) << 1) >> px;
      tout[49+2*py] |= ((tin[px+224*py] & 0x80) << 0) >> px;
    }
  }
}

void convertpalette(char *in, char *out) {
  uint16_t tgtcol;
  int pc;
  uint8_t r, g, b;
  for(pc = 0; pc < 256; pc++) {
    b = in[pc*3+0];
    g = in[pc*3+1];
    r = in[pc*3+2];
    tgtcol = ((b & 0xf8) << 7) | ((g & 0xf8) << 2) | ((r & 0xf8) >> 3);
    out[pc*2+0] = tgtcol & 0xff;
    out[pc*2+1] = tgtcol >> 8;
  }
}

void readflip(FILE *in, char *inbuf) {
  int y;
  for(y=0; y<144; y++) {
    fread(inbuf+224*(143-y), 224, 1, in);
  }
}

int main(int argc, char **argv) {
  preparetilemap();
  uint16_t x,y;
  for(y=0; y<18; y++) {
    for(x=0; x<28; x++) {
      printf("%03x ", tilemap[x][y]);
    }
    printf("\n");
  }
  char inbuf[32256], outbuf[32512];
  char inpal[768], outpal[512];

  FILE *in, *out;
  int fileno=0, startframe=0;
  uint16_t numcolors;
  char filename[80];
  out=fopen("out.msu", "wb");
  uint8_t numframes_l, numframes_h;
  uint8_t std_frameduration = 2;
  uint8_t alt_frameduration = 0;
  uint8_t alt_durfreq = 0;
  fwrite(&filename, 5, 1, out); /* write padding for now */
  while(1) {
    sprintf(filename, "%08d.tga", fileno++);
    if((in=fopen(filename, "rb"))==NULL) {
      if(fileno==1) {
        startframe = 1;
        continue;
      } else {
        break;
      }
    }
    fseek(in, 5, SEEK_SET);
    fread(&numcolors, 2, 1, in);
    fseek(in, 18, SEEK_SET);
    fread(inpal, numcolors*3, 1, in);
    readflip(in, inbuf);
//    fread(inbuf, 32256, 1, in);
    fclose(in);
    for(y=0; y<18; y++) {
      for(x=0; x<28; x++) {
        converttile(inbuf, outbuf, x, y);
      }
    }
    fwrite(outbuf, 32512, 1, out);
    convertpalette(inpal, outpal);
    fwrite(outpal, 512, 1, out);
  }
  fileno-=startframe;
  numframes_l=fileno&0xff;
  numframes_h=fileno>>8;
  fseek(out, 0, SEEK_SET);
  fwrite(&numframes_l, 1, 1, out);
  fwrite(&numframes_h, 1, 1, out);
  fwrite(&std_frameduration, 1, 1, out);
  fwrite(&alt_frameduration, 1, 1, out);
  fwrite(&alt_durfreq, 1, 1, out);
  fclose(out);
  return 0;
}

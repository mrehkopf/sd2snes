#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "genbsxpage.h"

int main(void) {
    FILE *out;
    uint8_t *bsxpage = malloc(bsx_filesize);
    uint32_t offset;
    uint16_t len;
    uint8_t *bsxptr = (uint8_t*)bsx_data;
    while(1) {
        offset = *bsxptr;
        offset += (uint32_t)(*(bsxptr+1)) << 8;
        offset += (uint32_t)(*(bsxptr+2)) << 16;
        len = *(bsxptr+3);
        len += (uint32_t)(*(bsxptr+4)) << 8;
        if(len == 0) {
            break;
        }
        bsxptr += 5;
        memcpy(bsxpage + offset, bsxptr, len);
        bsxptr += len;
    }
    if((out=fopen("bsxpage.bin","wb")) == NULL) {
        perror("Could not open bsxpage.bin for writing");
        return 1;
    }
    fwrite(bsxpage, bsx_filesize, 1, out);
    fclose(out);
    return 0;
}
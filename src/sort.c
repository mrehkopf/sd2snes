
#include <arm/NXP/LPC17xx/LPC17xx.h>
#include <string.h>
#include <stdlib.h>
#include "config.h"
#include "uart.h"
#include "memory.h"
#include "sort.h"

/* 
   heap sort algorithm for data located outside RAM 
   addr:     start address of pointer table
   i:        index (in 32-bit elements)
   heapsize: size of heap (in 32-bit elements)
*/

uint32_t stat_getstring = 0;
static char sort_str1[21], sort_str2[21];
uint32_t ptrcache[QSORT_MAXELEM] IN_AHBRAM;

/* get element from pointer table in external RAM*/
uint32_t sort_get_elem(uint32_t base, unsigned int index) {
  return sram_readlong(base+4*index);
}

/* put element from pointer table in external RAM */
void sort_put_elem(uint32_t base, unsigned int index, uint32_t elem) {
  sram_writelong(elem, base+4*index);
}

/* compare strings pointed to by elements of pointer table */
int sort_cmp_idx(uint32_t base, unsigned int index1, unsigned int index2) {
  uint32_t elem1, elem2;
  elem1 = sort_get_elem(base, index1);
  elem2 = sort_get_elem(base, index2);
  return sort_cmp_elem((void*)&elem1, (void*)&elem2);
}

int sort_cmp_elem(const void* elem1, const void* elem2) {
  uint32_t el1 = *(uint32_t*)elem1;
  uint32_t el2 = *(uint32_t*)elem2;
  sort_getstring_for_dirent(sort_str1, el1);
  sort_getstring_for_dirent(sort_str2, el2);
/*printf("i1=%d i2=%d elem1=%lx elem2=%lx ; compare %s   ---   %s\n", index1, index2, elem1, elem2, sort_str1, sort_str2); */

  if ((el1 & 0x80000000) && !(el2 & 0x80000000)) {
    return -1;
  }

  if (!(el1 & 0x80000000) && (el2 & 0x80000000)) {
    return 1;
  }
/*  
  uint16_t cmp_i;
  for(cmp_i=0; cmp_i<8 && sort_long1[cmp_i] == sort_long2[cmp_i]; cmp_i++);
  if(cmp_i==8) {
    return 0;
  }
  return sort_long1[cmp_i]-sort_long2[cmp_i]; */
  return strcasecmp(sort_str1, sort_str2);
}

/* get truncated string from database */
void sort_getstring_for_dirent(char *ptr, uint32_t addr) {
  uint8_t leaf_offset;
  if(addr & 0x80000000) {
    /* is directory link, name offset 4 */
    leaf_offset = sram_readbyte(addr + 4 + SRAM_MENU_ADDR);
    sram_readblock(ptr, addr + 5 + leaf_offset + SRAM_MENU_ADDR, 20);
  } else {
    /* is file link, name offset 6 */
    leaf_offset = sram_readbyte(addr + 6 + SRAM_MENU_ADDR);
    sram_readblock(ptr, addr + 7 + leaf_offset + SRAM_MENU_ADDR, 20);
  }
  ptr[20]=0;
}

void sort_heapify(uint32_t addr, unsigned int i, unsigned int heapsize)
{
  while(1) {
    unsigned int l = 2*i+1;
    unsigned int r = 2*i+2;
    unsigned int largest = (l < heapsize && sort_cmp_idx(addr, i, l) < 0) ? l : i;

    if(r < heapsize && sort_cmp_idx(addr, largest, r) < 0)
      largest = r;

    if(largest != i) {
      uint32_t tmp = sort_get_elem(addr, i);
      sort_put_elem(addr, i, sort_get_elem(addr, largest));
      sort_put_elem(addr, largest, tmp);
      i = largest;
    }
    else break;
  }
}

void sort_dir(uint32_t addr, unsigned int size)
{
stat_getstring=0;
  if(size > QSORT_MAXELEM) {
    printf("more than %d dir entries, doing slower in-place sort\n", QSORT_MAXELEM);
    ext_heapsort(addr, size);
  } else {
    /* retrieve, sort, and store dir table */
    sram_readblock(ptrcache, addr, size*4);
    qsort((void*)ptrcache, size, 4, sort_cmp_elem);
    sram_writeblock(ptrcache, addr, size*4);
  }
}

void ext_heapsort(uint32_t addr, unsigned int size) {
  for(unsigned int i = size/2; i > 0;) sort_heapify(addr, --i, size);

  for(unsigned int i = size-1; i>0; --i) {
    uint32_t tmp = sort_get_elem(addr, 0);
    sort_put_elem(addr, 0, sort_get_elem(addr, i));
    sort_put_elem(addr, i, tmp);
    sort_heapify(addr, 0, i);
  }
}


#ifndef _SORT_H
#define _SORT_H

#include <arm/NXP/LPC17xx/LPC17xx.h>

uint32_t sort_get_elem(uint32_t base, unsigned int index);
void sort_put_elem(uint32_t base, unsigned int index, uint32_t elem);
int sort_cmp_idx(uint32_t base, unsigned int index1, unsigned int index2);
int sort_cmp_elem(const void* elem1, const void* elem2);
void sort_getstring_for_dirent(char *ptr, uint32_t addr);
void sort_getlong_for_dirent(uint32_t* ptr, uint32_t addr);
void sort_heapify(uint32_t addr, unsigned int i, unsigned int heapsize);
void sort_dir(uint32_t addr, unsigned int size);
void ext_heapsort(uint32_t addr, unsigned int size);
#endif

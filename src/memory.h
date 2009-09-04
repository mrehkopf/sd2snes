// insert cool lengthy disclaimer here
// memory.h

#ifndef MEMORY_H
#define MEMORY_H
	uint32_t load_rom(char* filename);
	uint32_t load_sram(char* filename);
	void save_sram(char* filename, uint32_t sram_size, uint32_t base_addr);
	uint32_t calc_sram_crc(uint32_t size);
#endif

// insert cool lengthy disclaimer here
// memory.h

#ifndef MEMORY_H
#define MEMORY_H

#define SRAM_WORK_ADDR	(0x100000L)

	uint32_t load_rom(char* filename);
	uint32_t load_sram(char* filename);
	uint32_t sram_readlong(uint32_t addr);
	void sram_writelong(uint32_t val, uint32_t addr);
	void sram_readblock(void* buf, uint32_t addr, uint16_t size);
	void sram_writeblock(void* buf, uint32_t addr, uint16_t size);
	void save_sram(char* filename, uint32_t sram_size, uint32_t base_addr);
	uint32_t calc_sram_crc(uint32_t base_addr, uint32_t size);
#endif

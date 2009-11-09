// insert cool lengthy disclaimer here
// memory.h

#ifndef MEMORY_H
#define MEMORY_H

#define SRAM_WORK_ADDR	(0x100000L)
#define SRAM_DB_ADDR (0x080000L)
#define SRAM_DIR_ADDR (0x300000L)
#define SRAM_CMD_ADDR (0x601004L)
#define SRAM_FD_ADDR (0x601000L)
#define SRAM_SAVE_ADDR (0x600000L)
#define SRAM_SCRATCHPAD (0x7FFFF0L)
#define SRAM_RELIABILITY_SCORE (0x100)

	uint32_t load_rom(uint8_t* filename);
	uint32_t load_sram(uint8_t* filename, uint32_t base_addr);
	void sram_hexdump(uint32_t addr, uint32_t len);
	uint8_t sram_readbyte(uint32_t addr);
	uint32_t sram_readlong(uint32_t addr);
	void sram_writebyte(uint8_t val, uint32_t addr);
	void sram_writelong(uint32_t val, uint32_t addr);
	void sram_readblock(void* buf, uint32_t addr, uint16_t size);
	void sram_writeblock(void* buf, uint32_t addr, uint16_t size);
	void save_sram(uint8_t* filename, uint32_t sram_size, uint32_t base_addr);
	uint32_t calc_sram_crc(uint32_t base_addr, uint32_t size);
	uint8_t sram_reliable(void);
#endif

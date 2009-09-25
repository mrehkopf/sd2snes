// insert cool lengthy disclaimer here

/*
 * smc.h: data structures for SNES ROM images
 */

#ifndef SMC_H
#define SMC_H

typedef struct _snes_header {
	uint8_t maker[2];		// 0xB0
	uint8_t gamecode[4];	// 0xB2
	uint8_t fixed_00[7];	// 0xB6
	uint8_t expramsize;		// 0xBD
	uint8_t specver;		// 0xBE
	uint8_t carttype2; 		// 0xBF
	uint8_t name[21];		// 0xC0
	uint8_t map;			// 0xD5
	uint8_t carttype;		// 0xD6
	uint8_t romsize;		// 0xD7
	uint8_t ramsize;		// 0xD8
	uint8_t destcode;		// 0xD9
	uint8_t fixed_33;		// 0xDA
	uint8_t ver;			// 0xDB
	uint16_t cchk;			// 0xDC
	uint16_t chk;			// 0xDE
} snes_header_t;

typedef struct _snes_romprops {
	uint16_t offset;			// start of actual ROM image
	uint8_t mapper_id;			// FPGA mapper
	uint32_t expramsize_bytes;	// ExpRAM size in bytes
	uint32_t ramsize_bytes;		// CartRAM size in bytes
	uint32_t romsize_bytes;		// ROM size in bytes (rounded up)
	snes_header_t header;		// original header from ROM image
} snes_romprops_t;

void smc_id(snes_romprops_t*);
uint8_t smc_headerscore(snes_header_t*);


/*pedef struct {
	
}*/

#endif

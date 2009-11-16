// insert cool lengthy disclaimer here
// filetypes.c: File support

#include <avr/io.h>
#include <util/delay.h>
#include "fileops.h"
#include "config.h"
#include "uart.h"
#include "smc.h"

uint32_t hdr_addr[6] = {0xffb0, 0x101b0, 0x7fb0, 0x81b0, 0x40ffb0, 0x4101b0};
uint8_t countAllASCII(uint8_t* data, int size) {
	uint8_t res = 0;
	do {
		size--;
		if(data[size] >= 0x20 && data[size] <= 0x7e) {
			res++;
		}
	} while (size);
	return res;
}

uint8_t countAllJISX0201(uint8_t* data, int size) {
	uint8_t res = 0;
	do {
		size--;
		if((data[size] >= 0x20 && data[size] <= 0x7e)
           ||(data[size] >= 0xa1 && data[size] <= 0xdf)) {
			res++;
		}
	} while (size);
	return res;
}

uint8_t isFixed(uint8_t* data, int size, uint8_t value) {
	uint8_t res = 1;
	do {
		size--;
		if(data[size] != value) {
			res = 0;
		}
	} while (size);
	return res;
}

uint8_t checkChksum(uint16_t cchk, uint16_t chk) {
	uint32_t sum = cchk + chk;
	uint8_t res = 0;
	if(sum==0x0000ffff) {
		res = 0x10;
	}
	return res;
}

void smc_id(snes_romprops_t* props) {
	uint8_t score, maxscore=1, score_idx=2; // assume LoROM

	snes_header_t* header = &(props->header);
	
	for(uint8_t num = 0; num < 6; num++) {
		if(!file_readblock(header, hdr_addr[num], sizeof(snes_header_t)) 
		|| file_res) {
//			dprintf("uh oh... %d\n", file_res);
//			_delay_ms(30);
			score = 0;
		} else {
			score = smc_headerscore(header)/(1+(num&1));
		}
		dprintf("%d: offset = %lX; score = %d\n", num, hdr_addr[num], score);
//		_delay_ms(100);
		if(score>=maxscore) {
			score_idx=num;
			maxscore=score;
		}		
	}

	if(score_idx & 1) {
		props->offset = 0x200;
	} else {
		props->offset = 0;
	}
	
	// restore the chosen one
	dprintf("winner is %d\n", score_idx);
//	_delay_ms(30);
	file_readblock(header, hdr_addr[score_idx], sizeof(snes_header_t));
	switch(header->map & 0xef) {
		case 0x20:
			props->mapper_id = 1;
			break;
		case 0x21:
			props->mapper_id = 0;
			break;
		case 0x25:
			props->mapper_id = 2;
			break;
		default: // invalid/unsupported mapper, use header location
			switch(score_idx) {
				case 0:
				case 1:
					props->mapper_id = 0;
					break;
				case 2:
				case 3:
					props->mapper_id = 1;
					break;
				case 4:
				case 5:
					props->mapper_id = 2;
					break;
				default:
					props->mapper_id = 1; // whatever
			}
	}
	if(header->romsize == 0 || header->romsize > 13) {
		header->romsize = 13;
	}
	props->ramsize_bytes = (uint32_t)1024 << header->ramsize;
	props->romsize_bytes = (uint32_t)1024 << header->romsize;
	props->expramsize_bytes = (uint32_t)1024 << header->expramsize;
	f_lseek(&file_handle, 0);
}

uint8_t smc_headerscore(snes_header_t* header) {
	uint8_t score=0;
	score += countAllASCII(header->maker, sizeof(header->maker));
	score += countAllASCII(header->gamecode, sizeof(header->gamecode));
	score += isFixed(header->fixed_00, sizeof(header->fixed_00), 0x00);
	score += countAllJISX0201(header->name, sizeof(header->name));
	score += 3*isFixed(&header->fixed_33, sizeof(header->fixed_33), 0x33);
	score += checkChksum(header->cchk, header->chk);
	return score;
}


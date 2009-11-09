// insert cool lengthy disclaimer here

#include <stdio.h>
#include <string.h>
#include <avr/pgmspace.h>
#include <util/delay.h>
#include "config.h"
#include "uart.h"
#include "filetypes.h"
#include "ff.h"
#include "smc.h"
#include "fileops.h"
#include "crc16.h"
#include "memory.h"
#include "led.h"

uint16_t scan_flat(const char* path) {
	DIR dir;
	FRESULT res;
	FILINFO fno;
	fno.lfn = NULL;
	res = f_opendir(&dir, (unsigned char*)path);
	uint16_t numentries = 0;
	if (res == FR_OK) {
		for (;;) {
			res = f_readdir(&dir, &fno);
			if(res != FR_OK || fno.fname[0] == 0)break;
			numentries++;
		}
	}
	return numentries;
}

uint16_t scan_dir(char* path, char mkdb, uint32_t this_dir_tgt) {
	DIR dir;
	FILINFO fno;
	FRESULT res;
	uint8_t len;
	unsigned char* fn;
	static unsigned char depth = 0;
	static uint16_t crc;
	static uint32_t db_tgt;
	static uint32_t next_subdir_tgt;
	static uint32_t dir_end = 0;
	static uint8_t was_empty = 0;
	uint32_t dir_tgt;
	uint16_t numentries;
	uint32_t dirsize;
	uint8_t pass = 0;

	dir_tgt = this_dir_tgt;
	if(depth==0) {
		crc = 0;
		db_tgt = SRAM_DB_ADDR+0x10;
		dir_tgt = SRAM_DIR_ADDR;
		next_subdir_tgt = SRAM_DIR_ADDR;
		dprintf("root dir @%lx\n", dir_tgt);
	}	
	
	fno.lfn = file_lfn;
	numentries=0;
	for(pass = 0; pass < 2; pass++) {
		if(pass) {
			dirsize = 4*(numentries);
//			dir_tgt_next = dir_tgt + dirsize + 4; // number of entries + end marker
			next_subdir_tgt += dirsize + 4;
			if(next_subdir_tgt > dir_end) {
				dir_end = next_subdir_tgt;
			}
			dprintf("path=%s depth=%d ptr=%lx entries=%d next subdir @%lx\n", path, depth, db_tgt, numentries, next_subdir_tgt /*dir_tgt_next*/);
//			_delay_ms(50);
			if(mkdb) {
				dprintf("d=%d Saving %lX to Address %lX  [end]\n", depth, 0L, next_subdir_tgt - 4);
//				_delay_ms(50);	
				sram_writelong(0L, next_subdir_tgt - 4);
			}
		}
		res = f_opendir(&dir, (unsigned char*)path);
		if (res == FR_OK) {
			len = strlen((char*)path);
			for (;;) {
				toggle_busy_led();
				res = f_readdir(&dir, &fno);
				if (res != FR_OK || fno.fname[0] == 0) {
					if(pass) {
						if(!numentries) was_empty=1;
					}
					break;
				}
				fn = *fno.lfn ? fno.lfn : fno.fname;
	//			dprintf("%s\n", fn);
	//			_delay_ms(100);
				if (*fn == '.') continue;
				if (fno.fattrib & AM_DIR) {
					numentries++;
					if(pass) {
						path[len]='/';
						strncpy(path+len+1, (char*)fn, sizeof(fs_path)-len);
						depth++;
						if(mkdb) {
							uint16_t pathlen = strlen(path);
							// write element pointer to current dir structure
							dprintf("d=%d Saving %lX to Address %lX  [dir]\n", depth, db_tgt, dir_tgt);
//							_delay_ms(50);
							sram_writelong(db_tgt|((uint32_t)0x80<<24), dir_tgt);
//							sram_writeblock((uint8_t*)&db_tgt, dir_tgt_save, sizeof(dir_tgt_save));

							// save element:
							//  - path name
							//  - pointer to sub dir structure
							dprintf("    Saving dir descriptor to %lX, tgt=%lX, path=%s\n", db_tgt, next_subdir_tgt, path);
//							_delay_ms(100);
							sram_writelong(next_subdir_tgt, db_tgt);
							sram_writebyte(len+1, db_tgt+sizeof(next_subdir_tgt));
							sram_writeblock(path, db_tgt+sizeof(next_subdir_tgt)+sizeof(len), pathlen + 1);
//							sram_writeblock((uint8_t*)&dir_tgt, db_tgt+256, sizeof(dir_tgt));
							db_tgt += sizeof(next_subdir_tgt) + sizeof(len) + pathlen + 1;
						}
						scan_dir(path, mkdb, next_subdir_tgt);
						dir_tgt += 4;
//						if(was_empty)dir_tgt_next += 4;
						was_empty = 0;
						depth--;
						path[len]=0;
					}
				} else {
					SNES_FTYPE type = determine_filetype((char*)fn);
					if(type != TYPE_UNKNOWN) {
						numentries++;
						if(pass) {
							if(mkdb) {
								snes_romprops_t romprops;
								path[len]='/';
								strncpy(path+len+1, (char*)fn, sizeof(fs_path)-len);
								uint16_t pathlen = strlen(path);
								switch(type) {
									case TYPE_SMC:
										file_open_by_filinfo(&fno);
										if(file_res){
											dprintf("ZOMG NOOOO %d\n", file_res);
											_delay_ms(30);
										}
										smc_id(&romprops);
										file_close();
		//								_delay_ms(30);
										// write element pointer to current dir structure
//										dprintf("d=%d Saving %lX to Address %lX  [file]\n", depth, db_tgt, dir_tgt);
//										_delay_ms(50);
										sram_writelong(db_tgt, dir_tgt);
//										sram_writeblock((uint8_t*)&db_tgt, dir_tgt, sizeof(db_tgt));
										dir_tgt += 4;
										// save element:
										//  - SNES header information
										//  - file name
										sram_writeblock((uint8_t*)&romprops, db_tgt, sizeof(romprops));
										sram_writebyte(len+1, db_tgt + sizeof(romprops));
										sram_writeblock(path, db_tgt + sizeof(romprops) + sizeof(len), pathlen + 1);
										db_tgt += sizeof(romprops) + sizeof(len) + pathlen + 1;
										break;
									case TYPE_UNKNOWN:
									default:
										break;
								}
								path[len]=0;
		//						dprintf("%s ", path);
		//						_delay_ms(30);
							}
						} else {
							unsigned char* sfn = fno.fname;
							while(*sfn != 0) {
								crc += crc16_update(crc, sfn++, 1);
							}
						}
					}
	//					dprintf("%s/%s\n", path, fn);
	//					_delay_ms(50);
				}
			}
		} else uart_putc(0x30+res);
	}
//	dprintf("%x\n", crc);
//	_delay_ms(50);
	sram_writeblock(&db_tgt, SRAM_DB_ADDR+4, sizeof(db_tgt));
	sram_writeblock(&dir_end, SRAM_DB_ADDR+8, sizeof(dir_end));
	return crc;
}


SNES_FTYPE determine_filetype(char* filename) {
	char* ext = strrchr(filename, '.');
	if(ext == NULL)
		return TYPE_UNKNOWN;
	if(!strcasecmp_P(ext+1, PSTR("SMC"))) {
		return TYPE_SMC;
	}/* later
	if(!strcasecmp_P(ext+1, PSTR("SRM"))) {
		return TYPE_SRM;
	}
	if(!strcasecmp_P(ext+1, PSTR("SPC"))) {
		return TYPE_SPC;
	}*/
	return TYPE_UNKNOWN;
}

FRESULT get_db_id(uint16_t* id) {
	file_open((uint8_t*)"/sd2snes/sd2snes.db", FA_READ);
	if(file_res == FR_OK) {
		file_readblock(id, 0, 2);
/* XXX */// *id=0xdead;
		file_close();
	} else {
		*id=0xdead;
	}
	return file_res;
}

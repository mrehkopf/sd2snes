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

uint16_t scan_dir(char* path, char mkdb) {
	DIR dir;
	FILINFO fno;
	FRESULT res;
    int len;
	unsigned char* fn;
	static unsigned char lfn[256];
	static unsigned char depth = 0;
	static uint16_t crc;
	static uint32_t db_tgt;
	if(depth==0) {
		crc = 0;
		db_tgt = SRAM_WORK_ADDR+0x10;
	}
//	dprintf("path=%s depth=%d ptr=%lx\n", path, depth, db_tgt);
//	_delay_ms(50);
	fno.lfn = lfn;
    res = f_opendir(&dir, (unsigned char*)path);
    if (res == FR_OK) {
        len = strlen((char*)path);
        for (;;) {
            res = f_readdir(&dir, &fno);
            if (res != FR_OK || fno.fname[0] == 0) break;
            fn = *fno.lfn ? fno.lfn : fno.fname;
//			dprintf("%s\n", fn);
//			_delay_ms(100);
            if (*fn == '.') continue;
            if (fno.fattrib & AM_DIR) {
				path[len]='/';
                strncpy(path+len+1, (char*)fn, sizeof(fs_path)-len);
				depth++;
                scan_dir(path, mkdb);
				depth--;
				path[len]=0;
//                if (res != FR_OK) {
//					break;
//				}
            } else {
				SNES_FTYPE type = determine_filetype((char*)fn);
				if(type != TYPE_UNKNOWN) {
					if(mkdb) {
						snes_romprops_t romprops;
						path[len]='/';
						strncpy(path+len+1, (char*)fn, sizeof(fs_path)-len);
						switch(type) {
							case TYPE_SMC:
								file_open_by_filinfo(&fno);
								if(file_res){
									dprintf("ZOMG NOOOO %d\n", file_res);
									_delay_ms(30);
								}
								smc_id(&romprops);
								file_close();
								dprintf("%lx\n", db_tgt);
//								_delay_ms(30);
								sram_writeblock((uint8_t*)&romprops, db_tgt, sizeof(romprops));
								sram_writeblock(path, db_tgt + sizeof(romprops), 256);
								db_tgt += 0x140;
								break;
							case TYPE_UNKNOWN:
							default:
								break;
						}
						path[len]=0;
//						dprintf("%s ", path);
//						_delay_ms(30);
					}
					unsigned char* sfn = fno.fname;
					while(*sfn != 0) {
						crc += crc16_update(crc, sfn++, 1);
					}
				}
//					dprintf("%s/%s\n", path, fn);
//					_delay_ms(50);
//				_delay_ms(10);
            }
        }
    } else uart_putc(0x30+res);
//	dprintf("%x\n", crc);
//	_delay_ms(50);
	sram_writeblock(&db_tgt, SRAM_WORK_ADDR+4, sizeof(db_tgt));
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
	file_open("/sd2snes/sd2snes.db", FA_READ);
	if(file_res == FR_OK) {
		file_readblock(id, 0, 2);
/* XXX */// *id=0xdead;
		file_close();
	} else {
		*id=0xdead;
	}
	return file_res;
}

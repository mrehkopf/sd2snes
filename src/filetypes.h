// insert cool lengthy disclaimer here
// filetypes.h: fs scanning and file identification

#ifndef FILETYPES_H
#define FILETYPES_H

#include "ff.h"
typedef enum {
	TYPE_UNKNOWN = 0,		/* 0 */
	TYPE_SMC,			    /* 1 */
	TYPE_SRM,				/* 2 */
	TYPE_SPC				/* 3 */
} SNES_FTYPE;


char fs_path[256];
SNES_FTYPE determine_filetype(char* filename);
//uint32_t scan_fs();
uint16_t scan_dir(char* path, char mkdb);
FRESULT get_db_id(uint16_t*);

#endif

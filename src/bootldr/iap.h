#ifndef IAP_H
#define IAP_H

#define IAP_LOCATION 0x1fff1ff1
typedef void (*IAP)(uint32_t*, uint32_t*);

typedef enum {ERR_OK = 0, ERR_HW, ERR_FS, ERR_FILEHD, ERR_FILECHK, ERR_FLASHHD, ERR_FLASHCRC, ERR_FLASHPREP, ERR_FLASHERASE, ERR_FLASH} FLASH_RES;

typedef enum {
/* 0*/  CMD_SUCCESS = 0,
/* 1*/  INVALID_COMMAND,
/* 2*/  SRC_ADDR_ERROR,
/* 3*/  DST_ADDR_ERROR,
/* 4*/  SRC_ADDR_NOT_MAPPED,
/* 5*/  DST_ADDR_NOT_MAPPED,
/* 6*/  COUNT_ERROR,
/* 7*/  INVALID_SECTOR,
/* 8*/  SECTOR_NOT_BLANK,
/* 9*/  SECTOR_NOT_PREPARED_FOR_WRITE_OPERATION,
/*10*/  COMPARE_ERROR,
/*11*/  BUSY
} IAP_RES;

#define FW_MAGIC     (0x44534E53)

typedef struct {
  uint32_t magic;
  uint32_t version;
  uint32_t size;
  uint32_t crc;
  uint32_t crcc;
} sd2snes_fw_header;

uint32_t calc_flash_crc(uint32_t start, uint32_t end);
void test_iap(void);
FLASH_RES check_flash(void);
FLASH_RES flash_file(uint8_t* filename);


#endif

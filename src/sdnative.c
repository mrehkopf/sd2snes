#include <arm/NXP/LPC17xx/LPC17xx.h>
#include <stdio.h>
#include "config.h"
#include "crc.h"
#include "crc16.h"
#include "diskio.h"
#include "spi.h"
#include "timer.h"
#include "uart.h"
#include "led.h"
#include "sdnative.h"
#include "fileops.h"
#include "bits.h"
#include "fpga_spi.h"
#include "memory.h"
#include "snes.h"
#include "fileops.h"

#define MAX_CARDS 1

// SD/MMC commands
#define GO_IDLE_STATE           0
#define SEND_OP_COND            1
#define ALL_SEND_CID            2
#define SEND_RELATIVE_ADDR      3
#define SWITCH_FUNC             6
#define SELECT_CARD             7
#define SEND_IF_COND            8
#define SEND_CSD                9
#define SEND_CID               10
#define STOP_TRANSMISSION      12
#define SEND_STATUS            13
#define GO_INACTIVE_STATE      15
#define SET_BLOCKLEN           16
#define READ_SINGLE_BLOCK      17
#define READ_MULTIPLE_BLOCK    18
#define WRITE_BLOCK            24
#define WRITE_MULTIPLE_BLOCK   25
#define PROGRAM_CSD            27
#define SET_WRITE_PROT         28
#define CLR_WRITE_PROT         29
#define SEND_WRITE_PROT        30
#define ERASE_WR_BLK_STAR_ADDR 32
#define ERASE_WR_BLK_END_ADDR  33
#define ERASE                  38
#define LOCK_UNLOCK            42
#define APP_CMD                55
#define GEN_CMD                56
#define READ_OCR               58
#define CRC_ON_OFF             59

// SD ACMDs
#define SD_SET_BUS_WIDTH           6
#define SD_STATUS                 13
#define SD_SEND_NUM_WR_BLOCKS     22
#define SD_SET_WR_BLK_ERASE_COUNT 23
#define SD_SEND_OP_COND           41
#define SD_SET_CLR_CARD_DETECT    42
#define SD_SEND_SCR               51

// R1 status bits
#define STATUS_IN_IDLE          1
#define STATUS_ERASE_RESET      2
#define STATUS_ILLEGAL_COMMAND  4
#define STATUS_CRC_ERROR        8
#define STATUS_ERASE_SEQ_ERROR 16
#define STATUS_ADDRESS_ERROR   32
#define STATUS_PARAMETER_ERROR 64


/* Card types - cardtype == 0 is MMC */
#define CARD_SD   (1<<0)
#define CARD_SDHC (1<<1)

/*
                Rev.A    Rev.C
    1 DAT3/SS   P0.6     P2.3
    2 CMD/DI    P0.9     P0.9
    5 Clock     P0.7     P0.7
    7 DAT0/DO   P0.8     P2.0
    8 DAT1/IRQ  P1.14    P2.1
    9 DAT2/NC   P1.15    P2.2
*/

/* SD init procedure
   =================
    - initial clock frequency: ~100kHz
    - cycle the clock for at least 74 cycles (some more may be safer)
    - send CMD0
    - send CMD8 (SEND_OP_COND); if no response -> HCS=0; else HCS=1
    - send ACMD41 until OCR[31] (busy) becomes 1 (means: ready)
    - if OCR[30] (CCS) set -> SDHC; else SDSC
    - send CMD2 (read CID) (maybe log some stuff from the CID)
    - send CMD3 (read RCA), store RCA
== end of initialisation ==
    - send CMD9 (read CSD) with RCA, maybe do sth with TRAN_SPEED
    - send CMD7 with RCA, select card, put card in tran
    - maybe send CMD13 with RCA to check state (tran)
    - send ACMD51 with RCA to read SCR (maybe, to check 4bit support)
    - increase clock speed
    - send ACMD6 with RCA to set 4bit bus width
    - send transfer cmds
*/

/*
    static CMD payloads. (no CRC calc required)
    -  CMD0: 0x40 0x00 0x00 0x00 0x00 0x95
    -  CMD8: 0x48 0x00 0x00 0x01 0xaa 0x87
    -  CMD2: 0x42 0x00 0x00 0x00 0x00 0x4d
    -  CMD3: 0x43 0x00 0x00 0x00 0x00 0x21
    - CMD55: 0x77 0x00 0x00 0x00 0x00 0x65
*/

uint8_t cmd[6]={0,0,0,0,0,0};
uint8_t rsp[17];
uint8_t csd[17];
uint8_t cid[17];
diskinfo0_t di;
uint8_t ccs=0;
uint32_t rca;

enum trans_state { TRANS_NONE = 0, TRANS_READ, TRANS_WRITE, TRANS_MID };
enum cmd_state { CMD_RSP = 0, CMD_RSPDAT, CMD_DAT };

int during_blocktrans = TRANS_NONE;
uint32_t last_block = 0;
uint16_t last_offset = 0;

volatile int sd_changed;

/**
 * getbits - read value from bit buffer
 * @buffer: pointer to the data buffer
 * @start : index of the first bit in the value
 * @bits  : number of bits in the value
 *
 * This function returns a value from the memory region passed as
 * buffer, starting with bit "start" and "bits" bit long. The buffer
 * is assumed to be MSB first, passing 0 for start will read starting
 * from the highest-value bit of the first byte of the buffer.
 */
static uint32_t getbits(void *buffer, uint16_t start, int8_t bits) {
  uint8_t *buf = buffer;
  uint32_t result = 0;

  if ((start % 8) != 0) {
    /* Unaligned start */
    result += buf[start / 8] & (0xff >> (start % 8));
    bits  -= 8 - (start % 8);
    start += 8 - (start % 8);
  }
  while (bits >= 8) {
    result = (result << 8) + buf[start / 8];
    start += 8;
    bits -= 8;
  }
  if (bits > 0) {
    result = result << bits;
    result = result + (buf[start / 8] >> (8-bits));
  } else if (bits < 0) {
    /* Fraction of a single byte */
    result = result >> -bits;
  }
  return result;
}

void sdn_checkinit(BYTE drv) {
  if(disk_state == DISK_CHANGED) {
    disk_initialize(drv);
  }
}

uint8_t* sdn_getcid() {
  sdn_checkinit(0);
  return cid;
}

static inline void wiggle_slow_pos(uint16_t times) {
  while(times--) {
    delay_us(2);
    BITBAND(SD_CLKREG->FIOSET, SD_CLKPIN) = 1;
    delay_us(2);
    BITBAND(SD_CLKREG->FIOCLR, SD_CLKPIN) = 1;
  }
}

static inline void wiggle_slow_neg(uint16_t times) {
  while(times--) {
    delay_us(2);
    BITBAND(SD_CLKREG->FIOCLR, SD_CLKPIN) = 1;
    delay_us(2);
    BITBAND(SD_CLKREG->FIOSET, SD_CLKPIN) = 1;
  }
}

static inline void wiggle_fast_pos(uint16_t times) {
  while(times--) {
    BITBAND(SD_CLKREG->FIOSET, SD_CLKPIN) = 1;
    BITBAND(SD_CLKREG->FIOCLR, SD_CLKPIN) = 1;
  }
}

static inline void wiggle_fast_neg(uint16_t times) {
  while(times--) {
    BITBAND(SD_CLKREG->FIOCLR, SD_CLKPIN) = 1;
    BITBAND(SD_CLKREG->FIOSET, SD_CLKPIN) = 1;
  }
}

static inline void wiggle_fast_neg1(void) {
  BITBAND(SD_CLKREG->FIOCLR, SD_CLKPIN) = 1;
  BITBAND(SD_CLKREG->FIOSET, SD_CLKPIN) = 1;
}

static inline void wiggle_fast_pos1(void) {
  BITBAND(SD_CLKREG->FIOSET, SD_CLKPIN) = 1;
  BITBAND(SD_CLKREG->FIOCLR, SD_CLKPIN) = 1;
}


int get_and_check_datacrc(uint8_t *buf) {
  uint16_t crc0=0, crc1=0, crc2=0, crc3=0;
  uint16_t sdcrc0=0, sdcrc1=0, sdcrc2=0, sdcrc3=0;
  uint8_t d0=0, d1=0, d2=0, d3=0;
  uint8_t datdata;
  uint16_t datcnt;
  /* get crcs from card */
  for (datcnt=0; datcnt < 16; datcnt++) {
    datdata = SD_DAT;
    wiggle_fast_neg1();
    sdcrc0 = ((sdcrc0 << 1) & 0xfffe) | ((datdata >> 3) & 0x0001);
    sdcrc1 = ((sdcrc1 << 1) & 0xfffe) | ((datdata >> 2) & 0x0001);
    sdcrc2 = ((sdcrc2 << 1) & 0xfffe) | ((datdata >> 1) & 0x0001);
    sdcrc3 = ((sdcrc3 << 1) & 0xfffe) | ((datdata >> 0) & 0x0001);
  }
  wiggle_fast_neg1();
  /* calc crcs from data */
  for (datcnt=0; datcnt < 512; datcnt++) {
    d0 = ((d0 << 2) & 0xfc) | ((buf[datcnt] >> 6) & 0x02) | ((buf[datcnt] >> 3) & 0x01) ;
    d1 = ((d1 << 2) & 0xfc) | ((buf[datcnt] >> 5) & 0x02) | ((buf[datcnt] >> 2) & 0x01) ;
    d2 = ((d2 << 2) & 0xfc) | ((buf[datcnt] >> 4) & 0x02) | ((buf[datcnt] >> 1) & 0x01) ;
    d3 = ((d3 << 2) & 0xfc) | ((buf[datcnt] >> 3) & 0x02) | ((buf[datcnt] >> 0) & 0x01) ;
    if((datcnt % 4) == 3) {
      crc0 = crc_xmodem_update(crc0, d0);
      crc1 = crc_xmodem_update(crc1, d1);
      crc2 = crc_xmodem_update(crc2, d2);
      crc3 = crc_xmodem_update(crc3, d3);
    }
  }
  if((crc0 != sdcrc0) || (crc1 != sdcrc1) || (crc2 != sdcrc2) || (crc3 != sdcrc3)) {
    printf("CRC mismatch\nSDCRC   CRC\n %04x    %04x\n %04x    %04x\n %04x    %04x\n %04x    %04x\n", sdcrc0, crc0, sdcrc1, crc1, sdcrc2, crc2, sdcrc3, crc3);
    return 1;
  }
  return 0;
}

static inline void wait_busy(void) {
  while(!(BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN))) {
    wiggle_fast_neg1();
  }
  wiggle_fast_neg(4);
}

/*
   send_command_slow
   send SD command and put response in rsp.
   returns length of response or 0 if there was no response
*/
int send_command_slow(uint8_t* cmd, uint8_t* rsp){
  uint8_t shift, i=6;
  int rsplen;
  uint8_t cmdno = *cmd & 0x3f;
  wiggle_slow_pos(5);
  switch(*cmd & 0x3f) {
    case 0:
      rsplen = 0;
      break;
    case 2:
    case 9:
    case 10:
      rsplen = 17;
      break;
    default:
      rsplen = 6;
  }
  /* send command */
  BITBAND(SD_CMDREG->FIODIR, SD_CMDPIN) = 1;

  while(i--) {
    shift = 8;
    do {
      shift--;
      uint8_t data = *cmd;
      *cmd<<=1;
      if(data&0x80) {
        BITBAND(SD_CMDREG->FIOSET, SD_CMDPIN) = 1;
      } else {
        BITBAND(SD_CMDREG->FIOCLR, SD_CMDPIN) = 1;
      }
      wiggle_slow_pos(1);
    } while (shift);
    cmd++;
  }

  wiggle_slow_pos(1);
  BITBAND(SD_CMDREG->FIODIR, SD_CMDPIN) = 0;

  if(rsplen) {
    uint16_t timeout=1000;
    while((BITBAND(SD_CMDREG->FIOPIN, SD_CMDPIN)) && --timeout) {
      wiggle_slow_neg(1);
    }
    if(!timeout) {
      printf("CMD%d timed out\n", cmdno);
      return 0; /* no response within timeout */
    }

    i=rsplen;
    while(i--) {
      shift = 8;
      uint8_t data=0;
      do {
        shift--;
        data |= (BITBAND(SD_CMDREG->FIOPIN, SD_CMDPIN)) << shift;
        wiggle_slow_neg(1);
      } while (shift);
      *rsp=data;
      rsp++;
    }
  }
  return rsplen;
}


/*
   send_command_fast
   send SD command and put response in rsp.
   returns length of response or 0 if there was no response
*/
int send_command_fast(uint8_t* cmd, uint8_t* rsp, uint8_t* buf){
  uint8_t datshift=8, cmdshift, i=6;
  uint8_t cmdno = *cmd & 0x3f;
  int rsplen, dat=0, waitbusy=0, datcnt=512, j=0;
  static int state=CMD_RSP;
  wiggle_fast_pos(9); /* give the card >=8 cycles after last command */
  DBG_SD printf("send_command_fast: sending CMD%d; payload=%02x%02x%02x%02x%02x%02x...\n", cmdno, cmd[0], cmd[1], cmd[2], cmd[3], cmd[4], cmd[5]);
  switch(*cmd & 0x3f) {
    case 0:
      rsplen = 0;
      break;
    case 2:
    case 9:
    case 10:
      rsplen = 17;
      break;
    case 12:
      rsplen = 6;
      waitbusy = 1;
      break;
    case 13:
    case 17:
    case 18:
      dat = 1;
    default:
      rsplen = 6;
  }
  if(dat && (buf==NULL) && !sd_offload) {
    printf("send_command_fast error: buf is null but data transfer expected.\n");
    return 0;
  }
  /* send command */
  BITBAND(SD_CMDREG->FIODIR, SD_CMDPIN) = 1;

  while(i--) {
    uint8_t data = *cmd;
    cmdshift = 8;
    do {
      cmdshift--;
      if(data&0x80) {
        BITBAND(SD_CMDREG->FIOSET, SD_CMDPIN) = 1;
      } else {
        BITBAND(SD_CMDREG->FIOCLR, SD_CMDPIN) = 1;
      }
      data<<=1;
      wiggle_fast_pos1();
    } while (cmdshift);
    cmd++;
  }

  wiggle_fast_pos1();
  BITBAND(SD_CMDREG->FIODIR, SD_CMDPIN) = 0;

  if(rsplen) {
    uint32_t timeout=200000;
    /* wait for response */
    while((BITBAND(SD_CMDREG->FIOPIN, SD_CMDPIN)) && --timeout) {
      wiggle_fast_neg1();
    }
    if(!timeout) {
      printf("CMD%d timed out\n", cmdno);
      return 0; /* no response within timeout */
    }
    i=rsplen;
    uint8_t cmddata=0, datdata=0;
    while(i--) { /* process response */
      cmdshift = 8;
      do {
        if(dat) {
          if(!(BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN))) {
            printf("data start during response\n");
            j=datcnt;
            state=CMD_RSPDAT;
            break;
          }
        }
        cmdshift--;
        cmddata |= (BITBAND(SD_CMDREG->FIOPIN, SD_CMDPIN)) << cmdshift;
        wiggle_fast_neg1();
      } while (cmdshift);
      if(state==CMD_RSPDAT)break;
      *rsp=cmddata;
      cmddata=0;
      rsp++;
    }

    if(state==CMD_RSPDAT) { /* process response+data */
      int startbit=1;
      DBG_SD printf("processing rsp+data cmdshift=%d i=%d j=%d\n", cmdshift, i, j);
      datshift=8;
      while(1) {
        cmdshift--;
        cmddata |= (BITBAND(SD_CMDREG->FIOPIN, SD_CMDPIN)) << cmdshift;
        if(!cmdshift) {
          cmdshift=8;
          *rsp=cmddata;
          cmddata=0;
          rsp++;
          i--;
          if(!i) {
            DBG_SD printf("response end\n");
            if(j) state=CMD_DAT; /* response over, remaining data */
            break;
          }
        }
        if(!startbit) {
          datshift-=4;
          datdata |= SD_DAT << datshift;
          if(!datshift) {
            datshift=8;
            *buf=datdata;
            datdata=0;
            buf++;
            j--;
            if(!j) break;
          }
        }
        startbit=0;
        wiggle_fast_neg1();
      }
    }

    if(dat && state != CMD_DAT) { /* response ended before data */
      BITBAND(SD_CMDREG->FIODIR, SD_CMDPIN) = 1;
      state=CMD_DAT;
      j=datcnt;
      datshift=8;
      timeout=2000000;
      DBG_SD printf("response over, waiting for data...\n");
      /* wait for data start bit on DAT0 */
      while((BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN)) && --timeout) {
        wiggle_fast_neg1();
      }
// printf("%ld\n", timeout);
      if(!timeout) printf("timed out!\n");
      wiggle_fast_neg1(); /* eat the start bit */
      if(sd_offload) {
        if(sd_offload_partial) {
          if(sd_offload_partial_start != 0) {
            if(during_blocktrans == TRANS_MID) sd_offload_partial_start |= 0x8000;
          }
          if(sd_offload_partial_end != 512) {
            sd_offload_partial_end |= 0x8000;
            during_blocktrans = TRANS_MID;
          }
          DBG_SD_OFFLOAD printf("new partial %d - %d\n", sd_offload_partial_start, sd_offload_partial_end);
          fpga_set_sddma_range(sd_offload_partial_start, sd_offload_partial_end);
          fpga_sddma(sd_offload_tgt, 1);
//          sd_offload_partial=0;
          last_offset = sd_offload_partial_end & 0x1ff;
        } else {
          fpga_sddma(sd_offload_tgt, 0);
          last_offset = 0;
        }
        state=CMD_RSP;
        return rsplen;
      }
    }

    if(state==CMD_DAT) { /* transfer rest of data */
      DBG_SD printf("remaining data: %d\n", j);
      if(datshift==8) {
        while(1) {
          datdata |= SD_DAT << 4;
          wiggle_fast_neg1();

          datdata |= SD_DAT;
          wiggle_fast_neg1();

          *buf=datdata;
          datdata=0;
          buf++;
          j--;
          if(!j) break;
        }
      } else {

        while(1) {
          datshift-=4;
          datdata |= SD_DAT << datshift;
          if(!datshift) {
            datshift=8;
            *buf=datdata;
            datdata=0;
            buf++;
            j--;
            if(!j) break;
          }
          wiggle_fast_neg1();
        }
      }
    }
    if(dat) {
#ifdef CONFIG_SD_DATACRC
      if(get_and_check_datacrc(buf-512)) {
        return CRC_ERROR;
      }
#else
      /* eat the crcs */
      wiggle_fast_neg(17);
#endif
    }

    if(waitbusy) {
      DBG_SD printf("waitbusy after send_cmd\n");
      wait_busy();
    }
    state=CMD_RSP;
  }
  rsp-=rsplen;
  DBG_SD printf("send_command_fast: CMD%d response: %02x%02x%02x%02x%02x%02x\n", cmdno, rsp[0], rsp[1], rsp[2], rsp[3], rsp[4], rsp[5]);
  BITBAND(SD_CMDREG->FIODIR, SD_CMDPIN) = 1;
  return rsplen;
}


static inline void make_crc7(uint8_t* cmd) {
  cmd[5]=crc7update(0, cmd[0]);
  cmd[5]=crc7update(cmd[5], cmd[1]);
  cmd[5]=crc7update(cmd[5], cmd[2]);
  cmd[5]=crc7update(cmd[5], cmd[3]);
  cmd[5]=crc7update(cmd[5], cmd[4]);
  cmd[5]=(cmd[5] << 1) | 1;
}

int cmd_slow(uint8_t cmd, uint32_t param, uint8_t crc, uint8_t* dat, uint8_t* rsp) {
  uint8_t cmdbuf[6];
  cmdbuf[0] = 0x40 | cmd;
  cmdbuf[1] = param >> 24;
  cmdbuf[2] = param >> 16;
  cmdbuf[3] = param >> 8;
  cmdbuf[4] = param;
  if(!crc) {
    make_crc7(cmdbuf);
  } else {
    cmdbuf[5] = crc;
  }
  return send_command_slow(cmdbuf, rsp);
}

int acmd_slow(uint8_t cmd, uint32_t param, uint8_t crc, uint8_t* dat, uint8_t* rsp) {
  if(!(cmd_slow(APP_CMD, rca, 0, NULL, rsp))) {
    return 0;
  }
  return cmd_slow(cmd, param, crc, dat, rsp);
}

int cmd_fast(uint8_t cmd, uint32_t param, uint8_t crc, uint8_t* dat, uint8_t* rsp) {
  uint8_t cmdbuf[6];
  cmdbuf[0] = 0x40 | cmd;
  cmdbuf[1] = param >> 24;
  cmdbuf[2] = param >> 16;
  cmdbuf[3] = param >> 8;
  cmdbuf[4] = param;
  if(!crc) {
    make_crc7(cmdbuf);
  } else {
    cmdbuf[5] = crc;
  }
  return send_command_fast(cmdbuf, rsp, dat);
}

int acmd_fast(uint8_t cmd, uint32_t param, uint8_t crc, uint8_t* dat, uint8_t* rsp) {
  if(!(cmd_fast(APP_CMD, rca, 0, NULL, rsp))) {
    return 0;
  }
  return cmd_fast(cmd, param, crc, dat, rsp);
}

int stream_datablock(uint8_t *buf) {
//  uint8_t datshift=8;
  int j=512;
  uint8_t datdata=0;
  uint32_t timeout=1000000;

  DBG_SD printf("stream_datablock: wait for ready...\n");
  if(during_blocktrans != TRANS_MID) {
    while((BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN)) && --timeout) {
      wiggle_fast_neg1();
    }
    DBG_SD if(!timeout) printf("timeout!\n");
    wiggle_fast_neg1(); /* eat the start bit */
  }
  if(sd_offload) {
    if(sd_offload_partial) {
      if(sd_offload_partial_start != 0) {
        if(during_blocktrans == TRANS_MID) sd_offload_partial_start |= 0x8000;
      }
      if(sd_offload_partial_end != 512) {
        sd_offload_partial_end |= 0x8000;
      }
      DBG_SD_OFFLOAD printf("str partial %d - %d\n", sd_offload_partial_start, sd_offload_partial_end);
      fpga_set_sddma_range(sd_offload_partial_start, sd_offload_partial_end);
      fpga_sddma(sd_offload_tgt, 1);
    } else {
      fpga_sddma(sd_offload_tgt, 0);
    }
  } else {
    while(1) {
      datdata = SD_DAT << 4;
      wiggle_fast_neg1();

      datdata |= SD_DAT;
      wiggle_fast_neg1();

      *buf=datdata;
      buf++;
      j--;
      if(!j) break;
    }
#ifdef CONFIG_SD_DATACRC
    return get_and_check_datacrc(buf-512);
#else
    /* eat the crcs */
    wiggle_fast_neg(17);
#endif
  }
  return 0;
}

void send_datablock(uint8_t *buf) {
  uint16_t crc0=0, crc1=0, crc2=0, crc3=0, cnt=512;
  uint8_t dat0=0, dat1=0, dat2=0, dat3=0, crcshift, datshift;

  wiggle_fast_pos1();
  BITBAND(SD_DAT0REG->FIODIR, SD_DAT0PIN) = 1;
  BITBAND(SD_DAT1REG->FIODIR, SD_DAT1PIN) = 1;
  BITBAND(SD_DAT2REG->FIODIR, SD_DAT2PIN) = 1;
  BITBAND(SD_DAT3REG->FIODIR, SD_DAT3PIN) = 1;

  BITBAND(SD_DAT0REG->FIOCLR, SD_DAT0PIN) = 1;
  BITBAND(SD_DAT1REG->FIOCLR, SD_DAT1PIN) = 1;
  BITBAND(SD_DAT2REG->FIOCLR, SD_DAT2PIN) = 1;
  BITBAND(SD_DAT3REG->FIOCLR, SD_DAT3PIN) = 1;

  wiggle_fast_pos1(); /* send start bit to card */
  crcshift=8;
  while(cnt--) {
    datshift=8;
    do {
      datshift-=4;
/*      if(((*buf)>>datshift) & 0x8) {
        BITBAND(SD_DAT3REG->FIOSET, SD_DAT3PIN) = 1;
      } else {
        BITBAND(SD_DAT3REG->FIOCLR, SD_DAT3PIN) = 1;
      }
      if(((*buf)>>datshift) & 0x4) {
        BITBAND(SD_DAT2REG->FIOSET, SD_DAT2PIN) = 1;
      } else {
        BITBAND(SD_DAT2REG->FIOCLR, SD_DAT2PIN) = 1;
      }
      if(((*buf)>>datshift) & 0x2){
        BITBAND(SD_DAT1REG->FIOSET, SD_DAT1PIN) = 1;
      } else {
        BITBAND(SD_DAT1REG->FIOCLR, SD_DAT1PIN) = 1;
      }
      if(((*buf)>>datshift) & 0x1){
        BITBAND(SD_DAT0REG->FIOSET, SD_DAT0PIN) = 1;
      } else {
        BITBAND(SD_DAT0REG->FIOCLR, SD_DAT0PIN) = 1;
      }*/
      SD_DAT0REG->FIOPIN0 = (*buf) >> datshift;
      wiggle_fast_pos1();
    } while (datshift);

    crcshift-=2;
    dat0 |= (((*buf)&0x01) | (((*buf)&0x10) >> 3)) << crcshift;
    dat1 |= ((((*buf)&0x02) >> 1) | (((*buf)&0x20) >> 4)) << crcshift;
    dat2 |= ((((*buf)&0x04) >> 2) | (((*buf)&0x40) >> 5)) << crcshift;
    dat3 |= ((((*buf)&0x08) >> 3) | (((*buf)&0x80) >> 6)) << crcshift;
    if(!crcshift) {
      crc0 = crc_xmodem_update(crc0, dat0);
      crc1 = crc_xmodem_update(crc1, dat1);
      crc2 = crc_xmodem_update(crc2, dat2);
      crc3 = crc_xmodem_update(crc3, dat3);
      crcshift=8;
      dat0=0;
      dat1=0;
      dat2=0;
      dat3=0;
    }
    buf++;
  }
//  printf("crc0=%04x crc1=%04x crc2=%04x crc3=%04x ", crc0, crc1, crc2, crc3);
  /* send crcs */
  datshift=16;
  do {
    datshift--;
    if((crc0 >> datshift) & 1) {
      BITBAND(SD_DAT0REG->FIOSET, SD_DAT0PIN) = 1;
    } else {
      BITBAND(SD_DAT0REG->FIOCLR, SD_DAT0PIN) = 1;
    }
    if((crc1 >> datshift) & 1) {
      BITBAND(SD_DAT1REG->FIOSET, SD_DAT1PIN) = 1;
    } else {
      BITBAND(SD_DAT1REG->FIOCLR, SD_DAT1PIN) = 1;
    }
    if((crc2 >> datshift) & 1) {
      BITBAND(SD_DAT2REG->FIOSET, SD_DAT2PIN) = 1;
    } else {
      BITBAND(SD_DAT2REG->FIOCLR, SD_DAT2PIN) = 1;
    }
    if((crc3 >> datshift) & 1) {
      BITBAND(SD_DAT3REG->FIOSET, SD_DAT3PIN) = 1;
    } else {
      BITBAND(SD_DAT3REG->FIOCLR, SD_DAT3PIN) = 1;
    }
    wiggle_fast_pos1();
  } while(datshift);
  /* send end bit */
  BITBAND(SD_DAT0REG->FIOSET, SD_DAT0PIN) = 1;
  BITBAND(SD_DAT1REG->FIOSET, SD_DAT1PIN) = 1;
  BITBAND(SD_DAT2REG->FIOSET, SD_DAT2PIN) = 1;
  BITBAND(SD_DAT3REG->FIOSET, SD_DAT3PIN) = 1;

  wiggle_fast_pos1();

  BITBAND(SD_DAT0REG->FIODIR, SD_DAT0PIN) = 0;
  BITBAND(SD_DAT1REG->FIODIR, SD_DAT1PIN) = 0;
  BITBAND(SD_DAT2REG->FIODIR, SD_DAT2PIN) = 0;
  BITBAND(SD_DAT3REG->FIODIR, SD_DAT3PIN) = 0;

  wiggle_fast_neg(3);
  dat0=0;

  datshift=4;
  do {
    datshift--;
    dat0 |= ((BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN)) << datshift);
    wiggle_fast_neg1();
  } while (datshift);
  DBG_SD printf("crc %02x\n", dat0);
  if((dat0 & 7) != 2) {
    printf("crc error! %02x\n", dat0);
    while(1);
  }
  if(dat0 & 8) {
    printf("missing start bit in CRC status response...\n");
  }
  wiggle_fast_neg(2);
  wait_busy();
}

void read_block(uint32_t address, uint8_t *buf) {
  DBG_SD_OFFLOAD printf("read_block trans=%d addr=%08lx last_addr=%08lx  offld=%d/%d offst=%04x offed=%04x last_off=%04x\n", during_blocktrans, address, last_block, sd_offload, sd_offload_partial, sd_offload_partial_start, sd_offload_partial_end, last_offset);
  if(during_blocktrans == TRANS_READ && (last_block == address-1)) {
//uart_putc('r');
#ifdef CONFIG_SD_DATACRC
    int cmd_res;
    if((cmd_res = stream_datablock(buf)) == CRC_ERROR) {
      while(cmd_res == CRC_ERROR) {
        cmd_fast(STOP_TRANSMISSION, 0, 0x61, NULL, rsp);
        cmd_res = cmd_fast(READ_MULTIPLE_BLOCK, address, 0, buf, rsp);
      }
    }
#else
    stream_datablock(buf);
#endif
    last_block = address;
    last_offset = sd_offload_partial_end & 0x1ff;
    if(sd_offload_partial && sd_offload_partial_end != 512) {
      during_blocktrans = TRANS_MID;
    }
    sd_offload_partial = 0;
  } else if (during_blocktrans == TRANS_MID
             && last_block == address
             && last_offset == sd_offload_partial_start
             && sd_offload_partial) {
    sd_offload_partial_start |= 0x8000;
    stream_datablock(buf);
    during_blocktrans = TRANS_READ;
    last_offset = sd_offload_partial_end & 0x1ff;
    sd_offload_partial = 0;
  } else {
    if(during_blocktrans) {
//      uart_putc('_');
      DBG_SD_OFFLOAD printf("nonseq read (%lx -> %lx), restarting transmission\n", last_block, address);
      /* send STOP_TRANSMISSION to end an open READ/WRITE_MULTIPLE_BLOCK */
      cmd_fast(STOP_TRANSMISSION, 0, 0x61, NULL, rsp);
    }
    during_blocktrans = TRANS_READ;
    last_block = address;
    if(!ccs) {
      address <<= 9;
    }
#ifdef CONFIG_SD_DATACRC
    while(1) {
      if(cmd_fast(READ_MULTIPLE_BLOCK, address, 0, buf, rsp) != CRC_ERROR) break;
      cmd_fast(STOP_TRANSMISSION, 0, 0x61, NULL, rsp);
    };
#else
    cmd_fast(READ_MULTIPLE_BLOCK, address, 0, buf, rsp);
#endif
    sd_offload_partial = 0;
  }
//  printf("trans state = %d\n", during_blocktrans);
}

void write_block(uint32_t address, uint8_t* buf) {
  if(during_blocktrans == TRANS_WRITE && (last_block == address-1)) {
    wait_busy();
    send_datablock(buf);
    last_block=address;
  } else {
    if(during_blocktrans) {
      /* send STOP_TRANSMISSION to end an open READ/WRITE_MULTIPLE_BLOCK */
      cmd_fast(STOP_TRANSMISSION, 0, 0x61, NULL, rsp);
    }
    wait_busy();
    last_block=address;
    if(!ccs) {
      address <<= 9;
    }
    /* only send cmd & get response */
    cmd_fast(WRITE_MULTIPLE_BLOCK, address, 0, NULL, rsp);
    DBG_SD printf("write_block: CMD25 response = %02x%02x%02x%02x%02x%02x\n", rsp[0], rsp[1], rsp[2], rsp[3], rsp[4], rsp[5]);
    wiggle_fast_pos(8);
    send_datablock(buf);
    during_blocktrans = TRANS_WRITE;
  }
}

/* send STOP_TRANSMISSION after multiple block write
 * and reset during_blocktrans status */

void flush_write(void) {
  cmd_fast(STOP_TRANSMISSION, 0, 0x61, NULL, rsp);
  wait_busy();
  during_blocktrans = TRANS_NONE;
}

//
// Public functions
//

DRESULT sdn_ioctl(BYTE drv, BYTE cmd, void *buffer) {
  DRESULT res;
  if(drv >= MAX_CARDS) {
    res = STA_NOINIT|STA_NODISK;
  } else {
    switch(cmd) {
      case CTRL_SYNC:
        flush_write();
        res = RES_OK;
        break;

      default:
        res = RES_PARERR;
    }
  }
  return res;
}
DRESULT disk_ioctl(BYTE drv, BYTE cmd, void *buffer) __attribute__ ((weak, alias("sdn_ioctl")));

DRESULT sdn_read(BYTE drv, BYTE *buffer, DWORD sector, UINT count) {
  uint8_t sec;
  if(drv >= MAX_CARDS) {
    return RES_PARERR;
  }
  readled(1);
  for(sec=0; sec<count; sec++) {
    read_block(sector+sec, buffer);
    buffer+=512;
  }
  readled(0);
  return RES_OK;
}
DRESULT disk_read(BYTE drv, BYTE *buffer, DWORD sector, UINT count) __attribute__ ((weak, alias("sdn_read")));

DSTATUS sdn_initialize(BYTE drv) {

  uint8_t rsp[17]; /* space for response */
  int rsplen;
  uint8_t hcs=0;
  rca = 0;
  if(drv>=MAX_CARDS) {
    return STA_NOINIT|STA_NODISK;
  }

  if(sdn_status(drv) & STA_NODISK) {
    return STA_NOINIT|STA_NODISK;
  }
  /* if the card is sending data from before a reset we try to deselect it
     prior to initialization */
  for(rsplen=0; rsplen<2042; rsplen++) {
    if(!(BITBAND(SD_DAT3REG->FIOPIN, SD_DAT3PIN))) {
      printf("card seems to be sending data, attempting deselect\n");
      cmd_slow(SELECT_CARD, 0, 0, NULL, rsp);
    }
    wiggle_slow_neg(1);
  }
  printf("sd_init start\n");
  BITBAND(SD_DAT3REG->FIODIR, SD_DAT3PIN) = 1;
  BITBAND(SD_DAT3REG->FIOSET, SD_DAT3PIN) = 1;
  cmd_slow(GO_IDLE_STATE, 0, 0x95, NULL, rsp);

  if((rsplen=cmd_slow(SEND_IF_COND, 0x000001aa, 0x87, NULL, rsp))) {
    DBG_SD printf("CMD8 response:\n");
    DBG_SD uart_trace(rsp, 0, rsplen);
    hcs=1;
  }
  while(1) {
    if(!(acmd_slow(SD_SEND_OP_COND, (hcs << 30) | 0xfc0000, 0, NULL, rsp))) {
      printf("ACMD41 no response!\n");
    }
    if(rsp[1]&0x80) break;
  }

  BITBAND(SD_DAT3REG->FIODIR, SD_DAT3PIN) = 0;
  BITBAND(SD_DAT3REG->FIOCLR, SD_DAT3PIN) = 1;

  ccs = (rsp[1]>>6) & 1; /* SDHC/XC */

  cmd_slow(ALL_SEND_CID, 0, 0x4d, NULL, rsp);
  if(cmd_slow(SEND_RELATIVE_ADDR, 0, 0x21, NULL, rsp)) {
    rca=(rsp[1]<<24) | (rsp[2]<<16);
    printf("RCA: %04lx\n", rca>>16);
  } else {
    printf("CMD3 no response!\n");
    rca=0;
  }

  /* record CSD for getinfo */
  cmd_slow(SEND_CSD, rca, 0, NULL, csd);
  sdn_getinfo(drv, 0, &di);

  /* record CID */
  cmd_slow(SEND_CID, rca, 0, NULL, cid);

  /* select the card */
  if(cmd_slow(SELECT_CARD, rca, 0, NULL, rsp)) {
    printf("card selected!\n");
  } else {
    printf("CMD7 no response!\n");
  }

  /* get card status */
  cmd_slow(SEND_STATUS, rca, 0, NULL, rsp);

  /* set bus width */
  acmd_slow(SD_SET_BUS_WIDTH, 0x2, 0, NULL, rsp);

  /* set block length */
  cmd_slow(SET_BLOCKLEN, 0x200, 0, NULL, rsp);

  printf("SD init complete. SDHC/XC=%d\n", ccs);
  disk_state = DISK_OK;
  during_blocktrans = TRANS_NONE;
  return sdn_status(drv);
}

DSTATUS disk_initialize(BYTE drv) __attribute__ ((weak, alias("sdn_initialize")));

void sdn_init(void) {
  /* enable GPIO interrupt on SD detect pin, both edges */
/*  NVIC_EnableIRQ(EINT3_IRQn);
  SD_DT_INT_SETUP(); */
  /* disconnect SSP1 */
  LPC_PINCON->PINSEL0 &= ~(BV(13) | BV(15) | BV(17) | BV(19));
  /* prepare GPIOs */
  BITBAND(SD_DAT3REG->FIODIR, SD_DAT3PIN) = 0;
  BITBAND(SD_DAT2REG->FIODIR, SD_DAT2PIN) = 0;
  BITBAND(SD_DAT1REG->FIODIR, SD_DAT1PIN) = 0;
  BITBAND(SD_DAT0REG->FIODIR, SD_DAT0PIN) = 0;
  BITBAND(SD_CLKREG->FIODIR, SD_CLKPIN) = 1;
  BITBAND(SD_CMDREG->FIODIR, SD_CMDPIN) = 1;
  BITBAND(SD_CMDREG->FIOPIN, SD_CMDPIN) = 1;
  LPC_PINCON->PINMODE0 &= ~(BV(14) | BV(15));
  LPC_GPIO2->FIOPIN0 = 0x00;
  LPC_GPIO2->FIOMASK0 = ~0xf;
}
void disk_init(void) __attribute__ ((weak, alias("sdn_init")));


DSTATUS sdn_status(BYTE drv) {
  DSTATUS status = 0;
  if (SDCARD_DETECT) {
    if (disk_state == DISK_CHANGED) {
      status |= STA_NOINIT;
    }
    if (SDCARD_WP) {
      status |= STA_PROTECT;
    }
  } else {
    status |= STA_NODISK;
  }
  return status;
}
DSTATUS disk_status(BYTE drv) __attribute__ ((weak, alias("sdn_status")));

DRESULT sdn_getinfo(BYTE drv, BYTE page, void *buffer) {
  uint32_t capacity;

  if (drv >= MAX_CARDS) {
    return RES_NOTRDY;
  }
  if (sdn_status(drv) & STA_NODISK) {
    return RES_NOTRDY;
  }
  if (page != 0) {
    return RES_ERROR;
  }
  if (ccs) {
    /* Special CSD for SDHC cards */
    capacity = (1 + getbits(csd,127-69+8,22)) * 1024;
  } else {
    /* Assume that MMC-CSD 1.0/1.1/1.2 and SD-CSD 1.1 are the same... */
    uint8_t exponent = 2 + getbits(csd, 127-49+8, 3);
    capacity = 1 + getbits(csd, 127-73+8, 12);
    exponent += getbits(csd, 127-83+8,4) - 9;
    while (exponent--) capacity *= 2;
  }

  diskinfo0_t *di = buffer;
  di->validbytes  = sizeof(diskinfo0_t);
  di->disktype    = DISK_TYPE_SD;
  di->sectorsize  = 2;
  di->sectorcount = capacity;

  printf("card capacity: %lu sectors\n", capacity);
  return RES_OK;
}
DRESULT disk_getinfo(BYTE drv, BYTE page, void *buffer) __attribute__ ((weak, alias("sdn_getinfo")));

DRESULT sdn_write(BYTE drv, const BYTE *buffer, DWORD sector, UINT count) {
  uint8_t sec;
  uint8_t *buf = (uint8_t*)buffer;
  if(drv >= MAX_CARDS) {
    return RES_NOTRDY;
  }
  if (sdn_status(drv) & STA_NODISK) {
    return RES_NOTRDY;
  }
  writeled(1);
  for(sec=0; sec<count; sec++) {
    write_block(sector+sec, buf);
    buf+=512;
  }
  writeled(0);
  return RES_OK;
}

DRESULT disk_write(BYTE drv, const BYTE *buffer, DWORD sector, UINT count) __attribute__ ((weak, alias("sdn_write")));

/* Detect changes of SD card 0 */
void sdn_changed() {
  if (sd_changed) {
    printf("ch ");
    if(SDCARD_DETECT) {
      disk_state = DISK_CHANGED;
    } else {
      disk_state = DISK_REMOVED;
    }
    sd_changed = 0;
  }
}

/* measure sd access time */
void sdn_gettacc(uint32_t *tacc_max, uint32_t *tacc_avg) {
  uint32_t sec1 = 0;
  uint32_t sec2 = 0;
  uint32_t time, time_max = 0;
  uint32_t time_avg = 0LL;
  uint32_t numread = 16384;
  int i;
  int sec_step = di.sectorcount / numread - 1;
  if(disk_state == DISK_REMOVED) return;
  sdn_checkinit(0);
  for (i=0; i < 128; i++) {
    sd_offload_tgt=2;
    sd_offload=1;
    sdn_read(0, NULL, 0, 1);
    sd_offload_tgt=2;
    sd_offload=1;
    sdn_read(0, NULL, i*sec_step, 1);
  }
  for (i=0; i < numread && (snes_get_mcu_cmd() == SNES_CMD_SYSINFO) && disk_state != DISK_REMOVED; i++) {
  /* reset timer */
    LPC_RIT->RICTRL = 0;
    sd_offload_tgt=2;
    sd_offload=1;
    sdn_read(0, NULL, sec1, 2);
    sec1 += 2;
  /* start timer */
    LPC_RIT->RICOUNTER = 0;
    LPC_RIT->RICTRL = BV(RITEN);
    sd_offload_tgt=2;
    sd_offload=1;
    sdn_read(0, NULL, sec2, 1);
  /* read timer */
    time = LPC_RIT->RICOUNTER;
/*    sd_offload_tgt=2;
    sd_offload=1;
    sdn_read(0, NULL, sec2, 15);*/
    time_avg += time/16;
    if(time > time_max) {
      time_max = time;
    }
    sec2 += sec_step;
  }
  time_avg = time_avg / (i+1) * 16;
  sd_offload=0;
  LPC_RIT->RICTRL = 0;
  if(disk_state != DISK_REMOVED) {
    *tacc_max = time_max/(CONFIG_CPU_FREQUENCY / 1000000)-114;
    *tacc_avg = time_avg/(CONFIG_CPU_FREQUENCY / 1000000)-114;
  }
}

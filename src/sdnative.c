#include <arm/NXP/LPC17xx/LPC17xx.h>
#include <arm/bits.h>
#include <stdio.h>
#include "config.h"
#include "crc.h"
#include "diskio.h"
#include "spi.h"
#include "timer.h"
#include "uart.h"
#include "led.h"
#include "sdnative.h"
#include "fileops.h"

#define MAX_CARDS 1

// SD/MMC commands
#define GO_IDLE_STATE           0
#define SEND_OP_COND            1
#define SWITCH_FUNC             6
#define SEND_IF_COND            8
#define SEND_CSD                9
#define SEND_CID               10
#define STOP_TRANSMISSION      12
#define SEND_STATUS            13
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

#define SD_CLKREG LPC_GPIO0
#define SD_CMDREG LPC_GPIO0
#define SD_DAT0REG LPC_GPIO0
#define SD_DAT1REG LPC_GPIO1
#define SD_DAT2REG LPC_GPIO1
#define SD_DAT3REG LPC_GPIO0

#define SD_CLKPIN (7)
#define SD_CMDPIN (9)
#define SD_DAT0PIN (8)
#define SD_DAT1PIN (14)
#define SD_DAT2PIN (15)
#define SD_DAT3PIN (6)

/*
    1 DAT3/SS   P0.6
    2 CMD/DI    P0.9
    5 Clock     P0.7
    7 DAT0/DO   P0.8
    8 DAT1/IRQ  P1.14
    9 DAT2/NC   P1.15
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
uint8_t ccs=0;
uint8_t rca1, rca2;

int during_blocktrans = 0;
uint32_t last_block = 0;

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

static inline void wiggle_slow_pos(uint16_t times) {
  while(times--) {
    delay_us(5);
    BITBAND(SD_CLKREG->FIOSET, SD_CLKPIN) = 1;
    delay_us(5);
    BITBAND(SD_CLKREG->FIOCLR, SD_CLKPIN) = 1;
  }
}

static inline void wiggle_slow_neg(uint16_t times) {
  while(times--) {
    delay_us(5);
    BITBAND(SD_CLKREG->FIOCLR, SD_CLKPIN) = 1;
    delay_us(5);
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


/* 
   send_command_slow
   send SD command and put response in rsp.
   returns length of response or 0 if there was no response
*/
int send_command_slow(uint8_t* cmd, uint8_t* rsp){
  uint8_t shift, i=6;
  int rsplen;
//  printf("send_command_slow: sending CMD:\n");
  wiggle_slow_pos(5);
//  uart_trace(cmd, 0, 6);
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
    /* wait for responsebob */
    while((BITBAND(SD_CMDREG->FIOPIN, SD_CMDPIN)) && --timeout) {
      wiggle_slow_neg(1);
    }
  //  printf("timeout=%d\n", timeout);  
    if(!timeout) {
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
  int rsplen, dat=0, datcnt=512, j=0;
  static int state=0;
//  printf("send_command_fast: sending CMD:\n");
  wiggle_fast_pos(5);
//  uart_trace(cmd, 0, 6);
  switch(*cmd & 0x3f) {
    case 0:
      rsplen = 0;
      break;
    case 2:
    case 9:
    case 10:
      rsplen = 17;
      break;
    case 17:
    case 18:
      dat = 1;
    default:
      rsplen = 6;
  }

  if(dat && (buf==NULL)) {
    printf("error: buf is null but data transfer expected.\n");
    return 0;
  }
  /* send command */
  BITBAND(SD_CMDREG->FIODIR, SD_CMDPIN) = 1;

  while(i--) {
    cmdshift = 8;
    do {
      cmdshift--;
      uint8_t data = *cmd;
      *cmd<<=1;
      if(data&0x80) {
        BITBAND(SD_CMDREG->FIOSET, SD_CMDPIN) = 1;
      } else {
        BITBAND(SD_CMDREG->FIOCLR, SD_CMDPIN) = 1;
      }
      wiggle_fast_pos(1);
    } while (cmdshift);
    cmd++;
  }

  wiggle_fast_pos(1);
  BITBAND(SD_CMDREG->FIODIR, SD_CMDPIN) = 0;
  
  if(rsplen) {
    uint16_t timeout=65535;
    /* wait for responsebob */
    while((BITBAND(SD_CMDREG->FIOPIN, SD_CMDPIN)) && --timeout) {
      wiggle_fast_neg(1);
    }
  //  printf("timeout=%d\n", timeout);  
    if(!timeout) {
      return 0; /* no response within timeout */
    }

    i=rsplen;
    uint8_t cmddata=0, datdata=0;
    while(i--) { /* process response */
      cmdshift = 8;
      do {
	if(dat) {
          if(!(BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN))) {
//            printf("data start\n");
            j=datcnt;
            state=1;
            break;
          }
        }
        cmdshift--;
        cmddata |= (BITBAND(SD_CMDREG->FIOPIN, SD_CMDPIN)) << cmdshift;
        wiggle_fast_neg(1);
      } while (cmdshift);
      if(state==1)break;
      *rsp=cmddata;
      cmddata=0;
      rsp++;
    }

    if(state==1) { /* process response+data */
      int startbit=1;
      printf("processing rsp+data cmdshift=%d i=%d j=%d\n", cmdshift, i, j);
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
            printf("response end\n");
            if(j) state=2; /* response over, remaining data */
            break;
          }
        }
        if(!startbit) {
          datshift--;
          datdata |= (BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN)) << datshift;
      
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
        wiggle_fast_neg(1);
      }
    }

    if(dat && state!=2) { /* response ended before data */
      state=2;
      j=datcnt;
      datshift=8;
//      printf("response over, waiting for data...\n");
      while((BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN)) && --timeout) {
        wiggle_fast_neg(1);
      }
      wiggle_fast_neg(1); /* eat the start bit */
    }
    
    if(state==2) { /* transfer rest of data */
//      printf("remaining data: %d\n", j);
      while(1) {
        datshift-=4;
        datdata |= ((BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN))
                    |((SD_DAT1REG->FIOPIN >> 13) & 0x6)
                    |((BITBAND(SD_DAT3REG->FIOPIN, SD_DAT3PIN)) << 3)) << datshift;
        if(!datshift) {
          datshift=8;
          *buf=datdata;
          datdata=0;
          buf++;
          j--;
          if(!j) break;
        }
        wiggle_fast_neg(1);
      }
    }
    /* just eat the crcs for now */
    wiggle_fast_neg(17);
    state=3;
  }
  return rsplen;
}


void make_crc7(uint8_t* cmd) {
  cmd[5]=crc7update(0, cmd[0]);
  cmd[5]=crc7update(cmd[5], cmd[1]);
  cmd[5]=crc7update(cmd[5], cmd[2]);
  cmd[5]=crc7update(cmd[5], cmd[3]);
  cmd[5]=crc7update(cmd[5], cmd[4]);
  cmd[5]=(cmd[5] << 1) | 1;
}

void stream_datablock(uint8_t* buf) {
  uint8_t datshift=8;
  int j=512;
  uint8_t datdata=0;
  uint16_t timeout=65535;

  while((BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN)) && --timeout) {
    wiggle_fast_neg(1);
  }
  wiggle_fast_neg(1); /* eat the start bit */

  while(1) {
    datshift-=4;
    datdata |= ((BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN))
                |((SD_DAT1REG->FIOPIN >> 13) & 0x6)
                |((BITBAND(SD_DAT3REG->FIOPIN, SD_DAT3PIN)) << 3)) << datshift;
    if(!datshift) {
      datshift=8;
      *buf=datdata;
      datdata=0;
      buf++;
      j--;
      if(!j) break;
    }
    wiggle_fast_neg(1);
  }

  /* eat the crc for now */ 
  wiggle_fast_neg(17);
}

void read_block(uint32_t address, uint8_t* buf) {
  if(during_blocktrans && (last_block == address-1)) {
    stream_datablock(buf);
    last_block=address;
  } else {
    if(during_blocktrans) {
      /* send STOP_TRANSMISSION */ 
      cmd[0]=0x40+STOP_TRANSMISSION;
      cmd[1]=0;
      cmd[2]=0;
      cmd[3]=0;
      cmd[4]=0;
      cmd[5]=0x61;
      send_command_fast(cmd, rsp, NULL);
    }
    last_block=address;
    if(!ccs) address <<= 9;
    cmd[0]=0x40+READ_MULTIPLE_BLOCK;
    cmd[1]=address>>24;
    cmd[2]=address>>16;
    cmd[3]=address>>8;
    cmd[4]=address;
    make_crc7(cmd);
    send_command_fast(cmd, rsp, buf);
//    uart_trace(cmd, 0, 6);
//    uart_trace(rsp, 0, rsplen);
    during_blocktrans = 1;
  }
//  uart_trace(buf, 0, 512);
}

//
// Public functions
//

DRESULT sdn_read(BYTE drv, BYTE *buffer, DWORD sector, BYTE count) {
  uint8_t sec;
  if(drv >= MAX_CARDS) {
    return RES_PARERR;
  }
  for(sec=0; sec<count; sec++) {
    read_block(sector+sec, buffer);
    buffer+=512;
  }
  return RES_OK;
}
DRESULT disk_read(BYTE drv, BYTE *buffer, DWORD sector, BYTE count) __attribute__ ((weak, alias("sdn_read")));

DRESULT sdn_initialize(BYTE drv) {

  uint8_t cmd[6]={0,0,0,0,0,0}; /* command */
  uint8_t rsp[17]; /* space for response */
  int rsplen;
  uint8_t hcs=0, data;
  if(drv>=MAX_CARDS)
    return STA_NOINIT|STA_NODISK;

  data=BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN);
  /* if the card is sending data from before a reset we try to deselect it
     prior to initialization */
  for(rsplen=0; rsplen<1042; rsplen++) {
    if((data != BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN))) {
      printf("card seems to be sending data, attempting deselect\n");
      cmd[0]=0x40+7;
      cmd[1]=0;
      cmd[2]=0;
      cmd[3]=0;
      cmd[4]=0;
      make_crc7(cmd);
      if(send_command_slow(cmd, rsp)) {
        printf("card was sending data, CMD7 succeeded\n");
      } else {
        printf("CMD7 deselect no response! D:\n");
      }
    }
    data=BITBAND(SD_DAT0REG->FIOPIN, SD_DAT0PIN);
    wiggle_slow_neg(1);
  }
  cmd[0]=0x40+GO_IDLE_STATE;
  cmd[5]=0x95;
  printf("sd_init start\n");  
  if((rsplen=send_command_slow(cmd, rsp))) {
//    printf("CMD0 response?!:\n");
//    uart_trace(rsp, 0, rsplen);
  }

  wiggle_slow_pos(1000);
  cmd[0]=0x40+SEND_IF_COND;
  cmd[3]=0x01;
  cmd[4]=0xaa;
  cmd[5]=0x87;
  if((rsplen=send_command_slow(cmd, rsp))) {
//    uart_trace(cmd, 0, 6);
//    printf("CMD8 response:\n");
//    uart_trace(rsp, 0, rsplen);
    hcs=1;
  }
  while(1) {
    cmd[0]=0x40+APP_CMD;
    cmd[1]=0;
    cmd[2]=0;
    cmd[3]=0;
    cmd[4]=0;
    cmd[5]=0x65;

    if((rsplen=send_command_slow(cmd, rsp))) {
//      printf("CMD55 response:\n");
//      uart_trace(rsp, 0, rsplen);
    } else {
      printf("CMD55 no response!\n");
    }

    cmd[0]=0x40+41;
    cmd[1]=hcs<<6;
    cmd[2]=0xfc; /* 2.7-3.6V */
    cmd[3]=0x00;
    cmd[4]=0x00;
    cmd[5]=hcs ? 0x53 : 0xc1;
//    printf("send ACMD41 hcs=%d\n", hcs);
    if((rsplen=send_command_slow(cmd, rsp))) {
//      printf("ACMD41 response:\n");
//      uart_trace(rsp, 0, rsplen);
//      printf("busy=%d\n ccs=%d\n", rsp[1]>>7, (rsp[1]>>6)&1);
    } else {
      printf("ACMD41 no response!\n");
    }
    if(rsp[1]&0x80) break;
  }

  ccs = (rsp[1]>>6) & 1; /* SDHC */

  cmd[0]=0x40+2;
  cmd[1]=0;
  cmd[2]=0;
  cmd[3]=0;
  cmd[4]=0;
  cmd[5]=0x4d;

  if((rsplen=send_command_slow(cmd, rsp))) {
//    printf("CMD2 response:\n");
//    uart_trace(rsp, 0, rsplen);
  } else {
    printf("CMD2 no response!\n");
  }

  cmd[0]=0x40+3;
  cmd[1]=0;
  cmd[2]=0;
  cmd[3]=0;
  cmd[4]=0;
  cmd[5]=0x21;

  if((rsplen=send_command_slow(cmd, rsp))) {
//    printf("CMD3 response:\n"); 
//    uart_trace(rsp, 0, rsplen);
    rca1=rsp[1];
    rca2=rsp[2];
//    printf("RCA: %02x%02x\n", rca1, rca2);
  } else {
    printf("CMD3 no response!\n");
    rca1=0;
    rca2=0;
  }

  cmd[0]=0x40+9;
  cmd[1]=rca1;
  cmd[2]=rca2;
  cmd[3]=0;
  cmd[4]=0;
  make_crc7(cmd);

  if((rsplen=send_command_slow(cmd, csd))) {
//    printf("CMD9 response:\n");
//    uart_trace(rsp, 0, rsplen);
  } else {
    printf("CMD9 no response!\n");
  }

  cmd[0]=0x40+7;
  cmd[1]=rca1;
  cmd[2]=rca2;
  cmd[3]=0;
  cmd[4]=0;
  make_crc7(cmd);

  if((rsplen=send_command_slow(cmd, rsp))) {
//    printf("CMD7 response:\n");
//    uart_trace(rsp, 0, rsplen);
    printf("card selected!\n");
  } else {
    printf("CMD7 no response!\n");
  }

  cmd[0]=0x40+13;
  cmd[1]=rca1;
  cmd[2]=rca2;
  cmd[3]=0;
  cmd[4]=0;
  make_crc7(cmd);

  if((rsplen=send_command_fast(cmd, rsp, NULL))) {
//    printf("CMD13 response:\n");
//    uart_trace(rsp, 0, rsplen);
  } else {
    printf("CMD13 no response!\n");
  }

  cmd[0]=0x40+55;
  cmd[1]=rca1;
  cmd[2]=rca2;
  cmd[3]=0;
  cmd[4]=0;
  make_crc7(cmd);

  if((rsplen=send_command_slow(cmd, rsp))) {
//      printf("CMD55 response:\n");
//      uart_trace(rsp, 0, rsplen);
  } else {
    printf("CMD55 no response!\n");
  }

  cmd[0]=0x40+6;
  cmd[1]=0;
  cmd[2]=0;
  cmd[3]=0;
  cmd[4]=2;
  make_crc7(cmd);
  if((rsplen=send_command_slow(cmd, rsp))) {
//      printf("CMD55 response:\n");
//      uart_trace(rsp, 0, rsplen);
  } else {
    printf("ACMD6 no response!\n");
  }

/*  int i;
  printf("start 4MB streaming test\n");
  for(i=0; i<8192; i++) {
    read_block(i, file_buf);
  }
  printf("end 4MB streaming test\n");*/
  printf("SD init complete. SDHC/XC=%d\n", ccs);

  return sdn_status(drv);
}

DSTATUS disk_initialize(BYTE drv) __attribute__ ((weak, alias("sdn_initialize")));

void sdn_init(void) {
  /* enable GPIO interrupt on SD detect pin, both edges */
  NVIC_EnableIRQ(EINT3_IRQn);
  SD_DT_INT_SETUP();
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
}
void disk_init(void) __attribute__ ((weak, alias("sdn_init")));


DSTATUS sdn_status(BYTE drv) {
  if (SDCARD_DETECT)
    if (SDCARD_WP)
      return STA_PROTECT;
    else
      return RES_OK;
  else
    return STA_NOINIT|STA_NODISK;
}
DSTATUS disk_status(BYTE drv) __attribute__ ((weak, alias("sdn_status")));

DRESULT sdn_getinfo(BYTE drv, BYTE page, void *buffer) {
  uint32_t capacity;

  if (drv >= MAX_CARDS)
    return RES_NOTRDY;

  if (sdn_status(drv) & STA_NODISK)
    return RES_NOTRDY;

  if (page != 0)
    return RES_ERROR;

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
  return RES_OK;
}
DRESULT disk_getinfo(BYTE drv, BYTE page, void *buffer) __attribute__ ((weak, alias("sdn_getinfo")));

DRESULT sdn_write(BYTE drv, const BYTE *buffer, DWORD sector, BYTE count) {
  return RES_OK;
}
DRESULT disk_write(BYTE drv, const BYTE *buffer, DWORD sector, BYTE count) __attribute__ ((weak, alias("sdn_write")));

/* Detect changes of SD card 0 */
void sdn_changed() {
  if (SDCARD_DETECT)
    disk_state = DISK_CHANGED;
  else
    disk_state = DISK_REMOVED;
}


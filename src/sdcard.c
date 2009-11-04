/* sd2iec - SD/MMC to Commodore serial bus interface/controller
   Copyright (C) 2007-2009  Ingo Korb <ingo@akana.de>

   Inspiration and low-level SD/MMC access based on code from MMC2IEC
     by Lars Pontoppidan et al., see sdcard.c|h and config.h.

   FAT filesystem access based on code from ChaN and Jim Brain, see ff.c|h.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License only.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


   sdcard.c: SD/MMC access routines

   Extended, optimized and cleaned version of code from MMC2IEC,
   original copyright header follows:

//
// Title        : SD/MMC Card driver
// Author       : Lars Pontoppidan, Aske Olsson, Pascal Dufour,
// Date         : Jan. 2006
// Version      : 0.42
// Target MCU   : Atmel AVR Series
//
// CREDITS:
// This module is developed as part of a project at the technical univerisity of
// Denmark, DTU.
//
// DESCRIPTION:
// This SD card driver implements the fundamental communication with a SD card.
// The driver is confirmed working on 8 MHz and 14.7456 MHz AtMega32 and has
// been tested successfully with a large number of different SD and MMC cards.
//
// DISCLAIMER:
// The author is in no way responsible for any problems or damage caused by
// using this code. Use at your own risk.
//
// LICENSE:
// This code is distributed under the GNU Public License
// which can be found at http://www.gnu.org/licenses/gpl.txt
//

  The exported functions in this file are weak-aliased to their corresponding
  versions defined in diskio.h so when this file is the only diskio provider
  compiled in they will be automatically used by the linker.

*/

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <util/crc16.h>
#include "config.h"
#include "avrcompat.h"
#include "crc7.h"
#include "diskio.h"
#include "spi.h"
#include "uart.h"
#include "sdcard.h"

#ifndef TRUE
#define TRUE -1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#ifdef CONFIG_TWINSD
#  define MAX_CARDS 2
#else
#  define MAX_CARDS 1
#endif

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

static uint8_t cardtype[MAX_CARDS];

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

static uint8_t sdResponse(uint8_t expected)
{
  unsigned short count = 0x0FFF;

  while ((spiTransferByte(0xFF) != expected) && count )
    count--;

  // If count didn't run out, return success
  return (count != 0);
}

static uint8_t sdWaitWriteFinish(void)
{
  uint32_t count = 0x1FFFF; // wait for quite some time
  
  while ((spiTransferByte(0xFF) == 0) && count )
    count--;

  // If count didn't run out, return success
  return (count != 0);
}

static void deselectCard(uint8_t card) {
  // Send 8 clock cycles
  SPI_SS_HIGH(card);
  spiTransferByte(0xff);
}

/**
 * sendCommand - send a command to the SD card
 * @card     : card number to be accessed
 * @command  : command to be sent
 * @parameter: parameter to be sent
 * @deselect : Flags if the card should be deselected afterwards
 *
 * This function calculates the correct CRC7 for the command and
 * parameter and transmits all of it to the SD card. If requested
 * the card will be deselected afterwards.
 */
static int sendCommand(const uint8_t  card,
                       const uint8_t  command,
                       const uint32_t parameter,
                       const uint8_t  deselect) {
  union {
    uint32_t l;
    uint8_t  c[4];
  } long2char;

  uint8_t  i,crc=0,errorcount;
  uint16_t counter;

  long2char.l = parameter;
  crc = crc7update(0  , 0x40+command);
  crc = crc7update(crc, long2char.c[3]);
  crc = crc7update(crc, long2char.c[2]);
  crc = crc7update(crc, long2char.c[1]);
  crc = crc7update(crc, long2char.c[0]);
  crc = (crc << 1) | 1;

  errorcount = 0;
  while (errorcount < CONFIG_SD_AUTO_RETRIES) {
    // Select card
    SPI_SS_LOW(card);
#ifdef CONFIG_TWINSD
    if (card == 0 && command == GO_IDLE_STATE)
      /* Force both cards to SPI mode simultaneously */
      SPI_SS_LOW(1);
#endif

    // Transfer command
    spiTransferByte(0x40+command);
    spiTransferLong(parameter);
    spiTransferByte(crc);

    // Wait for a valid response
    counter = 0;
    do {
      i = spiTransferByte(0xff);
      counter++;
    } while (i & 0x80 && counter < 0x1000);

#ifdef CONFIG_TWINSD
    if (card == 0 && command == GO_IDLE_STATE)
      SPI_SS_HIGH(1);
#endif

    // Check for CRC error
    // can't reliably retry unless deselect is allowed
    if (deselect && (i & STATUS_CRC_ERROR)) {
      uart_putc('x');
      deselectCard(card);
      errorcount++;
      continue;
    }

    if (deselect) deselectCard(card);
    break;
  }

  return i;
}

// Extended init sequence for SDHC support
static uint8_t extendedInit(const uint8_t card) {
  uint8_t  i;
  uint32_t answer;

  // Send CMD8: SEND_IF_COND
  //   0b000110101010 == 2.7-3.6V supply, check pattern 0xAA
  i = sendCommand(card, SEND_IF_COND, 0b000110101010, 0);
  if (i > 1) {
    // Card returned an error, ok (MMC oder SD1.x) but not SDHC
    deselectCard(card);
    return TRUE;
  }

  // No error, continue SDHC initialization
  answer = spiTransferLong(0);
  deselectCard(card);

  if (((answer >> 8) & 0x0f) != 0b0001) {
    // Card didn't accept our voltage specification
    return FALSE;
  }

  // Verify echo-back of check pattern
  if ((answer & 0xff) != 0b10101010) {
    // Check pattern mismatch, working but not SD2.0 compliant
    // The specs say we should not use the card, but let's try anyway.
    return TRUE;
  }

  return TRUE;
}

// SD common initialisation
static void sdInit(const uint8_t card) {
  uint8_t i;
  uint16_t counter;

  counter = 0xffff;
  do {
    // Prepare for ACMD, send CMD55: APP_CMD
    i = sendCommand(card, APP_CMD, 0, 1);
    if (i > 1) {
      // Command not accepted, could be MMC
      return;
    }

    // Send ACMD41: SD_SEND_OP_COND
    //   1L<<30 == Host has High Capacity Support
    i = sendCommand(card, SD_SEND_OP_COND, 1L<<30, 1);
    // Repeat while card card accepts command but isn't ready
  } while (i == 1 && --counter > 0);

  // Ignore failures, there is at least one Sandisk MMC card
  // that accepts CMD55, but not ACMD41.
  if (i == 0)
    /* We know that a card is SD if ACMD41 was accepted. */
    cardtype[card] |= CARD_SD;
}

/* Detect changes of SD card 0 */
#ifdef SD_CHANGE_VECT
ISR(SD_CHANGE_VECT) {
  if (SDCARD_DETECT)
    disk_state = DISK_CHANGED;
  else
    disk_state = DISK_REMOVED;
}
#endif

#ifdef CONFIG_TWINSD
/* Detect changes of SD card 1 */
ISR(SD2_CHANGE_VECT) {
  if (SD2_DETECT)
    disk_state = DISK_CHANGED;
  else
    disk_state = DISK_REMOVED;
}
#endif

//
// Public functions
//
void sd_init(void) {
  SDCARD_DETECT_SETUP();
  SDCARD_WP_SETUP();
  SD_CHANGE_SETUP();
#ifdef CONFIG_TWINSD
  /* Initialize the control lines for card 2 */
  SD2_SETUP();
  SD2_CHANGE_SETUP();
#endif
}
void disk_init(void) __attribute__ ((weak, alias("sd_init")));


DSTATUS sd_status(BYTE drv) {
#ifdef CONFIG_TWINSD
  if (drv != 0) {
    if (SD2_DETECT) {
      if (SD2_PIN & SD2_WP) {
        return STA_PROTECT;
      } else {
        return RES_OK;
      }
    } else {
      return STA_NOINIT|STA_NODISK;
    }
  } else
#endif
  if (SDCARD_DETECT) {
//	uart_putc('0');
    if (SDCARD_WP) {
//	  uart_putc('1');
      return STA_PROTECT;
    } else {
//	  uart_putc('2');
      return RES_OK;
    }
  } else {
//    uart_putc('3');
    return STA_NOINIT|STA_NODISK;
  }
}
DSTATUS disk_status(BYTE drv) __attribute__ ((weak, alias("sd_status")));


/**
 * sd_initialize - initialize SD card
 * @drv   : drive
 *
 * This function tries to initialize the selected SD card.
 */
DSTATUS sd_initialize(BYTE drv) {
  uint8_t  i;
  uint16_t counter;
  uint32_t answer;

  if (drv >= MAX_CARDS)
    return STA_NOINIT|STA_NODISK;

  /* Don't bother initializing a card that isn't there */
//  uart_putc('#');
  if (sd_status(drv) & STA_NODISK)
    return sd_status(drv);

  /* JLB: Should be in sd_init, but some uIEC versions have
   * IEC lines tied to SPI, so I moved it here to resolve the
   * conflict.
   */
  spiInit();

  disk_state = DISK_ERROR;

  cardtype[drv] = 0;

  SPI_SS_HIGH(drv);

  // Send 80 clks
  for (i=0; i<10; i++) {
    spiTransferByte(0xFF);
  }

  // Reset card
  i = sendCommand(drv, GO_IDLE_STATE, 0, 1);
  if (i != 1) {
    return STA_NOINIT | STA_NODISK;
  }

  if (!extendedInit(drv))
    return STA_NOINIT | STA_NODISK;

  sdInit(drv);

  counter = 0xffff;
  // According to the spec READ_OCR should work at this point
  // without retries. One of my Sandisk-cards thinks otherwise.
  do {
    // Send CMD58: READ_OCR
    i = sendCommand(drv, READ_OCR, 0, 0);
    if (i > 1)
      deselectCard(drv);
  } while (i > 1 && counter-- > 0);

  if (counter > 0) {
    answer = spiTransferLong(0);

    // See if the card likes our supply voltage
    if (!(answer & SD_SUPPLY_VOLTAGE)) {
      // The code isn't set up to completely ignore the card,
      // but at least report it as nonworking
      deselectCard(drv);
      return STA_NOINIT | STA_NODISK;
    }

    // See what card we've got
    if (answer & 0x40000000) {
      cardtype[drv] |= CARD_SDHC;
    }
  }

  // Keep sending CMD1 (SEND_OP_COND) command until zero response
  counter = 0xffff;
  do {
    i = sendCommand(drv, SEND_OP_COND, 1L<<30, 1);
    counter--;
  } while (i != 0 && counter > 0);

  if (counter==0) {
    return STA_NOINIT | STA_NODISK;
  }

#ifdef CONFIG_SD_DATACRC
  // Enable CRC checking
  // The SD spec says that the host "should" send CRC_ON_OFF before ACMD_SEND_OP_COND.
  // The MMC manual I have says that CRC_ON_OFF isn't allowed before SEND_OP_COND.
  // Let's just hope that all SD cards work with this order. =(
  i = sendCommand(drv, CRC_ON_OFF, 1, 1);
  if (i > 1) {
    return STA_NOINIT | STA_NODISK;
  }
#endif

  // Send MMC CMD16(SET_BLOCKLEN) to 512 bytes
  i = sendCommand(drv, SET_BLOCKLEN, 512, 1);
  if (i != 0) {
    return STA_NOINIT | STA_NODISK;
  }

  // Thats it!
  disk_state = DISK_OK;
  return sd_status(drv);
}
DSTATUS disk_initialize(BYTE drv) __attribute__ ((weak, alias("sd_initialize")));


/**
 * sd_read - reads sectors from the SD card to buffer
 * @drv   : drive
 * @buffer: pointer to the buffer
 * @sector: first sector to be read
 * @count : number of sectors to be read
 *
 * This function reads count sectors from the SD card starting
 * at sector to buffer. Returns RES_ERROR if an error occured or
 * RES_OK if successful. Up to SD_AUTO_RETRIES will be made if
 * the calculated data CRC does not match the one sent by the
 * card. If there were errors during the command transmission
 * disk_state will be set to DISK_ERROR and no retries are made.
 */
DRESULT sd_read(BYTE drv, BYTE *buffer, DWORD sector, BYTE count) {
  uint8_t sec,res,tmp,errorcount;
  uint16_t crc,recvcrc;

  if (drv >= MAX_CARDS)
    return RES_PARERR;

  for (sec=0;sec<count;sec++) {
    errorcount = 0;
    while (errorcount < CONFIG_SD_AUTO_RETRIES) {
      if (cardtype[drv] & CARD_SDHC)
        res = sendCommand(drv, READ_SINGLE_BLOCK, sector+sec, 0);
      else
        res = sendCommand(drv, READ_SINGLE_BLOCK, (sector+sec) << 9, 0);

      if (res != 0) {
		uart_putc('?');
        SPI_SS_HIGH(drv);
        disk_state = DISK_ERROR;
        return RES_ERROR;
      }

      // Wait for data token
      if (!sdResponse(0xFE)) {
		uart_putc('-');
        SPI_SS_HIGH(drv);
        disk_state = DISK_ERROR;
        return RES_ERROR;
      }

      uint16_t i;
#ifdef CONFIG_SD_DATACRC
      BYTE *oldbuffer = buffer;
#endif

      // Get data
      crc = 0;
      // Initiate data exchange over SPI
      SPDR = 0xff;

      for (i=0; i<512; i++) {
        // Wait until data has been received
        loop_until_bit_is_set(SPSR, SPIF);
        tmp = SPDR;
        // Transmit the next byte while we store the current one
        SPDR = 0xff;

        *(buffer++) = tmp;
#ifdef CONFIG_SD_DATACRC
        crc = _crc_xmodem_update(crc, tmp);
#endif
      }
      // Wait until the first CRC byte is received
      loop_until_bit_is_set(SPSR, SPIF);

      // Check CRC
      recvcrc = (SPDR << 8) + spiTransferByte(0xff);
#ifdef CONFIG_SD_DATACRC
      if (recvcrc != crc) {
        uart_putc('X');
        deselectCard(drv);
        errorcount++;
        buffer = oldbuffer;
        continue;
      }
#endif

      break;
    }
    deselectCard(drv);

    if (errorcount >= CONFIG_SD_AUTO_RETRIES) return RES_ERROR;
  }

  return RES_OK;
}
DRESULT disk_read(BYTE drv, BYTE *buffer, DWORD sector, BYTE count) __attribute__ ((weak, alias("sd_read")));



/**
 * sd_write - writes sectors from buffer to the SD card
 * @drv   : drive
 * @buffer: pointer to the buffer
 * @sector: first sector to be written
 * @count : number of sectors to be written
 *
 * This function writes count sectors from buffer to the SD card
 * starting at sector. Returns RES_ERROR if an error occured,
 * RES_WPRT if the card is currently write-protected or RES_OK
 * if successful. Up to SD_AUTO_RETRIES will be made if the card
 * signals a CRC error. If there were errors during the command
 * transmission disk_state will be set to DISK_ERROR and no retries
 * are made.
 */
DRESULT sd_write(BYTE drv, const BYTE *buffer, DWORD sector, BYTE count) {
  uint8_t res,sec,errorcount,status;
  uint16_t crc;

  if (drv >= MAX_CARDS)
    return RES_PARERR;

#ifdef CONFIG_TWINSD
  if (drv != 0) {
    if (SD2_PIN & SD2_WP)
      return RES_WRPRT;
  } else
#endif

  if (SDCARD_WP) return RES_WRPRT;

  for (sec=0;sec<count;sec++) {
    errorcount = 0;
    while (errorcount < CONFIG_SD_AUTO_RETRIES) {
      if (cardtype[drv] & CARD_SDHC)
        res = sendCommand(drv, WRITE_BLOCK, sector+sec, 0);
      else
        res = sendCommand(drv, WRITE_BLOCK, (sector+sec)<<9, 0);

      if (res != 0) {
	uart_putc('C');
        SPI_SS_HIGH(drv);
        disk_state = DISK_ERROR;
        return RES_ERROR;
      }

      // Send data token
      spiTransferByte(0xFE);

      uint16_t i;
      const BYTE *oldbuffer = buffer;

      // Send data
      crc = 0;
      for (i=0; i<512; i++) {
#ifdef CONFIG_SD_DATACRC
        crc = _crc_xmodem_update(crc, *buffer);
#endif
        spiTransferByte(*(buffer++));
      }

      // Send CRC
      spiTransferByte(crc >> 8);
      spiTransferByte(crc & 0xff);

      // Get and check status feedback
      status = spiTransferByte(0xFF);

      // Retry if neccessary
      if ((status & 0x0F) != 0x05) {
        uart_putc('X');
        deselectCard(drv);
        errorcount++;
        buffer = oldbuffer;
        continue;
      }

      // Wait for write finish
      if (!sdWaitWriteFinish()) {
	uart_putc('W');
        SPI_SS_HIGH(drv);
        disk_state = DISK_ERROR;
        return RES_ERROR;
      }
      break;
    }
    deselectCard(drv);

    if (errorcount >= CONFIG_SD_AUTO_RETRIES) {
      if (!(status & STATUS_CRC_ERROR))
        disk_state = DISK_ERROR;
      return RES_ERROR;
    }
  }

  return RES_OK;
}
DRESULT disk_write(BYTE drv, const BYTE *buffer, DWORD sector, BYTE count) __attribute__ ((weak, alias("sd_write")));

DRESULT sd_getinfo(BYTE drv, BYTE page, void *buffer) {
  uint8_t i;
  uint8_t buf[18];
  uint32_t capacity;

  if (drv >= MAX_CARDS)
    return RES_NOTRDY;

  if (sd_status(drv) & STA_NODISK)
    return RES_NOTRDY;

  if (page != 0)
    return RES_ERROR;

  /* Try to calculate the total number of sectors on the card */
  /* FIXME: Write a generic data read function and merge with sd_read */
  if (sendCommand(drv, SEND_CSD, 0, 0) != 0) {
    deselectCard(drv);
    return RES_ERROR;
  }

  /* Wait for data token */
  if (!sdResponse(0xfe)) {
    deselectCard(drv);
    return RES_ERROR;
  }

  for (i=0;i<18;i++) {
    buf[i] = spiTransferByte(0xff);
  }
  deselectCard(drv);

  if (cardtype[drv] & CARD_SDHC) {
    /* Special CSD for SDHC cards */
    capacity = (1 + getbits(buf,127-69,22)) * 1024;
  } else {
    /* Assume that MMC-CSD 1.0/1.1/1.2 and SD-CSD 1.1 are the same... */
    uint8_t exponent = 2 + getbits(buf, 127-49, 3);
    capacity = 1 + getbits(buf, 127-73, 12);
    exponent += getbits(buf, 127-83,4) - 9;
    while (exponent--) capacity *= 2;
  }

  diskinfo0_t *di = buffer;
  di->validbytes  = sizeof(diskinfo0_t);
  di->disktype    = DISK_TYPE_SD;
  di->sectorsize  = 2;
  di->sectorcount = capacity;

  return RES_OK;
}
DRESULT disk_getinfo(BYTE drv, BYTE page, void *buffer) __attribute__ ((weak, alias("sd_getinfo")));

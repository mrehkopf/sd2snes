#include <string.h>
#include <stdlib.h>

#include "config.h"
#include "timer.h"
#include "uart.h"
#include "ff.h"
#include "ymodem.h"
#include "crc.h"

/* get byte with timeout, retry sending in timeout intervals */
uint8_t get_with_timeout(uint8_t retry_byte, tick_t timeout_ms) {
  tick_t start_time = getticks();
  uart_putc(retry_byte);
  while (!uart_gotc()) {
    if(getticks() - start_time > MS_TO_TICKS(timeout_ms)) {
      uart_putc(retry_byte);
      start_time = getticks();
    }
  }
  return uart_getc();
}

void ymodem_rxfile(FIL* fil) {
  uint8_t rxbuf[YMODEM_BLKSIZE_1K];
  uint8_t blknum, blknum_cmpl;
  uint16_t count;
  uint8_t c;
  uint32_t totalbytes = 0;
  uint32_t totalwritten = 0;
  int blocksize;
  UINT written;
  FRESULT res = FR_OK;
  uint16_t crc = 0, crc_sender;
  uint32_t filesize, remaining = 0;
  int have_filesize = 0, first_block = 1;
  uart_flush();
restart:
  first_block = 1;
  do {
    c = get_with_timeout(ASC_C, 3000);
  } while (c != ASC_SOH && c != ASC_STX);
  do {
    blocksize = (c == ASC_SOH) ? YMODEM_BLKSIZE : YMODEM_BLKSIZE_1K;
    blknum = uart_getc();
    blknum_cmpl = uart_getc();
    crc = 0x0000;
    for(count = 0; count < blocksize; count++) {
      crc = crc_xmodem_update(crc, rxbuf[count] = uart_getc());
      totalbytes++;
    }
    crc_sender = uart_getc();
    crc_sender = (crc_sender << 8) & 0xff00;
    crc_sender |= uart_getc();
    if(blknum != (uint8_t)(~blknum_cmpl)) {
      uart_putc(ASC_NAK);
      continue;
    }
    if(crc != crc_sender) {
      uart_putc(ASC_NAK);
      continue;
    }

    if(blknum == 0 && first_block) {
      /* get filename and filesize from block 0 */
      char *filename = (char*)rxbuf + 3;
      char *filesize_end;
      if(*filename == 0) {
        /* end of YMODEM batch transfer */
        uart_putc(ASC_ACK);
        goto end;
      }
      filesize = strtoul(filename+strlen(filename)+1, &filesize_end, 10);
      if(filesize_end > filename+strlen(filename)+1) {
        have_filesize = 1;
        remaining = filesize;
        totalbytes = 0;
      }
      uart_putc(ASC_ACK);
      goto restart;
    }

    if(have_filesize) {
      if(remaining < blocksize) {
        blocksize = remaining;
      }
    }
    res=f_write(fil, rxbuf, blocksize, &written);
    totalwritten += written;
    remaining -= blocksize;
    uart_putc(ASC_ACK);
    first_block = 0;
  } while ((c = uart_getc()) != ASC_EOT);
  uart_putc(ASC_ACK);
  goto restart;
end:
  uart_flush();
  sleep_ms(1000);
  printf("received %ld bytes (actual size: %ld bytes), wrote %ld bytes. last res = %d\n", totalbytes, (have_filesize ? filesize : totalbytes), totalwritten, res);
}

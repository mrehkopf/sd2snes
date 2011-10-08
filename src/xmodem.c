#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "config.h"
#include "timer.h"
#include "uart.h"
#include "ff.h"
#include "xmodem.h"

void xmodem_rxfile(FIL* fil) {
  uint8_t rxbuf[XMODEM_BLKSIZE], sum=0, sender_sum;
  uint8_t blknum, blknum2;
  uint8_t count;
  uint32_t totalbytes = 0;
  uint32_t totalwritten = 0;
  UINT written;
  FRESULT res;
  uart_flush();
  do {
    delay_ms(3000);
    uart_putc(ASC_NAK);
  } while (uart_getc() != ASC_SOH);
  do {
    blknum=uart_getc();
    blknum2=uart_getc();
    for(count=0; count<XMODEM_BLKSIZE; count++) {
      sum += rxbuf[count] = uart_getc();
      totalbytes++;
    }
    sender_sum = uart_getc();
    res=f_write(fil, rxbuf, XMODEM_BLKSIZE, &written);
    totalwritten += written;
    uart_putc(ASC_ACK);
  } while (uart_getc() != ASC_EOT);
  uart_putc(ASC_ACK);
  uart_flush();
  sleep_ms(1000);
  printf("received %ld bytes, wrote %ld bytes. last res = %d\n", totalbytes, totalwritten, res);
}

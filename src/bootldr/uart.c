/*

   uart.c: UART access routines

*/

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "config.h"
#include "uart.h"
#include "led.h"

/*static uint8_t uart_lookupratio(float f_fr) {
  uint16_t errors[72]={0,67,71,77,83,91,100,111,125,
                       133,143,154,167,182,200,214,222,231,
                       250,267,273,286,300,308,333,357,364,
                       375,385,400,417,429,444,455,462,467,
                       500,533,538,545,556,571,583,600,615,
                       625,636,643,667,692,700,714,727,733,
                       750,769,778,786,800,818,833,846,857,
                       867,875,889,900,909,917,923,929,933};

  uint8_t ratios[72]={0x10,0xf1,0xe1,0xd1,0xc1,0xb1,0xa1,0x91,0x81,
                      0xf2,0x71,0xd2,0x61,0xb2,0x51,0xe3,0x92,0xd3,
                      0x41,0xf4,0xb3,0x72,0xa3,0xd4,0x31,0xe5,0xb4,
                      0x83,0xd5,0x52,0xc5,0x73,0x94,0xb5,0xd6,0xf7,
                      0x21,0xf8,0xd7,0xb6,0x95,0x74,0xc7,0x53,0xd8,
                      0x85,0xb7,0xe9,0x32,0xd9,0xa7,0x75,0xb8,0xfb,
                      0x43,0xda,0x97,0xeb,0x54,0xb9,0x65,0xdb,0x76,
                      0xfd,0x87,0x98,0xa9,0xba,0xcb,0xdc,0xed,0xfe};

  int fr = (f_fr-1)*1000;
  int i=0, i_result=0;
  int err=0, lasterr=1000;
  for(i=0; i<72; i++) {
    if(fr<errors[i]) {
      err=errors[i]-fr;
    } else {
      err=fr-errors[i];
    }
    if(err<lasterr) {
      i_result=i;
      lasterr=err;
    }
  }
  return ratios[i_result];
}
*/
/*static uint32_t baud2divisor(unsigned int baudrate) {
  uint32_t int_ratio;
  uint32_t error;
  uint32_t dl=0;
  float f_ratio;
  float f_fr;
  float f_dl;
  float f_pclk = (float)CONFIG_CPU_FREQUENCY / CONFIG_UART_PCLKDIV;
  uint8_t fract_ratio;
  f_ratio=(f_pclk / 16 / baudrate);
  int_ratio = (int)f_ratio;
  error=(f_ratio*1000)-(int_ratio*1000);
  if(error>990) {
    int_ratio++;
  } else if(error>10) {
    f_fr=1.5;
    f_dl=f_pclk / (16 * baudrate * (f_fr));
    dl = (int)f_dl;
    f_fr=f_pclk / (16 * baudrate * dl);
    fract_ratio = uart_lookupratio(f_fr);
  }
  if(!dl) {
    return int_ratio;
  } else {
    return ((fract_ratio<<16)&0xff0000) | dl;
  }
}
*/
//static char txbuf[1 << CONFIG_UART_TX_BUF_SHIFT];
static volatile unsigned int read_idx,write_idx;

void uart_putc(char c) {
  if (c == '\n')
    uart_putc('\r');
  while(!(UART_REGS->LSR & (0x20)));
  UART_REGS->THR = c;
}

/* Polling version only */
unsigned char uart_getc(void) {
  /* wait for character */
  while (!(BITBAND(UART_REGS->LSR, 0))) ;
  return UART_REGS->RBR;
}

/* Returns true if a char is ready */
unsigned char uart_gotc(void) {
  return BITBAND(UART_REGS->LSR, 0);
}

void uart_init(void) {
  uint32_t div;

  /* Turn on power to UART */
  BITBAND(LPC_SC->PCONP, UART_PCONBIT) = 1;

  /* UART clock = CPU clock - this block is reduced at compile-time */
  if (CONFIG_UART_PCLKDIV == 1) {
    BITBAND(LPC_SC->UART_PCLKREG, UART_PCLKBIT  ) = 1;
    BITBAND(LPC_SC->UART_PCLKREG, UART_PCLKBIT+1) = 0;
  } else if (CONFIG_UART_PCLKDIV == 2) {
    BITBAND(LPC_SC->UART_PCLKREG, UART_PCLKBIT  ) = 0;
    BITBAND(LPC_SC->UART_PCLKREG, UART_PCLKBIT+1) = 1;
  } else if (CONFIG_UART_PCLKDIV == 4) {
    BITBAND(LPC_SC->UART_PCLKREG, UART_PCLKBIT  ) = 0;
    BITBAND(LPC_SC->UART_PCLKREG, UART_PCLKBIT+1) = 0;
  } else { // Fallback: Divide by 8
    BITBAND(LPC_SC->UART_PCLKREG, UART_PCLKBIT  ) = 1;
    BITBAND(LPC_SC->UART_PCLKREG, UART_PCLKBIT+1) = 1;
  }

  /* set baud rate - no fractional stuff for now */
  UART_REGS->LCR = BV(7) | 3; // always 8n1
  div = 0x850004; // baud2divisor(CONFIG_UART_BAUDRATE);

  UART_REGS->DLL = div & 0xff;
  UART_REGS->DLM = (div >> 8) & 0xff;
  BITBAND(UART_REGS->LCR, 7) = 0;

  if (div & 0xff0000) {
    UART_REGS->FDR = (div >> 16) & 0xff;
  }

  /* reset and enable FIFO */
  UART_REGS->FCR = BV(0);

  UART_REGS->THR = '?';
}

/* --- generic code below --- */
void uart_puthex(uint8_t num) {
  uint8_t tmp;
  tmp = (num & 0xf0) >> 4;
  if (tmp < 10)
    uart_putc('0'+tmp);
  else
    uart_putc('a'+tmp-10);

  tmp = num & 0x0f;
  if (tmp < 10)
    uart_putc('0'+tmp);
  else
    uart_putc('a'+tmp-10);
}

void uart_trace(void *ptr, uint16_t start, uint16_t len) {
  uint16_t i;
  uint8_t j;
  uint8_t ch;
  uint8_t *data = ptr;

  data+=start;
  for(i=0;i<len;i+=16) {

    uart_puthex(start>>8);
    uart_puthex(start&0xff);
    uart_putc('|');
    uart_putc(' ');
    for(j=0;j<16;j++) {
      if(i+j<len) {
        ch=*(data + j);
        uart_puthex(ch);
      } else {
        uart_putc(' ');
        uart_putc(' ');
      }
      uart_putc(' ');
    }
    uart_putc('|');
    for(j=0;j<16;j++) {
      if(i+j<len) {
        ch=*(data++);
        if(ch<32 || ch>0x7e)
          ch='.';
        uart_putc(ch);
      } else {
        uart_putc(' ');
      }
    }
    uart_putc('|');
    uart_putcrlf();
    start+=16;
  }
}

void uart_flush(void) {
  while (read_idx != write_idx) ;
}

void uart_puts(const char *text) {
  while (*text) {
    uart_putc(*text++);
  }
}

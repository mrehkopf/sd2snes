/*

   uart.c: UART access routines

*/

#include "config.h"
#include "bits.h"
#include "uart.h"
#include "led.h"

static volatile unsigned int read_idx,write_idx;

void uart_putc(char c) {
  if (c == '\n')
    uart_putc('\r');
  while(!(BITBAND(UART_REGS->SR, USART_SR_TXE_Pos)));
  UART_REGS->DR = c;
}

/* Polling version only */
unsigned char uart_getc(void) {
  /* wait for character */
  while (!(BITBAND(UART_REGS->SR, USART_SR_RXNE_Pos))) ;
  return UART_REGS->DR;
}

/* Returns true if a char is ready */
unsigned char uart_gotc(void) {
  return BITBAND(UART_REGS->SR, USART_SR_RXNE_Pos);
}

void uart_init(void) {
  /* Turn on power to UART */
  BITBAND(UART_RCC_REG, UART_RCC_BIT) = 1;

  /* connect USART2 on PA2,PA3 */
  GPIO_SEL_AF(GPIOA, 2, 7);
  GPIO_SEL_AF(GPIOA, 3, 7);
  GPIO_MODE_AF(GPIOA, 2);
  GPIO_MODE_AF(GPIOA, 3);

  /* 8N1, 16x oversampling, one bit sampling, enable USART+TX+RX */
  UART_REGS->CR1 = USART_CR1_UE | USART_CR1_TE | USART_CR1_RE;
  UART_REGS->CR3 = USART_CR3_ONEBIT;

  uint8_t mantissa, fraction;
  float f_fract;
  f_fract = CONFIG_CPU_FREQUENCY / CONFIG_UART_PCLKDIV / 16.0 / CONFIG_UART_BAUDRATE;
  mantissa = f_fract;
  f_fract = 16.0 * (f_fract - mantissa);
  fraction = f_fract;
  f_fract -= fraction;
  if(f_fract >= 0.5) {
    fraction++;
  }
  if(fraction == 16) {
    mantissa++;
    fraction = 0;
  }
  /* set baud rate */
  UART_REGS->BRR = (fraction << USART_BRR_DIV_Fraction_Pos)
                 | (mantissa << USART_BRR_DIV_Mantissa_Pos);

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

void uart_puts_hex(const char *text) {
  while (*text) {
    uart_puthex(*text++);
    uart_putc(' ');
  }
}

void uart_trace(void *ptr, uint32_t start, uint32_t len) {
  uint32_t i;
  uint8_t j;
  uint8_t ch;
  uint8_t *data = ptr;

  data+=start;
  for(i=0;i<len;i+=16) {

    uart_puthex(start>>16);
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
  while(!(BITBAND(UART_REGS->SR, USART_SR_TXE_Pos)));
}

void uart_puts(const char *text) {
  while (*text) {
    uart_putc(*text++);
  }
}

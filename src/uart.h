/*

   uart.h: Definitions for the UART access routines

*/

#ifndef UART_H
#define UART_H

#include <stdio.h>
#include <stdint.h>

//#ifdef CONFIG_UART_DEBUG
#if 1

#ifdef __AVR__
#  include <avr/pgmspace.h>
  void uart_puts_P(prog_char *text);
#else
#  define uart_puts_P(str) uart_puts(str)
#endif

void uart_init(void);
unsigned char uart_getc(void);
unsigned char uart_gotc(void);
void uart_putc(char c);
void uart_puts(const char *str);
void uart_puthex(uint8_t num);
void uart_puts_hex(const char *text);
void uart_trace(void *ptr, uint32_t start, uint32_t len);
void uart_flush(void);
int  printf(const char *fmt, ...);
int  snprintf(char *str, size_t size, const char *format, ...);
#define uart_putcrlf() uart_putc('\n')

#else

#define uart_init()    do {} while(0)
#define uart_getc()    0
#define uart_putc(x)   do {} while(0)
#define uart_puthex(x) do {} while(0)
#define uart_flush()   do {} while(0)
#define uart_puts_P(x) do {} while(0)
#define uart_puts(x)   do {} while(0)
#define uart_putcrlf() do {} while(0)
#define uart_trace(a,b,c) do {} while(0)

#endif

#endif

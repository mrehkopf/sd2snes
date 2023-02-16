/*

   uart.h: Definitions for the UART access routines

*/

#ifndef UART_H
#define UART_H

#include <stdio.h>
#include <stdint.h>
#include "config.h"

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

/* A few symbols to make this code work for all four UARTs */
#if defined(CONFIG_UART_NUM) && CONFIG_UART_NUM == 1
#  define UART_RCC_BIT RCC_APB2ENR_USART1EN_Pos
#  define UART_PCLKREG RCC->APB2ENR
#  define UART_REGS    USART1
#  define UART_HANDLER USART1_IRQHandler
#  define UART_IRQ     USART1_IRQn
#elif CONFIG_UART_NUM == 2
#  define UART_RCC_BIT RCC_APB1ENR_USART2EN_Pos
#  define UART_RCC_REG RCC->APB1ENR
#  define UART_REGS    USART2
#  define UART_HANDLER USART2_IRQHandler
#  define UART_IRQ     USART2_IRQn
#elif CONFIG_UART_NUM == 6
#  define UART_RCC_BIT RCC_APB2ENR_USART6EN_Pos
#  define UART_PCLKREG RCC->APB2ENR
#  define UART_REGS    USART6
#  define UART_HANDLER USART6_IRQHandler
#  define UART_IRQ     USART6_IRQn
#else
#  error CONFIG_UART_NUM is not set or has an invalid value!
#endif

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

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


   uart.h: Definitions for the UART access routines

*/

#ifndef UART_H
#define UART_H

#ifdef CONFIG_UART_DEBUG

#include <avr/pgmspace.h>

void uart_init(void);
unsigned char uart_getc(void);
void uart_putc(char c);
void uart_puthex(uint8_t num);
void uart_trace(void *ptr, uint16_t start, uint16_t len);
void uart_flush(void);
void uart_puts_P(prog_char *text);
void uart_putcrlf(void);

#include <stdio.h>
#define dprintf(str,...) printf_P(PSTR(str), ##__VA_ARGS__)

#else

#define uart_init()    do {} while(0)
#define uart_getc()    0
#define uart_putc(x)   do {} while(0)
#define uart_puthex(x) do {} while(0)
#define uart_flush()   do {} while(0)
#define uart_puts_P(x) do {} while(0)
#define uart_putcrlf() do {} while(0)
#define uart_trace(a,b,c) do {} while(0)

#endif

#endif

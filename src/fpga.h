/* sd2snes - SD card based universal cartridge for the SNES
   Copyright (C) 2009-2010 Maximilian Rehkopf <otakon@gmx.net>
   AVR firmware portion

   Inspired by and based on code from sd2iec, written by Ingo Korb et al.
   See sdcard.c|h, config.h.

   FAT file system access based on code by ChaN, Jim Brain, Ingo Korb,
   see ff.c|h.

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

   fpga.h: FPGA (re)configuration
*/

#ifndef FPGA_H
#define FPGA_H

void fpga_init(void);
uint8_t fpga_test(void);
void fpga_postinit(void);
void fpga_pgm(uint8_t* filename);

void set_avr_read(uint8_t val);
void set_avr_write(uint8_t val);
void set_avr_ena(uint8_t val);
void set_avr_nextaddr(uint8_t val);
void set_avr_addr_reset(uint8_t val);
void set_avr_data(uint8_t data);
void set_avr_addr_en(uint8_t val);
void set_avr_mapper(uint8_t val);
void set_avr_bank(uint8_t val);

uint8_t SPI_OFFLOAD;

#define FPGA_TEST_TOKEN	(0xa5)

// some macros for bulk transfers (faster)
#define FPGA_SEND_BYTE(data)	do {SET_AVR_DATA(data); CCLK();} while (0)
#define FPGA_SEND_BYTE_SERIAL(data)	do {SET_AVR_DATA(data); CCLK();\
SET_AVR_DATA(data<<1); CCLK(); SET_AVR_DATA(data<<2); CCLK();\
SET_AVR_DATA(data<<3); CCLK(); SET_AVR_DATA(data<<4); CCLK();\
SET_AVR_DATA(data<<5); CCLK(); SET_AVR_DATA(data<<6); CCLK();\
SET_AVR_DATA(data<<7); CCLK();} while (0)
#define SET_CCLK()				do {PORTD |= _BV(PD4);} while (0)
#define CLR_CCLK()				do {PORTD &= ~_BV(PD4);} while (0)
#define CCLK()					do {SET_CCLK(); CLR_CCLK();} while (0)
#define SET_AVR_READ()			do {PORTB |= _BV(PB3);} while (0)
#define CLR_AVR_READ()			do {PORTB &= ~_BV(PB3);} while (0)
#define SET_AVR_WRITE()			do {PORTB |= _BV(PB2);} while (0)
#define CLR_AVR_WRITE()			do {PORTB &= ~_BV(PB2);} while (0)
#define SET_AVR_EXCL()			do {PORTD |= _BV(PD7);} while (0)
#define CLR_AVR_EXCL()			do {PORTD &= ~_BV(PD7);} while (0)
#define SET_AVR_NEXTADDR()		do {PORTA |= _BV(PA4);} while (0)
#define CLR_AVR_NEXTADDR()		do {PORTA &= ~_BV(PA4);} while (0)
#define SET_AVR_ADDR_RESET()	do {PORTA |= _BV(PA5);} while (0)
#define CLR_AVR_ADDR_RESET()	do {PORTA &= ~_BV(PA5);} while (0)
#define SET_AVR_ADDR_EN()		do {PORTA |= _BV(PA6);} while (0)
#define CLR_AVR_ADDR_EN()		do {PORTA &= ~_BV(PA6);} while (0)
#define AVR_NEXTADDR()			do {SET_AVR_NEXTADDR(); CLR_AVR_NEXTADDR();} while (0)
#define AVR_ADDR_RESET()		do {CLR_AVR_ADDR_RESET();\
									AVR_NEXTADDR();SET_AVR_ADDR_RESET();} while (0)
#define SET_AVR_DATA(data)		do {PORTC = (uint8_t)data;} while (0)
#define AVR_READ()				do {CLR_AVR_READ(); SET_AVR_READ();} while (0)
#define AVR_WRITE()				do {CLR_AVR_WRITE(); SET_AVR_WRITE();} while (0)
#define	AVR_DATA				(PINC)
#endif

// insert cool lenghty disclaimer here

// fpga.h

#ifndef FPGA_H
#define FPGA_H

void fpga_init(void);
void fpga_postinit(void);
void fpga_pgm(char* filename);

void set_avr_read(uint8_t val);
void set_avr_write(uint8_t val);
void set_avr_ena(uint8_t val);
void set_avr_nextaddr(uint8_t val);
void set_avr_addr_reset(uint8_t val);
void set_avr_data(uint8_t data);
void set_avr_addr_en(uint8_t val);
void set_avr_mapper(uint8_t val);
void set_avr_bank(uint8_t val);

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

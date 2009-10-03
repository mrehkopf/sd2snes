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


   main.c: Lots of init calls for the submodules

*/

#include <stdio.h>
#include <string.h>
#include <avr/boot.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <avr/power.h>
#include <avr/wdt.h>
#include <util/delay.h>
#include "config.h"
#include "diskio.h"
#include "ff.h"
#include "led.h"
#include "timer.h"
#include "fpga.h"
#include "uart.h"
#include "ustring.h"
#include "utils.h"
#include "snes.h"
#include "fileops.h"
#include "memory.h"
#include "fpga_spi.h"
#include "spi.h"
#include "avrcompat.h"
#include "filetypes.h"

/* Make sure the watchdog is disabled as soon as possible    */
/* Copy this code to your bootloader if you use one and your */
/* MCU doesn't disable the WDT after reset!                  */
void get_mcusr(void) \
      __attribute__((naked)) \
      __attribute__((section(".init3")));
void get_mcusr(void)
{
  MCUSR = 0;
  wdt_disable();
}

#ifdef CONFIG_MEMPOISON
void poison_memory(void) \
  __attribute__((naked)) \
  __attribute__((section(".init1")));
void poison_memory(void) {
  register uint16_t i;
  register uint8_t  *ptr;

  asm("clr r1\n");
  /* There is no RAMSTARt variable =( */
  if (RAMEND > 2048 && RAMEND < 4096) {
    /* 2K memory */
    ptr = (void *)RAMEND-2047;
    for (i=0;i<2048;i++)
      ptr[i] = 0x55;
  } else if (RAMEND > 4096 && RAMEND < 8192) {
    /* 4K memory */
    ptr = (void *)RAMEND-4095;
    for (i=0;i<4096;i++)
      ptr[i] = 0x55;
  } else {
    /* Assume 8K memory */
    ptr = (void *)RAMEND-8191;
    for (i=0;i<8192;i++)
      ptr[i] = 0x55;
  }
}
#endif

void avr_goto_addr(const uint32_t val) {
	AVR_ADDR_RESET();
	for(uint32_t i=0; i<val; i++) {
		AVR_NEXTADDR();
	}
}
#if __GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ > 1)
int main(void) __attribute__((OS_main));
#endif
int main(void) {
#if defined __AVR_ATmega644__ || defined __AVR_ATmega644P__ || defined __AVR_ATmega2561__
  asm volatile("in  r24, %0\n"
               "ori r24, 0x80\n"
               "out %0, r24\n"
               "out %0, r24\n"
               :
               : "I" (_SFR_IO_ADDR(MCUCR))
               : "r24"
               );
#elif defined __AVR_ATmega32__
  asm volatile ("in  r24, %0\n"
                "ori r24, 0x80\n"
                "out %0, r24\n"
                "out %0, r24\n"
                :
                : "I" (_SFR_IO_ADDR(MCUCSR))
                : "r24"
                );
#elif defined __AVR_ATmega128__ || defined __AVR_ATmega1281__
  /* Just assume that JTAG doesn't hurt us on the m128 */
#else
#  error Unknown chip!
#endif

#ifdef CLOCK_PRESCALE
    clock_prescale_set(CLOCK_PRESCALE);
#endif
	spi_none();
    snes_reset(1);
    uart_init();
    sei();   // suspected to reset the AVR when inserting an SD card
    _delay_ms(100);
    disk_init();
    snes_init();
    timer_init();
    uart_puts_P(PSTR("\nsd2snes " VERSION));
    uart_putcrlf();

	file_init();
    FATFS fatfs;
    f_mount(0,&fatfs);
    set_busy_led(1);
    uart_putc('W');
    fpga_init();
    fpga_pgm("/sd2snes/main.bit");
	_delay_ms(100);
	fpga_spi_init();
    uart_putc('!');
	_delay_ms(100);
    set_avr_ena(0);
	snes_reset(1);

	uart_putc('(');
	load_rom("/test.smc");
	uart_putc(')');

	uart_putc('[');
	load_sram("/test.srm");
	uart_putc(']');
	*fs_path=0;
	uint16_t curr_dir_id = scan_dir(fs_path, 0); // generate files footprint
	dprintf("curr dir id = %x\n", curr_dir_id);
	uint16_t saved_dir_id;
	if((get_db_id(&saved_dir_id) != FR_OK)	// no database?
       || saved_dir_id != curr_dir_id) {	// files changed?
		dprintf("saved dir id = %x\n", saved_dir_id);
		_delay_ms(50);
		dprintf("rebuilding database...");
		_delay_ms(50);
		curr_dir_id = scan_dir(fs_path, 1);	// then rebuild database
		sram_writeblock(&curr_dir_id, 0x600000, 2);
		uint32_t endaddr;
		sram_readblock(&endaddr, 0x600004, 4);
		dprintf("%lx\n", endaddr);
		save_sram("/sd2snes/sd2snes.db", endaddr-0x600000, 0x600000);
		dprintf("done\n"); 
	}

	set_busy_led(0);
	set_avr_ena(1);
	_delay_ms(100);
	uart_puts_P(PSTR("SNES GO!\n"));
	snes_reset(0);


	while(1) {
		snes_main_loop();
	}


/* HERE BE LIONS */
while(1)  {	
	set_avr_addr(0x600000);
	spi_fpga();
	spiTransferByte(0x81); // read w/ increment... hopefully
	spiTransferByte(0x00); // 1 dummy read
	uart_putcrlf();
	uint8_t buff[21];
	for(uint8_t cnt=0; cnt<21; cnt++) {
	    uint8_t data=spiTransferByte(0x00);
		buff[cnt]=data;
	}
	for(uint8_t cnt=0; cnt<21; cnt++) {
		uint8_t data = buff[cnt];
		_delay_ms(2);
	    if(data>=0x20 && data <= 0x7a) {
			uart_putc(data);
	    } else {
//			uart_putc('.');
			uart_putc("0123456789ABCDEF"[data>>4]);
			uart_putc("0123456789ABCDEF"[data&15]);
			uart_putc(' ');
	    }
//		set_avr_bank(3);
	} 
	spi_none();
}
	while(1);
}


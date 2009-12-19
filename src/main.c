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

void writetest(void) {
// HERE BE LIONS, GET IN THE CAR
	char teststring[58];
	while(1) {
		sram_writeblock((void*)"Testtext of DOOM!!1! 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", SRAM_SCRATCHPAD+0x20, 58);
		sram_readblock((void*)teststring, SRAM_SCRATCHPAD+0x20, 58);
		teststring[57]=0;
		dprintf("%s\n", teststring);
	}
// END OF LIONS
}


void memtest(void) {
/* HERE BE DRAGONS */
	uint32_t dbg_i;
	for(dbg_i=0; dbg_i < 65536; dbg_i++) {
		sram_writeshort((uint16_t)dbg_i&0xffff, dbg_i*2);
	}
	save_sram((uint8_t*)"/sd2snes/memtest", 0x20000, 0);
	set_pwr_led(0);
	while(1);
/* END OF DRAGONS */
}


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
	set_pwr_led(0);
	set_busy_led(1);
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
	uart_putc('W');
	fpga_init();
	fpga_pgm((uint8_t*)"/sd2snes/main.bit");
	_delay_ms(100);
	set_pwr_led(1);
	fpga_spi_init();
	uart_putc('!');
	_delay_ms(100);

restart:
	set_avr_ena(0);
	snes_reset(1);

	*fs_path=0;
	uint16_t saved_dir_id;
	get_db_id(&saved_dir_id);

	uint16_t mem_dir_id = sram_readshort(SRAM_DIRID);
	uint32_t mem_magic = sram_readlong(SRAM_SCRATCHPAD);


	if((mem_magic != 0x12345678) || (mem_dir_id != saved_dir_id)) {
		uint16_t curr_dir_id = scan_dir(fs_path, 0, 0); // generate files footprint
		dprintf("curr dir id = %x\n", curr_dir_id);
		if((get_db_id(&saved_dir_id) != FR_OK)	// no database?
		|| saved_dir_id != curr_dir_id) {	// files changed? // XXX
			dprintf("saved dir id = %x\n", saved_dir_id);
			dprintf("rebuilding database...");
			_delay_ms(50);
			curr_dir_id = scan_dir(fs_path, 1, 0);	// then rebuild database
			sram_writeblock(&curr_dir_id, SRAM_DB_ADDR, 2);
			uint32_t endaddr, direndaddr;
			sram_readblock(&endaddr, SRAM_DB_ADDR+4, 4);
			sram_readblock(&direndaddr, SRAM_DB_ADDR+8, 4);
			dprintf("%lx %lx\n", endaddr, direndaddr);
			save_sram((uint8_t*)"/sd2snes/sd2snes.db", endaddr-SRAM_DB_ADDR, SRAM_DB_ADDR);
			save_sram((uint8_t*)"/sd2snes/sd2snes.dir", direndaddr-(SRAM_DIR_ADDR), SRAM_DIR_ADDR);
			dprintf("done\n"); 
			sram_hexdump(SRAM_DB_ADDR, 0x400);
		} else {
			dprintf("saved dir id = %x\n", saved_dir_id);
			dprintf("different card, consistent db, loading db...\n");
			load_sram((uint8_t*)"/sd2snes/sd2snes.db", SRAM_DB_ADDR);
			load_sram((uint8_t*)"/sd2snes/sd2snes.dir", SRAM_DIR_ADDR);
		}
//	save_sram((uint8_t*)"/debug.smc", 0x400000, 0);	
//	uart_putc('[');
//	load_sram((uint8_t*)"/test.srm", SRAM_SAVE_ADDR);
//	uart_putc(']');

		sram_writeshort(curr_dir_id, SRAM_DIRID);
		sram_writelong(0x12345678, SRAM_SCRATCHPAD);
	} else {
		dprintf("same card, loading db...\n");
		load_sram((uint8_t*)"/sd2snes/sd2snes.db", SRAM_DB_ADDR);
		load_sram((uint8_t*)"/sd2snes/sd2snes.dir", SRAM_DIR_ADDR);
	}

	led_pwm();

	uart_putc('(');
	load_rom((uint8_t*)"/sd2snes/menu.bin");
	set_rom_mask(0x3fffff); // force mirroring off
	uart_putc(')');

	sram_writebyte(0, SRAM_CMD_ADDR);

	set_busy_led(0);
	set_avr_ena(1);

	_delay_ms(100);
	uart_puts_P(PSTR("SNES GO!\r\n"));
	snes_reset(0);

	uint8_t cmd = 0;

	while(!sram_reliable());
	while(!cmd) {
		cmd=menu_main_loop();
		switch(cmd) {
			case 0x01: // SNES_CMD_LOADROM:
				get_selected_name(file_lfn);
				_delay_ms(100);
//				snes_reset(1);
				set_avr_ena(0);
				dprintf("Selected name: %s\n", file_lfn);
				load_rom(file_lfn);
				if(romprops.ramsize_bytes) {
					strcpy(strrchr((char*)file_lfn, (int)'.'), ".srm");
					dprintf("SRM file: %s\n", file_lfn);
					load_sram(file_lfn, SRAM_SAVE_ADDR);
				} else {
					dprintf("No SRAM\n");
				}
				set_avr_ena(1);
				snes_reset(1);
				_delay_ms(100);
				snes_reset(0);
				break;
			default:
				dprintf("unknown cmd: %d\n", cmd);
				cmd=0; // unknown cmd: stay in loop
			break;
		}
		
	}
	dprintf("cmd was %x, going to snes main loop\n", cmd);
	led_std();
	cmd=0;
	uint8_t snes_reset_prev=0, snes_reset_now=0, snes_reset_state=0;
	uint16_t reset_count=0;
	while(fpga_test() == FPGA_TEST_TOKEN) {
		dprintf("%02X\n", fpga_test());
		snes_reset_now=get_snes_reset();
		if(snes_reset_now) {
			if(!snes_reset_prev) {
				dprintf("RESET BUTTON DOWN\n");
				snes_reset_state=1;
				// reset reset counter
				reset_count=0;
			}
		} else {
			if(snes_reset_prev) {
				dprintf("RESET BUTTON UP\n");
				snes_reset_state=0;
			}
		}
		if(snes_reset_state) {
			_delay_ms(10);
			reset_count++;
		} else {
			sram_reliable();
			snes_main_loop();
		}
		if(reset_count>100) {
			reset_count=0;
			led_std();
			set_avr_ena(0);
			snes_reset(1);
			_delay_ms(100);
			if(romprops.ramsize_bytes && fpga_test() == 0xa5) {
				set_busy_led(1);
				save_sram(file_lfn, romprops.ramsize_bytes, SRAM_SAVE_ADDR);
				set_busy_led(0);
			}
			_delay_ms(1000);
			set_busy_led(1);
			goto restart;
		}
		snes_reset_prev = snes_reset_now;
	}
	// FPGA TEST FAIL. PANIC.

	led_std();

	while(1) {
		set_pwr_led(1);
		set_busy_led(1);
		_delay_ms(150);
		set_pwr_led(0);
		set_busy_led(0);
		_delay_ms(150);
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


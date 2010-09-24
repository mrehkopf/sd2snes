#include <arm/NXP/LPC17xx/LPC17xx.h>
#include <string.h>
#include "config.h"
#include "obj/autoconf.h"
#include "clock.h"
#include "uart.h"
#include "bits.h"
#include "power.h"
#include "timer.h"
#include "ff.h"
#include "diskio.h"
#include "spi.h"
#include "sdcard.h"
#include "fileops.h"
#include "fpga.h"
#include "fpga_spi.h"
#include "filetypes.h"
#include "memory.h"
#include "snes.h"
#include "led.h"
#include "sort.h"

#include "tests.h"

#define EMC0TOGGLE	(3<<4)
#define MR0R		(1<<1)

int i;

/* FIXME HACK */
volatile enum diskstates disk_state;

int main(void) {
  LPC_GPIO2->FIODIR = BV(0) | BV(1) | BV(2);
  LPC_GPIO1->FIODIR = 0;
  LPC_GPIO0->FIODIR = BV(16);

 /* connect UART3 on P0[25:26] + SSP0 on P0[15:18] SSP1 on P0[6:9] + MAT3.0 on P0[10] */
  LPC_PINCON->PINSEL1 = BV(18) | BV(19) | BV(20) | BV(21) /* UART3 */
                      | BV(3) | BV(5);                    /* SSP0 (FPGA) except SS */
  LPC_PINCON->PINSEL0 = BV(31)                            /* SSP0 */
                      | BV(13) | BV(15) | BV(17) | BV(19) /* SSP1 (SD) */
                      | BV(20) | BV(21);                  /* MAT3.0 */

 /* enable pull-downs for CIC data lines */
  LPC_PINCON->PINMODE3 = BV(18) | BV(19) | BV(20) | BV(21);
  clock_disconnect();
  snes_init();
  snes_reset(1);
  power_init();
  timer_init();
  uart_init();
  fpga_spi_init();
  spi_preinit(SPI_FPGA);
  spi_preinit(SPI_SD);
/* do this last because the peripheral init()s change PCLK dividers */
  clock_init();

  sd_init();
  fpga_spi_init();
  delay_ms(10);
  printf("\n\nsd2snes mk.2\n============\nfw ver.: " VER "\ncpu clock: %d Hz\n", CONFIG_CPU_FREQUENCY);
  file_init();
/*  uart_putc('S');
  for(p1=0; p1<8192; p1++) {
    file_read();
  }
  file_close();
  uart_putc('E');
  uart_putcrlf();
  printf("sizeof(struct FIL): %d\n", sizeof(file_handle));
  uart_trace(file_buf, 0, 512);*/

/* setup timer (fpga clk) */
  LPC_TIM3->CTCR=0;
  LPC_TIM3->EMR=EMC0TOGGLE;
  LPC_TIM3->MCR=MR0R;
  LPC_TIM3->MR0=1;
  LPC_TIM3->TCR=1;
  fpga_init();
  fpga_pgm((uint8_t*)"/sd2snes/main.bit");
restart:
  rdyled(1);
  readled(0);
  writeled(0);
  /* exclusive mode */
  set_mcu_ovr(1);
 
  *fs_path=0;
  uint16_t saved_dir_id;
  get_db_id(&saved_dir_id);

    uint16_t mem_dir_id = sram_readshort(SRAM_DIRID);
    uint32_t mem_magic = sram_readlong(SRAM_SCRATCHPAD);


    if((mem_magic != 0x12345678) || (mem_dir_id != saved_dir_id)) {
    /* generate fs footprint (interesting files only) */
    uint16_t curr_dir_id = scan_dir(fs_path, 0, 0);
    printf("curr dir id = %x\n", curr_dir_id);
    /* files changed or no database found? */
    if((get_db_id(&saved_dir_id) != FR_OK)
      || saved_dir_id != curr_dir_id) {
      /* rebuild database */
      printf("saved dir id = %x\n", saved_dir_id);
      printf("rebuilding database...");
      curr_dir_id = scan_dir(fs_path, 1, 0);
      sram_writeblock(&curr_dir_id, SRAM_DB_ADDR, 2);
      uint32_t endaddr, direndaddr;
      sram_readblock(&endaddr, SRAM_DB_ADDR+4, 4);
      sram_readblock(&direndaddr, SRAM_DB_ADDR+8, 4);
      printf("%lx %lx\n", endaddr, direndaddr);
      printf("sorting database...");
      sort_all_dir(direndaddr);
      printf("done\n");
      save_sram((uint8_t*)"/sd2snes/sd2snes.db", endaddr-SRAM_DB_ADDR, SRAM_DB_ADDR);
      save_sram((uint8_t*)"/sd2snes/sd2snes.dir", direndaddr-(SRAM_DIR_ADDR), SRAM_DIR_ADDR);
      printf("done\n");
    } else {
      printf("saved dir id = %x\n", saved_dir_id);
      printf("different card, consistent db, loading db...\n");
      load_sram((uint8_t*)"/sd2snes/sd2snes.db", SRAM_DB_ADDR);
      load_sram((uint8_t*)"/sd2snes/sd2snes.dir", SRAM_DIR_ADDR);
    }
    sram_writeshort(curr_dir_id, SRAM_DIRID);
    sram_writelong(0x12345678, SRAM_SCRATCHPAD);
  } else {
    printf("same card, loading db...\n");
    load_sram((uint8_t*)"/sd2snes/sd2snes.db", SRAM_DB_ADDR);
    load_sram((uint8_t*)"/sd2snes/sd2snes.dir", SRAM_DIR_ADDR);
  }

  /* load menu */
  uart_putc('(');
  load_rom((uint8_t*)"/sd2snes/menu.bin", SRAM_MENU_ADDR);
  /* force memory size + mapper */
  set_rom_mask(0x3fffff);
  set_mapper(0x7);
  uart_putc(')');
  uart_putcrlf();

  sram_writebyte(0, SRAM_CMD_ADDR);

  /* shared mode */
  set_mcu_ovr(0);

  printf("SNES GO!\n");
  snes_reset(0);

  uint8_t cmd = 0;
  printf("test sram\n");
  while(!sram_reliable()) uart_puts("DERP");
  printf("ok\n");

sram_hexdump(SRAM_DB_ADDR, 0x200);
  while(!cmd) {
    cmd=menu_main_loop();
    switch(cmd) {
      case SNES_CMD_LOADROM:
        get_selected_name(file_lfn);
        set_mcu_ovr(1);
        printf("Selected name: %s\n", file_lfn);
        load_rom(file_lfn, SRAM_ROM_ADDR);
        if(romprops.ramsize_bytes) {
          strcpy(strrchr((char*)file_lfn, (int)'.'), ".srm");
          printf("SRM file: %s\n", file_lfn);
          load_sram(file_lfn, SRAM_SAVE_ADDR);
        } else {
          printf("No SRAM\n");
        }
        set_mcu_ovr(0);
        snes_reset(1);
        delay_ms(100);
        snes_reset(0);
        break;
      case SNES_CMD_SETRTC:
        break;
      default:
        printf("unknown cmd: %d\n", cmd);
        cmd=0; /* unknown cmd: stay in loop */
        break;
    }
  }

  printf("cmd was %x, going to snes main loop\n", cmd);
  cmd=0;
  uint8_t snes_reset_prev=0, snes_reset_now=0, snes_reset_state=0;
  uint16_t reset_count=0;
  while(fpga_test() == FPGA_TEST_TOKEN) {
    snes_reset_now=get_snes_reset();
    if(snes_reset_now) {
      if(!snes_reset_prev) {
        printf("RESET BUTTON DOWN\n");
        snes_reset_state=1;
        reset_count=0;
      }
    } else {
      if(snes_reset_prev) {
        printf("RESET BUTTON UP\n");
        snes_reset_state=0;
      }
    }
    if(snes_reset_state) {
      delay_ms(10);
      reset_count++;
    } else {
      sram_reliable();
      snes_main_loop();
    }
    if(reset_count>100) {
      reset_count=0;
      set_mcu_ovr(1);
      snes_reset(1);
      delay_ms(100);
      if(romprops.ramsize_bytes && fpga_test() == 0xa5) {
        writeled(1);
        save_sram(file_lfn, romprops.ramsize_bytes, SRAM_SAVE_ADDR);
        writeled(0);
      }
      delay_ms(1000);
      goto restart;
    }
    snes_reset_prev = snes_reset_now;
  }
  /* fpga test fail: panic */
  led_panic();
}


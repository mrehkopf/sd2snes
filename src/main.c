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
#include "fileops.h"
#include "fpga.h"
#include "fpga_spi.h"
#include "filetypes.h"
#include "memory.h"
#include "snes.h"
#include "led.h"
#include "sort.h"
#include "cic.h"
#include "tests.h"
#include "cli.h"
#include "sdnative.h"
#include "crc.h"
#include "smc.h"

#define EMC0TOGGLE	(3<<4)
#define MR0R		(1<<1)

int i;

int sd_offload = 0, ff_sd_offload = 0, sd_offload_tgt = 0;
int sd_offload_partial = 0;
uint16_t sd_offload_partial_start = 0;
uint16_t sd_offload_partial_end = 0;

/* FIXME HACK */
volatile enum diskstates disk_state;
extern volatile tick_t ticks;
extern snes_romprops_t romprops;

int main(void) {
  LPC_GPIO2->FIODIR = BV(0) | BV(1) | BV(2);
  LPC_GPIO1->FIODIR = 0;
  LPC_GPIO0->FIODIR = BV(16);

 /* connect UART3 on P0[25:26] + SSP0 on P0[15:18] SSP1 on P0[6:9] + MAT3.0 on P0[10] */
  LPC_PINCON->PINSEL1 = BV(18) | BV(19) | BV(20) | BV(21) /* UART3 */
                      | BV(3) | BV(5);                    /* SSP0 (FPGA) except SS */
  LPC_PINCON->PINSEL0 = BV(31);                            /* SSP0 */
/*                      | BV(13) | BV(15) | BV(17) | BV(19)  SSP1 (SD) */

 /* pull-down CIC data lines */
  LPC_PINCON->PINMODE3 = BV(18) | BV(19) | BV(20) | BV(21);

  clock_disconnect();
  snes_init();
  snes_reset(1);
  power_init();
  timer_init();
  uart_init();
  fpga_spi_init();
  spi_preinit();
  led_init();
 /* do this last because the peripheral init()s change PCLK dividers */
  clock_init();
  LPC_PINCON->PINSEL0 |= BV(20) | BV(21);                  /* MAT3.0 (FPGA clock) */
led_pwm();
  sdn_init();
  fpga_spi_init();
  printf("\n\nsd2snes mk.2\n============\nfw ver.: " VER "\ncpu clock: %d Hz\n", CONFIG_CPU_FREQUENCY);
  file_init();
  cic_init(0);

/* setup timer (fpga clk) */
  LPC_TIM3->CTCR=0;
  LPC_TIM3->EMR=EMC0TOGGLE;
  LPC_TIM3->MCR=MR0R;
  LPC_TIM3->MR0=1;
  LPC_TIM3->TCR=1;
  fpga_init();
  fpga_rompgm();
restart:
  if(disk_state == DISK_CHANGED) {
    sdn_init();
    newcard = 1;
  }
  load_bootrle(SRAM_MENU_ADDR);
  set_saveram_mask(0x1fff);
  set_rom_mask(0x3fffff);
  set_mapper(0x7);
  set_mcu_ovr(0);
  snes_reset(0);
  delay_ms(15); /* allow CIC to settle */

  while(get_cic_state() == CIC_FAIL) {
    rdyled(0);
    readled(0);
    writeled(0);
    delay_ms(500);
    rdyled(1);
    readled(1);
    writeled(1);
    delay_ms(500);
  }
  /* some sanity checks */
  uint8_t card_go = 0;
  while(!card_go) {
    if(disk_status(0) & (STA_NOINIT|STA_NODISK)) {
      snes_bootprint("            No Card!            \0");
      while(disk_status(0) & (STA_NOINIT|STA_NODISK));
      delay_ms(200);
    }
    file_open((uint8_t*)"/sd2snes/menu.bin", FA_READ);
    if(file_status != FILE_OK) {
      snes_bootprint("  /sd2snes/menu.bin not found!  \0");
      while(disk_status(0) == RES_OK);
    } else {
      card_go = 1;
    }
    file_close();
  }
  snes_bootprint("           Loading ...          \0");
  if(get_cic_state() == CIC_PAIR) {
    printf("PAIR MODE ENGAGED!\n");
    cic_pair(CIC_PAL, CIC_NTSC);
  }
  rdyled(1);
  readled(0);
  writeled(0);
  /* exclusive mode */
  set_mcu_ovr(1);
 
  *fs_path=0;
  uint32_t saved_dir_id;
  get_db_id(&saved_dir_id);

  uint32_t mem_dir_id = sram_readlong(SRAM_DIRID);
  uint32_t mem_magic = sram_readlong(SRAM_SCRATCHPAD);
  printf("mem_magic=%lx mem_dir_id=%lx saved_dir_id=%lx\n", mem_magic, mem_dir_id, saved_dir_id);
  if((mem_magic != 0x12345678) || (mem_dir_id != saved_dir_id) || (newcard)) {
    newcard = 0;
    /* generate fs footprint (interesting files only) */
    uint32_t curr_dir_id = scan_dir(fs_path, 0, 0);
    printf("curr dir id = %lx\n", curr_dir_id);
    /* files changed or no database found? */
    if((get_db_id(&saved_dir_id) != FR_OK)
      || saved_dir_id != curr_dir_id) {
      /* rebuild database */
      printf("saved dir id = %lx\n", saved_dir_id);
      printf("rebuilding database...");
      snes_bootprint("     rebuilding database ...    \0");
      curr_dir_id = scan_dir(fs_path, 1, 0);
      sram_writeblock(&curr_dir_id, SRAM_DB_ADDR, 4);
      uint32_t endaddr, direndaddr;
      sram_readblock(&endaddr, SRAM_DB_ADDR+4, 4);
      sram_readblock(&direndaddr, SRAM_DB_ADDR+8, 4);
      printf("%lx %lx\n", endaddr, direndaddr);
      printf("sorting database...");
      snes_bootprint("       sorting database ...     \0");
      sort_all_dir(direndaddr);
      printf("done\n");
      snes_bootprint("        saving database ...     \0");
      save_sram((uint8_t*)"/sd2snes/sd2snes.db", endaddr-SRAM_DB_ADDR, SRAM_DB_ADDR);
      save_sram((uint8_t*)"/sd2snes/sd2snes.dir", direndaddr-(SRAM_DIR_ADDR), SRAM_DIR_ADDR);
      printf("done\n");
    } else {
      printf("saved dir id = %lx\n", saved_dir_id);
      printf("different card, consistent db, loading db...\n");
      load_sram((uint8_t*)"/sd2snes/sd2snes.db", SRAM_DB_ADDR);
      load_sram((uint8_t*)"/sd2snes/sd2snes.dir", SRAM_DIR_ADDR);
    }
    sram_writelong(curr_dir_id, SRAM_DIRID);
    sram_writelong(0x12345678, SRAM_SCRATCHPAD);
  } else {
    printf("same card, loading db...\n");
    load_sram((uint8_t*)"/sd2snes/sd2snes.db", SRAM_DB_ADDR);
    load_sram((uint8_t*)"/sd2snes/sd2snes.dir", SRAM_DIR_ADDR);
  }
  /* load menu */
  fpga_pgm((uint8_t*)"/main.bit.rle");

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
  snes_reset(1);
  delay_ms(1);
  snes_reset(0);

  uint8_t cmd = 0;
  uint32_t filesize=0;
  sram_writebyte(32, SRAM_CMD_ADDR);
  printf("test sram\n");
  while(!sram_reliable());
  printf("ok\n");
//while(1) {
//  delay_ms(1000);
//  printf("Estimated SNES master clock: %ld Hz\n", get_snes_sysclk());
//}
//sram_hexdump(SRAM_DB_ADDR, 0x200);
//sram_hexdump(SRAM_MENU_ADDR, 0x400);
  while(!cmd) {
    cmd=menu_main_loop();
// cmd = 1;
    printf("cmd: %d\n", cmd);
    sleep_ms(50);
    uart_putc('-');
    switch(cmd) {
      case SNES_CMD_LOADROM:
        get_selected_name(file_lfn);
        set_mcu_ovr(1);
// strcpy((char*)file_lfn, "/mon.smc"); 
        printf("Selected name: %s\n", file_lfn);
        filesize = load_rom(file_lfn, SRAM_ROM_ADDR);
        if(romprops.ramsize_bytes) {
          strcpy(strrchr((char*)file_lfn, (int)'.'), ".srm");
          printf("SRM file: %s\n", file_lfn);
          load_sram(file_lfn, SRAM_SAVE_ADDR);
        } else {
          printf("No SRAM\n");
        }
        set_mcu_ovr(0);
        snes_reset(1);
        delay_ms(10);
        snes_reset(0);
        break;
      case SNES_CMD_SETRTC:
        cmd=0; /* stay in loop */
        break;
      default:
        printf("unknown cmd: %d\n", cmd);
        cmd=0; /* unknown cmd: stay in loop */
        break;
    }
  }
  printf("cmd was %x, going to snes main loop\n", cmd);

/* MSU1 STUFF, GET ME OUTTA HERE */
  FIL durr;
// open MSU file
  strcpy((char*)file_buf, (char*)file_lfn);
  strcpy(strrchr((char*)file_buf, (int)'.'), ".msu");
  printf("MSU datafile: %s\n", file_buf);
  printf("f_open result: %d\n", f_open(&durr, (const TCHAR*)file_buf, FA_READ));
  UINT bytes_read = 1024;
  UINT bytes_read2 = 1;
  set_dac_vol(0x00);
  spi_set_speed(SSP_CLK_DIVISOR_FAST);
  while(fpga_status() & 0x4000);
  uint16_t fpga_status_prev = fpga_status();
  uint16_t fpga_status_now = fpga_status();
  uint16_t dac_addr = 0;
  uint16_t msu_addr = 0;
  uint8_t msu_repeat = 0;
  uint16_t msu_track = 0;
  uint32_t msu_offset = 0;

  uint32_t msu_page1_start = 0x0000;
  uint32_t msu_page2_start = 0x2000;
  uint32_t msu_page_size = 0x2000;

  set_msu_addr(0x0);
  msu_reset(0x0);
  ff_sd_offload=1;
  sd_offload_tgt=2;
  f_lseek(&durr, 0L);
  ff_sd_offload=1;
  sd_offload_tgt=2;
  f_read(&durr, file_buf, 16384, &bytes_read2);

  set_dac_addr(dac_addr);
  dac_pause();
  dac_reset();
/* audio_start, data_start, volume_start, audio_ctrl[1:0], ctrl_start */
while(1){
  fpga_status_now = fpga_status();
  if(fpga_status_now & 0x0020) {
    char suffix[11];

    /* get trackno */
    msu_track = get_msu_track();
    printf("Audio requested! Track=%d\n", msu_track);

    /* open file */
    f_close(&file_handle);
    snprintf(suffix, sizeof(suffix), "-%d.wav", msu_track);
    strcpy((char*)file_buf, (char*)file_lfn);
    strcpy(strrchr((char*)file_buf, (int)'.'), suffix);
    printf("filename: %s\n", file_buf);
    f_open(&file_handle, (const TCHAR*)file_buf, FA_READ);
    ff_sd_offload=1;
    sd_offload_tgt=1;
    f_lseek(&file_handle, 44L);
    set_dac_addr(0);
    dac_pause();
    dac_reset();
    ff_sd_offload=1;
    sd_offload_tgt=1;
    f_read(&file_handle, file_buf, 2048, &bytes_read);

    /* clear busy bit */
    set_msu_status(0x00, 0x20); /* set no bits, reset bit 5 */
  }

  if(fpga_status_now & 0x0010) {
    /* get address */
    msu_offset=get_msu_offset();
    printf("Data requested! Offset=%08lx page1=%08lx page2=%08lx\n", msu_offset, msu_page1_start, msu_page2_start);
    if(   ((msu_offset < msu_page1_start)
       || (msu_offset >= msu_page1_start + msu_page_size))
       && ((msu_offset < msu_page2_start)
       || (msu_offset >= msu_page2_start + msu_page_size))) {
      printf("offset %08lx out of range (%08lx-%08lx, %08lx-%08lx), reload\n", msu_offset, msu_page1_start,
             msu_page1_start+msu_page_size-1, msu_page2_start, msu_page2_start+msu_page_size-1);
      /* cache miss */
      /* fill buffer */
      set_msu_addr(0x0);
      sd_offload_tgt=2;
      ff_sd_offload=1;
      printf("seek to %08lx, res = %d\n", msu_offset, f_lseek(&durr, msu_offset));
      sd_offload_tgt=2;
      ff_sd_offload=1;
      printf("read res = %d\n", f_read(&durr, file_buf, 16384, &bytes_read2));
      printf("read %d bytes\n", bytes_read2);
      msu_reset(0x0);
      msu_page1_start = msu_offset;
      msu_page2_start = msu_offset + msu_page_size;
    } else {
      if (msu_offset >= msu_page1_start && msu_offset <= msu_page1_start + msu_page_size) {
        msu_reset(0x0000 + msu_offset - msu_page1_start);
        printf("inside page1, new offset: %08lx\n", 0x0000 + msu_offset-msu_page1_start);
        if(!(msu_page2_start == msu_page1_start + msu_page_size)) {
          set_msu_addr(0x2000);
          sd_offload_tgt=2;
          ff_sd_offload=1;
          f_read(&durr, file_buf, 8192, &bytes_read2);
          printf("next page dirty (was: %08lx), loaded page2 (start now: ", msu_page2_start);
          msu_page2_start = msu_page1_start + msu_page_size;
          printf("%08lx)\n", msu_page2_start);
        }
      } else if (msu_offset >= msu_page2_start && msu_offset <= msu_page2_start + msu_page_size) {
        printf("inside page2, new offset: %08lx\n", 0x2000 + msu_offset-msu_page2_start);
        msu_reset(0x2000 + msu_offset - msu_page2_start);
        if(!(msu_page1_start == msu_page2_start + msu_page_size)) {
          set_msu_addr(0x0);
          sd_offload_tgt=2;
          ff_sd_offload=1;
          f_read(&durr, file_buf, 8192, &bytes_read2);
          printf("next page dirty (was: %08lx), loaded page1 (start now: ", msu_page1_start);
          msu_page1_start = msu_page2_start + msu_page_size;
          printf("%08lx)\n", msu_page1_start);
        }
      } else printf("!!!WATWATWAT!!!\n");
    }
    /* clear busy bit */
    set_msu_status(0x00, 0x10);
  }

  if(fpga_status_now & 0x0001) {
    if(fpga_status_now & 0x0004) {
      msu_repeat = 1;
      set_msu_status(0x04, 0x01); /* set bit 2, reset bit 0 */
      printf("Repeat set!\n");
    } else {
      msu_repeat = 0;
      set_msu_status(0x00, 0x05); /* set no bits, reset bit 0+2 */
      printf("Repeat clear!\n");
    }
 
    if(fpga_status_now & 0x0002) {
      printf("PLAY!\n");
      set_msu_status(0x02, 0x01); /* set bit 0, reset bit 1 */
      dac_play();
    } else {
      printf("PAUSE!\n");
      set_msu_status(0x00, 0x03); /* set no bits, reset bit 1+0 */
      dac_pause();
    }
  }

  /* Audio buffer refill */
  if((fpga_status_now & 0x4000) != (fpga_status_prev & 0x4000)) {
    if(fpga_status_now & 0x4000) {
      dac_addr = 0x0;
    } else {
      dac_addr = 0x400;
    }
    set_dac_addr(dac_addr);
    sd_offload_tgt=1;
    ff_sd_offload=1;
    f_read(&file_handle, file_buf, 1024, &bytes_read);
  }

  /* Data buffer refill */
  if((fpga_status_now & 0x2000) != (fpga_status_prev & 0x2000)) {
    printf("data\n");
    if(fpga_status_now & 0x2000) {
      msu_addr = 0x0;
      msu_page1_start = msu_page2_start + msu_page_size;
    } else {
      msu_addr = 0x2000;
      msu_page2_start = msu_page1_start + msu_page_size;
    }
    set_msu_addr(msu_addr);
    sd_offload_tgt=2;
    ff_sd_offload=1;
    printf("data buffer refilled. res=%d page1=%08lx page2=%08lx\n", f_read(&durr, file_buf, 8192, &bytes_read2), msu_page1_start, msu_page2_start);
  }
  fpga_status_prev = fpga_status_now;

  /* handle loop / end */
  if(bytes_read<1024) {
    ff_sd_offload=0;
    sd_offload=0;
    if(msu_repeat) {
      printf("loop\n");
      ff_sd_offload=1;
      sd_offload_tgt=1;
      f_lseek(&file_handle, 44L);
      ff_sd_offload=1;
      sd_offload_tgt=1;
      f_read(&file_handle, file_buf, 1024 - bytes_read, &bytes_read);
    } else {
      set_msu_status(0x00, 0x02); /* clear play bit */
    }
    bytes_read=1024;
  }
}

/* END OF MSU1 STUFF */

  cmd=0;
  uint8_t snes_reset_prev=0, snes_reset_now=0, snes_reset_state=0;
  uint16_t reset_count=0;
  while(fpga_test() == FPGA_TEST_TOKEN) {
    cli_entrycheck();
    sleep_ms(250);
    sram_reliable();
    printf("%s ", get_cic_statename(get_cic_state()));
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
      reset_count++;
    } else {
      sram_reliable();
      snes_main_loop();
    }
    if(reset_count>4) {
      reset_count=0;
      set_mcu_ovr(1);
      snes_reset(1);
      delay_ms(1);
      if(romprops.ramsize_bytes && fpga_test() == FPGA_TEST_TOKEN) {
        writeled(1);
        save_sram(file_lfn, romprops.ramsize_bytes, SRAM_SAVE_ADDR);
        writeled(0);
      }
      rdyled(1);
      readled(1);
      writeled(1);
      snes_reset(0);
      while(get_snes_reset());
      snes_reset(1);
      delay_ms(200);
      goto restart;
    }
    snes_reset_prev = snes_reset_now;
  }
  /* fpga test fail: panic */
  led_panic();
}


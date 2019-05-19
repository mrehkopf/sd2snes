#include <arm/NXP/LPC17xx/LPC17xx.h>
#include <string.h>
#include "config.h"
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
#include "msu1.h"
#include "rtc.h"
#include "sysinfo.h"
#include "cfg.h"

int i;

int sd_offload = 0, ff_sd_offload = 0, sd_offload_tgt = 0;
int sd_offload_partial = 0;
int sd_offload_start_mid = 0;
int sd_offload_end_mid = 0;
uint16_t sd_offload_partial_start = 0;
uint16_t sd_offload_partial_end = 0;

int snes_boot_configured, firstboot;
extern const uint8_t *fpga_config;

volatile enum diskstates disk_state;
extern volatile tick_t ticks;
extern snes_romprops_t romprops;
extern volatile int reset_changed;

extern volatile cfg_t CFG;
extern volatile mcu_status_t STM;
extern volatile snes_status_t STS;

void menu_cmd_readdir(void) {
  uint8_t path[256];
  SNES_FTYPE filetypes[16];
  snes_get_filepath(path, 256);
  snescmd_readstrn(filetypes, SNESCMD_MCU_PARAM + 8, sizeof(filetypes));
  uint32_t tgt_addr = snescmd_readlong(SNESCMD_MCU_PARAM + 4) & 0xffffff;
printf("path=%s tgt=%06lx types=", path, tgt_addr);
uart_puts_hex((char*)filetypes);
uart_putc('\n');
  scan_dir(path, tgt_addr, filetypes);
}

int main(void) {
  SNES_CIC_PAIR_REG->FIODIR = BV(SNES_CIC_PAIR_BIT);
  BITBAND(SNES_CIC_PAIR_REG->FIOSET, SNES_CIC_PAIR_BIT) = 1;

  BITBAND(DAC_DEMREG->FIODIR, DAC_DEMBIT) = 1;
  BITBAND(DAC_DEMREG->FIOSET, DAC_DEMBIT) = 1;

 /* disable pull-up on fake USB_CONNECT pin, set P1.30 function to VBUS */
  USB_CONN_MODEREG |= BV(USB_CONN_MODEBIT);
  USB_VBUS_PINSEL |= BV(USB_VBUS_PINSELBIT);
  USB_VBUS_MODEREG |= BV(USB_VBUS_MODEBIT);

 /* connect UART3 on P0[25:26] + SSP0 on P0[15:18] */
  LPC_PINCON->PINSEL1 = BV(18) | BV(19) | BV(20) | BV(21) /* UART3 */
                      | BV(3) | BV(5);                    /* SSP0 (FPGA) except SS */
  LPC_PINCON->PINSEL0 = BV(31);                           /* SSP0 */
  LPC_GPIO0->FIODIR = BV(16);                             /* SSP0 SS */

 /* pull-down CIC data lines */
  BITBAND(SNES_CIC_D0_MODEREG, SNES_CIC_D0_MODEBIT) = 1;
  BITBAND(SNES_CIC_D0_MODEREG, SNES_CIC_D0_MODEBIT - 1) = 1;
  BITBAND(SNES_CIC_D1_MODEREG, SNES_CIC_D1_MODEBIT) = 1;
  BITBAND(SNES_CIC_D1_MODEREG, SNES_CIC_D1_MODEBIT - 1) = 1;

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
  FPGA_CLK_PINSEL |= BV(FPGA_CLK_PINSELBIT) | BV(FPGA_CLK_PINSELBIT - 1); /* MAT3.x (FPGA clock) */
  led_std();
  sdn_init();
  printf("\n\n" DEVICE_NAME "\n===============\nfw ver.: " CONFIG_VERSION "\ncpu clock: %d Hz\n", CONFIG_CPU_FREQUENCY);
printf("PCONP=%lx\n", LPC_SC->PCONP);

  file_init();
  cic_init(0);
/* setup timer (fpga clk) */
  LPC_TIM3->TCR=2;                         // counter reset
  LPC_TIM3->CTCR=0;                        // increment TC on PCLK
  LPC_TIM3->PR=0;                          // prescale = 1:1 (increment TC every PCLK)
  LPC_TIM3->EMR=EMR_FPGACLK_EMCxTOGGLE;    // toggle MAT3 output every time TC == MR
  LPC_TIM3->MCR=MCR_FPGACLK_MRxR;          // reset TC when == MR
  TMR_FPGACLK_MR=1;                        // MR = 1 -> toggle MAT3 output every 2 PCLK -> FPGA_CLK = PCLK / 4
  LPC_TIM3->TCR=1;                         // start the counter
  fpga_init();
  firstboot = 1;
  while(1) {
    snes_boot_configured = 0;
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
      if(disk_status(0) & (STA_NODISK)) {
        snes_bootprint("        No SD Card found!       \0");
        while(disk_status(0) & (STA_NODISK));
        delay_ms(200);
      }
      file_open((uint8_t*)MENU_FILENAME, FA_READ);
      if(file_status != FILE_OK) {
        snes_bootprint("  " MENU_FILENAME " not found!  \0");
        while(disk_status(0) == 0);
      } else {
        card_go = 1;
      }
      file_close();
    }
    if(fpga_config == FPGA_ROM) snes_bootprint("           Loading ...          \0");
    led_pwm();
    rdyled(1);
    readled(0);
    writeled(0);

    cic_init(0);

    if(firstboot) {
      cfg_load();
      cfg_save();
      cfg_validity_check_recent_games();
    }
    if(fpga_config != FPGA_BASE) fpga_pgm((uint8_t*)FPGA_BASE);
    cfg_dump_recent_games_for_snes(SRAM_LASTGAME_ADDR);
    led_set_brightness(CFG.led_brightness);

    /* load menu */
    sram_writelong(0x12345678, SRAM_SCRATCHPAD);
    fpga_dspx_reset(1);
    uart_putc('(');
    load_rom((uint8_t*)MENU_FILENAME, SRAM_MENU_ADDR, 0);
    /* force memory size + mapper */
    set_rom_mask(0x3fffff);
    set_mapper(0x7);
    /* disable all cheats+hooks */
    fpga_write_cheat(7, 0x3f00);
    /* reset DAC */
    dac_pause();
    dac_reset(0);
    uart_putc(')');
    uart_putcrlf();

    sram_writebyte(0, SRAM_CMD_ADDR);

    if((rtc_state = rtc_isvalid()) != RTC_OK) {
      printf("RTC invalid!\n");
      STM.rtc_valid = 0xff;
      set_bcdtime(0x20120701000000LL);
      set_fpga_time(0x20120701000000LL);
      invalidate_rtc();
    } else {
      printf("RTC valid!\n");
      STM.rtc_valid = 0;
      set_fpga_time(get_bcdtime());
    }
    sram_memset(SRAM_SYSINFO_ADDR, 13*40, 0x20);
    printf("SNES GO!\n");
    snes_reset(1);
    fpga_reset_srtc_state();
    if(!firstboot) {
      if(STS.is_u16 && (STS.u16_cfg & 0x01)) {
        delay_ms(59*SNES_RESET_PULSELEN_MS);
      }
    }
    firstboot = 0;
    delay_ms(SNES_RESET_PULSELEN_MS);
    sram_writebyte(32, SRAM_CMD_ADDR);

    fpga_set_dac_boost(CFG.msu_volume_boost);
    cfg_load_to_menu();
    snes_reset(0);

/* Since the Super Nt workaround requires pair mode to be disabled during reset
   (or the Super Nt doesn't boot), pair mode can only be enabled after reset,
   so we need to get the CIC state later to actually detect pair mode.
   A delay is required so the CICs can settle before getting the state. */
    delay_ms(100);
    enum cicstates cic_state = get_cic_state();
    switch(cic_state) {
      case CIC_PAIR:
        STM.pairmode = 1;
        printf("PAIR MODE ENGAGED!\n");
        cic_pair(CFG.vidmode_menu, CFG.vidmode_menu);
        break;
      case CIC_SCIC:
        STM.pairmode = 1;
        break;
      default:
        STM.pairmode = 0;
    }
    status_load_to_menu();

    uint8_t cmd = 0;
    uint64_t btime = 0;
    uint32_t filesize=0;
    printf("test sram\n");
    while(!sram_reliable()) cli_entrycheck();
    printf("ok\n");
//while(1) {
//  delay_ms(1000);
//  printf("Estimated SNES master clock: %ld Hz\n", get_snes_sysclk());
//}
  //sram_hexdump(SRAM_DB_ADDR, 0x200);
  //sram_hexdump(SRAM_MENU_ADDR, 0x400);
    while(!cmd) {
      /* tell the menu we're ready to accept commands */
      snescmd_writebyte(MCU_CMD_RDY, SNESCMD_SNES_CMD);
      cmd=menu_main_loop();
      /* acknowledge command */
      echo_mcu_cmd();
      printf("cmd: %d\n", cmd);
      status_save_from_menu();
      uart_putc('-');
      switch(cmd) {
        case SNES_CMD_LOADROM:
          get_selected_name(file_lfn);
          printf("Selected name: %s\n", file_lfn);
          cfg_add_last_game(file_lfn);
          filesize = load_rom(file_lfn, SRAM_ROM_ADDR, LOADROM_WITH_SRAM | LOADROM_WITH_RESET | LOADROM_WAIT_SNES);
          break;
        case SNES_CMD_SETRTC:
          /* get time from RAM */
          btime = snescmd_gettime();
          /* set RTC */
          set_bcdtime(btime);
          set_fpga_time(btime);
          cmd=0; /* stay in menu loop */
          break;
        case SNES_CMD_SYSINFO:
          /* go to sysinfo loop */
          sysinfo_loop();
          cmd=0; /* stay in menu loop */
          break;
        case SNES_CMD_LOADSPC:
          /* load SPC file */
          get_selected_name(file_lfn);
          printf("Selected name: %s\n", file_lfn);
          filesize = load_spc(file_lfn, SRAM_SPC_DATA_ADDR, SRAM_SPC_HEADER_ADDR);
          cmd=0; /* stay in menu loop */
          break;
        case SNES_CMD_RESET:
          /* process RESET request from SNES */
          printf("RESET requested by SNES\n");
          snes_reset_pulse();
          cmd=0; /* stay in menu loop */
          break;
        case SNES_CMD_LOADLAST:
          cfg_get_last_game(file_lfn, snes_get_mcu_param() & 0xff);
          printf("Selected name: %s\n", file_lfn);
          cfg_add_last_game(file_lfn);
          filesize = load_rom(file_lfn, SRAM_ROM_ADDR, LOADROM_WITH_SRAM | LOADROM_WITH_RESET | LOADROM_WAIT_SNES);
          break;
/*        case SNES_CMD_SET_ALLOW_PAIR:
          cfg_set_pair_mode_allowed(snes_get_mcu_param() & 0xff);
          break;
        case SNES_CMD_SELECT_FILE:
          menu_cmd_select_file();
          cmd=0;
          break;
        case SNES_CMD_SELECT_LAST_FILE:
          menu_cmd_select_last_file();
          cmd=0;
          break;*/
        case SNES_CMD_READDIR:
          menu_cmd_readdir();
          cmd=0; /* stay in menu loop */
          break;
        case SNES_CMD_GAMELOOP:
          /* enter game loop immediately */
          break;
        case SNES_CMD_SAVE_CFG:
          /* save config */
          cfg_get_from_menu();
          cic_init(CFG.pair_mode_allowed);
          if(CFG.pair_mode_allowed && cic_state == CIC_SCIC) {
            delay_ms(100);
            if(get_cic_state() == CIC_PAIR) {
              cic_pair(CFG.vidmode_menu, CFG.vidmode_menu);
            }
          }
          cic_videomode(CFG.vidmode_menu);
          fpga_set_dac_boost(CFG.msu_volume_boost);
          cfg_save();
          cmd=0; /* stay in menu loop */
          break;
        case SNES_CMD_LED_BRIGHTNESS:
          cfg_get_from_menu();
          led_set_brightness(CFG.led_brightness);
          cmd=0;
          break;
        case SNES_CMD_LOAD_CHT:
          /* load cheats */
          cmd=0; /* stay in menu loop */
          break;
        case SNES_CMD_SAVE_CHT:
          /* save cheats */
// XXX          cheat_save_from_menu()
          cmd=0; /* stay in menu loop */
          break;
        default:
          printf("unknown cmd: %d\n", cmd);
          cmd=0; /* unknown cmd: stay in loop */
          break;
      }
    }
    printf("loaded %lu bytes\n", filesize);
    printf("cmd was %x, going to snes main loop\n", cmd);

    /* clear SNES cmd */
    snes_set_mcu_cmd(0);

    if(romprops.has_msu1) {
      while(!msu1_loop());
      prepare_reset();
      continue;
    }

    cmd=0;
    int loop_ticks = getticks();
// uint8_t snes_res;
    while(fpga_test() == FPGA_TEST_TOKEN) {
      cli_entrycheck();
//        sleep_ms(250);
      sram_reliable();
      if(reset_changed) {
        printf("reset\n");
        reset_changed = 0;
// TODO have FPGA automatically reset SRTC on detected reset
        fpga_reset_srtc_state();
      }
      if(get_snes_reset_state() == SNES_RESET_LONG) {
        prepare_reset();
        break;
      } else {
        if(getticks() > loop_ticks + 25) {
          loop_ticks = getticks();
 //         sram_reliable();
          printf("%s ", get_cic_statename(get_cic_state()));
          cmd=snes_main_loop();
          if(cmd) {
            switch(cmd) {
              case SNES_CMD_RESET_LOOP_FAIL:
                snes_reset_loop();
                break;
              case SNES_CMD_RESET:
                snes_reset_pulse();
                break;
              case SNES_CMD_RESET_TO_MENU:
                prepare_reset();
                goto snes_loop_out;
              default:
                printf("unknown cmd: %02x\n", cmd);
                break;
            }
            snes_set_mcu_cmd(0);
          }
        }
      }
    }
    /* fpga test fail: panic */
    snes_loop_out:
    if(fpga_test() != FPGA_TEST_TOKEN){
      led_panic(LED_PANIC_FPGA_DEAD);
    }
    /* else reset */
  }
}

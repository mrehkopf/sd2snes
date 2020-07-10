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

   snes.c: SNES hardware control and monitoring
*/

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include <string.h>
#include "bits.h"
#include "config.h"
#include "uart.h"
#include "snes.h"
#include "memory.h"
#include "fileops.h"
#include "ff.h"
#include "led.h"
#include "smc.h"
#include "timer.h"
#include "cli.h"
#include "fpga.h"
#include "fpga_spi.h"
#include "rtc.h"
#include "cfg.h"
#include "sgb.h"

uint32_t saveram_crc, saveram_crc_old;
uint8_t sram_crc_valid;
uint32_t sram_crc_romsize;
extern snes_romprops_t romprops;
extern int snes_boot_configured;

extern cfg_t CFG;

volatile int reset_changed;
volatile int reset_pressed;

mcu_status_t STM = {
  .rtc_valid = 0xff,
  .num_recent_games = 0,
  .pairmode = 0
};

snes_status_t STS = {
  .is_u16 = 0,
  .u16_cfg = 0xff,
  .has_satellaview = 0
};

// These rom hashes are all based on unheadered contents in sram.
// Known conflicts with crc32 implementation.  Match count is always 2.
// 0x06F5FCAD, 0x2DCCDC2F, 0x47AC91A5, 0x566A91FD
// 0x61506060, 0x6D869DD1, 0x7B55EA0F, 0x81C1BA16
// 0xD8841B4B, 0xDEFABA49, 0xE7E44192
typedef struct { uint32_t crc; uint32_t base; uint32_t size; } SramOffset;
const SramOffset SramOffsetTable[] = {
  // GSU
  { 0x5cb1755a, 0x7c00, 0x0400 }, // yoshi's island (us)
  { 0x42115ad4, 0x7c00, 0x0400 }, // yoshi's island (us) 1.1
  { 0x08f007cc, 0x7c00, 0x0400 }, // yoshi's island (eu)
  { 0x8a699987, 0x7c00, 0x0400 }, // yoshi's island (eu) 1.1
  { 0xb9b78a85, 0x7c00, 0x0400 }, // yoshi's island (jp)
  { 0x82efeef5, 0x7c00, 0x0400 }, // yoshi's island (jp) 1.1
  { 0x7c8fb8d3, 0x7c00, 0x0400 }, // yoshi's island (jp) 1.2

  // SA1
  { 0x0acd464f, 0x0000, 0x2000 }, // super mario rpg (us)
  { 0x44604774, 0x0000, 0x2000 }, // super mario rpg (jp)

  { 0x9897b7b6, 0x1F00, 0x0100 }, // kirby super star (us)
  { 0xdf749c91, 0x1F00, 0x0100 }, // kirby super star (eu)
  { 0x045c941a, 0x1F00, 0x0100 }, // hoshi no kirby super deluxe (jp)

  { 0xfdcd089c, 0x5E00, 0x0200 }, // kirby's dreamland (us)
  { 0x52707a84, 0x5E00, 0x0200 }, // hoshi no kirby 3 (jp)

  { 0xb7ad7461, 0x0100, 0x0C00 }, // marvelous (jp)
  { 0xb803d023, 0x0100, 0x0C00 }, // marvelous 1.06 (us)
  { 0x7a76f989, 0x0100, 0x0C00 }, // marvelous 1.07 (us Tashi-DackR)
  { 0x186dddd3, 0x0100, 0x0C00 }  // marvelous 1.07 (us DackR)

};

void prepare_reset() {
  snes_reset(1);
  delay_ms(SNES_RESET_PULSELEN_MS);
  if(romprops.sramsize_bytes && fpga_test() == FPGA_TEST_TOKEN) {
    writeled(1);
    save_srm(file_lfn, romprops.ramsize_bytes, SRAM_SAVE_ADDR);
    writeled(0);
  }
  // don't save SGB RTC since we are in reset and it may be undefined
  rdyled(1);
  readled(1);
  writeled(1);
  snes_reset(0);
  while(get_snes_reset());
  snes_reset(1);
  fpga_dspx_reset(1);
  delay_ms(200);
}

void snes_init() {
  /* put reset level on reset pin */
  BITBAND(SNES_RESET_REG->FIOCLR, SNES_RESET_BIT) = 1;
  /* reset the SNES */
  snes_reset(1);
}

void snes_reset_pulse() {
  snes_reset(1);
  delay_ms(SNES_RESET_PULSELEN_MS);
  snes_reset(0);
}

/*
 * sets the SNES reset state.
 *
 *  state: put SNES in reset state when 1, release when 0
 */
void snes_reset(int state) {
  BITBAND(SNES_RESET_REG->FIODIR, SNES_RESET_BIT) = state;
}

/*
 * provides a mini reset environment to speed reset for clock synchronization
 *
 * returns: upon loop exit returns the current non-reset related command
 */
uint8_t snes_reset_loop(void) {
  uint8_t cmd = 0;
  tick_t starttime = getticks();
  while(fpga_test() == FPGA_TEST_TOKEN) {
    cmd = snes_get_mcu_cmd();
    // 100ms timeout in case the reset hook is defeated somehow
    if(getticks() > starttime + SNES_RESET_LOOP_TIMEOUT) {
      cmd = SNES_CMD_RESET_LOOP_TIMEOUT;
    }
    if (cmd) {
      printf("snes_reset_loop: cmd=%hhx\n", cmd);
      switch (cmd) {
        case SNES_CMD_RESET_LOOP_FAIL:
          snes_set_mcu_cmd(0);
          cmd = 0;
          snes_reset_pulse();
          //delay_us(SNES_RELEASE_RESET_DELAY_US);
          break;
        case SNES_CMD_RESET_LOOP_PASS:
        case SNES_CMD_RESET_LOOP_TIMEOUT:
          snes_set_mcu_cmd(0);
          cmd = 0;
        default:
          goto snes_reset_loop_out;
      }
    }
  }

snes_reset_loop_out:
  return cmd;
}

/*
 * gets the SNES reset state.
 *
 * returns: 1 when reset, 0 when not reset
 */
uint8_t get_snes_reset() {
  return !BITBAND(SNES_RESET_REG->FIOPIN, SNES_RESET_BIT);
}

uint8_t get_snes_reset_state(void) {

  static tick_t rising_ticks;
  tick_t rising_ticks_tmp = getticks();

  static uint8_t resbutton=0, resbutton_prev=0;
  static uint8_t pushes=0, reset_flag=0;

  uint8_t first_detection=0;

  uint8_t result=SNES_RESET_NONE;

  /* first check: Had the reset been pushed?
     If yes: - check for igr's double reset time and ...
             - release  */
  if(reset_flag) {
    /* 230ms are gone (time for igr's double reset)
       if time is exceeded, set pushes and reset_flag to zero  */
    if(rising_ticks_tmp > rising_ticks + 22) {
      pushes = 0;
      reset_flag = 0;
    }

    /* release reset from the sd2snes-side */
    snes_reset(0);
    delay_us(SNES_RELEASE_RESET_DELAY_US);
  }

  /* now start new cycle */
  resbutton = get_snes_reset(); /* SNES in reset? */

  if(resbutton) { /* Yes (e.g. reset-button is pressed) */

    result = cfg_is_reset_to_menu() ? SNES_RESET_LONG : SNES_RESET_SHORT;
    reset_flag = 1;

    if(!resbutton_prev) { /* push, reset tick-timer */
      pushes++;
      rising_ticks = getticks();
      if(pushes == 1) {
        first_detection = 1;
      }
      if(pushes == 2) { /* second push within 230ms -> initiate long reset */
        result = SNES_RESET_LONG;
      }
    }

    if(rising_ticks_tmp > rising_ticks + 99) { /* a (normal) long reset is detected */
      result = SNES_RESET_LONG;
    }

   /* no need to have the reset_flag set anymore
      also reset the number of pushes */
    if(result == SNES_RESET_LONG){
      pushes = 0;
      reset_flag = 0;
    }
  }

  if(reset_flag) {
    snes_reset(1);
    if(first_detection)
      delay_ms(190);
    else
      delay_ms(SNES_RESET_PULSELEN_MS);
  }

  resbutton_prev = resbutton;
  return result;
}

/*
 * SD2SNES game loop.
 * monitors SRAM changes and other things
 */
uint32_t diffcount = 0, samecount = 0, didnotsave = 0, save_failed = 0, last_save_failed = 0;
uint8_t sram_valid = 0;
uint8_t snes_main_loop() {
  recalculate_sram_range();
  
  /* save the GB RTC if enabled */
  sgb_gtc_save(file_lfn);
  
  if(romprops.sramsize_bytes) {
    saveram_crc = calc_sram_crc(SRAM_SAVE_ADDR + romprops.srambase, romprops.sramsize_bytes);
    sram_valid = sram_reliable();
    if(crc_valid && sram_valid) {
      if(save_failed) didnotsave++;
      if(saveram_crc != saveram_crc_old) {
        if(samecount) {
          diffcount=1;
        } else {
          diffcount++;
          didnotsave++;
        }
        samecount=0;
      }
      if(saveram_crc == saveram_crc_old) {
        samecount++;
      }
      if(diffcount>=1 && samecount==5) {
        printf("SaveRAM CRC: 0x%04lx; saving %s\n", saveram_crc, file_lfn);
        writeled(1);
        save_srm(file_lfn, romprops.ramsize_bytes, SRAM_SAVE_ADDR);
        last_save_failed = save_failed;
        save_failed = file_res ? 1 : 0;
        didnotsave = save_failed ? 25 : 0;
        writeled(0);
      }
      if(didnotsave>50) {
        printf("periodic save (sram contents keep changing or previous save failed)\n");
        diffcount=0;
        writeled(1);
        save_srm(file_lfn, romprops.ramsize_bytes, SRAM_SAVE_ADDR);
        last_save_failed = save_failed;
        save_failed = file_res ? 1 : 0;
        didnotsave = save_failed ? 25 : 0;
        writeled(!last_save_failed);
      }
      saveram_crc_old = saveram_crc;
    }
    printf("crc=%lx crc_valid=%d sram_valid=%d diffcount=%ld samecount=%ld, didnotsave=%ld\n", saveram_crc, crc_valid, sram_valid, diffcount, samecount, didnotsave);
  }
  return snes_get_mcu_cmd();
}

/*
 * SD2SNES menu loop.
 * monitors menu selection. return when selection was made.
 */
uint8_t menu_main_loop() {
  uint8_t cmd = 0;
  snes_set_mcu_cmd(0);
  while(!cmd) {
    if(!get_snes_reset()) {
      while(!sram_reliable())printf("hurr\n");
      cmd = snes_get_mcu_cmd();
    }
    if(get_snes_reset()) {
      cmd = 0;
    }
    sleep_ms(20);
    cli_entrycheck();
  }
  return cmd;
}

void get_selected_name(uint8_t* fn) {
  uint32_t cwdaddr;
  uint32_t fdaddr;
  char *dot;
  cwdaddr = snes_get_mcu_param();
  fdaddr = snescmd_readlong(SNESCMD_MCU_CMD + 0x08);
  printf("cwd addr=%lx  fdaddr=%lx\n", cwdaddr, fdaddr);
  uint16_t count = sram_readstrn(fn, cwdaddr, 256);
  if(count && fn[count-1] != '/') {
    fn[count] = '/';
    count++;
  }
  sram_readstrn(fn+count, fdaddr+6+SRAM_MENU_ADDR, 256-count);
  /* restore hidden file extension */
  if((dot=strchr((char*)fn, 1))) {
    *dot = '.';
  }
}

void snes_bootprint(void* msg) {
  if(!snes_boot_configured) {
    fpga_rompgm();
    sram_writebyte(0, SRAM_CMD_ADDR);
    load_bootrle(SRAM_MENU_ADDR);
    set_saveram_mask(0x1fff);
    set_rom_mask(0x3fffff);
    set_mapper(0x7);
    snes_reset_pulse();
    snes_boot_configured = 1;
    sleep_ms(200);
  }
  printf("snes_bootprint: \"%s\"\n", (char*)msg);
  sram_writeblock(msg, SRAM_CMD_ADDR, 33);
}

void snes_menu_errmsg(int err, void* msg) {
  sram_writeblock(msg, SRAM_CMD_ADDR+1, 64);
  sram_writebyte(err, SRAM_CMD_ADDR);
}

uint8_t snes_get_last_game_index() {
  return sram_readbyte(SRAM_PARAM_ADDR);
}

uint8_t snes_get_mcu_cmd() {
  fpga_set_snescmd_addr(SNESCMD_MCU_CMD);
  return fpga_read_snescmd();
}

void snes_set_mcu_cmd(uint8_t cmd) {
  fpga_set_snescmd_addr(SNESCMD_MCU_CMD);
  fpga_write_snescmd(cmd);
}

uint8_t snes_get_snes_cmd() {
  fpga_set_snescmd_addr(SNESCMD_SNES_CMD);
  return fpga_read_snescmd();
}

void snes_set_snes_cmd(uint8_t cmd) {
  fpga_set_snescmd_addr(SNESCMD_SNES_CMD);
  fpga_write_snescmd(cmd);
}

void echo_mcu_cmd() {
  snes_set_snes_cmd(snes_get_mcu_cmd());
}

uint32_t snes_get_mcu_param() {
  fpga_set_snescmd_addr(SNESCMD_MCU_PARAM);
  return (fpga_read_snescmd()
         | ((uint32_t)fpga_read_snescmd() << 8)
         | ((uint32_t)fpga_read_snescmd() << 16)
         | ((uint32_t)fpga_read_snescmd() << 24));
}

void snescmd_writeshort(uint16_t val, uint16_t addr) {
  fpga_set_snescmd_addr(addr);
  fpga_write_snescmd(val & 0xff);
  fpga_write_snescmd(val >> 8);
}

void snescmd_writebyte(uint8_t val, uint16_t addr) {
  fpga_set_snescmd_addr(addr);
  fpga_write_snescmd(val);
}

uint8_t snescmd_readbyte(uint16_t addr) {
  fpga_set_snescmd_addr(addr);
  return fpga_read_snescmd();
}

uint16_t snescmd_readshort(uint16_t addr) {
  uint16_t data = 0;
  fpga_set_snescmd_addr(addr);
  data = fpga_read_snescmd();
  data |= (uint16_t)fpga_read_snescmd() << 8;
  return data;
}

uint32_t snescmd_readlong(uint16_t addr) {
  uint32_t data = 0;
  fpga_set_snescmd_addr(addr);
  data = fpga_read_snescmd();
  data |= (uint32_t)fpga_read_snescmd() << 8;
  data |= (uint32_t)fpga_read_snescmd() << 16;
  data |= (uint32_t)fpga_read_snescmd() << 24;
  return data;
}

void snes_get_filepath(uint8_t *buffer, uint16_t length) {
  uint32_t path_address = snescmd_readlong(SNESCMD_MCU_PARAM);
  sram_readstrn(buffer, path_address, length-1);
printf("%s\n", buffer);
}

void snescmd_writeblock(void *buf, uint16_t addr, uint16_t size) {
  fpga_set_snescmd_addr(addr);
  while(size--) {
    fpga_write_snescmd(*(uint8_t*)buf++);
  }
}

uint64_t snescmd_gettime(void) {
  fpga_set_snescmd_addr(SNESCMD_MCU_PARAM);
  uint8_t data[12];
  for(int i=0; i<12; i++) {
    data[11-i] = fpga_read_snescmd();
  }
  return srtctime2bcdtime(data);
}

uint16_t snescmd_readstrn(void *buf, uint16_t addr, uint16_t size) {
  fpga_set_snescmd_addr(addr);
  uint16_t elemcount = 0;
  uint16_t count = size;
  uint8_t* tgt = buf;
  while(count--) {
    if(!(*(tgt++) = fpga_read_snescmd())) break;
    elemcount++;
  }
  tgt--;
  if(*tgt) *tgt = 0;
  return elemcount;
}

#define BRAM_SIZE (256 - (SNESCMD_MCU_PARAM - SNESCMD_MCU_CMD))
void snescmd_prepare_nmihook() {
  uint16_t bram_src = sram_readshort(SRAM_MENU_ADDR + MENU_ADDR_BRAM_SRC);
  uint8_t bram[BRAM_SIZE];
  sram_readblock(bram, SRAM_MENU_ADDR + bram_src, BRAM_SIZE);
//  snescmd_writeblock(bram, SNESCMD_HOOKS, 40);
  snescmd_writeblock(bram, SNESCMD_MCU_PARAM, BRAM_SIZE);
}

void status_load_to_menu() {
  sram_writeblock(&STM, SRAM_MCU_STATUS_ADDR, sizeof(mcu_status_t));
}

void status_save_from_menu() {
  sram_readblock(&STS, SRAM_SNES_STATUS_ADDR, sizeof(snes_status_t));
}

/*
   The goals of this function are the following:
   - detect a small, fixed set of popular games where the save location is a known, strict subset of sram.
     this avoids switching to the periodic save to sd mode.
   - revert to full sram save if there is any change in the rom.  this includes minor hacks that don't change save location.
   - not support any user control beyond rom modification.
     user control is very error prone: bad crc when rom is modified, incorrect save region definition, etc.
   - very limited rom hack coverage.  if the hack changes then it will no longer benefit without an updated crc.

   The full sram location is still loaded and saved.  The restricted bounds are only used to detect when to save.
*/
void recalculate_sram_range() {
  if (!sram_crc_valid && sram_valid) {
    printf("calculating rom hash (base=%06lx, size=%ld): ", SRAM_ROM_ADDR + romprops.load_address, sram_crc_romsize);
    /*
      there is a very small chance of collision.  there are several ways to avoid this:
      - incorporate (concatenate) checksum16 or other information
      - use a better hash function like sha-256
     */
    uint32_t crc = calc_sram_crc(SRAM_ROM_ADDR + romprops.load_address, sram_crc_romsize);
    printf("%08lx\n", crc);

    if (crc_valid) {
      sram_crc_valid = 1;

      for (uint32_t i = 0; i < (sizeof(SramOffsetTable)/sizeof(SramOffset)); i++) {
        if (crc == SramOffsetTable[i].crc) {
          romprops.srambase       = SramOffsetTable[i].base;
          romprops.sramsize_bytes = SramOffsetTable[i].size;
          printf("rom hash match: base=%lx size=%lx\n", romprops.srambase, romprops.sramsize_bytes);
          break;
        }
      }
    }
  }
}

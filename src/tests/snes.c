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

uint8_t initloop=1;
uint32_t saveram_crc, saveram_crc_old;
extern snes_romprops_t romprops;

volatile int reset_changed;

void prepare_reset() {
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
  fpga_dspx_reset(1);
  delay_ms(200);
}

void snes_init() {
  /* put reset level on reset pin */
  BITBAND(SNES_RESET_REG->FIOCLR, SNES_RESET_BIT) = 1;
  /* reset the SNES */
  snes_reset(1);
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
 * gets the SNES reset state.
 *
 * returns: 1 when reset, 0 when not reset
 */
uint8_t get_snes_reset() {
  return !BITBAND(SNES_RESET_REG->FIOPIN, SNES_RESET_BIT);
}

/*
 * SD2SNES main loop.
 * monitors SRAM changes and other things
 */
uint32_t diffcount = 0, samecount = 0, didnotsave = 0;
uint8_t sram_valid = 0;
void snes_main_loop() {
  if(!romprops.ramsize_bytes)return;
  if(initloop) {
    saveram_crc_old = calc_sram_crc(SRAM_SAVE_ADDR, romprops.ramsize_bytes);
    initloop=0;
  }
  saveram_crc = calc_sram_crc(SRAM_SAVE_ADDR, romprops.ramsize_bytes);
  sram_valid = sram_reliable();
  if(crc_valid && sram_valid) {
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
      printf("SaveRAM CRC: 0x%04lx; saving\n", saveram_crc);
      writeled(1);
      save_sram(file_lfn, romprops.ramsize_bytes, SRAM_SAVE_ADDR);
      writeled(0);
      didnotsave=0;
    }
    if(didnotsave>50) {
      printf("periodic save (sram contents keep changing...)\n");
      diffcount=0;
      writeled(1);
      save_sram(file_lfn, romprops.ramsize_bytes, SRAM_SAVE_ADDR);
      didnotsave=0;
      writeled(0);
    }
    saveram_crc_old = saveram_crc;
  }
  printf("crc=%lx crc_valid=%d sram_valid=%d diffcount=%ld samecount=%ld, didnotsave=%ld\n", saveram_crc, crc_valid, sram_valid, diffcount, samecount, didnotsave);
}

/*
 * SD2SNES menu loop.
 * monitors menu selection. return when selection was made.
 */
uint8_t menu_main_loop() {
  uint8_t cmd = 0;
  sram_writebyte(0, SRAM_CMD_ADDR);
  while(!cmd) {
    if(!get_snes_reset()) {
      while(!sram_reliable())printf("hurr\n");
      cmd = sram_readbyte(SRAM_CMD_ADDR);
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
  uint32_t addr;
  addr = sram_readlong(SRAM_PARAM_ADDR);
  printf("fd addr=%lx\n", addr);
  sram_readblock(fn, addr + 7 + SRAM_MENU_ADDR, 256);
}

void snes_bootprint(void* msg) {
  sram_writeblock(msg, SRAM_CMD_ADDR, 33);
}

void snes_menu_errmsg(int err, void* msg) {
  sram_writeblock(msg, SRAM_CMD_ADDR+1, 64);
  sram_writebyte(err, SRAM_CMD_ADDR);
}


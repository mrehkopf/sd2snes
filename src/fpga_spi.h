/* sd2snes - SD card based universal cartridge for the SNES
   Copyright (C) 2009-2010 Maximilian Rehkopf <otakon@gmx.net>
   uC firmware portion

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

   fpga_spi.h: functions for SPI ctrl, SRAM interfacing and feature configuration
*/

#ifndef _FPGA_SPI_H
#define _FPGA_SPI_H

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "spi.h"
#include "config.h"

#define FPGA_SS_BIT 16
#define FPGA_SS_REG LPC_GPIO0

#define FPGA_SELECT() do {FPGA_TX_SYNC(); BITBAND(FPGA_SS_REG->FIOCLR, FPGA_SS_BIT) = 1;} while (0)
#define FPGA_SELECT_ASYNC() do {BITBAND(FPGA_SS_REG->FIOCLR, FPGA_SS_BIT) = 1;} while (0)
#define FPGA_DESELECT() do {FPGA_TX_SYNC(); BITBAND(FPGA_SS_REG->FIOSET, FPGA_SS_BIT) = 1;} while (0)
#define FPGA_DESELECT_ASYNC() do {BITBAND(FPGA_SS_REG->FIOSET, FPGA_SS_BIT) = 1;} while (0)

#define FPGA_TX_SYNC()     spi_tx_sync()
#define FPGA_TX_BYTE(x)    spi_tx_byte(x)
#define FPGA_RX_BYTE()     spi_rx_byte()
#define FPGA_TXRX_BYTE(x)  spi_txrx_byte(x)
#define FPGA_TX_BLOCK(x,y) spi_tx_block(x,y)
#define FPGA_RX_BLOCK(x,y) spi_rx_block(x,y)

#define FEAT_CMD_UNLOCK    (1 << 5)
#define FEAT_213F          (1 << 4)
#define FEAT_MSU1          (1 << 3)
#define FEAT_SRTC          (1 << 2)
#define FEAT_ST0010        (1 << 1)
#define FEAT_DSPX          (1 << 0)

#define FPGA_WAIT_RDY()    do {while(BITBAND(SSP_REGS->SR, SSP_BSY)); while(!BITBAND(FPGA_MCU_RDY_REG->FIOPIN, FPGA_MCU_RDY_BIT));} while (0)

/* command parameters */
#define FPGA_MEM_AUTOINC        (0x8)
#define FPGA_SDDMA_PARTIAL      (0x4)
#define FPGA_TGT_MEM      (0x0)
#define FPGA_TGT_DACBUF   (0x1)
#define FPGA_TGT_MSUBUF   (0x2)

/* commands */
#define FPGA_CMD_SETADDR         (0x00)
#define FPGA_CMD_SETROMMASK      (0x10)
#define FPGA_CMD_SETRAMMASK      (0x20)
#define FPGA_CMD_SETMAPPER(x)    (0x30 | (x & 15))
#define FPGA_CMD_SDDMA           (0x40)
#define FPGA_CMD_SDDMA_RANGE     (0x60)
#define FPGA_CMD_READMEM         (0x80)
#define FPGA_CMD_WRITEMEM        (0x90)
#define FPGA_CMD_SNESCMD_SETADDR (0xd0)
#define FPGA_CMD_SNESCMD_READ    (0xd1)
#define FPGA_CMD_SNESCMD_WRITE   (0xd2)
#define FPGA_CMD_CHEAT_WRITE     (0xd3)
#define FPGA_CMD_MSUSETBITS      (0xe0)
#define FPGA_CMD_DACPAUSE        (0xe1)
#define FPGA_CMD_DACPLAY         (0xe2)
#define FPGA_CMD_DACRESETPTR     (0xe3)
#define FPGA_CMD_MSUSETPTR       (0xe4)
#define FPGA_CMD_RTCSET          (0xe5)
#define FPGA_CMD_BSXSETBITS      (0xe6)
#define FPGA_CMD_SRTCRESET       (0xe7)
#define FPGA_CMD_DSPRESETPTR     (0xe8)
#define FPGA_CMD_DSPWRITEPGM     (0xe9)
#define FPGA_CMD_DSPWRITEDAT     (0xea)
#define FPGA_CMD_DSPRESET        (0xeb)
#define FPGA_CMD_DACBOOST        (0xec)
#define FPGA_CMD_SETFEATURE      (0xed)
#define FPGA_CMD_SET213F         (0xee)
#define FPGA_CMD_DSPFEAT         (0xef)
#define FPGA_CMD_TEST            (0xf0)
#define FPGA_CMD_GETSTATUS       (0xf1)
#define FPGA_CMD_MSUGETADDR      (0xf2)
#define FPGA_CMD_MSUGETTRACK     (0xf3)
#define FPGA_CMD_GETSYSCLK       (0xfe)
#define FPGA_CMD_ECHO            (0xff)

void fpga_spi_init(void);
uint8_t fpga_test(void);
uint16_t fpga_status(void);
void set_mcu_addr(uint32_t);
void set_dac_addr(uint16_t);
void dac_play(void);
void dac_pause(void);
void dac_reset(void);
void msu_reset(uint16_t);
void set_msu_addr(uint16_t);
void set_msu_status(uint8_t set, uint8_t reset);
void set_saveram_mask(uint32_t);
void set_rom_mask(uint32_t);
void set_mapper(uint8_t val);
void fpga_sddma(uint8_t tgt, uint8_t partial);
void fpga_set_sddma_range(uint16_t start, uint16_t end);
uint16_t get_msu_track(void);
uint32_t get_msu_offset(void);
uint32_t get_snes_sysclk(void);
void set_bsx_regs(uint8_t set, uint8_t reset);
void set_fpga_time(uint64_t time);
void fpga_reset_srtc_state(void);
void fpga_reset_dspx_addr(void);
void fpga_write_dspx_pgm(uint32_t data);
void fpga_write_dspx_dat(uint16_t data);
void fpga_dspx_reset(uint8_t reset);
void fpga_set_dac_boost(uint8_t boost);
void fpga_set_features(uint8_t feat);
void fpga_set_213f(uint8_t data);
void fpga_set_snescmd_addr(uint16_t addr);
void fpga_write_snescmd(uint8_t data);
uint8_t fpga_read_snescmd(void);
void fpga_write_cheat(uint8_t index, uint32_t code);
void fpga_set_dspfeat(uint16_t feat);
#endif

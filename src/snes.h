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

   snes.h: SNES hardware control and monitoring
*/

#ifndef SNES_H
#define SNES_H

#define SNES_CMD_LOADROM           (0x01)
#define SNES_CMD_SETRTC            (0x02)
#define SNES_CMD_SYSINFO           (0x03)
#define SNES_CMD_LOADLAST          (0x04)
#define SNES_CMD_LOADSPC           (0x05)
#define SNES_CMD_SET_ALLOW_PAIR    (0x07)
#define SNES_CMD_SET_VIDMODE_GAME  (0x08)
#define SNES_CMD_SET_VIDMODE_MENU  (0x09)
#define SNES_CMD_READDIR           (0x0a)
#define SNES_CMD_FPGA_RECONF       (0x0b)
#define SNES_CMD_LOAD_CHT          (0x0c)
#define SNES_CMD_SAVE_CHT          (0x0d)
#define SNES_CMD_SAVE_CFG          (0x0e)
#define SNES_CMD_RESET             (0x80)
#define SNES_CMD_RESET_TO_MENU     (0x81)
#define SNES_CMD_ENABLE_CHEATS     (0x82)
#define SNES_CMD_DISABLE_CHEATS    (0x83)
#define SNES_CMD_KILL_NMIHOOK      (0x84)
#define SNES_CMD_GAMELOOP          (0xff)

#define MCU_CMD_RDY                (0x55)
#define MCU_CMD_ERR                (0xaa)

#define MENU_ERR_OK        (0x0)
#define MENU_ERR_FS        (0x1)
#define MENU_ERR_SUPPLFILE (0x2)
#define MENU_ERR_NOIMPL    (0x3)
#define MENU_ERR_CARDWP    (0x4)

#define SNES_RELEASE_RESET_DELAY_US (2)
#define SNES_RESET_PULSELEN_MS (5)

#define SNES_BOOL_TRUE  (0x01)
#define SNES_BOOL_FALSE (0x00)
#define SNES_BOOL_UNDEF (0xff)

#define SNESCMD_MCU_CMD              (0x2a00)
#define SNESCMD_SNES_CMD             (0x2a02)
#define SNESCMD_MCU_PARAM            (0x2a04)
#define SNESCMD_NMI_RESET            (0x2ba0)
#define SNESCMD_NMI_RESET_TO_MENU    (0x2ba2)
#define SNESCMD_NMI_ENABLE_CHEATS    (0x2ba4)
#define SNESCMD_NMI_DISABLE_CHEATS   (0x2ba6)
#define SNESCMD_NMI_KILL_NMIHOOK     (0x2ba8)
#define SNESCMD_NMI_TMP_KILL_NMIHOOK (0x2baa)
#define SNESCMD_NMI_ENABLE_BUTTONS   (0x2bfc)
#define SNESCMD_NMI_DISABLE_WRAM     (0x2bfe)
#define SNESCMD_NMI_WRAM_PATCH_COUNT (0x2bff)
#define SNESCMD_WRAM_CHEATS          (0x2a90)

#define ASM_LDA_IMM      (0xa9)
#define ASM_STA_ABSLONG  (0x8f)
#define ASM_RTS          (0x60)

#define SNES_BUTTON_LRET (0x3030)
#define SNES_BUTTON_LREX (0x2070)
#define SNES_BUTTON_LRSA (0x10b0)
#define SNES_BUTTON_LRSB (0x9030)
#define SNES_BUTTON_LRSY (0x5030)
#define SNES_BUTTON_LRSX (0x1070)

enum snes_reset_state { SNES_RESET_NONE = 0, SNES_RESET_SHORT, SNES_RESET_LONG };

typedef struct __attribute__ ((__packed__)) _status {
  uint8_t rtc_valid;
  uint8_t num_recent_games;
  uint8_t is_u16;
  uint8_t u16_cfg;
} status_t;

uint8_t crc_valid;

void prepare_reset(void);
void snes_init(void);
void snes_reset_pulse(void);
void snes_reset(int state);
uint8_t get_snes_reset(void);
uint8_t get_snes_reset_state(void);
uint8_t snes_main_loop(void);
uint8_t menu_main_loop(void);
void get_selected_name(uint8_t* lfn);
void snes_bootprint(void* msg);
void snes_menu_errmsg(int err, void* msg);
uint8_t snes_get_last_game_index(void);
uint8_t snes_get_mcu_cmd(void);
void snes_set_mcu_cmd(uint8_t cmd);
uint8_t snes_get_snes_cmd(void);
void snes_set_snes_cmd(uint8_t cmd);
void echo_mcu_cmd(void);
uint32_t snes_get_mcu_param(void);
void snescmd_writeshort(uint16_t val, uint16_t addr);
void snescmd_writebyte(uint8_t val, uint16_t addr);
void snescmd_writeblock(void *buf, uint16_t addr, uint16_t size);
uint16_t snescmd_readshort(uint16_t addr);
uint8_t snescmd_readbyte(uint16_t addr);
uint32_t snescmd_readlong(uint16_t addr);
uint64_t snescmd_gettime(void);
void snescmd_prepare_nmihook(void);
void snes_get_filepath(uint8_t *buffer, uint16_t length);
void status_load_to_menu(void);
void status_save_from_menu(void);
#endif

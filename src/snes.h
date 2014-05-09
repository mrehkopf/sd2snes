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

#define SNES_CMD_LOADROM           (1)
#define SNES_CMD_SETRTC            (2)
#define SNES_CMD_SYSINFO           (3)
#define SNES_CMD_LOADLAST          (4)
#define SNES_CMD_LOADSPC           (5)
#define SNES_CMD_RESET             (6)
#define SNES_CMD_SET_ALLOW_PAIR    (7)
#define SNES_CMD_SET_VIDMODE_GAME  (8)
#define SNES_CMD_SET_VIDMODE_MENU  (9)

#define MENU_ERR_OK     (0)
#define MENU_ERR_NODSP  (1)
#define MENU_ERR_NOBSX  (2)

#define SNES_RESET_PULSELEN_MS	(1)

enum snes_reset_state { SNES_RESET_NONE = 0, SNES_RESET_SHORT, SNES_RESET_LONG };

uint8_t crc_valid;

void prepare_reset(void);
void snes_init(void);
void snes_reset_pulse(void);
void snes_reset(int state);
uint8_t get_snes_reset(void);
uint8_t get_snes_reset_state(void);
void snes_main_loop(void);
uint8_t menu_main_loop(void);
void get_selected_name(uint8_t* lfn);
void snes_bootprint(void* msg);
void snes_menu_errmsg(int err, void* msg);
uint8_t snes_get_last_game_index(void);

#endif

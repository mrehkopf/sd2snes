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

   usbinterface.h: usb packet interface handler
*/

#ifndef USBINTERFACE_H
#define USBINTERFACE_H

#ifdef DEBUG_USB
#define PRINT_FUNCTION() printf("%-20s ", __FUNCTION__);
#define PRINT_CMD(buf) printf("header=%c%c%c%c op=%s space=%s flags=%d cmd_size=%d block_size=%d offset=%6x size=%d"\
                                                                        , buf[0], buf[1], buf[2], buf[3]          \
                                                                        , usbint_server_opcode_s[buf[4]]          \
                                                                        , usbint_server_space_s[buf[5]]           \
                                                                        , (int)buf[6]                             \
                                                                        , (int)server_info.cmd_size               \
                                                                        , (int)server_info.block_size             \
                                                                        , (int)server_info.offset                 \
                                                                        , (int)server_info.size                   \
                                                               );
#define PRINT_DAT(num, total) printf("%d/%d ", num, total);
#define PRINT_MSG(msg) printf("%-5s ", msg);
#define PRINT_END() uart_putc('\n');
#define PRINT_STATE(state) printf("state=%-32s ", usbint_server_state_s[state]);
#else
#define PRINT_FUNCTION() {}
#define PRINT_CMD(buf) {}
#define PRINT_DAT(num, total) {}
#define PRINT_MSG(msg) {}
#define PRINT_END() {}
#define PRINT_STATE(state) {}
#endif

/* defines */
#define USB_BLOCK_SIZE 512

#define USB_SNES_STATUS_SET_CONNECTED    (0x0001)

#define USB_SNES_STATUS_CLR_CONNECTED    (0x0100)

/* enums */

/* structs */

/* functions */

// CDC SIDE FLIT COLLECTION
// reset state
void usbint_set_state(unsigned open);
// collect a flit
void usbint_recv_flit(const unsigned char *in, int length);
// manage blocks
void usbint_recv_block(void);
void usbint_send_block(int blockSize);

// BUSY interface
int usbint_server_busy(void);
int usbint_server_dat(void);
int usbint_server_reset(void);

// menu/game state machine
int usbint_handler(void);
//void usbint_handler_server(void);
int usbint_handler_cmd(void);
int usbint_handler_dat(void);
int usbint_handler_exe(void);
void usbint_check_connect(void);

#endif

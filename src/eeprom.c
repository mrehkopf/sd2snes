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


   eeprom.c: Persistent configuration storage

*/

#include <avr/eeprom.h>
#include <avr/io.h>
#include "config.h"
#include "diskio.h"
#include "fatops.h"
#include "flags.h"
#include "iec.h"
#include "timer.h"
#include "eeprom.h"

#include "uart.h"

/**
 * struct storedconfig - in-eeprom data structure
 * @dummy      : EEPROM position 0 is unused
 * @checksum   : Checksum over the EEPROM contents
 * @structsize : size of the eeprom structure
 * @osccal     : stored value of OSCCAL
 * @globalflags: subset of the globalflags variable
 * @address    : device address set by software
 * @hardaddress: device address set by jumpers
 * @fileexts   : file extension mapping mode
 * @drvflags0  : 16 bits of drv mappings, organized as 4 nybbles.
 * @drvflags1  : 16 bits of drv mappings, organized as 4 nybbles.
 *
 * This is the data structure for the contents of the EEPROM.
 */
static EEMEM struct {
  uint8_t  dummy;
  uint8_t  checksum;
  uint16_t structsize;
  uint8_t  osccal;
  uint8_t  global_flags;
  uint8_t  address;
  uint8_t  hardaddress;
  uint8_t  fileexts;
  uint16_t drvconfig0;
  uint16_t drvconfig1;
} storedconfig;

/**
 * read_configuration - reads configuration from EEPROM
 *
 * This function reads the stored configuration values from the EEPROM.
 * If the stored checksum doesn't match the calculated one nothing will
 * be changed.
 */
void read_configuration(void) {
  uint16_t i,size;
  uint8_t checksum, tmp;

  /* Set default values */
  globalflags         |= JIFFY_ENABLED;        /* JiffyDos enabled */
  globalflags         |= POSTMATCH;            /* Post-* matching enabled */
  globalflags         |= FAT32_FREEBLOCKS;     /* Calculate the number of free blocks on FAT32 */
  file_extension_mode  = 1;                    /* Store x00 extensions except for PRG */
  set_drive_config(get_default_driveconfig()); /* Set the default drive configuration */

  /* Use the NEXT button to skip reading the EEPROM configuration */
  if (!(BUTTON_PIN & BUTTON_NEXT)) {
    ignore_keys();
    return;
  }

  size = eeprom_read_word(&storedconfig.structsize);

  /* Calculate checksum of EEPROM contents */
  checksum = 0;
  for (i=2; i<size; i++)
    checksum += eeprom_read_byte((uint8_t *)i);

  /* Abort if the checksum doesn't match */
  if (checksum != eeprom_read_byte(&storedconfig.checksum)) {
    EEAR = 0;
    return;
  }

  /* Read data from EEPROM */
  OSCCAL = eeprom_read_byte(&storedconfig.osccal);

  tmp = eeprom_read_byte(&storedconfig.global_flags);
  globalflags &= (uint8_t)~(JIFFY_ENABLED | POSTMATCH |
                            EXTENSION_HIDING | FAT32_FREEBLOCKS);
  globalflags |= tmp;

  if (eeprom_read_byte(&storedconfig.hardaddress) == DEVICE_SELECT)
    device_address = eeprom_read_byte(&storedconfig.address);

  file_extension_mode = eeprom_read_byte(&storedconfig.fileexts);

#ifdef NEED_DISKMUX
  if (size > 9) {
    uint32_t tmpconfig;
    tmpconfig = eeprom_read_word(&storedconfig.drvconfig0);
    tmpconfig |= (uint32_t)eeprom_read_word(&storedconfig.drvconfig1) << 16;
    set_drive_config(tmpconfig);
  }

  /* sanity check.  If the user has truly turned off all drives, turn the
   * defaults back on
   */
  if(drive_config == 0xffffffff)
    set_drive_config(get_default_driveconfig());
#endif

  /* Paranoia: Set EEPROM address register to the dummy entry */
  EEAR = 0;
}

/**
 * write_configuration - stores configuration data to EEPROM
 *
 * This function stores the current configuration values to the EEPROM.
 */
void write_configuration(void) {
  uint16_t i;
  uint8_t checksum;

  /* Write configuration to EEPROM */
  eeprom_write_word(&storedconfig.structsize, sizeof(storedconfig));
  eeprom_write_byte(&storedconfig.osccal, OSCCAL);
  eeprom_write_byte(&storedconfig.global_flags,
                    globalflags & (JIFFY_ENABLED | POSTMATCH |
                                   EXTENSION_HIDING | FAT32_FREEBLOCKS));
  eeprom_write_byte(&storedconfig.address, device_address);
  eeprom_write_byte(&storedconfig.hardaddress, DEVICE_SELECT);
  eeprom_write_byte(&storedconfig.fileexts, file_extension_mode);
#ifdef NEED_DISKMUX
  eeprom_write_word(&storedconfig.drvconfig0, drive_config);
  eeprom_write_word(&storedconfig.drvconfig1, drive_config >> 16);
#endif

  /* Calculate checksum over EEPROM contents */
  checksum = 0;
  for (i=2;i<sizeof(storedconfig);i++)
    checksum += eeprom_read_byte((uint8_t *) i);

  /* Store checksum to EEPROM */
  eeprom_write_byte(&storedconfig.checksum, checksum);

  /* Paranoia: Set EEPROM address register to the dummy entry */
  EEAR = 0;
}


#ifndef CRC_H
#define CRC_H

uint8_t crc7update(uint8_t crc, uint8_t data);
uint16_t crc_xmodem_update(uint16_t crc, uint8_t data);
uint16_t crc_xmodem_block(uint16_t crc, const uint8_t *data, uint32_t length);

// AVR-libc compatibility
#define _crc_xmodem_update(crc,data) crc_xmodem_update(crc,data)

#endif

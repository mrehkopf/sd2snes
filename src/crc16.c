/**
 * \file stdout
 * Functions and types for CRC checks.
 *
 * Generated on Tue Jun 30 23:02:59 2009,
 * by pycrc v0.7.1, http://www.tty1.net/pycrc/
 * using the configuration:
 *    Width        = 16
 *    Poly         = 0x8005
 *    XorIn        = 0x0000
 *    ReflectIn    = True
 *    XorOut       = 0x0000
 *    ReflectOut   = True
 *    Algorithm    = bit-by-bit-fast
 *    Direct       = True
 *****************************************************************************/
#include <stdint.h>
#include "crc16.h"
/**
 * Update the crc value with new data.
 *
 * \param crc      The current crc value.
 * \param data     Pointer to a buffer of \a data_len bytes.
 * \param data_len Number of bytes in the \a data buffer.
 * \return         The updated crc value.
 *****************************************************************************/
crc_t crc16_update(crc_t crc, const unsigned char *data, size_t data_len)
{
    unsigned int i;
    uint8_t bit;
    unsigned char c;

    while (data_len--) {
        c = *data++;
        for (i = 0x01; i & 0xff; i <<= 1) {
            bit = (crc & 0x8000 ? 1 : 0);
            if (c & i) {
                bit ^= 1;
            }
            crc <<= 1;
            if (bit) {
                crc ^= 0x8005;
            }
        }
        crc &= 0xffff;
    }
    return crc & 0xffff;
}




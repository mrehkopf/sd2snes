/**
 * \file stdout
 * Functions and types for CRC checks.
 *
 * Generated on Tue Jun 30 21:35:13 2009,
 * by pycrc v0.7.1, http://www.tty1.net/pycrc/
 * using the configuration:
 *    Width        = 32
 *    Poly         = 0x04c11db7
 *    XorIn        = 0xffffffff
 *    ReflectIn    = True
 *    XorOut       = 0xffffffff
 *    ReflectOut   = True
 *    Algorithm    = bit-by-bit-fast
 *    Direct       = True
 *****************************************************************************/
#include <stdint.h>
#include "crc32.h"

/**
 * Reflect all bits of a \a data word of \a data_len bytes.
 *
 * \param data         The data word to be reflected.
 * \param data_len     The width of \a data expressed in number of bits.
 * \return     The reflected data.
 *****************************************************************************/
long crc_reflect(long data, size_t data_len)
{
    unsigned int i;
    long ret;

    ret = data & 0x01;
    for (i = 1; i < data_len; i++)
    {
        data >>= 1;
        ret = (ret << 1) | (data & 0x01);
    }
    return ret;
}


/**
 * Update the crc value with new data.
 *
 * \param crc      The current crc value.
 * \param data     Pointer to a buffer of \a data_len bytes.
 * \param data_len Number of bytes in the \a data buffer.
 * \return         The updated crc value.
 *****************************************************************************/
crc_t crc_update(crc_t crc, const unsigned char *data, size_t data_len)
{
    unsigned int i;
    uint8_t bit;
    unsigned char c;

    while (data_len--) {
        c = *data++;
        for (i = 0x01; i & 0xff; i <<= 1) {
            bit = ((crc & 0x80000000) ? 1 : 0);
            if (c & i) {
                bit ^= 1;
            }
            crc <<= 1;
            if (bit) {
                crc ^= 0x04c11db7;
            }
        }
        crc &= 0xffffffff;
    }
    return crc & 0xffffffff;
}




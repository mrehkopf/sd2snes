/**
 * \file crc32.c
 * Functions and types for CRC checks.
 *
 * Generated on Mon Feb 21 23:02:07 2011,
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
#include "crc32.h"
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

/**
 * Reflect all bits of a \a data word of \a data_len bytes.
 *
 * \param data         The data word to be reflected.
 * \param data_len     The width of \a data expressed in number of bits.
 * \return     The reflected data.
******************************************************************************/
uint32_t crc_reflect(uint32_t data, size_t data_len)
{
    unsigned int i;
    uint32_t ret;

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
uint32_t crc32_update(uint32_t crc, const unsigned char data)
{
    unsigned int i;
    uint32_t bit;
    unsigned char c;

    c = data;
    for (i = 0x01; i & 0xff; i <<= 1) {
        bit = crc & 0x80000000;
        if (c & i) {
            bit = !bit;
        }
        crc <<= 1;
        if (bit) {
            crc ^= 0x04c11db7;
        }
    }
    return crc & 0xffffffff;
}



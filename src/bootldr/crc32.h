/**
 * \file crc32.h
 * Functions and types for CRC checks.
 *
 * Generated on Mon Feb 21 23:03:39 2011,
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
#ifndef __CRC___H__
#define __CRC___H__

#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * The definition of the used algorithm.
 *****************************************************************************/
#define CRC_ALGO_BIT_BY_BIT_FAST 1

/**
 * The type of the CRC values.
 *
 * This type must be big enough to contain at least 32 bits.
 *****************************************************************************/

/**
 * Reflect all bits of a \a data word of \a data_len bytes.
 *
 * \param data         The data word to be reflected.
 * \param data_len     The width of \a data expressed in number of bits.
 * \return     The reflected data.
 *****************************************************************************/
uint32_t crc_reflect(uint32_t data, size_t data_len);

/**
 * Calculate the initial crc value.
 *
 * \return     The initial crc value.
 *****************************************************************************/
static inline uint32_t crc_init(void)
{
    return 0xffffffff;
}

/**
 * Update the crc value with new data.
 *
 * \param crc      The current crc value.
 * \param data     Pointer to a buffer of \a data_len bytes.
 * \param data_len Number of bytes in the \a data buffer.
 * \return         The updated crc value.
 *****************************************************************************/
uint32_t crc32_update(uint32_t crc, const unsigned char data);

/**
 * Calculate the final crc value.
 *
 * \param crc  The current crc value.
 * \return     The final crc value.
 *****************************************************************************/
static inline uint32_t crc_finalize(uint32_t crc)
{
    return crc_reflect(crc, 32) ^ 0xffffffff;
}


#ifdef __cplusplus
}           /* closing brace for extern "C" */
#endif

#endif      /* __CRC___H__ */

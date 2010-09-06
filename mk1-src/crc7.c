/* This file is a modified version of the output of pycrc.
 *
 * Licensing terms of pycrc:
 *
 *   Copyright (c) 2006-2007, Thomas Pircher <tehpeh@gmx.net>
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *   THE SOFTWARE.
 *
 *
 * crc7.c: Calculate CRC7 for SD card commands
 *
 */

/*
 * Functions and types for CRC checks.
 *
 * Generated on Thu Nov  8 13:52:05 2007,
 * by pycrc v0.6.3, http://www.tty1.net/pycrc/
 * using the configuration:
 *    Width        = 7
 *    Poly         = 0x09
 *    XorIn        = 0x00
 *    ReflectIn    = False
 *    XorOut       = 0x00
 *    ReflectOut   = False
 *    Algorithm    = bit-by-bit-fast
 */
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

/**
; MMC/SD CRC Polynom X^7 + X^3 + 1
crc7taba:
        mov     dptr,#CRC7_TABA  ; (2)
  clr  c    ; (1)
  rrc  a    ; (1)
  xrl  a,crc7ta  ; (1)
        movc    a,@a+dptr  ; (2)
  jnc  crc7m    ; (2)
  xrl  a,#00001001b  ; (1)
crc7m:  mov  crc7ta,a  ; (1)
  ret      ; (2) (LCALL=2)
*/
uint8_t crc7tab[128] = {
   0x00,0x12,0x24,0x36,0x48,0x5a,0x6c,0x7e,
   0x19,0x0b,0x3d,0x2f,0x51,0x43,0x75,0x67,
   0x32,0x20,0x16,0x04,0x7a,0x68,0x5e,0x4c,
   0x2b,0x39,0x0f,0x1d,0x63,0x71,0x47,0x55,
   0x64,0x76,0x40,0x52,0x2c,0x3e,0x08,0x1a,
   0x7d,0x6f,0x59,0x4b,0x35,0x27,0x11,0x03,
   0x56,0x44,0x72,0x60,0x1e,0x0c,0x3a,0x28,
   0x4f,0x5d,0x6b,0x79,0x07,0x15,0x23,0x31,
   0x41,0x53,0x65,0x77,0x09,0x1b,0x2d,0x3f,
   0x58,0x4a,0x7c,0x6e,0x10,0x02,0x34,0x26,
   0x73,0x61,0x57,0x45,0x3b,0x29,0x1f,0x0d,
   0x6a,0x78,0x4e,0x5c,0x22,0x30,0x06,0x14,
   0x25,0x37,0x01,0x13,0x6d,0x7f,0x49,0x5b,
   0x3c,0x2e,0x18,0x0a,0x74,0x66,0x50,0x42,
   0x17,0x05,0x33,0x21,0x5f,0x4d,0x7b,0x69,
   0x0e,0x1c,0x2a,0x38,0x46,0x54,0x62,0x70
};

uint8_t crc7update(uint8_t crc, const uint8_t data) {
	uint8_t a = data;
	uint8_t b = data & 1;
	a = crc7tab[(a>>1) ^ crc];
	a ^= ((b<<3)|(b));
    crc = a;
	return a;	
}

/*uint8_t crc7update(uint8_t crc, const uint8_t data) {
    uint8_t i;
    bool bit;
    uint8_t c;

    c = data;
    for (i = 0x80; i > 0; i >>= 1) {
      bit = crc & 0x40;
      if (c & i) {
        bit = !bit;
      }
      crc <<= 1;
      if (bit) {
        crc ^= 0x09;
      }
    }
    crc &= 0x7f;
    return crc & 0x7f;
}*/

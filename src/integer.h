/* Integer definitions for ff, based on example code from ChaN */

#ifndef _INTEGER

#include <stdint.h>

/* These types are assumed as 16-bit or larger integer */
typedef int16_t  INT;
typedef uint16_t UINT;

/* These types are assumed as 8-bit integer */
typedef int8_t  CHAR;
typedef uint8_t UCHAR;
typedef uint8_t BYTE;

/* These types are assumed as 16-bit integer */
typedef int16_t  SHORT;
typedef uint16_t USHORT;
typedef uint16_t WORD;

/* These types are assumed as 32-bit integer */
typedef int32_t  LONG;
typedef uint32_t ULONG;
typedef uint32_t DWORD;

/* Boolean type */
typedef enum { FALSE = 0, TRUE } BOOL;

#define _INTEGER
#endif

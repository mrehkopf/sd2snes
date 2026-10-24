#ifndef EXO_DECRUNCH_ALREADY_INCLUDED
#define EXO_DECRUNCH_ALREADY_INCLUDED

/*
 * Copyright (c) 2005 Magnus Lind.
 *
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the authors be held liable for any damages arising from
 * the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 *   1. The origin of this software must not be misrepresented * you must not
 *   claim that you wrote the original software. If you use this software in a
 *   product, an acknowledgment in the product documentation would be
 *   appreciated but is not required.
 *
 *   2. Altered source versions must be plainly marked as such, and must not
 *   be misrepresented as being the original software.
 *
 *   3. This notice may not be removed or altered from any distribution.
 *
 *   4. The names of this software and/or it's copyright holders may not be
 *   used to endorse or promote products derived from this software without
 *   specific prior written permission.
 */

/**
 * This decompressor decompresses files that have been compressed
 * using the raw sub-sub command with the -P39 (default) setting of
 * the raw command.
 */

/*
 ! Modified by ikari_01 for fixed memory layout (no dynamic allocation)
 ! Modified for sd2snes: the window is a buffer the caller passes
 */

enum exo_state
{
    STATE_IMPLICIT_FIRST_LITERAL_BYTE,
    STATE_NEXT_BYTE,
    STATE_NEXT_LITERAL_BYTE,
    STATE_NEXT_SEQUENCE_BYTE,
    STATE_EOF
};

struct exo_table_entry
{
    unsigned int bits;
    unsigned int base;
};

typedef int exo_read_crunched_byte(void *data);

struct exo_decrunch_ctx
{
    struct exo_table_entry lengths[16];
    struct exo_table_entry offsets1[4];
    struct exo_table_entry offsets2[16];
    struct exo_table_entry offsets3[16];
    unsigned char *window;
    unsigned  int window_length;

    enum exo_state state;
    unsigned  int length;
    unsigned  int offset;
    unsigned  int window_pos;
    unsigned char bit_buffer;
    unsigned int bits_in_buffer;
    unsigned char reuse_offset_state;

    exo_read_crunched_byte *read_byte;
    void *read_data;
};

int
exo_decrunch_new(struct exo_decrunch_ctx *ctx,
                 unsigned char *window,
                 unsigned short int max_offset,
                 exo_read_crunched_byte *read_byte,
                 void *read_data);

int
exo_read_decrunched_byte(struct exo_decrunch_ctx *ctx);

#endif /* EXO_DECRUNCH_ALREADY_INCLUDED */

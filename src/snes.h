// insert cool lenghty disclaimer here

// snes.h

#ifndef SNES_H
#define SNES_H
uint8_t crc_valid;

void snes_init(void);
void snes_reset(int state);
uint8_t get_snes_reset(void);
void snes_main_loop(void);
uint8_t menu_main_loop(void);
void get_selected_name(uint8_t* lfn);
#endif

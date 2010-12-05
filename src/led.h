/* ___DISCLAIMER___ */

#ifndef _LED_H
#define _LED_H

void readbright(uint8_t bright);
void writebright(uint8_t bright);
void rdybright(uint8_t bright);
void readled(unsigned int state);
void writeled(unsigned int state);
void rdyled(unsigned int state);
void led_clkout32(uint32_t val);
void toggle_rdy_led(void);
void toggle_read_led(void);
void toggle_write_led(void);
void led_panic(void);
void led_pwm(void);
void led_std(void);
void led_init(void);

#endif

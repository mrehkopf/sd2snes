/* ___DISCLAIMER___ */

#ifndef _LED_H
#define _LED_H

#define LED_PANIC_FPGA_PROGB_STUCK (1)
#define LED_PANIC_FPGA_NO_INITB    (2)
#define LED_PANIC_FPGA_DONE_STUCK  (3)
#define LED_PANIC_FPGA_NOCONF      (4)
#define LED_PANIC_FPGA_DEAD        (5)

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
void led_panic(uint8_t led_states);
void led_pwm(void);
void led_std(void);
void led_init(void);
void led_error(void);
void led_set_brightness(uint8_t bright);
#endif

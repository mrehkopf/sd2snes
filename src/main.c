#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "config.h"
#include "clock.h"
#include "uart.h"
#include "bits.h"
#include "power.h"
#include "timer.h"
#include "ff.h"
#include "diskio.h"
#include "spi.h"
#include "sdcard.h"
#include "fileops.h"
#include "fpga.h"

#define EMC0TOGGLE	(3<<4)
#define MR0R		(1<<1)

int i;

/* FIXME HACK */
volatile enum diskstates disk_state;

int main(void) {
  LPC_GPIO2->FIODIR = BV(0) | BV(1) | BV(2);
  LPC_GPIO1->FIODIR = 0;
  uint32_t p1;

 /* connect UART3 on P0[25:26] + SSP1 on P0[6:9] + MAT3.0 on P0[10] */
  LPC_PINCON->PINSEL1=(0xf<<18);
  LPC_PINCON->PINSEL0=BV(13) | BV(15) | BV(17) | BV(19) | BV(20) | BV(21);

  clock_disconnect();

  power_init();
  timer_init();
  uart_init();
  spi_init(SPI_SPEED_SLOW);
  sd_init();
/* do this last because the peripheral init()s change PCLK dividers */
  clock_init();
  delay_ms(10);
  printf("\n\nsd2snes mk.2\n============\ncpu clock: %d Hz\n", CONFIG_CPU_FREQUENCY);
  file_init();
/*  uart_putc('S');
  for(p1=0; p1<8192; p1++) {
    file_read();
  }
  file_close();
  uart_putc('E');
  uart_putcrlf();
  printf("sizeof(struct FIL): %d\n", sizeof(file_handle));
  uart_trace(file_buf, 0, 512);*/

/* setup timer (fpga clk) */
  LPC_TIM3->CTCR=0;
  LPC_TIM3->EMR=EMC0TOGGLE;
  LPC_TIM3->MCR=MR0R;
  LPC_TIM3->MR0=1;
  LPC_TIM3->TCR=1;
  uart_puts("hurr durr derpderpderp\n");
  fpga_init();
  fpga_pgm((uint8_t*)"/sd2snes/main.bit");

  while (1) {
    p1 = LPC_GPIO1->FIOPIN;
    BITBAND(LPC_GPIO2->FIOPIN, 1) = (p1 & BV(29))>>29;
  }
}

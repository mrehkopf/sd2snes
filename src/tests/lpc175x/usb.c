#include "config.h"
#include "usb.h"

void usb_dummy_init() {
/* disable pull-up on fake USB_CONNECT pin (P1.18), set P1.30 to VBUS */
  GPIO_PULLNONE(USB_CONNREG, USB_CONNBIT);
  GPIO_MODE_AF(USB_VBUSREG, USB_VBUSBIT, 0b10);
  GPIO_PULLNONE(USB_VBUSREG, USB_VBUSBIT);
}


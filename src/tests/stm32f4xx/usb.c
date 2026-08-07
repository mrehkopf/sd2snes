#include "config.h"
#include "usb.h"

void usb_dummy_init() {
/* set alternate function for VBUS */
  GPIO_MODE_AF(USB_VBUSREG, USB_VBUSBIT);
  GPIO_SEL_AF(USB_VBUSREG, USB_VBUSBIT, 10);
  GPIO_PULLNONE(USB_VBUSREG, USB_VBUSBIT);
}


/*----------------------------------------------------------------------------
 *      U S B  -  K e r n e l
 *----------------------------------------------------------------------------
 * Name:    usbdesc.c
 * Purpose: USB Descriptors
 * Version: V1.20
 *----------------------------------------------------------------------------
 *      This software is supplied "AS IS" without any warranties, express,
 *      implied or statutory, including but not limited to the implied
 *      warranties of fitness for purpose, satisfactory quality and
 *      noninfringement. Keil extends you a royalty-free right to reproduce
 *      and distribute executable files created using this software for use
 *      on NXP Semiconductors LPC microcontroller devices only. Nothing else
 *      gives you the right to use this software.
 *
 * Copyright (c) 2009 Keil - An ARM Company. All rights reserved.
 *----------------------------------------------------------------------------
 * History:
 *          V1.20 Changed string descriptor handling
 *          V1.00 Initial Version
 *---------------------------------------------------------------------------*/
#include <stdint.h>

#include "usb.h"
#include "cdc.h"
#include "usbcfg.h"
#include "usbdesc.h"


/* USB Standard Device Descriptor */
const uint8_t USB_DeviceDescriptor[] = {
  USB_DEVICE_DESC_SIZE,              /* bLength */
  USB_DEVICE_DESCRIPTOR_TYPE,        /* bDescriptorType */
  WBVAL(0x0200), /* 2.0 */           /* bcdUSB */
  USB_DEVICE_CLASS_COMMUNICATIONS,   /* bDeviceClass CDC*/
  0x00,                              /* bDeviceSubClass */
  0x00,                              /* bDeviceProtocol */
  USB_MAX_PACKET0,                   /* bMaxPacketSize0 */
  WBVAL(0x1209),                     /* idVendor */
  WBVAL(0x5A22),                     /* idProduct */
  WBVAL(0x0100), /* 1.00 */          /* bcdDevice */
  0x01,                              /* iManufacturer */
  0x02,                              /* iProduct */
  0x03,                              /* iSerialNumber */
  0x01                               /* bNumConfigurations: one possible configuration*/
};

/* USB Configuration Descriptor */
/*   All Descriptors (Configuration, Interface, Endpoint, Class, Vendor */
const uint8_t USB_ConfigDescriptor[] = {
/* Configuration 1 */
  USB_CONFIGURATION_DESC_SIZE,       /* bLength */
  USB_CONFIGURATION_DESCRIPTOR_TYPE, /* bDescriptorType */
  WBVAL(                             /* wTotalLength */
    1*USB_CONFIGURATION_DESC_SIZE +
    1*USB_INTERFACE_DESC_SIZE     +  /* communication interface */
    0x0013                        +  /* CDC functions */
    1*USB_ENDPOINT_DESC_SIZE      +  /* interrupt endpoint */
    1*USB_INTERFACE_DESC_SIZE     +  /* data interface */
    2*USB_ENDPOINT_DESC_SIZE         /* bulk endpoints */
      ),
  0x02,                              /* bNumInterfaces */
  0x01,                              /* bConfigurationValue: 0x01 is used to select this configuration */
  0x00,                              /* iConfiguration: no string to describe this configuration */
  USB_CONFIG_SELF_POWERED,           /* bmAttributes */
  USB_CONFIG_POWER_MA(100),          /* bMaxPower, device power consumption is 100 mA */
/* Interface 0, Alternate Setting 0, Communication class interface descriptor */
  USB_INTERFACE_DESC_SIZE,           /* bLength */
  USB_INTERFACE_DESCRIPTOR_TYPE,     /* bDescriptorType */
  USB_CDC_CIF_NUM,                   /* bInterfaceNumber: Number of Interface */
  0x00,                              /* bAlternateSetting: Alternate setting */
  0x01,                              /* bNumEndpoints: One endpoint used */
  CDC_COMMUNICATION_INTERFACE_CLASS, /* bInterfaceClass: Communication Interface Class */
  CDC_ABSTRACT_CONTROL_MODEL,        /* bInterfaceSubClass: Abstract Control Model */

//ttyACM0 -> CDC_DIRECT_LINE_CONTROL_MODEL has no driver :>

  0x00,                              /* bInterfaceProtocol: no protocol used */
  //0x5E,                              /* iInterface: */
   0x04, 
  
/*Header Functional Descriptor*/
  0x05,                              /* bLength: Endpoint Descriptor size */
  CDC_CS_INTERFACE,                  /* bDescriptorType: CS_INTERFACE */
  CDC_HEADER,                        /* bDescriptorSubtype: Header Func Desc */
  WBVAL(CDC_V1_10), /* 1.10 */       /* bcdCDC */
/*Call Management Functional Descriptor*/
  0x05,                              /* bFunctionLength */
  CDC_CS_INTERFACE,                  /* bDescriptorType: CS_INTERFACE */
  CDC_CALL_MANAGEMENT,               /* bDescriptorSubtype: Call Management Func Desc */
  0x01,                              /* bmCapabilities: device handles call management */
  0x01,                              /* bDataInterface: CDC data IF ID */
  
  //debug
  //0x00, //disable all capabilities
 //0x00,
  
  
/*Abstract Control Management Functional Descriptor*/
  0x04,                              /* bFunctionLength */
  CDC_CS_INTERFACE,                  /* bDescriptorType: CS_INTERFACE */
  CDC_ABSTRACT_CONTROL_MANAGEMENT,   /* bDescriptorSubtype: Abstract Control Management desc */
  0x02,                              /* bmCapabilities: SET_LINE_CODING, GET_LINE_CODING, SET_CONTROL_LINE_STATE supported */
  
 // 0x00, //disable all capabilities
  
/*Union Functional Descriptor*/
  0x05,                              /* bFunctionLength */
  CDC_CS_INTERFACE,                  /* bDescriptorType: CS_INTERFACE */
  CDC_UNION,                         /* bDescriptorSubtype: Union func desc */
  USB_CDC_CIF_NUM,                   /* bMasterInterface: Communication class interface is master */
  USB_CDC_DIF_NUM,                   /* bSlaveInterface0: Data class interface is slave 0 */
/*Endpoint 1 Descriptor*/            /* event notification (optional) */
  USB_ENDPOINT_DESC_SIZE,            /* bLength */
  USB_ENDPOINT_DESCRIPTOR_TYPE,      /* bDescriptorType */
  USB_ENDPOINT_IN(1),                /* bEndpointAddress */
  USB_ENDPOINT_TYPE_INTERRUPT,       /* bmAttributes */
  WBVAL(0x0010),                     /* wMaxPacketSize */
  0x02,          /* 2ms */           /* bInterval */
/* Interface 1, Alternate Setting 0, Data class interface descriptor*/
  USB_INTERFACE_DESC_SIZE,           /* bLength */
  USB_INTERFACE_DESCRIPTOR_TYPE,     /* bDescriptorType */
  USB_CDC_DIF_NUM,                   /* bInterfaceNumber: Number of Interface */
  0x00,                              /* bAlternateSetting: no alternate setting */
  0x02,                              /* bNumEndpoints: two endpoints used */
  CDC_DATA_INTERFACE_CLASS,          /* bInterfaceClass: Data Interface Class */
  0x00,                              /* bInterfaceSubClass: no subclass available */
  0x00,                              /* bInterfaceProtocol: no protocol used */
  0x5E,                              /* iInterface: */
/* Endpoint, EP2 Bulk Out */
  USB_ENDPOINT_DESC_SIZE,            /* bLength */
  USB_ENDPOINT_DESCRIPTOR_TYPE,      /* bDescriptorType */
  USB_ENDPOINT_OUT(2),               /* bEndpointAddress */
  USB_ENDPOINT_TYPE_BULK,            /* bmAttributes */
  WBVAL(USB_CDC_BUFOUTSIZE),            /* wMaxPacketSize */
  0x00,                              /* bInterval: ignore for Bulk transfer */
/* Endpoint, EP2 Bulk In */
  USB_ENDPOINT_DESC_SIZE,            /* bLength */
  USB_ENDPOINT_DESCRIPTOR_TYPE,      /* bDescriptorType */
  USB_ENDPOINT_IN(2),                /* bEndpointAddress */
  USB_ENDPOINT_TYPE_BULK,            /* bmAttributes */
  WBVAL(USB_CDC_BUFINSIZE),            /* wMaxPacketSize */
  0x00,                              /* bInterval: ignore for Bulk transfer */
/* Terminator */
  0                                  /* bLength */
};




/* USB String Descriptor (optional) */
const uint8_t USB_StringDescriptor[] = {
/* Index 0x00: LANGID Codes */
  0x04,                              /* bLength */
  USB_STRING_DESCRIPTOR_TYPE,        /* bDescriptorType */
  WBVAL(0x0409), /* US English */    /* wLANGID */
/* Index 0x01: Manufacturer */
  (8*2 + 2),                        /* bLength (13 Char + Type + lenght) */
  USB_STRING_DESCRIPTOR_TYPE,        /* bDescriptorType */
  'i',0,
  'k',0,
  'a',0,
  'r',0,
  'i',0,
  '_',0,
  '0',0,
  '1',0,
/* Index 0x02: Product */
  (7*2 + 2),                        /* bLength ( 17 Char + Type + lenght) */
  USB_STRING_DESCRIPTOR_TYPE,        /* bDescriptorType */
  's',0,
  'd',0,
  '2',0,
  's',0,
  'n',0,
  'e',0,
  's',0,
/* Index 0x03: Serial Number */
/* TODO: deploy a real serial number here */
  (12*2 + 2),                        /* bLength (12 Char + Type + lenght) */
  USB_STRING_DESCRIPTOR_TYPE,        /* bDescriptorType */
  'D',0,
  'E',0,
  'M',0,
  'O',0,
  '0',0,
  '0',0,
  '0',0,
  '0',0,
  '0',0,
  '0',0,
  '0',0,
  '0',0,
/* Index 0x04: Interface 0, Alternate Setting 0 */
  ( 4*2 + 2),                        /* bLength (4 Char + Type + lenght) */
  USB_STRING_DESCRIPTOR_TYPE,        /* bDescriptorType */
  'V',0,
  'C',0,
  'O',0,
  'M',0
};

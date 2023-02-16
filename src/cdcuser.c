/*----------------------------------------------------------------------------
 *      U S B  -  K e r n e l
 *----------------------------------------------------------------------------
 *      Name:    cdcuser.c
 *      Purpose: USB Communication Device Class User module
 *      Version: V1.10
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
 *---------------------------------------------------------------------------*/

#include <stdint.h>

#include "config.h"
#include "uart.h"

#include "usb.h"
#include "usbhw.h"
#include "usbreg.h"
#include "usbcfg.h"
#include "usbcore.h"
#include "cdc.h"
#include "cdcuser.h"
#include "timer.h"

#include "usbinterface.h"
#include CONFIG_MCU_H //interrupt disable

unsigned char BulkBufIn  [USB_CDC_BUFINSIZE];            // Buffer to store USB IN  packet
unsigned char BulkBufOut [USB_CDC_BUFOUTSIZE];            // Buffer to store USB OUT packet
unsigned char NotificationBuf [10];
unsigned char soft_bulkin_int=0;

volatile uint32_t cdc_bulkIN_count    = 0;
volatile uint8_t *cdc_bulkIN_ptr      = NULL;
volatile uint8_t  cdc_bulkIN_occupied = 0;
volatile uint8_t  cdc_bulkIN_ZLP      = 0;

volatile uint8_t  cdc_bulkOUT_occupied = 0;

CDC_LINE_CODING CDC_LineCoding  = {9600, 0, 0, 8};
unsigned short  CDC_SerialState = 0x0000;
unsigned short  CDC_DepInEmpty  = 1;                   // Data IN EP is empty

/*----------------------------------------------------------------------------
  We need a buffer for incomming data on USB port because USB receives
  much faster than  UART transmits
 *---------------------------------------------------------------------------*/
/* Buffer masks */
#define CDC_BUF_SIZE               (64)                // Output buffer in bytes (power 2)
                                                       // large enough for file transfer
#define CDC_BUF_MASK               (CDC_BUF_SIZE-1ul)

/* Buffer read / write macros */
#define CDC_BUF_RESET(cdcBuf)      (cdcBuf.rdIdx = cdcBuf.wrIdx = 0)
#define CDC_BUF_WR(cdcBuf, dataIn) (cdcBuf.data[CDC_BUF_MASK & cdcBuf.wrIdx++] = (dataIn))
#define CDC_BUF_RD(cdcBuf)         (cdcBuf.data[CDC_BUF_MASK & cdcBuf.rdIdx++])
#define CDC_BUF_EMPTY(cdcBuf)      (cdcBuf.rdIdx == cdcBuf.wrIdx)
#define CDC_BUF_FULL(cdcBuf)       (cdcBuf.rdIdx == cdcBuf.wrIdx+1)
#define CDC_BUF_COUNT(cdcBuf)      (CDC_BUF_MASK & (cdcBuf.wrIdx - cdcBuf.rdIdx))


// CDC output buffer
typedef struct __CDC_BUF_T {
  unsigned char data[CDC_BUF_SIZE];
  //unsigned int wrIdx;
  //unsigned int rdIdx;
  volatile unsigned int wrIdx;
  volatile unsigned int rdIdx;
} CDC_BUF_T;

CDC_BUF_T  CDC_OutBuf;                                 // buffer for all CDC Out data

/*----------------------------------------------------------------------------
  read data from CDC_OutBuf
 *---------------------------------------------------------------------------*/
int CDC_RdOutBuf (char *buffer, const int *length) {
  int bytesToRead, bytesRead;

  /* Read *length bytes, block if *bytes are not avaialable	*/
  bytesToRead = *length;
  bytesToRead = (bytesToRead < (*length)) ? bytesToRead : (*length);
  bytesRead = bytesToRead;


  // ... add code to check for underrun

  while (bytesToRead--) {
    *buffer++ = CDC_BUF_RD(CDC_OutBuf);
  }
  return (bytesRead);
}

/*----------------------------------------------------------------------------
  write data to CDC_OutBuf
 *---------------------------------------------------------------------------*/
int CDC_WrOutBuf (const char *buffer, int *length) {
  int bytesToWrite, bytesWritten;

  // Write *length bytes
  bytesToWrite = *length;
  bytesWritten = bytesToWrite;


  // ... add code to check for overwrite

  while (bytesToWrite) {
      CDC_BUF_WR(CDC_OutBuf, *buffer++);           // Copy Data to buffer
      bytesToWrite--;
  }

  return (bytesWritten);
}

/*----------------------------------------------------------------------------
  check if character(s) are available at CDC_OutBuf
 *---------------------------------------------------------------------------*/
int CDC_OutBufAvailChar (int *availChar) {

  *availChar = CDC_BUF_COUNT(CDC_OutBuf);

  return (0);
}
/* end Buffer handling */


/*----------------------------------------------------------------------------
  CDC Initialisation
  Initializes the data structures and serial port
  Parameters:   None
  Return Value: None
 *---------------------------------------------------------------------------*/
void CDC_Init (char portNum ) {

  CDC_DepInEmpty  = 1;
  CDC_SerialState = CDC_GetSerialState();

  CDC_BUF_RESET(CDC_OutBuf);
  return;
}


/*----------------------------------------------------------------------------
  CDC SendEncapsulatedCommand Request Callback
  Called automatically on CDC SEND_ENCAPSULATED_COMMAND Request
  Parameters:   None                          (global SetupPacket and EP0Buf)
  Return Value: 1 - Success, 0 - Error
 *---------------------------------------------------------------------------*/
uint32_t CDC_SendEncapsulatedCommand (void) {

  return (1);
}


/*----------------------------------------------------------------------------
  CDC GetEncapsulatedResponse Request Callback
  Called automatically on CDC Get_ENCAPSULATED_RESPONSE Request
  Parameters:   None                          (global SetupPacket and EP0Buf)
  Return Value: 1 - Success, 0 - Error
 *---------------------------------------------------------------------------*/
uint32_t CDC_GetEncapsulatedResponse (void) {

  /* ... add code to handle request */
  return (1);
}


/*----------------------------------------------------------------------------
  CDC SetCommFeature Request Callback
  Called automatically on CDC Set_COMM_FATURE Request
  Parameters:   FeatureSelector
  Return Value: 1 - Success, 0 - Error
 *---------------------------------------------------------------------------*/
uint32_t CDC_SetCommFeature (unsigned short wFeatureSelector) {

  /* ... add code to handle request */
  return (1);
}


/*----------------------------------------------------------------------------
  CDC GetCommFeature Request Callback
  Called automatically on CDC Get_COMM_FATURE Request
  Parameters:   FeatureSelector
  Return Value: 1 - Success, 0 - Error
 *---------------------------------------------------------------------------*/
uint32_t CDC_GetCommFeature (unsigned short wFeatureSelector) {

  /* ... add code to handle request */
  return (1);
}


/*----------------------------------------------------------------------------
  CDC ClearCommFeature Request Callback
  Called automatically on CDC CLEAR_COMM_FATURE Request
  Parameters:   FeatureSelector
  Return Value: 1 - Success, 0 - Error
 *---------------------------------------------------------------------------*/
uint32_t CDC_ClearCommFeature (unsigned short wFeatureSelector) {

  /* ... add code to handle request */
  return (1);
}


/*----------------------------------------------------------------------------
  CDC SetLineCoding Request Callback
  Called automatically on CDC SET_LINE_CODING Request
  Parameters:   none                    (global SetupPacket and EP0Buf)
  Return Value: 1 - Success, 0 - Error
 *---------------------------------------------------------------------------*/
uint32_t CDC_SetLineCoding (void) {
  CDC_LineCoding.dwDTERate   =   (EP0Buf[0] <<  0)
                               | (EP0Buf[1] <<  8)
                               | (EP0Buf[2] << 16)
                               | (EP0Buf[3] << 24);
  CDC_LineCoding.bCharFormat =  EP0Buf[4];
  CDC_LineCoding.bParityType =  EP0Buf[5];
  CDC_LineCoding.bDataBits   =  EP0Buf[6];

  return (1);
}


/*----------------------------------------------------------------------------
  CDC GetLineCoding Request Callback
  Called automatically on CDC GET_LINE_CODING Request
  Parameters:   None                         (global SetupPacket and EP0Buf)
  Return Value: 1 - Success, 0 - Error
 *---------------------------------------------------------------------------*/
uint32_t CDC_GetLineCoding (void) {

  EP0Buf[0] = (CDC_LineCoding.dwDTERate >>  0) & 0xFF;
  EP0Buf[1] = (CDC_LineCoding.dwDTERate >>  8) & 0xFF;
  EP0Buf[2] = (CDC_LineCoding.dwDTERate >> 16) & 0xFF;
  EP0Buf[3] = (CDC_LineCoding.dwDTERate >> 24) & 0xFF;
  EP0Buf[4] =  CDC_LineCoding.bCharFormat;
  EP0Buf[5] =  CDC_LineCoding.bParityType;
  EP0Buf[6] =  CDC_LineCoding.bDataBits;

  return (1);
}


/*----------------------------------------------------------------------------
  CDC SetControlLineState Request Callback
  Called automatically on CDC SET_CONTROL_LINE_STATE Request
  Parameters:   ControlSignalBitmap
  Return Value: 1 - Success, 0 - Error
 *---------------------------------------------------------------------------*/
uint32_t CDC_SetControlLineState (unsigned short wControlSignalBitmap) {
  static unsigned short prev = 0;
  /* ... add code to handle request */

  // init USB state
  if ((wControlSignalBitmap ^ prev) & 0x1) {
    usbint_set_state(wControlSignalBitmap & 0x1);
  }

  prev = wControlSignalBitmap;

  return (1);
}


/*----------------------------------------------------------------------------
  CDC SendBreak Request Callback
  Called automatically on CDC Set_COMM_FATURE Request
  Parameters:   0xFFFF  start of Break
                0x0000  stop  of Break
                0x####  Duration of Break
  Return Value: 1 - Success, 0 - Error
 *---------------------------------------------------------------------------*/
uint32_t CDC_SendBreak (unsigned short wDurationOfBreak) {

  /* ... add code to handle request */
  printf("break: %04x\n",wDurationOfBreak);
  return (1);
}


//saturnu
void CDC_block_conf (void) {

  cdc_bulkIN_count    = 0;
  cdc_bulkIN_ptr      = NULL;
  cdc_bulkIN_occupied = 0;
  cdc_bulkIN_ZLP      = 0;

}


void CDC_block_init(uint8_t *buffer, uint32_t send_size) {
    cdc_bulkIN_occupied = 1;                 // fill the context
    cdc_bulkIN_ptr   = buffer;
    cdc_bulkIN_count = send_size;
    //cdc_bulkIN_ZLP   = 0;
}

//sautrnu
//send data with this function
uint32_t CDC_block_send( uint8_t *buffer, uint32_t send_size )
{
  DBG_USBHW printf("CDC_block_send(%p, %ld) cdc_bulkIN_occupied=%d\n", buffer, send_size, cdc_bulkIN_occupied);
  if ( !cdc_bulkIN_occupied ) {                 // The bulk IN endpoint is not busy
    CDC_block_init(buffer, send_size);

    USB_DisableIRQ();

    // *interrupt
    while ( !Endpoint_IsINReady() ) {	/*-- Wait until ready --*/
      delay_ms(1);
    }

    // *interrupt
    CDC_BulkIn();
    USB_EnableIRQ();
    return 1;
  }
  return -1;
}

int CDC_BulkIn_occupied(void) {
  return cdc_bulkIN_occupied;
}

/*----------------------------------------------------------------------------
  CDC_BulkIn call on DataIn Request
  Parameters:   none
  Return Value: none
  *---------------------------------------------------------------------------*/

extern volatile enum usbint_server_state_e server_state;
void CDC_BulkIn(void) {
  int numBytesSend;
  //    printf("called CDC_BulkIn\n");                                                     // split into packets

  // *interrupt
  // fill the buffer if it's empty
  //usbint_handler();

  //if less actual rest of bytes else full buffer size
  numBytesSend = (cdc_bulkIN_count < USB_CDC_BUFINSIZE) ? cdc_bulkIN_count : USB_CDC_BUFINSIZE;
  DBG_USBHW printf("CDC_BulkIN cdc_count=%ld numBytesSend=%d cdc_ZLP=%d\n", cdc_bulkIN_count, numBytesSend, cdc_bulkIN_ZLP);

  //if there are still bytes to send __OR__ (if there are non bytes to send __AND__ the ZLP is still missing)
  if ( numBytesSend || ((numBytesSend == 0) && cdc_bulkIN_ZLP) ) {

    USB_WriteEP (CDC_DEP_IN, (uint8_t*)cdc_bulkIN_ptr, numBytesSend);  // send over USB

    //USB_ClearEPBuf(CDC_DEP_IN);

    cdc_bulkIN_count -= numBytesSend;
    cdc_bulkIN_ptr   += numBytesSend;
    cdc_bulkIN_ZLP   = (numBytesSend == USB_CDC_BUFINSIZE);
    if ((!cdc_bulkIN_count) && (!cdc_bulkIN_ZLP))
        cdc_bulkIN_occupied = 0;
  } else {
    cdc_bulkIN_occupied = 0;
  }

  // fill send buffer if it's available
  if (!cdc_bulkIN_count && usbint_server_dat()) usbint_handler_dat();
}


/*
  void CDC_BulkIn(void) {
  int numBytesRead;

  // TODO read print buffer
  //uart_putc('Y');
  //call usb_fkt get data read endpoint

  NVIC_DisableIRQ(USB_IRQn);
  numBytesRead = read_usbbuffer(&BulkBufIn[0]);
  //  numBytesRead = ser_Read ((char *)&BulkBufIn[0], &numBytesAvail);

  // send over USB

  if (numBytesRead > 0) {

  //evtl. use better solution from here
  //http://www.lpcware.com/content/forum/usb-cdc-maximum-bandwidth



  USB_WriteEP (CDC_DEP_IN, &BulkBufIn[0], numBytesRead);


  }
  else {
  CDC_DepInEmpty = 1;
  }
  NVIC_EnableIRQ(USB_IRQn);


  return;
  }
*/

/*----------------------------------------------------------------------------
  CDC_BulkOut call on DataOut Request
  Parameters:   none
  Return Value: none
 *---------------------------------------------------------------------------*/
void CDC_BulkOut(void) {
  int numBytesRead;

  // get data from USB into intermediate buffer
  if ( /*!cdc_bulkIN_occupied &&*/ !usbint_server_busy()) {
    numBytesRead = USB_ReadEP(CDC_DEP_OUT, &BulkBufOut[0]);

    // ... add code to check for overwrite

    // store data in a buffer to transmit it over serial interface
    // CDC_WrOutBuf ((char *)&BulkBufOut[0], &numBytesRead);
    //	uart_putc(BulkBufOut[0]);

  //saturnu
  //append_usbbuffer(BulkBufOut, numBytesRead);

    usbint_recv_flit(BulkBufOut, numBytesRead);
//printf("Mörk %d\n", numBytesRead);


  }
  //CDC_NotificationIn ();

  return;
}


/*----------------------------------------------------------------------------
  Get the SERIAL_STATE as defined in usbcdc11.pdf, 6.3.5, Table 69.
  Parameters:   none
  Return Value: SerialState as defined in usbcdc11.pdf
 *---------------------------------------------------------------------------*/
unsigned short CDC_GetSerialState (void) {
  unsigned short temp;

  CDC_SerialState = 0;
  temp = 0;
  if (temp & 0x8000)  CDC_SerialState |= CDC_SERIAL_STATE_RX_CARRIER;
  if (temp & 0x2000)  CDC_SerialState |= CDC_SERIAL_STATE_TX_CARRIER;
  if (temp & 0x0010)  CDC_SerialState |= CDC_SERIAL_STATE_BREAK;
  if (temp & 0x4000)  CDC_SerialState |= CDC_SERIAL_STATE_RING;
  if (temp & 0x0008)  CDC_SerialState |= CDC_SERIAL_STATE_FRAMING;
  if (temp & 0x0004)  CDC_SerialState |= CDC_SERIAL_STATE_PARITY;
  if (temp & 0x0002)  CDC_SerialState |= CDC_SERIAL_STATE_OVERRUN;

  return (CDC_SerialState);
}


/*----------------------------------------------------------------------------
  Send the SERIAL_STATE notification as defined in usbcdc11.pdf, 6.3.5.
 *---------------------------------------------------------------------------*/
void CDC_NotificationIn (void) {

  NotificationBuf[0] = 0xA1;                           // bmRequestType
  NotificationBuf[1] = CDC_NOTIFICATION_SERIAL_STATE;  // bNotification (SERIAL_STATE)
  NotificationBuf[2] = 0x00;                           // wValue
  NotificationBuf[3] = 0x00;
  NotificationBuf[4] = 0x00;                           // wIndex (Interface #, LSB first)
  NotificationBuf[5] = 0x00;
  NotificationBuf[6] = 0x02;                           // wLength (Data length = 2 bytes, LSB first)
  NotificationBuf[7] = 0x00;
  NotificationBuf[8] = (CDC_SerialState >>  0) & 0xFF; // UART State Bitmap (16bits, LSB first)
  NotificationBuf[9] = (CDC_SerialState >>  8) & 0xFF;

  USB_WriteEP (CDC_CEP_IN, &NotificationBuf[0], 10);   // send notification
  return;
}

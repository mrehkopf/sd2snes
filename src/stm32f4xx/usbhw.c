/*----------------------------------------------------------------------------
 *      U S B  -  K e r n e l
 *----------------------------------------------------------------------------
 * Name:    usbhw.c
 * Purpose: USB Hardware Layer Module for NXP's LPC17xx MCU
 * Version: V1.20
 *----------------------------------------------------------------------------
 *      This software is supplied "AS IS" without any warranties, express,
 *      implied or statutory, including but not limited to the implied
 *      warranties of fitness for purpose, satisfactory quality and
 *      noninfringement. Keil extends you a royalty-free right to reproduce
 *      and distribute executable files created using this software for use
 *      on NXP Semiconductors LPC family microcontroller devices only. Nothing 
 *      else gives you the right to use this software.
 *
 * Copyright (c) 2009 Keil - An ARM Company. All rights reserved.
 *----------------------------------------------------------------------------
 * History:
 *          V1.20 Added USB_ClearEPBuf
 *          V1.00 Initial Version
 *----------------------------------------------------------------------------*/
#include <arm/bits.h>
#include <string.h>

#include "config.h"
#include "uart.h"

#include "usb.h"
#include "usbcfg.h"
#include "usbreg.h"
#include "usbhw.h"
#include "usbcore.h"
#include "usbuser.h"

#define USB_NUM_EP  (4)

#if defined (  __CC_ARM__  )
#pragma diag_suppress 1441
#endif


#define EP_MSK_CTRL 0x0001      /* Control Endpoint Logical Address Mask */
#define EP_MSK_BULK 0xC924      /* Bulk Endpoint Logical Address Mask */
#define EP_MSK_INT  0x4492      /* Interrupt Endpoint Logical Address Mask */
#define EP_MSK_ISO  0x1248      /* Isochronous Endpoint Logical Address Mask */

USB_OTG_GRXSTSP_Typedef CurrentUSBPacketStatus;
USB_EndPointState epout[USB_NUM_EP];
uint32_t doeptsiz[USB_NUM_EP];

#if USB_DMA

#pragma arm section zidata = "USB_RAM"
uint32_t UDCA[USB_EP_NUM];                     /* UDCA in USB RAM */
uint32_t DD_NISO_Mem[4*DD_NISO_CNT];           /* Non-Iso DMA Descriptor Memory */
uint32_t DD_ISO_Mem [5*DD_ISO_CNT];            /* Iso DMA Descriptor Memory */
#pragma arm section zidata
uint32_t udca[USB_EP_NUM];                     /* UDCA saved values */

uint32_t DDMemMap[2];                          /* DMA Descriptor Memory Usage */

#endif


void USB_Flush_TXFIFO(int ep) {
  uint32_t fifo_idx;
  ep &= 0x0f;
  USB_OTG_FS_EP->IN_Endpoint[ep].DIEPCTL |= USB_OTG_DIEPCTL_SNAK;
  while(!(USB_OTG_FS_EP->IN_Endpoint[ep].DIEPINT & USB_OTG_DIEPINT_INEPNE));

  fifo_idx = (USB_OTG_FS_EP->IN_Endpoint[ep].DIEPCTL & USB_OTG_DIEPCTL_TXFNUM_Msk) >> USB_OTG_DIEPCTL_TXFNUM_Pos;

  while(!(USB_OTG_FS_GLOBAL->GRSTCTL & USB_OTG_GRSTCTL_AHBIDL));

  USB_OTG_FS_GLOBAL->GRSTCTL = (fifo_idx << USB_OTG_GRSTCTL_TXFNUM_Pos) | USB_OTG_GRSTCTL_TXFFLSH;

  USB_OTG_FS_EP->IN_Endpoint[ep].DIEPTSIZ = 0;
  while(USB_OTG_FS_GLOBAL->GRSTCTL & USB_OTG_GRSTCTL_TXFFLSH);
}

/*
 *  USB Initialize Function
 *   Called by the User to initialize USB
 *    Return Value:    None
 */

void USB_Init (void) {

  RCC->AHB2ENR |= RCC_AHB2ENR_OTGFSEN_Msk;

  USB_OTG_FS_GLOBAL->GUSBCFG |= USB_OTG_GUSBCFG_PHYSEL;
  while(!(USB_OTG_FS_GLOBAL->GRSTCTL & USB_OTG_GRSTCTL_AHBIDL));

  USB_OTG_FS_GLOBAL->GCCFG = USB_OTG_GCCFG_PWRDWN
                           | (USB_OTG_FS_GLOBAL->GCCFG & 0xffff);
  USB_OTG_FS_GLOBAL->GAHBCFG = USB_OTG_GAHBCFG_GINT
                      | USB_OTG_GAHBCFG_PTXFELVL;
  USB_OTG_FS_GLOBAL->GUSBCFG = USB_OTG_GUSBCFG_FDMOD
                      | (0 << USB_OTG_GUSBCFG_TOCAL_Pos)
                      | (6 << USB_OTG_GUSBCFG_TRDT_Pos);

  USB_OTG_FS_DEVICE->DIEPMSK = 0;
  USB_OTG_FS_DEVICE->DOEPMSK = 0;
  USB_OTG_FS_DEVICE->DAINTMSK = 0;

  for (int i = 0; i < USB_NUM_EP; i++) {
    if(USB_OTG_FS_EP->IN_Endpoint[i].DIEPCTL & USB_OTG_DIEPCTL_EPENA) {
      if(i == 0) {
        USB_OTG_FS_EP->IN_Endpoint[i].DIEPCTL = USB_OTG_DIEPCTL_SNAK;
      } else {
        USB_OTG_FS_EP->IN_Endpoint[i].DIEPCTL = USB_OTG_DIEPCTL_SNAK | USB_OTG_DIEPCTL_EPDIS;
      }
    } else {
      USB_OTG_FS_EP->IN_Endpoint[i].DIEPCTL = 0;
    }

    if(USB_OTG_FS_EP->OUT_Endpoint[i].DOEPCTL & USB_OTG_DOEPCTL_EPENA) {
      if(i == 0) {
        USB_OTG_FS_EP->OUT_Endpoint[i].DOEPCTL = USB_OTG_DOEPCTL_SNAK;
      } else {
        USB_OTG_FS_EP->OUT_Endpoint[i].DOEPCTL = USB_OTG_DOEPCTL_SNAK | USB_OTG_DOEPCTL_EPDIS;
      }
    } else {
      USB_OTG_FS_EP->OUT_Endpoint[i].DOEPCTL = 0;
    }
    doeptsiz[i] = USB_OTG_FS_EP->OUT_Endpoint[i].DOEPTSIZ = 0;
    USB_OTG_FS_EP->OUT_Endpoint[i].DOEPINT |= USB_OTG_DOEPINT_NAK
                                            | USB_OTG_DIEPINT_BERR // XXX CMSIS is missing DOEPINT.BERR
                                            | USB_OTG_DOEPINT_OUTPKTERR
                                            | (1 << 5)             // XXX CMSIS is missing DOEPINT.STSPHSRX
                                            | USB_OTG_DOEPINT_OTEPDIS
                                            | USB_OTG_DOEPINT_STUP
                                            | USB_OTG_DOEPINT_EPDISD
                                            | USB_OTG_DOEPINT_XFRC;
  }

  USB_OTG_FS_GLOBAL->GINTSTS = USB_OTG_GINTSTS_MMIS
                             | USB_OTG_GINTSTS_USBRST
                             | USB_OTG_GINTSTS_ENUMDNE
                             | USB_OTG_GINTSTS_ESUSP
                             | USB_OTG_GINTSTS_USBSUSP
                             | USB_OTG_GINTSTS_SOF;

  USB_OTG_FS_GLOBAL->GINTMSK = USB_OTG_GINTMSK_MMISM
                             | USB_OTG_GINTMSK_OTGINT;

  USB_OTG_FS_DEVICE->DCFG = (0b11 << USB_OTG_DCFG_DSPD_Pos);
                          // TODO | USB_DCFG_NZLSOHSK ???
  USB_OTG_FS_GLOBAL->GINTMSK |= USB_OTG_GINTMSK_USBRST
                              | USB_OTG_GINTMSK_ENUMDNEM
                              | USB_OTG_GINTMSK_ESUSPM
                              | USB_OTG_GINTMSK_USBSUSPM
                       //       | USB_OTG_GINTMSK_SOFM
                              | USB_OTG_GINTMSK_SRQIM
                              | USB_OTG_GINTMSK_DISCINT;

 /* set PA9 VBUS function to INPUT (NOT VBUS AF) */
  GPIO_MODE_IN(USB_VBUSREG, USB_VBUSBIT);
  GPIO_PULLNONE(USB_VBUSREG, USB_VBUSBIT);

  /* PA12 D+, PA11 D- */
  GPIO_SEL_AF(USB_DPLUSREG, USB_DPLUSBIT, 10);
  GPIO_SEL_AF(USB_DMINUSREG, USB_DMINUSBIT, 10);
  GPIO_MODE_AF(USB_DPLUSREG, USB_DPLUSBIT);
  GPIO_MODE_AF(USB_DMINUSREG, USB_DMINUSBIT);

  GPIO_SPEED(USB_DPLUSREG, USB_DPLUSBIT, IO_SPEED_VH);
  GPIO_SPEED(USB_DMINUSREG, USB_DMINUSBIT, IO_SPEED_VH);

  //USB_Connect(1);

  printf("USB connect\n");
  USB_EnableIRQ();               /* enable USB interrupt */
  USB_SetAddress(0);
}


/*
 *  USB Connect Function
 *   Called by the User to Connect/Disconnect USB
 *    Parameters:      con:   Connect/Disconnect
 *    Return Value:    None
 */

void USB_Connect (uint32_t con) {
  if(con) {
    USB_OTG_FS_GLOBAL->GCCFG |= USB_OTG_GCCFG_VBUSBSEN;
    USB_OTG_FS_DEVICE->DCTL &= ~USB_OTG_DCTL_SDIS;
  } else {
    USB_OTG_FS_GLOBAL->GCCFG &= ~(USB_OTG_GCCFG_VBUSBSEN);
    USB_OTG_FS_DEVICE->DCTL |= USB_OTG_DCTL_SDIS;
  }
}

/*
 * IRQ disable/enable wrapper
 */

void USB_EnableIRQ() {
  NVIC_EnableIRQ(OTG_FS_IRQn);
}
void USB_DisableIRQ() {
  NVIC_DisableIRQ(OTG_FS_IRQn);
}

void USB_EnumDone(void) {
  DBG_USBHW printf("ENUMDONE SPEED=%ld\n", (USB_OTG_FS_DEVICE->DSTS & USB_OTG_DSTS_ENUMSPD) >> USB_OTG_DSTS_ENUMSPD_Pos);
//  USB_OTG_FS_EP->IN_Endpoint[0].DIEPCTL &= ~USB_OTG_DIEPCTL_MPSIZ;
}

/*
 *  USB Reset Function
 *   Called automatically on USB Reset
 *    Return Value:    None
 */

void USB_Reset (uint16_t max_size) {
  /* enable auto NAK for all endpoints (including unused) */
  for(int i = 0; i < 4; i++) {
    USB_OTG_FS_EP->OUT_Endpoint[i].DOEPCTL |= USB_OTG_DOEPCTL_SNAK;
  }

  /* enable IRQs for IN/OUT Endpoints 0 */
  USB_OTG_FS_DEVICE->DAINTMSK = (1 << (/*INEP*/  0 + USB_OTG_DAINTMSK_IEPM_Pos))
                               |(1 << (/*OUTEP*/ 0 + USB_OTG_DAINTMSK_OEPM_Pos));

  /* enable SETUP, Transfer Complete, and Timeout Interrupts */
  USB_OTG_FS_DEVICE->DOEPMSK |= USB_OTG_DOEPMSK_XFRCM | USB_OTG_DOEPMSK_STUPM;
  USB_OTG_FS_DEVICE->DIEPMSK |= USB_OTG_DIEPMSK_XFRCM | USB_OTG_DIEPMSK_TOM;

  /* set FIFO transfer sizes:
     - global OUT/SETUP RX FIFO: 64 words; must be sufficient for ALL OUT EPs
     - EP0 IN TX FIFO: 16 words, starting at 64 words offset (directly after RX FIFO)
  */
  USB_OTG_FS_GLOBAL->GRXFSIZ = USB_RXFIFO_SIZE;
  USB_OTG_FS_GLOBAL->DIEPTXF0_HNPTXFSIZ = (USB_EP0_TXFIFO_SIZE << USB_OTG_TX0FD_Pos)
                                         |(USB_RXFIFO_SIZE << USB_OTG_TX0FSA_Pos);

  /* setup OUT EP0 to receive 1 SETUP packet */
  doeptsiz[0] = USB_OTG_FS_EP->OUT_Endpoint[0].DOEPTSIZ = (1 << USB_OTG_DOEPTSIZ_STUPCNT_Pos)
                                                        | USB_MAX_PACKET0;

  /* set default address */
  USB_SetAddress(0);

  USB_OTG_FS_GLOBAL->GINTMSK |= (USB_OTG_GINTMSK_IEPINT /*| USB_OTG_GINTMSK_OEPINT */);
  USB_OTG_FS_GLOBAL->GINTMSK |= USB_OTG_GINTMSK_RXFLVLM;

  uint32_t mpsiz;
  if(max_size >= 64) {
    mpsiz = USB_OTG_DIEPCTL0_MPSIZ_64;
  } else if (max_size >= 32) {
    mpsiz = USB_OTG_DIEPCTL0_MPSIZ_32;
  } else if (max_size >= 16) {
    mpsiz = USB_OTG_DIEPCTL0_MPSIZ_16;
  } else {
    mpsiz = USB_OTG_DIEPCTL0_MPSIZ_8;
  }
  USB_OTG_FS_EP->IN_Endpoint[0].DIEPCTL = mpsiz;

  USB_OTG_FS_EP->IN_Endpoint[0].DIEPTSIZ = (max_size << USB_OTG_DIEPTSIZ_XFRSIZ_Pos) & USB_OTG_DIEPTSIZ0_XFRSIZ_Msk;
  USB_OTG_FS_EP->OUT_Endpoint[0].DOEPCTL |= USB_OTG_DOEPCTL_EPENA | USB_OTG_DOEPCTL_CNAK;
  USB_OTG_FS_EP->IN_Endpoint[0].DIEPCTL |= USB_OTG_DIEPCTL_EPENA | USB_OTG_DIEPCTL_SNAK;
}


/*
 *  USB Suspend Function
 *   Called automatically on USB Suspend
 *    Return Value:    None
 */

void USB_Suspend (void) {
  /* Performed by Hardware */
}


/*
 *  USB Resume Function
 *   Called automatically on USB Resume
 *    Return Value:    None
 */

void USB_Resume (void) {
  /* Performed by Hardware */
}


/*
 *  USB Remote Wakeup Function
 *   Called automatically on USB Remote Wakeup
 *    Return Value:    None
 */

void USB_WakeUp (void) {
  DBG_USBHW printf("NOIMPL USB_WakeUp\n");
#if 0
  if (USB_DeviceStatus & USB_GETSTATUS_REMOTE_WAKEUP) {
    WrCmdDat(CMD_SET_DEV_STAT, DAT_WR_BYTE(DEV_CON));
  }
#endif
}


/*
 *  USB Remote Wakeup Configuration Function
 *    Parameters:      cfg:   Enable/Disable
 *    Return Value:    None
 */

void USB_WakeUpCfg (uint32_t cfg) {
  /* Not needed */
}


/*
 *  USB Set Address Function
 *    Parameters:      adr:   USB Address
 *    Return Value:    None
 */

void USB_SetAddress (uint32_t adr) {
  DBG_USBHW printf("USB_SetAddress 0x%02lx\n", adr);
  DBG_USBHW printf("%08lx -> %08lx\n", USB_OTG_FS_DEVICE->DCFG, (USB_OTG_FS_DEVICE->DCFG & ~(USB_OTG_DCFG_DAD_Msk))
                          | ((adr << (uint32_t)USB_OTG_DCFG_DAD_Pos) & USB_OTG_DCFG_DAD_Msk));
  USB_OTG_FS_DEVICE->DCFG = (USB_OTG_FS_DEVICE->DCFG & ~(USB_OTG_DCFG_DAD_Msk))
                          | ((adr << (uint32_t)USB_OTG_DCFG_DAD_Pos) & USB_OTG_DCFG_DAD_Msk);
//  USB_OTG_FS_DEVICE->DCFG = 0x00000143;
}


/*
 *  USB Configure Function
 *    Parameters:      cfg:   Configure/Deconfigure
 *    Return Value:    None
 */
/* set or clear internal device "configured" state and realize EP0 */
void USB_Configure (uint32_t cfg) {
  DBG_USBHW printf("NOIMPL USB_Configure\n");
  // XXX probably not required for STM32F4 USB_OTG_FS
}


/*
 *  Configure USB Endpoint according to Descriptor
 *    Parameters:      pEPD:  Pointer to Endpoint Descriptor
 *    Return Value:    None
 */

void USB_ConfigEP (USB_ENDPOINT_DESCRIPTOR *pEPD) {
  uint32_t num;
  int isIn;

  num = pEPD->bEndpointAddress;
  isIn = (num & 0x80);
  num &= 0x0f;

  uint32_t mpsiz = (pEPD->wMaxPacketSize << USB_OTG_DIEPCTL_MPSIZ_Pos) & USB_OTG_DIEPCTL_MPSIZ_Msk;
  uint32_t eptyp = ((pEPD->bmAttributes & 0x3) << USB_OTG_DIEPCTL_EPTYP_Pos);
  uint32_t txfnum = (num << USB_OTG_DIEPCTL_TXFNUM_Pos);

  // DAINTMSK:
  // unmask EP IRQ
  USB_OTG_FS_DEVICE->DAINTMSK |= (isIn ? (1 << num) : ((1 << 16) << num));

  if(isIn) {
    /* setup FIFO for IN EPx:
       - start address: after RX FIFO + EP0 FIFO + n previous EPx FIFOs
       - size: generic TXFIFO size (64 words)
     */
    USB_OTG_FS_GLOBAL->DIEPTXF[num-1] = (USB_EPx_TXFIFO_SIZE << USB_OTG_DIEPTXF_INEPTXFD_Pos)
                                      | (USB_RXFIFO_SIZE + USB_EP0_TXFIFO_SIZE + (USB_EPx_TXFIFO_SIZE * (num-1)));
    DBG_USBHW printf("ConfigEP set DIEPTXF=%08lx\n", (USB_EPx_TXFIFO_SIZE << USB_OTG_DIEPTXF_INEPTXFD_Pos)
                                      | (USB_RXFIFO_SIZE + USB_EP0_TXFIFO_SIZE + (USB_EPx_TXFIFO_SIZE * (num-1))));
  // DxEPTSIZ:
  // set XFRSIZ
  // set PKTCNT
  // XXX probably do this on WriteEP only...
//    USB_OTG_FS_EP->IN_Endpoint[num].DIEPTSIZ = 


  // DxEPCTL:
  // set MPSIZ
  // set EPTYP
  // set CNAK
  // set TXFNUM (for IN EP)
  // set EPENA
  // set USBAEP

    USB_OTG_FS_EP->IN_Endpoint[num].DIEPCTL = mpsiz
                                            | eptyp
                                            | txfnum
                                            | USB_OTG_DIEPCTL_SNAK
                                            | USB_OTG_DIEPCTL_USBAEP;
  } else {
    USB_OTG_FS_EP->OUT_Endpoint[num].DOEPCTL = mpsiz
                                             | eptyp
                                             | USB_OTG_DOEPCTL_CNAK
                                             | USB_OTG_DOEPCTL_EPENA
                                             | USB_OTG_DOEPCTL_USBAEP;

    doeptsiz[num] = USB_OTG_FS_EP->OUT_Endpoint[num].DOEPTSIZ = mpsiz
                                                              | USB_OTG_PKTCNT0(1);
  }
}


/*
 *  Set Direction for USB Control Endpoint
 *    Parameters:      dir:   Out (dir == 0), In (dir <> 0)
 *    Return Value:    None
 */

void USB_DirCtrlEP (uint32_t dir) {
  /* Not needed */
}


/*
 *  Enable USB Endpoint
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *    Return Value:    None
 */

void USB_EnableEP (uint32_t EPNum) {
  uint8_t in = EPNum & 0x80;
  EPNum &= 0x0f;
  if(in) {
    USB_OTG_FS_EP->IN_Endpoint[EPNum].DIEPCTL |= USB_OTG_DIEPCTL_EPENA | USB_OTG_DIEPCTL_CNAK;
  } else {
    USB_OTG_FS_EP->OUT_Endpoint[EPNum].DOEPCTL |= USB_OTG_DOEPCTL_EPENA | USB_OTG_DOEPCTL_CNAK;
  }
}


/*
 *  Disable USB Endpoint
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *    Return Value:    None
 */

void USB_DisableEP (uint32_t EPNum) {
  uint8_t in = EPNum & 0x80;
  EPNum &= 0x0f;
  if(in) {
    USB_Flush_TXFIFO(EPNum);
    USB_OTG_FS_EP->IN_Endpoint[EPNum].DIEPCTL |= USB_OTG_DIEPCTL_EPDIS | USB_OTG_DIEPCTL_SNAK;
  } else {
    USB_OTG_FS_EP->OUT_Endpoint[EPNum].DOEPCTL |= USB_OTG_DOEPCTL_EPDIS | USB_OTG_DOEPCTL_SNAK;
  }
}


/*
 *  Reset USB Endpoint
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *    Return Value:    None
 */

void USB_ResetEP (uint32_t EPNum) {
  USB_ClrStallEP(EPNum);
  USB_EnableEP(EPNum);
}


/*
 *  Set Stall for USB Endpoint
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *    Return Value:    None
 */

void USB_SetStallEP (uint32_t EPNum) {
  if(EPNum & 0x80) {
    USB_OTG_FS_EP->IN_Endpoint[EPNum & 0x0f].DIEPCTL |= USB_OTG_DIEPCTL_STALL;
  } else {
    USB_OTG_FS_EP->OUT_Endpoint[EPNum & 0x0f].DOEPCTL |= USB_OTG_DOEPCTL_STALL;
  }
}


/*
 *  Clear Stall for USB Endpoint
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *    Return Value:    None
 */

void USB_ClrStallEP (uint32_t EPNum) {
  if(EPNum & 0x80) {
    USB_OTG_FS_EP->IN_Endpoint[EPNum & 0x0f].DIEPCTL &= ~USB_OTG_DIEPCTL_STALL;
  } else {
    USB_OTG_FS_EP->OUT_Endpoint[EPNum & 0x0f].DOEPCTL &= ~USB_OTG_DOEPCTL_STALL;
  }
}


/*
 *  Clear USB Endpoint Buffer
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *    Return Value:    None
 */

void USB_ClearEPBuf (uint32_t EPNum) {
  printf("NOIMPL USB_ClearEPBuf\n");
}


/*
 *  Read USB Endpoint Data
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *                     pData: Pointer to Data Buffer
 *    Return Value:    Number of bytes read
 */

uint32_t USB_ReadEP (uint32_t EPNum, uint8_t *pData) {
  /* on USB_OTG this only copies from EP soft buffer to target buffer.
     Data is already fetched by RX FIFO handler.
     TODO Try doing this without extra copy, e.g. by setting pointers only */

  DBG_USBHW printf("ReadEP ep=%ld, buff=%p, len=%d, data[0]=%02x\n", EPNum, epout[EPNum].buff, epout[EPNum].length, epout[EPNum].buff[0]);
  memcpy(pData, epout[EPNum].buff, epout[EPNum].length);
  return epout[EPNum].length;
}


/*
 *  Write USB Endpoint Data
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *                     pData: Pointer to Data Buffer
 *                     cnt:   Number of bytes to write
 *    Return Value:    Number of bytes written
 */

uint32_t USB_WriteEP (uint32_t EPNum, uint8_t *pData, uint32_t cnt) {
  uint32_t cnt32 = (cnt + 3) / 4;
  uint32_t *pData32;
  uint32_t dtxfsts = USB_OTG_FS_EP->IN_Endpoint[EPNum & 0xf].DTXFSTS;
  DBG_USBHW printf("WriteEP ep=%ld data @%p, count=%ld cnt32=%ld\n", EPNum, pData,cnt,cnt32);
  EPNum &= 0xf;
  pData32 = (uint32_t *)pData;

  USB_OTG_FS_EP->IN_Endpoint[EPNum].DIEPTSIZ = (cnt & USB_OTG_DIEPTSIZ0_XFRSIZ_Msk)
                                              |(USB_OTG_PKTCNT0(1));
  USB_OTG_FS_EP->IN_Endpoint[EPNum].DIEPCTL |= USB_OTG_DIEPCTL_EPENA | USB_OTG_DIEPCTL_CNAK;
  DBG_USBHW printf("DTXFSTS=%08lx\n", dtxfsts);
  while((USB_OTG_FS_EP->IN_Endpoint[EPNum].DTXFSTS & USB_OTG_DTXFSTS_INEPTFSAV) < cnt32);

  while(cnt32--) {
    DBG_USBHW printf("tx %08lx\n", *pData32);
    USB_OTG_FS_FIFO->FIFO[EPNum].FIFOData[0] = *pData32++;
  }
  DBG_USBHW printf("DTXFSTS=%08lx\n", dtxfsts);
  return cnt;
}

#if USB_DMA

/* DMA Descriptor Memory Layout */
const uint32_t DDAdr[2] = { DD_NISO_ADR, DD_ISO_ADR };
const uint32_t DDSz [2] = { 16,          20         };


/*
 *  Setup USB DMA Transfer for selected Endpoint
 *    Parameters:      EPNum: Endpoint Number
 *                     pDD: Pointer to DMA Descriptor
 *    Return Value:    TRUE - Success, FALSE - Error
 */

uint32_t USB_DMA_Setup(uint32_t EPNum, USB_DMA_DESCRIPTOR *pDD) {
  uint32_t num, ptr, nxt, iso, n;

  iso = pDD->Cfg.Type.IsoEP;                /* Iso or Non-Iso Descriptor */
  num = EPAdr(EPNum);                       /* Endpoint's Physical Address */

  ptr = 0;                                  /* Current Descriptor */
  nxt = udca[num];                          /* Initial Descriptor */
  while (nxt) {                             /* Go through Descriptor List */
    ptr = nxt;                              /* Current Descriptor */
    if (!pDD->Cfg.Type.Link) {              /* Check for Linked Descriptors */
      n = (ptr - DDAdr[iso]) / DDSz[iso];   /* Descriptor Index */
      DDMemMap[iso] &= ~(1 << n);           /* Unmark Memory Usage */
    }
    nxt = *((uint32_t *)ptr);                  /* Next Descriptor */
  }

  for (n = 0; n < 32; n++) {                /* Search for available Memory */
    if ((DDMemMap[iso] & (1 << n)) == 0) {
      break;                                /* Memory found */
    }
  }
  if (n == 32) return (FALSE);              /* Memory not available */

  DDMemMap[iso] |= 1 << n;                  /* Mark Memory Usage */
  nxt = DDAdr[iso] + n * DDSz[iso];         /* Next Descriptor */

  if (ptr && pDD->Cfg.Type.Link) {
    *((uint32_t *)(ptr + 0))  = nxt;           /* Link in new Descriptor */
    *((uint32_t *)(ptr + 4)) |= 0x00000004;    /* Next DD is Valid */
  } else {
    udca[num] = nxt;                        /* Save new Descriptor */
    UDCA[num] = nxt;                        /* Update UDCA in USB */
  }

  /* Fill in DMA Descriptor */
  *(((uint32_t *)nxt)++) =  0;                 /* Next DD Pointer */
  *(((uint32_t *)nxt)++) =  pDD->Cfg.Type.ATLE |
                       (pDD->Cfg.Type.IsoEP << 4) |
                       (pDD->MaxSize <<  5) |
                       (pDD->BufLen  << 16);
  *(((uint32_t *)nxt)++) =  pDD->BufAdr;
  *(((uint32_t *)nxt)++) =  pDD->Cfg.Type.LenPos << 8;
  if (iso) {
    *((uint32_t *)nxt) =  pDD->InfoAdr;
  }

  return (TRUE); /* Success */
}


/*
 *  Enable USB DMA Endpoint
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *    Return Value:    None
 */

void USB_DMA_Enable (uint32_t EPNum) {
  LPC_USB->USBEpDMAEn = 1 << EPAdr(EPNum);
}


/*
 *  Disable USB DMA Endpoint
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *    Return Value:    None
 */

void USB_DMA_Disable (uint32_t EPNum) {
  LPC_USB->USBEpDMADis = 1 << EPAdr(EPNum);
}


/*
 *  Get USB DMA Endpoint Status
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *    Return Value:    DMA Status
 */

uint32_t USB_DMA_Status (uint32_t EPNum) {
  uint32_t ptr, val;
          
  ptr = UDCA[EPAdr(EPNum)];                 /* Current Descriptor */
  if (ptr == 0) 
	return (USB_DMA_INVALID);

  val = *((uint32_t *)(ptr + 3*4));            /* Status Information */
  switch ((val >> 1) & 0x0F) {
    case 0x00:                              /* Not serviced */
      return (USB_DMA_IDLE);
    case 0x01:                              /* Being serviced */
      return (USB_DMA_BUSY);
    case 0x02:                              /* Normal Completition */
      return (USB_DMA_DONE);
    case 0x03:                              /* Data Under Run */
      return (USB_DMA_UNDER_RUN);
    case 0x08:                              /* Data Over Run */
      return (USB_DMA_OVER_RUN);
    case 0x09:                              /* System Error */
      return (USB_DMA_ERROR);
  }

  return (USB_DMA_UNKNOWN);
}


/*
 *  Get USB DMA Endpoint Current Buffer Address
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *    Return Value:    DMA Address (or -1 when DMA is Invalid)
 */

uint32_t USB_DMA_BufAdr (uint32_t EPNum) {
  uint32_t ptr, val;

  ptr = UDCA[EPAdr(EPNum)];                 /* Current Descriptor */
  if (ptr == 0)
  {
	return ((uint32_t)(-1));                /* DMA Invalid */
  }

  val = *((uint32_t *)(ptr + 2*4));         /* Buffer Address */
  return (val);                             /* Current Address */
}


/*
 *  Get USB DMA Endpoint Current Buffer Count
 *   Number of transfered Bytes or Iso Packets
 *    Parameters:      EPNum: Endpoint Number
 *                       EPNum.0..3: Address
 *                       EPNum.7:    Dir
 *    Return Value:    DMA Count (or -1 when DMA is Invalid)
 */

uint32_t USB_DMA_BufCnt (uint32_t EPNum) {
  uint32_t ptr, val;

  ptr = UDCA[EPAdr(EPNum)];                 /* Current Descriptor */
  if (ptr == 0)
  { 
	return ((uint32_t)(-1));                /* DMA Invalid */
  }
  val = *((uint32_t *)(ptr + 3*4));         /* Status Information */
  return (val >> 16);                       /* Current Count */
}


#endif /* USB_DMA */


/*
 *  Get USB Last Frame Number
 *    Parameters:      None
 *    Return Value:    Frame Number
 */

uint32_t USB_GetFrame (void) {
  printf("NOIMPL USB_GetFrame\n");
  return 0;
/* FIXME
  uint32_t val;

  WrCmd(CMD_RD_FRAME);
  val = RdCmdDat(DAT_RD_FRAME);
  val = val | (RdCmdDat(DAT_RD_FRAME) << 8);

  return (val);
*/
}

void USB_ReadPacket(uint8_t *dest, uint16_t count) {
  uint16_t count32, remainder;
  uint8_t  *dest8;
  uint32_t *dest32;
  uint32_t data;

  count32 = count >> 2;
  remainder = count & 0x3;
  dest8 = dest;
  dest32 = (uint32_t *)dest;

  while(count32--) {
    data = USB_OTG_FS_FIFO->FIFO[0].FIFOData[0];
    DBG_USBHW printf("data %08lx\n", data);
    *dest32++ = data;
    dest8 += 4;
  }

  if(remainder) {
    int i = 0;
    data = USB_OTG_FS_FIFO->FIFO[0].FIFOData[0];
    DBG_USBHW printf("data %08lx (remainder)\n", data);
    while(remainder--) {
      *dest8++ = (data >> (8 * i)) & 0xff;
      i++;
    }
  }
}

uint32_t USB_GetAllOEPInt(void) {
  uint32_t data;
  data  = USB_OTG_FS_DEVICE->DAINT;
  data &= USB_OTG_FS_DEVICE->DAINTMSK;
  return (data >> 16) & 0xffff;
}

uint32_t USB_GetAllIEPInt(void) {
  uint32_t data;
  data  = USB_OTG_FS_DEVICE->DAINT;
  data &= USB_OTG_FS_DEVICE->DAINTMSK;
  return data & 0xffff;
}
/*
 *  USB Interrupt Service Routine
 */

void OTG_FS_IRQHandler (void) {
  uint32_t gintsts, gotgintsts = 0;
  //uint32_t oepint, iepint;
  USB_OTG_GRXSTSP_Typedef otg_status;
  gintsts = USB_OTG_FS_GLOBAL->GINTSTS & USB_OTG_FS_GLOBAL->GINTMSK;
  //oepint = USB_OTG_FS_DEVICE->O
  DBG_USBHW printf("USB %08lx\n", gintsts);

  if(gintsts & USB_OTG_GINTSTS_USBRST) {
    // USB Reset interrupt from USB controller, perform basic endpoint setup
    DBG_USBHW printf("USBRST\n");
    USB_OTG_FS_GLOBAL->GINTSTS |= USB_OTG_GINTSTS_USBRST;
    USB_Reset(USB_MAX_PACKET0);
  }

  if(gintsts & USB_OTG_GINTSTS_ENUMDNE) {
    USB_EnumDone();
    USB_OTG_FS_GLOBAL->GINTSTS |= USB_OTG_GINTSTS_ENUMDNE;
  }

  if(gintsts & USB_OTG_GINTSTS_USBSUSP) {
    USB_OTG_FS_GLOBAL->GINTSTS |= USB_OTG_GINTSTS_USBSUSP;
  }

  if(gintsts & USB_OTG_GINTSTS_ESUSP) {
    USB_OTG_FS_GLOBAL->GINTSTS |= USB_OTG_GINTSTS_ESUSP;
  }

  if(gintsts & USB_OTG_GINTSTS_SRQINT) {
    DBG_USBHW printf("SRQ\n");
    USB_OTG_FS_GLOBAL->GINTSTS |= USB_OTG_GINTSTS_SRQINT;
  }

  if(gintsts & USB_OTG_GINTSTS_IEPINT) {
    uint32_t iepint = USB_GetAllIEPInt();
    uint8_t epnum = 0;
    while(iepint) {
      if(iepint & 1) {
        uint32_t diepint = USB_OTG_FS_EP->IN_Endpoint[epnum].DIEPINT;
        if(diepint & USB_OTG_DIEPINT_XFRC) {
          DBG_USBHW printf("DIEPINT%d %08lx\n", epnum, diepint);
          DBG_USBHW printf("IN\n");
          USB_OTG_FS_EP->IN_Endpoint[epnum].DIEPINT = USB_OTG_DIEPINT_XFRC;
          USB_P_EP[epnum](USB_EVT_IN);
        }
      }
      iepint >>= 1;
      epnum++;
    }
  }
/*/
  if(gintsts & USB_OTG_GINTSTS_OEPINT) {
    uint32_t oepint = USB_GetAllOEPInt();
    uint8_t epnum = 0;
    while(oepint) {
      if(oepint & 1) {
        uint32_t doepint = USB_OTG_FS_EP->OUT_Endpoint[epnum].DOEPINT;
        if(doepint) {
printf("DOEPINT%d %08lx\n", epnum, doepint);
          if(doepint & USB_OTG_DOEPINT_STUP) {
printf("SETUP\n");
//             USB_Flush_TXFIFO(0);
            USB_P_EP[0](USB_EVT_SETUP);
            USB_OTG_FS_EP->OUT_Endpoint[0].DOEPINT = USB_OTG_DOEPINT_STUP;
            USB_OTG_FS_EP->OUT_Endpoint[0].DOEPCTL |= USB_OTG_DOEPCTL_CNAK | USB_OTG_DOEPCTL_EPENA;
            USB_OTG_FS_EP->OUT_Endpoint[0].DOEPTSIZ = doeptsiz[0];
          }
          if(doepint & USB_OTG_DOEPINT_XFRC) {
            printf("OUT\n");
            //USB_P_EP[epnum](USB_EVT_OUT);
            USB_OTG_FS_EP->OUT_Endpoint[epnum].DOEPINT = USB_OTG_DOEPINT_XFRC;
            USB_OTG_FS_EP->OUT_Endpoint[epnum].DOEPCTL |= USB_OTG_DOEPCTL_CNAK | USB_OTG_DOEPCTL_EPENA;
            USB_OTG_FS_EP->OUT_Endpoint[epnum].DOEPTSIZ = doeptsiz[epnum];
          }
        }
      }
      oepint >>= 1;
      epnum++;
    }
  }
*/
  if(gintsts & USB_OTG_GINTSTS_RXFLVL) {
    otg_status.raw = USB_OTG_FS_GLOBAL->GRXSTSP;
    uint32_t bytecount = otg_status.bcnt;
    uint8_t epnum = otg_status.epnum;
    uint8_t pktsts = otg_status.pktsts;

    DBG_USBHW printf("RXSTS %08lx\nepnum=%d pktsts=%d bytes=%ld\n", otg_status.raw, epnum, pktsts, bytecount);

    if(pktsts == STS_SETUP_COMP) {
      USB_P_EP[epnum](USB_EVT_SETUP);
    }

    if(pktsts == STS_SETUP_COMP || pktsts == STS_XFER_COMP) {
        USB_OTG_FS_EP->OUT_Endpoint[epnum].DOEPCTL |= USB_OTG_DOEPCTL_CNAK | USB_OTG_DOEPCTL_EPENA;
        USB_OTG_FS_EP->OUT_Endpoint[epnum].DOEPTSIZ = doeptsiz[epnum];
        return;
    }

    if(pktsts == STS_SETUP_UPDT) {
      USB_ReadPacket((uint8_t*)&SetupPacket, 8);
      DBG_USBHW printf("-> to SetupPacket\n");
      USB_Flush_TXFIFO(0);
    } else if(pktsts == STS_DATA_UPDT) {
      USB_ReadPacket(epout[epnum].buff, otg_status.bcnt);
      epout[epnum].length = otg_status.bcnt;
      DBG_USBHW printf("-> to EPOut[%d].buff\n", epnum);
      USB_P_EP[epnum](USB_EVT_OUT);
    }
    DBG_USBHW printf("DOEPTSIZ%d = %08lx\n", epnum, USB_OTG_FS_EP->OUT_Endpoint[epnum].DOEPTSIZ);
  }

  if(gintsts & USB_OTG_GINTSTS_OTGINT) {
    gotgintsts = USB_OTG_FS_GLOBAL->GOTGINT;
    USB_OTG_FS_GLOBAL->GOTGINT = USB_OTG_FS_GLOBAL->GOTGINT;
    DBG_USBHW printf(" OTG %08lx\n", gotgintsts);
    USB_OTG_FS_GLOBAL->GINTSTS |= USB_OTG_GINTSTS_OTGINT;
  }



#if 0
  uint32_t disr, val, n, m;
  uint32_t episr, episrCur;

  disr = LPC_USB->USBDevIntSt;       /* Device Interrupt Status */
  /* Device Status Interrupt (Reset, Connect change, Suspend/Resume) */
  if (disr & DEV_STAT_INT) {
    LPC_USB->USBDevIntClr = DEV_STAT_INT;
    WrCmd(CMD_GET_DEV_STAT);
    val = RdCmdDat(DAT_GET_DEV_STAT);       /* Device Status */
    if (val & DEV_RST) {                    /* Reset */
      USB_Reset();
#if   USB_RESET_EVENT
      USB_Reset_Event();
#endif
    }
    if (val & DEV_CON_CH) {                 /* Connect change */
#if   USB_POWER_EVENT
      USB_Power_Event(val & DEV_CON);
#endif
    }
    if (val & DEV_SUS_CH) {                 /* Suspend/Resume */
      if (val & DEV_SUS) {                  /* Suspend */
        USB_Suspend();
#if     USB_SUSPEND_EVENT
        USB_Suspend_Event();
#endif
      } else {                              /* Resume */
        USB_Resume();
#if     USB_RESUME_EVENT
        USB_Resume_Event();
#endif
      }
    }
    goto isr_end;
  }

#if USB_SOF_EVENT
  /* Start of Frame Interrupt */
  if (disr & FRAME_INT) {
    USB_SOF_Event();
  }
#endif

#if USB_ERROR_EVENT
  /* Error Interrupt */
  if (disr & ERR_INT) {
    WrCmd(CMD_RD_ERR_STAT);
    val = RdCmdDat(DAT_RD_ERR_STAT);
    USB_Error_Event(val);
  }
#endif

  /* Endpoint's Slow Interrupt */
  if (disr & EP_SLOW_INT) {
    episrCur = 0;
    episr    = LPC_USB->USBEpIntSt;
    for (n = 0; n < USB_EP_NUM; n++) {      /* Check All Endpoints */
      if (episr == episrCur) break;         /* break if all EP interrupts handled */
      if (episr & (1 << n)) {
        episrCur |= (1 << n);
        m = n >> 1;
  
        LPC_USB->USBEpIntClr = (1 << n);
        while ((LPC_USB->USBDevIntSt & CDFULL_INT) == 0);
        val = LPC_USB->USBCmdData;
  
        if ((n & 1) == 0) {                 /* OUT Endpoint */
          if (n == 0) {                     /* Control OUT Endpoint */
            if (val & EP_SEL_STP) {         /* Setup Packet */
              if (USB_P_EP[0]) {
                USB_P_EP[0](USB_EVT_SETUP);
                continue;
              }
            }
          }
          if (USB_P_EP[m]) {
            USB_P_EP[m](USB_EVT_OUT);
          }
        } else {                            /* IN Endpoint */
          if (USB_P_EP[m]) {
            USB_P_EP[m](USB_EVT_IN);
          }
        }
      }
    }
    LPC_USB->USBDevIntClr = EP_SLOW_INT;
  }

#if USB_DMA

  if (LPC_USB->USBDMAIntSt & 0x00000001) {          /* End of Transfer Interrupt */
    val = LPC_USB->USBEoTIntSt;
    for (n = 2; n < USB_EP_NUM; n++) {      /* Check All Endpoints */
      if (val & (1 << n)) {
        m = n >> 1;
        if ((n & 1) == 0) {                 /* OUT Endpoint */
          if (USB_P_EP[m]) {
            USB_P_EP[m](USB_EVT_OUT_DMA_EOT);
          }
        } else {                            /* IN Endpoint */
          if (USB_P_EP[m]) {
            USB_P_EP[m](USB_EVT_IN_DMA_EOT);
          }
        }
      }
    }
    LPC_USB->USBEoTIntClr = val;
  }

  if (LPC_USB->USBDMAIntSt & 0x00000002) {          /* New DD Request Interrupt */
    val = LPC_USB->USBNDDRIntSt;
    for (n = 2; n < USB_EP_NUM; n++) {      /* Check All Endpoints */
      if (val & (1 << n)) {
        m = n >> 1;
        if ((n & 1) == 0) {                 /* OUT Endpoint */
          if (USB_P_EP[m]) {
            USB_P_EP[m](USB_EVT_OUT_DMA_NDR);
          }
        } else {                            /* IN Endpoint */
          if (USB_P_EP[m]) {
            USB_P_EP[m](USB_EVT_IN_DMA_NDR);
          }
        }
      }
    }
    LPC_USB->USBNDDRIntClr = val;
  }

  if (LPC_USB->USBDMAIntSt & 0x00000004) {          /* System Error Interrupt */
    val = LPC_USB->USBSysErrIntSt;
    for (n = 2; n < USB_EP_NUM; n++) {      /* Check All Endpoints */
      if (val & (1 << n)) {
        m = n >> 1;
        if ((n & 1) == 0) {                 /* OUT Endpoint */
          if (USB_P_EP[m]) {
            USB_P_EP[m](USB_EVT_OUT_DMA_ERR);
          }
        } else {                            /* IN Endpoint */
          if (USB_P_EP[m]) {
            USB_P_EP[m](USB_EVT_IN_DMA_ERR);
          }
        }
      }
    }
    LPC_USB->USBSysErrIntClr = val;
  }

#endif /* USB_DMA */
isr_end:
#endif
  return;
}


/* LPC implementation:
   "For an IN endpoint, at least one write endpoint buffer is empty."
-> STM32: check EP TXFIFO for at least MPSIZ worth of space.
   WriteEP already does that so no need to handle it here */
char Endpoint_IsINReady(void) {
  return 1;
}

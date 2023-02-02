/*----------------------------------------------------------------------------
 *      U S B  -  K e r n e l
 *----------------------------------------------------------------------------
 * Name:    usbhw.h
 * Purpose: USB Hardware Layer Definitions
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

#ifndef __USBHW_H__
#define __USBHW_H__
#include <stdint.h>
#include "config.h"
#include "usb.h"

#ifdef DEBUG_USBHW
  #define DBG_USBHW
#else
  #define DBG_USBHW while(0)
#endif

//saturnu
/// INAK_BI - Interrupt on NAK for Bulk In
#define INAK_BI			0x20

#define STS_GOUT_NAK                           1U
#define STS_DATA_UPDT                          2U
#define STS_XFER_COMP                          3U
#define STS_SETUP_COMP                         4U
#define STS_SETUP_UPDT                         6U


typedef struct
{
  int epnum;
  uint8_t buff[64];
  uint8_t length;
} USB_EndPointState;

/* USB OTG registers definitions */
typedef struct
{
  USB_OTG_INEndpointTypeDef IN_Endpoint[4];
  uint32_t Reserved80[96];
  USB_OTG_OUTEndpointTypeDef OUT_Endpoint[4];
} USB_OTG_EndpointsTypeDef;

/* USB FIFO memory mapping */
typedef struct
{
  __IO uint32_t FIFOData[USB_OTG_FIFO_SIZE / 4];
} USB_OTG_FIFOTypeDef;

typedef struct
{
  USB_OTG_FIFOTypeDef FIFO[4];
} USB_OTG_FIFOMapTypeDef;

typedef union
{
  struct { /* LSB to MSB */
    uint32_t epnum    :  4;
    uint32_t bcnt     : 11;
    uint32_t dpid     :  2;
    uint32_t pktsts   :  4;
    uint32_t frmnum   :  4;
    uint32_t reserved :  7;
  };
  uint32_t raw;
} USB_OTG_GRXSTSP_Typedef;

#define USB_OTG_FS_GLOBAL  (USB_OTG_FS)
#define USB_OTG_FS_HOST    ((USB_OTG_HostTypeDef *)(USB_OTG_FS_PERIPH_BASE + USB_OTG_HOST_BASE))
#define USB_OTG_FS_DEVICE  ((USB_OTG_DeviceTypeDef *)(USB_OTG_FS_PERIPH_BASE + USB_OTG_DEVICE_BASE))
#define USB_OTG_FS_PCGCCTL ((__IO uint32_t *)(USB_OTG_FS_PERIPH_BASE + USB_OTG_PCGCCTL_BASE))
#define USB_OTG_FS_EP      ((USB_OTG_EndpointsTypeDef *)(USB_OTG_FS_PERIPH_BASE + USB_OTG_IN_ENDPOINT_BASE))
#define USB_OTG_FS_FIFO    ((USB_OTG_FIFOMapTypeDef *)(USB_OTG_FS_PERIPH_BASE + USB_OTG_FIFO_BASE))

#define USB_OTG_DIEPCTL0_MPSIZ_8  (0b11)
#define USB_OTG_DIEPCTL0_MPSIZ_16 (0b10)
#define USB_OTG_DIEPCTL0_MPSIZ_32 (0b01)
#define USB_OTG_DIEPCTL0_MPSIZ_64 (0b00)
#define USB_OTG_DIEPTSIZ0_XFRSIZ_Msk (0x7f)
#define USB_OTG_DIEPTSIZ0_PKTCNT_Msk (0x03 << USB_OTG_DIEPTSIZ_PKTCNT_Pos)

#define USB_OTG_PKTCNT0(x) (((x) << USB_OTG_DIEPTSIZ_PKTCNT_Pos) & USB_OTG_DIEPTSIZ0_PKTCNT_Msk)

#define USB_EP0_TXFIFO_SIZE (16)
#define USB_RXFIFO_SIZE     (65)
#define USB_EPx_TXFIFO_SIZE (65)

/* USB DMA Descriptor */
typedef struct _USB_DMA_DESCRIPTOR {
  uint32_t BufAdr;                     /* DMA Buffer Address */
  uint16_t  BufLen;                     /* DMA Buffer Length */
  uint16_t  MaxSize;                    /* Maximum Packet Size */
  uint32_t InfoAdr;                    /* Packet Info Memory Address */
  union {                           /* DMA Configuration */
    struct {
      uint32_t Link   : 1;             /* Link to existing Descriptors */
      uint32_t IsoEP  : 1;             /* Isonchronous Endpoint */
      uint32_t ATLE   : 1;             /* ATLE (Auto Transfer Length Extract) */
      uint32_t Rsrvd  : 5;             /* Reserved */
      uint32_t LenPos : 8;             /* Length Position (ATLE) */
    } Type;
    uint32_t Val;
  } Cfg;
} USB_DMA_DESCRIPTOR;

/* USB Hardware Functions */
extern void  USB_Init       (void);
extern void  USB_Connect    (uint32_t  con);
extern void  USB_EnableIRQ  (void);
extern void  USB_DisableIRQ (void);
extern void  USB_Reset      (uint16_t max_size);
extern void  USB_Suspend    (void);
extern void  USB_Resume     (void);
extern void  USB_WakeUp     (void);
extern void  USB_WakeUpCfg  (uint32_t  cfg);
extern void  USB_SetAddress (uint32_t adr);
extern void  USB_Configure  (uint32_t  cfg);
extern void  USB_ConfigEP   (USB_ENDPOINT_DESCRIPTOR *pEPD);
extern void  USB_DirCtrlEP  (uint32_t dir);
extern void  USB_EnableEP   (uint32_t EPNum);
extern void  USB_DisableEP  (uint32_t EPNum);
extern void  USB_ResetEP    (uint32_t EPNum);
extern void  USB_SetStallEP (uint32_t EPNum);
extern void  USB_ClrStallEP (uint32_t EPNum);
extern void USB_ClearEPBuf  (uint32_t  EPNum);
extern uint32_t USB_ReadEP     (uint32_t EPNum, uint8_t *pData);
extern uint32_t USB_WriteEP    (uint32_t EPNum, uint8_t *pData, uint32_t cnt);
extern uint32_t  USB_DMA_Setup  (uint32_t EPNum, USB_DMA_DESCRIPTOR *pDD);
extern void  USB_DMA_Enable (uint32_t EPNum);
extern void  USB_DMA_Disable(uint32_t EPNum);
extern uint32_t USB_DMA_Status (uint32_t EPNum);
extern uint32_t USB_DMA_BufAdr (uint32_t EPNum);
extern uint32_t USB_DMA_BufCnt (uint32_t EPNum);
extern uint32_t USB_GetFrame   (void);
extern void  USB_IRQHandler (void);

//saturnu
extern uint32_t EPAdr (uint32_t EPNum);
extern uint32_t RdCmdDat (uint32_t cmd);
extern void WrCmd (uint32_t cmd);

extern char Endpoint_IsINReady(void);

#endif  /* __USBHW_H__ */

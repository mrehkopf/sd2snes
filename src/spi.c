/* Sd2iec - SD/MMC to Commodore serial bus interface/controller
   Copyright (C) 2007-2010  Ingo Korb <ingo@akana.de>

   Inspiration and low-level SD/MMC access based on code from MMC2IEC
     by Lars Pontoppidan et al., see sdcard.c|h and config.h.

   FAT filesystem access based on code from ChaN and Jim Brain, see ff.c|h.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License only.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


   spi.c: Low-level SPI routines

*/

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "config.h"
#include "spi.h"
#include "uart.h"

#define SSP_TFE 0   // Transmit FIFO empty
#define SSP_TNF 1   // Transmit FIFO not full
#define SSP_RNE 2   // Receive FIFO not empty
#define SSP_RFF 3   // Receive FIFO full
#define SSP_BSY 4   // Busy

typedef struct {
  LPC_SSP_TypeDef     *SSP_REGS;
  LPC_GPDMACH_TypeDef *SSP_DMACH;
  uint32_t            *SSP_PCLKREG;
  int                  SSP_PCLKBIT;
  int                  SSP_DMAID_TX;
  int                  SSP_DMAID_RX;
} ssp_props;


static ssp_props SSP_SEL[2] = {
  { LPC_SSP0, LPC_GPDMACH0, (uint32_t*)&(LPC_SC->PCLKSEL1), 10, 0, 1 }, /* SSP0 */
  { LPC_SSP1, LPC_GPDMACH1, (uint32_t*)&(LPC_SC->PCLKSEL0), 20, 2, 3 }  /* SSP1 */
};

void spi_preinit(int device) {
  /* select interface */
  ssp_props *ssp = &(SSP_SEL[device]);

  /* Set clock prescaler to 1:1 */
  BITBAND(*(ssp->SSP_PCLKREG), ssp->SSP_PCLKBIT) = 1;
}

void spi_init(spi_speed_t speed, int device) {

  /* select interface */
  ssp_props *ssp = &(SSP_SEL[device]);

  /* configure data format - 8 bits, SPI, CPOL=0, CPHA=0, 1 clock per bit */
  ssp->SSP_REGS->CR0 = (8-1);

  /* set clock prescaler */
  if (speed == SPI_SPEED_FAST) {
    ssp->SSP_REGS->CPSR = SSP_CLK_DIVISOR_FAST;
  } else if (speed == SPI_SPEED_SLOW) {
    ssp->SSP_REGS->CPSR = SSP_CLK_DIVISOR_SLOW;
  } else if (speed == SPI_SPEED_FPGA_FAST) {
    ssp->SSP_REGS->CPSR = SSP_CLK_DIVISOR_FPGA_FAST;
  } else {
    ssp->SSP_REGS->CPSR = SSP_CLK_DIVISOR_FPGA_SLOW;
  }

  /* Enable SSP */
  ssp->SSP_REGS->CR1 = BV(1);

  /* Enable DMA controller, little-endian mode */
  BITBAND(LPC_SC->PCONP, 29) = 1;
  LPC_GPDMA->DMACConfig = 1;
}

void spi_tx_sync(int device) {
  /* select interface */
  ssp_props *ssp = &(SSP_SEL[device]);
  
  /* Wait until TX fifo is flushed */
  while (BITBAND(ssp->SSP_REGS->SR, SSP_BSY)) ;
}

void spi_tx_byte(uint8_t data, int device) {

  /* select interface */
  ssp_props *ssp = &(SSP_SEL[device]);

  /* Wait until TX fifo can accept data */
  while (!BITBAND(ssp->SSP_REGS->SR, SSP_TNF)) ;

  /* Send byte */
  ssp->SSP_REGS->DR = data;
}

uint8_t spi_txrx_byte(uint8_t data, int device) {
  /* select interface */
  ssp_props *ssp = &(SSP_SEL[device]);

  /* Wait until SSP is not busy */
  while (BITBAND(ssp->SSP_REGS->SR, SSP_BSY)) ;

  /* Clear RX fifo */
  while (BITBAND(ssp->SSP_REGS->SR, SSP_RNE))
    (void) ssp->SSP_REGS->DR;

  /* Transmit a single dummy byte */
  ssp->SSP_REGS->DR = data;

  /* Wait until answer has been received */
  while (!BITBAND(ssp->SSP_REGS->SR, SSP_RNE)) ;

  return ssp->SSP_REGS->DR;
}

uint8_t spi_rx_byte(int device) {

  /* select interface */
  ssp_props *ssp = &(SSP_SEL[device]);

  /* Wait until SSP is not busy */
  while (BITBAND(ssp->SSP_REGS->SR, SSP_BSY)) ;

  /* Clear RX fifo */
  while (BITBAND(ssp->SSP_REGS->SR, SSP_RNE))
    (void) ssp->SSP_REGS->DR;

  /* Transmit a single dummy byte */
  ssp->SSP_REGS->DR = 0xff;

  /* Wait until answer has been received */
  while (!BITBAND(ssp->SSP_REGS->SR, SSP_RNE)) ;

  return ssp->SSP_REGS->DR;
}

void spi_tx_block(const void *ptr, unsigned int length, int device) {
  const uint8_t *data = (const uint8_t *)ptr;

  /* select interface */
  ssp_props *ssp = &(SSP_SEL[device]);

  while (length--) {
  /* Wait until TX fifo can accept data */
    while (!BITBAND(ssp->SSP_REGS->SR, SSP_TNF)) ;

    ssp->SSP_REGS->DR = *data++;
  }
}

void spi_rx_block(void *ptr, unsigned int length, int device) {
  uint8_t *data = (uint8_t *)ptr;
  unsigned int txlen = length;

  /* select interface */
  ssp_props *ssp = &(SSP_SEL[device]);

  /* Wait until SSP is not busy */
  while (BITBAND(ssp->SSP_REGS->SR, SSP_BSY)) ;

  /* Clear RX fifo */
  while (BITBAND(ssp->SSP_REGS->SR, SSP_RNE))
    (void) ssp->SSP_REGS->DR;

  if ((length & 3) != 0 || ((uint32_t)ptr & 3) != 0) {
    /* Odd length or unaligned buffer */
    while (length > 0) {
      /* Wait until TX or RX FIFO are ready */
      while (txlen > 0 && !BITBAND(ssp->SSP_REGS->SR, SSP_TNF) &&
             !BITBAND(ssp->SSP_REGS->SR, SSP_RNE)) ;

      /* Try to receive data */
      while (length > 0 && BITBAND(ssp->SSP_REGS->SR, SSP_RNE)) {
        *data++ = ssp->SSP_REGS->DR;
        length--;
      }

      /* Send dummy data until TX full or RX ready */
      while (txlen > 0 && BITBAND(ssp->SSP_REGS->SR, SSP_TNF) && !BITBAND(ssp->SSP_REGS->SR, SSP_RNE)) {
        txlen--;
        ssp->SSP_REGS->DR = 0xff;
      }
    }
  } else {
    /* Clear interrupt flags of DMA channels 0 */
    LPC_GPDMA->DMACIntTCClear = BV(device);
    LPC_GPDMA->DMACIntErrClr  = BV(device);

    /* Set up RX DMA channel */
    ssp->SSP_DMACH->DMACCSrcAddr  = (uint32_t)&ssp->SSP_REGS->DR;
    ssp->SSP_DMACH->DMACCDestAddr = (uint32_t)ptr;
    ssp->SSP_DMACH->DMACCLLI      = 0; // no linked list
    ssp->SSP_DMACH->DMACCControl  = length
      | (0 << 12) // source burst size 1 (FIXME: Check if larger possible/useful)
      | (0 << 15) // destination burst size 1
      | (0 << 18) // source transfer width 1 byte
      | (2 << 21) // destination transfer width 4 bytes
      | (0 << 26) // source address not incremented
      | (1 << 27) // destination address incremented
      ;
    ssp->SSP_DMACH->DMACCConfig = 1 // enable channel
      | (ssp->SSP_DMAID_RX << 1) // data source SSP RX
      | (2 << 11) // transfer from peripheral to memory
      ;

    /* Enable RX FIFO DMA */
    ssp->SSP_REGS->DMACR = 1;

    /* Write <length> bytes into TX FIFO */
    // FIXME: Any value in doing this using DMA too?
    while (txlen > 0) {
      while (txlen > 0 && BITBAND(ssp->SSP_REGS->SR, SSP_TNF)) {
        txlen--;
        ssp->SSP_REGS->DR = 0xff;
      }
    }

    /* Wait until DMA channel disables itself */
    while (ssp->SSP_DMACH->DMACCConfig & 1) ;

    /* Disable RX FIFO DMA */
    ssp->SSP_REGS->DMACR = 0;
  }
}

void spi_set_speed(spi_speed_t speed, int device) {
  /* select interface */
  ssp_props *ssp = &(SSP_SEL[device]);

  /* Wait until TX fifo is empty */
  while (!BITBAND(ssp->SSP_REGS->SR, 0)) ;

  /* Disable SSP (FIXME: Is this required?) */
  ssp->SSP_REGS->CR1 = 0;

  /* Change clock divisor */
  if (speed == SPI_SPEED_FAST) {
    ssp->SSP_REGS->CPSR = SSP_CLK_DIVISOR_FAST;
  } else if (speed == SPI_SPEED_SLOW) {
    ssp->SSP_REGS->CPSR = SSP_CLK_DIVISOR_SLOW;
  } else if (speed == SPI_SPEED_FPGA_FAST) {
    ssp->SSP_REGS->CPSR = SSP_CLK_DIVISOR_FPGA_FAST;
  } else {
    ssp->SSP_REGS->CPSR = SSP_CLK_DIVISOR_FPGA_SLOW;
  }

  /* Enable SSP */
  ssp->SSP_REGS->CR1 = BV(1);
}

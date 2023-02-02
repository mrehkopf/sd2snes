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

#include "bits.h"
#include "config.h"
#include "spi.h"
#include "uart.h"

void spi_preinit() {

  /* Set clock prescaler to 1:1 */
  BITBAND(LPC_SC->SPI_PCLKREG, SPI_PCLKBIT) = 1;
}

void spi_init() {

  GPIO_MODE_AF(SPI_SCLKREG, SPI_SCLKBIT, 2);
  GPIO_MODE_AF(SPI_MISOREG, SPI_MISOBIT, 2);
  GPIO_MODE_AF(SPI_MOSIREG, SPI_MOSIBIT, 2);

  /* configure data format - 8 bits, SPI, CPOL=0, CPHA=0, 1 clock per bit */
  SPI_REGS->CR0 = (8-1);

  /* set clock prescaler */
  SPI_REGS->CPSR = SSP_CLK_DIVISOR;

  /* Enable SSP */
  SPI_REGS->CR1 = BV(1);

  /* Enable DMA controller, little-endian mode */
  BITBAND(LPC_SC->PCONP, 29) = 1;
  LPC_GPDMA->DMACConfig = 1;
}

void spi_tx_sync() {
  /* Wait until TX fifo is flushed */
  while (BITBAND(SPI_REGS->SR, SPI_BSY)) ;
}

void spi_tx_byte(uint8_t data) {
  /* Wait until TX fifo can accept data */
  while (!BITBAND(SPI_REGS->SR, SPI_TNF)) ;

  /* Send byte */
  SPI_REGS->DR = data;
}

uint8_t spi_txrx_byte(uint8_t data) {
  /* Wait until SSP is not busy */
  while (BITBAND(SPI_REGS->SR, SPI_BSY)) ;

  /* Clear RX fifo */
  while (BITBAND(SPI_REGS->SR, SPI_RNE))
    (void) SPI_REGS->DR;

  /* Transmit a single byte */
  SPI_REGS->DR = data;

  /* Wait until answer has been received */
  while (!BITBAND(SPI_REGS->SR, SPI_RNE)) ;

  return SPI_REGS->DR;
}

uint8_t spi_rx_byte() {
  /* Wait until SSP is not busy */
  while (BITBAND(SPI_REGS->SR, SPI_BSY)) ;

  /* Clear RX fifo */
  while (BITBAND(SPI_REGS->SR, SPI_RNE))
    (void) SPI_REGS->DR;

  /* Transmit a single dummy byte */
  SPI_REGS->DR = 0xff;

  /* Wait until answer has been received */
  while (!BITBAND(SPI_REGS->SR, SPI_RNE)) ;

  return SPI_REGS->DR;
}

void spi_tx_block(const void *ptr, unsigned int length) {
  const uint8_t *data = (const uint8_t *)ptr;

  while (length--) {
  /* Wait until TX fifo can accept data */
    while (!BITBAND(SPI_REGS->SR, SPI_TNF)) ;

    SPI_REGS->DR = *data++;
  }
}

void spi_rx_block(void *ptr, unsigned int length) {
  uint8_t *data = (uint8_t *)ptr;
  unsigned int txlen = length;

  /* Wait until SSP is not busy */
  while (BITBAND(SPI_REGS->SR, SPI_BSY)) ;

  /* Clear RX fifo */
  while (BITBAND(SPI_REGS->SR, SPI_RNE))
    (void) SPI_REGS->DR;

  if ((length & 3) != 0 || ((uint32_t)ptr & 3) != 0) {
    /* Odd length or unaligned buffer */
    while (length > 0) {
      /* Wait until TX or RX FIFO are ready */
      while (txlen > 0 && !BITBAND(SPI_REGS->SR, SPI_TNF) &&
             !BITBAND(SPI_REGS->SR, SPI_RNE)) ;

      /* Try to receive data */
      while (length > 0 && BITBAND(SPI_REGS->SR, SPI_RNE)) {
        *data++ = SPI_REGS->DR;
        length--;
      }

      /* Send dummy data until TX full or RX ready */
      while (txlen > 0 && BITBAND(SPI_REGS->SR, SPI_TNF) && !BITBAND(SPI_REGS->SR, SPI_RNE)) {
        txlen--;
        SPI_REGS->DR = 0xff;
      }
    }
  } else {
    /* Clear interrupt flags of DMA channels 0 */
    LPC_GPDMA->DMACIntTCClear = BV(0);
    LPC_GPDMA->DMACIntErrClr  = BV(0);

    /* Set up RX DMA channel */
    SPI_DMACH->DMACCSrcAddr  = (uint32_t)&SPI_REGS->DR;
    SPI_DMACH->DMACCDestAddr = (uint32_t)ptr;
    SPI_DMACH->DMACCLLI      = 0; // no linked list
    SPI_DMACH->DMACCControl  = length
      | (0 << 12) // source burst size 1 (FIXME: Check if larger possible/useful)
      | (0 << 15) // destination burst size 1
      | (0 << 18) // source transfer width 1 byte
      | (2 << 21) // destination transfer width 4 bytes
      | (0 << 26) // source address not incremented
      | (1 << 27) // destination address incremented
      ;
    SPI_DMACH->DMACCConfig = 1 // enable channel
      | (SPI_DMAID_RX << 1) // data source SSP RX
      | (2 << 11) // transfer from peripheral to memory
      ;

    /* Enable RX FIFO DMA */
    SPI_REGS->DMACR = 1;

    /* Write <length> bytes into TX FIFO */
    // FIXME: Any value in doing this using DMA too?
    while (txlen > 0) {
      while (txlen > 0 && BITBAND(SPI_REGS->SR, SPI_TNF)) {
        txlen--;
        SPI_REGS->DR = 0xff;
      }
    }

    /* Wait until DMA channel disables itself */
    while (SPI_DMACH->DMACCConfig & 1) ;

    /* Disable RX FIFO DMA */
    SPI_REGS->DMACR = 0;
  }
}

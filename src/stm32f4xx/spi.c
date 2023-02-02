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

#include "config.h"
#include "bits.h"
#include "spi.h"
#include "uart.h"

void spi_preinit() {

}

void spi_init() {

  /* configure & enable SPI1 -
     master mode
     clk = pclk/2 = 42MHz
     bits = 8
     CPHA = 0
     CPOL = 0
     SS software controlled
   */
  SPI1->CR1 = SPI_CR1_SSM | SPI_CR1_SSI | SPI_CR1_SPE | SPI_CR1_MSTR
            | (0b000 << SPI_CR1_BR_Pos);
  /* connect SPI1 (FPGA) on PB3,PB4,PB5 (SS -PA4- remains as GPIO) */
  GPIOB->AFR[0] |= (5 << GPIO_AFRL_AFSEL3_Pos) | (5 << GPIO_AFRL_AFSEL4_Pos)
                 | (5 << GPIO_AFRL_AFSEL5_Pos);
  GPIO_MODE_AF(GPIOB, 3);
  GPIO_MODE_AF(GPIOB, 4);
  GPIO_MODE_AF(GPIOB, 5);
  GPIO_SPEED(GPIOB, 3, IO_SPEED_H);
  GPIO_SPEED(GPIOB, 4, IO_SPEED_H);
  GPIO_SPEED(GPIOB, 5, IO_SPEED_H);
  GPIO_SPEED(FPGA_SSREG, FPGA_SSBIT, IO_SPEED_H);
  GPIO_PULLNONE(GPIOB, 4);
  GPIO_MODE_OUT(FPGA_SSREG, FPGA_SSBIT);
}

void spi_tx_sync() {
  /* Wait until TX fifo is flushed */
  while (BITBAND(SPI1->SR, SPI_SR_BSY_Pos));
}

void spi_tx_byte(uint8_t data) {
  /* Wait until TX fifo can accept data */
  while (!BITBAND(SPI1->SR, SPI_SR_TXE_Pos)) ;

  /* Send byte */
  SPI1->DR = data;
}

uint8_t spi_txrx_byte(uint8_t data) {
  /* Wait until SSP is not busy */
  while (BITBAND(SPI1->SR, SPI_SR_BSY_Pos)) ;

  /* Clear RX fifo */
  while (BITBAND(SPI1->SR, SPI_SR_RXNE_Pos))
    (void) SPI1->DR;

  /* Transmit a single byte */
  SPI1->DR = data;

  /* Wait until answer has been received */
  while (!BITBAND(SPI1->SR, SPI_SR_RXNE_Pos)) ;

  return SPI1->DR;
}

uint8_t spi_rx_byte() {
  /* Wait until SSP is not busy */
  while (BITBAND(SPI1->SR, SPI_SR_BSY_Pos)) ;

  /* Clear RX fifo */
  while (BITBAND(SPI1->SR, SPI_SR_RXNE_Pos))
    (void) SPI1->DR;

  /* Transmit a single dummy byte */
  SPI1->DR = 0xff;

  /* Wait until answer has been received */
  while (!BITBAND(SPI1->SR, SPI_SR_RXNE_Pos)) ;

  return SPI1->DR;
}

void spi_tx_block(const void *ptr, unsigned int length) {
  const uint8_t *data = (const uint8_t *)ptr;

  while (length--) {
  /* Wait until TX fifo can accept data */
    while (!BITBAND(SPI1->SR, SPI_SR_TXE_Pos)) ;

    SPI1->DR = *data++;
  }
}

void spi_rx_block(void *ptr, unsigned int length) {
  uint8_t *data = (uint8_t *)ptr;
  unsigned int txlen = length;

  /* Wait until SSP is not busy */
  while (BITBAND(SPI1->SR, SPI_SR_BSY_Pos)) ;

  /* Clear RX fifo */
  while (BITBAND(SPI1->SR, SPI_SR_RXNE_Pos))
    (void) SPI1->DR;

  if ((length & 3) != 0 || ((uint32_t)ptr & 3) != 0) {
    /* Odd length or unaligned buffer */
    while (length > 0) {
      /* Wait until TX or RX FIFO are ready */
      while (txlen > 0 && !BITBAND(SPI1->SR, SPI_SR_TXE_Pos) &&
             !BITBAND(SPI1->SR, SPI_SR_RXNE_Pos)) ;

      /* Try to receive data */
      while (length > 0 && BITBAND(SPI1->SR, SPI_SR_RXNE_Pos)) {
        *data++ = SPI1->DR;
        length--;
      }

      /* Send dummy data until TX full or RX ready */
      while (txlen > 0 && BITBAND(SPI1->SR, SPI_SR_TXE_Pos) && !BITBAND(SPI1->SR, SPI_SR_RXNE_Pos)) {
        txlen--;
        SPI1->DR = 0xff;
      }
    }
  } else {
    /* Clear interrupt flags of DMA2 stream 0 (SPI1_RX)  */
    DMA2->LIFCR = DMA_LIFCR_CDMEIF0
                | DMA_LIFCR_CFEIF0
                | DMA_LIFCR_CHTIF0
                | DMA_LIFCR_CTEIF0
                | DMA_LIFCR_CTCIF0;

    /* Set up RX DMA channel */
    DMA2_Stream0->NDTR = length;
    DMA2_Stream0->PAR = (uint32_t)&SPI1->DR;
    DMA2_Stream0->M0AR = (uint32_t)ptr;

    DMA2_Stream0->CR = (3 << DMA_SxCR_CHSEL_Pos)  // DMA channel 3 selects SPI1_RX request
                     | (1 << DMA_SxCR_MBURST_Pos) // 4-byte transfer (memory)
                     | (0 << DMA_SxCR_PBURST_Pos) // single transfer (peripheral)
                     | (0 << DMA_SxCR_MSIZE_Pos)  // mem data size = byte
                     | (0 << DMA_SxCR_PSIZE_Pos)  // periph data size = byte
                     | (1 << DMA_SxCR_MINC_Pos)   // increment memory address
                     | (0 << DMA_SxCR_PINC_Pos)   // do not increment peripheral address
                     | (0 << DMA_SxCR_DIR_Pos)    // direction: peripheral to memory
                     | (1 << DMA_SxCR_PFCTRL_Pos) // flow governed by peripheral
                     | (1 << DMA_SxCR_EN_Pos);    // enable stream

    /* Enable RX FIFO DMA */
    BITBAND(SPI1->CR2, SPI_CR2_RXDMAEN_Pos) = 1;

    /* Write <length> bytes into TX FIFO */
    // FIXME: Any value in doing this using DMA too?
    while (txlen > 0) {
      while (txlen > 0 && BITBAND(SPI1->SR, SPI_SR_TXE_Pos)) {
        txlen--;
        SPI1->DR = 0xff;
      }
    }

    /* Wait until DMA channel disables itself */
    while (!(DMA2->LISR & DMA_LISR_TCIF0));

    /* Disable RX FIFO DMA */
    BITBAND(SPI1->CR2, SPI_CR2_RXDMAEN_Pos) = 0;
  }
}

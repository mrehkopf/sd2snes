// insert cool lengthy disclaimer here
/*
	fpga_spi.c: SPI functions for SRAM interfacing and mapper config

	SPI commands

	cmd		param		function	
   =============================================
	00		bb[hh[ll]]	set address to 0xbbhhll
	2s		-			set SRAM size to s
	3m		-			set mapper to m
						0=HiROM, 1=LoROM
	80		-			read with increment
	81		-			read w/o increment
	90		{xx}*		write xx with increment
	91		{xx}*		write xx w/o increment
	
*/

#include <avr/pgmspace.h>
#include <util/delay.h>
#include "avrcompat.h"
#include "fpga.h"
#include "config.h"
#include "uart.h"
#include "spi.h"
#include "fpga_spi.h"

void spi_fpga(void) {
	SPI_SS_HIGH();
	FPGA_SS_LOW();
}

void spi_sd(void) {
	FPGA_SS_HIGH();
	SPI_SS_LOW();
}

void fpga_spi_init(void) {
	DDRC = _BV(PC7);
	FPGA_SS_HIGH();
}

void set_avr_addr(uint32_t address) {
	spi_fpga();
	spiTransferByte(0x00);
	spiTransferByte((address>>16)&0xff);
	spiTransferByte((address>>8)&0xff);
	spiTransferByte((address)&0xff);
	spi_sd();
}


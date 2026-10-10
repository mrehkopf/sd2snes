#include <stdio.h>
#include <string.h>
#include "config.h"
#include "crc.h"
#include "crc16.h"
#include "diskio.h"
#include "spi.h"
#include "timer.h"
#include "uart.h"
#include "led.h"
#include "sdnative.h"
#include "fileops.h"
#include "bits.h"
#include "fpga_spi.h"
#include "memory.h"
#include "snes.h"
#include "fileops.h"
#include "usbinterface.h"

#define MAX_CARDS 1

// SD/MMC commands
#define GO_IDLE_STATE           0
#define SEND_OP_COND            1
#define ALL_SEND_CID            2
#define SEND_RELATIVE_ADDR      3
#define SWITCH_FUNC             6
#define SELECT_CARD             7
#define SEND_IF_COND            8
#define SEND_CSD                9
#define SEND_CID               10
#define STOP_TRANSMISSION      12
#define SEND_STATUS            13
#define GO_INACTIVE_STATE      15
#define SET_BLOCKLEN           16
#define READ_SINGLE_BLOCK      17
#define READ_MULTIPLE_BLOCK    18
#define WRITE_BLOCK            24
#define WRITE_MULTIPLE_BLOCK   25
#define PROGRAM_CSD            27
#define SET_WRITE_PROT         28
#define CLR_WRITE_PROT         29
#define SEND_WRITE_PROT        30
#define ERASE_WR_BLK_STAR_ADDR 32
#define ERASE_WR_BLK_END_ADDR  33
#define ERASE                  38
#define LOCK_UNLOCK            42
#define APP_CMD                55
#define GEN_CMD                56
#define READ_OCR               58
#define CRC_ON_OFF             59

// SD ACMDs
#define SD_SET_BUS_WIDTH           6
#define SD_STATUS                 13
#define SD_SEND_NUM_WR_BLOCKS     22
#define SD_SET_WR_BLK_ERASE_COUNT 23
#define SD_SEND_OP_COND           41
#define SD_SET_CLR_CARD_DETECT    42
#define SD_SEND_SCR               51

// R1 status bits
#define STATUS_IN_IDLE          1
#define STATUS_ERASE_RESET      2
#define STATUS_ILLEGAL_COMMAND  4
#define STATUS_CRC_ERROR        8
#define STATUS_ERASE_SEQ_ERROR 16
#define STATUS_ADDRESS_ERROR   32
#define STATUS_PARAMETER_ERROR 64

/* Card types - cardtype == 0 is MMC */
#define CARD_SD   (1<<0)
#define CARD_SDHC (1<<1)

/*
                Rev.A    Rev.C
    1 DAT3/SS   P0.6     P2.3
    2 CMD/DI    P0.9     P0.9
    5 Clock     P0.7     P0.7
    7 DAT0/DO   P0.8     P2.0
    8 DAT1/IRQ  P1.14    P2.1
    9 DAT2/NC   P1.15    P2.2
*/

/* SD init procedure
   =================
    - initial clock frequency: ~100kHz
    - cycle the clock for at least 74 cycles (some more may be safer)
    - send CMD0
    - send CMD8 (SEND_OP_COND); if no response -> HCS=0; else HCS=1
    - send ACMD41 until OCR[31] (busy) becomes 1 (means: ready)
    - if OCR[30] (CCS) set -> SDHC; else SDSC
    - send CMD2 (read CID) (maybe log some stuff from the CID)
    - send CMD3 (read RCA), store RCA
== end of initialisation ==
    - send CMD9 (read CSD) with RCA, maybe do sth with TRAN_SPEED
    - send CMD7 with RCA, select card, put card in tran
    - maybe send CMD13 with RCA to check state (tran)
    - send ACMD51 with RCA to read SCR (maybe, to check 4bit support)
    - increase clock speed
    - send ACMD6 with RCA to set 4bit bus width
    - send transfer cmds
*/

/*
    static CMD payloads. (no CRC calc required)
    -  CMD0: 0x40 0x00 0x00 0x00 0x00 0x95
    -  CMD8: 0x48 0x00 0x00 0x01 0xaa 0x87
    -  CMD2: 0x42 0x00 0x00 0x00 0x00 0x4d
    -  CMD3: 0x43 0x00 0x00 0x00 0x00 0x21
    - CMD55: 0x77 0x00 0x00 0x00 0x00 0x65
*/

uint8_t cmd[6]={0,0,0,0,0,0};
uint8_t rsp[17];
uint8_t csd[17];
uint8_t cid[17];
diskinfo0_t di;
uint8_t ccs=0;
uint32_t rca;

enum trans_state { TRANS_NONE = 0, TRANS_READ, TRANS_WRITE, TRANS_MID };
enum cmd_state { CMD_RSP = 0, CMD_RSPDAT, CMD_DAT };

int during_blocktrans = TRANS_NONE;
uint32_t last_block = 0;
uint16_t last_offset = 0;

volatile int sd_changed;

#if defined(CONFIG_SD_HWSDIO_WRITE) && !defined(CONFIG_SD_HWSDIO)
#error "CONFIG_SD_HWSDIO_WRITE requires CONFIG_SD_HWSDIO"
#endif

#ifdef CONFIG_SD_HWSDIO
/*
   Hardware SDIO host:
   ===================
   Use dedicated SDIO controller for MCU-owned access (DMA2 stream 3 channel 4)
   Card init and FPGA-side SD DMA (via sd_offload) stay bitbanged for now
   to keep compatibility with current FPGA cores

   SD pins are switched between GPIO and AF12 (SDIO host) on demand.
   CMD18/25 may be handed over.

   Use the PWRSAV flag to make sure the SDIO-host generated SD clock is
   stopped to make hand-over to sd_offload / bitbanging possible.
*/

#define SD_HW_RETRIES       (3)
#define SD_HW_DTIMER        (12000000)    /* data timeout in SDIO_CK cycles */
#define SD_HW_LOOP_GUARD    (20000000)    /* polling loop limit */
#define SD_R1_ERRORS        (0xfdffe008)  /* error bits of the R1 card status */

#define SDIO_CMD_RESP_SHORT (SDIO_CMD_WAITRESP_0)

#define SDIO_STA_CMD_DONE   (SDIO_STA_CMDREND | SDIO_STA_CCRCFAIL | SDIO_STA_CTIMEOUT)
#define SDIO_STA_DATA_ERR   (SDIO_STA_DCRCFAIL | SDIO_STA_DTIMEOUT | SDIO_STA_RXOVERR \
                             | SDIO_STA_TXUNDERR | SDIO_STA_STBITERR)
#define SDIO_ICR_CMD_FLAGS  (SDIO_ICR_CCRCFAILC | SDIO_ICR_CTIMEOUTC | SDIO_ICR_CMDRENDC \
                             | SDIO_ICR_CMDSENTC)
#define SDIO_ICR_ALL_FLAGS  (SDIO_ICR_CMD_FLAGS | SDIO_ICR_DCRCFAILC | SDIO_ICR_DTIMEOUTC \
                             | SDIO_ICR_TXUNDERRC | SDIO_ICR_RXOVERRC | SDIO_ICR_DATAENDC \
                             | SDIO_ICR_STBITERRC | SDIO_ICR_DBCKENDC)

enum sd_bus_mode { SD_BUS_GPIO = 0, SD_BUS_HOST };
enum sd_stream_owner { SD_OWNER_BB = 0, SD_OWNER_HOST };

sd_hw_stats_t sd_hw_stats;

/* whether MCU-side (not offloaded) transfers go through the SDIO host */
static inline int sd_use_host(void) {
  return 1;
}

static uint8_t sd_bus_mode = SD_BUS_GPIO;
static uint8_t sd_stream_owner = SD_OWNER_BB;
static uint8_t sd_host_clk_idle = 0;   /* SDIO_CK level while gated */
static uint32_t sd_hw_bounce[128];     /* word aligned block buffer for DMA */

/* SDIO registers must not be written again within 3 SDIOCLK + 2 PCLK2 cycles */
static inline void sdio_reg_delay(void) {
  for(volatile int i = 0; i < 8; i++);
}

/* hand the SD pins to the bit-banging code */
static void sd_bus_gpio(void) {
  if(sd_bus_mode == SD_BUS_GPIO) return;
  /* keep SD_CLK at its current level so the switch creates no clock edge */
  OUT_BIT(SD_CLKREG, SD_CLKBIT, BITBAND(SD_CLKREG->GPIO_I, SD_CLKBIT));
  SET_BIT(SD_CMDREG, SD_CMDBIT);
  GPIO_MODE_OUT(SD_CLKREG, SD_CLKBIT);
  GPIO_MODE_OUT(SD_CMDREG, SD_CMDBIT);
  GPIO_MODE_IN(SD_DAT0REG, SD_DAT0BIT);
  GPIO_MODE_IN(SD_DAT1REG, SD_DAT1BIT);
  GPIO_MODE_IN(SD_DAT2REG, SD_DAT2BIT);
  GPIO_MODE_IN(SD_DAT3REG, SD_DAT3BIT);
  sd_bus_mode = SD_BUS_GPIO;
}

/* hand the SD pins to the SDIO host */
static void sd_bus_host(void) {
  if(sd_bus_mode == SD_BUS_HOST) return;
  /* move SD_CLK to the host's idle level first */
  OUT_BIT(SD_CLKREG, SD_CLKBIT, sd_host_clk_idle);
  GPIO_MODE_AF(SD_CLKREG, SD_CLKBIT);
  GPIO_MODE_AF(SD_CMDREG, SD_CMDBIT);
  GPIO_MODE_AF(SD_DAT0REG, SD_DAT0BIT);
  GPIO_MODE_AF(SD_DAT1REG, SD_DAT1BIT);
  GPIO_MODE_AF(SD_DAT2REG, SD_DAT2BIT);
  GPIO_MODE_AF(SD_DAT3REG, SD_DAT3BIT);
  sd_bus_mode = SD_BUS_HOST;
}

static void sdio_dma_start(const void *buf, int to_card) {
  uint32_t guard = 100000;
  DMA2_Stream3->CR = 0;
  while((DMA2_Stream3->CR & DMA_SxCR_EN) && --guard);
  DMA2->LIFCR = DMA_LIFCR_CTCIF3
              | DMA_LIFCR_CHTIF3
              | DMA_LIFCR_CTEIF3
              | DMA_LIFCR_CDMEIF3
              | DMA_LIFCR_CFEIF3;
  DMA2_Stream3->PAR  = (uint32_t)&SDIO->FIFO;
  DMA2_Stream3->M0AR = (uint32_t)buf;
  DMA2_Stream3->NDTR = 0;                               // ignored: SDIO is flow controller
  DMA2_Stream3->FCR  = DMA_SxFCR_DMDIS | DMA_SxFCR_FTH; // FIFO mode, threshold full
  DMA2_Stream3->CR   = (4 << DMA_SxCR_CHSEL_Pos)        // DMA channel 4 selects SDIO
                     | (0 << DMA_SxCR_MBURST_Pos)       // single (memory): buffers are
                                                        // only word aligned, a burst
                                                        // could cross a 1KB boundary
                     | (1 << DMA_SxCR_PBURST_Pos)       // INCR4 burst (peripheral)
                     | (2 << DMA_SxCR_MSIZE_Pos)        // mem data size = word
                     | (2 << DMA_SxCR_PSIZE_Pos)        // periph data size = word
                     | (3 << DMA_SxCR_PL_Pos)           // very high priority
                     | (1 << DMA_SxCR_MINC_Pos)         // increment memory address
                     | ((to_card ? 1 : 0) << DMA_SxCR_DIR_Pos) // 01: memory to peripheral
                     | (1 << DMA_SxCR_PFCTRL_Pos)       // flow governed by peripheral
                     | (1 << DMA_SxCR_EN_Pos);          // enable stream
}

/* stop any data transfer of the host and its DMA */
static void sdio_abort(void) {
  uint32_t guard = 100000;
  SDIO->DCTRL = 0;
  DMA2_Stream3->CR &= ~DMA_SxCR_EN;
  while((DMA2_Stream3->CR & DMA_SxCR_EN) && --guard);
  SDIO->ICR = SDIO_ICR_ALL_FLAGS;
}

/* send a command through the host; resp = 0 (none) or SDIO_CMD_RESP_SHORT */
static int sdio_cmd(uint8_t index, uint32_t arg, uint32_t resp, uint32_t *r1) {
  uint32_t sta, guard = SD_HW_LOOP_GUARD;
  uint32_t done = resp ? SDIO_STA_CMD_DONE : SDIO_STA_CMDSENT;
  SDIO->ICR = SDIO_ICR_CMD_FLAGS;
  SDIO->ARG = arg;
  SDIO->CMD = (index & SDIO_CMD_CMDINDEX) | resp | SDIO_CMD_CPSMEN;
  while(!((sta = SDIO->STA) & done) && --guard);
  SDIO->ICR = SDIO_ICR_CMD_FLAGS;
  if(!guard || (sta & SDIO_STA_CTIMEOUT)) {
    sd_hw_stats.cmd_timeout++;
    DBG_SD printf("SDIO: CMD%d timeout\n", index);
    return -1;
  }
  if(sta & SDIO_STA_CCRCFAIL) {
    sd_hw_stats.cmd_crcfail++;
    DBG_SD printf("SDIO: CMD%d response CRC error\n", index);
    return -1;
  }
  if(r1) {
    *r1 = SDIO->RESP1;
  }
  return 0;
}

/* arm the data path for len bytes in 512 byte blocks */
static void sdio_dpsm_start(uint32_t len, int to_card) {
  SDIO->DTIMER = SD_HW_DTIMER;
  SDIO->DLEN = len;
  SDIO->DCTRL = (9 << SDIO_DCTRL_DBLOCKSIZE_Pos)   // 2^9 = 512 byte blocks
              | SDIO_DCTRL_DMAEN
              | (to_card ? 0 : SDIO_DCTRL_DTDIR)
              | SDIO_DCTRL_DTEN;
}

/* wait for the end of a data transfer; returns 0 on success */
static int sdio_data_wait(int to_card) {
  uint32_t sta, guard = SD_HW_LOOP_GUARD;
  while(!((sta = SDIO->STA) & (SDIO_STA_DATAEND | SDIO_STA_DATA_ERR)) && --guard);
  if(guard && !(sta & SDIO_STA_DATA_ERR)) {
    if(to_card) {
      /* FIFO empty; release the stream if it has not stopped yet */
      DMA2_Stream3->CR &= ~DMA_SxCR_EN;
    }
    /* reads: DMA drains its FIFO and then disables the stream */
    guard = SD_HW_LOOP_GUARD;
    while((DMA2_Stream3->CR & DMA_SxCR_EN) && --guard);
    if(DMA2->LISR & (DMA_LISR_TEIF3 | DMA_LISR_DMEIF3)) {
      sd_hw_stats.dma_error++;
    } else if(guard) {
      SDIO->ICR = SDIO_ICR_ALL_FLAGS;
      return 0;
    } else {
      sd_hw_stats.dma_timeout++;
    }
  } else {
    if(!guard)                  sd_hw_stats.data_timeout++;
    if(sta & SDIO_STA_DCRCFAIL) sd_hw_stats.data_crcfail++;
    if(sta & SDIO_STA_DTIMEOUT) sd_hw_stats.data_timeout++;
    if(sta & SDIO_STA_RXOVERR)  sd_hw_stats.rx_overrun++;
    if(sta & SDIO_STA_TXUNDERR) sd_hw_stats.tx_underrun++;
    if(sta & SDIO_STA_STBITERR) sd_hw_stats.startbit_err++;
  }
  DBG_SD printf("SDIO: data error, STA=%08lx\n", sta);
  sdio_abort();
  return -1;
}

/* wait until the card releases DAT0 (busy); keep the clock running meanwhile.
   Only call this with no read stream open, or the card would stream data. */
static void sdio_wait_busy(void) {
  tick_t timeout = getticks() + MS_TO_TICKS(1000);
  SDIO->CLKCR &= ~SDIO_CLKCR_PWRSAV;
  sdio_reg_delay();
  while(!(BITBAND(SD_DAT0REG->GPIO_I, SD_DAT0BIT))) {
    if(time_after(getticks(), timeout)) {
      sd_hw_stats.busy_timeout++;
      break;
    }
  }
  SDIO->CLKCR |= SDIO_CLKCR_PWRSAV;
  sdio_reg_delay();
}

/* end any open CMD18/CMD25 stream through the host */
static void sdio_stop_transmission(void) {
  sd_bus_host();
  sdio_abort();
  /* response ignored: card might set OUT_OF_RANGE after its last block */
  sdio_cmd(STOP_TRANSMISSION, 0, SDIO_CMD_RESP_SHORT, NULL);
  sdio_wait_busy();
  sd_hw_stats.stream_stops++;
  during_blocktrans = TRANS_NONE;
}

static int sdio_read_once(uint8_t *buf, uint32_t sector, uint32_t count) {
  uint32_t r1;
  int newstream = 1;
  int aligned = !((uint32_t)buf & 3);
  sd_bus_host();
#ifdef CONFIG_SD_HWSDIO_CONTINUE
  if(during_blocktrans == TRANS_READ && last_block == sector - 1) {
    newstream = 0;
    sd_hw_stats.stream_continues++;
  }
#endif
  if(newstream && during_blocktrans) {
    sdio_stop_transmission();
  }
  for(uint32_t blk = 0; blk < count; ) {
    /* aligned buffers get all blocks in one go, others one by one */
    uint32_t n = aligned ? count : 1;
    sdio_dma_start(aligned ? (void*)buf : (void*)sd_hw_bounce, 0);
    /* arm the data path first; data may start during the response */
    sdio_dpsm_start(n * 512, 0);
    if(newstream) {
      /* from here on a stream may be open, even if the command fails */
      during_blocktrans = TRANS_READ;
      if(sdio_cmd(READ_MULTIPLE_BLOCK, ccs ? sector : sector << 9, SDIO_CMD_RESP_SHORT, &r1)) {
        sdio_abort();
        return -1;
      }
      if(r1 & SD_R1_ERRORS) {
        sd_hw_stats.r1_error++;
        DBG_SD printf("SDIO: CMD18 R1=%08lx\n", r1);
        sdio_abort();
        return -1;
      }
      newstream = 0;
    }
    if(sdio_data_wait(0)) {
      return -1;
    }
    if(!aligned) {
      memcpy(buf + blk * 512, sd_hw_bounce, 512);
      sd_hw_stats.bounce_blocks++;
    }
    blk += n;
  }
  during_blocktrans = TRANS_READ;
  sd_stream_owner = SD_OWNER_HOST;
  last_block = sector + count - 1;
  last_offset = 0;
  sd_offload_partial = 0;
#ifndef CONFIG_SD_HWSDIO_CONTINUE
  sdio_stop_transmission();
#endif
  return 0;
}

static DRESULT sdio_read(uint8_t *buf, uint32_t sector, uint32_t count) {
  sd_hw_stats.read_calls++;
  for(int attempt = 0; attempt <= SD_HW_RETRIES; attempt++) {
    if(attempt) {
      sd_hw_stats.read_retries++;
    }
    if(!sdio_read_once(buf, sector, count)) {
      return RES_OK;
    }
    sdio_stop_transmission();
  }
  sd_hw_stats.read_failures++;
  printf("SDIO: reading sector %08lx (+%lu) failed\n", sector, count);
  return RES_ERROR;
}

#ifdef CONFIG_SD_HWSDIO_WRITE
static int sdio_write_once(const uint8_t *buf, uint32_t sector, uint32_t count) {
  uint32_t r1;
  int newstream = 1;
  int aligned = !((uint32_t)buf & 3);
  sd_bus_host();
#ifdef CONFIG_SD_HWSDIO_CONTINUE
  if(during_blocktrans == TRANS_WRITE && last_block == sector - 1) {
    newstream = 0;
    sd_hw_stats.stream_continues++;
  }
#endif
  if(newstream && during_blocktrans) {
    sdio_stop_transmission();
  }
  sdio_wait_busy();
  if(newstream) {
    /* from here on a stream may be open, even if the command fails */
    during_blocktrans = TRANS_WRITE;
    if(sdio_cmd(WRITE_MULTIPLE_BLOCK, ccs ? sector : sector << 9, SDIO_CMD_RESP_SHORT, &r1)) {
      return -1;
    }
    if(r1 & SD_R1_ERRORS) {
      sd_hw_stats.r1_error++;
      DBG_SD printf("SDIO: CMD25 R1=%08lx\n", r1);
      return -1;
    }
  }
  sd_stream_owner = SD_OWNER_HOST;
  for(uint32_t blk = 0; blk < count; ) {
    /* aligned buffers go out in one go, others one by one */
    uint32_t n = aligned ? count : 1;
    if(!aligned) {
      if(blk) {
        sdio_wait_busy();
      }
      memcpy(sd_hw_bounce, buf + blk * 512, 512);
      sd_hw_stats.bounce_blocks++;
    }
    sdio_dma_start(aligned ? (const void*)buf : (const void*)sd_hw_bounce, 1);
    sdio_dpsm_start(n * 512, 1);
    if(sdio_data_wait(1)) {
      return -1;
    }
    blk += n;
  }
  last_block = sector + count - 1;
#ifndef CONFIG_SD_HWSDIO_CONTINUE
  sdio_stop_transmission();
#endif
  return 0;
}

static DRESULT sdio_write(const uint8_t *buf, uint32_t sector, uint32_t count) {
  sd_hw_stats.write_calls++;
  for(int attempt = 0; attempt <= SD_HW_RETRIES; attempt++) {
    if(attempt) {
      sd_hw_stats.write_retries++;
    }
    if(!sdio_write_once(buf, sector, count)) {
      return RES_OK;
    }
    sdio_stop_transmission();
  }
  sd_hw_stats.write_failures++;
  printf("SDIO: writing sector %08lx (+%lu) failed\n", sector, count);
  return RES_ERROR;
}
#endif

/* configure the host for the initialized card (4 bit bus, card selected) */
static void sdio_host_setup(void) {
  SDIO->CLKCR = (CONFIG_SD_HWSDIO_CLKDIV << SDIO_CLKCR_CLKDIV_Pos)
              | SDIO_CLKCR_WIDBUS_0    // 4 bit bus
              | SDIO_CLKCR_PWRSAV      // gate SDIO_CK while the host is idle
              | SDIO_CLKCR_CLKEN;
  sdio_reg_delay();
  /* measure the gated clock level so later mode switches create no clock edge */
  sd_bus_host();
  sdio_reg_delay();
  uint8_t samples = 0;
  /* sample the clock 8 times */
  for(int i = 0; i < 8; i++) {
    samples = (samples << 1) | BITBAND(SD_CLKREG->GPIO_I, SD_CLKBIT);
    sdio_reg_delay();
  }
  /* validate */
  if(samples != 0x00 && samples != 0xff) {
    printf("SDIO host: WARNING: SDIO_CK idle level unstable (samples %02x), assuming low\n", samples);
    samples = 0;
  }
  sd_host_clk_idle = samples & 1;
  sd_stream_owner = SD_OWNER_BB;
  printf("SDIO host: SDIO_CK=%dkHz, idle level %d\n",
         48000 / (CONFIG_SD_HWSDIO_CLKDIV + 2), sd_host_clk_idle);
}

void sdn_hw_printstats(void) {
  printf("SDIO host: SDIO_CK=%dkHz idle=%d bus=%s stream=%d owner=%s\n",
         48000 / (CONFIG_SD_HWSDIO_CLKDIV + 2), sd_host_clk_idle,
         sd_bus_mode == SD_BUS_HOST ? "host" : "gpio", during_blocktrans,
         sd_stream_owner == SD_OWNER_HOST ? "host" : "bb");
  printf("calls: read %lu write %lu; retries: read %lu write %lu; failed: read %lu write %lu\n",
         sd_hw_stats.read_calls, sd_hw_stats.write_calls,
         sd_hw_stats.read_retries, sd_hw_stats.write_retries,
         sd_hw_stats.read_failures, sd_hw_stats.write_failures);
  printf("streams: continued %lu, stopped %lu; bounce blocks %lu\n",
         sd_hw_stats.stream_continues, sd_hw_stats.stream_stops, sd_hw_stats.bounce_blocks);
  printf("errors: cmd timeout %lu, cmd crc %lu, r1 %lu, data crc %lu, data timeout %lu,\n"
         "        rx overrun %lu, tx underrun %lu, start bit %lu, dma %lu, busy %lu\n",
         sd_hw_stats.cmd_timeout, sd_hw_stats.cmd_crcfail, sd_hw_stats.r1_error,
         sd_hw_stats.data_crcfail, sd_hw_stats.data_timeout, sd_hw_stats.rx_overrun,
         sd_hw_stats.tx_underrun, sd_hw_stats.startbit_err, sd_hw_stats.dma_timeout,
         sd_hw_stats.busy_timeout);
  printf("        dma error %lu\n", sd_hw_stats.dma_error);
}

#define SD_BB_ENTRY() sd_bus_gpio()
#else
#define SD_BB_ENTRY() do {} while(0)
#endif

/**
 * getbits - read value from bit buffer
 * @buffer: pointer to the data buffer
 * @start : index of the first bit in the value
 * @bits  : number of bits in the value
 *
 * This function returns a value from the memory region passed as
 * buffer, starting with bit "start" and "bits" bit long. The buffer
 * is assumed to be MSB first, passing 0 for start will read starting
 * from the highest-value bit of the first byte of the buffer.
 */
static uint32_t getbits(void *buffer, uint16_t start, int8_t bits) {
  uint8_t *buf = buffer;
  uint32_t result = 0;

  if ((start % 8) != 0) {
    /* Unaligned start */
    result += buf[start / 8] & (0xff >> (start % 8));
    bits  -= 8 - (start % 8);
    start += 8 - (start % 8);
  }
  while (bits >= 8) {
    result = (result << 8) + buf[start / 8];
    start += 8;
    bits -= 8;
  }
  if (bits > 0) {
    result = result << bits;
    result = result + (buf[start / 8] >> (8-bits));
  } else if (bits < 0) {
    /* Fraction of a single byte */
    result = result >> -bits;
  }
  return result;
}

void sdn_checkinit(BYTE drv) {
  if(disk_state == DISK_CHANGED) {
    disk_initialize(drv);
  }
}

uint8_t* sdn_getcid() {
  sdn_checkinit(0);
  return cid;
}

static inline void wiggle_slow_pos(uint16_t times) {
  while(times--) {
    delay_us(2);
    SET_BIT(SD_CLKREG, SD_CLKBIT);
    delay_us(2);
    CLEAR_BIT(SD_CLKREG, SD_CLKBIT);
  }
}

static inline void wiggle_slow_neg(uint16_t times) {
  while(times--) {
    delay_us(2);
    CLEAR_BIT(SD_CLKREG, SD_CLKBIT);
    delay_us(2);
    SET_BIT(SD_CLKREG, SD_CLKBIT);
  }
}

static inline void wiggle_fast_pos(uint16_t times) {
  while(times--) {
    SET_BIT(SD_CLKREG, SD_CLKBIT);
    __DSB();
    __NOP();
    CLEAR_BIT(SD_CLKREG, SD_CLKBIT);
    __DSB();
    __NOP();
  }
}

static inline void wiggle_fast_neg(uint16_t times) {
  while(times--) {
    CLEAR_BIT(SD_CLKREG, SD_CLKBIT);
    __DSB();
    __NOP();
    SET_BIT(SD_CLKREG, SD_CLKBIT);
    __DSB();
    __NOP();
  }
}

static inline void wiggle_fast_neg1(void) {
    CLEAR_BIT(SD_CLKREG, SD_CLKBIT);
    __DSB();
    __NOP();
    SET_BIT(SD_CLKREG, SD_CLKBIT);
    __DSB();
    __NOP();
}

static inline void wiggle_fast_pos1(void) {
    SET_BIT(SD_CLKREG, SD_CLKBIT);
    __DSB();
    __NOP();
    CLEAR_BIT(SD_CLKREG, SD_CLKBIT);
    __DSB();
    __NOP();
}

int get_and_check_datacrc(uint8_t *buf) {
  uint16_t crc0=0, crc1=0, crc2=0, crc3=0;
  uint16_t sdcrc0=0, sdcrc1=0, sdcrc2=0, sdcrc3=0;
  uint8_t d0=0, d1=0, d2=0, d3=0;
  uint8_t datdata;
  uint16_t datcnt;
  /* get crcs from card */
  for (datcnt=0; datcnt < 16; datcnt++) {
    datdata = SD_DAT_IN;
    wiggle_fast_neg1();
    sdcrc0 = ((sdcrc0 << 1) & 0xfffe) | ((datdata >> 3) & 0x0001);
    sdcrc1 = ((sdcrc1 << 1) & 0xfffe) | ((datdata >> 2) & 0x0001);
    sdcrc2 = ((sdcrc2 << 1) & 0xfffe) | ((datdata >> 1) & 0x0001);
    sdcrc3 = ((sdcrc3 << 1) & 0xfffe) | ((datdata >> 0) & 0x0001);
  }
  wiggle_fast_neg1();
  /* calc crcs from data */
  for (datcnt=0; datcnt < 512; datcnt++) {
    d0 = ((d0 << 2) & 0xfc) | ((buf[datcnt] >> 6) & 0x02) | ((buf[datcnt] >> 3) & 0x01) ;
    d1 = ((d1 << 2) & 0xfc) | ((buf[datcnt] >> 5) & 0x02) | ((buf[datcnt] >> 2) & 0x01) ;
    d2 = ((d2 << 2) & 0xfc) | ((buf[datcnt] >> 4) & 0x02) | ((buf[datcnt] >> 1) & 0x01) ;
    d3 = ((d3 << 2) & 0xfc) | ((buf[datcnt] >> 3) & 0x02) | ((buf[datcnt] >> 0) & 0x01) ;
    if((datcnt % 4) == 3) {
      crc0 = crc_xmodem_update(crc0, d0);
      crc1 = crc_xmodem_update(crc1, d1);
      crc2 = crc_xmodem_update(crc2, d2);
      crc3 = crc_xmodem_update(crc3, d3);
    }
  }
  if((crc0 != sdcrc0) || (crc1 != sdcrc1) || (crc2 != sdcrc2) || (crc3 != sdcrc3)) {
    printf("CRC mismatch\nSDCRC   CRC\n %04x    %04x\n %04x    %04x\n %04x    %04x\n %04x    %04x\n", sdcrc0, crc0, sdcrc1, crc1, sdcrc2, crc2, sdcrc3, crc3);
    return 1;
  }
  return 0;
}

static inline void wait_busy(void) {
  SD_BB_ENTRY();
  while(!(BITBAND(SD_DAT0REG->GPIO_I, SD_DAT0BIT))) {
    wiggle_fast_neg1();
  }
  wiggle_fast_neg(4);
}

/*
   send_command_slow
   send SD command and put response in rsp.
   returns length of response or 0 if there was no response
*/
int send_command_slow(uint8_t* cmd, uint8_t* rsp){
  SD_BB_ENTRY();
  uint8_t shift, i=6;
  int rsplen;
  uint8_t cmdno = *cmd & 0x3f;
  wiggle_slow_pos(5);
  switch(*cmd & 0x3f) {
    case 0:
      rsplen = 0;
      break;
    case 2:
    case 9:
    case 10:
      rsplen = 17;
      break;
    default:
      rsplen = 6;
  }
  /* send command */
  GPIO_MODE_OUT(SD_CMDREG, SD_CMDBIT);

  while(i--) {
    shift = 8;
    do {
      shift--;
      uint8_t data = *cmd;
      *cmd<<=1;
      if(data&0x80) {
        SET_BIT(SD_CMDREG, SD_CMDBIT);
      } else {
        CLEAR_BIT(SD_CMDREG, SD_CMDBIT);
      }
      wiggle_slow_pos(1);
    } while (shift);
    cmd++;
  }

  wiggle_slow_pos(1);
  GPIO_MODE_IN(SD_CMDREG, SD_CMDBIT);

  if(rsplen) {
    uint16_t timeout=1000;
    while((BITBAND(SD_CMDREG->GPIO_I, SD_CMDBIT)) && --timeout) {
      wiggle_slow_neg(1);
    }
    if(!timeout) {
      printf("CMD%d timed out\n", cmdno);
      return 0; /* no response within timeout */
    }

    i=rsplen;
    while(i--) {
      shift = 8;
      uint8_t data=0;
      do {
        shift--;
        data |= (BITBAND(SD_CMDREG->GPIO_I, SD_CMDBIT)) << shift;
        wiggle_slow_neg(1);
      } while (shift);
      *rsp=data;
      rsp++;
    }
  }
  return rsplen;
}

/*
   send_command_fast
   send SD command and put response in rsp.
   returns length of response or 0 if there was no response
*/
int send_command_fast(uint8_t* cmd, uint8_t* rsp, uint8_t* buf){
  SD_BB_ENTRY();
  uint8_t datshift=8, cmdshift, i=6;
  uint8_t cmdno = *cmd & 0x3f;
  int rsplen, dat=0, waitbusy=0, datcnt=512, j=0;
  static int state=CMD_RSP;
  wiggle_fast_pos(9); /* give the card >=8 cycles after last command */
  DBG_SD printf("send_command_fast: sending CMD%d; payload=%02x%02x%02x%02x%02x%02x...\n", cmdno, cmd[0], cmd[1], cmd[2], cmd[3], cmd[4], cmd[5]);
  switch(*cmd & 0x3f) {
    case 0:
      rsplen = 0;
      break;
    case 2:
    case 9:
    case 10:
      rsplen = 17;
      break;
    case 12:
      rsplen = 6;
      waitbusy = 1;
      break;
    case 13:
    case 17:
    case 18:
      dat = 1;
    default:
      rsplen = 6;
  }
  if(dat && (buf==NULL) && !sd_offload) {
    printf("send_command_fast error: buf is null but data transfer expected.\n");
    return 0;
  }
  /* send command */
  GPIO_MODE_OUT(SD_CMDREG, SD_CMDBIT);

  while(i--) {
    uint8_t data = *cmd;
    cmdshift = 8;
    do {
      cmdshift--;
      if(data&0x80) {
        SET_BIT(SD_CMDREG, SD_CMDBIT);
      } else {
        CLEAR_BIT(SD_CMDREG, SD_CMDBIT);
      }
      data<<=1;
      wiggle_fast_pos1();
    } while (cmdshift);
    cmd++;
  }

  wiggle_fast_pos1();
  GPIO_MODE_IN(SD_CMDREG, SD_CMDBIT);

  if(rsplen) {
    uint32_t timeout=200000;
    /* wait for response */
    while((BITBAND(SD_CMDREG->GPIO_I, SD_CMDBIT)) && --timeout) {
      wiggle_fast_neg1();
    }
    if(!timeout) {
      printf("CMD%d timed out\n", cmdno);
      return 0; /* no response within timeout */
    }
    i=rsplen;
    uint8_t cmddata=0, datdata=0;
    while(i--) { /* process response */
      cmdshift = 8;
      do {
        if(dat) {
          if(!(BITBAND(SD_DAT0REG->GPIO_I, SD_DAT0BIT))) {
            printf("data start during response\n");
            j=datcnt;
            state=CMD_RSPDAT;
            break;
          }
        }
        cmdshift--;
        cmddata |= (BITBAND(SD_CMDREG->GPIO_I, SD_CMDBIT)) << cmdshift;
        wiggle_fast_neg1();
      } while (cmdshift);
      if(state==CMD_RSPDAT)break;
      *rsp=cmddata;
      cmddata=0;
      rsp++;
    }

    if(state==CMD_RSPDAT) { /* process response+data */
      int startbit=1;
      DBG_SD printf("processing rsp+data cmdshift=%d i=%d j=%d\n", cmdshift, i, j);
      datshift=8;
      while(1) {
        cmdshift--;
        cmddata |= (BITBAND(SD_CMDREG->GPIO_I, SD_CMDBIT)) << cmdshift;
        if(!cmdshift) {
          cmdshift=8;
          *rsp=cmddata;
          cmddata=0;
          rsp++;
          i--;
          if(!i) {
            DBG_SD printf("response end\n");
            if(j) state=CMD_DAT; /* response over, remaining data */
            break;
          }
        }
        if(!startbit) {
          datshift-=4;
          datdata |= SD_DAT_IN << datshift;
          if(!datshift) {
            datshift=8;
            *buf=datdata;
            datdata=0;
            buf++;
            j--;
            if(!j) break;
          }
        }
        startbit=0;
        wiggle_fast_neg1();
      }
    }

    if(dat && state != CMD_DAT) { /* response ended before data */
      GPIO_MODE_OUT(SD_CMDREG, SD_CMDBIT);
      state=CMD_DAT;
      j=datcnt;
      datshift=8;
      timeout=2000000;
      DBG_SD printf("response over, waiting for data...\n");
      /* wait for data start bit on DAT0 */
      while((BITBAND(SD_DAT0REG->GPIO_I, SD_DAT0BIT)) && --timeout) {
        wiggle_fast_neg1();
      }
// printf("%ld\n", timeout);
      if(!timeout) printf("timed out!\n");
      wiggle_fast_neg1(); /* eat the start bit */
      if(sd_offload) {
        if(sd_offload_partial) {
          if(sd_offload_partial_start != 0) {
            if(during_blocktrans == TRANS_MID) sd_offload_partial_start |= 0x8000;
          }
          if(sd_offload_partial_end != 512) {
            sd_offload_partial_end |= 0x8000;
            during_blocktrans = TRANS_MID;
          }
          DBG_SD_OFFLOAD printf("new partial %d - %d\n", sd_offload_partial_start, sd_offload_partial_end);
          fpga_set_sddma_range(sd_offload_partial_start, sd_offload_partial_end);
          fpga_sddma(sd_offload_tgt, 1);
//          sd_offload_partial=0;
          last_offset = sd_offload_partial_end & 0x1ff;
        } else {
          fpga_sddma(sd_offload_tgt, 0);
          last_offset = 0;
        }
        state=CMD_RSP;
        return rsplen;
      }
    }

    if(state==CMD_DAT) { /* transfer rest of data */
      DBG_SD printf("remaining data: %d\n", j);
      if(datshift==8) {
        while(1) {
          datdata |= SD_DAT_IN << 4;
          wiggle_fast_neg1();

          datdata |= SD_DAT_IN;
          wiggle_fast_neg1();

          *buf=datdata;
          datdata=0;
          buf++;
          j--;
          if(!j) break;
        }
      } else {

        while(1) {
          datshift-=4;
          datdata |= SD_DAT_IN << datshift;
          if(!datshift) {
            datshift=8;
            *buf=datdata;
            datdata=0;
            buf++;
            j--;
            if(!j) break;
          }
          wiggle_fast_neg1();
        }
      }
    }
    if(dat) {
#ifdef CONFIG_SD_DATACRC
      if(get_and_check_datacrc(buf-512)) {
        return CRC_ERROR;
      }
#else
      /* eat the crcs */
      wiggle_fast_neg(17);
#endif
    }

    if(waitbusy) {
      DBG_SD printf("waitbusy after send_cmd\n");
      wait_busy();
    }
    state=CMD_RSP;
  }
  rsp-=rsplen;
  DBG_SD printf("send_command_fast: CMD%d response: %02x%02x%02x%02x%02x%02x\n", cmdno, rsp[0], rsp[1], rsp[2], rsp[3], rsp[4], rsp[5]);
  GPIO_MODE_OUT(SD_CMDREG, SD_CMDBIT);
  return rsplen;
}

static inline void make_crc7(uint8_t* cmd) {
  cmd[5]=crc7update(0, cmd[0]);
  cmd[5]=crc7update(cmd[5], cmd[1]);
  cmd[5]=crc7update(cmd[5], cmd[2]);
  cmd[5]=crc7update(cmd[5], cmd[3]);
  cmd[5]=crc7update(cmd[5], cmd[4]);
  cmd[5]=(cmd[5] << 1) | 1;
}

int cmd_slow(uint8_t cmd, uint32_t param, uint8_t crc, uint8_t* dat, uint8_t* rsp) {
  uint8_t cmdbuf[6];
  cmdbuf[0] = 0x40 | cmd;
  cmdbuf[1] = param >> 24;
  cmdbuf[2] = param >> 16;
  cmdbuf[3] = param >> 8;
  cmdbuf[4] = param;
  if(!crc) {
    make_crc7(cmdbuf);
  } else {
    cmdbuf[5] = crc;
  }
  return send_command_slow(cmdbuf, rsp);
}

int acmd_slow(uint8_t cmd, uint32_t param, uint8_t crc, uint8_t* dat, uint8_t* rsp) {
  if(!(cmd_slow(APP_CMD, rca, 0, NULL, rsp))) {
    return 0;
  }
  return cmd_slow(cmd, param, crc, dat, rsp);
}

int cmd_fast(uint8_t cmd, uint32_t param, uint8_t crc, uint8_t* dat, uint8_t* rsp) {
  uint8_t cmdbuf[6];
  cmdbuf[0] = 0x40 | cmd;
  cmdbuf[1] = param >> 24;
  cmdbuf[2] = param >> 16;
  cmdbuf[3] = param >> 8;
  cmdbuf[4] = param;
  if(!crc) {
    make_crc7(cmdbuf);
  } else {
    cmdbuf[5] = crc;
  }
  return send_command_fast(cmdbuf, rsp, dat);
}

int acmd_fast(uint8_t cmd, uint32_t param, uint8_t crc, uint8_t* dat, uint8_t* rsp) {
  if(!(cmd_fast(APP_CMD, rca, 0, NULL, rsp))) {
    return 0;
  }
  return cmd_fast(cmd, param, crc, dat, rsp);
}

int stream_datablock(uint8_t *buf) {
  SD_BB_ENTRY();
//  uint8_t datshift=8;
  int j=512;
  uint8_t datdata=0;
  uint32_t timeout=1000000;

  DBG_SD printf("stream_datablock: wait for ready...\n");
  if(during_blocktrans != TRANS_MID) {
    while((BITBAND(SD_DAT0REG->GPIO_I, SD_DAT0BIT)) && --timeout) {
      wiggle_fast_neg1();
    }
    DBG_SD if(!timeout) printf("timeout!\n");
    wiggle_fast_neg1(); /* eat the start bit */
  }
  if(sd_offload) {
    if(sd_offload_partial) {
      if(sd_offload_partial_start != 0) {
        if(during_blocktrans == TRANS_MID) sd_offload_partial_start |= 0x8000;
      }
      if(sd_offload_partial_end != 512) {
        sd_offload_partial_end |= 0x8000;
      }
      DBG_SD_OFFLOAD printf("str partial %d - %d\n", sd_offload_partial_start, sd_offload_partial_end);
      fpga_set_sddma_range(sd_offload_partial_start, sd_offload_partial_end);
      fpga_sddma(sd_offload_tgt, 1);
    } else {
      fpga_sddma(sd_offload_tgt, 0);
    }
  } else {
    while(1) {
      datdata = SD_DAT_IN << 4;
      wiggle_fast_neg1();

      datdata |= SD_DAT_IN;
      wiggle_fast_neg1();

      *buf=datdata;
      buf++;
      j--;
      if(!j) break;
    }
#ifdef CONFIG_SD_DATACRC
    return get_and_check_datacrc(buf-512);
#else
    /* eat the crcs */
    wiggle_fast_neg(17);
#endif
  }
  return 0;
}

void send_datablock(uint8_t *buf) {
  SD_BB_ENTRY();
  uint16_t crc0=0, crc1=0, crc2=0, crc3=0, cnt=512;
  uint8_t dat0=0, dat1=0, dat2=0, dat3=0, crcshift, datshift;

  wiggle_fast_pos1();
  GPIO_MODE_OUT(SD_DAT0REG, SD_DAT0BIT);
  GPIO_MODE_OUT(SD_DAT1REG, SD_DAT1BIT);
  GPIO_MODE_OUT(SD_DAT2REG, SD_DAT2BIT);
  GPIO_MODE_OUT(SD_DAT3REG, SD_DAT3BIT);

  SD_DAT_OUT(0);

  wiggle_fast_pos1(); /* send start bit to card */
  crcshift=8;
  while(cnt--) {
    datshift=8;
    do {
      datshift-=4;
      SD_DAT_OUT(((*buf)>>datshift) & 0xf);
      wiggle_fast_pos1();
    } while (datshift);

    crcshift-=2;
    dat0 |= (((*buf)&0x01) | (((*buf)&0x10) >> 3)) << crcshift;
    dat1 |= ((((*buf)&0x02) >> 1) | (((*buf)&0x20) >> 4)) << crcshift;
    dat2 |= ((((*buf)&0x04) >> 2) | (((*buf)&0x40) >> 5)) << crcshift;
    dat3 |= ((((*buf)&0x08) >> 3) | (((*buf)&0x80) >> 6)) << crcshift;
    if(!crcshift) {
      crc0 = crc_xmodem_update(crc0, dat0);
      crc1 = crc_xmodem_update(crc1, dat1);
      crc2 = crc_xmodem_update(crc2, dat2);
      crc3 = crc_xmodem_update(crc3, dat3);
      crcshift=8;
      dat0=0;
      dat1=0;
      dat2=0;
      dat3=0;
    }
    buf++;
  }
//  printf("crc0=%04x crc1=%04x crc2=%04x crc3=%04x ", crc0, crc1, crc2, crc3);
  /* send crcs */
  datshift=16;
  do {
    datshift--;
    OUT_BIT(SD_DAT0REG, SD_DAT0BIT, (crc0 >> datshift) & 1);
    OUT_BIT(SD_DAT1REG, SD_DAT1BIT, (crc1 >> datshift) & 1);
    OUT_BIT(SD_DAT2REG, SD_DAT2BIT, (crc2 >> datshift) & 1);
    OUT_BIT(SD_DAT3REG, SD_DAT3BIT, (crc3 >> datshift) & 1);
    wiggle_fast_pos1();
  } while(datshift);
  /* send end bit */
  SD_DAT_OUT(0xf);

  wiggle_fast_pos1();

  GPIO_MODE_IN(SD_DAT0REG, SD_DAT0BIT);
  GPIO_MODE_IN(SD_DAT1REG, SD_DAT1BIT);
  GPIO_MODE_IN(SD_DAT2REG, SD_DAT2BIT);
  GPIO_MODE_IN(SD_DAT3REG, SD_DAT3BIT);

  wiggle_fast_neg(3);
  dat0=0;

  datshift=4;
  do {
    datshift--;
    dat0 |= ((BITBAND(SD_DAT0REG->GPIO_I, SD_DAT0BIT)) << datshift);
    wiggle_fast_neg1();
  } while (datshift);
  DBG_SD printf("crc %02x\n", dat0);
  if((dat0 & 7) != 2) {
    printf("crc error! %02x\n", dat0);
    while(1);
  }
  if(dat0 & 8) {
    printf("missing start bit in CRC status response...\n");
  }
  wiggle_fast_neg(2);
  wait_busy();
}

void read_block(uint32_t address, uint8_t *buf) {
#ifdef CONFIG_SD_HWSDIO
  /* never continue a read stream the host has opened (see above) */
  if(during_blocktrans == TRANS_READ && sd_stream_owner == SD_OWNER_HOST) {
    sdio_stop_transmission();
  }
  sd_bus_gpio();
  sd_stream_owner = SD_OWNER_BB;
#endif
  DBG_SD_OFFLOAD printf("read_block trans=%d addr=%08lx last_addr=%08lx  offld=%d/%d offst=%04x offed=%04x last_off=%04x\n", during_blocktrans, address, last_block, sd_offload, sd_offload_partial, sd_offload_partial_start, sd_offload_partial_end, last_offset);
  if(during_blocktrans == TRANS_READ && (last_block == address-1)) {
//uart_putc('r');
#ifdef CONFIG_SD_DATACRC
    int cmd_res;
    if((cmd_res = stream_datablock(buf)) == CRC_ERROR) {
      while(cmd_res == CRC_ERROR) {
        cmd_fast(STOP_TRANSMISSION, 0, 0x61, NULL, rsp);
        cmd_res = cmd_fast(READ_MULTIPLE_BLOCK, address, 0, buf, rsp);
      }
    }
#else
    stream_datablock(buf);
#endif
    last_block = address;
    last_offset = sd_offload_partial_end & 0x1ff;
    if(sd_offload_partial && sd_offload_partial_end != 512) {
      during_blocktrans = TRANS_MID;
    }
    sd_offload_partial = 0;
  } else if (during_blocktrans == TRANS_MID
             && last_block == address
             && last_offset == sd_offload_partial_start
             && sd_offload_partial) {
    sd_offload_partial_start |= 0x8000;
    stream_datablock(buf);
    during_blocktrans = TRANS_READ;
    last_offset = sd_offload_partial_end & 0x1ff;
    sd_offload_partial = 0;
  } else {
    if(during_blocktrans) {
//      uart_putc('_');
      DBG_SD_OFFLOAD printf("nonseq read (%lx -> %lx), restarting transmission\n", last_block, address);
      /* send STOP_TRANSMISSION to end an open READ/WRITE_MULTIPLE_BLOCK */
      cmd_fast(STOP_TRANSMISSION, 0, 0x61, NULL, rsp);
    }
    during_blocktrans = TRANS_READ;
    last_block = address;
    if(!ccs) {
      address <<= 9;
    }
#ifdef CONFIG_SD_DATACRC
    while(1) {
      if(cmd_fast(READ_MULTIPLE_BLOCK, address, 0, buf, rsp) != CRC_ERROR) break;
      cmd_fast(STOP_TRANSMISSION, 0, 0x61, NULL, rsp);
    };
#else
    cmd_fast(READ_MULTIPLE_BLOCK, address, 0, buf, rsp);
#endif
    sd_offload_partial = 0;
  }
//  printf("trans state = %d\n", during_blocktrans);
}

void write_block(uint32_t address, uint8_t* buf) {
#ifdef CONFIG_SD_HWSDIO
  sd_bus_gpio();
  sd_stream_owner = SD_OWNER_BB;
#endif
  if(during_blocktrans == TRANS_WRITE && (last_block == address-1)) {
    wait_busy();
    send_datablock(buf);
    last_block=address;
  } else {
    if(during_blocktrans) {
      /* send STOP_TRANSMISSION to end an open READ/WRITE_MULTIPLE_BLOCK */
      cmd_fast(STOP_TRANSMISSION, 0, 0x61, NULL, rsp);
    }
    wait_busy();
    last_block=address;
    if(!ccs) {
      address <<= 9;
    }
    /* only send cmd & get response */
    cmd_fast(WRITE_MULTIPLE_BLOCK, address, 0, NULL, rsp);
    DBG_SD printf("write_block: CMD25 response = %02x%02x%02x%02x%02x%02x\n", rsp[0], rsp[1], rsp[2], rsp[3], rsp[4], rsp[5]);
    wiggle_fast_pos(8);
    send_datablock(buf);
    during_blocktrans = TRANS_WRITE;
  }
}

/* send STOP_TRANSMISSION after multiple block write
 * and reset during_blocktrans status */

void flush_write(void) {
#ifdef CONFIG_SD_HWSDIO
  /* the card does not care which side ends the stream */
  if(during_blocktrans) {
    sdio_stop_transmission();
  }
  during_blocktrans = TRANS_NONE;
#else
  cmd_fast(STOP_TRANSMISSION, 0, 0x61, NULL, rsp);
  wait_busy();
  during_blocktrans = TRANS_NONE;
#endif
}

//
// Public functions
//

DRESULT sdn_ioctl(BYTE drv, BYTE cmd, void *buffer) {
  DRESULT res;
  if(drv >= MAX_CARDS) {
    res = STA_NOINIT|STA_NODISK;
  } else {
    switch(cmd) {
      case CTRL_SYNC:
        flush_write();
        res = RES_OK;
        break;

      default:
        res = RES_PARERR;
    }
  }
  return res;
}
DRESULT disk_ioctl(BYTE drv, BYTE cmd, void *buffer) __attribute__ ((weak, alias("sdn_ioctl")));

DRESULT sdn_read(BYTE drv, BYTE *buffer, DWORD sector, UINT count) {
  uint8_t sec;
  if(drv >= MAX_CARDS) {
    return RES_PARERR;
  }
#ifdef CONFIG_SD_HWSDIO
  if(!sd_offload && sd_use_host()) {
    DRESULT res;
    readled(1);
    res = sdio_read(buffer, sector, count);
    readled(0);
    return res;
  }
#endif
  readled(1);
  for(sec=0; sec<count; sec++) {
    read_block(sector+sec, buffer);
    buffer+=512;
  }
  readled(0);
  return RES_OK;
}
DRESULT disk_read(BYTE drv, BYTE *buffer, DWORD sector, UINT count) __attribute__ ((weak, alias("sdn_read")));

DSTATUS sdn_initialize(BYTE drv) {

  uint8_t rsp[17]; /* space for response */
  int rsplen;
  uint8_t hcs=0;
  rca = 0;
  if(drv>=MAX_CARDS) {
    return STA_NOINIT|STA_NODISK;
  }

  if(sdn_status(drv) & STA_NODISK) {
    return STA_NOINIT|STA_NODISK;
  }
#ifdef CONFIG_SD_HWSDIO
  /* card init stays bit-banged */
  sdio_abort();
  sd_bus_gpio();
  sd_stream_owner = SD_OWNER_BB;
#endif
  /* if the card is sending data from before a reset we try to deselect it
     prior to initialization
     In all likelihood this is always the case if the card was present on
     power-up because it has already been initialized by the bootloader as well
  */
  for(rsplen=0; rsplen<2042; rsplen++) {
    if(!(BITBAND(SD_DAT3REG->GPIO_I, SD_DAT3BIT))) {
      printf("card seems to be sending data, attempting deselect\n");
      cmd_slow(SELECT_CARD, 0, 0, NULL, rsp);
    }
    wiggle_slow_neg(1);
  }
  printf("sd_init start\n");
  GPIO_MODE_OUT(SD_DAT3REG, SD_DAT3BIT);
  SET_BIT(SD_DAT3REG, SD_DAT3BIT);
  cmd_slow(GO_IDLE_STATE, 0, 0x95, NULL, rsp);

  if((rsplen=cmd_slow(SEND_IF_COND, 0x000001aa, 0x87, NULL, rsp))) {
    DBG_SD printf("CMD8 response:\n");
    DBG_SD uart_trace(rsp, 0, rsplen);
    hcs=1;
  }
  while(1) {
    if(!(acmd_slow(SD_SEND_OP_COND, (hcs << 30) | 0xfc0000, 0, NULL, rsp))) {
      printf("ACMD41 no response!\n");
    }
    if(rsp[1]&0x80) break;
  }
  GPIO_MODE_IN(SD_DAT3REG, SD_DAT3BIT);
  CLEAR_BIT(SD_DAT3REG, SD_DAT3BIT);

  ccs = (rsp[1]>>6) & 1; /* SDHC/XC */

  cmd_slow(ALL_SEND_CID, 0, 0x4d, NULL, rsp);
  if(cmd_slow(SEND_RELATIVE_ADDR, 0, 0x21, NULL, rsp)) {
    rca=(rsp[1]<<24) | (rsp[2]<<16);
    printf("RCA: %04lx\n", rca>>16);
  } else {
    printf("CMD3 no response!\n");
    rca=0;
  }

  /* record CSD for getinfo */
  cmd_slow(SEND_CSD, rca, 0, NULL, csd);
  sdn_getinfo(drv, 0, &di);

  /* record CID */
  cmd_slow(SEND_CID, rca, 0, NULL, cid);

  /* select the card */
  if(cmd_slow(SELECT_CARD, rca, 0, NULL, rsp)) {
    printf("card selected!\n");
  } else {
    printf("CMD7 no response!\n");
  }

  /* get card status */
  cmd_slow(SEND_STATUS, rca, 0, NULL, rsp);

  /* set bus width */
  acmd_slow(SD_SET_BUS_WIDTH, 0x2, 0, NULL, rsp);

  /* set block length */
  cmd_slow(SET_BLOCKLEN, 0x200, 0, NULL, rsp);

#ifdef CONFIG_SD_HWSDIO
  sdio_host_setup();
#endif
  printf("SD init complete. SDHC/XC=%d\n", ccs);
  disk_state = DISK_OK;
  during_blocktrans = TRANS_NONE;
  return sdn_status(drv);
}

DSTATUS disk_initialize(BYTE drv) __attribute__ ((weak, alias("sdn_initialize")));

void sdn_init(void) {
  /* enable GPIO interrupt on SD detect pin, both edges */
/*  NVIC_EnableIRQ(EINT3_IRQn);
  SD_DT_INT_SETUP(); */
  /* prepare GPIOs */
  GPIO_SPEED(SD_DAT3REG, SD_DAT3BIT, IO_SPEED_VH);
  GPIO_SPEED(SD_DAT2REG, SD_DAT2BIT, IO_SPEED_VH);
  GPIO_SPEED(SD_DAT1REG, SD_DAT1BIT, IO_SPEED_VH);
  GPIO_SPEED(SD_DAT0REG, SD_DAT0BIT, IO_SPEED_VH);
  GPIO_SPEED(SD_CLKREG, SD_CLKBIT, IO_SPEED_VH);
  GPIO_SPEED(SD_CMDREG, SD_CMDBIT, IO_SPEED_VH);
  GPIO_MODE_IN(SD_DAT3REG, SD_DAT3BIT);
  GPIO_MODE_IN(SD_DAT2REG, SD_DAT2BIT);
  GPIO_MODE_IN(SD_DAT1REG, SD_DAT1BIT);
  GPIO_MODE_IN(SD_DAT0REG, SD_DAT0BIT);
  GPIO_MODE_OUT(SD_CLKREG, SD_CLKBIT);
  GPIO_MODE_OUT(SD_CMDREG, SD_CMDBIT);
  SET_BIT(SD_CMDREG, SD_CMDBIT);
  GPIO_PULLUP(SD_CLKREG, SD_CLKBIT);
  GPIO_PULLUP(SD_CMDREG, SD_CMDBIT);
  GPIO_PULLUP(SD_DAT0REG, SD_DAT0BIT);
  GPIO_PULLUP(SD_DAT1REG, SD_DAT1BIT);
  GPIO_PULLUP(SD_DAT2REG, SD_DAT2BIT);
  GPIO_PULLUP(SD_DAT3REG, SD_DAT3BIT);
  SD_DAT_OUT(0);
  SD_DAT_MASK();
#ifdef CONFIG_SD_HWSDIO
  /* SDIO host: AF12 on the SD pins (selected only when the host owns the bus) */
  RCC->APB2ENR |= RCC_APB2ENR_SDIOEN;
  GPIO_SEL_AF(SD_CLKREG, SD_CLKBIT, 12);
  GPIO_SEL_AF(SD_CMDREG, SD_CMDBIT, 12);
  GPIO_SEL_AF(SD_DAT0REG, SD_DAT0BIT, 12);
  GPIO_SEL_AF(SD_DAT1REG, SD_DAT1BIT, 12);
  GPIO_SEL_AF(SD_DAT2REG, SD_DAT2BIT, 12);
  GPIO_SEL_AF(SD_DAT3REG, SD_DAT3BIT, 12);
  SDIO->CLKCR = 0;
  sdio_reg_delay();
  SDIO->POWER = SDIO_POWER_PWRCTRL;  /* power on: the host may clock the card */
  sdio_reg_delay();
#endif
}
void disk_init(void) __attribute__ ((weak, alias("sdn_init")));

DSTATUS sdn_status(BYTE drv) {
  DSTATUS status = 0;
  if (SDCARD_DETECT) {
    if (disk_state == DISK_CHANGED) {
      status |= STA_NOINIT;
    }
    if (SDCARD_WP) {
      status |= STA_PROTECT;
    }
  } else {
    status |= STA_NODISK;
  }
  return status;
}
DSTATUS disk_status(BYTE drv) __attribute__ ((weak, alias("sdn_status")));

DRESULT sdn_getinfo(BYTE drv, BYTE page, void *buffer) {
  uint32_t capacity;

  if (drv >= MAX_CARDS) {
    return RES_NOTRDY;
  }
  if (sdn_status(drv) & STA_NODISK) {
    return RES_NOTRDY;
  }
  if (page != 0) {
    return RES_ERROR;
  }
  if (ccs) {
    /* Special CSD for SDHC cards */
    capacity = (1 + getbits(csd,127-69+8,22)) * 1024;
  } else {
    /* Assume that MMC-CSD 1.0/1.1/1.2 and SD-CSD 1.1 are the same... */
    uint8_t exponent = 2 + getbits(csd, 127-49+8, 3);
    capacity = 1 + getbits(csd, 127-73+8, 12);
    exponent += getbits(csd, 127-83+8,4) - 9;
    while (exponent--) capacity *= 2;
  }

  diskinfo0_t *di = buffer;
  di->validbytes  = sizeof(diskinfo0_t);
  di->disktype    = DISK_TYPE_SD;
  di->sectorsize  = 2;
  di->sectorcount = capacity;

  printf("card capacity: %lu sectors\n", capacity);
  return RES_OK;
}
DRESULT disk_getinfo(BYTE drv, BYTE page, void *buffer) __attribute__ ((weak, alias("sdn_getinfo")));

DRESULT sdn_write(BYTE drv, const BYTE *buffer, DWORD sector, UINT count) {
  uint8_t sec;
  uint8_t *buf = (uint8_t*)buffer;
  if(drv >= MAX_CARDS) {
    return RES_NOTRDY;
  }
  if (sdn_status(drv) & STA_NODISK) {
    return RES_NOTRDY;
  }
#ifdef CONFIG_SD_HWSDIO_WRITE
  if(sd_use_host()) {
    DRESULT res;
    writeled(1);
    res = sdio_write(buf, sector, count);
    writeled(0);
    return res;
  }
#endif
  writeled(1);
  for(sec=0; sec<count; sec++) {
    write_block(sector+sec, buf);
    buf+=512;
  }
  writeled(0);
  return RES_OK;
}

DRESULT disk_write(BYTE drv, const BYTE *buffer, DWORD sector, UINT count) __attribute__ ((weak, alias("sdn_write")));

/* Detect changes of SD card 0 */
void sdn_changed() {
  if (sd_changed) {
    printf("ch ");
    if(SDCARD_DETECT) {
      disk_state = DISK_CHANGED;
    } else {
      disk_state = DISK_REMOVED;
    }
    sd_changed = 0;
  }
}

/* measure sd access time */
void sdn_gettacc(uint32_t *tacc_max, uint32_t *tacc_avg) {
  uint32_t sec1 = 0;
  uint32_t sec2 = 0;
  uint32_t time, time_max = 0;
  uint32_t time_avg = 0LL;
  uint32_t numread = 16384;
  int i;
  int sec_step = di.sectorcount / numread - 1;
  if(disk_state == DISK_REMOVED || usbint_server_busy()) return;
  sdn_checkinit(0);
  for (i=0; i < 128; i++) {
    sd_offload_tgt=2;
    sd_offload=1;
    sdn_read(0, NULL, 0, 1);
    sd_offload_tgt=2;
    sd_offload=1;
    sdn_read(0, NULL, i*sec_step, 1);
  }
  for (i=0; i < numread && (snes_get_mcu_cmd() == SNES_CMD_SYSINFO) && disk_state != DISK_REMOVED && !usbint_server_busy(); i++) {
  /* reset timer */
    TIM2->CR1 = 0;
    sd_offload_tgt=2;
    sd_offload=1;
    sdn_read(0, NULL, sec1, 2);
    sec1 += 2;
  /* start timer at 0, count up*/
    TIM2->CNT = 0;
    TIM2->CR1 = TIM_CR1_URS | TIM_CR1_CEN;
    sd_offload_tgt=2;
    sd_offload=1;
    sdn_read(0, NULL, sec2, 1);
  /* read timer */
    time = TIM2->CNT;
  /* clear event pending */
    BITBAND(TIM2->SR, TIM_SR_UIF_Pos) = 0;
/*    sd_offload_tgt=2;
    sd_offload=1;
    sdn_read(0, NULL, sec2, 15);*/
    time_avg += time/16;
    if(time > time_max) {
      time_max = time;
    }
    sec2 += sec_step;
  }
  time_avg = time_avg / (i+1) * 16;
  sd_offload=0;
  TIM2->CR1 = 0;
  if(disk_state != DISK_REMOVED && !usbint_server_busy()) {
    *tacc_max = time_max/(CONFIG_CPU_FREQUENCY / 1000000)-114;
    *tacc_avg = time_avg/(CONFIG_CPU_FREQUENCY / 1000000)-114;
  }
}

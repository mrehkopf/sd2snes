/* DISCLAIMER */

#ifndef SDNATIVE_H
#define SDNATIVE_H

#ifdef DEBUG_SD
#define DBG_SD
#else
#define DBG_SD while(0)
#endif

#ifdef DEBUG_SD_OFFLOAD
#define DBG_SD_OFFLOAD
#else
#define DBG_SD_OFFLOAD while(0)
#endif

#include "config.h"
#include "diskio.h"

#define CRC_ERROR        (0xf000)

extern int sd_offload;

#ifdef CONFIG_SD_HWSDIO
/* event and error counters of the hardware SDIO path */
typedef struct {
  uint32_t read_calls;
  uint32_t write_calls;
  uint32_t read_retries;
  uint32_t write_retries;
  uint32_t read_failures;
  uint32_t write_failures;
  uint32_t stream_continues;  /* transfers continuing an open CMD18/CMD25 stream */
  uint32_t stream_stops;      /* CMD12 sent through the SDIO host */
  uint32_t cmd_timeout;
  uint32_t cmd_crcfail;
  uint32_t r1_error;
  uint32_t data_crcfail;
  uint32_t data_timeout;
  uint32_t rx_overrun;
  uint32_t tx_underrun;
  uint32_t startbit_err;
  uint32_t dma_timeout;
  uint32_t dma_error;         /* DMA transfer or direct mode error flagged */
  uint32_t busy_timeout;
  uint32_t bounce_blocks;     /* blocks moved through the aligned bounce buffer */
} sd_hw_stats_t;

extern sd_hw_stats_t sd_hw_stats;

void sdn_hw_printstats(void);
#endif

/* These functions are weak-aliased to disk_... */
void    sdn_init(void);
DSTATUS sdn_status(BYTE drv);
DSTATUS sdn_initialize(BYTE drv);
DRESULT sdn_read(BYTE drv, BYTE *buffer, DWORD sector, UINT count);
DRESULT sdn_write(BYTE drv, const BYTE *buffer, DWORD sector, UINT count);
DRESULT sdn_getinfo(BYTE drv, BYTE page, void *buffer);
DRESULT sdn_ioctl(BYTE drv, BYTE cmd, void *buffer);

void    sdn_changed(void);
uint8_t* sdn_getcid(void);
void    sdn_gettacc(uint32_t *tacc_max, uint32_t *tacc_avg);
#endif

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include <arm/bits.h>
#include <string.h>
#include "config.h"
#include "diskio.h"
#include "ff.h"
#include "timer.h"
#include "uart.h"
#include "fileops.h"
#include "memory.h"
#include "snes.h"
#include "fpga.h"
#include "fpga_spi.h"
#include "cic.h"
#include "sdnative.h"
#include "sysinfo.h"

extern status_t ST;

static uint32_t sd_tacc_max, sd_tacc_avg;

void sysinfo_loop() {
  sd_tacc_max = 0;
  sd_tacc_avg = 0;
  int sd_measured = 0;
  echo_mcu_cmd();
  while(snes_get_mcu_cmd() == SNES_CMD_SYSINFO) {
    sd_measured = write_sysinfo(sd_measured);
    delay_ms(100);
  }
  echo_mcu_cmd();
}

int write_sysinfo(int sd_measured) {
  uint32_t sram_addr = SRAM_SYSINFO_ADDR;
  char linebuf[40];
  int len;
  int sd_ok = 0;
  uint8_t *sd_cid;
  uint32_t sd_tacc_max_int = sd_tacc_max / 1000;
  uint32_t sd_tacc_max_frac = sd_tacc_max - (sd_tacc_max_int * 1000);
  uint32_t sd_tacc_avg_int = sd_tacc_avg / 1000;
  uint32_t sd_tacc_avg_frac = sd_tacc_avg - (sd_tacc_avg_int * 1000);
  int32_t sysclk = get_snes_sysclk();
  uint32_t fssize;
  uint32_t fsfree;
  FATFS *ffs = &fatfs;
  status_save_from_menu();

  if(!sd_measured)sram_writeblock("Calculating disk space\x7f\x80                ", sram_addr, 40);
  /* remount before sdn_getcid so fatfs registers the disk state change first */
  f_getfree("0:", &fsfree, &ffs);
  sd_cid = sdn_getcid();

  fssize = ((uint64_t)fatfs.n_fatent - 2LL) * (uint64_t)fatfs.csize * 512LL / 1048576LL;
  fsfree = ((uint64_t)fsfree) * (uint64_t)fatfs.csize * 512LL / 1048576LL;

  len = snprintf(linebuf, sizeof(linebuf), "Firmware version: %s", CONFIG_VERSION);
  memset(linebuf+len, 0x20, 40-len);
  sram_writeblock(linebuf, sram_addr, 40);
  sram_addr += 40;
  sram_memset(sram_addr, 40, 0x20);
  sram_addr += 40;
  if(disk_state == DISK_REMOVED) {
    sd_measured = 0;
    sd_tacc_max = 0;
    sd_tacc_avg = 0;
    sram_memset(sram_addr, 40, 0x20);
    sram_addr += 40;
    sram_memset(sram_addr, 40, 0x20);
    sram_addr += 40;
    sram_writestrn("         *** SD Card removed ***        ", sram_addr, 40);
    sram_addr += 40;
    sram_memset(sram_addr, 40, 0x20);
    sram_addr += 40;
    sram_memset(sram_addr, 40, 0x20);
    sram_addr += 40;
    sd_ok = 0;
  } else {
    len = snprintf(linebuf, sizeof(linebuf), "SD Maker/OEM:    0x%02x, \"%c%c\"", sd_cid[1], sd_cid[2], sd_cid[3]);
    memset(linebuf+len, 0x20, 40-len);
    sram_writeblock(linebuf, sram_addr, 40);
    sram_addr += 40;
    len = snprintf(linebuf, sizeof(linebuf), "SD Product Name: \"%c%c%c%c%c\", Rev. %d.%d", sd_cid[4], sd_cid[5], sd_cid[6], sd_cid[7], sd_cid[8], sd_cid[9]>>4, sd_cid[9]&15);
    memset(linebuf+len, 0x20, 40-len);
    sram_writeblock(linebuf, sram_addr, 40);
    sram_addr += 40;
    len = snprintf(linebuf, sizeof(linebuf), "SD Serial No.:   %02x%02x%02x%02x, Mfd. %d/%02d", sd_cid[10], sd_cid[11], sd_cid[12], sd_cid[13], 2000+((sd_cid[14]&15)<<4)+(sd_cid[15]>>4), sd_cid[15]&15);
    memset(linebuf+len, 0x20, 40-len);
    sram_writeblock(linebuf, sram_addr, 40);
    sram_addr += 40;
    if(sd_tacc_max) {
      len = snprintf(linebuf, sizeof(linebuf), "SD acc. time: %ld.%03ld / %ld.%03ld ms avg/max", sd_tacc_avg_int, sd_tacc_avg_frac, sd_tacc_max_int, sd_tacc_max_frac);
    } else {
      len = snprintf(linebuf, sizeof(linebuf), "SD acc. time: measuring\x7f\x80  ");
    }
    memset(linebuf+len, 0x20, 40-len);
    sram_writeblock(linebuf, sram_addr, 40);
    sram_addr += 40;
    len = snprintf(linebuf, sizeof(linebuf), "Card usage: %ldMB / %ldMB", fssize-fsfree, fssize);
    memset(linebuf+len, 0x20, 40-len);
    sram_writeblock(linebuf, sram_addr, 40);
    sram_addr += 40;
    sd_ok = 1;
  }
  sram_memset(sram_addr, 40, 0x20);
  sram_addr += 40;
  len = snprintf(linebuf, sizeof(linebuf), "CIC state: %s", get_cic_statefriendlyname(get_cic_state()));
  memset(linebuf+len, 0x20, 40-len);
  sram_writeblock(linebuf, sram_addr, 40);
  sram_addr += 40;
  if(sysclk == -1)
    len = snprintf(linebuf, sizeof(linebuf), "SNES master clock: measuring\x7f\x80");
  else
    len = snprintf(linebuf, sizeof(linebuf), "SNES master clock: %ldHz    ", get_snes_sysclk());
  memset(linebuf+len, 0x20, 40-len);
  sram_writeblock(linebuf, sram_addr, 40);
  sram_addr += 40;
  if(ST.is_u16) {
    if(ST.u16_cfg & 0x01) {
      len = snprintf(linebuf, sizeof(linebuf), "Ultra16 serial no. %d (Autoboot On)", ST.is_u16);
    } else {
      len = snprintf(linebuf, sizeof(linebuf), "Ultra16 serial no. %d (Autoboot Off)", ST.is_u16);
    }
    memset(linebuf+len, 0x20, 40-len);
    sram_writeblock(linebuf, sram_addr, 40);
  } else {
    sram_memset(sram_addr, 40, 0x20);
  }
  sram_addr += 40;
  sram_memset(sram_addr, 40, 0x20);
  sram_hexdump(SRAM_SYSINFO_ADDR, 13*40);
  if(sysclk != -1 && sd_ok && !sd_measured){
    sdn_gettacc(&sd_tacc_max, &sd_tacc_avg);
    sd_measured = 1;
  }
  return sd_measured;
}

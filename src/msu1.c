#include <string.h>
#include "config.h"
#include "uart.h"
#include "ff.h"
#include "diskio.h"
#include "spi.h"
#include "fpga_spi.h"
#include "cli.h"
#include "fileops.h"
#include "msu1.h"
#include "snes.h"
#include "timer.h"
#include "smc.h"

FIL msufile;
DWORD msu_cltbl[CLTBL_SIZE] IN_AHBRAM;
DWORD pcm_cltbl[CLTBL_SIZE] IN_AHBRAM;

extern snes_romprops_t romprops;

int msu1_check_reset(void) {
  static tick_t rising_ticks;

  static uint8_t resbutton=0, resbutton_prev=0;
  resbutton = get_snes_reset();
  if(resbutton && !resbutton_prev) { /* push */
    rising_ticks = getticks();
  } else if(resbutton && resbutton_prev) { /* hold */
    if(getticks() > rising_ticks + 99) {
      return 1;
    }
  }
  resbutton_prev = resbutton;
  return 0;
}

int msu1_check(uint8_t* filename) {
/* open MSU file */
  strcpy((char*)file_buf, (char*)filename);
  strcpy(strrchr((char*)file_buf, (int)'.'), ".msu");
  printf("MSU datafile: %s\n", file_buf);
  if(f_open(&msufile, (const TCHAR*)file_buf, FA_READ) != FR_OK) {
    printf("MSU datafile not found\n");
    return 0;
  }
  msufile.cltbl = msu_cltbl;
  msu_cltbl[0] = CLTBL_SIZE;
  if(f_lseek(&msufile, CREATE_LINKMAP)) {
    printf("Error creating FF linkmap for MSU file!\n");
  }
  romprops.fpga_features |= FEAT_MSU1;
  return 1;
}

int msu1_loop() {
/* it is assumed that the MSU file is already opened by calling msu1_check(). */
  UINT bytes_read = 1024;
  UINT bytes_read2 = 1;
  FRESULT res;
  set_dac_vol(0x00);
  while(fpga_status() & 0x4000);
  uint16_t fpga_status_prev = fpga_status();
  uint16_t fpga_status_now = fpga_status();
  uint16_t dac_addr = 0;
  uint16_t msu_addr = 0;
  uint8_t msu_repeat = 0;
  uint16_t msu_track = 0;
  uint32_t msu_offset = 0;
  uint32_t msu_loop_point = 0;

  uint32_t msu_page1_start = 0x0000;
  uint32_t msu_page2_start = 0x2000;
  uint32_t msu_page_size = 0x2000;

  set_msu_addr(0x0);
  msu_reset(0x0);
  ff_sd_offload=1;
  sd_offload_tgt=2;
  f_lseek(&msufile, 0L);
  ff_sd_offload=1;
  sd_offload_tgt=2;
  f_read(&msufile, file_buf, 16384, &bytes_read2);

  set_dac_addr(dac_addr);
  dac_pause();
  dac_reset();
/* audio_start, data_start, 0, audio_ctrl[1:0], ctrl_start */
  while(1){
    cli_entrycheck();
    fpga_status_now = fpga_status();

    /* Data buffer refill */
    if((fpga_status_now & 0x2000) != (fpga_status_prev & 0x2000)) {
      DBG_MSU1 printf("data\n");
      uint8_t pageno = 0;
      if(fpga_status_now & 0x2000) {
	msu_addr = 0x0;
	msu_page1_start = msu_page2_start + msu_page_size;
	pageno = 1;
      } else {
	msu_addr = 0x2000;
	msu_page2_start = msu_page1_start + msu_page_size;
	pageno = 2;
      }
      set_msu_addr(msu_addr);
      sd_offload_tgt=2;
      ff_sd_offload=1;
      res = f_read(&msufile, file_buf, 8192, &bytes_read2);
      DBG_MSU1 printf("data buffer refilled. res=%d page1=%08lx page2=%08lx\n", res, msu_page1_start, msu_page2_start);
    }

    /* Audio buffer refill */
    if((fpga_status_now & 0x4000) != (fpga_status_prev & 0x4000)) {
      if(fpga_status_now & 0x4000) {
	dac_addr = 0;
      } else {
	dac_addr = MSU_DAC_BUFSIZE/2;
      }
      set_dac_addr(dac_addr);
      sd_offload_tgt=1;
      ff_sd_offload=1;
      f_read(&file_handle, file_buf, MSU_DAC_BUFSIZE/2, &bytes_read);
    }

    if(fpga_status_now & 0x0020) {
      char suffix[11];

      /* get trackno */
      msu_track = get_msu_track();
      DBG_MSU1 printf("Audio requested! Track=%d\n", msu_track);

      /* open file, fill buffer */
      f_close(&file_handle);
      snprintf(suffix, sizeof(suffix), "-%d.pcm", msu_track);
      strcpy((char*)file_buf, (char*)file_lfn);
      strcpy(strrchr((char*)file_buf, (int)'.'), suffix);
      DBG_MSU1 printf("filename: %s\n", file_buf);
      f_open(&file_handle, (const TCHAR*)file_buf, FA_READ);
      file_handle.cltbl = pcm_cltbl;
      pcm_cltbl[0] = CLTBL_SIZE;
      f_lseek(&file_handle, CREATE_LINKMAP);
      f_lseek(&file_handle, 4L);
      f_read(&file_handle, &msu_loop_point, 4, &bytes_read);
      DBG_MSU1 printf("loop point: %ld samples\n", msu_loop_point);
      ff_sd_offload=1;
      sd_offload_tgt=1;
      f_lseek(&file_handle, 8L);
      set_dac_addr(0);
      dac_pause();
      dac_reset();
      ff_sd_offload=1;
      sd_offload_tgt=1;
      f_read(&file_handle, file_buf, MSU_DAC_BUFSIZE, &bytes_read);

      /* clear busy bit */
      set_msu_status(0x00, 0x20); /* set no bits, reset bit 5 */
    }

    if(fpga_status_now & 0x0010) {
      /* get address */
      msu_offset=get_msu_offset();
      DBG_MSU1 printf("Data requested! Offset=%08lx page1=%08lx page2=%08lx\n", msu_offset, msu_page1_start, msu_page2_start);
      if(   ((msu_offset < msu_page1_start)
	 || (msu_offset >= msu_page1_start + msu_page_size))
	 && ((msu_offset < msu_page2_start)
	 || (msu_offset >= msu_page2_start + msu_page_size))) {
	DBG_MSU1 printf("offset %08lx out of range (%08lx-%08lx, %08lx-%08lx), reload\n", msu_offset, msu_page1_start,
	       msu_page1_start+msu_page_size-1, msu_page2_start, msu_page2_start+msu_page_size-1);
	/* "cache miss" */
	/* fill buffer */
	set_msu_addr(0x0);
	sd_offload_tgt=2;
	ff_sd_offload=1;
        res = f_lseek(&msufile, msu_offset);
	DBG_MSU1 printf("seek to %08lx, res = %d\n", msu_offset, res);
	sd_offload_tgt=2;
	ff_sd_offload=1;

        res = f_read(&msufile, file_buf, 16384, &bytes_read2);
	DBG_MSU1 printf("read res = %d\n", res);
	DBG_MSU1 printf("read %d bytes\n", bytes_read2);
	msu_reset(0x0);
	msu_page1_start = msu_offset;
	msu_page2_start = msu_offset + msu_page_size;
      } else {
	if (msu_offset >= msu_page1_start && msu_offset <= msu_page1_start + msu_page_size) {
	  msu_reset(0x0000 + msu_offset - msu_page1_start);
	  DBG_MSU1 printf("inside page1, new offset: %08lx\n", 0x0000 + msu_offset-msu_page1_start);
	  if(!(msu_page2_start == msu_page1_start + msu_page_size)) {
	    set_msu_addr(0x2000);
	    sd_offload_tgt=2;
	    ff_sd_offload=1;
	    f_read(&msufile, file_buf, 8192, &bytes_read2);
	    DBG_MSU1 printf("next page dirty (was: %08lx), loaded page2 (start now: ", msu_page2_start);
	    msu_page2_start = msu_page1_start + msu_page_size;
	    DBG_MSU1 printf("%08lx)\n", msu_page2_start);
	  }
	} else if (msu_offset >= msu_page2_start && msu_offset <= msu_page2_start + msu_page_size) {
	  DBG_MSU1 printf("inside page2, new offset: %08lx\n", 0x2000 + msu_offset-msu_page2_start);
	  msu_reset(0x2000 + msu_offset - msu_page2_start);
	  if(!(msu_page1_start == msu_page2_start + msu_page_size)) {
	    set_msu_addr(0x0);
	    sd_offload_tgt=2;
	    ff_sd_offload=1;
	    f_read(&msufile, file_buf, 8192, &bytes_read2);
	    DBG_MSU1 printf("next page dirty (was: %08lx), loaded page1 (start now: ", msu_page1_start);
	    msu_page1_start = msu_page2_start + msu_page_size;
	    DBG_MSU1 printf("%08lx)\n", msu_page1_start);
	  }
	} else printf("!!!WATWATWAT!!!\n");
      }
      /* clear bank bit to mask bank reset artifact */
      fpga_status_now &= ~0x2000;
      fpga_status_prev &= ~0x2000;
      /* clear busy bit */
      set_msu_status(0x00, 0x10);
    }

    if(fpga_status_now & 0x0001) {
      if(fpga_status_now & 0x0004) {
	msu_repeat = 1;
	set_msu_status(0x04, 0x01); /* set bit 2, reset bit 0 */
	DBG_MSU1 printf("Repeat set!\n");
      } else {
	msu_repeat = 0;
	set_msu_status(0x00, 0x05); /* set no bits, reset bit 0+2 */
	DBG_MSU1 printf("Repeat clear!\n");
      }

      if(fpga_status_now & 0x0002) {
	DBG_MSU1 printf("PLAY!\n");
	set_msu_status(0x02, 0x01); /* set bit 0, reset bit 1 */
	dac_play();
      } else {
	DBG_MSU1 printf("PAUSE!\n");
	set_msu_status(0x00, 0x03); /* set no bits, reset bit 1+0 */
	dac_pause();
      }
    }

    fpga_status_prev = fpga_status_now;

    /* handle loop / end */
    if(bytes_read < MSU_DAC_BUFSIZE / 2) {
      ff_sd_offload=0;
      sd_offload=0;
      if(msu_repeat) {
	DBG_MSU1 printf("loop\n");
	ff_sd_offload=1;
	sd_offload_tgt=1;
	f_lseek(&file_handle, 8L+msu_loop_point*4);
	ff_sd_offload=1;
	sd_offload_tgt=1;
	f_read(&file_handle, file_buf, (MSU_DAC_BUFSIZE / 2) - bytes_read, &bytes_read);
      } else {
	set_msu_status(0x00, 0x02); /* clear play bit */
	dac_pause();
      }
      bytes_read = MSU_DAC_BUFSIZE;
    }
    if(msu1_check_reset()) {
      f_close(&msufile);
      f_close(&file_handle);
      return 1;
    }
  }
}
/* END OF MSU1 STUFF */

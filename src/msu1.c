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
FRESULT msu_res;
DWORD msu_cltbl[CLTBL_SIZE] IN_AHBRAM;
DWORD pcm_cltbl[CLTBL_SIZE] IN_AHBRAM;
UINT msu_audio_bytes_read = 1024;
UINT msu_data_bytes_read = 1;

extern snes_romprops_t romprops;
uint32_t msu_loop_point = 0;
uint32_t msu_page1_start = 0x0000;
uint32_t msu_page2_start = 0x2000;
uint32_t msu_page_size = 0x2000;
uint16_t fpga_status_prev = 0;
uint16_t fpga_status_now = 0;

void prepare_audio_track(uint16_t msu_track, uint32_t audio_offset) {
  /* open file, fill buffer */
  char suffix[11];
  f_close(&file_handle);
  snprintf(suffix, sizeof(suffix), "-%d.pcm", msu_track);
  strcpy((char*)file_buf, (char*)file_lfn);
  strcpy(strrchr((char*)file_buf, (int)'.'), suffix);
  DBG_MSU1 printf("filename: %s\n", file_buf);
  dac_pause();
  dac_reset();
  if(f_open(&file_handle, (const TCHAR*)file_buf, FA_READ) == FR_OK) {
    file_handle.cltbl = pcm_cltbl;
    pcm_cltbl[0] = CLTBL_SIZE;
    f_lseek(&file_handle, CREATE_LINKMAP);
    f_lseek(&file_handle, 4L);
    f_read(&file_handle, &msu_loop_point, 4, &msu_audio_bytes_read);
    DBG_MSU1 printf("loop point: %ld samples\n", msu_loop_point);
    ff_sd_offload=1;
    sd_offload_tgt=1;
    f_lseek(&file_handle, audio_offset);
    set_dac_addr(0);
    ff_sd_offload=1;
    sd_offload_tgt=1;
    f_read(&file_handle, file_buf, MSU_DAC_BUFSIZE, &msu_audio_bytes_read);
    /* clear busy bit */
    set_msu_status(0x00, 0x28); /* set no bits, reset audio_busy + audio_error */
  } else {
    f_close(&file_handle);
    set_msu_status(0x08, 0x20); /* reset audio_busy, set audio_error */
  }
}

void prepare_data(uint32_t msu_offset) {
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
    msu_res = f_lseek(&msufile, msu_offset);
    DBG_MSU1 printf("seek to %08lx, res = %d\n", msu_offset, msu_res);
    sd_offload_tgt=2;
    ff_sd_offload=1;
    msu_res = f_read(&msufile, file_buf, 16384, &msu_data_bytes_read);
    DBG_MSU1 printf("read res = %d\n", msu_res);
    DBG_MSU1 printf("read %d bytes\n", msu_data_bytes_read);
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
        f_read(&msufile, file_buf, 8192, &msu_data_bytes_read);
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
        f_read(&msufile, file_buf, 8192, &msu_data_bytes_read);
        DBG_MSU1 printf("next page dirty (was: %08lx), loaded page1 (start now: ", msu_page1_start);
        msu_page1_start = msu_page2_start + msu_page_size;
        DBG_MSU1 printf("%08lx)\n", msu_page1_start);
      }
    } else printf("!!!WATWATWAT!!!\n");
  }
  /* clear bank bit to mask bank reset artifact */
  fpga_status_now &= ~MSU_FPGA_STATUS_MSU_READ_MSB;
  fpga_status_prev &= ~MSU_FPGA_STATUS_MSU_READ_MSB;
  /* clear busy bit */
  set_msu_status(0x00, 0x10);
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
  uint16_t dac_addr = 0;
  uint16_t msu_addr = 0;
  uint8_t msu_repeat = 0;
  uint16_t msu_track = 0;
  uint32_t msu_offset = 0;
  int32_t resume_msu_track = -1;
  uint32_t resume_msu_offset = 0;
  int msu_res;
  uint8_t cmd;

  msu_page1_start = 0x0000;
  msu_page2_start = 0x2000;

  set_dac_addr(dac_addr);
  dac_pause();
  dac_reset();

  set_msu_addr(0x0);
  msu_reset(0x0);
  ff_sd_offload=1;
  sd_offload_tgt=2;
  f_lseek(&msufile, 0L);
  ff_sd_offload=1;
  sd_offload_tgt=2;
  f_read(&msufile, file_buf, 16384, &msu_data_bytes_read);

  prepare_audio_track(0, 8L);
  prepare_data(0);
/* audio_start, data_start, 0, audio_ctrl[1:0], ctrl_start */
  msu_res = SNES_RESET_NONE;
  fpga_status_prev = fpga_status();
  fpga_status_now = fpga_status();
  while(msu_res == SNES_RESET_NONE){
    msu_res = get_snes_reset_state();
    cmd = snes_get_mcu_cmd();
    if(cmd) {
      switch(cmd) {
        case SNES_CMD_RESET:
          msu_res = SNES_RESET_SHORT;
          snes_reset_pulse();
          break;
        case SNES_CMD_RESET_TO_MENU:
          msu_res = SNES_RESET_LONG;
          break;
        default:
          printf("unknown cmd: %02x\n", cmd);
          break;
      }
      snes_set_mcu_cmd(0);
    }
    cli_entrycheck();
    fpga_status_now = fpga_status();

    /* ACK as fast as possible */
    if(fpga_status_now & MSU_FPGA_STATUS_CTRL_START) {
      set_msu_status(0x00, 0x01);
    }

    /* Data buffer refill */
    if((fpga_status_now & MSU_FPGA_STATUS_MSU_READ_MSB) != (fpga_status_prev & MSU_FPGA_STATUS_MSU_READ_MSB)) {
      DBG_MSU1 printf("data\n");
      if(fpga_status_now & MSU_FPGA_STATUS_MSU_READ_MSB) {
        msu_addr = 0x0;
        msu_page1_start = msu_page2_start + msu_page_size;
      } else {
        msu_addr = 0x2000;
        msu_page2_start = msu_page1_start + msu_page_size;
      }
      set_msu_addr(msu_addr);
      sd_offload_tgt=2;
      ff_sd_offload=1;
      msu_res = f_read(&msufile, file_buf, 8192, &msu_data_bytes_read);
      DBG_MSU1 printf("data buffer refilled. res=%d page1=%08lx page2=%08lx\n", msu_res, msu_page1_start, msu_page2_start);
    }

    /* Audio buffer refill */
    if((fpga_status_now & MSU_FPGA_STATUS_DAC_READ_MSB) != (fpga_status_prev & MSU_FPGA_STATUS_DAC_READ_MSB)) {
      if(fpga_status_now & MSU_FPGA_STATUS_DAC_READ_MSB) {
        dac_addr = 0;
      } else {
        dac_addr = MSU_DAC_BUFSIZE/2;
      }
      set_dac_addr(dac_addr);
      sd_offload_tgt=1;
      ff_sd_offload=1;
      f_read(&file_handle, file_buf, MSU_DAC_BUFSIZE/2, &msu_audio_bytes_read);
    }

    if(fpga_status_now & MSU_FPGA_STATUS_AUDIO_START) {
      /* get trackno */
      msu_track = get_msu_track();
      DBG_MSU1 printf("Audio requested! Track=%d\n", msu_track);

      prepare_audio_track(msu_track, (msu_track == resume_msu_track) ? resume_msu_offset : 8L);
      if(msu_track == resume_msu_track) {
        resume_msu_track = -1;
      }
    }

    if(fpga_status_now & MSU_FPGA_STATUS_DATA_START) {
      /* get address */
      msu_offset=get_msu_offset();
      prepare_data(msu_offset);
    }

    if(fpga_status_now & MSU_FPGA_STATUS_CTRL_START) {
      if(fpga_status_now & MSU_FPGA_STATUS_CTRL_RESUME_FLAG_BIT && !(fpga_status_now & MSU_FPGA_STATUS_CTRL_PLAY_FLAG_BIT)) {
        resume_msu_track = msu_track;
        resume_msu_offset = f_tell(&file_handle);
      }

      if(fpga_status_now & MSU_FPGA_STATUS_CTRL_REPEAT_FLAG_BIT) {
        msu_repeat = 1;
        set_msu_status(0x04, 0x00); /* set bit 2 */
        DBG_MSU1 printf("Repeat set!\n");
      } else {
        msu_repeat = 0;
        set_msu_status(0x00, 0x04); /* reset bit 2 */
        DBG_MSU1 printf("Repeat clear!\n");
      }

      if(fpga_status_now & MSU_FPGA_STATUS_CTRL_PLAY_FLAG_BIT) {
        DBG_MSU1 printf("PLAY!\n");
        set_msu_status(0x02, 0x00); /* set bit 1 */
        dac_play();
      } else {
        DBG_MSU1 printf("PAUSE!\n");
        set_msu_status(0x00, 0x02); /* reset bit 1 */
        dac_pause();
      }
    }

    fpga_status_prev = fpga_status_now;

    /* handle loop / end */
    if(msu_audio_bytes_read < MSU_DAC_BUFSIZE / 2) {
      ff_sd_offload=0;
      sd_offload=0;
      if(msu_repeat) {
        DBG_MSU1 printf("loop\n");
        ff_sd_offload=1;
        sd_offload_tgt=1;
        f_lseek(&file_handle, 8L+msu_loop_point*4);
        ff_sd_offload=1;
        sd_offload_tgt=1;
        f_read(&file_handle, file_buf, (MSU_DAC_BUFSIZE / 2) - msu_audio_bytes_read, &msu_audio_bytes_read);
      } else {
        set_msu_status(0x00, 0x02); /* clear play bit */
        dac_pause();
      }
      msu_audio_bytes_read = MSU_DAC_BUFSIZE;
    }
  }
  dac_pause();
  f_close(&file_handle);
  DBG_MSU1 printf("Reset ");
  if(msu_res == SNES_RESET_LONG) {
    f_close(&msufile);
    DBG_MSU1 printf("to menu\n");
    return 1;
  }
  DBG_MSU1 printf("game\n");
  return 0;
}

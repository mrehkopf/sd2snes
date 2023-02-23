#include <stdint.h>
#include <stddef.h>

#include "config.h"
#include "hwinfo.h"

char *hwinfo_model_name[] = { "sd2snes", "FXPAK Pro", "future Mk.4", "future Mk.5", "future Mk.6" };
char revname[2];

uint8_t get_hwinfo(hwinfo_t *hw) {
  uint8_t id, id_bak;
  GPIO_PULLUP(HWREV0_REG, HWREV0_BIT);
  GPIO_PULLUP(HWREV1_REG, HWREV1_BIT);
  GPIO_PULLUP(HWREV2_REG, HWREV2_BIT);
  GPIO_PULLUP(HWREV3_REG, HWREV3_BIT);
  GPIO_PULLDOWN(HWREV4_REG, HWREV4_BIT);
  GPIO_PULLDOWN(HWREV5_REG, HWREV5_BIT);
  GPIO_PULLDOWN(HWREV6_REG, HWREV6_BIT);
  GPIO_PULLDOWN(HWREV7_REG, HWREV7_BIT);
  SD_DAT_UNMASK();
  id = ((BITBAND(HWREV7_REG->GPIO_I, HWREV7_BIT) << 7)
       |(BITBAND(HWREV6_REG->GPIO_I, HWREV6_BIT) << 6)
       |(BITBAND(HWREV5_REG->GPIO_I, HWREV5_BIT) << 5)
       |(BITBAND(HWREV4_REG->GPIO_I, HWREV4_BIT) << 4)
       |(BITBAND(HWREV3_REG->GPIO_I, HWREV3_BIT) << 3)
       |(BITBAND(HWREV2_REG->GPIO_I, HWREV2_BIT) << 2)
       |(BITBAND(HWREV1_REG->GPIO_I, HWREV1_BIT) << 1)
       |(BITBAND(HWREV0_REG->GPIO_I, HWREV0_BIT) << 0));
  SD_DAT_MASK();
  id ^= 0x0f;
  id_bak = id;

  if(id >= 0xb0) {
    hw->maker = MAKER_KRIKZZ;
    hw->makername = "KRIKzz";
  } else if (id <= 0x40) {
    hw->maker = MAKER_IKARI_01;
    hw->makername = "ikari_01";
  } else {
    hw->maker = MAKER_UNKNOWN;
    hw->makername = "???";
  }

  if(hw->maker != MAKER_UNKNOWN) {
    id -= hw->maker;
    hw->model = (id >> 4);
    hw->modelname = hwinfo_model_name[hw->model];
    hw->revision = (id & 0x0f);
    if((hw->revision == 0) && (hw->model == 0)) {
      hw->revname = "A-G";
    } else {
      hw->revname = revname;
      revname[0] = 'A'+hw->revision - 1;
      revname[1] = 0;
    }
  } else {
    hw->modelname = "???";
    hw->revname = "?";
  }

  return id_bak;
}


MCUSRC := src

MK2MCUPATH := $(MCUSRC)/obj-mk2
MK3MCUPATH := $(MCUSRC)/obj-mk3
MK2MCU := firmware.img
MK3MCU := firmware.im3

MENUPATH := snes
MK2MENU := menu.bin
MK3MENU := m3nu.bin

FPGAPATH := verilog
MK2EXT := bit
MK3EXT := bi3
MK2CORES := base cx4 gsu obc1 sdd1 sa1
MK3CORES := base cx4 gsu obc1 sdd1 sa1

MK2FPGA := $(foreach C,$(MK2CORES),$(FPGAPATH)/sd2snes_$C/fpga_$C.$(MK2EXT))
MK3FPGA := $(foreach C,$(MK3CORES),$(FPGAPATH)/sd2snes_$C/fpga_$C.$(MK3EXT))

UTILS := utils

VERSION ?= SNAPSHOT

TARGETPARENT := release/v$(VERSION)
TARGET := $(TARGETPARENT)/sd2snes

all: version release

release: version bsxpage
	rm -rf $(TARGETPARENT)
	mkdir -p $(TARGET)
	cp bsxpage.bin $(TARGET)
	cp $(MK2FPGA) $(TARGET)
	cp $(MK3FPGA) $(TARGET)
	cp $(MK2MCUPATH)/$(MK2MCU) $(TARGET)
	cp $(MK3MCUPATH)/$(MK3MCU) $(TARGET)
	cp $(MENUPATH)/$(MK2MENU) $(TARGET)
	cp $(MENUPATH)/$(MK3MENU) $(TARGET)
	cd $(TARGETPARENT) && zip -r sd2snes_firmware_v$(VERSION).zip sd2snes

bsxpage:
	$(UTILS)/genbsxpage

version:
	@echo Version: $(VERSION)
ifeq ($(VERSION),SNAPSHOT)
	$(warning For release packaging please specify VERSION (e.g. 1.2.3))
endif

.PHONY: version release bsxpage

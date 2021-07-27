MCUSRC := src

MK2MCUPATH := $(MCUSRC)/obj-mk2
MK3MCUPATH := $(MCUSRC)/obj-mk3
MK2MCU := firmware.img
MK3MCU := firmware.im3

SAVESTATEPATH := savestate
SAVESTATEFILES := savestate*

MENUPATH := snes
MK2MENU := menu.bin
MK3MENU := m3nu.bin

FPGAPATH := verilog
MK2EXT := bit
MK3EXT := bi3
MK2CORES := base cx4 gsu obc1 sdd1 sa1 dsp sgb sgb_msu
MK3CORES := base cx4 gsu obc1 sdd1 sa1 dsp sgb

MK2FPGA := $(foreach C,$(MK2CORES),$(FPGAPATH)/sd2snes_$C/fpga_$C.$(MK2EXT))
MK3FPGA := $(foreach C,$(MK3CORES),$(FPGAPATH)/sd2snes_$C/fpga_$C.$(MK3EXT))

MK2MINI := $(FPGAPATH)/sd2snes_mini/fpga_mini.bit
MK3MINI := $(FPGAPATH)/sd2snes_mini/fpga_mini.bi3

MK2CLEAN := $(foreach C,$(MK2CORES) mini,$(FPGAPATH)/sd2snes_$C/.clean.$(MK2EXT))
MK3CLEAN := $(foreach C,$(MK3CORES) mini,$(FPGAPATH)/sd2snes_$C/.clean.$(MK3EXT))

UTILS := utils

include src/VERSION

TARGETPARENT := release/v$(CONFIG_VERSION)
TARGET := $(TARGETPARENT)/sd2snes

all: version build release

fpga: $(MK2FPGA) $(MK3FPGA)

$(MK2FPGA) $(MK2MINI):
	$(MAKE) -C $(dir $@) mk2

$(MK3FPGA) $(MK3MINI):
	$(MAKE) -C $(dir $@) mk3

$(MK2CLEAN):
	$(MAKE) -C $(dir $@) mk2_clean

$(MK3CLEAN):
	$(MAKE) -C $(dir $@) mk3_clean

build: $(MK2MINI) $(MK3MINI)
	@cd snes && make
	@cd src && make CONFIG=config-mk2
	@cd src && make CONFIG=config-mk3
	@cd savestate && make

release: version bsxpage
	rm -rf $(TARGETPARENT)
	mkdir -p $(TARGET)
	cp bin/*.bin $(TARGET)
	cp README.md $(TARGET)/readme.txt
	cp $(MK2FPGA) $(TARGET)
	cp $(MK3FPGA) $(TARGET)
	cp $(MK2MCUPATH)/$(MK2MCU) $(TARGET)
	cp $(MK3MCUPATH)/$(MK3MCU) $(TARGET)
	cp $(MENUPATH)/$(MK2MENU) $(TARGET)
	cp $(MENUPATH)/$(MK3MENU) $(TARGET)
	cp $(SAVESTATEPATH)/$(SAVESTATEFILES) $(TARGET)
	cd $(TARGETPARENT) && zip -r sd2snes_firmware_v$(CONFIG_VERSION).zip sd2snes

bsxpage:
	cd bin && ../$(UTILS)/genbsxpage

version:
	@echo Version: $(CONFIG_VERSION)

.PHONY: version release bsxpage $(MK2FPGA) $(MK3FPGA) $(MK2MINI) $(MK3MINI) $(MK2CLEAN) $(MK3CLEAN)

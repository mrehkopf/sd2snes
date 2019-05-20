include ../common.mk
# This is a rather primitive Makefile to facilitate (re)compilation of the FPGA
# core. It assumes that an initial project setup/compilation, particularly of
# any IP cores used, has taken place using the vendor's corresponding FPGA
# development environment.

# build on Windows
CORE = sdd1
XILINX_PART = xc3s400-pq208-4

# set paths to Xilinx/Intel tools, adjust these for your environment
mkpath = $(subst $(eval) ,:,$(wildcard $1))
XILINX := $(XILINX_HOME)/ISE
XILINX_EDK := $(XILINX_HOME)/EDK
XILINX_PLANAHEAD := $(XILINX_HOME)/PlanAhead
XILINX_DSP := $(XILINX_HOME)/ISE
XILINX_PATH = $(patsubst %,$(XILINX_HOME)/%,$(XILINX_PATHS))
XILINX_PATH := $(call mkpath,$(XILINX_PATH))

# make pretty Windows style paths for SmartXplorer...
ifeq ($(HOST),CYGWIN)
	XILINX_EDK := $(shell cygpath -w $(XILINX_EDK))
	XILINX_DSP := $(shell cygpath -w $(XILINX_DSP))
	XILINX_PLANAHEAD := $(shell cygpath -w $(XILINX_PLANAHEAD))
	XILINX := $(shell cygpath -w $(XILINX))
endif

# get cost table number from project file
XILINX_CT = $(shell grep Cost.*Map sd2snes_$(CORE).xise | sed -e 's/.*value="\([0-9]\+\)".*$$/\1/g')
XILINX_MAP_OPTS = -timing -logic_opt on -ol high -xe n -register_duplication on -cm area -ir off -pr b -power off
XILINX_PAR_OPTS = -ol high -xe n

VSRC = address.v cheat.v clk_test.v dac.v DCM_Scope.v main.v mcu_cmd.v msu.v sd_dma.v spi.v
VHSRC = FIFO_B2B.vhd FIFO_AXIS.vhd Golomb_0_Decoder.vhd Golomb_N_Decoder.vhd Input_Manager.vhd Output_Manager.vhd Probability_Estimator.vhd SDD1.vhd Serializer.vhd

XIL_IP = dac_buf.v msu_databuf.v snescmd_buf.v
XIL_IPCORE_DIR = ipcore_dir

# prepare source lists
VSRC := $(sort $(VSRC))
VHSRC := $(sort $(VHSRC))

XIL_IP := $(sort $(XIL_IP))
XIL_IP := $(patsubst %,$(XIL_IPCORE_DIR)/%,$(XIL_IP))

XIL_SRC := $(VSRC) $(VHSRC) $(XIL_IP)

# build all targets
all: mk2s mk3

# build mk2 (Xilinx) or mk3 (Intel) only
mk2: fpga_$(CORE).bit
mk3: fpga_$(CORE).bi3

# build mk2 using SmartXPlorer (useful for cx4, gsu, sa1, sdd1)
mk2s: smartxplorer

smartxplorer: main.ngd
	rm -rf smartxplorer_results
	PATH="$(XILINX_PATH)":"$(PATH)"; \
	export XILINX="$(XILINX)" XILINX_DSP="$(XILINX_DSP)" XILINX_EDK="$(XILINX_EDK)" XILINX_PLANAHEAD="$(XILINX_PLANAHEAD)"; \
	smartxplorer -p $(XILINX_PART) -b -wd smartxplorer_results main.ngd -to "-v 3 -s 4 -n 3 -fastpaths -xml main.twx -ucf main.ucf" $(XPLORER_PARAMS) \
	&& (while true; do \
		touch $@; \
		export SX_RUN=`grep "Run index" smartxplorer_results/smartxplorer.log | sed -e 's/^.*\:.*run\([0-9]\+\).*$$/\1/g'`; \
		export SX_RUN=$${SX_RUN:-1}; \
		echo Winner: "$$SX_RUN"; \
		cp -a smartxplorer_results/run$$SX_RUN/* ./; \
		sed -i'' -e 's/\(Starting Placer Cost Table.*value="\)[0-9]*/\1'$$SX_RUN'/' sd2snes_$(CORE).xise; \
		break; \
	done) \
	&& ../../utils/rle main.bit fpga_$(CORE).bit

fpga_$(CORE).bit: main.bit
	../../utils/rle $^ $@

main.bit: main.ncd
	$(XILINX_BIN)/bitgen -f main.ut $^

main.ncd: main_map.ncd
	$(XILINX_BIN)/par -w -t $(XILINX_CT) $(XILINX_PAR_OPTS) $^ $@ main.pcf

main_map.ncd: main.ngd
	$(XILINX_BIN)/map -p $(XILINX_PART) -t $(XILINX_CT) $(XILINX_MAP_OPTS) -o $@ $^ main.pcf

main.ngd: main.ngc
	$(XILINX_BIN)/ngdbuild -dd _ngo -sd ipcore_dir -nt timestamp -uc main.ucf -p $(XILINX_PART) $^ $@

main.ngc: main.xst main.prj
	$(XILINX_BIN)/xst -ifn main.xst -ofn main.syr

main.prj: $(XIL_SRC)
	rm -f main.prj
	for src in $(VSRC) $(XIL_IP); do echo "verilog work \"$$src\"" >> main.prj; done
	for src in $(VHSRC); do echo vhdl work "$$src" >> main.prj; done

clean: mk2_clean mk3_clean

mk2_clean:
	rm -f main.ncd main.bit fpga_$(CORE).bit main.pcf main.ngd main.ngc main.prj

mk3_clean:
	rm -f output_files/main.rbf fpga_$(CORE).bi3

fpga_$(CORE).bi3: output_files/main.rbf
	../../utils/rle $^ $@

# Intel pulls a lot more stuff from project context...
output_files/main.rbf: $(VSRC) $(VHSRC)
	$(INTEL_BIN)/quartus_map --read_settings_files=on --write_settings_files=off sd2snes_$(CORE) -c main
	$(INTEL_BIN)/quartus_fit --read_settings_files=on --write_settings_files=off sd2snes_$(CORE) -c main
	$(INTEL_BIN)/quartus_asm --read_settings_files=off --write_settings_files=off sd2snes_$(CORE) -c main
	$(INTEL_BIN)/quartus_sta sd2snes_$(CORE) -c main
	$(INTEL_BIN)/quartus_eda --read_settings_files=on --write_settings_files=off sd2snes_$(CORE) -c main

.PHONY: clean mk2 mk2s mk3 mk2_clean mk3_clean

# This is a Makefile to facilitate (re)compilation of the FPGA core.
# It assumes that an initial project setup/compilation, particularly of
# any IP cores used, has taken place using the vendor's corresponding FPGA
# development environment.

# set paths to Xilinx/Intel tools, adjust these for your environment
mkpath = $(subst $(eval) ,:,$(wildcard $1))
XILINX := $(XILINX_HOME)/ISE
XILINX_EDK := $(XILINX_HOME)/EDK
XILINX_PLANAHEAD := $(XILINX_HOME)/PlanAhead
XILINX_DSP := $(XILINX_HOME)/ISE
XILINX_PATH = $(patsubst %,$(XILINX_HOME)/%,$(XILINX_PATHS))
XILINX_PATH := $(call mkpath,$(XILINX_PATH))

XILINX_PART = $(shell $(XILINX_BIN)/xtclsh ../xgetpartname.tcl sd2snes_$(CORE).xise)

XILINX_SYNTH  := "Synthesize - XST"
XILINX_IMPL   := "Implement Design"
XILINX_BITGEN := "Generate Programming File"

# make pretty Windows style paths for SmartXplorer...
ifeq ($(HOST),CYGWIN)
	XILINX_EDK := $(shell cygpath -w $(XILINX_EDK))
	XILINX_DSP := $(shell cygpath -w $(XILINX_DSP))
	XILINX_PLANAHEAD := $(shell cygpath -w $(XILINX_PLANAHEAD))
	XILINX := $(shell cygpath -w $(XILINX))
endif

# prepare source lists
VSRC := $(sort $(VSRC))
VHSRC := $(sort $(VHSRC))

XIL_IP := $(sort $(XIL_IP))
XIL_IP := $(patsubst %,$(XIL_IPCORE_DIR)/%.ngc,$(XIL_IP))

# build all targets
all: mk2 mk3

# build mk2 (Xilinx) or mk3 (Intel) only
mk2: fpga_$(CORE).bit
mk3: fpga_$(CORE).bi3

# build mk2 using SmartXPlorer (useful for cx4, gsu, sa1, sdd1)
mk2s: smartxplorer

smartxplorer: main.ngd currentProps.stratfile hostlistfile.txt
	rm -rf smartxplorer_results
	PATH="$(XILINX_PATH)":"$(PATH)"; \
	export XILINX="$(XILINX)" XILINX_DSP="$(XILINX_DSP)" XILINX_EDK="$(XILINX_EDK)" XILINX_PLANAHEAD="$(XILINX_PLANAHEAD)"; \
	echo "Running SmartXPlorer. Check smartxplorer_results/smartxplorer.html for progress."; \
	$(XILINX_BIN)/smartxplorer -p $(XILINX_PART) -b -wd smartxplorer_results main.ngd -to "-v 3 -s 4 -n 3 -fastpaths -xml main.twx -ucf main.ucf" $(XPLORER_PARAMS) \
	&& (while true; do \
		touch $@; \
		export SX_RUN=`grep "Run index" smartxplorer_results/smartxplorer.log | sed -e 's/^.*\:.*run\([0-9]\+\).*$$/\1/g'`; \
		export SX_RUN=$${SX_RUN:-1}; \
		echo Winner: "$$SX_RUN"; \
		cp -af smartxplorer_results/run$$SX_RUN/* ./; \
		sed -i'' -e 's/\(Starting Placer Cost Table.*value="\)[0-9]*/\1'$$SX_RUN'/' sd2snes_$(CORE).xise; \
		break; \
	done) \
	&& ../../utils/rle main.bit fpga_$(CORE).bit

fpga_$(CORE).bit: main.bit
	../../utils/rle $^ $@

main.bit: main.ncd
	$(XILINX_BIN)/xtclsh ../xrun.tcl sd2snes_$(CORE).xise $(XILINX_BITGEN)

main.ngd: main.ngc $(XIL_IP)
	$(XILINX_BIN)/ngdbuild -dd _ngo -sd ipcore_dir -nt timestamp -uc main.ucf -p $(XILINX_PART) $< $@

main.ncd: main.ngc $(XIL_IP)
	$(XILINX_BIN)/xtclsh ../xrun.tcl sd2snes_$(CORE).xise $(XILINX_IMPL)

currentProps.stratfile:
	$(XILINX_BIN)/xtclsh ../xgenstratfile.tcl sd2snes_$(CORE).xise

hostlistfile.txt:
	n=0; while [ $$n -lt $(XPLORER_CPUS) ]; do echo localhost; n=$$(( n + 1 )); done > $@

$(XIL_IPCORE_DIR)/%.ngc: $(XIL_IPCORE_DIR)/%.xco | $(XIL_IPCORE_DIR)/coregen.cgc
	$(XILINX_BIN)/coregen -p $(XIL_IPCORE_DIR) -b $< -r

main.ngc: sd2snes_$(CORE).xise $(XIL_IP)
	rm -f $@
	$(XILINX_BIN)/xtclsh ../xrun.tcl sd2snes_$(CORE).xise $(XILINX_SYNTH)

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
#	$(INTEL_BIN)/quartus_eda --read_settings_files=on --write_settings_files=off sd2snes_$(CORE) -c main

.PHONY: clean mk2 mk2s mk3 mk2_clean mk3_clean

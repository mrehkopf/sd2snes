# This is a Makefile to facilitate (re)compilation of the FPGA core.
# It assumes that an initial project setup/compilation, particularly of
# any IP cores used, has taken place using the vendor's corresponding FPGA
# development environment.

# set window title to indicate FPGA build status
T = @echo -e "\e]0;$(1)\a"

# Xilinx coregen needs an updated JVM (link /usr/bin/java into
# (e.g.) /opt/Xilinx/14.7/ISE/ISE_DS/java/lin64/jre/bin) on recent linuxes;
# the bundled 64-bit JVM fails to load its own classes.
#
# However current JVMs do not support the -d64 switch as used by coregen
# anymore.
# so set JAVA_OPTS / _JAVA_OPTIONS (depending on Oracle/OpenJDK)
# to ignore unrecognized switches:
export JAVA_OPTS := "-XX:+IgnoreUnrecognizedVMOptions"
export _JAVA_OPTIONS := "-XX:+IgnoreUnrecognizedVMOptions"


# these are relative to the core subdir, not the path of common.mk
XILINX_XST_TMPDIR := "xst/projnav.tmp"
XILINX_SCRIPTS := "../xilinx_scripts"
mkpath = $(subst $(eval) ,:,$(wildcard $1))

XILINX_PATH := $(patsubst %,$(XILINX_HOME)/%,$(XILINX_PATHS))

XILINX := $(XILINX_HOME)/ISE
XILINX_EDK := $(XILINX_HOME)/EDK
XILINX_PLANAHEAD := $(XILINX_HOME)/PlanAhead
XILINX_DSP := $(XILINX_HOME)/ISE

# make pretty Windows style paths for SmartXplorer...
ifeq ($(HOST),CYGWIN)
	XILINX_EDK := $(shell cygpath -w $(XILINX_EDK))
	XILINX_DSP := $(shell cygpath -w $(XILINX_DSP))
	XILINX_PLANAHEAD := $(shell cygpath -w $(XILINX_PLANAHEAD))
	XILINX := $(shell cygpath -w $(XILINX))
	XILINX_PATH := $(shell cygpath $(XILINX_PATH))
endif

ifeq ($(HOST),WSL)
	XILINX_ENV := MSYS2_ARG_CONV_EXCL='*' wsl . $(XILINX_HOME)/settings64.sh \> /dev/null \;
else
	XILINX_ENV := [ -f $(XILINX_HOME)/settings64.sh ] && . $(XILINX_HOME)/settings64.sh > /dev/null ; 
endif

XILINX_PATH := $(call mkpath,$(XILINX_PATH))
XILINX_PART = $(shell $(XILINX_ENV) $(XILINX_BIN)/xtclsh $(XILINX_SCRIPTS)/xgetpartname.tcl sd2snes_$(CORE).xise)

# prepare source lists
VSRC := $(sort $(VSRC))
VHSRC := $(sort $(VHSRC))
UCF := main.ucf

# apply differing source path
ifdef VSRC_DIR
	VSRC := $(patsubst %,$(VSRC_DIR)/%,$(VSRC))
	VHSRC := $(patsubst %,$(VSRC_DIR)/%,$(VHSRC))
	UCF := $(patsubst %,$(VSRC_DIR)/%,$(UCF))
endif

XIL_IP := $(sort $(XIL_IP))
XIL_IP += $(sort $(COMMON_IP))
XIL_IP := $(patsubst %,$(XIL_IPCORE_DIR)/%.ngc,$(XIL_IP))


export QUARTUS_ROOTDIR
export XILINX_EDK XILINX_DSP XILINX_PLANAHEAD XILINX XILINX_PATH

# INTEL_ENV := [ -d $(QUARTUS_ROOTDIR)/adm ] && . $(QUARTUS_ROOTDIR)/adm/qenv.sh ;

INT_IP := $(sort $(INT_IP))
INT_IP += $(sort $(COMMON_IP))
INT_IP := $(patsubst %,%.v,$(INT_IP))

mk2 := fpga_$(CORE).bit
mk3 := fpga_$(CORE).bi3

# build all targets
all: $(mk2) $(mk3)

# build mk2 (Xilinx) or mk3 (Intel) only
mk2: $(mk2)
mk3: $(mk3)

# ######## XILINX ########
# build mk2 using SmartXPlorer (useful for cx4, gsu, sa1, sdd1)
mk2s: smartxplorer

smartxplorer: main.ngd currentProps.stratfile hostlistfile.txt
	rm -rf smartxplorer_results
	PATH="$(XILINX_PATH)":"$(PATH)"; \
	export XILINX="$(XILINX)" XILINX_DSP="$(XILINX_DSP)" XILINX_EDK="$(XILINX_EDK)" XILINX_PLANAHEAD="$(XILINX_PLANAHEAD)" XILINX_PATH="$(XILINX_PATH)"; \
	echo "Running SmartXPlorer. Check smartxplorer_results/smartxplorer.html for progress."; \
	$(XILINX_ENV) $(XILINX_BIN)/smartxplorer -p $(XILINX_PART) -b -wd smartxplorer_results main.ngd -to "-v 3 -s 4 -n 3 -fastpaths -xml main.twx -ucf $(UCF)" $(XPLORER_PARAMS) \
	&& (while true; do \
		touch $@; \
		export SX_RUN=`grep "Run index" smartxplorer_results/smartxplorer.log | sed -e 's/^.*\:.*run\([0-9]\+\).*$$/\1/g'`; \
		export SX_RUN=$${SX_RUN:-1}; \
		echo Winner: "$$SX_RUN"; \
		cp -af smartxplorer_results/run$$SX_RUN/* ./; \
		sed -i'' -e 's/\(Starting Placer Cost Table.*value="\)[0-9]*/\1'$$SX_RUN'/' sd2snes_$(CORE).xise; \
		echo Results and settings have been copied.; \
		break; \
	done) \
	&& ../../utils/rle main.bit fpga_$(CORE).bit

fpga_$(CORE).bit: main.bit
	../../utils/rle $^ $@

main.ngc: main.xst main.prj
	$(call T,[mk2] fpga_$(CORE) - Synthesize)
	rm -f $@
	mkdir -p $(XILINX_XST_TMPDIR)
	$(XILINX_ENV) $(XILINX_BIN)/xst -ifn main.xst -ofn main.syr

main.ngd: main.ngc $(XIL_IP)
	$(call T,[mk2] fpga_$(CORE) - Translate)
	$(XILINX_ENV) $(XILINX_BIN)/ngdbuild -dd _ngo -sd $(XIL_IPCORE_DIR) -nt timestamp -uc $(UCF) -p $(XILINX_PART) $< $@

main_map.ncd: main.ngd
	$(call T,[mk2] fpga_$(CORE) - Map)
	$(eval XILINX_MAP_OPTS := $(shell $(XILINX_ENV) $(XILINX_BIN)/xtclsh $(XILINX_SCRIPTS)/xgenmapcmd.tcl sd2snes_$(CORE).xise))
	$(XILINX_ENV) $(XILINX_BIN)/map -p $(XILINX_PART) $(XILINX_MAP_OPTS) -o $@ $^ main.pcf

main.ncd: main_map.ncd
	$(call T,[mk2] fpga_$(CORE) - Place and Route)
	$(eval XILINX_PAR_OPTS := $(shell $(XILINX_ENV) $(XILINX_BIN)/xtclsh $(XILINX_SCRIPTS)/xgenparcmd.tcl sd2snes_$(CORE).xise))
	$(XILINX_ENV) $(XILINX_BIN)/par -w $(XILINX_PAR_OPTS) $^ $@ main.pcf
	@! grep -q 'Timing Score: [1-9][0-9]*' main.par || (echo "[mk2] sd2snes_$(CORE): Timing not met! Aborting."; exit 55)

main.bit: main.ncd main.ut
	$(call T,[mk2] fpga_$(CORE) - Generate Programming File)
	$(XILINX_ENV) $(XILINX_BIN)/bitgen -f main.ut $<
	$(call T)

# IP Core regeneration
$(XIL_IPCORE_DIR)/%.ngc: $(XIL_IPCORE_DIR)/%.xco | $(XIL_IPCORE_DIR)/coregen.cgc
	$(call T,[mk2] fpga_$(CORE) - Regenerate IP Cores)
	$(XILINX_ENV) $(XILINX_BIN)/coregen -p $(XIL_IPCORE_DIR) -b $< -r

# ## Supplementary files required for Xilinx processes ##
# PRJ file - basically a list of files that comprise the project
main.prj: $(XIL_IP) $(VSRC) $(VHSRC) $(HEADER)
	rm -f main.prj
	for src in $(VSRC) $(XIL_IP:.ngc=.v); do echo "verilog work \"$$src\"" >> main.prj; done
	for src in $(VHSRC); do echo vhdl work "$$src" >> main.prj; done

# XST file - list of command line options for the synthesis tool (xst)
main.xst: sd2snes_$(CORE).xise main.prj
	$(XILINX_ENV) $(XILINX_BIN)/xtclsh $(XILINX_SCRIPTS)/xgenxstfile.tcl $< $@ main.prj $(XIL_IPCORE_DIR) $(XILINX_XST_TMPDIR)

# UT file - list of command line options for the bit file generator (bitgen)
main.ut: sd2snes_$(CORE).xise
	$(XILINX_ENV) $(XILINX_BIN)/xtclsh $(XILINX_SCRIPTS)/xgenbitgenfile.tcl $^ $@

# Generate Strategy file for SmartXPlorer
currentProps.stratfile: sd2snes_$(CORE).xise
	$(XILINX_ENV) $(XILINX_BIN)/xtclsh $(XILINX_SCRIPTS)/xgenstratfile.tcl sd2snes_$(CORE).xise

# Generate host list file for SmartXPlorer (enable parallel operation)
hostlistfile.txt:
	n=0; while [ $$n -lt $(XPLORER_CPUS) ]; do echo localhost; n=$$(( n + 1 )); done > $@


# ######## ALTERA / INTEL ########

fpga_$(CORE).bi3: output_files/main.rbf
	../../utils/rle $^ $@

# Intel pulls a lot more stuff from project context...
output_files/main.rbf: $(VSRC) $(VHSRC) $(HEADER) $(INT_IP) main.sdc
	rm -rf db incremental_db
	$(call T,[mk3] fpga_$(CORE) - Map)
	$(INTEL_ENV) $(INTEL_BIN)/quartus_map --read_settings_files=on --write_settings_files=off sd2snes_$(CORE) -c main
	$(call T,[mk3] fpga_$(CORE) - Fit)
	$(INTEL_ENV) $(INTEL_BIN)/quartus_fit --read_settings_files=on --write_settings_files=off sd2snes_$(CORE) -c main
	$(call T,[mk3] fpga_$(CORE) - Timing Analysis)
	$(INTEL_ENV) $(INTEL_BIN)/quartus_sta sd2snes_$(CORE) -c main
	@! grep -q 'TNS.*-' output_files/main.sta.summary || (echo "[mk3] sd2snes_$(CORE): Timing not met! Aborting."; exit 55)
	$(call T,[mk3] fpga_$(CORE) - Assemble)
	$(INTEL_ENV) $(INTEL_BIN)/quartus_asm --read_settings_files=off --write_settings_files=off sd2snes_$(CORE) -c main
#	$(INTEL_ENV) $(INTEL_BIN)/quartus_eda --read_settings_files=on --write_settings_files=off sd2snes_$(CORE) -c main
	$(call T)


clean: mk2_clean mk3_clean

mk2_clean:
	rm -f main.ncd main.bit fpga_$(CORE).bit main.pcf main.ngd main.ngc main.prj

mk3_clean:
	rm -f output_files/main.rbf fpga_$(CORE).bi3

.PHONY: clean mk2 mk2s mk3 mk2_clean mk3_clean ALWAYS

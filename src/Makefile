# Hey Emacs, this is a -*- makefile -*-

#----------------------------------------------------------------------------
# WinAVR Makefile Template written by Eric B. Weddington, Joerg Wunsch, et al.
#
# Released to the Public Domain
#
# Additional material for this makefile was written by:
# Peter Fleury
# Tim Henigan
# Colin O'Flynn
# Reiner Patommel
# Markus Pfaff
# Sander Pool
# Frederik Rouleau
# Carlos Lamas
#
#
# Extensively modified for sd2iec and later adapted for ARM by Ingo Korb
#
# To rebuild project do "make clean" then "make all".
#----------------------------------------------------------------------------

# select programming interface (default: ae-ft2232)
# setting is expanded to filename interface/$INTERFACE.cfg
# available: ae-ft2232 usb-blaster oocdlink usbjtag
# INTERFACE=bmp uses a Black Magic Probe via gdb instead (program only)
export INTERFACE ?= ae-ft2232

# Read configuration file
ifndef CONFIG
$(info ERROR: Please use $(MAKE) CONFIG=... to specify at least one config file.)
$(info Available configs:)
$(foreach cfg,$(wildcard config-*),$(info $(patsubst %,  %,$(cfg))))
$(info )
$(info You may specify a programming interface using INTERFACE=...)
$(info Available INTERFACEs (default/current: $(INTERFACE)):)
$(foreach intf,$(wildcard interface/*),$(info $(patsubst interface/%.cfg,  %,$(intf))))
$(info $()  bmp (Black Magic Probe, program only))
$(info )
$(error missing CONFIG parameter)
else
 CONFIGSUFFIX = $(CONFIG:config%=%)
endif

# Enable verbose compilation with "make V=1"
ifdef V
 Q :=
 E := @:
else
 Q := @
 E := @echo
endif

# Include the configuration file
include $(CONFIG)

# OpenOCD search path from config
export CONFIG_OPENOCD_SCRIPT_PATH ?= .

# Directory for all generated files
OBJDIR := obj$(CONFIGSUFFIX)
DEPDIR := .dep$(CONFIGSUFFIX)

# Linker script
LINKERSCRIPT = $(CONFIG_LD_SCRIPT)

# Target file name (without extension).
TARGET = $(OBJDIR)/sd2snes

# Environment variables for openocd reuse
export FW_START=$(CONFIG_FW_START)
export FW_FILE=$(OBJDIR)/$(CONFIG_FW_FILE)
export FLASH_SIZE=$(CONFIG_FLASH_SIZE)

# Version
-include VERSION
include version.mk

# List C source files here. (C dependencies are automatically generated.)
SRC  = main.c ff.c ccsbcs.c
SRC += printf.c fileops.c fpga.c fpga_spi.c snes.c smc.c
SRC += memory.c filetypes.c faulthandler.c sort.c crc32.c cic.c
SRC += cli.c ymodem.c msu1.c crc16.c sysinfo.c exodecrunch.c exomem.c
SRC += cfg.c cheat.c yaml.c savestate.c sgb.c hwinfo.c skinconv.c

SRC += usbdesc.c usbcore.c usbuser.c cdcuser.c usbinterface.c

# List Assembler source files here.
#     Make them always end in a capital .S.  Files ending in a lowercase .s
#     will not be considered source files but generated files (assembler
#     output from the compiler), and will be deleted upon "make clean"!
#     Even though the DOS/Win* filesystem matches both .s and .S the same,
#     it will preserve the spelling of the filenames, and gcc itself does
#     care about how the name is spelled on its command-line.
ASRC = crc.S

# add in platform specific configuration
include $(CONFIG_ARCH)/variables.mk
-include $(CONFIG_ARCH)/debug-variables.mk

# usbcontrol.c usb_hid.c usbhw_lpc.c usbinit.c usbstdreq.c

# Optimization level, can be [0, 1, 2, 3, s].
#     0 = turn off optimization. s = optimize for size.
#     (Note: 3 is not always the best optimization level. See avr-libc FAQ.)
# Use s -mcall-prologues when you really need size...
#OPT = 2
OPT = s

# Debugging format.
DEBUG = dwarf-2

# List any extra directories to look for include files here.
#     Each directory must be seperated by a space.
#     Use forward slashes for directory separators.
#     For a directory that has spaces, enclose it in quotes.
EXTRAINCDIRS =

# Compiler flag to set the C Standard level.
#     c89   = "ANSI" C
#     gnu89 = c89 plus GCC extensions
#     c99   = ISO C99 standard (not yet fully implemented)
#     gnu99 = c99 plus GCC extensions
CSTANDARD = -std=gnu99

# Place -D or -U options here
CDEFS = -DF_OSC=$(CONFIG_MCU_FOSC)UL

# The boot screen's FPGA core (CONFIG_CFGWARE, the bitstream as the FPGA
# tools write it) and SNES ROM (snesboot.h, made by snes/boot) are packed
# with exomizer raw; its decoder (exomem.c) keeps the last EXO_WINDOW bytes.
EXOMIZER ?= exomizer
EXO_WINDOW = 8192
CDEFS += -DEXO_WINDOW=$(EXO_WINDOW)

# Place -I options here
CINCS = -Iinclude -Iinclude/arm

# CPU-specific flags
ifndef CPUFLAGS
  CPUFLAGS := -mthumb -mcpu=cortex-m3
endif

ifndef ARCH
  ARCH := arm-none-eabi
endif

# Define programs and commands.
# CC must be defined here to generate the correct CFLAGS
SHELL = sh
CC = $(ARCH)-gcc
OBJCOPY = $(ARCH)-objcopy
OBJDUMP = $(ARCH)-objdump
SIZE = $(ARCH)-size
NM = $(ARCH)-nm
REMOVE = rm -f
COPY = cp
AWK = gawk
BIN2C = ../utils/bin2c

#---------------- Compiler Options ----------------
#  -g*:          generate debugging information
#  -O*:          optimization level
#  -f...:        tuning, see GCC manual and avr-libc documentation
#  -Wall...:     warning level
#  -Wa,...:      tell GCC to pass this to the assembler.
#    -adhlns...: create assembler listing
CFLAGS = -g$(DEBUG)
CFLAGS += $(CDEFS) $(CINCS)
CFLAGS += -O$(OPT)
CFLAGS += $(CPUFLAGS) -nostartfiles
#CFLAGS += -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
CFLAGS += -Wall -Wstrict-prototypes -Werror -Wno-strict-aliasing
CFLAGS += -Wa,-adhlns=$(OBJDIR)/$(<:.c=.lst)
CFLAGS += -I$(OBJDIR) -I$(CONFIG_ARCH)
CFLAGS += $(patsubst %,-I%,$(EXTRAINCDIRS))
CFLAGS += $(CSTANDARD)
CFLAGS += -ffunction-sections -fdata-sections

#---------------- Assembler Options ----------------
#  -Wa,...:   tell GCC to pass this to the assembler.
#  -ahlms:    create listing
#  -gstabs:   have the assembler create line number information; note that
#             for use in COFF files, additional information about filenames
#             and function names needs to be present in the assembler source
#             files -- see avr-libc docs [FIXME: not yet described there]
ASFLAGS = $(CPUFLAGS) -Wa,-adhlns=$(OBJDIR)/$(<:.S=.lst),-gstabs -I$(OBJDIR)

#---------------- Linker Options ----------------
#  -Wl,...:     tell GCC to pass this to linker.
#    -Map:      create map file
#    --cref:    add cross reference to  map file
LDFLAGS = -Wl,-Map=$(TARGET).map,--cref
LDFLAGS += -T$(LINKERSCRIPT)
LDFLAGS += -Wl,--gc-sections
ifeq ($(CONFIG_LINKER_RELAX),y)
  LDFLAGS += -Wl,-O9,--relax
endif

# OpenOCD options
# -s <path>:      set additional script search path
# -f openocd.cfg: load common script
OPENOCDFLAGS = -s $(CONFIG_OPENOCD_SCRIPT_PATH) -f openocd.cfg

# Black Magic Probe options (INTERFACE=bmp)
# BMP_PORT: GDB server device of the probe (default: first probe found in
#           /dev/serial/by-id, else /dev/ttyACM0)
# BMP_SCAN: monitor command that finds the target (auto_scan, swd_scan,
#           jtag_scan; older probe firmware has swdp_scan instead of swd_scan)
# GDB:      gdb with ARM support (e.g. arm-none-eabi-gdb, gdb-multiarch)
BMP_PORT ?= $(firstword $(wildcard /dev/serial/by-id/usb-Black_*_Black_Magic_Probe_*-if00) /dev/ttyACM0)
BMP_SCAN ?= auto_scan
GDB ?= gdb

#============================================================================

# De-dupe the list of C source files
CSRC := $(sort $(SRC))

# Define all object files.
OBJ := $(patsubst %,$(OBJDIR)/%,$(CSRC:.c=.o) $(ASRC:.S=.o))

# Define all listing files.
LST := $(patsubst %,$(OBJDIR)/%,$(CSRC:.c=.lst) $(ASRC:.S=.lst))

# Generate list of obj dirs
OBJDIRS := $(sort $(dir $(OBJ)))

# Compiler flags to generate dependency files.
GENDEPFLAGS = -MMD -MP -MF $(DEPDIR)/$(@F).d

# Combine all necessary flags and optional flags.
# Add target processor to flags.
ALL_CFLAGS = -I. $(CFLAGS) $(GENDEPFLAGS)
ALL_ASFLAGS = -I. -x assembler-with-cpp $(ASFLAGS) $(CDEFS)

# Default target.
all: build

build: elf bin hex
	$(E) "  SIZE   $(TARGET).elf"
	$(Q)$(ELFSIZE)|grep -v debug
	cp $(TARGET).bin $(OBJDIR)/$(CONFIG_FW_FILE)

elf: $(TARGET).elf
bin: $(TARGET).bin
hex: $(TARGET).hex
eep: $(TARGET).eep
lss: $(TARGET).lss
sym: $(TARGET).sym

ifeq ($(INTERFACE),bmp)
program: build
	$(GDB) -nx -batch -x bmp.gdb -ex 'bmp_program $(BMP_PORT) $(BMP_SCAN)' $(TARGET).elf

debug reset:
	$(error INTERFACE=bmp currently only supports the program target)
else
program: build
	utils/lpcchksum $(TARGET).bin
	openocd $(OPENOCDFLAGS) -f flash.cfg

debug: build
	openocd $(OPENOCDFLAGS)

reset:
	openocd $(OPENOCDFLAGS) -f reset.cfg
endif

# Display size of file.
ELFSIZE = $(SIZE) -A $(TARGET).elf

# Generate version.h
.PRECIOUS : $(OBJDIR)/version.h
$(OBJDIR)/version.h: .ARG_VERSION | $(OBJDIR)
	$(E) "  VERSION $(CONFIG_VERSION)"
	$(Q)printf "#ifndef __VERSION_H\n"\
"#define __VERSION_H\n"\
"#define CONFIG_VERSION \"$(CONFIG_VERSION)\"\n"\
"#endif" > $(OBJDIR)/version.h

# Generate autoconf.h from config
.PRECIOUS : $(OBJDIR)/autoconf.h
$(OBJDIR)/autoconf.h: $(CONFIG) | $(OBJDIR)
	$(E) "  CONF2H $(CONFIG)"
	$(Q)$(AWK) -f conf2h.awk $(CONFIG) > $(OBJDIR)/autoconf.h

# Generate embedded FPGA config from finished bitfile, exomizer-packed
.PRECIOUS : $(OBJDIR)/cfgware.h $(OBJDIR)/cfgware.exo
$(OBJDIR)/cfgware.exo: $(CONFIG_CFGWARE) | $(OBJDIR)
	$(E) "  EXO    $(CONFIG_CFGWARE)"
	$(Q)$(EXOMIZER) raw -q -m $(EXO_WINDOW) -o $@ "$(CONFIG_CFGWARE)"

$(OBJDIR)/cfgware.h: $(OBJDIR)/cfgware.exo | $(OBJDIR) $(OBJDIR)/autoconf.h
	$(E) "  BIN2C $<"
	$(Q)$(BIN2C) $< cfgware > $@

# Create final output files from ELF output file.
# --gap-fill 0xff is important to match the padding values as they end up
# in physical flash; CRC calculation is wrong otherwise.
$(TARGET)-intermediate.bin: $(TARGET)-intermediate.elf
	$(E) "  BINTMP $@"
	$(Q)$(OBJCOPY) --gap-fill 0xff -O binary -R .fwhdr $< $@

$(TARGET).bin: $(OBJDIR)/fw.hdr $(TARGET)-intermediate.bin
	$(E) "  BIN    $@"
	$(Q)cat $^ > $@

$(OBJDIR)/%.hex: $(OBJDIR)/%.elf
	$(E) "  HEX    $@"
	$(Q)$(OBJCOPY) -O ihex $< $@

# Create extended listing file from ELF output file.
$(OBJDIR)/%.lss: $(OBJDIR)/%.elf
	$(E) "  LSS    $<"
	$(Q)$(OBJDUMP) -h -S $< > $@

# Create a symbol table from ELF output file.
$(OBJDIR)/%.sym: $(OBJDIR)/%.elf
	$(E) "  SYM    $<"
	$(E)$(NM) -n $< > $@

# Link: create ELF output file from object files.
.SECONDARY : $(TARGET)-intermediate.elf
.PRECIOUS : $(OBJ)
$(TARGET)-intermediate.elf: .EXTRA_PREREQS = $(LINKERSCRIPT)
$(TARGET)-intermediate.elf : $(OBJ)
	$(E) "  LINK   $@"
	$(Q)$(CC) $(ALL_CFLAGS) $^ --output $@ $(LDFLAGS)

# create final ELF file with embedded firmware header
.SECONDARY : $(TARGET).elf
$(TARGET).elf: $(TARGET)-intermediate.elf $(OBJDIR)/fw.hdr
	$(E) "  ELF    $@"
	$(Q)$(OBJCOPY) --update-section .fwhdr=$(OBJDIR)/fw.hdr $< $@

# firmware header file generated by genhdr
$(OBJDIR)/fw.hdr: $(TARGET)-intermediate.bin
	$(E) "  GENHDR $@"
	$(Q)utils/genhdr -s $(CONFIG_FW_MAGIC) -h $(CONFIG_FW_HEADERSIZE) -o $@ $<

$(OBJDIR)/$(CONFIG_FW_FILE): $(TARGET).elf
	cat $^ > $(OBJDIR)/$(CONFIG_FW_FILE)

# Compile: create object files from C source files.
$(OBJDIR)/%.o : %.c | $(OBJDIRS) $(OBJDIR)/autoconf.h $(OBJDIR)/cfgware.h $(OBJDIR)/version.h
	$(E) "  CC     $<"
	$(Q)$(CC) -c $(ALL_CFLAGS) $< -o $@

# Compile: create assembler files from C source files.
$(OBJDIR)/%.s : %.c | $(OBJDIR) $(OBJDIR)/autoconf.h $(OBJDIR)/cfgware.h $(OBJDIR)/version.h
	$(CC) -S $(ALL_CFLAGS) $< -o $@

# Assemble: create object files from assembler source files.
$(OBJDIR)/%.o : %.S | $(OBJDIRS) $(OBJDIR)/autoconf.h
	$(E) "  AS     $<"
	$(Q)$(CC) -c $(ALL_ASFLAGS) $< -o $@

# Create preprocessed source for use in sending a bug report.
$(OBJDIR)/%.i : %.c | $(OBJDIR) $(OBJDIR)/autoconf.h $(OBJDIR)/cfgware.h $(OBJDIR)/version.h
	$(CC) -E -mmcu=$(MCU) -I. $(CFLAGS) $< -o $@

# Create the output directory
$(OBJDIRS) :
	$(E) "  MKDIR  $(OBJDIRS)"
	$(Q)mkdir -p $(OBJDIRS)

# Target: clean project.
clean: begin clean_list end

clean_list :
	$(E) "  CLEAN"
	$(Q)$(REMOVE) $(TARGET).hex
	$(Q)$(REMOVE) $(TARGET).bin
	$(Q)$(REMOVE) $(TARGET).elf
	$(Q)$(REMOVE) $(TARGET)-intermediate.bin
	$(Q)$(REMOVE) $(TARGET)-intermediate.elf
	$(Q)$(REMOVE) $(TARGET).map
	$(Q)$(REMOVE) $(TARGET).sym
	$(Q)$(REMOVE) $(TARGET).lss
	$(Q)$(REMOVE) $(OBJ)
	$(Q)$(REMOVE) $(OBJDIR)/autoconf.h
	$(Q)$(REMOVE) $(OBJDIR)/cfgware.h $(OBJDIR)/cfgware.exo
	$(Q)$(REMOVE) $(OBJDIR)/version.h
	$(Q)$(REMOVE) $(OBJDIR)/${CONFIG_FW_FILE}
	$(Q)$(REMOVE) $(OBJDIR)/fw.hdr
	$(Q)$(REMOVE) $(OBJDIR)/.DS_Store
	$(Q)$(REMOVE) $(LST)
	$(Q)$(REMOVE) $(CSRC:.c=.s)
	$(Q)$(REMOVE) $(CSRC:.c=.d)
	$(Q)$(REMOVE) $(DEPDIR)/*
	-$(Q)rmdir --ignore-fail-on-non-empty -p $(OBJDIRS)

# Include the dependency files.
-include $(info $(DEPDIR)) $(shell mkdir $(DEPDIR) 2>/dev/null) $(wildcard $(DEPDIR)/*)

# Listing of phony targets.
.PHONY : all begin finish end sizebefore sizeafter \
build elf hex lss sym clean clean_list

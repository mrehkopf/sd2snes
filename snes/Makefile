IPS = header.ips
O65 = reset.o65 main.o65 font.o65 palette.o65 data.o65 const.o65 logo.o65 logospr.o65 dma.o65 filesel.o65 pad.o65 time.o65 sysinfo.o65 spc700.o65 spcplay.o65 menu.o65 menudata.o65 ui.o65 nmihook.o65 common.o65 cheat.o65 savestate.o65 # gfx.o65 # vars.o65

OBJS = $(IPS) $(O65)
# stopgap measure to create both files as long as they are identical...

OUT = menu.bin m3nu.bin

LOG = $(OBJS:=.log)
MAP = $(IPS:.ips=.map) $(O65:.o65=.map)

all: $(OUT) $(MAP)

smc: menu.bin
	cat menu.bin sd2snes.rom > menu.smc

map: $(MAP)

$(MAP) &: menu.bin $(LOG) link.log
	utils/mkmap.sh $(OBJS)

# generate menu.bin / m3nu.bin / link.log
$(OUT): $(IPS) $(OBJS)
	sneslink -fsmc -o $@ $^ 2>&1 | tee link.log

# in case link.log has been deleted
link.log: $(IPS) $(OBJS)
	sneslink -fsmc -o /dev/null $^ 2>&1 | tee link.log

# Generic rule to create .o65[.log] out from .a65
%.o65 %.o65.log: %.a65
	snescom -J -Wall -o $(@:.log=) $< 2>&1 | tee $(@:.log=).log

# Generic rule to create .ips out from .a65
%.ips %.ips.log: %.a65
	snescom -I -J -Wall -o $(@:log=) $< 2>&1 | tee $(@.log=).log

clean:
	rm -f -- *~ *.ips *.o65 $(OUT) *.o65.log *.ips.log

.PHONY: all smc map clean

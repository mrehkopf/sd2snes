OBJS = header.ips reset.o65 main.o65 font.o65 palette.o65 data.o65 const.o65 logo.o65 logospr.o65 dma.o65 filesel.o65 pad.o65 time.o65 sysinfo.o65 spc700.o65 spcplay.o65 menu.o65 menudata.o65 ui.o65 nmihook.o65 common.o65 cheat.o65 # gfx.o65 # vars.o65

# stopgap measure to create both files as long as they are identical...
OUT = menu.bin m3nu.bin

all: clean $(OUT) map

smc: menu.bin
	cat menu.bin sd2snes.rom > menu.smc

map: menu.bin
	utils/mkmap.sh $(OBJS)

$(OUT): $(OBJS)
	sneslink -fsmc -o $@ $^ 2>&1 | tee link.log

# Generic rule to create .o65 out from .a65
%.o65: %.a65
	snescom -J -Wall -o $@ $< 2>&1 | tee $@.log

# Generic rule to create .ips out from .a65
%.ips: %.a65
	snescom -I -J -Wall -o $@ $< 2>&1 | tee $@.log

clean:
	rm -f *.ips *.o65 *~ $(OUT)

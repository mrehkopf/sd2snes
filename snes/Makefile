OBJS = header.ips reset.o65 main.o65 font.o65 palette.o65 data.o65 const.o65 logo.o65 logospr.o65 text.o65 dma.o65 menu.o65 pad.o65 time.o65 mainmenu.o65 # gfx.o65 # vars.o65

all: menu.bin menu.smc

menu.smc: menu.bin
	cat menu.bin sd2snes.rom > $@
menu.bin: $(OBJS)
	sneslink -fsmc -o $@ $^

# Generic rule to create .o65 out from .a65
%.o65: %.a65
	snescom -J -Wall -o $@ $<

# Generic rule to create .ips out from .a65
%.ips: %.a65
	snescom -I -J -Wall -o $@ $<

clean:
	rm -f *.ips *.o65 *~ menu.bin

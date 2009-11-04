OBJS = header.ips reset.o65 main.o65 font.o65 palette.o65 data.o65 const.o65 logo.o65 text.o65 dma.o65 menu.o65 # gfx.o65 # vars.o65

all: menu.bin

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

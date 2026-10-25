OBJS = header.ips reset.o65 main.o65 font.o65 palette.o65 data.o65 const.o65 text.o65 dma.o65 # gfx.o65 # vars.o65

all: menu.bin

# the firmware's copy of this ROM (the boot screen's), exomizer-packed for
# its decoder (src/exomem.c); committed with the source changes. The window
# goes into the header too, and the firmware checks it against its own
# (EXO_WINDOW in src/Makefile).
EXO_WINDOW = 8192
snesboot: ../../src/snesboot.h
../../src/snesboot.h: menu.bin
	exomizer raw -q -m $(EXO_WINDOW) -o menu.exo $<
	{ echo "#define BOOTROM_EXO_WINDOW $(EXO_WINDOW)"; ../../utils/bin2c menu.exo bootrom; } > $@

menu.bin: $(OBJS)
	sneslink -fsmc -o $@ $^

# Generic rule to create .o65 out from .a65
%.o65: %.a65
	snescom -J -Wall -o $@ $<

# Generic rule to create .ips out from .a65
%.ips: %.a65
	snescom -I -J -Wall -o $@ $<

clean:
	rm -f *.ips *.o65 *~ menu.bin menu.exo

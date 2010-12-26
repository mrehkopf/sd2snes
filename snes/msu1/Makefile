OBJS = header.ips reset.o65 main.o65 data.o65 const.o65 dma.o65 msu1.o65 # gfx.o65 # vars.o65

all: msu1vid.sfc

msu1vid.sfc: $(OBJS)
	sneslink -fsmc -o $@ $^

# Generic rule to create .o65 out from .a65
%.o65: %.a65
	snescom -J -Wall -o $@ $<

# Generic rule to create .ips out from .a65
%.ips: %.a65
	snescom -I -J -Wall -o $@ $<

clean:
	rm -f *.ips *.o65 *~ msu1vid.sfc

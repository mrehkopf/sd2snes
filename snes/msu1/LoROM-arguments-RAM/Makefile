OBJS = header.ips lorom-padding.o65 reset.o65 main.o65 data.o65 const.o65 dma.o65 msu1.o65 spc.o65 # gfx.o65 # vars.o65

all: clean msu1vid.sfc map

map: msu1vid.sfc
	../../utils/mkmap.sh $(OBJS)
	rm -f msu1vid.sfc.tmp

msu1vid.sfc: msu1vid.sfc.tmp
	dd if=$^ of=$@ bs=32768 count=1 skip=1

msu1vid.sfc.tmp: $(OBJS)
	sneslink -fsmc -o $@ $^ 2>&1 | tee link.log

# Generic rule to create .o65 out from .a65
%.o65: %.a65
	snescom -J -Wall -o $@ $< 2>&1 | tee $@.log

# Generic rule to create .ips out from .a65
%.ips: %.a65
	snescom -I -J -Wall -o $@ $< 2>&1 | tee $@.log

clean:
	rm -f *.ips *.o65 *~ *.tmp msu1vid.sfc

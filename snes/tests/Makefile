OBJS = vectors.ips header.ips reset.o65 tests.o65

all: test.bin

test.bin: $(OBJS)
	sneslink -fsmc -o $@.tmp $^ 2>&1 | tee link.log
	dd if=$@.tmp of=$@ bs=2048 count=1 skip=31

map: test.bin
	utils/mkmap.sh $(OBJS)

# Generic rule to create .o65 out from .a65
%.o65: %.a65
	snescom -J -Wall -o $@ $< 2>&1 | tee $@.log

# Generic rule to create .ips out from .a65
%.ips: %.a65
	snescom -I -J -Wall -o $@ $< 2>&1 | tee $@.log

clean:
	rm -f *.ips *.o65 *~ test.bin

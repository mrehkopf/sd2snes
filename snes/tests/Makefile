OBJS = header.ips reset.o65 tests.o65

all: test.bin

test.bin: $(OBJS)
	sneslink -fsmc -o $@ $^

# Generic rule to create .o65 out from .a65
%.o65: %.a65
	snescom -J -Wall -o $@ $<

# Generic rule to create .ips out from .a65
%.ips: %.a65
	snescom -I -J -Wall -o $@ $<

clean:
	rm -f *.ips *.o65 *~ test.bin

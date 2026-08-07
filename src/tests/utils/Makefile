
CC = gcc
CFLAGS = -Wall -Wstrict-prototypes -Werror

all: lpcchksum genhdr create-dma-testfile

create-dma-testfile: create-dma-testfile.o
	$(CC) $(CFLAGS) $^ --output $@

genhdr: genhdr.o
	$(CC) $(CFLAGS) $^ --output $@

lpcchksum: lpcchksum.o
	$(CC) $(CFLAGS) $^ --output $@

%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	rm -f genhdr.o genhdr
	rm -f lpcchksum.o lpcchksum
	rm -f create-dma-testfile.o create-dma-testfile


CC := gcc

CFLAGS = -Wall -Wstrict-prototypes -Werror

BIN = bin2asm bin2c bin2coe chili2chr derle gentilemap mem2lorom palremap palreorder rle genbsxpage

LIBUSB_CFLAGS := $(shell pkg-config --cflags libusb-1.0 2>/dev/null)
LIBUSB_LIBS := $(shell pkg-config --libs libusb-1.0 2>/dev/null)

all: $(BIN)

bin2asm: bin2asm.o
	$(CC) $(CFLAGS) $^ --output $@

bin2c: bin2c.o
	$(CC) $(CFLAGS) $^ --output $@

bin2coe: bin2coe.o
	$(CC) $(CFLAGS) $^ --output $@

chili2chr: chili2chr.o
	$(CC) $(CFLAGS) $^ --output $@

derle: derle.o
	$(CC) $(CFLAGS) $^ --output $@

gentilemap: gentilemap.o
	$(CC) $(CFLAGS) $^ --output $@

mem2lorom: mem2lorom.o
	$(CC) $(CFLAGS) $^ --output $@

palremap: palremap.o
	$(CC) $(CFLAGS) $^ --output $@

palreorder: palreorder.o
	$(CC) $(CFLAGS) $^ --output $@

rle: rle.o
	$(CC) $(CFLAGS) $^ --output $@

genbsxpage: genbsxpage.o
	$(CC) $(CFLAGS) $^ --output $@

# Not part of "all" because this host-side hardware test needs libusb-1.0.
sd2snes-ls-test: sd2snes-ls-test.c
	$(CC) $(CFLAGS) -std=c11 $(LIBUSB_CFLAGS) $< $(LIBUSB_LIBS) --output $@

%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	rm -f $(BIN) $(BIN:=.o) sd2snes-ls-test

.phony: clean all

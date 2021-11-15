CC := gcc

CFLAGS = -Wall -Wstrict-prototypes -Werror

BIN = bin2asm bin2c bin2coe chili2chr derle gentilemap mem2lorom palremap palreorder rle genbsxpage

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

%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	rm -f $(BIN) $(BIN:=.o)

.phony: clean all

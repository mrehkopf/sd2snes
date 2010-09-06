
CC = gcc
CFLAGS = -Wall -Wstrict-prototypes -Werror

all: lpcchksum

lpcchksum: lpcchksum.o
	$(CC) $(CFLAGS) $^ --output $@

%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@


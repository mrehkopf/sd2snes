KEY_ARCH = p12f629
LOCK_ARCH = p16f630

all: supercic-key.hex supercic-lock.hex

supercic-key.hex: supercic-key.asm
	gpasm -p $(KEY_ARCH) $^

supercic-lock.hex: supercic-lock.asm
	gpasm -p $(LOCK_ARCH) $^

clean:
	rm supercic-key.hex supercic-lock.hex

.PHONY: all clean

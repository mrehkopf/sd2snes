KEY_ARCH := p12f629 p12f675 p12f683
LOCK_ARCH := p16f630 p16f676 p16f684

GPASM_EXT := hex cod lst err

ALL_KEY := $(patsubst %,supercic-key_%,$(KEY_ARCH))
ALL_LOCK := $(patsubst %,supercic-lock_%,$(LOCK_ARCH))
ALL_RGBLOCK := $(patsubst %,supercic-lock-RGB-cathode_%,$(LOCK_ARCH))

ALL_BASE := $(ALL_KEY) $(ALL_LOCK) $(ALL_RGBLOCK)
ALL_HEX := $(ALL_BASE:=.hex)

ALL_ARTIFACTS := $(foreach B,$(ALL_BASE),$(foreach E,$(GPASM_EXT),$B.$E))

ARCHIVE := supercic.zip

all: $(ALL_HEX) release

supercic-key_%.hex: supercic-key.asm
	gpasm -p $(patsubst supercic-key_%.hex,%,$@) -o $@ $^

supercic-lock_%.hex: supercic-lock.asm
	gpasm -p $(patsubst supercic-lock_%.hex,%,$@) -o $@ $^

supercic-lock-RGB-cathode_%.hex: supercic-lock-RGB-cathode.asm
	gpasm -p $(patsubst supercic-lock-RGB-cathode_%.hex,%,$@) -o $@ $^

release: $(ALL_HEX)
	zip $(ARCHIVE) $(ALL_HEX)

clean:
	-rm $(ALL_ARTIFACTS) $(ARCHIVE)

.PHONY: all clean release

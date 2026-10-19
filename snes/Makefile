# rom.asm includes all other sources
# TODO make Makefile sensitive to changes in all source files again
SRC = rom.asm

OUT = menu.bin m3nu.bin

AS = 64tass
AS_MIN_VERSION = 1.60.3243
ASFLAGS = --m65816 -C -a -q
CHKSUM = ../utils/sneschksum

DEPDIR := .dep

all: $(OUT)

menu.bin: $(SRC) | $(DEPDIR)
	@test -x $(CHKSUM) || { echo "$(CHKSUM) not found, run 'make -C ../utils' first"; exit 1; }
	@v=$$($(AS) --version | sed -n 's/.* V\([0-9.]*\).*/\1/p'); \
	  printf '%s\n%s\n' $(AS_MIN_VERSION) "$$v" | sort -V -C || \
	  { echo "64tass $(AS_MIN_VERSION) or newer required (found: $$v)"; exit 1; }
	$(AS) $(ASFLAGS) -f -o $@ -L menu.lst --line-numbers --vice-labels -l menu.lbl \
	  --map menu.map -M $(DEPDIR)/menu.d --make-phony $(SRC)
	$(CHKSUM) $@

# stopgap measure to create both files as long as they are identical...
m3nu.bin: menu.bin
	cp $< $@

$(DEPDIR):
	mkdir -p $@

smc: menu.bin
	cat menu.bin sd2snes.rom > menu.smc

# symbol list sorted by address ("C0xxxx label")
map: menu.sym

menu.sym: menu.bin
	awk '{ sub(/^\./, "", $$3); a = toupper($$2); while (length(a) < 6) a = "0" a; print a, $$3 }' menu.lbl | sort -u > $@

clean:
	rm -f -- *~ $(OUT) menu.lst menu.lbl menu.map menu.sym menu.smc
	rm -rf -- $(DEPDIR)

-include $(wildcard $(DEPDIR)/*.d)

.PHONY: all smc map clean

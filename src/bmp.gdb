# Program the firmware with a Black Magic Probe (make program INTERFACE=bmp).
#
# Usage: gdb -nx -batch -x bmp.gdb -ex 'bmp_program PORT SCAN' sd2snes.elf
#   PORT: GDB server device of the probe, e.g. /dev/ttyACM0 or COM8
#   SCAN: monitor command that finds the target (auto_scan, swd_scan, jtag_scan)
#
# The steps are defined commands rather than separate -ex options because an
# error inside a defined command stops it and makes gdb exit with an error,
# while gdb -batch carries on after a failing -ex.
#
# load only erases and writes the flash sectors covered by the ELF file, so
# the bootloader below CONFIG_FW_START is kept. kill resets the target, which
# then boots through the bootloader, and detaches.

define bmp_attach
  target extended-remote $arg0
  monitor $arg1
  attach 1
end

define bmp_program
  bmp_attach $arg0 $arg1
  load
  compare-sections
  kill
end

/* Linker script for LPC1756
 *
 * Written 2010 by Ingo Korb
 * Modified by Maximilian Rehkopf
 *
 * Partially based on the linker scripts of avr-libc
 */

OUTPUT_FORMAT(elf32-littlearm)
ENTRY(_start)

MEMORY
{
  flash  (rx)  : ORIGIN = 0x0000c100, LENGTH = 0x33f00 /* leave room for bootldr + metadata */
  ram    (rwx) : ORIGIN = 0x10000000, LENGTH = 0x04000
  ahbram (rwx) : ORIGIN = 0x2007C000, LENGTH = 0x04000
}

SECTIONS
{
  .text :
  {
    KEEP(*(.vectors))
    KEEP(*(.init))
    *(.text)
    *(.text.*)
    *(.gnu.linkonce.t.*)

    /* C++ con-/destructors */
    __ctors_start = . ;
    *(.ctors)
    __ctors_end = . ;
    __dtors_start = . ;
    *(.dtors)
    __dtors_end = . ;
    KEEP(SORT(*)(.ctors))
    KEEP(SORT(*)(.dtors))

    KEEP(*(.fini))

    __text_end = .;
  } > flash

  /* .ARM.exidx is sorted, so has to go in its own output section.  */
  __exidx_start = .;
  .ARM.exidx :
  {
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
  } >flash
  __exidx_end = .;

  /* I hope this does what I think it does */
  .rodata : AT (ALIGN(__exidx_end,4))
  {
    *(.rodata)
    *(.rodata.*)
    *(.gnu.linkonce.r.*)
    __rodata_end = .;
  } > flash

  /* Data section */
  .data : AT (ALIGN(__rodata_end,4))
  {
    __data_start = .;
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d.*)
    __data_end = .;
  } > ram

  /* Addresses of in-rom data section */
  __data_load_start = LOADADDR(.data);
  __data_load_end   = __data_load_start + SIZEOF(.data);

  . = ALIGN(4);

  /* BSS */
  .bss :
  {
    __bss_start__ = .;
    *(.bss)
    *(.bss.*)
    *(COMMON)
    __bss_end__ = .;
  } > ram

  /* second BSS in AHB ram */
  .ahbram (NOLOAD) :
  {
    __ahbram_start__ = .;
    *(.ahbram)
    *(.ahbram.*)
    __ahbram_end__ = .;
  } > ahbram

  __heap_start = ALIGN(__bss_end__, 4);

  /* Default stack starts at end of ram */
  PROVIDE(__stack = ORIGIN(ram) + LENGTH(ram)) ;


  /* Everyone seems to copy the stuff below straight from somewhere else, so I'll do that too */

  /* Stabs debugging sections.  */
  .stab 0 : { *(.stab) }
  .stabstr 0 : { *(.stabstr) }
  .stab.excl 0 : { *(.stab.excl) }
  .stab.exclstr 0 : { *(.stab.exclstr) }
  .stab.index 0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment 0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info) *(.gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
}

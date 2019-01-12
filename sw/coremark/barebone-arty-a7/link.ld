OUTPUT_ARCH( "riscv" )
ENTRY( _start )
__Ram_end = 0x8000ffff;
SECTIONS
{
  . = 0x80000000;
  .text.init : { *(.text.init) }
  /* text: test code section */
  .text : { *(.text) }
  /* data: Initialized data segment */
  .data : { *(.data) }
  /* End of uninitalized data segement */
  .bss : { *(.bss) }
  _end = .;
}

/* Entry point symbol (defined in start.S) */
ENTRY(_start)

/*
 * Physical memory map matching system_top.vhdl:
 *   FLASH : SPI XIP program storage (reset_vec = 0x0000_0000)
 *   RAM   : 4 KiB internal SRAM (0x4000_0000 - 0x4000_0FFF)
 */
MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 2M
    RAM   (rwx) : ORIGIN = 0x40000000, LENGTH = 4K
}

SECTIONS
{
    /* Code and read-only constants stay in Flash (executed in place via spiXipBus) */
    .text : {
        *(.text.start)      /* Force _start to address 0x0000_0000 */
        *(.text*)           /* All other executable code */
        *(.rodata*)         /* Read-only constants (const arrays, strings) */
        . = ALIGN(4);       /* Pad end of .text to a 4-byte boundary */
        _etext = .;         /* Flash address where initial .data values begin */
    } > FLASH

    /*
     * Initialized writable global/static variables (non-zero initial value).
     * Stored in Flash at _etext (LMA) and copied to RAM (_sdata.._edata, VMA)
     * by start.S at boot.
     */
    .data : AT(_etext) {
        _sdata = .;
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } > RAM

    /*
     * Uninitialized or zero-initialized writable global/static variables.
     * Takes 0 bytes in Flash; zeroed in RAM (_sbss.._ebss) by start.S at boot.
     */
    .bss : {
        _sbss = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > RAM

    /* Stack starts at the top of SRAM (0x4000_1000) and grows downward */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);

    /* Fail at link time if .data + .bss leave less than 512 bytes for the stack */
    _min_stack_size = 512;
    ASSERT((_ebss + _min_stack_size) <= _stack_top, "Error: RAM overflow - not enough space for stack!")
}
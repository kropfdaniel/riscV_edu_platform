/* -------------------------------------------------------------------------- */
/* Reset Entry Point (placed at 0x0000_0000 by link.ld)                       */
/* -------------------------------------------------------------------------- */
.section .text.start
.global _start

_start:
    /* 1. Set stack pointer (sp) to top of 4 KiB SRAM (0x4000_1000) */
    la   sp, _stack_top

    /* 2. Copy .data section from Flash (_etext) to SRAM (_sdata .. _edata) */
    la   t0, _etext         /* t0 = source pointer in Flash */
    la   t1, _sdata         /* t1 = destination start pointer in RAM */
    la   t2, _edata         /* t2 = destination end pointer in RAM */
1:
    bge  t1, t2, 2f         /* If t1 >= t2, copy is done -> jump forward to label 2 */
    lw   t3, 0(t0)          /* Read 32-bit word from Flash */
    sw   t3, 0(t1)          /* Write 32-bit word to RAM */
    addi t0, t0, 4          /* Advance Flash pointer by 4 bytes */
    addi t1, t1, 4          /* Advance RAM pointer by 4 bytes */
    j    1b                 /* Repeat loop (jump backward to label 1) */

    /* 3. Zero-initialize .bss section in SRAM (_sbss .. _ebss) */
2:
    la   t0, _sbss          /* t0 = start of .bss in RAM */
    la   t1, _ebss          /* t1 = end of .bss in RAM */
3:
    bge  t0, t1, 4f         /* If t0 >= t1, zeroing is done -> jump forward to label 4 */
    sw   zero, 0(t0)        /* Write 0 (hardwired zero register) to RAM */
    addi t0, t0, 4          /* Advance RAM pointer by 4 bytes */
    j    3b                 /* Repeat loop */

    /* 4. Configure trap vector and jump to C main() */
4:
    la   t0, trap_entry     /* Load 4-byte-aligned address of trap_entry */
    csrw mtvec, t0          /* Write to mtvec (bits [1:0] = 00 -> Direct mode) */

    call main               /* Save return address in ra and jump to main() */

hang:
    j    hang               /* Catch-all infinite loop if main() ever returns */

/* -------------------------------------------------------------------------- */
/* C-callable Helper: void enable_interrupts(void)                            */
/* -------------------------------------------------------------------------- */
.section .text
.global enable_interrupts

enable_interrupts:
    li   t0, (1 << 7)       /* Bit 7: mie.MTIE (Machine Timer Interrupt Enable) */
    csrs mie, t0            /* Set bit in mie CSR without clearing other bits */
    li   t0, (1 << 3)       /* Bit 3: mstatus.MIE (Global Machine Interrupt Enable) */
    csrs mstatus, t0        /* Set bit in mstatus CSR */
    ret                     /* Return to caller (jumps to address in ra) */

/* -------------------------------------------------------------------------- */
/* Trap Handler Entry (jumped to by SERV on any interrupt or exception)       */
/* -------------------------------------------------------------------------- */
.balign 4                   /* Required: mtvec Direct mode needs 4-byte alignment */
.global trap_entry

trap_entry:
    /*
     * Save all 16 caller-saved registers onto the stack (16 * 4 = 64 bytes).
     * Callee-saved registers (s0-s11) are automatically preserved by C functions.
     */
    addi sp, sp, -64
    sw   ra,   0(sp)
    sw   t0,   4(sp)
    sw   t1,   8(sp)
    sw   t2,  12(sp)
    sw   a0,  16(sp)
    sw   a1,  20(sp)
    sw   a2,  24(sp)
    sw   a3,  28(sp)
    sw   a4,  32(sp)
    sw   a5,  36(sp)
    sw   a6,  40(sp)
    sw   a7,  44(sp)
    sw   t3,  48(sp)
    sw   t4,  52(sp)
    sw   t5,  56(sp)
    sw   t6,  60(sp)

    /*
     * Read mcause into a0 (1st argument register in RISC-V C ABI)
     * and call C function: void trap_handler(uint32_t mcause)
     */
    csrr a0, mcause
    call trap_handler

    /* Restore all 16 caller-saved registers and release stack frame */
    lw   ra,   0(sp)
    lw   t0,   4(sp)
    lw   t1,   8(sp)
    lw   t2,  12(sp)
    lw   a0,  16(sp)
    lw   a1,  20(sp)
    lw   a2,  24(sp)
    lw   a3,  28(sp)
    lw   a4,  32(sp)
    lw   a5,  36(sp)
    lw   a6,  40(sp)
    lw   a7,  44(sp)
    lw   t3,  48(sp)
    lw   t4,  52(sp)
    lw   t5,  56(sp)
    lw   t6,  60(sp)
    addi sp, sp, 64

    /* Return from trap: restores mstatus.MIE from MPIE and jumps to mepc */
    mret
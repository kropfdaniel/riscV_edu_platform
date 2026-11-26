#include <stdint.h>

/* Assembly helper defined in start.S */
extern void enable_interrupts(void);

/* -------------------------------------------------------------------------- */
/* Memory-Mapped Peripheral Definitions                                       */
/* -------------------------------------------------------------------------- */

/* Base addresses from system_top.vhdl */
#define PIC_BASE       0x80000200u
#define TIMER_BASE     0x80000300u
#define LEDS_BASE      0x80000800u

/* PIC (Read-Only): bit 0 = uart_irq, bit 1 = timer_irq */
#define PIC_REG        ((volatile uint32_t *)PIC_BASE)
#define PIC_TIMER_IRQ  (1u << 1)

/*
 * Timer16 (Single 32-bit register at 0x8000_0300):
 *   Bits [31:16] RELOAD   : 16-bit down-counter reload value
 *   Bit  [8]     IRQ_PEND : Interrupt pending flag (Write-1-to-Clear)
 *   Bits [7:4]   PRESCALE : 2^N clock divider (0 = /1 .. 15 = /32768)
 *   Bit  [2]     IRQ_EN   : Interrupt output enable
 *   Bit  [1]     MODE     : 0 = One-shot, 1 = Periodic
 *   Bit  [0]     TIMER_EN : 1 = Running, 0 = Halted
 */
#define TIMER_REG      ((volatile uint32_t *)TIMER_BASE)
/* Byte 1 (offset +1) targets SEL_I(1) / DAT_I(8) to clear IRQ_PEND without touching config bits */
#define TIMER_IRQ_CLR  ((volatile uint8_t  *)(TIMER_BASE + 1u))

#define TIMER_EN       (1u << 0)
#define TIMER_PERIODIC (1u << 1)
#define TIMER_IRQ_EN   (1u << 2)

/*
 * LED Matrix (2 KiB address space):
 *   Offset 0x400 sets ADDR_I(10) = '1' (pixel-based mode).
 *   Each pixel n (0..119) is word-aligned at offset 0x400 + 4*n.
 *   LED 11 is column 0, row 11 -> immediately visible on nRed(0)/nGreen(0)/nBlue(0) after reset.
 */
#define LED_PIXEL(n)   ((volatile uint32_t *)(LEDS_BASE + 0x400u + ((n) * 4u)))
#define TEST_LED       11u

/* RGB bit encoding for leds.vhdl: bit 2 = Red, bit 1 = Green, bit 0 = Blue */
#define COLOR_OFF      0x0u
#define COLOR_BLUE     0x1u
#define COLOR_GREEN    0x2u
#define COLOR_RED      0x4u

/* RISC-V mcause value: bit 31 = 1 (async interrupt), code 7 = Machine Timer Interrupt */
#define MCAUSE_MTI     0x80000007u

/*
 * Timer period equation: T_irq = ((RELOAD + 1) * 2^PRESCALE) / 50 MHz
 *   -DSIM (GHDL) : ((1000 + 1) * 1)     / 50 MHz = ~20 us  (fits well inside 1 ms oneKhzTick)
 *   Hardware     : ((1525 + 1) * 32768) / 50 MHz = ~1.000 s
 */
#ifdef SIM
  #define TIMER_PRESCALE 0u
  #define TIMER_RELOAD   1000u
#else
  #define TIMER_PRESCALE 15u
  #define TIMER_RELOAD   1525u
#endif

/* Toggled on every timer interrupt (placed in .bss, initialized to 0 by start.S) */
static volatile uint32_t led_state = 0;

/* -------------------------------------------------------------------------- */
/* Trap Handler (called from trap_entry in start.S)                           */
/* -------------------------------------------------------------------------- */
void trap_handler(uint32_t mcause) {
    if (mcause == MCAUSE_MTI) {
        /* Confirm via PIC that Timer16 is the active interrupt source */
        if ((*PIC_REG) & PIC_TIMER_IRQ) {
            /* Clear IRQ_PEND first so timer_irq deasserts before mret */
            *TIMER_IRQ_CLR = 1u;

            /* Toggle LED 11 between Red and Green */
            led_state ^= 1u;
            *LED_PIXEL(TEST_LED) = led_state ? COLOR_RED : COLOR_GREEN;
        }
    } else {
        /*
         * Synchronous exception (e.g., misaligned access) or unexpected trap.
         * Turn LED 11 Blue as a visual fault indicator and halt.
         */
        *LED_PIXEL(TEST_LED) = COLOR_BLUE;
        while (1) {
        }
    }
}

/* -------------------------------------------------------------------------- */
/* Main Program                                                               */
/* -------------------------------------------------------------------------- */
int main(void) {
    /* Ensure LED 11 starts OFF */
    *LED_PIXEL(TEST_LED) = COLOR_OFF;

    /*
     * Atomically configure RELOAD, PRESCALE, IRQ_EN, Periodic mode,
     * and set TIMER_EN (0 -> 1 transition loads the counter and starts it).
     */
    *TIMER_REG = (TIMER_RELOAD << 16) |
                 (TIMER_PRESCALE << 4) |
                 TIMER_IRQ_EN |
                 TIMER_PERIODIC |
                 TIMER_EN;

    /* Enable Machine Timer Interrupt (mie.MTIE) and global interrupts (mstatus.MIE) */
    enable_interrupts();

    /* Idle forever; all work happens in trap_handler() */
    while (1) {
    }
}
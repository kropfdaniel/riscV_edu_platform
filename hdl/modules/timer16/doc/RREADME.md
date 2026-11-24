# Wishbone 16-Bit Low-Power Interrupt Timer

## Overview
This module provides a fully synchronous, 32-bit Wishbone Classic compatible 16-bit down-counter interrupt timer (`timer16`).

The core supports one-shot and periodic operating modes, a $2^N$ power-of-2 clock prescaler, and Write-1-to-Clear (W1C) interrupt handling within a single 32-bit register. Both the prescaler and main counter are frozen whenever `TIMER_EN` is `0` to minimize dynamic switching power.

## Hardware Integration
To integrate this module into your system:
1. Connect `CLK_I`, `RST_I`, and the standard 32-bit Wishbone Classic signals (`ADDR_I`, `DAT_I`, `DAT_O`, `SEL_I`, `CYC_I`, `STB_I`, `WE_I`, `CTI_I`, `ACK_O`, `ERR_O`) to your interconnect.
2. Configure the `BaseAddress` generic to map the module's 4-byte register space in your system address map.
3. Connect the `timer_irq` output to your processor's timer interrupt input or interrupt controller.

## Software Usage Guide

### Register Map
The module occupies 4 bytes of address space (a single 32-bit register) and supports byte-enable accesses via `SEL_I` (`sb`, `sh`, `sw`).

| Offset | Register | Bits  | Field      | Access | Description                                                           |
|--------|----------|-------|------------|--------|-----------------------------------------------------------------------|
| `0x00` | `TIMER`  | 31:16 | `RELOAD`   | R/W    | 16-bit counter reload value (buffered while `TIMER_EN` = 1)           |
|        |          | 15:9  | Reserved   | R/O    | Read as 0                                                             |
|        |          | 8     | `IRQ_PEND` | R/W1C  | Interrupt pending flag. Set by hardware on expiry; write 1 to clear   |
|        |          | 7:4   | `PRESCALE` | R/W    | Power-of-2 clock prescaler (`0` = /1, `1` = /2, ..., `15` = /32768)   |
|        |          | 3     | Reserved   | R/O    | Read as 0                                                             |
|        |          | 2     | `IRQ_EN`   | R/W    | Interrupt output enable (`1` = enabled, `0` = masked)                 |
|        |          | 1     | `MODE`     | R/W    | `0` = One-shot (auto-clears `TIMER_EN`), `1` = Periodic (auto-reload) |
|        |          | 0     | `TIMER_EN` | R/W    | `1` = Timer enabled, `0` = Timer halted (counters frozen)             |

**Runtime Behavior Notes:**
* **Atomic Start (`TIMER_EN` `0 -> 1`):** Resets the prescaler to `0` and loads the counter from `RELOAD` on the same clock edge (using the incoming bus bytes if `SEL_I(3:2)` are asserted, otherwise the stored `RELOAD` value).
* **Buffered Reload:** Writing to `RELOAD` while `TIMER_EN = 1` does not interrupt the active countdown; the new value takes effect on the next auto-reload (periodic mode) or next restart.
* **Prescaler Updates:** Changing `PRESCALE` while `TIMER_EN = 1` takes effect immediately. Disable the timer first for deterministic timing.

### Using the Timer

1. **Configure and Start (Atomic 32-bit Write):**
   Write a single 32-bit word (`sw`) to `BaseAddress + 0x00` containing `RELOAD`, `PRESCALE`, `IRQ_EN`, `MODE`, and `TIMER_EN = 1`.
   *(Example: writing `0xC34F0007` starts a periodic timer with `RELOAD = 49999`, `PRESCALE = 0`, and `IRQ_EN = 1`.)*
2. **Service and Clear the Interrupt:**
   When the counter expires, hardware sets `IRQ_PEND = 1` and asserts `timer_irq` (if `IRQ_EN = 1`). In your ISR, clear `IRQ_PEND` using a single 8-bit store (`sb`) of `0x01` to `BaseAddress + 0x01` (`SEL_I = "0010"`). This clears the flag without disturbing `TIMER_EN` or `RELOAD`.
3. **Update Period While Running (Optional):**
   In periodic mode, perform a 16-bit store (`sh`) to `BaseAddress + 0x02` (`SEL_I = "1100"`) to stage a new `RELOAD` value for the next cycle.
4. **Polling Mode (Optional):**
   Set `IRQ_EN = 0` and poll bit 8 (`IRQ_PEND`) until it reads `1`, then clear it via `BaseAddress + 0x01`.
5. **Stop the Timer:**
   In one-shot mode (`MODE = 0`), `TIMER_EN` clears automatically on expiry. In periodic mode, write `0` to bit 0 at `BaseAddress + 0x00` (`sb`) to halt the counters.

### Prescaler & Period Calculation
The `PRESCALE` field selects a power-of-2 divider from the main Wishbone system clock (`CLK_I`), and the 16-bit down-counter fires after `RELOAD + 1` prescaler ticks.

**Formulas:**
* `f_tick = CLK_I / (2^PRESCALE)`
* `T_irq  = ((RELOAD + 1) * 2^PRESCALE) / CLK_I`

*Examples (50 MHz system clock):*
* **1 ms period:** Set `PRESCALE = 0` (`/1`) and `RELOAD = 49999` (`0xC34F`).
* **~1 s period:** Set `PRESCALE = 10` (`/1024`) and `RELOAD = 48827` (`0xBEBB`).
* **Maximum period (~42.95 s):** Set `PRESCALE = 15` (`/32768`) and `RELOAD = 65535` (`0xFFFF`).
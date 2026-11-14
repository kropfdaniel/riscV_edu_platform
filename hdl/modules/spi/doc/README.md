# Wishbone SPI Master Controller

## Overview
This module provides a fully synchronous, 32-bit Wishbone Classic compatible SPI Master interface.

The core supports dynamic runtime configuration of Clock Polarity (CPOL), Clock Phase (CPHA), and bit ordering (LSB/MSB first), allowing communication with mixed-mode SPI devices on the same bus.

## Hardware Integration
To integrate this module into your system:
1. Connect the `CLK_I`, `RST_I`, and standard 32-bit Wishbone signals to your interconnect.
2. Map the module's `BaseAddress` in your interconnect address decoder.
3. Route the external physical pins (`spiClk`, `spiMoSi`, `spiMiSo`, `spiNCs1`, `spiNCs2`) to your top-level FPGA constraints.

## Software Usage Guide

### Register Map
The module occupies 16 bytes of address space. The registers are hardware-locked against writes during active transactions to prevent corruption.

| Offset | Register | Bits  | Field     | Access | Description                                 |
|--------|----------|-------|-----------|--------|---------------------------------------------|
| `0x00` | `SPI_CR` | 31:16 | `CLK_DIV` | R/W    | 16-bit Clock Divider value                  |
|        |          | 15:4  | Reserved  | R/O    | Read as 0                                   |
|        |          | 3     | `LSBF`    | R/W    | 1 = LSB First, 0 = MSB First                |
|        |          | 2     | `CPHA`    | R/W    | Clock Phase                                 |
|        |          | 1     | `CPOL`    | R/W    | Clock Polarity                              |
|        |          | 0     | `SPI_EN`  | R/W    | 1 = Enable clock divider tick, 0 = Disable  |
| `0x04` | `SPI_SR` | 31:1  | Reserved  | R/O    | Read as 0                                   |
|        |          | 0     | `BUSY`    | R/O    | 1 = Transaction in progress, bus locked     |
| `0x08` | `SPI_DR` | 31:8  | Reserved  | R/O    | Read as 0                                   |
|        |          | 7:0   | `DATA`    | R/W    | Write triggers TX, Read yields RX byte      |
| `0x0C` | `SPI_SS` | 31:2  | Reserved  | R/O    | Read as 0                                   |
|        |          | 1     | `nCS2`    | R/W    | State of spiNCs2 pin                        |
|        |          | 0     | `nCS1`    | R/W    | State of spiNCs1 pin                        |

### Executing a Transaction

1. **Configure the Bus:** 
   Write to `SPI_CR` (0x00) to set `CLK_DIV`, `LSBF`, `CPHA`, and `CPOL`. Ensure `SPI_EN` is set to `1`.
2. **Assert Chip Select:**
   Write to `SPI_SS` (0x0C) to pull the target device's active-low Chip Select line down (e.g., write `0x02` to pull `nCS1` low while keeping `nCS2` high).
3. **Transmit/Receive Byte:**
   Write the 8-bit payload to `SPI_DR` (0x08). This automatically triggers the transceiver, toggling the SPI clock and shifting the data bits.
4. **Wait for Completion:**
   Poll `SPI_SR` (0x04) bit 0 (`BUSY`). Wait in a software loop until this bit reads `0`.
5. **Read Received Data:**
   Read from `SPI_DR` (0x08) to retrieve the byte shifted in from the MISO line during the transaction.
6. **De-assert Chip Select:**
   Once all necessary bytes for the command are transferred, write to `SPI_SS` to pull the Chip Select lines back high (e.g., write `0x03`).

### Clock Divider Calculation
The `CLK_DIV` value determines the SPI SCK frequency based on the main Wishbone system clock (`CLK_I`). The internal tick generator toggles at twice the target SPI frequency to support edge routing.

**Formula:**
`SPI_SCK = CLK_I / (2 * (CLK_DIV + 1))`

*Example:* If the SoC runs at 50 MHz and you want a 25 MHz SPI clock, set `CLK_DIV` to `0`. For a 1 MHz SPI clock, set `CLK_DIV` to `24`.
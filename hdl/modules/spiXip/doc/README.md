# SPI Execute-In-Place (XIP) Subsystem

A read-only Wishbone to SPI Flash controller subsystem designed to fetch instructions directly from an external SPI Flash memory. When an address is latched onto the Wishbone interface, the module starts the SPI transaction, fetches the required data, and provides it to the bus.

## Specifications

* **System Clock:** 50 MHz synchronous
* **SPI Clock (SCK):** 25 MHz (generated via clock division)
* **Target Memory:** Standard SPI Flash (e.g., MX25R3235F)
* **SPI Mode:** Mode 0 (CPOL=0, CPHA=0)
* **Addressing:** 24-bit physical addressing
* **Command:** Standard Read (`0x03`)

## Modules

1. **`spiXip_pkg.vhd`**
   Defines global package constants, including `C_FLASH_ADDR_WIDTH = 24`.

2. **`spiXipBus.vhd`**
   Provides a read-only, classic Wishbone interface. Handles address decoding between the logical Wishbone space and physical Flash space, masks upper address bits, and generates single-cycle `ACK_O` and `ERR_O` pulses.

3. **`spiXipController.vhd`**
   Implements the protocol FSM. Sends the `0x03` read command, transmits the 24-bit address, and receives 32 bits of instruction data using single-cycle `byteDone` pulses.

4. **`spiByteTransceiver.vhd`**
   The physical layer shift register. Toggles the SPI `SCK` pin on state transitions without external tick counters, shifting `MOSI` on falling edges and sampling `MISO` on rising edges.
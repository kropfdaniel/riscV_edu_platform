--------------------------------------------------------------------------------
--! @author     Daniel Kropf
--! @copyright  MIT License
--! @brief      Global constants package for the SPI Execute-In-Place (XIP) subsystem.
--!
--! Centralizes system-wide hardware parameters to ensure architectural consistency 
--! Defines the physical interface widths required by the external SPI Flash (e.g., MX25R3235F).
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package spiXip_pkg is
    --! Physical address width required by the MX25R3235F SPI Flash
    constant C_FLASH_ADDR_WIDTH : integer := 24;
end package spiXip_pkg;
--------------------------------------------------------------------------------
--! @author Daniel Kropf
--! @copyright MIT License
--! @brief SPI Flash Execute-in-Place (XIP) module
--!
--! Provides a read-only, classic Wishbone interface for executing code in place, 
--! fetching instructions stored on an external Flash memory connected via SPI.
--!
--! This module requires a 50 MHz synchronous system clock, allowing the 
--! lower-level transceiver to generate a 25 MHz SPI SCK. It is specifically 
--! designed for standard SPI Flash memories (e.g., MX25R3235F) operating in 
--! SPI Mode 0 (CPOL=0, CPHA=0), supporting only 24-bit physical addressing 
--! and the standard 1-bit read command (0x03).
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.spiXip_pkg.all;

entity spiXipBus is
    generic (
        --! Number of Data Bits. Only 32-bit data width is currently supported.
        DataBits    : integer                                   := 32;
        --! Number of Address Bits.
        AddrBits    : integer                                   := 32;
        --! Base address of this module (used by interconnect, not internally).
        BaseAddress : std_logic_vector( AddrBits-1 downto 0)    := std_logic_vector(to_unsigned(0, AddrBits));
        --! Number of lower address bits used by the Flash memory (21 bits = 2MiB space)
        FlashAddrWidth : integer range 1 to C_FLASH_ADDR_WIDTH  := 21
    );
    port (
        -- Wishbone Signals
        --! clock input
        CLK_I       : in std_logic;
        --! reset input
        RST_I       : in std_logic;
        -- DAT_I is not supported (read only)
        --! data output
        DAT_O       : out std_logic_vector(DataBits - 1 downto 0);
        -- TAGD_I and TAGD_O are not implemented
        --! acknowledge output
        ACK_O       : out std_logic;
        --! address input
        ADDR_I      : in std_logic_vector(AddrBits - 1 downto 0);
        --! cycle input
        CYC_I       : in std_logic;
        --! error output
        ERR_O       : out std_logic;
        -- LOCK_I is not used in this module
        -- RTY_I is not implemented
        -- SEL_I is not used (module always returns a full word)
        --! strobe input
        STB_I       : in std_logic;
        -- TGA_O and TGC_O are not implemented
        --! write enable input. Only read supported.
        WE_I        : in std_logic;
        --! Cycle type input. Only Classic cycle type "000" supported.
        CTI_I       : in std_logic_vector(2 downto 0);
        -- BTE_I is not used in this module

        -- External
        --! Chip select control line for the Flash chip
        spiNCs      : out std_logic;
        --! SPI Serial Clock
        spiClk      : out std_logic;
        --! Master Out, Slave In
        spiMoSi     : out std_logic;
        --! Master In, Slave Out (from Flash)
        spiMiSo     : in std_logic;
        --! Flash Write Protect (low active)
        flashWpN    : out std_logic;
        --! Flash Reset (low active)
        flashResetN : out std_logic
    );
end entity spiXipBus;

architecture platformIndependent of spiXipBus is
    --! acknowledge register
    signal s_ackReg                 : std_logic;
    --! acknowledge after succesful spi read of flash
    signal s_spiReadAck             : std_logic;
    --! error register
    signal s_errorReg               : std_logic;
    --! flash address register
    signal s_flashAddrReg           : std_logic_vector( C_FLASH_ADDR_WIDTH-1 downto 0 );
    --! flag if CYC_I and STB_I are set and the address on the bus is within the address space for this module
    signal s_isMyTransaction        : std_logic;
    --! flag if the transaction is a read and of type classic (CTI_I="000")
    signal s_isCorrectTransaction   : std_logic;
    --! Delay register to detect the start of a transaction
    signal s_isCorrectTransaction_d : std_logic;
    --! flag to start an spi byte transaction from spiXipController to spiByteTransceiver
    signal s_startByteTransaction   : std_logic;
    --! Byte to send onto SPI from spiXipController to spiByteTransceiver
    signal s_txByte                 : std_logic_vector(7 downto 0);
    --! Byte received onto SPI from spiByteTransceiver to spiXipController
    signal s_rxByte                 : std_logic_vector(7 downto 0);
    --! Flag that a SPI Byte transaction is ongoing from spiByteTransceiver to spiXipController
    signal s_busyByteTransaction    : std_logic;
    --! Flag which indicates when the spi controller should start to read a byte.
    signal s_startRead              : std_logic;
begin
    ERR_O <= s_errorReg;
    ACK_O <= s_ackReg;

    -- if the address on the bus is within the address space for this module
    s_isMyTransaction <= CYC_I and STB_I when ADDR_I( AddrBits-1 downto FlashAddrWidth) = BaseAddress(AddrBits-1 downto FlashAddrWidth) else '0';
    -- if it is a read and classic cycle type
    s_isCorrectTransaction <= s_isMyTransaction when WE_I = '0' and CTI_I = "000" else '0';

    -- Set the unused falsh address lines to 0. 
    unusedFlashAddressLines : if FlashAddrWidth < C_FLASH_ADDR_WIDTH generate
        s_flashAddrReg(C_FLASH_ADDR_WIDTH-1 downto FlashAddrWidth) <= (others => '0');
    end generate unusedFlashAddressLines;

    process(CLK_I) 
    begin
        if rising_edge(CLK_I) then 
            if RST_I then
                s_errorReg  <= '0';
                s_ackReg    <= '0';
                s_startRead <= '0';
            else
                s_isCorrectTransaction_d <= s_isCorrectTransaction;
                s_startRead <= '0'; -- Default
                s_errorReg <= not(s_errorReg) and s_isMyTransaction and not(s_isCorrectTransaction);
                s_ackReg   <= not(s_ackReg) and s_isCorrectTransaction and s_spiReadAck;
                
                if (s_isCorrectTransaction = '1' and s_isCorrectTransaction_d = '0') then
                    -- when the transaction arrives, store the flash address
                    s_flashAddrReg(FlashAddrWidth-1 downto 0) <= ADDR_I(FlashAddrWidth-1 downto 0);
                    s_startRead <= '1';
                end if;
            end if;
        end if;
    end process;

    --! Low-level SPI Mode 0 (CPOL=0 and CPHA=0) physical datapath and transceiver engine.
    Transceiver : entity work.spiByteTransceiver(rtl)
        port map (
            clock                   => CLK_I,
            reset                   => RST_I,
            startByteTransaction    => s_startByteTransaction,
            txByte                  => s_txByte,
            rxByte                  => s_rxByte,
            busyByteTransaction     => s_busyByteTransaction,
            spiClk                  => spiClk,
            spiMoSi                 => spiMoSi,
            spiMiSo                 => spiMiSo,
            flashWpN                => flashWpN,
            flashResetN             => flashResetN
        );

    --! Protocol Controller for SPI Flash Execute-in-Place (XIP) reads.
    Controller : entity work.spiXipController(rtl)
        generic map (
            DataBits => DataBits,
            AddrBits => 24
        )
        port map (
            clock                   => CLK_I,
            reset                   => RST_I,
            startRead               => s_startRead,
            readAddress             => s_flashAddrReg,
            readData                => DAT_O,
            readAck                 => s_spiReadAck,
            startByteTransaction    => s_startByteTransaction,
            txByte                  => s_txByte,
            rxByte                  => s_rxByte,
            busyByteTransaction     => s_busyByteTransaction,
            spiNCs                  => spiNCs            
        );
    
end architecture;

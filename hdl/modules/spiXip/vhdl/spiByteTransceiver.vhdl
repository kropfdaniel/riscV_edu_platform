--------------------------------------------------------------------------------
--! @author     Daniel Kropf
--! @brief      Low-level SPI Mode 0 (CPOL=0 and CPHA=0) physical datapath and transceiver engine.
--!
--! Manages byte-level transmission and reception.
--! Optimizes MISO sampling and MOSI shifting for standard 1-bit SPI communication with 
--! external SPI Flash memory (e.g., MX25R3235F).
--! SCK runs on half the Clock speed.
--! This module expects a 50MHz clock input which results in 25MHz SCK.
--! This is to guarantee the maximum SCK of the MX25R3235F which is 33MHz for 
--! 1-Bit read command (0x03).
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spiByteTransceiver is
    port (
        --! System clock domain. Expected 50MHz clock
        clock                   : in std_logic;
        --! Active-high system reset
        reset                   : in std_logic;

        -- Control Interface (Driven by the SPI FSM)
        --! Flag to start shifting out/in a full byte
        startByteTransaction    : in std_logic;
        --! Parallel byte data to transmit out via MOSI
        txByte                  : in std_logic_vector(7 downto 0);
        --! Parallel byte data accumulated from MISO
        rxByte                  : out std_logic_vector(7 downto 0);
        --! High while a byte shift transaction is active
        busyByteTransaction     : out std_logic;

        -- External SPI Physical Pins
        --! SPI Serial Clock
        spiClk                  : out std_logic;
        --! Master Out, Slave In
        spiMoSi                 : out std_logic;
        --! Master In, Slave Out (from Flash)
        spiMiSo                 : in std_logic;
        --! Flash Write Protect (low active)
        flashWpN                : out std_logic;
        --! Flash Reset (low active)
        flashResetN             : out std_logic
    );
end entity spiByteTransceiver;

architecture rtl of spiByteTransceiver is
    --! FSM States definition for SPI transaction lifecycle
    type t_state is (
        --! Waits on startByteTransaction signal to start a transaction 
        IDLE,
        --! SPI Clock is high. Sample MISO signal
        SCK_HIGH,
        --! SPI Clock is low. Shift next bit out. Check if all the bits have been shifted out
        SCK_LOW
    );
    --! Current state register for the SPI FSM
    signal s_state : t_state;

    --! Shift register holding outgoing transmission data and accumulating incoming received data
    signal s_shiftReg : std_logic_vector(7 downto 0);
    --! Bit counter tracking data bits remaining (counts down from 7 to 0)
    signal s_bitCounter : unsigned(2 downto 0);

    signal s_miso_sampled : std_logic;
begin
    flashWpN    <= '0'; -- Only read of the flash data is performmed
    flashResetN <= '1';
    spiMoSi     <= s_shiftReg(7); -- Shift out MSB
    rxByte      <= s_shiftReg;    -- After transaction s_shiftReg holds the received data.

    --! Step through the SPI Mode 0 phases. 
    --! Samples MISO directly into a register on the rising 
    --! edge of the SPI clock (SCK_HIGH) and updates the MOSI shift register 
    --! on the falling edge (SCK_LOW), decrementing the bit counter until 
    --! the byte transaction is complete.
    spi_transceiver : process (clock)
    begin
        if rising_edge(clock) then
            if reset then
                s_state             <= IDLE;
                busyByteTransaction <= '0';
                spiClk              <= '0';
                s_shiftReg          <= (others => '0');
            else
                case s_state is
                    when IDLE =>
                        spiClk <= '0';
                        if startByteTransaction then
                            busyByteTransaction <= '1';
                            s_shiftReg          <= txByte;
                            s_bitCounter        <= to_unsigned(7, 3);
                            s_state             <= SCK_HIGH;
                        else
                            busyByteTransaction <= '0';
                        end if;
                    when SCK_HIGH =>
                        spiClk         <= '1';     -- Flash chip samples MOSI here
                        s_miso_sampled <= spiMiSo; -- Sample MISO here
                        s_state        <= SCK_LOW;
                    when SCK_LOW =>
                        spiClk     <= '0';                                     -- Flash chip updates its MISO here
                        s_shiftReg <= s_shiftReg(6 downto 0) & s_miso_sampled; -- Shift left

                        if s_bitCounter = 0 then
                            s_state <= IDLE; -- Byte complete
                            busyByteTransaction <= '0';
                        else
                            s_bitCounter <= s_bitCounter - 1;
                            s_state      <= SCK_HIGH;
                        end if;
                    when others =>
                        -- Safe state fallback
                        s_state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end architecture;
--------------------------------------------------------------------------------
--! @author    Daniel Kropf
--! @copyright MIT License
--! @brief     Configurable low-level SPI physical datapath and transceiver.
--!
--! Manages byte-level transmission and reception. This transceiver supports 
--! dynamic runtime configuration of Clock Polarity (CPOL), Clock Phase (CPHA), 
--! and Bit Order (LSB First). 
--!  
--! The internal architecture completely decouples the data shift 
--! and sample execution from the bit-counting FSM. Edges are mathematically 
--! routed using a base clock and an external clock divider tick, 
--! synthesizing to highly efficient LUT-based multiplexers.
--!
--! **Note:** The configuration inputs (cpol, cpha, lsbf) must remain strictly 
--!           static while busyByteTransaction is '1' to prevent clock glitches.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spiByteTransceiver is
    port (
        --! System clock domain. Expected 50MHz clock
        clock                   : in  std_logic;
        --! Active-high system reset
        reset                   : in  std_logic;

        -- Control Interface
        --! Flag to start shifting out/in a full byte
        startByteTransaction    : in  std_logic;
        --! Parallel byte data to transmit out via MOSI
        txByte                  : in  std_logic_vector(7 downto 0);
        --! Parallel byte data accumulated from MISO
        rxByte                  : out std_logic_vector(7 downto 0);
        --! High while a byte shift transaction is active
        busyByteTransaction     : out std_logic;
        --! Clock Divider tick input. indicates to toggle SPI Clock line.
        clkDivTick              : in  std_logic;
        --! CPOL configuration input
        cpol                    : in  std_logic;
        --! CPHA configuration input
        cpha                    : in  std_logic;
        --! LSB first configuration input
        lsbf                    : in  std_logic;

        -- External SPI Physical Pins
        --! SPI Serial Clock
        spiClk                  : out std_logic;
        --! Master Out, Slave In
        spiMoSi                 : out std_logic;
        --! Master In, Slave Out
        spiMiSo                 : in  std_logic
    );
end entity spiByteTransceiver;

architecture rtl of spiByteTransceiver is
    --! Shift register holding outgoing transmission data and accumulating incoming received data
    signal s_shiftReg       : std_logic_vector(7 downto 0);
    --! Bit counter tracking data bits remaining (counts down from 7 to 0)
    signal s_bitCounter     : unsigned(2 downto 0);
    --! Internal clock, always idles at '0'
    signal s_baseClk        : std_logic;
    --! flag that indicates when the SPI CLK has a leading edge
    signal s_leadingEdge    : std_logic;
    --! flag that indicates when the SPI CLK has a trailling edge
    signal s_trailingEdge   : std_logic;
    --! flag to indicate when to sample the MISO signal
    signal s_sampleEn       : std_logic;
    --! flag to indicate when to shift the next bit out
    signal s_shiftEn        : std_logic;
    --! stores the sampleded Miso signal
    signal s_miSoSampledReg : std_logic;
begin
    spiMoSi <= s_shiftReg(0) when lsbf else s_shiftReg(7); -- Shift out MSB or LSB
    rxByte  <= s_shiftReg;    -- After transaction s_shiftReg holds the received data.

    s_leadingEdge  <= clkDivTick and not(s_baseClk);
    s_trailingEdge <= clkDivTick and     s_baseClk;

    s_sampleEn <= (s_leadingEdge  and not(cpha) ) or (s_trailingEdge and cpha); 
    s_shiftEn  <= (s_trailingEdge and not(cpha) ) or (s_leadingEdge  and cpha); 

    spiClk  <= s_baseClk xor CPOL;

    --! Steps through the a single SPI byte transaction
    spi_transceiver : process (clock)
    begin
        if rising_edge(clock) then
            if reset then
                busyByteTransaction <= '0';
                s_baseClk           <= '0';
                s_shiftReg          <= (others => '0');
                s_bitCounter        <= (others => '0');
            else
                if busyByteTransaction = '0' then
                    s_baseClk <= '0'; 

                    if startByteTransaction then 
                        busyByteTransaction <= '1';
                        s_bitCounter        <= to_unsigned(7, 3);
                        s_shiftReg          <= txByte;
                    end if;
                else 
                    if clkDivTick then
                        s_baseClk <= not(s_baseClk);
                    end if;

                    if s_sampleEn then
                        s_miSoSampledReg <= spiMiSo;
                    end if;

                    if s_shiftEn = '1' and not(cpha = '1' and s_bitCounter = 7) then -- if cpha=1 skip the first shift as the miso pin is already correct
                        if lsbf then
                            -- shift right, miso feeds into MSB
                            s_shiftReg <= s_miSoSampledReg & s_shiftReg(7 downto 1);
                        else
                            -- shift left, miso feeds into LSB
                            s_shiftReg <= s_shiftReg(6 downto 0) & s_miSoSampledReg;
                        end if;
                    end if;

                    if s_trailingEdge then
                        if s_bitCounter = 0 then
                            busyByteTransaction <= '0';

                            -- CPHA=1: Shift the final bit directly from the MISO pin
                            if cpha = '1' then
                                if lsbf = '1' then
                                    s_shiftReg <= spiMiSo & s_shiftReg(7 downto 1);
                                else
                                    s_shiftReg <= s_shiftReg(6 downto 0) & spiMiSo;
                                end if;
                            end if;
                        else 
                            s_bitCounter <= s_bitCounter - 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;
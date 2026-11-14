--------------------------------------------------------------------------------
--! @author    Daniel Kropf
--! @copyright MIT License
--! @brief     Wishbone-compatible SPI Master controller and configuration wrapper.
--!
--! Acts as the bridge between a 32-bit Wishbone Classic interconnect 
--! and the physical `spiByteTransceiver`. It provides a memory-mapped 
--! register interface for software-driven SPI configuration, chip 
--! select assertion, and data transactions.
--!
--! During transactions (busy flag active) all writes to the registers
--! are ignored.
--!
--! SPI transactions are triggered by writing to DATA register
--!
--! Clock Divider Equation: `SPI_SCK = CLK_I / (2 * (CLK_DIV + 1))`
--!
--! ### Register Map
--! 
--! | Offset | Register | Bits  | Field     | Access | Description                                 |
--! |--------|----------|-------|-----------|--------|---------------------------------------------|
--! | `0x00` | `SPI_CR` | 31:16 | `CLK_DIV` | R/W    | 16-bit Clock Divider value                  |
--! |        |          | 15:4  | Reserved  | R/O    | Read as 0                                   |
--! |        |          | 3     | `LSBF`    | R/W    | 1 = LSB First, 0 = MSB First                |
--! |        |          | 2     | `CPHA`    | R/W    | Clock Phase                                 |
--! |        |          | 1     | `CPOL`    | R/W    | Clock Polarity                              |
--! |        |          | 0     | `SPI_EN`  | R/W    | 1 = Enable clock divider tick, 0 = Disable  |
--! | `0x04` | `SPI_SR` | 31:1  | Reserved  | R/O    | Read as 0                                   |
--! |        |          | 0     | `BUSY`    | R/O    | 1 = Transaction in progress, bus locked     |
--! | `0x08` | `SPI_DR` | 31:8  | Reserved  | R/O    | Read as 0                                   |
--! |        |          | 7:0   | `DATA`    | R/W    | Write triggers TX, Read yields RX byte      |
--! | `0x0C` | `SPI_SS` | 31:2  | Reserved  | R/O    | Read as 0                                   |
--! |        |          | 1     | `nCS2`    | R/W    | State of spiNCs2 pin                        |
--! |        |          | 0     | `nCS1`    | R/W    | State of spiNCs1 pin
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spiBus is
    generic (
        --! Number of Wishbone Data Bits. Only 32-bit data width is currently supported.
        DataBits    : integer                                   := 32;
        --! Number of Wishbone Address Bits.
        AddrBits    : integer                                   := 32;
        --! Base Wishbone address of this module (used by interconnect, not internally).
        BaseAddress : std_logic_vector(AddrBits-1 downto 0)   := (AddrBits => '0')
    );
    port (
        -- Wishbone Signals
        --! clock input
        CLK_I       : in  std_logic;
        --! reset input
        RST_I       : in  std_logic;
        --! data input
        DAT_I       : in  std_logic_vector(DataBits-1 downto 0);
        --! data output
        DAT_O       : out std_logic_vector(DataBits-1 downto 0);
        -- TAGD_I and TAGD_O are not implemented
        --! acknowledge output
        ACK_O       : out std_logic;
        --! address input
        ADDR_I      : in  std_logic_vector(AddrBits-1 downto 0);
        --! cycle input
        CYC_I       : in  std_logic;
        --! error output
        ERR_O       : out std_logic;
        -- LOCK_I is not used in this module
        -- RTY_I is not implemented
        --! select input
        SEL_I       : in  std_logic_vector((DataBits/8)-1 downto 0);
        --! strobe input
        STB_I       : in  std_logic;
        -- TGA_O and TGC_O are not implemented
        --! write enable input
        WE_I        : in  std_logic;
        --! Cycle type input. Only Classic cycle type "000" supported.
        CTI_I       : in  std_logic_vector(2 downto 0);
        -- BTE_I is not used in this module

        -- External
        --! Chip select 1 control line
        spiNCs1      : out std_logic;
        --! Chip select 2 control line
        spiNCs2      : out std_logic;
        --! SPI Serial Clock
        spiClk      : out std_logic;
        --! Master Out, Slave In
        spiMoSi     : out std_logic;
        --! Master In, Slave Out
        spiMiSo     : in std_logic
    );
end entity spiBus;

architecture platformIndependent of spiBus is
    --! Number of bits of the clock divider
    constant c_clkDivBits         : integer := 16;
    --! wishbone acknowledge register
    signal s_ackReg               : std_logic;
    --! wishbone error register (error happens if CTI_I/="000")
    signal s_errorReg             : std_logic;
    --! Combinatorial write enable pulse. 
    --! Asserts for exactly one clock cycle before the Wishbone ACK to prevent duplicate register writes.
    signal s_we                   : std_logic;
    --! index Register. Indexes the different SPI registers
    signal s_spiRegisterIndex     : std_logic_vector(1 downto 0);

    --! flag if CYC_I and STB_I are set and the address on the bus is within the address space for this module
    signal s_isMyTransaction      : std_logic;
    --! flag if the transaction is mine and of type classic (CTI_I="000")
    signal s_isCorrectTransaction : std_logic;

    -- 0x00: SPI_CR (Control Register)
    --! SPI Clock Divider register
    signal s_clkDivReg            : std_logic_vector(c_clkDivBits-1 downto 0);
    --! SPI LSB first register
    signal s_lsbfReg              : std_logic;
    --! SPI CPHA register
    signal s_cphaReg              : std_logic;
    --! SPI CPOL register
    signal s_cpolReg              : std_logic;
    --! SPI Enable register
    signal s_spiEnReg             : std_logic;
    
    -- 0x04: SPI_SR (Status Register) - Read Only from internal logic
    --! SPI Busy bit
    signal s_spiBusy              : std_logic;
    
    -- 0x08: SPI_DR (Data Register)
    --! SPI tx byte register
    signal s_txByteReg            : std_logic_vector(7 downto 0);
    --! SPI rx byte
    signal s_rxByte               : std_logic_vector(7 downto 0);
    
    -- 0x0C: SPI_CS (Chip Select Register)
    --! SPI nCs register
    signal s_nCsReg               : std_logic_vector(1 downto 0);

    --! flag used to indicate that a new spi byte transaction should be started
    signal s_startSpiTransaction  : std_logic;

    --! Counter to divide the clock
    signal s_clkDivCounterReg     : unsigned(c_clkDivBits-1 downto 0);
    --! flag to indicate when the SPI CLK signal should toggle
    signal s_clkDivTickReg        : std_logic;
begin
    ERR_O   <= s_errorReg;
    ACK_O   <= s_ackReg;
    spiNCs1 <= s_nCsReg(0);
    spiNCs2 <= s_nCsReg(1);

    -- if the address on the bus is within the address space for this module
    s_isMyTransaction <= (CYC_I and STB_I) when ADDR_I( AddrBits-1 downto 4 ) = BaseAddress( AddrBits-1 downto 4 ) else '0';
    -- if it is classic cycle type
    s_isCorrectTransaction <= s_isMyTransaction when CTI_I = "000" else '0'; 

    s_we <= not(s_ackReg) and s_isCorrectTransaction and WE_I;
    s_spiRegisterIndex <= ADDR_I(3 downto 2);

    --! Wishbone interface process
    makeBusRegs : process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                s_ackReg         <= '0';
                s_errorReg       <= '0';
            else
                s_ackReg   <= not(s_ackReg) and s_isCorrectTransaction;
                s_errorReg <= not(s_errorReg) and s_isMyTransaction and not(s_isCorrectTransaction);
            end if;
        end if;
    end process makeBusRegs;

    --! SPI Register write process. 
    makeSpiRegs : process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                s_clkDivReg <= (others => '0');
                s_lsbfReg   <= '0';
                s_cphaReg   <= '0';
                s_cpolReg   <= '0';
                s_spiEnReg  <= '0';
                s_txByteReg <= (others => '0');
                s_nCsReg    <= "11"; -- chip selects lines are high after reset
            else
                s_startSpiTransaction <= '0'; -- auto disable 
                if s_we = '1' and s_spiBusy = '0' then
                    case s_spiRegisterIndex is
                        when "00" => -- 0x00: SPI_CR
                            -- Byte 0: Configuration Bits
                            if SEL_I(0) = '1' then
                                s_lsbfReg  <= DAT_I(3);
                                s_cphaReg  <= DAT_I(2);
                                s_cpolReg  <= DAT_I(1);
                                s_spiEnReg <= DAT_I(0);
                            end if;
                            -- Byte 2: Lower byte of CLK_DIV (Data bits 23:16 -> CLK_DIV 7:0)
                            if SEL_I(2) = '1' then
                                s_clkDivReg(7 downto 0) <= DAT_I(23 downto 16);
                            end if;
                            -- Byte 3: Upper byte of CLK_DIV (Data bits 31:24 -> CLK_DIV 15:8)
                            if SEL_I(3) = '1' then
                                s_clkDivReg(15 downto 8) <= DAT_I(31 downto 24);
                            end if;
                        when "01" => -- 0x04: SPI_SR
                            null; -- Read-only
                        when "10" => -- 0x08: SPI_DR
                            -- Byte 0: Transmit Payload
                            if SEL_I(0) = '1' then
                                s_txByteReg           <= DAT_I(7 downto 0);
                                s_startSpiTransaction <= '1'; 
                            end if;
                        when "11" => -- 0x0C: SPI_SS
                            -- Byte 0: Chip Selects
                            if SEL_I(0) = '1' then
                                s_nCsReg <= DAT_I(1 downto 0);
                            end if;
                        when others =>
                            null;
                    end case;
                end if;
            end if;
        end if;
    end process makeSpiRegs;

    --! Wishbone data output multiplexer
    dataOut : process(all)
    begin
        DAT_O <= (others => '0'); -- Default to zeros for unmapped bits
        
        case s_spiRegisterIndex is
            when "00" => -- 0x00: SPI_CR
                DAT_O(31 downto 16) <= s_clkDivReg;
                DAT_O(3)            <= s_lsbfReg;
                DAT_O(2)            <= s_cphaReg;
                DAT_O(1)            <= s_cpolReg;
                DAT_O(0)            <= s_spiEnReg;
            when "01" => -- 0x04: SPI_SR
                DAT_O(0)            <= s_spiBusy;
            when "10" => -- 0x08: SPI_DR
                DAT_O(7 downto 0)   <= s_rxByte;
            when "11" => -- 0x0C: SPI_SS
                DAT_O(1 downto 0)   <= s_nCsReg;
            when others =>
                null;
        end case;
    end process dataOut;


    --! Divide the clock to produce tick signal
    clockDivider : process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' or s_spiEnReg = '0' then
                s_clkDivCounterReg <= to_unsigned(0, c_clkDivBits);
                s_clkDivTickReg    <= '0';
            else
                if s_clkDivCounterReg = unsigned(s_clkDivReg) then
                    s_clkDivCounterReg <= to_unsigned(0, c_clkDivBits);
                    s_clkDivTickReg    <= '1';
                else
                    s_clkDivCounterReg <= s_clkDivCounterReg + 1;
                    s_clkDivTickReg    <= '0';
                end if;
            end if;
        end if;
    end process clockDivider;

    --! low-level SPI physical datapath and transceiver
    transceiver : entity work.spiByteTransceiver(rtl)
        port map (
            clock                => CLK_I,
            reset                => RST_I,
            startByteTransaction => s_startSpiTransaction,
            txByte               => s_txByteReg,
            rxByte               => s_rxByte,
            busyByteTransaction  => s_spiBusy,
            clkDivTick           => s_clkDivTickReg,
            cpol                 => s_cpolReg,
            cpha                 => s_cphaReg,
            lsbf                 => s_lsbfReg,
            spiClk               => spiClk,
            spiMoSi              => spiMoSi,
            spiMiSo              => spiMiSo
        );
end architecture;
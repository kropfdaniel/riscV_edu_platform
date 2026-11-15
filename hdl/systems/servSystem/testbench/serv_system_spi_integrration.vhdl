-- =============================================================================
-- Author:      Daniel Kropf
-- License:     MIT
-- 
-- Description: 
--   Black-box verification testbench for the spiBus integration.
--
-- Verification Strategy (Register-Accurate Loopback):
--   1. CPU writes 0x00010001 to SPI_CR (0x00) to set CLK_DIV=1 and SPI_EN=1.
--   2. CPU writes 0x2 to SPI_SS (0x0C) to pull spiNCs(0) low (active).
--   3. CPU writes 0xA5 to SPI_DR (0x08) to trigger the transaction.
--   4. CPU executes 4 NOPs to wait for the SPI state machine to finish.
--   5. Testbench physically monitors the general-purpose SPI pins, asserting that 
--      the correct waveform for 0xA5 is generated on MOSI.
--   6. Testbench concurrently drives a return payload (0x5A) onto the MISO pin.
--   7. CPU reads SPI_DR (0x08) capturing the 0x5A payload into register x3.
--   8. CPU shifts 0x5A left by 16 bits (0x5A0000) and exports it via a load word.
--   9. The spiXip mock flash intercepts the broadcast and asserts the address matches.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spi_integration_top is
end entity tb_spi_integration_top;

architecture sim of tb_spi_integration_top is

    signal s_clk       : std_logic := '0';
    signal s_nreset    : std_logic := '0';
    signal spiNCs      : std_logic_vector(1 downto 0);
    signal spiClk      : std_logic;
    signal spiMoSi     : std_logic;
    signal spiMiSo     : std_logic := '1';
    
    signal spiXipNCs   : std_logic;
    signal spiXipClk   : std_logic;
    signal spiXipMoSi  : std_logic;
    signal spiXipMiSo  : std_logic := '1';
    signal flashWpN    : std_logic;
    signal flashResetN : std_logic;
    
    signal RxD         : std_logic := '1';
    signal TxD         : std_logic;

    constant CLK_PERIOD : time := 20 ns;

    -- Mock Flash Memory Array (RISC-V hardware config, TX, and Polling Loop)
    type rom_type is array (0 to 55) of std_logic_vector(7 downto 0);
    constant MOCK_FLASH_ROM : rom_type := (
        x"b7", x"00", x"00", x"80", -- 0x00: lui  x1, 0x80000 | x1 = 0x80000000 (Base)
        x"37", x"01", x"01", x"00", -- 0x04: lui  x2, 0x10    | x2 = 0x00010000 
        x"13", x"01", x"11", x"00", -- 0x08: addi x2, x2, 1   | x2 = 0x00010001 (EN=1, CLKDIV=1)
        x"23", x"a0", x"20", x"00", -- 0x0C: sw   x2, 0(x1)   | Write SPI_CR [0x00]
        x"13", x"01", x"20", x"00", -- 0x10: addi x2, x0, 2   | x2 = 2 (nCS(0) = 0, nCS(1) = 1)
        x"23", x"a6", x"20", x"00", -- 0x14: sw   x2, 12(x1)  | Write SPI_SS [0x0C]
        x"13", x"01", x"50", x"0a", -- 0x18: addi x2, x0, 165 | x2 = 0xA5
        x"23", x"a4", x"20", x"00", -- 0x1C: sw   x2, 8(x1)   | Write SPI_DR [0x08] -> Starts TX
        
        -- Polling Loop
        x"03", x"a2", x"40", x"00", -- 0x20: lw   x4, 4(x1)   | Read SPI_SR [0x04]
        x"e3", x"1e", x"02", x"fe", -- 0x24: bne  x4, x0, -4  | If x4 != 0 (Busy), branch to 0x20
        
        -- Export Result
        x"83", x"a1", x"80", x"00", -- 0x28: lw   x3, 8(x1)   | Read  SPI_DR [0x08] -> RX Byte
        x"93", x"91", x"01", x"01", -- 0x2C: slli x3, x3, 16  | Shift left 16 (0x150000)
        x"83", x"a2", x"01", x"00", -- 0x30: lw   x5, 0(x3)   | Broadcast over XIP
        x"6f", x"00", x"00", x"00"  -- 0x34: j .              | Halt
    );

begin

    uut: entity work.system_top(rtl)
        port map (
            clock       => s_clk,
            n_reset     => s_nreset,
            spiNCs      => spiNCs,
            spiClk      => spiClk,
            spiMoSi     => spiMoSi,
            spiMiSo     => spiMiSo,
            spiXipNCs   => spiXipNCs,
            spiXipClk   => spiXipClk,
            spiXipMoSi  => spiXipMoSi,
            spiXipMiSo  => spiXipMiSo,
            flashWpN    => flashWpN,
            flashResetN => flashResetN,
            RxD         => RxD,
            TxD         => TxD
        );

    s_clk <= not s_clk after CLK_PERIOD / 2;

    process
    begin
        s_nreset <= '0';
        wait for 100 ns;
        s_nreset <= '1';
        
        wait for 500 us;
        report "TEST FAILED: Simulation timed out!" severity failure;
    end process;

    -- =================================================================
    -- MOCK SPI EXTERNAL SLAVE (Attached to general-purpose spiBus pins)
    -- =================================================================
    process
        variable shift_in  : std_logic_vector(7 downto 0) := x"00";
        variable shift_out : std_logic_vector(7 downto 0) := x"15"; -- Payload to send to CPU
    begin
        -- Wait for Chip Select 0 to go active low
        wait until falling_edge(spiNCs(0));
        
        for i in 0 to 7 loop
            -- Shift out MISO on falling edge (CPHA=0)
            spiMiSo <= shift_out(7);
            shift_out := shift_out(6 downto 0) & '0';
            
            -- Sample MOSI on rising edge (CPHA=0)
            wait until rising_edge(spiClk);
            shift_in := shift_in(6 downto 0) & spiMoSi;
            
            wait until falling_edge(spiClk) or rising_edge(spiNCs(0));
        end loop;

        assert shift_in = x"A5"
            report "TEST FAILED: spiBus physical output incorrect! Expected 0xA5, got 0x" & to_hstring(shift_in)
            severity failure;
            
        report "SPI BUS: Successfully received 0xA5 from CPU and transmitted 0x15 back.";
        spiMiSo <= '1';
    end process;

    -- =================================================================
    -- MOCK SPI XIP FLASH (Instruction feeder and final address checker)
    -- =================================================================
    process(spiXipNCs, spiXipClk)
        variable bit_cnt  : integer := 0;
        variable shift_in : std_logic_vector(31 downto 0);
        variable addr     : integer := 0;
        variable byte_out : std_logic_vector(7 downto 0);
    begin
        if spiXipNCs = '1' then
            spiXipMiSo <= '1';
            bit_cnt := 0;
        else
            if rising_edge(spiXipClk) then
                shift_in := shift_in(30 downto 0) & spiXipMoSi;
                bit_cnt := bit_cnt + 1;
                
                if bit_cnt = 32 then
                    if not is_x(shift_in(23 downto 0)) then
                        addr := to_integer(unsigned(shift_in(23 downto 0)));

                        if addr > 55 then
                                assert addr = 16#150000#
                                report "TEST FAILED: CPU broadcast wrong address! Expected 0x150000 but got 0x" & to_hstring(shift_in(23 downto 0))
                                severity failure;
                                
                            report "TEST PASSED: Full SPI Loopback Successful! CPU configured regs, received 0x15, and exported address 0x150000!";
                            std.env.finish; 
                        end if;
                    end if;
                end if;
            end if;
            
            if falling_edge(spiXipClk) then
                if bit_cnt >= 32 then
                    if (bit_cnt mod 8) = 0 then
                        byte_out := MOCK_FLASH_ROM(addr mod 56); 
                        addr := addr + 1;
                    else
                        byte_out := byte_out(6 downto 0) & '0';
                    end if;
                    spiXipMiSo <= byte_out(7);
                end if;
            end if;
        end if;
    end process;

end architecture sim;
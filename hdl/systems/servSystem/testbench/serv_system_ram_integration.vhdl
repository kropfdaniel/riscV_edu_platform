-- =============================================================================
-- Author:      Daniel Kropf
-- License:     MIT
-- 
-- Description: 
--   Black-box verification testbench for a RISC-V SoC integrating the SERV 
--   bit-serial core, an internal SRAM Wishbone slave, and a custom SPI XIP controller.
--
-- Verification Strategy (Write, Read, Export):
--   1. A Mock SPI Flash feeds a RISC-V test program over the MISO line.
--   2. The CPU stores a test payload (15) into the SRAM at 0x40000000 using register x2.
--   3. The CPU reads back from the SRAM at 0x40000000 into a completely clean register (x3).
--   4. The CPU shifts the read result (x3) by 16 bits to form an export address (0x0F0000).
--   5. The CPU executes a Load Word using x3 as the address, forcing a physical SPI read.
--   6. The testbench intercepts the read command on the MOSI line and asserts that 
--      the physical SPI address matches the expected result (0x0F0000).
--
-- Executed Assembly Program:
--   0x00: lui  x1, 0x40000    (Load upper immediate: x1 = 0x40000000, SRAM Base)
--   0x04: addi x2, x0, 15     (Load 15 into x2)
--   0x08: sw   x2, 0(x1)      (Store x2 into SRAM at 0x40000000)
--   0x0C: lw   x3, 0(x1)      (Load from SRAM at 0x40000000 into x3)
--   0x10: slli x3, x3, 16     (Shift 15 left by 16 bits -> 0x0F0000)
--   0x14: lw   x5, 0(x3)      (Read from 0x0F0000 to broadcast result over SPI)
--   0x18: j .                 (Infinite loop, never reached)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sram_integration_top is
end entity tb_sram_integration_top;

architecture sim of tb_sram_integration_top is

    -- Signals for the Unit Under Test (UUT)
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

    -- 50 MHz Clock period
    constant CLK_PERIOD : time := 20 ns;

    -- Mock Flash Memory Array (holding our RISC-V SRAM test program)
    type rom_type is array (0 to 27) of std_logic_vector(7 downto 0);
    constant MOCK_FLASH_ROM : rom_type := (
        x"b7", x"00", x"00", x"40", -- 0x00: lui  x1, 0x40000 | x1 = 0x40000000
        x"13", x"01", x"f0", x"00", -- 0x04: addi x2, x0, 15  | x2 = 15
        x"23", x"a0", x"20", x"00", -- 0x08: sw   x2, 0(x1)   | Write 15 to SRAM
        x"83", x"a1", x"00", x"00", -- 0x0C: lw   x3, 0(x1)   | Read from SRAM into x3
        x"93", x"91", x"01", x"01", -- 0x10: slli x3, x3, 16  | Shift result left 16 bits (x3 = 0x0F0000)
        x"83", x"a2", x"01", x"00", -- 0x14: lw   x5, 0(x3)   | Broadcast over SPI
        x"6f", x"00", x"00", x"00"  -- 0x18: j .              | Halt
    );

begin

    -- Instantiate your top level
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

    -- Clock generation
    s_clk <= not s_clk after CLK_PERIOD / 2;

    -- Main stimulus process
    process
    begin
        -- Hold reset for 100ns
        s_nreset <= '0';
        wait for 100 ns;
        s_nreset <= '1';
        
        -- Watchdog timeout: Give plenty of time for Wishbone transactions
        wait for 300 us;
        report "TEST FAILED: Simulation timed out! CPU hung, likely missing an ACK from SRAM." severity failure;

    end process;

    -- =================================================================
    -- MOCK SPI FLASH (Attached to spiXip pins)
    -- =================================================================
    process(spiXipNCs, spiXipClk)
        variable bit_cnt : integer := 0;
        variable shift_in : std_logic_vector(31 downto 0);
        variable addr     : integer := 0;
        variable byte_out : std_logic_vector(7 downto 0);
    begin
        if spiXipNCs = '1' then
            spiXipMiSo <= '1';
            bit_cnt := 0;
        else
            -- Sample MOSI on Rising Edge
            if rising_edge(spiXipClk) then
                shift_in := shift_in(30 downto 0) & spiXipMoSi;
                bit_cnt := bit_cnt + 1;
                
                -- After 32 bits (8 bit cmd + 24 bit addr), we have the address
                if bit_cnt = 32 then
                    addr := to_integer(unsigned(shift_in(23 downto 0)));

                    -- Ignore standard instruction fetches (addresses 0 to 27).
                    -- The only other read requested by our program is the broadcast lw.
                    if addr > 27 then
                        
                        -- Exactly check the correct address using VHDL assert
                        assert addr = 16#0F0000#
                            report "TEST FAILED: CPU broadcast wrong address! Expected 983040 (0x0F0000) but got " & integer'image(addr)
                            severity failure;
                            
                        report "TEST PASSED: CPU correctly stored 15 to SRAM, read it back via x3, and exported address 0x0F0000!";
                        std.env.finish; -- End successfully
                    end if;
                end if;
            end if;
            
            -- Shift out MISO on Falling Edge
            if falling_edge(spiXipClk) then
                if bit_cnt >= 32 then
                    if (bit_cnt mod 8) = 0 then
                        -- Fetch next byte from ROM. modulo 28 ensures wrap around.
                        byte_out := MOCK_FLASH_ROM(addr mod 28); 
                        addr := addr + 1;
                    else
                        -- Shift byte
                        byte_out := byte_out(6 downto 0) & '0';
                    end if;
                    spiXipMiSo <= byte_out(7);
                end if;
            end if;
        end if;
    end process;

end architecture sim;
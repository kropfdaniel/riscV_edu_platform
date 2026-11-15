-- =============================================================================
-- Author:      Daniel Kropf
-- License:     MIT
-- 
-- Description: 
--   Black-box verification testbench for the uartBus integration.
--
-- Verification Strategy (External Physical Loopback with Byte Access):
--   1. CPU sets Base Address to 0x80000100.
--   2. CPU writes 0x80 to offset 0x3 (LCR) via 'sb' to set DLAB=1 safely.
--   3. CPU writes 0x01 to offset 0x0 (DIV LSB) via 'sb'.
--   4. CPU writes 0x00 to offset 0x1 (DIV MSB) via 'sb'.
--   5. CPU writes 0x03 to offset 0x3 (LCR) via 'sb' to set DLAB=0.
--   6. CPU writes 0x15 to offset 0x0 (TX FIFO) via 'sb'.
--   7. Testbench physically loops TxD directly into RxD.
--   8. CPU continuously polls LSR (offset 0x5) via 'lbu' and masks bit 0.
--   9. CPU reads the RX FIFO (offset 0x0) via 'lbu' and broadcasts via spiXip.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_integration_top is
end entity tb_uart_integration_top;

architecture sim of tb_uart_integration_top is

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
    
    signal RxD         : std_logic;
    signal TxD         : std_logic;

    constant CLK_PERIOD : time := 20 ns;

    -- Mock Flash Memory Array (RISC-V Byte-Accurate UART Config & Polling)
    type rom_type is array (0 to 71) of std_logic_vector(7 downto 0);
    constant MOCK_FLASH_ROM : rom_type := (
        -- Pointers
        x"b7", x"00", x"00", x"80", -- 0x00: lui  x1, 0x80000
        x"93", x"80", x"00", x"10", -- 0x04: addi x1, x1, 0x100 | x1 = 0x80000100 (Base)
        
        -- DLAB = 1 (LCR is offset 3)
        x"13", x"01", x"00", x"08", -- 0x08: addi x2, x0, 0x80
        x"a3", x"81", x"20", x"00", -- 0x0C: sb   x2, 3(x1)     | LCR = 0x80
        
        -- Divisor = 1 (DIV LSB is offset 0, MSB is offset 1)
        x"13", x"01", x"30", x"00", -- 0x10: addi x2, x0, 3
        x"23", x"80", x"20", x"00", -- 0x14: sb   x2, 0(x1)     | DIV LSB = 1
        x"a3", x"80", x"00", x"00", -- 0x18: sb   x0, 1(x1)     | DIV MSB = 0
        
        -- DLAB = 0, 8-bit Data (LCR is offset 3)
        x"13", x"01", x"30", x"00", -- 0x1C: addi x2, x0, 3
        x"a3", x"81", x"20", x"00", -- 0x20: sb   x2, 3(x1)     | LCR = 0x03
        
        -- Transmit 0x15 (TX FIFO is offset 0)
        x"13", x"01", x"50", x"01", -- 0x24: addi x2, x0, 21
        x"23", x"80", x"20", x"00", -- 0x28: sb   x2, 0(x1)     | TX FIFO = 0x15
        
        -- Polling Loop (LSR is offset 5, Data Ready is bit 0)
        x"03", x"c2", x"50", x"00", -- 0x2C: lbu  x4, 5(x1)     | Load exactly LSR
        x"13", x"72", x"12", x"00", -- 0x30: andi x4, x4, 1     | Mask Data Ready bit
        x"e3", x"0c", x"02", x"fe", -- 0x34: beq  x4, x0, -8    | If 0, loop back to 0x2C
        
        -- Read Received Data & Export (RX FIFO is offset 0)
        x"83", x"c1", x"00", x"00", -- 0x38: lbu  x3, 0(x1)     | Load RX FIFO
        x"93", x"91", x"01", x"01", -- 0x3C: slli x3, x3, 16    | Shift to 0x150000
        x"83", x"a2", x"01", x"00", -- 0x40: lw   x5, 0(x3)     | Broadcast via spiXip!
        x"63", x"00", x"00", x"00"  -- 0x44: j .                | Halt
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

    -- =================================================================
    -- EXTERNAL PHYSICAL LOOPBACK
    -- =================================================================
    RxD <= TxD;

    s_clk <= not s_clk after CLK_PERIOD / 2;

    process
    begin
        s_nreset <= '0';
        wait for 100 ns;
        s_nreset <= '1';
        
        wait for 2 ms; -- Give enough time for the physical UART transaction 
        report "TEST FAILED: Simulation timed out! CPU hung in polling loop (byte never arrived)." severity failure;
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

                        if addr > 71 then
                            assert addr = 16#150000#
                                report "TEST FAILED: CPU broadcast wrong address! Expected 0x150000 but got 0x" & to_hstring(shift_in(23 downto 0))
                                severity failure;
                                
                            report "TEST PASSED: UART External Loopback Successful! Byte exited TxD, entered RxD, passed through FIFOs, and was read by CPU!";
                            std.env.finish; 
                        end if;
                    end if;
                end if;
            end if;
            
            if falling_edge(spiXipClk) then
                if bit_cnt >= 32 then
                    if (bit_cnt mod 8) = 0 then
                        byte_out := MOCK_FLASH_ROM(addr mod 72); 
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
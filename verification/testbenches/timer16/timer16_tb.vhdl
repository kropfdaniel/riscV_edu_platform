--------------------------------------------------------------------------------
--! @author    Daniel Kropf
--! @copyright MIT License
--! @brief     Self-checking VHDL-2008 testbench for timer16.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity timer16_tb is
end entity timer16_tb;

architecture sim of timer16_tb is

    constant c_clkPeriod   : time := 20 ns; -- 50 MHz
    constant c_dataBits    : integer := 32;
    constant c_addrBits    : integer := 32;
    constant c_baseAddress : std_logic_vector(c_addrBits-1 downto 0) := 32X"80000200";

    -- DUT signals
    signal s_clk      : std_logic := '0';
    signal s_rst      : std_logic := '1';
    signal s_datI     : std_logic_vector(c_dataBits-1 downto 0) := (others => '0');
    signal s_datO     : std_logic_vector(c_dataBits-1 downto 0);
    signal s_ackO     : std_logic;
    signal s_addrI    : std_logic_vector(c_addrBits-1 downto 0) := (others => '0');
    signal s_cycI     : std_logic := '0';
    signal s_errO     : std_logic;
    signal s_selI     : std_logic_vector((c_dataBits/8)-1 downto 0) := (others => '0');
    signal s_stbI     : std_logic := '0';
    signal s_weI      : std_logic := '0';
    signal s_ctiI     : std_logic_vector(2 downto 0) := "000";
    signal s_timerIrq : std_logic;

begin

    -- 50 MHz clock generator
    s_clk <= not s_clk after c_clkPeriod / 2;

    -- DUT instantiation
    dut : entity work.timer16
        generic map (
            DataBits    => c_dataBits,
            AddrBits    => c_addrBits,
            BaseAddress => c_baseAddress
        )
        port map (
            CLK_I     => s_clk,
            RST_I     => s_rst,
            DAT_I     => s_datI,
            DAT_O     => s_datO,
            ACK_O     => s_ackO,
            ADDR_I    => s_addrI,
            CYC_I     => s_cycI,
            ERR_O     => s_errO,
            SEL_I     => s_selI,
            STB_I     => s_stbI,
            WE_I      => s_weI,
            CTI_I     => s_ctiI,
            timer_irq => s_timerIrq
        );

    -- Stimulus & verification process
    p_stim : process
        variable v_readData : std_logic_vector(31 downto 0);

        -- Wishbone Classic Write
        procedure wb_write(
            addr       : in std_logic_vector(31 downto 0);
            data       : in std_logic_vector(31 downto 0);
            sel        : in std_logic_vector(3 downto 0) := "1111";
            cti        : in std_logic_vector(2 downto 0) := "000";
            expect_err : in boolean := false
        ) is
        begin
            s_addrI <= addr;
            s_datI  <= data;
            s_selI  <= sel;
            s_ctiI  <= cti;
            s_weI   <= '1';
            s_cycI  <= '1';
            s_stbI  <= '1';

            -- Edge 1: Slave latches write and asserts ACK_O or ERR_O
            wait until rising_edge(s_clk);
            wait for 1 ns;

            if expect_err then
                assert s_errO = '1' and s_ackO = '0'
                    report "Expected ERR_O = 1 and ACK_O = 0 exactly 1 cycle after write"
                    severity failure;
            else
                assert s_ackO = '1' and s_errO = '0'
                    report "Expected ACK_O = 1 and ERR_O = 0 exactly 1 cycle after write"
                    severity failure;
            end if;

            -- Edge 2: Master completes cycle; slave clears ACK_O/ERR_O
            wait until rising_edge(s_clk);
            s_cycI <= '0';
            s_stbI <= '0';
            s_weI  <= '0';

            wait for 1 ns;
            assert s_ackO = '0' and s_errO = '0'
                report "ACK_O and ERR_O did not return to 0 after transaction"
                severity failure;
        end procedure;

        -- Wishbone Classic Read
        procedure wb_read(
            addr       : in  std_logic_vector(31 downto 0);
            data       : out std_logic_vector(31 downto 0);
            cti        : in  std_logic_vector(2 downto 0) := "000";
            expect_err : in  boolean := false
        ) is
        begin
            s_addrI <= addr;
            s_selI  <= "1111";
            s_ctiI  <= cti;
            s_weI   <= '0';
            s_cycI  <= '1';
            s_stbI  <= '1';

            -- Edge 1: Slave asserts ACK_O or ERR_O
            wait until rising_edge(s_clk);
            wait for 1 ns;

            if expect_err then
                assert s_errO = '1' and s_ackO = '0'
                    report "Expected ERR_O = 1 and ACK_O = 0 exactly 1 cycle after read"
                    severity failure;
            else
                assert s_ackO = '1' and s_errO = '0'
                    report "Expected ACK_O = 1 and ERR_O = 0 exactly 1 cycle after read"
                    severity failure;
            end if;

            data := s_datO;

            -- Edge 2: Master completes cycle; slave clears ACK_O/ERR_O
            wait until rising_edge(s_clk);
            s_cycI <= '0';
            s_stbI <= '0';
            
            wait for 1 ns;
            assert s_ackO = '0' and s_errO = '0'
                report "ACK_O and ERR_O did not return to 0 after transaction"
                severity failure;
        end procedure;

        -- Helper to wait N clock cycles
        procedure wait_cycles(n : in natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(s_clk);
            end loop;
        end procedure;

    begin
        -- =====================================================================
        -- Test 1: Reset state
        -- =====================================================================
        report "Test 1: Reset state";
        s_rst <= '1';
        wait_cycles(3);
        s_rst <= '0';
        wait_cycles(1);

        assert s_timerIrq = '0' report "IRQ should be 0 after reset" severity failure;
        wb_read(c_baseAddress, v_readData);
        assert v_readData = 32X"00000000"
            report "Register should be 0 after reset, got " & to_hstring(v_readData)
            severity failure;

        -- =====================================================================
        -- Test 2: Wishbone error on non-classic CTI
        -- =====================================================================
        report "Test 2: Wishbone CTI error check";
        wb_write(c_baseAddress, 32X"00000001", sel => "1111", cti => "010", expect_err => true);
        wait_cycles(1);

        -- =====================================================================
        -- Test 3: One-shot mode (PRESCALE = 0 (/1), RELOAD = 3 -> 4 cycles)
        -- Note: wb_write returns 1 cycle after s_start latched, so 3 cycles left.
        -- =====================================================================
        report "Test 3: One-shot mode (RELOAD=3, PRESCALE=0)";
        -- RELOAD=0x0003, IRQ_PEND=0, PRESCALE=0, IRQ_EN=1, MODE=0, TIMER_EN=1
        wb_write(c_baseAddress, 32X"00030005");

        wait_cycles(2); -- Total 3 cycles elapsed
        wait for 1 ns;
        assert s_timerIrq = '0' report "IRQ fired too early in one-shot mode" severity failure;

        wait_cycles(1); -- Total 4 cycles elapsed -> expiry
        wait for 1 ns;
        assert s_timerIrq = '1' report "IRQ did not fire on cycle 4 in one-shot mode" severity failure;

        -- Verify TIMER_EN auto-cleared and IRQ_PEND = 1
        wb_read(c_baseAddress, v_readData);
        assert v_readData(0) = '0' report "TIMER_EN did not auto-clear in one-shot mode" severity failure;
        assert v_readData(8) = '1' report "IRQ_PEND not set after expiry" severity failure;

        -- =====================================================================
        -- Test 4: W1C clear via Byte 1 only (SEL_I = "0010")
        -- =====================================================================
        report "Test 4: W1C clear via Byte 1";
        wb_write(c_baseAddress, 32X"00000100", sel => "0010");
        wait for 1 ns;
        assert s_timerIrq = '0' report "IRQ did not clear after W1C" severity failure;

        wb_read(c_baseAddress, v_readData);
        assert v_readData(31 downto 16) = 16X"0003"
            report "RELOAD was corrupted by Byte 1 W1C write" severity failure;

        -- =====================================================================
        -- Test 5: Periodic mode + Prescaler (PRESCALE = 2 (/4), RELOAD = 1 -> 8 cycles)
        -- =====================================================================
        report "Test 5: Periodic mode (RELOAD=1, PRESCALE=2 -> 8 cycles)";
        -- RELOAD=0x0001, PRESCALE=2 (0x20), IRQ_EN=1 (0x04), MODE=1 (0x02), EN=1 (0x01) -> 0x27
        wb_write(c_baseAddress, 32X"00010027");

        wait_cycles(6); -- Total 7 cycles elapsed
        wait for 1 ns;
        assert s_timerIrq = '0' report "Periodic IRQ fired too early" severity failure;

        wait_cycles(1); -- Total 8 cycles elapsed -> 1st expiry
        wait for 1 ns;
        assert s_timerIrq = '1' report "Periodic IRQ did not fire at cycle 8" severity failure;

        -- Clear IRQ via Byte 1 (takes 2 cycles: 1 write + 1 ack)
        wb_write(c_baseAddress, 32X"00000100", sel => "0010");
        wait for 1 ns;
        assert s_timerIrq = '0' report "Periodic IRQ did not clear" severity failure;

        -- 2nd expiry should happen 8 cycles after 1st expiry (6 cycles remaining after W1C)
        wait_cycles(5);
        wait for 1 ns;
        assert s_timerIrq = '0' report "2nd periodic IRQ fired too early" severity failure;

        wait_cycles(1);
        wait for 1 ns;
        assert s_timerIrq = '1' report "2nd periodic IRQ did not fire at cycle 16" severity failure;

        -- Stop timer and clear IRQ
        wb_write(c_baseAddress, 32X"00000100", sel => "0011");

        -- =====================================================================
        -- Test 6: Polling mode (IRQ_EN = 0)
        -- =====================================================================
        report "Test 6: Polling mode (IRQ_EN = 0)";
        -- RELOAD=1, PRESCALE=0, IRQ_EN=0, MODE=0, TIMER_EN=1 -> 2 cycles
        wb_write(c_baseAddress, 32X"00010001");
        wait_cycles(1); -- Total 2 cycles elapsed
        wait for 1 ns;

        assert s_timerIrq = '0' report "IRQ output should stay masked when IRQ_EN = 0" severity failure;
        wb_read(c_baseAddress, v_readData);
        assert v_readData(8) = '1' report "IRQ_PEND should still set when IRQ_EN = 0" severity failure;

        -- Enable IRQ_EN without restarting timer -> IRQ should assert immediately
        wb_write(c_baseAddress, 32X"00000004", sel => "0001");
        wait for 1 ns;
        assert s_timerIrq = '1' report "IRQ should assert immediately once IRQ_EN = 1" severity failure;

        -- =====================================================================
        -- Test 7: Buffered RELOAD update while running (Periodic mode)
        -- =====================================================================
        report "Test 7: Buffered RELOAD update while running";
        -- Stop timer and clear any pending IRQ from Test 6
        wb_write(c_baseAddress, 32X"00000100", sel => "0011");

        -- Start periodic timer: RELOAD = 3, PRESCALE = 0 -> 4 cycles
        -- (1 cycle elapses during wb_write)
        wb_write(c_baseAddress, 32X"00030007");

        -- Mid-run: update RELOAD to 7 via Byte 2 only (SEL_I = "0100")
        -- (2 more cycles elapse during wb_write -> 3 cycles total)
        wb_write(c_baseAddress, 32X"00070000", sel => "0100");
        wait for 1 ns;
        assert s_timerIrq = '0' report "IRQ fired too early after buffered RELOAD write" severity failure;

        -- 4th cycle: first period must still expire on the original RELOAD = 3
        wait_cycles(1);
        wait for 1 ns;
        assert s_timerIrq = '1' report "Original period (4 cycles) did not expire on time" severity failure;

        -- Clear IRQ via Byte 1 (2 cycles of the new 8-cycle period elapse here)
        wb_write(c_baseAddress, 32X"00000100", sel => "0010");
        wait for 1 ns;
        assert s_timerIrq = '0' report "IRQ did not clear" severity failure;

        -- Remaining 6 cycles of the new RELOAD = 7 (8-cycle) period
        wait_cycles(5);
        wait for 1 ns;
        assert s_timerIrq = '0' report "New buffered period (8 cycles) fired too early" severity failure;

        wait_cycles(1);
        wait for 1 ns;
        assert s_timerIrq = '1' report "New buffered period (8 cycles) did not fire on time" severity failure;

        report "ALL TESTS PASSED!";
        stop;
    end process p_stim;

end architecture sim;
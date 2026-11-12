--------------------------------------------------------------------------------
--! @author    Daniel Kropf
--! @copyright MIT License
--! @brief     Self-checking testbench for spiByteTransceiver
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spiByteTransceiver_tb is
end entity spiByteTransceiver_tb;

architecture sim of spiByteTransceiver_tb is
    -- DUT Signals
    signal clock                : std_logic := '1';
    signal reset                : std_logic := '1';
    signal startByteTransaction : std_logic := '0';
    signal txByte               : std_logic_vector(7 downto 0) := (others => '0');
    signal rxByte               : std_logic_vector(7 downto 0);
    signal busyByteTransaction  : std_logic;
    signal clkDivTick           : std_logic := '0';
    signal cpol                 : std_logic := '0';
    signal cpha                 : std_logic := '0';
    signal lsbf                 : std_logic := '0';
    signal spiClk               : std_logic;
    signal spiMoSi              : std_logic;
    signal spiMiSo              : std_logic := '0';

    -- 50 MHz System Clock
    constant CLK_PERIOD : time := 20 ns;

    -- Testbench verification data
    signal tb_miso_data : std_logic_vector(7 downto 0) := x"00";
begin

    -- Instantiate the Device Under Test (DUT)
    dut : entity work.spiByteTransceiver(rtl)
        port map (
            clock                => clock,
            reset                => reset,
            startByteTransaction => startByteTransaction,
            txByte               => txByte,
            rxByte               => rxByte,
            busyByteTransaction  => busyByteTransaction,
            clkDivTick           => clkDivTick,
            cpol                 => cpol,
            cpha                 => cpha,
            lsbf                 => lsbf,
            spiClk               => spiClk,
            spiMoSi              => spiMoSi,
            spiMiSo              => spiMiSo
        );

    -- 1. Main System Clock Generator
    clock <= not clock after CLK_PERIOD / 2;

    -- 2. Tick Generator (Simulates the clkDiv tick from spiBus)
    -- Generates a tick every 4 system clock cycles
    process
    begin
        wait for CLK_PERIOD * 3;
        clkDivTick <= '1';
        wait for CLK_PERIOD;
        clkDivTick <= '0';
    end process;

    -- 3. Main Stimulus and Checking Process
    process
        variable v_expected_mosi : std_logic;
    begin
        -- =====================================================================
        -- INITIALIZATION & RESET
        -- =====================================================================
        reset <= '1';
        wait for CLK_PERIOD * 10;
        reset <= '0';
        wait until rising_edge(clock);

        -- Verify Idle State Defaults
        assert busyByteTransaction = '0' report "FAIL: Busy flag should be 0 after reset" severity failure;
        assert spiClk = cpol report "FAIL: spiClk should idle at CPOL" severity failure;

        -- =====================================================================
        -- TEST CASE 1: Mode 0 (CPOL=0, CPHA=0), MSB First (Standard Flash)
        -- =====================================================================
        report "Starting Test Case 1: CPOL=0, CPHA=0, MSB First...";
        cpol   <= '0';
        cpha   <= '0';
        lsbf   <= '0';
        txByte <= x"A5";       -- 10100101 (Data sent to MOSI)
        tb_miso_data <= x"C3"; -- 11000011 (Emulated Slave response on MISO)

        -- Align to tick, then assert start signal
        wait until rising_edge(clock) and clkDivTick = '1';
        startByteTransaction <= '1';
        wait until rising_edge(clock);
        wait for 1 ps;
        startByteTransaction <= '0';

        assert busyByteTransaction = '1' report "TC1 FAIL: busy flag didn't assert" severity failure;

        spiMiSo <= tb_miso_data(7);

        -- Bit-by-bit check (MSB first: 7 down to 0)
        for i in 7 downto 0 loop
            v_expected_mosi := txByte(i);
            
            -- [Leading Edge Setup] (For CPHA=0, MOSI is updated BEFORE the leading edge)
            wait until rising_edge(clock) and clkDivTick = '1';
            wait for 1 ps;
            assert spiClk = '1' report "TC1 FAIL: spiClk leading edge did not go HIGH" severity failure;
            assert spiMoSi = v_expected_mosi report "TC1 FAIL: MOSI mismatch at bit " & integer'image(i) severity failure;
            
            
            
            -- [Trailing Edge Setup]
            wait until rising_edge(clock) and clkDivTick = '1';
            wait for 1 ps;
            assert spiClk = '0' report "TC1 FAIL: spiClk trailing edge did not go LOW" severity failure;
            -- Emulate Slave: Drive MISO so the DUT can sample it on the leading edge
            if i > 0 then 
                spiMiSo <= tb_miso_data(i-1);
            end if;
        end loop;

        -- End of Transaction Check
        wait for 1 ps;
        assert busyByteTransaction = '0' report "TC1 FAIL: busy flag didn't de-assert" severity failure;
        assert rxByte = tb_miso_data report "TC1 FAIL: rxByte payload corrupted" severity failure;
        report "Test Case 1 Passed!";

        -- =====================================================================
        -- TEST CASE 2: Mode 3 (CPOL=1, CPHA=1), LSB First
        -- =====================================================================
        report "Starting Test Case 2: CPOL=1, CPHA=1, LSB First...";
        wait for CLK_PERIOD * 10;
        
        cpol   <= '1';
        cpha   <= '1';
        lsbf   <= '1';
        txByte <= x"d5";       -- 11010101
        tb_miso_data <= x"93"; -- 10010011
        
        wait until rising_edge(clock) and clkDivTick = '1';
        startByteTransaction <= '1';
        wait until rising_edge(clock);
        wait for 1 ps;
        startByteTransaction <= '0';

        assert busyByteTransaction = '1' report "TC2 FAIL: busy flag didn't assert" severity failure;

        -- Bit-by-bit check (LSB first: 0 to 7)
        for i in 0 to 7 loop
            v_expected_mosi := txByte(i);

            -- [Leading Edge Setup] (For CPHA=1, MOSI is shifted ON the leading edge)
            wait until rising_edge(clock) and clkDivTick = '1';
            wait for 1 ps;
            
            assert spiClk = '0' report "TC2 FAIL: spiClk leading edge did not go LOW" severity failure;
            assert spiMoSi = v_expected_mosi report "TC2 FAIL: MOSI mismatch at bit " & integer'image(i) severity failure;
            
            -- Emulate Slave: Drive MISO so the DUT can sample it on the trailing edge
            spiMiSo <= tb_miso_data(i);

            -- [Trailing Edge Setup]
            wait until rising_edge(clock) and clkDivTick = '1';
            wait for 1 ps;

            assert spiClk = '1' report "TC2 FAIL: spiClk trailing edge did not go HIGH" severity failure;
        end loop;
        
        -- End of Transaction Check
        wait for 1 ps;
        assert busyByteTransaction = '0' report "TC2 FAIL: busy flag didn't de-assert" severity failure;
        assert rxByte = tb_miso_data report "TC2 FAIL: rxByte payload corrupted" severity failure;
        report "Test Case 2 Passed!";

        wait for CLK_PERIOD * 3;

        -- =====================================================================
        -- END SIMULATION
        -- =====================================================================
        report "SUCCESS: All spiByteTransceiver tests passed!";
        std.env.finish; -- Gracefully stops GHDL in VHDL-2008
    end process;
end architecture sim;
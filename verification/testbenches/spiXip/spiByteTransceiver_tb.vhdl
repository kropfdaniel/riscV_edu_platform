--------------------------------------------------------------------------------
--! @author     Daniel Kropf
--! @brief      Self-checking testbench for spiByteTransceiver.
--!
--! Verifies SPI Mode 0 byte transmission and reception using a direct 
--! MOSI-to-MISO loopback. Validates FSM busy flags and static output pins.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spiByteTransceiver is
end entity tb_spiByteTransceiver;

architecture sim of tb_spiByteTransceiver is
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz clock
    
    signal clk     : std_logic := '0';
    signal rst     : std_logic := '0';
    
    signal start   : std_logic := '0';
    signal txByte  : std_logic_vector(7 downto 0) := (others => '0');
    signal rxByte  : std_logic_vector(7 downto 0);
    signal busy    : std_logic;
    
    signal spiClk  : std_logic;
    signal spiMoSi : std_logic;
    signal spiMiSo : std_logic;
    signal wpn     : std_logic;
    signal rstn    : std_logic;
begin
    uut: entity work.spiByteTransceiver(rtl)
        port map (
            clock                => clk,
            reset                => rst,
            startByteTransaction => start,
            txByte               => txByte,
            rxByte               => rxByte,
            busyByteTransaction  => busy,
            spiClk               => spiClk,
            spiMoSi              => spiMoSi,
            spiMiSo              => spiMiSo,
            flashWpN             => wpn,
            flashResetN          => rstn
        );

    -- 50 MHz system clock generation
    clk <= not clk after CLK_PERIOD / 2;
    
    -- Hardware loopback: Slave receives MOSI and immediately drives it back to Master via MISO
    spiMiSo <= spiMoSi;

    stimulus: process
        --! Helper procedure to send a byte and automatically check the received loopback data
        procedure send_and_check(constant data_to_send : in std_logic_vector(7 downto 0)) is
        begin
            report "Testing byte transmission: 0x" & to_hstring(data_to_send);

            assert busy = '0' report "Timing Error: busy is not 0 before transaction." severity failure;
            assert spiClk = '0' report "Timing Error: spiClk must idle low (CPOL=0)." severity failure;
            
            -- Setup data and start pulse
            txByte <= data_to_send;
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';

            wait for 1 ps; 
            assert busy = '1' report "Control Error: busy did not assert after start pulse." severity failure;
            
            -- Cycle-by-Cycle Timing Verification (8 bits = 16 system clocks)
            for i in 7 downto 0 loop
                -- Phase A: FSM should be in SCK_HIGH
                wait until rising_edge(clk);
                wait for 1 ps; -- Allow signals to update
                assert spiClk = '1' report "SPI Error: spiClk did not go high." severity failure;
                assert busy = '1' report "Control Error: busy dropped prematurely." severity failure;
                
                -- Phase B: FSM should be in SCK_LOW
                wait until rising_edge(clk);
                wait for 1 ps;
                assert spiClk = '0' report "SPI Error: spiClk did not go low." severity failure;
            end loop;
            
            -- Check clean completion
            assert busy = '0' report "Control Error: busy did not deassert after 8 bits." severity failure;
            
            -- Verify loopback data
            assert rxByte = data_to_send 
                report "Data mismatch! Expected 0x" & to_hstring(data_to_send) & " but got 0x" & to_hstring(rxByte) 
                severity failure;
                
            -- Provide gap between transactions
            wait for 5 * CLK_PERIOD;
        end procedure;

    begin
        -- System Reset
        rst <= '1';
        wait for 5 * CLK_PERIOD;
        rst <= '0';
        wait for 5 * CLK_PERIOD;

        -- Verify static outputs are driven correctly for the Flash memory
        assert wpn = '0' report "Test Failed: flashWpN should be tied low." severity failure;
        assert rstn = '1' report "Test Failed: flashResetN should be tied high." severity failure;

        -- Run loopback tests with various bit patterns (Alternating, all zeros, all ones, edges)
        send_and_check(x"A5"); -- 10100101
        send_and_check(x"5A"); -- 01011010
        send_and_check(x"00"); -- All zeros
        send_and_check(x"FF"); -- All ones
        send_and_check(x"81"); -- MSB and LSB only
        send_and_check(x"3C"); -- 00111100

        report "ALL TESTS PASSED.";
        std.env.stop;
    end process;

end architecture sim;
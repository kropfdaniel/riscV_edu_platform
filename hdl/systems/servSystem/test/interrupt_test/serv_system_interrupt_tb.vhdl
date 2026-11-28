library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

use work.firmware_pkg.all;

entity serv_system_interrupt_tb is
end entity serv_system_interrupt_tb;

architecture sim of serv_system_interrupt_tb is
    constant c_clk_period : time := 20 ns; -- 50 MHz

    signal clock       : std_logic := '0';
    signal n_reset     : std_logic := '0';

    -- General SPI (unused in this test)
    signal spiNCs      : std_logic_vector(1 downto 0);
    signal spiClk      : std_logic;
    signal spiMoSi     : std_logic;
    signal spiMiSo     : std_logic := '0';

    -- External SPI XIP Flash pins
    signal spiXipNCs   : std_logic;
    signal spiXipClk   : std_logic;
    signal spiXipMoSi  : std_logic;
    signal spiXipMiSo  : std_logic := '0';
    signal flashWpN    : std_logic;
    signal flashResetN : std_logic;

    -- UART (idle high)
    signal RxD         : std_logic := '1';
    signal TxD         : std_logic;

    -- LED Matrix outputs
    signal rgbRow      : std_logic_vector(3 downto 0);
    signal nRed        : std_logic_vector(9 downto 0);
    signal nGreen      : std_logic_vector(9 downto 0);
    signal nBlue       : std_logic_vector(9 downto 0);
begin

    -- 50 MHz clock generator
    clock <= not clock after c_clk_period / 2;

    -- Device Under Test
    dut : entity work.system_top(rtl)
        port map (
            clock       => clock,
            n_reset     => n_reset,
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
            TxD         => TxD,
            rgbRow      => rgbRow,
            nRed        => nRed,
            nGreen      => nGreen,
            nBlue       => nBlue
        );

    ----------------------------------------------------------------------------
    -- Behavioral SPI NOR Flash Mock (SPI Mode 0)
    -- Supports 0x03 (Read) and 0x0B (Fast Read) from firmware_pkg.FIRMWARE_DATA
    ----------------------------------------------------------------------------
    spi_flash_mock : process
        variable v_cmd  : std_logic_vector(7 downto 0);
        variable v_addr : unsigned(23 downto 0);
        variable v_byte : std_logic_vector(7 downto 0);
        variable v_idx  : integer;
    begin
        spiXipMiSo <= '0';

        -- Wait for CS assertion (active low)
        if spiXipNCs /= '0' then
            wait until spiXipNCs = '0';
        end if;

        -- 1. Receive 8-bit command (MSB first on rising edge)
        for i in 7 downto 0 loop
            wait until rising_edge(spiXipClk) or spiXipNCs = '1';
            exit when spiXipNCs = '1';
            v_cmd(i) := spiXipMoSi;
        end loop;

        -- 2. Receive 24-bit address (MSB first on rising edge)
        if spiXipNCs = '0' and (v_cmd = x"03" or v_cmd = x"0B") then
            for i in 23 downto 0 loop
                wait until rising_edge(spiXipClk) or spiXipNCs = '1';
                exit when spiXipNCs = '1';
                v_addr(i) := spiXipMoSi;
            end loop;

            -- Optional 8 dummy cycles for Fast Read (0x0B)
            if spiXipNCs = '0' and v_cmd = x"0B" then
                for i in 7 downto 0 loop
                    wait until rising_edge(spiXipClk) or spiXipNCs = '1';
                    exit when spiXipNCs = '1';
                end loop;
            end if;

            -- 3. Stream bytes out MSB first on falling edge (auto-incrementing address)
            while spiXipNCs = '0' loop
                v_idx := to_integer(v_addr);
                if v_idx < FIRMWARE_LENGTH then
                    v_byte := FIRMWARE_DATA(v_idx);
                else
                    v_byte := x"FF"; -- Unprogrammed flash reads as 0xFF
                end if;

                for i in 7 downto 0 loop
                    wait until falling_edge(spiXipClk) or spiXipNCs = '1';
                    exit when spiXipNCs = '1';
                    spiXipMiSo <= v_byte(i);
                end loop;

                v_addr := v_addr + 1;
            end loop;
        else
            -- Ignore unsupported commands until CS goes high
            if spiXipNCs = '0' then
                wait until spiXipNCs = '1';
            end if;
        end if;
    end process spi_flash_mock;

    ----------------------------------------------------------------------------
    -- Stimulus & Assertions
    ----------------------------------------------------------------------------
    check_proc : process
    begin
        -- Hold reset for 5 clock cycles
        n_reset <= '0';
        wait for 5 * c_clk_period;
        n_reset <= '1';
        wait for 2 * c_clk_period;

        -- 1. Check initial state: row 11 selected, LED 11 OFF (active-low = '1')
        assert rgbRow = "1011"
            report "Expected rgbRow = 1011 (row 11) after reset" severity error;
        assert nRed(0) = '1' and nGreen(0) = '1' and nBlue(0) = '1'
            report "LED 11 should be OFF after reset" severity error;

        -- 2. Wait for 1st timer interrupt -> LED 11 turns RED (nRed(0) = '0')
        wait until nRed(0) = '0' for 500 us;
        assert rgbRow = "1011"
            report "rgbRow changed before 1st interrupt completed!" severity failure;
        assert nRed(0) = '0' and nGreen(0) = '1' and nBlue(0) = '1'
            report "FAIL: 1st interrupt did not turn LED 11 RED (nBlue=0 means trap fault)"
            severity failure;
        report "PASS: 1st timer interrupt toggled LED 11 to RED";

        -- 3. Wait for 2nd timer interrupt -> LED 11 turns GREEN (nGreen(0) = '0')
        wait until nGreen(0) = '0' for 500 us;
        assert rgbRow = "1011"
            report "rgbRow changed before 2nd interrupt completed!" severity failure;
        assert nRed(0) = '1' and nGreen(0) = '0' and nBlue(0) = '1'
            report "FAIL: 2nd interrupt did not turn LED 11 GREEN"
            severity failure;
        report "PASS: 2nd timer interrupt toggled LED 11 to GREEN";

        report "ALL TESTS PASSED";
        finish;
    end process check_proc;

end architecture sim;
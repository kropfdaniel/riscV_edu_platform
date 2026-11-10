--------------------------------------------------------------------------------
--! @author     Daniel Kropf
--! @brief      Self-checking testbench for spiXipBus.
--!
--! Verifies Wishbone Classic read transactions, error handling for writes and 
--! invalid cycle types, and implements a procedural SPI Mode 0 Mock Flash 
--! to automatically validate the returned execute-in-place data.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.spiXip_pkg.all;

entity spiXipBus_tb is
end entity spiXipBus_tb;

architecture sim of spiXipBus_tb is
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz clock
    
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    
    -- Wishbone interface
    signal dat_o       : std_logic_vector(31 downto 0);
    signal ack_o       : std_logic;
    signal err_o       : std_logic;
    signal addr_i      : std_logic_vector(31 downto 0) := (others => '0');
    signal cyc_i       : std_logic := '0';
    signal stb_i       : std_logic := '0';
    signal we_i        : std_logic := '0';
    signal cti_i       : std_logic_vector(2 downto 0) := "000";
    signal sel_i       : std_logic_vector(3 downto 0) := "1111";

    -- External SPI
    signal spiNCs      : std_logic;
    signal spiClk      : std_logic;
    signal spiMoSi     : std_logic;
    signal spiMiSo     : std_logic := 'Z';
    signal flashWpN    : std_logic;
    signal flashResetN : std_logic;

    -- Expected mock data for automatic checking
    constant EXPECTED_FLASH_DATA    : std_logic_vector(31 downto 0) := x"DEADBEEF";
    constant EXPECTED_FLASH_ADDRESS : std_logic_vector(23 downto 0) :=   x"00A5A5";
begin
    uut: entity work.spiXipBus(platformIndependent)
        generic map (
            DataBits       => 32,
            AddrBits       => 32,
            BaseAddress    => x"40000000",
            FlashAddrWidth => 21
        )
        port map (
            CLK_I       => clk,
            RST_I       => rst,
            DAT_O       => dat_o,
            ACK_O       => ack_o,
            ADDR_I      => addr_i,
            CYC_I       => cyc_i,
            ERR_O       => err_o,
            SEL_I       => sel_i,
            STB_I       => stb_i,
            WE_I        => we_i,
            CTI_I       => cti_i,
            spiNCs      => spiNCs,
            spiClk      => spiClk,
            spiMoSi     => spiMoSi,
            spiMiSo     => spiMiSo,
            flashWpN    => flashWpN,
            flashResetN => flashResetN
        );

    clk <= not clk after CLK_PERIOD / 2;

    --! Main Wishbone Stimulus and Automatic Checker Process
    stimulus: process
    begin
        -- System Reset
        rst <= '1';
        wait for 5 * CLK_PERIOD;
        rst <= '0';
        wait for 5 * CLK_PERIOD;

        ------------------------------------------------------------------------
        -- TEST 1: Invalid Write Transaction (Should trigger ERR_O)
        ------------------------------------------------------------------------
        report "Starting Test 1: Invalid Write Transaction";
        addr_i <= x"40001234";
        cyc_i  <= '1';
        stb_i  <= '1';
        we_i   <= '1'; -- Write not supported
        cti_i  <= "000";

        -- Wait for error with a timeout fallback
        for i in 0 to 10 loop
            wait until rising_edge(clk);
            exit when err_o = '1';
        end loop;

        assert err_o = '1' report "Test 1 Failed: ERR_O was not asserted for a write transaction." severity failure;
        assert ack_o = '0' report "Test 1 Failed: ACK_O should not be asserted during an error." severity failure;
        
        cyc_i <= '0';
        stb_i <= '0';
        wait for 5 * CLK_PERIOD;

        ------------------------------------------------------------------------
        -- TEST 2: Invalid Cycle Type (Should trigger ERR_O)
        ------------------------------------------------------------------------
        report "Starting Test 2: Invalid Cycle Type";
        addr_i <= x"40001234";
        cyc_i  <= '1';
        stb_i  <= '1';
        we_i   <= '0'; 
        cti_i  <= "010"; -- Only "000" (Classic) is supported

        for i in 0 to 10 loop
            wait until rising_edge(clk);
            exit when err_o = '1';
        end loop;

        assert err_o = '1' report "Test 2 Failed: ERR_O was not asserted for non-classic CTI_I." severity failure;
        
        cyc_i <= '0';
        stb_i <= '0';
        wait for 5 * CLK_PERIOD;

        ------------------------------------------------------------------------
        -- TEST 3: Ignored Transaction (Out of bounds address)
        ------------------------------------------------------------------------
        report "Starting Test 3: Out of bounds address";
        addr_i <= x"50000000"; -- Outside 0x40000000 base
        cyc_i  <= '1';
        stb_i  <= '1';
        we_i   <= '0';
        cti_i  <= "000";
        
        wait for 10 * CLK_PERIOD;
        assert ack_o = '0' and err_o = '0' report "Test 3 Failed: Module responded to an out-of-bounds address." severity failure;

        cyc_i <= '0';
        stb_i <= '0';
        wait for 5 * CLK_PERIOD;

        ------------------------------------------------------------------------
        -- TEST 4: Valid Classic Read Transaction
        ------------------------------------------------------------------------
        report "Starting Test 4: Valid Read Transaction";
        addr_i <= x"40" & EXPECTED_FLASH_ADDRESS;
        cyc_i  <= '1';
        stb_i  <= '1';
        we_i   <= '0';
        cti_i  <= "000";

        -- Read transactions take longer due to SPI shifting. Wait until ACK.
        loop
            wait until rising_edge(clk);
            exit when ack_o = '1';
        end loop;

        assert dat_o = EXPECTED_FLASH_DATA report "Test 4 Failed: Data mismatch! Expected x""DEADBEEF""." severity failure;
        assert err_o = '0' report "Test 4 Failed: ERR_O was asserted during a valid read." severity failure;

        cyc_i <= '0';
        stb_i <= '0';
        wait for 5 * CLK_PERIOD;

        report "ALL TESTS PASSED.";
        std.env.stop;
    end process;

    --! Procedural Mock SPI Flash (MX25R3235F Mode 0 Behavior)
    mock_flash_proc: process
        variable v_cmd_addr : std_logic_vector(31 downto 0);
    begin
        spiMiSo <= 'Z';
        
        -- Wait for chip select to go active
        wait until falling_edge(spiNCs);

        -- Phase 1: Receive 8-bit Command + 24-bit Address
        -- SPI Mode 0: Slave samples MOSI on the rising edge of SCK
        for i in 31 downto 0 loop
            wait until rising_edge(spiClk);
            v_cmd_addr(i) := spiMoSi;
        end loop;

        -- Verify the controller sent the correct 1-Bit Read command (0x03)
        assert v_cmd_addr(31 downto 24) = x"03" 
            report "Mock Flash Error: Received command was not 0x03." severity failure;
            
        -- Verify the controller sent the correctly mapped 24-bit address 
        -- (Base Address is masked out, leaving the 21-bit physical address padded to 24 bits)
        assert v_cmd_addr(23 downto 0) = EXPECTED_FLASH_ADDRESS
            report "Mock Flash Error: Received address was incorrect. Expected x""00A5A5""." severity failure;
        
        -- Phase 2: Transmit 32-bit Data back to Master
        -- SPI Mode 0: Slave updates MISO on the falling edge of SCK
        -- Transmit lowest byte first, MSB first within each byte.
        for byte_idx in 0 to 3 loop
            for bit_idx in 7 downto 0 loop
                wait until falling_edge(spiClk);
                spiMiSo <= EXPECTED_FLASH_DATA(byte_idx * 8 + bit_idx);
            end loop;
        end loop;

        -- Wait for chip select to be released
        wait until rising_edge(spiNCs);
        spiMiSo <= 'Z';
    end process;

end architecture sim;
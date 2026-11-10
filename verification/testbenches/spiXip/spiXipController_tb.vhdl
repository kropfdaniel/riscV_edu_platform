--------------------------------------------------------------------------------
--! @author     Daniel Kropf
--! @brief      Self-checking testbench for spiXipController.
--!
--! Automatically verifies the FSM command sequencing (0x03 + 24-bit address), 
--! chip select framing (spiNCs), 32-bit data word reconstruction, and 
--! ensures all control outputs (readAck, startByteTransaction, txByte) 
--! adhere strictly to expected pulse widths and values.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spiXipController is
end entity tb_spiXipController;

architecture sim of tb_spiXipController is
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz clock
    
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    
    -- Interface from Bus
    signal startRead : std_logic := '0';
    signal readAddr  : std_logic_vector(23 downto 0) := (others => '0');
    signal readData  : std_logic_vector(31 downto 0);
    signal readAck   : std_logic;
    
    -- Interface to spiByteTransceiver
    signal startByte : std_logic;
    signal txByte    : std_logic_vector(7 downto 0);
    signal rxByte    : std_logic_vector(7 downto 0) := (others => '0');
    signal busyByte  : std_logic := '0';
    
    -- External
    signal spiNCs    : std_logic;

    -- Testbench communication signals
    signal expected_addr : std_logic_vector(23 downto 0);
    signal expected_data : std_logic_vector(31 downto 0);
begin
    uut: entity work.spiXipController
        generic map (
            DataBits => 32,
            AddrBits => 24
        )
        port map (
            clock                => clk,
            reset                => rst,
            startRead            => startRead,
            readAddress          => readAddr,
            readData             => readData,
            readAck              => readAck,
            startByteTransaction => startByte,
            txByte               => txByte,
            rxByte               => rxByte,
            busyByteTransaction  => busyByte,
            spiNCs               => spiNCs
        );

    -- 50 MHz system clock generation
    clk <= not clk after CLK_PERIOD / 2;

    --! Main Stimulus and Verification Process
    stimulus: process
        --! Helper procedure to execute a read and verify the result
        procedure execute_read_test(
            constant test_addr : in std_logic_vector(23 downto 0);
            constant test_data : in std_logic_vector(31 downto 0)
        ) is
        begin
            report "Testing XIP Read at Address: 0x" & to_hstring(test_addr);
            
            -- Pass expected values to the mock transceiver process
            expected_addr <= test_addr;
            expected_data <= test_data;
            
            -- Initiate the read
            readAddr <= test_addr;
            startRead <= '1';
            wait until rising_edge(clk);
            startRead <= '0';
            
            -- Check that Chip Select goes active immediately
            wait for 1 ps;
            assert spiNCs = '0' report "Test Failed: spiNCs did not assert active low." severity failure;
            assert readAck = '0' report "Test Failed: readAck must be low during transaction." severity failure;

            -- Wait for the controller to complete the sequence and flag ACK
            wait until rising_edge(clk) and readAck = '1';
            
            -- Output Assertions at completion
            assert readData = test_data 
                report "Data mismatch! Expected 0x" & to_hstring(test_data) & " but got 0x" & to_hstring(readData) 
                severity failure;
                
            assert spiNCs = '1' report "Test Failed: spiNCs was not released (high) at the end of the transaction." severity failure;
            
            -- Verify readAck is strictly a single-cycle pulse
            wait until rising_edge(clk);
            wait for 1 ps;
            assert readAck = '0' report "Test Failed: readAck did not deassert after one clock cycle." severity failure;
            
            wait for 5 * CLK_PERIOD;
        end procedure;

    begin
        -- System Reset
        rst <= '1';
        wait for 5 * CLK_PERIOD;
        rst <= '0';
        wait for 5 * CLK_PERIOD;
        
        -- Check Idle/Reset States of outputs
        assert spiNCs = '1' report "Reset Error: spiNCs should idle high." severity failure;
        assert readAck = '0' report "Reset Error: readAck should idle low." severity failure;
        assert startByte = '0' report "Reset Error: startByteTransaction should idle low." severity failure;

        -- Test 1: Read a standard word
        execute_read_test(x"123456", x"DEADBEEF");

        -- Test 2: Read another word to ensure FSM fully recovered to IDLE
        execute_read_test(x"CAFE00", x"87654321");

        report "ALL TESTS PASSED.";
        std.env.stop;
    end process;

    --! Procedural Mock Transceiver
    --! Simulates the busy delay of bit shifting, asserts that the controller 
    --! sends the correct command/address sequence (and zero-bytes for reads), 
    --! and feeds back the dummy data.
    mock_transceiver: process
        variable v_byte_transaction_count : integer := 0;
    begin
        busyByte <= '0';
        rxByte <= x"00";
        
        loop
            wait until rising_edge(clk);
            
            if startByte = '1' then
                busyByte <= '1';
                
                -- Simulate the 16 system clock cycles it takes to shift 8 bits
                for i in 1 to 16 loop
                    wait until rising_edge(clk);
                end loop;
                
                -- Verify controller txByte output and feed the appropriate mock data
                case v_byte_transaction_count is
                    when 0 => 
                        -- Phase: SEND_READ_CMD
                        assert txByte = x"03" report "Protocol Error: First byte was not 0x03 (Read Command)." severity failure;
                    when 1 => 
                        -- Phase: SEND_ADDR_HIGH
                        assert txByte = expected_addr(23 downto 16) report "Protocol Error: Incorrect High Address." severity failure;
                    when 2 => 
                        -- Phase: SEND_ADDR_MID
                        assert txByte = expected_addr(15 downto 8) report "Protocol Error: Incorrect Mid Address." severity failure;
                    when 3 => 
                        -- Phase: SEND_ADDR_LOW
                        assert txByte = expected_addr(7 downto 0) report "Protocol Error: Incorrect Low Address." severity failure;
                    
                    -- Controller reads data back during these phases. 
                    -- It assigns the previous transaction's rxByte to readData.
                    when 4 => 
                        -- Phase: RECEIVE_DATA_LOWEST
                        assert txByte = x"00" report "Protocol Error: txByte must be 0x00 during data read phase." severity failure;
                        rxByte <= expected_data(7 downto 0);
                    when 5 => 
                        -- Phase: RECEIVE_DATA_LOW
                        assert txByte = x"00" report "Protocol Error: txByte must be 0x00 during data read phase." severity failure;
                        rxByte <= expected_data(15 downto 8);
                    when 6 => 
                        -- Phase: RECEIVE_DATA_HIGH
                        assert txByte = x"00" report "Protocol Error: txByte must be 0x00 during data read phase." severity failure;
                        rxByte <= expected_data(23 downto 16);
                    when 7 => 
                        -- Phase: RECEIVE_DATA_HIGHEST
                        assert txByte = x"00" report "Protocol Error: txByte must be 0x00 during data read phase." severity failure;
                        rxByte <= expected_data(31 downto 24);
                    when others => 
                        null;
                end case;
                
                -- Release busy flag 
                busyByte <= '0';
                
                -- Track which byte in the 8-byte XIP sequence we are on
                if v_byte_transaction_count = 7 then
                    v_byte_transaction_count := 0;
                else
                    v_byte_transaction_count := v_byte_transaction_count + 1;
                end if;
            end if;
        end loop;
    end process;
    
end architecture sim;
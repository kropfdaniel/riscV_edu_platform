--------------------------------------------------------------------------------
--! @author    Daniel Kropf
--! @copyright MIT License
--! @brief     Self-checking top-level testbench for the Wishbone SPI Master
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spiBus is
end entity tb_spiBus;

architecture sim of tb_spiBus is
    -- 32-bit parameters matching the DUT
    constant C_DATA_BITS : integer := 32;
    constant C_ADDR_BITS : integer := 32;
    constant C_BASE_ADDR : std_logic_vector(31 downto 0) := x"4000_0000";

    -- DUT Signals
    signal clk_i   : std_logic := '0';
    signal rst_i   : std_logic := '1';
    signal dat_i   : std_logic_vector(C_DATA_BITS-1 downto 0) := (others => '0');
    signal dat_o   : std_logic_vector(C_DATA_BITS-1 downto 0);
    signal ack_o   : std_logic;
    signal addr_i  : std_logic_vector(C_ADDR_BITS-1 downto 0) := (others => '0');
    signal cyc_i   : std_logic := '0';
    signal err_o   : std_logic;
    signal sel_i   : std_logic_vector((C_DATA_BITS/8)-1 downto 0) := (others => '0');
    signal stb_i   : std_logic := '0';
    signal we_i    : std_logic := '0';
    signal cti_i   : std_logic_vector(2 downto 0) := "000";

    signal spi_ncs1 : std_logic;
    signal spi_ncs2 : std_logic;
    signal spi_clk  : std_logic;
    signal spi_mosi : std_logic;
    signal spi_miso : std_logic := '0';

    -- System Clock (50 MHz)
    constant CLK_PERIOD : time := 20 ns;

    -- Testbench control signals
    signal tb_slave1_tx_data : std_logic_vector(7 downto 0) := x"C3"; 
    signal tb_slave1_rx_data : std_logic_vector(7 downto 0) := x"00"; 
    
    signal tb_slave2_tx_data : std_logic_vector(7 downto 0) := x"5A"; 
    signal tb_slave2_rx_data : std_logic_vector(7 downto 0) := x"00"; 

    signal slave1_miso : std_logic := 'Z';
    signal slave2_miso : std_logic := 'Z';
    
    signal tb_sim_done : boolean := false;

begin

    -- Instantiate the Top-Level DUT
    dut : entity work.spiBus
        generic map (
            DataBits    => C_DATA_BITS,
            AddrBits    => C_ADDR_BITS,
            BaseAddress => C_BASE_ADDR
        )
        port map (
            CLK_I   => clk_i,
            RST_I   => rst_i,
            DAT_I   => dat_i,
            DAT_O   => dat_o,
            ACK_O   => ack_o,
            ADDR_I  => addr_i,
            CYC_I   => cyc_i,
            ERR_O   => err_o,
            SEL_I   => sel_i,
            STB_I   => stb_i,
            WE_I    => we_i,
            CTI_I   => cti_i,
            spiNCs1 => spi_ncs1,
            spiNCs2 => spi_ncs2,
            spiClk  => spi_clk,
            spiMoSi => spi_mosi,
            spiMiSo => spi_miso
        );

    -- 1. Main System Clock
    clk_i <= not clk_i after CLK_PERIOD / 2 when not tb_sim_done else '0';

    -- Physical MISO Multiplexer
    spi_miso <= slave1_miso when spi_ncs1 = '0' else 
                slave2_miso when spi_ncs2 = '0' else 
                'Z';

    -- 2A. SPI Slave Emulator 1 (nCS1) | Mode 0 (CPOL=0, CPHA=0), MSB First
    process
    begin
        slave1_miso <= 'Z';
        wait until falling_edge(spi_ncs1);
        
        slave1_miso <= tb_slave1_tx_data(7);
        for i in 7 downto 0 loop
            wait until rising_edge(spi_clk);
            tb_slave1_rx_data(i) <= spi_mosi;
            
            wait until falling_edge(spi_clk) or rising_edge(spi_ncs1);
            if spi_ncs1 = '1' then exit; end if; 
            
            if i > 0 then
                slave1_miso <= tb_slave1_tx_data(i-1);
            end if;
        end loop;
        
        wait until rising_edge(spi_ncs1);
    end process;

    -- 2B. SPI Slave Emulator 2 (nCS2) | Mode 3 (CPOL=1, CPHA=1), LSB First
    process
    begin
        slave2_miso <= 'Z';
        wait until falling_edge(spi_ncs2);
        
        for i in 0 to 7 loop
            -- In CPHA=1, shift occurs on the leading edge (falling edge for CPOL=1)
            wait until falling_edge(spi_clk);
            wait for 1 ps; 
            slave2_miso <= tb_slave2_tx_data(i);

            -- In CPHA=1, sample occurs on the trailing edge (rising edge for CPOL=1)
            wait until rising_edge(spi_clk);
            tb_slave2_rx_data(i) <= spi_mosi;
        end loop;
        
        wait until rising_edge(spi_ncs2);
    end process;

    -- 3. Main Stimulus Process (Wishbone Master Procedures Emulator)
    process
        -- =====================================================================
        -- Wishbone Master Procedures
        -- =====================================================================
        procedure wb_write(
            constant addr : in std_logic_vector(31 downto 0);
            constant data : in std_logic_vector(31 downto 0);
            constant sel  : in std_logic_vector(3 downto 0) := "1111"
        ) is
        begin
            wait until rising_edge(clk_i);
            addr_i <= addr;
            dat_i  <= data;
            sel_i  <= sel;
            we_i   <= '1';
            cyc_i  <= '1';
            stb_i  <= '1';
            cti_i  <= "000"; -- Classic cycle
            
            loop
                wait until rising_edge(clk_i);
                if ack_o = '1' or err_o = '1' then
                    exit;
                end if;
            end loop;
            
            cyc_i <= '0';
            stb_i <= '0';
            we_i  <= '0';
        end procedure;

        procedure wb_read(
            constant addr : in std_logic_vector(31 downto 0);
            variable data : out std_logic_vector(31 downto 0)
        ) is
        begin
            wait until rising_edge(clk_i);
            addr_i <= addr;
            we_i   <= '0';
            sel_i  <= "1111";
            cyc_i  <= '1';
            stb_i  <= '1';
            cti_i  <= "000";
            
            loop
                wait until rising_edge(clk_i);
                if ack_o = '1' or err_o = '1' then
                    data := dat_o;
                    exit;
                end if;
            end loop;
            
            cyc_i <= '0';
            stb_i <= '0';
        end procedure;

        -- Testbench variables
        variable v_read_data : std_logic_vector(31 downto 0);
        variable t_edge1 : time;
        variable t_edge2 : time;
        variable t_period : time;
        
        -- Register Addresses based on C_BASE_ADDR
        constant REG_SPI_CR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASE_ADDR) + 16#00#);
        constant REG_SPI_SR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASE_ADDR) + 16#04#);
        constant REG_SPI_DR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASE_ADDR) + 16#08#);
        constant REG_SPI_SS : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASE_ADDR) + 16#0C#);
        
        -- Formula: SPI_SCK = 50MHz / (2 * (2 + 1)) = 8.333 MHz -> 120 ns period
        constant EXPECTED_PERIOD : time := 120 ns;
    begin
        -- =====================================================================
        -- INITIALIZATION
        -- =====================================================================
        rst_i <= '1';
        wait for CLK_PERIOD * 5;
        rst_i <= '0';
        wait for CLK_PERIOD * 5;

        report "--- Starting Wishbone SPI Master Tests ---";

        report "--- STARTING ROUND 1: nCS1, Mode 0, MSB First, CLK_DIV=2 ---";
        -- =====================================================================
        -- TEST 1: Configure SPI Control Register (SPI_CR)
        -- =====================================================================
        -- Write: CLK_DIV = 2, LSBF = 0, CPHA = 0, CPOL = 0, SPI_EN = 1
        -- Data: 0x0002_0001
        report "1. Configuring SPI_CR...";
        wb_write(REG_SPI_CR, x"0002_0001");
        
        -- Read back and verify
        wb_read(REG_SPI_CR, v_read_data);
        assert v_read_data = x"0002_0001" report "FAIL: SPI_CR readback mismatch" severity failure;

        -- =====================================================================
        -- TEST 2: Assert Chip Select 1 (SPI_SS)
        -- =====================================================================
        -- Write: nCS1 = 0, nCS2 = 1 (Active low, so write 0x02 to keep CS2 high, CS1 low)
        report "2. Asserting Chip Select 1...";
        wb_write(REG_SPI_SS, x"0000_0002");
        wait for CLK_PERIOD;
        assert spi_ncs1 = '0' and spi_ncs2 = '1' report "FAIL: Chip Selects not physically asserted" severity failure;

        -- =====================================================================
        -- TEST 3: Transmit Data (SPI_DR)
        -- =====================================================================
        -- Write 0xA5 to the data register to trigger the transaction
        report "3. Writing TX payload to SPI_DR...";
        wb_write(REG_SPI_DR, x"0000_00A5");

        -- =====================================================================
        -- TEST 3.5: Measure SPI Clock Frequency physically
        -- =====================================================================
        report "3.5 Measuring SPI Clock Period...";
        wait until rising_edge(spi_clk);
        t_edge1 := now;
        wait until rising_edge(spi_clk);
        t_edge2 := now;
        t_period := t_edge2 - t_edge1;
        
        assert t_period = EXPECTED_PERIOD 
            report "FAIL: CLK_DIV math is wrong. Expected " & time'image(EXPECTED_PERIOD) & " but got " & time'image(t_period) 
            severity failure;

        -- =====================================================================
        -- TEST 4: Poll Status Register and attempt Malicious Write
        -- =====================================================================
        report "4. Attempting malicious write during active transaction...";
        
        -- Try to overwrite SPI_CR while the bus is busy shifting data
        wb_write(REG_SPI_CR, x"FFFF_FFFF"); 

        -- Now wait for BUSY to drop
        loop
            wb_read(REG_SPI_SR, v_read_data);
            exit when v_read_data(0) = '0';
            wait for CLK_PERIOD * 5;
        end loop;

        -- Verify the hardware ignored our malicious write and kept the original config
        wb_read(REG_SPI_CR, v_read_data);
        assert v_read_data = x"0002_0001" 
            report "FAIL: Hardware interlock failed! SPI_CR was overwritten while BUSY=1" 
            severity failure;

        -- =====================================================================
        -- TEST 5: Verify Received Data
        -- =====================================================================
        report "5. Reading RX payload from SPI_DR...";
        wb_read(REG_SPI_DR, v_read_data);
        
        -- The slave emulator sent tb_slave_tx_data (0xC3)
        assert v_read_data(7 downto 0) = x"C3" 
            report "FAIL: Incorrect RX data read from Wishbone but got 0x" & to_hstring(v_read_data(7 downto 0)) 
            severity failure;
        
        -- We sent 0xA5, check if the slave emulator received it correctly
        assert tb_slave1_rx_data = x"A5" 
        report "FAIL: Slave 1 emulator received incorrect MOSI data but got 0x" & to_hstring(tb_slave1_rx_data) 
        severity failure;

        -- =====================================================================
        -- TEST 6: De-assert Chip Select
        -- =====================================================================
        report "6. De-asserting Chip Select...";
        wb_write(REG_SPI_SS, x"0000_0003"); -- Both high
        wait for CLK_PERIOD;
        assert spi_ncs1 = '1' report "FAIL: nCS1 did not de-assert" severity failure;

        report "--- STARTING ROUND 2: nCS2, Mode 3, LSB First, CLK_DIV=4 ---";

        -- =====================================================================
        -- TEST 7: Reconfigure SPI Control Register
        -- =====================================================================
        -- Write: CLK_DIV = 4 (0x0004), LSBF = 1, CPHA = 1, CPOL = 1, SPI_EN = 1
        -- Bits 3 downto 0: 1111 (0xF) -> 0x0004_000F
        report "7. Configuring SPI_CR for Mode 3, LSB First...";
        wb_write(REG_SPI_CR, x"0004_000F");

        -- =====================================================================
        -- TEST 8: Assert Chip Select 2
        -- =====================================================================
        -- Write: nCS1 = 1, nCS2 = 0 (Write 0x01)
        report "8. Asserting Chip Select 2...";
        wb_write(REG_SPI_SS, x"0000_0001");
        wait for CLK_PERIOD;
        assert spi_ncs1 = '1' and spi_ncs2 = '0' report "FAIL: nCS2 did not physically assert" severity failure;

        -- =====================================================================
        -- TEST 9: Transmit Payload
        -- =====================================================================
        report "9. Writing TX payload (0x99) to SPI_DR...";
        wb_write(REG_SPI_DR, x"0000_0099");

        -- =====================================================================
        -- TEST 10: Measure Frequency and Poll Status
        -- =====================================================================
        report "10. Polling SPI_SR and measuring clock...";
        wait until falling_edge(spi_clk); -- First edge in CPOL=1 is falling
        t_edge1 := now;
        wait until falling_edge(spi_clk);
        t_edge2 := now;
        
        -- Expected: 50MHz / (2 * (4 + 1)) = 5 MHz -> 200 ns
        assert (t_edge2 - t_edge1) = 200 ns report "FAIL: CLK_DIV=4 generated wrong frequency" severity failure;

        loop
            wb_read(REG_SPI_SR, v_read_data);
            exit when v_read_data(0) = '0';
            wait for CLK_PERIOD * 10;
        end loop;

        -- =====================================================================
        -- TEST 11: Verify Mode 3 Received Data
        -- =====================================================================
        report "11. Reading RX payload from SPI_DR...";
        wb_read(REG_SPI_DR, v_read_data);
        
        assert v_read_data(7 downto 0) = x"5A" 
            report "FAIL: Incorrect RX data in Round 2. Got 0x" & to_hstring(v_read_data(7 downto 0)) 
            severity failure;
        assert tb_slave2_rx_data = x"99" 
            report "FAIL: Slave 2 emulator received incorrect MOSI data but got 0x" & to_hstring(tb_slave2_rx_data) 
            severity failure;

        -- =====================================================================
        -- TEST 12: De-assert All
        -- =====================================================================
        report "12. De-asserting Chip Selects...";
        wb_write(REG_SPI_SS, x"0000_0003");

        report "SUCCESS: All multi-configuration Wishbone transactions passed.";
        tb_sim_done <= true;
        std.env.finish;
    end process;
end architecture sim;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_system_top is
end entity tb_system_top;

architecture sim of tb_system_top is

    -- Signals for the Unit Under Test (UUT)
    signal s_clk       : std_logic := '0';
    signal s_nreset    : std_logic := '0';
    signal spiNCs      : std_logic;
    signal spiClk      : std_logic;
    signal spiMoSi     : std_logic;
    signal spiMiSo     : std_logic := '1';
    signal flashWpN    : std_logic;
    signal flashResetN : std_logic;

    -- 50 MHz Clock period
    constant CLK_PERIOD : time := 20 ns;

    -- Mock Flash Memory Array (holding our RISC-V program)
    type rom_type is array (0 to 23) of std_logic_vector(7 downto 0);
    constant MOCK_FLASH_ROM : rom_type := (
        x"93", x"00", x"50", x"00", -- 0x00: addi x1, x0, 5   | Load 5 into register x1
        x"13", x"01", x"a0", x"00", -- 0x04: addi x2, x0, 10  | Load 10 into register x2
        x"b3", x"81", x"20", x"00", -- 0x08: add  x3, x1, x2  | Add x1 + x2 and store the result (15) in x3
        x"93", x"91", x"01", x"01", -- 0x0C: slli x3, x3, 16  | Shift 15 left by 16 bits (x3 = 0x0F0000)
        x"83", x"a2", x"01", x"00", -- 0x10: lw   x5, 0(x3)   | Read from 0x0F0000 (Forces SPI to output address)
        x"6f", x"00", x"00", x"00"  -- 0x14: j .              | Infinite loop
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
            flashWpN    => flashWpN,
            flashResetN => flashResetN
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
        
        -- Watchdog timeout: If 200us pass without a successful SPI read, the CPU hung.
        wait for 200 us;
        report "TEST FAILED: Simulation timed out!" severity failure;

    end process;

    -- =================================================================
    -- MOCK SPI FLASH (Mode 0: CPOL=0, CPHA=0, Read Cmd = 0x03)
    -- =================================================================
    process(spiNCs, spiClk)
        variable bit_cnt : integer := 0;
        variable shift_in : std_logic_vector(31 downto 0);
        variable addr     : integer := 0;
        variable byte_out : std_logic_vector(7 downto 0);
    begin
        if spiNCs = '1' then
            spiMiSo <= '1';
            bit_cnt := 0;
        else
            -- Sample MOSI on Rising Edge
            if rising_edge(spiClk) then
                shift_in := shift_in(30 downto 0) & spiMoSi;
                bit_cnt := bit_cnt + 1;
                
                -- After 32 bits (8 bit cmd + 24 bit addr), we have the address
                if bit_cnt = 32 then
                    addr := to_integer(unsigned(shift_in(23 downto 0)));

                    -- Ignore standard instruction fetches (addresses 0 to 23).
                    -- The only other read requested by our program is the lw test.
                    if addr > 23 then
                        
                        -- Exactly check the correct address using VHDL assert
                        assert addr = 16#0F0000#
                            report "TEST FAILED: CPU requested wrong SPI address! Expected 983040 (0x0F0000) but got " & integer'image(addr)
                            severity failure;
                            
                        report "TEST PASSED: CPU correctly calculated 15 and requested SPI address 0x0F0000!";
                        std.env.finish; -- End successfully
                    end if;
                end if;
            end if;
            
            -- Shift out MISO on Falling Edge
            if falling_edge(spiClk) then
                if bit_cnt >= 32 then
                    if (bit_cnt mod 8) = 0 then
                        -- Fetch next byte from ROM
                        -- modulo 16 ensures we wrap around if SERV fetches out of bounds
                        byte_out := MOCK_FLASH_ROM(addr mod 24); 
                        addr := addr + 1;
                    else
                        -- Shift byte
                        byte_out := byte_out(6 downto 0) & '0';
                    end if;
                    spiMiSo <= byte_out(7);
                end if;
            end if;
        end if;
    end process;

end architecture sim;
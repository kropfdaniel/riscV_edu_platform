--------------------------------------------------------------------------------
--! @author     Daniel Kropf
--! @brief      Synthesizable Hardware-in-the-Loop Tester for spiXipBus.
--!
--! Designed to run on the Gecko 5 board. It acts as a Wishbone Master, 
--! sequentially reading the entire firmware via the spiXipBus module and 
--! verifying the fetched 32-bit words against the embedded FIRMWARE_DATA array.
--! Uses the LED matrix to indicate Pass (Green) or Fail (Red).
--! Assumes that the Flash is previously programmed with firmware.vhdl
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.firmware_pkg.all;

entity xip_hardware_tester is
    port (
        clock      : in  std_logic;
        nReset     : in  std_logic;
        nButton    : in  std_logic;
        
        -- SPI ports
        spiClk     : out std_logic;
        spiNCs     : out std_logic;
        spiSiIo0   : out std_logic;
        spiSoIo1   : in  std_logic;
        spiIo2     : out std_logic;
        spiIo3     : out std_logic;

        -- LED Matrix
        colSelect  : out std_logic_vector( 3 downto 0 );
        nRedLeds   : out std_logic_vector( 9 downto 0 );
        nGreenLeds : out std_logic_vector( 9 downto 0 );
        nBlueLeds  : out std_logic_vector( 9 downto 0 )
    );
end entity;

architecture rtl of xip_hardware_tester is

    -- Wishbone Master Signals
    constant BASE_ADDR : std_logic_vector(31 downto 0) := x"40000000";
    signal wb_dat_o    : std_logic_vector(31 downto 0);
    signal wb_ack_o    : std_logic;
    signal wb_err_o    : std_logic;
    signal wb_addr_i   : std_logic_vector(31 downto 0);
    signal wb_cyc_i    : std_logic;
    signal wb_stb_i    : std_logic;
    
    -- Tester FSM States
    type tester_state_t is (IDLE, SET_READ_REQ, WAIT_ACK, CHECK_DATA, DONE_SUCCESS, DONE_ERROR);
    signal fsm_state : tester_state_t := IDLE;
    
    -- Counters & Data
    constant TOTAL_WORDS : integer := FIRMWARE_LENGTH / 4; -- 188 / 4 = 47 words
    signal word_idx      : integer range 0 to TOTAL_WORDS;
    signal expected_word : std_logic_vector(31 downto 0);
    
    -- Button Synchronization
    signal s_button, s_reset  : std_logic;
    signal s_dividedClockTick : std_logic;
    signal s_buttonPressed    : std_logic;

begin

    -- Initialize LED Matrix Columns (Active Low)
    colSelect <= X"0";
    nBlueLeds <= (others => '1');

    s_button <= not(nButton); -- the buttons are active low
    s_reset  <= not(nReset);  -- the user reset button is active low

    -- first we instantiate the debounce counter
    divider1 : entity work.genClockDiv(hello)
        generic map (
            clockFrequency => 74250000, -- we use the 74.25MHz clock
            tickFrequency  => 1000      -- we use a scanning of 1 kHz
        )
        port map (
            clock => clock,
            reset => s_reset,
            tick  => s_dividedClockTick
        );

    -- here is the edgedetection placed
    isPressed : entity work.edgeDetector(hello)
        port map (
            clock       => clock,
            reset       => s_reset,
            enable      => s_dividedClockTick,
            inputValue  => s_button,
            risingEdge  => s_buttonPressed,
            fallingEdge => open
        );

    -- Instantiating the Device Under Test (DUT)
    uut_spiXipBus : entity work.spiXipBus
        generic map (
            DataBits       => 32,
            AddrBits       => 32,
            BaseAddress    => BASE_ADDR,
            FlashAddrWidth => 21
        )
        port map (
            CLK_I       => clock,
            RST_I       => s_reset,
            DAT_O       => wb_dat_o,
            ACK_O       => wb_ack_o,
            ADDR_I      => wb_addr_i,
            CYC_I       => wb_cyc_i,
            ERR_O       => wb_err_o,
            STB_I       => wb_stb_i,
            WE_I        => '0',        -- Read only
            CTI_I       => "000",      -- Classic cycle
            
            -- Map to physical SPI pins of the Gecko 5 board
            spiNCs      => spiNCs,
            spiClk      => spiClk,
            spiMoSi     => spiSiIo0,
            spiMiSo     => spiSoIo1,
            flashWpN    => spiIo2,
            flashResetN => spiIo3
        );

    -- Verification FSM
    process(clock)
    begin
        if rising_edge(clock) then
            if s_reset then
                fsm_state <= IDLE;
                wb_cyc_i  <= '0';
                wb_stb_i  <= '0';
                wb_addr_i <= (others => '0');
                word_idx  <= 0;
                
                -- Turn off LEDs (Active Low) 
                nRedLeds   <= (others => '1');
                nGreenLeds <= (others => '1');
            else
                case fsm_state is
                    
                    when IDLE =>
                        wb_cyc_i <= '0';
                        wb_stb_i <= '0';
                        word_idx <= 0;
                        nRedLeds   <= (others => '1');
                        nGreenLeds <= (others => '1');
                        
                        -- Wait for user to press button to start the test
                        if s_buttonPressed = '1' then
                            fsm_state <= SET_READ_REQ;
                        end if;

                    when SET_READ_REQ =>
                        -- Set Wishbone Address = BASE_ADDR + (word_idx * 4)
                        wb_addr_i <= std_logic_vector(unsigned(BASE_ADDR) + to_unsigned(word_idx * 4, 32));
                        wb_cyc_i  <= '1';
                        wb_stb_i  <= '1';
                        
                        -- Prepare the expected data for the upcoming check
                        -- Map firmware byte array to 32-bit word (Lowest address to Lowest byte)
                        expected_word(7 downto 0)   <= FIRMWARE_DATA(word_idx * 4 + 0);
                        expected_word(15 downto 8)  <= FIRMWARE_DATA(word_idx * 4 + 1);
                        expected_word(23 downto 16) <= FIRMWARE_DATA(word_idx * 4 + 2);
                        expected_word(31 downto 24) <= FIRMWARE_DATA(word_idx * 4 + 3);
                        
                        fsm_state <= WAIT_ACK;

                    when WAIT_ACK =>
                        if wb_err_o = '1' then
                            -- Bus error occurred
                            wb_cyc_i  <= '0';
                            wb_stb_i  <= '0';
                            fsm_state <= DONE_ERROR;
                        elsif wb_ack_o = '1' then
                            -- Read completed successfully
                            wb_cyc_i  <= '0';
                            wb_stb_i  <= '0';
                            fsm_state <= CHECK_DATA;
                        end if;

                    when CHECK_DATA =>
                        -- Compare fetched Wishbone data against the embedded ROM expected data
                        if wb_dat_o = expected_word then
                            -- Match!
                            if word_idx = TOTAL_WORDS - 1 then
                                -- Finished all words
                                fsm_state <= DONE_SUCCESS;
                            else
                                -- Move to the next word
                                word_idx  <= word_idx + 1;
                                fsm_state <= SET_READ_REQ;
                            end if;
                        else
                            -- Mismatch!
                            fsm_state <= DONE_ERROR;
                        end if;

                    when DONE_SUCCESS =>
                        -- Turn on a Green LED
                        nGreenLeds(0) <= '0';
                        
                        -- Allow restart
                        if s_buttonPressed = '1' then
                            fsm_state <= IDLE;
                        end if;

                    when DONE_ERROR =>
                        -- Turn on a Red LED
                        nRedLeds(0) <= '0';
                        
                        -- Allow restart
                        if s_buttonPressed = '1' then
                            fsm_state <= IDLE;
                        end if;
                        
                end case;
            end if;
        end if;
    end process;

end architecture rtl;
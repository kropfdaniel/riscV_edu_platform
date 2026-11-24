--------------------------------------------------------------------------------
--! @author    Daniel Kropf
--! @copyright MIT License
--! @brief     16-bit low-power interrupt timer.
--!
--! Implements a single-register 32-bit Wishbone Classic slave with a 16-bit
--! down-counter and a 2^N power-of-2 prescaler. Both counters are held idle
--! when `TIMER_EN` is 0 to minimize dynamic switching power.
--!
--! Writing `TIMER_EN` from 0 to 1 resets the prescaler and atomically loads
--! the counter from `RELOAD` (using the incoming bus bytes if `SEL_I(3:2)`
--! are asserted, otherwise the stored `RELOAD` value). Writes to `RELOAD`
--! while the timer is running are buffered until the next underflow or restart.
--!
--! Changing `PRESCALE` while timer is running takes effect immediately. 
--! Disable the timer first for deterministic timing.
--!
--! Prescaler Tick Equation:   `f_tick = CLK_I / (2^PRESCALE)`
--! Interrupt Period Equation: `T_irq  = ((RELOAD + 1) * 2^PRESCALE) / CLK_I`
--!
--! ### Register Map
--!
--! | Offset | Register | Bits  | Field      | Access | Description                                                           |
--! |--------|----------|-------|------------|--------|-----------------------------------------------------------------------|
--! | `0x00` | `TIMER`  | 31:16 | `RELOAD`   | R/W    | 16-bit counter reload value (buffered while `TIMER_EN` = 1)           |
--! |        |          | 15:9  | Reserved   | R/O    | Read as 0                                                             |
--! |        |          | 8     | `IRQ_PEND` | R/W1C  | Interrupt pending flag. Set by hardware on expiry; write 1 to clear   |
--! |        |          | 7:4   | `PRESCALE` | R/W    | Power-of-2 clock prescaler (`0` = /1, `1` = /2, ..., `15` = /32768)   |
--! |        |          | 3     | Reserved   | R/O    | Read as 0                                                             |
--! |        |          | 2     | `IRQ_EN`   | R/W    | Interrupt output enable (`1` = enabled, `0` = masked)                 |
--! |        |          | 1     | `MODE`     | R/W    | `0` = One-shot (auto-clears `TIMER_EN`), `1` = Periodic (auto-reload) |
--! |        |          | 0     | `TIMER_EN` | R/W    | `1` = Timer enabled, `0` = Timer halted (counters frozen)             |
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer16 is
    generic (
        --! Number of Wishbone Data Bits. Only 32-bit data width is currently supported.
        DataBits    : integer                                   := 32;
        --! Number of Wishbone Address Bits.
        AddrBits    : integer                                   := 32;
        --! Base Wishbone address of this module (used by interconnect, not internally).
        BaseAddress : std_logic_vector(AddrBits-1 downto 0)     := (others => '0')
    );
    port (
        -- Wishbone Signals
        --! clock input
        CLK_I       : in  std_logic;
        --! reset input
        RST_I       : in  std_logic;
        --! data input
        DAT_I       : in  std_logic_vector(DataBits-1 downto 0);
        --! data output
        DAT_O       : out std_logic_vector(DataBits-1 downto 0);
        -- TAGD_I and TAGD_O are not implemented
        --! acknowledge output
        ACK_O       : out std_logic;
        --! address input
        ADDR_I      : in  std_logic_vector(AddrBits-1 downto 0);
        --! cycle input
        CYC_I       : in  std_logic;
        --! error output
        ERR_O       : out std_logic;
        -- LOCK_I is not used in this module
        -- RTY_I is not implemented
        --! select input
        SEL_I       : in  std_logic_vector((DataBits/8)-1 downto 0);
        --! strobe input
        STB_I       : in  std_logic;
        -- TGA_O and TGC_O are not implemented
        --! write enable input
        WE_I        : in  std_logic;
        --! Cycle type input. Only Classic cycle type "000" supported.
        CTI_I       : in  std_logic_vector(2 downto 0);
        -- BTE_I is not used in this module

        --! Chip select control lines
        timer_irq   : out std_logic
    );
end entity timer16;

architecture rtl of timer16 is
    --! wishbone acknowledge register
    signal s_ackReg               : std_logic;
    --! wishbone error register (error happens if CTI_I/="000")
    signal s_errorReg             : std_logic;

    --! flag if CYC_I and STB_I are set and the address on the bus is within the address space for this module
    signal s_isMyTransaction      : std_logic;
    --! flag if the transaction is mine and of type classic (CTI_I="000")
    signal s_isCorrectTransaction : std_logic;
    --! single-cycle write enable strobe
    signal s_we                   : std_logic;

    -- Timer Register
    --! Counter Reload Value register
    signal s_reloadReg            : unsigned(15 downto 0);
    --! Interrupt Pending register
    signal s_irqPendReg           : std_logic;
    --! Prescale Register
    signal s_prescaleReg          : std_logic_vector(3 downto 0);
    --! Interrupt Enable register
    signal s_irqEnReg             : std_logic;
    --! Timer Mode register
    signal s_modeReg              : std_logic;
    --! Timer Enable register
    signal s_timerEnReg           : std_logic;

    --! Internal timer counter register
    signal s_counterReg           : unsigned(15 downto 0);
    --! Internal counter register for the prescaler
    signal s_prescaleCounterReg   : unsigned(14 downto 0);

    --! Detect EN 0 --> 1 transition
    signal s_start                : std_logic;
    --! Byte-aware reload value for atomic starts
    signal s_loadValue            : unsigned(15 downto 0);
    --! Next prescaler value (16-bit to tap bit N for 2^N division)
    signal s_prescaleNext         : unsigned(15 downto 0);
    --! Single-cycle prescaler tick
    signal s_prescaleTick         : std_logic;
    --! Next counter value
    signal s_counterNext          : unsigned(16 downto 0);
    --! Single-cycle timer expiry event
    signal s_timerExpired         : std_logic;
begin
    ERR_O               <= s_errorReg;
    ACK_O               <= s_ackReg;
    DAT_O(31 downto 16) <= std_logic_vector(s_reloadReg);
    DAT_O(15 downto  9) <= (others => '0');
    DAT_O(8)            <= s_irqPendReg;
    DAT_O( 7 downto  4) <= s_prescaleReg;
    DAT_O(3)            <= '0';
    DAT_O(2)            <= s_irqEnReg;
    DAT_O(1)            <= s_modeReg;
    DAT_O(0)            <= s_timerEnReg;
    
    timer_irq <= s_irqPendReg and s_irqEnReg;
    
    -- if the address on the bus is within the address space for this module
    s_isMyTransaction <= (CYC_I and STB_I) when ADDR_I( AddrBits-1 downto 2 ) = BaseAddress( AddrBits-1 downto 2 ) else '0';
    -- if it is classic cycle type
    s_isCorrectTransaction <= s_isMyTransaction when CTI_I = "000" else '0'; 
    
    -- Single-cycle write strobe
    s_we <= not(s_ackReg) and s_isCorrectTransaction and WE_I;
    
    -- Detect EN 0 --> 1 transition
    s_start <= '1' when s_we = '1' and SEL_I(0) = '1' and 
                        s_timerEnReg = '0' and DAT_I(0) = '1' 
                    else '0'; 

    -- Select incoming reload bytes on atomic start, otherwise keep stored reload value
    s_loadValue(7 downto 0)  <= unsigned(DAT_I(23 downto 16)) when SEL_I(2) = '1' else
                                s_reloadReg(7 downto 0);
    s_loadValue(15 downto 8) <= unsigned(DAT_I(31 downto 24)) when SEL_I(3) = '1' else
                                s_reloadReg(15 downto 8);

    -- Prescale counter
    s_prescaleNext <= ('0' & s_prescaleCounterReg) + 1;
    s_prescaleTick <= s_timerEnReg and s_prescaleNext(to_integer(unsigned(s_prescaleReg)));

    s_counterNext  <= ('0' & s_counterReg) - 1;
        
    s_timerExpired <= s_prescaleTick and s_counterNext(16);

    --! Wishbone interface process
    makeBusRegs : process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                s_ackReg         <= '0';
                s_errorReg       <= '0';
            else
                s_ackReg   <= not(s_ackReg) and s_isCorrectTransaction;
                s_errorReg <= not(s_errorReg) and s_isMyTransaction and not(s_isCorrectTransaction);
            end if;
        end if;
    end process makeBusRegs;

    --! Timer Register write process. 
    timerRegs : process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                s_reloadReg   <= (others => '0');
                s_irqPendReg  <= '0';
                s_prescaleReg <= (others => '0');
                s_irqEnReg    <= '0';
                s_modeReg     <= '0';
                s_timerEnReg  <= '0';
            else
                -- Wishbone write
                if s_we = '1' then
                    -- Byte 0: Configuration Bits
                    if SEL_I(0) then
                        s_prescaleReg <= DAT_I(7 downto 4);
                        s_irqEnReg    <= DAT_I(2);
                        s_modeReg     <= DAT_I(1);
                        s_timerEnReg  <= DAT_I(0);
                    end if;
                    -- Byte 1: interrupt pending bit write to clear
                    if SEL_I(1) = '1' and DAT_I(8) = '1' then
                        s_irqPendReg <= '0'; -- Write 1 to clear
                    end if;
                    -- Byte 2: Lower byte of RELOAD (Data bits 23:16 -> RELOAD 7:0)
                    if SEL_I(2) then
                        s_reloadReg(7 downto 0) <= unsigned(DAT_I(23 downto 16));
                    end if;
                    -- Byte 3: Upper byte of RELOAD (Data bits 31:24 -> RELOAD 15:8)
                    if SEL_I(3) then
                        s_reloadReg(15 downto 8) <= unsigned(DAT_I(31 downto 24));
                    end if;
                end if;

                -- Automatic Hardware expiry
                if s_timerExpired then 
                    s_irqPendReg <= '1'; -- set interrupt register
                    if s_modeReg = '0' then 
                        s_timerEnReg <= '0'; -- in one-shot mode automatically disable timer
                    end if;
                end if;
            end if;
        end if;
    end process timerRegs;

    --! Prescaler counter process
    prescaler : process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' or s_start = '1' then
                s_prescaleCounterReg <= (others => '0');
            elsif s_timerEnReg = '1' then
                if s_prescaleTick = '1' then
                    s_prescaleCounterReg <= (others => '0');
                else
                    s_prescaleCounterReg <= s_prescaleNext(14 downto 0);
                end if;
            end if;
        end if;
    end process prescaler;

    --! Main 16-bit down-counter process
    counter : process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                s_counterReg <= (others => '0');
            elsif s_start = '1' then
                s_counterReg <= s_loadValue;
            elsif s_prescaleTick = '1' then
                if s_counterReg = 0 then
                    if s_modeReg = '1' then
                        s_counterReg <= s_reloadReg; -- auto-reload
                    end if;
                else
                    s_counterReg <= s_counterNext(15 downto 0);
                end if;
            end if;
        end if;
    end process counter;
end architecture;
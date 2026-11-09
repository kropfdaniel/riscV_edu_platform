--------------------------------------------------------------------------------
--! @author Daniel Kropf
--! @copyright MIT License
--! @brief Fixed tick generator for SPI masters using a generic divisor.
--!
--! Derives 4x and 2x tick pulses from a 50 MHz reference clock.
--! Includes integrated 2-stage synchronizers (synchroFlop) to safely 
--! cross tick pulses into the destination clock domain.
--!          
--! **Note:** Adapted from the original UART baud generator design by Dr Theo Kluter.
--!
--! **Formula:**       
--! `TICK_DIVISOR = f_50MHz / (4 * f_SCK)` 
--!
--! *Example (1 MHz SCK):* `50,000,000 / (4 * 1,000,000) = 12.5 -> 13`
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tickGenerator is
  
  generic( 
    --! Configuration value defining the 4x clock period
    TICK_DIVISOR : unsigned(15 downto 0) := to_unsigned(13, 16)
  );
  port( 
    --! Destination system clock domain for synchronized ticks
    clock           : in  std_logic;
    --! Reference clock for internal counters
    clock_50MHz     : in  std_logic;
    --! Active-high system reset
    reset           : in  std_logic;
    --! Single-cycle tick pulsing at 4x the target SPI frequency
    tickRateX4Tick  : out std_logic;
    --! Single-cycle tick pulsing at 2x the target SPI frequency (SCK toggle rate)
    tickRateX2Tick  : out std_logic
  );
end entity tickGenerator;

architecture behav of tickGenerator is

  --! Primary 16-bit down-counter register defining the 4x tick period
  signal s_counterReg      : unsigned(15 downto 0);
  --! Combinatorial next-state value for the primary down-counter
  signal s_counterNext     : unsigned(15 downto 0);
  --! Latched reset state used to mask out false tick pulses during startup
  signal s_counterResetReg : std_logic;
  --! Heartbeat flag active when the primary counter reaches zero
  signal s_counterLoad     : std_logic;
  --! 1-bit toggle register used to divide the 4x tick down to a 2x tick
  signal s_tickDivReg      : std_logic;
  --! Combinatorial next-state for the 2x toggle register
  signal s_tickDivNext     : std_logic;
  --! Flag indicating when the toggle register is zero
  signal s_tickDivIsZero   : std_logic;
  --! Raw, unsynchronized 4x tick pulse generated in the 50 MHz domain
  signal s_tickRateX4Tick  : std_logic;
  --! Raw, unsynchronized 2x tick pulse generated in the 50 MHz domain
  signal s_tickRateX2Tick  : std_logic;
  
begin
  s_counterLoad     <= '1' when s_counterReg(15 downto 1) = to_unsigned(0, 15) else '0';
  s_counterNext     <= TICK_DIVISOR when reset = '1' or s_counterLoad = '1' else s_counterReg - to_unsigned(1, 16);
  s_tickDivNext     <= '1' when reset = '1' else
                       not(s_tickDivReg) when s_counterLoad = '1' else s_tickDivReg;
  s_tickDivIsZero   <= not(s_tickDivReg);
  s_tickRateX4Tick  <= s_counterLoad and not(s_counterResetReg);
  s_tickRateX2Tick  <= s_counterLoad and s_tickDivIsZero and not(s_counterResetReg);
  
  --! Sequential process driving primary counter registers and toggle dividers on the 50 MHz clock edge.
  makeFlops : process( clock_50MHz )
  begin
    if (rising_edge( clock_50MHz )) then
      s_counterResetReg <= reset;
      s_counterReg      <= s_counterNext;
      s_tickDivReg      <= s_tickDivNext;
    end if;
  end process makeFlops;
  
  --! Dual-flop synchronizer (from modules/support) crossing the 4x tick pulse into the destination system clock domain
  tick4 : entity work.synchroFlop(platformIndependant)
    port map ( clockIn  => clock_50MHz,
               clockOut => clock,
               reset    => reset,
               D        => s_tickRateX4Tick,
               Q        => tickRateX4Tick);

  --! Dual-flop synchronizer (from modules/support) crossing the 2x tick pulse into the destination system clock domain
  tick2 : entity work.synchroFlop(platformIndependant)
    port map ( clockIn  => clock_50MHz,
               clockOut => clock,
               reset    => reset,
               D        => s_tickRateX2Tick,
               Q        => tickRateX2Tick);
end architecture behav;

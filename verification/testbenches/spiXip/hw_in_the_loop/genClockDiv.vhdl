library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity genClockDiv is
  generic ( clockFrequency : integer := 50000000;
            tickFrequency  : integer := 1000);
  port ( clock : in  std_logic;
         reset : in  std_logic;
         tick  : out std_logic);
end genClockDiv;

architecture hello of genClockDiv is

  constant reloadValue : integer := clockFrequency / tickFrequency;
  constant nrOfBits    : integer := integer(ceil(log2(real(reloadValue))));
  
  signal counterRegister : unsigned( nrOfBits-1 downto 0 );

begin
  tick <= '1' when counterRegister = to_unsigned(0, nrOfBits) else '0';
  
  makeCounter : process( clock ) is
  begin
    if (rising_edge(clock)) then
      if (reset = '1' or counterRegister = to_unsigned(0, nrOfBits)) then
        counterRegister <= to_unsigned( reloadValue - 1, nrOfBits);
                                                                     else
        counterRegister <= counterRegister - to_unsigned(1, nrOfBits);
      end if;
    end if;
  end process makeCounter;
end hello;
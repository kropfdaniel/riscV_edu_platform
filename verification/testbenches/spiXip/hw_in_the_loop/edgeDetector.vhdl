library ieee;
use ieee.std_logic_1164.all;

entity edgeDetector is
  port ( clock       : in  std_logic;
         reset       : in  std_logic;
         enable      : in  std_logic;
         inputValue  : in  std_logic;
         risingEdge  : out std_logic;
         fallingEdge : out std_logic);
end edgeDetector;

architecture hello of edgeDetector is

  signal edgeRegisters : std_logic_vector( 2 downto 0 );

begin
  risingEdge  <= not( edgeRegisters(2) ) and edgeRegisters(1);
  fallingEdge <= edgeRegisters(2) and not ( edgeRegisters(1) );
  
  makeRegs : process( clock ) is
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then
        edgeRegisters <= inputValue&inputValue&inputValue;
      else
        edgeRegisters(2 downto 1) <= edgeRegisters(1 downto 0);
        if (enable = '1') then
          edgeRegisters(0) <= inputValue;
        end if;
      end if;
    end if;
  end process makeRegs;
end hello;
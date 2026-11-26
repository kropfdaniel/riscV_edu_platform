library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tickGenerator is
    generic (
        Divider : positive := 50_000  -- 50 MHz / 50_000 = 1 kHz
    );
    port (
        clock50Mhz : in  std_logic;
        reset      : in  std_logic;
        oneKhzTick : out std_logic
    );
end entity tickGenerator;

architecture rtl of tickGenerator is
    constant c_cntWidth : positive := integer(ceil(log2(real(Divider))));
    constant c_reload   : unsigned(c_cntWidth - 1 downto 0) := to_unsigned(Divider - 1, c_cntWidth);
    signal   s_counter  : unsigned(c_cntWidth - 1 downto 0);
begin

    counter : process (clock50Mhz) is
    begin
        if rising_edge(clock50Mhz) then
            if reset = '1' then
                s_counter <= c_reload;
            elsif s_counter = 0 then
                s_counter <= c_reload;
            else
                s_counter <= s_counter - 1;
            end if;
        end if;
    end process counter;

    oneKhzTick <= '1' when s_counter = 0 else '0';

end architecture rtl;
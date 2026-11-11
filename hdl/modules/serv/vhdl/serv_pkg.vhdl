----------------------------------------------------------------------------------
-- File: serv_pkg.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV helper functions and constants
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

package serv_pkg is
    function bool_to_int(bool : boolean) return integer;
    function clog2(value : integer) return natural;
    type std_logic_array_t is array (natural range <>) of std_logic_vector;
end package;

package body serv_pkg is
    function bool_to_int(bool : boolean) return integer is
    begin
        if bool then
            return 1;
        else
            return 0;
        end if;
    end function;

    function clog2(value : integer) return natural is
    begin
        return natural(ceil(log2(real(value))));
    end function clog2;
end package body serv_pkg;
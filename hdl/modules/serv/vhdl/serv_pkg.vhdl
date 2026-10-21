----------------------------------------------------------------------------------
-- File: serv_pkg.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV helper functions and constants
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package serv_pkg is
    function bool_to_int(bool : boolean) return integer;
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
end package body serv_pkg;
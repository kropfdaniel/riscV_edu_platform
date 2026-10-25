-- File: serv_rf_ram.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SRAM-based RF storage for SERV
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2019 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.serv_pkg.all;

entity serv_rf_ram is
    generic(
        width          : integer := 0;
        csr_regs       : integer := 4;
        depth          : integer := 32*(32+csr_regs)/width
    );
    port(
        i_clk               : in  std_logic;
        i_waddr             : in  std_logic_vector(clog2(depth)-1 downto 0);
        i_wdata             : in  std_logic_vector(width-1 downto 0);
        i_wen               : in  std_logic;
        i_raddr             : in  std_logic_vector(clog2(depth)-1 downto 0);
        i_ren               : in  std_logic;
        o_rdata             : out std_logic_vector(width-1 downto 0)
    );
end entity serv_rf_ram;

architecture rtl of serv_rf_ram is
    signal memory  : std_logic_array_t(0 to depth-1)(width-1 downto 0) := (others => (others => '0'));
    signal rdata   : std_logic_vector(width-1 downto 0);
    signal regzero : std_logic;
begin
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_wen then
                memory(to_integer(unsigned(i_waddr))) <= i_wdata;
            end if;
            if i_ren then
                rdata <= memory(to_integer(unsigned(i_raddr)));
            else
                rdata <= (others => 'X');
            end if;
            -- Reads from reg x0 needs to return 0
            -- Check that the part of the read address corresponding to the register
            -- is zero and gate the output
            -- width LSB of reg index clog2(width)
            -- 2     4                1
            -- 4     3                2
            -- 8     2                3
            -- 16    1                4
            -- 32    0                5
            regzero <= nor i_raddr(clog2(depth)-1 downto 5-clog2(width));
        end if;
    end process;

    o_rdata <= rdata and not(width-1 downto 0 => regzero);
end architecture rtl;
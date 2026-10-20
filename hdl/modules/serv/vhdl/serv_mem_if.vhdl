----------------------------------------------------------------------------------
-- File: serv_mem_if.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV memory interface
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2018 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_mem_if is
    generic(
        WITH_CSR       : boolean := true;
        W              : integer := 1;
        B              : integer := W-1
    );
    port(
        i_clk               : in  std_logic;
        -- State
        i_bytecnt           : in  std_logic_vector(1 downto 0);
        i_lsb               : in  std_logic_vector(1 downto 0);
        o_misalign          : out std_logic;
        -- Control
        i_signed            : in  std_logic;
        i_word              : in  std_logic;
        i_half              : in  std_logic;
        -- MDU
        i_mdu_op            : in  std_logic;
        -- Data
        i_bufreg2_q         : in  std_logic_vector(B downto 0);
        o_rd                : out std_logic_vector(B downto 0);
        -- External
        o_wb_sel            : out std_logic_vector(3 downto 0)

    );
end entity serv_mem_if;

architecture rtl of serv_mem_if is
    signal signbit, dat_valid : std_logic;
begin
    dat_valid <= '1' when (i_mdu_op = '1' or 
                           i_word = '1' or
                           i_bytecnt = 2B"00" or 
                           (i_half = '1' and i_bytecnt(1) = '0') ) 
                     else '0';  

    o_rd <= i_bufreg2_q when dat_valid = '1' else 
            (B downto 0 => (i_signed and signbit));

    o_wb_sel(3) <= '1' when ( i_lsb = 2B"11" or 
                              i_word = '1' or 
                              (i_half = '1' and i_lsb(1) = '1') )
                       else '0';

    o_wb_sel(2) <= '1' when ( i_lsb = 2B"10" or 
                              i_word = '1' )
                       else '0';

    o_wb_sel(1) <= '1' when ( i_lsb = 2B"01" or 
                              i_word = '1' or 
                              (i_half = '1' and i_lsb(1) = '0') )
                       else '0';

    o_wb_sel(0) <= '1' when ( i_lsb = 2B"00" ) else '0';

    process(i_clk)
    begin
        if rising_edge(i_clk) and dat_valid = '1' then
             signbit <= i_bufreg2_q(B);
        end if;
    end process;

    -- mem_misalign is checked after the init stage to decide whether to do a data
    -- bus transaction or go to the trap state. It is only guaranteed to be correct
    -- at this time
end architecture rtl;
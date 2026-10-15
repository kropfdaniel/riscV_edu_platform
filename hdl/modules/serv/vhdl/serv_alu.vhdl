----------------------------------------------------------------------------------
-- File: serv_alu.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV Arithmetic Logic Unit
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2018 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_alu is
    generic(
        W : integer := 1;
        B : integer := W-1
    );
    port(
        clk         : in  std_logic;
        -- State
        i_en        : in  std_logic;
        i_cnt0      : in  std_logic;
        o_cmp       : out std_logic;
        -- Control
        i_sub       : in  std_logic;
        i_bool_op   : in  std_logic_vector(1 downto 0);
        i_cmp_eq    : in  std_logic;
        i_cmp_sig   : in  std_logic;
        i_rd_sel    : in  std_logic_vector(2 downto 0);
        -- Data
        i_rs1       : in  std_logic_vector(B downto 0);
        i_op_b      : in  std_logic_vector(B downto 0);
        i_buf       : in  std_logic_vector(B downto 0);
        o_rd        : out std_logic_vector(B downto 0)
    );
end entity serv_alu;

architecture rtl of serv_alu is
    signal result_add, result_slt, add_cy_r, add_b, result_bool 
            :  std_logic_vector(B downto 0);
    signal cmp_r, add_cy, rs1_sx, op_b_sx, result_lt, result_eq
            : std_logic;
    signal add_full : std_logic_vector(W downto 0);
begin
    -- Sign-extended operands
    rs1_sx  <= i_rs1(B)  and i_cmp_sig;
    op_b_sx <= i_op_b(B) and i_cmp_sig;

    add_b <= i_op_b xor (W-1 downto 0 => i_sub);

    add_full <= std_logic_vector( unsigned('0' & i_rs1) + 
                                  unsigned('0' & add_b) + 
                                  unsigned('0' & add_cy_r) );
    add_cy <= add_full(W);
    result_add <= add_full(B downto 0);

    result_lt <= rs1_sx xor not op_b_sx xor add_cy;

    result_eq <= not(or result_add) and (cmp_r or i_cnt0);

    o_cmp <= result_eq when i_cmp_eq = '1' else result_lt;

    -- The result_bool expression implements the following operations between
    -- i_rs1 and i_op_b depending on the value of i_bool_op
    -- 
    -- 00 xor
    -- 01 0
    -- 10 or
    -- 11 and
    -- 
    -- i_bool_op will be 01 during shift operations, so by outputting zero under
    -- this condition we can safely or result_bool with i_buf
    result_bool <= ((i_rs1 xor i_op_b) and not(W-1 downto 0 => i_bool_op(0))) or 
                   ((W-1 downto 0 => i_bool_op(1)) and i_op_b and i_rs1);
    
    result_slt(0) <= cmp_r and i_cnt0;

    gen_w_gt_1 : if W>1 generate 
        result_slt(B downto 1) <= (B downto 1 => '0');
    end generate gen_w_gt_1;

    o_rd <= i_buf or 
            ((W-1 downto 0 => i_rd_sel(0)) and result_add) or 
            ((W-1 downto 0 => i_rd_sel(1)) and result_slt) or 
            ((W-1 downto 0 => i_rd_sel(2)) and result_bool);

    process(clk)
    begin
        if rising_edge(clk) then
            add_cy_r    <= (W-1 downto 0 => '0');
            add_cy_r(0) <= add_cy when i_en = '1' else i_sub;
            
            if i_en = '1' then
                cmp_r <= o_cmp;
            end if;
        end if;
    end process;

end architecture rtl;
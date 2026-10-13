----------------------------------------------------------------------------------
-- File: serv_compdec.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: Decodes RISC-V compressed instructions into their RV32i equivalent
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2020 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_compdec is
    port(
        i_clk           : in  std_logic;
        i_instr         : in  std_logic_vector(31 downto 0);
        i_ack           : in  std_logic;
        o_instr         : out std_logic_vector(31 downto 0);
        o_iscomp        : out std_logic
    );
end entity serv_compdec;

architecture rtl of serv_compdec is
    constant OPCODE_LOAD    : std_logic_vector(6 downto 0) := 7x"03";
    constant OPCODE_OP_IMM  : std_logic_vector(6 downto 0) := 7x"13";
    constant OPCODE_STORE   : std_logic_vector(6 downto 0) := 7x"23";
    constant OPCODE_OP      : std_logic_vector(6 downto 0) := 7x"33";
    constant OPCODE_LUI     : std_logic_vector(6 downto 0) := 7x"37";
    constant OPCODE_BRANCH  : std_logic_vector(6 downto 0) := 7x"63";
    constant OPCODE_JALR    : std_logic_vector(6 downto 0) := 7x"67";
    constant OPCODE_JAL     : std_logic_vector(6 downto 0) := 7x"6f";

    signal comp_instr : std_logic_vector(31 downto 0);
    signal illegal_instr : std_logic;
begin
    o_instr <= i_instr when illegal_instr = '1' else comp_instr;

    process(i_clk) 
    begin
        if rising_edge(i_clk) and i_ack='1' then
            o_iscomp <= not illegal_instr;
        end if;
    end process;

    process(all)
    begin
        -- By default, forward incoming instruction, mark it as legal.
        comp_instr <= i_instr;
        illegal_instr <= '0';
    end process;


end architecture rtl;

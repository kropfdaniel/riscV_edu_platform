----------------------------------------------------------------------------------
-- File: serv_mstate.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV module for handling internal state during instructions
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2019 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_state is
    generic(
        RESET_STRATEGY : string := "MINI";
        WITH_CSR       : boolean := true;
        ALIGN          : boolean := false;
        MDU            : boolean := false;
        W              : integer := 1
    );
    port(
        i_clk               : in  std_logic;
        i_rst               : in  std_logic;
        -- State
        i_new_irq           : in  std_logic;
        i_alu_cmp           : in  std_logic;
        o_init              : out std_logic;
        o_cnt_en            : out std_logic;
        o_cnt0to3           : out std_logic;
        o_cnt12to31         : out std_logic;
        o_cnt0              : out std_logic;
        o_cnt1              : out std_logic;
        o_cnt2              : out std_logic;
        o_cnt3              : out std_logic;
        o_cnt7              : out std_logic;
        o_cnt11             : out std_logic;
        o_cnt12             : out std_logic;
        o_cnt_done          : out std_logic;
        o_bufreg_en         : out std_logic;
        o_ctrl_pc_en        : out std_logic;
        o_ctrl_jump         : out std_logic;
        o_ctrl_trap         : out std_logic;
        o_ctrl_misalign     : out std_logic;
        i_sh_done           : in  std_logic;
        o_mem_bytecnt       : out std_logic_vector(1 downto 0);
        i_mem_misalign      : in  std_logic;
        -- Control
        i_bne_or_bge        : in  std_logic;
        i_cond_branch       : in  std_logic;
        i_dbus_en           : in  std_logic;
        i_two_stage_op      : in  std_logic;
        i_branch_op         : in  std_logic;
        i_shift_op          : in  std_logic;
        i_sh_right          : in  std_logic;
        i_alu_rd_sell       : in  std_logic;
        i_rd_alu_en         : in  std_logic;
        i_e_op              : in  std_logic;
        i_rd_op             : in  std_logic;
        -- MDU
        i_mdu_op            : in  std_logic;
        o_mdu_valid         : out std_logic;
    

    );
end entity serv_state;

architecture rtl of serv_state is

begin

end architecture rtl;
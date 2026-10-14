----------------------------------------------------------------------------------
-- File: serv_decode.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV module decoding instruction word into control signals
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2018 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_decode is
    generic(
        PRE_REGISTER : boolean := true;
        MDU          : boolean := false
    );
    port(
        clk                 : in  std_logic;
        -- input
        i_wb_rdt            : in  std_logic_vector(31 downto 2);
        i_wb_en             : in  std_logic;
        -- To state
        o_sh_right          : out std_logic;
        o_bne_or_bge        : out std_logic;
        o_cond_branch       : out std_logic;
        o_e_op              : out std_logic;
        o_ebreak            : out std_logic;
        o_branch_op         : out std_logic;
        o_shift_op          : out std_logic;
        o_rd_op             : out std_logic;
        o_two_stage_op      : out std_logic;
        o_dbus_en           : out std_logic;
        -- MDU
        o_mdu_op            : out std_logic;
        -- Extension
        o_ext_funct3        : out std_logic_vector(2 downto 0);
        -- To bufreg
        o_bufreg_rs1_en     : out std_logic;
        o_bufreg_imm_en     : out std_logic;
        o_bufreg_clr_lsb    : out std_logic;   
        o_bufreg_sh_signed  : out std_logic;   
        -- To ctrl
        o_ctrl_jal_or_jalr  : out std_logic;
        o_ctrl_utype        : out std_logic;
        o_ctrl_pc_rel       : out std_logic;
        o_ctrl_mret         : out std_logic;
        -- To alu
        o_alu_sub           : out std_logic;
        o_alu_bool_op       : out std_logic_vector(1 downto 0);    
        o_alu_cmp_eq        : out std_logic;    
        o_alu_cmp_sig       : out std_logic;    
        o_alu_rd_sel        : out std_logic_vector(2 downto 0);
        -- To mem IF
        o_mem_signed        : out std_logic;
        o_mem_word          : out std_logic;
        o_mem_half          : out std_logic;
        o_mem_cmd           : out std_logic;
        -- To CSR
        o_csr_en            : out std_logic;
        o_csr_addr          : out std_logic_vector(1 downto 0);
        o_csr_mstatus_en    : out std_logic;
        o_csr_mie_en        : out std_logic;
        o_csr_mcause_en     : out std_logic;
        o_csr_source        : out std_logic_vector(1 downto 0);
        o_csr_d_sel         : out std_logic;
        o_csr_imm_en        : out std_logic;
        o_mtval_pc          : out std_logic;
        -- To top
        o_immdec_ctrl       : out std_logic_vector(3 downto 0);
        o_immdec_en         : out std_logic_vector(3 downto 0);
        o_op_b_source       : out std_logic;
        -- TO RF IF
        o_rd_mem_en         : out std_logic;
        o_rd_csr_en         : out std_logic;
        o_rd_alu_en         : out std_logic
    );
end entity serv_decode;

architecture rtl of serv_decode is
    signal opcode : std_logic_vector(4 downto 0);
    signal funct3, co_ext_funct3, co_alu_rd_sel : std_logic_vector(2 downto 0);
    signal op20, op21, op22, op26, imm25, imm30 : std_logic;
    signal co_mdu_op, co_two_stage_op, co_shift_op, co_branch_op,
           co_dbus_en, co_mtval_pc, co_mem_word, co_rd_alu_en, 
           co_rd_mem_en, co_bufreg_rs1_en, co_burfreg_imm_en, 
           co_bufreg_clr_lsb, co_cond_branch, co_ctrl_utype, 
           co_ctrl_jal_or_jalr, co_ctrl_pc_rel, co_rd_op,
           co_sh_right, co_bne_or_bge, csr_op, co_ebreak, 
           co_ctrl_mret, co_e_op, co_bufreg_sh_signed, co_alu_sub,
           csr_valid, co_rd_csr_en, co_csr_en, co_csr_mstatus_en, 
           co_csr_mie_en, co_csr_mcause_en, co_csr_d_sel, 
           co_csr_imm_en, co_alu_cmp_eq, co_alu_cmp_sig, 
           co_mem_cmd, co_mem_signed, co_mem_half, co_op_b_source : std_logic;
    signal co_csr_source, co_csr_addr, co_alu_bool_op : std_logic_vector(1 downto 0);
    signal co_immdec_ctrl, co_immdec_en : std_logic_vector(3 downto 0);
begin
    co_mdu_op <= '1' when (MDU and opcode = 5B"01100" and imm25 = '1') else '0';
    
    co_two_stage_op <= not opcode(2) or (funct3(0) and not funct3(1) and not opcode(0) and not opcode(4)) or 
                       (funct3(1) and not funct3(2) and not opcode(0) and not opcode(4)) or co_mdu_op;
    co_shift_op     <= (opcode(2) and not funct3(1)) and not co_mdu_op;
    co_branch_op    <= opcode(4);
    co_dbus_en      <= not opcode(2) and not opcode(4);
    co_mtval_pc     <= opcode(4);
    co_mem_word     <= funct3(1);
    co_rd_alu_en    <= not opcode(0) and opcode(2) and not opcode(4) and not co_mdu_op;
    co_rd_mem_en    <= (not opcode(2) and not opcode(0)) or co_mdu_op;
    co_ext_funct3   <= funct3;

end architecture rtl;
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
           co_rd_mem_en, co_bufreg_rs1_en, co_bufreg_imm_en, 
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

    -- jal,branch =     imm
    -- jalr       = rs1+imm
    -- mem        = rs1+imm
    -- shift      = rs1
    co_bufreg_rs1_en <= not opcode(4) or (not opcode(1) and opcode(0));
    co_bufreg_imm_en <= not opcode(2);

    -- Clear LSB of immediate for BRANCH and JAL ops
    -- True for BRANCH and JAL
    -- False for JALR/LOAD/STORE/OP/OPIMM?
    co_bufreg_clr_lsb <= '1' when (opcode(4) = '1' and ((opcode(1 downto 0) = 2B"00") or (opcode(1 downto 0) = 2B"11"))) 
                             else '0'; 
    
    -- Conditional branch
    -- True for BRANCH
    -- False for JAL/JALR
    co_cond_branch <= not opcode(0);

    co_ctrl_utype       <= not opcode(4) and opcode(2) and opcode(0);
    co_ctrl_jal_or_jalr <= opcode(4) and opcode(0);

    -- PC-relative operations
    -- True for jal, b* auipc, ebreak
    -- False for jalr, lui
    co_ctrl_pc_rel <= '1' when opcode(2 downto 0) = 3B"000" or 
                               opcode(1 downto 0) = 2B"11"  or 
                               (opcode(4) = '1' and opcode(2) = '1' and op20 = '1') or 
                               opcode(4 downto 3) = 2B"00" 
                          else '0';

    -- Write to RD
    -- True for OP-IMM, AUIPC, OP, LUI, SYSTEM, JALR, JAL, LOAD
    -- False for STORE, BRANCH, MISC-MEM
    co_rd_op <= opcode(2) or 
                (not opcode(2) and opcode(4) and opcode(0)) or 
                (not opcode(2) and not opcode(3) and not opcode(0));

    -- 
    -- funct3
    -- 

    co_sh_right   <= funct3(2);
    co_bne_or_bge <= funct3(0);

    -- Matches system ops except ecall/ebreak/mret
    csr_op <= opcode(4) and opcode(2) and (or funct3);

    -- op20
    co_ebreak <= op20;

    -- opcode & funct3 & op21

    co_ctrl_mret <= opcode(4) and opcode(2) and op21 and not (or funct3);

    -- Matches system opcodes except CSR accesses (funct3 == 0)
    -- and mret (!op21)
    co_e_op <= opcode(4) and opcode(2) and not op21 and not (or funct3);

    -- opcode & funct3 & imm30
    co_bufreg_sh_signed <= imm30;

    -- True for sub, b*, slt*
    -- False for add*
    -- op    opcode f3  i30
    -- b*    11000  xxx x   t
    -- addi  00100  000 x   f
    -- slt*  0x100  01x x   t
    -- add   01100  000 0   f
    -- sub   01100  000 1   t
    co_alu_sub <= funct3(1) or funct3(0) or (opcode(3) and imm30) or opcode(4);

    -- Bits 26, 22, 21 and 20 are enough to uniquely identify the eight supported CSR regs
    -- mtvec, mscratch, mepc and mtval are stored externally (normally in the RF) and are
    -- treated differently from mstatus, mie and mcause which are stored in serv_csr.
    -- 
    -- The former get a 2-bit address as seen below while the latter get a
    -- one-hot enable signal each.
    -- 
    -- Hex|2 222|Reg     |csr
    -- adr|6 210|name    |addr
    -- ---|-----|--------|----
    -- 300|0_000|mstatus | xx
    -- 304|0_100|mie     | xx
    -- 305|0_101|mtvec   | 01
    -- 340|1_000|mscratch| 00
    -- 341|1_001|mepc    | 10
    -- 342|1_010|mcause  | xx
    -- 343|1_011|mtval   | 11

    -- true  for mtvec,mscratch,mepc and mtval
    -- false for mstatus, mie, mcause
    csr_valid <= op20 or (op26 and not op21);

    co_rd_csr_en <= csr_op;

    co_csr_en         <= csr_op and csr_valid;
    co_csr_mstatus_en <= csr_op and not op26 and not op22 and not op20;
    co_csr_mie_en     <= csr_op and not op26 and     op22 and not op20;
    co_csr_mcause_en  <= csr_op and                  op21 and not op20;

    co_csr_source <= funct3(1 downto 0);
    co_csr_d_sel <= funct3(2);
    co_csr_imm_en <= opcode(4) and opcode(2) and funct3(2);
    co_csr_addr <= (op26 and op20) & (not op26 or op21);

    co_alu_cmp_eq <= '1' when funct3(2 downto 1) = 2B"00" else '0';
    
    co_alu_cmp_sig <= not((funct3(0) and funct3(1)) or (funct3(1) and funct3(2)));
    
    co_mem_cmd <= opcode(3);
    co_mem_signed <= not funct3(2);
    co_mem_half <= funct3(0);

    co_alu_bool_op <= funct3(1 downto 0);

    -- True for S (STORE) or B (BRANCH) type instructions
    -- False for J type instructions
    co_immdec_ctrl(0) <= '1' when opcode(3 downto 0) = 4B"1000" else '0';
    -- True for OP-IMM, LOAD, STORE, JALR  (I S)
    -- False for LUI, AUIPC, JAL           (U J)
    co_immdec_ctrl(1) <= '1' when opcode(1 downto 0) = 2B"00" or 
                                  opcode(2 downto 1) = 2B"00" else '0';
    co_immdec_ctrl(2) <= opcode(4) and not opcode(0);
    co_immdec_ctrl(3) <= opcode(4);

    
    co_immdec_en(3) <= opcode(4) or opcode(3) or opcode(2) or not opcode(0);     -- B I J S U
    co_immdec_en(2) <= (opcode(4) and opcode(2)) or not opcode(3) or opcode(0);  --   I J   U
    co_immdec_en(1) <= '1' when opcode(2 downto 1) = 2B"01" or                   --     J   U
                                (opcode(2) and opcode(0)) = '1' or 
                                co_csr_imm_en = '1'
                           else '0';
    co_immdec_en(0) <= not co_rd_op;                                             -- B     S

    co_alu_rd_sel(0) <= '1' when funct3 = 3B"000" else '0';             -- Add/sub
    co_alu_rd_sel(1) <= '1' when funct3(2 downto 1) = 2B"01" else '0';  -- SLT*
    co_alu_rd_sel(2) <= funct3(2);                                      -- Bool

    -- 0 (OP_B_SOURCE_IMM) when OPIMM
    -- 1 (OP_B_SOURCE_RS2) when BRANCH or OP
    co_op_b_source <= opcode(3);

    gen_pre_register : if PRE_REGISTER = true generate 
        process(clk) 
        begin
            if rising_edge(clk) and i_wb_en = '1' then
                funct3 <= i_wb_rdt(14 downto 12);
                imm30  <= i_wb_rdt(30);   
                imm25  <= i_wb_rdt(25);   
                opcode <= i_wb_rdt(6 downto 2);  
                op20   <= i_wb_rdt(20);   
                op21   <= i_wb_rdt(21);   
                op22   <= i_wb_rdt(22);   
                op26   <= i_wb_rdt(26);   
            end if;
        end process;

        process(all)
        begin
            o_sh_right         <= co_sh_right;        
            o_bne_or_bge       <= co_bne_or_bge;      
            o_cond_branch      <= co_cond_branch;     
            o_dbus_en          <= co_dbus_en;         
            o_mtval_pc         <= co_mtval_pc;        
            o_two_stage_op     <= co_two_stage_op;         
            o_e_op             <= co_e_op;            
            o_ebreak           <= co_ebreak;          
            o_branch_op        <= co_branch_op;       
            o_shift_op         <= co_shift_op;        
            o_rd_op            <= co_rd_op;           
            o_mdu_op           <= co_mdu_op;          
            o_ext_funct3       <= co_ext_funct3;      
            o_bufreg_rs1_en    <= co_bufreg_rs1_en;   
            o_bufreg_imm_en    <= co_bufreg_imm_en;   
            o_bufreg_clr_lsb   <= co_bufreg_clr_lsb;  
            o_bufreg_sh_signed <= co_bufreg_sh_signed;
            o_ctrl_jal_or_jalr <= co_ctrl_jal_or_jalr;
            o_ctrl_utype       <= co_ctrl_utype;      
            o_ctrl_pc_rel      <= co_ctrl_pc_rel;     
            o_ctrl_mret        <= co_ctrl_mret;       
            o_alu_sub          <= co_alu_sub;         
            o_alu_bool_op      <= co_alu_bool_op;     
            o_alu_cmp_eq       <= co_alu_cmp_eq;      
            o_alu_cmp_sig      <= co_alu_cmp_sig;     
            o_alu_rd_sel       <= co_alu_rd_sel;      
            o_mem_signed       <= co_mem_signed;      
            o_mem_word         <= co_mem_word;        
            o_mem_half         <= co_mem_half;        
            o_mem_cmd          <= co_mem_cmd;         
            o_csr_en           <= co_csr_en;          
            o_csr_addr         <= co_csr_addr;        
            o_csr_mstatus_en   <= co_csr_mstatus_en;  
            o_csr_mie_en       <= co_csr_mie_en;      
            o_csr_mcause_en    <= co_csr_mcause_en;   
            o_csr_source       <= co_csr_source;      
            o_csr_d_sel        <= co_csr_d_sel;       
            o_csr_imm_en       <= co_csr_imm_en;      
            o_immdec_ctrl      <= co_immdec_ctrl;     
            o_immdec_en        <= co_immdec_en;       
            o_op_b_source      <= co_op_b_source;     
            o_rd_csr_en        <= co_rd_csr_en;       
            o_rd_alu_en        <= co_rd_alu_en;       
            o_rd_mem_en        <= co_rd_mem_en;
        end process;
    end generate gen_pre_register;

    gen_post_register : if PRE_REGISTER = false generate 
        process(all)
        begin
            funct3 <= i_wb_rdt(14 downto 12);
            imm30  <= i_wb_rdt(30);          
            imm25  <= i_wb_rdt(25);          
            opcode <= i_wb_rdt(6 downto 2);  
            op20   <= i_wb_rdt(20);          
            op21   <= i_wb_rdt(21);          
            op22   <= i_wb_rdt(22);          
            op26   <= i_wb_rdt(26);          
        end process;

        process(clk)
        begin
            if rising_edge(clk) and i_wb_en = '1' then
                o_sh_right         <= co_sh_right;        
                o_bne_or_bge       <= co_bne_or_bge;      
                o_cond_branch      <= co_cond_branch;     
                o_e_op             <= co_e_op;            
                o_ebreak           <= co_ebreak;          
                o_two_stage_op     <= co_two_stage_op;    
                o_dbus_en          <= co_dbus_en;         
                o_mtval_pc         <= co_mtval_pc;        
                o_branch_op        <= co_branch_op;       
                o_shift_op         <= co_shift_op;        
                o_rd_op            <= co_rd_op;           
                o_mdu_op           <= co_mdu_op;          
                o_ext_funct3       <= co_ext_funct3;      
                o_bufreg_rs1_en    <= co_bufreg_rs1_en;   
                o_bufreg_imm_en    <= co_bufreg_imm_en;   
                o_bufreg_clr_lsb   <= co_bufreg_clr_lsb;  
                o_bufreg_sh_signed <= co_bufreg_sh_signed;
                o_ctrl_jal_or_jalr <= co_ctrl_jal_or_jalr;
                o_ctrl_utype       <= co_ctrl_utype;      
                o_ctrl_pc_rel      <= co_ctrl_pc_rel;     
                o_ctrl_mret        <= co_ctrl_mret;       
                o_alu_sub          <= co_alu_sub;         
                o_alu_bool_op      <= co_alu_bool_op;     
                o_alu_cmp_eq       <= co_alu_cmp_eq;      
                o_alu_cmp_sig      <= co_alu_cmp_sig;     
                o_alu_rd_sel       <= co_alu_rd_sel;      
                o_mem_signed       <= co_mem_signed;      
                o_mem_word         <= co_mem_word;        
                o_mem_half         <= co_mem_half;        
                o_mem_cmd          <= co_mem_cmd;         
                o_csr_en           <= co_csr_en;          
                o_csr_addr         <= co_csr_addr;        
                o_csr_mstatus_en   <= co_csr_mstatus_en;  
                o_csr_mie_en       <= co_csr_mie_en;      
                o_csr_mcause_en    <= co_csr_mcause_en;   
                o_csr_source       <= co_csr_source;      
                o_csr_d_sel        <= co_csr_d_sel;       
                o_csr_imm_en       <= co_csr_imm_en;      
                o_immdec_ctrl      <= co_immdec_ctrl;     
                o_immdec_en        <= co_immdec_en;       
                o_op_b_source      <= co_op_b_source;     
                o_rd_csr_en        <= co_rd_csr_en;       
                o_rd_alu_en        <= co_rd_alu_en;       
                o_rd_mem_en        <= co_rd_mem_en;
            end if;
        end process;
    end generate gen_post_register;    
end architecture rtl;
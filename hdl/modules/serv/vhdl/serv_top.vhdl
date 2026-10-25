-- File: serv_top.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV toplevel
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2018 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.serv_pkg.all;

entity serv_top is
    generic(
        WITH_CSR            : boolean := true;
        W                   : integer := 1;
        B                   : integer := W-1;
        PRE_REGISTER        : boolean := true;
        RESET_STRATEGY      : string := "MINI";
        RESET_PC            : std_logic_vector(31 downto 0) := 32D"0";
        DEBUG               : boolean := false;
        MDU                 : boolean := false;
        COMPRESSED          : boolean := false;
        ALIGN               : boolean := COMPRESSED;
        RISCV_FORMAL        : boolean := false
    );
    port(
        clk                 : in  std_logic;
        i_rst               : in  std_logic;
        i_timer_irq         : in  std_logic;
        -- RISCV_FORMAL
        -- rvfi_valid          : out std_logic;
        -- rvfi_order          : out std_logic_vector(63 downto 0);
        -- rvfi_insn           : out std_logic_vector(31 downto 0);
        -- rvfi_trap           : out std_logic;     
        -- rvfi_halt           : out std_logic;     
        -- rvfi_intr           : out std_logic;     
        -- rvfi_mode           : out std_logic_vector(1 downto 0);
        -- rvfi_ixl            : out std_logic_vector(1 downto 0);  
        -- rvfi_rs1_addr       : out std_logic_vector(4 downto 0);  
        -- rvfi_rs2_addr       : out std_logic_vector(4 downto 0);  
        -- rvfi_rs1_rdata      : out std_logic_vector(31 downto 0);
        -- rvfi_rs2_rdata      : out std_logic_vector(31 downto 0);
        -- rvfi_rd_addr        : out std_logic_vector(4 downto 0);   
        -- rvfi_rd_wdata       : out std_logic_vector(31 downto 0);
        -- rvfi_pc_rdata       : out std_logic_vector(31 downto 0);
        -- rvfi_pc_wdata       : out std_logic_vector(31 downto 0);
        -- rvfi_mem_addr       : out std_logic_vector(31 downto 0);
        -- rvfi_mem_rmask      : out std_logic_vector(3 downto 0); 
        -- rvfi_mem_wmask      : out std_logic_vector(3 downto 0); 
        -- rvfi_mem_rdata      : out std_logic_vector(31 downto 0);
        -- rvfi_mem_wdata      : out std_logic_vector(31 downto 0);
        -- RF Interface
        o_rf_rreq           : out std_logic;     
        o_rf_wreq           : out std_logic;     
        i_rf_ready          : in  std_logic;     
        o_wreg0             : out std_logic_vector((4 + (bool_to_int(WITH_CSR))) downto 0);
        o_wreg1             : out std_logic_vector((4 + (bool_to_int(WITH_CSR))) downto 0);
        o_wen0              : out std_logic;
        o_wen1              : out std_logic;
        o_wdata0            : out std_logic_vector(B downto 0);
        o_wdata1            : out std_logic_vector(B downto 0);
        o_rreg0             : out std_logic_vector((4 + (bool_to_int(WITH_CSR))) downto 0);
        o_rreg1             : out std_logic_vector((4 + (bool_to_int(WITH_CSR))) downto 0);
        i_rdata0            : in  std_logic_vector(B downto 0);
        i_rdata1            : in  std_logic_vector(B downto 0);
        -- 
        o_ibus_adr          : out std_logic_vector(31 downto 0);
        o_ibus_cyc          : out std_logic;   
        i_ibus_rdt          : in  std_logic_vector(31 downto 0);
        i_ibus_ack          : in  std_logic;      
        o_dbus_adr          : out std_logic_vector(31 downto 0);
        o_dbus_dat          : out std_logic_vector(31 downto 0);
        o_dbus_sel          : out std_logic_vector(3 downto 0);
        o_dbus_we           : out std_logic;
        o_dbus_cyc          : out std_logic; 
        i_dbus_rdt          : in  std_logic_vector(31 downto 0);
        i_dbus_ack          : in  std_logic;
        -- Extension
        o_ext_funct3        : out std_logic_vector(2 downto 0); 
        i_ext_ready         : in  std_logic;
        i_ext_rd            : in  std_logic_vector(31 downto 0);
        o_ext_rs1           : out std_logic_vector(31 downto 0);  
        o_ext_rs2           : out std_logic_vector(31 downto 0);
        -- MDU
        o_mdu_valid         : out std_logic
    );
end entity serv_top;

architecture rtl of serv_top is
    signal rd_addr, rs1_addr, rs2_addr : std_logic_vector(4 downto 0);
    signal immdec_ctrl, immdec_en : std_logic_vector(3 downto 0);
    signal sh_right, bne_or_bge, cond_branch, two_stage_op, e_op, ebreak, 
           branch_op, shift_op, rd_op, mdu_op, rd_alu_en, rd_csr_en, rd_mem_en,
           mtval_pc, ctrl_pc_en, jump, jal_or_jalr, utype, mret, trap,
           pc_rel, iscomp, init, cnt_en, cnt0to3, cnt12to31, cnt0, cnt1, cnt2, 
           cnt3, cnt7, cnt11, cnt12, cnt_done, bufreg_en, bufreg_sh_signed, 
           bufreg_rs1_en, bufreg_imm_en, bufreg_clr_lsb, dbus_ack, alu_sub,
           alu_cmp_eq, alu_cmp_sig, alu_cmp, rd_en, op_b_sel, mem_signed, 
           mem_word, mem_half, sh_done, mem_misalign, csr_mstatus_en, csr_mie_en,
           csr_mcause_en, csr_d_sel, csr_en, csr_imm_en, dbus_en, new_irq, wb_ibus_cyc,
           wb_ibus_ack : std_logic;
    signal ctrl_rd, alu_rd, mem_rd, csr_rd, imm, bufreg_q, bufreg2_q, rs1, rs2, op_b,
           bad_pc, csr_imm, csr_pc, csr_in, rf_csr_out : std_logic_vector(B downto 0);
    signal dbus_rdt, i_wb_rdt, wb_ibus_adr, wb_ibus_rdt : std_logic_vector(31 downto 0);
    signal alu_bool_op, mem_bytecnt, csr_source, csr_addr, lsb : std_logic_vector(1 downto 0);
    signal alu_rd_sel : std_logic_vector(2 downto 0);
begin
    gen_align : if ALIGN generate
        aligner : entity work.serv_aligner(rtl)
        port map ( clk           => clk,
                   rst           => i_rst,
                   -- SERV_RF_TOP
                   i_ibus_adr    => wb_ibus_adr,
                   i_ibus_cyc    => wb_ibus_cyc,
                   o_ibus_rdt    => wb_ibus_rdt,
                   o_ibus_ack    => wb_ibus_ack,
                   -- servant_arbiter
                   o_wb_ibus_adr => o_ibus_adr,
                   o_wb_ibus_cyc => o_ibus_cyc,
                   i_wb_ibus_rdt => i_ibus_rdt,
                   i_wb_ibus_ack => i_ibus_ack );
    else generate
        o_ibus_adr <= wb_ibus_adr;
        o_ibus_cyc <= wb_ibus_cyc;
        wb_ibus_rdt <= i_ibus_rdt;
        wb_ibus_ack <= i_ibus_ack;
    end generate gen_align;

    gen_compressed : if COMPRESSED generate
        compdec : entity work.serv_compdec(rtl)
        port map ( i_clk    => clk,
                   i_instr  => wb_ibus_rdt, 
                   i_ack    => wb_ibus_ack,
                   o_instr  => i_wb_rdt,
                   o_iscomp => iscomp );
    else generate
        i_wb_rdt <= wb_ibus_rdt;
        iscomp <= '0';
    end generate gen_compressed;

    state : entity work.serv_state(rtl)
    generic map ( RESET_STRATEGY => RESET_STRATEGY,
                  WITH_CSR       => WITH_CSR,
                  MDU            => MDU,
                  ALIGN          => ALIGN,
                  W              => W )
    port map ( i_clk             => clk,
               i_rst             => i_rst,
               -- State       
               i_new_irq         => new_irq,
               i_alu_cmp         => alu_cmp,
               o_init            => init,
               o_cnt_en          => cnt_en,
               o_cnt0to3         => cnt0to3,   
               o_cnt12to31       => cnt12to31, 
               o_cnt0            => cnt0,      
               o_cnt1            => cnt1,      
               o_cnt2            => cnt2,      
               o_cnt3            => cnt3,      
               o_cnt7            => cnt7,      
               o_cnt11           => cnt11,     
               o_cnt12           => cnt12,     
               o_cnt_done        => cnt_done,  
               o_bufreg_en       => bufreg_en,    
               o_ctrl_pc_en      => ctrl_pc_en,   
               o_ctrl_jump       => jump,    
               o_ctrl_trap       => trap,    
               i_ctrl_misalign   => lsb(1),
               i_sh_done         => sh_done,      
               o_mem_bytecnt     => mem_bytecnt,  
               i_mem_misalign    => mem_misalign,
               -- Control     
               i_bne_or_bge      => bne_or_bge,  
               i_cond_branch     => cond_branch, 
               i_dbus_en         => dbus_en,     
               i_two_stage_op    => two_stage_op,
               i_branch_op       => branch_op,   
               i_shift_op        => shift_op,    
               i_sh_right        => sh_right,    
               i_alu_rd_sel1     => alu_rd_sel(1), 
               i_rd_alu_en       => rd_alu_en,   
               i_e_op            => e_op,        
               i_rd_op           => rd_op,       
               -- MDU         
               i_mdu_op          => mdu_op,   
               o_mdu_valid       => o_mdu_valid,
               -- Extension   
               i_mdu_ready       => i_ext_ready,
               -- External    
               o_dbus_cyc        => o_dbus_cyc,
               i_dbus_ack        => i_dbus_ack,
               o_ibus_cyc        => wb_ibus_cyc,
               i_ibus_ack        => wb_ibus_ack,
               -- RF Interface
               o_rf_rreq         => o_rf_rreq, 
               o_rf_wreq         => o_rf_wreq, 
               i_rf_ready        => i_rf_ready,
               o_rf_rd_en        => rd_en );

    decode : entity work.serv_decode(rtl)
    generic map ( PRE_REGISTER => PRE_REGISTER,
                  MDU          => MDU )
    port map ( clk                 => clk,
               -- input            
               i_wb_rdt            => i_wb_rdt(31 downto 2),
               i_wb_en             => wb_ibus_ack,
               -- To state
               o_sh_right          => sh_right,    
               o_bne_or_bge        => bne_or_bge,  
               o_cond_branch       => cond_branch, 
               o_e_op              => e_op,        
               o_ebreak            => ebreak,      
               o_branch_op         => branch_op,   
               o_shift_op          => shift_op,    
               o_rd_op             => rd_op,       
               o_two_stage_op      => two_stage_op,
               o_dbus_en           => dbus_en,     
               -- MDU
               o_mdu_op            => mdu_op,
               -- Extension
               o_ext_funct3        => o_ext_funct3,
               -- To bufreg
               o_bufreg_rs1_en     => bufreg_rs1_en,   
               o_bufreg_imm_en     => bufreg_imm_en,   
               o_bufreg_clr_lsb    => bufreg_clr_lsb,  
               o_bufreg_sh_signed  => bufreg_sh_signed,
               -- To bufreg2  
               o_op_b_source       => op_b_sel,
               -- To ctrl
               o_ctrl_jal_or_jalr  => jal_or_jalr,
               o_ctrl_utype        => utype,      
               o_ctrl_pc_rel       => pc_rel,     
               o_ctrl_mret         => mret,       
               -- To alu
               o_alu_sub           => alu_sub,    
               o_alu_bool_op       => alu_bool_op,
               o_alu_cmp_eq        => alu_cmp_eq, 
               o_alu_cmp_sig       => alu_cmp_sig,
               o_alu_rd_sel        => alu_rd_sel, 
               -- To mem IF
               o_mem_signed        => mem_signed,
               o_mem_word          => mem_word,  
               o_mem_half          => mem_half,  
               o_mem_cmd           => o_dbus_we,
               -- To CSR
               o_csr_en            => csr_en,        
               o_csr_addr          => csr_addr,      
               o_csr_mstatus_en    => csr_mstatus_en,
               o_csr_mie_en        => csr_mie_en,    
               o_csr_mcause_en     => csr_mcause_en, 
               o_csr_source        => csr_source,    
               o_csr_d_sel         => csr_d_sel,     
               o_csr_imm_en        => csr_imm_en,    
               o_mtval_pc          => mtval_pc,      
               -- To top
               o_immdec_ctrl       => immdec_ctrl,
               o_immdec_en         => immdec_en,
               -- TO RF IF
               o_rd_mem_en         => rd_mem_en,
               o_rd_csr_en         => rd_csr_en,
               o_rd_alu_en         => rd_alu_en);

    immdec : entity work.serv_immdec(rtl)
    generic map ( SHARED_RFADDR_IMM_REGS => true,
                  W                      => W)
    port map ( i_clk        => clk,
               -- State
               i_cnt_en     => cnt_en,  
               i_cnt_done   => cnt_done,
               -- Control
               i_immdec_en  => immdec_en, 
               i_csr_imm_en => csr_imm_en,
               i_ctrl       => immdec_ctrl,      
               o_rd_addr    => rd_addr,   
               o_rs1_addr   => rs1_addr,  
               o_rs2_addr   => rs2_addr,  
               -- Data
               o_csr_imm    => csr_imm,
               o_imm        => imm,    
               -- External
               i_wb_en      => wb_ibus_ack,
               i_wb_rdt     => i_wb_rdt(31 downto 7) );

    bufreg : entity work.serv_bufreg(rtl)
    generic map ( MDU => MDU,
                  W   => W)
    port map ( i_clk             => clk,
               -- State
               i_cnt0            => cnt0,
               i_cnt1            => cnt1,
               i_cnt_done        => cnt_done,
               i_en              => bufreg_en,
               i_init            => init,
               i_mdu_op          => mdu_op,
               o_lsb             => lsb,
               -- Control
               i_rs1_en          => bufreg_rs1_en,        
               i_imm_en          => bufreg_imm_en,        
               i_clr_lsb         => bufreg_clr_lsb,       
               i_shift_op        => shift_op,      
               i_right_shift_op  => sh_right,
               i_shamt           => o_dbus_dat(26 downto 24),         
               i_sh_signed       => bufreg_sh_signed,     
               -- Data
               i_rs1             => rs1, 
               i_imm             => imm, 
               o_q               => bufreg_q,   
               -- External
               o_dbus_adr        => o_dbus_adr,
               o_ext_rs1         => o_ext_rs1 );

    bufreg2 : entity work.serv_bufreg2(rtl)
    generic map ( W => W )
    port map ( i_clk       => clk,
               -- State
               i_en        => cnt_en,      
               i_init      => init,    
               i_cnt7      => cnt7,    
               i_cnt_done  => cnt_done,
               i_sh_right  => sh_right,
               i_lsb       => lsb,     
               i_bytecnt   => mem_bytecnt, 
               o_sh_done   => sh_done, 
               -- Control
               i_op_b_sel  => op_b_sel,
               i_shift_op  => shift_op,
               -- Data
               i_rs2       => rs2,   
               i_imm       => imm,   
               o_op_b      => op_b,  
               o_q         => bufreg2_q,     
               -- External
               o_dat       => o_dbus_dat,
               i_load      => dbus_ack,
               i_dat       => dbus_rdt );

    ctrl : entity work.serv_ctrl(rtl)
    generic map ( RESET_PC       => RESET_PC,
                  RESET_STRATEGY => RESET_STRATEGY,
                  WITH_CSR       => WITH_CSR,
                  W              => W )
    port map ( clk           => clk,
               i_rst         => i_rst,
               -- State
               i_pc_en       => ctrl_pc_en,
               i_cnt12to31   => cnt12to31,
               i_cnt0        => cnt0,     
               i_cnt1        => cnt1,     
               i_cnt2        => cnt2,     
               -- Control
               i_jump        => jump,       
               i_jal_or_jalr => jal_or_jalr,
               i_utype       => utype,      
               i_pc_rel      => pc_rel,     
               i_trap        => trap or mret,       
               i_iscomp      => iscomp,     
               -- Data
               i_imm         => imm,   
               i_buf         => bufreg_q,   
               i_csr_pc      => csr_pc,
               o_rd          => ctrl_rd,    
               o_bad_pc      => bad_pc,
               -- External
               o_ibus_adr    => wb_ibus_adr );

    alu : entity work.serv_alu(rtl)
    generic map ( W => W)
    port map ( clk        => clk,
               -- State
               i_en       => cnt_en,
               i_cnt0     => cnt0,
               o_cmp      => alu_cmp, 
               -- Control
               i_sub      => alu_sub,    
               i_bool_op  => alu_bool_op,
               i_cmp_eq   => alu_cmp_eq, 
               i_cmp_sig  => alu_cmp_sig,
               i_rd_sel   => alu_rd_sel, 
               -- Data
               i_rs1      => rs1,
               i_op_b     => op_b,
               i_buf      => bufreg_q,
               o_rd       => alu_rd );

    rf_if : entity work.serv_rf_if(rtl)
    generic map ( WITH_CSR => WITH_CSR, 
                  W        => W )
    port map ( -- RF interface
               i_cnt_en           => cnt_en,
               o_wreg0            => o_wreg0, 
               o_wreg1            => o_wreg1, 
               o_wen0             => o_wen0,  
               o_wen1             => o_wen1,  
               o_wdata0           => o_wdata0,
               o_wdata1           => o_wdata1,
               o_rreg0            => o_rreg0, 
               o_rreg1            => o_rreg1, 
               i_rdata0           => i_rdata0,
               i_rdata1           => i_rdata1,
               -- Trap interface
               i_trap             => trap,    
               i_mret             => mret,    
               i_mepc             => wb_ibus_adr(B downto 0),    
               i_mtval_pc         => mtval_pc,
               i_bufreg_q         => bufreg_q,
               i_bad_pc           => bad_pc,  
               o_csr_pc           => csr_pc,  
               -- CSR write port
               i_csr_en           => csr_en,  
               i_csr_addr         => csr_addr,
               i_csr              => csr_in,     
               -- RD write port
               i_rd_wen           => rd_en,    
               i_rd_waddr         => rd_addr,  
               i_ctrl_rd          => ctrl_rd,   
               i_alu_rd           => alu_rd,    
               i_rd_alu_en        => rd_alu_en, 
               i_csr_rd           => csr_rd,    
               i_rd_csr_en        => rd_csr_en, 
               i_mem_rd           => mem_rd,    
               i_rd_mem_en        => rd_mem_en, 
               -- RS1 read port
               i_rs1_raddr        => rs1_addr,
               o_rs1              => rs1,      
               -- RS2 read port
               i_rs2_raddr        => rs2_addr,
               o_rs2              => rs2,      
               -- CSR read port
               o_csr              => rf_csr_out );

    mem_if : entity work.serv_mem_if(rtl)
    generic map ( WITH_CSR => WITH_CSR, 
                  W        => W )
    port map ( i_clk        => clk,
               -- State
               i_bytecnt    => mem_bytecnt,
               i_lsb        => lsb,
               o_misalign   => mem_misalign,
               -- Control
               i_signed     => mem_signed,
               i_word       => mem_word,
               i_half       => mem_half,
               -- MDU
               i_mdu_op     => mdu_op,
               -- Data
               i_bufreg2_q  => bufreg2_q,
               o_rd         => mem_rd,
               -- External
               o_wb_sel     => o_dbus_sel );

    gen_csr : if WITH_CSR generate
        csr : entity work.serv_csr(rtl)
        generic map ( RESET_STRATEGY => RESET_STRATEGY, 
                      W        => W )
        port map ( i_clk        => clk, 
                   i_rst        => i_rst,
                   -- State
                   i_trig_irq   => wb_ibus_ack,
                   i_en         => cnt_en,      
                   i_cnt0to3    => cnt0to3, 
                   i_cnt3       => cnt3,    
                   i_cnt7       => cnt7,    
                   i_cnt11      => cnt11,   
                   i_cnt12      => cnt12,   
                   i_cnt_done   => cnt_done,
                   i_mem_op     => not mtval_pc,
                   i_mtip       => i_timer_irq,
                   i_trap       => trap,
                   o_new_irq    => new_irq,
                   -- Control
                   i_e_op       => e_op,      
                   i_ebreak     => ebreak,    
                   i_mem_cmd    => o_dbus_we,   
                   i_mstatus_en => csr_mstatus_en,
                   i_mie_en     => csr_mie_en,    
                   i_mcause_en  => csr_mcause_en, 
                   i_csr_source => csr_source,
                   i_mret       => mret,      
                   i_csr_d_sel  => csr_d_sel, 
                   -- Data
                   i_rf_csr_out => rf_csr_out,
                   o_csr_in     => csr_in,    
                   i_csr_imm    => csr_imm,   
                   i_rs1        => rs1,       
                   o_q          => csr_rd );
    else generate
        csr_in <= (others => '0');
        csr_rd <= (others => '0');
        new_irq <= '0';
    end generate gen_csr;

    gen_debug : if DEBUG generate
        -- TODO add debug

    end generate gen_debug;

    gen_mdu : if MDU generate
        dbus_rdt <= i_ext_rd when (??i_ext_ready) else i_dbus_rdt;
        dbus_ack <= i_dbus_ack or i_ext_ready;
    else generate
        dbus_rdt <= i_dbus_rdt;
        dbus_ack <= i_dbus_ack;
    end generate gen_mdu;

    o_ext_rs2 <= o_dbus_dat;    
end architecture rtl;
----------------------------------------------------------------------------------
-- File: serv_csr.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV module for handling CSR registers
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2018 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_csr is
    generic(
        RESET_STRATEGY : string := "MINI";
        W              : integer := 1;
        B              : integer := W-1
    );
    port(
        i_clk               : in  std_logic;
        i_rst               : in  std_logic;
        -- State
        i_trig_irq          : in  std_logic;
        i_en                : in  std_logic;
        i_cnt0to3           : in  std_logic;
        i_cnt3              : in  std_logic;
        i_cnt7              : in  std_logic;
        i_cnt11             : in  std_logic;
        i_cnt12             : in  std_logic;
        i_cnt_done          : in  std_logic;
        i_mem_op            : in  std_logic;
        i_mtip              : in  std_logic;
        i_trap              : in  std_logic;
        o_new_irq           : out std_logic;
        -- Control
        i_e_op              : in  std_logic;
        i_ebreak            : in  std_logic;
        i_mem_cmd           : in  std_logic;
        i_mstatus_en        : in  std_logic;
        i_mie_en            : in  std_logic;
        i_mcause_en         : in  std_logic; 
        i_csr_source        : in  std_logic_vector(1 downto 0); 
        i_mret              : in  std_logic; 
        i_csr_d_sel         : in  std_logic; 
        -- Data
        i_rf_csr_out        : in  std_logic_vector(B downto 0);
        o_csr_in            : out std_logic_vector(B downto 0);
        i_csr_imm           : in  std_logic_vector(B downto 0);
        i_rs1               : in  std_logic_vector(B downto 0);
        o_q                 : out std_logic_vector(B downto 0)
    );
end entity serv_csr;

architecture rtl of serv_csr is
    constant CSR_SOURCE_CSR : std_logic_vector(1 downto 0) := 2B"00";
    constant CSR_SOURCE_EXT : std_logic_vector(1 downto 0) := 2B"01";
    constant CSR_SOURCE_SET : std_logic_vector(1 downto 0) := 2B"10";
    constant CSR_SOURCE_CLR : std_logic_vector(1 downto 0) := 2B"11";

    signal mstatus_mie, mstatus_mpie, mie_mtie, mcause31, timer_irq_r, 
           timer_irq, new_irq_int : std_logic;
    signal mcause3_0 : std_logic_vector(3 downto 0);
    signal mcause, csr_in, csr_out, d, mstatus : std_logic_vector(B downto 0);
begin
    assert (W = 1 or W = 4)
        report "serv_csr PARAMETER ERROR: W must be exactly 1 or 4."
        severity failure;
    
    o_new_irq <= new_irq_int; 

    d <= i_csr_imm when i_csr_d_sel = '1' else i_rs1;

    csr_in <= d                 when i_csr_source = CSR_SOURCE_EXT else
              csr_out or d      when i_csr_source = CSR_SOURCE_SET else
              csr_out and not d when i_csr_source = CSR_SOURCE_CLR else
              csr_out           when i_csr_source = CSR_SOURCE_CSR else
              (B downto 0 => 'X');

    gen_mstatus_w1 : if W = 1 generate
        mstatus(0) <= (mstatus_mie and i_cnt3) or (i_cnt11 or i_cnt12);
    end generate gen_mstatus_w1;
    gen_mstatus_w4 : if W = 4 generate
        mstatus <= (i_cnt11 or (mstatus_mie and i_cnt3)) & 2B"00" & i_cnt12;
    end generate gen_mstatus_w4;

    csr_out <= ((B downto 0 => i_mstatus_en and i_en) and mstatus) or 
               i_rf_csr_out or 
               ((B downto 0 => i_mcause_en and i_en) and mcause);

    o_q <= csr_out;

    timer_irq <= i_mtip and mstatus_mie and mie_mtie;

    mcause <= mcause3_0(B downto 0)            when i_cnt0to3 = '1'  else -- [3:0]
              mcause31 & (B-1 downto 0 => '0') when i_cnt_done = '1' else -- [31]
              (B downto 0 => '0');

    o_csr_in <= csr_in;

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_trig_irq = '1' then
                timer_irq_r <= timer_irq;
                new_irq_int <= timer_irq and not timer_irq_r;
            end if;

            if i_mie_en = '1' and i_cnt7 = '1' then
                mie_mtie <= csr_in(B);
            end if;

            -- The mie bit in mstatus gets updated under three conditions

            -- When a trap is taken, the bit is cleared
            -- During an mret instruction, the bit is restored from mpie
            -- During a mstatus CSR access instruction it's assigned when
            -- bit 3 gets updated
            -- 
            -- These conditions are all mutually exclusive
            if (i_trap = '1' and i_cnt_done = '1') or 
               (i_mstatus_en = '1' and i_cnt3 = '1' and i_en = '1') or 
               (i_mret = '1') then
                mstatus_mie <= (not i_trap and mstatus_mpie) when i_mret = '1' else
                               (not i_trap and csr_in(B));
            end if;

            -- Note: To save resources mstatus_mpie (mstatus bit 7) is not
            -- readable or writable from sw
            if i_trap = '1' and i_cnt_done = '1' then
                mstatus_mpie <= mstatus_mie;
            end if;

            -- The four lowest bits in mcause hold the exception code
            -- 
            -- These bits get updated under three conditions
            -- 
            -- During an mcause CSR access function, they are assigned when
            -- bits 0 to 3 gets updated
            -- 
            -- During an external interrupt the exception code is set to
            -- 7, since SERV only support timer interrupts
            -- 
            -- During an exception, the exception code is assigned to indicate
            -- if it was caused by an ebreak instruction (3),
            -- ecall instruction (11), misaligned load (4), misaligned store (6)
            -- or misaligned jump (0)
            -- 
            -- The expressions below are derived from the following truth table
            -- irq  => 0111 (timer=7)
            -- e_op => x011 (ebreak=3, ecall=11)
            -- mem  => 01x0 (store=6, load=4)
            -- ctrl => 0000 (jump=0)
            if (i_mcause_en = '1' and i_en = '1' and i_cnt0to3 = '1') or 
               (i_trap = '1' and i_cnt_done = '1') then
                mcause3_0(3) <= (i_e_op and not i_ebreak) or (not i_trap and csr_in(B));
                
                if W = 1 then
                    mcause3_0(2) <= new_irq_int or i_mem_op or (not i_trap and mcause3_0(3));
                    mcause3_0(1) <= new_irq_int or i_e_op or (i_mem_op and i_mem_cmd) or (not i_trap and mcause3_0(2));
                else
                    mcause3_0(2) <= new_irq_int or i_mem_op or (not i_trap and csr_in(2));
                    mcause3_0(1) <= new_irq_int or i_e_op or (i_mem_op and i_mem_cmd) or (not i_trap and csr_in(1));
                end if;
                mcause3_0(0) <= (new_irq_int or i_e_op or (not i_trap and mcause3_0(1))) when W = 1 else
                                (new_irq_int or i_e_op or (not i_trap and csr_in(0)));  
            end if;

            if (i_mcause_en = '1' and i_cnt_done = '1') or i_trap = '1' then
                mcause31 <= new_irq_int when i_trap = '1' else csr_in(B);
            end if;
            if i_rst = '1' then 
                if RESET_STRATEGY /= "NONE" then
                    new_irq_int <= '0';
                    mie_mtie <= '0';
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
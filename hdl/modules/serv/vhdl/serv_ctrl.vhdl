----------------------------------------------------------------------------------
-- File: serv_ctrl.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV module for updating program counter
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2018 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_ctrl is
    generic(
        RESET_STRATEGY : string := "MINI";
        RESET_PC       : std_logic_vector(31 downto 0) := 32d"0";
        WITH_CSR       : boolean := true;
        W              : integer := 1;
        B              : integer := W-1
    );
    port(
        clk                 : in  std_logic;
        i_rst               : in  std_logic;
        -- State
        i_pc_en             : in  std_logic;
        i_cnt12to31         : in  std_logic;
        i_cnt0              : in  std_logic;
        i_cnt1              : in  std_logic;
        i_cnt2              : in  std_logic;
        -- Control
        i_jump              : in  std_logic;
        i_jal_or_jalr       : in  std_logic;
        i_utype             : in  std_logic;
        i_pc_rel            : in  std_logic;
        i_trap              : in  std_logic;
        i_iscomp            : in  std_logic; 
        -- Data
        i_imm               : in  std_logic_vector(B downto 0);
        i_buf               : in  std_logic_vector(B downto 0);
        i_csr_pc            : in  std_logic_vector(B downto 0);
        o_rd                : out std_logic_vector(B downto 0);
        o_bad_pc            : out std_logic_vector(B downto 0);
        -- External
        o_ibus_adr          : out std_logic_vector(31 downto 0)

    );
end entity serv_ctrl;

architecture rtl of serv_ctrl is
    signal pc_plus_4_cy, pc_plus_4_cy_r, pc_plus_offset_cy, 
           pc_plus_offset_cy_r : std_logic;
    signal pc_plus_4, pc_plus_4_cy_r_w, pc_plus_offset,
           pc_plus_offset_cy_r_w, pc_plus_offset_aligned, 
           plus_4, pc, new_pc, offset_a, offset_b : std_logic_vector(B downto 0);
    signal pc_plus_4_ext, pc_plus_offset_ext : std_logic_vector(W downto 0);

    function init_pc(strategy : string) return std_logic_vector is
    begin
        if strategy = "NONE" then
            return RESET_PC;
        else
            return (31 downto 0 => '0');
        end if;
    end function;

    signal ibus_adr_int : std_logic_vector(31 downto 0) := init_pc(RESET_STRATEGY);
begin
    assert (W = 1 or W = 4)
        report "serv_ctrl PARAMETER ERROR: W must be exactly 1 or 4."
        severity failure;

    o_ibus_adr <= ibus_adr_int;
    
    pc <= ibus_adr_int(B downto 0);

    -- If i_iscomp=1: increment pc by 2 else increment pc by 4
    gen_plus_4_w_eq_1 : if W = 1 generate
        plus_4(0) <= i_cnt1 when i_iscomp = '1' else i_cnt2;
    end generate gen_plus_4_w_eq_1;
    gen_plus_4_w_eq_4 : if W = 4 generate
        plus_4 <= 4D"0" when not (i_cnt0 = '1' or i_cnt1 = '1') else 
                  4D"2" when i_iscomp = '1' else
                  4D"4";
    end generate gen_plus_4_w_eq_4;

    o_bad_pc <= pc_plus_offset_aligned;
    
    pc_plus_4_ext <= std_logic_vector( unsigned('0' & pc) +
                                       unsigned('0' & plus_4) +
                                       unsigned('0' & pc_plus_4_cy_r_w) );
    pc_plus_4_cy <= pc_plus_4_ext(W);
    pc_plus_4 <= pc_plus_4_ext(B downto 0);

    gen_csr : if WITH_CSR = true generate
        gen_new_pc_w_eq_1 : if W = 1 generate
            new_pc <= (i_csr_pc and not (i_cnt0 or i_cnt1)) when i_trap = '1' else
                      pc_plus_offset_aligned when i_jump = '1' else
                      pc_plus_4;
        end generate gen_new_pc_w_eq_1;
        gen_new_pc_w_eq_4 : if W = 4 generate
            new_pc <= (i_csr_pc and 4B"1100") when i_trap = '1' and (i_cnt0 = '1' or i_cnt1 = '1') else
                      (i_csr_pc and 4B"1111") when i_trap = '1' else
                      pc_plus_offset_aligned when i_jump = '1' else
                      pc_plus_4;
        end generate gen_new_pc_w_eq_4;
    end generate gen_csr;
    
    gen_no_csr : if WITH_CSR = false generate
        new_pc <= pc_plus_offset_aligned when i_jump = '1' else pc_plus_4;
    end generate gen_no_csr;

    o_rd <= ( (B downto 0 => i_utype) and pc_plus_offset_aligned ) or 
            ( pc_plus_4 and (B downto 0 => i_jal_or_jalr));

    offset_a <= (B downto 0 => i_pc_rel) and pc;
    offset_b <= (i_imm and (B downto 0 => i_cnt12to31)) when i_utype = '1' else i_buf;
    
    pc_plus_offset_ext <= std_logic_vector( unsigned('0' & offset_a) +
                                            unsigned('0' & offset_b) +
                                            unsigned('0' & pc_plus_offset_cy_r_w));
    pc_plus_offset_cy <= pc_plus_offset_ext(W);
    pc_plus_offset <= pc_plus_offset_ext(B downto 0);

    gen_w_gt_1 : if W>1 generate
        pc_plus_offset_aligned(B downto 1) <= pc_plus_offset(B downto 1);
        pc_plus_offset_cy_r_w(B downto 1) <= (B downto 1 => '0');
        pc_plus_4_cy_r_w(B downto 1) <= (B downto 1 => '0');
    end generate gen_w_gt_1;

    pc_plus_offset_aligned(0) <= pc_plus_offset(0) and not i_cnt0;
    pc_plus_offset_cy_r_w(0) <= pc_plus_offset_cy_r;
    pc_plus_4_cy_r_w(0) <= pc_plus_4_cy_r;

    process(clk)
    begin
        if rising_edge(clk) then
            pc_plus_4_cy_r <= i_pc_en and pc_plus_4_cy;
            pc_plus_offset_cy_r <= i_pc_en and pc_plus_offset_cy;

            if RESET_STRATEGY = "NONE" then
                if i_pc_en = '1' then
                    ibus_adr_int <= new_pc & ibus_adr_int(31 downto W);
                end if;
            else
                if i_pc_en = '1' or i_rst = '1' then
                    ibus_adr_int <= RESET_PC when i_rst = '1' else
                                    new_pc & ibus_adr_int(31 downto W);
                end if;
            end if;
        end if;
    end process;

end architecture;
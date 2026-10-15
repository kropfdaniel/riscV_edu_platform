----------------------------------------------------------------------------------
-- File: serv_immdec.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV module for decoding immediates from instruction words
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2020 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_immdec is
    generic(
        SHARED_RFADDR_IMM_REGS : boolean := true;
        W : integer := 1
    );
    port(
        i_clk           : in  std_logic;
        -- State
        i_cnt_en        : in  std_logic;
        i_cnt_done      : in  std_logic;
        -- Control
        i_immdec_en     : in  std_logic_vector(3 downto 0);
        i_csr_imm_en    : in  std_logic;
        i_ctrl          : in  std_logic_vector(3 downto 0);
        o_rd_addr       : out  std_logic_vector(4 downto 0);
        o_rs1_addr      : out  std_logic_vector(4 downto 0);
        o_rs2_addr      : out  std_logic_vector(4 downto 0);
        -- Data
        o_csr_imm       : out  std_logic_vector(W - 1 downto 0);
        o_imm           : out  std_logic_vector(W - 1 downto 0);
        -- External
        i_wb_en         : in  std_logic;
        i_wb_rdt        : in  std_logic_vector(31 downto 7)
    );
end entity serv_immdec;

architecture rtl of serv_immdec is

    
begin

    assert (W = 1 or W = 4)
        report "serv_immdec PARAMETER ERROR: W must be exactly 1 or 4."
        severity failure;

    
    gen_o_immdec_w_eq_1 : if W = 1 generate
        signal imm31 : std_logic;
        signal imm19_12_20 : std_logic_vector(8 downto 0);
        signal imm7 : std_logic;
        signal imm30_25 : std_logic_vector(5 downto 0);
        signal imm24_20 : std_logic_vector(4 downto 0);
        signal imm11_7 : std_logic_vector(4 downto 0);
        signal signbit : std_logic;
    begin
        o_csr_imm(0) <= imm19_12_20(4);
        signbit <= imm31 and not i_csr_imm_en;

        gen_shared_imm_regs : if SHARED_RFADDR_IMM_REGS = true generate
            o_rs1_addr <= imm19_12_20(8 downto 4);
            o_rs2_addr <= imm24_20;
            o_rd_addr  <= imm11_7;

            process (i_clk)
            begin
                if rising_edge(i_clk) then
                    if i_wb_en = '1' then
                        -- CSR immediates are always zero-extended, hence clear the signbit
                        imm31 <= i_wb_rdt(31);
                    end if;

                    if i_wb_en = '1' or (i_cnt_en = '1' and i_immdec_en(1) = '1') then 
                        imm19_12_20 <= i_wb_rdt(19 downto 12) & i_wb_rdt(20) when i_wb_en = '1' else
                                        signbit     & imm19_12_20(8 downto 1) when i_ctrl(3) = '1' else
                                        imm24_20(0) & imm19_12_20(8 downto 1);
                    end if;
                    

                    if i_wb_en = '1' or i_cnt_en = '1' then
                        imm7 <= i_wb_rdt(7) when i_wb_en = '1' else signbit;
                    end if;

                    if i_wb_en = '1' or (i_cnt_en = '1' and i_immdec_en(3) = '1') then
                        imm30_25 <= i_wb_rdt(30 downto 25) when i_wb_en = '1' else
                                    imm7           & imm30_25(5 downto 1) when i_ctrl(2) = '1' else
                                    signbit        & imm30_25(5 downto 1) when i_ctrl(1) = '1' else
                                    imm19_12_20(0) & imm30_25(5 downto 1);
                    end if;

                    if i_wb_en = '1' or (i_cnt_en = '1' and i_immdec_en(2) = '1') then
                        imm24_20 <= i_wb_rdt(24 downto 20) when i_wb_en = '1' else
                                    imm30_25(0) & imm24_20(4 downto 1);
                    end if;

                    if i_wb_en = '1' or (i_cnt_en = '1' and i_immdec_en(0) = '1') then
                        imm11_7 <= i_wb_rdt(11 downto 7) when i_wb_en = '1' else
                                    imm30_25(0) & imm11_7(4 downto 1);
                    end if;
                end if;
            end process;
        end generate gen_shared_imm_regs;

        gen_separate_imm_regs : if SHARED_RFADDR_IMM_REGS = false generate
            signal rd_addr  : std_logic_vector(4 downto 0);
            signal rs1_addr : std_logic_vector(4 downto 0);
            signal rs2_addr : std_logic_vector(4 downto 0);
        begin
            o_rd_addr  <= rd_addr;
            o_rs1_addr <= rs1_addr;
            o_rs2_addr <= rs2_addr;

            process (i_clk)
            begin
                if rising_edge(i_clk) then
                    if i_wb_en = '1' then
                        -- CSR immediates are always zero-extended, hence clear the signbit
                        imm31 <= i_wb_rdt(31);
                        imm19_12_20 <= i_wb_rdt(19 downto 12) & i_wb_rdt(20);
                        imm7 <= i_wb_rdt(7);
                        imm30_25 <= i_wb_rdt(30 downto 25);
                        imm24_20 <= i_wb_rdt(24 downto 20);
                        imm11_7 <= i_wb_rdt(11 downto 7);
                        rd_addr  <= i_wb_rdt(11 downto 7);
                        rs1_addr <= i_wb_rdt(19 downto 15);
                        rs2_addr <= i_wb_rdt(24 downto 20);
                    end if;

                    if i_cnt_en = '1' then
                        imm19_12_20 <= signbit     & imm19_12_20(8 downto 1) when i_ctrl(3) = '1' else
                                       imm24_20(0) & imm19_12_20(8 downto 1);
                        imm7 <= signbit;
                        imm30_25 <= imm7           & imm30_25(5 downto 1) when i_ctrl(2) = '1' else
                                    signbit        & imm30_25(5 downto 1) when i_ctrl(1) = '1' else
                                    imm19_12_20(0) & imm30_25(5 downto 1);
                        imm24_20 <= imm30_25(0) & imm24_20(4 downto 1);
                        imm11_7 <= imm30_25(0) & imm11_7(4 downto 1);
                    end if;
                end if;
            end process;
        end generate gen_separate_imm_regs;

        o_imm(0) <= signbit    when i_cnt_done = '1' else 
                    imm11_7(0) when i_ctrl(0) = '1'  else 
                    imm24_20(0);

    end generate gen_o_immdec_w_eq_1;

    gen_o_immdec_w_eq_4 : if W = 4 generate
        signal rd_addr  : std_logic_vector(4 downto 0);
        signal rs1_addr : std_logic_vector(4 downto 0);
        signal rs2_addr : std_logic_vector(4 downto 0);
        signal i31, i30, i29, i28, i27, i26, i25, i24, i23, i22, i21, i20, 
               i19, i18, i17, i16, i15, i14, i13, i12, i11, i10, i9, i8, i7 : std_logic;
        signal i7_2 : std_logic;
        signal i20_2 : std_logic;
        signal signbit : std_logic;
    begin
        signbit <= i31 and not i_csr_imm_en;
        o_csr_imm(3) <= i18;
        o_csr_imm(2) <= i17;
        o_csr_imm(1) <= i16;
        o_csr_imm(0) <= i15;

        o_rd_addr  <= rd_addr;
        o_rs1_addr <= rs1_addr;
        o_rs2_addr <= rs2_addr;

        process (i_clk)
        begin
            if rising_edge(i_clk) then
                if i_wb_en = '1' then
                    -- Common
                    i31 <= i_wb_rdt(31);

                    -- Bit lane 3
                    i19 <= i_wb_rdt(19);
                    i15 <= i_wb_rdt(15);
                    i20 <= i_wb_rdt(20);
                    i7  <= i_wb_rdt(7);
                    i27 <= i_wb_rdt(27);
                    i23 <= i_wb_rdt(23);
                    i10 <= i_wb_rdt(10);

                    -- Bit lane 2
                    i22 <= i_wb_rdt(22);
                    i9  <= i_wb_rdt(9);
                    i26 <= i_wb_rdt(26);
                    i30 <= i_wb_rdt(30);
                    i14 <= i_wb_rdt(14);
                    i18 <= i_wb_rdt(18);

                    -- Bit lane 1
                    i21 <= i_wb_rdt(21);
                    i8  <= i_wb_rdt(8);
                    i25 <= i_wb_rdt(25);
                    i29 <= i_wb_rdt(29);
                    i13 <= i_wb_rdt(13);
                    i17 <= i_wb_rdt(17);

                    -- Bit lane 0
                    i11 <= i_wb_rdt(11);
                    i7_2 <= i_wb_rdt(7);
                    i20_2 <= i_wb_rdt(20);
                    i24 <= i_wb_rdt(24);
                    i28 <= i_wb_rdt(28);
                    i12 <= i_wb_rdt(12);
                    i16 <= i_wb_rdt(16);

                    rd_addr  <= i_wb_rdt(11 downto 7);
                    rs1_addr <= i_wb_rdt(19 downto 15);
                    rs2_addr <= i_wb_rdt(24 downto 20);
                end if;
                if i_cnt_en = '1' then
                    --Bit lane 3
                    i10 <= i27;
                    i23 <= i27;
                    i27 <= i7       when i_ctrl(2) = '1' else 
                           signbit  when i_ctrl(1) = '1' else 
                           i20;
                    i7  <= signbit;
                    i20 <= i15;
                    i15 <= i19;
                    i19 <= signbit when i_ctrl(3) = '1' else i23;

                    --Bit lane 2
                    i22 <= i26;
                    i9  <= i26;
                    i26 <= i30;
                    i30 <= signbit when (i_ctrl(1) = '1' or i_ctrl(2) = '1') else i14;
                    i14 <= i18;
                    i18 <= signbit when i_ctrl(3) = '1' else i22;

                    --Bit lane 1
                    i21 <= i25;
                    i8  <= i25;
                    i25 <= i29;
                    i29 <= signbit when (i_ctrl(1) = '1' or i_ctrl(2) = '1') else i13;
                    i13 <= i17;
                    i17 <= signbit when i_ctrl(3) = '1' else i21;

                    --Bit lane 0
                    i7_2  <= i11;
                    i11   <= i28;
                    i20_2 <= i24;
                    i24   <= i28;
                    i28   <= signbit when (i_ctrl(1) = '1' or i_ctrl(2) = '1') else i12;
                    i12   <= i16;
                    i16   <= signbit when i_ctrl(3) = '1' else i20_2;
                end if;
            end if;
        end process;

        o_imm(3) <= signbit when i_cnt_done = '1' else 
                    i10     when i_ctrl(0)  = '1' else
                    i23;
        o_imm(2) <= i9      when i_ctrl(0)  = '1' else i22;
        o_imm(1) <= i8      when i_ctrl(0)  = '1' else i21;
        o_imm(0) <= i7_2    when i_ctrl(0)  = '1' else i20_2;

    end generate gen_o_immdec_w_eq_4;

end architecture rtl;
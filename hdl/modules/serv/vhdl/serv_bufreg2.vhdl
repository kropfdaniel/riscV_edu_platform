----------------------------------------------------------------------------------
-- File: serv_bufreg2.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV buffer register for load/store data and shift amount
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2022 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_bufreg2 is
    generic(
        W   : integer := 1;
        -- Internally calculated. Do not touch
        B   : integer := W-1
    );
    port(
        i_clk               : in  std_logic;
        -- State
        i_en                : in  std_logic;
        i_init              : in  std_logic;
        i_cnt7              : in  std_logic;
        i_cnt_done          : in  std_logic;
        i_sh_right          : in  std_logic;
        i_lsb               : in  std_logic_vector(1 downto 0);
        i_bytecnt           : in  std_logic_vector(1 downto 0);
        o_sh_done           : out std_logic;
        -- Control
        i_op_b_sel          : in  std_logic;
        i_shift_op          : in  std_logic; 
        -- Data
        i_rs2               : in  std_logic_vector(B downto 0);
        i_imm               : in  std_logic_vector(B downto 0);
        o_op_b              : out std_logic_vector(B downto 0);
        o_q                 : out std_logic_vector(B downto 0);
        -- External
        o_dat               : out std_logic_vector(31 downto 0);
        i_load              : in  std_logic;
        i_dat               : in  std_logic_vector(31 downto 0)
    );
end entity serv_bufreg2;

architecture rtl of serv_bufreg2 is
    -- High and low data words form a 32-bit word
    signal dhi : std_logic_vector(7 downto 0);
    signal dlo : std_logic_vector(23 downto 0);
    signal byte_valid, shift_en, cnt_en : std_logic;
    signal cnt_next, dat_shamt : std_logic_vector(7 downto 0);
    signal bytcnt0 : std_logic;
begin
    assert (W = 1 or W = 4)
        report "serv_bufreg2 PARAMETER ERROR: W must be exactly 1 or 4."
        severity failure;

    -- Before a store operation, the data to be written needs to be shifted into
    -- place. Depending on the address alignment, we need to shift different
    -- amounts. One formula for calculating this is to say that we shift when
    -- i_lsb + i_bytecnt < 4. Unfortunately, the synthesis tools don't seem to be
    -- clever enough so the hideous expression below is used to achieve the same
    -- thing in a more optimal way.
    byte_valid <= (not i_lsb(0) and not i_lsb(1))         or 
                  (not i_bytecnt(0) and not i_bytecnt(1)) or 
                  (not i_bytecnt(1) and not i_lsb(1))     or 
                  (not i_bytecnt(1) and not i_lsb(0))     or 
                  (not i_bytecnt(0) and not i_lsb(1));

    o_op_b <= i_rs2 when i_op_b_sel = '1' else i_imm;

    bytcnt0 <= '1' when i_bytecnt = 2B"00" else '0';
    shift_en <= (i_en and i_init and bytcnt0) when i_shift_op = '1' else 
                i_en and byte_valid;

    cnt_en <= (i_shift_op and (not i_init or (i_cnt_done and i_sh_right)));

    -- The dat register has three different use cases for store, load and
    -- shift operations.
    -- store : Data to be written is shifted to the correct position in dat during
    --         init by shift_en and is presented on the data bus as o_wb_dat
    -- load  : Data from the bus gets latched into dat during i_wb_ack and is then
    --         shifted out at the appropriate time to end up in the correct
    --         position in rd
    -- shift : Data is shifted in during init. After that, the six LSB are used as
    --         a downcounter (with bit 5 initially set to 0) that trigger
    --         o_sh_done when they wrap around to indicate that
    --         the requested number of shifts have been performed
    gen_cnt_w_eq_1 : if W=1 generate
        cnt_next <= o_op_b & dhi(7) & std_logic_vector( unsigned(dhi(5 downto 0))-6D"1" );
    end generate gen_cnt_w_eq_1;
    gen_cnt_w_eq_4 : if W=4 generate
        cnt_next <= o_op_b(3 downto 2) & std_logic_vector( unsigned(dhi(5 downto 0))-6D"4" );
    end generate gen_cnt_w_eq_4;

    dat_shamt <= 
        -- Down counter mode
        cnt_next when cnt_en = '1' else
        -- Shift reg mode
        o_op_b & dhi(7 downto W);

    o_sh_done <= dat_shamt(5);

    o_q <= o_dat(W+23 downto 24) when i_lsb = 2D"3" else
           o_dat(W+15 downto 16) when i_lsb = 2D"2" else
           o_dat( W+7 downto  8) when i_lsb = 2D"1" else
           o_dat( W-1 downto  0);

    o_dat <= dhi & dlo;

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if shift_en = '1' or cnt_en = '1' or i_load = '1' then
                dhi <= i_dat(31 downto 24) when i_load = '1' else
                       dat_shamt and (2B"11" & not(i_shift_op and i_cnt7 and not cnt_en)) & 5B"11111";
            end if;
            if shift_en = '1' or i_load = '1' then
                dlo <= i_dat(23 downto 0) when i_load = '1' else (dhi(B downto 0) & dlo(23 downto W));
            end if;
        end if;
    end process;
end architecture rtl;
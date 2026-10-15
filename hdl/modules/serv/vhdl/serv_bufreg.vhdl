----------------------------------------------------------------------------------
-- File: serv_bufreg.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV buffer register for load/store address and shift data
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2019 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_bufreg is
    generic(
        MDU : boolean := false;
        W   : integer := 1;
        B   : integer := W-1
    );
    port(
        i_clk               : in  std_logic;
        -- State
        i_cnt0              : in  std_logic;
        i_cnt1              : in  std_logic;
        i_cnt_done          : in  std_logic;
        i_en                : in  std_logic;
        i_init              : in  std_logic;
        i_mdu_op            : in  std_logic;
        o_lsb               : out std_logic_vector(1 downto 0);
        -- Control
        i_rs1_en            : in  std_logic;
        i_imm_en            : in  std_logic;
        i_clr_lsb           : in  std_logic;
        i_shift_op          : in  std_logic;
        i_right_shift_op    : in  std_logic;
        i_shamt             : in  std_logic_vector(2 downto 0);
        i_sh_signed         : in  std_logic;        
        -- Data
        i_rs1               : in  std_logic_vector(B downto 0);
        i_imm               : in  std_logic_vector(B downto 0);
        o_q                 : out std_logic_vector(B downto 0);
        -- External
        o_dbus_adr          : out std_logic_vector(31 downto 0);
        o_ext_rs1           : out std_logic_vector(31 downto 0)
    );
end entity serv_bufreg;

architecture rtl of serv_bufreg is
    signal c : std_logic;
    signal q, c_r, clr_lsb : std_logic_vector(B downto 0);
    signal data : std_logic_vector(31 downto 0);
    signal add_full : std_logic_vector(W downto 0);
begin

    assert (W = 1 or W = 4)
        report "serv_bufreg PARAMETER ERROR: W must be exactly 1 or 4."
        severity failure;
    
    clr_lsb(0) <= i_cnt0 and i_clr_lsb;

    gen_clr_lsb_w_gt_1 : if W > 1 generate
        clr_lsb(B downto 1) <= (B downto 1 => '0');
    end generate gen_clr_lsb_w_gt_1;

    add_full <= std_logic_vector( unsigned('1' & (i_rs1 and (B downto 0 => i_rs1_en))) +
                                  unsigned('1' & (i_imm and (B downto 0 => i_imm_en) and not clr_lsb)) +
                                  unsigned(c_r) );
    c <= add_full(W);
    q <= add_full(B downto 0);

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- Make sure carry is cleared before loading new data
            c_r    <= (B downto 0 => '0');
            c_r(0) <= c and i_en;
        end if;
    end process;

    gen_w_eq_1 : if W = 1 generate 
        process(i_clk)
        begin
            if rising_edge(i_clk) then
                if i_en = '1' then
                    data(31 downto 2) <= q & data (31 downto 3) when i_init = '1' else
                                         (B downto 0 => data(31) and i_sh_signed) & data (31 downto 3);
                end if;

                if i_init = '1' then
                    if i_cnt0 = '1' or i_cnt1 = '1' then
                        data(1 downto 0) <= q(0) & data(1);
                    end if;
                else
                    if i_en = '1' then
                        data(1 downto 0) <= data(2 downto 1);
                    end if;
                end if;
            end if;
        end process;
        o_lsb <= 2B"00" when (MDU and i_mdu_op = '1') else data(1 downto 0);
        o_q(0) <= data(0) and i_en;
    end generate gen_w_eq_1;

    gen_lsb_w_4 : if W = 4 generate 
        signal lsb          : std_logic_vector(1 downto 0);
        signal data_tail    : std_logic_vector(W-2 downto 0);
        signal shift_amount : std_logic_vector(2 downto 0);
        signal muxdata      : std_logic_vector(2*W+B-2 downto 0);
        signal muxout       : std_logic_vector(B downto 0);
    begin
        shift_amount <= 3D"3" when i_shift_op = '0' else
                        std_logic_vector(3D"3" + unsigned('0' & i_shamt(1 downto 0))) 
                              when i_right_shift_op = '1' else
                        '0' & not i_shamt(1 downto 0);
        
        process(i_clk)
        begin
            if rising_edge(i_clk) then
                if i_en = '1' then
                    if i_cnt0 = '1' then
                        lsb <= q(1 downto 0);
                    end if;
                    data <= q & data(31 downto W) when i_init = '1' else 
                            (B downto 0 => i_sh_signed and data(31)) & data(31 downto W);
                    data_tail <= data(B downto 1) and (B-1 downto 0 => not i_cnt_done);
                end if;
            end if;
        end process;

        muxdata <= data(W+B-1 downto 0) & data_tail;
        
        process(muxdata, shift_amount)
            variable base_index : integer;
        begin
            base_index := to_integer(unsigned('0' & shift_amount));

            for i in 0 to B loop
                muxout(i) <= muxdata(base_index + i);
            end loop; 
        end process;

        o_lsb <= 2B"00" when MDU and i_mdu_op = '1' else lsb;
        o_q <= muxout when i_en = '1' else (B downto 0 => '0');
    end generate gen_lsb_w_4;

    o_dbus_adr <= data(31 downto 2) & 2B"00";
    o_ext_rs1 <= data;    
end architecture rtl;
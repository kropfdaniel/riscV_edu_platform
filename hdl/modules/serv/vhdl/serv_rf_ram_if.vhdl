-- File: serv_rf_ram_if.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: Interface between SERV and SRAM-based RF storage
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2019 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.serv_pkg.all;

entity serv_rf_ram_if is
    generic(
        -- Data width. Adjust to preferred width of SRAM data interface
        WIDTH          : integer := 8;
        W              : integer := 1;
        -- Select reset strategy.                                      
        -- "MINI" for resetting minimally required FFs
        -- "NONE" for relying on FFs having a defined value on startupdepth
        RESET_STRATEGY : string := "MINI";
        -- Number of CSR registers. These are allocated after the normal
        -- GPR registers in the RAM.
        CSR_REGS       : integer := 4;
        -- Internal parameters calculated from above values. Do not change
        B              : integer := W-1;
        raw            : integer := clog2(32+CSR_REGS); -- Register address width
        l2w            : integer := clog2(WIDTH);       -- log2 of width
        aw             : integer := 5+raw-l2w           -- Address width
    );
    port(
        -- SERV side
        i_clk               : in  std_logic;
        i_rst               : in  std_logic;
        i_wreq              : in  std_logic;
        i_rreq              : in  std_logic;
        o_ready             : out std_logic;
        i_wreg0             : in  std_logic_vector(raw-1 downto 0);
        i_wreg1             : in  std_logic_vector(raw-1 downto 0);
        i_wen0              : in  std_logic;
        i_wen1              : in  std_logic;
        i_wdata0            : in  std_logic_vector(B downto 0);
        i_wdata1            : in  std_logic_vector(B downto 0);
        i_rreg0             : in  std_logic_vector(raw-1 downto 0);
        i_rreg1             : in  std_logic_vector(raw-1 downto 0);
        o_rdata0            : out std_logic_vector(B downto 0);
        o_rdata1            : out std_logic_vector(B downto 0);
        -- RAM side
        o_waddr             : out std_logic_vector(aw-1 downto 0);
        o_wdata             : out std_logic_vector(width-1 downto 0);
        o_wen               : out std_logic;
        o_raddr             : out std_logic_vector(aw-1 downto 0);
        o_ren               : out std_logic;
        i_rdata             : in  std_logic_vector(width-1 downto 0)
    );
end entity serv_rf_ram_if;

architecture rtl of serv_rf_ram_if is
    constant ratio : integer := WIDTH/W;
    constant CMSB  : integer := 4-clog2(W); -- Counter MSB
    constant l2r   : integer := clog2(ratio);

    signal rgnt, rtrig0, rtrig1, wen0_r, wen1_r, wtrig0, 
           wtrig1, rgate, rreq_r : std_logic;
    signal rcnt, wcnt : unsigned(CMSB downto 0);
    signal wdata0_r, rdata0 : std_logic_vector(WIDTH-1 downto 0);
    signal wdata1_r : std_logic_vector(WIDTH+W-1 downto 0);
    signal wreg, rreg : std_logic_vector(raw-1 downto 0);
    signal rdata1 : std_logic_vector(WIDTH-1-W downto 0);
begin
    o_ready <= rgnt or i_wreq;
    
    -- ********** Write side ***********

    wtrig0 <= rtrig1;

    gen_wtrig_ratio_eq_2 : if ratio = 2 generate
        wtrig1 <= wcnt(0);
    end generate gen_wtrig_ratio_eq_2;

    gen_wtrig_ratio_neq_2 : if ratio /= 2 generate
        signal wtrig0_r : std_logic;
    begin
        process(i_clk)
        begin
            if rising_edge(i_clk) then
                wtrig0_r <= wtrig0;
            end if;
        end process;
        wtrig1 <= wtrig0_r;
    end generate;

    o_wdata <= wdata1_r(WIDTH-1 downto 0) when (??wtrig1) else wdata0_r;
    
    wreg <= i_wreg1 when (??wtrig1) else i_wreg0;

    gen_w_eq_32 : if WIDTH = 32 generate
        o_waddr <= wreg;
    end generate gen_w_eq_32;
    gen_w_neq_32 : if WIDTH /= 32 generate
        o_waddr <= wreg & std_logic_vector(wcnt(CMSB downto l2r));
    end generate gen_w_neq_32;

    o_wen <= (wtrig0 and wen0_r) or (wtrig1 and wen1_r);

    wcnt <= rcnt - 4;

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if wcnt(0) then
                wen0_r <= i_wen0;
                wen1_r <= i_wen1;
            end if;

            wdata0_r <= i_wdata0 & wdata0_r(WIDTH-1 downto W);
            wdata1_r <= i_wdata1 & wdata1_r(WIDTH+W-1 downto W);
        end if;
    end process;

    -- ********** Read side ***********

    rreg <= i_rreg1 when (??rtrig0) else i_rreg0;
    
    gen_rreg_eq_32 : if WIDTH = 32 generate
        o_raddr <= rreg;
    end generate gen_rreg_eq_32;
    gen_rreg_neq_32 : if WIDTH /= 32 generate
        o_raddr <= rreg & std_logic_vector(rcnt(CMSB downto l2r));
    end generate gen_rreg_neq_32;

    o_rdata0 <= rdata0(B downto 0);
    o_rdata1 <= i_rdata(B downto 0) when (??rtrig1) else rdata1(B downto 0);

    rtrig0 <= '1' when rcnt(l2r-1 downto 0) = 1 else '0';

    gen_ren_w_eq_2 : if ratio = 2 generate
        o_ren <= rgate;
    end generate gen_ren_w_eq_2;
    gen_ren_w_neq_2 : if ratio /= 2 generate
        o_ren <= '1' when (??rgate) and (rcnt(l2r-1 downto 1) = 0) else '0';
    end generate gen_ren_w_neq_2;

    gen_rdata1 : if ratio > 2 generate
        process(i_clk)
        begin
            if rising_edge(i_clk) then
                rdata1 <= (B downto 0 => '0') & rdata1(WIDTH-W-1 downto W);
                if rtrig1 then
                    rdata1(WIDTH-W-1 downto 0) <= i_rdata(WIDTH-1 downto W);
                end if;
            end if;
        end process;
    else generate
        process(i_clk)
        begin
            if rising_edge(i_clk) and (??rtrig1) then
                rdata1 <= i_rdata(W*2-1 downto W);
            end if;
        end process;
    end generate gen_rdata1;

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (and rcnt) or i_rreq then
                rgate <= i_rreq;
            end if;

            rtrig1 <= rtrig0;
            rcnt <= rcnt + 1;

            if i_rreq or i_wreq then
                rcnt <= (CMSB-2 downto 0 => '0') & i_wreq & '0'; 
            end if;

            rreq_r <= i_rreq;
            rgnt <= rreq_r;

            rdata0 <= (B downto 0 => '0') & rdata0(WIDTH-1 downto W);
            if rtrig0 then
                rdata0 <= i_rdata;
            end if;
            
            if i_rst then
                if RESET_STRATEGY /= "NONE" then
                    rgate  <= '0';
                    rgnt   <= '0';
                    rreq_r <= '0';
                    rcnt   <= (others => '0');
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
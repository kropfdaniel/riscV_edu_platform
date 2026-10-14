----------------------------------------------------------------------------------
-- File: serv_aligner.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: Realign a misaligned 32-bit word fetched from memory
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2020 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_aligner is
    port(
        clk             : in  std_logic;
        rst             : in  std_logic;
        -- serv_top
        i_ibus_adr      : in  std_logic_vector(31 downto 0);
        i_ibus_cyc      : in  std_logic;
        o_ibus_rdt      : out std_logic_vector(31 downto 0);
        o_ibus_ack      : out std_logic;
        -- serv_rf_top
        o_wb_ibus_adr   : out std_logic_vector(31 downto 0);
        o_wb_ibus_cyc   : out std_logic;
        i_wb_ibus_rdt   : in  std_logic_vector(31 downto 0);
        i_wb_ibus_ack   : in  std_logic
    );
end entity serv_aligner;

architecture rtl of serv_aligner is
    signal ibus_rdt_concat : std_logic_vector(31 downto 0);
    signal ack_en          : std_logic;
    signal lower_hw        : std_logic_vector(15 downto 0);
    signal ctrl_misal      : std_logic;
begin
    -- From SERV core to Memory
    --
    -- o_wb_ibus_adr: Carries address of instruction to memory. In case of misaligned access,
    -- which is caused by pc+2 due to compressed instruction, next instruction is fetched
    -- by pc+4 and concatenation is done to make the instruction aligned.
    --
    -- o_wb_ibus_cyc: Simply forwarded from SERV to Memory and is only altered by memory or SERV core.
    o_wb_ibus_adr <= std_logic_vector(unsigned(i_ibus_adr) + 4) when ctrl_misal = '1' else i_ibus_adr;
    o_wb_ibus_cyc <= i_ibus_cyc;

    -- From Memory to SERV core
    --
    -- o_ibus_ack: Instruction bus acknowledge is send to SERV only when the aligned instruction,
    -- either compressed or un-compressed, is ready to dispatch.
    --
    -- o_ibus_rdt: Carries the instruction from memory to SERV core. It can be either aligned
    -- instruction coming from memory or made aligned by two bus transactions and concatenation.
    o_ibus_ack <= i_wb_ibus_ack and ack_en;
    o_ibus_rdt <= ibus_rdt_concat when ctrl_misal = '1' else i_wb_ibus_rdt;

    process(clk)
    begin
        if rising_edge(clk) and i_wb_ibus_ack = '1' then
            lower_hw <= i_wb_ibus_rdt(31 downto 16);
        end if;
    end process;

    ibus_rdt_concat <= i_wb_ibus_rdt(15 downto 0) & lower_hw;

    -- Two control signals: ack_en, ctrl_misal are set to control the bus transactions between
    -- SERV core and the memory
    ack_en <= not (i_ibus_adr(1) and not ctrl_misal);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ctrl_misal <= '0';
            elsif i_wb_ibus_ack = '1' and i_ibus_adr(1) = '1' then
                ctrl_misal <= not ctrl_misal;
            end if;
        end if;
    end process;
end architecture rtl;
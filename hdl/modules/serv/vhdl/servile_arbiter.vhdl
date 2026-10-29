-- File: servile_arbiter.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: I/D arbiter for the servile convenience wrapper.
--              Relies on the fact that not ibus and dbus are active at the same time.
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2024 Olof Kindgren
--              Original License: Apache-2.0
-- Changes compared to original servile_arbiter.v:
-- - renamed signals
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity servile_arbiter is
    port(
        -- SERV
        i_serv_dbus_adr : in  std_logic_vector(31 downto 0);
        i_serv_dbus_dat : in  std_logic_vector(31 downto 0);
        i_serv_dbus_sel : in  std_logic_vector(3 downto 0);
        i_serv_dbus_we  : in  std_logic;
        i_serv_dbus_stb : in  std_logic;
        o_serv_dbus_rdt : out std_logic_vector(31 downto 0);
        o_serv_dbus_ack : out std_logic;

        i_serv_ibus_adr : in  std_logic_vector(31 downto 0);
        i_serv_ibus_stb : in  std_logic;
        o_serv_ibus_rdt : out std_logic_vector(31 downto 0);
        o_serv_ibus_ack : out std_logic;
        
        -- Wishbone IF
        o_wb_adr        : out std_logic_vector(31 downto 0);
        o_wb_dat        : out std_logic_vector(31 downto 0);
        o_wb_sel        : out std_logic_vector(3 downto 0);
        o_wb_we         : out std_logic;
        o_wb_stb        : out std_logic;
        i_wb_rdt        : in  std_logic_vector(31 downto 0);
        i_wb_ack        : in  std_logic
    );
end entity servile_arbiter;

architecture rtl of servile_arbiter is

begin
    o_serv_dbus_rdt <= i_wb_rdt;
    o_serv_dbus_ack <= i_wb_ack and not(i_serv_ibus_stb);

    o_serv_ibus_rdt <= i_wb_rdt;
    o_serv_ibus_ack <= i_wb_ack and i_serv_ibus_stb;

    o_wb_adr <= i_serv_ibus_adr when (??i_serv_ibus_stb) else i_serv_dbus_adr;
    o_wb_dat <= i_serv_dbus_dat;
    o_wb_sel <= i_serv_dbus_sel;
    o_wb_we  <= i_serv_dbus_we and not(i_serv_ibus_stb);
    o_wb_stb <= i_serv_ibus_stb or i_serv_dbus_stb;
end architecture;
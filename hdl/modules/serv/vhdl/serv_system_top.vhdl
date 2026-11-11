-- File: serv_system_top.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: System Toplevel including SERV with RF and Bus Arbiter
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.serv_pkg.all;

entity serv_system_top is
    generic(
        DataBits     : integer := 32;  -- only 32 bit supported
        AddrBits     : integer := 32;  -- only 32 bit supported
        -- COMPRESSED=1: Enable the compressed decoder and allowed misaligned jump of pc
        -- COMPRESSED=0: Disable the compressed decoder and does not allow the misaligned jump of pc        
        COMPRESSED   : boolean := false;

        -- ALIGN = 1: Fetch the aligned instruction by making two bus transactions if the misaligned address
        -- is given to the instruction bus.
        ALIGN        : boolean := COMPRESSED;

        -- Multiplication and Division Unit
        -- This parameter enables the interface for connecting SERV and MDU
        MDU          : boolean := false;
        -- Register signals before or after the decoder
        -- 0 : Register after the decoder. Faster but uses more resources
        -- 1 : (default) Register before the decoder. Slower but uses less resources
        PRE_REGISTER : boolean := false;
        WITH_CSR     : boolean := true;
        W            : integer := 1
    );
    port(
        CLK_I        : in  std_logic;
        RST_I        : in  std_logic;
        DAT_I        : in  std_logic_vector( DataBits-1 downto 0 );
        DAT_O        : out std_logic_vector( DataBits-1 downto 0 );
        -- TAGD_I and TAGD_O are not implemented
        ACK_I        : in  std_logic;
        ADDR_O       : out std_logic_vector( AddrBits-1 downto 0 );
        CYC_O        : out std_logic;
        -- ERR_I and LOCK_O are not implemented
        -- RTY_I is not implemented
        SEL_O        : out std_logic_vector( (DataBits/8)-1 downto 0 );
        STB_O        : out std_logic;
        -- TGA_O and TGC_O are not implemented
        WE_O         : out std_logic;
        -- CTI_O and BTE_O arre not implemented
        
        i_timer_irq  : in  std_logic;

        -- Extension
        o_ext_rs1    : out std_logic_vector(DataBits-1 downto 0);  
        o_ext_rs2    : out std_logic_vector(DataBits-1 downto 0);
        o_ext_funct3 : out std_logic_vector(2 downto 0); 
        i_ext_rd     : in  std_logic_vector(DataBits-1 downto 0);
        i_ext_ready  : in  std_logic;
        -- MDU
        o_mdu_valid  : out std_logic;
        -- External
        reset_vec    : in std_logic_vector(AddrBits-1 downto 0)
    );
end entity serv_system_top;

architecture rtl of serv_system_top is
    signal serv_dbus_adr, serv_ibus_adr  : std_logic_vector(AddrBits-1 downto 0);
    signal serv_dbus_dat, serv_dbus_rdt, serv_ibus_rdt : std_logic_vector(DataBits-1 downto 0);
    signal serv_dbus_sel : std_logic_vector( (DataBits/8)-1 downto 0);
    signal serv_dbus_we : std_logic;
    signal serv_dbus_cyc, serv_ibus_cyc : std_logic;
    signal serv_dbus_ack, serv_ibus_ack : std_logic;
begin
    assert (AddrBits = 32)
        report "serv_system_top PARAMETER ERROR: AddrBits must be exactly 32."
        severity failure;

    assert (DataBits = 32)
        report "serv_system_top PARAMETER ERROR: DataBits must be exactly 32."
        severity failure;
    
    serv_with_rf : entity work.serv_rf_top(rtl)
    generic map ( 
        COMPRESSED   => COMPRESSED,
        ALIGN        => ALIGN,
        MDU          => MDU,
        PRE_REGISTER => PRE_REGISTER,
        WITH_CSR     => WITH_CSR,
        W            => W
    )
    port map (
        clk          => CLK_I,      
        i_rst        => RST_I,
        i_timer_irq  => i_timer_irq,
        o_ibus_adr   => serv_ibus_adr,
        o_ibus_cyc   => serv_ibus_cyc,
        i_ibus_rdt   => serv_ibus_rdt,
        i_ibus_ack   => serv_ibus_ack,
        o_dbus_adr   => serv_dbus_adr,
        o_dbus_dat   => serv_dbus_dat,
        o_dbus_sel   => serv_dbus_sel,
        o_dbus_we    => serv_dbus_we,
        o_dbus_cyc   => serv_dbus_cyc,
        i_dbus_rdt   => serv_dbus_rdt,
        i_dbus_ack   => serv_dbus_ack,
        -- =>  Extension
        o_ext_rs1    => o_ext_rs1,
        o_ext_rs2    => o_ext_rs2,
        o_ext_funct3 => o_ext_funct3,
        i_ext_rd     => i_ext_rd,
        i_ext_ready  => i_ext_ready,
        -- =>  MDU      
        o_mdu_valid  => o_mdu_valid,
        -- =>  External 
        reset_vec    => reset_vec
    );

    bus_arbiter : entity work.servile_arbiter(rtl)
        port map(
            i_serv_dbus_adr => serv_dbus_adr,
            i_serv_dbus_dat => serv_dbus_dat,
            i_serv_dbus_sel => serv_dbus_sel,
            i_serv_dbus_we  => serv_dbus_we, 
            i_serv_dbus_cyc => serv_dbus_cyc,
            o_serv_dbus_rdt => serv_dbus_rdt,
            o_serv_dbus_ack => serv_dbus_ack,

            i_serv_ibus_adr => serv_ibus_adr,
            i_serv_ibus_cyc => serv_ibus_cyc,
            o_serv_ibus_rdt => serv_ibus_rdt,
            o_serv_ibus_ack => serv_ibus_ack,
            -- Wishbone IF 
            o_wb_adr        => ADDR_O,
            o_wb_dat        => DAT_O,
            o_wb_sel        => SEL_O,
            o_wb_we         => WE_O,
            o_wb_cyc        => CYC_O,
            i_wb_rdt        => DAT_I,
            i_wb_ack        => ACK_I
        );

    STB_O <= CYC_O;

end architecture;
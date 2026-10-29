-- File: serv_rf_top.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: Toplevel including SERV and SRAM-based RF storage
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2019 Olof Kindgren
--              Original License: ISC
-- Changes compared to original serv_rf_top.v:
-- - debug generic is not supported (generic is still there for equiv check, but must be set to false)
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.serv_pkg.all;

entity serv_rf_top is
    generic(
        RESET_PC        : std_logic_vector(31 downto 0);

        -- COMPRESSED=1: Enable the compressed decoder and allowed misaligned jump of pc
        -- COMPRESSED=0: Disable the compressed decoder and does not allow the misaligned jump of pc        
        COMPRESSED      : boolean := false;

        -- ALIGN = 1: Fetch the aligned instruction by making two bus transactions if the misaligned address
        -- is given to the instruction bus.
        ALIGN           : boolean := COMPRESSED;

        -- Multiplication and Division Unit
        -- This parameter enables the interface for connecting SERV and MDU
        MDU             : boolean := false;
        -- Register signals before or after the decoder
        -- 0 : Register after the decoder. Faster but uses more resources
        -- 1 : (default) Register before the decoder. Slower but uses less resources
        PRE_REGISTER    : boolean := false;
        -- Amount of reset applied to design
        -- "NONE" : No reset at all. Relies on a POR to set correct initialization
        --          values and that core isn't reset during runtime
        -- "MINI" : Standard setting. Resets the minimal amount of FFs needed to
        --          restart execution from the instruction at RESET_PC
        RESET_STRATEGY  : string := "MINI";

        DEBUG           : boolean := false; -- unsupported. must be set to false
        WITH_CSR        : boolean := true;
        W               : integer := 1;
        RF_WIDTH        : integer := 2*W;
        RF_L2D          : integer := clog2((32+(bool_to_int(WITH_CSR)*4))*32/RF_WIDTH)
    );
    port(
        clk                 : in  std_logic;
        i_rst               : in  std_logic;
        i_timer_irq         : in  std_logic;

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
        o_ext_rs1           : out std_logic_vector(31 downto 0);  
        o_ext_rs2           : out std_logic_vector(31 downto 0);
        o_ext_funct3        : out std_logic_vector(2 downto 0); 
        i_ext_rd            : in  std_logic_vector(31 downto 0);
        i_ext_ready         : in  std_logic;
        -- MDU
        o_mdu_valid         : out std_logic
    );
end entity serv_rf_top;

architecture rtl of serv_rf_top is
    constant CSR_REGS : integer := bool_to_int(WITH_CSR)*4;
    signal rf_wreq, rf_rreq, wen0, wen1, rf_ready, wen, ren : std_logic;
    signal wreg0, wreg1, rreg0, rreg1 : std_logic_vector(4+bool_to_int(WITH_CSR) downto 0);
    signal wdata0, wdata1, rdata0, rdata1 : std_logic_vector(W-1 downto 0);
    signal waddr, raddr : std_logic_vector(RF_L2D-1 downto 0);
    signal wdata, rdata : std_logic_vector(RF_WIDTH-1 downto 0);
begin
    assert (DEBUG = false)
        report "serv_rf_top PARAMETER ERROR: Debug is not supported. Must be set to false"
        severity failure;
    
    rf_ram_if : entity work.serv_rf_ram_if(rtl)
    generic map ( WIDTH => RF_WIDTH,
                  RESET_STRATEGY => RESET_STRATEGY,
                  CSR_REGS => CSR_REGS,
                  W => W  )
    port map ( -- SERV side
               i_clk    => clk,
               i_rst    => i_rst,
               i_wreq   => rf_wreq,
               i_rreq   => rf_rreq,
               o_ready  => rf_ready,
               i_wreg0  => wreg0,
               i_wreg1  => wreg1, 
               i_wen0   => wen0,  
               i_wen1   => wen1,  
               i_wdata0 => wdata0,
               i_wdata1 => wdata1,
               i_rreg0  => rreg0, 
               i_rreg1  => rreg1, 
               o_rdata0 => rdata0,
               o_rdata1 => rdata1,
               -- RAM side 
               o_waddr  => waddr,
               o_wdata  => wdata,
               o_wen    => wen,  
               o_raddr  => raddr,
               o_ren    => ren,  
               i_rdata  => rdata );

    rf_ram : entity work.serv_rf_ram(rtl)
    generic map ( WIDTH    => RF_WIDTH,
                  CSR_REGS => CSR_REGS )
    port map ( i_clk    => clk,
               i_waddr  => waddr,
               i_wdata  => wdata,
               i_wen    => wen,  
               i_raddr  => raddr,
               i_ren    => ren,  
               o_rdata  => rdata );

    cpu : entity work.serv_top(rtl)
    generic map ( RESET_PC          => RESET_PC,
                  PRE_REGISTER      => PRE_REGISTER,
                  RESET_STRATEGY    => RESET_STRATEGY,
                  WITH_CSR          => WITH_CSR,
                  DEBUG             => DEBUG,
                  MDU               => MDU,
                  COMPRESSED        => COMPRESSED,
                  ALIGN             => ALIGN,
                  W                 => W )
    port map ( clk          => clk,
               i_rst        => i_rst,
               i_timer_irq  => i_timer_irq,
               -- RF Interface 
               o_rf_rreq    => rf_rreq, 
               o_rf_wreq    => rf_wreq, 
               i_rf_ready   => rf_ready,
               o_wreg0      => wreg0,   
               o_wreg1      => wreg1,   
               o_wen0       => wen0,    
               o_wen1       => wen1,    
               o_wdata0     => wdata0,  
               o_wdata1     => wdata1,  
               o_rreg0      => rreg0,   
               o_rreg1      => rreg1,   
               i_rdata0     => rdata0,  
               i_rdata1     => rdata1,  
               --            
               o_ibus_adr   => o_ibus_adr,
               o_ibus_cyc   => o_ibus_cyc,
               i_ibus_rdt   => i_ibus_rdt,
               i_ibus_ack   => i_ibus_ack,
               o_dbus_adr   => o_dbus_adr,
               o_dbus_dat   => o_dbus_dat,
               o_dbus_sel   => o_dbus_sel,
               o_dbus_we    => o_dbus_we, 
               o_dbus_cyc   => o_dbus_cyc,
               i_dbus_rdt   => i_dbus_rdt,
               i_dbus_ack   => i_dbus_ack,
               -- Extension    
               o_ext_funct3 => o_ext_funct3,
               i_ext_ready  => i_ext_ready, 
               i_ext_rd     => i_ext_rd,    
               o_ext_rs1    => o_ext_rs1,   
               o_ext_rs2    => o_ext_rs2,   
               -- MDU          
               o_mdu_valid  => o_mdu_valid );

end architecture;
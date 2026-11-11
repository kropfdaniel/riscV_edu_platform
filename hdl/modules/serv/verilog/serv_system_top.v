/* File: serv_system_top.vhdl
 * Author: Daniel Kropf
 * License: MIT License
 * 
 * Description: System Toplevel including SERV with RF and Bus Arbiter
 * *********************************************
 */

module serv_system_top
    #(
        parameter DataBits = 32, // only 32 bit supported
        parameter AddrBits = 32, // only 32 bit supported
        /*  COMPRESSED=1: Enable the compressed decoder and allowed misaligned jump of pc
            COMPRESSED=0: Disable the compressed decoder and does not allow the misaligned jump of pc
        */
        parameter [0:0] COMPRESSED = 0,
        /*
        ALIGN = 1: Fetch the aligned instruction by making two bus transactions if the misaligned address
        is given to the instruction bus.
        */
        parameter [0:0] ALIGN = COMPRESSED,
        /* Multiplication and Division Unit
        This parameter enables the interface for connecting SERV and MDU
        */
        parameter [0:0] MDU = 0,
        /* Register signals before or after the decoder
        0 : Register after the decoder. Faster but uses more resources
        1 : (default) Register before the decoder. Slower but uses less resources
        */
        parameter PRE_REGISTER = 1,
        /* Amount of reset applied to design
        "NONE" : No reset at all. Relies on a POR to set correct initialization
                    values and that core isn't reset during runtime
        "MINI" : Standard setting. Resets the minimal amount of FFs needed to
                    restart execution from the instruction at reset_vec
        */
        parameter RESET_STRATEGY = "MINI",
        parameter [0:0] DEBUG = 1'b0,
        parameter WITH_CSR = 1,
        parameter W        = 1)
    ( 
        input  wire CLK_I,
        input  wire RST_I,
        input  wire [DataBits-1:0] DAT_I,
        output wire [DataBits-1:0] DAT_O,
        // TAGD_I and TAGD_O are not implemented
        input  wire ACK_I,
        output wire [AddrBits-1:0] ADDR_O,
        output wire CYC_O,
        // ERR_I and LOCK_O are not implemented
        // RTY_I is not implemented
        output wire [(DataBits/8)-1:0] SEL_O,
        output wire STB_O,
        // TGA_O and TGC_O are not implemented
        output wire WE_O,
        // CTI_O and BTE_O arre not implemented

        input wire 	      i_timer_irq,
        // Extension
        output wire [DataBits-1:0] o_ext_rs1,
        output wire [DataBits-1:0] o_ext_rs2,
        output wire [ 2:0] o_ext_funct3,
        input  wire [DataBits-1:0] i_ext_rd,
        input  wire        i_ext_ready,
        // MDU
        output wire        o_mdu_valid,
        // External
        input  wire [AddrBits-1:0] reset_vec
    );

    wire [AddrBits-1:0] serv_dbus_adr, serv_ibus_adr;
    wire [DataBits-1:0] serv_dbus_dat, serv_dbus_rdt, serv_ibus_rdt;
    wire [(DataBits/8)-1:0] serv_dbus_sel;
    wire serv_dbus_we;
    wire serv_dbus_cyc, serv_ibus_cyc;
    wire serv_dbus_ack, serv_ibus_ack;
    
    serv_rf_top #(
        .COMPRESSED(COMPRESSED),
        .ALIGN(ALIGN),
        .MDU(MDU),
        .PRE_REGISTER(PRE_REGISTER),
        .RESET_STRATEGY(RESET_STRATEGY),
        .DEBUG(DEBUG),
        .WITH_CSR(WITH_CSR),
        .W(W)
    ) serv_with_rf (
        .clk(CLK_I),
        .i_rst(RST_I),
        .i_timer_irq(i_timer_irq),
        .o_ibus_adr(serv_ibus_adr),
        .o_ibus_cyc(serv_ibus_cyc),
        .i_ibus_rdt(serv_ibus_rdt),
        .i_ibus_ack(serv_ibus_ack),
        .o_dbus_adr(serv_dbus_adr),
        .o_dbus_dat(serv_dbus_dat),
        .o_dbus_sel(serv_dbus_sel),
        .o_dbus_we (serv_dbus_we ),
        .o_dbus_cyc(serv_dbus_cyc),
        .i_dbus_rdt(serv_dbus_rdt),
        .i_dbus_ack(serv_dbus_ack),
        .o_ext_rs1(o_ext_rs1),
        .o_ext_rs2(o_ext_rs2),
        .o_ext_funct3(o_ext_funct3),
        .i_ext_rd(i_ext_rd),
        .i_ext_ready(i_ext_ready),
        .o_mdu_valid(o_mdu_valid),
        .reset_vec(reset_vec)
    );

    servile_arbiter #() 
    bus_arbiter (
        .i_serv_dbus_adr(serv_dbus_adr),
        .i_serv_dbus_dat(serv_dbus_dat),
        .i_serv_dbus_sel(serv_dbus_sel),
        .i_serv_dbus_we (serv_dbus_we ),
        .i_serv_dbus_cyc(serv_dbus_cyc),
        .o_serv_dbus_rdt(serv_dbus_rdt),
        .o_serv_dbus_ack(serv_dbus_ack),
        .i_serv_ibus_adr(serv_ibus_adr),
        .i_serv_ibus_cyc(serv_ibus_cyc),
        .o_serv_ibus_rdt(serv_ibus_rdt),
        .o_serv_ibus_ack(serv_ibus_ack),

        .o_wb_adr(ADDR_O),
        .o_wb_dat(DAT_O),
        .o_wb_sel(SEL_O),
        .o_wb_we (WE_O ),
        .o_wb_cyc(CYC_O),
        .i_wb_rdt(DAT_I),
        .i_wb_ack(ACK_I)
    );

    assign STB_O = CYC_O;
endmodule
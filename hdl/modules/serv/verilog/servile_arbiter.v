/*
 * servile_arbiter.v : I/D arbiter for the servile convenience wrapper.
 *  Relies on the fact that not ibus and dbus are active at the same time.
 *
 * SPDX-FileCopyrightText: 2024 Olof Kindgren <olof.kindgren@gmail.com>
 * SPDX-License-Identifier: Apache-2.0
 *
 * Modified 2026 by Daniel Kropf
 * Changes:
 * - renamed signals
 */

module servile_arbiter
  (
   input wire [31:0]  i_serv_dbus_adr,
   input wire [31:0]  i_serv_dbus_dat,
   input wire [3:0]   i_serv_dbus_sel,
   input wire 	      i_serv_dbus_we,
   input wire 	      i_serv_dbus_stb,
   output wire [31:0] o_serv_dbus_rdt,
   output wire 	      o_serv_dbus_ack,

   input wire [31:0]  i_serv_ibus_adr,
   input wire 	      i_serv_ibus_stb,
   output wire [31:0] o_serv_ibus_rdt,
   output wire 	      o_serv_ibus_ack,

   output wire [31:0] o_wb_adr,
   output wire [31:0] o_wb_dat,
   output wire [3:0]  o_wb_sel,
   output wire 	      o_wb_we,
   output wire 	      o_wb_stb,
   input wire [31:0]  i_wb_rdt,
   input wire 	      i_wb_ack);

   assign o_serv_dbus_rdt = i_wb_rdt;
   assign o_serv_dbus_ack = i_wb_ack & !i_serv_ibus_stb;

   assign o_serv_ibus_rdt = i_wb_rdt;
   assign o_serv_ibus_ack = i_wb_ack & i_serv_ibus_stb;

   assign o_wb_adr = i_serv_ibus_stb ? i_serv_ibus_adr : i_serv_dbus_adr;
   assign o_wb_dat = i_serv_dbus_dat;
   assign o_wb_sel = i_serv_dbus_sel;
   assign o_wb_we  = i_serv_dbus_we & !i_serv_ibus_stb;
   assign o_wb_stb = i_serv_ibus_stb | i_serv_dbus_stb;


endmodule

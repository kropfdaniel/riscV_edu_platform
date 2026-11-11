/*
 * serv_rf_ram.v : SRAM-based RF storage for SERV
 *
 * SPDX-FileCopyrightText: 2019 Olof Kindgren <olof@award-winning.me>
 * SPDX-License-Identifier: ISC
 * Modified 2026 by Daniel Kropf
 * Changes:
 * - renamed parameter to all caps
 */
module serv_rf_ram
  #(parameter WIDTH=0,
    parameter CSR_REGS=4,
    parameter DEPTH=32*(32+CSR_REGS)/WIDTH)
   (input wire i_clk,
    input wire [$clog2(DEPTH)-1:0] i_waddr,
    input wire [WIDTH-1:0] 	   i_wdata,
    input wire 			   i_wen,
    input wire [$clog2(DEPTH)-1:0] i_raddr,
    input wire			   i_ren,
    output wire [WIDTH-1:0] 	   o_rdata);

   reg [WIDTH-1:0] 		   memory [0:DEPTH-1];
   reg [WIDTH-1:0] 		   rdata ;

   always @(posedge i_clk) begin
      if (i_wen)
	memory[i_waddr] <= i_wdata;
      rdata <= i_ren ? memory[i_raddr] : {WIDTH{1'bx}};
   end

   /* Reads from reg x0 needs to return 0
    Check that the part of the read address corresponding to the register
    is zero and gate the output
    WIDTH LSB of reg index $clog2(WIDTH)
    2     4                1
    4     3                2
    8     2                3
    16    1                4
    32    0                5
    */
   reg regzero;

   always @(posedge i_clk)
     regzero <= !(|i_raddr[$clog2(DEPTH)-1:5-$clog2(WIDTH)]);

   assign o_rdata = rdata & ~{WIDTH{regzero}};

`ifdef SERV_CLEAR_RAM
   integer i;
   initial
     for (i=0;i<DEPTH;i=i+1)
       memory[i] = {WIDTH{1'd0}};
`endif
endmodule

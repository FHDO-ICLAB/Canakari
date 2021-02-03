////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : recarbitreg2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : receive arbitration register
// Commentary   :  
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 15.05.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module recarbitreg2 (
  input wire clk,
  input wire rst,
  input wire cpu,             // CPU wuenscht Zugriff
  input wire can,             // controller will zugreifen (im promiscous mode)
  input wire [15:0] reginp,
  input wire [15:0] recidin,
  output wire [15:0] regout
);

//tmrg default triplicate
//tmrg tmr_error false

reg [15:0] register_i;

//triplication signals
wire [15:0] register_iVoted = register_i;
assign regout = register_iVoted;


always @(posedge clk)
begin
  if (rst == 1'b0)        // synchroner reset (neg.)
    register_i <= 16'd0;
  else if (cpu == 1'b1)   // cpu zugriff (von write_demux)
    register_i <= reginp;
  else if (can == 1'b1)   // llc zugriff
    register_i <= recidin;
  else
    register_i <= register_iVoted;
end

endmodule

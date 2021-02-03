////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : recmescontrolreg2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : 
// Commentary   : output reg (VHDL) geander nach
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 15.05.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 15.05.2019 | outputname reg (VHDL) changed to regout 
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module recmescontrolreg2 (
  input wire clk,
  input wire rst,
  input wire cpu,           // CPU wuenscht Zugriff
  input wire can,           // controller wuenscht Zugriff
  input wire ofp,           // IOCPU,overflow indication processor
  input wire ofc,           // llc, overflow indication can
  input wire rip,           // IOCPU, receive indication processor
  input wire ric,           // llc, receive indication can
  input wire ien,           // interrupt enable (not used)
  input wire rtr,           // MAC, remote flag
  input wire ext,           // IOCPU,extended flag
  //input wire prom,        // Promiscous Mode (alle Daten werden empfangen)
  input wire [3:0]  dlc,    // data length code
  output wire [15:0] regout  // generalregister
);

//tmrg default triplicate
//tmrg tmr_error false

reg [15:0] register_i;

//triplication signals
wire [15:0] register_iVoted = register_i;
assign regout = register_iVoted;

always @(posedge clk)
begin
  if (rst == 1'b0) begin        // synchroner Reset
   register_i <= 16'd0;
  end
  else if (cpu == 1'b1) begin        // IOCPU, write_demux
    register_i[15]  <= ofp;
    register_i[14]  <= rip;
    //register_i[13] <= prom;
    register_i[8]   <= ien;
    register_i[4]   <= ext;
    end
  else if (can == 1'b1) begin   // llc, aktiv-signal
    register_i[15]  <= ofc;         // llc
    register_i[14]  <= ric;         // llc
    register_i[5]   <= rtr;         // mac
    register_i[3:0] <= dlc;         // dlc
    end
  else
    register_i <= register_iVoted;
end

endmodule

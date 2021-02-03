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
  output reg [15:0] regout  // generalregister
);

always @(posedge clk)
begin
  if (rst == 1'b0) begin        // synchroner Reset
   regout <= 16'd0;
  end
  else if (cpu == 1'b1) begin        // IOCPU, write_demux
    regout[15]  <= ofp;
    regout[14]  <= rip;
    //regout[13] <= prom;
    regout[8]   <= ien;
    regout[4]   <= ext;
    end
  else if (can == 1'b1) begin   // llc, aktiv-signal
    regout[15]  <= ofc;         // llc
    regout[14]  <= ric;         // llc
    regout[5]   <= rtr;         // mac
    regout[3:0] <= dlc;         // dlc
    end
end

endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : transmesconreg2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : transmit message control register
// Commentary   : Adresse: 0x1a 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 14.05.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module transmesconreg2 (
  input wire clk,
  input wire rst,
  input wire cpu,           // IOCPU, CPU wuenscht Zugriff
  input wire can,           // controller wuenscht Zugriff
  input wire tsucf,         // llc, successful transmission
  input wire [15:0] reginp, // Register Bus (daten)
  output reg [15:0] regout  // generalregister
);

always @(posedge clk)
begin
  if (rst == 1'b0) begin
    regout <= 16'd0;          // synchroner Reset
    end
  else if (cpu == 1'b1) begin      // cpu schreibt
    regout <= reginp;
    end
  else if (can == 1'b1) begin // can schreibt nur
    regout[15] <= 1'b0;       // treq auf 0
    regout[14] <= tsucf;      // transmit indication (llc)
    end
end
endmodule

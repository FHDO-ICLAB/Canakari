////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : transmitreg2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : ordinary transmit data register
// Commentary   : Adressen: 0x14, 0x12, 0x10, 0x0e (v.u.n.o) 
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

module transmitreg2 (
  input wire clk,
  input wire rst,
  input wire cpu,           // CPU wuenscht Zugriff
  input wire [15:0] reginp, // Registerbus
  output reg [15:0] regout  // Generalregister
);

always@(posedge clk)
begin
  if (rst == 1'b0) begin    // synchroner Reset
    regout <= 16'd0;    
  end
  else if (cpu == 1'b1) begin    // cpu schriebt zu sendende Daten
    regout <= reginp;
  end
end
endmodule

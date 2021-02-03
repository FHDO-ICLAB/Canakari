////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : recregister2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : 
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

module recregister2 (
  input wire clk,
  input wire rst,           // reset
  input wire can,           // CPU wuenscht Zugriff
  input wire [7:0]  regin1, // MAC, rshift
  input wire [7:0]  regin2, // MAC, rshift
  output reg [15:0] regout  // generalregister
);

always @(posedge clk)
begin
  if (rst == 1'b0) begin        // synchroner Reset
    regout <= 16'd0;
    end
  else if (can == 1'b1) begin   // wird nur von MAC beschrieben
    regout[15:8] <= regin1[7:0];
    regout[7:0]  <= regin2[7:0]; // kein CPU-Zugriff
    end
end

endmodule

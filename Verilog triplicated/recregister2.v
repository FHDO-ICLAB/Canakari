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
  else if (can == 1'b1) begin   // wird nur von MAC beschrieben
    register_i [15:8] <= regin1[7:0];
    register_i [7:0]  <= regin2[7:0]; // kein CPU-Zugriff
    end
  else
    register_i <= register_iVoted;
end

endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : accmaskreg2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Acceptance Mask Register
// Commentary   : Adressen: 10000 und 10001 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 22.05.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module accmaskreg2(
  input wire clk,
  input wire rst,
  input wire cpu,            // CPU wuenscht Zugriff
  input wire [15:0] reginp,  // Registerbus
  output reg [15:0] regout   // Acceptance Mask Register
);

always@(posedge clk)  // steigende Flanke        
begin
  if (rst == 1'b0) begin  // synchroner Reset
    regout <= 16'd0;
  end
  else if (cpu == 1'b1) begin  // cpu schreibt
    regout <= reginp;
  end
end

endmodule

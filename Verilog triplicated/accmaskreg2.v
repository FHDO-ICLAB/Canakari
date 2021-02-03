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
  output wire [15:0] regout   // Acceptance Mask Register
);

//tmrg default triplicate
//tmrg tmr_error false 

reg [15:0] reg_i;

//triplication signals
wire [15:0] reg_iVoted = reg_i;
assign regout = reg_iVoted;

always@(posedge clk)  // steigende Flanke        
begin
  if (rst == 1'b0) begin  // synchroner Reset
    reg_i <= 16'd0;
  end
  else
  begin
    reg_i <= reg_iVoted;
    if (cpu == 1'b1) begin  // cpu schreibt
      reg_i <= reginp;
    end
  end
end

endmodule

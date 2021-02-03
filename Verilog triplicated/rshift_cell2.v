////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : rshift_cell2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : RSHIFT_CELL
// Commentary   : F�r optimierte Synthese: Ein einfaches Register, synchroner
//                reset (act. low) und taktabh�ngigem input (pos. edge)
//                Changed portname input (VHDL) to Input (keyword). 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 08.07.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module rshift_cell2(
	  input  wire enable,
    input  wire clock,
    input  wire reset,
    input  wire Input,
    output wire q
);

//tmrg default triplicate
//tmrg tmr_error false

reg q_i;

//triplication signals
wire q_iVoted = q_i;
assign q = q_iVoted;

always@(posedge clock)    // rising clock edge
begin   
  if (reset == 1'b0)      // synchronous reset (active low)
        q_i <= 1'b0;
  else
	if (enable == 1'b1) 
	    begin
      q_i <= Input;
      end
      else
      q_i <= q_iVoted;
end

endmodule
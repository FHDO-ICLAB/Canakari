////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : rshift_cell2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : RSHIFT_CELL
// Commentary   : Für optimierte Synthese: Ein einfaches Register, synchroner
//                reset (act. low) und taktabhängigem input (pos. edge)
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
    output reg q
);

always@(posedge clock)    // rising clock edge
begin   
  if (reset == 1'b0)      // synchronous reset (active low)
        q <= 1'b0;
  else
	  if (enable == 1'b1) 
	    begin
      q <= Input;
      end
end

endmodule
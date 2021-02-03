////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : rcrc_cell2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : RCRC_CELL
//                Für optimierte Synthese: Ein einfaches Register, synchroner
//                reset (act. low) und taktabhängigem input (pos. edge)
// Commentary   : Changed portname input (VHDL) to Input. 
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

module rcrc_cell2(
    input  wire enable,
    input  wire clock,
    input  wire reset,
    input  wire Input,    
    output reg  q
    );

reg edge_var;

always@(posedge clock)
begin
  if (reset == 1'b0) begin    // synchronous reset (active low)
        q <= 1'b0;
        edge_var = 1'b0;
        end
  else
    if ((enable == 1'b1) && (edge_var == 1'b0)) begin
        q <= Input;
        edge_var = 1'b1;
        end
    else if ((enable == 1'b0) && (edge_var == 1'b1)) begin
        edge_var = 1'b0;
        end
end 
endmodule

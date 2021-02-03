////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : tshift_cell2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : TSHIFT_CELL
// Commentary   : Für optimierte Synthese: Ein einfaches Register, synchroner
//                reset (act. low) und taktabhängigem input (pos. edge), preload mit enable
//                Eingang load. 
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

module tshift_cell2(
    input  wire enable,
    input  wire preload,
    input  wire clock,
    input  wire reset,
    input  wire load,
    input  wire Input,
    output reg  q
    );

always@(posedge clock)    // rising clock edge
begin  
  if (reset == 1'b0)      // asynchronous reset (active low)
    q <= 1'b0;
  else
    if (enable == 1'b1) begin   // load ist enable, entwd. input oder preload
      q <= (preload & load) | (Input & (~load));
  //else
    end
end

endmodule
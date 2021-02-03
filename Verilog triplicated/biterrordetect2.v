////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : biterrordetect2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : biterror detection
// Commentary   : DW 2005_06_30 clock Flanke von negativ auf positiv geaendert. 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 01.07.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 01.07.2019 | Deleted variable edged (VHDL) during translation.
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module biterrordetect2 (
  input  wire clock,        
  input  wire bitin,      // vergleich 1
  input  wire bitout,     // vergleich 2
  input  wire activ,      // synchron neg. clock
  input  wire reset,      // synchron neg. clock
  output wire  biterror    // ergebnis
  );

//tmrg default triplicate
//tmrg tmr_error false 

reg error;

//triplication signals
wire [15:0] errorVoted = error;
assign biterror = errorVoted;


always@(posedge clock)    // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
begin
  if (reset ==1'b0)
    error <= 1'b0;
  else if (activ == 1'b1)
   begin
    if (bitin != bitout)
      error <= 1'b1;
    else
      error <= 1'b0;
   end
   else
    error <= errorVoted;
end

endmodule

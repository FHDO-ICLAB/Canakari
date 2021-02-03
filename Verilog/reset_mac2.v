////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : reset_mac2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Reset Generator für MAC. Für 3 langsame (prescaler) Taktflanken das
//                Resetsignal aktivieren, damit langsam getaktete, synchrone Register
//                zurückgesetzt werden.
// Commentary   : DW 2005_06_30 clock Flanke von negativ auf positiv geaendert. 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 08.07.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 21.10.2019 | changed prescaler / added main clock
// -------------------------------------------------------------------------------------------------
// 0.92    | Leduc              | 12.02.2020 | Added Changes done in Verilog Triplication Files
// -------------------------------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module reset_mac2(
    input  wire reset,          // resetgen
    input  wire clock,          // clock
    input  wire prescaler,      // prescaler
    output wire sync_reset     // MAC-Komponenten
);

reg [1:0] count;
reg       active;                // high, solange reset counter aktiv

assign sync_reset = reset & (~active);
  
  
always@(posedge clock, negedge reset)
begin
  if (reset == 1'b0) begin        // asynchroner Reset (low aktiv)
      active <= 1'b1;             // Aktivieren
      count  <= 2'd0;             // Zähler klarmachen
      end
  else begin
   if (prescaler == 1'b1)
     if (active == 1'b1)
       if (count == 2'd3)          // 0,1,2= drei Taktflanken
         active <= 1'b0;           // deaktivieren
       else
         count  <= count +2'd1;    // inkrementieren
  end
end

endmodule
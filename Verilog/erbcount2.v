////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : erbcount2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : E leven, R eceived, B its
//                count er: für BUSOFF Zustand, MACFSM sendet Signal, wenn 11 zusammenhängende
//                rezessive Bits gesamplet wurden. erb_eq128 sorgt für faultfsm
//                Zustandsübergang nach Erroractive
// Commentary   : DW 2005_06_30 clock Flanke von negativ auf positiv geaendert 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 17.04.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module erbcount2(
   input  wire clock,     
   input  wire reset,
   input  wire elevrecb,       // MACFSM
   output reg  erb_eq128       // faultfsm
  );

reg [7:0] counter;             // ein Register mehr= Merker für Überlauf
reg       edged;               // Flankenmerker, deglitch

always @(posedge clock)        // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
begin
  if (reset == 1'b0)           // synchronous reset (active low)  
    begin
     counter <= 8'd0;
     edged   <= 1'b0;
    end
  else if (elevrecb == 1'b1)
    begin
    if (edged == 1'b0)         // Flanke merken
      begin
       edged <= 1'b1;
       if (counter < 8'd128)
         counter <= counter+1; // inkrementieren, reset macht faultfsm
      end 
    end                     // edged
  else
    edged <= 1'b0;             // Flanke zurücksetzen
end                            // elevrecb


always @(counter)              // Auswertung, Ueberlauf stattgefunden?
begin
  if (counter == 8'd128)
    erb_eq128 = 1'b1;
  else
    erb_eq128 = 1'b0;
end
endmodule

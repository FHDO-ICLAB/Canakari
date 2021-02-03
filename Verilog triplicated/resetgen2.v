////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : resetgen2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Reset Generator f�r fuer 3 normale (clock_in) Taktflanken, um das
//                Resetsignal zu aktivieren, damit synchrone Register zurueckgesetzt werden.
// Commentary   :  
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 20.03.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module resetgen2 (
 input  wire clock,      // aussen
 input  wire reset,      // aussen
 output wire sync_reset  // Alle Komponenten, bis auf prescaler
 );
 
 //tmrg default triplicate
 //tmrg tmr_error false
 
 reg active;
 reg [1:0] count;

 wire activeVoted = active;
 wire [1:0] countVoted = count;
 
 always @(posedge clock, negedge reset)
 begin
  if (reset == 1'b0) 
    begin
     active <= 1'b1;
     count <= 2'b00;
    end
  else
    begin
    count <= countVoted;
    active <= activeVoted;
    if (activeVoted == 1'b1)
      if (countVoted == 2'b11)
        active <= 1'b0;
      else
        count <= countVoted+1;
    end
 end
  
 assign sync_reset = reset & ~activeVoted;

endmodule

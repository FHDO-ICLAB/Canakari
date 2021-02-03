////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : rec2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : R eceive E rror C ounter, 
//                z�hlt vom MAC gemeldete Fehler und gibt an den kritischen Punkten (96 und 128) 
//                Signale an faultfsm
// Commentary   : DW 2005_06_30 clock Flanke von negativ auf positiv geaendert 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 1.0     | Leduc              | 17.04.2019 | created
// -------------------------------------------------------------------------------------------------
// 1.1     | Leduc              | 18.04.2019 | assignment of reccount excludes MSB of counter [8:0]
// ------------------------------------------------------------------------------------------------- 
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module rec2 (
    input wire reset,          // resetgen, (OR) faultfsm
    input wire clock,
    input wire inconerec,      // MACFSM +1
    input wire incegtrec,      // MACFSM +8
    input wire decrec,         // MACFSM -1
    output reg rec_lt96,       // faultfsm, ok
    output reg rec_ge96,       // faultfsm, warning
    output reg rec_ge128,      // faultfsm, errorpassive
    output wire [7:0] reccount
);

//tmrg default triplicate
//tmrg tmr_error false

reg  [8:0] counter;    // ein Register mehr= Merker f�r �berlauf
reg        edged;      // Flankenmerker, deglitch
wire       action;

//triplication signal
wire [8:0] counterVoted = counter;
wire edgedVoted = edged;

assign action   = inconerec | incegtrec | decrec; // dann wird gearbeitet
assign reccount = counterVoted[7:0];

always @(posedge clock)   // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
begin
  if (reset == 1'b0)      // synchronous reset (active low)
    begin
    counter <= 9'd0;
    edged   <= 1'b0;
    end
  else
  begin
    counter <= counterVoted;
    edged <= edgedVoted;
    if (action == 1'b1)
      begin
      if (edgedVoted == 1'b0)    // Flankenmerker
        begin
        edged <= 1'b1;      // Flanke gemerkt
        if (counterVoted != 9'd0 && decrec == 1'b1)
          counter <= counterVoted-1;       // runterz�hlen nur wenn nicht 0 
        else if (counterVoted <= 255)
          begin
          if (inconerec == 1'b1)
            counter <= counterVoted+1;     // inkrementieren, reset von fsm    
          else if (incegtrec == 1'b1)
            counter <= counterVoted+8;     // oder um 8 inkrementieren
          end
        end    
      end
    else              // action='0'
      edged <= 1'b0;  // Flankenmerker resetten
  end
end

// Auswertung Z�hlerstand: 96 Warning, 128 Errorpassive
always @(counterVoted)
begin
  if (counterVoted > 9'd127)
    begin
    rec_lt96  <= 1'b0;
    rec_ge96  <= 1'b1;
    rec_ge128 <= 1'b1;
    end
  else if (counterVoted <= 9'd127 && counterVoted >= 9'd96) 
    begin
    rec_lt96  <= 1'b0;
    rec_ge96  <= 1'b1;
    rec_ge128 <= 1'b0;
    end
  else
    begin
    rec_lt96  <= 1'b1;
    rec_ge96  <= 1'b0;
    rec_ge128 <= 1'b0; 
    end
end
endmodule

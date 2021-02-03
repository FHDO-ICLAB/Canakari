////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : counter2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : received/sent bits counter 
// Commentary   : reset synchron, negative clock-Flanke
//                DW 2005.06.30 Prescale Enable eingefügt. 
//                DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 01.07.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 01.07.2019 | Tansl. Process FSM_events (VHDL) in two always blocks
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module counter2 (
  input  wire clock,
  input  wire Prescale_EN,
  input  wire inc,           // MACFSM, Zähler inkrementieren
  input  wire reset,
  output reg  lt3,           // MACFSM, lower, greater, equal 3
  output reg  gt3,
  output reg  eq3,
  output reg  lt11,          // MACFSM, lower, equal 11
  output reg  eq11,
  output wire [6:0]counto
);

reg       inc_rise_merker;  // de-glitchen
reg [6:0] count;

assign counto = count;      // Signal raus

always@(posedge clock)      // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
begin
  if (Prescale_EN == 1'b1)  // DW 2005.06.30 Prescale Enable eingefügt.
   begin
    if (reset == 1'b0)
      begin
       count           <= 7'd0;
       inc_rise_merker <= 1'b0;       
      end
    else if (inc == 1'b1)
      begin
       if (inc_rise_merker == 1'b0)   // flanke merken
        begin                         // flanke war schon
         inc_rise_merker <= 1'b1;
         if (count == 7'd127)         // Überlauf
           count <= 7'd0;
         else
           count <= count + 1;
        end
      end
    else
      inc_rise_merker <= 1'b0;        // flankenmerker für nächste flanke vorbereiten
   end 
end

////////////////////////////////////////////////////////////////////////////////
// purpose: für intermission werden hier signale für <,>,= 3 und 11 generiert,
// um MACFSM mit DC extrahierbar zu bekommen.
// type   : combinational
// inputs : count
// outputs: lt11, eq11, lt3, gt3, eq3

always@(count)
begin
  if (count < 3) 
    begin
     lt3 = 1'b1; 
     gt3 = 1'b0; 
     eq3 = 1'b0;
    end
  else if (count == 3) 
    begin
     lt3 = 1'b0; 
     gt3 = 1'b0; 
     eq3 = 1'b1;
    end
  else 
    begin
     lt3 = 1'b0; 
     gt3 = 1'b1; 
     eq3 = 1'b0;
    end
end    
    
always@(count)
begin
  if (count < 11) 
    begin
     lt11 = 1'b1; 
     eq11 = 1'b0;
    end
  else if (count == 11) 
    begin
     lt11 = 1'b0; 
     eq11 = 1'b1;
    end
  else 
    begin
     lt11 = 1'b0; 
     eq11 = 1'b0;
    end     
end

endmodule

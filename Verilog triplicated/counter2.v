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
//                DW 2005.06.30 Prescale Enable eingef�gt. 
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
  input  wire inc,           // MACFSM, Z�hler inkrementieren
  input  wire reset,
  output reg  lt3,           // MACFSM, lower, greater, equal 3
  output reg  gt3,
  output reg  eq3,
  output reg  lt11,          // MACFSM, lower, equal 11
  output reg  eq11,
  output wire [6:0]counto
);

//tmrg default triplicate
//tmrg tmr_error false

reg       inc_rise_merker;  // de-glitchen
reg [6:0] count;

//triplication signals
wire [6:0] countVoted = count;
wire inc_rise_merkerVoted = inc_rise_merker;

assign counto = countVoted;      // Signal raus

always@(posedge clock)      // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
begin
  count <= countVoted;
  inc_rise_merker <= inc_rise_merkerVoted;
  if (Prescale_EN == 1'b1)  // DW 2005.06.30 Prescale Enable eingef�gt.
   begin
    if (reset == 1'b0)
      begin
       count           <= 7'd0;
       inc_rise_merker <= 1'b0;       
      end
    else if (inc == 1'b1)
      begin
       if (inc_rise_merkerVoted == 1'b0)   // flanke merken
        begin                         // flanke war schon
         inc_rise_merker <= 1'b1;
         if (countVoted == 7'd127)         // �berlauf
           count <= 7'd0;
         else
           count <= countVoted + 1;
        end
      end
    else
      inc_rise_merker <= 1'b0;        // flankenmerker f�r n�chste flanke vorbereiten
   end 
end

////////////////////////////////////////////////////////////////////////////////
// purpose: f�r intermission werden hier signale f�r <,>,= 3 und 11 generiert,
// um MACFSM mit DC extrahierbar zu bekommen.
// type   : combinational
// inputs : count
// outputs: lt11, eq11, lt3, gt3, eq3

always@(countVoted)
begin
  if (countVoted < 3) 
    begin
     lt3 = 1'b1; 
     gt3 = 1'b0; 
     eq3 = 1'b0;
    end
  else if (countVoted == 3) 
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
    
always@(countVoted)
begin
  if (countVoted < 11) 
    begin
     lt11 = 1'b1; 
     eq11 = 1'b0;
    end
  else if (countVoted == 11) 
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

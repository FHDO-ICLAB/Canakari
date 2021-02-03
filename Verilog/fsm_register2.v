////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : fsm_register2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : fsm_register/ Auslagerung der MACFSM Latches
// Commentary   : Diese Signale waren intern. Jetzt werden sie aus der macfsm so gesteuert:
//                signalxx_set="11"; // auf 1 setzen
//                signalxx_set="10"; // auf 0 setzen
//                signalxx_set="00"; // Unverändert lassen;
//                signalxx_set="01"; //  
//                signalxx steht für:
//                ackerror 
//                onarbit     
//                transmitter 
//                receiver    
//                error       
//                first       
//                puffer
//                rext
//                rrtr
//                reset synchron, neg. FLanke
//                DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 12.07.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module fsm_register2(
    input  wire       clock,
    input  wire       reset,
    input  wire [1:0] ackerror_set,     // Steuereingang
    input  wire [1:0] onarbit_set,
    input  wire [1:0] transmitter_set,
    input  wire [1:0] receiver_set,
    input  wire [1:0] error_set,
    input  wire [1:0] first_set,
    input  wire [1:0] puffer_set,
    input  wire [1:0] rext_set,
    input  wire [1:0] rrtr_set,
    output reg        ackerror,         // Register Ausgang
    output reg        onarbit,
    output reg        transmitter,
    output reg        receiver,
    output reg        error,
    output reg        first,
    output reg        puffer,
    output reg        rext,
    output reg        rrtr
  );


always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS ackerror
      if (reset == 1'b0)                 // synchroner Reset
        ackerror <= 1'b0;
      else
        case (ackerror_set)
          2'b11   : ackerror <= 1'b1;    // Setzen
          2'b10   : ackerror <= 1'b0;    // Zurücksetzen
          default : ackerror <= ackerror;  //NULL;          // Halten (00 und 01)
        endcase

end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS onarbit
      if (reset == 1'b0) 
        case (onarbit_set) 
          2'b11   : onarbit <= 1'b1;
          2'b10   : onarbit <= 1'b0;
          default : onarbit <= 1'b0;  //NULL;
        endcase
end 

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS transmitter
      if (reset == 1'b0) 
        transmitter <= 1'b0;
      else
        case (transmitter_set) 
          2'b11   : transmitter <= 1'b1;
          2'b10   : transmitter <= 1'b0;
          default : transmitter <= transmitter;  //NULL;
        endcase

end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS receiver
      if (reset == 1'b0) 
        receiver <= 1'b0;
      else
        case (receiver_set) 
          2'b11   : receiver <= 1'b1;
          2'b10   : receiver <= 1'b0;
          default : receiver <= receiver;  //NULL;
        endcase

end
 
always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS error
      if (reset == 1'b0) 
        error <= 1'b0;
      else
        case (error_set) 
          2'b11   : error <= 1'b1;
          2'b10   : error <= 1'b0;
          default : error <= error;  //NULL;
        endcase
end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS first
      if (reset == 1'b0) 
        first <= 1'b0;
      else
        case (first_set) 
          2'b11   : first <= 1'b1;
          2'b10   : first <= 1'b0;
          default : first <= first;  //NULL;
        endcase
end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS puffer
      if (reset == 1'b0) 
        puffer <= 1'b0;
      else
        case (puffer_set) 
          2'b11   : puffer <= 1'b1;
          2'b10   : puffer <= 1'b0;
         default  : puffer <= puffer;  //NULL;
        endcase
end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS rext
      if (reset == 1'b0) 
        rext <= 1'b0;
      else
        case (rext_set) 
          2'b11   : rext <= 1'b1;
          2'b10   : rext <= 1'b0;
          default : rext <= rext;  //NULL;
        endcase
end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS rrtr
      if (reset == 1'b0) 
        rrtr <= 1'b0;
      else
        case (rrtr_set) 
          2'b11   : rrtr <= 1'b1;
          2'b10   : rrtr <= 1'b0;
          default : rrtr <= rrtr;  //NULL;
        endcase
end

endmodule

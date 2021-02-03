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
//                signalxx_set="00"; // Unver�ndert lassen;
//                signalxx_set="01"; //  
//                signalxx steht f�r:
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
    output wire        ackerror,         // Register Ausgang
    output wire        onarbit,
    output wire        transmitter,
    output wire        receiver,
    output wire        error,
    output wire        first,
    output wire        puffer,
    output wire        rext,
    output wire        rrtr
  );

//tmrg default triplicate
//tmrg tmr_error false

reg   ackerror_i;
reg   onarbit_i;
reg   transmitter_i;
reg   receiver_i;
reg   error_i;
reg   first_i;
reg   puffer_i;
reg   rext_i;
reg   rrtr_i;


//triplication signals

wire ackerror_iVoted = ackerror_i;
wire onarbit_iVoted = onarbit_i;
wire transmitter_iVoted = transmitter_i;
wire receiver_iVoted = receiver_i;
wire error_iVoted = error_i;
wire first_iVoted = first_i;
wire puffer_iVoted = puffer_i;
wire rext_iVoted = rext_i;
wire rrtr_iVoted = rrtr_i;
assign ackerror = ackerror_iVoted;
assign onarbit = onarbit_iVoted;
assign transmitter = transmitter_iVoted;
assign receiver = receiver_iVoted;
assign error = error_iVoted;
assign first = first_iVoted;
assign puffer = puffer_iVoted;
assign rext = rext_iVoted;
assign rrtr = rrtr_iVoted;


always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS ackerror
      if (reset == 1'b0)                 // synchroner Reset
        ackerror_i <= 1'b0;
      else
        case (ackerror_set)
          2'b11   : ackerror_i <= 1'b1;    // Setzen
          2'b10   : ackerror_i <= 1'b0;    // Zur�cksetzen
          default : ackerror_i <= ackerror_iVoted;  //NULL;          // Halten (00 und 01)
        endcase

end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS onarbit
      if (reset == 1'b0) 
        case (onarbit_set) 
          2'b11   : onarbit_i <= 1'b1;
          2'b10   : onarbit_i <= 1'b0;
          default : onarbit_i <= 1'b0;  //NULL;
        endcase
end 

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS transmitter
      if (reset == 1'b0) 
        transmitter_i <= 1'b0;
      else
        case (transmitter_set) 
          2'b11   : transmitter_i <= 1'b1;
          2'b10   : transmitter_i <= 1'b0;
          default : transmitter_i <= transmitter_iVoted;  //NULL;
        endcase

end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS receiver
      if (reset == 1'b0) 
        receiver_i <= 1'b0;
      else
        case (receiver_set) 
          2'b11   : receiver_i <= 1'b1;
          2'b10   : receiver_i <= 1'b0;
          default : receiver_i <= receiver_iVoted;  //NULL;
        endcase

end
 
always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS error
      if (reset == 1'b0) 
        error_i <= 1'b0;
      else
        case (error_set) 
          2'b11   : error_i <= 1'b1;
          2'b10   : error_i <= 1'b0;
          default : error_i <= error_iVoted;  //NULL;
        endcase
end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS first
      if (reset == 1'b0) 
        first_i <= 1'b0;
      else
        case (first_set) 
          2'b11   : first_i <= 1'b1;
          2'b10   : first_i <= 1'b0;
          default : first_i <= first_iVoted;  //NULL;
        endcase
end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS puffer
      if (reset == 1'b0) 
        puffer_i <= 1'b0;
      else
        case (puffer_set) 
          2'b11   : puffer_i <= 1'b1;
          2'b10   : puffer_i <= 1'b0;
         default  : puffer_i <= puffer_iVoted;  //NULL;
        endcase
end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS rext
      if (reset == 1'b0) 
        rext_i <= 1'b0;
      else
        case (rext_set) 
          2'b11   : rext_i <= 1'b1;
          2'b10   : rext_i <= 1'b0;
          default : rext_i <= rext_iVoted;  //NULL;
        endcase
end

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  begin  // PROCESS rrtr
      if (reset == 1'b0) 
        rrtr_i <= 1'b0;
      else
        case (rrtr_set) 
          2'b11   : rrtr_i <= 1'b1;
          2'b10   : rrtr_i <= 1'b0;
          default : rrtr_i <= rrtr_iVoted;  //NULL;
        endcase
end

endmodule

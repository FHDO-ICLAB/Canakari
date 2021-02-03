////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : encapsulation2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : encapsulation unit
// Commentary   : reset synchron, neg. flanke
//                Data nun direkt aus Registern IOCPU in tshift
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 01.07.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module encapsulation2 (
  input  wire        clock,         // main clock
  input  wire [28:0] identifier,    // IOCPU, tarbit
  input  wire        extended,      // IOCPU, transmesconreg
  input  wire        remote,        // IOCPU, transmesconreg
  input  wire        activ,         // LLC: actvtcap
  input  wire        reset,
  input  wire [ 3:0] datalen,       // IOCPU, transmesconreg
  output wire [ 3:0] tmlen,         // reale Datal�nge (0 bei RTR)
  output reg  [38:0] message        // tshift, tcrc, Id-Feld
  );

//tmrg default triplicate
//tmrg tmr_error false 

reg [3:0] datalen_buf;
reg rem;

//triplication signals
wire [3:0] datalen_bufVoted = datalen_buf;
wire remVoted = rem;
assign tmlen = datalen_bufVoted;

always@(posedge clock)            // PROCESS datalenbuf
begin                             // rising active edge
  if(reset == 1'b0) begin         // synchronous reset (active low)
    datalen_buf <= 4'b0000;
    rem <= 0;
  end  
  else begin
    rem <= remVoted;
    datalen_buf <= datalen_bufVoted;           
    if(activ == 1'b1 ) begin
      if(remVoted == 1'b0) begin
        rem <= 1'b1;
        if (remote == 1'b1)
          datalen_buf <= 4'b0000;     // RTR haben realen DLC=0
        else
          datalen_buf <= datalen;     // alle anderen: realer DLC=DLC
      end
    end
    else 
      rem <= 1'b0;
  end
end


always@(identifier, datalen, remote, extended)
begin
  message[38]  = 1'b0;                    // start of frame    outbit: 102
  message[6]   = remote;                  // RTR-Feld
  message[5:4] = 2'b00;                   // Basic: IDE,r0; Extended r0,r1
  message[3:0] = datalen;                 // DLC Feld
  if (extended == 1'b1)                    // extended Datenrahmen
   begin
    message[37:27] = identifier [28:18];  // Basic id
    message[26:25] = 2'b11;               // SRR und IDE
    message[24:7]  = identifier[17:0];    // Extended id    
   end
  else
   begin
    message[37:18] = 20'd0;               // leer
    message[17:7]  = identifier[28:18];   // Basic id nach unten 
 end
end

endmodule

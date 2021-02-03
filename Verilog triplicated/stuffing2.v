////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : stuffing2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Stuffing Unit
// Commentary   : Sendestuffing
//                reset: 
//                mac.vhdl: resetstfsig <= reset(extern) or resettra (llc) or resetstf;
//                (MACFSM)--> auf neg. clock flanke
//                direct: Stuffing abschalten (Error Flag etc.)
//                setdom, setrec: dominantes, rezessives Bit unabh�ngig von bitin 
//                *bitin: mal aus tshift (wenn crc_shft_out(MACFSM)0), oder aus rcrc-register
//                (wenn crc_shft_out 1), neu: tcrc wird sendeschieberegister.
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 08.07.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module stuffing2(
  input  wire clock,
  input  wire bitin,         // Commentary(*)
  input  wire activ,         // MACFSM: actvtstf
  input  wire reset,         // resetstfsig, s.o
  input  wire direct,        // MACFSM: actvtdct
  input  wire setdom,        // MACFSM: setbdom
  input  wire setrec,        // MACFSM: setbrec
  output wire  bitout,        // bitout, aussen
  output wire  stuff          // MACFSM, stufft
);

//tmrg default triplicate
//tmrg tmr_error false

reg [2:0] count;  // Z�hler
reg       Buf;    // aktuelles Bit
reg       edged;  // Flankenmerker
reg       bitout_i;
reg       stuff_i;
//triplication signals
wire edgedVoted = edged;
wire bitout_iVoted = bitout_i;
wire stuff_iVoted = stuff_i;
assign bitout = bitout_iVoted;
assign stuff = stuff_iVoted;

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
begin
  if (reset == 1'b0) begin               
    count   = 3'd0;
    Buf     = 1'b0;
    bitout_i <= 1'b1;
    stuff_i  <= 1'b0;
    edged   = 1'b0;
    end
  else begin
    edged = edgedVoted;
    stuff_i <= stuff_iVoted;
    bitout_i <= bitout_iVoted;
    if (activ == 1'b1) begin
      if (edgedVoted == 1'b0) begin                  // war schon ?
        edged = 1'b1;                            // es war eine pos. active flanke
        if (direct == 1'b1) begin               // nicht z�hlen
          bitout_i <= bitin;
          stuff_i  <= 1'b0;                       // kein stuffing
          end              
        else if (setdom == 1'b1) begin          // Dominantes Bit senden
            bitout_i <= 1'b0;
            stuff_i  <= 1'b0;                     // kein error
            end          
        else if (setrec == 1'b1) begin          // rezessives Bit senden
            bitout_i <= 1'b1;
            stuff_i  <= 1'b0;                     // kein stuffing
            end
        else if ((count == 3'd0) || ((bitin != Buf) && (count != 5))) begin
          Buf     = bitin;                      // erstes Bit merken, count=0
          count   = 3'd1;                       // erstes Bit, deshalb 1
          bitout_i <= bitin;                      // durchschalten
          stuff_i  <= 1'b0;                       // kein stuffing
          end
        else if (bitin == Buf && count != 5) begin
          count  = count +3'd1;                 // gleiches Bit, count hoch
          bitout_i <= bitin;                      // durchschalten
          stuff_i  <= 1'b0;                       // kein stuffing
          end
        else if (count == 3'd5) begin           // stufffall
          count  = 3'd1;                        // z�hler auf 1, stuffbit ist 1.
          Buf    = ~Buf;                        // jetzt umgekehrte z�hlen
          bitout_i <= Buf;                        // stuffbit senden
          stuff_i  <= 1'b1;                       // Stufffall anzeigen
          end
        end      
      else
        edged = 1'b1;                           // noch keine neg. flanke gewesen
      end
     else
       edged = 1'b0;                            // das war die neg. flanke
    end 
end 

endmodule

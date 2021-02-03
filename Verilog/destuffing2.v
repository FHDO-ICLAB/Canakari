////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : destuffing2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : destuffing unit
// Commentary   : activ zählt, direct überbrückt (bei Errorflags etc.)
//                reset synchron mit neg. clock Flanke, da von MACFSM ausgelöst (auch)
//                DW 2005_06_30 clock Flanke von negativ auf positiv geaendert. 
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

module destuffing2(
  input  wire clock,
  input  wire bitin,    // bittiming: sampledbit
  input  wire activ,    // MACFSM: actvrstf
  input  wire reset,    // MACFSM: resetdst or reset
  input  wire direct,   // MACFSM: actvrdct
  output reg  stfer,    // MACFSM: stferror
  output reg  stuff,    // MACFSM: stuffr
  output reg  bitout    // MACFSM: inbit; rcrc,rshift:bitin
  );

reg [2:0] count;
reg [3:0] state;
reg buff;         // name was changed from buf to buff
reg edged;        // Flankenmerker, deglitch

always@(posedge clock)    // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.  
begin
 if (reset == 1'b0)
  begin
    count = 3'b0;
    state = 4'b0000;
    stuff <= 1'b0;
    stfer <= 1'b0;
    edged = 1'b0;
  end  
 else
  begin
    if (activ == 1'b1)
      if (edged == 1'b0)
       begin
        edged <= 1'b1;
        bitout <= bitin;       // Bit weitergeben
        
        if (bitin == buff)     // gleiches Bit
          state[3] = 1'b1; 
        else
          state[3] = 1'b0;
          
        if (count == 3'd0)     // Anfang
          state[2] = 1'b1;
        else
          state[2] = 1'b0;
          
        if (count == 3'd5)     // Stufffall
          state[1] = 1'b1;
        else
          state[1] = 1'b0;
          
        if (direct == 1'b1)    // uebergehen
          state[0] = 1'b1;
        else
          state[0] = 1'b0;
      // end
       
        case (state)
         4'b0100, 4'b1100, 4'b0000  : begin
                                      buff  = bitin;    // erstes Bit, da count=0
                                      count = 3'b1;     // oder Buf/=Bit, dann
                                      stuff <= 1'b0;     // count 'resetten'
                                      stfer <= 1'b0;
                                      end
         4'b0010                    : begin
                                      count = 3'b1;     // Stuffbit entfernen, da count=5
                                      stuff <= 1'b1;
                                      buff  = bitin;
                                      end
         4'b1010                    : begin
                                      stfer <= 1'b1;     // stuff error, buf=bitin und count=5
                                      stuff <= 1'b0;
                                      count = 3'd0;
                                      end
         4'b1000                    : begin 
                                      count = count +4'd1; // gleiches Bit aber keine Regelverletzung
                                      stuff <= 1'b0;        // buf=bitin, count <6
                                      end
         default                    : begin               // NULL in VHDL
                                      buff   = buff;
                                      count  = count;
                                      stuff <= stuff;
                                      stfer <= stfer;
                                      end                  
        endcase
        
       end
      else
        edged <= 1'b1;
    else
      edged <= 1'b0;
  end
end

endmodule

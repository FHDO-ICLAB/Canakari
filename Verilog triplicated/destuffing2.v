////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : destuffing2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : destuffing unit
// Commentary   : activ z�hlt, direct �berbr�ckt (bei Errorflags etc.)
//                reset synchron mit neg. clock Flanke, da von MACFSM ausgel�st (auch)
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
  output wire  stfer,    // MACFSM: stferror
  output wire  stuff,    // MACFSM: stuffr
  output wire  bitout    // MACFSM: inbit; rcrc,rshift:bitin
  );

//tmrg default triplicate
//tmrg tmr_error false

reg [2:0] count;
reg [3:0] state;
reg buff;         // name was changed from buf to buff
reg edged;        // Flankenmerker, deglitch
reg stfer_i;
reg stuff_i;
reg bitout_i;

//triplication signals
wire edgedVoted = edged;
wire stfer_iVoted = stfer_i;
wire stuff_iVoted = stuff_i;
wire bitout_iVoted = bitout_i;

assign stfer = stfer_iVoted;
assign stuff = stuff_iVoted;
assign bitout = bitout_iVoted;

always@(posedge clock)    // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.  
begin
 if (reset == 1'b0)
  begin
    count = 3'b0;
    state = 4'b0000;
    stuff_i <= 1'b0;
    stfer_i <= 1'b0;
    edged = 1'b0;
  end  
 else
  begin
    edged = edgedVoted;
    stfer_i <= stfer_iVoted;
    stuff_i <= stuff_iVoted;
    bitout_i <= bitout_iVoted;
    if (activ == 1'b1)
      if (edgedVoted == 1'b0)
       begin
        edged = 1'b1;
        bitout_i <= bitin;       // Bit weitergeben
        
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
                                      stuff_i <= 1'b0;     // count 'resetten'
                                      stfer_i <= 1'b0;
                                      end
         4'b0010                    : begin
                                      count = 3'b1;     // Stuffbit entfernen, da count=5
                                      stuff_i <= 1'b1;
                                      buff  = bitin;
                                      end
         4'b1010                    : begin
                                      stfer_i <= 1'b1;     // stuff error, buf=bitin und count=5
                                      stuff_i <= 1'b0;
                                      count = 3'd0;
                                      end
         4'b1000                    : begin 
                                      count = count +4'd1; // gleiches Bit aber keine Regelverletzung
                                      stuff_i <= 1'b0;        // buf=bitin, count <6
                                      end
         default                    : begin               // NULL in VHDL
                                      buff   = buff;
                                      count  = count;
                                      stuff_i <= stuff_iVoted;
                                      stfer_i <= stfer_iVoted;
                                      end                  
        endcase
        
       end
      else
        edged = 1'b1;
    else
      edged = 1'b0;
  end
end

endmodule

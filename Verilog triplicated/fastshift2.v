////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : fastshift2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : schnelles Schieben (ungeteilter Takt) des receive shift register
//                um Daten immer an selbe Position zu schieben. wenn DLC=8Byte 0 mal schieben,
//                wenn DLC=1Byte 56 mal schieben. Einsparung Multiplexer in decapuslation. Ein
//                Z�hler wird von 128 heruntergez�hlt, bis die oberen 4 Bit gleich DLC sind
//                und die unteren Null (Multiplikation 16). Es sind dann doppelt soviele 
//                Z�hltakte wie Schiebetakte, pro Z�hltakt wird Schiebesignal invertiert.
//                = Division /2. 8Bit=1Byte , 16/2=8
// Commentary   : DW 2005_06_30 clock Flanke von negativ auf positiv geaendert. 
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

module fastshift2 (
  input  wire       reset,
  input  wire       clock,      // aussen
  input  wire       activate,   // MACFSM, activatefast
  input  wire [3:0] rmlb,       // recmeslen, Real Message Length Byte
  output wire       setzero,    // rshiftreg, Nullen nachschieben
  output wire       directshift // rshiftreg, Schiebetakt
  );

//tmrg default triplicate
//tmrg tmr_error false   

wire      reset_i;
assign    reset_i = reset;
reg       directshift_i;
reg       working;
reg [7:0] count;                    // Z�hler Schiebetakte (l�uft abw�rts)
reg [3:0] upper4count, lower4count; // unsigned
reg [3:0] rmlb_us;                  // unsigned
reg [7:0] count_us;                 // unsigned

//triplication signals
wire directshift_iVoted = directshift_i;
wire workingVoted = working;
wire [7:0] countVoted = count;
assign directshift = directshift_iVoted;
assign setzero     = ~workingVoted;       // wenn aktiv, eingang rshift auf 0


always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
begin
  directshift_i <= directshift_iVoted;
  working <= workingVoted;
  count <= countVoted;
  if (reset_i == 1'b0)  // synchronous Reset, neg. clock edge
    begin
      working <= 1'b0;
      count <= 8'd128;          // Z�hler z�hlt runter! Reset=alles 1
      directshift_i <= 1'b0;
    end
  else if (activate == 1'b1)  // kurzes Signal startet!
    begin
      working <= 1'b1;
    end
  else if (workingVoted == 1'b1)   // runterz�hlen bis obere 4 Bit=DLC und untere 4 Bit 0 
    begin                     // (da DLC in Byte *8 und *2 wg. Taktflanke directshift)
      if (!((rmlb_us == upper4count) && (lower4count == 4'd0))) // Abbruchbedingung
        begin
          directshift_i <= ~directshift_iVoted;  // taktsignal zum Schieben
          count         <= countVoted - 1;        // Z�hler dekrementieren
        end
      else
        working <= 1'b0;  // Abbruchbedingung erreicht, abschalten
    end
end

always@(countVoted, rmlb) // Beer, 2018_06_22
begin
  count_us    = countVoted;
  upper4count = count_us[7:4];
  lower4count = count_us[3:0];
  rmlb_us     = rmlb;
end

endmodule

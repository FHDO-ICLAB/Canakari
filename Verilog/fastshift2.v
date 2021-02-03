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
//                Zähler wird von 128 heruntergezählt, bis die oberen 4 Bit gleich DLC sind
//                und die unteren Null (Multiplikation 16). Es sind dann doppelt soviele 
//                Zähltakte wie Schiebetakte, pro Zähltakt wird Schiebesignal invertiert.
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

wire      reset_i;
reg       directshift_i;
reg       working;
reg [7:0] count;                    // Zähler Schiebetakte (läuft abwärts)
reg [3:0] upper4count, lower4count; // unsigned
reg [3:0] rmlb_us;                  // unsigned
reg [7:0] count_us;                 // unsigned

assign reset_i     = reset;
assign setzero     = ~working;       // wenn aktiv, eingang rshift auf 0
assign directshift = directshift_i;

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
begin
  if (reset_i == 1'b0)  // synchronous Reset, neg. clock edge
    begin
      working <= 1'b0;
      count <= 8'd128;          // Zähler zählt runter! Reset=alles 1
      directshift_i <= 1'b0;
    end
  else if (activate == 1'b1)  // kurzes Signal startet!
    begin
      working <= 1'b1;
    end
  else if (working == 1'b1)   // runterzählen bis obere 4 Bit=DLC und untere 4 Bit 0 
    begin                     // (da DLC in Byte *8 und *2 wg. Taktflanke directshift)
      if (!((rmlb_us == upper4count) && (lower4count == 4'd0))) // Abbruchbedingung
        begin
          directshift_i <= ~directshift_i;  // taktsignal zum Schieben
          count         <= count - 1;        // Zähler dekrementieren
        end
      else
        working <= 1'b0;  // Abbruchbedingung erreicht, abschalten
    end
end

always@(count, rmlb) // Beer, 2018_06_22
begin
  count_us    = count;
  upper4count = count_us[7:4];
  lower4count = count_us[3:0];
  rmlb_us     = rmlb;
end

endmodule

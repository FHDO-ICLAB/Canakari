////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : tec2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : R eceive E rror C ounter, zählt vom MAC gemeldete Fehler und gibt an den 
//                kritischen Punkten (96,128,256) Signale an faultfsm 
// Commentary   : DW 2005_06_30 clock Flanke von negativ auf positiv geaendert. 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 1.0     | Leduc              | 18.04.2019 | created
// -------------------------------------------------------------------------------------------------
// 1.1     | Leduc              | 18.04.2019 | assignment of teccount excludes MSB of counter [8:0]
// -------------------------------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module tec2 (
  input wire  reset,           // resetgen
  input wire  clock,     
  input wire  incegttra,       // MACFSM +8
  input wire  dectra,          // MACFSM -1
  output reg  tec_lt96,        // faultfsm, ok
  output reg  tec_ge96,        // faultfsm, warning
  output reg  tec_ge128,       // faultfsm, errorpassive
  output reg  tec_ge256,       // faultfsm, busoff
  output wire [7:0] teccount
);

reg [8:0] counter;
reg       edged;
wire      action; 

assign action   = incegttra | dectra;   // dann wird gearbeitet
assign teccount = counter [7:0];

always @(posedge clock)
begin
  if (reset == 1'b0)
    begin
    counter <= 9'd0;
    edged   <= 1'b0;
    end
  else if (action == 1'b1)
    begin
    if (edged == 1'b0)
      begin
      edged <= 1'b1;
      if (counter <= 9'd255 && incegttra == 1'b1)
        counter <= counter+8;
      else if (counter != 9'd0 && dectra == 1'b1)
        counter <= counter-1;
      end
    end
  else
    edged <= 1'b0;
end

// Auswertung
always @(counter)
  begin  // PROCESS evaluate
    if (counter >= 9'd256)         // busoff
      begin
      tec_lt96    <= 1'b0;               
      tec_ge96    <= 1'b1;       // >=96
      tec_ge128   <= 1'b1;       // >=128
      tec_ge256   <= 1'b1;       // >=256
      end
    else if (counter >= 9'd128 && counter < 9'd256)  // errorpassive
      begin
      tec_lt96    <= 1'b0;
      tec_ge96    <= 1'b1;       // >=96
      tec_ge128   <= 1'b1;       // >=128
      tec_ge256   <= 1'b0;
      end
    else if (counter <= 9'd127 && counter >= 9'd96)  // warning
      begin
      tec_lt96    <= 1'b0;
      tec_ge96    <= 1'b1;       // >=96
      tec_ge128   <= 1'b0;
      tec_ge256   <= 1'b0;
      end
    else                        // erroractive
      begin
      tec_lt96    <= 1'b1;       // <96
      tec_ge96    <= 1'b0;
      tec_ge128   <= 1'b0;
      tec_ge256   <= 1'b0;
      end
  end

endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : prescale2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Der Prescaler teilt den 10 MHz Eingangstakt herunter
// Commentary   : DW 2005.06.21 Prescale Enable eingefügt 
//                DW 2005.06.26 Prescale Enable korrigiert
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 20.03.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 12.02.2020 | Added Changes done in Verilog Triplication Files
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module prescale2 ( 
 input  wire       clock,
 input  wire       reset,
 input  wire [3:0] high,        // IOCPU, prescaleregister
 input  wire [3:0] low,         // IOCPU, prescaleregister
 output reg        Prescale_EN // DW 2005.06.21 Prescale Enable 
 );
 
 reg [3:0] lo_count;
 reg [3:0] hi_count;
 reg       hilo;
 // int_high, int_low entfallen, conversion entfaellt
 

 
 always @(posedge clock, negedge reset)
 begin
   if (reset == 1'b0)
    begin
      lo_count    <= 4'b0000;
      hi_count    <= 4'b0000;
      hilo        <= 1'b1;
      Prescale_EN <= 1'b0;
    end
   else
    begin
      if (hilo == 1'b1)
        begin
          Prescale_EN <= 1'b0;
          if (hi_count == high)
            begin
              hi_count <= 4'b0000;
              hilo     <= 1'b0; 
            end
          else
            hi_count <= hi_count + 1;   
          //  hilo     <= 1'b1;
        end
      else
        begin
          if (lo_count == low)
            begin
              Prescale_EN <= 1'b1;
              lo_count    <= 4'b0000;
              hilo        <= 1'b1;
            end
          else
            begin
              Prescale_EN <= 1'b0;
              lo_count    <= lo_count + 1;
//              hilo        <= 1'b0;
            end
          end
        end
    end
endmodule

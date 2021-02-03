////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : edgepuffer2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Flip Flop
// Commentary   : Änderung: buf neu, um tatsächlich eine ganze Bitzeit und nicht nur eine 
//                Taktflanke zu verzögern.- Ist vor Einbau des Prescalers nicht aufgefallen
//                synchroner Reset
//                DW 2005.06.21 Prescale Enable eingefügt
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 15.01.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 12.02.2020 | Added Changes done in Verilog Triplication Files
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module edgepuffer2 (
 input  wire  clock, 			
 input  wire  Prescale_EN, 	 // DW 2005.06.21 Prescale Enable	
 input  wire  reset,     
 input  wire  rx,            // aussen
 output wire  puffer	        // smpldbit_reg
 );	
 
 reg buff;	// buf in buff geaendert (reserved word)
 
 assign puffer = buff;
 
 always @(posedge clock, negedge reset)
 begin
 if (reset == 1'b0)
  begin
	  buff   <= 1'b0;
	end
 else
	 if (Prescale_EN == 1'b1)   // DW 2005.06.21 Prescale Enable eingefügt
	  begin                
	   buff   <= rx;            // speichern für nächstes
	  end
 end
endmodule

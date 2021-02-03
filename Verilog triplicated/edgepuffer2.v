////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : edgepuffer2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Flip Flop
// Commentary   : �nderung: buf neu, um tats�chlich eine ganze Bitzeit und nicht nur eine 
//                Taktflanke zu verz�gern.- Ist vor Einbau des Prescalers nicht aufgefallen
//                synchroner Reset
//                DW 2005.06.21 Prescale Enable eingef�gt
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 15.01.2019 | created
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

//tmrg default triplicate
//tmrg tmr_error false 

 reg buff;	// buf in buff geaendert (reserved word)

 //triplication signals
 wire buffVoted = buff;
 assign puffer = buffVoted;

 always @(posedge clock, negedge reset)
 begin
 if (reset == 1'b0)
  begin
	  buff   <= 1'b0;
	end
 else begin
	 buff <= buffVoted;
	 if (Prescale_EN == 1'b1)   // DW 2005.06.21 Prescale Enable eingef�gt
	  begin                
	   buff   <= rx;            // speichern f�r n�chstes
	  end
	end
 end
endmodule

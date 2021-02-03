////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : timecount2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Grundzeiteinheitenz�hler
// Commentary   : DW 2005.06.21 Prescale Enable eingef�gt
//
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

module timecount2 (
 input  wire  clock, 			    // prescaler
 input  wire  Prescale_EN, 	// DW 2005.06.21 Prescale Enable
 input  wire  reset,        // resetgen
 input  wire  increment,    // fsm
 input  wire  setctzero,    // fsm
 input  wire  setctotwo,    // fsm
 output wire [3:0] counto 	  // sum (arithmetik) 
 );	

//tmrg default triplicate
//tmrg tmr_error false 

reg [3:0] counto_i; 	  // sum (arithmetik) 

//triplication signals
wire [3:0] counto_iVoted = counto_i;
assign counto = counto_iVoted;

 always @(posedge clock, negedge reset) // pos. flanke (clock), asynchroner reset
 begin
  if (reset == 1'b0) 
   counto_i <= 4'b0000;
  else
	 if (Prescale_EN == 1'b1)          // DW 2005.06.21 Prescale Enable
	  begin 
    if (setctzero == 1'b1)	          // null setzen 
	    counto_i <= 4'b0000;        
    else if (increment == 1'b1)      // erhoehen
	    counto_i <= counto_iVoted+1;
	  else if (setctotwo == 1'b1)      // auf 2 setzen
	    counto_i <= 4'd2;
	  else 
	    counto_i <= counto_iVoted;        // halten  
    end
 end 
endmodule

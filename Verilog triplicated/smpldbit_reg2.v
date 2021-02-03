////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : smpldbit_reg2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : 
// Commentary   : Ausgelagert aus bittime-FSM um extrahierbar zu bekommen. ctrl steurt
//                Verhalten: Bei "01" AUsgang "1", Bei "10" Ausgang Puffer (Aus edge_puffer),
//                das Bit um eine Bitzeit verzoegert.
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 14.01.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module smpldbit_reg2 (
 input  wire       clock, 			
 input  wire       reset, 			
 input  wire [1:0] ctrl,      // bittime fsm: smpldbit_reg_ctrl
 output wire       smpldbit,  // MAC, destuff, biterrordetect
 input  wire       puffer	    // edgepuffer: puffer	
 );	

//tmrg default triplicate
//tmrg tmr_error false 

reg smpldbit_i;

//triplication signals
wire smpldbit_iVoted = smpldbit_i;
assign smpldbit = smpldbit_iVoted;

always @(posedge clock, negedge reset)
begin
 if (reset == 1'b0)
  smpldbit_i <= 1'b1;
 else
  begin
   case (ctrl) 
	 2'b01 : smpldbit_i <= 1'b1;        // rezessiv
	 2'b10 : smpldbit_i <= puffer;      // versp�tet
	 default : smpldbit_i <= smpldbit_iVoted;  
	 endcase
  end  
end

endmodule
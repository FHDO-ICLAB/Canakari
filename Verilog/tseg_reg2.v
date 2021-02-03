////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
// 
// Filename     : tseg_reg2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : 
// Commentary   : Ausgelagert aus bittiming fsm, wg. extraktion bei synthese. 
//                Latch (kein clock, kein reset) für tseg-wert bei resynchronisation. 
//                Steuerbefehle (ctrl) aus Bittiming FSM. DW 2005.06.26 Aus dem Latch 
//                wurde ein Register, welches mit Prescle_EN tacktet. 
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// --------+--------------------+------------+------------------------------------------------------
// 0.9     | Leduc              | 14.01.2019 | created
// --------+--------------------+------------+------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module tseg_reg2 (
 input  wire       clock, 		    // DW 2005.06.26 Clock
 input  wire       reset, 		    // DW 2005.06.26 Reset aktiv low
 input  wire [1:0] ctrl,		
 input  wire [2:0] tseg1,		     // IOCPU, genreg.
 input  wire [4:0] tseg1pcount, // sum
 input  wire [4:0] tseg1p1psjw, // sum
 output reg  [4:0] tseg1mpl	    // sum
 );
 
 // aus dem  Latch wird ein Register
 // DW 2005.06.26 Prescle_EN und Reset eingefügt
 
 always @(posedge clock, negedge reset)
 begin
  if (reset == 1'b0)
   tseg1mpl <= 5'b00000;
  else
   begin
  	 case (ctrl) // umschalten
	  2'b01 : tseg1mpl <= {2'b00,tseg1};
	  2'b10 : tseg1mpl <= tseg1pcount;
	  2'b11 : tseg1mpl <= tseg1p1psjw;
	  default : tseg1mpl <= tseg1mpl;   // halten 
	 endcase  
   end
 end
 
endmodule


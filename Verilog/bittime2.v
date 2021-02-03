////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : bittime2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Bittiming FSM - Teil von bittiming
// Commentary   : Änderungen: Latches für smpldbit und tsegreg ausgelagert für Extraktion
//                DW 2005.06.21 Prescale Enable eingefügt -- test 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 15.01.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 27.03.2019 | default state added
// -------------------------------------------------------------------------------------------------
// 0.92    | Leduc              | 12.02.2020 | Added Changes done in Verilog Triplication Files
// -------------------------------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module bittime2 (
 input wire clock,
 input wire Prescale_EN,                // DW 2005.06.21 Prescale Enable
 input wire reset,                      
 input wire hardsync,                   // von MACFSM
 input wire notnull,                    // von sum counter /= 0
 input wire gtsjwp1,                    //   "     counter > sjw+1
 input wire gttseg1p1,                  //   "     counter > tseg1+1 (nach smplpoint)
 input wire cpsgetseg1ptseg2p2,         //   "     counter ist sjw vor ende
 input wire cetseg1ptseg2p1,            //   "     counter ist am ende der bitzeit
 input wire countesmpltime,             //   "     counter = smplpoiunt
 input wire puffer,                     // von edgepuffer (smpldbit ein Bit verzögert)
 input wire rx,                         // von aussen (CAN-BUS in)
 output reg increment,                  // zu timecount
 output reg setctzero,                  // zu  "
 output reg setctotwo,                  // zu  "
 output reg sendpoint,                  // zu MACFSM
 output reg smplpoint,                  // zu MACFSM
 output reg [1:0] smpldbit_reg_ctrl,    // steuert ext. Latch smpldbit
 output reg [1:0] tseg_reg_ctrl,        // steuert externes Latch
 output reg [3:0] bitst	                // debug-state
 );	
 
 
 parameter [3:0] normal = 4'd0, hardset = 4'd1, stretchok = 4'd2, stretchnok = 4'd3,
                 slimok  = 4'd4, slimnok  = 4'd5, sndprescnt = 4'd6, samplepoint = 4'd7,				 
				         resetstate = 4'd8;
				 
 reg [3:0] current_state, next_state;
 
 // LEDUC: (ATTRIBUTE STATE_VECTOR VHDL?)
 
 always @(posedge clock, negedge reset)  // (SYNCH Process) Zustandsregister    
 begin
  if (reset == 1'b0)
    current_state <= resetstate;
  else 
    if (Prescale_EN == 1'b1)
    current_state <= next_state;  
 end
 
 always @(current_state)  // (steateb_p Process) Debug Ausgangsschaltnetz                    
 begin
  case (current_state)
    normal      : bitst <= 4'h0;
	  hardset     : bitst <= 4'h1;
	  stretchok   : bitst <= 4'h2;
	  stretchnok  : bitst <= 4'h3;
	  slimok      : bitst <= 4'h4;
	  slimnok     : bitst <= 4'h5;
	  sndprescnt  : bitst <= 4'h6;
	  samplepoint : bitst <= 4'h7;
	  resetstate  : bitst <= 4'h8;
    default     : bitst <= 4'ha;
  endcase
 end
 
 // (COMBIN Process) Uebergangs-/Ausgangsschaltnetz
 always @(current_state, hardsync, rx, puffer, notnull, gtsjwp1, gttseg1p1, 
          cpsgetseg1ptseg2p2, cetseg1ptseg2p1, countesmpltime)                      
 begin
   case (current_state)
    resetstate : begin
   	  increment  <= 1'b0; setctzero <= 1'b0; setctotwo <= 1'b0; sendpoint <= 1'b0;
      smplpoint  <= 1'b0; smpldbit_reg_ctrl <= 2'b01; tseg_reg_ctrl <= 2'b01;
      next_state <= hardset;
	  end
	////////////////////////////////////////////////////////////////////////////////////////
  	 normal: begin
  	   increment <= 1'b1; setctzero <= 1'b0; setctotwo <= 1'b0; sendpoint <= 1'b0;
      smplpoint <= 1'b0; smpldbit_reg_ctrl <= 2'b00; tseg_reg_ctrl <= 2'b00;
	    if (rx == 1'b0 && puffer == 1'b1)
  	     if (hardsync == 1)
  		     next_state <= hardset;
  	 	   else
  		     if (notnull == 1'b1 && gtsjwp1 == 1'b0)
  		      next_state <= stretchok;
  	 	    else if (gtsjwp1 == 1'b1 && gttseg1p1 == 1'b0)
   		     next_state <= stretchnok;
 	       else if (gttseg1p1 == 1'b1 && cpsgetseg1ptseg2p2 == 1'b0)
  		      next_state <= slimnok;
  		     else if (cpsgetseg1ptseg2p2 == 1'b1)
  		      next_state <= slimok;
  		     else
  		      next_state <= normal;
  	   else 
  	     if (cetseg1ptseg2p1 == 1'b1)
  		     next_state <= sndprescnt;
  		    else if (countesmpltime == 1'b1)
  	      next_state <= samplepoint;
  		    else
  		     next_state <= normal;
   	end
	////////////////////////////////////////////////////////////////////////////////////////
  	 hardset : begin
  	    increment <= 1'b0; setctzero <= 1'b0; setctotwo <= 1'b1; sendpoint <= 1'b1;
       smplpoint <= 1'b0; smpldbit_reg_ctrl <= 2'b00; tseg_reg_ctrl <= 2'b01;
       next_state <= normal;
  	 end
	////////////////////////////////////////////////////////////////////////////////////////
  	 sndprescnt : begin
        increment <= 1'b0; setctzero <= 1'b1; setctotwo <= 1'b0; sendpoint <= 1'b1;
        smplpoint <= 1'b0; smpldbit_reg_ctrl <= 2'b00; tseg_reg_ctrl <= 2'b01;	
  	     if (rx == 1'b0 && puffer == 1'b1)
  	       if (hardsync == 1)
  		       next_state <= hardset;
  		      else
  	        next_state <= slimok;
  	     else
  	      next_state <= normal;
 	  end
	////////////////////////////////////////////////////////////////////////////////////////
  	 stretchok : begin
  	   increment  <= 1'b1; setctzero <= 1'b0; setctotwo <= 1'b0; sendpoint <= 1'b0;
      smplpoint  <= 1'b0; smpldbit_reg_ctrl <= 2'b00; tseg_reg_ctrl <= 2'b10;
      next_state <= normal;  
  	 end
	////////////////////////////////////////////////////////////////////////////////////////
  	 stretchnok : begin
  	   increment  <= 1'b1; setctzero <= 1'b0; setctotwo <= 1'b0; sendpoint <= 1'b0;
      smplpoint  <= 1'b0; smpldbit_reg_ctrl <= 2'b00; tseg_reg_ctrl <= 2'b11;
      next_state <= normal;
  	 end
	////////////////////////////////////////////////////////////////////////////////////////
  	 slimok : begin
  	   increment  <= 1'b0; setctzero <= 1'b0; setctotwo <= 1'b1; sendpoint <= 1'b1;
      smplpoint  <= 1'b0; smpldbit_reg_ctrl <= 2'b00; tseg_reg_ctrl <= 2'b01;
      next_state <= normal;
  	 end
	////////////////////////////////////////////////////////////////////////////////////////	
  	 slimnok : begin
      increment <= 1'b1; setctzero <= 1'b0; setctotwo <= 1'b0; sendpoint <= 1'b0;
      smplpoint <= 1'b0; smpldbit_reg_ctrl <= 2'b00; tseg_reg_ctrl <= 2'b00;
  	   if (cpsgetseg1ptseg2p2 == 1'b1)
  	     next_state <= slimok;
  	   else
  	     next_state <= slimnok;  
  	 end	
	////////////////////////////////////////////////////////////////////////////////////////
  	 samplepoint : begin
      increment <= 1'b1; setctzero <= 1'b0; setctotwo <= 1'b0; sendpoint <= 1'b0;
      smplpoint <= 1'b1; smpldbit_reg_ctrl <= 2'b10; tseg_reg_ctrl <= 2'b00;
  	   if (rx == 1'b0 && puffer == 1'b1)
  	     if (hardsync == 1)
  		     next_state <= hardset;
  		    else
  		     if (cpsgetseg1ptseg2p2 == 1'b1)
  		      next_state <= slimok;
  		     else
  		      next_state <= slimnok;
  	   else
  	    next_state <= normal; 
  	 end
	////////////////////////////////////////////////////////////////////////////////////////
  	 default : begin 
     	 increment <= 1'b0; setctzero <= 1'b0; setctotwo <= 1'b0; sendpoint <= 1'b0;
      	smplpoint <= 1'b0; smpldbit_reg_ctrl <= 2'b00; tseg_reg_ctrl <= 2'b00;  	   
  	   next_state <= current_state; 
  	 end
   endcase
 end
 
endmodule

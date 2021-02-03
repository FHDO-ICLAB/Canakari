////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : write_demux2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : WRITE_DEMUX erzeugt Aktivierungssignale, wenn CPU auf ein Register schreiben
//                will. Abhängig von der Adresse wird das Signal activ_in zu einem der 15
//                möglichen activ_out durchgeschaltet, die in multiplexer_top gemappt werden.
// Commentary   :  
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 20.05.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module write_demux2 (
  input  wire [4:0] address,      // aussen
  input  wire activ_in,           // multiplexer_top
  output reg  [14:0] activ_out    //        "
);

always@(address, activ_in)
begin
  case(address)
      5'b10010  : begin 
                  activ_out[14] = activ_in;  // Interruptregister
                  activ_out[13:0]  = 14'd0; 
                  end
      5'b10001  : begin 
                  activ_out[13] = activ_in;  // Acceptionmaskregister 28...13
                  activ_out[14 : 14] = 1'd0;
                  activ_out[12 : 0]  = 13'd0; 
                  end
      5'b10000  : begin 
                  activ_out[12] = activ_in;  // Acceptionmaskregister 12...0
                  activ_out[14 : 13] = 2'd0;
                  activ_out[11 : 0]  = 12'd0;
                  end
      5'b01111  : begin
                  activ_out[11] = activ_in;  // Prescaleregister
                  activ_out[14 : 12] = 3'd0;
                  activ_out[10 : 0]  = 11'd0;
                  end                  
      5'b01110  : begin 
                  activ_out[10] = activ_in;  // Generalregister
                  activ_out[14 : 11] = 4'd0;
                  activ_out[ 9 : 0]  = 10'd0;
                  end                  
      5'b01101  : begin 
                  activ_out[ 9] = activ_in;  // tranmit message control register
                  activ_out[14 : 10] = 5'd0;
                  activ_out[ 8 : 0]  = 9'd0;
                  end                  
      5'b01100  : begin 
                  activ_out[ 8] = activ_in;  // transmit id bit 28..13
                  activ_out[14 : 9]  = 6'd0;
                  activ_out[ 7 : 0]  = 8'd0;
                  end                  
      5'b01011  : begin 
                  activ_out[ 7] = activ_in;  // transmit id bit 12..0
                  activ_out[14 : 8]  = 7'd0;
                  activ_out[ 6 : 0]  = 7'd0;
                  end                  
      5'b01010  : begin 
                  activ_out[ 6] = activ_in;  // transmit data 1,2
                  activ_out[14 : 7]  = 8'd0;
                  activ_out[ 5 : 0]  = 6'd0;
                  end                  
      5'b01001  : begin 
                  activ_out[ 5] = activ_in;  // transmit data 3,4
                  activ_out[14 : 6]  = 9'd0;
                  activ_out[ 4 : 0]  = 5'd0;
                  end                  
      5'b01000  : begin 
                  activ_out[ 4] = activ_in;  // transmit data 5,6
                  activ_out[14 : 5]  = 10'd0;
                  activ_out[ 3 : 0]  = 4'd0;
                  end                  
      5'b00111  : begin 
                  activ_out[ 3] = activ_in;  // transmit data 7,8
                  activ_out[14 : 4]  = 11'd0;
                  activ_out[ 2 : 0]  = 3'd0;
                  end                  
      5'b00110  : begin 
                  activ_out[ 2] = activ_in;  // receive message control register
                  activ_out[14 : 3]  = 12'd0;
                  activ_out[ 1 : 0]  = 2'd0;
                  end                  
      5'b00101  : begin 
                  activ_out[ 1] = activ_in;  // receive id 28..13
                  activ_out[14 : 2]  = 13'd0;
                  activ_out[ 0 : 0]  = 1'd0;
                  end                  
      5'b00100  : begin 
                  activ_out[ 0] = activ_in;  // receive id 12..0
                  activ_out[14 : 1]  = 14'd0;
                  end                  
      default   : activ_out = 15'd0;  // receive data ist nicht von der cpu beschreibbar    
  endcase
end
    
endmodule

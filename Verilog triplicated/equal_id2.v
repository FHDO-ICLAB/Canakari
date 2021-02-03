////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : equal_id2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : equal_id: Akzeptanzpr�fung im LLC, verglichen wird id aus dem arbitration
//                register in IOCPU (rarbit) mit empfangener aus MAC, decapsulation. equal=1,
//                wenn gleich. Zur Extrahierbarkeit von LLC_fsm eingebaut
//                Empfangsbedingung wird hier ueberpr�ft. Acceptance Mask und idregister legen 
//                diese fest.
// Commentary   :  
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 08.04.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module equal_id2 (
  input wire        extended,     // IOCPU, recmescontrolreg
  input wire [28:0] idregister,   // IOCPU, rarbit
  input wire [28:0] idreceived,   // MAC, decapsulation
  input wire [28:0] accmask,      // NEU Acception Mask
  output reg        equal         // LLC_FSM
);
//tmrg default triplicate
//tmrg tmr_error false 

always @(extended, idregister, idreceived, accmask)
 begin
   if (  ((extended == 1'b1) & (( (idregister        ^ idreceived)        & accmask)        == 29'd0)) | 
         ((extended == 1'b0) & ((((idregister[28:18] ^ idreceived[28:18]) & accmask[28:18]) == 11'd0)))  )
    equal = 1'b1;
   else
    equal = 1'b0;
 end
endmodule
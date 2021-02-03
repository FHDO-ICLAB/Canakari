////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : llc2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : LLC Logic Link Control
// Commentary   : neu: Strukturunterteilung, id Vergleich in equal_id 
//                neu Promiscuous Mode, FSM skippt Akzeptanzpr�fung
//                Struktur
//                equal_id_i: equal_id: Vergleicht ID empfangen mit ID aus REgister (IOCPU)
//                llc_fsm_1: llc_fsm: Zustandsmaschine Senden/Empfangen
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 04.04.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module llc2 (
  input  wire clock,              
  input  wire reset,                  
  input  wire initreqr,           // CPU signalises the reset // initialisation of the CAN Controller
  input  wire traregbit,          // bit indicating data for transmission     
  input  wire sucfrecvc,          // mac unit indicates the succesful // reception of a message       
  input  wire sucftranc,          // mac unit indicates the succesful // transmission of a message
  input  wire sucfrecvr,          // general register bit        
  input  wire sucftranr,          // general register bit
  input  wire extended,           // information of the decaps e
  input  wire [28:0] accmaskreg,  // IOCPU
  input  wire [28:0] idreg,       // IOCPU
  input  wire [28:0] idrec,       // MAC
  // input wire promiscous        // IOCPU, recmesconreg
  output wire  activtreg,          // enables writing to the transmission register              
  output wire  activrreg,          // enables writing to the reception register
  output wire  activgreg,          // enables writing to the general register
  output wire  ldrecid,            // rec_id ins rec_arbitreg laden
  output wire  sucftrano,          // sets the suctran bit in the general register
  output wire  sucfrecvo,          // sets the sucrecv bit in the general register
  output wire  overflowo,          // sets the overflow bit in the reception register
  output wire  trans,              // signalises the wish of the CPU to send a message
  output wire  load,               // enables loading of the shift register
  output wire  actvtsft,           // activates the shift register
  output wire  actvtcap,           // activates the encapsulation entity 
  output wire  resettra,           // resets the transmission entities
  output wire  resetall            // full can reset 
  );

//tmrg default triplicate
//tmrg tmr_error false

wire equal_i;

llc_fsm2 llc_fsm_2 (
      .clock      ( clock     ),  
      .reset      ( reset     ),  
      .initreqr   ( initreqr  ),  // IOCPU, reset in generalreg
      .traregbit  ( traregbit ),  // IOCPU, transmesconreg: Transmission REquest
      .sucfrecvc  ( sucfrecvc ),  // MACFSM, decrec
      .sucftranc  ( sucftranc ),  // MACFSM, dectra
      .sucfrecvr  ( sucfrecvr ),  // IOCPU, generalregister
      .sucftranr  ( sucftranr ),  // IOCPU, generalregister
      .equal      ( equal_i   ),  // equal_id
//    .promiscous ( promiscous),  // IOCPU, recmesconreg
      .activtreg  ( activtreg ),  // IOCPU, transmesconreg, schreibaktiv
      .activrreg  ( activrreg ),  // IOCPU, recmesconreg, schreibaktiv
      .activgreg  ( activgreg ),  // IOCPU, generalregister, schreibaktiv
      .ldrecid    ( ldrecid   ),  // IOCPU, rarbit, ID laden (Prom. Mode)
      .sucftrano  ( sucftrano ),  // IOCPU, generalreg, Bit 11
      .sucfrecvo  ( sucfrecvo ),  // IOCPU, generalreg, Bit 10
      .overflowo  ( overflowo ),  // IOCPU, recmesctrlreg, Bit 15
      .trans      ( trans     ),  // MACFSM
      .load       ( load      ),  // MAC, transshift
      .actvtsft   ( actvtsft  ),  // MAC, transshift
      .actvtcap   ( actvtcap  ),  // MAC, encapsulation
      .resettra   ( resettra  ),  // MAC, reset transmit
      .resetall   ( resetall  )   // MAC reset
);

equal_id2 equal_id_2 (
      .extended   ( extended   ),  // Vergleich abh�ngig
      .idregister ( idreg      ),  // aus Register
      .idreceived ( idrec      ),  // grad empfangegn
      .accmask    ( accmaskreg ),  // AcceptionmaskRegister
      .equal      ( equal_i    )   // gleich = 1
);

endmodule

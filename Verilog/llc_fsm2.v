////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : llc_fsm2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : LLC- FSM
// Commentary   : neu: Promiscuous Mode: Vergleich skippen und ID ins rarbit Register schreiben. 
//                Der Zustand trareset wird im Originalmodul (VHDL) niemals betreten und daher 
//                auskommentiert.
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 08.04.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 09.04.2019 | Removed FSM state trareset and adjusted state coding.
//         |                    |            | Removed sucftranr from sensitivity list.
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module llc_fsm2 (
  input wire  clock,
  input wire  reset, 
  input wire  initreqr,    // CPU signalises the reset / initialisation of the CAN Controller
  input wire  traregbit,   // bit indicating data for transmission 
  input wire  sucfrecvc,   // mac unit indicates the succesful reception of a message
  input wire  sucftranc,   // mac unit indicates the succesful transmission of a message
  input wire  sucfrecvr,   // general register bit
  input wire  sucftranr,   // general register bit
  input wire  equal,       // abhängig von extended, empfangene und --gespeicherte id gleich
//input wire  promiscous,  // Promiscous MOde (aus rec-ctrl. reg.)
  output reg  activtreg,   // enables writing to the transmission register
  output wire activrreg,   // enables writing to the reception register
  output reg  activgreg,   // enables writing to the general register
  output wire ldrecid,     // rec_id ins rec_arbitreg laden
  output reg  sucftrano,   // sets the suctran bit in the general register
  output reg  sucfrecvo,   // sets the sucrecv bit in the general register
  output reg  overflowo,   // sets the overflow bit in the reception register
  output reg  trans,       // signalises the wish of the CPU to send a message
  output reg  load,        // enables loading of the shift register
  output reg  actvtsft,    // activates the shift register
  output reg  actvtcap,    // activates the encapsulation entity 
  output reg  resettra,    // resets the transmission entities
  output reg  resetall     // full can reset  
);

//

localparam  waitoact    = 4'b0000, 
            tradrvdat   = 4'b0001, 
            traruncap   = 4'b0010, 
            tralodsft   = 4'b0011, 
            trawtosuc   = 4'b0100, 
            trasetvall  = 4'b0101, 
            trareset    = 4'b0110,  // FSM state removed and coding adjusted
            trasetvalh  = 4'b0111, 
            recwrtmesll = 4'b1000, 
            recwrtmeslh = 4'b1001, 
            recwrtmeshl = 4'b1010, 
            recwrtmeshh = 4'b1011, 
            resetste    = 4'b1100;


//            trasetvalh  = 4'b0110, 
//            recwrtmesll = 4'b0111, 
//            recwrtmeslh = 4'b1000, 
//            recwrtmeshl = 4'b1001, 
//            recwrtmeshh = 4'b1010, 
//            resetste    = 4'b1011;
            
reg  [3:0] CURRENT_STATE, NEXT_STATE;
reg        activrreg_i; 
wire [1:0] sctrrcin;


assign sctrrcin   = {sucftranr, sucfrecvr};
assign ldrecid    = activrreg_i;
assign activrreg  = activrreg_i;

// Zustandsregister

always @(posedge clock)
 begin
   if (reset == 1'b0)
    CURRENT_STATE <= waitoact;
   else
    CURRENT_STATE <= NEXT_STATE;
 end
 
 
 // Ausgangs- / Ueberfuehrungsschaltnetz
 
always @(CURRENT_STATE, traregbit, sucfrecvc, sucftranc, sucfrecvr, sctrrcin, initreqr, equal)
 begin   
	activtreg   = 1'b0;
        activrreg_i = 1'b0;
        activgreg   = 1'b0;
        sucftrano   = 1'b0;
        sucfrecvo   = 1'b0;
        trans       = 1'b0;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        overflowo   = 1'b0;
        resettra    = 1'b1;
        resetall    = 1'b1;

   case (CURRENT_STATE)
      // Warten auf Aktion (Sendeaufforderung, Empfang)
      waitoact: begin
        activtreg   = 1'b0;
        activrreg_i = 1'b0;
        activgreg   = 1'b0;
        sucftrano   = 1'b0;
        sucfrecvo   = 1'b0;
        trans       = 1'b0;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        overflowo   = 1'b0;
        resettra    = 1'b1;
        resetall    = 1'b1; 
        if (initreqr == 1'b1) 
          NEXT_STATE = resetste;
        else if (initreqr == 1'b0 && traregbit == 1'b1 && sucfrecvc == 1'b0)
          NEXT_STATE = tradrvdat;
        else if (sctrrcin == 2'b00 && sucfrecvc == 1'b1 && initreqr == 1'b0 && equal == 1'b1)  // promiscous='1' 
          NEXT_STATE = recwrtmesll;
        else if (sctrrcin == 2'b01 && sucfrecvc == 1'b1 && initreqr == 1'b0 && equal == 1'b1) // promiscous='1' 
          NEXT_STATE = recwrtmeslh;
        else if (sctrrcin == 2'b10 && sucfrecvc == 1'b1 && initreqr == 1'b0 && equal == 1'b1) // promiscous='1' 
          NEXT_STATE = recwrtmeshl;
        else if (sctrrcin == 2'b11 && sucfrecvc == 1'b1 && initreqr == 1'b0 && equal == 1'b1) // promiscous='1' 
          NEXT_STATE = recwrtmeshh;
        else
          NEXT_STATE = waitoact;
      end
      ////////////////////////////
      // Alles zurücksetzen
      resetste: begin
        activtreg   = 1'b0;
        activrreg_i = 1'b0;
        activgreg   = 1'b1;
        sucftrano   = 1'b0;
        sucfrecvo   = 1'b0;
        trans       = 1'b0;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        overflowo   = 1'b0;
        //recindico   = 1'b0;
        resettra    = 1'b1;
        resetall    = 1'b0;
        NEXT_STATE  = waitoact;
      end
      ////////////////////////////
      // 1. Schritt Sendeaufforderung, MAC resetten
      trareset: begin
        activtreg   = 1'b0;
        activrreg_i = 1'b0;
        activgreg   = 1'b0;
        sucftrano   = 1'b0;
        sucfrecvo   = 1'b0;
        trans       = 1'b0;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        overflowo   = 1'b0;
        resettra    = 1'b0;
        resetall    = 1'b1;
        if (initreqr == 1'b1)
          NEXT_STATE = resetste;
        else
          NEXT_STATE = tradrvdat;
      end
      ////////////////////////////
      // 2. Schritt: Reset weg
      tradrvdat: begin
        activtreg   = 1'b0;
        activrreg_i = 1'b0;
        activgreg   = 1'b0;
        sucftrano   = 1'b0;
        sucfrecvo   = 1'b0;
        trans       = 1'b0;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        overflowo   = 1'b0;
        resettra    = 1'b1;
        resetall    = 1'b1;
        if (initreqr == 1'b1)
          NEXT_STATE = resetste;
        else
          NEXT_STATE = traruncap;
      end
      ////////////////////////////
      // 3. Schritt, Register laden und Encapsulation
      traruncap: begin
        activtreg   = 1'b0;
        activrreg_i = 1'b0;
        activgreg   = 1'b0;
        sucftrano   = 1'b0;
        sucfrecvo   = 1'b0;
        trans       = 1'b0;
        load        = 1'b1;
        actvtsft    = 1'b0;
        actvtcap    = 1'b1;
        overflowo   = 1'b0;
        resettra    = 1'b1;
        resetall    = 1'b1;
        if (initreqr == 1'b1)
          NEXT_STATE = resetste;
        else
          NEXT_STATE = tralodsft; 
      end
      ////////////////////////////
      // 4. Schritt, trans setzen, dann gehts los
      tralodsft: begin
        activtreg   = 1'b0;
        activrreg_i = 1'b0;
        activgreg   = 1'b0;
        sucftrano   = 1'b0;
        sucfrecvo   = 1'b0;
        trans       = 1'b0;
        load        = 1'b1;
        actvtsft    = 1'b1;
        actvtcap    = 1'b0;
        overflowo   = 1'b0;
        resettra    = 1'b1;
        resetall    = 1'b1;
        if (initreqr == 1'b1)
          NEXT_STATE = resetste;
        else
          NEXT_STATE = trawtosuc;
      end
      ////////////////////////////
      // warten auf geglückten Versand
      trawtosuc: begin
        activtreg   = 1'b0;
        activrreg_i = 1'b0;
        activgreg   = 1'b0;
        sucftrano   = 1'b0;
        sucfrecvo   = 1'b0;
        trans       = 1'b1;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        overflowo   = 1'b0;
        resettra    = 1'b1;
        resetall    = 1'b1;
        if (initreqr == 1'b1)
          NEXT_STATE = resetste;
        else if (initreqr == 1'b0 && sucftranc == 1'b1 && sucfrecvc == 1'b0 && sucfrecvr == 1'b0)
          NEXT_STATE = trasetvall;
        else if (initreqr == 1'b0 && sucftranc == 1'b1 && sucfrecvc == 1'b0 && sucfrecvr == 1'b1)
          NEXT_STATE = trasetvalh;
        else if (sctrrcin == 2'b00 && sucfrecvc == 1'b1 && initreqr == 1'b0 && equal == 1'b1)      // promiscous='1' 
          NEXT_STATE = recwrtmesll;
        else if (sctrrcin == 2'b01 && sucfrecvc == 1'b1 && initreqr == 1'b0 && equal == 1'b1)      // promiscous='1' 
          NEXT_STATE = recwrtmeshl;
        else if (sctrrcin == 2'b10 && sucfrecvc == 1'b1 && initreqr == 1'b0 && equal == 1'b1)      // promiscous='1' 
          NEXT_STATE = recwrtmeshl;
        else if (sctrrcin == 2'b11 && sucfrecvc == 1'b1 && initreqr == 1'b0 && equal == 1'b1)      // promiscous='1'  
          NEXT_STATE = recwrtmeshh;
        else
          NEXT_STATE = trawtosuc;   
      end
      ////////////////////////////
      // Succesful transmit Bit im Genreg setzen
      trasetvall: begin
        activtreg   = 1'b1;
        activrreg_i = 1'b0;
        activgreg   = 1'b1;
        sucftrano   = 1'b1;
        sucfrecvo   = 1'b0;
        trans       = 1'b0;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        overflowo   = 1'b0;
        resettra    = 1'b1;
        resetall    = 1'b1;
        if (initreqr == 1'b1)
          NEXT_STATE = resetste;
        else
          NEXT_STATE = waitoact;
      end
      ////////////////////////////
      // Vor dem Versenden noch was empfangen: Succsessfull trans und received im
      // Genreg register setzen
      trasetvalh: begin
        activtreg   = 1'b1;
        activrreg_i = 1'b0;
        activgreg   = 1'b1;
        sucftrano   = 1'b1;
        sucfrecvo   = 1'b1;
        trans       = 1'b0;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        overflowo   = 1'b0;
        //recindico   = 1'b0;
        resettra    = 1'b1;
        resetall    = 1'b1;
        if (initreqr == 1'b1)
          NEXT_STATE = resetste;
        else
          NEXT_STATE = waitoact;
      end
      ////////////////////////////
      // Nur empfangen: Sucrec. Bit setzen
      recwrtmesll: begin
        activtreg   = 1'b0;
        activrreg_i = 1'b1;
        activgreg   = 1'b1;
        sucftrano   = 1'b0;
        sucfrecvo   = 1'b1;
        trans       = 1'b0;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        resettra    = 1'b1;
        overflowo   = 1'b0;
        resetall    = 1'b1;
        if (initreqr == 1'b1)
          NEXT_STATE = resetste;
        else if (sucfrecvc == 1'b0)
          NEXT_STATE = waitoact;
        else
          NEXT_STATE = recwrtmesll;
      end
      ////////////////////////////
      // Zum 2. Mal empfangen: Sucrec. Bit und Overflow BIt setzen
      recwrtmeslh: begin
        activtreg   = 1'b0;
        activrreg_i = 1'b1;
        activgreg   = 1'b1;
        sucftrano   = 1'b0;
        sucfrecvo   = 1'b1;
        trans       = 1'b0;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        resettra    = 1'b1;
        overflowo   = 1'b1;
        resetall    = 1'b1;
        if (initreqr == 1'b1)
          NEXT_STATE = resetste;
        else if (sucfrecvc == 1'b0)
          NEXT_STATE = waitoact;
        else
          NEXT_STATE = recwrtmeslh;
      end
      ////////////////////////////
      // Erfolgreich Empfangen und versendet, Bits setzen
      recwrtmeshl: begin
        activtreg   = 1'b0;
        activrreg_i = 1'b1;
        activgreg   = 1'b1;
        sucftrano   = 1'b1;
        sucfrecvo   = 1'b1;
        trans       = 1'b0;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        resettra    = 1'b1;
        overflowo   = 1'b0;
        resetall    = 1'b1;
        if (initreqr == 1'b1)
          NEXT_STATE = resetste;
        else if (sucfrecvc == 1'b0)
          NEXT_STATE = waitoact;
        else
          NEXT_STATE = recwrtmeshl;
      end
      ////////////////////////////
      // Empfangen zum 2. Mal und versendet: overflow, sucsent, sucrecv Bits setzen
      recwrtmeshh: begin
        activtreg   = 1'b0;
        activrreg_i = 1'b1;
        activgreg   = 1'b1;
        sucftrano   = 1'b1;
        sucfrecvo   = 1'b1;
        trans       = 1'b0;
        load        = 1'b0;
        actvtsft    = 1'b0;
        actvtcap    = 1'b0;
        resettra    = 1'b1;
        overflowo   = 1'b1;
        resetall    = 1'b1;
        if (initreqr == 1'b1)
          NEXT_STATE = resetste;
        else if (sucfrecvc == 1'b0)
          NEXT_STATE = waitoact;
        else
          NEXT_STATE = recwrtmeshh;
       end
       default: begin       
        //NEXT_STATE = waitoact; 
        NEXT_STATE = CURRENT_STATE;
      end        
  endcase          
 end 
endmodule

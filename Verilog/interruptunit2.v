////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : interruptunit2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Löst IRQ bei successful transmit, successful receive und bei Statuswechseln aus
//                Zustandsautomat mit fuenf Zuständen.
// Commentary   :  
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 25.03.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module interruptunit2 (
 input  wire       clock,
 input  wire       reset,
 input  wire [2:0] ienable,       // Interrupt Enable im interruptregister von iocpu
 input  wire [2:0] irqstd,        // Interruptzustand im interruptregister von iocpu
 input  wire       irqsig,        // von fce-fsm Zustandswechsel (Currentstate=Nextstate)     
 input  wire       sucfrec,       // successful reception controller von llc
 input  wire       sucftra,       // successful transmission controller von llc    
 output reg        activintreg,   // aktiviert Interruptregister 
 output reg        irqstatus,     // Neue Irqwerte für Interruptregister
 output reg        irqsuctra,
 output reg        irqsucrec,
 output wire       irq            // Interrupt Request Leitung die nach aussen gefuehrt wird
 );

 reg       [1:0]  CURRENT_STATE, NEXT_STATE;

 parameter [1:0]  waitoact  = 2'b00, 
                  recind    = 2'b01, 
                  traind    = 2'b10, 
                  statind   = 2'b11;

 assign irq = (irqstd[0] | irqstd[1] | irqstd [2]); // Wenn eines der Bits im Interruptregister 1 ist dann IRQ

 always @(posedge clock)  // Zustandsregister
  begin
    if (reset == 1'b0) 
      CURRENT_STATE <= waitoact;
    else
      CURRENT_STATE <= NEXT_STATE;
  end
   
 always @(CURRENT_STATE, irqsig, sucfrec, sucftra, irqstd, ienable)   // Ueberfuehrungs-/Ausgangsschaltnetz
  begin
    case (CURRENT_STATE)
 //////////////////////////////
      waitoact : begin
        activintreg   = 1'b0;
        irqstatus     = 1'b0;
        irqsuctra     = 1'b0;
        irqsucrec     = 1'b0;
        if      (sucfrec == 1'b1 & irqstd[0] == 1'b0 & ienable[0] == 1'b1)  // Falls eine der Interupt-Indications 
          NEXT_STATE = recind;
        else if (sucftra == 1'b1 & irqstd[1] == 1'b0 & ienable[1] == 1'b1)  // von der llc oder fce vorliegt und noch 
          NEXT_STATE = traind;
        else if (irqsig == 1'b1 & irqstd[2] == 1'b0 & ienable[2] == 1'b1)  // nicht im Interruptregister vermerkt ist
          NEXT_STATE = statind;
        else
          NEXT_STATE = waitoact;                                             // ansonsten bleibe in waitoact
      end
 //////////////////////////////  
      recind : begin
        activintreg   = 1'b1;
        irqstatus     = 1'b0;
        irqsuctra     = 1'b0;
        irqsucrec     = 1'b1;
        if      (sucftra == 1'b1 & irqstd[1] == 1'b0 & ienable[1] == 1'b1)  // Übergang nach Transmit Indication
          NEXT_STATE = traind;        
        else if (irqsig ==  1'b1 & irqstd[2] == 1'b0 & ienable[2] == 1'b1)  // Übergang nach Status Indication
          NEXT_STATE = statind;
        else                                                                  // ansonsten nach waitoact zurückkehren
          NEXT_STATE = waitoact;        
      end
 //////////////////////////////       
      traind : begin
        activintreg   = 1'b1;
        irqstatus     = 1'b0;
        irqsuctra     = 1'b1;
        irqsucrec     = 1'b0; 
        if      (sucfrec == 1'b1 & irqstd[0] == 1'b0 & ienable[0] == 1'b1)  // Übergang nach Receive Indication 
          NEXT_STATE = recind;       
        else if (irqsig ==  1'b1 & irqstd[2] == 1'b0 & ienable[2] == 1'b1)  // Übergang nach Status Indication          
          NEXT_STATE = statind;                                              
        else  
          NEXT_STATE = waitoact;        
      end
 //////////////////////////////        
      statind : begin
        activintreg   = 1'b1;
        irqstatus     = 1'b1;
        irqsuctra     = 1'b0;
        irqsucrec     = 1'b0;
        if      (sucfrec == 1'b1 & irqstd[0] == 1'b0 & ienable[0] == 1'b1)   // Übergang nach Receive Indication 
          NEXT_STATE = recind;       
        else if (sucftra ==  1'b1 & irqstd[1] == 1'b0 & ienable[1] == 1'b1)  // Übergang nach Transmit Indication          
          NEXT_STATE = traind;                                              
        else  
          NEXT_STATE = waitoact;                                            // ansonsten nach waitoact zurückkehren        
      end
 //////////////////////////////
     // default : begin
     // end
  endcase        
 end

endmodule

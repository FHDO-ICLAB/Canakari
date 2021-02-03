////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : faultfsm2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Fehlerzustandsautomat
// Commentary   : Resets umgedreht auf active low 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 17.04.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 13.05.2019 | Added default state to fsm
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module faultfsm2(
   input  wire  clock,
   input  wire  reset,        
   input  wire  rec_lt96,     
   input  wire  rec_ge96,     
   input  wire  rec_ge128,    
   input  wire  tec_lt96,     
   input  wire  tec_ge96,     
   input  wire  tec_ge128,    
   input  wire  tec_ge256,    
   input  wire  erb_eq128,    
   output reg   resetcount,   
   output reg   erroractive,  
   output reg   errorpassive, 
   output reg   busoff,       
   output reg   warnsig,      
   output wire  irqsig      
);

//tmrg default triplicate
//tmrg tmr_error false 

localparam  [2:0] erroractiv  = 3'b000, 
                  errorpassiv = 3'b001, 
                  busof       = 3'b010, 
                  resetstate  = 3'b011, 
                  warning     = 3'b100;

reg [2:0] CURRENT_STATE, NEXT_STATE;

//triplication signals
wire [2:0] CURRENT_STATEVoted = CURRENT_STATE;                  

// Zustandsregister
always @(posedge clock) 
begin
  if (reset == 1'b0)              // define an asynchronous reset
    CURRENT_STATE <= erroractiv;  // define the reset state
  else
    CURRENT_STATE <= NEXT_STATE;
end                 

// Uebergangs-/Ausgangsschaltnetz
assign irqsig = (CURRENT_STATEVoted == NEXT_STATE) ? 1'b0 : 1'b1;

always @(CURRENT_STATEVoted, rec_lt96, rec_ge96, rec_ge128, tec_lt96, tec_ge96, tec_ge128, tec_ge256, erb_eq128)
begin
  case (CURRENT_STATEVoted)
  ///////////////////////// 
  // Erroractive (<96)  
    erroractiv: begin
      erroractive  = 1'b1; 
      errorpassive = 1'b0;
      busoff       = 1'b0;
      warnsig      = 1'b0;
      resetcount   = 1'b1;
      if (rec_ge96 == 1'b1 || tec_ge96 == 1'b1)
        NEXT_STATE = warning;
      else
        NEXT_STATE = erroractiv;
    end 
  ///////////////////////// 
  // Warning (96 < C < 128)
    warning: begin
      erroractive  = 1'b1;
      errorpassive = 1'b0;
      busoff       = 1'b0;
      warnsig      = 1'b1;
      resetcount   = 1'b1;
      if (rec_ge128 == 1'b1 || tec_ge128 == 1'b1)  
        NEXT_STATE = errorpassiv;
      else if (rec_lt96 == 1'b1 && tec_lt96 == 1'b1)  
        NEXT_STATE = erroractiv;
      else
        NEXT_STATE = warning;
    end
  ///////////////////////// 
  // Errorpassive (>128)   
    errorpassiv: begin
      erroractive  = 1'b0;
      errorpassive = 1'b1;
      busoff       = 1'b0;
      warnsig      = 1'b0;
      resetcount   = 1'b1;
      if (tec_ge256 == 1'b1)  
        NEXT_STATE = busof;
      else if (tec_ge128 == 1'b0 && rec_ge128 == 1'b0)  
        NEXT_STATE = erroractiv;
      else
        NEXT_STATE = errorpassiv;  
    end
  ///////////////////////// 
  // Busoff =256   
    busof: begin
      erroractive  = 1'b0;
      errorpassive = 1'b0;
      busoff       = 1'b1;
      warnsig      = 1'b0;
      resetcount   = 1'b1;
      if (erb_eq128 == 1'b1)  
        NEXT_STATE = resetstate;
      else
        NEXT_STATE = busof;
    end
  ///////////////////////// 
  // RESET, alles von vorne   
    resetstate: begin
      erroractive  = 1'b1;
      errorpassive = 1'b0;
      busoff       = 1'b0;
      warnsig      = 1'b0;
      resetcount   = 1'b0;
      NEXT_STATE   = erroractiv;
    end
  /////////////////////////    
    default: begin
      erroractive  = 1'b0;
      errorpassive = 1'b0;
      busoff       = 1'b0;
      warnsig      = 1'b0;
      resetcount   = 1'b0;
      NEXT_STATE   = CURRENT_STATEVoted;
    end
  endcase  
end

endmodule

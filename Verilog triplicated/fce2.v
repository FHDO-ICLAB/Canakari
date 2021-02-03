////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : fce2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Fault Confinement Entity
// Commentary   : FCE unterteilung in FSM, REC(Receive Error Counter), TEC (Transmit..)
//                Die Counter geben wichtige Z�hlerst�nde als Signal, kein Vergleich mehr in
//                FSM -> weniger Signale, FSM extrahierbar.
//                rein strukturorientiert, bis auf AND f�r reset
//                erb_count: erbcount: Z�hlt 11 rez. Bits um nach 128 Busoff zu verlassen
//                tec_count: tec: Transmit error Counter
//                rec:count: rec: receive Error Counter
//                fsm: faultfsm: FSM steuert Zustands�berg�nge EA->EP->BO->EA->. 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 18.04.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module fce2(
   input  wire clock,
   input  wire reset,
   input  wire inconerec,         // MACFSM zu REC
   input  wire incegtrec,         // MACFSM zu REC
   input  wire incegttra,         // MACFSM zu TEC
   input  wire decrec,            // MACFSM zu REC
   input  wire dectra,            // MACFSM zu TEC
   input  wire elevrecb,          // MACFSM zu ERB
   output wire erroractive,       // MACFSM, IOCPU
   output wire errorpassive,      // MACFSM, IOCPU
   output wire busoff,            // MACFSM, IOCPU
   output wire warnsig,           // IOCPU, generalregister
   output wire irqsig,
   output wire [7:0] tecfce,   
   output wire [7:0] recfce
); 

//tmrg default triplicate
//tmrg tmr_error false 

  wire rec_ge96_i;
  wire rec_ge128_i;
  wire rec_lt96_i;      //rec als signal wegen fehler hinzugef�gt
  wire tec_lt96_i; 
  wire tec_ge96_i;
  wire tec_ge128_i;
  wire tec_ge256_i;
  wire erb_eq128_i;
  wire resetcount_i;    
  wire resetsig;
  
  // reset von aussen und intern
  assign resetsig = reset & resetcount_i;  // war vor 0->1 OR
 
  faultfsm2 fsm (
      .clock        ( clock        ),
      .reset        ( reset        ),
      .rec_lt96     ( rec_lt96_i   ),   // REC, <96, ok 
      .rec_ge96     ( rec_ge96_i   ),   // REC, >=96, warning
      .rec_ge128    ( rec_ge128_i  ),   // REC, >=128, errorpassive
      .tec_lt96     ( tec_lt96_i   ),   // TEC, <96, ok
      .tec_ge96     ( tec_ge96_i   ),   // TEC, >=96, warning
      .tec_ge128    ( tec_ge128_i  ),   // TEC, >=128, errorpassive
      .tec_ge256    ( tec_ge256_i  ),   // TEC, =256, busoff
      .erb_eq128    ( erb_eq128_i  ),   // ERB, Busoff beenden (128*11)
      .resetcount   ( resetcount_i ),   // REC,TEC,ERB
      .erroractive  ( erroractive  ),   // s.o.
      .errorpassive ( errorpassive ),   //  "
      .busoff       ( busoff       ),   //  "
      .warnsig      ( warnsig      ),
      .irqsig       ( irqsig       )    //  "
  );

  rec2 rec_count ( 
      .reset     ( resetsig     ),
      .clock     ( clock        ),
      .inconerec ( inconerec    ),
      .incegtrec ( incegtrec    ),
      .decrec    ( decrec       ),
      .rec_lt96  ( rec_lt96_i   ),
      .rec_ge96  ( rec_ge96_i   ),
      .rec_ge128 ( rec_ge128_i  ),
      .reccount  ( recfce       )
  );
      
  tec2 tec_count (
      .reset     ( resetsig     ),
      .clock     ( clock        ),
      .incegttra ( incegttra    ),
      .dectra    ( dectra       ),
      .tec_lt96  ( tec_lt96_i   ),
      .tec_ge96  ( tec_ge96_i   ),
      .tec_ge128 ( tec_ge128_i  ),
      .tec_ge256 ( tec_ge256_i  ),
      .teccount  ( tecfce       )
  );
      
  erbcount2 erb_count (
      .clock     ( clock        ),
      .reset     ( resetsig     ),
      .elevrecb  ( elevrecb     ),
      .erb_eq128 ( erb_eq128_i  )
  );

endmodule

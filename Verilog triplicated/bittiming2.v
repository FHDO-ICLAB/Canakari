////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : bittiming2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Timing Control
// Commentary   : rein Struktur, Verbindungen der Komponenten
//                tseg_reg ist zwischen sum und Bittime-FSM, speichert, oder wird mit
//                tseg1pcount geladen, oder tseg1psjw.
//                edgepuffer: speichert einen takt lang das gesampelte bit (f�r flanken), das
//                zeitverz�gerte (signal puffer) in FSM und smpldbit_reg (neu), dort
//                �bernahme, und ausgabe auf port smpldbit zum MAC
//                Struktur: (Instanz, Komponente)
//                tseg_reg_i : tseg_reg : Latch f�r ver�ndertes tseg (aus FSM raus)
//                smpldbit_reg_i: smpldbit_reg: Latch f�r smpldbit, kann mit puffer geladen wrd
//                flipflop: edgepuffer: Zeitverz�gertes smpldbit
//                counter: timecount: Grundeinheitenz�hler
//                arithmetic: sum: Addi.- Subs. von Z�hlerstand, sjw- Berechnung
//                bittiming: bittime: Zustandsmaschine
//                DW 2005.06.21 Prescale Enable eingef�gt            
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 15.01.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module bittiming2 (
 input wire clock,         // 10 MHz
 input wire Prescale_EN,   // DW 2005.06.21 Prescale Enable
 input wire reset,
 input wire hardsync,      // von MACFSM
 input wire rx,            // von aussen
 input wire [2:0] tseg1,   // 5(6) Generalregister
 input wire [2:0] tseg2,   // 4(5)        "
 input wire [2:0] sjw,     //             "
 output wire sendpoint,     // zu MACFSM
 output wire smplpoint,     //     "
 output wire smpledbit,     // zu MAC- destuffing, biterrordetect
 output wire [6:0] bitst   // DW: zum debuggen
 );	
 
//tmrg default triplicate
//tmrg tmr_error false 

 // (Komponenten-Deklaration entfaellt in Verilog) 

 wire [4:0] tseg1pcount; 
 wire [4:0] tseg1p1psjw;        
 wire       notnull;            
 wire       gtsjwp1;            
 wire       gttseg1p1;          
 wire       cpsgetseg1ptseg2p2; 
 wire       cetseg1ptseg2p1;    
 wire       countesmpltime;     
 wire       puffer;             
 wire [4:0] tseg1mpl;           
 wire       increment;          
 wire       setctzero;          
 wire       setctotwo;          
 wire [3:0] count;              
 wire [1:0] smpldbit_reg_ctrl;  
 wire [1:0] tseg_reg_ctrl;  
 wire [2:0] deblatch; 

 reg        rxf;
 
 //triplication signals
 wire rxfVoted = rxf;

 // purpose: filter out setup time violation for FSM
 // type   : sequential
 // inputs : clock, reset, rx
 // outputs: rxf
 
 always @(posedge clock, negedge reset)    // (Process cleanupRX) // Das hat Tobi eingefuegt
 begin
  if (reset == 1'b0)                       // asynchronous reset (active low)
    rxf <= 1'b1;
  else 
    rxf <= rx;
 end
 
 assign deblatch [0]   = Prescale_EN;
 assign deblatch [2:1] = tseg_reg_ctrl;
 assign bitst    [6:4] = deblatch;
 
 
 bittime2 bittiming (
  .clock              ( clock              ), // input // DW 2005.06.21 Prescale Enable
  .Prescale_EN        ( Prescale_EN        ), // input // DW 2005.06.21 Prescale Enable
  .reset              ( reset              ), // input
  .hardsync           ( hardsync           ), // input
  .notnull            ( notnull            ), // input
  .gtsjwp1            ( gtsjwp1            ), // input
  .gttseg1p1          ( gttseg1p1          ), // input
  .cpsgetseg1ptseg2p2 ( cpsgetseg1ptseg2p2 ), // input
  .cetseg1ptseg2p1    ( cetseg1ptseg2p1    ), // input
  .countesmpltime     ( countesmpltime     ), // input
  .puffer             ( puffer             ), // input
  .rx                 ( rxfVoted           ), // input
  .increment          ( increment          ), // output
  .setctzero          ( setctzero          ), // output
  .setctotwo          ( setctotwo          ), // output
  .sendpoint          ( sendpoint          ), // output
  .smplpoint          ( smplpoint          ), // output
  .smpldbit_reg_ctrl  ( smpldbit_reg_ctrl  ), // output [1:0]
  .tseg_reg_ctrl      ( tseg_reg_ctrl      ), // output [1:0]
  .bitst              ( bitst[3:0]         )  // output [3:0]
  );            
   
 sum2 aritmetic (
  .count              ( count              ), // input [3:0]
  .tseg1org           ( tseg1              ), // input [2:0]
  .tseg1mpl           ( tseg1mpl           ), // input [4:0]
  .tseg2              ( tseg2              ), // input [2:0]
  .sjw                ( sjw                ), // input [2:0]
  .notnull            ( notnull            ), // output
  .gtsjwp1            ( gtsjwp1            ), // output
  .gttseg1p1          ( gttseg1p1          ), // output
  .cpsgetseg1ptseg2p2 ( cpsgetseg1ptseg2p2 ), // output
  .cetseg1ptseg2p1    ( cetseg1ptseg2p1    ), // output
  .countesmpltime     ( countesmpltime     ), // output
  .tseg1p1psjw        ( tseg1p1psjw        ), // output [4:0]
  .tseg1pcount        ( tseg1pcount        )  // output [4:0]
  );
  
 timecount2 counter (
  .clock       ( clock       ), // input  // DW 2005.06.21 Prescale Enable
  .Prescale_EN ( Prescale_EN ), // input  // DW 2005.06.21 Prescale Enable
  .reset       ( reset       ), // input
  .increment   ( increment   ), // input
  .setctzero   ( setctzero   ), // input
  .setctotwo   ( setctotwo   ), // input
  .counto      ( count       )  // output [3:0]
  );
   
 edgepuffer2 flipflop (
  .clock       ( clock       ), // input  // DW 2005.06.21 Prescale Enable
  .Prescale_EN ( Prescale_EN ), // input  // DW 2005.06.21 Prescale Enable
  .reset       ( reset       ), // input
  .rx          ( rxfVoted    ), // input
  .puffer      ( puffer      )  // output
  );

 smpldbit_reg2 smpldbit_reg_i (
  .clock    ( clock             ), // input
  .reset    ( reset             ), // input
  .ctrl     ( smpldbit_reg_ctrl ), // input [1:0]
  .smpldbit ( smpledbit         ), // output
  .puffer   ( puffer            )  // input
  );
  
 tseg_reg2 tseg_reg_i (
  .clock       ( clock         ), // input	
  .reset       ( reset         ), // input   
  .ctrl        ( tseg_reg_ctrl ), // input [1:0]
  .tseg1       ( tseg1         ), // input [2:0]
  .tseg1pcount ( tseg1pcount   ), // input [4:0]
  .tseg1p1psjw ( tseg1p1psjw   ), // input [4:0]
  .tseg1mpl    ( tseg1mpl      )  // output [4:0]
 );

endmodule


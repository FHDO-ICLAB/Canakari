////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : iocpu2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : CPU Interface Control
// Commentary   : Alle Registereingänge für CPU über regbus zusammengeschaltet, write_demux 
//                erzeugt aus adresse das entsprechende schreibsignal (activate). Zum Auslesen
//                Multiplexer schaltet direkt auf Datenbus.
//                Änderungen Avalon Busprotokoll, FSM weg.
//                Struktur:
//                rdata78: recregister: Empfangene Datenbytes 7,8
//                rdata56: recregister: Empfangene Datenbytes 5,6
//                rdata34: recregister: Empfangene Datenbytes 3,4
//                rdata12: recregister: Empfangene Datenbytes 1,2
//                rarbit2: recarbitreg: Akzeptanzfilterung ID 28..13
//                rarbit1: recarbitreg: Akzeptanzfilterung ID 12..0
//                mcontrol: recmescontrolreg: receiv message control register
//                tdata78: transmitreg: Zu sendende Datenbytes 7,8
//                tdata56: transmitreg: Zu sendende Datenbytes 5,6
//                tdata34: transmitreg: Zu sendende Datenbytes 3,4
//                tdata12: transmitreg: Zu sendende Datenbytes 1,2
//                tarbit2: transmitreg: Sende ID 28..13
//                tarbit1: transmitreg: Sende ID 12..0
//                tcontrol: transmesconreg: transmit message control register
//                general: generalregister
//                komplexe: multiplexer: CONFIGURATION multiplexer (multiplexer_top.vhdl)
//                prescaleregister: prescalereg: High und Low Werte für Vorteiler
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 28.05.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 18.06.2019 | corrected floating signal error on recidin2[2:0]
// -------------------------------------------------------------------------------------------------
// 0.92    | Leduc              | 04.07.2019 | deleted fehlercountreg2 and added assign fehlregout
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module iocpu2( 
   input  wire clock,
   input  wire reset,
   input  wire [4:0]  address,     // aussen
   output wire [15:0] readdata,    // aussen
   input  wire [15:0] writedata,   // aussen
   input  wire read_n,             // aussen
   input  wire write_n,            // aussen
   input  wire cs,                 // aussen
   input  wire activgreg,          // llc activates general register
   input  wire activtreg,          // llc activates transmission register
   input  wire activrreg,          // llc activates reception register
   input  wire activintreg,        // llc activates interrupt register
   input  wire ldrecid,            // llc activates receive id
   input  wire sucftrani,          // llc sets the suctran bit in the gen. and tcon.  register
   input  wire sucfrecvi,          // llc sets the sucrecv bit in the general register
   input  wire overflowo,          // llc sets the overflow bit in the reception register
   input  wire erroractive,        // fce
   input  wire errorpassive,       // fce
   input  wire busoff,             // fce
   input  wire warning,            // fce
   input  wire irqstatus,          // irqstatusc von IU an iocpu
   input  wire irqsuctra,          // irqsuctrac von IU an iocpu
   input  wire irqsucrec,          // irqsuctrac von IU an iocpu
   input  wire [28:0] rec_id,      // MAC, received id, for promiscous mode(i.e. ACC.MASK="000...000")
   input  wire rremote,            // MAC    
   input  wire [3:0] rdlc,         // MAC
   input  wire [7:0] data1r,       // MAC
   input  wire [7:0] data2r,       // MAC
   input  wire [7:0] data3r,       // MAC
   input  wire [7:0] data4r,       // MAC
   input  wire [7:0] data5r,       // MAC
   input  wire [7:0] data6r,       // MAC
   input  wire [7:0] data7r,       // MAC
   input  wire [7:0] data8r,       // MAC
   input  wire [7:0] teccan,       
   input  wire [7:0] reccan,       
   output wire [2:0] sjw,          // generalregister
   output wire [2:0] tseg1,         // generalregister
   output wire [2:0] tseg2,        // generalregister
   output wire sucfrecvo,          // genregr informs llc sucessfull reception bit
   output wire sucftrano,          // genregr informs llc succesfull transmission bit
   output wire initreqr,           // genregr informs llc reset/init bit;
   output wire traregbit,          // genregr informs llc transmission indic bit
   output wire [28:0] accmask,     // Acceptance Mask Register
   output wire [28:0] ridentifier, // llc, equal_id
   output wire rextended,          // llc, equal_id
   output wire [2:0] ienable,      // Interruptenablevector for IU
   output wire [2:0] irqstd,       // Interruptstdvector for IU
   output wire [28:0]tidentifier,  // MAC, encapsulation 
   output wire [7:0] data1t,       // MAC, transshift
   output wire [7:0] data2t,       // MAC, transshift
   output wire [7:0] data3t,       // MAC, transshift
   output wire [7:0] data4t,       // MAC, transshift
   output wire [7:0] data5t,       // MAC, transshift
   output wire [7:0] data6t,       // MAC, transshift
   output wire [7:0] data7t,       // MAC, transshift
   output wire [7:0] data8t,       // MAC, transshift
   output wire textended,          // MAC, encapsulation
   output wire tremote,            // MAC, encapsulation
   output wire [3:0] tdlc,         // MAC, encapsulation
   output wire [7:0] prescale_out, // prescaler
   output wire onoffn
   );

parameter [15:0] system_id = 16'hCA05; // HW-ID

wire [15:0] preregr;    // prescale register
wire [15:0] genregr;    // general register
wire [15:0] intregr;    // interrupt register
wire [15:0] traconr;    // transmit message control register
wire [15:0] traar1r;    // arbitration Bits 28 - 13
wire [15:0] traar2r;    // arbitration Bits 12 - 0 
wire [15:0] trad01r;    // data0 + data1
wire [15:0] trad23r;    // data2 + data3
wire [15:0] trad45r;    // data4 + data5
wire [15:0] trad67r;    // data6 + data7
wire [15:0] recconr;    // receive message control register
wire [15:0] recar1r;    // arbitration Bits 28 - 13
wire [15:0] recar2r;    // arbitration Bits 12 - 0 
wire [15:0] accmask1r;  // Acceptance Bits 28 - 13 
wire [15:0] accmask2r;  // Acceptance Bits 12 - 0 
wire [15:0] recd01r;    // data0 + data1
wire [15:0] recd23r;    // data2 + data3
wire [15:0] recd45r;    // data4 + data5
wire [15:0] recd67r;    // data6 + data7
wire [15:0] fehlregout;   
//wire [15:0] fehlregr;
     
// datenbus für alle register; die von der CPU beschrieben werden können
wire [15:0] register_bus; 

// Aktivier Register; wenn cpu schreibt
wire presca;
wire genrega;  // activate general register
wire intrega;  // activate interrupt register
wire tracona;  // activate transmit message control register
wire traar1a;  // activate arbitration Bits 28 - 13
wire traar2a;  // activate arbitration Bits 12 - 0 + 3 Bits reserved
wire trad01a;  // activate data0 + data1
wire trad23a;  // activate data2 + data3
wire trad45a;  // activate data4 + data5
wire trad67a;  // activate data6 + data7
wire reccona;  // activate receive message control register
wire recar1a;  // activate arbitration Bits 28 - 13w
wire recar2a;  // activate arbitration Bits 12 - 0 + 3 Bits reserved
wire [15:0] recidin1; 
wire [15:0] recidin2; 
wire accmask1a;  // activate acceptance mask register
wire accmask2a;  // activate acceptance mask register


// Kombinatorische Zuweisungen 

assign prescale_out = preregr [7:0];
                                 
assign sjw       = genregr[8:6];
assign tseg1     = genregr[5:3];
assign tseg2     = genregr[2:0];
assign sucfrecvo = genregr[10];
assign sucftrano = genregr[11];
assign initreqr  = genregr[9];

assign traregbit = traconr[15];
assign textended = traconr[4];
assign tremote   = traconr[5];
assign tdlc      = traconr[3:0];    

assign tidentifier[28:13] = traar1r;  // MAC
assign tidentifier[12:0]  = traar2r[15 : 3];

assign data1t = trad01r[15:8];     // MAC
assign data2t = trad01r[ 7:0];
assign data3t = trad23r[15:8];     // MAC
assign data4t = trad23r[ 7:0];
assign data5t = trad45r[15:8];
assign data6t = trad45r[ 7:0];
assign data7t = trad67r[15:8];
assign data8t = trad67r[ 7:0];

assign rextended  = recconr[4];
// assign promiscous = recconr[13];       // outbit Promiscous Mode (zu llc)   
 
assign recidin1         = rec_id[28:13];           // von MAC, schreiben
assign recidin2[15 : 0] = {rec_id[12: 0],3'b000};  // von Mac, schreiben   

assign ridentifier[28:13] = recar1r;          // zu llc
assign ridentifier[12: 0] = recar2r[15: 3];   // zu llc   

assign accmask[28:13] = accmask1r;            // zu llc
assign accmask[12: 0] = accmask2r[15 : 3];    // zu llc   

assign onoffn       = intregr[15];
assign ienable      = intregr[6:4];
assign irqstd       = intregr[2:0];   

//assign fehlregout   = fehlregr[15:0];

assign fehlregout     = {teccan, reccan}; 

multiplexer2 #(
       .system_id  ( system_id    ))    // HW-ID Prameter
      komplexe (
       .readdata   ( readdata     ), 
//     .clock      ( clock        ), 
       .writedata  ( writedata    ), 
       .address    ( address      ), 
       .cs         ( cs           ), 
       .read_n     ( read_n       ), 
       .write_n    ( write_n      ), 
       .preregr    ( preregr      ),    // prescale register
       .genregr    ( genregr      ),    // general register
       .intregr    ( intregr      ),    // general register
       .traconr    ( traconr      ),    // transmit message control register
       .traar1r    ( traar1r      ),    // arbitration Bits 28 - 13
       .traar2r    ( traar2r      ),    // arbitration Bits 12 - 0 
       .trad01r    ( trad01r      ),    // data0 + data1
       .trad23r    ( trad23r      ),    // data2 + data3
       .trad45r    ( trad45r      ),    // data4 + data5
       .trad67r    ( trad67r      ),    // data6 + data7
       .recconr    ( recconr      ),    // receive message control register
       .accmask1r  ( accmask1r    ),    // acceptance mask register
       .accmask2r  ( accmask2r    ),    // acceptance mask register
       .recar1r    ( recar1r      ),    // arbitration Bits 28 - 13
       .recar2r    ( recar2r      ),    // arbitration Bits 12 - 0 
       .recd01r    ( recd01r      ),    // data0 + data1
       .recd23r    ( recd23r      ),    // data2 + data3
       .recd45r    ( recd45r      ),    // data4 + data5
       .recd67r    ( recd67r      ),    // data6 + data7
       .fehlregr   ( fehlregout   ), 
       .regbus     ( register_bus ), 
       .presca     ( presca       ), 
       .genrega    ( genrega      ),    // activate general register
       .intrega    ( intrega      ), 
       .tracona    ( tracona      ),    // activate transmit message control register
       .traar1a    ( traar1a      ),    // activate arbitration Bits 28 - 13
       .traar2a    ( traar2a      ),    // activate arbitration Bits 12 - 0 + 3 Bits reserved
       .trad01a    ( trad01a      ),    // activate data0 + data1
       .trad23a    ( trad23a      ),    // activate data2 + data3
       .trad45a    ( trad45a      ),    // activate data4 + data5
       .trad67a    ( trad67a      ),    // activate data6 + data7
       .reccona    ( reccona      ),    // activate receive message control register
       .recar1a    ( recar1a      ),    // activate arbitration Bits 28 - 13w
       .recar2a    ( recar2a      ),    // activate arbitration Bits 12 - 0 + 3 Bits reserved
       .accmask1a  ( accmask1a    ), 
       .accmask2a  ( accmask2a    ) 
    );
    
    
  generalregister2 general(
         .clk       ( clock             ),
         .rst       ( reset             ),
         .cpu       ( genrega           ),      // CPU wuenscht Zugriff
         .can       ( activgreg         ),      // controller wuenscht Zugriff
         .bof       ( busoff            ),      // bus off
         .era       ( erroractive       ),      // error activ
         .erp       ( errorpassive      ),      // error passive
         .war       ( warning           ),      // warning error count level
         .sjw       ( register_bus[8:6] ),
         .tseg1     ( register_bus[5:3] ),
         .tseg2     ( register_bus[2:0] ),
         .ssp       ( register_bus[11]  ),      // succesfull send processor
         .srp       ( register_bus[10]  ),      // succesfull received processor
         .ssc       ( sucftrani         ),      // succesfull send can
         .src       ( sucfrecvi         ),      // succesfull received can
         .rsp       ( register_bus[9]   ),      // reset/initialization processor
         .register  ( genregr           )       // generalregister
  );
    
  recmescontrolreg2 mcontrol(
     .clk   ( clock             ),
     .rst   ( reset             ),
     .cpu   ( reccona           ),                  // CPU wuenscht Zugriff
     .can   ( activrreg         ),                  // controller wuenscht Zugriff
     .ofp   ( register_bus[15]  ),                  // overflow indication processor
     .ofc   ( overflowo         ),                  // overflow indication can
     .rip   ( register_bus[14]  ),                  // receive indication processor
     .ric   ( activrreg         ),                  // receive indication can
     .ien   ( register_bus[8]   ),                  // interrupt enable
     .rtr   ( rremote           ),                  // remote flag
     .ext   ( register_bus[4]   ),                  // extended flag
 //  .      ( register_bus[13]  ),                  // Promiscous Mode von cpu anschalten
     .dlc   ( rdlc              ),                  // data length code
     .regout( recconr           )
  );   
  
  recarbitreg2 rarbit1(
     .clk     ( clock         ),
     .rst     ( reset         ),
     .cpu     ( recar1a       ),                      // CPU wuenscht Zugriff
     .can     ( ldrecid       ),
     .reginp  ( register_bus  ),                      // Ausgang
     .recidin ( recidin1      ),
     .regout  ( recar1r       )
  );
     
   recarbitreg2 rarbit2(
     .clk     ( clock         ),
     .rst     ( reset         ),
     .cpu     ( recar2a       ),                      // CPU wuenscht Zugriff
     .can     ( ldrecid       ),                      // LLC  schreibt im Prom. Mode Id
     .reginp  ( register_bus  ),                      // Ausgang
     .recidin ( recidin2      ),
     .regout  ( recar2r       )
  ); 
  
  accmaskreg2 accmask1(
     .clk     ( clock         ),
     .rst     ( reset         ),
     .cpu     ( accmask1a     ),                      // CPU wuenscht Zugriff
     .reginp  ( register_bus  ),                      // Ausgang
     .regout  ( accmask1r     )
  );
  
  accmaskreg2 accmask2(
     .clk     ( clock         ),
     .rst     ( reset         ),
     .cpu     ( accmask2a     ),                      // CPU wuenscht Zugriff
     .reginp  ( register_bus  ),                      // Ausgang
     .regout  ( accmask2r     )
  );
   
  interrupregister2 interruptreg(
      .clk        ( clock            ),
      .rst        ( reset            ),
      .cpu        ( intrega          ),                     // CPU wuenscht Zugriff
      .can        ( activintreg      ),                     // controller wuenscht Zugriff
      .onoffnin   ( register_bus[15] ),                     // iestatusp
      .iestatusp  ( register_bus[6]  ),                     // iestatusp
      .iesuctrap  ( register_bus[5]  ),                     // iesuctrap
      .iesucrecp  ( register_bus[4]  ),                     // iesucrecp
      .irqstatusp ( register_bus[2]  ),                     // irqstatusp
      .irqsuctrap ( register_bus[1]  ),                     // irqsuctrap
      .irqsucrecp ( register_bus[0]  ),                     // irqsucrecp
      .irqstatusc ( irqstatus        ),                     // irqstatusc
      .irqsuctrac ( irqsuctra        ),                     // irqsuctrac
      .irqsucrecc ( irqsucrec        ),                     // irqsucrecc
      .register   ( intregr          )                      // register 
  );
  
//  fehlercountreg2 fehlercount(
//        .clk      ( clock    ),
//        .rst      ( reset    ),      
//        .teccan   ( teccan   ),    
//        .reccan   ( reccan   ),    
//        .register ( fehlregr )
//  );
  
  
  prescalereg2 prescaleregister(
      .clk    ( clock         ),
      .rst    ( reset         ),
      .cpu    ( presca        ),
      .reginp ( register_bus  ),           // Input ist Bus
      .regout ( preregr       )            // Beer 2018_06_18: von 8 auf 16bit
      ); 
      
  recregister2 rdata12(
     .clk     ( clock     ),
     .rst     ( reset     ),
     .can     ( activrreg ),               // LLC wuenscht Zugriff
     .regin1  ( data1r    ),
     .regin2  ( data2r    ),
     .regout  ( recd01r   )
  );
  
  recregister2 rdata34(
     .clk     ( clock     ),
     .rst     ( reset     ),
     .can     ( activrreg ),               // LLC wuenscht Zugriff
     .regin1  ( data3r    ),
     .regin2  ( data4r    ),
     .regout  ( recd23r   )
  );
  
  recregister2 rdata56(
     .clk     ( clock     ),
     .rst     ( reset     ),
     .can     ( activrreg ),               // LLC wuenscht Zugriff
     .regin1  ( data5r    ),
     .regin2  ( data6r    ),
     .regout  ( recd45r   )
  );
  
  recregister2 rdata78(
     .clk     ( clock     ),
     .rst     ( reset     ),
     .can     ( activrreg ),               // LLC wuenscht Zugriff
     .regin1  ( data7r    ),
     .regin2  ( data8r    ),
     .regout  ( recd67r   )
  );
   
  transmesconreg2 tcontrol(
     .clk     ( clock         ),
     .rst     ( reset         ),
     .cpu     ( tracona       ),                      // CPU wuenscht Zugriff
     .can     ( activtreg     ),                      // controller wuenscht Zugriff
     .tsucf   ( sucftrani     ),                      // successful transmission
     .reginp  ( register_bus  ),                      // traconw
     .regout  ( traconr       )
  );
  
  transmitreg2 tarbit1(
     .clk     ( clock         ),
     .rst     ( reset         ),
     .cpu     ( traar1a       ),                      // CPU wuenscht Zugriff
     .reginp  ( register_bus  ),                      // traar1w,
     .regout  ( traar1r       )
  );
  
  transmitreg2 tarbit2(
     .clk     ( clock         ),
     .rst     ( reset         ),
     .cpu     ( traar2a       ),                      // CPU wuenscht Zugriff
     .reginp  ( register_bus  ),                      // traar1w,
     .regout  ( traar2r       )
  );  

  transmitreg2 tdata12(
     .clk     ( clock         ),
     .rst     ( reset         ),
     .cpu     ( trad01a       ),                      // CPU wuenscht Zugriff
     .reginp  ( register_bus  ),                      // traar1w,
     .regout  ( trad01r       )
  );  
  
    transmitreg2 tdata34(
     .clk     ( clock         ),
     .rst     ( reset         ),
     .cpu     ( trad23a       ),                      // CPU wuenscht Zugriff
     .reginp  ( register_bus  ),                      // traar1w,
     .regout  ( trad23r       )
  ); 
  
    transmitreg2 tdata56(
     .clk     ( clock         ),
     .rst     ( reset         ),
     .cpu     ( trad45a       ),                      // CPU wuenscht Zugriff
     .reginp  ( register_bus  ),                      // traar1w,
     .regout  ( trad45r       )
  ); 
  
    transmitreg2 tdata78(
     .clk     ( clock         ),
     .rst     ( reset         ),
     .cpu     ( trad67a       ),                      // CPU wuenscht Zugriff
     .reginp  ( register_bus  ),                      // traar1w,
     .regout  ( trad67r       )
  ); 
  
  
  
endmodule

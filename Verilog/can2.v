////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : can2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Top Level of Canakari
// Commentary   : fast nur Struktur, ein AND für resetsignal
//                prescaler:           prescale:    Entity, Vorteiler Systemtakt
//                IOControl:           iocpu:       Configuration, CPU I/O Logik, Mux, Demux
//                FaultConfinement:    fce:         Configuration, Fehler Zähler, FSM
//                TimeControl:         bittiming:   Configuration, sendpoint  und smplpoint erzeugen
//                LogicalLinkControl:  llc:         Configuration,MAC <-> IOCPU, Akzeptanzfilterung
//                MediumAccessControl: mac:         Configuration
//                reset_generator:    resetgen:     Resetsig für synchrone Registerresets
//
//                DW 2005.06.21 Prescale Enable eingefügt   
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 29.07.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 12.02.2020 | Added Changes done in Verilog Triplication Files
// -------------------------------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module can2 (
  input  wire        clock,
  input  wire        reset,
  input  wire [ 4:0] address,
  output wire [15:0] readdata,           // Avalon lesedaten
  input  wire [15:0] writedata,
  input  wire        cs,                 // Avalon Chip Select
  input  wire        read_n,             // Avalon read enable active low
  input  wire        write_n,            // Avalon write enable active low
  output wire        irq,
  output wire        irqstatus,
  output wire        irqsuctra,
  output wire        irqsucrec,
  input  wire        rx,                 // CAN-BUS
  output wire        tx,                 // CAN-BUS
  output wire [ 7:0] statedeb,
  output wire        Prescale_EN_debug,  // DW 2005.06.25 Debug Prescale
  output wire [ 6:0] bitst
  );
 
parameter [15:0] system_id = 16'hCA05; // HW-ID

// mac signals 
wire        sendpoint;        
wire        smplpoint;
wire        trans;
wire        erroractiv;
wire        errorpassiv;
wire        busof;
wire        load;
wire        actvtsftllc;
wire        actvtcap;
wire        resettra;
wire [28:0] accmaskreg_i;
wire [28:0] identifierr;
wire [ 7:0] data1r;
wire [ 7:0] data2r;
wire [ 7:0] data3r;
wire [ 7:0] data4r;
wire [ 7:0] data5r;
wire [ 7:0] data6r;
wire [ 7:0] data7r;
wire [ 7:0] data8r;
wire        extendedr;
wire        remoter;
wire [ 3:0] datalenr;
wire [28:0] identifierw;
wire [ 7:0] data1w;
wire [ 7:0] data2w;
wire [ 7:0] data3w;
wire [ 7:0] data4w;
wire [ 7:0] data5w;
wire [ 7:0] data6w;
wire [ 7:0] data7w;
wire [ 7:0] data8w;
wire        remotew;
wire [ 3:0] datalenw;
wire        inconerec;
wire        incegtrec;
wire        incegttra;
wire        decrec;
wire        dectra;
wire        elevrecb;
wire        hardsync;

// llc signals  
wire        initreqr;            
wire        traregbit;
wire        sucfrecvr;
wire        sucftranr;
wire        activtreg;
wire        activrreg;
wire        activgreg;
wire        sucftrano;
wire        sucfrecvo;
wire        overflowo;
wire        resetall;
wire        ldrecid;

// bittiming signals
wire [ 2:0] tseg1;                
wire [ 2:0] tseg2;  
wire [ 2:0] sjw;
wire        smpledbit;

// fce signals
wire        warnsig;           
wire        irqsig;

// iocpu signals
wire [28:0] ridentifier;
wire        rextended;     

// common signals
wire        resetsig;   

// prescaler
wire [ 3:0] high_i;     
wire [ 3:0] low_i;

wire [ 7:0] prescale_out;
wire        sync_reset_i;
wire        Prescale_EN;   

// Interruptunit  
wire        activintreg;  
wire [ 2:0] ienable;
wire [ 2:0] irqstd;
wire [ 7:0] tec_i;
wire [ 7:0] rec_i;
wire        switched_rx;
wire        tx_i;
wire        onoffn_i;
wire        irqstatus_internal;
wire        irqsucrec_internal;
wire        irqsuctra_internal;


// off = 0 ,  not off = 1 , X or 1 = 1= immer rezessiv
assign switched_rx        = rx    | (~ onoffn_i);
assign tx                 = tx_i  | (~ onoffn_i);  
assign resetsig           = reset & resetall;

assign high_i             = prescale_out [7:4];
assign low_i              = prescale_out [3:0];
assign Prescale_EN_debug  = Prescale_EN;
  
// Implicit buffered output assignments
assign irqstatus          = irqstatus_internal;
assign irqsucrec          = irqsucrec_internal;
assign irqsuctra          = irqsuctra_internal;


resetgen2 reset_generator(
    .reset      ( resetsig      ),
    .sync_reset ( sync_reset_i  ),
    .clock      ( clock         )
    );

mac2 MediumAccessControl(
   .clock       ( clock        ),

   .Prescale_EN ( Prescale_EN  ),   // DW 2005.06.21 Prescale Enable eingefügt
   .reset       ( sync_reset_i ),
   .sendpoint   ( sendpoint    ),
   .smplpoint   ( smplpoint    ),
   .inbit       ( smpledbit    ),
   .trans       ( trans        ),
   .erroractiv  ( erroractiv   ),
   .errorpassiv ( errorpassiv  ),
   .busof       ( busof        ),
   .load        ( load         ),
   .actvtsftllc ( actvtsftllc  ),
   .actvtcap    ( actvtcap     ),
   .resettra    ( resettra     ),
   .identifierr ( identifierr  ),
   .data1r      ( data1r       ),
   .data2r      ( data2r       ),
   .data3r      ( data3r       ),
   .data4r      ( data4r       ),
   .data5r      ( data5r       ),
   .data6r      ( data6r       ),
   .data7r      ( data7r       ),
   .data8r      ( data8r       ),
   .extendedr   ( extendedr    ),
   .remoter     ( remoter      ),
   .datalenr    ( datalenr     ),
   .identifierw ( identifierw  ),
   .data1w      ( data1w       ),
   .data2w      ( data2w       ),
   .data3w      ( data3w       ),
   .data4w      ( data4w       ),
   .data5w      ( data5w       ),
   .data6w      ( data6w       ),
   .data7w      ( data7w       ),
   .data8w      ( data8w       ),
   .remotew     ( remotew      ),
   .datalenw    ( datalenw     ),
   .inconerec   ( inconerec    ),
   .incegtrec   ( incegtrec    ),
   .incegttra   ( incegttra    ),
   .decrec      ( decrec       ),
   .dectra      ( dectra       ),
   .elevrecb    ( elevrecb     ),
   .hardsync    ( hardsync     ),
   .outbit      ( tx_i         ),
   .statedeb    ( statedeb     )
   );


llc2 LogicalLinkControl( 
   .clock      ( clock         ),
   .reset      ( sync_reset_i  ),
   .initreqr   ( initreqr      ),
   .traregbit  ( traregbit     ),
   .sucfrecvc  ( decrec        ),
   .sucftranc  ( dectra        ),
   .sucfrecvr  ( sucfrecvr     ),
   .sucftranr  ( sucftranr     ),
   .extended   ( rextended     ),
   .accmaskreg ( accmaskreg_i  ),
   .idreg      ( ridentifier   ),
   .idrec      ( identifierw   ),
   .activtreg  ( activtreg     ),
   .activrreg  ( activrreg     ),
   .activgreg  ( activgreg     ),
   .ldrecid    ( ldrecid       ),
   .sucftrano  ( sucftrano     ),
   .sucfrecvo  ( sucfrecvo     ),
   .overflowo  ( overflowo     ),
   .trans      ( trans         ),
   .load       ( load          ),
   .actvtsft   ( actvtsftllc   ),
   .actvtcap   ( actvtcap      ),
   .resettra   ( resettra      ),
   .resetall   ( resetall      )
		 );

bittiming2 TimeControl( 
  .clock       ( clock       ),

  .Prescale_EN ( Prescale_EN ),      // DW 2005.06.21
  .reset       ( resetsig    ),
  .hardsync    ( hardsync    ),
  .rx          ( switched_rx ),
  .tseg1       ( tseg1       ),
  .tseg2       ( tseg2       ),
  .sjw         ( sjw         ),
  .sendpoint   ( sendpoint   ),
  .smplpoint   ( smplpoint   ),
  .smpledbit   ( smpledbit   ),
  .bitst       ( bitst       )
	);

fce2 FaultConfinement( 
   .clock        ( clock         ),
   .reset        ( sync_reset_i  ),
   .inconerec    ( inconerec     ),
   .incegtrec    ( incegtrec     ),
   .incegttra    ( incegttra     ),
   .decrec       ( decrec        ),
   .dectra       ( dectra        ),
   .elevrecb     ( elevrecb      ),
   .erroractive  ( erroractiv    ),
   .errorpassive ( errorpassiv   ),
   .busoff       ( busof         ),
   .warnsig      ( warnsig       ),
   .irqsig       ( irqsig        ),
   .tecfce       ( tec_i         ),        
   .recfce       ( rec_i         )
 );

interruptunit2 irqunit(  
   .clock       ( clock               ),
   .reset       ( sync_reset_i        ),
   .ienable     ( ienable             ),
   .irqstd      ( irqstd              ),
   .irqsig      ( irqsig              ),
   .sucfrec     ( sucfrecvo           ),
   .sucftra     ( sucftrano           ),
   .activintreg ( activintreg         ),
   .irqstatus   ( irqstatus_internal  ),
   .irqsuctra   ( irqsuctra_internal  ),
   .irqsucrec   ( irqsucrec_internal  ),
   .irq         ( irq                 )
    );
    
    
iocpu2 #(  
   .system_id    ( system_id          ))
  IOControl (
   .clock        ( clock              ),
   .reset        ( sync_reset_i       ),
   .address      ( address            ),
   .readdata     ( readdata           ),
   .writedata    ( writedata          ),
   .read_n       ( read_n             ),
   .write_n      ( write_n            ),
   .cs           ( cs                 ),
   .activgreg    ( activgreg          ),
   .activtreg    ( activtreg          ),
   .activrreg    ( activrreg          ),
   .activintreg  ( activintreg        ),
   .ldrecid      ( ldrecid            ),
   .sucftrani    ( sucftrano          ),
   .sucfrecvi    ( sucfrecvo          ),
   .overflowo    ( overflowo          ),
   .erroractive  ( erroractiv         ),
   .errorpassive ( errorpassiv        ),
   .busoff       ( busof              ),
   .warning      ( warnsig            ),
   .irqstatus    ( irqstatus_internal ),
   .irqsuctra    ( irqsuctra_internal ),
   .irqsucrec    ( irqsucrec_internal ),
   .rec_id       ( identifierw        ),
   .rremote      ( remotew            ),
   .rdlc         ( datalenw           ),
   .data1r       ( data1w             ),
   .data2r       ( data2w             ),
   .data3r       ( data3w             ),
   .data4r       ( data4w             ),
   .data5r       ( data5w             ),
   .data6r       ( data6w             ),
   .data7r       ( data7w             ),
   .data8r       ( data8w             ),
   .teccan       ( tec_i              ),
   .reccan       ( rec_i              ),
   .sjw          ( sjw                ),
   .tseg1        ( tseg1              ),
   .tseg2        ( tseg2              ),
   .sucfrecvo    ( sucfrecvr          ),
   .sucftrano    ( sucftranr          ),
   .initreqr     ( initreqr           ),
   .traregbit    ( traregbit          ),
   .accmask      ( accmaskreg_i       ),
   .ridentifier  ( ridentifier        ),
   .rextended    ( rextended          ),
   .ienable      ( ienable            ),
   .irqstd       ( irqstd             ),
   .tidentifier  ( identifierr        ),
   .data1t       ( data1r             ),
   .data2t       ( data2r             ),
   .data3t       ( data3r             ),
   .data4t       ( data4r             ),
   .data5t       ( data5r             ),
   .data6t       ( data6r             ),
   .data7t       ( data7r             ),
   .data8t       ( data8r             ),
   .textended    ( extendedr          ),
   .tremote      ( remoter            ),
   .tdlc         ( datalenr           ),
   .prescale_out ( prescale_out       ),
   .onoffn       ( onoffn_i           )
    );

prescale2 prescaler(
   .clock       ( clock       ),
   .reset       ( reset       ),
   .high        ( high_i      ),
   .low         ( low_i       ),
   .Prescale_EN ( Prescale_EN )     // DW 2005.06.21        
   );

endmodule

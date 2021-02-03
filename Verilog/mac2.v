///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : mac2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : medium access controller
// Commentary   : Strukturorientiert, bis auf einige zusammengeführte resetsignale
//                Instanz : Komponente : Aufgabe
//                reset_mac_i  : reset_mac: Erzeugt langen Resetimpuls für MAC (synchron)
//                fsm : macfsm : Zustandsmaschine
//                errordetect  : biterrordetect : Bitvergleich in/out
//                counting     : counter        : Bitpositionszähler, Signale für fsm intermission
//                decaps       : decapsulation  : ID für LLC, Register zusammenstellen (aus rshift)
//                destuff      : destuffing     : Bitstuffing Empfang, kann abgeschaltet werden
//                encaps       : encapsulation  : ID aus IOCPU für tshift zusammenstellen
//                receivecrc   : rcrc           : Empfangs CRC prüfen (Ausgang: OK,/OK)
//                recmlen      : recmeslen      : Empfangenen DLC auswerten, realen DLC (rmlb) bereitstellen       
//                recshift     : rshiftreg      : Empfangsschieberegister
//                stuff        : stuffing       : Bitstuffing senden
//                transmitcrc  : tcrc           : Sende CRC Register 
//                transhift    : tshiftreg      : Sendeschieberegister
//                fsm_regs     : fsm_register   : Aus FSM ausgelagerte Register (Synthese)
//                frshift      : fastshift      : rshift passend schieben, s. entity fastshift
//                comparator   : meslencompare  : signalisiert Steuerbitpositionen beim Empfang
//
//                DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt. 
//
// Changelog:
// ------------------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// ------------------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 09.07.2019 | created
// ------------------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 09.07.2019 | transl. combinational processes as simple assignments 
// ------------------------------------------------------------------------------------------------------------
// 0.92    | Leduc              | 12.02.2020 | Added Changes done in Verilog Triplication Files
// ------------------------------------------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module mac2(
   input  wire        clock,    // aussen
   input  wire        Prescale_EN,   // DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
   input  wire        reset,         // reset_mac
   input  wire        sendpoint,     // bittiming
   input  wire        smplpoint,     // bittiming
   input  wire        inbit,         // destuffing
   input  wire        trans,         // llc
   input  wire        erroractiv,    // fce
   input  wire        errorpassiv,   // fce
   input  wire        busof,         // fce
   input  wire        load,          // llc
   input  wire        actvtsftllc,   // llc
   input  wire        actvtcap,      // llc
   input  wire        resettra,      // llc
   input  wire [28:0] identifierr,   // IOCPU
   input  wire [ 7:0] data1r,        // IOCPU
   input  wire [ 7:0] data2r,        // IOCPU
   input  wire [ 7:0] data3r,        // IOCPU
   input  wire [ 7:0] data4r,        // IOCPU
   input  wire [ 7:0] data5r,        // IOCPU
   input  wire [ 7:0] data6r,        // IOCPU
   input  wire [ 7:0] data7r,        // IOCPU
   input  wire [ 7:0] data8r,        // IOCPU
   input  wire        extendedr,     // IOCPU
   input  wire        remoter,       // IOCPU
   input  wire [ 3:0] datalenr,      // IOCPU
   output wire [28:0] identifierw,   // IOCPU, LLC
   output wire [ 7:0] data1w,        // IOCPU
   output wire [ 7:0] data2w,        // IOCPU
   output wire [ 7:0] data3w,        // IOCPU
   output wire [ 7:0] data4w,        // IOCPU
   output wire [ 7:0] data5w,        // IOCPU
   output wire [ 7:0] data6w,        // IOCPU
   output wire [ 7:0] data7w,        // IOCPU
   output wire [ 7:0] data8w,        // IOCPU
   output wire        remotew,       // IOCPU
   output wire [ 3:0]  datalenw,     // IOCPU
   output wire        inconerec,     // fce
   output wire        incegtrec,     // fce
   output wire        incegttra,     // fce
   output wire        decrec,        // fce
   output wire        dectra,        // fce
   output wire        elevrecb,      // fce
   output wire        hardsync,      // bittiming
   output wire        outbit,      
   output wire [ 7:0] statedeb    
);

wire        stufft;    
wire        stuffr;    
wire        biterror;  
wire        stferror;  
wire [ 6:0] count;     
wire [ 3:0] rmlb;         // rmlen in Byte
wire [ 2:0] setrmleno; 
wire        actvrmln;  
// wire actvrcap;  
wire        actvtcrc;  
wire        actvrcrc;  
wire        actvtstf;  
wire        actvrstf;  
wire        actvtsft;  
wire        actvrsft;  
wire        actvtdct;  
wire        actvrdct;  
wire        actvtbed;  
wire        setbdom;   
wire        setbrec;   
wire        lcrc;      
wire        lmsg;      
wire        tshift;    
wire        inccount;  
wire        resrmlen;  
wire        rescount;  
wire        resetdst;  
wire        resetstf;  
wire        bitout; 
wire [67:0] mesout_a;     // 0...67
wire [17:0] mesout_b;     // 71..88
wire [10:0] mesout_c;     // 91..101
wire [102:0]mesin;    
wire        bittosend;   
wire        receivedbit; 
wire        actvtsftsig; 
wire        resetsig;    
wire        resetstfsig; 
wire        rescountsig; 
wire        resrmlensig; 
wire        resetdstsig; 
wire        loader; 
wire [14:0] crc_pre_load_sig_ext;   // änderung im crc
wire [14:0] crc_pre_load_sig_rem;   // änderung im crc
wire        crc_out_bit;            // aus dem tshit ins crc
wire        crc_ok;                 // statt rest (14 downto 0)
wire [ 1:0] ackerror_set_i;    
wire [ 1:0] onarbit_set_i;     
wire [ 1:0] transmitter_set_i; 
wire [ 1:0] receiver_set_i;    
wire [ 1:0] error_set_i;       
wire [ 1:0] first_set_i;       
wire [ 1:0] puffer_set_i;      
wire [ 1:0] rext_set_i;       
wire [ 1:0] rrtr_set_i;        
wire        ackerror_i;    
wire        onarbit_i;     
wire        transmitter_i; 
wire        receiver_i;    
wire        error_i;       
wire        first_i;       
wire        puffer_i;      
wire        rext;          
wire        rrtr;          
wire        rmzero;        
// wire equal19, equal39;          // ersatz für rec_data_shifting
// wire tequal19, tequal39;        // ersatz in tra_data_fsm
wire        lt3_i, gt3_i, eq3_i;   // inter_fsm : von count
wire        lt11_i, eq11_i;        //    "           "
wire        activatefast;          // neue Entitiy: Fastshift
wire        directshift;  
wire        setzero;      
wire        crc_shft_out; 
wire        crc_tosend;   
wire        stuff_inbit;  
// wire [3:0] rmlen;         
wire [ 3:0] tmlen;         
wire        startrcrc_i;   
wire        starttcrc_i;   
wire        zerointcrc_i;  
wire        en_zerointcrc; 
wire        sync_reset_i; 

// obsolete decapsulation (siehe fastshift):
// data1w..data8w und datalen kommen aus recshift
// extendedw und remotew kommen aus fsm_regs

assign remotew  = rrtr;
assign datalenw = mesout_a[67:64];
assign data1w   = mesout_a[63:56];
assign data2w   = mesout_a[55:48];
assign data3w   = mesout_a[47:40];
assign data4w   = mesout_a[39:32];
assign data5w   = mesout_a[31:24];
assign data6w   = mesout_a[23:16];
assign data7w   = mesout_a[15 : 8];
assign remotew  = rrtr;
assign datalenw = mesout_a[67:64];
assign data1w   = mesout_a[63:56];
assign data2w   = mesout_a[55:48];
assign data3w   = mesout_a[47:40];
assign data4w   = mesout_a[39:32];
assign data5w   = mesout_a[31:24];
assign data6w   = mesout_a[23:16];
assign data7w   = mesout_a[15: 8];
assign data8w   = mesout_a[ 7: 0];
assign data8w   = mesout_a[ 7: 0];


// Da Sende CRC, zum Senderegister wird, muss Stuffingjetzt aus dem CRC sein Signal bekommen, 
// Abhängige: crc_shft_out (MACFSM)
assign stuff_inbit = (crc_shft_out  & crc_tosend) | ((~crc_shft_out) & bittosend);                                                                                                                                                                                                                      
assign mesin[63:0] = {data1r, data2r, data3r, data4r, data5r, data6r, data7r, data8r};
                      
// Transmit CRC v|laden mit ext oder basic (rem???-egal) datenanfang                      
assign crc_pre_load_sig_ext = mesin[102:88];          
assign crc_pre_load_sig_rem = mesin[82:68];

assign actvtsftsig  =  actvtsft | actvtsftllc;              // actvtsft aus llc und macfsm zusammenführen
assign resetsig     = sync_reset_i & resettra;              // reset aus mac_reset und llc zusammenführen
assign resetstfsig  = sync_reset_i & resettra & resetstf;   // reset aus mac_reset und llc und mac zusammenführen
assign rescountsig  = sync_reset_i & rescount;              // reset aus mac_reset und mac zusammenführen 
assign resrmlensig  = sync_reset_i & resrmlen;              // reset aus mac_reset und mac zusammenführen
assign resetdstsig  = sync_reset_i & resetdst;              // reset aus mac_reset und mac zusammenführen
assign outbit       = bitout;                               // Ausgabe
assign loader       = load | lmsg;                          // ladesignal für tshift aus macfsm und llc zusammenführen




  reset_mac2 reset_mac_i ( 
      .reset      ( reset        ),
      .sync_reset ( sync_reset_i ),
      .clock      ( clock        ),
      .prescaler  ( Prescale_EN  )     // DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
  );

  macfsm2 fsm (  
      .clock            ( clock             ),   // DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
      .Prescale_EN      ( Prescale_EN       ),   // DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
      .reset            ( sync_reset_i      ),
      .sendpoint        ( sendpoint         ),
      .smplpoint        ( smplpoint         ),
      .crc_ok           ( crc_ok            ),
      .inbit            ( receivedbit       ),
      .stufft           ( stufft            ),
      .stuffr           ( stuffr            ),
      .biterror         ( biterror          ),
      .stferror         ( stferror          ),
      .trans            ( trans             ),
      .text             ( extendedr         ),
      .erroractiv       ( erroractiv        ),
      .errorpassiv      ( errorpassiv       ),
      .busof            ( busof             ),
      .ackerror         ( ackerror_i        ),
      .onarbit          ( onarbit_i         ),
      .transmitter      ( transmitter_i     ),
      .receiver         ( receiver_i        ),
      .error            ( error_i           ),
      .first            ( first_i           ),
      .puffer           ( puffer_i          ),
      .rext             ( rext              ),
      .rrtr             ( rrtr              ),
      .startrcrc        ( startrcrc_i       ),
      .rmzero           ( rmzero            ),
      .starttcrc        ( starttcrc_i       ),
      .lt3              ( lt3_i             ),
      .gt3              ( gt3_i             ),
      .eq3              ( eq3_i             ),
      .lt11             ( lt11_i            ),
      .eq11             ( eq11_i            ),
      .ackerror_set     ( ackerror_set_i    ),
      .onarbit_set      ( onarbit_set_i     ),
      .transmitter_set  ( transmitter_set_i ),
      .receiver_set     ( receiver_set_i    ),
      .error_set        ( error_set_i       ),
      .first_set        ( first_set_i       ),
      .puffer_set       ( puffer_set_i      ),
      .rext_set         ( rext_set_i        ),
      .rrtr_set         ( rrtr_set_i        ),
      .count            ( count             ),
      .setrmleno        ( setrmleno         ),
      .actvrmln         ( actvrmln          ),
      .actvtcrc         ( actvtcrc          ),
      .actvrcrc         ( actvrcrc          ),
      .actvtstf         ( actvtstf          ),
      .actvrstf         ( actvrstf          ),
      .actvtsft         ( actvtsft          ),
      .actvrsft         ( actvrsft          ),
      .actvtdct         ( actvtdct          ),
      .actvrdct         ( actvrdct          ),
      .actvtbed         ( actvtbed          ),
      .setbdom          ( setbdom           ),
      .setbrec          ( setbrec           ),
      .lcrc             ( lcrc              ),
      .lmsg             ( lmsg              ),
      .tshift           ( tshift            ),
      .inconerec        ( inconerec         ),
      .incegtrec        ( incegtrec         ),
      .incegttra        ( incegttra         ),
      .decrec           ( decrec            ),
      .dectra           ( dectra            ),
      .elevrecb         ( elevrecb          ),
      .hardsync         ( hardsync          ),
      .inccount         ( inccount          ),
      .resrmlen         ( resrmlen          ),
      .rescount         ( rescount          ),
      .resetdst         ( resetdst          ),
      .resetstf         ( resetstf          ),
      .activatefast     ( activatefast      ),
      .crc_shft_out     ( crc_shft_out      ),
      .en_zerointcrc    ( en_zerointcrc     ),
      .statedeb         ( statedeb          )
  );


  biterrordetect2 errordetect (  
     .clock     ( clock        ),
     .bitin     ( inbit        ),
     .bitout    ( bitout       ),
     .activ     ( actvtbed     ),
     .reset     ( sync_reset_i ),
     .biterror  ( biterror     )
  );

  counter2 counting (    
      .clock       ( clock        ),    // DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
      .Prescale_EN ( Prescale_EN  ),    // DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
      .inc         ( inccount     ),
      .reset       ( rescountsig  ),
      .lt3         ( lt3_i        ),
      .gt3         ( gt3_i        ),
      .eq3         ( eq3_i        ),
      .lt11        ( lt11_i       ),
      .eq11        ( eq11_i       ),
      .counto      ( count        )
  );

  decapsulation2 decaps (   
      .message_b  ( mesout_b    ),
      .message_c  ( mesout_c    ),
      .extended   ( rext        ),
      .identifier ( identifierw )  
  );

  destuffing2 destuff (  
     .clock   ( clock       ),
     .bitin   ( inbit       ),
     .activ   ( actvrstf    ),
     .reset   ( resetdstsig ),
     .direct  ( actvrdct    ),
     .stfer   ( stferror    ),
     .stuff   ( stuffr      ),
     .bitout  ( receivedbit )
  );
  

  encapsulation2 encaps (  
     .clock      ( clock         ),
     .identifier ( identifierr   ),
     .extended   ( extendedr     ),
     .remote     (  remoter      ),
     .activ      (  actvtcap     ),
     .reset      (  resetsig     ),
     .datalen    (  datalenr     ),
     .tmlen      (  tmlen        ),
     .message    ( mesin[102:64] )      // nur der Id Teil
  );             



  rcrc2 receivecrc (  
     .clock  ( clock        ),
     .bitin  ( receivedbit  ),
     .activ  ( actvrcrc     ),
     .reset  ( resrmlensig  ),
     .crc_ok ( crc_ok       )
  );

  recmeslen2 recmlen (  
     .clock    ( clock       ),
     .activ    ( actvrmln    ),
     .reset    ( resrmlensig ),
     .setrmlen ( setrmleno   ),
     .rmlb     (  rmlb       )
  );

  rshiftreg2 recshift (  
     .clock         (  clock        ),
     .bitin         ( receivedbit   ),
     .activ         (  actvrsft     ),
     .reset         ( sync_reset_i  ),
     .lcrc          ( lcrc          ),   //siehe component rshiftreg
     .setzero       ( setzero       ),
     .directshift   ( directshift   ),
     .mesout_a      ( mesout_a      ),
     .mesout_b      ( mesout_b      ),
     .mesout_c      ( mesout_c      )
  );

  stuffing2 stuff (  
     .clock  ( clock        ),
     .bitin  (  stuff_inbit ),
     .activ  ( actvtstf     ),
     .reset  ( resetstfsig  ),
     .direct ( actvtdct     ),
     .setdom ( setbdom      ),
     .setrec ( setbrec      ),
     .bitout ( bitout       ),
     .stuff  (  stufft      )
  );

  tcrc2 transmitcrc (  
     .clock            ( clock                ),
     .bitin            ( crc_out_bit          ),
     .activ            ( actvtcrc             ),
     .reset            ( resetsig             ),
     .crc_pre_load_ext ( crc_pre_load_sig_ext ),
     .crc_pre_load_rem ( crc_pre_load_sig_rem ),
     .extended         ( extendedr            ),
     .load             ( loader               ),
     .load_activ       ( actvtsftsig          ),
     .crc_shft_out     ( crc_shft_out         ),
     .zerointcrc       ( zerointcrc_i         ),
     .crc_tosend       ( crc_tosend           )
  );

  tshiftreg2 transhift (  
     .clock       ( clock       ),
     .mesin       ( mesin       ),
     .activ       ( actvtsftsig ),
     .reset       ( resetsig    ),
     .load        ( loader      ),
     .shift       ( tshift      ),
     .extended    ( extendedr   ),
     .bitout      ( bittosend   ),
     .crc_out_bit ( crc_out_bit )
  );

  fsm_register2 fsm_regs (  
      .clock              ( clock           ),
      .reset              ( sync_reset_i    ),
      .ackerror_set     ( ackerror_set_i    ),
      .onarbit_set      ( onarbit_set_i     ),
      .transmitter_set  ( transmitter_set_i ),
      .receiver_set     ( receiver_set_i    ),
      .error_set        ( error_set_i       ),
      .first_set        ( first_set_i       ),
      .puffer_set       ( puffer_set_i      ),
      .rext_set         ( rext_set_i        ),
      .rrtr_set         ( rrtr_set_i        ),
      .ackerror         ( ackerror_i        ),
      .onarbit          ( onarbit_i         ),
      .transmitter      ( transmitter_i     ),
      .receiver         ( receiver_i        ),
      .error            ( error_i           ),
      .first            ( first_i           ),
      .puffer           ( puffer_i          ),
      .rext             ( rext            ),
      .rrtr             ( rrtr            )
  );

  fastshift2 frshift (     
      .reset       ( resrmlensig  ),
      .clock       ( clock        ),
      .activate    ( activatefast ),
      .rmlb        ( rmlb         ),
      .setzero     ( setzero      ),
      .directshift ( directshift  )
  );

  meslencompare2 comparator (     
      .count         ( count          ),
      .rmlen         ( rmlb           ),
      .tmlen         ( tmlen          ),
      .ext_r         ( rext           ),
      .ext_t         ( extendedr      ),
      .startrcrc     ( startrcrc_i    ),
      .rmzero        ( rmzero         ),
      .starttcrc     ( starttcrc_i    ),
      .zerointcrc    ( zerointcrc_i   ),
      .en_zerointcrc ( en_zerointcrc  )
  );

endmodule
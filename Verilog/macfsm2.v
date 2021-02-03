////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : macfsm2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : mac Zustandsautomat
// Commentary   : Auslagerung von Latches in FSM_register: rext,rrtr,transmitter, receiver,
//                error, first, puffer, onarbit. Für alle gilt:
//                signalxx_set==2'b11; // auf 1 setzen
//                signalxx_set==2'b10; // auf 0 setzen
//                signalxx_set==2'b00; // Unverändert lassen;
//                signalxx_set="01"; 
//                alle resetsignale gedreht (reset==0, normal betrieb 1)
//                DW 2005.06.30 Prescale Enable eingefügt.
//                DW 2005.06.30 Aus dem synchronen Reset wird ein asynchroner Reset.      
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 16.07.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 19.07.2019 | transl. process statedeb_p for debug signal as simple
//         |                    |            | assignment, so current_state is always statedeb. This
//         |                    |            | leads to non equality when compared wit CEC, because 
//         |                    |            | default state "ff" in vhdl case is now missing.
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module macfsm2(
	input  wire clock,      	// prescaler
	input  wire Prescale_EN,    // DW 2005.06.30 Prescale Enable eingefügt
	input  wire reset,      	// Mac/reset
	input  wire sendpoint,      // bittiming
	input  wire smplpoint,      // bittiming
	input  wire crc_ok,      	// rcrc (1, wenn reg alle 0)
	input  wire inbit,      	// destuffing
	input  wire stufft,      	// stuffing (transmit)
	input  wire stuffr,      	// destuffing (receive)
	input  wire biterror,      	// biterrordetect
	input  wire stferror,      	// destuff
	input  wire trans,      	// llc, start transmission
	input  wire text,      		// IOCPU, transmesconreg
	input  wire erroractiv,     // FCE FSM
	input  wire errorpassiv,    // FCE FSM
	input  wire busof,      	// FCE FSM
	input  wire ackerror,      	// FSM_register (wird hier gesetzt)
	input  wire onarbit,      	// FSM_register (wird hier gesetzt)
	input  wire transmitter,    // FSM_register (wird hier gesetzt)
	input  wire receiver,      	// FSM_register (wird hier gesetzt)
	input  wire error,      	// FSM_register (wird hier gesetzt)
	input  wire first,      	// FSM_register (wird hier gesetzt)
	input  wire puffer,      	// FSM_register (wird hier gesetzt)
	input  wire rext,      		// FSM_register (wird hier gesetzt)
	input  wire rrtr,      		// FSM_register (wird hier gesetzt)
	input  wire lt3, 			// counter <,>,= 3, Intermiss. , erract
	input  wire gt3, 
	input  wire eq3,      
	input  wire lt11, 			// counter <,= 11, Intermiss., errpass
	input  wire eq11,      
	input  wire startrcrc,      // meslencompare, Datenfeld vorbei
	input  wire rmzero,      	// meslencompare, Datenfeld==0,
								// rec_acptdat überspringen
	input  wire starttcrc,      // meslencompare, crc senden signal
	output reg  [1:0] ackerror_set,  	// fsm_register
	output reg  [1:0] onarbit_set,  	// fsm_register
	output reg  [1:0] transmitter_set,  // fsm_register
	output reg  [1:0] receiver_set,  	// fsm_register
	output reg  [1:0] error_set,  		// fsm_register
	output reg  [1:0] first_set,  		// fsm_register
	output reg  [1:0] puffer_set,  		// fsm_register
	output reg  [1:0] rext_set,  		// fsm_register
	output reg  [1:0] rrtr_set,  		// fsm_register
	input  wire [6:0] count,  			// counter
	output reg  [2:0] setrmleno,  		// recmeslen, empfangs/ dlc(in mesg)
	output reg  actvrmln,      	// recmeslen, activate 
	output reg  actvtcrc,      	// tcrc, active
	output reg  actvrcrc,      	// rcrc, active
	output reg  actvtstf,      	// stuffing, active
	output reg  actvrstf,      	// destuffing, active
	output reg  actvtsft,      	// tshift, active
	output reg  actvrsft,      	// rshift, active
	output reg  actvtdct,      	// stuffing, direct
	output reg  actvrdct,      	// destuffing, direct
	output reg  actvtbed,     	// biterrordetect, active
	output reg  setbdom,      	// stuffing, setdom
	output reg  setbrec,      	// stuffing, setrec
	output reg  lcrc,     	 	// rshift, bei crc nicht active; 
	output reg  lmsg,      		// tshift, tcrc, (vor/)laden der register
	output reg  tshift,      	// tshift, schieben enable, dann actvtsft
	output reg  inconerec,      // FCE, rec
	output reg  incegtrec,      // FCE, rec
	output reg  incegttra,      // FCE, tec
	output reg  decrec,      	// FCE, rec
	output reg  dectra,      	// FCE, tec
	output reg  elevrecb,      	// FCE, erbcount
	output reg  hardsync,      	// bittiming fsm
	output reg  inccount,      	// counter
	output reg  resrmlen,      	// recmeslen, reset(in mac || mit reset)
	output reg  rescount,      	// counter, reset (in mac || mit reset)
	output reg  resetdst,      	// destuffing, reset ( " )
	output reg  resetstf,      	// stuffing, reset ( " )
	output reg  activatefast,   // fastshift, startsignal
	output reg  crc_shft_out,   // tcrc wird sendeschieberegister
	output reg  en_zerointcrc,
	output wire [7:0] statedeb // fsm debug
	);     						
	//
// FSM/VSS/interna: Die Reihenfolge der States hier entspricht der Zahl, die
// man liest, wenn man current_state als Integer Wert verarbeitet. Zählung
// beginnt mit 0. (streamaker.c FSM/Übergangsüberwachung)
		
parameter 	sync_start             = 8'h00, sync_sample           	= 8'h01,
        			sync_sum               = 8'h02, sync_end               = 8'h03,
        			inter_sample           = 8'h04, inter_check            = 8'h05,
        			inter_goregtran        = 8'h06, inter_react            = 8'h07,
        			bus_idle_chk           = 8'h08, bus_idle_sample        = 8'h09,
        			inter_transhift        = 8'h0a, inter_regtrancnt       = 8'h0b,
        			inter_preprec          = 8'h0c, inter_incsigres        = 8'h0d,
        			tra_arbit_tactrsftn    = 8'h0e, tra_arbit_tactrsftsr   = 8'h0f,
        			tra_arbit_tactrsfte    = 8'h10, tra_arbit_tactrsfter   = 8'h11,
        			tra_arbit_tnactrnsft   = 8'h12, tra_arbit_tsftrsmpl    = 8'h13,
        			tra_arbit_tnsftrsmpl   = 8'h14, tra_arbit_goreceive    = 8'h15,
        			tra_data_activatecrc   = 8'h16, tra_data_activatncrc   = 8'h17,
        			tra_data_shifting      = 8'h18, tra_data_noshift       = 8'h19,
        			tra_data_lastshift     = 8'h1a, tra_data_loadcrc       = 8'h1b,
        			tra_crc_activatedec    = 8'h1c, tra_crc_activatndec    = 8'h1d,
        			tra_crc_shifting       = 8'h1e, tra_crc_noshift        = 8'h1f,
        			tra_crc_delshft        = 8'h20, tra_ack_sendack        = 8'h21,
        			tra_ack_shifting       = 8'h22, tra_ack_stopack        = 8'h23,
        			tra_edof_sendrecb      = 8'h24, tra_edof_shifting      = 8'h25,
        			rec_flglen_sample      = 8'h26, rec_flglen_shiftstdrtr = 8'h27,
        			rec_flglen_shiftextnor = 8'h28, rec_flglen_shiftdlc64  = 8'h29,
        			rec_flglen_shiftdlc32  = 8'h2a, rec_flglen_shiftdlc16  = 8'h2b,
        			rec_flglen_shiftdlc8   = 8'h2c, rec_flglen_shiftextrtr = 8'h2d,
        			rec_flglen_shifting    = 8'h2e, rec_flglen_noshift     = 8'h2f,
        			rec_acptdat_sample     = 8'h30, rec_acptdat_shifting   = 8'h31,
        			rec_acptdat_noshift    = 8'h32, rec_crc_rescnt         = 8'h33,
        			rec_crc_sample         = 8'h34, rec_crc_shifting       = 8'h35,
        			rec_crc_noshift        = 8'h36, rec_ack_recdelim       = 8'h37,
        			rec_ack_prepgiveack    = 8'h38, rec_ack_prepnoack      = 8'h39,
        			rec_ack_noack          = 8'h3a, rec_ack_giveack        = 8'h3b,
        			rec_ack_checkack       = 8'h3c, rec_ack_stopack        = 8'h3d,
        			rec_edof_sample        = 8'h3e, rec_edof_check         = 8'h3f,
        			rec_edof_endrec        = 8'h40, rec_flglen_setdlc      = 8'h41,
        			rec_acptdat_lastshift  = 8'h42, over_firstdom          = 8'h43,
        			over_senddomb          = 8'h44, over_check1            = 8'h45,
        			over_preprecb          = 8'h46, over_wtonrecb          = 8'h47,
        			over_increccounter     = 8'h48, over_inctracounter     = 8'h49,
        			over_check2            = 8'h4a, over_sendrecb          = 8'h4b,
        			over_check3            = 8'h4c, over_waitoclk          = 8'h4d,
        			over_prepsend          = 8'h4e, erroractiv_firstdom    = 8'h4f,
        			erroractiv_inceinsrec  = 8'h50, erroractiv_incachtrec  = 8'h51,
        			erroractiv_incachttra  = 8'h52, erroractiv_senddomb    = 8'h53,
        			erroractiv_check1      = 8'h54, erroractiv_preprecb    = 8'h55,
        			erroractiv_wtonrecb    = 8'h56, erroractiv_dombitdct   = 8'h57,
        			erroractiv_egtdombt    = 8'h58, erroractiv_egtdombr    = 8'h59,
        			erroractiv_check2      = 8'h5a, erroractiv_sendrecb    = 8'h5b,
        			erroractiv_check3      = 8'h5c, erroractiv_waitoclk    = 8'h5d,
        			erroractiv_prepsend    = 8'h5e, errorpassiv_firstrec   = 8'h5f,
        			errorpassiv_inceinsrec = 8'h60, errorpassiv_incachtrec = 8'h61,
        			errorpassiv_fillpuffer = 8'h62, errorpassiv_incachttra = 8'h63,
        			errorpassiv_incsrecb   = 8'h64, errorpassiv_zersrecbi  = 8'h65,
        			errorpassiv_pufferrec  = 8'h66, errorpassiv_zersrecbz  = 8'h67,
        			errorpassiv_zersrecbo  = 8'h68, errorpassiv_check1     = 8'h69,
        			errorpassiv_pufferdom  = 8'h6a, errorpassiv_wtonrecb   = 8'h6b,
        			errorpassiv_dombitdct  = 8'h6c, errorpassiv_egtdombt   = 8'h6d,
        			errorpassiv_pufferdomi = 8'h6e, errorpassiv_egtdombr   = 8'h6f,
        			errorpassiv_check2     = 8'h70, errorpassiv_sendrecb   = 8'h71,
        			errorpassiv_check3     = 8'h72, errorpassiv_waitoclk   = 8'h73,
        			errorpassiv_prepsend   = 8'h74, errorpassiv_preprecb   = 8'h75,
        			errorpassiv_newcount   = 8'h76, errorpassiv_prepcount  = 8'h77,
        			busoff_first           = 8'h78, busoff_sample          = 8'h79,
        			busoff_setzer          = 8'h7a, busoff_increm          = 8'h7b,
        			busoff_deccnt          = 8'h7c, rec_edof_lastbit       = 8'h7d,
        			rec_edof_inter         = 8'h7e, tra_edof_dectra        = 8'h7f,
        			inter_preprec_shifting = 8'h80, inter_arbit_tsftrsmpl  = 8'h81; 

reg [7:0] 	current_state, next_state; 

assign statedeb = current_state;		// Debug signal

///////////  synch : PROCESS(clock,Prescale_EN , reset)  /////// sensitivity list fehler dokumentieren


always@(posedge clock, negedge reset)	
begin
  if (reset == 1'b0)              		// DW 2005.06.30 Aus dem synchronen Reset wird ein asynchroner Reset.
      current_state <= sync_start;    	
  else
    if (Prescale_EN == 1'b1)      		// DW 2005.06.30 Prescale Enable eingefügt
      current_state <= next_state;
	//else
end

always@* /*(current_state, sendpoint, smplpoint, crc_ok, inbit, stufft, stuffr, biterror, stferror, trans, 
		 text, erroractiv, errorpassiv, busof, count, rext, rrtr, ackerror, onarbit, transmitter, receiver, 
		error, first, puffer, lt3, gt3, eq3, lt11, eq11, rmzero, startrcrc, starttcrc)*/
begin
    rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
    actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
    actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
    setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;         tshift <= 1'b0;
    inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
    decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
    resetstf        <= 1'b1;  hardsync <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
    setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b0;     ackerror_set <= 2'b10;
    transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
    activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1;
    crc_shft_out <= 1'b0;
    next_state      <= current_state;

    case(current_state)
/////////////////////////////// start synchronization  ///////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
// FSM/Unterteilung: Anfang SYNC, Einziger Einstieg: 0, sync_start
///////////////////////////////////////////////////////////////////////////////      
//0///////////////////////////////////////////////////////////////////////////////
       sync_start : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b0;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= sync_sample;
        else
          next_state <= sync_start;
        end
//1///////////////////////////////////////////////////////////////////////////////        
       sync_sample : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (inbit == 1'b1) 
          next_state <= sync_sum;
        else
          next_state <= sync_start;
        end
//2///////////////////////////////////////////////////////////////////////////////
// Abfrage counter,/ dann ende sync
       sync_sum : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1 && count != 8) 
          next_state <= sync_sample;
        else if (count == 8) 
          next_state <= sync_end;
        else
          next_state <= sync_sum;
        end
//3///////////////////////////////////////////////////////////////////////////////
// Warten auf smplpoint, dann nach !bus_idle!
       sync_end : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= bus_idle_sample;  // inter_sample; keine intermission Zeit!
        else
          next_state <= sync_end;
        end

///////////////////////////////////////////////////////////////////////////////
// FSM/Unterteilung: Ende SYNC
//                   Anfang INTERFRAME, Einziger Einstieg: 4, inter_sample
///////////////////////////////////////////////////////////////////////////////      
//4///////////////////////////////////////////////////////////////////////////////
// nach dem samplezeitpunkt, senden, empfangen, overload oder arbitrierung
       inter_sample : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b0; 
        crc_shft_out <= 1'b0;

        if (busof == 1'b1) 
          next_state <= busoff_first;
        else if ((((errorpassiv == 1'b0 || receiver == 1'b1) && lt3 == 1'b1)||((errorpassiv == 1'b1 && receiver == 1'b0) && lt11 == 1'b1)) && inbit == 1'b1) 
          next_state <= inter_check;
        else if (lt3 == 1'b1 && inbit == 1'b0) 
          next_state <= over_firstdom;
          // overload
        else if (inbit == 1'b0 && (gt3 == 1'b1 || ((eq3 == 1'b1 || gt3 == 1'b1) &&((errorpassiv == 1'b1 && receiver == 1'b0) || trans == 1'b0)))) 
          next_state <= inter_preprec;
//nochne Einsparung: aus >=3 und >=11 wurde ==3 und ==11
//DW 2005.07.01: eq3 == 1'b1 wird ersetzt durch (eq3 == 1'b1 || gt3 == 1'b1), damit
//ein Zählerstand auch abgefangen wird.
        else if (sendpoint == 1'b1 &&(((errorpassiv == 1'b0 || receiver == 1'b1)&& (eq3 == 1'b1 || gt3 == 1'b1))||((errorpassiv == 1'b1 && receiver == 1'b0)&& (eq11 == 1'b1 || lt11 == 1'b0))) && inbit == 1'b1 && trans == 1'b1)   //DW 2005.07.01: eq3 == 1'b1 wird ersetzt durch (eq3 == 1'b1 || gt3 == 1'b1), damit
//ein Zählerstand auch abgefangen wird.
          next_state <= inter_goregtran;
        else if ((errorpassiv == 1'b0 || receiver == 1'b1) && (eq3 == 1'b1 || gt3 == 1'b1) && inbit == 1'b0 && trans == 1'b1)   //DW 2005.07.01: eq3 == 1'b1 wird ersetzt durch (eq3 == 1'b1 || gt3 == 1'b1), damit
//ein Zählerstand auch abgefangen wird.
          next_state <= inter_react;
        else if (trans == 1'b0 &&(((eq3 == 1'b1 || gt3 == 1'b1) && (errorpassiv == 1'b0 || receiver == 1'b1))||( (eq11 == 1'b1 || lt11 == 1'b0) && (errorpassiv == 1'b1 && receiver == 1'b0))))   //DW 2005.07.01: eq3 == 1'b1 wird ersetzt durch (eq3 == 1'b1 || gt3 == 1'b1), damit
//ein Zählerstand auch abgefangen wird.
          next_state <= bus_idle_chk;
        else
          next_state <= inter_sample;
        end
//5///////////////////////////////////////////////////////////////////////////////
// auf nächsten smplpoint warten
       inter_check : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b0;
        resetstf        <= 1'b1;  hardsync <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b0; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= inter_sample;
        else
          next_state <= inter_check;
        end
//8///////////////////////////////////////////////////////////////////////////////
// bus_idle, kein overload mehr bei counter überlauf (bus_idle_chk==inter_check)
       bus_idle_chk : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b0;
        resetstf        <= 1'b1;  hardsync <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b0; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= bus_idle_sample;
        else
          next_state <= bus_idle_chk;
        end
//9///////////////////////////////////////////////////////////////////////////////
// entspricht inter_sample , kein inccount!
       bus_idle_sample : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b0; 
        crc_shft_out <= 1'b0;

        if (trans == 1'b0 && inbit == 1'b1) 
          next_state <= bus_idle_chk;
        else if (inbit == 1'b0 && trans == 1'b0) 
          next_state <= inter_preprec;
          // go receive
        else if (inbit == 1'b0 && trans == 1'b1) 
          next_state <= inter_react;
        else if (sendpoint == 1'b1 && inbit == 1'b1 && trans == 1'b1) 
          next_state <= inter_goregtran;
        else
          next_state <= bus_idle_sample;
        end
//7///////////////////////////////////////////////////////////////////////////////
// hierlang, wenn Sendeauftrag und inbit == 0 (anstehende Arbitrierung)
       inter_react : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b1;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b0;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b0; 
        crc_shft_out <= 1'b0;
        next_state      <= inter_transhift;
        end
//6///////////////////////////////////////////////////////////////////////////////
// hierhin, wenn Sendeauftrag und Bus rezessiv. Es ist sendpoint, SOF starten
       inter_goregtran : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b1;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b0;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b0;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b0; 
        crc_shft_out <= 1'b0;
        next_state      <= inter_regtrancnt;
        end
//11//////////////////////////////////////////////////////////////////////////////
// Fortsetzung senden bei bus rezessiv (von goregtran) (warten auf smplpoint des SOF)
       inter_regtrancnt : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b1;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b0;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b0; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= inter_arbit_tsftrsmpl;  // war: tra_arbit_tsftrsmpl;
        else
          next_state <= inter_regtrancnt;
        end
//129///////////////////////////////////////////////////////////////////////////////
// neuer Zustand: inter_arbit_tsftrsmpl. Vereinheitlichung der Einstiegspunkte
// von tra_arbit: Von hier und von inter_react gehts nun zu tra_arbit_tactrsftn
// Ausgänge: Kopie von tra_arbit_tsftrsmpl, warten auf sendpoint, dann normal
// weiter im tra_arbit Zweig, nächster sendpoint, 1. bit ID
       inter_arbit_tsftrsmpl : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b1;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b11; en_zerointcrc <= 1'b0; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= tra_arbit_tactrsftn;
        else
          next_state <= inter_arbit_tsftrsmpl;
        end
//10///////////////////////////////////////////////////////////////////////////////
// von inter_react, SOF ist auf dem Bus, tshift schieben, um beim nächsten
// sendpoint 1. Bit ID senden zu können
       inter_transhift : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b1;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b0; 
        crc_shft_out <= 1'b0;
        next_state      <= inter_incsigres;
		end
//13///////////////////////////////////////////////////////////////////////////////
// von inter_transhift, warten auf sendpoint, dann nach tra_arbit und 1. Bit ID
// auf den Bus
       inter_incsigres : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b0; 
        crc_shft_out <= 1'b0;
        next_state <= tra_arbit_tactrsftn;
		end
//12///////////////////////////////////////////////////////////////////////////////
// um Übergänge zu Vereineiheitlichen, wird zu rec_flglen_sample gesprungen.
// Dann ist dies der einzige Einstiegspunkt in rec_flglen*. Aus tra_arbit wird
// auch nach _sample gesprungen. Vorbereitung für Zerlegung der FSM.
// kein Sendeauftrag, SOF entdeckt
       inter_preprec : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b0;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        next_state      <= inter_preprec_shifting;
		end
//128///////////////////////////////////////////////////////////////////////////////
// auf smplpoint warten von 1. Bit ID, dann zu rec_flglen
       inter_preprec_shifting : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= rec_flglen_sample;
        else
          next_state <= inter_preprec_shifting;
        end
///////////////////////////////////////////////////////////////////////////////
// FSM/Unterteilung: Ende INTERFRAME
//                   Anfang TRANSMIT_DATA, Einziger Einstieg: 14,tra_arbit_tactrsftn
///////////////////////////////////////////////////////////////////////////////      
//18///////////////////////////////////////////////////////////////////////////////
// nach einem Stuffbit auf smplpoint warten
       tra_arbit_tnactrnsft : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b11; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= tra_arbit_tsftrsmpl;
        else
          next_state <= tra_arbit_tnactrnsft;
        end
//14/////////////////////>>>>>///Einstieg (resetstate)//<<<<<<<</////////////////////
// senden des arbitfeldes (es ist sendpoint)
       tra_arbit_tactrsftn : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b1;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b11; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1 && stufft == 1'b0) 
          next_state <= tra_arbit_tsftrsmpl;
        else if (smplpoint == 1'b1 && stufft == 1'b1) 
          next_state <= tra_arbit_tnsftrsmpl;
        else
          next_state <= tra_arbit_tactrsftn;
        end
//15///////////////////////////////////////////////////////////////////////////////
// senden des RTR (Basic) (und setzen für empfang, falls abitverlust)
       tra_arbit_tactrsftsr : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b11;     actvtcrc <= 1'b1;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b11; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1 && stufft == 1'b0) 
          next_state <= tra_arbit_tsftrsmpl;
        else if (smplpoint == 1'b1 && stufft == 1'b1) 
          next_state <= tra_arbit_tnsftrsmpl;
        else
          next_state <= tra_arbit_tactrsftsr;
        end
//16///////////////////////////////////////////////////////////////////////////////
// Senden des IDE (auch für empfang, arbit!)
       tra_arbit_tactrsfte : begin
        rext_set        <= 2'b11; rrtr_set <= 2'b10;     actvtcrc <= 1'b1;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b11; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1 && stufft == 1'b0) 
          next_state <= tra_arbit_tsftrsmpl;
        else if (smplpoint == 1'b1 && stufft == 1'b1) 
          next_state <= tra_arbit_tnsftrsmpl;
        else
          next_state <= tra_arbit_tactrsfte;
        end
//17///////////////////////////////////////////////////////////////////////////////
// RTR vom Extended datenrahmen (count war falsch! 33!!)
       tra_arbit_tactrsfter : begin
        rext_set        <= 2'b11; rrtr_set <= 2'b11;     actvtcrc <= 1'b1;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b11; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1 && stufft == 1'b0) 
          next_state <= tra_arbit_tsftrsmpl;
        else if (smplpoint == 1'b1 && stufft == 1'b1) 
          next_state <= tra_arbit_tnsftrsmpl;
        else
          next_state <= tra_arbit_tactrsfter;
        end
//19///////////////////////////////////////////////////////////////////////////////
// smplpoint in arbit,/ biterror == go receive, entscheidung, was als nächstes
// gesendet wird. stferror hat hier niochts zu suchen
       tra_arbit_tsftrsmpl : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b1;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b11; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1 && biterror == 1'b0 && stferror == 1'b0 && count == 13 && inbit == 1'b1 && text == 1'b1)
        
          next_state <= tra_arbit_tactrsftsr;
        else if(sendpoint == 1'b1 && biterror == 1'b0 && stferror == 1'b0 && count == 14 && inbit == 1'b1)
          next_state <= tra_arbit_tactrsfte;  // Fehler arbit. ext :32 /> 33
        else if(sendpoint == 1'b1 && biterror == 1'b0 && stferror == 1'b0 && count == 33 && inbit == 1'b1)
          next_state <= tra_arbit_tactrsfter;
        else if(sendpoint == 1'b1 && biterror == 1'b0 && stferror == 1'b0 &&
              (inbit == 1'b0 ||(count != 13 && count != 14 && count != 33 )) &&
              (!((count == 13 && text == 1'b0) || (count == 34 && text == 1'b1 )))) // Leduc Aenderung NOR
          next_state <= tra_arbit_tactrsftn;
        else if(sendpoint == 1'b1 && biterror == 1'b0 && stferror == 1'b0 &&((count == 13 && text == 1'b0)
                                                                      || (count == 34 && text == 1'b1))) 
          next_state <= tra_data_activatecrc;
          //go data send
        else if (biterror == 1'b1 && stferror == 1'b0) 
          next_state <= tra_arbit_goreceive;

        else
          next_state <= tra_arbit_tsftrsmpl;
        end
//21///////////////////////////////////////////////////////////////////////////////
// Arbitrierung verloren, auf nächsten smplpoint warten, um daten zu empfangen
       tra_arbit_goreceive : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= rec_flglen_sample;
        else
          next_state <= tra_arbit_goreceive;
        end
//20///////////////////////////////////////////////////////////////////////////////
// smplpoint des stuffbits, hier ist der stufffehler von interesse
       tra_arbit_tnsftrsmpl : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     resetdst <= 1'b1;
        resetstf        <= 1'b1;  hardsync <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b11; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;

        if (sendpoint == 1'b1 && biterror == 1'b0) 
          next_state <= tra_arbit_tnactrnsft;
        else if (stferror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (stferror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else
          next_state <= tra_arbit_tnsftrsmpl;
        end
// Ende Arbit, Anfang data (keine FSM/Unterteilung!!!)
//22&23: Änderungen: synth, invalide zellen weg, starttcrc
//22///////////////////////////////////////////////////////////////////////////////
// Sendpoint, daten versenden
       tra_data_activatecrc : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b1;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1 && stufft == 1'b0 && starttcrc == 1'b0) 
          next_state <= tra_data_shifting;
        else if (smplpoint == 1'b1 && stufft == 1'b0 && starttcrc == 1'b1) 
          next_state <= tra_data_lastshift;
        else if (smplpoint == 1'b1 && stufft == 1'b1) 
          next_state <= tra_data_noshift;
        else
          next_state <= tra_data_activatecrc;
        end
//23///////////////////////////////////////////////////////////////////////////////
// sendpoint stuffbit, warten auf smplpoint stuffbit
       tra_data_activatncrc : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1 && starttcrc == 1'b0) 
          next_state <= tra_data_shifting;
        else if (smplpoint == 1'b1 && starttcrc == 1'b1) 
          next_state <= tra_data_lastshift;
        else
          next_state <= tra_data_activatncrc;
        end
//24///////////////////////////////////////////////////////////////////////////////
// smplpoint nach Daten/Stuffbit versenden, Bit checken
       tra_data_shifting : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b1;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1 && biterror == 1'b0) 
          next_state <= tra_data_activatecrc;
        else if (biterror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else
          next_state <= tra_data_shifting;
        end
//26///////////////////////////////////////////////////////////////////////////////
// smplpoint des letzten Datenbits, counter für crc resetten, bit checken
       tra_data_lastshift : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b1;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (biterror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else
          next_state <= tra_data_loadcrc;
        end
//25///////////////////////////////////////////////////////////////////////////////
// smplpoint des bits vor stuffbit, tshift nicht aktivieren (actvtsft!)
       tra_data_noshift : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1 && biterror == 1'b0) 
          next_state <= tra_data_activatncrc;
        else if (biterror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else
          next_state <= tra_data_noshift;
        end
//27///////////////////////////////////////////////////////////////////////////////
// warten auf sendpoint des 1. Bit CRC
       tra_data_loadcrc : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b1;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b1;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= tra_crc_activatedec;
        else
          next_state <= tra_data_loadcrc;
        end
///////////////////////////////////////////////////////////////////////////////
// FSM/Unterteilung: Ende TRANSMIT_DATA
//                   Anfang TRANSMIT_CHECK, Einziger Einstieg: 14,tra_crc_activatedec
///////////////////////////////////////////////////////////////////////////////      
//28///////////////////////////////////////////////////////////////////////////////
// sendpoint crc bit, warten auf smplpoint
       tra_crc_activatedec : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b1;
        // 15 /> 16
        if (smplpoint == 1'b1 && stufft == 1'b0 && count != 16) 
          next_state <= tra_crc_shifting;
        else if (smplpoint == 1'b1 && stufft == 1'b0 && count == 16) 
          // tra_crc_lastshif /> delshift
          next_state <= tra_crc_delshft;
        else if (smplpoint == 1'b1 && stufft == 1'b1) 
          next_state <= tra_crc_noshift;
        else
          next_state <= tra_crc_activatedec;
        end
//29///////////////////////////////////////////////////////////////////////////////
// sendpoint stuffbit, warten auf smplpoint
       tra_crc_activatndec : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b1;
        if (smplpoint == 1'b1 && count != 16) 
          next_state <= tra_crc_shifting;
        else if (smplpoint == 1'b1 && count == 16) 
          next_state <= tra_crc_delshft;
        else
          next_state <= tra_crc_activatndec;
        end
//30///////////////////////////////////////////////////////////////////////////////
// smplpoint des eben gesendeten CRC/Stuff Bits, warten auf sendpoint, Bit checken
       tra_crc_shifting : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b1;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b1;
        if (sendpoint == 1'b1 && biterror == 1'b0) 
          next_state <= tra_crc_activatedec;
        else if (biterror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else
          next_state <= tra_crc_shifting;
        end
//31///////////////////////////////////////////////////////////////////////////////
// smplpoint des Bits vor stuffbit, tshift nicht schieben, bit checken
       tra_crc_noshift : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b1;
        if (sendpoint == 1'b1 && biterror == 1'b0) 
          next_state <= tra_crc_activatndec;
        else if (biterror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else
          next_state <= tra_crc_noshift;
        end
//32///////////////////////////////////////////////////////////////////////////////
// smplpoint des CRC/Delimiter, checken, ob rezessiv. lastshift und senddel
// fallen weg, ist jetzt inkl. in CRC Versendung. Warten auf  sendpoint ACK (setbrec).
       tra_crc_delshft : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b1;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b1;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b1;
        if (sendpoint == 1'b1 && biterror == 1'b0) 
          next_state <= tra_ack_sendack;
        else if (biterror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else
          next_state <= tra_crc_delshft;
        end
// Ende CRC, Anfanck Ack (keine FSM/Unterteilung !!!)
// immer noch TRANMIST_CHECK
//33///////////////////////////////////////////////////////////////////////////////
// sendpoint ACK_Slot, rezessiv senden (setbrec!)
       tra_ack_sendack : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= tra_ack_shifting;
        else
          next_state <= tra_ack_sendack;
        end
//34///////////////////////////////////////////////////////////////////////////////
// smplpoint ACK/Slot, checken auf ACK. ACK ok, wenn biterror==1
       tra_ack_shifting : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
// Änderung: Error Flag muß direkt nach dem A_S kommen, nicht wie gehabt nach
// dem A_D, deshalb nicht mehr auf Sendpoint warten und direkt nach stopack
        if (biterror == 1'b0) 
          next_state <= tra_ack_stopack;
//        if (sendpoint == 1'b1 && biterror == 1'b0) 
//          next_state <= tra_ack_senddel;
        else if (sendpoint == 1'b1 && biterror == 1'b1) 
          next_state <= tra_edof_sendrecb;  // OK (Biterror)
        else
          next_state <= tra_ack_shifting;
        end
//35///////////////////////////////////////////////////////////////////////////////
// kein ACK bekommen, Error flag direkt starten (nicht auf A_D warten)
       tra_ack_stopack : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b11;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else
          next_state <= errorpassiv_firstrec;
        end
// Ende tra_ack, anfang tra_edof
// Änderung: hier wird nur zum shifting verzweigt.Dort Error Abfrage. Keine
// Extrawurst mehr fürs letzte Bit, da das auch zu einem Form Error führt.
// Overload stimmt nicht.
//36///////////////////////////////////////////////////////////////////////////////
// ACK war ok
       tra_edof_sendrecb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= tra_edof_shifting;
        else
          next_state <= tra_edof_sendrecb;
        end
//37///////////////////////////////////////////////////////////////////////////////
// smplpoint, beim nächsten sendpoint entweder noch ein EOF Bit senden, oder ende
// neu, von hier wird nach dectra verzweigt. lastshift gibs nun nicht mehr        
       tra_edof_shifting : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1 && biterror == 1'b0 && count != 8) 
          next_state <= tra_edof_sendrecb;
        else if (sendpoint == 1'b1 && biterror == 1'b0 && count == 8) 
          next_state <= tra_edof_dectra;
        else if (biterror == 1'b1 && count == 8) 
          next_state <= over_firstdom;
        else if (biterror == 1'b1 && erroractiv == 1'b1 && count != 8) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1 && count != 8) 
          next_state <= errorpassiv_firstrec;
        else
          next_state <= tra_edof_shifting;
        end
//neuer Zustand von mir, damit kein dectra, wenn 7. Bit EOF dominant, sondern
//nur Overload Flag!
//127///////////////////////////////////////////////////////////////////////////////
// sendpoint des letzten (7.) EOF Bits, nächster smplpoint schon intermission,
// dectra signal an FCE und LLC
       tra_edof_dectra : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b1;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b11; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= inter_sample;
        else
          next_state <= tra_edof_dectra;
        end
///////////////////////////////////////////////////////////////////////////////
// FSM/Unterteilung: Ende TRANSMIT_CHECK
//                   Anfang RECEIVE_DATA, Einziger Einstieg: 38,rec_flglen_sample
/////////////////////////////////////////////////////////////////////////////// 
//38///////////////////////////////////////////////////////////////////////////////
// smplpoint des empfangenen Bits (hier wird immer angefangen mit dem 1. Bit
// ID, SOF wird im inter_*/bus_* bereich abgehandelt)
       rec_flglen_sample : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (stuffr == 1'b1 && stferror == 1'b0) 
          next_state <= rec_flglen_noshift;
        else if (stferror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (stferror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else if (stuffr == 1'b0 && stferror == 1'b0 && inbit == 1'b1 && count == 12) 
          next_state <= rec_flglen_shiftstdrtr;
        else if ((stuffr == 1'b0) && (stferror == 1'b0) && (inbit == 1'b1) && (count == 13)) 
          next_state <= rec_flglen_shiftextnor;
        else if (stuffr == 1'b0 && stferror == 1'b0 && inbit == 1'b1 && count == 15 && rrtr == 1'b0 && rext == 1'b0) 
          next_state <= rec_flglen_shiftdlc64;
        else if (stuffr == 1'b0 && stferror == 1'b0 && inbit == 1'b1 && count == 16 && rrtr == 1'b0 && rext == 1'b0) 
          next_state <= rec_flglen_shiftdlc32;
        else if (stuffr == 1'b0 && stferror == 1'b0 && inbit == 1'b1 && count == 17 && rrtr == 1'b0 && rext == 1'b0) 
          next_state <= rec_flglen_shiftdlc16;
        else if (stuffr == 1'b0 && stferror == 1'b0 && inbit == 1'b1 && count == 18 && rrtr == 1'b0 && rext == 1'b0) 
          next_state <= rec_flglen_shiftdlc8;
        else if (stuffr == 1'b0 && stferror == 1'b0 && inbit == 1'b1 && count == 32 && rext == 1'b1) 
          next_state <= rec_flglen_shiftextrtr;
        else if (stuffr == 1'b0 && stferror == 1'b0 && inbit == 1'b1 && count == 35 && rrtr == 1'b0 && rext == 1'b1) 
          next_state <= rec_flglen_shiftdlc64;
        else if (stuffr == 1'b0 && stferror == 1'b0 && inbit == 1'b1 && count == 36 && rrtr == 1'b0 && rext == 1'b1) 
          next_state <= rec_flglen_shiftdlc32;
        else if (stuffr == 1'b0 && stferror == 1'b0 && inbit == 1'b1 && count == 37 && rrtr == 1'b0 && rext == 1'b1) 
          next_state <= rec_flglen_shiftdlc16;
        else if (stuffr == 1'b0 && stferror == 1'b0 && inbit == 1'b1 && count == 38 && rrtr == 1'b0 && rext == 1'b1) 
          next_state <= rec_flglen_shiftdlc8;
        else if (stuffr == 1'b0 && stferror == 1'b0 &&
               (inbit == 1'b0 ||
                (
                  count != 12 &&
                  count != 13 &&       //nächste Zeile: "|| rrtr==1'b1" von mir
                                        //wg. Fehler im empfang von RTR Bas ID
                  (rext == 1'b1 || rrtr == 1'b1 ||(count != 15 && count != 16 && count != 17 && count != 18)) &&
                  (count != 32 || rext == 1'b0)&&
                  (rext == 1'b0 || rrtr == 1'b1 ||(count != 35 && count != 36 && count != 37 && count != 38))
                  )
                )
               ) 
          next_state <= rec_flglen_shifting;
        else
          next_state <= rec_flglen_sample;
        end
//46///////////////////////////////////////////////////////////////////////////////
// Teil der ID empfangen, kein spezielles Steuerbit, warten auf nächstes Bit
// (smplpoint). Entscheidung nach rec_data oder rec_crc zu verzweigen
// Änderung mit rmzero, Übergang nach rec_crc, auch wenn dataframe (RTR==0) mit
// DLC==0. s. _crc_rescnt
       rec_flglen_shifting : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;

        if (smplpoint == 1'b1 && (!((count == 19 && rext == 1'b0) || (count == 39 && rext == 1'b1)))) // Leduc Aenderung des NOR
          next_state <= rec_flglen_sample;
        else if(smplpoint == 1'b1 &&((count == 19 && rext == 1'b0)||(count == 39 && rext == 1'b1))&& rrtr == 1'b0 && rmzero == 1'b0) 
          next_state <= rec_acptdat_sample;
        else if(smplpoint == 1'b1 &&((count == 19 && rext == 1'b0)||(count == 39 && rext == 1'b1))&& (rrtr == 1'b1 || rmzero == 1'b1))
          next_state <= rec_crc_rescnt;
        else
          next_state <= rec_flglen_shifting;
        end

//39/////////////////////////////////////////////////////////////////////////////
// wenn empfangspos bei Basic RTR (rrtr_set!)
       rec_flglen_shiftstdrtr : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b11;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= rec_flglen_sample;
        else
          next_state <= rec_flglen_shiftstdrtr;
        end
//40///////////////////////////////////////////////////////////////////////////////
// Wenn IDE kommt (also extended rahmen) rext_set!
       rec_flglen_shiftextnor : begin
        rext_set        <= 2'b11; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= rec_flglen_sample;
        else
          next_state <= rec_flglen_shiftextnor;
        end
//41///////////////////////////////////////////////////////////////////////////////
// Bit#3 (MSB) vom DLC (setrmleno,actvtrmlen !)
       rec_flglen_shiftdlc64 : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 4;    actvrmln <= 1'b1;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        next_state      <= rec_flglen_setdlc;
		end
//42///////////////////////////////////////////////////////////////////////////////
// Bit#2 DLC (setrmleno,actvtrmlen!)
       rec_flglen_shiftdlc32 : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 3;    actvrmln <= 1'b1;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        next_state      <= rec_flglen_setdlc;
		end
//43///////////////////////////////////////////////////////////////////////////////
// Bit#1 DLC (setrmleno, actvtrmlen!)
       rec_flglen_shiftdlc16 : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 2;    actvrmln <= 1'b1;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        next_state      <= rec_flglen_setdlc;
		end
//44///////////////////////////////////////////////////////////////////////////////
// Bit#0 DLC (setrmleno, actvtrmlen!)
       rec_flglen_shiftdlc8 : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 1;    actvrmln <= 1'b1;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        next_state      <= rec_flglen_setdlc;
		end
//65///////////////////////////////////////////////////////////////////////////////
// Nach DLC/bit (setrmleno==7) 
       rec_flglen_setdlc : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 7;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1 && (!((count == 19 && rext == 1'b0) || (count == 39 && rext == 1'b1))))  // Leduc Aenderung NOR 
          next_state <= rec_flglen_sample;
        else if(smplpoint == 1'b1 &&((count == 19 && rext == 1'b0)||(count == 39 && rext == 1'b1))&& rrtr == 1'b0)
          next_state <= rec_acptdat_sample;
// hier nicht mehr nach rec_crc, in rec_flglen_shifting!!!
        else
          next_state <= rec_flglen_setdlc;
        end
//45///////////////////////////////////////////////////////////////////////////////
// Extended+RTR (counter 32 && rext, rrtr_set!)
       rec_flglen_shiftextrtr : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b11;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= rec_flglen_sample;
        else
          next_state <= rec_flglen_shiftextrtr;
        end
//47///////////////////////////////////////////////////////////////////////////////
// nach stuff, warten auf smplpoint
       rec_flglen_noshift : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= rec_flglen_sample;
        else
          next_state <= rec_flglen_noshift;
        end
// ende arbitrierung, anfang daten
//48///////////////////////////////////////////////////////////////////////////////
// samplepoint empfangenes bit
       rec_acptdat_sample : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (stuffr == 1'b1 && stferror == 1'b0) 
          next_state <= rec_acptdat_noshift;
        else if (stferror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (stferror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else
          next_state <= rec_acptdat_shifting;
        end
//49///////////////////////////////////////////////////////////////////////////////
// direkt nach smplpoint, rshift schieben, auf nächsten smplpoint warten
       rec_acptdat_shifting : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
// Änderung: synth: invalide Zellen weg, meslencompare,startrcrc
        if (smplpoint == 1'b1 && startrcrc == 1'b0) 
          next_state <= rec_acptdat_sample;
        else if (startrcrc == 1'b1) 
          next_state <= rec_acptdat_lastshift;
        else
          next_state <= rec_acptdat_shifting;
        end
//50///////////////////////////////////////////////////////////////////////////////
// Stuffbit, warten, nicht rshift schieben, warten auf nächsten smplp oint
       rec_acptdat_noshift : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= rec_acptdat_sample;
        else
          next_state <= rec_acptdat_noshift;
        end
//66///////////////////////////////////////////////////////////////////////////////
// counter für crc empfang resetten, auf smplpoint des 1. CRC Bits warten
// eigentlich nicht mehr nötig, aber für gleiche einstiegspunkte halt nach
// crc_rescnt. gibt es halt ein längeres resetsignal
       rec_acptdat_lastshift : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if(smplpoint == 1'b1) 
          next_state <= rec_crc_rescnt;  //war: crc_sample, aber counter muss resetten
        else
          next_state <= rec_acptdat_lastshift;
        end
///////////////////////////////////////////////////////////////////////////////
// FSM/Unterteilung: Ende RECEIVE_DATA
//                   Anfang RECEIVE_CHECK, Einziger Einstieg: 51,rec_crc_rescnt
/////////////////////////////////////////////////////////////////////////////// 
//51///////////////////////////////////////////////////////////////////////////////
// von mir wg. übergang von dlc==0 oder rrtr==1 zum direkten crc (rescount!)
       rec_crc_rescnt : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b1;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b1;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;

        next_state <= rec_crc_sample;
		end
//52///////////////////////////////////////////////////////////////////////////////
// smplpoint des crc/bits, direkt nächstes abwarten, oder zum delim/empfang
       rec_crc_sample : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b1;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (stuffr == 1'b1 && stferror == 1'b0) 
          next_state <= rec_crc_noshift;
        else if (stferror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (stferror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
// Eingefügt für stuff berichtigung
        else if (count == 15) 
          next_state <= rec_ack_recdelim;
        else
          next_state <= rec_crc_shifting;
        end
//53///////////////////////////////////////////////////////////////////////////////
// warten auf nächsten smplpoint des crc
//Änderung: actvrcrc <= 1'b1 , dann wird crc ins empfangsregister nachgeschoben        
       rec_crc_shifting : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b1;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b1;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b1;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
//        if(smplpoint == 1'b1 && count!=15)
        if (smplpoint == 1'b1) 
          next_state <= rec_crc_sample;
// gelöscht, stuff änderung
          //     else if(smplpoint == 1'b1 && count == 15)
          //       next_state <= rec_ack_recdelim;
// ende änderung
        else
          next_state <= rec_crc_shifting;
        end
//54///////////////////////////////////////////////////////////////////////////////
// stuffbit empfangen, ignorieren, auf nächsten smplpoint warten
       rec_crc_noshift : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b1;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= rec_crc_sample;
        else
          next_state <= rec_crc_noshift;
        end
// ende rec_crc, anfang rec_ack
//55///////////////////////////////////////////////////////////////////////////////
// Delimiter smplpoint, jetzt crc auswerten und zu give_ack oder give_noack verzweigen.
// hier stand ursprünglich: (crcrest == crcrecv) nun muß auf 0 getestet werden
// neues Signal crc_ok: 0==nicht ok, 1 ==ok. crc/änderung
       rec_ack_recdelim : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;

        if (inbit == 1'b1 && crc_ok == 1'b0) 
          next_state <= rec_ack_prepnoack;
//        if (inbit == 1'b1 && NOT (crcrest == crcrecv)) 
//          next_state <= rec_ack_prepnoack;
        else if (inbit == 1'b0 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (inbit == 1'b0 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else if (inbit == 1'b0 && busof == 1'b1) 
          next_state <= busoff_first;
        else
          next_state <= rec_ack_prepgiveack;
        end
//56///////////////////////////////////////////////////////////////////////////////
// vor dem ACK/slot, warten auf sendpoint um dominant zu senden
       rec_ack_prepgiveack : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b1;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b1;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= rec_ack_giveack;
        else
          next_state <= rec_ack_prepgiveack;
        end
//59///////////////////////////////////////////////////////////////////////////////
// Warten auf smplpoint des A_S
       rec_ack_giveack : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b1;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b1;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= rec_ack_checkack;
        else
          next_state <= rec_ack_giveack;
        end
//60///////////////////////////////////////////////////////////////////////////////
// smplpoint des A_S, Biterror checken, zum nächsten sendpoint nach stopack,
// EOF senden
       rec_ack_checkack : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (biterror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else if (sendpoint == 1'b1) 
          next_state <= rec_ack_stopack;
        else
          next_state <= rec_ack_checkack;
        end
//57///////////////////////////////////////////////////////////////////////////////
// auf sendpoint A_S warten, dann nach rec_ack_noack, rezessiv senden (setbrec!)
       rec_ack_prepnoack : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= rec_ack_noack;
        else
          next_state <= rec_ack_prepnoack;
        end
//58///////////////////////////////////////////////////////////////////////////////
// smplpoint des nicht gegebenen ACKs. Dann ab in einen Errorzustand.
       rec_ack_noack : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (smplpoint == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else if (smplpoint == 1'b1 && busof == 1'b1) 
          next_state <= busoff_first;
        else
          next_state <= rec_ack_noack;
        end
//61///////////////////////////////////////////////////////////////////////////////
// Warten auf smplpoint des ACK/Delim, dann nach rec_edof
       rec_ack_stopack : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= rec_edof_sample;
        else
          next_state <= rec_ack_stopack;
        end

// ende rec_ack, anfang rec_edof
// Änderungen: Receiver: valid, beim vorletzten bit des eof, neuer state:
// rec_edof_lastbit, dann ist decrec einen früher und das letzte Bit
// don't care
// alle 8 in 7 geändert und übergang von rec_edof_endrec nach rec_edof lastshift
//62///////////////////////////////////////////////////////////////////////////////
// smplpoint des EOF (fängt an mit A_D!!!). Also 8 rezessive. 
       rec_edof_sample : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (inbit == 1'b0 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (inbit == 1'b0 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else
          next_state <= rec_edof_check;
        end
//63///////////////////////////////////////////////////////////////////////////////
// wenn in sample alles ok war, auf nächsten smplpoint warten, ansonsten direkt
// nach endrec
       rec_edof_check : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (count != 7 && smplpoint == 1'b1) 
          next_state <= rec_edof_sample;
        else if (count == 7 && inbit == 1'b1) 
          next_state <= rec_edof_endrec;
// Das nur bei Transmitter
//        else if (count == 8 && inbit == 1'b0)  
//          next_state <= over_firstdom;
        else
          next_state <= rec_edof_check;
        end
//64///////////////////////////////////////////////////////////////////////////////
// decrec setzen (kurz nach smplpoint des 6. EOF bits), auf smplpoint des
// letzten EOF Bits warten
       rec_edof_endrec : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b1;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= rec_edof_lastbit;
        else
          next_state <= rec_edof_endrec;
        end
//125///////////////////////////////////////////////////////////////////////////////
// smplpoint des letzten EOF, hier ein biterror == overload
// neuer Zustand: letztes Bit EOF== don't care        
       rec_edof_lastbit : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (inbit == 1'b1) 
          next_state <= rec_edof_inter;  //inter_sample;
        else if (inbit == 1'b0) 
          next_state <= over_firstdom;
        else
          next_state <= rec_edof_lastbit;
        end
//126///////////////////////////////////////////////////////////////////////////////
// warten auf smplpoint des 1. Intermission Bits
// NEU, um einen Einstiegspunkt in unterteilter FSM in INTERFRAME zu haben
       rec_edof_inter : begin
        rext_set        <= 2'b00; rrtr_set <= 2'b00;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b11; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= inter_sample;
        else
          next_state <= rec_edof_inter;
        end
///////////////////////////////////////////////////////////////////////////////
// FSM/Unterteilung: Ende RECEIVE_CHECK
//                   Anfang OVERLOAD, Einziger Einstieg: 67,over_firstdom
/////////////////////////////////////////////////////////////////////////////// 
//67///////////////////////////////////////////////////////////////////////////////
// warten auf sendpoint fürs 1. Overload/Flag dom/ Bit (setbdom!)
       over_firstdom : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b1;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= over_senddomb;
        else
          next_state <= over_firstdom;
        end
//68///////////////////////////////////////////////////////////////////////////////
// Sendpoint: OV/Flag Bit senden, warten auf smplpoint
       over_senddomb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b1;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= over_check1;
        else
          next_state <= over_senddomb;
        end
//69///////////////////////////////////////////////////////////////////////////////
// smplpoint eines OV/Flag Bits (dominant)
       over_check1 : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b1;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1 && biterror == 1'b0 && count != 6) 
          next_state <= over_senddomb;
        else if (biterror == 1'b0 && count == 6) 
          next_state <= over_preprecb;
        else if (biterror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else if (biterror == 1'b1 && busof == 1'b1) 
          next_state <= busoff_first;
        else
          next_state <= over_check1;
        end
//70///////////////////////////////////////////////////////////////////////////////
// Auf sendpoint des 1. OV/Delim Bits warten
       over_preprecb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= over_wtonrecb;
        else
          next_state <= over_preprecb;
        end
//71///////////////////////////////////////////////////////////////////////////////
// Auf smplpoint eines rezessiven Bits warten
       over_wtonrecb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= over_check2;
        else
          next_state <= over_wtonrecb;
        end
//73///////////////////////////////////////////////////////////////////////////////
// mehr als 7 dominante Bits /> TEC+8 (wenn vorher Transmitter)
       over_inctracounter : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b1;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= over_check2;
        else
          next_state <= over_inctracounter;
        end
//72///////////////////////////////////////////////////////////////////////////////
// mehr als 7 dominante Bits /> REC+8 (wenn vorher Receiver)        
       over_increccounter : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b1;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= over_check2;
        else
          next_state <= over_increccounter;
        end
//74///////////////////////////////////////////////////////////////////////////////
// smplpoint, warten auf rezessives Bit, wenn nicht zurück nach wtonrecb, sonst
// nach prepsend
       over_check2 : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
//Änderung synth: < 7 in !=7 , invalid Cells weg
        if (sendpoint == 1'b1 && biterror == 1'b1 && count != 7) 
          next_state <= over_wtonrecb;
        else if (sendpoint == 1'b1 && biterror == 1'b1 && count == 7 && receiver == 1'b1) 
          next_state <= over_increccounter;
        else if (sendpoint == 1'b1 && biterror == 1'b1 && count == 7 && transmitter == 1'b1) 
          next_state <= over_inctracounter;
        else if (biterror == 1'b0) 
          next_state <= over_prepsend;
        else
          next_state <= over_check2;
        end
//78///////////////////////////////////////////////////////////////////////////////
// letzter smplpoint war rezessiv, also 1. Bit des Delim, warten auf sendpoint
// des 2. rezessiven Bits
       over_prepsend : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= over_sendrecb;
        else
          next_state <= over_prepsend;
        end
//75///////////////////////////////////////////////////////////////////////////////
// sendpoint: Rezessive Bits auf den Bus
       over_sendrecb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= over_check3;
        else
          next_state <= over_sendrecb;
        end
//76///////////////////////////////////////////////////////////////////////////////
// Smplpoint Delimiter, checken, bei Error: wenn noch nicht letztes Bit, dann
// zu Erroractiv/passiv, wenn letztes Bit: neuer Overload Rahmen
// Overload Regel: ist das letzte Bit des Overload/error Delimiters falsch,
// wird ein Overload Frame ausgelöst.        
       over_check3 : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1 && biterror == 1'b0 && count != 7) 
          next_state <= over_sendrecb;
        else if (biterror == 1'b0 && count == 7) 
          next_state <= over_waitoclk;
        else if (biterror == 1'b1 && count == 7) 
          next_state <= over_firstdom;
        else if (biterror == 1'b1 && erroractiv == 1'b1 && count != 7) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1 && count != 7) 
          next_state <= errorpassiv_firstrec;
        else if (biterror == 1'b1 && busof == 1'b1 && count != 7) 
          next_state <= busoff_first;
        else
          next_state <= over_check3;
        end
//77///////////////////////////////////////////////////////////////////////////////
// Auf den smplpoint des 1. Intermission Bits warten, und dann ab an den Anfang
       over_waitoclk : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= inter_sample;
        else
          next_state <= over_waitoclk;
        end
///////////////////////////////////////////////////////////////////////////////
// FSM/Unterteilung: Ende OVERLOAD
//                   Anfang ERRORACTIVE, Einziger Einstieg: 79,erroractiv_firstdom
/////////////////////////////////////////////////////////////////////////////// 
//79///////////////////////////////////////////////////////////////////////////////
// Fehlerzähler hochzählen (inceinsrec, incachtrec, inceinsrec), oder auf
// sendpoint warten, wenn aus Arbitrierung gekommen
       erroractiv_firstdom : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b1;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b00;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b00; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1 && onarbit == 1'b1) 
          next_state <= erroractiv_senddomb;
        else if (onarbit == 1'b0 && transmitter == 1'b0 && receiver == 1'b1 && error == 1'b0) 
          next_state <= erroractiv_inceinsrec;
        else if (onarbit == 1'b0 && transmitter == 1'b0 && receiver == 1'b1 && error == 1'b1) 
          next_state <= erroractiv_incachtrec;
        else if (onarbit == 1'b0 && transmitter == 1'b1) 
          next_state <= erroractiv_incachttra;
        else
          next_state <= erroractiv_firstdom;
        end
//80///////////////////////////////////////////////////////////////////////////////
// REC+1, auf sendpoint für 1. dom. Bit Flag warten
       erroractiv_inceinsrec : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b1;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b1;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= erroractiv_senddomb;
        else
          next_state <= erroractiv_inceinsrec;
        end
//81///////////////////////////////////////////////////////////////////////////////
// REC+8, auf sendpoint für 1. dom. Bit Flag warten        
       erroractiv_incachtrec : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b1;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b1;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= erroractiv_senddomb;
        else
          next_state <= erroractiv_incachtrec;
        end
//82///////////////////////////////////////////////////////////////////////////////
// TEC+8, auf sendpoint für 1. dom. Bit Flag warten        
       erroractiv_incachttra : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b1;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b1;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= erroractiv_senddomb;
        else
          next_state <= erroractiv_incachttra;
        end
//83///////////////////////////////////////////////////////////////////////////////
// Sendpoint Errorflag
       erroractiv_senddomb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b1;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= erroractiv_check1;
        else
          next_state <= erroractiv_senddomb;
        end
//84///////////////////////////////////////////////////////////////////////////////
// smplpoint eines dom. Bit des Flags, wenn schon 6, dann weiter nach _preprecb
       erroractiv_check1 : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b1;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1 && biterror == 1'b0 && count != 6) 
          next_state <= erroractiv_senddomb;
        else if (biterror == 1'b0 && count == 6) 
          next_state <= erroractiv_preprecb;
        else if (biterror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else if (biterror == 1'b1 && busof == 1'b1) 
          next_state <= busoff_first;
        else
          next_state <= erroractiv_check1;
        end
//85///////////////////////////////////////////////////////////////////////////////
// warten auf sendpoint des 1. Bits nach eigenem Flag
       erroractiv_preprecb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= erroractiv_wtonrecb;
        else
          next_state <= erroractiv_preprecb;
        end
//86///////////////////////////////////////////////////////////////////////////////
// warten auf smplpoint, erwarte rezessive bits, mein flag ist vorbei
       erroractiv_wtonrecb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b00;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= erroractiv_check2;
        else
          next_state <= erroractiv_wtonrecb;
        end
//87///////////////////////////////////////////////////////////////////////////////
// Eigenes Error Flag beendet, war receiver und das 1. Bit nach eigenem Flag
// ist dominant, direkt den REC um weitere 8 erhöhen. auf nächsten smplpoint
// warten um nach rezessivem bit zu suchen
       erroractiv_dombitdct : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b1;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= erroractiv_check2;
        else
          next_state <= erroractiv_dombitdct;
        end
//89///////////////////////////////////////////////////////////////////////////////
// mehr als 14 dominante bits und ich war Receiver/> REC+8
       erroractiv_egtdombr : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b1;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= erroractiv_check2;
        else
          next_state <= erroractiv_egtdombr;
        end

//88///////////////////////////////////////////////////////////////////////////////
// mehr als 14 dominante Bits und ich war Transmitter/> TEC+8
// Falsch: inconerec ==1'b1 | Richtig: incegttra==1'b1
       erroractiv_egtdombt : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b1;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= erroractiv_check2;
        else
          next_state <= erroractiv_egtdombt;
        end
//90///////////////////////////////////////////////////////////////////////////////
// Es ist smplpoint. Warten auf rezessives Bit, dann zu _prepsend. Kommt keins,
// dann REC+8, wenn 1. dom Bit, REC oder TEC+8, wenn 8 weitere dominante
       erroractiv_check2 : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b00;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if(sendpoint == 1'b1 && biterror == 1'b1 && count != 7 &&(count != 1 || receiver == 1'b0 || first == 1'b0))
        
          next_state <= erroractiv_wtonrecb;
        else if(sendpoint == 1'b1 && biterror == 1'b1 && count == 1 && receiver == 1'b1 && first == 1'b1) 
          next_state <= erroractiv_dombitdct;
        else if(sendpoint == 1'b1 && biterror == 1'b1 && count == 7 && transmitter == 1'b1 && receiver == 1'b0) 
          next_state <= erroractiv_egtdombt;
        else if(sendpoint == 1'b1 && biterror == 1'b1 && count == 7 && transmitter == 1'b0 && receiver == 1'b1) 
          next_state <= erroractiv_egtdombr;
        else if (biterror == 1'b0) 
          next_state <= erroractiv_prepsend;
        else
          next_state <= erroractiv_check2;
        end
//94///////////////////////////////////////////////////////////////////////////////
// Warten auf sendpoint für rezessiven Delimiter
       erroractiv_prepsend : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= erroractiv_sendrecb;
        else
          next_state <= erroractiv_prepsend;
        end
//91///////////////////////////////////////////////////////////////////////////////
// Sendpoint: Rezessiv mitsenden, auf smplpoint warten
       erroractiv_sendrecb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b1;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= erroractiv_check3;
        else
          next_state <= erroractiv_sendrecb;
        end
//92//////////////////////////////////////////////////////////////////////////////
// smplpoint: Delimiter checken, wenn dominant, wieder von vorne anfnagen
       erroractiv_check3 : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b1;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1 && biterror == 1'b0 && count != 7) 
          next_state <= erroractiv_sendrecb;
        else if (sendpoint == 1'b1 && biterror == 1'b0 && count == 7) 
          next_state <= erroractiv_waitoclk;
        else if (biterror == 1'b1 && erroractiv == 1'b1) 
          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else if (biterror == 1'b1 && busof == 1'b1) 
          next_state <= busoff_first;
        else
          next_state <= erroractiv_check3;
        end
//93///////////////////////////////////////////////////////////////////////////////
// auf smplpoint nach Delimiter warten, dann wieder von vorne, Intermission
       erroractiv_waitoclk : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b1;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b1;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= inter_sample;
        else
          next_state <= erroractiv_waitoclk;
        end
///////////////////////////////////////////////////////////////////////////////
// FSM/Unterteilung: Ende ERRORACTIVE
//                   Anfang ERRORPASSIVE, Einziger Einstieg: 95,errorpassiv_firstrec
/////////////////////////////////////////////////////////////////////////////// 
//95///////////////////////////////////////////////////////////////////////////////
// warten auf sendpoint des 1. rez Flag oder REC/TEC erhöhen gehen
       errorpassiv_firstrec : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b00;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b00; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1 && transmitter == 1'b1 && (onarbit == 1'b1 || ackerror == 1'b1)) 
          next_state <= errorpassiv_incsrecb;
        else if (onarbit == 1'b0 && transmitter == 1'b0 && receiver == 1'b1 && error == 1'b0) 
          next_state <= errorpassiv_inceinsrec;
        else if (onarbit == 1'b0 && transmitter == 1'b0 && receiver == 1'b1 && error == 1'b1) 
          next_state <= errorpassiv_incachtrec;
        else if (onarbit == 1'b0 && transmitter == 1'b1 && ackerror == 1'b0) 
          next_state <= errorpassiv_incachttra;
        else
          next_state <= errorpassiv_firstrec;
        end
//96///////////////////////////////////////////////////////////////////////////////
// REC+1, warten auf sendpoint 1. rez. Flag
       errorpassiv_inceinsrec : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b1;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= errorpassiv_incsrecb;
        else
          next_state <= errorpassiv_inceinsrec;
        end
//97///////////////////////////////////////////////////////////////////////////////
// REC+8, warten auf sendpoint 1. rez. Flag
       errorpassiv_incachtrec : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b1;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= errorpassiv_incsrecb;
        else
          next_state <= errorpassiv_incachtrec;
        end
//99///////////////////////////////////////////////////////////////////////////////
// TEC+8, warten auf sendpoint 1. rez. Flag
       errorpassiv_incachttra : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b1;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= errorpassiv_incsrecb;
        else
          next_state <= errorpassiv_incachttra;
        end
//100///////////////////////////////////////////////////////////////////////////////
// warten auf smplpoint 1. rez. Bit Flag
       errorpassiv_incsrecb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b00;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1 && count != 0) 
          next_state <= errorpassiv_check1;
        else if (smplpoint == 1'b1 && count == 0) 
          next_state <= errorpassiv_fillpuffer;
        else
          next_state <= errorpassiv_incsrecb;
        end
//98///////////////////////////////////////////////////////////////////////////////
// 1. rez. Bit, Puffer auf 0 setzen; wenn dominant auf Bus: 1. Sender und
// Ackerror nach _pufferdomi, sonst nach _pufferdom, sonst _pufferrec
       errorpassiv_fillpuffer : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if(inbit == 1'b0 && transmitter == 1'b1 && ackerror == 1'b1) 
          next_state <= errorpassiv_pufferdomi;
        else if(inbit == 1'b0 && (transmitter == 1'b0 || ackerror == 1'b0)) 
          next_state <= errorpassiv_pufferdom;
        else
          next_state <= errorpassiv_pufferrec;
        end
//102///////////////////////////////////////////////////////////////////////////////
// Puffer auf 1, da 1. Bit rez. geblieben ist, auf sendpoint 2. Bit warten
       errorpassiv_pufferrec : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b11;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if(sendpoint == 1'b1) 
          next_state <= errorpassiv_incsrecb;
        else
          next_state <= errorpassiv_pufferrec;
        end
//106///////////////////////////////////////////////////////////////////////////////
// Puffer auf 0, da 1. rez. Bit domi überschrieben, auf sendpoint warten, kein
// Erhöhung Fehlerzähler, da Ackerror (Exception 1 von Regel 3)
       errorpassiv_pufferdom : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if(sendpoint == 1'b1) 
          next_state <= errorpassiv_incsrecb;
        else
          next_state <= errorpassiv_pufferdom;
        end
//110///////////////////////////////////////////////////////////////////////////////
// Puffer auf 0, da 1. rez. Bit dom. überschrieben, auf sendpoint warten,
// TEC+8, da Transmitter gewesen, aber kein Ackerror
       errorpassiv_pufferdomi : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b1;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if(sendpoint == 1'b1) 
          next_state <= errorpassiv_incsrecb;
        else
          next_state <= errorpassiv_pufferdomi;
        end
//104///////////////////////////////////////////////////////////////////////////////
// vorher domi, jetzt rezessiv, puffer auf 1 setzen, dann nach _newcount
       errorpassiv_zersrecbo : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b11;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        next_state      <= errorpassiv_newcount;
		end
//103///////////////////////////////////////////////////////////////////////////////
// vorher rez., jetzt domi, puffer auf 0 setzen, dann _newcount
       errorpassiv_zersrecbz : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        next_state      <= errorpassiv_newcount;
		end
//101///////////////////////////////////////////////////////////////////////////////
// vorher rez., jetzt dom. , vorher aber kein TEC+8, wg. Sender und Ackerror
// (Ausnahme 1) dann jetzt aber TEC+8
       errorpassiv_zersrecbi : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b1;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        next_state      <= errorpassiv_newcount;
		end
//118///////////////////////////////////////////////////////////////////////////////
// Es wurde während des 2..6. Bit des Flags ein Bitwechsel entdeckt, die
// Zählung beginnt von neuem (rescount!)
       errorpassiv_newcount : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b00;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        next_state      <= errorpassiv_prepcount;
		end
//119///////////////////////////////////////////////////////////////////////////////
// Zähler wurde zurückgesetzt, auf 1. Bit smplpoint warten
       errorpassiv_prepcount : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b00;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= errorpassiv_check1;
        else
          next_state <= errorpassiv_prepcount;
        end
//105///////////////////////////////////////////////////////////////////////////////
// smplpoint aktuelles flagbit. Normal: warten auf sendpoint nächstes gleiches
// Bit, oder übergang nach Delimiter. Wenn Änderung, über _zersrecbz,
// _zersrecbi, zersrecbo nach _newcount und von vorne 6 gleiche suchen.
       errorpassiv_check1 : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b00;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b00;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if(sendpoint == 1'b1 && biterror == puffer && biterror == 1'b1 && transmitter == 1'b1 && ackerror == 1'b1)
        
          next_state <= errorpassiv_zersrecbi;
        else if(sendpoint == 1'b1 && biterror == puffer && biterror == 1'b1 &&(ackerror == 1'b0 || transmitter == 1'b0))
        
          next_state <= errorpassiv_zersrecbz;
        else if(sendpoint == 1'b1 && biterror == puffer && biterror == 1'b0) 
          next_state <= errorpassiv_zersrecbo;
        else if (sendpoint == 1'b1 && biterror != puffer && count != 6) 
          next_state <= errorpassiv_incsrecb;
        else if (biterror != puffer && count == 6) 
          next_state <= errorpassiv_preprecb;
        else
          next_state <= errorpassiv_check1;
        end
//117///////////////////////////////////////////////////////////////////////////////
// Abschluss des Flags, es wurden 6 rez. oder dom. Bit gefunden, warten auf
// sendpoint des nächsten Bits (vielleicht ein rezessives, oder auch nicht)
       errorpassiv_preprecb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b11;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= errorpassiv_wtonrecb;
        else
          next_state <= errorpassiv_preprecb;
        end
//107///////////////////////////////////////////////////////////////////////////////
// warten auf smplpoint des aktuellen Bits (erwarte rez. Delimiter)
       errorpassiv_wtonrecb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b00;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= errorpassiv_check2;
        else
          next_state <= errorpassiv_wtonrecb;
        end
//108///////////////////////////////////////////////////////////////////////////////
// noch dominant nach flag, aber nicht Fehlerzähler erhöhen (hier first auf 0!)
// auf nächsten smplpoint warten für _check2
       errorpassiv_dombitdct : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b1;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= errorpassiv_check2;
        else
          next_state <= errorpassiv_dombitdct;
        end
//111///////////////////////////////////////////////////////////////////////////////
// 7 weitere dominante entdeckt und receiver gewesen /> REC+8
// warten auf smplpoint für _check2
       errorpassiv_egtdombr : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b1;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= errorpassiv_check2;
        else
          next_state <= errorpassiv_egtdombr;
        end
//109///////////////////////////////////////////////////////////////////////////////
// 7 weitere dominante entdeckt und transmitter gewesen /> TEC+8
// warten auf smplpoint für _check2
       errorpassiv_egtdombt : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b1;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= errorpassiv_check2;
        else
          next_state <= errorpassiv_egtdombt;
        end
//112///////////////////////////////////////////////////////////////////////////////
// smplpoint des aktuellen bits, warten auf delimiter. Wenn 1.Bit noch dominant,
// Zähler erhöhen (_egtdombx), sonst warten (_wtonrecb)
       errorpassiv_check2 : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b00;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if(sendpoint == 1'b1 && biterror == 1'b1 && count != 7 &&(count != 1 || receiver == 1'b0 || first == 1'b0))
        
          next_state <= errorpassiv_wtonrecb;
        else if(sendpoint == 1'b1 && biterror == 1'b1 && count == 1 && receiver == 1'b1 && first == 1'b1) 
          next_state <= errorpassiv_dombitdct;
        else if(sendpoint == 1'b1 && biterror == 1'b1 && count == 7 && transmitter == 1'b1 && receiver == 1'b0) 
          next_state <= errorpassiv_egtdombt;
        else if(sendpoint == 1'b1 && biterror == 1'b1 && count == 7 && transmitter == 1'b0 && receiver == 1'b1) 
          next_state <= errorpassiv_egtdombr;
        else if (biterror == 1'b0) 
          next_state <= errorpassiv_prepsend;
        else
          next_state <= errorpassiv_check2;
        end
//116///////////////////////////////////////////////////////////////////////////////
// endlich ein rezessives Bit, der Delimiter beginnt (warten auf nächsten sendpoint)
       errorpassiv_prepsend : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1) 
          next_state <= errorpassiv_sendrecb;
        else
          next_state <= errorpassiv_prepsend;
        end
//113///////////////////////////////////////////////////////////////////////////////
// Delimiter: mitsenden rezessiv, warten auf smplpoint für _check3
       errorpassiv_sendrecb : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b1;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b1;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b1;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= errorpassiv_check3;
        else
          next_state <= errorpassiv_sendrecb;
        end
//114///////////////////////////////////////////////////////////////////////////////
// checken des Delimiters, warten auf nächsten Sendpoint. Delimiter gestört,/
// dann wieder von vorne oder Busoff, ansonsten Zähler ok, ab zu _waitoclk
       errorpassiv_check3 : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b1;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b1;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (sendpoint == 1'b1 && biterror == 1'b0 && count != 7) 
          next_state <= errorpassiv_sendrecb;
        else if (sendpoint == 1'b1 && biterror == 1'b0 && count == 7) 
          next_state <= errorpassiv_waitoclk;
// Controller geht nicht von EP nach EA, während EP Delimiter
//        else if (biterror == 1'b1 && erroractiv == 1'b1) 
//          next_state <= erroractiv_firstdom;
        else if (biterror == 1'b1 && errorpassiv == 1'b1) 
          next_state <= errorpassiv_firstrec;
        else if (biterror == 1'b1 && busof == 1'b1) 
          next_state <= busoff_first;
        else
          next_state <= errorpassiv_check3;
        end
//115///////////////////////////////////////////////////////////////////////////////
// warten auf smplpoint 1. Intermission bit, dann an den Anfang
       errorpassiv_waitoclk : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b1;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b0;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b1;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b00; receiver_set <= 2'b00; error_set <= 2'b11;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= inter_sample;
        else
          next_state <= errorpassiv_waitoclk;
        end

///////////////////////////////////////////////////////////////////////////////
// FSM/Unterteilung: Ende ERRORPASSIVE
//                   Anfang BUSOFF, Einziger Einstieg: 120,busoff_first
/////////////////////////////////////////////////////////////////////////////// 
//120///////////////////////////////////////////////////////////////////////////////
// warten auf 1. Smplpoint, counter resetten (rescount!)
       busoff_first : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= busoff_sample;
        else
          next_state <= busoff_first;
        end
//121///////////////////////////////////////////////////////////////////////////////
// smplpoint aktuelles bit, wenn rez, zähler erhöhen, wenn dom. zähler resetten
       busoff_sample : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b1;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (inbit == 1'b1 && count != 10) 
          next_state <= busoff_increm;
        else if (inbit == 1'b1 && count == 10) 
          next_state <= busoff_deccnt;
        else
          next_state <= busoff_setzer;
        end
//123///////////////////////////////////////////////////////////////////////////////
// war rez., zähler erhöhen, auf nächsten smplpoint warten
       busoff_increm : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b1;     rescount <= 1'b1;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= busoff_sample;
        else
          next_state <= busoff_increm;
        end
//122///////////////////////////////////////////////////////////////////////////////
// war dominant, keine 11 gleichen hintereinander, zähler resetten, nächsten
// smplpoint abwarten
       busoff_setzer : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b0;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b1;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1) 
          next_state <= busoff_sample;
        else
          next_state <= busoff_setzer;
        end
//124///////////////////////////////////////////////////////////////////////////////
// war rez., und das 11. Bit, Signal elevrecb für FCE (128 davon== Ende Busoff),
// counter zurücksetzen, auf nächsten smplpoint warten.
       busoff_deccnt : begin
        rext_set        <= 2'b10; rrtr_set <= 2'b10;     actvtcrc <= 1'b0;
        actvrcrc        <= 1'b0;  actvtstf <= 1'b0;      actvrstf <= 1'b0;     actvtsft <= 1'b0;
        actvrsft        <= 1'b0;  actvtdct <= 1'b0;      actvrdct <= 1'b1;     actvtbed <= 1'b0;
        setbdom         <= 1'b0;  setbrec <= 1'b0;       lcrc <= 1'b0;           tshift <= 1'b0;
        inconerec       <= 1'b0;  incegtrec <= 1'b0;     incegttra <= 1'b0;    lmsg <= 1'b0;
        decrec          <= 1'b0;  dectra <= 1'b0;        elevrecb <= 1'b1;     hardsync <= 1'b0;
        resetdst        <= 1'b1;  resetstf <= 1'b0;      inccount <= 1'b0;     rescount <= 1'b0;
        setrmleno       <= 0;    actvrmln <= 1'b0;      resrmlen <= 1'b1;     ackerror_set <= 2'b10;
        transmitter_set <= 2'b10; receiver_set <= 2'b10; error_set <= 2'b10;   first_set <= 2'b10;
        activatefast    <= 1'b0;  puffer_set <= 2'b10;   onarbit_set <= 2'b10; en_zerointcrc <= 1'b1; 
        crc_shft_out <= 1'b0;
        if (smplpoint == 1'b1 && busof == 1'b1) 
          next_state <= busoff_sample;
        else if (smplpoint == 1'b1 && busof == 1'b0) 
          next_state <= inter_sample;
        else
          next_state <= busoff_deccnt;
        end
       default : begin
 //       next_state <= sync_start;
	     end	
	   endcase
end
///////////////////////////////////////////////////////////////////////////////

endmodule

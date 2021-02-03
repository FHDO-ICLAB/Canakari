-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                      Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: macfsm.vhd
--                     Beschreibung: mac Zustandsautomat
-------------------------------------------------------------------------------
-- Auslagerung von Latches in FSM_register: rext,rrtr,transmitter, receiver,
-- error, first, puffer, onarbit. Für alle gilt:
-- signalxx_set="11"; -- auf 1 setzen
-- signalxx_set="10"; -- auf 0 setzen
-- signalxx_set="00"; -- Unverändert lassen;
-- signalxx_set="01"; --         "
-------------------------------------------------------------------------------
-- alle resetsignale gedreht (reset=0, normal betrieb 1)
-- DW 2005.06.30 Prescale Enable eingefügt.
-- DW 2005.06.30 Aus dem synchronen Reset wird ein asynchroner Reset.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
LIBRARY synopsys;
USE synopsys.attributes.ALL;

ENTITY macfsm1 IS
  PORT( clock           : IN  bit;      -- prescaler
        Prescale_EN     : IN  bit;      -- DW 2005.06.30 Prescale Enable eingefügt
        reset           : IN  bit;      -- Mac-reset
        sendpoint       : IN  bit;      -- bittiming
        smplpoint       : IN  bit;      -- bittiming
        crc_ok          : IN  bit;      -- rcrc (1, wenn reg alle 0)
        inbit           : IN  bit;      -- destuffing
        stufft          : IN  bit;      -- stuffing (transmit)
        stuffr          : IN  bit;      -- destuffing (receive)
        biterror        : IN  bit;      -- biterrordetect
        stferror        : IN  bit;      -- destuff
        trans           : IN  bit;      -- llc, start transmission
        text            : IN  bit;      -- IOCPU, transmesconreg
        erroractiv      : IN  bit;      -- FCE FSM
        errorpassiv     : IN  bit;      -- FCE FSM
        busof           : IN  bit;      -- FCE FSM
        ackerror        : IN  bit;      -- FSM_register (wird hier gesetzt)
        onarbit         : IN  bit;      -- FSM_register (wird hier gesetzt)
        transmitter     : IN  bit;      -- FSM_register (wird hier gesetzt)
        receiver        : IN  bit;      -- FSM_register (wird hier gesetzt)
        error           : IN  bit;      -- FSM_register (wird hier gesetzt)
        first           : IN  bit;      -- FSM_register (wird hier gesetzt)
        puffer          : IN  bit;      -- FSM_register (wird hier gesetzt)
        rext            : IN  bit;      -- FSM_register (wird hier gesetzt)
        rrtr            : IN  bit;      -- FSM_register (wird hier gesetzt)
        lt3, gt3, eq3   : IN  bit;      -- counter <,>,= 3, Intermiss. , erract
        lt11, eq11      : IN  bit;      -- counter <,= 11, Intermiss., errpass
        startrcrc       : IN  bit;      -- meslencompare, Datenfeld vorbei
        rmzero          : IN  bit;      -- meslencompare, Datenfeld=0,
                                        -- rec_acptdat überspringen
        starttcrc       : IN  bit;      -- meslencompare, crc senden signal
        ackerror_set    : OUT bit_vector(1 DOWNTO 0);  -- fsm_register
        onarbit_set     : OUT bit_vector(1 DOWNTO 0);  -- fsm_register
        transmitter_set : OUT bit_vector(1 DOWNTO 0);  -- fsm_register
        receiver_set    : OUT bit_vector(1 DOWNTO 0);  -- fsm_register
        error_set       : OUT bit_vector(1 DOWNTO 0);  -- fsm_register
        first_set       : OUT bit_vector(1 DOWNTO 0);  -- fsm_register
        puffer_set      : OUT bit_vector(1 DOWNTO 0);  -- fsm_register
        rext_set        : OUT bit_vector(1 DOWNTO 0);  -- fsm_register
        rrtr_set        : OUT bit_vector(1 DOWNTO 0);  -- fsm_register
        count           : IN  integer RANGE 0 TO 127;  -- counter
        setrmleno       : OUT integer RANGE 0 TO 7;  -- recmeslen, empfangs-
                                                     -- dlc(in mesg)
        actvrmln        : OUT bit;      -- recmeslen, activate 
        actvtcrc        : OUT bit;      -- tcrc, active
        actvrcrc        : OUT bit;      -- rcrc, active
        actvtstf        : OUT bit;      -- stuffing, active
        actvrstf        : OUT bit;      -- destuffing, active
        actvtsft        : OUT bit;      -- tshift, active
        actvrsft        : OUT bit;      -- rshift, active
        actvtdct        : OUT bit;      -- stuffing, direct
        actvrdct        : OUT bit;      -- destuffing, direct
        actvtbed        : OUT bit;      -- biterrordetect, active
        setbdom         : OUT bit;      -- stuffing, setdom
        setbrec         : OUT bit;      -- stuffing, setrec
        lcrc            : OUT bit;      -- rshift, bei crc nicht active; 
        lmsg            : OUT bit;      -- tshift, tcrc, (vor-)laden der register
        tshift          : OUT bit;      -- tshift, schieben enable, dann actvtsft
        inconerec       : OUT bit;      -- FCE, rec
        incegtrec       : OUT bit;      -- FCE, rec
        incegttra       : OUT bit;      -- FCE, tec
        decrec          : OUT bit;      -- FCE, rec
        dectra          : OUT bit;      -- FCE, tec
        elevrecb        : OUT bit;      -- FCE, erbcount
        hardsync        : OUT bit;      -- bittiming fsm
        inccount        : OUT bit;      -- counter
        resrmlen        : OUT bit;      -- recmeslen, reset(in mac OR mit reset)
        rescount        : OUT bit;      -- counter, reset (in mac OR mit reset)
        resetdst        : OUT bit;      -- destuffing, reset ( " )
        resetstf        : OUT bit;      -- stuffing, reset ( " )
        activatefast    : OUT bit;      -- fastshift, startsignal
        crc_shft_out    : OUT bit;      -- tcrc wird sendeschieberegister
        en_zerointcrc   : OUT bit;
        statedeb        : OUT std_logic_vector(7 DOWNTO 0)  -- fsm debug
        );     -- meslencompare, enable für
 
END macfsm1;


ARCHITECTURE behv OF macfsm1 IS
  -- FSM-VSS-interna: Die Reihenfolge der States hier entspricht der Zahl, die
  -- man liest, wenn man current_state als Integer Wert verarbeitet. Zählung
  -- beginnt mit 0. (streamaker.c FSM-Übergangsüberwachung)
  TYPE state_type IS
    (sync_start, sync_sample, sync_sum, sync_end,
     inter_sample, inter_check, inter_goregtran, inter_react,
     bus_idle_chk, bus_idle_sample,
     inter_transhift, inter_regtrancnt, inter_preprec, inter_incsigres,
     tra_arbit_tactrsftn, tra_arbit_tactrsftsr, tra_arbit_tactrsfte, tra_arbit_tactrsfter,
     tra_arbit_tnactrnsft, tra_arbit_tsftrsmpl, tra_arbit_tnsftrsmpl, tra_arbit_goreceive,
     tra_data_activatecrc,
     tra_data_activatncrc, tra_data_shifting, tra_data_noshift, tra_data_lastshift,
     tra_data_loadcrc, tra_crc_activatedec, tra_crc_activatndec, tra_crc_shifting,
     tra_crc_noshift, tra_crc_delshft,
     tra_ack_sendack, tra_ack_shifting, tra_ack_stopack,
     tra_edof_sendrecb, tra_edof_shifting, rec_flglen_sample,
     rec_flglen_shiftstdrtr, rec_flglen_shiftextnor, rec_flglen_shiftdlc64, rec_flglen_shiftdlc32,
     rec_flglen_shiftdlc16, rec_flglen_shiftdlc8, rec_flglen_shiftextrtr, rec_flglen_shifting,
     rec_flglen_noshift, rec_acptdat_sample, rec_acptdat_shifting, rec_acptdat_noshift,
     rec_crc_rescnt, rec_crc_sample, rec_crc_shifting, rec_crc_noshift, rec_ack_recdelim,
     rec_ack_prepgiveack, rec_ack_prepnoack, rec_ack_noack, rec_ack_giveack,
     rec_ack_checkack, rec_ack_stopack, rec_edof_sample, rec_edof_check,
     rec_edof_endrec, rec_flglen_setdlc, rec_acptdat_lastshift,
     over_firstdom, over_senddomb, over_check1, over_preprecb,
     over_wtonrecb, over_increccounter, over_inctracounter, over_check2,
     over_sendrecb, over_check3, over_waitoclk, over_prepsend,
     erroractiv_firstdom, erroractiv_inceinsrec, erroractiv_incachtrec, erroractiv_incachttra,
     erroractiv_senddomb, erroractiv_check1, erroractiv_preprecb, erroractiv_wtonrecb,
     erroractiv_dombitdct, erroractiv_egtdombt, erroractiv_egtdombr, erroractiv_check2,
     erroractiv_sendrecb, erroractiv_check3, erroractiv_waitoclk, erroractiv_prepsend,
     errorpassiv_firstrec, errorpassiv_inceinsrec, errorpassiv_incachtrec, errorpassiv_fillpuffer,
     errorpassiv_incachttra, errorpassiv_incsrecb, errorpassiv_zersrecbi, errorpassiv_pufferrec,
     errorpassiv_zersrecbz, errorpassiv_zersrecbo, errorpassiv_check1, errorpassiv_pufferdom,
     errorpassiv_wtonrecb, errorpassiv_dombitdct, errorpassiv_egtdombt, errorpassiv_pufferdomi,
     errorpassiv_egtdombr, errorpassiv_check2, errorpassiv_sendrecb, errorpassiv_check3,
     errorpassiv_waitoclk, errorpassiv_prepsend, errorpassiv_preprecb, errorpassiv_newcount,
     errorpassiv_prepcount,
     busoff_first, busoff_sample, busoff_setzer, busoff_increm,
     busoff_deccnt, rec_edof_lastbit, rec_edof_inter, tra_edof_dectra,
     inter_preprec_shifting, inter_arbit_tsftrsmpl );

  SIGNAL current_state, next_state : STATE_TYPE;

-- The next two lines are aynopsys state machine attributes
-- see chapter 4, section on state vector attributes

  ATTRIBUTE state_vector         : string;
  ATTRIBUTE state_vector OF behv : ARCHITECTURE IS "current_state";

BEGIN
  combin : PROCESS(current_state, sendpoint, smplpoint, crc_ok, inbit, stufft, stuffr, biterror,
                   stferror, trans, text, erroractiv, errorpassiv, busof, count, rext, rrtr, ackerror,
                   onarbit, transmitter, receiver, error, first, puffer, lt3, gt3, eq3, lt11, eq11,
                   rmzero, startrcrc, starttcrc)
  BEGIN

    rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
    actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
    actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
    setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';         tshift <= '0';
    inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
    decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
    resetstf        <= '1';  hardsync <= '1';      inccount <= '0';     rescount <= '0';
    setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '0';     ackerror_set <= "10";
    transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
    activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1';
    crc_shft_out <= '0';
    next_state      <= current_state;

    CASE current_state IS
------------------------------- start synchronization  -------------------------------------------
-------------------------------------------------------------------------------
-- FSM-Unterteilung: Anfang SYNC, Einziger Einstieg: 0, sync_start
-------------------------------------------------------------------------------      
--0-------------------------------------------------------------------------------
      WHEN sync_start =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '0';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= sync_sample;
        ELSE
          next_state <= sync_start;
        END IF;
--1-------------------------------------------------------------------------------        
      WHEN sync_sample =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (inbit = '1') THEN
          next_state <= sync_sum;
        ELSE
          next_state <= sync_start;
        END IF;
--2-------------------------------------------------------------------------------
-- Abfrage counter,- dann ende sync
      WHEN sync_sum =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1' AND count /= 8) THEN
          next_state <= sync_sample;
        ELSIF count = 8 THEN
          next_state <= sync_end;
        ELSE
          next_state <= sync_sum;
        END IF;
--3-------------------------------------------------------------------------------
-- Warten auf smplpoint, dann nach !bus_idle!
      WHEN sync_end =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= bus_idle_sample;  -- inter_sample; keine intermission Zeit!
        ELSE
          next_state <= sync_end;
        END IF;

-------------------------------------------------------------------------------
-- FSM-Unterteilung: Ende SYNC
--                   Anfang INTERFRAME, Einziger Einstieg: 4, inter_sample
-------------------------------------------------------------------------------      
--4-------------------------------------------------------------------------------
-- nach dem samplezeitpunkt, senden, empfangen, overload oder arbitrierung
      WHEN inter_sample =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '0'; 
        crc_shft_out <= '0';

        IF (busof = '1') THEN
          next_state <= busoff_first;
        ELSIF ((((errorpassiv = '0' OR receiver = '1') AND lt3 = '1')OR((errorpassiv = '1' AND receiver = '0') AND lt11 = '1')) AND inbit = '1') THEN
          next_state <= inter_check;
        ELSIF (lt3 = '1' AND inbit = '0') THEN
          next_state <= over_firstdom;
          -- overload
        ELSIF (inbit = '0' AND (gt3 = '1' OR ((eq3 = '1' OR gt3 = '1') AND((errorpassiv = '1' AND receiver = '0') OR trans = '0')))) THEN
          next_state <= inter_preprec;
--nochne Einsparung: aus >=3 und >=11 wurde =3 und =11
--DW 2005.07.01: eq3 = '1' wird ersetzt durch (eq3 = '1' OR gt3 = '1'), damit
--ein Zählerstand auch abgefangen wird.
        ELSIF (sendpoint = '1'AND(((errorpassiv = '0' OR receiver = '1')AND (eq3 = '1' OR gt3 = '1'))OR((errorpassiv = '1' AND receiver = '0')AND (eq11 = '1' or lt11 = '0'))) AND inbit = '1' AND trans = '1') THEN  --DW 2005.07.01: eq3 = '1' wird ersetzt durch (eq3 = '1' OR gt3 = '1'), damit
--ein Zählerstand auch abgefangen wird.
          next_state <= inter_goregtran;
        ELSIF ((errorpassiv = '0' OR receiver = '1') AND (eq3 = '1' OR gt3 = '1') AND inbit = '0' AND trans = '1') THEN  --DW 2005.07.01: eq3 = '1' wird ersetzt durch (eq3 = '1' OR gt3 = '1'), damit
--ein Zählerstand auch abgefangen wird.
          next_state <= inter_react;
        ELSIF trans = '0'AND(((eq3 = '1' OR gt3 = '1') AND (errorpassiv = '0' OR receiver = '1'))OR( (eq11 = '1' or lt11 = '0') AND (errorpassiv = '1' AND receiver = '0'))) THEN  --DW 2005.07.01: eq3 = '1' wird ersetzt durch (eq3 = '1' OR gt3 = '1'), damit
--ein Zählerstand auch abgefangen wird.
          next_state <= bus_idle_chk;
        ELSE
          next_state <= inter_sample;
        END IF;
--5-------------------------------------------------------------------------------
-- auf nächsten smplpoint warten
      WHEN inter_check =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '0';
        resetstf        <= '1';  hardsync <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '0'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= inter_sample;
        ELSE
          next_state <= inter_check;
        END IF;
--8-------------------------------------------------------------------------------
-- bus_idle, kein overload mehr bei counter überlauf (bus_idle_chk=inter_check)
      WHEN bus_idle_chk =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '0';
        resetstf        <= '1';  hardsync <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '0'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= bus_idle_sample;
        ELSE
          next_state <= bus_idle_chk;
        END IF;
--9-------------------------------------------------------------------------------
-- entspricht inter_sample , kein inccount!
      WHEN bus_idle_sample =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '0'; 
        crc_shft_out <= '0';

        IF (trans = '0' AND inbit = '1') THEN
          next_state <= bus_idle_chk;
        ELSIF (inbit = '0' AND trans = '0') THEN
          next_state <= inter_preprec;
          -- go receive
        ELSIF (inbit = '0' AND trans = '1') THEN
          next_state <= inter_react;
        ELSIF (sendpoint = '1' AND inbit = '1' AND trans = '1') THEN
          next_state <= inter_goregtran;
        ELSE
          next_state <= bus_idle_sample;
        END IF;
--7-------------------------------------------------------------------------------
-- hierlang, wenn Sendeauftrag und inbit = 0 (anstehende Arbitrierung)
      WHEN inter_react =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '1';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '0';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '0'; 
        crc_shft_out <= '0';
        next_state      <= inter_transhift;
--6-------------------------------------------------------------------------------
-- hierhin, wenn Sendeauftrag und Bus rezessiv. Es ist sendpoint, SOF starten
      WHEN inter_goregtran =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '1';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '0';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '0';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '0'; 
        crc_shft_out <= '0';
        next_state      <= inter_regtrancnt;
--11------------------------------------------------------------------------------
-- Fortsetzung senden bei bus rezessiv (von goregtran) (warten auf smplpoint des SOF)
      WHEN inter_regtrancnt =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '1';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '0';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '0'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= inter_arbit_tsftrsmpl;  -- war: tra_arbit_tsftrsmpl;
        ELSE
          next_state <= inter_regtrancnt;
        END IF;
--129-------------------------------------------------------------------------------
-- neuer Zustand: inter_arbit_tsftrsmpl. Vereinheitlichung der Einstiegspunkte
-- von tra_arbit: Von hier und von inter_react gehts nun zu tra_arbit_tactrsftn
-- Ausgänge: Kopie von tra_arbit_tsftrsmpl, warten auf sendpoint, dann normal
-- weiter im tra_arbit Zweig, nächster sendpoint, 1. bit ID
      WHEN inter_arbit_tsftrsmpl =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '1';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "11"; en_zerointcrc <= '0'; 
        crc_shft_out <= '0';
        IF sendpoint = '1' THEN
          next_state <= tra_arbit_tactrsftn;
        ELSE
          next_state <= inter_arbit_tsftrsmpl;
        END IF;
--10-------------------------------------------------------------------------------
-- von inter_react, SOF ist auf dem Bus, tshift schieben, um beim nächsten
-- sendpoint 1. Bit ID senden zu können
      WHEN inter_transhift =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '1';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '0'; 
        crc_shft_out <= '0';
        next_state      <= inter_incsigres;
--13-------------------------------------------------------------------------------
-- von inter_transhift, warten auf sendpoint, dann nach tra_arbit und 1. Bit ID
-- auf den Bus
      WHEN inter_incsigres =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '0'; 
        crc_shft_out <= '0';
        next_state <= tra_arbit_tactrsftn;
--12-------------------------------------------------------------------------------
-- um Übergänge zu Vereineiheitlichen, wird zu rec_flglen_sample gesprungen.
-- Dann ist dies der einzige Einstiegspunkt in rec_flglen*. Aus tra_arbit wird
-- auch nach _sample gesprungen. Vorbereitung für Zerlegung der FSM.
-- kein Sendeauftrag, SOF entdeckt
      WHEN inter_preprec =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '0';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        next_state      <= inter_preprec_shifting;
--128-------------------------------------------------------------------------------
-- auf smplpoint warten von 1. Bit ID, dann zu rec_flglen
      WHEN inter_preprec_shifting =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= rec_flglen_sample;
        ELSE
          next_state <= inter_preprec_shifting;
        END IF;
-------------------------------------------------------------------------------
-- FSM-Unterteilung: Ende INTERFRAME
--                   Anfang TRANSMIT_DATA, Einziger Einstieg: 14,tra_arbit_tactrsftn
-------------------------------------------------------------------------------      
--18-------------------------------------------------------------------------------
-- nach einem Stuffbit auf smplpoint warten
      WHEN tra_arbit_tnactrnsft =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "11"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= tra_arbit_tsftrsmpl;
        ELSE
          next_state <= tra_arbit_tnactrnsft;
        END IF;
--14--------------------->>>>>---Einstieg (resetstate)--<<<<<<<<---------------------
-- senden des arbitfeldes (es ist sendpoint)
      WHEN tra_arbit_tactrsftn =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '1';
        actvrcrc        <= '1';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "11"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1' AND stufft = '0') THEN
          next_state <= tra_arbit_tsftrsmpl;
        ELSIF (smplpoint = '1' AND stufft = '1') THEN
          next_state <= tra_arbit_tnsftrsmpl;
        ELSE
          next_state <= tra_arbit_tactrsftn;
        END IF;
--15-------------------------------------------------------------------------------
-- senden des RTR (Basic) (und setzen für empfang, falls abitverlust)
      WHEN tra_arbit_tactrsftsr =>
        rext_set        <= "00"; rrtr_set <= "11";     actvtcrc <= '1';
        actvrcrc        <= '1';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "11"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1' AND stufft = '0') THEN
          next_state <= tra_arbit_tsftrsmpl;
        ELSIF (smplpoint = '1' AND stufft = '1') THEN
          next_state <= tra_arbit_tnsftrsmpl;
        ELSE
          next_state <= tra_arbit_tactrsftsr;
        END IF;
--16-------------------------------------------------------------------------------
-- Senden des IDE (auch für empfang, arbit!)
      WHEN tra_arbit_tactrsfte =>
        rext_set        <= "11"; rrtr_set <= "10";     actvtcrc <= '1';
        actvrcrc        <= '1';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "11"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1' AND stufft = '0') THEN
          next_state <= tra_arbit_tsftrsmpl;
        ELSIF (smplpoint = '1' AND stufft = '1') THEN
          next_state <= tra_arbit_tnsftrsmpl;
        ELSE
          next_state <= tra_arbit_tactrsfte;
        END IF;
--17-------------------------------------------------------------------------------
-- RTR vom Extended datenrahmen (count war falsch! 33!!)
      WHEN tra_arbit_tactrsfter =>
        rext_set        <= "11"; rrtr_set <= "11";     actvtcrc <= '1';
        actvrcrc        <= '1';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "11"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1' AND stufft = '0') THEN
          next_state <= tra_arbit_tsftrsmpl;
        ELSIF (smplpoint = '1' AND stufft = '1') THEN
          next_state <= tra_arbit_tnsftrsmpl;
        ELSE
          next_state <= tra_arbit_tactrsfter;
        END IF;
--19-------------------------------------------------------------------------------
-- smplpoint in arbit,- biterror = go receive, entscheidung, was als nächstes
-- gesendet wird. stferror hat hier niochts zu suchen
      WHEN tra_arbit_tsftrsmpl =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '1';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "11"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1'AND biterror = '0'AND stferror = '0'AND count = 13 AND inbit = '1'AND text = '1')
        THEN
          next_state <= tra_arbit_tactrsftsr;
        ELSIF(sendpoint = '1'AND biterror = '0'AND stferror = '0'AND count = 14 AND inbit = '1')THEN
          next_state <= tra_arbit_tactrsfte;  -- Fehler arbit. ext :32 -> 33
        ELSIF(sendpoint = '1'AND biterror = '0'AND stferror = '0'AND count = 33 AND inbit = '1')THEN
          next_state <= tra_arbit_tactrsfter;
        ELSIF(sendpoint = '1'AND biterror = '0'AND stferror = '0'AND
              (inbit = '0'OR(count /= 13 AND count /= 14 AND count /= 33 )) AND
              ((count = 13 AND text = '0') NOR (count = 34 AND text = '1' ))) THEN
          next_state <= tra_arbit_tactrsftn;
        ELSIF(sendpoint = '1'AND biterror = '0'AND stferror = '0' AND((count = 13 AND text = '0')
                                                                      OR (count = 34 AND text = '1'))) THEN
          next_state <= tra_data_activatecrc;
          --go data send
        ELSIF (biterror = '1' AND stferror = '0') THEN
          next_state <= tra_arbit_goreceive;

        ELSE
          next_state <= tra_arbit_tsftrsmpl;
        END IF;
--21-------------------------------------------------------------------------------
-- Arbitrierung verloren, auf nächsten smplpoint warten, um daten zu empfangen
      WHEN tra_arbit_goreceive =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= rec_flglen_sample;
        ELSE
          next_state <= tra_arbit_goreceive;
        END IF;
--20-------------------------------------------------------------------------------
-- smplpoint des stuffbits, hier ist der stufffehler von interesse
      WHEN tra_arbit_tnsftrsmpl =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     resetdst <= '1';
        resetstf        <= '1';  hardsync <= '0';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "11"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';

        IF (sendpoint = '1' AND biterror = '0') THEN
          next_state <= tra_arbit_tnactrnsft;
        ELSIF (stferror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (stferror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSE
          next_state <= tra_arbit_tnsftrsmpl;
        END IF;
-- Ende Arbit, Anfang data (keine FSM-Unterteilung!!!)
--22&23: Änderungen: synth, invalide zellen weg, starttcrc
--22-------------------------------------------------------------------------------
-- Sendpoint, daten versenden
      WHEN tra_data_activatecrc =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '1';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1' AND stufft = '0' AND starttcrc = '0') THEN
          next_state <= tra_data_shifting;
        ELSIF (smplpoint = '1' AND stufft = '0' AND starttcrc = '1') THEN
          next_state <= tra_data_lastshift;
        ELSIF (smplpoint = '1' AND stufft = '1') THEN
          next_state <= tra_data_noshift;
        ELSE
          next_state <= tra_data_activatecrc;
        END IF;
--23-------------------------------------------------------------------------------
-- sendpoint stuffbit, warten auf smplpoint stuffbit
      WHEN tra_data_activatncrc =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1' AND starttcrc = '0') THEN
          next_state <= tra_data_shifting;
        ELSIF (smplpoint = '1' AND starttcrc = '1') THEN
          next_state <= tra_data_lastshift;
        ELSE
          next_state <= tra_data_activatncrc;
        END IF;
--24-------------------------------------------------------------------------------
-- smplpoint nach Daten/Stuffbit versenden, Bit checken
      WHEN tra_data_shifting =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '1';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1' AND biterror = '0') THEN
          next_state <= tra_data_activatecrc;
        ELSIF (biterror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSE
          next_state <= tra_data_shifting;
        END IF;
--26-------------------------------------------------------------------------------
-- smplpoint des letzten Datenbits, counter für crc resetten, bit checken
      WHEN tra_data_lastshift =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '1';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (biterror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSE
          next_state <= tra_data_loadcrc;
        END IF;
--25-------------------------------------------------------------------------------
-- smplpoint des bits vor stuffbit, tshift nicht aktivieren (actvtsft!)
      WHEN tra_data_noshift =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1' AND biterror = '0') THEN
          next_state <= tra_data_activatncrc;
        ELSIF (biterror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSE
          next_state <= tra_data_noshift;
        END IF;
--27-------------------------------------------------------------------------------
-- warten auf sendpoint des 1. Bit CRC
      WHEN tra_data_loadcrc =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '1';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '1';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= tra_crc_activatedec;
        ELSE
          next_state <= tra_data_loadcrc;
        END IF;
-------------------------------------------------------------------------------
-- FSM-Unterteilung: Ende TRANSMIT_DATA
--                   Anfang TRANSMIT_CHECK, Einziger Einstieg: 14,tra_crc_activatedec
-------------------------------------------------------------------------------      
--28-------------------------------------------------------------------------------
-- sendpoint crc bit, warten auf smplpoint
      WHEN tra_crc_activatedec =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '1';
        -- 15 -> 16
        IF (smplpoint = '1' AND stufft = '0' AND count /= 16) THEN
          next_state <= tra_crc_shifting;
        ELSIF (smplpoint = '1' AND stufft = '0' AND count = 16) THEN
          -- tra_crc_lastshif -> delshift
          next_state <= tra_crc_delshft;
        ELSIF (smplpoint = '1' AND stufft = '1') THEN
          next_state <= tra_crc_noshift;
        ELSE
          next_state <= tra_crc_activatedec;
        END IF;
--29-------------------------------------------------------------------------------
-- sendpoint stuffbit, warten auf smplpoint
      WHEN tra_crc_activatndec =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '1';
        IF (smplpoint = '1' AND count /= 16) THEN
          next_state <= tra_crc_shifting;
        ELSIF (smplpoint = '1' AND count = 16) THEN
          next_state <= tra_crc_delshft;
        ELSE
          next_state <= tra_crc_activatndec;
        END IF;
--30-------------------------------------------------------------------------------
-- smplpoint des eben gesendeten CRC/Stuff Bits, warten auf sendpoint, Bit checken
      WHEN tra_crc_shifting =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '1';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '1';
        IF (sendpoint = '1' AND biterror = '0') THEN
          next_state <= tra_crc_activatedec;
        ELSIF (biterror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSE
          next_state <= tra_crc_shifting;
        END IF;
--31-------------------------------------------------------------------------------
-- smplpoint des Bits vor stuffbit, tshift nicht schieben, bit checken
      WHEN tra_crc_noshift =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '1';
        IF (sendpoint = '1' AND biterror = '0') THEN
          next_state <= tra_crc_activatndec;
        ELSIF (biterror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSE
          next_state <= tra_crc_noshift;
        END IF;
--32-------------------------------------------------------------------------------
-- smplpoint des CRC-Delimiter, checken, ob rezessiv. lastshift und senddel
-- fallen weg, ist jetzt inkl. in CRC Versendung. Warten auf  sendpoint ACK (setbrec).
      WHEN tra_crc_delshft =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '1';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '1';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '1';
        IF (sendpoint = '1' AND biterror = '0') THEN
          next_state <= tra_ack_sendack;
        ELSIF (biterror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSE
          next_state <= tra_crc_delshft;
        END IF;
-- Ende CRC, Anfanck Ack (keine FSM-Unterteilung !!!)
-- immer noch TRANMIST_CHECK
--33-------------------------------------------------------------------------------
-- sendpoint ACK_Slot, rezessiv senden (setbrec!)
      WHEN tra_ack_sendack =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= tra_ack_shifting;
        ELSE
          next_state <= tra_ack_sendack;
        END IF;
--34-------------------------------------------------------------------------------
-- smplpoint ACK-Slot, checken auf ACK. ACK ok, wenn biterror=1
      WHEN tra_ack_shifting =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
-- Änderung: Error Flag muß direkt nach dem A_S kommen, nicht wie gehabt nach
-- dem A_D, deshalb nicht mehr auf Sendpoint warten und direkt nach stopack
        IF (biterror = '0') THEN
          next_state <= tra_ack_stopack;
--        IF (sendpoint = '1' AND biterror = '0') THEN
--          next_state <= tra_ack_senddel;
        ELSIF (sendpoint = '1' AND biterror = '1') THEN
          next_state <= tra_edof_sendrecb;  -- OK (Biterror)
        ELSE
          next_state <= tra_ack_shifting;
        END IF;
--35-------------------------------------------------------------------------------
-- kein ACK bekommen, Error flag direkt starten (nicht auf A_D warten)
      WHEN tra_ack_stopack =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "11";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSE
          next_state <= errorpassiv_firstrec;
        END IF;
-- Ende tra_ack, anfang tra_edof
-- Änderung: hier wird nur zum shifting verzweigt.Dort Error Abfrage. Keine
-- Extrawurst mehr fürs letzte Bit, da das auch zu einem Form Error führt.
-- Overload stimmt nicht.
--36-------------------------------------------------------------------------------
-- ACK war ok
      WHEN tra_edof_sendrecb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= tra_edof_shifting;
        ELSE
          next_state <= tra_edof_sendrecb;
        END IF;
--37-------------------------------------------------------------------------------
-- smplpoint, beim nächsten sendpoint entweder noch ein EOF Bit senden, oder ende
-- neu, von hier wird nach dectra verzweigt. lastshift gibs nun nicht mehr        
      WHEN tra_edof_shifting =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1' AND biterror = '0' AND count /= 8) THEN
          next_state <= tra_edof_sendrecb;
        ELSIF (sendpoint = '1' AND biterror = '0' AND count = 8) THEN
          next_state <= tra_edof_dectra;
        ELSIF (biterror = '1' AND count = 8) THEN
          next_state <= over_firstdom;
        ELSIF (biterror = '1' AND erroractiv = '1' AND count /= 8) THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1' AND count /= 8) THEN
          next_state <= errorpassiv_firstrec;
        ELSE
          next_state <= tra_edof_shifting;
        END IF;
--neuer Zustand von mir, damit kein dectra, wenn 7. Bit EOF dominant, sondern
--nur Overload Flag!
--127-------------------------------------------------------------------------------
-- sendpoint des letzten (7.) EOF Bits, nächster smplpoint schon intermission,
-- dectra signal an FCE und LLC
      WHEN tra_edof_dectra =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '1';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '0';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "11"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= inter_sample;
        ELSE
          next_state <= tra_edof_dectra;
        END IF;
-------------------------------------------------------------------------------
-- FSM-Unterteilung: Ende TRANSMIT_CHECK
--                   Anfang RECEIVE_DATA, Einziger Einstieg: 38,rec_flglen_sample
------------------------------------------------------------------------------- 
--38-------------------------------------------------------------------------------
-- smplpoint des empfangenen Bits (hier wird immer angefangen mit dem 1. Bit
-- ID, SOF wird im inter_*/bus_* bereich abgehandelt)
      WHEN rec_flglen_sample =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (stuffr = '1' AND stferror = '0') THEN
          next_state <= rec_flglen_noshift;
        ELSIF (stferror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (stferror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSIF (stuffr = '0' AND stferror = '0' AND inbit = '1' AND count = 12) THEN
          next_state <= rec_flglen_shiftstdrtr;
        ELSIF (stuffr = '0' AND stferror = '0' AND inbit = '1' AND count = 13) THEN
          next_state <= rec_flglen_shiftextnor;
        ELSIF (stuffr = '0'AND stferror = '0'AND inbit = '1'AND count = 15 AND rrtr = '0'AND rext = '0') THEN
          next_state <= rec_flglen_shiftdlc64;
        ELSIF (stuffr = '0'AND stferror = '0'AND inbit = '1'AND count = 16 AND rrtr = '0'AND rext = '0') THEN
          next_state <= rec_flglen_shiftdlc32;
        ELSIF (stuffr = '0'AND stferror = '0'AND inbit = '1'AND count = 17 AND rrtr = '0'AND rext = '0') THEN
          next_state <= rec_flglen_shiftdlc16;
        ELSIF (stuffr = '0'AND stferror = '0'AND inbit = '1'AND count = 18 AND rrtr = '0'AND rext = '0') THEN
          next_state <= rec_flglen_shiftdlc8;
        ELSIF (stuffr = '0' AND stferror = '0' AND inbit = '1' AND count = 32 AND rext = '1') THEN
          next_state <= rec_flglen_shiftextrtr;
        ELSIF (stuffr = '0'AND stferror = '0'AND inbit = '1'AND count = 35 AND rrtr = '0'AND rext = '1') THEN
          next_state <= rec_flglen_shiftdlc64;
        ELSIF (stuffr = '0'AND stferror = '0'AND inbit = '1'AND count = 36 AND rrtr = '0'AND rext = '1') THEN
          next_state <= rec_flglen_shiftdlc32;
        ELSIF (stuffr = '0'AND stferror = '0'AND inbit = '1'AND count = 37 AND rrtr = '0'AND rext = '1') THEN
          next_state <= rec_flglen_shiftdlc16;
        ELSIF (stuffr = '0'AND stferror = '0'AND inbit = '1'AND count = 38 AND rrtr = '0'AND rext = '1') THEN
          next_state <= rec_flglen_shiftdlc8;
        ELSIF (stuffr = '0'AND stferror = '0'AND
               (inbit = '0' OR
                (
                  count /= 12 AND
                  count /= 13 AND       --nächste Zeile: "OR rrtr='1'" von mir
                                        --wg. Fehler im empfang von RTR Bas ID
                  (rext = '1'OR rrtr = '1'OR(count /= 15 AND count /= 16 AND count /= 17 AND count /= 18)) AND
                  (count /= 32 OR rext = '0')AND
                  (rext = '0'OR rrtr = '1'OR(count /= 35 AND count /= 36 AND count /= 37 AND count /= 38))
                  )
                )
               ) THEN
          next_state <= rec_flglen_shifting;
        ELSE
          next_state <= rec_flglen_sample;
        END IF;
--46-------------------------------------------------------------------------------
-- Teil der ID empfangen, kein spezielles Steuerbit, warten auf nächstes Bit
-- (smplpoint). Entscheidung nach rec_data oder rec_crc zu verzweigen
-- Änderung mit rmzero, Übergang nach rec_crc, auch wenn dataframe (RTR=0) mit
-- DLC=0. s. _crc_rescnt
      WHEN rec_flglen_shifting =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';

        IF (smplpoint = '1' AND ((count = 19 AND rext = '0') NOR (count = 39 AND rext = '1'))) THEN
          next_state <= rec_flglen_sample;
        ELSIF(smplpoint = '1'AND((count = 19 AND rext = '0')OR(count = 39 AND rext = '1'))AND rrtr = '0' AND rmzero = '0') THEN
          next_state <= rec_acptdat_sample;
        ELSIF(smplpoint = '1'AND((count = 19 AND rext = '0')OR(count = 39 AND rext = '1'))AND (rrtr = '1' OR rmzero = '1'))THEN
          next_state <= rec_crc_rescnt;
        ELSE
          next_state <= rec_flglen_shifting;
        END IF;

--39-----------------------------------------------------------------------------
-- wenn empfangspos bei Basic RTR (rrtr_set!)
      WHEN rec_flglen_shiftstdrtr =>
        rext_set        <= "00"; rrtr_set <= "11";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= rec_flglen_sample;
        ELSE
          next_state <= rec_flglen_shiftstdrtr;
        END IF;
--40-------------------------------------------------------------------------------
-- Wenn IDE kommt (also extended rahmen) rext_set!
      WHEN rec_flglen_shiftextnor =>
        rext_set        <= "11"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= rec_flglen_sample;
        ELSE
          next_state <= rec_flglen_shiftextnor;
        END IF;
--41-------------------------------------------------------------------------------
-- Bit#3 (MSB) vom DLC (setrmleno,actvtrmlen !)
      WHEN rec_flglen_shiftdlc64 =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 4;    actvrmln <= '1';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        next_state      <= rec_flglen_setdlc;
--42-------------------------------------------------------------------------------
-- Bit#2 DLC (setrmleno,actvtrmlen!)
      WHEN rec_flglen_shiftdlc32 =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 3;    actvrmln <= '1';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        next_state      <= rec_flglen_setdlc;
--43-------------------------------------------------------------------------------
-- Bit#1 DLC (setrmleno, actvtrmlen!)
      WHEN rec_flglen_shiftdlc16 =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 2;    actvrmln <= '1';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        next_state      <= rec_flglen_setdlc;
--44-------------------------------------------------------------------------------
-- Bit#0 DLC (setrmleno, actvtrmlen!)
      WHEN rec_flglen_shiftdlc8 =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 1;    actvrmln <= '1';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        next_state      <= rec_flglen_setdlc;
--65-------------------------------------------------------------------------------
-- Nach DLC-bit (setrmleno=7) 
      WHEN rec_flglen_setdlc =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 7;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1' AND ((count = 19 AND rext = '0') NOR (count = 39 AND rext = '1'))) THEN
          next_state <= rec_flglen_sample;
        ELSIF(smplpoint = '1'AND((count = 19 AND rext = '0')OR(count = 39 AND rext = '1'))AND rrtr = '0')THEN
          next_state <= rec_acptdat_sample;
-- hier nicht mehr nach rec_crc, in rec_flglen_shifting!!!
        ELSE
          next_state <= rec_flglen_setdlc;
        END IF;
--45-------------------------------------------------------------------------------
-- Extended+RTR (counter 32 AND rext, rrtr_set!)
      WHEN rec_flglen_shiftextrtr =>
        rext_set        <= "00"; rrtr_set <= "11";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= rec_flglen_sample;
        ELSE
          next_state <= rec_flglen_shiftextrtr;
        END IF;
--47-------------------------------------------------------------------------------
-- nach stuff, warten auf smplpoint
      WHEN rec_flglen_noshift =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= rec_flglen_sample;
        ELSE
          next_state <= rec_flglen_noshift;
        END IF;
-- ende arbitrierung, anfang daten
--48-------------------------------------------------------------------------------
-- samplepoint empfangenes bit
      WHEN rec_acptdat_sample =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (stuffr = '1' AND stferror = '0') THEN
          next_state <= rec_acptdat_noshift;
        ELSIF (stferror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (stferror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSE
          next_state <= rec_acptdat_shifting;
        END IF;
--49-------------------------------------------------------------------------------
-- direkt nach smplpoint, rshift schieben, auf nächsten smplpoint warten
      WHEN rec_acptdat_shifting =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
-- Änderung: synth: invalide Zellen weg, meslencompare,startrcrc
        IF (smplpoint = '1'AND startrcrc = '0') THEN
          next_state <= rec_acptdat_sample;
        ELSIF startrcrc = '1' THEN
          next_state <= rec_acptdat_lastshift;
        ELSE
          next_state <= rec_acptdat_shifting;
        END IF;
--50-------------------------------------------------------------------------------
-- Stuffbit, warten, nicht rshift schieben, warten auf nächsten smplp oint
      WHEN rec_acptdat_noshift =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= rec_acptdat_sample;
        ELSE
          next_state <= rec_acptdat_noshift;
        END IF;
--66-------------------------------------------------------------------------------
-- counter für crc empfang resetten, auf smplpoint des 1. CRC Bits warten
-- eigentlich nicht mehr nötig, aber für gleiche einstiegspunkte halt nach
-- crc_rescnt. gibt es halt ein längeres resetsignal
      WHEN rec_acptdat_lastshift =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF(smplpoint = '1') THEN
          next_state <= rec_crc_rescnt;  --war: crc_sample, aber counter muss resetten
        ELSE
          next_state <= rec_acptdat_lastshift;
        END IF;
-------------------------------------------------------------------------------
-- FSM-Unterteilung: Ende RECEIVE_DATA
--                   Anfang RECEIVE_CHECK, Einziger Einstieg: 51,rec_crc_rescnt
------------------------------------------------------------------------------- 
--51-------------------------------------------------------------------------------
-- von mir wg. übergang von dlc=0 oder rrtr=1 zum direkten crc (rescount!)
      WHEN rec_crc_rescnt =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '1';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '1';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';

        next_state <= rec_crc_sample;

--52-------------------------------------------------------------------------------
-- smplpoint des crc-bits, direkt nächstes abwarten, oder zum delim-empfang
      WHEN rec_crc_sample =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '1';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (stuffr = '1' AND stferror = '0') THEN
          next_state <= rec_crc_noshift;
        ELSIF (stferror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (stferror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
-- Eingefügt für stuff berichtigung
        ELSIF (count = 15) THEN
          next_state <= rec_ack_recdelim;
        ELSE
          next_state <= rec_crc_shifting;
        END IF;
--53-------------------------------------------------------------------------------
-- warten auf nächsten smplpoint des crc
--Änderung: actvrcrc <= '1' , dann wird crc ins empfangsregister nachgeschoben        
      WHEN rec_crc_shifting =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '1';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '1';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '1';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
--        IF(smplpoint = '1' AND count/=15)THEN
        IF (smplpoint = '1') THEN
          next_state <= rec_crc_sample;
-- gelöscht, stuff änderung
          --     ELSIF(smplpoint = '1' AND count = 15)THEN
          --       next_state <= rec_ack_recdelim;
-- ende änderung
        ELSE
          next_state <= rec_crc_shifting;
        END IF;
--54-------------------------------------------------------------------------------
-- stuffbit empfangen, ignorieren, auf nächsten smplpoint warten
      WHEN rec_crc_noshift =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '1';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= rec_crc_sample;
        ELSE
          next_state <= rec_crc_noshift;
        END IF;
-- ende rec_crc, anfang rec_ack
--55-------------------------------------------------------------------------------
-- Delimiter smplpoint, jetzt crc auswerten und zu give_ack oder give_noack verzweigen.
-- hier stand ursprünglich: (crcrest = crcrecv) nun muß auf 0 getestet werden
-- neues Signal crc_ok: 0=nicht ok, 1 =ok. crc-änderung
      WHEN rec_ack_recdelim =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';

        IF (inbit = '1' AND crc_ok = '0') THEN
          next_state <= rec_ack_prepnoack;
--        IF (inbit = '1' AND NOT (crcrest = crcrecv)) THEN
--          next_state <= rec_ack_prepnoack;
        ELSIF (inbit = '0' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (inbit = '0' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSIF (inbit = '0' AND busof = '1') THEN
          next_state <= busoff_first;
        ELSE
          next_state <= rec_ack_prepgiveack;
        END IF;
--56-------------------------------------------------------------------------------
-- vor dem ACK-slot, warten auf sendpoint um dominant zu senden
      WHEN rec_ack_prepgiveack =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '1';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '1';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= rec_ack_giveack;
        ELSE
          next_state <= rec_ack_prepgiveack;
        END IF;
--59-------------------------------------------------------------------------------
-- Warten auf smplpoint des A_S
      WHEN rec_ack_giveack =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '1';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '1';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= rec_ack_checkack;
        ELSE
          next_state <= rec_ack_giveack;
        END IF;
--60-------------------------------------------------------------------------------
-- smplpoint des A_S, Biterror checken, zum nächsten sendpoint nach stopack,
-- EOF senden
      WHEN rec_ack_checkack =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (biterror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSIF (sendpoint = '1') THEN
          next_state <= rec_ack_stopack;
        ELSE
          next_state <= rec_ack_checkack;
        END IF;
--57-------------------------------------------------------------------------------
-- auf sendpoint A_S warten, dann nach rec_ack_noack, rezessiv senden (setbrec!)
      WHEN rec_ack_prepnoack =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= rec_ack_noack;
        ELSE
          next_state <= rec_ack_prepnoack;
        END IF;
--58-------------------------------------------------------------------------------
-- smplpoint des nicht gegebenen ACKs. Dann ab in einen Errorzustand.
      WHEN rec_ack_noack =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (smplpoint = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSIF (smplpoint = '1' AND busof = '1') THEN
          next_state <= busoff_first;
        ELSE
          next_state <= rec_ack_noack;
        END IF;
--61-------------------------------------------------------------------------------
-- Warten auf smplpoint des ACK-Delim, dann nach rec_edof
      WHEN rec_ack_stopack =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= rec_edof_sample;
        ELSE
          next_state <= rec_ack_stopack;
        END IF;

-- ende rec_ack, anfang rec_edof
-- Änderungen: Receiver: valid, beim vorletzten bit des eof, neuer state:
-- rec_edof_lastbit, dann ist decrec einen früher und das letzte Bit
-- don't care
-- alle 8 in 7 geändert und übergang von rec_edof_endrec nach rec_edof lastshift
--62-------------------------------------------------------------------------------
-- smplpoint des EOF (fängt an mit A_D!!!). Also 8 rezessive. 
      WHEN rec_edof_sample =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (inbit = '0' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (inbit = '0' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSE
          next_state <= rec_edof_check;
        END IF;
--63-------------------------------------------------------------------------------
-- wenn in sample alles ok war, auf nächsten smplpoint warten, ansonsten direkt
-- nach endrec
      WHEN rec_edof_check =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (count /= 7 AND smplpoint = '1') THEN
          next_state <= rec_edof_sample;
        ELSIF (count = 7 AND inbit = '1') THEN
          next_state <= rec_edof_endrec;
-- Das nur bei Transmitter
--        ELSIF (count = 8 AND inbit = '0') THEN 
--          next_state <= over_firstdom;
        ELSE
          next_state <= rec_edof_check;
        END IF;
--64-------------------------------------------------------------------------------
-- decrec setzen (kurz nach smplpoint des 6. EOF bits), auf smplpoint des
-- letzten EOF Bits warten
      WHEN rec_edof_endrec =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '1';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= rec_edof_lastbit;
        ELSE
          next_state <= rec_edof_endrec;
        END IF;
--125-------------------------------------------------------------------------------
-- smplpoint des letzten EOF, hier ein biterror = overload
-- neuer Zustand: letztes Bit EOF= don't care        
      WHEN rec_edof_lastbit =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '0';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (inbit = '1') THEN
          next_state <= rec_edof_inter;  --inter_sample;
        ELSIF (inbit = '0') THEN
          next_state <= over_firstdom;
        ELSE
          next_state <= rec_edof_lastbit;
        END IF;
--126-------------------------------------------------------------------------------
-- warten auf smplpoint des 1. Intermission Bits
-- NEU, um einen Einstiegspunkt in unterteilter FSM in INTERFRAME zu haben
      WHEN rec_edof_inter =>
        rext_set        <= "00"; rrtr_set <= "00";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '0';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "11"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= inter_sample;
        ELSE
          next_state <= rec_edof_inter;
        END IF;
-------------------------------------------------------------------------------
-- FSM-Unterteilung: Ende RECEIVE_CHECK
--                   Anfang OVERLOAD, Einziger Einstieg: 67,over_firstdom
------------------------------------------------------------------------------- 
--67-------------------------------------------------------------------------------
-- warten auf sendpoint fürs 1. Overload-Flag dom- Bit (setbdom!)
      WHEN over_firstdom =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '1';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= over_senddomb;
        ELSE
          next_state <= over_firstdom;
        END IF;
--68-------------------------------------------------------------------------------
-- Sendpoint: OV-Flag Bit senden, warten auf smplpoint
      WHEN over_senddomb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '1';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= over_check1;
        ELSE
          next_state <= over_senddomb;
        END IF;
--69-------------------------------------------------------------------------------
-- smplpoint eines OV-Flag Bits (dominant)
      WHEN over_check1 =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '1';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1' AND biterror = '0' AND count /= 6) THEN
          next_state <= over_senddomb;
        ELSIF (biterror = '0' AND count = 6) THEN
          next_state <= over_preprecb;
        ELSIF (biterror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSIF (biterror = '1' AND busof = '1') THEN
          next_state <= busoff_first;
        ELSE
          next_state <= over_check1;
        END IF;
--70-------------------------------------------------------------------------------
-- Auf sendpoint des 1. OV-Delim Bits warten
      WHEN over_preprecb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= over_wtonrecb;
        ELSE
          next_state <= over_preprecb;
        END IF;
--71-------------------------------------------------------------------------------
-- Auf smplpoint eines rezessiven Bits warten
      WHEN over_wtonrecb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= over_check2;
        ELSE
          next_state <= over_wtonrecb;
        END IF;
--73-------------------------------------------------------------------------------
-- mehr als 7 dominante Bits -> TEC+8 (wenn vorher Transmitter)
      WHEN over_inctracounter =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '1';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= over_check2;
        ELSE
          next_state <= over_inctracounter;
        END IF;
--72-------------------------------------------------------------------------------
-- mehr als 7 dominante Bits -> REC+8 (wenn vorher Receiver)        
      WHEN over_increccounter =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '1';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= over_check2;
        ELSE
          next_state <= over_increccounter;
        END IF;
--74-------------------------------------------------------------------------------
-- smplpoint, warten auf rezessives Bit, wenn nicht zurück nach wtonrecb, sonst
-- nach prepsend
      WHEN over_check2 =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
--Änderung synth: < 7 in /=7 , invalid Cells weg
        IF (sendpoint = '1' AND biterror = '1' AND count /= 7) THEN
          next_state <= over_wtonrecb;
        ELSIF (sendpoint = '1' AND biterror = '1' AND count = 7 AND receiver = '1') THEN
          next_state <= over_increccounter;
        ELSIF (sendpoint = '1' AND biterror = '1' AND count = 7 AND transmitter = '1') THEN
          next_state <= over_inctracounter;
        ELSIF (biterror = '0') THEN
          next_state <= over_prepsend;
        ELSE
          next_state <= over_check2;
        END IF;
--78-------------------------------------------------------------------------------
-- letzter smplpoint war rezessiv, also 1. Bit des Delim, warten auf sendpoint
-- des 2. rezessiven Bits
      WHEN over_prepsend =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= over_sendrecb;
        ELSE
          next_state <= over_prepsend;
        END IF;
--75-------------------------------------------------------------------------------
-- sendpoint: Rezessive Bits auf den Bus
      WHEN over_sendrecb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= over_check3;
        ELSE
          next_state <= over_sendrecb;
        END IF;
--76-------------------------------------------------------------------------------
-- Smplpoint Delimiter, checken, bei Error: wenn noch nicht letztes Bit, dann
-- zu Erroractiv/passiv, wenn letztes Bit: neuer Overload Rahmen
-- Overload Regel: ist das letzte Bit des Overload/error Delimiters falsch,
-- wird ein Overload Frame ausgelöst.        
      WHEN over_check3 =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1' AND biterror = '0' AND count /= 7) THEN
          next_state <= over_sendrecb;
        ELSIF (biterror = '0' AND count = 7) THEN
          next_state <= over_waitoclk;
        ELSIF (biterror = '1' AND count = 7) THEN
          next_state <= over_firstdom;
        ELSIF (biterror = '1' AND erroractiv = '1' AND count /= 7) THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1' AND count /= 7) THEN
          next_state <= errorpassiv_firstrec;
        ELSIF (biterror = '1' AND busof = '1' AND count /= 7) THEN
          next_state <= busoff_first;
        ELSE
          next_state <= over_check3;
        END IF;
--77-------------------------------------------------------------------------------
-- Auf den smplpoint des 1. Intermission Bits warten, und dann ab an den Anfang
      WHEN over_waitoclk =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '0';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= inter_sample;
        ELSE
          next_state <= over_waitoclk;
        END IF;
-------------------------------------------------------------------------------
-- FSM-Unterteilung: Ende OVERLOAD
--                   Anfang ERRORACTIVE, Einziger Einstieg: 79,erroractiv_firstdom
------------------------------------------------------------------------------- 
--79-------------------------------------------------------------------------------
-- Fehlerzähler hochzählen (inceinsrec, incachtrec, inceinsrec), oder auf
-- sendpoint warten, wenn aus Arbitrierung gekommen
      WHEN erroractiv_firstdom =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '1';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "00";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "00"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1' AND onarbit = '1') THEN
          next_state <= erroractiv_senddomb;
        ELSIF (onarbit = '0' AND transmitter = '0' AND receiver = '1' AND error = '0') THEN
          next_state <= erroractiv_inceinsrec;
        ELSIF (onarbit = '0' AND transmitter = '0' AND receiver = '1' AND error = '1') THEN
          next_state <= erroractiv_incachtrec;
        ELSIF (onarbit = '0' AND transmitter = '1') THEN
          next_state <= erroractiv_incachttra;
        ELSE
          next_state <= erroractiv_firstdom;
        END IF;
--80-------------------------------------------------------------------------------
-- REC+1, auf sendpoint für 1. dom. Bit Flag warten
      WHEN erroractiv_inceinsrec =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '1';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '1';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= erroractiv_senddomb;
        ELSE
          next_state <= erroractiv_inceinsrec;
        END IF;
--81-------------------------------------------------------------------------------
-- REC+8, auf sendpoint für 1. dom. Bit Flag warten        
      WHEN erroractiv_incachtrec =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '1';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '1';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= erroractiv_senddomb;
        ELSE
          next_state <= erroractiv_incachtrec;
        END IF;
--82-------------------------------------------------------------------------------
-- TEC+8, auf sendpoint für 1. dom. Bit Flag warten        
      WHEN erroractiv_incachttra =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '1';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '1';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= erroractiv_senddomb;
        ELSE
          next_state <= erroractiv_incachttra;
        END IF;
--83-------------------------------------------------------------------------------
-- Sendpoint Errorflag
      WHEN erroractiv_senddomb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '1';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= erroractiv_check1;
        ELSE
          next_state <= erroractiv_senddomb;
        END IF;
--84-------------------------------------------------------------------------------
-- smplpoint eines dom. Bit des Flags, wenn schon 6, dann weiter nach _preprecb
      WHEN erroractiv_check1 =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '1';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1' AND biterror = '0' AND count /= 6) THEN
          next_state <= erroractiv_senddomb;
        ELSIF (biterror = '0' AND count = 6) THEN
          next_state <= erroractiv_preprecb;
        ELSIF (biterror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSIF (biterror = '1' AND busof = '1') THEN
          next_state <= busoff_first;
        ELSE
          next_state <= erroractiv_check1;
        END IF;
--85-------------------------------------------------------------------------------
-- warten auf sendpoint des 1. Bits nach eigenem Flag
      WHEN erroractiv_preprecb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= erroractiv_wtonrecb;
        ELSE
          next_state <= erroractiv_preprecb;
        END IF;
--86-------------------------------------------------------------------------------
-- warten auf smplpoint, erwarte rezessive bits, mein flag ist vorbei
      WHEN erroractiv_wtonrecb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "00";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= erroractiv_check2;
        ELSE
          next_state <= erroractiv_wtonrecb;
        END IF;
--87-------------------------------------------------------------------------------
-- Eigenes Error Flag beendet, war receiver und das 1. Bit nach eigenem Flag
-- ist dominant, direkt den REC um weitere 8 erhöhen. auf nächsten smplpoint
-- warten um nach rezessivem bit zu suchen
      WHEN erroractiv_dombitdct =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '1';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= erroractiv_check2;
        ELSE
          next_state <= erroractiv_dombitdct;
        END IF;
--89-------------------------------------------------------------------------------
-- mehr als 14 dominante bits und ich war Receiver-> REC+8
      WHEN erroractiv_egtdombr =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '1';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= erroractiv_check2;
        ELSE
          next_state <= erroractiv_egtdombr;
        END IF;

--88-------------------------------------------------------------------------------
-- mehr als 14 dominante Bits und ich war Transmitter-> TEC+8
-- Falsch: inconerec ='1' | Richtig: incegttra='1'
      WHEN erroractiv_egtdombt =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '1';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= erroractiv_check2;
        ELSE
          next_state <= erroractiv_egtdombt;
        END IF;
--90-------------------------------------------------------------------------------
-- Es ist smplpoint. Warten auf rezessives Bit, dann zu _prepsend. Kommt keins,
-- dann REC+8, wenn 1. dom Bit, REC oder TEC+8, wenn 8 weitere dominante
      WHEN erroractiv_check2 =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "00";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF(sendpoint = '1'AND biterror = '1'AND count /= 7 AND(count /= 1 OR receiver = '0'OR first = '0'))
        THEN
          next_state <= erroractiv_wtonrecb;
        ELSIF(sendpoint = '1' AND biterror = '1' AND count = 1 AND receiver = '1' AND first = '1') THEN
          next_state <= erroractiv_dombitdct;
        ELSIF(sendpoint = '1'AND biterror = '1'AND count = 7 AND transmitter = '1'AND receiver = '0') THEN
          next_state <= erroractiv_egtdombt;
        ELSIF(sendpoint = '1'AND biterror = '1'AND count = 7 AND transmitter = '0'AND receiver = '1') THEN
          next_state <= erroractiv_egtdombr;
        ELSIF (biterror = '0') THEN
          next_state <= erroractiv_prepsend;
        ELSE
          next_state <= erroractiv_check2;
        END IF;
--94-------------------------------------------------------------------------------
-- Warten auf sendpoint für rezessiven Delimiter
      WHEN erroractiv_prepsend =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= erroractiv_sendrecb;
        ELSE
          next_state <= erroractiv_prepsend;
        END IF;
--91-------------------------------------------------------------------------------
-- Sendpoint: Rezessiv mitsenden, auf smplpoint warten
      WHEN erroractiv_sendrecb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '1';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= erroractiv_check3;
        ELSE
          next_state <= erroractiv_sendrecb;
        END IF;
--92------------------------------------------------------------------------------
-- smplpoint: Delimiter checken, wenn dominant, wieder von vorne anfnagen
      WHEN erroractiv_check3 =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '1';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1' AND biterror = '0' AND count /= 7) THEN
          next_state <= erroractiv_sendrecb;
        ELSIF (sendpoint = '1' AND biterror = '0' AND count = 7) THEN
          next_state <= erroractiv_waitoclk;
        ELSIF (biterror = '1' AND erroractiv = '1') THEN
          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSIF (biterror = '1' AND busof = '1') THEN
          next_state <= busoff_first;
        ELSE
          next_state <= erroractiv_check3;
        END IF;
--93-------------------------------------------------------------------------------
-- auf smplpoint nach Delimiter warten, dann wieder von vorne, Intermission
      WHEN erroractiv_waitoclk =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '1';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '1';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '0';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= inter_sample;
        ELSE
          next_state <= erroractiv_waitoclk;
        END IF;
-------------------------------------------------------------------------------
-- FSM-Unterteilung: Ende ERRORACTIVE
--                   Anfang ERRORPASSIVE, Einziger Einstieg: 95,errorpassiv_firstrec
------------------------------------------------------------------------------- 
--95-------------------------------------------------------------------------------
-- warten auf sendpoint des 1. rez Flag oder REC/TEC erhöhen gehen
      WHEN errorpassiv_firstrec =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "00";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "00"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1' AND transmitter = '1' AND (onarbit = '1' OR ackerror = '1')) THEN
          next_state <= errorpassiv_incsrecb;
        ELSIF (onarbit = '0' AND transmitter = '0' AND receiver = '1' AND error = '0') THEN
          next_state <= errorpassiv_inceinsrec;
        ELSIF (onarbit = '0' AND transmitter = '0' AND receiver = '1' AND error = '1') THEN
          next_state <= errorpassiv_incachtrec;
        ELSIF (onarbit = '0' AND transmitter = '1' AND ackerror = '0') THEN
          next_state <= errorpassiv_incachttra;
        ELSE
          next_state <= errorpassiv_firstrec;
        END IF;
--96-------------------------------------------------------------------------------
-- REC+1, warten auf sendpoint 1. rez. Flag
      WHEN errorpassiv_inceinsrec =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '1';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= errorpassiv_incsrecb;
        ELSE
          next_state <= errorpassiv_inceinsrec;
        END IF;
--97-------------------------------------------------------------------------------
-- REC+8, warten auf sendpoint 1. rez. Flag
      WHEN errorpassiv_incachtrec =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '1';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= errorpassiv_incsrecb;
        ELSE
          next_state <= errorpassiv_incachtrec;
        END IF;
--99-------------------------------------------------------------------------------
-- TEC+8, warten auf sendpoint 1. rez. Flag
      WHEN errorpassiv_incachttra =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '1';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= errorpassiv_incsrecb;
        ELSE
          next_state <= errorpassiv_incachttra;
        END IF;
--100-------------------------------------------------------------------------------
-- warten auf smplpoint 1. rez. Bit Flag
      WHEN errorpassiv_incsrecb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "00";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1' AND count /= 0) THEN
          next_state <= errorpassiv_check1;
        ELSIF (smplpoint = '1' AND count = 0) THEN
          next_state <= errorpassiv_fillpuffer;
        ELSE
          next_state <= errorpassiv_incsrecb;
        END IF;
--98-------------------------------------------------------------------------------
-- 1. rez. Bit, Puffer auf 0 setzen; wenn dominant auf Bus: 1. Sender und
-- Ackerror nach _pufferdomi, sonst nach _pufferdom, sonst _pufferrec
      WHEN errorpassiv_fillpuffer =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF(inbit = '0' AND transmitter = '1'AND ackerror = '1') THEN
          next_state <= errorpassiv_pufferdomi;
        ELSIF(inbit = '0' AND (transmitter = '0' OR ackerror = '0')) THEN
          next_state <= errorpassiv_pufferdom;
        ELSE
          next_state <= errorpassiv_pufferrec;
        END IF;
--102-------------------------------------------------------------------------------
-- Puffer auf 1, da 1. Bit rez. geblieben ist, auf sendpoint 2. Bit warten
      WHEN errorpassiv_pufferrec =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "11";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF(sendpoint = '1') THEN
          next_state <= errorpassiv_incsrecb;
        ELSE
          next_state <= errorpassiv_pufferrec;
        END IF;
--106-------------------------------------------------------------------------------
-- Puffer auf 0, da 1. rez. Bit domi überschrieben, auf sendpoint warten, kein
-- Erhöhung Fehlerzähler, da Ackerror (Exception 1 von Regel 3)
      WHEN errorpassiv_pufferdom =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF(sendpoint = '1') THEN
          next_state <= errorpassiv_incsrecb;
        ELSE
          next_state <= errorpassiv_pufferdom;
        END IF;
--110-------------------------------------------------------------------------------
-- Puffer auf 0, da 1. rez. Bit dom. überschrieben, auf sendpoint warten,
-- TEC+8, da Transmitter gewesen, aber kein Ackerror
      WHEN errorpassiv_pufferdomi =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '1';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF(sendpoint = '1') THEN
          next_state <= errorpassiv_incsrecb;
        ELSE
          next_state <= errorpassiv_pufferdomi;
        END IF;
--104-------------------------------------------------------------------------------
-- vorher domi, jetzt rezessiv, puffer auf 1 setzen, dann nach _newcount
      WHEN errorpassiv_zersrecbo =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "11";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        next_state      <= errorpassiv_newcount;
--103-------------------------------------------------------------------------------
-- vorher rez., jetzt domi, puffer auf 0 setzen, dann _newcount
      WHEN errorpassiv_zersrecbz =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        next_state      <= errorpassiv_newcount;
--101-------------------------------------------------------------------------------
-- vorher rez., jetzt dom. , vorher aber kein TEC+8, wg. Sender und Ackerror
-- (Ausnahme 1) dann jetzt aber TEC+8
      WHEN errorpassiv_zersrecbi =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '1';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        next_state      <= errorpassiv_newcount;
--118-------------------------------------------------------------------------------
-- Es wurde während des 2..6. Bit des Flags ein Bitwechsel entdeckt, die
-- Zählung beginnt von neuem (rescount!)
      WHEN errorpassiv_newcount =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "00";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        next_state      <= errorpassiv_prepcount;
--119-------------------------------------------------------------------------------
-- Zähler wurde zurückgesetzt, auf 1. Bit smplpoint warten
      WHEN errorpassiv_prepcount =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "00";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= errorpassiv_check1;
        ELSE
          next_state <= errorpassiv_prepcount;
        END IF;
--105-------------------------------------------------------------------------------
-- smplpoint aktuelles flagbit. Normal: warten auf sendpoint nächstes gleiches
-- Bit, oder übergang nach Delimiter. Wenn Änderung, über _zersrecbz,
-- _zersrecbi, zersrecbo nach _newcount und von vorne 6 gleiche suchen.
      WHEN errorpassiv_check1 =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "00";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "00";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF(sendpoint = '1'AND biterror = puffer AND biterror = '1'AND transmitter = '1'AND ackerror = '1')
        THEN
          next_state <= errorpassiv_zersrecbi;
        ELSIF(sendpoint = '1'AND biterror = puffer AND biterror = '1'AND(ackerror = '0'OR transmitter = '0'))
        THEN
          next_state <= errorpassiv_zersrecbz;
        ELSIF(sendpoint = '1'AND biterror = puffer AND biterror = '0') THEN
          next_state <= errorpassiv_zersrecbo;
        ELSIF (sendpoint = '1' AND biterror /= puffer AND count /= 6) THEN
          next_state <= errorpassiv_incsrecb;
        ELSIF (biterror /= puffer AND count = 6) THEN
          next_state <= errorpassiv_preprecb;
        ELSE
          next_state <= errorpassiv_check1;
        END IF;
--117-------------------------------------------------------------------------------
-- Abschluss des Flags, es wurden 6 rez. oder dom. Bit gefunden, warten auf
-- sendpoint des nächsten Bits (vielleicht ein rezessives, oder auch nicht)
      WHEN errorpassiv_preprecb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "11";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= errorpassiv_wtonrecb;
        ELSE
          next_state <= errorpassiv_preprecb;
        END IF;
--107-------------------------------------------------------------------------------
-- warten auf smplpoint des aktuellen Bits (erwarte rez. Delimiter)
      WHEN errorpassiv_wtonrecb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "00";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= errorpassiv_check2;
        ELSE
          next_state <= errorpassiv_wtonrecb;
        END IF;
--108-------------------------------------------------------------------------------
-- noch dominant nach flag, aber nicht Fehlerzähler erhöhen (hier first auf 0!)
-- auf nächsten smplpoint warten für _check2
      WHEN errorpassiv_dombitdct =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '1';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= errorpassiv_check2;
        ELSE
          next_state <= errorpassiv_dombitdct;
        END IF;
--111-------------------------------------------------------------------------------
-- 7 weitere dominante entdeckt und receiver gewesen -> REC+8
-- warten auf smplpoint für _check2
      WHEN errorpassiv_egtdombr =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '1';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= errorpassiv_check2;
        ELSE
          next_state <= errorpassiv_egtdombr;
        END IF;
--109-------------------------------------------------------------------------------
-- 7 weitere dominante entdeckt und transmitter gewesen -> TEC+8
-- warten auf smplpoint für _check2
      WHEN errorpassiv_egtdombt =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '1';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= errorpassiv_check2;
        ELSE
          next_state <= errorpassiv_egtdombt;
        END IF;
--112-------------------------------------------------------------------------------
-- smplpoint des aktuellen bits, warten auf delimiter. Wenn 1.Bit noch dominant,
-- Zähler erhöhen (_egtdombx), sonst warten (_wtonrecb)
      WHEN errorpassiv_check2 =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "00";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF(sendpoint = '1'AND biterror = '1'AND count /= 7 AND(count /= 1 OR receiver = '0' OR first = '0'))
        THEN
          next_state <= errorpassiv_wtonrecb;
        ELSIF(sendpoint = '1'AND biterror = '1'AND count = 1 AND receiver = '1'AND first = '1') THEN
          next_state <= errorpassiv_dombitdct;
        ELSIF(sendpoint = '1'AND biterror = '1'AND count = 7 AND transmitter = '1'AND receiver = '0') THEN
          next_state <= errorpassiv_egtdombt;
        ELSIF(sendpoint = '1'AND biterror = '1'AND count = 7 AND transmitter = '0'AND receiver = '1') THEN
          next_state <= errorpassiv_egtdombr;
        ELSIF (biterror = '0') THEN
          next_state <= errorpassiv_prepsend;
        ELSE
          next_state <= errorpassiv_check2;
        END IF;
--116-------------------------------------------------------------------------------
-- endlich ein rezessives Bit, der Delimiter beginnt (warten auf nächsten sendpoint)
      WHEN errorpassiv_prepsend =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1') THEN
          next_state <= errorpassiv_sendrecb;
        ELSE
          next_state <= errorpassiv_prepsend;
        END IF;
--113-------------------------------------------------------------------------------
-- Delimiter: mitsenden rezessiv, warten auf smplpoint für _check3
      WHEN errorpassiv_sendrecb =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '1';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '1';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '1';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= errorpassiv_check3;
        ELSE
          next_state <= errorpassiv_sendrecb;
        END IF;
--114-------------------------------------------------------------------------------
-- checken des Delimiters, warten auf nächsten Sendpoint. Delimiter gestört,-
-- dann wieder von vorne oder Busoff, ansonsten Zähler ok, ab zu _waitoclk
      WHEN errorpassiv_check3 =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '1';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '1';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (sendpoint = '1' AND biterror = '0'AND count /= 7) THEN
          next_state <= errorpassiv_sendrecb;
        ELSIF (sendpoint = '1' AND biterror = '0' AND count = 7) THEN
          next_state <= errorpassiv_waitoclk;
-- Controller geht nicht von EP nach EA, während EP Delimiter
--        ELSIF (biterror = '1' AND erroractiv = '1') THEN
--          next_state <= erroractiv_firstdom;
        ELSIF (biterror = '1' AND errorpassiv = '1') THEN
          next_state <= errorpassiv_firstrec;
        ELSIF (biterror = '1' AND busof = '1') THEN
          next_state <= busoff_first;
        ELSE
          next_state <= errorpassiv_check3;
        END IF;
--115-------------------------------------------------------------------------------
-- warten auf smplpoint 1. Intermission bit, dann an den Anfang
      WHEN errorpassiv_waitoclk =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '1';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '0';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '1';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '0';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "00"; receiver_set <= "00"; error_set <= "11";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= inter_sample;
        ELSE
          next_state <= errorpassiv_waitoclk;
        END IF;

-------------------------------------------------------------------------------
-- FSM-Unterteilung: Ende ERRORPASSIVE
--                   Anfang BUSOFF, Einziger Einstieg: 120,busoff_first
------------------------------------------------------------------------------- 
--120-------------------------------------------------------------------------------
-- warten auf 1. Smplpoint, counter resetten (rescount!)
      WHEN busoff_first =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= busoff_sample;
        ELSE
          next_state <= busoff_first;
        END IF;
--121-------------------------------------------------------------------------------
-- smplpoint aktuelles bit, wenn rez, zähler erhöhen, wenn dom. zähler resetten
      WHEN busoff_sample =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '1';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (inbit = '1' AND count /= 10) THEN
          next_state <= busoff_increm;
        ELSIF (inbit = '1' AND count = 10) THEN
          next_state <= busoff_deccnt;
        ELSE
          next_state <= busoff_setzer;
        END IF;
--123-------------------------------------------------------------------------------
-- war rez., zähler erhöhen, auf nächsten smplpoint warten
      WHEN busoff_increm =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '1';     rescount <= '1';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= busoff_sample;
        ELSE
          next_state <= busoff_increm;
        END IF;
--122-------------------------------------------------------------------------------
-- war dominant, keine 11 gleichen hintereinander, zähler resetten, nächsten
-- smplpoint abwarten
      WHEN busoff_setzer =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '0';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '1';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1') THEN
          next_state <= busoff_sample;
        ELSE
          next_state <= busoff_setzer;
        END IF;
--124-------------------------------------------------------------------------------
-- war rez., und das 11. Bit, Signal elevrecb für FCE (128 davon= Ende Busoff),
-- counter zurücksetzen, auf nächsten smplpoint warten.
      WHEN busoff_deccnt =>
        rext_set        <= "10"; rrtr_set <= "10";     actvtcrc <= '0';
        actvrcrc        <= '0';  actvtstf <= '0';      actvrstf <= '0';     actvtsft <= '0';
        actvrsft        <= '0';  actvtdct <= '0';      actvrdct <= '1';     actvtbed <= '0';
        setbdom         <= '0';  setbrec <= '0';       lcrc <= '0';           tshift <= '0';
        inconerec       <= '0';  incegtrec <= '0';     incegttra <= '0';    lmsg <= '0';
        decrec          <= '0';  dectra <= '0';        elevrecb <= '1';     hardsync <= '0';
        resetdst        <= '1';  resetstf <= '0';      inccount <= '0';     rescount <= '0';
        setrmleno       <= 0;    actvrmln <= '0';      resrmlen <= '1';     ackerror_set <= "10";
        transmitter_set <= "10"; receiver_set <= "10"; error_set <= "10";   first_set <= "10";
        activatefast    <= '0';  puffer_set <= "10";   onarbit_set <= "10"; en_zerointcrc <= '1'; 
        crc_shft_out <= '0';
        IF (smplpoint = '1' AND busof = '1') THEN
          next_state <= busoff_sample;
        ELSIF (smplpoint = '1' AND busof = '0') THEN
          next_state <= inter_sample;
        ELSE
          next_state <= busoff_deccnt;
        END IF;
 --     WHEN OTHERS =>
 --       next_state <= sync_start;
-------------------------------------------------------------------------------
    END CASE;
  END PROCESS;
-------------------------------------------------------------------------------
-- Zustandsvektor
-------------------------------------------------------------------------------
  synch : PROCESS(clock, reset)  -- DW 2005.06.30 Prescale Enable eingefügt
  BEGIN
    IF (reset = '0') THEN              -- DW 2005.06.30 Aus dem synchronen Reset wird ein asynchroner Reset.
       current_state <= sync_start;    -- define the reset state
    ELSIF (clock'event AND clock = '1') THEN  -- pos. clock
      IF (Prescale_EN = '1') THEN      -- DW 2005.06.30 Prescale Enable eingefügt
        current_state <= next_state;
      END IF;
    END IF;
  END PROCESS;

statedeb_p : PROCESS (current_state)
BEGIN  -- PROCESS e
  CASE current_state IS
    WHEN sync_start             => statedeb <= x"00";
    WHEN sync_sample            => statedeb <= x"01";
    WHEN sync_sum               => statedeb <= x"02";
    WHEN sync_end               => statedeb <= x"03";
    WHEN inter_sample           => statedeb <= x"04";
    WHEN inter_check            => statedeb <= x"05";
    WHEN inter_goregtran        => statedeb <= x"06";
    WHEN inter_react            => statedeb <= x"07";
    WHEN bus_idle_chk           => statedeb <= x"08";
    WHEN bus_idle_sample        => statedeb <= x"09";
    WHEN inter_transhift        => statedeb <= x"0a";
    WHEN inter_regtrancnt       => statedeb <= x"0b";
    WHEN inter_preprec          => statedeb <= x"0c";
    WHEN inter_incsigres        => statedeb <= x"0d";
    WHEN tra_arbit_tactrsftn    => statedeb <= x"0e";
    WHEN tra_arbit_tactrsftsr   => statedeb <= x"0f";
    WHEN tra_arbit_tactrsfte    => statedeb <= x"10";
    WHEN tra_arbit_tactrsfter   => statedeb <= x"11";
    WHEN tra_arbit_tnactrnsft   => statedeb <= x"12";
    WHEN tra_arbit_tsftrsmpl    => statedeb <= x"13";
    WHEN tra_arbit_tnsftrsmpl   => statedeb <= x"14";
    WHEN tra_arbit_goreceive    => statedeb <= x"15";
    WHEN tra_data_activatecrc   => statedeb <= x"16";
    WHEN tra_data_activatncrc   => statedeb <= x"17";
    WHEN tra_data_shifting      => statedeb <= x"18";
    WHEN tra_data_noshift       => statedeb <= x"19";
    WHEN tra_data_lastshift     => statedeb <= x"1a";
    WHEN tra_data_loadcrc       => statedeb <= x"1b";
    WHEN tra_crc_activatedec    => statedeb <= x"1c";
    WHEN tra_crc_activatndec    => statedeb <= x"1d";
    WHEN tra_crc_shifting       => statedeb <= x"1e";
    WHEN tra_crc_noshift        => statedeb <= x"1f";
    WHEN tra_crc_delshft        => statedeb <= x"20";
    WHEN tra_ack_sendack        => statedeb <= x"21";
    WHEN tra_ack_shifting       => statedeb <= x"22";
    WHEN tra_ack_stopack        => statedeb <= x"23";
    WHEN tra_edof_sendrecb      => statedeb <= x"24";
    WHEN tra_edof_shifting      => statedeb <= x"25";
    WHEN rec_flglen_sample      => statedeb <= x"26";
    WHEN rec_flglen_shiftstdrtr => statedeb <= x"27";
    WHEN rec_flglen_shiftextnor => statedeb <= x"28";
    WHEN rec_flglen_shiftdlc64  => statedeb <= x"29";
    WHEN rec_flglen_shiftdlc32  => statedeb <= x"2a";
    WHEN rec_flglen_shiftdlc16  => statedeb <= x"2b";
    WHEN rec_flglen_shiftdlc8   => statedeb <= x"2c";
    WHEN rec_flglen_shiftextrtr => statedeb <= x"2d";
    WHEN rec_flglen_shifting    => statedeb <= x"2e";
    WHEN rec_flglen_noshift     => statedeb <= x"2f";
    WHEN rec_acptdat_sample     => statedeb <= x"30";
    WHEN rec_acptdat_shifting   => statedeb <= x"31";
    WHEN rec_acptdat_noshift    => statedeb <= x"32";
    WHEN rec_crc_rescnt         => statedeb <= x"33";
    WHEN rec_crc_sample         => statedeb <= x"34";
    WHEN rec_crc_shifting       => statedeb <= x"35";
    WHEN rec_crc_noshift        => statedeb <= x"36";
    WHEN rec_ack_recdelim       => statedeb <= x"37";
    WHEN rec_ack_prepgiveack    => statedeb <= x"38";
    WHEN rec_ack_prepnoack      => statedeb <= x"39";
    WHEN rec_ack_noack          => statedeb <= x"3a";
    WHEN rec_ack_giveack        => statedeb <= x"3b";
    WHEN rec_ack_checkack       => statedeb <= x"3c";
    WHEN rec_ack_stopack        => statedeb <= x"3d";
    WHEN rec_edof_sample        => statedeb <= x"3e";
    WHEN rec_edof_check         => statedeb <= x"3f";
    WHEN rec_edof_endrec        => statedeb <= x"40";
    WHEN rec_flglen_setdlc      => statedeb <= x"41";
    WHEN rec_acptdat_lastshift  => statedeb <= x"42";
    WHEN over_firstdom          => statedeb <= x"43";
    WHEN over_senddomb          => statedeb <= x"44";
    WHEN over_check1            => statedeb <= x"45";
    WHEN over_preprecb          => statedeb <= x"46";
    WHEN over_wtonrecb          => statedeb <= x"47";
    WHEN over_increccounter     => statedeb <= x"48";
    WHEN over_inctracounter     => statedeb <= x"49";
    WHEN over_check2            => statedeb <= x"4a";
    WHEN over_sendrecb          => statedeb <= x"4b";
    WHEN over_check3            => statedeb <= x"4c";
    WHEN over_waitoclk          => statedeb <= x"4d";
    WHEN over_prepsend          => statedeb <= x"4e";
    WHEN erroractiv_firstdom    => statedeb <= x"4f";
    WHEN erroractiv_inceinsrec  => statedeb <= x"50";
    WHEN erroractiv_incachtrec  => statedeb <= x"51";
    WHEN erroractiv_incachttra  => statedeb <= x"52";
    WHEN erroractiv_senddomb    => statedeb <= x"53";
    WHEN erroractiv_check1      => statedeb <= x"54";
    WHEN erroractiv_preprecb    => statedeb <= x"55";
    WHEN erroractiv_wtonrecb    => statedeb <= x"56";
    WHEN erroractiv_dombitdct   => statedeb <= x"57";
    WHEN erroractiv_egtdombt    => statedeb <= x"58";
    WHEN erroractiv_egtdombr    => statedeb <= x"59";
    WHEN erroractiv_check2      => statedeb <= x"5a";
    WHEN erroractiv_sendrecb    => statedeb <= x"5b";
    WHEN erroractiv_check3      => statedeb <= x"5c";
    WHEN erroractiv_waitoclk    => statedeb <= x"5d";
    WHEN erroractiv_prepsend    => statedeb <= x"5e";
    WHEN errorpassiv_firstrec   => statedeb <= x"5f";
    WHEN errorpassiv_inceinsrec => statedeb <= x"60";
    WHEN errorpassiv_incachtrec => statedeb <= x"61";
    WHEN errorpassiv_fillpuffer => statedeb <= x"62";
    WHEN errorpassiv_incachttra => statedeb <= x"63";
    WHEN errorpassiv_incsrecb   => statedeb <= x"64";
    WHEN errorpassiv_zersrecbi  => statedeb <= x"65";
    WHEN errorpassiv_pufferrec  => statedeb <= x"66";
    WHEN errorpassiv_zersrecbz  => statedeb <= x"67";
    WHEN errorpassiv_zersrecbo  => statedeb <= x"68";
    WHEN errorpassiv_check1     => statedeb <= x"69";
    WHEN errorpassiv_pufferdom  => statedeb <= x"6a";
    WHEN errorpassiv_wtonrecb   => statedeb <= x"6b";
    WHEN errorpassiv_dombitdct  => statedeb <= x"6c";
    WHEN errorpassiv_egtdombt   => statedeb <= x"6d";
    WHEN errorpassiv_pufferdomi => statedeb <= x"6e";
    WHEN errorpassiv_egtdombr   => statedeb <= x"6f";
    WHEN errorpassiv_check2     => statedeb <= x"70";
    WHEN errorpassiv_sendrecb   => statedeb <= x"71";
    WHEN errorpassiv_check3     => statedeb <= x"72";
    WHEN errorpassiv_waitoclk   => statedeb <= x"73";
    WHEN errorpassiv_prepsend   => statedeb <= x"74";
    WHEN errorpassiv_preprecb   => statedeb <= x"75";
    WHEN errorpassiv_newcount   => statedeb <= x"76";
    WHEN errorpassiv_prepcount  => statedeb <= x"77";
    WHEN busoff_first           => statedeb <= x"78";
    WHEN busoff_sample          => statedeb <= x"79";
    WHEN busoff_setzer          => statedeb <= x"7a";
    WHEN busoff_increm          => statedeb <= x"7b";
    WHEN busoff_deccnt          => statedeb <= x"7c";
    WHEN rec_edof_lastbit       => statedeb <= x"7d";
    WHEN rec_edof_inter         => statedeb <= x"7e";
    WHEN tra_edof_dectra        => statedeb <= x"7f";
    WHEN inter_preprec_shifting => statedeb <= x"80";
    WHEN inter_arbit_tsftrsmpl  => statedeb <= x"81";
    WHEN OTHERS                 => statedeb <= x"ff";
  END CASE;
END PROCESS statedeb_p;

END behv;

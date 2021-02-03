-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                         
-------------------------------------------------------------------------------
--                            Datei: mac.vhd
--                     Beschreibung: medium access controller
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Strukturorientiert, bis auf einige zusammengeführte resetsignale
-- Instanz : Komponente : Aufgabe
-- reset_mac_i : reset_mac: Erzeugt langen Resetimpuls für MAC (synchron)
-- fsm : macfsm : Zustandsmaschine
-- errordetect : biterrordetect : Bitvergleich in/out
-- counting : counter : Bitpositionszähler, Signale für fsm intermission
-- decaps : decapsulation : ID für LLC, Register zusammenstellen (aus rshift)
-- destuff : destuffing : Bitstuffing Empfang, kann abgeschaltet werden
-- encaps : encapsulation : ID aus IOCPU für tshift zusammenstellen
-- receivecrc : rcrc : Empfangs CRC prüfen (Ausgang: OK,/OK)
-- recmlen : recmeslen : Empfangenen DLC auswerten, realen DLC (rmlb) bereitstellen
-- recshift : rshiftreg : Empfangsschieberegister
-- stuff : stuffing : Bitstuffing senden
-- transmitcrc : tcrc : Sende CRC Register
-- transhift : tshiftreg : Sendeschieberegister
-- fsm_regs : fsm_register : Aus FSM ausgelagerte Register (Synthese)
-- frshift : fastshift : rshift passend schieben, s. entity fastshift
-- comparator : meslencompare : signalisiert Steuerbitpositionen beim Empfang
-- DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.

-- | Leduc | 12.02.2020 | Added Changes done in Verilog Triplication Files
  
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY mac1 IS
  PORT(clock       : IN  bit;           -- aussen
       Prescale_EN : IN  bit;           -- DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
       reset       : IN  bit;           -- reset_mac
       sendpoint   : IN  bit;           -- bittiming
       smplpoint   : IN  bit;           -- bittiming
       inbit       : IN  bit;           -- destuffing
       trans       : IN  bit;           -- llc
       erroractiv  : IN  bit;           -- fce
       errorpassiv : IN  bit;           -- fce
       busof       : IN  bit;           -- fce
       load        : IN  bit;           -- llc
       actvtsftllc : IN  bit;           -- llc
       actvtcap    : IN  bit;           -- llc
       resettra    : IN  bit;           -- llc
       identifierr : IN  bit_vector( 28 DOWNTO 0);  -- IOCPU
       data1r      : IN  bit_vector( 7 DOWNTO 0);  -- IOCPU
       data2r      : IN  bit_vector( 7 DOWNTO 0);  -- IOCPU
       data3r      : IN  bit_vector( 7 DOWNTO 0);  -- IOCPU
       data4r      : IN  bit_vector( 7 DOWNTO 0);  -- IOCPU
       data5r      : IN  bit_vector( 7 DOWNTO 0);  -- IOCPU
       data6r      : IN  bit_vector( 7 DOWNTO 0);  -- IOCPU
       data7r      : IN  bit_vector( 7 DOWNTO 0);  -- IOCPU
       data8r      : IN  bit_vector( 7 DOWNTO 0);  -- IOCPU
       extendedr   : IN  bit;  -- IOCPU
       remoter     : IN  bit;  -- IOCPU
       datalenr    : IN  bit_vector( 3 DOWNTO 0);  -- IOCPU
       identifierw : OUT bit_vector( 28 DOWNTO 0);  -- IOCPU, LLC
       data1w      : OUT bit_vector( 7 DOWNTO 0);  -- IOCPU
       data2w      : OUT bit_vector( 7 DOWNTO 0);  -- IOCPU
       data3w      : OUT bit_vector( 7 DOWNTO 0);  -- IOCPU
       data4w      : OUT bit_vector( 7 DOWNTO 0);  -- IOCPU
       data5w      : OUT bit_vector( 7 DOWNTO 0);  -- IOCPU
       data6w      : OUT bit_vector( 7 DOWNTO 0);  -- IOCPU
       data7w      : OUT bit_vector( 7 DOWNTO 0);  -- IOCPU
       data8w      : OUT bit_vector( 7 DOWNTO 0);  -- IOCPU
       remotew     : OUT bit;  -- IOCPU
       datalenw    : OUT bit_vector( 3 DOWNTO 0);  -- IOCPU
       inconerec   : OUT bit;           -- fce
       incegtrec   : OUT bit;           -- fce
       incegttra   : OUT bit;           -- fce
       decrec      : OUT bit;           -- fce
       dectra      : OUT bit;           -- fce
       elevrecb    : OUT bit;           -- fce
       hardsync    : OUT bit;           -- bittiming
       outbit      : OUT bit;
       statedeb    : OUT std_logic_vector(7 DOWNTO 0)
       );          -- aussen
END mac1;
-------------------------------------------------------------------------------
ARCHITECTURE behv OF mac1 IS
  
  COMPONENT reset_mac1
    PORT (
      reset      : IN  bit;
      sync_reset : OUT bit;
      clock      : IN  bit;
      prescaler  : IN  bit);
  END COMPONENT;
-------------------------------------------------------------------------------  
  COMPONENT biterrordetect1
    PORT(clock    : IN  bit;
         bitin    : IN  bit;
         bitout   : IN  bit;
         activ    : IN  bit;
         reset    : IN  bit;
         biterror : OUT bit);
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT counter1
    PORT(clock         : IN  bit;
         Prescale_EN   : IN  bit;       -- DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
         inc           : IN  bit;       -- neu zur synchronisation
         reset         : IN  bit;
         lt3, gt3, eq3 : OUT bit;
         lt11, eq11    : OUT bit;
         counto        : OUT integer RANGE 0 TO 127);
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT decapsulation1
    PORT (
      message_b  : IN  bit_vector(17 DOWNTO 0);
      message_c  : IN  bit_vector(10 DOWNTO 0);
      extended   : IN  bit;
      identifier : OUT bit_vector( 28 DOWNTO 0));
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT destuffing1
    PORT(clock  : IN  bit;
         bitin  : IN  bit;
         activ  : IN  bit;
         reset  : IN  bit;
         direct : IN  bit;
         stfer  : OUT bit;
         stuff  : OUT bit;
         bitout : OUT bit);
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT encapsulation1 
    PORT(clock      : IN bit;
         identifier : IN bit_vector( 28 DOWNTO 0);
         extended   : IN bit;
         remote     : IN bit;
         activ      : IN bit;
         reset      : IN bit;
         datalen    : IN bit_vector( 3 DOWNTO 0);
         tmlen : OUT bit_vector(3 DOWNTO 0);
         message : OUT bit_vector(38 DOWNTO 0));
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT macfsm1
    PORT(clock       : IN bit;
         Prescale_EN : IN bit;    -- DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
         reset       : IN bit;
         sendpoint   : IN bit;
         smplpoint   : IN bit;
         crc_ok      : IN bit;
         inbit       : IN bit;
         stufft      : IN bit;
         stuffr      : IN bit;
         biterror    : IN bit;
         stferror    : IN bit;
         trans       : IN bit;
         text        : IN bit;
         erroractiv  : IN bit;
         errorpassiv : IN bit;
         busof       : IN bit;
         ackerror    : IN bit;
         onarbit     : IN bit;
         transmitter : IN bit;
         receiver    : IN bit;
         error       : IN bit;
         first       : IN bit;
         puffer      : IN bit;
         rext        : IN bit;
         rrtr        : IN bit;
         startrcrc : IN bit;
         rmzero    : IN bit;
         starttcrc : IN bit;
         lt3, gt3, eq3 : IN bit;
         lt11, eq11    : IN bit;
         ackerror_set    : OUT bit_vector(1 DOWNTO 0);
         onarbit_set     : OUT bit_vector(1 DOWNTO 0);
         transmitter_set : OUT bit_vector(1 DOWNTO 0);
         receiver_set    : OUT bit_vector(1 DOWNTO 0);
         error_set       : OUT bit_vector(1 DOWNTO 0);
         first_set       : OUT bit_vector(1 DOWNTO 0);
         puffer_set      : OUT bit_vector(1 DOWNTO 0);
         rext_set        : OUT bit_vector(1 DOWNTO 0);
         rrtr_set        : OUT bit_vector(1 DOWNTO 0);
         count           : IN  integer RANGE 0 TO 127;
         setrmleno       : OUT integer RANGE 0 TO 7;
         actvrmln        : OUT bit;
         actvtcrc        : OUT bit;
         actvrcrc        : OUT bit;
         actvtstf        : OUT bit;
         actvrstf        : OUT bit;     --destuffing.vhd
         actvtsft        : OUT bit;
         actvrsft        : OUT bit;
         actvtdct        : OUT bit;
         actvrdct        : OUT bit;     --destuffing.vhd
         actvtbed        : OUT bit;
         setbdom         : OUT bit;
         setbrec         : OUT bit;
         lcrc            : OUT bit;
         lmsg            : OUT bit;
         tshift          : OUT bit;
         inconerec       : OUT bit;
         incegtrec       : OUT bit;
         incegttra       : OUT bit;
         decrec          : OUT bit;
         dectra          : OUT bit;
         elevrecb        : OUT bit;
         hardsync        : OUT bit;
         inccount        : OUT bit;
         resrmlen        : OUT bit;
         rescount        : OUT bit;
         resetdst        : OUT bit;
         resetstf        : OUT bit;
         activatefast    : OUT bit;
         crc_shft_out    : OUT bit;
         en_zerointcrc   : OUT bit;
         statedeb        : OUT std_logic_vector(7 DOWNTO 0)
);
 END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT rcrc1
    PORT(clock  : IN  bit;
         bitin  : IN  bit;
         activ  : IN  bit;
         reset  : IN  bit;
         crc_ok : OUT bit);
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT recmeslen1
    PORT(clock    : IN  bit;
         activ    : IN  bit;
         reset    : IN  bit;
         setrmlen : IN  integer RANGE 0 TO 7;
         rmlb     : OUT bit_vector(3 DOWNTO 0));
  END COMPONENT;
-------------------------------------------------------------------------------
--Das crcrecv register wird nicht mehr gebraucht, da der empfangene crc direkt
--durch das receive crc geschoben wird und er ok ist, wenns danach 0 ist.
--deshalb wegfall der eingänge lcrc (load crc) und crcrecv. lcrc als signal
--darf in dieser hierarchie aber nicht gelöscht werden, da es benutzt wird um
--das transmit shift register mit dem crc zu laden, wenn gesendet wird.
  COMPONENT rshiftreg1
    PORT(clock       : IN  bit;
         bitin       : IN  bit;
         activ       : IN  bit;
         reset       : IN  bit;
         lcrc        : IN  bit;
         setzero     : IN  bit;
         directshift : IN  bit;
         mesout_a    : OUT bit_vector(67 DOWNTO 0);
         mesout_b    : OUT bit_vector(17 DOWNTO 0);
         mesout_c    : OUT bit_vector(10 DOWNTO 0));   
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT stuffing1
    PORT(clock  : IN  bit;
         bitin  : IN  bit;
         activ  : IN  bit;
         reset  : IN  bit;
         direct : IN  bit;
         setdom : IN  bit;
         setrec : IN  bit;
         bitout : OUT bit;
         stuff  : OUT bit);
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT tcrc1 
    PORT(clock            : IN  bit;
         bitin            : IN  bit;
         activ            : IN  bit;
         reset            : IN  bit;
         crc_pre_load_ext : IN  bit_vector(14 DOWNTO 0);  --neu, siehe tcrc
         crc_pre_load_rem : IN  bit_vector(14 DOWNTO 0);
         extended         : IN  bit;
         load             : IN  bit;                      -- neu
         load_activ       : IN  bit;                      -- neu
         crc_shft_out     : IN  bit;
         zerointcrc       : IN  bit;
         crc_tosend       : OUT bit);        
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT tshiftreg1 
    PORT(clock       : IN  bit;
         mesin       : IN  bit_vector(102 DOWNTO 0);
         activ       : IN  bit;
         reset       : IN  bit;
         load        : IN  bit;
         shift       : IN  bit;
         extended    : IN  bit;
         bitout      : OUT bit;
         crc_out_bit : OUT bit);
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT fsm_register1
    PORT (
      clock           : IN  bit;
      reset           : IN  bit;
      ackerror_set    : IN  bit_vector(1 DOWNTO 0);
      onarbit_set     : IN  bit_vector(1 DOWNTO 0);
      transmitter_set : IN  bit_vector(1 DOWNTO 0);
      receiver_set    : IN  bit_vector(1 DOWNTO 0);
      error_set       : IN  bit_vector(1 DOWNTO 0);
      first_set       : IN  bit_vector(1 DOWNTO 0);
      puffer_set      : IN  bit_vector(1 DOWNTO 0);
      rext_set        : IN  bit_vector(1 DOWNTO 0);
      rrtr_set        : IN  bit_vector(1 DOWNTO 0);
      ackerror        : OUT bit;
      onarbit         : OUT bit;
      transmitter     : OUT bit;
      receiver        : OUT bit;
      error           : OUT bit;
      first           : OUT bit;
      puffer          : OUT bit;
      rext            : OUT bit;
      rrtr            : OUT bit);
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT fastshift1
    PORT (
      reset       : IN  bit;
      clock       : IN  bit;
      activate    : IN  bit;
      rmlb        : IN  bit_vector(3 DOWNTO 0);
      setzero     : OUT bit;
      directshift : OUT bit);
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT meslencompare1
    PORT (
      count         : IN  integer RANGE 0 TO 127;
      rmlen         : IN  bit_vector(3 DOWNTO 0);
      tmlen         : IN  bit_vector(3 DOWNTO 0);
      ext_r         : IN  bit;
      ext_t         : IN  bit;
      en_zerointcrc : IN  bit;
      startrcrc     : OUT bit;
      rmzero        : OUT bit;
      starttcrc     : OUT bit;
      zerointcrc    : OUT bit);
  END COMPONENT;
-------------------------------------------------------------------------------

  SIGNAL stufft    : bit;
  SIGNAL stuffr    : bit;
  SIGNAL biterror  : bit;
  SIGNAL stferror  : bit;
  SIGNAL count     : integer RANGE 0 TO 127;
  SIGNAL rmlb      : bit_vector(3 DOWNTO 0);  -- rmlen in Byte
  SIGNAL setrmleno : integer RANGE 0 TO 7;
  SIGNAL actvrmln  : bit;
 -- SIGNAL actvrcap  : bit;
  SIGNAL actvtcrc  : bit;
  SIGNAL actvrcrc  : bit;
  SIGNAL actvtstf  : bit;
  SIGNAL actvrstf  : bit;
  SIGNAL actvtsft  : bit;
  SIGNAL actvrsft  : bit;
  SIGNAL actvtdct  : bit;
  SIGNAL actvrdct  : bit;
  SIGNAL actvtbed  : bit;
  SIGNAL setbdom   : bit;
  SIGNAL setbrec   : bit;
  SIGNAL lcrc      : bit;
  SIGNAL lmsg      : bit;
  SIGNAL tshift    : bit;
  SIGNAL inccount  : bit;
  SIGNAL resrmlen  : bit;
  SIGNAL rescount  : bit;
  SIGNAL resetdst  : bit;
  SIGNAL resetstf  : bit;
  SIGNAL bitout : bit;
  SIGNAL mesout_a : bit_vector(67 DOWNTO 0);  -- 0...67
  SIGNAL mesout_b : bit_vector(17 DOWNTO 0);  -- 71..88
  SIGNAL mesout_c : bit_vector(10 DOWNTO 0);  -- 91..101
  SIGNAL mesin    : bit_vector(102 DOWNTO 0);
  SIGNAL bittosend   : bit;
  SIGNAL receivedbit : bit;
  SIGNAL actvtsftsig : bit;
  SIGNAL resetsig    : bit;
  SIGNAL resetstfsig : bit;
  SIGNAL rescountsig : bit;
  SIGNAL resrmlensig : bit;
  SIGNAL resetdstsig : bit;
  SIGNAL loader : bit;
  SIGNAL crc_pre_load_sig_ext : bit_vector(14 DOWNTO 0);  -- änderung im crc
  SIGNAL crc_pre_load_sig_rem : bit_vector(14 DOWNTO 0);  -- änderung im crc
  SIGNAL crc_out_bit          : bit;    -- aus dem tshit ins crc
  SIGNAL crc_ok               : bit;    -- statt rest (14 downto 0)
  SIGNAL ackerror_set_i    : bit_vector(1 DOWNTO 0);
  SIGNAL onarbit_set_i     : bit_vector(1 DOWNTO 0);
  SIGNAL transmitter_set_i : bit_vector(1 DOWNTO 0);
  SIGNAL receiver_set_i    : bit_vector(1 DOWNTO 0);
  SIGNAL error_set_i       : bit_vector(1 DOWNTO 0);
  SIGNAL first_set_i       : bit_vector(1 DOWNTO 0);
  SIGNAL puffer_set_i      : bit_vector(1 DOWNTO 0);
  SIGNAL rext_set_i        : bit_vector(1 DOWNTO 0);
  SIGNAL rrtr_set_i        : bit_vector(1 DOWNTO 0);
  SIGNAL ackerror_i    : bit;
  SIGNAL onarbit_i     : bit;
  SIGNAL transmitter_i : bit;
  SIGNAL receiver_i    : bit;
  SIGNAL error_i       : bit;
  SIGNAL first_i       : bit;
  SIGNAL puffer_i      : bit;
  SIGNAL rext          : bit;
  SIGNAL rrtr          : bit;
  SIGNAL rmzero        : bit;
 -- SIGNAL equal19, equal39,   -- ersatz für rec_data_shifting
 -- SIGNAL tequal19, tequal39       : bit;  -- ersatz in tra_data_fsm
  SIGNAL lt3_i, gt3_i, eq3_i      : bit;  -- inter_fsm : von count
  SIGNAL lt11_i, eq11_i           : bit;  --    "           "
  SIGNAL activatefast : bit;            -- neue Entitiy: Fastshift
  SIGNAL directshift  : bit;
  SIGNAL setzero      : bit;
  SIGNAL crc_shft_out : bit;
  SIGNAL crc_tosend   : bit;
  SIGNAL stuff_inbit  : bit;
 -- SIGNAL rmlen         : bit_vector(3 DOWNTO 0);
  SIGNAL tmlen         : bit_vector(3 DOWNTO 0);
  SIGNAL startrcrc_i   : bit;
  SIGNAL starttcrc_i   : bit;
  SIGNAL zerointcrc_i  : bit;
  SIGNAL en_zerointcrc : bit;
  SIGNAL sync_reset_i : bit;
-------------------------------------------------------------------------------  
BEGIN

-- obsolete decapsulation (siehe fastshift):
-- data1w..data8w und datalen kommen aus recshift
-- extendedw und remotew kommen aus fsm_regs

  remotew  <= rrtr;
  datalenw <= mesout_a(67 DOWNTO 64);
  data1w   <= mesout_a(63 DOWNTO 56);
  data2w   <= mesout_a(55 DOWNTO 48);
  data3w   <= mesout_a(47 DOWNTO 40);
  data4w   <= mesout_a(39 DOWNTO 32);
  data5w   <= mesout_a(31 DOWNTO 24);
  data6w   <= mesout_a(23 DOWNTO 16);
  data7w   <= mesout_a(15 DOWNTO 8);
  data8w   <= mesout_a( 7 DOWNTO 0);


-- Da Sende CRC, zum Senderegister wird muss Stuffing jetzt aus dem CRC sein
-- Signal bekommen, abhängige: crc_shft_out (MACFSM)
  stuff_inbit        <= (crc_shft_out AND crc_tosend) OR ((NOT crc_shft_out) AND bittosend);
  mesin(63 DOWNTO 0) <= data1r & data2r & data3r & data4r &
                        data5r & data6r & data7r & data8r;
-- Transmit CRC vorladen mit ext oder basic (rem???-egal) datenanfang
  crc_pre_load_sig_ext <= mesin(102 DOWNTO 88);
  crc_pre_load_sig_rem <= mesin(82 DOWNTO 68);

-- actvtsft aus llc und macfsm zusammenführen
  PROCESS(actvtsft, actvtsftllc)
  BEGIN
    actvtsftsig <= actvtsft OR actvtsftllc;
  END PROCESS;
-- reset aus mac_reset und llc zusammenführen
  PROCESS(sync_reset_i, resettra)
  BEGIN
    resetsig <= sync_reset_i AND resettra;
  END PROCESS;
-- reset aus mac_reset und llc und mac zusammenführen
  PROCESS(sync_reset_i, resettra, resetstf)
  BEGIN
    resetstfsig <= sync_reset_i AND resettra AND resetstf;
  END PROCESS;
-- reset aus mac_reset und mac zusammenführen
  PROCESS(sync_reset_i, rescount)              -- rescounto == rescount
  BEGIN
    rescountsig <= sync_reset_i AND rescount;  -- nicht mehr problematisch
  END PROCESS;
-- reset aus mac_reset und mac zusammenführen
  PROCESS(sync_reset_i, resrmlen)
  BEGIN
    resrmlensig <= sync_reset_i AND resrmlen;
  END PROCESS;
-- reset aus mac_reset und mac zusammenführen
  PROCESS(sync_reset_i, resetdst)       -- restdsto==resetdst
  BEGIN
    resetdstsig <= sync_reset_i AND resetdst;
  END PROCESS;
-- Ausgabe
  PROCESS(bitout)
  BEGIN
    outbit <= bitout;
  END PROCESS;
-- ladesignal für tshift aus macfsm und llc zusammenführen
  tshiftreg_loader : PROCESS(load, lmsg)
  BEGIN
    loader <= load OR lmsg;
  END PROCESS;

-------------------------------------------------------------------------------
  reset_mac_i : reset_mac1
    PORT MAP (
      reset      => reset,
      sync_reset => sync_reset_i,
      clock      => clock,
      prescaler  => Prescale_EN);   -- DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
-------------------------------------------------------------------------------  
  fsm : macfsm1
    PORT MAP (
      clock       => clock,         -- DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
      Prescale_EN => Prescale_EN,   -- DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
      reset       => sync_reset_i,
      sendpoint   => sendpoint,
      smplpoint   => smplpoint,
      crc_ok      => crc_ok,
      inbit       => receivedbit,
      stufft      => stufft,
      stuffr      => stuffr,
      biterror    => biterror,
      stferror    => stferror,
      trans       => trans,
      text        => extendedr,
      erroractiv  => erroractiv,
      errorpassiv => errorpassiv,
      busof       => busof,
      ackerror    => ackerror_i,
      onarbit     => onarbit_i,
      transmitter => transmitter_i,
      receiver    => receiver_i,
      error       => error_i,
      first       => first_i,
      puffer      => puffer_i,
      rext        => rext,
      rrtr        => rrtr,
      startrcrc   => startrcrc_i,
      rmzero      => rmzero,
      starttcrc   => starttcrc_i,
      lt3         => lt3_i,
      gt3         => gt3_i,
      eq3         => eq3_i,
      lt11        => lt11_i,
      eq11        => eq11_i,
      ackerror_set    => ackerror_set_i,
      onarbit_set     => onarbit_set_i,
      transmitter_set => transmitter_set_i,
      receiver_set    => receiver_set_i,
      error_set       => error_set_i,
      first_set       => first_set_i,
      puffer_set      => puffer_set_i,
      rext_set        => rext_set_i,
      rrtr_set        => rrtr_set_i,
      count         => count,
      setrmleno     => setrmleno,
      actvrmln      => actvrmln,
      actvtcrc      => actvtcrc,
      actvrcrc      => actvrcrc,
      actvtstf      => actvtstf,
      actvrstf      => actvrstf,
      actvtsft      => actvtsft,
      actvrsft      => actvrsft,
      actvtdct      => actvtdct,
      actvrdct      => actvrdct,
      actvtbed      => actvtbed,
      setbdom       => setbdom,
      setbrec       => setbrec,
      lcrc          => lcrc,
      lmsg          => lmsg,
      tshift        => tshift,
      inconerec     => inconerec,
      incegtrec     => incegtrec,
      incegttra     => incegttra,
      decrec        => decrec,
      dectra        => dectra,
      elevrecb      => elevrecb,
      hardsync      => hardsync,
      inccount      => inccount,
      resrmlen      => resrmlen,
      rescount      => rescount,
      resetdst      => resetdst,
      resetstf      => resetstf,
      activatefast  => activatefast,
      crc_shft_out  => crc_shft_out,
      en_zerointcrc => en_zerointcrc,
      statedeb      => statedeb);

-------------------------------------------------------------------------------
  errordetect : biterrordetect1 PORT MAP
    (clock,
     inbit,
     bitout,
     actvtbed,
     sync_reset_i,
     biterror);
-------------------------------------------------------------------------------
  counting : counter1
    PORT MAP (
      clock       => clock,        -- DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
      Prescale_EN => Prescale_EN,  -- DW 2005.06.29 clock_low vom Prescaler durch Prescale_EN ersetzt.
      inc         => inccount,
      reset       => rescountsig,
      lt3         => lt3_i,
      gt3         => gt3_i,
      eq3         => eq3_i,
      lt11        => lt11_i,
      eq11        => eq11_i,
      counto      => count);
-------------------------------------------------------------------------------
  decaps : decapsulation1
    PORT MAP (
      message_b  => mesout_b,
      message_c  => mesout_c,
      extended   => rext,
      identifier => identifierw);
-------------------------------------------------------------------------------
  destuff : destuffing1 PORT MAP
    (clock,
     inbit,
     actvrstf,
     resetdstsig,
     actvrdct,
     stferror,
     stuffr,
     receivedbit);
-------------------------------------------------------------------------------
  encaps : encapsulation1 PORT MAP
    (clock,
     identifierr,
     extendedr,
     remoter,
     actvtcap,
     resetsig,
     datalenr,
     tmlen,
     mesin(102 DOWNTO 64));             -- nur der Id Teil
-------------------------------------------------------------------------------
  receivecrc : rcrc1 PORT MAP
    (clock,
     receivedbit,
     actvrcrc,
     resrmlensig,
     crc_ok);
-------------------------------------------------------------------------------
  recmlen : recmeslen1 PORT MAP
    (clock,
     actvrmln,
     resrmlensig,
     setrmleno,
     rmlb);
-------------------------------------------------------------------------------
  recshift : rshiftreg1 PORT MAP
    (clock,
     receivedbit,
     actvrsft,
     sync_reset_i,
     lcrc,                              --siehe component rshiftreg
     setzero,
     directshift,
     mesout_a,
     mesout_b,
     mesout_c);
-------------------------------------------------------------------------------
  stuff : stuffing1 PORT MAP
    (clock,
     stuff_inbit,
     actvtstf,
     resetstfsig,
     actvtdct,
     setbdom,
     setbrec,
     bitout,
     stufft);
-------------------------------------------------------------------------------
  transmitcrc : tcrc1 PORT MAP
    (clock,
     crc_out_bit,
     actvtcrc,
     resetsig,
     crc_pre_load_sig_ext,
     crc_pre_load_sig_rem,
     extendedr,
     loader,
     actvtsftsig,
     crc_shft_out,
     zerointcrc_i,
     crc_tosend);
-------------------------------------------------------------------------------
  transhift : tshiftreg1 PORT MAP
    (clock,
     mesin,
     actvtsftsig,
     resetsig,
     loader,
     tshift,
     extendedr,
     bittosend,
     crc_out_bit);
-------------------------------------------------------------------------------
  fsm_regs : fsm_register1
    PORT MAP (
      clock           => clock,
      reset           => sync_reset_i,
      ackerror_set    => ackerror_set_i,
      onarbit_set     => onarbit_set_i,
      transmitter_set => transmitter_set_i,
      receiver_set    => receiver_set_i,
      error_set       => error_set_i,
      first_set       => first_set_i,
      puffer_set      => puffer_set_i,
      rext_set        => rext_set_i,
      rrtr_set        => rrtr_set_i,
      ackerror        => ackerror_i,
      onarbit         => onarbit_i,
      transmitter     => transmitter_i,
      receiver        => receiver_i,
      error           => error_i,
      first           => first_i,
      puffer          => puffer_i,
      rext            => rext,
      rrtr            => rrtr);
-------------------------------------------------------------------------------
  frshift : fastshift1
    PORT MAP (
      reset       => resrmlensig,
      clock       => clock,
      activate    => activatefast,
      rmlb        => rmlb,
      setzero     => setzero,
      directshift => directshift);
-------------------------------------------------------------------------------
  comparator : meslencompare1
    PORT MAP (
      count         => count,
      rmlen         => rmlb,
      tmlen         => tmlen,
      ext_r         => rext,
      ext_t         => extendedr,
      startrcrc     => startrcrc_i,
      rmzero        => rmzero,
      starttcrc     => starttcrc_i,
      zerointcrc    => zerointcrc_i,
      en_zerointcrc => en_zerointcrc);
END behv;
